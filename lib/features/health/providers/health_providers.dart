import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/health_repository.dart';
import '../data/health_integration_api.dart';
import '../../../core/models/weight_entry.dart';
import '../../progress/measurements/providers/measurements_providers.dart';

final healthRepositoryProvider = Provider(
  (ref) => HealthRepository(ref.watch(appDatabaseProvider)),
);
final healthSamplesProvider = StreamProvider<List<HealthSampleData>>(
  (ref) => ref.watch(healthRepositoryProvider).watchAll(),
);
final healthIntegrationApiProvider = Provider<HealthIntegrationApi>(
  (ref) => HttpHealthIntegrationApi(ref.watch(apiClientProvider)),
);
final healthAccountProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).accountId,
);
// Account-scoped, memory-only status. No HTTP when signed out; a changed
// dependency discards late responses from the previous account.
final healthStatusProvider =
    FutureProvider.autoDispose<HealthIntegrationStatus?>((ref) {
      if (ref.watch(healthAccountProvider) == null) return null;
      return ref.watch(healthIntegrationApiProvider).getStatus();
    });
final mergedWeightsProvider = Provider<AsyncValue<List<WeightEntry>>>((ref) {
  final manual = ref.watch(allMeasurementsProvider);
  final health = ref.watch(healthSamplesProvider);
  return manual.when(
    data: (m) => health.whenData((h) => HealthRepository.mergeWeights(m, h)),
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
  );
});
