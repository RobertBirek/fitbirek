import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_quarantine.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'structured_plan_persistence_test.dart' show structure;
import '../exercises/catalog_filter_test.dart' show exercise;
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';

class MutableAuthority extends CachedAuthWriteAuthority {
  int generation = 0;
  @override
  int get epoch => generation;
}

class ChangingRepository extends PlannerRepository {
  ChangingRepository(super.db, this.authority);
  final MutableAuthority authority;
  @override
  Future<void> updateTemplate(
    WorkoutPlanData baseline, {
    required String name,
    required StructuredPlan plan,
  }) async {
    await super.updateTemplate(baseline, name: name, plan: plan);
    authority.generation += 2;
  }
}

void main() {
  test(
    'offline manual templates and outbox survive actual database reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp('fit-templates-');
      final file = File('${directory.path}/cache.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      await PlannerRepository(db).savePlan(
        nazwa: 'Offline',
        cwiczeniaIds: structure.exerciseIds,
        cel: '',
        structure: structure,
      );
      final before = (await db.select(db.syncOutbox).get()).single;
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        expect(
          (await PlannerRepository(db).readAll()).single.structure!.toJson(),
          structure.toJson(),
        );
        expect((await db.select(db.syncOutbox).get()).single, before);
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect(await db.select(db.setsLog).get(), isEmpty);
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
  test(
    'explicit saved start snapshots goals; edit/delete never mutate session history',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final workflow = c.read(plannerWorkflowProvider);
      await workflow.saveTemplate(
        await workflow.openTemplate(),
        structure,
        name: 'Template',
      );
      final saved = (await c.read(plannerRepositoryProvider).readAll()).single;
      final lease = await workflow.openTemplate(syncId: saved.syncId);
      await workflow.startTemplate(lease, [exercise('yoga')]);
      final session = (await db.select(db.workoutSessions).get()).single;
      expect(session.syncId, isNot(saved.syncId));
      expect(
        WorkoutGuidance.tryRead(session.guidanceJson)!.plan.toJson(),
        structure.toJson(),
      );
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(await db.select(db.workoutDrafts).get(), isEmpty);
      await workflow.saveTemplate(lease, structure, name: 'Renamed');
      final latest = await workflow.openTemplate(syncId: saved.syncId);
      await workflow.deleteTemplate(latest);
      expect((await db.select(db.workoutSessions).get()).single, session);
      expect(c.read(activeWorkoutProvider).isActive, isTrue);
    },
  );
  test('schema1 optional kg roundtrip and old bytes; invalid kg rejected', () {
    final old = structure.blocks.first.prescription.toJson();
    expect(PlanPrescription.fromJson(old).toJson(), old);
    for (final kg in [0, 12.5]) {
      final json = {...old, 'weightKg': kg};
      expect(PlanPrescription.fromJson(json).weightKg, kg);
    }
    for (final kg in [-1, double.infinity, double.nan]) {
      expect(
        () => PlanPrescription.fromJson({...old, 'weightKg': kg}),
        throwsFormatException,
      );
    }
  });
  test(
    'optimistic edit/delete preserve attempted bytes and create no execution',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = PlannerRepository(db);
      final id = await repo.savePlan(
        nazwa: 'A',
        cwiczeniaIds: structure.exerciseIds,
        cel: '',
        structure: structure,
      );
      final baseline = (await db.select(db.workoutPlans).get()).single;
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final bytes = (await db.select(db.syncOutbox).get()).single;
      await repo.updateTemplate(baseline, name: 'B', plan: structure);
      await expectLater(
        repo.updateTemplate(baseline, name: 'C', plan: structure),
        throwsStateError,
      );
      final current = (await db.select(db.workoutPlans).get()).single;
      await repo.deleteTemplate(current);
      expect(
        (await db.select(db.syncOutbox).get()).where((o) => o.attempted).single,
        bytes,
      );
      expect((await db.plansDao.getPlan(id))!.deletedAtUtc, isNotNull);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.select(db.setsLog).get(), isEmpty);
    },
  );
  test(
    'kg survives edit, backup restore and remote pull with no execution',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final other = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      addTearDown(other.close);
      final json = structure.toJson();
      final block = (json['blocks'] as List).first as Map;
      (block['prescription'] as Map)['weightKg'] = 12.5;
      final weighted = StructuredPlan.fromJson(Map<String, dynamic>.from(json));
      final repo = PlannerRepository(db);
      await repo.savePlan(
        nazwa: 'A',
        cwiczeniaIds: weighted.exerciseIds,
        cel: '',
        structure: weighted,
      );
      await repo.updateTemplate(
        (await db.select(db.workoutPlans).get()).single,
        name: 'B',
        plan: weighted,
      );
      final backup = BackupService(db);
      expect(
        (await backup.importFromBytes(await backup.exportToBytes())).success,
        isTrue,
      );
      final op = (await db.syncDao.pendingOperations()).last;
      await SyncStore(other).apply({
        'entityType': 'workoutPlan',
        'entityId': op.entityId,
        'version': 1,
        'updatedAt': '2026-10-19T00:00:00Z',
        'deletedAt': null,
        'payload': op.payload,
      });
      expect(
        (await PlannerRepository(
          other,
        ).readAll()).single.structure!.blocks.single.prescription.weightKg,
        12.5,
      );
      expect(await other.select(other.workoutSessions).get(), isEmpty);
    },
  );
  test(
    'deferred, push hold and pull quarantine block optimistic mutations',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(accountId: 'A', deviceId: 'device'),
          );
      final repo = PlannerRepository(db);
      await repo.savePlan(
        nazwa: 'A',
        cwiczeniaIds: structure.exerciseIds,
        cel: '',
        structure: structure,
      );
      final row = (await db.select(db.workoutPlans).get()).single;
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);
      final workflow = c.read(plannerWorkflowProvider);
      final lease = await workflow.openTemplate(syncId: row.syncId);
      final source = await workflow.openTemplate();
      expect(
        (await workflow.templateUpdateChoices(source)).single.baseline,
        row,
      );
      await db
          .into(db.syncDeferredRecords)
          .insert(
            SyncDeferredRecordsCompanion.insert(
              entityType: 'workoutPlan',
              entityId: row.syncId,
              version: 1,
              recordJson: '{}',
            ),
          );
      await expectLater(
        repo.updateTemplate(row, name: 'B', plan: structure),
        throwsStateError,
      );
      await expectLater(repo.deleteTemplate(row), throwsStateError);
      expect(await workflow.templateUpdateChoices(source), isEmpty);
      await expectLater(
        workflow.startTemplate(lease, [exercise('yoga')]),
        throwsStateError,
      );
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      await db.delete(db.syncDeferredRecords).go();
      final quarantine = SyncQuarantine(db, SyncStore(db));
      await quarantine.hold(
        'A',
        (await db.syncDao.pendingOperations()).single,
        {},
      );
      await expectLater(repo.deleteTemplate(row), throwsStateError);
      expect(await workflow.templateUpdateChoices(source), isEmpty);
      await db.delete(db.syncDeferredRecords).go();
      await quarantine.apply(
        {'entityType': 'workoutPlan', 'entityId': row.syncId},
        'A',
        1,
        0,
      );
      await expectLater(
        repo.updateTemplate(row, name: 'B', plan: structure),
        throwsStateError,
      );
      expect(await workflow.templateUpdateChoices(source), isEmpty);
      expect((await repo.readAll()).single.nazwa, 'A');
    },
  );
  test(
    'lease rejects A-B-A epoch and durable device rotation / offline lock',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final auth = MutableAuthority();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(() async {
        c.dispose();
        auth.revision.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'A', deviceId: 'd1'));
      final workflow = c.read(plannerWorkflowProvider);
      final lease = await workflow.openTemplate();
      auth.generation += 2;
      await expectLater(
        workflow.templateUpdateChoices(lease),
        throwsStateError,
      );
      await expectLater(
        workflow.saveTemplate(lease, structure, name: 'Stale'),
        throwsStateError,
      );
      final fresh = await workflow.openTemplate();
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(deviceId: Value('d2')));
      await expectLater(
        workflow.saveTemplate(fresh, structure, name: 'Stale'),
        throwsStateError,
      );
      final offline = await workflow.openTemplate();
      await db.syncDao.lockOfflineAccess();
      await expectLater(
        workflow.saveTemplate(offline, structure, name: 'Stale'),
        throwsStateError,
      );
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect(c.exists(authStateProvider), isFalse);
    },
  );
  test(
    'epoch change after repository await rolls back row and outbox',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final auth = MutableAuthority();
      final repo = ChangingRepository(db, auth);
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(auth),
          plannerRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() async {
        c.dispose();
        auth.revision.dispose();
        await db.close();
      });
      await repo.savePlan(
        nazwa: 'A',
        cwiczeniaIds: structure.exerciseIds,
        cel: '',
        structure: structure,
      );
      final before = (await db.select(db.syncOutbox).get()).single;
      final lease = await c
          .read(plannerWorkflowProvider)
          .openTemplate(syncId: (await repo.readAll()).single.syncId);
      await expectLater(
        c
            .read(plannerWorkflowProvider)
            .saveTemplate(lease, structure, name: 'B'),
        throwsStateError,
      );
      expect((await repo.readAll()).single.nazwa, 'A');
      expect((await db.select(db.syncOutbox).get()).single, before);
    },
  );
}
