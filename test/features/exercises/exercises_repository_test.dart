// Testy ExercisesRepository - import przyrostowy (syncFromAssets) z
// assets/data/exercises.json do bazy Drift w pamięci, oraz podstawowa
// walidacja rozmiaru/struktury samego pliku danych.

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/utils/partia_kategoria.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ExercisesRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ExercisesRepository(db);
  });

  tearDown(() async => await db.close());

  group('syncFromAssets - import przyrostowy', () {
    test('wgrywa całą bazę (316 ćwiczeń) przy pustej tabeli', () async {
      await repo.syncFromAssets();

      final count = await db.exercisesDao.count();
      expect(count, 316);
    });

    test(
      'drugie uruchomienie na niepustej, już zsynchronizowanej bazie nie duplikuje wierszy',
      () async {
        await repo.syncFromAssets();
        await repo.syncFromAssets();

        final count = await db.exercisesDao.count();
        expect(count, 316);
      },
    );

    test(
      'odświeżenie seed data zachowuje favorite w ExerciseFavorites',
      () async {
        await repo.syncFromAssets();
        await repo.toggleFavorite('cw001', true);
        await repo.syncFromAssets();

        expect(await db.exercisesDao.count(), 316);
        expect((await repo.getById('cw001'))!.ulubione, isTrue);

        final favorite = (await db.select(db.exerciseFavorites).get()).single;
        expect(favorite.exerciseId, 'cw001');
        expect(favorite.syncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      },
    );

    test(
      'watchAll po synchronizacji zwraca 316 ćwiczeń z poprawnym mapowaniem list',
      () async {
        await repo.syncFromAssets();

        final all = await repo.watchAll().first;
        expect(all, hasLength(316));

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
    late List<dynamic> data;

    setUpAll(() {
      final file = File('assets/data/exercises.json');
      data = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    });

    test('zawiera dokładnie 316 pozycji', () {
      expect(data, hasLength(316));
    });

    test('wszystkie id są unikalne i mają format cwNNN', () {
      final ids = data.map((e) => e['id'] as String).toList();
      expect(ids.toSet(), hasLength(ids.length));
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
      const validSprzet = {
        'Masa własna',
        'Hantle',
        'Ławeczka',
        'Drążek',
        'Gumy oporowe',
        'Bieżnia',
        'Skakanka',
        'Krzesło',
        'Ręcznik',
      };
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
