import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/exercises/domain/filter_preset.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'catalog_filter_test.dart' show exercise, metadata;

Map<String, dynamic> executionIndex() => {
  'schemaVersion': 1,
  'styles': [
    {'id': 'strength', 'label': 'Siłowy', 'aliases': <String>[]},
  ],
  'muscles': [
    {'id': 'back', 'label': 'Plecy', 'aliases': <String>[]},
  ],
  'conditions': [
    {
      'id': 'quiet',
      'label': 'Cichy trening',
      'aliases': ['low impact'],
    },
    {'id': 'no_jumps', 'label': 'Bez skoków', 'aliases': <String>[]},
  ],
  'positions': [
    {
      'id': 'standing',
      'label': 'Stojąco',
      'aliases': ['upright'],
    },
    {'id': 'seated', 'label': 'Siedząco', 'aliases': <String>[]},
  ],
  'exercises': {
    for (final id in ['a', 'b', 'c'])
      id: {
        'styles': ['strength'],
        'primaryMuscles': ['back'],
        'secondaryMuscles': <String>[],
        'aliases': <String>[],
        'tracking': 'reps',
        'unilateral': false,
        'conditions': id == 'a'
            ? ['quiet', 'no_jumps']
            : id == 'b'
            ? ['quiet']
            : ['no_jumps'],
        'positions': id == 'b' ? ['seated'] : ['standing'],
      },
  },
};

ExerciseFilters criteria(
  List<String> conditions, [
  List<String> positions = const [],
]) => FilterPreset.decodeFilters({
  'conditions': conditions,
  'positions': positions,
});

void main() {
  final all = [
    exercise('a', favorite: true),
    exercise('b'),
    exercise('c'),
    exercise('custom'),
  ];
  ExerciseFilterEngine engine() =>
      ExerciseFilterEngine(ExerciseCatalogMetadata.fromJson(executionIndex()));
  test(
    'conditions are AND requirements; positions OR; custom is not verified',
    () {
      expect(
        engine().filter(all, criteria(['quiet', 'no_jumps'])).map((e) => e.id),
        ['a'],
      );
      expect(
        engine()
            .filter(all, criteria(['quiet'], ['standing', 'seated']))
            .map((e) => e.id),
        ['a', 'b'],
      );
      expect(
        engine()
            .filter(
              all,
              criteria(['quiet'], ['standing']).copyWith(
                styles: {'strength'},
                muscles: {'back'},
                sprzet: {'Hantle'},
                poziomy: {'Początkujący'},
                tylkoUlubione: true,
                query: 'Ruch',
              ),
            )
            .map((e) => e.id),
        ['a'],
      );
      expect(
        engine().filter(all, criteria(['quiet']).copyWith(sprzet: {'Krzesło'})),
        isEmpty,
      );
    },
  );
  test('query searches execution labels and aliases, folded', () {
    for (final query in [
      'cichy trening stojaco',
      'low impact upright',
      'bez skokow cichy',
    ]) {
      expect(
        engine().filter(all, ExerciseFilters(query: query)).map((e) => e.id),
        ['a'],
      );
    }
  });
  test(
    'condition counts refine AND; position counts omit only own OR facet',
    () {
      final f = criteria(['quiet'], ['seated']);
      final facets = engine().facets([...all, all[1]], f);
      expect(facets.conditions, {'quiet': 1, 'no_jumps': 0});
      expect(facets.positions, {'standing': 1, 'seated': 1});
      expect(engine().facets(all, criteria(['quiet', 'no_jumps'])).conditions, {
        'quiet': 1,
        'no_jumps': 1,
      });
      expect(
        engine().facets(all, criteria(['unknown'])).conditions['unknown'],
        0,
      );
      expect(
        engine()
            .facets(all, f.copyWith(tylkoUlubione: true))
            .conditions['quiet'],
        0,
      );
    },
  );
  test('codec round trip, unknown IDs, old presets, reset and count', () {
    final f = criteria(['quiet', 'future_condition'], ['future_position']);
    final encoded = FilterPreset.encodeFilters(f.copyWith(query: 'test'));
    expect(encoded['conditions'], ['quiet', 'future_condition']);
    expect(encoded['positions'], ['future_position']);
    expect(
      FilterPreset.encodeFilters(FilterPreset.decodeFilters(encoded)),
      encoded,
    );
    expect(f.activeCount, 3);
    expect(const ExerciseFilters().activeCount, 0);
    expect(
      FilterPreset.encodeFilters(FilterPreset.decodeFilters({}))['conditions'],
      isEmpty,
    );
    expect(
      FilterPreset.encodeFilters(FilterPreset.decodeFilters({}))['positions'],
      isEmpty,
    );
    expect(
      () => FilterPreset.decodeFilters({
        'conditions': [1],
      }),
      throwsFormatException,
    );
  });
  test(
    'unknown position remains selected but does not negate known OR match',
    () {
      expect(
        engine()
            .filter(all, criteria(['quiet'], ['standing', 'future_position']))
            .map((e) => e.id),
        ['a'],
      );
    },
  );
  test('old index is accepted, but does not claim execution verification', () {
    expect(
      ExerciseFilterEngine(metadata).filter(all, criteria(['quiet'])),
      isEmpty,
    );
    expect(
      ExerciseFilterEngine(metadata).filter(all, criteria([], ['standing'])),
      isEmpty,
    );
    final fallback = ExerciseFilterEngine(
      const ExerciseCatalogMetadata(),
      classificationAvailable: false,
    );
    expect(fallback.filter(all, criteria(['quiet'])), isEmpty);
    expect(fallback.filter(all, criteria([], ['standing'])), isEmpty);
    expect(
      fallback.filter(all, const ExerciseFilters(styles: {'unknown'})),
      hasLength(4),
    );
  });
  test('corrupt optional fields fail rather than being ignored', () {
    for (final field in ['conditions', 'positions']) {
      final json = executionIndex()..[field] = 'broken';
      expect(() => ExerciseCatalogMetadata.fromJson(json), throwsA(anything));
      final entryJson = executionIndex();
      (entryJson['exercises'] as Map)['a'][field] = [1];
      expect(
        () => ExerciseCatalogMetadata.fromJson(entryJson),
        throwsA(anything),
      );
    }
  });
  test('planner never broadens execution filters and preserves criteria', () {
    final f = criteria(['quiet', 'no_jumps'], ['standing', 'seated']);
    final plan = StructuredPlanGenerator.generate(
      allExercises: all,
      engine: engine(),
      criteria: f,
      equipment: ['Hantle'],
      level: 'Średni',
      minutes: 10,
    );
    expect(plan.exerciseIds, ['a']);
    expect(StructuredPlan.fromJson(plan.toJson()).toJson(), plan.toJson());
    for (final f in [
      criteria(['quiet']),
      criteria([], ['standing']),
    ]) {
      expect(
        () => StructuredPlanGenerator.candidates(
          allExercises: all,
          engine: ExerciseFilterEngine(
            const ExerciseCatalogMetadata(),
            classificationAvailable: false,
          ),
          criteria: f,
          equipment: ['Hantle'],
          level: 'Średni',
        ),
        throwsStateError,
      );
    }
  });
}
