import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/exercises_table.dart';
import '../tables/sync_tables.dart';

part 'exercises_dao.g.dart';

@DriftAccessor(tables: [Exercises, ExerciseFavorites])
class ExercisesDao extends DatabaseAccessor<AppDatabase>
    with _$ExercisesDaoMixin {
  ExercisesDao(super.db);

  Stream<List<(ExerciseData, bool)>> watchAllWithFavorites() {
    final query = select(exercises).join([
      leftOuterJoin(
        exerciseFavorites,
        exerciseFavorites.exerciseId.equalsExp(exercises.id) &
            exerciseFavorites.deletedAtUtc.isNull(),
      ),
    ]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (
              row.readTable(exercises),
              row.readTableOrNull(exerciseFavorites) != null,
            ),
          )
          .toList(),
    );
  }

  Future<List<ExerciseData>> getAll() => select(exercises).get();

  Future<int> count() async {
    final rows = await select(exercises).get();
    return rows.length;
  }

  /// Zwraca zbiór ID wszystkich ćwiczeń już obecnych w bazie.
  /// Używane przez import przyrostowy, żeby wstawiać tylko nowe pozycje
  /// bez dotykania (i bez nadpisywania `ulubione`) już istniejących wierszy.
  Future<Set<String>> getAllIds() async {
    final rows = await (selectOnly(
      exercises,
    )..addColumns([exercises.id])).get();
    return rows.map((r) => r.read(exercises.id)!).toSet();
  }

  Future<void> insertAll(List<ExercisesCompanion> rows) {
    return batch(
      (b) => b.insertAll(exercises, rows, mode: InsertMode.insertOrIgnore),
    );
  }

  Future<ExerciseFavoriteData?> getFavorite(String exerciseId) {
    return (select(
      exerciseFavorites,
    )..where((table) => table.exerciseId.equals(exerciseId))).getSingleOrNull();
  }

  Future<(ExerciseData, bool)?> getByIdWithFavorite(String id) async {
    final query = select(exercises).join([
      leftOuterJoin(
        exerciseFavorites,
        exerciseFavorites.exerciseId.equalsExp(exercises.id) &
            exerciseFavorites.deletedAtUtc.isNull(),
      ),
    ])..where(exercises.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (
      row.readTable(exercises),
      row.readTableOrNull(exerciseFavorites) != null,
    );
  }

  Future<void> upsertFavorite(ExerciseFavoritesCompanion favorite) {
    return into(exerciseFavorites).insertOnConflictUpdate(favorite);
  }
}
