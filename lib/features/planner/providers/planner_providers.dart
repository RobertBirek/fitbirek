import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../data/planner_repository.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PlannerRepository(db);
});

final savedPlansProvider = StreamProvider<List<SavedPlan>>((ref) {
  final repo = ref.watch(plannerRepositoryProvider);
  return repo.watchAll();
});
