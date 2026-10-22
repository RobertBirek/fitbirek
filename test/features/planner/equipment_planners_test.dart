import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/planner/domain/plan_generator.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import '../exercises/catalog_filter_test.dart' show exercise;

void main() {
  final ex = exercise('step').copyWith(sprzet: ['Hantle', 'Ławeczka']);
  final engine = ExerciseFilterEngine(
    const ExerciseCatalogMetadata(
      exercises: {
        'step': ExerciseCatalogEntry(
          tracking: 'reps',
          unilateral: false,
          equipmentSets: [
            ['Hantle', 'Ławeczka'],
            ['Masa własna', 'Step'],
          ],
        ),
      },
    ),
  );
  test('both generators share complete alternatives and strict fallback', () {
    for (final gear in <List<String>>[
      [],
      ['Hantle'],
      ['Step'],
    ]) {
      final expected = gear.contains('Step') ? [ex] : [];
      expect(
        PlanGenerator.generate(
          wszystkieCwiczenia: [ex],
          cel: CelTreningowy.mix,
          poziom: 'Zaawansowany',
          dostepnySprzet: gear,
          engine: engine,
        ),
        expected,
      );
      expect(
        StructuredPlanGenerator.candidates(
          allExercises: [ex],
          engine: engine,
          criteria: const ExerciseFilters(),
          equipment: gear,
          level: 'Zaawansowany',
        ),
        expected,
      );
    }
    expect(
      PlanGenerator.generate(
        wszystkieCwiczenia: [ex],
        cel: CelTreningowy.mix,
        poziom: 'Zaawansowany',
        dostepnySprzet: ['Hantle'],
      ),
      isEmpty,
    );
  });
  test('alternatives do not bypass level or browse constraints', () {
    expect(
      StructuredPlanGenerator.candidates(
        allExercises: [ex.copyWith(poziom: 'Zaawansowany')],
        engine: engine,
        criteria: const ExerciseFilters(),
        equipment: ['Step'],
        level: 'Początkujący',
      ),
      isEmpty,
    );
    expect(
      StructuredPlanGenerator.candidates(
        allExercises: [ex],
        engine: engine,
        criteria: const ExerciseFilters(sprzet: {'Roller'}),
        equipment: ['Step'],
        level: 'Zaawansowany',
      ),
      isEmpty,
    );
  });
}
