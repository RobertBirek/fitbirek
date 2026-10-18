import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/workout/domain/workout_repeat.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import '../planner/structured_plan_persistence_test.dart' show structure;

SetLogData row(
  String uuid, {
  int reps = 8,
  String? side,
  int? seconds,
  String? variantId,
}) => SetLogData(
  id: 1,
  sesjaId: 1,
  cwiczenieId: 'yoga',
  nazwaCwiczeniaPl: 'Yoga',
  numerSerii: 1,
  powtorzenia: seconds == null ? reps : null,
  czasSekund: seconds,
  ciezarKg: seconds == null ? 12 : null,
  side: side,
  variantId: variantId,
  variantLabel: variantId == null ? null : 'Wariant',
  rpe: 9,
  timestamp: DateTime.utc(2026),
  syncId: uuid,
  syncVersion: 0,
  updatedAtUtc: DateTime.utc(2026),
);

void main() {
  test('execution includes every set and extra in timestamp / UUID order', () {
    final targets = WorkoutRepeat.execution([
      row('b', reps: 6, side: 'both'),
      row('a', reps: 11),
      row('c', seconds: 17, side: 'left'),
    ]).targets;
    expect(targets.map((t) => t.reps), [11, 6, null]);
    expect(targets.map((t) => t.side), [null, 'both', 'left']);
    expect(targets.last.seconds, 17);
    expect(targets.first.previousRpe, 9);
    expect(targets.first.prefill.containsKey('rpe'), isFalse);
    expect(targets.first.prefill.containsKey('timer'), isFalse);
  });
  test(
    'variant UUID and nullable side survive snapshot without old set UUIDs',
    () {
      const uuid = '11111111-1111-4111-8111-111111111111';
      final repeat = WorkoutRepeat.execution([row('old-set', variantId: uuid)]);
      final restored = WorkoutRepeat.fromJson(repeat.toJson());
      expect(restored.targets.single.variantId, uuid);
      expect(restored.targets.single.side, isNull);
      expect(repeat.toJson().toString(), isNot(contains('old-set')));
    },
  );
  test(
    'original means exact immutable plan, never replacements or executions',
    () {
      final g = WorkoutGuidance.start(structure).replace(0, 'other').skip(0);
      final repeat = WorkoutRepeat.original(g);
      expect(repeat.plan!.toJson(), structure.toJson());
      expect(repeat.targets.first.exerciseId, 'yoga');
      expect(repeat.targets.length, structure.blocks.first.prescription.sets);
    },
  );
  test('empty execution cannot start and malformed targets are rejected', () {
    expect(WorkoutRepeat.execution([]).targets, isEmpty);
    expect(
      () => WorkoutRepeat.fromJson({
        'version': 1,
        'targets': [{}],
      }),
      throwsFormatException,
    );
  });
}
