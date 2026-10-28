import 'dart:convert';
import 'package:fitbirek_training/app/constants.dart';

import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/planner/domain/plan_generator.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> exercises;
  late ExerciseCatalogMetadata metadata;
  late ExerciseFilterEngine engine;

  setUpAll(() async {
    final catalog =
        jsonDecode(await rootBundle.loadString('assets/data/exercises.json'))
            as List;
    exercises = catalog
        .map((row) => Exercise.fromJson(row as Map<String, dynamic>))
        .toList();
    metadata = ExerciseCatalogMetadata.fromJson(
      jsonDecode(
            await rootBundle.loadString(
              'assets/data/exercise_catalog_metadata.json',
            ),
          )
          as Map<String, dynamic>,
    );
    engine = ExerciseFilterEngine(metadata);
  });

  test(
    'real offline index covers all 431 exercises with known classifications',
    () {
      expect(exercises, hasLength(431));
      for (final exercise in exercises) {
        final entry = metadata.entryFor(exercise.id);
        expect(entry, isNotNull, reason: exercise.id);
        expect(entry!.styles, isNotEmpty, reason: exercise.id);
        expect(entry.primaryMuscles, isNotEmpty, reason: exercise.id);
        expect(entry.styles.every(metadata.styles.containsKey), isTrue);
        expect(
          engine.musclesFor(exercise).every(metadata.muscles.containsKey),
          isTrue,
        );
      }
    },
  );

  test(
    'partner collection is searchable and excluded from solo generators',
    () {
      final partnerIds = {for (var n = 393; n <= 408; n++) 'cw$n'};
      for (final filters in [
        const ExerciseFilters(styles: {'partner'}),
        const ExerciseFilters(query: 'w parach'),
        const ExerciseFilters(query: 'partnerskie'),
      ]) {
        expect(
          engine.filter(exercises, filters).map((e) => e.id).toSet(),
          partnerIds,
        );
      }
      final equipment = exercises.expand((e) => e.sprzet).toSet()
        ..remove('Partner');
      final solo = StructuredPlanGenerator.candidates(
        allExercises: exercises,
        engine: engine,
        criteria: const ExerciseFilters(),
        equipment: equipment.toList(),
        level: 'Zaawansowany',
      );
      expect(solo, isNotEmpty);
      expect(solo.any((e) => partnerIds.contains(e.id)), isFalse);
      expect(
        StructuredPlanGenerator.candidates(
          allExercises: exercises,
          engine: engine,
          criteria: const ExerciseFilters(styles: {'partner'}),
          equipment: [...equipment, 'Partner'],
          level: 'Zaawansowany',
        ).map((e) => e.id).toSet(),
        partnerIds,
      );
      for (final goal in CelTreningowy.values) {
        final plan = PlanGenerator.generate(
          wszystkieCwiczenia: exercises
              .where((e) => partnerIds.contains(e.id))
              .toList(),
          cel: goal,
          poziom: 'Zaawansowany',
          dostepnySprzet: equipment.toList(),
        );
        expect(plan, isEmpty);
      }
    },
  );

  test('EZ has distinct equipment and both generators require every item', () {
    const ez = 'Gryf łamany EZ';
    expect(AppConstants.dostepnySprzetOpcje, contains(ez));
    final selected = engine.filter(
      exercises,
      const ExerciseFilters(sprzet: {ez}),
    );
    expect(selected.map((e) => e.id).toSet(), {'cw409', 'cw410', 'cw411'});
    for (final exercise in selected) {
      expect(exercise.sprzet, exercise.id == 'cw411' ? [ez, 'Ławeczka'] : [ez]);
      expect(metadata.entryFor(exercise.id)!.tracking, 'reps');
      expect(metadata.entryFor(exercise.id)!.unilateral, isFalse);
      for (final equipment in <List<String>>[
        ['Hantle', 'Sztanga', 'Ławeczka'],
        [ez],
        [ez, 'Ławeczka'],
      ]) {
        final allowed = exercise.sprzet.every(equipment.contains);
        final candidates = StructuredPlanGenerator.candidates(
          allExercises: [exercise],
          engine: engine,
          criteria: const ExerciseFilters(),
          equipment: equipment,
          level: 'Zaawansowany',
        );
        expect(
          candidates.isNotEmpty,
          allowed,
          reason: '${exercise.id}: $equipment',
        );
        for (final goal in CelTreningowy.values) {
          final plan = PlanGenerator.generate(
            wszystkieCwiczenia: [exercise],
            cel: goal,
            poziom: 'Zaawansowany',
            dostepnySprzet: equipment,
          );
          expect(
            plan.isNotEmpty,
            allowed,
            reason: '${exercise.id}: $equipment',
          );
        }
      }
    }
  });

  test(
    'easy bike is timed and unavailable without explicit bike equipment',
    () {
      const bike = 'Rower stacjonarny';
      expect(AppConstants.dostepnySprzetOpcje, contains(bike));
      final selected = engine.filter(
        exercises,
        const ExerciseFilters(sprzet: {bike}),
      );
      expect(selected.map((e) => e.id), ['cw412']);
      expect(metadata.entryFor('cw412')!.tracking, 'time');
      expect(metadata.entryFor('cw412')!.unilateral, isFalse);
      for (final equipment in <List<String>>[
        [],
        ['Bieżnia'],
        [bike],
      ]) {
        final allowed = equipment.contains(bike);
        expect(
          StructuredPlanGenerator.candidates(
            allExercises: selected,
            engine: engine,
            criteria: const ExerciseFilters(),
            equipment: equipment,
            level: 'Zaawansowany',
          ).isNotEmpty,
          allowed,
        );
        for (final goal in CelTreningowy.values) {
          final plan = PlanGenerator.generate(
            wszystkieCwiczenia: selected,
            cel: goal,
            poziom: 'Zaawansowany',
            dostepnySprzet: equipment,
          );
          expect(plan.isNotEmpty, allowed);
        }
      }
    },
  );

  test(
    'sandbag filter selects the sixteen lifts and the new carry with their muscles',
    () {
      const filters = ExerciseFilters(sprzet: {'Sandbag'});
      final selected = engine.filter(exercises, filters);
      expect(selected.map((e) => e.id).toSet(), {
        for (var n = 317; n <= 332; n++) 'cw$n',
        'cw424',
      });
      final muscles = {
        for (final exercise in selected) ...engine.musclesFor(exercise),
      };
      expect(engine.facets(exercises, filters).muscles.keys.toSet(), muscles);
    },
  );

  test('real execution metadata covers exactly all catalog IDs', () {
    expect(metadata.exercises.keys.toSet(), exercises.map((e) => e.id).toSet());
    expect(metadata.conditions.keys.toSet(), {
      'no_jumps',
      'quiet',
      'no_kneeling',
      'no_hand_support',
      'no_floor',
      'small_space',
    });
    expect(metadata.positions.keys.toSet(), {
      'standing',
      'seated',
      'floor',
      'hanging',
      'bench',
    });
    for (final item in metadata.exercises.entries) {
      expect(item.value.positions, isNotEmpty, reason: item.key);
      expect(
        item.value.conditions.every(metadata.conditions.containsKey),
        isTrue,
        reason: item.key,
      );
      expect(
        item.value.positions.every(metadata.positions.containsKey),
        isTrue,
        reason: item.key,
      );
    }
  });

  test('real execution filters and cross-facets match explicit entry tags', () {
    Set<String> expected(ExerciseFilters filters) => exercises
        .where((exercise) {
          final entry = metadata.entryFor(exercise.id)!;
          return filters.conditions.every(entry.conditions.contains) &&
              (filters.positions.isEmpty ||
                  filters.positions.any(entry.positions.contains));
        })
        .map((exercise) => exercise.id)
        .toSet();

    for (final condition in metadata.conditions.keys) {
      final single = ExerciseFilters(conditions: {condition});
      expect(expected(single), isNotEmpty, reason: condition);
      expect(
        engine.filter(exercises, single).map((e) => e.id).toSet(),
        expected(single),
      );
      for (final position in metadata.positions.keys) {
        final filters = single.copyWith(positions: {position, 'seated'});
        expect(engine.executionFiltersVerified(filters), isTrue);
        expect(
          engine.filter(exercises, filters).map((e) => e.id).toSet(),
          expected(filters),
        );
        final facets = engine.facets(exercises, filters);
        for (final next in metadata.conditions.keys) {
          expect(
            facets.conditions[next],
            expected(filters.copyWith(conditions: {condition, next})).length,
          );
        }
        for (final next in metadata.positions.keys) {
          expect(
            facets.positions[next] ?? 0,
            expected(filters.copyWith(positions: {next})).length,
          );
        }
      }
    }
    for (final position in metadata.positions.keys) {
      final filters = ExerciseFilters(positions: {position});
      expect(expected(filters), isNotEmpty, reason: position);
      expect(
        engine.filter(exercises, filters).map((e) => e.id).toSet(),
        expected(filters),
      );
    }
  });

  test(
    'biceps includes primary and supporting work and intersects dumbbells',
    () {
      const filters = ExerciseFilters(muscles: {'biceps'}, sprzet: {'Hantle'});
      final selected = engine.filter(exercises, filters);
      final expected = exercises
          .where((e) {
            final entry = metadata.entryFor(e.id)!;
            return e.sprzet.contains('Hantle') &&
                {
                  ...entry.primaryMuscles,
                  ...entry.secondaryMuscles,
                }.contains('biceps');
          })
          .map((e) => e.id)
          .toSet();
      expect(expected, isNotEmpty);
      expect(selected.map((e) => e.id).toSet(), expected);
      expect(
        selected.any(
          (e) => metadata.entryFor(e.id)!.secondaryMuscles.contains('biceps'),
        ),
        isTrue,
      );
      final bicepsExercises = engine.filter(
        exercises,
        const ExerciseFilters(muscles: {'biceps'}),
      );
      expect(engine.facets(exercises, filters).equipment.keys.toSet(), {
        for (final exercise in bicepsExercises) ...exercise.sprzet,
      });
    },
  );

  test('yoga and taichi search also discover existing entries by style', () {
    for (final item in {'joga': 'yoga', 'taichi': 'tai_chi'}.entries) {
      final expected = exercises
          .where((e) => metadata.entryFor(e.id)!.styles.contains(item.value))
          .map((e) => e.id)
          .toSet();
      expect(expected, isNotEmpty);
      final actual = engine.filter(exercises, ExerciseFilters(query: item.key));
      expect(actual.map((e) => e.id).toSet(), expected);
    }
    expect(
      engine.filter(exercises, const ExerciseFilters(query: 'kolko brzucha')),
      hasLength(3),
    );
  });

  test('spine collection includes exactly 13 existing and 6 new exercises', () {
    final selected = engine.filter(
      exercises,
      const ExerciseFilters(styles: {'spine'}),
    );
    expect(selected, hasLength(19));
    expect(selected.map((e) => e.id).toSet(), {
      'cw154',
      'cw169',
      'cw171',
      'cw179',
      'cw181',
      'cw250',
      'cw252',
      'cw266',
      'cw267',
      'cw268',
      'cw290',
      'cw291',
      'cw294',
      for (var n = 364; n <= 369; n++) 'cw$n',
    });
  });
}
