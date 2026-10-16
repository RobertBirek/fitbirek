import 'exercise_filter_engine.dart';

/// Device-local criteria, deliberately independent of catalog contents and IDs.
class FilterPreset {
  FilterPreset({
    required this.id,
    required this.name,
    required ExerciseFilters filters,
  }) : filters = decodeFilters(encodeFilters(filters));

  final String id;
  final String name;
  final ExerciseFilters filters;

  static String validateName(String value) {
    final name = value.trim();
    if (name.isEmpty || name.runes.length > 80) {
      throw ArgumentError('Nazwa musi mieć od 1 do 80 znaków.');
    }
    return name;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'filters': encodeFilters(filters),
  };

  factory FilterPreset.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String ||
        id.isEmpty ||
        json['name'] is! String ||
        json['filters'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid preset');
    }
    return FilterPreset(
      id: id,
      name: validateName(json['name'] as String),
      filters: decodeFilters(json['filters'] as Map<String, dynamic>),
    );
  }

  /// Missing fields default; unknown fields are ignored, unknown IDs preserved.
  static Map<String, Object?> encodeFilters(ExerciseFilters f) => {
    'styles': f.styles.toList(),
    'muscles': f.muscles.toList(),
    'conditions': f.conditions.toList(),
    'positions': f.positions.toList(),
    'sprzet': f.sprzet.toList(),
    'typy': f.typy.toList(),
    'partie': f.partie.toList(),
    'poziomy': f.poziomy.toList(),
    'tylkoUlubione': f.tylkoUlubione,
    'query': f.query,
    'sortBy': f.sortBy.name,
  };

  static ExerciseFilters decodeFilters(Map<String, dynamic> json) {
    Set<String> strings(String key) {
      final value = json[key];
      if (value == null) return const {};
      if (value is! List || value.any((v) => v is! String)) {
        throw FormatException('Invalid $key');
      }
      return Set.unmodifiable(value.cast<String>());
    }

    if ((json['query'] != null && json['query'] is! String) ||
        (json['tylkoUlubione'] != null && json['tylkoUlubione'] is! bool)) {
      throw const FormatException('Invalid criteria');
    }
    return ExerciseFilters(
      styles: strings('styles'),
      muscles: strings('muscles'),
      conditions: strings('conditions'),
      positions: strings('positions'),
      sprzet: strings('sprzet'),
      typy: strings('typy'),
      partie: strings('partie'),
      poziomy: strings('poziomy'),
      tylkoUlubione: json['tylkoUlubione'] as bool? ?? false,
      query: json['query'] as String? ?? '',
      sortBy: ExerciseSortBy.values.firstWhere(
        (v) => v.name == json['sortBy'],
        orElse: () => ExerciseSortBy.alfabetycznie,
      ),
    );
  }
}
