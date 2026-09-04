import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

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
  static const int currentSchemaVersion = 1;

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

    final payload = {
      'schemaVersion': currentSchemaVersion,
      'appVersion': '1.0.0',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': {
        'userProfiles': userProfiles.map((e) => e.toJson()).toList(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'workoutSessions': sessions.map((e) => e.toJson()).toList(),
        'setsLog': sets.map((e) => e.toJson()).toList(),
        'moodEntries': moods.map((e) => e.toJson()).toList(),
        'measurements': measurements.map((e) => e.toJson()).toList(),
        'fitnessTestResults': tests.map((e) => e.toJson()).toList(),
        'personalRecords': prs.map((e) => e.toJson()).toList(),
        'workoutPlans': plans.map((e) => e.toJson()).toList(),
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
  /// czyści wszystkie tabele i wgrywa dane z pliku, w jednej transakcji
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

    try {
      await db.transaction(() async {
        // Czyścimy w kolejności odwrotnej do FK (setsLog referencjonuje
        // workoutSessions, więc setsLog najpierw).
        await db.delete(db.setsLog).go();
        await db.delete(db.workoutSessions).go();
        await db.delete(db.workoutPlans).go();
        await db.delete(db.personalRecords).go();
        await db.delete(db.fitnessTestResults).go();
        await db.delete(db.measurements).go();
        await db.delete(db.moodEntries).go();
        await db.delete(db.exercises).go();
        await db.delete(db.userProfiles).go();

        counts['profil'] = await _restoreUserProfiles(data['userProfiles']);
        counts['ćwiczenia'] = await _restoreExercises(data['exercises']);
        counts['sesje treningowe'] = await _restoreSessions(
          data['workoutSessions'],
        );
        counts['serie'] = await _restoreSets(data['setsLog']);
        counts['wpisy samopoczucia'] = await _restoreMoods(data['moodEntries']);
        counts['pomiary'] = await _restoreMeasurements(data['measurements']);
        counts['testy sprawnościowe'] = await _restoreTests(
          data['fitnessTestResults'],
        );
        counts['rekordy osobiste'] = await _restorePrs(data['personalRecords']);
        counts['plany treningowe'] = await _restorePlans(data['workoutPlans']);
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

  Future<int> _restoreUserProfiles(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = UserProfileData.fromJson(item as Map<String, dynamic>);
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

  Future<int> _restoreSessions(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = WorkoutSessionData.fromJson(item as Map<String, dynamic>);
      // Wstawiamy z zachowaniem oryginalnego ID (żeby setsLog.sesjaId się
      // nie rozjechało) - insertOnConflictUpdate pozwala nadpisać po ID.
      await db
          .into(db.workoutSessions)
          .insertOnConflictUpdate(row.toCompanion(true));
      n++;
    }
    return n;
  }

  Future<int> _restoreSets(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = SetLogData.fromJson(item as Map<String, dynamic>);
      await db.into(db.setsLog).insertOnConflictUpdate(row.toCompanion(true));
      n++;
    }
    return n;
  }

  Future<int> _restoreMoods(dynamic raw) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = MoodEntryData.fromJson(item as Map<String, dynamic>);
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
      final row = MeasurementData.fromJson(item as Map<String, dynamic>);
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
      final row = FitnessTestResultData.fromJson(item as Map<String, dynamic>);
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
      final row = PersonalRecordData.fromJson(item as Map<String, dynamic>);
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
      final row = WorkoutPlanData.fromJson(item as Map<String, dynamic>);
      await db
          .into(db.workoutPlans)
          .insertOnConflictUpdate(row.toCompanion(true));
      n++;
    }
    return n;
  }
}
