import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' show PersonalRecordData;
import '../../../../core/providers/database_provider.dart';
import '../data/prs_repository.dart';

final prsRepositoryProvider = Provider<PrsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PrsRepository(db);
});

final allPrsProvider = StreamProvider<List<PersonalRecordData>>((ref) {
  final repo = ref.watch(prsRepositoryProvider);
  return repo.watchAll();
});

/// History remains separated into exact scopes; NULL is not `both`.
final prGroupsProvider =
    Provider<
      AsyncValue<Map<(String, String?, String?), List<PersonalRecordData>>>
    >((ref) {
      return ref.watch(allPrsProvider).whenData((rows) {
        final groups = <(String, String?, String?), List<PersonalRecordData>>{};
        for (final row in rows) {
          groups
              .putIfAbsent((row.cwiczenieId, row.side, row.variantId), () => [])
              .add(row);
        }
        return groups;
      });
    });
