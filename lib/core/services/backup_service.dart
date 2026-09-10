import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'package:drift/drift.dart';
import '../sync/sync_store.dart';

/// Wynik operacji importu - do wyświetlenia użytkownikowi.
class ImportResult {
  final bool success;
  final String message;
  final Map<String, int> importedCounts;

  const ImportResult({
    required this.success,
    required this.message,
    this.importedCounts = const {},
  });
}

/// Serwis odpowiedzialny za eksport/import całej bazy danych FitBirek do/z JSON.
///
/// Format pliku (wersjonowany, żeby przyszłe zmiany schematu dało się
/// obsłużyć migracją danych zamiast łamać stare backupy):
/// {
///   "schemaVersion": 1,
///   "appVersion": "1.0.0",
///   "exportedAt": "2026-09-04T12:00:00.000Z",
///   "data": {
///     "userProfiles": [...],
///     "exercises": [...],
///     "workoutSessions": [...],
///     "setsLog": [...],
///     "moodEntries": [...],
///     "measurements": [...],
///     "fitnessTestResults": [...],
///     "personalRecords": [...],
///     "workoutPlans": [...],
///   }
/// }
///
/// Działa identycznie na Web i Android - operuje na Uint8List (bytes),
/// nie na dart:io File, więc nie ma rozjazdu platformowego (patrz
/// ARCHITECTURE.md sekcja o Drift multi-platform dla analogicznego problemu).
class BackupService {
  static const int currentSchemaVersion = 2;

  final AppDatabase db;

  BackupService(this.db);

  // ---------------------------------------------------------------------
  // EKSPORT
  // ---------------------------------------------------------------------

  /// Eksportuje całą bazę danych do bajtów JSON (UTF-8), gotowych do
  /// zapisania/udostępnienia przez share_plus.
  Future<Uint8List> exportToBytes() async {
    final userProfiles = await db.select(db.userProfiles).get();
    final exercises = await db.select(db.exercises).get();
    final sessions = await db.select(db.workoutSessions).get();
    final sets = await db.select(db.setsLog).get();
    final moods = await db.select(db.moodEntries).get();
    final measurements = await db.select(db.measurements).get();
    final tests = await db.select(db.fitnessTestResults).get();
    final prs = await db.select(db.personalRecords).get();
    final plans = await db.select(db.workoutPlans).get();
    final favorites = await db.select(db.exerciseFavorites).get();

    final payload = {
      'schemaVersion': currentSchemaVersion,
      'appVersion': '1.0.0',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': {
        'userProfiles': userProfiles
            .where((r) => r.deletedAtUtc == null)
            .map(_withoutSyncMetadata)
            .toList(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'workoutSessions': sessions
            .where((r) => r.deletedAtUtc == null)
            .map(_withoutSyncMetadata)
            .toList(),
        'setsLog': sets
            .where(
              (r) =>
                  r.deletedAtUtc == null &&
                  sessions.any(
                    (s) => s.id == r.sesjaId && s.deletedAtUtc == null,
                  ),
            )
            .map(_withoutSyncMetadata)
            .toList(),
        'moodEntries': moods
            .where((r) => r.deletedAtUtc == null)
            .map(_withoutSyncMetadata)
            .toList(),
        'measurements': measurements
            .where((r) => r.deletedAtUtc == null)
            .map(_withoutSyncMetadata)
            .toList(),
        'fitnessTestResults': tests
            .where((r) => r.deletedAtUtc == null)
            .map(_withoutSyncMetadata)
            .toList(),
        'personalRecords': prs
            .where((r) => r.deletedAtUtc == null)
            .map(_withoutSyncMetadata)
            .toList(),
        'workoutPlans': plans
            .where((r) => r.deletedAtUtc == null)
            .map(_withoutSyncMetadata)
            .toList(),
        'exerciseFavorites': favorites
            .where((favorite) => favorite.deletedAtUtc == null)
            .map((favorite) => {'exerciseId': favorite.exerciseId})
            .toList(),
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  /// Nazwa pliku dla eksportu, np. "fitbirek_backup_2026-09-04.json".
  String suggestedFileName() {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'fitbirek_backup_$date.json';
  }

  // ---------------------------------------------------------------------
  // IMPORT
  // ---------------------------------------------------------------------

  /// Importuje bazę danych z bajtów JSON. Strategia: "zastąp wszystko" -
  /// zastępuje widoczne dane, zachowując tombstone'y sesji potrzebne do sync,
  /// i wgrywa dane z pliku w jednej transakcji
  /// (jeśli coś pójdzie źle w połowie, baza wraca do stanu przed importem -
  /// nigdy nie zostaje w połowie zaimportowanym, uszkodzonym stanie).
  Future<ImportResult> importFromBytes(Uint8List bytes) async {
    Map<String, dynamic> payload;
    try {
      final jsonString = utf8.decode(bytes);
      payload = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return ImportResult(
        success: false,
        message:
            'Nieprawidłowy plik - to nie jest poprawny plik backupu '
            'FitBirek (błąd parsowania JSON).',
      );
    }

    final schemaVersion = payload['schemaVersion'] as int?;
    if (schemaVersion == null) {
      return const ImportResult(
        success: false,
        message:
            'Nieprawidłowy plik - brak informacji o wersji schematu. '
            'To nie jest plik wygenerowany przez FitBirek.',
      );
    }
    if (schemaVersion > currentSchemaVersion) {
      return ImportResult(
        success: false,
        message:
            'Ten plik backupu pochodzi z nowszej wersji aplikacji '
            '(schemaVersion: $schemaVersion, ta aplikacja obsługuje do '
            '$currentSchemaVersion). Zaktualizuj aplikację przed importem.',
      );
    }

    final data = payload['data'] as Map<String, dynamic>?;
    if (data == null) {
      return const ImportResult(
        success: false,
        message: 'Nieprawidłowy plik - brak sekcji danych.',
      );
    }

    final counts = <String, int>{};
    final favoritesToRestore = schemaVersion == 1
        ? _legacyFavorites(data['exercises'])
        : data['exerciseFavorites'];

    try {
      await db.transaction(() async {
        final profileBefore = await db.userProfileDao.watchProfileOnce();
        final favoritesBefore = await db.select(db.exerciseFavorites).get();
        await SyncStore(db).enqueueAll(deleted: true);
        // Czyścimy w kolejności odwrotnej do FK (setsLog referencjonuje
        // workoutSessions, więc setsLog najpierw).
        await db.delete(db.setsLog).go();
        // A remote device may have published children not yet pulled. Keep
        // their UUID -> integer parent mappings even after the delete is acked.
        final now = DateTime.now().toUtc();
        await (db.update(
          db.workoutSessions,
        )..where((s) => s.deletedAtUtc.isNull())).write(
          WorkoutSessionsCompanion(
            deletedAtUtc: Value(now),
            updatedAtUtc: Value(now),
          ),
        );
        await db.delete(db.exerciseFavorites).go();
        await db.delete(db.workoutPlans).go();
        await db.delete(db.personalRecords).go();
        await db.delete(db.fitnessTestResults).go();
        await db.delete(db.measurements).go();
        await db.delete(db.moodEntries).go();
        await db.delete(db.exercises).go();
        await db.delete(db.userProfiles).go();

        counts['profil'] = await _restoreUserProfiles(data['userProfiles']);
        counts['ćwiczenia'] = await _restoreExercises(data['exercises']);
        final restoredSessionIds = await _restoreSessions(
          data['workoutSessions'],
        );
        counts['sesje treningowe'] = restoredSessionIds.length;
        counts['serie'] = await _restoreSets(
          data['setsLog'],
          restoredSessionIds,
        );
        counts['wpisy samopoczucia'] = await _restoreMoods(data['moodEntries']);
        counts['pomiary'] = await _restoreMeasurements(data['measurements']);
        counts['testy sprawnościowe'] = await _restoreTests(
          data['fitnessTestResults'],
        );
        counts['rekordy osobiste'] = await _restorePrs(data['personalRecords']);
        counts['plany treningowe'] = await _restorePlans(data['workoutPlans']);
        counts['ulubione ćwiczenia'] = await _restoreFavorites(
          favoritesToRestore,
        );
        // Singleton records keep their server identity/version. Other restored
        // rows receive fresh UUIDs, with deletes queued for the replaced rows.
        if (profileBefore != null) {
          await db
              .update(db.userProfiles)
              .write(
                UserProfilesCompanion(
                  syncId: Value(profileBefore.syncId),
                  syncVersion: Value(profileBefore.syncVersion),
                ),
              );
        } else {
          await db
              .update(db.userProfiles)
              .write(
                UserProfilesCompanion(
                  syncId: Value(await db.syncDao.singletonId('profile')),
                ),
              );
        }
        for (final favorite in await db.select(db.exerciseFavorites).get()) {
          final before = favoritesBefore
              .where((f) => f.exerciseId == favorite.exerciseId)
              .firstOrNull;
          await (db.update(
            db.exerciseFavorites,
          )..where((f) => f.exerciseId.equals(favorite.exerciseId))).write(
            ExerciseFavoritesCompanion(
              syncId: Value(
                before?.syncId ??
                    await db.syncDao.singletonId(
                      'favorite:${favorite.exerciseId}',
                    ),
              ),
              syncVersion: Value(before?.syncVersion ?? 0),
            ),
          );
        }
        await SyncStore(db).enqueueAll();
      });
    } catch (e) {
      return ImportResult(
        success: false,
        message:
            'Import nie powiódł się, baza danych pozostała '
            'niezmieniona (transakcja wycofana). Błąd: $e',
      );
    }

    final totalRecords = counts.values.fold<int>(0, (a, b) => a + b);
    return ImportResult(
      success: true,
      message:
          'Import zakończony pomyślnie. Wczytano $totalRecords '
          'rekordów.',
      importedCounts: counts,
    );
  }

  // --- Helpery restore per-tabela (bezpieczne na null/brak sekcji) -------

  Map<String, dynamic> _withoutSyncMetadata(dynamic row) {
    final json = Map<String, dynamic>.from(row.toJson() as Map);
    json.remove('syncId');
    json.remove('syncVersion');
    json.remove('updatedAtUtc');
    json.remove('deletedAtUtc');
    return json;
  }

  Map<String, dynamic> _withFreshSyncMetadata(dynamic raw) {
    final row = Map<String, dynamic>.from(raw as Map);
    final now = DateTime.now().toUtc().toIso8601String();
    row['syncId'] = Uuid().v4();
    row['syncVersion'] = 0;
    row['updatedAtUtc'] = now;
    row['deletedAtUtc'] = null;
    return row;
  }

  List<Map<String, String>> _legacyFavorites(dynamic raw) {
    if (raw == null) return const [];
    return (raw as List)
        .cast<Map>()
        .where((exercise) => exercise['ulubione'] == true)
        .map((exercise) => {'exerciseId': exercise['id'] as String})
        .toList();
  }

  Future<int> _restoreUserProfiles(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = UserProfileData.fromJson(_withFreshSyncMetadata(item));
      await db.into(db.userProfiles).insert(row.toCompanion(true));
      n++;
    }
    return n;
  }

  Future<int> _restoreExercises(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = ExerciseData.fromJson(item as Map<String, dynamic>);
      await db.into(db.exercises).insert(row.toCompanion(true));
      n++;
    }
    return n;
  }

  Future<Map<int, int>> _restoreSessions(dynamic raw) async {
    if (raw == null) return {};
    final list = raw as List;
    final ids = <int, int>{};
    for (final item in list) {
      final row = WorkoutSessionData.fromJson(_withFreshSyncMetadata(item));
      if (ids.containsKey(row.id)) {
        throw const FormatException('Duplicate backup session ID');
      }
      ids[row.id] = await db
          .into(db.workoutSessions)
          .insert(row.toCompanion(true).copyWith(id: const Value.absent()));
    }
    return ids;
  }

  Future<int> _restoreSets(dynamic raw, Map<int, int> sessionIds) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = SetLogData.fromJson(_withFreshSyncMetadata(item));
      final parent = sessionIds[row.sesjaId];
      if (parent == null) {
        throw const FormatException('Missing backup session ID');
      }
      await db
          .into(db.setsLog)
          .insertOnConflictUpdate(
            row.toCompanion(true).copyWith(sesjaId: Value(parent)),
          );
      n++;
    }
    return n;
  }

  Future<int> _restoreMoods(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = MoodEntryData.fromJson(_withFreshSyncMetadata(item));
      await db
          .into(db.moodEntries)
          .insertOnConflictUpdate(row.toCompanion(true));
      n++;
    }
    return n;
  }

  Future<int> _restoreMeasurements(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = MeasurementData.fromJson(_withFreshSyncMetadata(item));
      await db
          .into(db.measurements)
          .insertOnConflictUpdate(row.toCompanion(true));
      n++;
    }
    return n;
  }

  Future<int> _restoreTests(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = FitnessTestResultData.fromJson(_withFreshSyncMetadata(item));
      await db
          .into(db.fitnessTestResults)
          .insertOnConflictUpdate(row.toCompanion(true));
      n++;
    }
    return n;
  }

  Future<int> _restorePrs(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = PersonalRecordData.fromJson(_withFreshSyncMetadata(item));
      await db
          .into(db.personalRecords)
          .insertOnConflictUpdate(row.toCompanion(true));
      n++;
    }
    return n;
  }

  Future<int> _restorePlans(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = WorkoutPlanData.fromJson(_withFreshSyncMetadata(item));
      await db
          .into(db.workoutPlans)
          .insertOnConflictUpdate(row.toCompanion(true));
      n++;
    }
    return n;
  }

  Future<int> _restoreFavorites(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final exerciseId = (item as Map<String, dynamic>)['exerciseId'] as String;
      final now = DateTime.now().toUtc();
      await db
          .into(db.exerciseFavorites)
          .insert(
            ExerciseFavoritesCompanion.insert(
              exerciseId: exerciseId,
              syncId: Value(Uuid().v4()),
              updatedAtUtc: Value(now),
            ),
          );
      n++;
    }
    return n;
  }
}
