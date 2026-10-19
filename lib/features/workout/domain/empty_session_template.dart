import '../../../core/models/exercise.dart';
import '../../exercises/domain/exercise_catalog_metadata.dart';
import '../../exercises/domain/exercise_filter_engine.dart';
import '../../planner/domain/structured_plan.dart';
import 'workout_repeat.dart';

/// A proposal, never execution. Repeat targets are copied only losslessly.
/// New selected exercises have explicit editable defaults, not inferred work.
StructuredPlan templateFromSelection(
  List<Exercise> selected,
  ExerciseCatalogMetadata metadata, {
  WorkoutRepeat? repeat,
}) {
  if (selected.isEmpty) throw const FormatException('Wybierz ćwiczenia.');
  final ids = selected.map((e) => e.id).toSet();
  if (ids.length != selected.length ||
      (repeat?.targets.any((t) => !ids.contains(t.exerciseId)) ?? false)) {
    throw const FormatException(
      'Nie można pominąć ani powielić ćwiczenia w kopii.',
    );
  }
  final blocks = <PlanBlock>[];
  for (final e in selected) {
    final m = metadata.entryFor(e.id);
    if (m == null || !{'reps', 'time'}.contains(m.tracking)) {
      throw const FormatException('Nieobsługiwany sposób śledzenia.');
    }
    final targets =
        repeat?.targets.where((t) => t.exerciseId == e.id).toList() ?? [];
    final first = targets.firstOrNull;
    if (targets.any(
          (t) =>
              t.side != null ||
              t.variantId != null ||
              t.variantLabel != null ||
              t.reps != first?.reps ||
              t.seconds != first?.seconds ||
              t.weightKg != first?.weightKg,
        ) ||
        (first != null &&
            (m.tracking == 'reps'
                ? first.reps == null || first.seconds != null
                : first.seconds == null || first.reps != null))) {
      throw const FormatException(
        'Różne cele, strony lub warianty nie mieszczą się w jednym celu szablonu.',
      );
    }
    final reps = m.tracking == 'reps' ? first?.reps ?? 10 : null;
    if (reps != null && reps > PlanPrescription.maxReps) {
      throw const FormatException('Cel powtórzeń przekracza limit szablonu.');
    }
    blocks.add(
      PlanBlock(
        exerciseId: e.id,
        section: PlanSection.main,
        prescription: PlanPrescription(
          tracking: m.tracking,
          sets: targets.isEmpty ? 1 : targets.length,
          reps: reps,
          workSeconds: reps == null
              ? first?.seconds ?? 30
              : reps * 3 * (m.unilateral ? 2 : 1),
          restSeconds: 0,
          transitionSeconds: 0,
          weightKg: first?.weightKg,
        ),
      ),
    );
  }
  final seconds = blocks.fold<int>(
    0,
    (n, b) => n + b.prescription.totalSeconds,
  );
  if (seconds > 5400) throw const FormatException('Kopia przekracza 90 minut.');
  return StructuredPlan(
    criteria: const ExerciseFilters(),
    budgetSeconds: seconds < 300 ? 300 : ((seconds + 59) ~/ 60) * 60,
    blocks: blocks,
    warnings: const [
      'Kopia wyboru i celów, nie wykonania. Nowe ćwiczenia: wstępnie 1 seria, 10 powtórzeń lub 30 s. Dostosuj cele przed zapisem. Przerw nie mierzono — początkowo 0 s. Czas ESTYMOWANY.',
    ],
  );
}
