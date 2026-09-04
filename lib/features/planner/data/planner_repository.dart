import 'dart:convert';
import '../../../core/database/app_database.dart';

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
  }) {
    return _db.plansDao.addPlan(
      WorkoutPlansCompanion.insert(
        nazwa: nazwa,
        cwiczeniaIds: jsonEncode(cwiczeniaIds),
        cel: cel,
      ),
    );
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

  Future<void> deletePlan(int id) => _db.plansDao.deletePlan(id);
}
