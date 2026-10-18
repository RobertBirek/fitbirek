import 'dart:async';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/exercises/providers/filter_presets_providers.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/schedule/data/schedule_repository.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:fitbirek_training/features/schedule/providers/schedule_providers.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import '../exercises/catalog_filter_test.dart' show exercise;
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;
import 'schedule_repository_test.dart' show TestAuthority;

class PausedPlan extends PlannerRepository {
  PausedPlan(super.db);
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<SavedPlan?> getBySyncId(String id) async {
    entered.complete();
    await release.future;
    return super.getBySyncId(id);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test(
    'A-B-A during plan resolution cannot leave an active in-memory session after SQLite rollback',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, CollectionServer());
      final authority = TestAuthority();
      final planner = PausedPlan(db);
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
          plannerRepositoryProvider.overrideWithValue(planner),
        ],
      );
      addTearDown(() async {
        c.dispose();
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      await saveProfile(db);
      await planner.savePlan(
        nazwa: 'Zapisany',
        cwiczeniaIds: ['cw001'],
        cel: 'mix',
      );
      final id = (await db.select(db.workoutPlans).getSingle()).syncId;
      final starting = c.read(plannerWorkflowProvider).startSaved(id, [
        exercise('cw001'),
      ]);
      final rejected = expectLater(starting, throwsStateError);
      await planner.entered.future;
      authority.generation += 2;
      planner.release.complete();
      await rejected;
      expect(c.read(activeWorkoutProvider).isActive, isFalse);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
    },
  );
  test(
    'saved plan UUID adapter starts exact plan via existing workflow with no automatic completion or sets',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final planner = c.read(plannerRepositoryProvider);
      await planner.savePlan(
        nazwa: 'Zapisany',
        cwiczeniaIds: ['cw001'],
        cel: 'mix',
      );
      final saved = (await planner.watchAll().first).single;
      expect(
        saved.syncId,
        (await db.select(db.workoutPlans).getSingle()).syncId,
      );
      final workflow = c.read(plannerWorkflowProvider);
      await expectLater(
        workflow.startSaved(saved.syncId!, []),
        throwsStateError,
      );
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      await workflow.startSaved(saved.syncId!, [exercise('cw001')]);
      expect(
        c.read(activeWorkoutProvider).selectedExercises.single.id,
        'cw001',
      );
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      await expectLater(
        workflow.startSaved(saved.syncId!, [exercise('cw001')]),
        throwsStateError,
      );
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
    },
  );
  test(
    'week read observes remote plan deletion as unavailable and does not regenerate',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, CollectionServer());
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          filterPresetsAccountProvider.overrideWith(
            (ref) => Stream.value('account'),
          ),
        ],
      );
      addTearDown(() async {
        c.dispose();
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      await saveProfile(db);
      await c
          .read(plannerRepositoryProvider)
          .savePlan(nazwa: 'Zapisany', cwiczeniaIds: ['cw001'], cel: 'mix');
      final plan = (await db.select(db.workoutPlans).getSingle()).syncId;
      final day = CalendarDay.parse('2026-10-19');
      await ScheduleRepository(db).addRule(
        'account',
        planSyncId: plan,
        name: 'Zapisany',
        weekday: 1,
        effectiveFrom: day,
      );
      await c.read(filterPresetsAccountProvider.future);
      final removed = Completer<ScheduleWeek>();
      final sub = c.listen(scheduleWeekProvider(day), (_, next) {
        final value = next.valueOrNull;
        if (value != null && value.plans.isEmpty && !removed.isCompleted) {
          removed.complete(value);
        }
      });
      addTearDown(sub.close);
      final first = (await c.read(scheduleWeekProvider(day).future))!;
      expect(first.occurrences, hasLength(1));
      expect(first.plans, hasLength(1));
      await db
          .update(db.workoutPlans)
          .write(WorkoutPlansCompanion(deletedAtUtc: Value(DateTime.now())));
      final after = await removed.future.timeout(const Duration(seconds: 10));
      expect(after.occurrences.single.planSyncId, plan);
      expect(after.plans, isEmpty);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
    },
  );
}
