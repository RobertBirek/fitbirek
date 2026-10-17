import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exercise_variants_repository.dart';
import 'filter_presets_providers.dart';

final exerciseVariantsRepositoryProvider = Provider<ExerciseVariantsRepository>(
  (ref) =>
      ExerciseVariantsRepository(ref.watch(userCollectionsRepositoryProvider)),
);

final exerciseVariantsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      exerciseId,
    ) {
      final account = ref.watch(filterPresetsAccountProvider).valueOrNull;
      final collections = ref.watch(userCollectionsRepositoryProvider);
      if (account == null) return Stream.value([]);
      return collections.db.userProfileDao.watchProfile().asyncMap((row) async {
        if (row == null) return <Map<String, dynamic>>[];
        return ref
            .read(exerciseVariantsRepositoryProvider)
            .load(account, exerciseId);
      });
    });
