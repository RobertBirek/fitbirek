import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' show MeasurementData;
import '../../../../core/providers/database_provider.dart';
import '../data/measurements_repository.dart';

final measurementsRepositoryProvider = Provider<MeasurementsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MeasurementsRepository(db);
});

final allMeasurementsProvider = StreamProvider<List<MeasurementData>>((ref) {
  final repo = ref.watch(measurementsRepositoryProvider);
  return repo.watchAll();
});

final latestMeasurementProvider = FutureProvider.autoDispose<MeasurementData?>((
  ref,
) {
  final repo = ref.watch(measurementsRepositoryProvider);
  return repo.getLatest();
});
