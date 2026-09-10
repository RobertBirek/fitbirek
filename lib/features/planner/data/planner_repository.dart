import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_models.dart';

/// Prosty model zapisanego planu treningowego (do wyświetlenia w historii).
class SavedPlan {
  const SavedPlan({
    required this.id,
    required this.nazwa,
    required this.cwiczeniaIds,
    required this.cel,
    required this.dataUtworzenia,
  });

  final int id;
  final String nazwa;
  final List<String> cwiczeniaIds;
  final String cel;
  final DateTime dataUtworzenia;
}

/// Repozytorium planów treningowych - zapis wygenerowanych planów (Premium).
class PlannerRepository {
  PlannerRepository(this._db);
  final AppDatabase _db;

  Future<int> savePlan({
    required String nazwa,
    required List<String> cwiczeniaIds,
    required String cel,
  }) async {
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    final encodedExerciseIds = jsonEncode(cwiczeniaIds);
    return _db.transaction(() async {
      final id = await _db.plansDao.addPlan(
        WorkoutPlansCompanion.insert(
          nazwa: nazwa,
          cwiczeniaIds: encodedExerciseIds,
          cel: cel,
          dataUtworzenia: Value(now),
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.workoutPlan,
        entityId: syncId,
        baseVersion: 0,
        payload: _payload(
          nazwa: nazwa,
          cwiczeniaIds: cwiczeniaIds,
          cel: cel,
          dataUtworzenia: now,
        ),
      );
      return id;
    });
  }

  Stream<List<SavedPlan>> watchAll() {
    return _db.plansDao.watchAll().map(
      (rows) => rows
          .map(
            (r) => SavedPlan(
              id: r.id,
              nazwa: r.nazwa,
              cwiczeniaIds: List<String>.from(jsonDecode(r.cwiczeniaIds)),
              cel: r.cel,
              dataUtworzenia: r.dataUtworzenia,
            ),
          )
          .toList(),
    );
  }

  Future<void> deletePlan(int id) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      final plan = await _db.plansDao.getPlan(id);
      if (plan == null || plan.deletedAtUtc != null) return;
      await _db.plansDao.deletePlan(id, now);
      await _db.syncDao.enqueueDelete(
        entityType: SyncEntityType.workoutPlan,
        entityId: plan.syncId,
        baseVersion: plan.syncVersion,
        payload: _payload(
          nazwa: plan.nazwa,
          cwiczeniaIds: List<String>.from(jsonDecode(plan.cwiczeniaIds)),
          cel: plan.cel,
          dataUtworzenia: plan.dataUtworzenia,
        ),
      );
    });
  }

  static Map<String, Object?> _payload({
    required String nazwa,
    required List<String> cwiczeniaIds,
    required String cel,
    required DateTime dataUtworzenia,
  }) => {
    'nazwa': nazwa,
    'cwiczeniaIds': cwiczeniaIds,
    'cel': cel,
    'dataUtworzenia': dataUtworzenia.toUtc().toIso8601String(),
  };
}
