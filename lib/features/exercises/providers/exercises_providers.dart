import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/exercise.dart';
import '../../../core/providers/database_provider.dart';
import '../data/exercises_repository.dart';

final exercisesRepositoryProvider = Provider<ExercisesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ExercisesRepository(db);
});

/// Strumień wszystkich ćwiczeń z bazy - reaktywnie odświeża się przy zmianach
/// (np. po dodaniu do ulubionych).
final allExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final repo = ref.watch(exercisesRepositoryProvider);
  return repo.watchAll();
});

/// Filtry aktywne w bottom sheecie bazy ćwiczeń.
class ExerciseFilters {
  const ExerciseFilters({
    this.partie = const {},
    this.sprzet = const {},
    this.poziomy = const {},
    this.typy = const {},
    this.tylkoUlubione = false,
    this.query = '',
    this.sortBy = ExerciseSortBy.alfabetycznie,
  });

  final Set<String> partie;
  final Set<String> sprzet;
  final Set<String> poziomy;
  final Set<String> typy;
  final bool tylkoUlubione;
  final String query;
  final ExerciseSortBy sortBy;

  bool get isEmpty =>
      partie.isEmpty &&
      sprzet.isEmpty &&
      poziomy.isEmpty &&
      typy.isEmpty &&
      !tylkoUlubione;

  int get activeCount =>
      partie.length +
      sprzet.length +
      poziomy.length +
      typy.length +
      (tylkoUlubione ? 1 : 0);

  ExerciseFilters copyWith({
    Set<String>? partie,
    Set<String>? sprzet,
    Set<String>? poziomy,
    Set<String>? typy,
    bool? tylkoUlubione,
    String? query,
    ExerciseSortBy? sortBy,
  }) {
    return ExerciseFilters(
      partie: partie ?? this.partie,
      sprzet: sprzet ?? this.sprzet,
      poziomy: poziomy ?? this.poziomy,
      typy: typy ?? this.typy,
      tylkoUlubione: tylkoUlubione ?? this.tylkoUlubione,
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

enum ExerciseSortBy { alfabetycznie, partia, poziom }

final exerciseFiltersProvider = StateProvider<ExerciseFilters>(
  (ref) => const ExerciseFilters(),
);

/// Lista ćwiczeń po zastosowaniu filtrów, wyszukiwania i sortowania.
final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final exercisesAsync = ref.watch(allExercisesProvider);
  final filters = ref.watch(exerciseFiltersProvider);

  final all = exercisesAsync.value ?? [];

  var result = all.where((ex) {
    if (filters.partie.isNotEmpty &&
        !filters.partie.contains(ex.partiaGlowna)) {
      return false;
    }
    if (filters.sprzet.isNotEmpty &&
        !ex.sprzet.any((s) => filters.sprzet.contains(s))) {
      return false;
    }
    if (filters.poziomy.isNotEmpty && !filters.poziomy.contains(ex.poziom)) {
      return false;
    }
    if (filters.typy.isNotEmpty && !filters.typy.contains(ex.typ)) {
      return false;
    }
    if (filters.tylkoUlubione && !ex.ulubione) {
      return false;
    }
    if (filters.query.isNotEmpty) {
      final q = filters.query.toLowerCase();
      final matchesPl = ex.nazwaPl.toLowerCase().contains(q);
      final matchesEn = ex.nazwaEn.toLowerCase().contains(q);
      if (!matchesPl && !matchesEn) return false;
    }
    return true;
  }).toList();

  switch (filters.sortBy) {
    case ExerciseSortBy.alfabetycznie:
      result.sort((a, b) => a.nazwaPl.compareTo(b.nazwaPl));
      break;
    case ExerciseSortBy.partia:
      result.sort((a, b) => a.partiaGlowna.compareTo(b.partiaGlowna));
      break;
    case ExerciseSortBy.poziom:
      result.sort((a, b) => a.poziom.compareTo(b.poziom));
      break;
  }

  return result;
});
