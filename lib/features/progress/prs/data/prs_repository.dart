import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_models.dart';
import '../../../../core/utils/pr_detector.dart';
import '../../../exercises/data/exercise_variants_repository.dart';

/// Repozytorium rekordów osobistych (PR).
class PrsRepository {
  PrsRepository(this._db);
  final AppDatabase _db;

  Future<PersonalRecordData?> getBestForExercise(
    String exerciseId, {
    String? side,
    String? variantId,
  }) {
    return _db.prsDao.getBestForExercise(
      exerciseId,
      side: side,
      variantId: variantId,
    );
  }

  Future<void> savePr({
    required String exerciseId,
    required String exerciseNamePl,
    required double weightKg,
    required int reps,
    String? side,
    String? variantId,
    String? variantLabel,
    String? accountId,
  }) async {
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    final estimated1Rm = PrDetector.epley1Rm(weightKg, reps);
    await _db.transaction(() async {
      final label = await ExerciseVariantsRepository.requireLive(
        _db,
        exerciseId,
        variantId,
        accountId: accountId,
      );
      await _db.prsDao.addRecord(
        PersonalRecordsCompanion.insert(
          cwiczenieId: exerciseId,
          side: Value(side),
          variantId: Value(variantId),
          variantLabel: Value(label),
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
          if (side != null) 'side': side,
          if (variantId != null) 'variantId': variantId,
          if (variantId != null) 'variantLabel': label,
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

  Future<List<PersonalRecordData>> getHistoryForExercise(
    String exerciseId, {
    String? side,
    String? variantId,
  }) {
    return _db.prsDao.getHistoryForExercise(
      exerciseId,
      side: side,
      variantId: variantId,
    );
  }
}
