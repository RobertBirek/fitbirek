import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/exercises/presentation/exercise_illustrations.dart';
import 'package:fitbirek_training/features/exercises/presentation/pages/exercise_detail_page.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final raw =
      (jsonDecode(File('assets/data/exercises.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();
  final metadata = ExerciseCatalogMetadata.fromJson(
    jsonDecode(
          File('assets/data/exercise_catalog_metadata.json').readAsStringSync(),
        )
        as Map<String, dynamic>,
  );
  final catalog = raw.map(Exercise.fromJson).toList();
  const newIds = {
    'cw425',
    'cw426',
    'cw427',
    'cw428',
    'cw429',
    'cw430',
    'cw431',
  };

  test(
    'seven basic movements are selectable by actual equipment and execution',
    () {
      expect(catalog, hasLength(431));
      Set<String> candidates(List<String> equipment, Set<String> conditions) =>
          StructuredPlanGenerator.candidates(
            allExercises: catalog,
            engine: ExerciseFilterEngine(metadata),
            criteria: ExerciseFilters(conditions: conditions),
            equipment: equipment,
            level: 'Zaawansowany',
          ).map((e) => e.id).toSet().intersection(newIds);
      expect(candidates([], {}), {'cw425', 'cw426', 'cw427', 'cw428', 'cw431'});
      expect(candidates(['Krzesło'], {}), newIds);
      expect(candidates(['Krzesło'], {'no_floor', 'no_kneeling'}), {
        'cw425',
        'cw426',
        'cw427',
        'cw428',
        'cw429',
        'cw430',
      });
      expect(candidates(['Krzesło'], {'no_hand_support'}), {
        'cw426',
        'cw427',
        'cw428',
        'cw430',
      });
      expect(
        candidates(['Krzesło'], {'no_jumps', 'quiet', 'small_space'}),
        newIds,
      );
    },
  );

  test(
    'upgrade424 adds seven rows only; preserves profile variants history and attempted outbox',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final old = ExercisesRepository(
        db,
        loadAsset: (path) async => path.endsWith('exercises.json')
            ? jsonEncode(raw.take(424).toList())
            : File(path).readAsStringSync(),
      );
      await old.syncFromAssets();
      await old.toggleFavorite('cw424', true);
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      await db
          .into(db.userProfiles)
          .insert(
            UserProfilesCompanion.insert(
              imie: const Value('Offline'),
              wiek: 40,
              wzrostCm: 175,
              wagaKg: 80,
              cel: 'mix',
              dostepnySprzet: '["Krzesło"]',
              exerciseVariantsJson: const Value(
                '{"version":1,"entries":[{"id":"11111111-1111-4111-8111-111111111111",'
                '"exerciseId":"cw424","name":"Lokalny wariant","tempo":"Spokojnie",'
                '"createdAtUtc":"2026-10-27T10:00:00.000Z","updatedAtUtc":"2026-10-27T10:00:00.000Z"}]}',
              ),
            ),
          );
      final session = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              dataStart: DateTime.utc(2026, 10, 27),
            ),
          );
      await db
          .into(db.setsLog)
          .insert(
            SetsLogCompanion.insert(
              sesjaId: session,
              cwiczenieId: 'cw424',
              nazwaCwiczeniaPl: 'Historyczny chód',
              numerSerii: 1,
              czasSekund: const Value(24),
              variantId: const Value('11111111-1111-4111-8111-111111111111'),
              variantLabel: const Value('Historyczna etykieta wariantu'),
              syncVersion: const Value(8),
            ),
          );
      final before = await db.exercisesDao.getAll();
      final favorites = await db.select(db.exerciseFavorites).get();
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox.single.attempted, isTrue);
      final profiles = await db.select(db.userProfiles).get();
      final sessions = await db.select(db.workoutSessions).get();
      final history = await db.select(db.setsLog).get();
      final importer = ExercisesRepository(db);
      final beforeChanges =
          (await db.customSelect('SELECT total_changes() AS n').getSingle())
              .read<int>('n');
      await importer.syncFromAssets();
      expect(
        (await db.customSelect('SELECT total_changes() AS n').getSingle())
            .read<int>('n'),
        beforeChanges + 7,
        reason:
            'Only seven inserts, not even value-preserving writes to raw424',
      );
      final after = await db.exercisesDao.getAll();
      expect(after, hasLength(431));
      expect(after.where((e) => !newIds.contains(e.id)).toList(), before);
      expect(
        after.where((e) => newIds.contains(e.id)).map((e) => e.id).toSet(),
        newIds,
      );
      for (final e in raw.skip(424)) {
        expect((await importer.getById(e['id'] as String))!.toJson(), e);
      }
      Future<void> unchanged() async {
        expect(await db.select(db.exerciseFavorites).get(), favorites);
        expect(await db.select(db.syncOutbox).get(), outbox);
        expect(await db.select(db.userProfiles).get(), profiles);
        expect(await db.select(db.workoutSessions).get(), sessions);
        expect(await db.select(db.setsLog).get(), history);
      }

      await unchanged();
      final changes =
          (await db.customSelect('SELECT total_changes() AS n').getSingle())
              .read<int>('n');
      await importer.syncFromAssets();
      expect(
        (await db.customSelect('SELECT total_changes() AS n').getSingle())
            .read<int>('n'),
        changes,
      );
      expect(await db.exercisesDao.getAll(), after);
      await unchanged();
    },
  );

  test('431 catalog movements have illustrations with no pending', () {
    expect(illustratedExerciseIds, hasLength(431));
    expect(awaitingIllustrationExerciseIds, isEmpty);
    expect(illustratedExerciseIds.intersection(newIds), newIds);
    expect(illustratedExerciseIds, catalog.map((e) => e.id).toSet());
    for (final id in newIds) {
      expect(exerciseIllustrationAsset(id), 'assets/exercises/$id.webp');
    }
  });

  for (final id in newIds) {
    testWidgets(
      '$id detail shows its own illustration offline without pending text',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              allExercisesProvider.overrideWith((ref) => Stream.value(catalog)),
              exerciseCatalogMetadataProvider.overrideWith(
                (ref) async => metadata,
              ),
            ],
            child: MaterialApp(home: ExerciseDetailPage(exerciseId: id)),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Ilustracja w przygotowaniu — skorzystaj z instrukcji poniżej.',
          ),
          findsNothing,
        );
        final image = tester.widget<Image>(find.byType(Image));
        expect(
          (image.image as AssetImage).assetName,
          'assets/exercises/$id.webp',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
