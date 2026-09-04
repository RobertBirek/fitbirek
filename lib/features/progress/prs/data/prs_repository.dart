import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/prs_table.dart';
import '../../../../core/utils/pr_detector.dart';

/// Repozytorium rekordów osobistych (PR).
class PrsRepository {
  PrsRepository(this._db);
  final AppDatabase _db;

  Future<PersonalRecordData?> getBestForExercise(String exerciseId) {
    return _db.prsDao.getBestForExercise(exerciseId);
  }

  Future<void> savePr({
    required String exerciseId,
    required String exerciseNamePl,
    required double weightKg,
    required int reps,
  }) {
    return _db.prsDao.addRecord(
      PersonalRecordsCompanion.insert(
        cwiczenieId: exerciseId,
        nazwaCwiczeniaPl: exerciseNamePl,
        ciezarKg: weightKg,
        powtorzenia: reps,
        szacowane1Rm: PrDetector.epley1Rm(weightKg, reps),
      ),
    );
  }

  Stream<List<PersonalRecordData>> watchAll() => _db.prsDao.watchAll();

  Future<List<PersonalRecordData>> getHistoryForExercise(String exerciseId) {
    return _db.prsDao.getHistoryForExercise(exerciseId);
  }
}
