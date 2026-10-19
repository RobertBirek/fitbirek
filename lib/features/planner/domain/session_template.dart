import '../../../core/database/app_database.dart';
import '../../exercises/domain/exercise_catalog_metadata.dart';
import '../../exercises/domain/exercise_filter_engine.dart';
import 'structured_plan.dart';

/// No writes. Refuses any lossy collapse of variants, sides or unequal doses.
StructuredPlan templateFromSets(
  List<SetLogData> sets,
  ExerciseCatalogMetadata metadata,
) {
  final groups = <String, List<SetLogData>>{};
  for (final s in sets.where((s) => s.deletedAtUtc == null)) {
    if (s.side != null || s.variantId != null || s.variantLabel != null) {
      throw const FormatException(
        'Szablon ma jeden cel na ćwiczenie i nie przechowuje stron ani wariantów. To wykonanie zawiera takie dane. Ułóż szablon ręcznie; historii nie zmieniono.',
      );
    }
    groups.putIfAbsent(s.cwiczenieId, () => []).add(s);
  }
  if (groups.isEmpty) {
    throw const FormatException('Brak potwierdzonych serii do skopiowania.');
  }
  final blocks = <PlanBlock>[];
  for (final entry in groups.entries) {
    final m = metadata.entryFor(entry.key);
    if (m == null || !{'reps', 'time'}.contains(m.tracking)) {
      throw FormatException(
        'Nieobsługiwany sposób śledzenia: ${entry.key}. Niczego nie pominięto.',
      );
    }
    final first = entry.value.first;
    final reps = m.tracking == 'reps';
    if (entry.value.any(
          (s) =>
              s.powtorzenia != first.powtorzenia ||
              s.czasSekund != first.czasSekund ||
              s.ciezarKg != first.ciezarKg,
        ) ||
        (reps
            ? (first.powtorzenia == null ||
                  first.powtorzenia! <= 0 ||
                  first.czasSekund != null)
            : (first.czasSekund == null ||
                  first.czasSekund! <= 0 ||
                  first.powtorzenia != null)) ||
        (first.ciezarKg != null &&
            (!first.ciezarKg!.isFinite || first.ciezarKg! < 0))) {
      throw FormatException(
        '${entry.key}: różne lub nieprawidłowe cele serii nie mieszczą się w jednym celu szablonu. Ułóż szablon ręcznie; niczego nie pominięto.',
      );
    }
    blocks.add(
      PlanBlock(
        exerciseId: entry.key,
        section: PlanSection.main,
        prescription: PlanPrescription(
          tracking: m.tracking,
          sets: entry.value.length,
          reps: reps ? first.powtorzenia : null,
          workSeconds: reps
              ? first.powtorzenia! * 3 * (m.unilateral ? 2 : 1)
              : first.czasSekund!,
          restSeconds: 0,
          transitionSeconds: 15,
          weightKg: first.ciezarKg,
        ),
      ),
    );
  }
  final seconds = blocks.fold<int>(
    0,
    (n, b) => n + b.prescription.totalSeconds,
  );
  if (seconds > 5400) {
    throw const FormatException(
      'Kopia przekracza limit 90 min. Ułóż krótsze szablony ręcznie.',
    );
  }
  return StructuredPlan(
    criteria: const ExerciseFilters(),
    budgetSeconds: seconds < 300 ? 300 : ((seconds + 59) ~/ 60) * 60,
    blocks: blocks,
    warnings: const [
      'Kopia potwierdzonych serii. Przerw nie mierzono — ustaw je ręcznie (początkowo 0 s). Czas ESTYMOWANY, nie czas wykonania.',
    ],
  );
}
