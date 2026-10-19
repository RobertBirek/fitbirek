import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/domain/empty_session_template.dart';
import 'package:fitbirek_training/features/workout/domain/workout_repeat.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'session_tracking_test.dart' show exercise;

void main() {
  final metadata = ExerciseCatalogMetadata(
    exercises: {
      exercise.id: const ExerciseCatalogEntry(
        tracking: 'reps',
        unilateral: false,
      ),
    },
  );
  WorkoutRepeat repeat(List<RepeatSetTarget> targets) => WorkoutRepeat.fromJson(
    {'version': 1, 'targets': targets.map((t) => t.toJson()).toList()},
  );
  test(
    'empty selection conversion proposes explicit defaults, not execution',
    () {
      final p = templateFromSelection([exercise], metadata);
      expect(p.blocks.single.prescription.sets, 1);
      expect(p.warnings.single, contains('nie wykonania'));
      expect(p.blocks.single.prescription.weightKg, isNull);
    },
  );
  test(
    'repeat targets copy exact equal doses and kg; refuse lossy sides/variants/differing targets',
    () {
      final t = RepeatSetTarget(
        exerciseId: exercise.id,
        name: exercise.nazwaPl,
        reps: 7,
        weightKg: 12,
      );
      final p = templateFromSelection(
        [exercise],
        metadata,
        repeat: repeat([t, t]),
      );
      expect(p.blocks.single.prescription.sets, 2);
      expect(p.blocks.single.prescription.reps, 7);
      expect(p.blocks.single.prescription.weightKg, 12);
      for (final changed in [
        RepeatSetTarget(exerciseId: exercise.id, name: 'x', reps: 8),
        RepeatSetTarget(
          exerciseId: exercise.id,
          name: 'x',
          reps: 7,
          side: 'left',
        ),
      ]) {
        expect(
          () => templateFromSelection(
            [exercise],
            metadata,
            repeat: repeat([t, changed]),
          ),
          throwsFormatException,
        );
      }
    },
  );
}
