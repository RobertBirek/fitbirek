import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/planner/domain/session_template.dart';
import '../exercises/catalog_filter_test.dart' show metadata;

SetLogData row(
  int i, {
  String exercise = 'b',
  int? reps = 10,
  int? seconds,
  String? variant,
  String? side,
  double? kg = 12.5,
  bool deleted = false,
}) => SetLogData(
  syncId: '$i',
  syncVersion: 0,
  updatedAtUtc: DateTime(2026),
  id: i,
  sesjaId: 1,
  cwiczenieId: exercise,
  nazwaCwiczeniaPl: exercise,
  numerSerii: i,
  powtorzenia: reps,
  czasSekund: seconds,
  ciezarKg: kg,
  variantId: variant,
  side: side,
  timestamp: DateTime(2026),
  deletedAtUtc: deleted ? DateTime(2026) : null,
);

void main() {
  test(
    'heterogeneous doses and explicit roles copy to one ordered v2 list',
    () {
      final plan = templateFromSets([
        row(
          1,
        ).copyWith(setRole: const Value('warmup'), ciezarKg: const Value(8)),
        row(2, reps: 6, kg: 15).copyWith(setRole: const Value('working')),
      ], metadata);
      expect(plan.schemaVersion, 2);
      final targets = plan.blocks.single.prescription.setTargets;
      expect(targets.map((t) => t.setRole), ['warmup', 'working']);
      expect(targets.map((t) => t.reps), [10, 6]);
      expect(targets.map((t) => t.weightKg), [8, 15]);
      expect(targets.map((t) => t.targetId).toSet(), hasLength(2));
      expect(() => targets.clear(), throwsUnsupportedError);
    },
  );
  test(
    'actual uniform live groups copy exact metric and kg, no fabricated rest',
    () {
      final plan = templateFromSets([
        row(1),
        row(2),
        row(3, deleted: true),
        row(4, exercise: 'a', reps: null, seconds: 40, kg: null),
      ], metadata);
      expect(plan.exerciseIds, ['b', 'a']);
      final p = plan.blocks.first.prescription;
      expect(p.sets, 2);
      expect(p.reps, 10);
      expect(p.weightKg, 12.5);
      expect(p.restSeconds, 0);
      expect(plan.blocks.last.prescription.workSeconds, 40);
      expect(plan.warnings.single, contains('Przerw nie mierzono'));
    },
  );
  test(
    'unsupported, mixed variants/sides/metrics/targets fail entire copy explicitly',
    () {
      for (final sets in <List<SetLogData>>[
        [],
        [row(1, variant: 'variant')],
        [row(1, side: 'left')],
        [row(1, reps: 0)],
        [row(1, reps: null, seconds: 40)],
        [row(1, seconds: 40)],
        [row(1, exercise: 'missing')],
        [row(1, kg: double.infinity)],
        [row(1, reps: 2000)],
      ]) {
        expect(() => templateFromSets(sets, metadata), throwsFormatException);
      }
    },
  );
}
