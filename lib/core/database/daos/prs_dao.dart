import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/prs_table.dart';

part 'prs_dao.g.dart';

@DriftAccessor(tables: [PersonalRecords])
class PrsDao extends DatabaseAccessor<AppDatabase> with _$PrsDaoMixin {
  PrsDao(super.db);

  Future<int> addRecord(PersonalRecordsCompanion record) {
    return into(personalRecords).insert(record);
  }

  Stream<List<PersonalRecordData>> watchAll() {
    return (select(personalRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.data)]))
        .watch();
  }

  /// Najlepszy dotychczasowy PR (po szacowanym 1RM) dla danego ćwiczenia.
  Future<PersonalRecordData?> getBestForExercise(String exerciseId) async {
    final rows = await (select(personalRecords)
          ..where((t) => t.cwiczenieId.equals(exerciseId))
          ..orderBy([(t) => OrderingTerm.desc(t.szacowane1Rm)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<PersonalRecordData>> getHistoryForExercise(String exerciseId) {
    return (select(personalRecords)
          ..where((t) => t.cwiczenieId.equals(exerciseId))
          ..orderBy([(t) => OrderingTerm.desc(t.data)]))
        .get();
  }
}
