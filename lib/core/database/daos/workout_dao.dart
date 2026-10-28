import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/workout_tables.dart';
import '../working_sets.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [WorkoutSessions, SetsLog])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  Future<int> createSession(WorkoutSessionsCompanion session) {
    return into(workoutSessions).insert(session);
  }

  Future<void> updateSession(int id, WorkoutSessionsCompanion changes) {
    return (update(
      workoutSessions,
    )..where((t) => t.id.equals(id))).write(changes);
  }

  Future<WorkoutSessionData?> getSession(int id) {
    return (select(
      workoutSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<WorkoutSessionData?> watchSession(int id) => (select(
    workoutSessions,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<int> addSet(SetsLogCompanion setLog) {
    return into(setsLog).insert(setLog);
  }

  Stream<List<WorkoutSessionData>> watchAllSessions() {
    return (select(workoutSessions)
          ..where((t) => t.deletedAtUtc.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.dataStart)]))
        .watch();
  }

  Future<List<WorkoutSessionData>> getAllSessionsSorted() async {
    final rows =
        await (select(workoutSessions)
              ..where((t) => t.deletedAtUtc.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.dataStart)]))
            .get();
    return rows;
  }

  Future<List<SetLogData>> getSetsForSession(int sessionId) {
    return (select(setsLog)
          ..where((t) => t.sesjaId.equals(sessionId) & t.deletedAtUtc.isNull()))
        .get();
  }

  /// Zwraca ostatnią wykonaną serię dla danego ćwiczenia (do auto-progress).
  Future<SetLogData?> getLastSetForExercise(
    String exerciseId, {
    String? side,
    String? variantId,
  }) async {
    final query = select(setsLog)
      ..where((t) => t.cwiczenieId.equals(exerciseId) & t.deletedAtUtc.isNull())
      ..where(effectiveWorkingSets)
      ..where((t) => side == null ? t.side.isNull() : t.side.equals(side))
      ..where(
        (t) => variantId == null
            ? t.variantId.isNull()
            : t.variantId.equals(variantId),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.timestamp),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(1);
    final rows = await query.get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Zwraca wszystkie serie danego ćwiczenia (do wykrywania PR).
  Future<List<SetLogData>> getAllSetsForExercise(
    String exerciseId, {
    String? side,
    String? variantId,
    bool effectiveWorkingOnly = false,
  }) {
    return (select(setsLog)..where(
          (t) =>
              t.cwiczenieId.equals(exerciseId) &
              t.deletedAtUtc.isNull() &
              (effectiveWorkingOnly
                  ? effectiveWorkingSets(t)
                  : const Constant(true)) &
              (side == null ? t.side.isNull() : t.side.equals(side)) &
              (variantId == null
                  ? t.variantId.isNull()
                  : t.variantId.equals(variantId)),
        ))
        .get();
  }

  Future<List<SetLogData>> getAllSets() {
    return (select(setsLog)..where((t) => t.deletedAtUtc.isNull())).get();
  }
}
