// Testy BackupService - eksport/import całej bazy danych do/z JSON.
//
// Używamy AppDatabase.forTesting() z NativeDatabase.memory() - baza w
// pamięci, nie na dysku, każdy test dostaje czystą instancję.

import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';

void main() {
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
    },
  );
}
