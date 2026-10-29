import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/schedule/data/training_programs_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/training_program_schedule.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:fitbirek_training/features/schedule/providers/training_programs_providers.dart';
import 'package:fitbirek_training/features/workout/preparation/providers/preparation_providers.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/workout_preparation.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import '../../core/profile_collections_sync_test.dart'
    show CollectionServer, saveProfile;
import '../../core/training_sets_programs_domain_test.dart'
    show planA, planB, planJson;
import '../exercises/catalog_filter_test.dart' show exercise;
import 'training_programs_repository_test.dart' show programMetadata;
import 'schedule_repository_test.dart' show TestAuthority;

void main() {
  late AppDatabase db;
  late SyncService sync;
  late ProviderContainer c;
  late TrainingProgramsRepository repo;
  late TestAuthority authority;
  final day = CalendarDay.parse('2026-10-19');
  late String program;
  Future<ProgramOccurrence> occurrence() async => TrainingProgramSchedule(
    await repo.load('account'),
  ).between(day, day).single;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sync = SyncService(db, CollectionServer());
    await sync.bindAccount('account');
    await saveProfile(db);
    for (final id in [planA, planB]) {
      await db
          .into(db.workoutPlans)
          .insert(
            WorkoutPlansCompanion.insert(
              nazwa: 'Plan',
              cwiczeniaIds: '["cw001"]',
              cel: 'Własny szablon',
              syncId: Value(id),
              structureJson: Value(jsonEncode(planJson())),
            ),
          );
    }
    repo = TrainingProgramsRepository(db);
    authority = TestAuthority();
    program = await repo.create(
      await repo.open('account'),
      name: 'Program',
      planSyncIds: [planA, planB],
      weekdays: {1, 3, 5},
      effectiveFrom: day,
      catalog: [exercise('cw001')],
      metadata: programMetadata,
    );
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
        filterPresetsAccountProvider.overrideWith(
          (ref) => Stream.value('account'),
        ),
        allExercisesProvider.overrideWith(
          (ref) => Stream.value([exercise('cw001')]),
        ),
        exerciseCatalogMetadataProvider.overrideWith(
          (ref) async => programMetadata,
        ),
      ],
    );
    await c.read(filterPresetsAccountProvider.future);
    await db.delete(db.syncOutbox).go();
  });
  tearDown(() async {
    c.dispose();
    sync.dispose();
    await db.close();
  });
  for (final change in [
    'move-back',
    'end',
    'plan-edit',
    'hold',
    'accountABA',
  ]) {
    test(
      'program preparation lease rejects $change before creating any session or draft',
      () async {
        final workflow = c.read(workoutPreparationWorkflowProvider);
        final original = await occurrence();
        final snapshot = await workflow.open(
          planSyncId: planA,
          programOccurrence: original,
        );
        if (change == 'move-back') {
          await repo.move('account', original, day.plus(1));
          final moved = TrainingProgramSchedule(
            await repo.load('account'),
          ).between(day.plus(1), day.plus(1)).single;
          await repo.move('account', moved, day);
        } else if (change == 'end') {
          await repo.end(
            await repo.open('account', programId: program),
            CalendarDay.local(DateTime.now()),
          );
        } else if (change == 'plan-edit') {
          await db
              .update(db.workoutPlans)
              .write(
                const WorkoutPlansCompanion(nazwa: Value('Równoległa edycja')),
              );
        } else if (change == 'hold') {
          final profile = (await db.userProfileDao.watchProfileOnce())!;
          await db
              .into(db.syncDeferredRecords)
              .insert(
                SyncDeferredRecordsCompanion.insert(
                  entityType: 'profile',
                  entityId: profile.syncId,
                  version: 2,
                  recordJson: '{"raw":"hold"}',
                ),
              );
        } else {
          authority.generation += 2;
        }
        final outbox = (await db.select(db.syncOutbox).get())
            .map((r) => r.toJson())
            .toList();
        await expectLater(
          workflow.start(PreparationDraft(snapshot), isCurrent: () => true),
          throwsStateError,
        );
        expect(c.read(activeWorkoutProvider).isActive, isFalse);
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect(await db.select(db.workoutDrafts).get(), isEmpty);
        expect(
          (await db.select(db.syncOutbox).get())
              .map((r) => r.toJson())
              .toList(),
          outbox,
        );
      },
    );
  }

  test(
    'read-only program preparation cancel writes nothing; stale move/rename/hold refuses start',
    () async {
      final workflow = c.read(workoutPreparationWorkflowProvider);
      final snapshot = await workflow.open(
        planSyncId: planA,
        programOccurrence: await occurrence(),
      );
      expect(snapshot.plan!.schemaVersion, 2);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.select(db.workoutDrafts).get(), isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      await repo.rename(
        await repo.open('account', programId: program),
        'Nowa nazwa',
      );
      await expectLater(
        workflow.start(PreparationDraft(snapshot), isCurrent: () => true),
        throwsStateError,
      );
      expect(c.read(activeWorkoutProvider).isActive, isFalse);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
    },
  );
  test(
    'program starts via existing v2 preparation, never completes; active snapshot survives edit',
    () async {
      final workflow = c.read(workoutPreparationWorkflowProvider);
      final snapshot = await workflow.open(
        planSyncId: planA,
        programOccurrence: await occurrence(),
      );
      await workflow.start(PreparationDraft(snapshot), isCurrent: () => true);
      final active = c.read(activeWorkoutProvider);
      expect(active.isActive, isTrue);
      expect(
        active.guidance!.plan.blocks.single.prescription.setTargets.map(
          (t) => t.weightKg,
        ),
        [12.0, 18.0],
      );
      expect(active.currentTarget!.targetId, 'a');
      expect(active.currentTarget!.setRole, 'warmup');
      expect((await occurrence()).sessionSyncId, isNull);
      expect(await db.select(db.setsLog).get(), isEmpty);
      final lease = await c
          .read(plannerWorkflowProvider)
          .openTemplate(syncId: planA);
      final edited = planJson();
      (edited['blocks'] as List)
              .single['prescription']['setTargets'][0]['weightKg'] =
          2.0;
      await c
          .read(plannerWorkflowProvider)
          .saveTemplate(lease, StructuredPlan.fromJson(edited), name: 'Edycja');
      expect(
        c.read(activeWorkoutProvider).guidance!.plan.toJson(),
        snapshot.plan!.toJson(),
      );
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
    },
  );
  test(
    'week observes warmup filter, deleted plan and profile hold without any writes',
    () async {
      final sub = c.listen(trainingProgramsWeekProvider(day), (_, _) {});
      addTearDown(sub.close);
      final first = (await c.read(trainingProgramsWeekProvider(day).future))!;
      expect(first.occurrences, hasLength(3));
      expect(first.writeError, isNull);
      final changed = Completer<TrainingProgramsWeek>();
      final listener = c.listen(trainingProgramsWeekProvider(day), (_, next) {
        final value = next.valueOrNull;
        if (value != null &&
            value.unavailable.containsKey(planA) &&
            value.writeError != null &&
            !changed.isCompleted) {
          changed.complete(value);
        }
      });
      addTearDown(listener.close);
      await (db.update(
        db.workoutPlans,
      )..where((p) => p.syncId.equals(planA))).write(
        WorkoutPlansCompanion(deletedAtUtc: Value(DateTime.now().toUtc())),
      );
      final profile = (await db.userProfileDao.watchProfileOnce())!;
      await db
          .into(db.syncDeferredRecords)
          .insert(
            SyncDeferredRecordsCompanion.insert(
              entityType: 'profile',
              entityId: profile.syncId,
              version: 2,
              recordJson: '{"raw":"future"}',
            ),
          );
      final after = await changed.future.timeout(const Duration(seconds: 10));
      expect(after.occurrences, hasLength(3));
      expect(after.sessions, isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      await expectLater(
        c
            .read(workoutPreparationWorkflowProvider)
            .open(
              planSyncId: planB,
              programOccurrence: TrainingProgramSchedule(
                await repo.load('account'),
              ).between(day.plus(2), day.plus(2)).single,
            ),
        throwsStateError,
      );
    },
  );
}
