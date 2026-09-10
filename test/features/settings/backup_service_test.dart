// Testy BackupService - eksport/import całej bazy danych do/z JSON.
//
// Używamy AppDatabase.forTesting() z NativeDatabase.memory() - baza w
// pamięci, nie na dysku, każdy test dostaje czystą instancję.

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';

Future<void> seedSyncStateAndOutbox(AppDatabase db) async {
  await db
      .into(db.syncState)
      .insert(
        SyncStateCompanion.insert(
          id: const Value(1),
          accountId: 'account-before-restore',
          deviceId: 'device-before-restore',
        ),
      );
  await db.syncDao.enqueueUpsert(
    entityType: SyncEntityType.mood,
    entityId: 'pending-mood',
    baseVersion: 0,
    payload: const {'energia': 8},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'eksport pustej bazy tworzy poprawny JSON ze wszystkimi sekcjami',
    () async {
      final bytes = await service.exportToBytes();
      expect(bytes, isNotEmpty);

      final jsonString = String.fromCharCodes(bytes);
      expect(jsonString, contains('"schemaVersion"'));
      expect(jsonString, contains('"userProfiles"'));
      expect(jsonString, contains('"exercises"'));
      expect(jsonString, contains('"workoutSessions"'));
      expect(jsonString, contains('"setsLog"'));
      expect(jsonString, contains('"personalRecords"'));
    },
  );

  test('schema-v1 backup restores with fresh sync metadata', () async {
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'schemaVersion': 1,
          'data': {
            'userProfiles': [
              {
                'id': 1,
                'imie': 'Robert',
                'wiek': 35,
                'wzrostCm': 180.0,
                'wagaKg': 90.0,
                'cel': 'sila',
                'dostepnySprzet': '[]',
                'onboardingZakonczony': true,
                'dataUtworzenia': '2026-09-08T10:00:00.000Z',
              },
            ],
            'exercises': <Object?>[],
            'workoutSessions': <Object?>[],
            'setsLog': <Object?>[],
            'moodEntries': <Object?>[],
            'measurements': <Object?>[],
            'fitnessTestResults': <Object?>[],
            'personalRecords': <Object?>[],
            'workoutPlans': <Object?>[],
          },
        }),
      ),
    );
    await seedSyncStateAndOutbox(db);

    final result = await service.importFromBytes(bytes);

    expect(result.success, isTrue);
    final profile = (await db.select(db.userProfiles).get()).single;
    expect(profile.syncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(profile.syncVersion, 0);
    expect(profile.deletedAtUtc, isNull);
    expect(profile.updatedAtUtc.toUtc(), isA<DateTime>());
    expect((await db.syncDao.readState())!.accountId, 'account-before-restore');
    expect(
      (await db.syncDao.pendingOperations()).any(
        (o) => o.entityType == SyncEntityType.profile && !o.deleted,
      ),
      isTrue,
    );
  });

  test('schema-v1 backup restores legacy exercise favorites', () async {
    final exercises = ExercisesRepository(db);
    await exercises.syncFromAssets();
    final exported =
        jsonDecode(utf8.decode(await service.exportToBytes()))
            as Map<String, dynamic>;
    exported['schemaVersion'] = 1;
    final data = exported['data'] as Map<String, dynamic>;
    data.remove('exerciseFavorites');
    final legacyFavorite = (data['exercises'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((exercise) => exercise['id'] == 'cw001');
    legacyFavorite['ulubione'] = true;

    await exercises.toggleFavorite('cw002', true);
    await seedSyncStateAndOutbox(db);

    final result = await service.importFromBytes(
      Uint8List.fromList(utf8.encode(jsonEncode(exported))),
    );

    expect(result.success, isTrue);
    final favorites = await db.select(db.exerciseFavorites).get();
    expect(favorites, hasLength(1));
    expect(favorites.single.exerciseId, 'cw001');
    expect(favorites.single.deletedAtUtc, isNull);
    expect((await exercises.getById('cw001'))!.ulubione, isTrue);
    expect((await exercises.getById('cw002'))!.ulubione, isFalse);
    expect((await db.syncDao.readState())!.accountId, 'account-before-restore');
    expect(
      (await db.syncDao.pendingOperations()).any(
        (o) => o.entityType == SyncEntityType.exerciseFavorite && !o.deleted,
      ),
      isTrue,
    );
  });

  test('schema-v2 export and import preserves exercise favorites', () async {
    final exercises = ExercisesRepository(db);
    await exercises.syncFromAssets();
    await exercises.toggleFavorite('cw001', true);
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(
            id: const Value(1),
            accountId: 'account-before-backup',
            deviceId: 'device-before-backup',
          ),
        );
    final originalFavorite =
        (await db.select(db.exerciseFavorites).get()).single;

    final bytes = await service.exportToBytes();
    final exported = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final data = exported['data'] as Map<String, dynamic>;

    expect(exported['schemaVersion'], 2);
    expect(data['exerciseFavorites'], [
      {'exerciseId': 'cw001'},
    ]);
    expect(data.containsKey('syncState'), isFalse);
    expect(data.containsKey('syncOutbox'), isFalse);

    await db.delete(db.exerciseFavorites).go();
    await db.delete(db.exercises).go();
    expect(await db.syncDao.readState(), isNotNull);
    expect(await db.syncDao.pendingOperations(), isNotEmpty);

    final result = await service.importFromBytes(bytes);

    expect(result.success, isTrue);
    final restoredFavorite =
        (await db.select(db.exerciseFavorites).get()).single;
    expect(restoredFavorite.exerciseId, 'cw001');
    expect(restoredFavorite.syncId, isNot(originalFavorite.syncId));
    expect(restoredFavorite.syncVersion, 0);
    expect((await exercises.getById('cw001'))!.ulubione, isTrue);
    expect((await db.syncDao.readState())!.accountId, 'account-before-backup');
    expect(
      (await db.syncDao.pendingOperations()).any(
        (o) => o.entityType == SyncEntityType.exerciseFavorite && !o.deleted,
      ),
      isTrue,
    );
  });

  test(
    'round-trip: eksport -> import odtwarza dane profilu użytkownika',
    () async {
      // Wstaw profil
      await db
          .into(db.userProfiles)
          .insert(
            UserProfilesCompanion.insert(
              wiek: 47,
              wzrostCm: 180.0,
              wagaKg: 94.0,
              cel: 'redukcja',
              dostepnySprzet: '["Hantle","Ławka"]',
            ),
          );
      final bytes = await service.exportToBytes();

      // Wyczyść bazę ręcznie, żeby potwierdzić że import faktycznie przywraca
      // dane (a nie tylko "nic nie usuwał").
      await db.delete(db.userProfiles).go();
      final afterClear = await db.select(db.userProfiles).get();
      expect(afterClear, isEmpty);

      final result = await service.importFromBytes(bytes);

      expect(result.success, isTrue);
      final profiles = await db.select(db.userProfiles).get();
      expect(profiles, hasLength(1));
      expect(profiles.first.wiek, 47);
      expect(profiles.first.wagaKg, 94.0);
      expect(profiles.first.cel, 'redukcja');
    },
  );

  test(
    'round-trip: sesja treningowa + serie zachowują relację (sesjaId)',
    () async {
      final sessionId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(dataStart: DateTime(2026, 1, 15)),
          );

      await db
          .into(db.setsLog)
          .insert(
            SetsLogCompanion.insert(
              sesjaId: sessionId,
              cwiczenieId: 'wyciskanie_hantli',
              nazwaCwiczeniaPl: 'Wyciskanie hantli',
              numerSerii: 1,
              ciezarKg: const Value(15.0),
              powtorzenia: const Value(10),
            ),
          );

      final bytes = await service.exportToBytes();

      await db.delete(db.setsLog).go();
      await db.delete(db.workoutSessions).go();

      final result = await service.importFromBytes(bytes);
      expect(result.success, isTrue);

      final sessions = await db.select(db.workoutSessions).get();
      final sets = await db.select(db.setsLog).get();
      expect(sessions, hasLength(1));
      expect(sets, hasLength(1));
      // Kluczowa weryfikacja: relacja FK (sesjaId) przetrwała round-trip.
      expect(sets.first.sesjaId, sessions.first.id);
      expect(sets.first.ciezarKg, 15.0);
    },
  );

  test('import odrzuca plik z nieznanym/przyszłym schemaVersion', () async {
    final fakeBytes = '{"schemaVersion": 999, "data": {}}'.codeUnits;
    final result = await service.importFromBytes(Uint8List.fromList(fakeBytes));

    expect(result.success, isFalse);
    expect(result.message, contains('nowszej wersji'));
  });

  test('import odrzuca nieprawidłowy JSON bez crashowania', () async {
    final garbage = 'to nie jest json {{{'.codeUnits;
    final result = await service.importFromBytes(Uint8List.fromList(garbage));

    expect(result.success, isFalse);
    expect(result.message, contains('Nieprawidłowy plik'));
  });

  test(
    'import zachowuje bazę niezmienioną gdy transakcja się nie powiedzie',
    () async {
      // Wstaw dane, które MUSZĄ przetrwać nieudany import.
      await db
          .into(db.userProfiles)
          .insert(
            UserProfilesCompanion.insert(
              wiek: 47,
              wzrostCm: 180.0,
              wagaKg: 94.0,
              cel: 'sila',
              dostepnySprzet: '[]',
            ),
          );
      final exercises = ExercisesRepository(db);
      await exercises.syncFromAssets();
      await exercises.toggleFavorite('cw001', true);
      await seedSyncStateAndOutbox(db);
      final stateBefore = await db.syncDao.readState();
      final pendingBefore = await db.syncDao.pendingOperations();

      // JSON poprawny strukturalnie (przechodzi walidację schemaVersion), ale
      // z zepsutym typem danych w środku - musi wywalić się w transakcji.
      const corruptButValidJson = '''
    {
      "schemaVersion": 1,
      "data": {
        "userProfiles": [{"nieistniejące_pole": "wartość"}]
      }
    }
    ''';
      final result = await service.importFromBytes(
        Uint8List.fromList(corruptButValidJson.codeUnits),
      );

      expect(result.success, isFalse);

      // Profil wstawiony PRZED próbą importu powinien przetrwać (rollback).
      final profiles = await db.select(db.userProfiles).get();
      expect(profiles, hasLength(1));
      expect(profiles.first.cel, 'sila');
      expect((await exercises.getById('cw001'))!.ulubione, isTrue);
      expect((await db.syncDao.readState())!.accountId, stateBefore!.accountId);
      expect(
        (await db.syncDao.pendingOperations()).map(
          (operation) => operation.operationId,
        ),
        pendingBefore.map((operation) => operation.operationId),
      );
    },
  );
}
