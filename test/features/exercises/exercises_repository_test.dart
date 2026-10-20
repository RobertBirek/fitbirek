// Testy ExercisesRepository - import przyrostowy (syncFromAssets) z
// assets/data/exercises.json do bazy Drift w pamięci, oraz podstawowa
// walidacja rozmiaru/struktury samego pliku danych.

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/app/constants.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/utils/partia_kategoria.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ExercisesRepository repo;
  const legacyCount = 316;
  final legacyIds = {
    for (var i = 1; i <= legacyCount; i++) 'cw${i.toString().padLeft(3, '0')}',
  };
  late List<Map<String, dynamic>> data;

  setUpAll(() {
    data =
        (jsonDecode(File('assets/data/exercises.json').readAsStringSync())
                as List)
            .cast<Map<String, dynamic>>();
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ExercisesRepository(db);
  });

  tearDown(() async => await db.close());

  group('syncFromAssets - import przyrostowy', () {
    test(
      'aktualizuje tylko nazwaPl, gdy wszystkie ID aktualnego katalogu już istnieją',
      () async {
        await repo.syncFromAssets();
        final catalog = await db.exercisesDao.getAll();
        // Symulacja starszego katalogu: każde ID istnieje, każda nazwa jest inna.
        for (final row in catalog) {
          await (db.update(db.exercises)..where((t) => t.id.equals(row.id)))
              .write(ExercisesCompanion(nazwaPl: Value('Stara ${row.id}')));
        }
        await (db.update(
          db.exercises,
        )..where((t) => t.id.equals('cw001'))).write(
          const ExercisesCompanion(
            nazwaEn: Value('Local English push-up'),
            partiaGlowna: Value('Plecy'),
            partieWspierajace: Value('["Biceps"]'),
            sprzet: Value('["Hantle"]'),
            typ: Value('Siła'),
            poziom: Value('Zaawansowany'),
            wzorzecRuchu: Value('Lokalny wzorzec'),
            seriexPowtorzenia: Value('7 x 3'),
            tempo: Value('3-1-3-1'),
            kluczoweWskazowki: Value('["Lokalna wskazówka"]'),
            czesteBledy: Value('["Lokalny błąd"]'),
            progresja: Value('Lokalna progresja'),
            regresja: Value('Lokalna regresja'),
            zrodlo: Value('Lokalne źródło'),
          ),
        );
        await repo.toggleFavorite('cw001', true);
        await repo.toggleFavorite('cw002', true);
        await repo.toggleFavorite('cw002', false);
        final before = await db.exercisesDao.getAll();
        final favorites = await db.select(db.exerciseFavorites).get();
        final outbox = await db.select(db.syncOutbox).get();
        final names = {for (final row in catalog) row.id: row.nazwaPl};

        await repo.syncFromAssets();

        final after = await db.exercisesDao.getAll();
        expect(after, hasLength(data.length));
        expect(
          {for (final row in after) row.id: row},
          {
            for (final row in before)
              row.id: row.copyWith(nazwaPl: names[row.id]),
          },
        );
        expect(await db.select(db.exerciseFavorites).get(), favorites);
        expect(await db.select(db.syncOutbox).get(), outbox);
        expect((await repo.getById('cw001'))!.ulubione, isTrue);
        expect((await repo.getById('cw002'))!.ulubione, isFalse);
      },
    );

    for (final prefixCount in [316, 369]) {
      test(
        'po rozszerzeniu dopisuje nowe ID do starego prefiksu $prefixCount bez zmiany pól, historii i ulubionych',
        () async {
          final legacyIds = {
            for (var i = 1; i <= prefixCount; i++)
              'cw${i.toString().padLeft(3, '0')}',
          };
          // Stan urządzenia sprzed rozszerzenia: nigdy nie importowano nowych ID.
          // Fixture pochodzi z prawdziwego assetu, nie z pełnego importu i DELETE.
          final legacy = data
              .where((e) => legacyIds.contains(e['id']))
              .toList();
          expect(legacy, hasLength(prefixCount));
          for (final e in legacy) {
            await db
                .into(db.exercises)
                .insert(
                  ExercisesCompanion.insert(
                    id: e['id'] as String,
                    nazwaPl: e['nazwaPl'] as String,
                    nazwaEn: e['nazwaEn'] as String,
                    partiaGlowna: e['partiaGlowna'] as String,
                    partieWspierajace: jsonEncode(e['partieWspierajace']),
                    sprzet: jsonEncode(e['sprzet']),
                    typ: e['typ'] as String,
                    poziom: e['poziom'] as String,
                    wzorzecRuchu: e['wzorzecRuchu'] as String,
                    seriexPowtorzenia: e['seriexPowtorzenia'] as String,
                    tempo: e['tempo'] as String,
                    kluczoweWskazowki: jsonEncode(e['kluczoweWskazowki']),
                    czesteBledy: jsonEncode(e['czesteBledy']),
                    progresja: e['progresja'] as String,
                    regresja: e['regresja'] as String,
                    zrodlo: e['zrodlo'] as String,
                  ),
                );
          }
          // Lokalne pola niebędące nazwą PL również nie mogą zostać odświeżone.
          await (db.update(
            db.exercises,
          )..where((t) => t.id.equals('cw001'))).write(
            const ExercisesCompanion(
              nazwaEn: Value('Local English push-up'),
              tempo: Value('4-2-1-0'),
              zrodlo: Value('Lokalna notatka o źródle'),
            ),
          );
          await repo.toggleFavorite('cw001', true);
          await repo.toggleFavorite('cw316', true);
          await repo.toggleFavorite('cw002', true);
          await repo.toggleFavorite('cw002', false);

          final startedAt = DateTime.utc(2026, 10, 1, 10);
          final sessionId = await db
              .into(db.workoutSessions)
              .insert(
                WorkoutSessionsCompanion.insert(
                  dataStart: startedAt,
                  dataKoniec: Value(startedAt.add(const Duration(minutes: 20))),
                  czasTrwaniaSekund: const Value(1200),
                  notatka: const Value('Historia sprzed rozszerzenia katalogu'),
                  syncVersion: const Value(7),
                ),
              );
          for (final id in ['cw001', 'cw316']) {
            await db
                .into(db.setsLog)
                .insert(
                  SetsLogCompanion.insert(
                    sesjaId: sessionId,
                    cwiczenieId: id,
                    nazwaCwiczeniaPl: 'Historyczna nazwa $id',
                    numerSerii: 1,
                    ciezarKg: const Value(12.5),
                    powtorzenia: const Value(8),
                    rpe: const Value(7),
                    timestamp: Value(startedAt.add(const Duration(minutes: 5))),
                    // Stara historia bez side zachowuje swoje dotychczasowe znaczenie.
                    syncVersion: const Value(4),
                  ),
                );
          }
          final before = await db.exercisesDao.getAll();
          expect(before.map((e) => e.id).toSet(), legacyIds);
          expect(await repo.getById('cw${prefixCount + 1}'), isNull);
          final sessions = await db.select(db.workoutSessions).get();
          final sets = await db.select(db.setsLog).get();
          final favorites = await db.select(db.exerciseFavorites).get();
          final outbox = await db.select(db.syncOutbox).get();

          await repo.syncFromAssets();

          final after = await db.exercisesDao.getAll();
          expect(after, hasLength(data.length));
          expect(
            after.map((e) => e.id).toSet(),
            data.map((e) => e['id']).toSet(),
          );
          expect(
            {
              for (final row in after.where((e) => legacyIds.contains(e.id)))
                row.id: row,
            },
            {for (final row in before) row.id: row},
          );
          final additions = data.where((e) => !legacyIds.contains(e['id']));
          expect(additions, isNotEmpty);
          for (final e in additions) {
            final imported = await repo.getById(e['id'] as String);
            expect(imported, isNotNull, reason: e['id'] as String);
            expect(imported!.toJson(), e, reason: e['id'] as String);
          }
          expect(await db.select(db.workoutSessions).get(), sessions);
          expect(await db.select(db.setsLog).get(), sets);
          expect(await db.select(db.exerciseFavorites).get(), favorites);
          expect(await db.select(db.syncOutbox).get(), outbox);
          expect((await repo.getById('cw001'))!.ulubione, isTrue);
          expect((await repo.getById('cw316'))!.ulubione, isTrue);
          expect((await repo.getById('cw002'))!.ulubione, isFalse);

          final changes =
              (await db.customSelect('SELECT total_changes() AS n').getSingle())
                  .read<int>('n');
          await repo.syncFromAssets();
          expect(await db.exercisesDao.getAll(), after);
          expect(
            (await db.customSelect('SELECT total_changes() AS n').getSingle())
                .read<int>('n'),
            changes,
          );
        },
      );
    }
    test(
      'dopisuje brakujące, zachowuje rekord spoza katalogu i nie zapisuje ponownie',
      () async {
        await repo.syncFromAssets();
        final original = (await db.exercisesDao.getAll()).first;
        final extra = original.copyWith(
          id: 'custom',
          nazwaPl: 'Moje ćwiczenie',
        );
        await db.into(db.exercises).insert(extra);
        await (db.delete(
          db.exercises,
        )..where((t) => t.id.equals('cw316'))).go();
        await (db.update(db.exercises)..where((t) => t.id.equals(original.id)))
            .write(const ExercisesCompanion(nazwaPl: Value('Stara nazwa')));

        await repo.syncFromAssets();

        expect(await db.exercisesDao.count(), data.length + 1);
        expect(await repo.getById('cw316'), isNotNull);
        expect(
          (await db.exercisesDao.getByIdWithFavorite(original.id))!.$1,
          original,
        );
        expect(
          (await db.exercisesDao.getByIdWithFavorite('custom'))!.$1,
          extra,
        );
        final changes = await db
            .customSelect('SELECT total_changes() AS n')
            .getSingle();
        await repo.syncFromAssets();
        final repeated = await db
            .customSelect('SELECT total_changes() AS n')
            .getSingle();
        expect(repeated.read<int>('n'), changes.read<int>('n'));
      },
    );

    test('po zmianie nazwy PL wyszukiwanie nadal znajduje nazwę EN', () async {
      await repo.syncFromAssets();
      await (db.update(db.exercises)..where((t) => t.id.equals('cw001'))).write(
        const ExercisesCompanion(nazwaPl: Value('Old push-up')),
      );
      await repo.syncFromAssets();
      final container = ProviderContainer(
        overrides: [exercisesRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(allExercisesProvider.future);
      container.read(exerciseFiltersProvider.notifier).state =
          const ExerciseFilters(query: 'PUSH-UP');
      final result = container.read(filteredExercisesProvider);
      final exercise = result.singleWhere((e) => e.id == 'cw001');
      expect(exercise.nazwaPl, 'Pompki klasyczne');
      expect(exercise.nazwaEn, 'Push-up');
    });

    test(
      'błąd aktualizacji wycofuje także dopisanie brakujących ćwiczeń',
      () async {
        await repo.syncFromAssets();
        await (db.delete(
          db.exercises,
        )..where((t) => t.id.equals('cw316'))).go();
        await (db.update(db.exercises)..where((t) => t.id.equals('cw001')))
            .write(const ExercisesCompanion(nazwaPl: Value('Stara nazwa')));
        final before = await db.exercisesDao.getAll();
        await db.customStatement('''
        CREATE TEMP TRIGGER reject_rename BEFORE UPDATE ON exercises
        WHEN NEW.id = 'cw001'
        BEGIN SELECT RAISE(ABORT, 'rename rejected'); END
      ''');

        await expectLater(
          repo.syncFromAssets(),
          throwsA(
            predicate((error) => error.toString().contains('rename rejected')),
          ),
        );

        expect(await db.exercisesDao.getAll(), before);
      },
    );

    test('wgrywa cały aktualny asset przy pustej tabeli', () async {
      await repo.syncFromAssets();

      final count = await db.exercisesDao.count();
      expect(count, data.length);
    });

    test(
      'drugie uruchomienie na niepustej, już zsynchronizowanej bazie nie duplikuje wierszy',
      () async {
        await repo.syncFromAssets();
        await repo.syncFromAssets();

        final count = await db.exercisesDao.count();
        expect(count, data.length);
      },
    );

    test(
      'odświeżenie seed data zachowuje favorite w ExerciseFavorites',
      () async {
        await repo.syncFromAssets();
        await repo.toggleFavorite('cw001', true);
        await repo.syncFromAssets();

        expect(await db.exercisesDao.count(), data.length);
        expect((await repo.getById('cw001'))!.ulubione, isTrue);

        final favorite = (await db.select(db.exerciseFavorites).get()).single;
        expect(favorite.exerciseId, 'cw001');
        expect(favorite.syncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      },
    );

    test(
      'watchAll po synchronizacji zwraca cały aktualny katalog z poprawnym mapowaniem list',
      () async {
        await repo.syncFromAssets();

        final all = await repo.watchAll().first;
        expect(all, hasLength(data.length));

        final pompki = all.firstWhere((e) => e.id == 'cw001');
        expect(pompki.sprzet, contains('Masa własna'));
        expect(pompki.kluczoweWskazowki, isNotEmpty);
      },
    );
  });

  test('unfavoriting tombstones the favorite and queues a delete', () async {
    await repo.syncFromAssets();
    await repo.toggleFavorite('cw001', true);
    final activeFavorite = (await db.select(db.exerciseFavorites).get()).single;

    await repo.toggleFavorite('cw001', false);

    final tombstone = (await db.select(db.exerciseFavorites).get()).single;
    final operation = (await db.syncDao.pendingOperations()).single;
    expect(tombstone.syncId, activeFavorite.syncId);
    expect(tombstone.deletedAtUtc, isNotNull);
    expect(operation.entityId, tombstone.syncId);
    expect(operation.deleted, isTrue);
    expect(operation.payload, {'exerciseId': 'cw001'});
  });

  group('assets/data/exercises.json - walidacja statyczna pliku danych', () {
    test('zachowuje stary prefiks 316 ID i zawiera jego rozszerzenie', () {
      expect(data.length, greaterThan(legacyCount));
      expect(data.take(legacyCount).map((e) => e['id']).toSet(), legacyIds);
    });

    test('wszystkie id są unikalne i mają format cwNNN', () {
      final ids = data.map((e) => e['id'] as String).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, [
        for (var i = 1; i <= data.length; i++)
          'cw${i.toString().padLeft(3, '0')}',
      ]);
      for (final id in ids) {
        expect(RegExp(r'^cw\d{3}$').hasMatch(id), isTrue, reason: id);
      }
    });

    test('nazwaPl+partiaGlowna+typ oraz nazwaEn+partiaGlowna+typ są unikalne '
        '(prawdziwa baza Roberta ma kilka nazw powtórzonych w różnych '
        'sekcjach tematycznych Excela dla innej partii/kontekstu użycia, np. '
        '"Band pull-apart" dla tylnych barków i osobno dla romboidów, albo '
        '"Seated cat-cow" jako rozgrzewka vs jako regeneracja - to zamierzone, '
        'różne warianty tego samego ruchu, nie błąd danych)', () {
      final plTriples = data
          .map((e) => '${e['nazwaPl']}|${e['partiaGlowna']}|${e['typ']}')
          .toList();
      final enTriples = data
          .map((e) => '${e['nazwaEn']}|${e['partiaGlowna']}|${e['typ']}')
          .toList();
      expect(plTriples.toSet(), hasLength(plTriples.length));
      expect(enTriples.toSet(), hasLength(enTriples.length));
    });

    test('poziom i typ zgodne z dozwolonymi wartościami enum', () {
      const validPoziom = {'Początkujący', 'Średni', 'Zaawansowany'};
      const validTyp = {
        'Hipertrofia',
        'Siła',
        'Wytrzymałość',
        'Cardio',
        'Rozgrzewka',
        'Regeneracja',
        'Explosive',
        'Rozciąganie',
        'Izometria',
        'Mobilność',
      };
      for (final e in data) {
        expect(validPoziom, contains(e['poziom']), reason: e['id']);
        expect(validTyp, contains(e['typ']), reason: e['id']);
      }
    });

    test('sprzęt jest zawsze podzbiorem znanych opcji sprzętu', () {
      final validSprzet = AppConstants.dostepnySprzetOpcje.toSet();
      for (final e in data) {
        final sprzet = List<String>.from(e['sprzet'] as List);
        for (final s in sprzet) {
          expect(validSprzet, contains(s), reason: '${e['id']}: $s');
        }
      }
    });

    test('każda partiaGlowna mapuje się na jedną z 10 kategorii UI '
        '(mapToKategoria nie zwraca nieznanej wartości)', () {
      const validKategorie = {
        'Klatka',
        'Plecy',
        'Barki',
        'Biceps',
        'Triceps',
        'Nogi',
        'Pośladki',
        'Brzuch',
        'Cardio',
        'Mobilność',
      };
      for (final e in data) {
        final kategoria = mapToKategoria(
          e['partiaGlowna'] as String,
          wzorzecRuchu: e['wzorzecRuchu'] as String,
        );
        expect(
          validKategorie,
          contains(kategoria),
          reason: '${e['id']}: ${e['partiaGlowna']}',
        );
      }
    });
  });
}
