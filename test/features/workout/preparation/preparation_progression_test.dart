import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/domain/fixed_load_progression.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/equipment_inventory.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/preparation_progression.dart';

List<ProgressionPerformance> session(
  int id, {
  int count = 3,
  int reps = 12,
  int? rpe = 7,
  double? kg = 7.25,
  String? side = 'both',
  String? variantId,
  String exerciseId = 'cw001',
}) => List.generate(
  count,
  (_) => ProgressionPerformance(
    sessionId: id,
    exerciseId: exerciseId,
    endedAt: DateTime.utc(2026, 10, id),
    side: side,
    variantId: variantId,
    weightKg: kg,
    reps: reps,
    rpe: rpe,
  ),
);

void main() {
  PreparationLoadSuggestion suggest(
    List<ProgressionPerformance> history, {
    String prescription = '3×8–12',
    String tracking = 'reps',
    bool confirmed = true,
    bool usesWeight = true,
    LoadImplement? implement = LoadImplement.smallDumbbell,
    EquipmentInventory? inventory,
    int quantity = 2,
  }) => proposePreparationLoad(
    exerciseId: 'cw001',
    side: 'both',
    variantId: null,
    prescription: prescription,
    tracking: tracking,
    usesWeight: usesWeight,
    implement: implement,
    quantity: quantity,
    historyUnitConfirmed: confirmed,
    history: history,
    inventory: inventory ?? EquipmentInventory.ownerConfirmed(),
  );

  test('first training has no fabricated last load or progression', () {
    final result = suggest([]);
    expect(result.last, isNull);
    expect(result.targetWeightKg, isNull);
    expect(result.targetReps, isNull);
    expect(result.evidence, isEmpty);
  });

  test(
    'two complete easy upper-bound sessions propose achievable7750 and8 reps',
    () {
      final result = suggest([...session(2), ...session(1)]);
      expect(result.last?.weightKg, 7.25);
      expect(result.targetWeightKg, 7.75);
      expect(result.targetReps, 8);
      expect(result.evidence.map((r) => r.sessionId).toList(), [2, 1]);
      expect(result.reason, isNotEmpty);
    },
  );

  test('one session cannot substitute for two different workouts', () {
    final result = suggest(session(1, count: 6));
    expect(result.last?.weightKg, 7.25);
    expect(result.targetWeightKg, isNull);
    expect(result.targetReps, isNull);
  });

  test('missing planned sets cannot earn an increase', () {
    final result = suggest([...session(2, count: 2), ...session(1)]);
    expect(result.targetWeightKg, isNull);
    expect(result.targetReps, isNull);
  });

  test('missing RPE cannot earn an increase', () {
    final result = suggest([...session(2, rpe: null), ...session(1)]);
    expect(result.targetWeightKg, isNull);
    expect(result.targetReps, isNull);
  });

  test(
    'latest different weight cannot be skipped in favor of older easy sessions',
    () {
      final result = suggest([
        ...session(3, kg: 8.25),
        ...session(2),
        ...session(1),
      ]);
      expect(result.last?.weightKg, 8.25);
      expect(result.targetWeightKg, isNull);
      expect(result.targetReps, isNull);
    },
  );

  test('last is last ordered actual set, never the heaviest set', () {
    final result = suggest([
      ...session(2, count: 1, kg: 6.25),
      ...session(2, count: 2, kg: 7.25),
      ...session(1),
    ]);
    expect(result.last?.weightKg, 6.25);
    expect(result.targetWeightKg, isNull);
    expect(result.targetReps, isNull);
  });

  test('low effort below upper bound reuses conservative +1 rep policy', () {
    final result = suggest([...session(2, reps: 10), ...session(1, reps: 10)]);
    expect(result.targetWeightKg, isNull);
    expect(result.targetReps, 11);
  });

  test('high effort never proposes more kg', () {
    final result = suggest([
      ...session(2, reps: 10, rpe: 9),
      ...session(1, reps: 10),
    ]);
    expect(result.targetWeightKg, isNull);
    expect(result.targetReps, 9);
  });

  test('unknown unit, tracking or prescription does not invent a target', () {
    final history = [...session(2), ...session(1)];
    for (final result in [
      suggest(history, confirmed: false),
      suggest(history, tracking: 'time'),
      suggest(history, prescription: 'Według możliwości'),
    ]) {
      expect(result.targetWeightKg, isNull);
      expect(result.targetReps, isNull);
    }
  });

  test('other exercise, side or variant cannot supply a last result', () {
    final result = suggest([
      ...session(3, exerciseId: 'cw002'),
      ...session(2, side: 'left'),
      ...session(1, variantId: 'another'),
    ]);
    expect(result.last, isNull);
    expect(result.targetWeightKg, isNull);
  });

  test('plate stock is shared by the pair when proposing the next weight', () {
    final stock = EquipmentInventory(
      plateCounts: {2500: 4, 1250: 2, 1000: 2, 500: 2},
    );
    final history = [...session(2), ...session(1)];
    expect(
      suggest(history, inventory: stock, quantity: 1).targetWeightKg,
      7.75,
    );
    expect(suggest(history, inventory: stock).targetWeightKg, isNull);
  });

  test('nearest available jump above10 percent is not recommended', () {
    final history = [...session(2, kg: 2.25), ...session(1, kg: 2.25)];
    final result = suggest(history);
    expect(result.last?.weightKg, 2.25);
    expect(result.targetWeightKg, isNull);
  });

  test('bodyweight can progress reps without fake kilograms', () {
    final history = [
      ...session(2, kg: null, reps: 10),
      ...session(1, kg: null, reps: 10),
    ];
    final result = suggest(history, usesWeight: false, implement: null);
    expect(result.targetWeightKg, isNull);
    expect(result.targetReps, 11);
  });

  test('fixed dumbbell max2kg does not pretend that5kg exists', () {
    final result = suggest([
      ...session(2, kg: 2),
      ...session(1, kg: 2),
    ], implement: LoadImplement.fixedDumbbell);
    expect(result.targetWeightKg, isNull);
  });

  test('finite enormous recorded kg cannot overflow gram conversion', () {
    final result = suggest([
      ...session(2, kg: 1e308),
      ...session(1, kg: 1e308),
    ]);
    expect(result.targetWeightKg, isNull);
  });

  test(
    'fixed repetition prescription keeps its existing no-increase policy',
    () {
      final result = suggest([
        ...session(2),
        ...session(1),
      ], prescription: '3×12');
      expect(result.targetWeightKg, isNull);
      expect(result.targetReps, 12);
    },
  );
}
