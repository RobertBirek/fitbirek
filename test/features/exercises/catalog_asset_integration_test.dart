import 'dart:convert';

import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
    'real offline index covers all 363 exercises with known classifications',
    () {
      expect(exercises, hasLength(363));
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
    'sandbag filter selects exactly the 16 new sandbag exercises and their muscles',
    () {
      const filters = ExerciseFilters(sprzet: {'Sandbag'});
      final selected = engine.filter(exercises, filters);
      expect(selected.map((e) => e.id).toSet(), {
        for (var n = 317; n <= 332; n++) 'cw$n',
      });
      final muscles = {
        for (final exercise in selected) ...engine.musclesFor(exercise),
      };
      expect(engine.facets(exercises, filters).muscles.keys.toSet(), muscles);
    },
  );

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
}
