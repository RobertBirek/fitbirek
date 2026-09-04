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

  Stream<List<WorkoutPlanData>> watchAll() => select(workoutPlans).watch();

  Future<void> deletePlan(int id) {
    return (delete(workoutPlans)..where((t) => t.id.equals(id))).go();
  }
}
