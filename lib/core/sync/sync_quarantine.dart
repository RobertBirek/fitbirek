import 'dart:convert';
import '../database/app_database.dart';
import 'sync_models.dart';
import 'sync_store.dart';

/// Local-only envelopes in the existing durable deferred store. Separate keys
/// prevent a newer snapshot/reconcile from destroying the original evidence.
class SyncQuarantine {
  SyncQuarantine(this.db, this.store);
  final AppDatabase db;
  final SyncStore store;
  static const pullType = '_syncPullQuarantine';
  static const pushType = '_syncPushHold';

  Future<void> _save(String type, String id, Map<String, dynamic> value) => db
      .into(db.syncDeferredRecords)
      .insertOnConflictUpdate(
        SyncDeferredRecordsCompanion.insert(
          entityType: type,
          entityId: id,
          version: 1,
          recordJson: jsonEncode(value),
        ),
      );

  Future<List<SyncDeferredRecordData>> _rows(String type) => (db.select(
    db.syncDeferredRecords,
  )..where((r) => r.entityType.equals(type))).get();

  Future<Set<String>> heldKeys(String accountId) async => {
    for (final row in await _rows(pushType))
      if ((jsonDecode(row.recordJson) as Map)['accountId'] == accountId)
        (jsonDecode(row.recordJson) as Map)['key'] as String,
    for (final row in await _rows(pullType))
      ..._pullKeys(jsonDecode(row.recordJson) as Map, accountId),
  };

  Set<String> _pullKeys(Map envelope, String accountId) {
    final raw = envelope['raw'];
    if (envelope['accountId'] != accountId ||
        envelope['recovered'] == true ||
        raw is! Map ||
        raw['entityType'] is! String ||
        raw['entityId'] is! String) {
      return {};
    }
    return {'${raw['entityType']}:${raw['entityId']}'};
  }

  Future<void> hold(String accountId, SyncOperation op, Object outcome) =>
      _save(pushType, op.operationId, {
        'accountId': accountId,
        'key': '${op.entityType.wireName}:${op.entityId}',
        'operationId': op.operationId, 'outcome': outcome,
        // Original immutable bytes remain in sync_outbox. No re-ID or resend.
      });

  /// Only explicit wire validation failures are quarantined. SQLite, IO and
  /// programming errors escape and roll back the page including its cursor.
  Future<void> apply(
    Object? raw,
    String accountId,
    int cursor,
    int index,
  ) async {
    try {
      await _apply(raw);
    } on InvalidSyncRecord catch (e) {
      await _save(pullType, jsonEncode([accountId, cursor, index]), {
        'accountId': accountId,
        'cursor': cursor,
        'index': index,
        'raw': raw,
        'reason': e.message,
        'recovered': false,
      });
    }
  }

  Future<void> _apply(Object? raw) async {
    if (raw is! Map<String, dynamic>) {
      throw const InvalidSyncRecord('Sync record must be an object');
    }
    await store.apply(raw);
  }

  /// Retry local snapshots only (never pushes). Missing parents can arrive on
  /// a later page; corrected newer versions supersede invalid history. Evidence
  /// is retained even after successful recovery, including unknown schemas.
  Future<bool> recover(String accountId) async {
    var blocked = false;
    for (final row in await _rows(pullType)) {
      final envelope = Map<String, dynamic>.from(
        jsonDecode(row.recordJson) as Map,
      );
      if (envelope['accountId'] != accountId || envelope['recovered'] == true) {
        continue;
      }
      try {
        await _apply(envelope['raw']);
        envelope['recovered'] = true;
        await _save(pullType, row.entityId, envelope);
      } on InvalidSyncRecord {
        blocked = true;
      }
    }
    return blocked;
  }
}
