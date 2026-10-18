import 'dart:convert';
import 'package:drift/native.dart';
import '../../core/database/legacy_schema.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';

final structure = StructuredPlan(
  criteria: const ExerciseFilters(query: 'joga', styles: {'yoga'}),
  budgetSeconds: 300,
  blocks: [
    const PlanBlock(
      exerciseId: 'yoga',
      section: PlanSection.main,
      prescription: PlanPrescription(
        tracking: 'time',
        sets: 2,
        workSeconds: 40,
        restSeconds: 20,
        transitionSeconds: 15,
      ),
    ),
  ],
  warnings: ['Brak rozgrzewki w aktywnej puli.'],
);

void main() {
  test('repo rejects mismatched shallow IDs and structured blocks', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await expectLater(
      PlannerRepository(db).savePlan(
        nazwa: 'Mismatch',
        cwiczeniaIds: ['other'],
        cel: 'mix',
        structure: structure,
      ),
      throwsArgumentError,
    );
    expect(await db.select(db.workoutPlans).get(), isEmpty);
    expect(await db.syncDao.pendingOperations(), isEmpty);
  });
  test(
    'v9 -> 10 keeps shallow plans NULL and attempted payload byte-for-byte',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      var db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await PlannerRepository(
        db,
      ).savePlan(nazwa: 'Legacy', cwiczeniaIds: ['x'], cel: 'mix');
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final before =
          (await db.customSelect('SELECT * FROM sync_outbox').getSingle()).data;
      await db.customStatement(
        'ALTER TABLE workout_plans DROP COLUMN structure_json',
      );
      await removeV12Columns(db);
      await db.customStatement('PRAGMA user_version = 9');
      await db.customStatement(
        'ALTER TABLE workout_sessions DROP COLUMN guidance_json',
      );
      await db.customStatement('DROP TABLE workout_drafts');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);
      expect(
        (await db.select(db.workoutPlans).getSingle()).structureJson,
        isNull,
      );
      expect(
        (await db.customSelect('SELECT * FROM sync_outbox').getSingle()).data,
        before,
      );
      expect(db.schemaVersion, 13);
    },
  );
  test(
    'structure survives save/pull/backup/restore and optional wire field',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = PlannerRepository(db);
      await repo.savePlan(
        nazwa: 'Yoga',
        cwiczeniaIds: structure.exerciseIds,
        cel: 'mix',
        structure: structure,
      );
      expect(
        (await repo.watchAll().first).single.structure!.toJson(),
        structure.toJson(),
      );
      final op = (await db.syncDao.pendingOperations()).single;
      expect(op.payload['structure'], structure.toJson());
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final before =
          (await db.customSelect('SELECT * FROM sync_outbox').getSingle()).data;
      final backup = BackupService(db);
      expect(
        (await backup.importFromBytes(await backup.exportToBytes())).success,
        isTrue,
      );
      expect(
        (await repo.watchAll().first).single.structure!.toJson(),
        structure.toJson(),
      );
      expect(
        (await db
                .customSelect('SELECT * FROM sync_outbox WHERE attempted = 1')
                .getSingle())
            .data,
        before,
      );
      final restoredOp = (await db.syncDao.pendingOperations()).last;
      expect(restoredOp.payload['structure'], structure.toJson());
      await db.close();
      final other = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(other.close);
      final store = SyncStore(other);
      Map<String, Object?> record(int version, Map<String, Object?> payload) =>
          {
            'entityType': 'workoutPlan',
            'entityId': 'remote-plan',
            'version': version,
            'updatedAt': '2026-10-16T00:00:00Z',
            'deletedAt': null,
            'payload': payload,
          };
      await store.apply(record(1, restoredOp.payload));
      expect(
        jsonDecode(
          (await other.select(other.workoutPlans).getSingle()).structureJson!,
        ),
        structure.toJson(),
      );
      await store.apply(
        record(2, {...restoredOp.payload}..remove('structure')),
      );
      expect(
        (await other.select(other.workoutPlans).getSingle()).structureJson,
        isNull,
      );
      await store.enqueueAll();
      expect(
        (await other.syncDao.pendingOperations()).single.payload.containsKey(
          'structure',
        ),
        isFalse,
      );
    },
  );
}
