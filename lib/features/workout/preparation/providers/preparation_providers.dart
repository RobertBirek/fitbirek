import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../exercises/domain/exercise_filter_engine.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../planner/providers/planner_providers.dart';
import '../../../schedule/data/schedule_repository.dart';
import '../../../schedule/domain/activity_schedule.dart';
import '../../../schedule/domain/weekly_schedule.dart';
import '../../../schedule/providers/schedule_providers.dart';
import '../../domain/fixed_load_progression.dart';
import '../../providers/workout_providers.dart';
import '../domain/equipment_inventory.dart';
import '../domain/workout_preparation.dart';

final preparationEquipmentProvider = Provider<EquipmentInventory>(
  (ref) => EquipmentInventory.ownerConfirmed(),
);
final workoutPreparationWorkflowProvider = Provider<WorkoutPreparationWorkflow>(
  (ref) => WorkoutPreparationWorkflow(ref),
);
typedef PreparationHistoryKey = ({
  PreparationSnapshot snapshot,
  String exerciseId,
  String? side,
  String? variantId,
});
final preparationHistoryProvider = FutureProvider.autoDispose
    .family<List<ProgressionPerformance>, PreparationHistoryKey>((ref, key) {
      return ref
          .read(workoutPreparationWorkflowProvider)
          .readHistory(
            key.snapshot,
            key.exerciseId,
            side: key.side,
            variantId: key.variantId,
          );
    });

/// A preview is a read-only account-bound lease, not a partially started session.
class WorkoutPreparationWorkflow {
  WorkoutPreparationWorkflow(this.ref) {
    ref.onDispose(() => _alive = false);
  }
  final Ref ref;
  bool _alive = true, _busy = false;

  Future<void> _binding(TemplateLease lease) async {
    final authority = ref.read(cachedAuthWriteAuthorityProvider);
    void guard() {
      final auth = authority.state;
      if (!_alive ||
          authority.epoch != lease.epoch ||
          lease.accountId == null ||
          lease.accountId!.isEmpty ||
          (auth != null &&
              (!auth.isSignedIn || auth.accountId != lease.accountId))) {
        throw StateError('Konto zmieniło się. Otwórz przygotowanie ponownie.');
      }
    }

    guard();
    final state = await ref.read(appDatabaseProvider).syncDao.readState();
    guard();
    if (state?.accountId != lease.accountId ||
        state?.deviceId != lease.deviceId ||
        state?.offlineAccess != true ||
        lease.offlineAccess != true) {
      throw StateError('Brak lokalnego dostępu do tego konta.');
    }
  }

  Future<PreparationSnapshot> open({
    String? planSyncId,
    ScheduleOccurrence? occurrence,
  }) async {
    final authority = ref.read(cachedAuthWriteAuthorityProvider);
    final epoch = authority.epoch;
    if (occurrence != null &&
        (occurrence.activityType != ActivityType.fitbirek ||
            occurrence.planSyncId != planSyncId)) {
      throw StateError('To nie jest termin tego treningu FitBirek.');
    }
    final planner = ref.read(plannerWorkflowProvider);
    final lease = await planner.openTemplate(syncId: planSyncId);
    if (epoch != authority.epoch) throw StateError('Konto zmieniło się.');
    await _binding(lease);
    final db = ref.read(appDatabaseProvider);
    final profile = await db.userProfileDao.watchProfileOnce();
    if (profile == null || profile.deletedAtUtc != null) {
      throw StateError('Profil treningowy jest niedostępny.');
    }
    final rawEquipment = jsonDecode(profile.dostepnySprzet);
    if (rawEquipment is! List || rawEquipment.any((e) => e is! String)) {
      throw const FormatException('Nieprawidłowa lista dostępnego sprzętu.');
    }
    final saved = planSyncId == null
        ? null
        : await ref.read(plannerRepositoryProvider).getBySyncId(planSyncId);
    if (planSyncId != null && (saved == null || saved.isUnavailable)) {
      throw StateError('Szablon jest niedostępny.');
    }
    final catalog = await ref.read(allExercisesProvider.future);
    final metadata = await ref.read(exerciseCatalogMetadataProvider.future);
    final snapshot = PreparationSnapshot(
      lease: lease,
      savedPlan: saved,
      profileSyncId: profile.syncId,
      catalog: catalog,
      availableEquipment: rawEquipment.cast<String>(),
      engine: ExerciseFilterEngine(metadata),
      occurrence: occurrence,
    );
    for (final id in snapshot.exerciseIds) {
      snapshot.exercise(id);
    }
    await _validate(snapshot);
    return snapshot;
  }

  Future<void> _validate(
    PreparationSnapshot snapshot, {
    Iterable<String> additionalExerciseIds = const [],
  }) async {
    await _binding(snapshot.lease);
    final catalog = await ref.read(allExercisesProvider.future);
    final byId = {for (final exercise in catalog) exercise.id: exercise};
    for (final id in {...snapshot.exerciseIds, ...additionalExerciseIds}) {
      if (byId[id] != snapshot.exercise(id)) {
        throw StateError(
          'Katalog ćwiczeń zmienił się. Otwórz przygotowanie ponownie.',
        );
      }
    }
    // Cards read histories concurrently. Lease validation here is read-only and
    // must not reserve PlannerWorkflow's exclusive mutation slot for each card.
    final baseline = snapshot.lease.baseline;
    if (baseline != null) {
      await ref.read(plannerRepositoryProvider).checkTemplate(baseline);
    }
    final db = ref.read(appDatabaseProvider);
    final profile = await db.userProfileDao.watchProfileOnce();
    if (profile == null ||
        profile.deletedAtUtc != null ||
        profile.syncId != snapshot.profileSyncId ||
        jsonEncode(jsonDecode(profile.dostepnySprzet)) !=
            jsonEncode(snapshot.availableEquipment)) {
      throw StateError(
        'Profil lub sprzęt zmienił się. Otwórz przygotowanie ponownie.',
      );
    }
    final chosen = snapshot.occurrence;
    if (chosen != null) {
      final schedule = await ref
          .read(scheduleRepositoryProvider)
          .load(snapshot.lease.accountId!);
      await assertScheduleWritable(db, profile.syncId);
      final current = schedule
          .between(chosen.date, chosen.date)
          .where((o) => o.id == chosen.id)
          .firstOrNull;
      if (current == null ||
          current.isCompleted ||
          current.mutationBaseline != snapshot.occurrenceBaseline) {
        throw StateError('Termin zmienił się lub został już zaliczony.');
      }
    }
    await _binding(snapshot.lease);
  }

  Future<List<ProgressionPerformance>> readHistory(
    PreparationSnapshot snapshot,
    String exerciseId, {
    required String? side,
    required String? variantId,
  }) async {
    await _validate(snapshot, additionalExerciseIds: [exerciseId]);
    final result = await ref
        .read(workoutRepositoryProvider)
        .getPreparationHistory(exerciseId, side: side, variantId: variantId);
    await _binding(snapshot.lease);
    return result;
  }

  Future<void> start(
    PreparationDraft draft, {
    required bool Function() isCurrent,
  }) async {
    if (_busy) throw StateError('Rozpoczęcie treningu już trwa.');
    _busy = true;
    String? started;
    final notifier = ref.read(activeWorkoutProvider.notifier);
    try {
      final snapshot = draft.snapshot;
      await ref.read(appDatabaseProvider).transaction(() async {
        await _validate(
          snapshot,
          additionalExerciseIds: draft.sessionPlan?.exerciseIds ?? const [],
        );
        final plan = draft.sessionPlan;
        final sandbagGrams = ref
            .read(preparationEquipmentProvider)
            .sandbagGrams;
        if (plan != null && sandbagGrams != null) {
          for (var i = 0; i < plan.blocks.length; i++) {
            final block = plan.blocks[i];
            final exercise = snapshot.exercise(block.exerciseId);
            final equipment =
                snapshot.engine.matchingEquipment(
                  exercise,
                  snapshot.availableEquipment,
                ) ??
                exercise.sprzet;
            final weight = draft.targets.containsKey(i)
                ? draft.targets[i]!.weightKg
                : block.prescription.weightKg;
            if (equipment.contains('Sandbag') &&
                weight != null &&
                weight != sandbagGrams / 1000) {
              throw StateError(
                'Sandbag ma potwierdzone ${sandbagGrams / 1000} kg. Wybierz zgodny cel jawnie lub zmień ćwiczenie.',
              );
            }
          }
        }
        if (!isCurrent()) throw StateError('Przygotowanie zostało zamknięte.');
        await ref
            .read(plannerWorkflowProvider)
            .startPrepared(
              snapshot.lease,
              snapshot.catalog,
              sessionPlan: draft.sessionPlan,
              templatePlan: draft.templatePlan,
              targets: draft.targets,
              isCurrent: () => _alive && isCurrent(),
            );
        started = ref.read(activeWorkoutProvider).sessionSyncId;
        await _binding(snapshot.lease);
        if (!isCurrent()) throw StateError('Start anulowany.');
      });
    } catch (_) {
      if (started != null &&
          ref.read(activeWorkoutProvider).sessionSyncId == started) {
        notifier.discardSession();
      }
      rethrow;
    } finally {
      _busy = false;
    }
    // The persistent draft queue must run outside the caller's transaction.
    await notifier.flushDraft();
  }
}
