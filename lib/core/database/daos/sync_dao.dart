import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../sync/sync_models.dart';
import '../app_database.dart';
import '../tables/sync_tables.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncState, SyncOutbox, ExerciseFavorites])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  Future<SyncStateData?> readState() => select(syncState).getSingleOrNull();

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
    return _enqueue(
      entityType: entityType,
      entityId: entityId,
      baseVersion: baseVersion,
      payload: payload,
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
