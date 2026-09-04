import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/workout_session.dart';

/// Repozytorium sesji treningowych - zapis, historia, pobieranie ostatniej serii.
class WorkoutRepository {
  WorkoutRepository(this._db);
  final AppDatabase _db;

  Future<int> startSession() {
    return _db.workoutDao.createSession(
      WorkoutSessionsCompanion.insert(dataStart: DateTime.now()),
    );
  }

  Future<void> finishSession(int sessionId, DateTime start) {
    final duration = DateTime.now().difference(start).inSeconds;
    return _db.workoutDao.finishSession(sessionId, DateTime.now(), duration);
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
  }) {
    return _db.workoutDao.addSet(
      SetsLogCompanion.insert(
        sesjaId: sessionId,
        cwiczenieId: exerciseId,
        nazwaCwiczeniaPl: exerciseNamePl,
        numerSerii: setNumber,
        ciezarKg: Value(weightKg),
        powtorzenia: Value(reps),
        czasSekund: Value(seconds),
        rpe: Value(rpe),
      ),
    );
  }

  /// Zwraca opis ostatniej wykonanej serii dla danego ćwiczenia
  /// w formacie do wyświetlenia jako "auto-progress": "Ostatnio: 15 kg × 8 (RPE 8)"
  Future<SetLogData?> getLastSet(String exerciseId) {
    return _db.workoutDao.getLastSetForExercise(exerciseId);
  }

  Stream<List<WorkoutSessionData>> watchAllSessions() {
    return _db.workoutDao.watchAllSessions();
  }

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
