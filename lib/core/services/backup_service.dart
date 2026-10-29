import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../app/constants.dart';

import '../database/app_database.dart';
import 'package:drift/drift.dart';
import '../sync/sync_store.dart';
import '../sync/user_collections.dart';
import '../../features/workout/domain/workout_guidance.dart';
import '../../features/progress/tests/domain/fitness_protocol.dart';
import '../models/fitness_test.dart';
import '../models/set_role.dart';
import '../../features/planner/domain/structured_plan.dart';
import '../../features/schedule/domain/training_program.dart';
import '../../features/schedule/domain/weekly_schedule.dart';

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
  static const int currentSchemaVersion = 4;

  final AppDatabase db;

  BackupService(this.db);

  // ---------------------------------------------------------------------
  // EKSPORT
  // ---------------------------------------------------------------------

  /// Eksportuje całą bazę danych do bajtów JSON (UTF-8), gotowych do
  /// zapisania/udostępnienia przez share_plus.
  Future<Uint8List> exportToBytes() async {
    // Materialize every source in one snapshot, so concurrent writes cannot
    // mix parent/child revisions or health imports in the same archive.
    final (
      userProfiles,
      exercises,
      sessions,
      sets,
      moods,
      measurements,
      tests,
      prs,
      plans,
      favorites,
      healthSamples,
      deferredRecords,
      pendingOperations,
    ) = await db.transaction(() async {
      return (
        await db.select(db.userProfiles).get(),
        await db.select(db.exercises).get(),
        await db.select(db.workoutSessions).get(),
        await db.select(db.setsLog).get(),
        await db.select(db.moodEntries).get(),
        await db.select(db.measurements).get(),
        await db.select(db.fitnessTestResults).get(),
        await db.select(db.personalRecords).get(),
        await db.select(db.workoutPlans).get(),
        await db.select(db.exerciseFavorites).get(),
        await db.select(db.healthSamples).get(),
        await db.select(db.syncDeferredRecords).get(),
        await db.select(db.syncOutbox).get(),
      );
    });

    // Filtering, archive mapping and JSON encoding do not hold the transaction.
    final references = _programReferences(
      userProfiles.where((p) => p.deletedAtUtc == null),
    );
    final referencedSessions = sessions
        .where(
          (s) =>
              references.retainAll ||
              references.sessions.contains(_identityKey(s.syncId)),
        )
        .map((s) => s.id)
        .toSet();
    final exportedSessions = sessions
        .where(
          (s) => s.deletedAtUtc == null || referencedSessions.contains(s.id),
        )
        .toList();
    // Performed links remain history after their set is deleted, including in
    // ordinary guided v1/v2 sessions with no program. Retain only their own
    // referenced tombstones, not unrelated deleted sets or sessions.
    final performedSets = <(int, String)>{
      for (final session in exportedSessions)
        for (final event
            in WorkoutGuidance.tryRead(session.guidanceJson)?.events ??
                const <Map<String, Object?>>[])
          if (event['type'] == 'performed')
            (session.id, _identityKey(event['setSyncId'] as String)),
    };
    final payload = {
      'schemaVersion': currentSchemaVersion,
      'appVersion': AppConstants.appVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': {
        // Recovery evidence, not portable authority to retry another account's
        // operation IDs. Keep JSON strings (especially attempted bytes) intact.
        'syncRecovery': {
          'deferredRecords': deferredRecords.map((r) => r.toJson()).toList(),
          'outbox': pendingOperations.map((r) => r.toJson()).toList(),
        },
        'userProfiles': userProfiles
            .where((r) => r.deletedAtUtc == null)
            .map(_withoutSyncMetadata)
            .toList(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'workoutSessions': exportedSessions
            .map(
              (r) => {
                ..._archiveReferencedRow(r),
                'archiveSessionSyncId': r.syncId,
              },
            )
            .toList(),
        'setsLog': sets
            .where(
              (r) =>
                  referencedSessions.contains(r.sesjaId) ||
                  performedSets.contains((r.sesjaId, _identityKey(r.syncId))) ||
                  (r.deletedAtUtc == null &&
                      sessions.any(
                        (s) => s.id == r.sesjaId && s.deletedAtUtc == null,
                      )),
            )
            .map(
              (s) => {
                ..._archiveReferencedRow(s),
                'archiveSetSyncId': s.syncId,
              },
            )
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
            .where(
              (r) =>
                  r.deletedAtUtc == null ||
                  references.retainAll ||
                  references.plans.contains(_identityKey(r.syncId)),
            )
            .map(
              (r) => {
                ..._archiveReferencedRow(r),
                'archivePlanSyncId': r.syncId,
              },
            )
            .toList(),
        'exerciseFavorites': favorites
            .where((favorite) => favorite.deletedAtUtc == null)
            .map((favorite) => {'exerciseId': favorite.exerciseId})
            .toList(),
        // Informational archive only: imports are refreshed from the account's
        // server, never restored as user-created records or new UUIDs.
        'healthSamples': healthSamples
            .where((s) => s.deletedAtUtc == null)
            .map(_withoutSyncMetadata)
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

    final schemaVersion = payload['schemaVersion'];
    if (schemaVersion is! int || schemaVersion < 1) {
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
        // A replace-style restore cannot safely delete quarantined source data.
        // Export remains lossless; refusal retains raw rows and pending outcomes.
        await _requireReadableCurrentExtensions();
        final profileCollectionClears = <String>{};
        final profileBefore = await db.userProfileDao.watchProfileOnce();
        final favoritesBefore = await db.select(db.exerciseFavorites).get();
        final retained = await _retainedProgramRows(profileBefore);
        await SyncStore(db).enqueueAll(deleted: true);
        // Retained immutable program definitions still own their old references.
        // Keep their full rows as tombstones, including evidence and guidance
        // links. Fresh restores use new integer keys as well as new UUIDs.
        await (db.delete(
          db.setsLog,
        )..where((s) => s.sesjaId.isNotIn(retained.sessions))).go();
        await db.delete(db.workoutDrafts).go();
        // A remote device may have published children not yet pulled. Keep
        // their UUID -> integer parent mappings even after the delete is acked.
        final now = DateTime.now().toUtc();
        await (db.update(
          db.setsLog,
        )..where((s) => s.deletedAtUtc.isNull())).write(
          SetsLogCompanion(deletedAtUtc: Value(now), updatedAtUtc: Value(now)),
        );
        await (db.update(
          db.workoutSessions,
        )..where((s) => s.deletedAtUtc.isNull())).write(
          WorkoutSessionsCompanion(
            deletedAtUtc: Value(now),
            updatedAtUtc: Value(now),
          ),
        );
        await db.delete(db.exerciseFavorites).go();
        await (db.delete(
          db.workoutPlans,
        )..where((p) => p.id.isNotIn(retained.plans))).go();
        await (db.update(
          db.workoutPlans,
        )..where((p) => p.deletedAtUtc.isNull())).write(
          WorkoutPlansCompanion(
            deletedAtUtc: Value(now),
            updatedAtUtc: Value(now),
          ),
        );
        await db.delete(db.personalRecords).go();
        await db.delete(db.fitnessTestResults).go();
        await db.delete(db.measurements).go();
        await db.delete(db.moodEntries).go();
        await db.delete(db.exercises).go();
        await db.delete(db.userProfiles).go();

        counts['ćwiczenia'] = await _restoreExercises(data['exercises']);
        final sessionUuids = <String, String>{}, planUuids = <String, String>{};
        final restoredSessionIds = await _restoreSessions(
          data['workoutSessions'],
          sessionUuids,
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
        counts['plany treningowe'] = await _restorePlans(
          data['workoutPlans'],
          planUuids,
        );
        counts['profil'] = await _restoreUserProfiles(
          data['userProfiles'],
          profileBefore,
          profileCollectionClears,
          planUuids,
          sessionUuids,
        );
        await _remapScheduleReferences(planUuids, sessionUuids);
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
        await SyncStore(
          db,
        ).enqueueAll(profileCollectionClears: profileCollectionClears);
        if (schemaVersion == 4 && data['syncRecovery'] != null) {
          final recovery = Map<String, dynamic>.from(
            data['syncRecovery'] as Map,
          );
          if ((recovery['deferredRecords'] as List).isNotEmpty ||
              (recovery['outbox'] as List).isNotEmpty) {
            await db
                .into(db.syncDeferredRecords)
                .insert(
                  SyncDeferredRecordsCompanion.insert(
                    entityType: '_backupRecoveryArchive',
                    entityId: const Uuid().v4(),
                    version: 1,
                    recordJson: jsonEncode({
                      'schemaVersion': 1,
                      'recovery': recovery,
                    }),
                  ),
                );
          }
        }
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
          'rekordów. Apple Zdrowie: importy i oczekujące usunięcia pozostają '
          'bez zmian; próbki z pliku nie są odtwarzane. Na nowym urządzeniu '
          'pobierze je synchronizacja bieżącego konta.',
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

  /// Tombstones in the dependency closure are data, not live copies to revive.
  /// This key is backup4-only metadata, never part of the sync wire payload.
  Map<String, dynamic> _archiveReferencedRow(dynamic row) => {
    ..._withoutSyncMetadata(row),
    if (row.deletedAtUtc != null)
      'archiveDeletedAtUtc': (row.deletedAtUtc as DateTime)
          .toUtc()
          .toIso8601String(),
  };

  Map<String, dynamic> _withFreshSyncMetadata(
    dynamic raw, {
    bool preserveArchivedDeletion = false,
  }) {
    final row = Map<String, dynamic>.from(raw as Map);
    final now = DateTime.now().toUtc().toIso8601String();
    row['syncId'] = Uuid().v4();
    row['syncVersion'] = 0;
    row['updatedAtUtc'] = now;
    final deletion = preserveArchivedDeletion
        ? row['archiveDeletedAtUtc']
        : null;
    if (deletion != null &&
        (deletion is! String || DateTime.tryParse(deletion)?.isUtc != true)) {
      throw const FormatException(
        'Nieprawidłowy tombstone referencji w backupie.',
      );
    }
    row['deletedAtUtc'] = deletion;
    return row;
  }

  String _identityKey(String value) =>
      UserCollections.isUuid(value) ? value.toLowerCase() : value;

  ({Set<String> plans, Set<String> sessions, bool retainAll})
  _programReferences(Iterable<UserProfileData> profiles) {
    final plans = <String>{}, sessions = <String>{};
    var retainAll = false;
    for (final profile in profiles) {
      if (profile.trainingProgramsJson == null) continue;
      try {
        final collection = UserCollections.validate(
          'trainingPrograms',
          jsonDecode(profile.trainingProgramsJson!),
        );
        for (final e in collection['entries'] as List) {
          final definition = e['kind'] == 'program' ? e : e['programSnapshot'];
          plans.addAll(
            (definition['planSyncIds'] as List).cast<String>().map(
              _identityKey,
            ),
          );
          if (e['sessionSyncId'] is String) {
            sessions.add(_identityKey(e['sessionSyncId'] as String));
          }
        }
      } on FormatException {
        // Future/quarantined collections must still be exportable raw. Without
        // a readable reference graph, keep the complete dependency superset.
        retainAll = true;
      }
    }
    return (plans: plans, sessions: sessions, retainAll: retainAll);
  }

  Future<({Set<int> plans, Set<int> sessions})> _retainedProgramRows(
    UserProfileData? profile,
  ) async {
    final references = _programReferences([if (profile != null) profile]);
    final plans = (await db.select(db.workoutPlans).get())
        .where(
          (p) =>
              references.retainAll ||
              references.plans.contains(_identityKey(p.syncId)),
        )
        .toList();
    final sessions = (await db.select(db.workoutSessions).get())
        .where(
          (s) =>
              references.retainAll ||
              references.sessions.contains(_identityKey(s.syncId)),
        )
        .toList();
    if (!references.plans.every(
          plans.map((p) => _identityKey(p.syncId)).toSet().contains,
        ) ||
        !references.sessions.every(
          sessions.map((s) => _identityKey(s.syncId)).toSet().contains,
        )) {
      throw const FormatException(
        'Brak lokalnej referencji zachowywanego programu.',
      );
    }
    final ids = sessions.map((s) => s.id).toSet();
    final sets = ids.isEmpty
        ? <SetLogData>[]
        : await (db.select(
            db.setsLog,
          )..where((s) => s.sesjaId.isIn(ids))).get();
    final byUuid = {for (final s in sets) _identityKey(s.syncId): s};
    for (final session in sessions) {
      if (session.guidanceJson == null) continue;
      final guidance = WorkoutGuidance.validateJson(
        jsonDecode(session.guidanceJson!),
      );
      for (final event in guidance.events.where(
        (e) => e['type'] == 'performed',
      )) {
        final set = byUuid[_identityKey(event['setSyncId'] as String)];
        if (set == null || set.sesjaId != session.id) {
          throw const FormatException(
            'Brak lokalnego dowodu powiązanego z zachowywanym programem.',
          );
        }
      }
    }
    return (plans: plans.map((p) => p.id).toSet(), sessions: ids);
  }

  List<Map<String, String>> _legacyFavorites(dynamic raw) {
    if (raw == null) return const [];
    return (raw as List)
        .cast<Map>()
        .where((exercise) => exercise['ulubione'] == true)
        .map((exercise) => {'exerciseId': exercise['id'] as String})
        .toList();
  }

  Future<int> _restoreUserProfiles(
    dynamic raw,
    UserProfileData? previous,
    Set<String> clearedCollections,
    Map<String, String> plans,
    Map<String, String> sessions,
  ) async {
    final list = raw == null ? const [] : raw as List;
    if (list.isEmpty &&
        previous != null &&
        UserCollections.keys.any(
          (key) => previous.toJson()['${key}Json'] != null,
        )) {
      // No source profile is not an instruction to erase newer extensions.
      // Keep its scalar envelope as well: there is no imported scalar authority.
      await db.into(db.userProfiles).insert(previous.toCompanion(false));
      return 1;
    }
    var n = 0;
    for (final item in list) {
      final json = _withFreshSyncMetadata(item);
      final old = previous?.toJson();
      for (final key in UserCollections.keys) {
        final column = '${key}Json';
        final stored = old?[column] as String?;
        final incoming = json[column] as String?;
        if (!json.containsKey(column)) {
          json[column] = stored;
        } else if (incoming == null &&
            {'fitnessProtocols', 'trainingPrograms'}.contains(key)) {
          // Rules and tombstones are never erased by NULL or an old backup.
          json[column] = stored;
        } else if (incoming == null) {
          // NULL in the archive is an explicit intent, unlike a legacy missing
          // key. Carry it into the first wire operation before coalescing.
          clearedCollections.add(key);
        } else {
          final merged = UserCollections.merge(
            key,
            stored == null ? null : jsonDecode(stored),
            key == 'trainingPrograms'
                ? _forkPrograms(jsonDecode(incoming), plans, sessions)
                : jsonDecode(incoming),
          );
          json[column] = jsonEncode(merged);
        }
        if (json[column] != null) {
          UserCollections.validate(key, jsonDecode(json[column] as String));
        }
      }
      final row = UserProfileData.fromJson(json);
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

  Future<Map<int, int>> _restoreSessions(
    dynamic raw,
    Map<String, String> uuids,
  ) async {
    if (raw == null) return {};
    final list = raw as List;
    final ids = <int, int>{};
    for (final item in list) {
      final row = WorkoutSessionData.fromJson(
        _withFreshSyncMetadata(item, preserveArchivedDeletion: true),
      );
      if (item['archiveSessionSyncId'] is String) {
        final old = _identityKey(item['archiveSessionSyncId'] as String);
        if (uuids.containsKey(old)) {
          throw const FormatException('Duplicate archived session UUID');
        }
        uuids[old] = row.syncId;
      }
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
    // Even an absent section must validate/remap every restored guidance link.
    final list = raw == null ? const [] : raw as List;
    var n = 0;
    final linkedIds = <String, String>{};
    final linkedSessions = <String, int>{};
    for (final item in list) {
      final json = _withFreshSyncMetadata(item, preserveArchivedDeletion: true);
      UserCollections.validateVariantPair(json);
      SetRole.validate(json['setRole']);
      final row = SetLogData.fromJson(json);
      if (item['archiveSetSyncId'] is String) {
        final old = _identityKey(item['archiveSetSyncId'] as String);
        if (linkedIds.containsKey(old)) {
          throw const FormatException('Duplicate archived set UUID');
        }
        linkedIds[old] = row.syncId;
      }
      final parent = sessionIds[row.sesjaId];
      if (parent == null) {
        throw const FormatException('Missing backup session ID');
      }
      linkedSessions[row.syncId] = parent;
      await db
          .into(db.setsLog)
          .insert(
            row
                .toCompanion(true)
                .copyWith(id: const Value.absent(), sesjaId: Value(parent)),
          );
      n++;
    }
    for (final id in sessionIds.values) {
      final session = (await db.workoutDao.getSession(id))!;
      if (session.guidanceJson == null) continue;
      final g = WorkoutGuidance.validateJson(jsonDecode(session.guidanceJson!));
      final events = g.events.map((event) {
        if (event['type'] != 'performed') return event;
        final mapped = linkedIds[_identityKey(event['setSyncId'] as String)];
        if (mapped == null || linkedSessions[mapped] != id) {
          throw const FormatException('Missing archived guidance set UUID');
        }
        return {...event, 'setSyncId': mapped};
      }).toList();
      final mapped = WorkoutGuidance.validateJson({
        ...g.toJson(),
        'events': events,
      });
      await db.workoutDao.updateSession(
        id,
        WorkoutSessionsCompanion(
          guidanceJson: Value(jsonEncode(mapped.toJson())),
        ),
      );
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
      if (row.customProtocolJson != null || row.typ == 'customFitnessTestV1') {
        final parsed = CustomFitnessResult.fromRow(row);
        if (!parsed.isAvailable) {
          throw const FormatException(
            'Nieczytelny snapshot wyniku własnego testu.',
          );
        }
      } else if (!TypTestu.values.any((t) => t.name == row.typ)) {
        throw const FormatException('Nieobsługiwany typ testu w backupie.');
      }
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

  Future<int> _restorePlans(dynamic raw, Map<String, String> uuids) async {
    if (raw == null) return 0;
    final list = raw as List;
    var n = 0;
    for (final item in list) {
      final row = WorkoutPlanData.fromJson(
        _withFreshSyncMetadata(item, preserveArchivedDeletion: true),
      );
      if (item['archivePlanSyncId'] is String) {
        final old = _identityKey(item['archivePlanSyncId'] as String);
        if (uuids.containsKey(old)) {
          throw const FormatException('Duplicate archived plan UUID');
        }
        uuids[old] = row.syncId;
      }
      await db
          .into(db.workoutPlans)
          .insert(row.toCompanion(true).copyWith(id: const Value.absent()));
      n++;
    }
    return n;
  }

  /// Restore creates new workout identities. Remap references, not occurrence
  /// identities, before enqueueing the fresh profile. Old archives without UUID
  /// metadata stay explicitly unavailable rather than guessing integer IDs.
  Future<void> _remapScheduleReferences(
    Map<String, String> plans,
    Map<String, String> sessions,
  ) async {
    final profile = await db.userProfileDao.watchProfileOnce();
    if (profile?.weeklyScheduleJson == null) return;
    final json = UserCollections.validate(
      'weeklySchedule',
      jsonDecode(profile!.weeklyScheduleJson!),
    );
    for (final raw in json['entries'] as List) {
      final e = raw as Map<String, dynamic>;
      var changed = false;
      void replace(Map target, String field, Map<String, String> ids) {
        final old = target[field];
        final replacement = old is String ? ids[_identityKey(old)] : null;
        if (replacement != null && replacement != target[field]) {
          target[field] = replacement;
          changed = true;
        }
      }

      if (['rule', 'activityRule'].contains(e['kind'])) {
        replace(e, 'planSyncId', plans);
      }
      if (['override', 'activityOverride'].contains(e['kind'])) {
        replace(e['ruleSnapshot'] as Map, 'planSyncId', plans);
        replace(e, 'sessionSyncId', sessions);
      }
      if (changed) {
        final previous = DateTime.parse(e['updatedAtUtc'] as String);
        final now = DateTime.now().toUtc();
        e['updatedAtUtc'] =
            (now.isAfter(previous)
                    ? now
                    : previous.add(const Duration(microseconds: 1)))
                .toIso8601String();
      }
    }
    UserCollections.validate('weeklySchedule', json);
    await db
        .update(db.userProfiles)
        .write(
          UserProfilesCompanion(weeklyScheduleJson: Value(jsonEncode(json))),
        );
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

  Map<String, dynamic> _forkPrograms(
    Object? value,
    Map<String, String> plans,
    Map<String, String> sessions,
  ) {
    final json = UserCollections.validate('trainingPrograms', value);
    final entries = (json['entries'] as List).cast<Map<String, dynamic>>();
    final programs = <String, String>{
      for (final e in entries.where((e) => e['kind'] == 'program'))
        (e['id'] as String).toLowerCase(): const Uuid().v4(),
    };
    String reference(Map<String, String> map, Object? old) {
      final mapped =
          map[old] ?? (old is String ? map[old.toLowerCase()] : null);
      if (mapped == null) {
        throw const FormatException(
          'Brak mapowanej referencji programu w backupie.',
        );
      }
      return mapped;
    }

    void definition(Map<String, dynamic> e) {
      e['planSyncIds'] = [
        for (final old in e['planSyncIds'] as List) reference(plans, old),
      ];
    }

    for (final e in entries) {
      if (e['kind'] == 'program') {
        e['id'] = reference(programs, e['id']);
        definition(e);
      } else {
        e['programId'] = reference(programs, e['programId']);
        e['id'] = TrainingPrograms.occurrenceId(
          e['programId'] as String,
          CalendarDay.parse(e['originalDate'] as String),
        );
        definition(e['programSnapshot'] as Map<String, dynamic>);
        if (e['sessionSyncId'] != null) {
          e['sessionSyncId'] = reference(sessions, e['sessionSyncId']);
        }
      }
    }
    return UserCollections.validate('trainingPrograms', json);
  }

  Future<void> _requireReadableCurrentExtensions() async {
    for (final p in await db.select(db.workoutPlans).get()) {
      if (p.structureJson != null) {
        StructuredPlan.validateJson(
          jsonDecode(p.structureJson!),
          exerciseIds: jsonDecode(p.cwiczeniaIds),
        );
      }
    }
    for (final s in await db.select(db.workoutSessions).get()) {
      if (s.guidanceJson != null) {
        WorkoutGuidance.validateJson(jsonDecode(s.guidanceJson!));
      }
    }
    for (final p in await db.select(db.userProfiles).get()) {
      for (final key in UserCollections.keys) {
        final raw = p.toJson()['${key}Json'] as String?;
        if (raw != null) UserCollections.validate(key, jsonDecode(raw));
      }
    }
  }
}
