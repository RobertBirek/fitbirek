/// Offline sidecar index, independent of persisted Exercise/Drift models.
class ExerciseCatalogTag {
  const ExerciseCatalogTag({
    required this.id,
    required this.label,
    this.aliases = const [],
  });
  final String id;
  final String label;
  final List<String> aliases;
}

class ExerciseCatalogEntry {
  const ExerciseCatalogEntry({
    this.styles = const [],
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.aliases = const [],
    this.conditions = const [],
    this.positions = const [],
    this.equipmentSets,
    required this.tracking,
    required this.unilateral,
  });
  final List<String> styles;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> aliases;
  final List<String> conditions;
  final List<String> positions;

  /// OR of complete AND sets; null preserves legacy Exercise.sprzet.
  final List<List<String>>? equipmentSets;
  final String tracking;
  final bool unilateral;
}

class ExerciseCatalogMetadata {
  const ExerciseCatalogMetadata({
    this.styles = const {},
    this.muscles = const {},
    this.conditions = const {},
    this.positions = const {},
    this.exercises = const {},
  });
  final Map<String, ExerciseCatalogTag> styles;
  final Map<String, ExerciseCatalogTag> muscles;
  final Map<String, ExerciseCatalogTag> conditions;
  final Map<String, ExerciseCatalogTag> positions;
  final Map<String, ExerciseCatalogEntry> exercises;

  ExerciseCatalogEntry? entryFor(String exerciseId) => exercises[exerciseId];
  String muscleLabel(String id) => muscles[id]?.label ?? id;
  String styleLabel(String id) => styles[id]?.label ?? id;
  String conditionLabel(String id) =>
      conditions[id]?.label ?? conditionLabels[id] ?? id;
  String positionLabel(String id) =>
      positions[id]?.label ?? positionLabels[id] ?? id;

  // Display vocabulary only: never evidence that an exercise meets a requirement.
  static const conditionLabels = {
    'no_jumps': 'Bez skoków',
    'quiet': 'Cichy trening',
    'no_kneeling': 'Bez klęku',
    'no_hand_support': 'Bez podporu na dłoniach',
    'no_floor': 'Bez schodzenia na podłogę',
    'small_space': 'Mało miejsca',
  };
  static const positionLabels = {
    'standing': 'Stojąco',
    'seated': 'Siedząco',
    'floor': 'Na podłodze',
    'hanging': 'W zwisie',
    'bench': 'Na ławce',
  };

  factory ExerciseCatalogMetadata.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Nieobsługiwana wersja indeksu ćwiczeń');
    }
    List<String> strings(dynamic value) =>
        List<String>.unmodifiable((value as List).cast<String>());
    Map<String, ExerciseCatalogTag> tags(dynamic value) => Map.unmodifiable({
      for (final tag in value as List)
        tag['id'] as String: ExerciseCatalogTag(
          id: tag['id'] as String,
          label: tag['label'] as String,
          aliases: strings(tag['aliases']),
        ),
    });
    final entries = <String, ExerciseCatalogEntry>{};
    List<List<String>> equipmentSets(dynamic value) {
      if (value is! List || value.isEmpty) {
        throw const FormatException('Nieprawidłowe zestawy sprzętu');
      }
      return List<List<String>>.unmodifiable(
        value.map((group) {
          if (group is! List ||
              group.isEmpty ||
              group.any((s) => s is! String || s.trim().isEmpty) ||
              group.toSet().length != group.length) {
            throw const FormatException('Nieprawidłowy zestaw sprzętu');
          }
          return List<String>.unmodifiable(group.cast<String>());
        }),
      );
    }

    for (final item in (json['exercises'] as Map<String, dynamic>).entries) {
      final value = item.value as Map<String, dynamic>;
      final tracking = value['tracking'] as String;
      if (!const {'reps', 'time', 'rounds'}.contains(tracking)) {
        throw FormatException('Nieobsługiwany sposób rejestrowania: $tracking');
      }
      entries[item.key] = ExerciseCatalogEntry(
        styles: strings(value['styles']),
        primaryMuscles: strings(value['primaryMuscles']),
        secondaryMuscles: strings(value['secondaryMuscles']),
        aliases: strings(value['aliases']),
        conditions: value.containsKey('conditions')
            ? strings(value['conditions'])
            : const [],
        positions: value.containsKey('positions')
            ? strings(value['positions'])
            : const [],
        tracking: tracking,
        equipmentSets: value.containsKey('equipmentSets')
            ? equipmentSets(value['equipmentSets'])
            : null,
        unilateral: value['unilateral'] as bool,
      );
    }
    return ExerciseCatalogMetadata(
      styles: tags(json['styles']),
      muscles: tags(json['muscles']),
      conditions: json.containsKey('conditions')
          ? tags(json['conditions'])
          : const {},
      positions: json.containsKey('positions')
          ? tags(json['positions'])
          : const {},
      exercises: Map.unmodifiable(entries),
    );
  }
}
