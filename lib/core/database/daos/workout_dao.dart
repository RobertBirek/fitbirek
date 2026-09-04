import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/workout_tables.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [WorkoutSessions, SetsLog])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  Future<int> createSession(WorkoutSessionsCompanion session) {
    return into(workoutSessions).insert(session);
  }

  Future<void> finishSession(
    int id,
    DateTime dataKoniec,
    int czasTrwaniaSekund,
  ) {
    return (update(workoutSessions)..where((t) => t.id.equals(id))).write(
      WorkoutSessionsCompanion(
        dataKoniec: Value(dataKoniec),
        czasTrwaniaSekund: Value(czasTrwaniaSekund),
      ),
    );
  }

  Future<int> addSet(SetsLogCompanion setLog) {
    return into(setsLog).insert(setLog);
  }

  Stream<List<WorkoutSessionData>> watchAllSessions() {
    return (select(
      workoutSessions,
    )..orderBy([(t) => OrderingTerm.desc(t.dataStart)])).watch();
  }

  Future<List<WorkoutSessionData>> getAllSessionsSorted() async {
    final rows = await (select(
      workoutSessions,
    )..orderBy([(t) => OrderingTerm.desc(t.dataStart)])).get();
    return rows;
  }

  Future<List<SetLogData>> getSetsForSession(int sessionId) {
    return (select(setsLog)..where((t) => t.sesjaId.equals(sessionId))).get();
  }

  /// Zwraca ostatnią wykonaną serię dla danego ćwiczenia (do auto-progress).
  Future<SetLogData?> getLastSetForExercise(String exerciseId) async {
    final query = select(setsLog)
      ..where((t) => t.cwiczenieId.equals(exerciseId))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(1);
    final rows = await query.get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Zwraca wszystkie serie danego ćwiczenia (do wykrywania PR).
  Future<List<SetLogData>> getAllSetsForExercise(String exerciseId) {
    return (select(
      setsLog,
    )..where((t) => t.cwiczenieId.equals(exerciseId))).get();
  }

  Future<List<SetLogData>> getAllSets() => select(setsLog).get();
}
