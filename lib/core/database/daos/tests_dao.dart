import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tests_table.dart';

part 'tests_dao.g.dart';

@DriftAccessor(tables: [FitnessTestResults])
class TestsDao extends DatabaseAccessor<AppDatabase> with _$TestsDaoMixin {
  TestsDao(super.db);

  Future<int> addResult(FitnessTestResultsCompanion result) {
    return into(fitnessTestResults).insert(result);
  }

  Stream<List<FitnessTestResultData>> watchAll() {
    return (select(fitnessTestResults)
          ..where((t) => t.deletedAtUtc.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.data),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Future<List<FitnessTestResultData>> getHistoryForType(String typ) {
    return (select(fitnessTestResults)
          ..where((t) => t.typ.equals(typ) & t.deletedAtUtc.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.data),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }
}
