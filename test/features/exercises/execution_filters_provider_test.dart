import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'catalog_filter_test.dart' show exercise;
import 'execution_filters_test.dart' show executionIndex;

void main() {
  test(
    'loading and failed refresh cannot reuse stale execution evidence',
    () async {
      final ready = ExerciseCatalogMetadata.fromJson(executionIndex());
      var pending = Completer<ExerciseCatalogMetadata>()..complete(ready);
      final c = ProviderContainer(
        overrides: [
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([exercise('a'), exercise('b')]),
          ),
          exerciseCatalogMetadataProvider.overrideWith((ref) => pending.future),
        ],
      );
      addTearDown(c.dispose);
      c.listen(filteredExercisesProvider, (_, __) {});
      await c.read(allExercisesProvider.future);
      await c.read(exerciseCatalogMetadataProvider.future);
      c.read(exerciseFiltersProvider.notifier).state = const ExerciseFilters(
        conditions: {'quiet'},
        positions: {'standing'},
      );
      expect(c.read(filteredExercisesProvider).map((e) => e.id), ['a']);
      pending = Completer<ExerciseCatalogMetadata>();
      c.invalidate(exerciseCatalogMetadataProvider);
      expect(c.read(filteredExercisesProvider), isEmpty);
      final refresh = c.read(exerciseCatalogMetadataProvider.future);
      pending.completeError(const FormatException('corrupt index'));
      await expectLater(refresh, throwsFormatException);
      expect(c.read(filteredExercisesProvider), isEmpty);
      expect(c.read(exerciseFiltersProvider).conditions, {'quiet'});
      expect(
        c
            .read(exerciseFilterEngineProvider)
            .executionFiltersVerified(c.read(exerciseFiltersProvider)),
        isFalse,
      );
      // Ordinary filters retain the previous legacy fallback behavior.
      c.read(exerciseFiltersProvider.notifier).state = const ExerciseFilters();
      expect(c.read(filteredExercisesProvider), hasLength(2));
    },
  );
}
