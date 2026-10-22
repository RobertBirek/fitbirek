import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'catalog_filter_test.dart' show exercise;

Map<String, dynamic> equipmentIndex(Object? sets) => {
  'schemaVersion': 1,
  'styles': [],
  'muscles': [],
  'exercises': {
    'cw009': {
      'styles': [],
      'primaryMuscles': [],
      'secondaryMuscles': [],
      'aliases': [],
      'tracking': 'reps',
      'unilateral': false,
      'equipmentSets': sets,
    },
  },
};

void main() {
  test('old entry constructors and missing field retain null fallback', () {
    const entry = ExerciseCatalogEntry(tracking: 'reps', unilateral: false);
    expect(entry.equipmentSets, isNull);
    final index = equipmentIndex(null);
    (index['exercises']['cw009'] as Map).remove('equipmentSets');
    expect(
      ExerciseCatalogMetadata.fromJson(index).entryFor('cw009')!.equipmentSets,
      isNull,
    );
  });
  for (final invalid in <Object?>[
    null,
    'Step',
    [],
    [[]],
    ['Step'],
    [
      [3],
    ],
    [
      [''],
    ],
    [
      ['  '],
    ],
    [
      ['Step', 'Step'],
    ],
  ]) {
    test('rejects malformed equipment sets: $invalid', () {
      expect(
        () => ExerciseCatalogMetadata.fromJson(equipmentIndex(invalid)),
        throwsFormatException,
      );
    });
  }
  final ex = exercise('cw009').copyWith(sprzet: ['Masa własna', 'Ławeczka']);
  final engine = ExerciseFilterEngine(
    ExerciseCatalogMetadata.fromJson(
      equipmentIndex([
        ['Masa własna', 'Step'],
        ['Masa własna', 'Krzesło'],
        ['Masa własna', 'Ławeczka'],
      ]),
    ),
  );
  test('OR of complete AND sets; implicit bodyweight; first match wins', () {
    expect(engine.supportsEquipment(ex, []), isFalse);
    for (final gear in ['Step', 'Krzesło', 'Ławeczka']) {
      expect(engine.supportsEquipment(ex, [gear]), isTrue);
    }
    expect(engine.matchingEquipment(ex, ['Krzesło', 'Step']), [
      'Masa własna',
      'Step',
    ]);
    expect(engine.matchingEquipment(ex, []), isNull);
    expect(
      () => engine.equipmentOptions(ex).first.add('Hantle'),
      throwsUnsupportedError,
    );
  });
  test('fallback strict AND without bench aliases', () {
    final fallback = ExerciseFilterEngine(const ExerciseCatalogMetadata());
    final press = exercise('press').copyWith(sprzet: ['Hantle', 'Ławeczka']);
    expect(fallback.supportsEquipment(press, ['Hantle']), isFalse);
    expect(
      fallback.supportsEquipment(press, [
        'Hantle',
        'Ławka do brzuszków',
        'Ławka ujemna do wyciskania',
      ]),
      isFalse,
    );
    expect(fallback.supportsEquipment(press, ['Hantle', 'Ławeczka']), isTrue);
    expect(
      fallback.supportsEquipment(press.copyWith(sprzet: ['Masa własna']), []),
      isTrue,
    );
  });
  test('browse OR, query and deduplicated facets include alternatives', () {
    expect(engine.filter([ex], const ExerciseFilters(sprzet: {'Step'})), [ex]);
    expect(engine.filter([ex], const ExerciseFilters(query: 'krzeslo')), [ex]);
    expect(engine.facets([ex, ex], const ExerciseFilters()).equipment, {
      'Masa własna': 1,
      'Step': 1,
      'Krzesło': 1,
      'Ławeczka': 1,
    });
  });
  test('metadata AND never grants equipment from a partially owned set', () {
    final press = exercise('cw009').copyWith(sprzet: ['Hantle', 'Ławeczka']);
    final strict = ExerciseFilterEngine(
      ExerciseCatalogMetadata.fromJson(
        equipmentIndex([
          ['Hantle', 'Ławeczka'],
          ['Hantle', 'Step'],
        ]),
      ),
    );
    expect(strict.supportsEquipment(press, ['Hantle']), isFalse);
    expect(strict.supportsEquipment(press, ['Step']), isFalse);
    expect(strict.supportsEquipment(press, ['Hantle', 'Step']), isTrue);
    expect(strict.filter([press], const ExerciseFilters(sprzet: {'Step'})), [
      press,
    ]);
  });
  test(
    'decline press needs dumbbells and its explicit bench, never an abs bench',
    () {
      final fallback = ExerciseFilterEngine(const ExerciseCatalogMetadata());
      final decline = exercise(
        'decline',
      ).copyWith(sprzet: ['Hantle', 'Ławka ujemna do wyciskania']);
      expect(
        fallback.supportsEquipment(decline, ['Ławka ujemna do wyciskania']),
        isFalse,
      );
      expect(
        fallback.supportsEquipment(decline, ['Hantle', 'Ławka do brzuszków']),
        isFalse,
      );
      expect(
        fallback.supportsEquipment(decline, [
          'Hantle',
          'Ławka ujemna do wyciskania',
        ]),
        isTrue,
      );
    },
  );
}
