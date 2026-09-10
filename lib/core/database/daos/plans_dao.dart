import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/plans_table.dart';

part 'plans_dao.g.dart';

@DriftAccessor(tables: [WorkoutPlans])
class PlansDao extends DatabaseAccessor<AppDatabase> with _$PlansDaoMixin {
  PlansDao(super.db);

  Future<int> addPlan(WorkoutPlansCompanion plan) {
    return into(workoutPlans).insert(plan);
  }

  Stream<List<WorkoutPlanData>> watchAll() {
    return (select(
      workoutPlans,
    )..where((t) => t.deletedAtUtc.isNull())).watch();
  }

  Future<WorkoutPlanData?> getPlan(int id) {
    return (select(
      workoutPlans,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> deletePlan(int id, DateTime deletedAtUtc) {
    return (update(workoutPlans)..where((t) => t.id.equals(id))).write(
      WorkoutPlansCompanion(
        updatedAtUtc: Value(deletedAtUtc),
        deletedAtUtc: Value(deletedAtUtc),
      ),
    );
  }
}
