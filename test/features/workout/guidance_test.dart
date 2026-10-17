import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';

void main() {
  StructuredPlan plan() => StructuredPlan(
    criteria: const ExerciseFilters(),
    budgetSeconds: 300,
    warnings: [],
    blocks: [
      const PlanBlock(
        exerciseId: 'cw1',
        section: PlanSection.main,
        prescription: PlanPrescription(
          tracking: 'reps',
          sets: 2,
          reps: 10,
          workSeconds: 30,
          restSeconds: 30,
          transitionSeconds: 15,
        ),
      ),
    ],
  );
  test(
    'replacement and skip survive JSON without changing original targets',
    () {
      final g = WorkoutGuidance.start(plan()).replace(0, 'cw2').skip(0);
      final restored = WorkoutGuidance.validateJson(g.toJson());
      expect(restored.plan.exerciseIds, ['cw1']);
      expect(restored.exerciseAt(0), 'cw2');
      expect(restored.events.length, 2);
      expect(restored.plan.blocks.first.prescription.reps, 10);
    },
  );
  test(
    'set links are unique, bounded and never inferred from exercise IDs',
    () {
      final g = WorkoutGuidance.start(plan()).link(0, 'set-a');
      expect(g.link(0, 'set-a').events.length, 1);
      expect(() => g.link(1, 'set-b'), throwsRangeError);
      expect(g.additionalSetIds(['set-a', 'mentor-b']), ['mentor-b']);
    },
  );
  test(
    'invalid or future guidance is explicit, defensive read preserves history',
    () {
      for (final value in [
        null,
        {},
        {'schemaVersion': 2},
        {'schemaVersion': 1, 'plan': []},
      ]) {
        expect(
          () => WorkoutGuidance.validateJson(value),
          throwsFormatException,
        );
      }
      expect(WorkoutGuidance.tryRead('{broken'), isNull);
      final bad = WorkoutGuidance.start(plan()).toJson();
      bad['events'] = [
        {'type': 'performed', 'slotIndex': 3, 'setSyncId': 's'},
      ];
      expect(() => WorkoutGuidance.validateJson(bad), throwsFormatException);
    },
  );
  test(
    'draft validates side RPE and timer but preserves future local prescription fields',
    () {
      final draft = {
        'schemaVersion': 1,
        'currentSlot': 0,
        'selectedIds': ['cw1'],
        'fields': {
          'side': 'left',
          'rpe': 8,
          'reps': '12',
          'futurePrescription': {'tempo': '3-1'},
        },
      };
      expect(validateWorkoutDraft(draft)['fields'], draft['fields']);
      expect(
        () => validateWorkoutDraft({
          ...draft,
          'fields': {'side': 'alien'},
        }),
        throwsFormatException,
      );
      expect(
        () => validateWorkoutDraft({
          ...draft,
          'fields': {'timer': {}},
        }),
        throwsFormatException,
      );
      expect(
        () => validateWorkoutDraft({
          ...draft,
          'fields': {'rpe': 20},
        }),
        throwsFormatException,
      );
    },
  );
}
