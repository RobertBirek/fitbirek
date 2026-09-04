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

  Future<void> toggleFavorite(String id, bool value) {
    return (update(exercises)..where((t) => t.id.equals(id))).write(
      ExercisesCompanion(ulubione: Value(value)),
    );
  }

  Future<ExerciseData?> getById(String id) {
    return (select(exercises)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}
