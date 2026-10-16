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
    required this.tracking,
    required this.unilateral,
  });
  final List<String> styles;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> aliases;
  final String tracking;
  final bool unilateral;
}

class ExerciseCatalogMetadata {
  const ExerciseCatalogMetadata({
    this.styles = const {},
    this.muscles = const {},
    this.exercises = const {},
  });
  final Map<String, ExerciseCatalogTag> styles;
  final Map<String, ExerciseCatalogTag> muscles;
  final Map<String, ExerciseCatalogEntry> exercises;

  ExerciseCatalogEntry? entryFor(String exerciseId) => exercises[exerciseId];
  String muscleLabel(String id) => muscles[id]?.label ?? id;
  String styleLabel(String id) => styles[id]?.label ?? id;

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
        tracking: tracking,
        unilateral: value['unilateral'] as bool,
      );
    }
    return ExerciseCatalogMetadata(
      styles: tags(json['styles']),
      muscles: tags(json['muscles']),
      exercises: Map.unmodifiable(entries),
    );
  }
}
