import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_models.dart';
import '../../sync/user_collections.dart';
import '../app_database.dart';
import '../tables/sync_tables.dart';
import '../../../features/progress/tests/domain/fitness_protocol.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncState, SyncOutbox, ExerciseFavorites])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  Future<SyncStateData?> readState() => select(syncState).getSingleOrNull();

  /// Revokes every service/tab using the old binding, even after A → B → A
  /// or a same-account login. deviceId is local-only, not an API identity.
  Future<void> lockOfflineAccess() => update(syncState).write(
    SyncStateCompanion(
      offlineAccess: const Value(false),
      deviceId: Value(Uuid().v4()),
    ),
  );

  Future<String> singletonId(String key) async {
    final state = await readState();
    return state == null
        ? Uuid().v4()
        : Uuid().v5(Namespace.url.value, 'fitbirek:${state.accountId}:$key');
  }

  Future<List<SyncOperation>> pendingOperations() async {
    final rows =
        await (select(syncOutbox)..orderBy([
              (table) => OrderingTerm.desc(table.attempted),
              (table) => OrderingTerm.asc(table.createdAtUtc),
            ]))
            .get();
    return rows.map(_operationFromRow).toList();
  }

  SyncOperation _operationFromRow(SyncOutboxData row) {
    final decodedPayload = jsonDecode(row.payloadJson);
    if (decodedPayload is! Map<String, dynamic>) {
      throw FormatException('Outbox payload must be an object.');
    }
    return SyncOperation.fromPersisted(
      operationId: row.operationId,
      entityType: row.entityType,
      entityId: row.entityId,
      baseVersion: row.baseVersion,
      payload: Map<String, Object?>.from(decodedPayload),
      deleted: row.deleted,
      preserveLocal: row.preserveLocal,
    );
  }

  Future<void> enqueueUpsert({
    bool preserveLocal = false,
    required SyncEntityType entityType,
    required String entityId,
    required int baseVersion,
    required Map<String, Object?> payload,
  }) {
    if (entityType == SyncEntityType.healthSample) {
      throw StateError('Health imports are server-owned');
    }
    final snapshot = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(payload)) as Map,
    );
    if (entityType == SyncEntityType.fitnessTest &&
        (snapshot['typ'] == 'customFitnessTestV1' ||
            snapshot['customProtocol'] != null)) {
      FitnessProtocol.validateResultPayload(snapshot);
    }
    if (entityType == SyncEntityType.profile) {
      for (final key in UserCollections.keys) {
        if (snapshot[key] != null) UserCollections.validate(key, snapshot[key]);
      }
    }
    if (entityType == SyncEntityType.workoutSet ||
        entityType == SyncEntityType.personalRecord) {
      UserCollections.validateVariantPair(Map<String, dynamic>.from(snapshot));
      if (snapshot['variantId'] == null) snapshot.remove('variantLabel');
    }
    return _enqueue(
      entityType: entityType,
      entityId: entityId,
      baseVersion: baseVersion,
      payload: snapshot,
      deleted: false,
      preserveLocal: preserveLocal,
    );
  }

  Future<void> enqueueDelete({
    bool preserveLocal = false,
    required SyncEntityType entityType,
    required String entityId,
    required int baseVersion,
    required Map<String, Object?> payload,
  }) {
    return _enqueue(
      entityType: entityType,
      entityId: entityId,
      baseVersion: baseVersion,
      payload: payload,
      deleted: true,
      preserveLocal: preserveLocal,
    );
  }

  Future<void> _enqueue({
    required bool preserveLocal,
    required SyncEntityType entityType,
    required String entityId,
    required int baseVersion,
    required Map<String, Object?> payload,
    required bool deleted,
  }) async {
    // Work on a new snapshot only. Previously attempted operations are inputs,
    // never mutation targets, including when an explicit restore clear survives
    // a later ordinary profile save that omits nullable raw extension columns.
    payload = Map<String, Object?>.from(payload);
    if (entityType == SyncEntityType.profile && !deleted) {
      final seen = <String>{
        for (final key in UserCollections.keys)
          if (payload.containsKey(key)) key,
      };
      final pending = await attachedDatabase
          .customSelect(
            'SELECT payload_json FROM sync_outbox WHERE entity_type = ? AND entity_id = ? AND deleted = 0 ORDER BY rowid DESC',
            variables: [Variable(entityType.wireName), Variable(entityId)],
          )
          .get();
      for (final row in pending) {
        final old = jsonDecode(row.read<String>('payload_json')) as Map;
        for (final key in UserCollections.keys) {
          if (!seen.contains(key) && old.containsKey(key)) {
            seen.add(key);
            if (old[key] == null) payload[key] = null;
          }
        }
      }
    }
    final previous =
        await (select(syncOutbox)..where(
              (o) =>
                  o.entityType.equals(entityType.wireName) &
                  o.entityId.equals(entityId),
            ))
            .get();
    preserveLocal = preserveLocal || previous.any((o) => o.preserveLocal);
    // The newest complete mutation supersedes an unsent mutation for a row.
    await (delete(syncOutbox)..where(
          (table) =>
              table.entityType.equals(entityType.wireName) &
              table.entityId.equals(entityId) &
              table.attempted.equals(false),
        ))
        .go();
    await into(syncOutbox).insert(
      SyncOutboxCompanion.insert(
        operationId: Uuid().v4(),
        entityType: entityType.wireName,
        entityId: entityId,
        baseVersion: baseVersion,
        payloadJson: jsonEncode(payload),
        deleted: Value(deleted),
        preserveLocal: Value(preserveLocal),
        createdAtUtc: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
