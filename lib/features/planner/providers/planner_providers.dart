import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../data/planner_repository.dart';
import '../../../core/models/exercise.dart';
import '../../../core/database/app_database.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/domain/exercise_filter_engine.dart';
import '../../workout/providers/workout_providers.dart';
import '../domain/structured_plan.dart';
import '../../workout/domain/workout_guidance.dart';

/// One-time entry snapshot, never a frozen catalog ID list.
final plannerEntryCriteriaProvider = StateProvider<ExerciseFilters?>(
  (ref) => null,
);

final plannerWorkflowProvider = Provider<PlannerWorkflow>(
  (ref) => PlannerWorkflow(ref),
);

class PlannerWorkflow {
  PlannerWorkflow(this.ref);
  final Ref ref;
  bool _busy = false;

  Future<T> _write<T>(
    Future<T> Function(AppDatabase db, bool Function() guard) action,
  ) async {
    if (_busy) throw StateError('Operacja planu już trwa.');
    final authority = ref.read(cachedAuthWriteAuthorityProvider);
    final epoch = authority.epoch;
    final db = ref.read(appDatabaseProvider);
    bool alive = true;
    void disposed() => alive = false;
    ref.onDispose(disposed);
    bool guard() =>
        alive &&
        authority.epoch == epoch &&
        (authority.state == null || authority.state!.isSignedIn);
    _busy = true;
    try {
      return await db.transaction(() async {
        if (!guard()) {
          throw StateError('Konto zmieniło się. Otwórz planner ponownie.');
        }
        final cache = await db.syncDao.readState();
        final account = authority.state?.accountId;
        if (!guard() ||
            (cache != null && !cache.offlineAccess) ||
            (account != null &&
                (cache?.accountId != account ||
                    cache?.offlineAccess != true))) {
          throw StateError('Pamięć konta jest niedostępna.');
        }
        final result = await action(db, guard);
        final after = await db.syncDao.readState();
        if (!guard() ||
            cache?.accountId != after?.accountId ||
            cache?.offlineAccess != after?.offlineAccess) {
          throw StateError('Pamięć konta zmieniła się.');
        }
        return result;
      });
    } finally {
      _busy = false;
    }
  }

  Future<int> save(
    StructuredPlan plan, {
    required String name,
    required String goal,
  }) => _write(
    (db, guard) => ref
        .read(plannerRepositoryProvider)
        .savePlan(
          nazwa: name,
          cwiczeniaIds: plan.exerciseIds,
          cel: goal,
          structure: plan,
        ),
  );

  Future<void> start(List<Exercise> exercises, {StructuredPlan? plan}) =>
      _write((db, guard) async {
        if (exercises.isEmpty ||
            ref.read(activeWorkoutProvider).isActive ||
            ref.read(activeWorkoutProvider).selectedExercises.isNotEmpty) {
          throw StateError('Najpierw zakończ lub odrzuć bieżący trening.');
        }
        final notifier = ref.read(activeWorkoutProvider.notifier);
        await notifier.startSession(
          guidance: plan == null ? null : WorkoutGuidance.start(plan),
        );
        if (!guard() || !ref.read(activeWorkoutProvider).isActive) {
          throw StateError('Start anulowany.');
        }
        for (final e in exercises) {
          notifier.addExercise(e);
        }
        notifier.updateDraft({});
      });
}

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PlannerRepository(db);
});

final savedPlansProvider = StreamProvider<List<SavedPlan>>((ref) {
  final repo = ref.watch(plannerRepositoryProvider);
  return repo.watchAll();
});
