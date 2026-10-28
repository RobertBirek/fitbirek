import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'structured_plan_persistence_test.dart' show structure;

/// Minimal workoutPlan branch copied from SyncStore.apply at 3397b83:
/// existing tombstones still parse required fields from the WIRE payload,
/// convert the ID list to local JSON, then write the snapshot in the page txn.
/// The current generated row has the same four required legacy fields; its
/// additional nullable structureJson plays no role in this receiver contract.
Future<void> legacyPull(AppDatabase db, SyncOperation operation) =>
    db.transaction(() async {
      final existing = await (db.select(
        db.workoutPlans,
      )..where((p) => p.syncId.equals(operation.entityId))).getSingleOrNull();
      if (existing == null && operation.deleted) return;
      final json = Map<String, dynamic>.from(operation.payload);
      json['cwiczeniaIds'] = jsonEncode(json['cwiczeniaIds'] as List);
      json.addAll({
        'id': existing!.id,
        'syncId': operation.entityId,
        'syncVersion': existing.syncVersion + 1,
        'updatedAtUtc': '2026-10-16T02:00:00Z',
        'deletedAtUtc': '2026-10-16T02:00:00Z',
      });
      final parsed = WorkoutPlanData.fromJson(json);
      await db
          .into(db.workoutPlans)
          .insertOnConflictUpdate(parsed.toCompanion(false));
      await db
          .update(db.syncState)
          .write(
            const SyncStateCompanion(cursor: Value(25), fullCursor: Value(25)),
          );
    });

void main() {
  late AppDatabase db;
  late PlannerRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlannerRepository(db);
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(accountId: 'account', deviceId: 'device'),
        );
  });
  tearDown(() => db.close());

  final cases = <String, (String?, String, List<String>)>{
    'correct structure': (jsonEncode(structure.toJson()), '["yoga"]', ['yoga']),
    'corrupt structure': ('{', '["yoga"]', ['yoga']),
    'corrupt IDs JSON': ('{}', '{', []),
    'corrupt IDs contents': ('[]', '["yoga",42]', []),
  };
  for (final route in ['repo', 'enqueueAll deleted', 'enqueueAll tombstone']) {
    for (final entry in cases.entries) {
      test(
        '$route / ${entry.key}: legacy envelope, raw preserved, old receiver advances cursor',
        () async {
          final id = await repo.savePlan(
            nazwa: 'Plan źródłowy',
            cwiczeniaIds: ['yoga'],
            cel: 'mix',
          );
          await db.delete(db.syncOutbox).go();
          await (db.update(
            db.workoutPlans,
          )..where((p) => p.id.equals(id))).write(
            WorkoutPlansCompanion(
              structureJson: Value(entry.value.$1),
              cwiczeniaIds: Value(entry.value.$2),
              deletedAtUtc: route == 'enqueueAll tombstone'
                  ? Value(DateTime.utc(2026, 10, 16))
                  : const Value.absent(),
            ),
          );
          final original = (await db.select(db.workoutPlans).getSingle());
          if (route == 'repo') {
            await repo.deletePlan(id);
          } else {
            await SyncStore(
              db,
            ).enqueueAll(deleted: route == 'enqueueAll deleted');
          }
          final op = (await db.syncDao.pendingOperations()).single;
          expect(op.deleted, isTrue);
          expect(op.payload, {
            'nazwa': original.nazwa,
            'cwiczeniaIds': entry.value.$3,
            'cel': original.cel,
            'dataUtworzenia': original.dataUtworzenia.toUtc().toIso8601String(),
          });
          final raw = await db.select(db.workoutPlans).getSingle();
          expect(raw.structureJson, original.structureJson);
          expect(raw.cwiczeniaIds, original.cwiczeniaIds);
          await legacyPull(db, op);
          expect(
            (await db.select(db.workoutPlans).getSingle()).deletedAtUtc,
            isNotNull,
          );
          expect((await db.syncDao.readState())!.cursor, 25);
        },
      );
    }
  }
  test(
    'old receiver repro: empty attempted DELETE blocks required parser and cursor',
    () async {
      final id = await repo.savePlan(
        nazwa: 'existing',
        cwiczeniaIds: ['yoga'],
        cel: 'mix',
      );
      await db.delete(db.syncOutbox).go();
      final row = (await db.select(db.workoutPlans).getSingle());
      await db.syncDao.enqueueDelete(
        entityType: SyncEntityType.workoutPlan,
        entityId: row.syncId,
        baseVersion: 0,
        payload: const {},
      );
      final op = (await db.syncDao.pendingOperations()).single;
      await expectLater(legacyPull(db, op), throwsA(isA<TypeError>()));
      expect((await db.syncDao.readState())!.cursor, 0);
      expect((await db.plansDao.getPlan(id))!.deletedAtUtc, isNull);
    },
  );
  test(
    'restore preserves attempted empty DELETE exactly, new deletes carry legacy fields',
    () async {
      final id = await repo.savePlan(
        nazwa: 'restored',
        cwiczeniaIds: ['yoga'],
        cel: 'mix',
        structure: structure,
      );
      await db.delete(db.syncOutbox).go();
      final row = await db.select(db.workoutPlans).getSingle();
      await db.syncDao.enqueueDelete(
        entityType: SyncEntityType.workoutPlan,
        entityId: row.syncId,
        baseVersion: 0,
        payload: const {},
      );
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final attempted =
          (await db.customSelect('SELECT * FROM sync_outbox').getSingle()).data;
      final service = BackupService(db);
      final backup = await service.exportToBytes();
      // Quarantined raw now refuses destructive restore; this regression checks
      // the independent attempted DELETE/legacy envelope contract on readable data.
      expect((await db.plansDao.getPlan(id))!.structureJson, isNotNull);
      expect((await service.importFromBytes(backup)).success, isTrue);
      expect(
        (await db
                .customSelect('SELECT * FROM sync_outbox WHERE attempted = 1')
                .getSingle())
            .data,
        attempted,
      );
      final ops = await db.syncDao.pendingOperations();
      final deletes = ops
          .where((o) => o.deleted && o.payload.isNotEmpty)
          .toList();
      expect(deletes, hasLength(1));
      expect(deletes.single.payload, {
        'nazwa': row.nazwa,
        'cwiczeniaIds': ['yoga'],
        'cel': row.cel,
        'dataUtworzenia': row.dataUtworzenia.toUtc().toIso8601String(),
      });
      expect(
        ops.where((o) => !o.deleted).single.payload['structure'],
        structure.toJson(),
      );
    },
  );
}
