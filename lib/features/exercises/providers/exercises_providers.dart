import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/exercise.dart';
import '../../../core/providers/database_provider.dart';
import '../data/exercises_repository.dart';
import '../domain/exercise_catalog_metadata.dart';
import '../domain/exercise_filter_engine.dart';
export '../domain/exercise_filter_engine.dart'
    show ExerciseFilters, ExerciseSortBy;

final exercisesRepositoryProvider = Provider<ExercisesRepository>((ref) {
  return ExercisesRepository(ref.watch(appDatabaseProvider));
});

final allExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exercisesRepositoryProvider).watchAll();
});

/// Offline metadata. Errors remain explicit so the UI can explain legacy fallback.
final exerciseCatalogMetadataProvider = FutureProvider<ExerciseCatalogMetadata>(
  (ref) async {
    final source = await rootBundle.loadString(
      'assets/data/exercise_catalog_metadata.json',
    );
    return ExerciseCatalogMetadata.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  },
);

final exerciseFiltersProvider = StateProvider<ExerciseFilters>(
  (ref) => const ExerciseFilters(),
);

final exerciseFilterEngineProvider = Provider<ExerciseFilterEngine>((ref) {
  final source = ref.watch(exerciseCatalogMetadataProvider);
  final metadata = source.valueOrNull;
  return ExerciseFilterEngine(
    metadata ?? const ExerciseCatalogMetadata(),
    classificationAvailable: metadata != null,
    executionMetadataAvailable:
        metadata != null && !source.hasError && !source.isLoading,
  );
});

/// Synchronous compatibility API. Pages must inspect allExercisesProvider for loading/errors.
final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  return ref
      .watch(exerciseFilterEngineProvider)
      .filter(
        ref.watch(allExercisesProvider).valueOrNull ?? [],
        ref.watch(exerciseFiltersProvider),
      );
});

final exerciseFacetsProvider = Provider<ExerciseFacets>((ref) {
  return ref
      .watch(exerciseFilterEngineProvider)
      .facets(
        ref.watch(allExercisesProvider).valueOrNull ?? [],
        ref.watch(exerciseFiltersProvider),
      );
});
