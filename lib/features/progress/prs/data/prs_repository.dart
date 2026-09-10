import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_models.dart';
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
  }) async {
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    final estimated1Rm = PrDetector.epley1Rm(weightKg, reps);
    await _db.transaction(() async {
      await _db.prsDao.addRecord(
        PersonalRecordsCompanion.insert(
          cwiczenieId: exerciseId,
          nazwaCwiczeniaPl: exerciseNamePl,
          ciezarKg: weightKg,
          powtorzenia: reps,
          data: Value(now),
          szacowane1Rm: estimated1Rm,
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.personalRecord,
        entityId: syncId,
        baseVersion: 0,
        payload: {
          'cwiczenieId': exerciseId,
          'nazwaCwiczeniaPl': exerciseNamePl,
          'ciezarKg': weightKg,
          'powtorzenia': reps,
          'data': now.toIso8601String(),
          'szacowane1Rm': estimated1Rm,
        },
      );
    });
  }

  Stream<List<PersonalRecordData>> watchAll() => _db.prsDao.watchAll();

  Future<List<PersonalRecordData>> getHistoryForExercise(String exerciseId) {
    return _db.prsDao.getHistoryForExercise(exerciseId);
  }
}
