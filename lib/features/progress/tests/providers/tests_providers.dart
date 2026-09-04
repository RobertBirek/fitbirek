import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' show FitnessTestResultData;
import '../../../../core/providers/database_provider.dart';
import '../data/tests_repository.dart';

final testsRepositoryProvider = Provider<TestsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TestsRepository(db);
});

final allTestResultsProvider = StreamProvider<List<FitnessTestResultData>>((
  ref,
) {
  final repo = ref.watch(testsRepositoryProvider);
  return repo.watchAll();
});
