import '../../../../core/models/exercise.dart';
import '../../../exercises/domain/exercise_filter_engine.dart';
import '../../../planner/data/planner_repository.dart';
import '../../../planner/domain/structured_plan.dart';
import '../../../planner/providers/planner_providers.dart' show TemplateLease;
import '../../../schedule/domain/weekly_schedule.dart';
import 'equipment_inventory.dart';

enum ReplacementScope { sessionOnly, templateAndSession }

class PreparedTarget {
  const PreparedTarget({
    this.weightKg,
    this.reps,
    this.side,
    this.variantId,
    this.implement,
    this.quantity = 2,
  });
  final double? weightKg;
  final int? reps;
  final String? side, variantId;
  final LoadImplement? implement;
  final int quantity;

  void validate() {
    if ((weightKg != null && (!weightKg!.isFinite || weightKg! < 0)) ||
        (reps != null && (reps! < 1 || reps! > 1800)) ||
        !const {null, 'both', 'left', 'right'}.contains(side) ||
        quantity < 1 ||
        quantity > 2) {
      throw const FormatException('Nieprawidłowy cel przygotowania.');
    }
  }

  Map<String, Object?> toDraftFields() => {
    'weight': weightKg == null ? '' : '$weightKg',
    if (reps != null) 'reps': '$reps',
    'side': side,
    'variantId': variantId,
    'variantLabel': null,
  };
}

/// Detached read-only baseline, captured before the user edits the modal.
class PreparationSnapshot {
  PreparationSnapshot({
    required this.lease,
    required SavedPlan? savedPlan,
    required this.profileSyncId,
    required List<Exercise> catalog,
    required List<String> availableEquipment,
    required this.engine,
    this.occurrence,
  }) : savedPlan = savedPlan == null
           ? null
           : SavedPlan(
               id: savedPlan.id,
               nazwa: savedPlan.nazwa,
               cwiczeniaIds: List.unmodifiable(savedPlan.cwiczeniaIds),
               cel: savedPlan.cel,
               dataUtworzenia: savedPlan.dataUtworzenia,
               syncId: savedPlan.syncId,
               structure: savedPlan.structure,
               structureError: savedPlan.structureError,
               rawStructureJson: savedPlan.rawStructureJson,
             ),
       catalog = List.unmodifiable(catalog),
       availableEquipment = List.unmodifiable(availableEquipment),
       occurrenceBaseline = occurrence?.mutationBaseline;

  final TemplateLease lease;
  final SavedPlan? savedPlan;
  final String profileSyncId;
  final List<Exercise> catalog;
  final List<String> availableEquipment;
  final ExerciseFilterEngine engine;
  final ScheduleOccurrence? occurrence;
  final String? occurrenceBaseline;
  String get name => savedPlan?.nazwa ?? occurrence?.name ?? 'Trening swobodny';
  StructuredPlan? get plan => savedPlan?.structure;
  List<String> get exerciseIds => savedPlan?.cwiczeniaIds ?? const [];

  Exercise exercise(String id) => catalog.firstWhere(
    (e) => e.id == id,
    orElse: () => throw StateError('Ćwiczenie jest niedostępne w katalogu.'),
  );

  List<String>? matchingEquipment(String id) =>
      engine.matchingEquipment(exercise(id), availableEquipment);

  /// Canonical requirements remain visible if no complete set matches. This
  /// informational fallback is not evidence that the profile supports a move.
  List<String> equipmentFor(String id) =>
      matchingEquipment(id) ?? exercise(id).sprzet;

  String? defaultSide(String id) =>
      engine.metadata.entryFor(id)?.unilateral == true ? 'both' : null;
}

class _Replacement {
  const _Replacement(this.exerciseId, this.scope);
  final String exerciseId;
  final ReplacementScope scope;
}

/// Changes are local values only. Derive session and template independently so
/// a session-only swap can never leak into the saved template through copying.
class PreparationDraft {
  PreparationDraft(this.snapshot)
    : _replacements = const {},
      targets = const {};
  PreparationDraft._(
    this.snapshot,
    Map<int, _Replacement> replacements,
    Map<int, PreparedTarget> targets,
  ) : _replacements = Map.unmodifiable(replacements),
      targets = Map.unmodifiable(targets);

  final PreparationSnapshot snapshot;
  final Map<int, _Replacement> _replacements;
  final Map<int, PreparedTarget> targets;

  StructuredPlan? get sessionPlan => _build(false);
  StructuredPlan? get templatePlan =>
      _replacements.values.any(
        (r) => r.scope == ReplacementScope.templateAndSession,
      )
      ? _build(true)
      : null;

  String exerciseIdAt(int index) =>
      _replacements[index]?.exerciseId ?? snapshot.exerciseIds[index];
  ReplacementScope? scopeAt(int index) => _replacements[index]?.scope;

  PreparationDraft setTarget(int index, PreparedTarget target) {
    _checkIndex(index);
    target.validate();
    if (target.variantId != null ||
        target.side != snapshot.defaultSide(exerciseIdAt(index))) {
      throw StateError(
        'Cel musi dotyczyć tej samej strony i bazowego wariantu.',
      );
    }
    return PreparationDraft._(snapshot, _replacements, {
      ...targets,
      index: target,
    });
  }

  List<Exercise> candidatesFor(int index) {
    _checkIndex(index);
    final plan = snapshot.plan!;
    final source = snapshot.exercise(exerciseIdAt(index));
    final tracking = plan.blocks[index].prescription.tracking;
    final pool = StructuredPlanGenerator.candidates(
      allExercises: snapshot.catalog,
      engine: snapshot.engine,
      criteria: plan.criteria,
      equipment: snapshot.availableEquipment,
      level: plan.level,
    );
    return pool.where((e) {
      if (e.id == source.id ||
          snapshot.engine.metadata.entryFor(e.id)?.tracking != tracking ||
          StructuredPlanGenerator.sectionFor(e) != plan.blocks[index].section) {
        return false;
      }
      final samePattern =
          source.wzorzecRuchu.trim().isNotEmpty &&
          ExerciseFilterEngine.fold(source.wzorzecRuchu) ==
              ExerciseFilterEngine.fold(e.wzorzecRuchu);
      final sameMuscle =
          source.partiaGlowna.trim().isNotEmpty &&
          ExerciseFilterEngine.fold(source.partiaGlowna) ==
              ExerciseFilterEngine.fold(e.partiaGlowna);
      return samePattern || sameMuscle;
    }).toList();
  }

  PreparationDraft replace(
    int index,
    String exerciseId,
    ReplacementScope scope,
  ) {
    _checkIndex(index);
    final changesExercise = exerciseIdAt(index) != exerciseId;
    if (changesExercise &&
        !candidatesFor(index).any((e) => e.id == exerciseId)) {
      throw StateError('Zamiennik nie spełnia warunków tego ćwiczenia.');
    }
    final nextTargets = {...targets};
    if (changesExercise) nextTargets.remove(index);
    final replacements = {..._replacements};
    if (exerciseId == snapshot.plan!.blocks[index].exerciseId) {
      replacements.remove(index);
    } else {
      replacements[index] = _Replacement(exerciseId, scope);
    }
    final next = PreparationDraft._(snapshot, replacements, nextTargets);
    next.sessionPlan;
    next.templatePlan;
    return next;
  }

  void _checkIndex(int index) {
    if (snapshot.plan == null ||
        index < 0 ||
        index >= snapshot.plan!.blocks.length) {
      throw StateError('Ten plan nie zawiera edytowalnych celów.');
    }
  }

  StructuredPlan? _build(bool forTemplate) {
    final plan = snapshot.plan;
    if (plan == null) return null;
    final blocks = <PlanBlock>[];
    for (var i = 0; i < plan.blocks.length; i++) {
      final original = plan.blocks[i];
      final replacement = _replacements[i];
      if (replacement == null ||
          (forTemplate && replacement.scope == ReplacementScope.sessionOnly)) {
        blocks.add(original);
      } else {
        final p = original.prescription;
        blocks.add(
          PlanBlock(
            exerciseId: replacement.exerciseId,
            section: original.section,
            prescription: PlanPrescription(
              tracking: p.tracking,
              sets: p.sets,
              reps: p.reps,
              workSeconds: p.workSeconds,
              restSeconds: p.restSeconds,
              transitionSeconds: p.transitionSeconds,
            ),
          ),
        );
      }
    }
    if (blocks.map((b) => b.exerciseId).toSet().length != blocks.length) {
      throw StateError(
        'Ta zamiana powieliłaby ćwiczenie w treningu lub szablonie.',
      );
    }
    final result = StructuredPlan(
      criteria: plan.criteria,
      budgetSeconds: plan.budgetSeconds,
      level: plan.level,
      equipment: plan.equipment,
      warnings: plan.warnings,
      blocks: blocks,
    );
    StructuredPlan.validateJson(
      result.toJson(),
      exerciseIds: result.exerciseIds,
    );
    return result;
  }
}
