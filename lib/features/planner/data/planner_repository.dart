import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_models.dart';
import '../domain/structured_plan.dart';
import 'plan_sync_payload.dart';

/// Prosty model zapisanego planu treningowego (do wyświetlenia w historii).
class SavedPlan {
  const SavedPlan({
    required this.id,
    required this.nazwa,
    required this.cwiczeniaIds,
    required this.cel,
    required this.dataUtworzenia,
    this.syncId,
    this.structure,
    this.structureError,
    this.rawStructureJson,
  });

  final int id;
  final String? syncId;
  final String nazwa;
  final List<String> cwiczeniaIds;
  final String cel;
  final DateTime dataUtworzenia;
  final StructuredPlan? structure;

  /// Non-null is an unavailable plan, NOT a legacy list-only plan.
  final String? structureError;
  final String? rawStructureJson;
  bool get isUnavailable => structureError != null;
}

/// Repozytorium planów treningowych - zapis wygenerowanych planów (Premium).
class PlannerRepository {
  PlannerRepository(this._db);
  final AppDatabase _db;

  Future<int> savePlan({
    required String nazwa,
    required List<String> cwiczeniaIds,
    required String cel,
    StructuredPlan? structure,
  }) async {
    if (structure != null) {
      final ids = structure.exerciseIds;
      if (ids.length != cwiczeniaIds.length ||
          List.generate(
            ids.length,
            (i) => ids[i] == cwiczeniaIds[i],
          ).contains(false)) {
        throw ArgumentError(
          'ID ćwiczeń muszą odpowiadać blokom planu w tej samej kolejności.',
        );
      }
      StructuredPlan.validateJson(
        structure.toJson(),
        exerciseIds: cwiczeniaIds,
      );
    }
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    final encodedExerciseIds = jsonEncode(cwiczeniaIds);
    return _db.transaction(() async {
      final id = await _db.plansDao.addPlan(
        WorkoutPlansCompanion.insert(
          nazwa: nazwa,
          cwiczeniaIds: encodedExerciseIds,
          cel: cel,
          structureJson: Value(
            structure == null ? null : jsonEncode(structure.toJson()),
          ),
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
          structure: structure?.toJson(),
        ),
      );
      return id;
    });
  }

  Stream<List<SavedPlan>> watchAll() {
    return _db.plansDao.watchAll().map((rows) => rows.map(_savedPlan).toList());
  }

  Future<List<SavedPlan>> readAll() async => (await (_db.select(
    _db.workoutPlans,
  )..where((p) => p.deletedAtUtc.isNull())).get()).map(_savedPlan).toList();

  Future<SavedPlan?> getBySyncId(String id) async {
    final row =
        await (_db.select(_db.workoutPlans)
              ..where((p) => p.syncId.equals(id) & p.deletedAtUtc.isNull()))
            .getSingleOrNull();
    return row == null ? null : _savedPlan(row);
  }

  static SavedPlan _savedPlan(WorkoutPlanData row) {
    var ids = <String>[];
    StructuredPlan? structure;
    String? error;
    const unavailable =
        'Plan niedostępny — uszkodzone dane lub nieobsługiwana struktura. Możesz usunąć ten wpis.';
    try {
      final value = jsonDecode(row.cwiczeniaIds);
      if (value is! List || value.any((id) => id is! String)) {
        throw const FormatException('Nieprawidłowe ID ćwiczeń');
      }
      ids = value.cast<String>().toList();
      if (row.structureJson != null) {
        structure = StructuredPlan.validateJson(
          jsonDecode(row.structureJson!),
          exerciseIds: ids,
        );
      }
    } on FormatException {
      error = unavailable;
    }
    return SavedPlan(
      id: row.id,
      syncId: row.syncId,
      nazwa: row.nazwa,
      cwiczeniaIds: ids,
      cel: row.cel,
      dataUtworzenia: row.dataUtworzenia,
      structure: structure,
      structureError: error,
      rawStructureJson: row.structureJson,
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
        // Preserve the legacy envelope without decoding structureJson.
        payload: workoutPlanDeletePayload(plan),
      );
    });
  }

  static Map<String, Object?> _payload({
    required String nazwa,
    required List<String> cwiczeniaIds,
    required String cel,
    required DateTime dataUtworzenia,
    Map<String, Object?>? structure,
  }) => {
    'nazwa': nazwa,
    'cwiczeniaIds': cwiczeniaIds,
    'cel': cel,
    'dataUtworzenia': dataUtworzenia.toUtc().toIso8601String(),
    if (structure != null) 'structure': structure,
  };
}
