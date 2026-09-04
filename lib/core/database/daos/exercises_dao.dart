import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/exercises_table.dart';

part 'exercises_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExercisesDao extends DatabaseAccessor<AppDatabase>
    with _$ExercisesDaoMixin {
  ExercisesDao(super.db);

  Stream<List<ExerciseData>> watchAll() => select(exercises).watch();

  Future<List<ExerciseData>> getAll() => select(exercises).get();

  Future<int> count() async {
    final rows = await select(exercises).get();
    return rows.length;
  }

  Future<void> insertAll(List<ExercisesCompanion> rows) {
    return batch((b) => b.insertAll(exercises, rows, mode: InsertMode.insertOrIgnore));
  }

  Future<void> toggleFavorite(String id, bool value) {
    return (update(exercises)..where((t) => t.id.equals(id)))
        .write(ExercisesCompanion(ulubione: Value(value)));
  }

  Future<ExerciseData?> getById(String id) {
    return (select(exercises)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}
