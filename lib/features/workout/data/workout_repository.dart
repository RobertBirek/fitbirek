import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/sync/sync_models.dart';

class WorkoutSessionUnavailable extends StateError {
  WorkoutSessionUnavailable(int id)
    : super('Workout session $id is missing or deleted.');
}

class WorkoutAccountUnavailable extends StateError {
  WorkoutAccountUnavailable() : super('Workout account is no longer active.');
}

class IdempotentSessionWrite {
  const IdempotentSessionWrite(this.session, {required this.alreadyExists});

  final WorkoutSessionData session;
  final bool alreadyExists;
}

class IdempotentSetWrite {
  const IdempotentSetWrite(this.set, {required this.alreadyExists});

  final SetLogData set;
  final bool alreadyExists;
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

  /// Creates a session exactly once for [syncId]. The account check and the
  /// duplicate lookup happen in the same database transaction as the outbox
  /// mutation, so a restarted caller cannot enqueue a second action.
  /// [guard] is synchronous live ownership (auth + notifier generation), checked
  /// after database awaits as well as before writes. Throwing rolls back both
  /// rows and outbox, including when this runs inside a notifier transaction.
  Future<IdempotentSessionWrite> startSessionIdempotent({
    required String syncId,
    required String accountId,
    bool Function()? guard,
  }) async {
    _requireGuard(guard);
    final now = DateTime.now().toUtc();
    return _db.transaction(() async {
      await _requireAccount(accountId, guard);
      final existing = await _sessionBySyncId(syncId);
      _requireGuard(guard);
      if (existing != null) {
        return IdempotentSessionWrite(existing, alreadyExists: true);
      }
      // A second proposal (or a fresh notifier) must not create another live
      // session while the first start is still awaiting its UI attachment.
      final active = await (_db.select(
        _db.workoutSessions,
      )..where((s) => s.dataKoniec.isNull() & s.deletedAtUtc.isNull())).get();
      _requireGuard(guard);
      if (active.isNotEmpty) throw WorkoutSessionUnavailable(active.first.id);
      final id = await _db.workoutDao.createSession(
        WorkoutSessionsCompanion.insert(
          dataStart: now,
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      _requireGuard(guard);
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
      _requireGuard(guard);
      final session = (await _db.workoutDao.getSession(id))!;
      await _requireAccount(accountId, guard);
      _requireGuard(guard);
      return IdempotentSessionWrite(session, alreadyExists: false);
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

  /// Inserts one set under a caller-owned stable sync ID. Lookup deliberately
  /// includes tombstones: a proposal may never resurrect a remotely deleted
  /// record just because it is retried after a reload.
  Future<IdempotentSetWrite> logSetIdempotent({
    required int sessionId,
    required String exerciseId,
    required String exerciseNamePl,
    required int setNumber,
    required double weightKg,
    required int reps,
    required String syncId,
    required String accountId,
    bool Function()? guard,
  }) async {
    _requireGuard(guard);
    final now = DateTime.now().toUtc();
    return _db.transaction(() async {
      await _requireAccount(accountId, guard);
      final existing = await _setBySyncId(syncId);
      _requireGuard(guard);
      if (existing != null) {
        return IdempotentSetWrite(existing, alreadyExists: true);
      }
      final session = await _db.workoutDao.getSession(sessionId);
      _requireGuard(guard);
      if (session == null ||
          session.deletedAtUtc != null ||
          session.dataKoniec != null) {
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
          timestamp: Value(now),
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      _requireGuard(guard);
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
          'czasSekund': null,
          'rpe': null,
          'timestamp': now.toIso8601String(),
        },
      );
      _requireGuard(guard);
      final set = await (_db.select(
        _db.setsLog,
      )..where((s) => s.id.equals(id))).getSingle();
      await _requireAccount(accountId, guard);
      _requireGuard(guard);
      return IdempotentSetWrite(set, alreadyExists: false);
    });
  }

  static void _requireGuard(bool Function()? guard) {
    if (guard != null && !guard()) throw WorkoutAccountUnavailable();
  }

  Future<void> _requireAccount(
    String accountId, [
    bool Function()? guard,
  ]) async {
    _requireGuard(guard);
    final state = await _db.syncDao.readState();
    _requireGuard(guard);
    if (state == null || state.accountId != accountId || !state.offlineAccess) {
      throw WorkoutAccountUnavailable();
    }
  }

  Future<WorkoutSessionData?> _sessionBySyncId(String syncId) {
    return (_db.select(
      _db.workoutSessions,
    )..where((session) => session.syncId.equals(syncId))).getSingleOrNull();
  }

  Future<SetLogData?> _setBySyncId(String syncId) {
    return (_db.select(
      _db.setsLog,
    )..where((set) => set.syncId.equals(syncId))).getSingleOrNull();
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

  /// Includes soft-deleted rows so callers can safely recognize an old action.
  Future<WorkoutSessionData?> findSessionBySyncId(String syncId) =>
      _sessionBySyncId(syncId);

  /// Includes soft-deleted rows so retries cannot resurrect or duplicate a set.
  Future<SetLogData?> findSetBySyncId(String syncId) => _setBySyncId(syncId);

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
