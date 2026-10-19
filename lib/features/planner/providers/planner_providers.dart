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

/// Captured before opening an editor/confirmation, not after the user's await.
class TemplateLease {
  TemplateLease(
    this.epoch,
    this.accountId,
    this.deviceId,
    this.offlineAccess,
    this.baseline,
  );
  final int epoch;
  final String? accountId, deviceId;
  final bool? offlineAccess;
  final WorkoutPlanData? baseline;
}

class PlannerWorkflow {
  PlannerWorkflow(this.ref);
  final Ref ref;
  bool _busy = false;

  Future<TemplateLease> openTemplate({String? syncId}) =>
      _write((db, guard) async {
        final state = await db.syncDao.readState();
        final repo = ref.read(plannerRepositoryProvider);
        final row = syncId == null ? null : await repo.snapshot(syncId);
        if (syncId != null && row == null) {
          throw StateError('Szablon jest niedostępny.');
        }
        if (row != null) await repo.checkTemplate(row);
        return TemplateLease(
          ref.read(cachedAuthWriteAuthorityProvider).epoch,
          state?.accountId,
          state?.deviceId,
          state?.offlineAccess,
          row,
        );
      });

  Future<void> _checkLease(AppDatabase db, TemplateLease lease) async {
    final state = await db.syncDao.readState();
    if (ref.read(cachedAuthWriteAuthorityProvider).epoch != lease.epoch ||
        state?.accountId != lease.accountId ||
        state?.deviceId != lease.deviceId ||
        state?.offlineAccess != lease.offlineAccess) {
      throw StateError(
        'Konto zmieniło się. Zamknij edytor i otwórz go ponownie.',
      );
    }
    if (lease.baseline != null) {
      await ref.read(plannerRepositoryProvider).checkTemplate(lease.baseline!);
    }
  }

  Future<void> validateTemplateLease(TemplateLease lease) =>
      _write((db, guard) => _checkLease(db, lease));

  /// Capture optimistic baselines under the *source* account, never recapture
  /// authority after a session read or the destination picker.
  Future<List<TemplateLease>> templateUpdateChoices(TemplateLease source) =>
      _write((db, guard) async {
        await _checkLease(db, source);
        final repo = ref.read(plannerRepositoryProvider);
        final choices = <TemplateLease>[];
        for (final saved in await repo.readAll()) {
          if (saved.isUnavailable || saved.structure == null) continue;
          final row = await repo.snapshot(saved.syncId!);
          if (row == null) continue;
          try {
            await repo.checkTemplate(row);
          } on StateError {
            continue; // Deferred/quarantined entries cannot be destinations.
          }
          choices.add(
            TemplateLease(
              source.epoch,
              source.accountId,
              source.deviceId,
              source.offlineAccess,
              row,
            ),
          );
        }
        await _checkLease(db, source);
        return choices;
      });

  Future<void> saveTemplate(
    TemplateLease lease,
    StructuredPlan plan, {
    required String name,
  }) => _write((db, guard) async {
    await _checkLease(db, lease);
    PlannerRepository.validateTemplate(name, plan);
    final repo = ref.read(plannerRepositoryProvider);
    if (lease.baseline == null) {
      await repo.savePlan(
        nazwa: name.trim(),
        cwiczeniaIds: plan.exerciseIds,
        cel: 'Własny szablon',
        structure: plan,
      );
    } else {
      await repo.updateTemplate(lease.baseline!, name: name, plan: plan);
    }
  });

  Future<void> deleteTemplate(TemplateLease lease) => _write((db, guard) async {
    await _checkLease(db, lease);
    if (lease.baseline == null) throw StateError('Brak zapisanego szablonu.');
    await ref.read(plannerRepositoryProvider).deleteTemplate(lease.baseline!);
  });

  Future<void> startTemplate(TemplateLease lease, List<Exercise> catalog) =>
      startSaved(lease.baseline?.syncId ?? '', catalog, lease: lease);

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
            cache?.deviceId != after?.deviceId ||
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
      _write((db, guard) => _start(exercises, guard, plan: plan));

  /// Resolve UUID again inside the guarded transaction. No generator fallback
  /// or silent dropping of unavailable catalog exercises.
  Future<void> startSaved(
    String syncId,
    List<Exercise> catalog, {
    TemplateLease? lease,
  }) => _write((db, guard) async {
    if (lease != null) await _checkLease(db, lease);
    final saved = await ref.read(plannerRepositoryProvider).getBySyncId(syncId);
    if (saved == null || saved.isUnavailable) {
      throw StateError('Plan jest niedostępny.');
    }
    final byId = {for (final e in catalog) e.id: e};
    if (saved.cwiczeniaIds.any((id) => !byId.containsKey(id))) {
      throw StateError('Co najmniej jedno ćwiczenie planu jest niedostępne.');
    }
    await _start(
      [for (final id in saved.cwiczeniaIds) byId[id]!],
      guard,
      plan: saved.structure,
    );
  });

  Future<void> _start(
    List<Exercise> exercises,
    bool Function() guard, {
    StructuredPlan? plan,
  }) async {
    if (!guard()) throw StateError('Konto zmieniło się. Start anulowany.');
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
  }
}

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PlannerRepository(db);
});

final savedPlansProvider = StreamProvider<List<SavedPlan>>((ref) {
  final repo = ref.watch(plannerRepositoryProvider);
  return repo.watchAll();
});
