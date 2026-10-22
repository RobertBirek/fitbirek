import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late ExercisesRepository repository;
  late List<Exercise> catalog;
  late ExerciseFilterEngine engine;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ExercisesRepository(db);
    await repository.syncFromAssets();
    catalog = await repository.watchAll().first;
    final metadata = ExerciseCatalogMetadata.fromJson(
      jsonDecode(
            await rootBundle.loadString(
              'assets/data/exercise_catalog_metadata.json',
            ),
          )
          as Map<String, dynamic>,
    );
    engine = ExerciseFilterEngine(metadata);
  });
  tearDown(() => db.close());

  Set<String> candidates(List<String> equipment) =>
      StructuredPlanGenerator.candidates(
        allExercises: catalog,
        engine: engine,
        criteria: const ExerciseFilters(),
        equipment: equipment,
        level: 'Zaawansowany',
      ).map((e) => e.id).toSet();

  test(
    'real imported catalog adds twelve IDs and corrects wrist roller without a duplicate',
    () async {
      expect(catalog, hasLength(424));
      expect(catalog.map((e) => e.id).toSet(), hasLength(424));
      final roller = (await repository.getById('cw123'))!;
      expect(roller.sprzet, ['Wrist roller']);
      expect(roller.nazwaPl.toLowerCase(), contains('linki'));
      expect(
        catalog.where((e) => e.nazwaEn.toLowerCase() == 'wrist roller'),
        hasLength(1),
      );
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );

  test(
    'step-only profile admits support alternatives without dumbbells or a bench',
    () {
      final ids = candidates(['Step']);
      expect(
        ids,
        containsAll([
          'cw009',
          'cw135',
          'cw136',
          'cw165',
          'cw413',
          'cw414',
          'cw415',
        ]),
      );
      expect(ids, isNot(contains('cw012')));
      expect(ids, isNot(contains('cw013')));
      expect(ids, isNot(contains('cw418')));
    },
  );

  test(
    'decline abdominal bench never grants flat, incline or weighted decline capability',
    () {
      final ids = candidates(['Hantle', 'Ławka do brzuszków']);
      expect(ids, containsAll(['cw416', 'cw417']));
      for (final id in ['cw012', 'cw013', 'cw418']) {
        expect(ids, isNot(contains(id)), reason: id);
      }
      expect(
        candidates(['Hantle', 'Ławka ujemna do wyciskania']),
        contains('cw418'),
      );
      expect(
        candidates(['Ławka ujemna do wyciskania']),
        isNot(contains('cw418')),
      );
      expect(candidates(['Hantle', 'Ławeczka']), isNot(contains('cw418')));
    },
  );

  test('wrist roller is not unlocked merely by owning dumbbells', () {
    expect(candidates(['Hantle']), isNot(contains('cw123')));
    expect(candidates(['Wrist roller']), contains('cw123'));
  });

  test(
    'feet-elevated push-up retains one identity and searchable alternative supports',
    () {
      for (final equipment in ['Step', 'Krzesło', 'Ławeczka']) {
        expect(candidates([equipment]), contains('cw009'), reason: equipment);
      }
      expect(candidates([]), isNot(contains('cw009')));
      expect(
        engine
            .filter(catalog, const ExerciseFilters(sprzet: {'Step'}))
            .where((e) => e.id == 'cw009'),
        hasLength(1),
      );
      expect(
        engine
            .filter(catalog, const ExerciseFilters(query: 'step'))
            .map((e) => e.id),
        contains('cw009'),
      );
      expect(
        catalog.where((e) => e.nazwaEn == 'Decline push-up'),
        hasLength(1),
      );
    },
  );

  test('ankle straps do not enable any new automatic inversion exercises', () {
    final ids = candidates(['Pasy do zwisu za nogi', 'Drążek']);
    for (var n = 413; n <= 424; n++) {
      expect(ids, isNot(contains('cw$n')), reason: 'cw$n');
    }
    expect(candidates(['Roller']), contains('cw267'));
  });
}
