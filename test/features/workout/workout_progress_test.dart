import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/domain/workout_progress.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/domain/workout_repeat.dart';
import '../planner/structured_plan_persistence_test.dart' show structure;

void main() {
  test(
    'skip is not done; unique live performed IDs only, capped per block',
    () {
      final g = WorkoutGuidance.start(
        structure,
      ).link(0, 'a').link(0, 'b').link(0, 'c').skip(0);
      final goal = structure.blocks.first.prescription.sets;
      final p = WorkoutProgress.from(
        liveSetIds: ['a', 'a', 'b', 'c', 'extra'],
        guidance: g,
      );
      expect(p.confirmed, 3.clamp(0, goal));
      expect(p.actual, 4);
      expect(p.percent, lessThanOrEqualTo(100));
      expect(
        WorkoutProgress.from(liveSetIds: ['extra'], guidance: g).confirmed,
        0,
      );
      expect(WorkoutProgress.from(liveSetIds: ['a'], guidance: g).confirmed, 1);
    },
  );
  test(
    'repeat counts only confirmed live UUIDs, free has no fabricated percentage',
    () {
      final repeat = WorkoutRepeat.fromJson({
        'version': 1,
        'targets': [
          const RepeatSetTarget(
            exerciseId: 'cw1',
            name: 'Test',
            reps: 10,
          ).toJson(),
          const RepeatSetTarget(
            exerciseId: 'cw1',
            name: 'Test',
            reps: 10,
          ).toJson(),
        ],
      });
      final p = WorkoutProgress.from(
        liveSetIds: ['a', 'extra'],
        repeat: repeat,
        repeatCompleted: ['a', 'a', 'removed'],
      );
      expect(p.percent, 50);
      expect(p.confirmed, 1);
      expect(p.remaining, 1);
      expect(WorkoutProgress.from(liveSetIds: ['extra']).percent, isNull);
    },
  );
}
