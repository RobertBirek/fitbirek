import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';

Exercise exercise(
  String id, {
  String name = 'Ruch',
  List<String> equipment = const ['Hantle'],
  bool favorite = false,
}) => Exercise(
  id: id,
  nazwaPl: name,
  nazwaEn: 'Movement',
  partiaGlowna: 'Plecy',
  partieWspierajace: const ['Biceps'],
  sprzet: equipment,
  typ: 'Siła',
  poziom: 'Początkujący',
  wzorzecRuchu: '',
  seriexPowtorzenia: '',
  tempo: '',
  kluczoweWskazowki: const [],
  czesteBledy: const [],
  progresja: '',
  regresja: '',
  zrodlo: '',
  ulubione: favorite,
);

final metadata = ExerciseCatalogMetadata.fromJson({
  'schemaVersion': 1,
  'styles': [
    {
      'id': 'tai',
      'label': 'Tai chi',
      'aliases': ['taichi'],
    },
    {
      'id': 'strength',
      'label': 'Siłowy',
      'aliases': ['strength'],
    },
  ],
  'muscles': [
    {
      'id': 'back',
      'label': 'Plecy',
      'aliases': ['back'],
    },
    {
      'id': 'arms',
      'label': 'Ramiona',
      'aliases': ['arms'],
    },
  ],
  'exercises': {
    'a': {
      'styles': ['tai'],
      'primaryMuscles': ['back'],
      'secondaryMuscles': ['arms'],
      'aliases': ['żuraw'],
      'tracking': 'time',
      'unilateral': true,
    },
    'b': {
      'styles': ['strength'],
      'primaryMuscles': ['arms'],
      'secondaryMuscles': ['arms'],
      'aliases': [],
      'tracking': 'reps',
      'unilateral': false,
    },
  },
});

void main() {
  final all = [
    exercise('a', name: 'Płynące dłonie', favorite: true),
    exercise('b', equipment: ['Krzesło']),
    exercise('custom'),
  ];
  final engine = ExerciseFilterEngine(metadata);
  test('public entry API and missing custom entry', () {
    expect(metadata.entryFor('a')!.tracking, 'time');
    expect(metadata.entryFor('a')!.unilateral, isTrue);
    expect(metadata.entryFor('custom'), isNull);
    expect(engine.filter(all, const ExerciseFilters()), hasLength(3));
  });
  test('folds Polish, aliases, English and token AND across fields', () {
    for (final query in [
      'PLYNaCE zuraw',
      'tai chi arms hantle',
      'taichi back',
      'movement zuraw',
    ]) {
      expect(
        engine.filter(all, ExerciseFilters(query: query)).map((e) => e.id),
        ['a'],
      );
    }
    expect(
      engine.filter(all, const ExerciseFilters(query: 'zuraw missing')),
      isEmpty,
    );
  });
  test('OR within groups, AND between groups; supporting muscles count', () {
    expect(
      engine
          .filter(
            all,
            const ExerciseFilters(
              styles: {'tai', 'strength'},
              muscles: {'arms'},
              sprzet: {'Hantle'},
            ),
          )
          .map((e) => e.id),
      ['a'],
    );
    expect(
      engine.filter(all, const ExerciseFilters(muscles: {'arms'})),
      hasLength(2),
    );
    expect(
      engine.filter(all, const ExerciseFilters(partie: {'Plecy'})),
      hasLength(3),
    );
  });
  test(
    'facet skips itself, respects query/favorite/level and counts IDs once',
    () {
      final filters = const ExerciseFilters(
        muscles: {'back'},
        styles: {'strength'},
      );
      expect(engine.facets(all, filters).muscles['arms'], 1);
      expect(engine.facets(all, filters).styles['tai'], 1);
      expect(
        engine
            .facets(all, const ExerciseFilters(tylkoUlubione: true))
            .muscles['arms'],
        1,
      );
      expect(engine.facets(all, const ExerciseFilters(query: 'zuraw')).styles, {
        'tai': 1,
      });
      expect(
        engine
            .facets(all, const ExerciseFilters(poziomy: {'Zaawansowany'}))
            .muscles,
        isEmpty,
      );
    },
  );
  test('unknown schema fails instead of silently empty catalog', () {
    expect(
      () => ExerciseCatalogMetadata.fromJson({'schemaVersion': 2}),
      throwsFormatException,
    );
  });
  test(
    'fallback searches supporting muscles and never offers activity as muscle',
    () {
      final fallback = ExerciseFilterEngine(const ExerciseCatalogMetadata());
      final custom = exercise('local').copyWith(
        partiaGlowna: 'Mobilność',
        partieWspierajace: ['Biceps', 'Cardio'],
      );
      expect(
        fallback.filter([
          custom,
        ], const ExerciseFilters(query: 'biceps movement')),
        [custom],
      );
      expect(fallback.facets([custom], const ExerciseFilters()).muscles, {
        'biceps': 1,
      });
      expect(
        fallback.filter([custom], const ExerciseFilters(partie: {'Mobilność'})),
        [custom],
      );
    },
  );
  test(
    'own equipment facet can broaden OR, selected missing values have zero count',
    () {
      final facets = engine.facets(
        all,
        const ExerciseFilters(sprzet: {'Hantle'}, styles: {'strength'}),
      );
      expect(facets.equipment, {'Krzesło': 1});
      expect(facets.equipment['Hantle'] ?? 0, 0);
      expect(
        engine
            .filter(
              all,
              const ExerciseFilters(
                sprzet: {'Hantle', 'Krzesło'},
                styles: {'strength'},
              ),
            )
            .map((e) => e.id),
        ['b'],
      );
    },
  );
  test('facet counts deduplicate IDs, tags and both muscle roles', () {
    expect(engine.facets([all[1], all[1]], const ExerciseFilters()).muscles, {
      'arms': 1,
    });
  });
  test(
    'custom legacy muscles match canonical IDs and do not duplicate facets',
    () {
      final index = ExerciseCatalogMetadata.fromJson({
        'schemaVersion': 1,
        'styles': [],
        'muscles': [
          {
            'id': 'biceps',
            'label': 'Biceps',
            'aliases': ['dwugłowy ramienia'],
          },
          {
            'id': 'shoulders',
            'label': 'Barki',
            'aliases': ['deltoids'],
          },
        ],
        'exercises': {
          'a': {
            'styles': [],
            'primaryMuscles': ['biceps'],
            'secondaryMuscles': [],
            'aliases': [],
            'tracking': 'reps',
            'unilateral': false,
          },
        },
      });
      final custom = exercise('custom').copyWith(
        partiaGlowna: 'Biceps',
        partieWspierajace: ['dwugłowy ramienia', 'deltoids'],
      );
      final resolver = ExerciseFilterEngine(index);
      expect(
        resolver.filter([
          exercise('a'),
          custom,
        ], const ExerciseFilters(muscles: {'biceps'})),
        hasLength(2),
      );
      expect(
        resolver.facets([
          exercise('a'),
          custom,
        ], const ExerciseFilters()).muscles,
        {'biceps': 2, 'shoulders': 1},
      );
      expect(
        resolver.filter([custom], const ExerciseFilters(muscles: {'Biceps'})),
        [custom],
      );
      final fallback = ExerciseFilterEngine(const ExerciseCatalogMetadata());
      expect(fallback.musclesFor(custom), {'biceps', 'shoulders'});
      expect(
        fallback.musclesFor(
          custom.copyWith(partiaGlowna: 'Barki', partieWspierajace: []),
        ),
        {'shoulders'},
      );
    },
  );
}
