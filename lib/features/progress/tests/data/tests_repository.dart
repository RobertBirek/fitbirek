import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/models/fitness_test.dart';
import '../../../../core/sync/sync_models.dart';
import '../../../../core/utils/test_score_calculator.dart';

/// Repozytorium testów sprawnościowych.
class TestsRepository {
  TestsRepository(this._db);
  final AppDatabase _db;

  Future<void> addResult({required TypTestu typ, required double wynik}) async {
    final score = TestScoreCalculator.calculateScore(typ, wynik);
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    await _db.transaction(() async {
      await _db.testsDao.addResult(
        FitnessTestResultsCompanion.insert(
          typ: typ.name,
          data: Value(now),
          wynik: wynik,
          score: Value(score),
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.fitnessTest,
        entityId: syncId,
        baseVersion: 0,
        payload: {
          'typ': typ.name,
          'data': now.toIso8601String(),
          'wynik': wynik,
          'score': score,
        },
      );
    });
  }

  Stream<List<FitnessTestResultData>> watchAll() => _db.testsDao.watchAll();

  Future<List<FitnessTestResultData>> getHistoryForType(TypTestu typ) {
    return _db.testsDao.getHistoryForType(typ.name);
  }
}
