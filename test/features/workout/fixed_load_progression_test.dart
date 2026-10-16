import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/domain/fixed_load_progression.dart';

ProgressionPerformance performance(
  int session, {
  int reps = 8,
  int? rpe = 7,
  double? kg = 20,
  String? side = 'left',
  String exercise = 'sandbag',
}) => ProgressionPerformance(
  sessionId: session,
  exerciseId: exercise,
  side: side,
  endedAt: DateTime.utc(2026, 10, session),
  weightKg: kg,
  reps: reps,
  rpe: rpe,
);

void main() {
  FixedLoadSuggestion suggest(
    List<ProgressionPerformance> history, {
    String range = '3×8–12',
    double? kg = 20,
    String? side = 'left',
    bool weighted = true,
    String tracking = 'reps',
  }) => proposeFixedLoad(
    exerciseId: 'sandbag',
    side: side,
    prescription: range,
    tracking: tracking,
    usesWeight: weighted,
    currentWeightKg: kg,
    history: history,
  );

  test('two completed distinct sessions give one rep, never more kg', () {
    final result = suggest([performance(1), performance(2)]);
    expect(result.target, 9);
    expect(result.weightKg, 20);
    expect(result.evidence, hasLength(2));
  });
  test('two easy sets in one session are insufficient', () {
    expect(suggest([performance(1), performance(1)]).target, isNull);
  });
  test(
    'increase is relative to the latest session, not an older lower result',
    () {
      expect(suggest([performance(1), performance(2, reps: 10)]).target, 11);
    },
  );
  test('unknown side and overflowing ranges fail closed without throwing', () {
    expect(
      suggest([
        performance(1, side: 'invalid'),
        performance(2, side: 'invalid'),
      ], side: 'invalid').target,
      isNull,
    );
    expect(
      suggest(
        [performance(1), performance(2)],
        range:
            '3x999999999999999999999999999999-9999999999999999999999999999999',
      ).target,
      isNull,
    );
  });
  for (final side in [null, 'both', 'right']) {
    test('never combines left with $side', () {
      expect(
        suggest([performance(1), performance(2, side: side)]).target,
        isNull,
      );
    });
  }
  test('exact exercise id only', () {
    expect(
      suggest([performance(1), performance(2, exercise: 'other')]).target,
      isNull,
    );
  });
  for (final kg in <double?>[null, 0, -1, 15, 25, double.nan]) {
    test('current load $kg cannot borrow a 20kg target', () {
      expect(suggest([performance(1), performance(2)], kg: kg).target, isNull);
    });
  }
  test('latest different load cannot be bypassed using older easy sets', () {
    expect(
      suggest([performance(1), performance(2), performance(3, kg: 15)]).target,
      isNull,
    );
  });
  for (final rpe in <int?>[null, 0, 11]) {
    test('missing or invalid RPE $rpe gives no target', () {
      expect(
        suggest([performance(1), performance(2, rpe: rpe)]).target,
        isNull,
      );
    });
  }
  test('RPE8 holds, RPE9 regresses, mixed effort never increases', () {
    expect(suggest([performance(1), performance(2, rpe: 8)]).target, 8);
    expect(
      suggest([
        performance(1, reps: 10),
        performance(2, reps: 10, rpe: 9),
      ]).target,
      9,
    );
    expect(suggest([performance(1, rpe: 10), performance(2)]).target, 8);
  });
  test('hard set in same session cannot be hidden by easy last set', () {
    expect(
      suggest([
        performance(1),
        performance(2, reps: 10, rpe: 10),
        performance(2),
      ]).target,
      8,
    );
  });
  test(
    'upper bound is held, not interpreted as weight or variant increase',
    () {
      final result = suggest([
        performance(1, reps: 12),
        performance(2, reps: 12),
      ]);
      expect(result.target, 12);
      expect(result.reason, contains('górną'));
    },
  );
  for (final range in [
    '3x8',
    '3x12-8',
    '3x0-12',
    '3x8-12 lub do bólu',
    '',
    '3x8-12-15',
  ]) {
    test('fixed or malformed prescription $range never invents progress', () {
      final result = suggest([performance(1), performance(2)], range: range);
      expect(result.target, range == '3x8' ? 8 : isNull);
    });
  }
  test('out of range and zero results are not a progression basis', () {
    expect(suggest([performance(1, reps: 7), performance(2)]).target, isNull);
    expect(suggest([performance(1, reps: 0), performance(2)]).target, isNull);
  });
  test('bodyweight stays bodyweight, without invented load or 1RM', () {
    final result = suggest(
      [performance(1, kg: null), performance(2, kg: null)],
      weighted: false,
      kg: null,
    );
    expect(result.target, 9);
    expect(result.weightKg, isNull);
  });
  test(
    'rounds and time without comparable configuration are maintain only',
    () {
      for (final tracking in ['rounds', 'time']) {
        expect(
          suggest(
            [performance(1), performance(2)],
            tracking: tracking,
            range: '3x20-40 s',
          ).target,
          isNull,
        );
      }
    },
  );
}
