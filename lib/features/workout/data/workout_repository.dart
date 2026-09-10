import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/sync/sync_models.dart';

class WorkoutSessionUnavailable extends StateError {
  WorkoutSessionUnavailable(int id)
    : super('Workout session $id is missing or deleted.');
}

/// Repozytorium sesji treningowych - zapis, historia, pobieranie ostatniej serii.
class WorkoutRepository {
  WorkoutRepository(this._db);
  final AppDatabase _db;

  Future<int> startSession() async {
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    return _db.transaction(() async {
      final id = await _db.workoutDao.createSession(
        WorkoutSessionsCompanion.insert(
          dataStart: now,
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.workoutSession,
        entityId: syncId,
        baseVersion: 0,
        payload: _sessionPayload(
          dataStart: now,
          dataKoniec: null,
          czasTrwaniaSekund: 0,
          notatka: null,
        ),
      );
      return id;
    });
  }

  Future<void> finishSession(int sessionId, DateTime start) async {
    final now = DateTime.now().toUtc();
    final duration = now.difference(start).inSeconds;
    await _db.transaction(() async {
      final session = await _db.workoutDao.getSession(sessionId);
      if (session == null || session.deletedAtUtc != null) {
        throw WorkoutSessionUnavailable(sessionId);
      }
      await _db.workoutDao.updateSession(
        sessionId,
        WorkoutSessionsCompanion(
          dataKoniec: Value(now),
          czasTrwaniaSekund: Value(duration),
          updatedAtUtc: Value(now),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.workoutSession,
        entityId: session.syncId,
        baseVersion: session.syncVersion,
        payload: _sessionPayload(
          dataStart: session.dataStart,
          dataKoniec: now,
          czasTrwaniaSekund: duration,
          notatka: session.notatka,
        ),
      );
    });
  }

  Future<int> logSet({
    required int sessionId,
    required String exerciseId,
    required String exerciseNamePl,
    required int setNumber,
    double? weightKg,
    int? reps,
    int? seconds,
    int? rpe,
  }) async {
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    return _db.transaction(() async {
      final session = await _db.workoutDao.getSession(sessionId);
      if (session == null || session.deletedAtUtc != null) {
        throw WorkoutSessionUnavailable(sessionId);
      }
      final id = await _db.workoutDao.addSet(
        SetsLogCompanion.insert(
          sesjaId: sessionId,
          cwiczenieId: exerciseId,
          nazwaCwiczeniaPl: exerciseNamePl,
          numerSerii: setNumber,
          ciezarKg: Value(weightKg),
          powtorzenia: Value(reps),
          czasSekund: Value(seconds),
          rpe: Value(rpe),
          timestamp: Value(now),
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.workoutSet,
        entityId: syncId,
        baseVersion: 0,
        payload: {
          'sessionSyncId': session.syncId,
          'cwiczenieId': exerciseId,
          'nazwaCwiczeniaPl': exerciseNamePl,
          'numerSerii': setNumber,
          'ciezarKg': weightKg,
          'powtorzenia': reps,
          'czasSekund': seconds,
          'rpe': rpe,
          'timestamp': now.toIso8601String(),
        },
      );
      return id;
    });
  }

  static Map<String, Object?> _sessionPayload({
    required DateTime dataStart,
    required DateTime? dataKoniec,
    required int czasTrwaniaSekund,
    required String? notatka,
  }) => {
    'dataStart': dataStart.toUtc().toIso8601String(),
    'dataKoniec': dataKoniec?.toUtc().toIso8601String(),
    'czasTrwaniaSekund': czasTrwaniaSekund,
    'notatka': notatka,
  };

  /// Zwraca opis ostatniej wykonanej serii dla danego ćwiczenia
  /// w formacie do wyświetlenia jako "auto-progress": "Ostatnio: 15 kg × 8 (RPE 8)"
  Future<SetLogData?> getLastSet(String exerciseId) {
    return _db.workoutDao.getLastSetForExercise(exerciseId);
  }

  Stream<List<WorkoutSessionData>> watchAllSessions() {
    return _db.workoutDao.watchAllSessions();
  }

  Stream<WorkoutSessionData?> watchSession(int id) =>
      _db.workoutDao.watchSession(id);

  Future<List<WorkoutSessionData>> getAllSessionsSorted() {
    return _db.workoutDao.getAllSessionsSorted();
  }

  Future<List<SetLogData>> getSetsForSession(int sessionId) {
    return _db.workoutDao.getSetsForSession(sessionId);
  }

  Future<List<SetLogData>> getAllSetsForExercise(String exerciseId) {
    return _db.workoutDao.getAllSetsForExercise(exerciseId);
  }

  Future<WorkoutSession> buildSessionModel(WorkoutSessionData session) async {
    final sets = await getSetsForSession(session.id);
    return WorkoutSession(
      id: session.id,
      dataStart: session.dataStart,
      dataKoniec: session.dataKoniec,
      czasTrwaniaSekund: session.czasTrwaniaSekund,
      notatka: session.notatka,
      serie: sets
          .map(
            (s) => SetLog(
              id: s.id,
              sesjaId: s.sesjaId,
              cwiczenieId: s.cwiczenieId,
              nazwaCwiczeniaPl: s.nazwaCwiczeniaPl,
              numerSerii: s.numerSerii,
              ciezarKg: s.ciezarKg,
              powtorzenia: s.powtorzenia,
              czasSekund: s.czasSekund,
              rpe: s.rpe,
              timestamp: s.timestamp,
            ),
          )
          .toList(),
    );
  }
}
