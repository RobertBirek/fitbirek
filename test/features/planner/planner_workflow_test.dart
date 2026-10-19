import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import '../workout/pr_cancel_test.dart'
    show LocalAuthRepository, LocalSyncService, LocalExercisesRepository;
import '../../core/push_settings_test.dart' show FakePush;
import '../exercises/catalog_filter_test.dart' show exercise;
import 'structured_plan_persistence_test.dart' show structure;
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';

class PausedStart extends WorkoutRepository {
  PausedStart(super.db);
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<int> startSession({
    bool Function()? guard,
    String? accountId,
    WorkoutGuidance? guidance,
    bool requireNoActiveSession = false,
  }) async {
    entered.complete();
    await release.future;
    return super.startSession(
      guard: guard,
      accountId: accountId,
      guidance: guidance,
      requireNoActiveSession: requireNoActiveSession,
    );
  }
}

void main() {
  test(
    'logout during planner async start rolls back cache rows and outbox without HTTP refresh',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = PausedStart(db);
      final api = LocalAuthRepository();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(api),
          syncServiceProvider.overrideWith((ref) => LocalSyncService(db)),
          exercisesRepositoryProvider.overrideWithValue(
            LocalExercisesRepository(db),
          ),
          pushClientProvider.overrideWithValue(FakePush()),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final ready = Completer<void>();
      c.listen(authStateProvider, (_, state) {
        if (state.isSignedIn && !ready.isCompleted) ready.complete();
      }, fireImmediately: true);
      await ready.future;
      final reads = api.sessionReads;
      final start = c.read(plannerWorkflowProvider).start([exercise('yoga')]);
      final failed = expectLater(start, throwsStateError);
      await repo.entered.future;
      final logout = c.read(authStateProvider.notifier).logout();
      repo.release.complete();
      await failed;
      await logout;
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect(c.read(activeWorkoutProvider).isActive, isFalse);
      expect(api.sessionReads, reads);
    },
  );
  test(
    'preview does not write, save preserves structure; start uses active notifier',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      final workflow = c.read(plannerWorkflowProvider);
      await workflow.save(structure, name: 'Yoga', goal: 'mix');
      expect(
        (await c.read(savedPlansProvider.future)).single.structure!.toJson(),
        structure.toJson(),
      );
      await workflow.start([exercise('yoga')]);
      expect(c.read(activeWorkoutProvider).isActive, isTrue);
      expect(c.read(activeWorkoutProvider).selectedExercises.single.id, 'yoga');
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      await expectLater(workflow.start([exercise('yoga')]), throwsStateError);
    },
  );
  test(
    'discard during asynchronous start rolls back session and outbox',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = PausedStart(db);
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final start = c.read(plannerWorkflowProvider).start([exercise('yoga')]);
      final failed = expectLater(start, throwsStateError);
      await repo.entered.future;
      c.read(activeWorkoutProvider.notifier).discardSession();
      repo.release.complete();
      await failed;
      expect(c.read(activeWorkoutProvider).isActive, isFalse);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      expect(await db.syncDao.pendingOperations(), isEmpty);
    },
  );
}
