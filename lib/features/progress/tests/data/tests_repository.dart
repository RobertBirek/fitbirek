import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/models/fitness_test.dart';
import '../../../../core/utils/test_score_calculator.dart';

/// Repozytorium testów sprawnościowych.
class TestsRepository {
  TestsRepository(this._db);
  final AppDatabase _db;

  Future<void> addResult({required TypTestu typ, required double wynik}) {
    final score = TestScoreCalculator.calculateScore(typ, wynik);
    return _db.testsDao.addResult(
      FitnessTestResultsCompanion.insert(
        typ: typ.name,
        wynik: wynik,
        score: Value(score),
      ),
    );
  }

  Stream<List<FitnessTestResultData>> watchAll() => _db.testsDao.watchAll();

  Future<List<FitnessTestResultData>> getHistoryForType(TypTestu typ) {
    return _db.testsDao.getHistoryForType(typ.name);
  }
}
