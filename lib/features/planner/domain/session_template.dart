import '../../../core/database/app_database.dart';
import '../../../core/models/set_role.dart';
import 'package:uuid/uuid.dart';
import '../../exercises/domain/exercise_catalog_metadata.dart';
import '../../exercises/domain/exercise_filter_engine.dart';
import 'structured_plan.dart';
import 'set_prescription.dart';

/// No writes. Heterogeneous doses become ordered targets, never an average.
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
  final perSet = groups.values.any(
    (rows) => rows.any(
      (s) =>
          s.setRole != null ||
          s.powtorzenia != rows.first.powtorzenia ||
          s.czasSekund != rows.first.czasSekund ||
          s.ciezarKg != rows.first.ciezarKg,
    ),
  );
  for (final entry in groups.entries) {
    final m = metadata.entryFor(entry.key);
    if (m == null || !{'reps', 'time'}.contains(m.tracking)) {
      throw FormatException(
        'Nieobsługiwany sposób śledzenia: ${entry.key}. Niczego nie pominięto.',
      );
    }
    final first = entry.value.first;
    final reps = m.tracking == 'reps';
    for (final s in entry.value) {
      SetRole.validate(s.setRole);
      if ((reps
              ? (s.powtorzenia == null ||
                    s.powtorzenia! < 1 ||
                    s.powtorzenia! > 1800 ||
                    s.czasSekund != null)
              : (s.czasSekund == null ||
                    s.czasSekund! < 1 ||
                    s.czasSekund! > 5400 ||
                    s.powtorzenia != null)) ||
          (s.ciezarKg != null && (!s.ciezarKg!.isFinite || s.ciezarKg! < 0)) ||
          (perSet && m.unilateral)) {
        throw FormatException(
          '${entry.key}: nieprawidłowe lub niejednoznaczne cele; niczego nie pominięto.',
        );
      }
    }
    blocks.add(
      PlanBlock(
        exerciseId: entry.key,
        section: PlanSection.main,
        prescription: perSet
            ? PlanPrescription.perSet(
                tracking: m.tracking,
                transitionSeconds: 15,
                setTargets: [
                  for (final s in entry.value)
                    SetPrescription(
                      targetId: const Uuid().v5(
                        Namespace.url.value,
                        'fitbirek:set-target:${s.syncId}',
                      ),
                      setRole: s.setRole ?? SetRole.working,
                      reps: s.powtorzenia,
                      seconds: s.czasSekund,
                      weightKg: s.ciezarKg,
                      workSeconds: reps ? s.powtorzenia! * 3 : s.czasSekund!,
                      restSeconds: 0,
                    ),
                ],
              )
            : PlanPrescription(
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
    schemaVersion: perSet ? 2 : 1,
    criteria: const ExerciseFilters(),
    budgetSeconds: seconds < 300 ? 300 : ((seconds + 59) ~/ 60) * 60,
    blocks: blocks,
    warnings: const [
      'Kopia potwierdzonych serii. Przerw nie mierzono — ustaw je ręcznie (początkowo 0 s). Czas ESTYMOWANY, nie czas wykonania.',
    ],
  );
}
