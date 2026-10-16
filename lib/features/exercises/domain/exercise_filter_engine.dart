import '../../../core/models/exercise.dart';
import '../../../core/utils/partia_kategoria.dart';
import 'exercise_catalog_metadata.dart';

enum ExerciseSortBy { alfabetycznie, partia, poziom }

/// Legacy fields remain supported for planner callers and saved UI state.
class ExerciseFilters {
  const ExerciseFilters({
    this.partie = const {},
    this.sprzet = const {},
    this.poziomy = const {},
    this.typy = const {},
    this.styles = const {},
    this.muscles = const {},
    this.conditions = const {},
    this.positions = const {},
    this.tylkoUlubione = false,
    this.query = '',
    this.sortBy = ExerciseSortBy.alfabetycznie,
  });
  final Set<String> partie,
      sprzet,
      poziomy,
      typy,
      styles,
      muscles,
      conditions,
      positions;
  bool get hasExecutionFilters => conditions.isNotEmpty || positions.isNotEmpty;
  final bool tylkoUlubione;
  final String query;
  final ExerciseSortBy sortBy;
  bool get isEmpty => activeCount == 0;
  int get activeCount =>
      partie.length +
      sprzet.length +
      poziomy.length +
      typy.length +
      styles.length +
      muscles.length +
      conditions.length +
      positions.length +
      (tylkoUlubione ? 1 : 0);
  ExerciseFilters copyWith({
    Set<String>? partie,
    Set<String>? sprzet,
    Set<String>? poziomy,
    Set<String>? typy,
    Set<String>? styles,
    Set<String>? muscles,
    Set<String>? conditions,
    Set<String>? positions,
    bool? tylkoUlubione,
    String? query,
    ExerciseSortBy? sortBy,
  }) => ExerciseFilters(
    partie: partie ?? this.partie,
    sprzet: sprzet ?? this.sprzet,
    poziomy: poziomy ?? this.poziomy,
    typy: typy ?? this.typy,
    styles: styles ?? this.styles,
    muscles: muscles ?? this.muscles,
    conditions: conditions ?? this.conditions,
    positions: positions ?? this.positions,
    tylkoUlubione: tylkoUlubione ?? this.tylkoUlubione,
    query: query ?? this.query,
    sortBy: sortBy ?? this.sortBy,
  );
}

class ExerciseFacets {
  const ExerciseFacets({
    required this.styles,
    required this.muscles,
    required this.equipment,
    required this.levels,
    required this.types,
    this.conditions = const {},
    this.positions = const {},
  });
  final Map<String, int> styles,
      muscles,
      equipment,
      levels,
      types,
      conditions,
      positions;
}

/// Pure, deterministic filtering; never reads assets or the database.
class ExerciseFilterEngine {
  ExerciseFilterEngine(
    this.metadata, {
    this.classificationAvailable = true,
    bool? executionMetadataAvailable,
  }) : executionMetadataAvailable =
           executionMetadataAvailable ?? classificationAvailable,
       _muscleIds = {
         ..._legacyMuscleIds,
         for (final tag in metadata.muscles.values)
           for (final term in [tag.id, tag.label, ...tag.aliases])
             fold(term.trim()): tag.id,
       };
  final ExerciseCatalogMetadata metadata;
  final Map<String, String> _muscleIds;

  /// No index has been loaded: preserve choices, but suspend its two filters.
  final bool classificationAvailable;
  final bool executionMetadataAvailable;

  /// Missing/old dictionaries cannot verify active exclusion criteria.
  bool executionFiltersVerified(ExerciseFilters filters) =>
      !filters.hasExecutionFilters ||
      (executionMetadataAvailable &&
          filters.conditions.every(metadata.conditions.containsKey) &&
          (filters.positions.isEmpty ||
              filters.positions.any(metadata.positions.containsKey)));

  // Explicit legacy vocabulary, not lowercasing Polish names into pretend IDs.
  // The first term is also the offline display label. Metadata terms take priority.
  static const _legacyMuscles = <String, List<String>>{
    'biceps': ['Biceps', 'dwugłowy ramienia'],
    'triceps': ['Triceps', 'trójgłowy ramienia'],
    'chest': ['Klatka piersiowa', 'Klatka', 'piersiowe', 'pectoralis'],
    'back': [
      'Plecy',
      'latissimus dorsi',
      'najszerszy grzbietu',
      'trapezy',
      'romboidy',
      'prostowniki grzbietu',
    ],
    'shoulders': ['Barki', 'naramienne', 'deltoids'],
    'abs': ['Brzuch', 'core', 'skośne brzucha', 'poprzeczny brzucha'],
    'glutes': ['Pośladki', 'gluteus', 'pośladkowe', 'odwodziciele bioder'],
    'quadriceps': ['Przód uda', 'kwadryceps', 'czworogłowy uda'],
    'hamstrings': ['Tył uda', 'dwugłowy uda', 'kulszowo-goleniowe'],
    'adductors': ['Przywodziciele uda', 'adduktory', 'wewnętrzna strona uda'],
    'calves': ['Łydki', 'gastrocnemius', 'soleus', 'trójgłowy łydki'],
    'forearms': [
      'Przedramiona',
      'chwyt',
      'grip',
      'zginacze nadgarstka',
      'prostowniki nadgarstka',
    ],
    'hip_flexors': ['Zginacze bioder', 'iliopsoas', 'biodrowo-lędźwiowy'],
    'brachialis': ['Mięsień ramienny', 'ramienny'],
    'rotator_cuff': [
      'Stożek rotatorów barku',
      'rotatory barku',
      'infraspinatus',
      'subscapularis',
      'supraspinatus',
    ],
    'serratus': ['Mięsień zębaty przedni', 'serratus anterior'],
    'tibialis_anterior': [
      'Przód goleni',
      'piszczelowy przedni',
      'tibialis anterior',
    ],
    'neck': ['Mięśnie szyi', 'zginacze szyi'],
    'diaphragm': ['Przepona'],
    'feet': ['Mięśnie stóp', 'stopy'],
    'quadratus_lumborum': [
      'Mięsień czworoboczny lędźwi',
      'QL',
      'quadratus lumborum',
    ],
  };

  static final _legacyMuscleIds = <String, String>{
    for (final item in _legacyMuscles.entries)
      for (final term in [item.key, ...item.value]) fold(term.trim()): item.key,
  };

  // Unknown anatomy stays visible; never guess a category.
  String _muscleId(String term) => _muscleIds[fold(term.trim())] ?? term.trim();

  String muscleLabel(String id) {
    final canonical = _muscleId(id);
    return metadata.muscles[canonical]?.label ??
        _legacyMuscles[canonical]?.first ??
        id;
  }

  static String fold(String text) {
    var result = text.toLowerCase();
    const source = 'ąćęłńóśźżàáâãäåèéêëìíîïòôõöùúûüýÿç';
    const target = 'acelnoszzaaaaaaeeeeiiiioooouuuuyyc';
    for (var i = 0; i < source.length; i++) {
      result = result.replaceAll(source[i], target[i]);
    }
    return result
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .replaceAll(RegExp(r'tai[\s-]*chi'), 'taichi');
  }

  Set<String> musclesFor(Exercise ex) {
    final entry = metadata.entryFor(ex.id);
    if (entry != null) {
      return {
        ...entry.primaryMuscles,
        ...entry.secondaryMuscles,
      }.map(_muscleId).toSet();
    }
    // Missing/custom records retain their legacy classification, not a guessed style.
    return {ex.partiaGlowna, ...ex.partieWspierajace}
        .expand((m) => m.split(RegExp(r'[,;/]')))
        .map((m) => m.trim())
        .where(
          (m) =>
              m.isNotEmpty && !const {'cardio', 'mobilnosc'}.contains(fold(m)),
        )
        .map(_muscleId)
        .toSet();
  }

  bool _overlaps(Set<String> selected, Iterable<String> values) =>
      selected.isEmpty || values.any(selected.contains);

  bool _matches(Exercise ex, ExerciseFilters filters) {
    final entry = metadata.entryFor(ex.id);
    if (!executionFiltersVerified(filters) ||
        !filters.conditions.every(
          (id) => entry?.conditions.contains(id) ?? false,
        ) ||
        !_overlaps(filters.positions, entry?.positions ?? [])) {
      return false;
    }
    if (!_overlaps(filters.partie, [
          mapToKategoria(ex.partiaGlowna, wzorzecRuchu: ex.wzorzecRuchu),
        ]) ||
        !_overlaps(filters.sprzet, ex.sprzet) ||
        !_overlaps(filters.poziomy, [ex.poziom]) ||
        !_overlaps(filters.typy, [ex.typ]) ||
        (classificationAvailable &&
            (!_overlaps(filters.styles, entry?.styles ?? []) ||
                !_overlaps(
                  filters.muscles.map(_muscleId).toSet(),
                  musclesFor(ex),
                ))) ||
        (filters.tylkoUlubione && !ex.ulubione)) {
      return false;
    }
    final tokens = fold(
      filters.query,
    ).trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final text = fold(
      [
        ex.nazwaPl,
        ex.nazwaEn,
        ex.partiaGlowna,
        ...ex.partieWspierajace,
        ...ex.sprzet,
        ex.typ,
        ...?entry?.aliases,
        for (final id in entry?.conditions ?? <String>[]) ...[
          id,
          metadata.conditionLabel(id),
          ...?metadata.conditions[id]?.aliases,
        ],
        for (final id in entry?.positions ?? <String>[]) ...[
          id,
          metadata.positionLabel(id),
          ...?metadata.positions[id]?.aliases,
        ],
        for (final id in entry?.styles ?? <String>[]) ...[
          id,
          metadata.styleLabel(id),
          ...?metadata.styles[id]?.aliases,
        ],
        for (final id in musclesFor(ex)) ...[
          id,
          muscleLabel(id),
          ...?_legacyMuscles[id],
          ...?metadata.muscles[id]?.aliases,
        ],
      ].join(' '),
    );
    return tokens.every(text.contains);
  }

  List<Exercise> filter(List<Exercise> all, ExerciseFilters filters) {
    final result = all.where((e) => _matches(e, filters)).toList();
    String key(Exercise e) => switch (filters.sortBy) {
      ExerciseSortBy.alfabetycznie => e.nazwaPl,
      ExerciseSortBy.partia => e.partiaGlowna,
      ExerciseSortBy.poziom => e.poziom,
    };
    result.sort((a, b) {
      final comparison = key(a).compareTo(key(b));
      return comparison == 0 ? a.id.compareTo(b.id) : comparison;
    });
    return result;
  }

  ExerciseFacets facets(List<Exercise> all, ExerciseFilters filters) {
    Map<String, int> count(
      ExerciseFilters f,
      Iterable<String> Function(Exercise) values,
    ) {
      final ids = <String, Set<String>>{};
      for (final ex in all.where((e) => _matches(e, f))) {
        for (final value in values(ex).toSet()) {
          (ids[value] ??= {}).add(ex.id);
        }
      }
      return {for (final item in ids.entries) item.key: item.value.length};
    }

    return ExerciseFacets(
      // AND refinement: keep current requirements and add X, not skip-own-facet.
      conditions: {
        for (final id in {...metadata.conditions.keys, ...filters.conditions})
          id: all
              .where(
                (e) => _matches(
                  e,
                  filters.copyWith(conditions: {...filters.conditions, id}),
                ),
              )
              .map((e) => e.id)
              .toSet()
              .length,
      },
      positions: count(
        filters.copyWith(positions: {}),
        (e) => metadata.entryFor(e.id)?.positions ?? [],
      ),
      styles: count(
        filters.copyWith(styles: {}),
        (e) => metadata.entryFor(e.id)?.styles ?? [],
      ),
      muscles: count(filters.copyWith(muscles: {}), musclesFor),
      equipment: count(filters.copyWith(sprzet: {}), (e) => e.sprzet),
      levels: count(filters.copyWith(poziomy: {}), (e) => [e.poziom]),
      types: count(filters.copyWith(typy: {}), (e) => [e.typ]),
    );
  }
}
