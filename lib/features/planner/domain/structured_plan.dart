import 'dart:convert';
import '../../../core/models/exercise.dart';
import '../../exercises/domain/exercise_filter_engine.dart';
import '../../exercises/domain/filter_preset.dart';

enum PlanSection {
  warmup('Rozgrzewka'),
  main('Praca'),
  cooldown('Schłodzenie');

  const PlanSection(this.label);
  final String label;
}

/// Work is per set (and includes both sides for unilateral exercises).
/// Repetition estimates use an explicit 3 s/rep; rests occur BETWEEN sets.
class PlanPrescription {
  const PlanPrescription({
    required this.tracking,
    required this.sets,
    this.reps,
    required this.workSeconds,
    required this.restSeconds,
    required this.transitionSeconds,
  });
  final String tracking;
  final int sets, workSeconds, restSeconds, transitionSeconds;
  final int? reps;
  int get totalSeconds =>
      sets * workSeconds + (sets - 1) * restSeconds + transitionSeconds;
  Map<String, Object?> toJson() => {
    'tracking': tracking,
    'sets': sets,
    'reps': reps,
    'workSeconds': workSeconds,
    'restSeconds': restSeconds,
    'transitionSeconds': transitionSeconds,
  };
  factory PlanPrescription.fromJson(Map<String, dynamic> j) {
    final p = PlanPrescription(
      tracking: j['tracking'] as String,
      sets: j['sets'] as int,
      reps: j['reps'] as int?,
      workSeconds: j['workSeconds'] as int,
      restSeconds: j['restSeconds'] as int,
      transitionSeconds: j['transitionSeconds'] as int,
    );
    if (!{'reps', 'time', 'rounds'}.contains(p.tracking) ||
        p.sets < 1 ||
        p.workSeconds < 1 ||
        p.restSeconds < 0 ||
        p.transitionSeconds < 0 ||
        (p.tracking == 'reps'
            ? (p.reps == null || p.reps! < 1)
            : p.reps != null)) {
      throw const FormatException('Nieprawidłowe cele planu');
    }
    return p;
  }
}

class PlanBlock {
  const PlanBlock({
    required this.exerciseId,
    required this.section,
    required this.prescription,
  });
  final String exerciseId;
  final PlanSection section;
  final PlanPrescription prescription;
  Map<String, Object?> toJson() => {
    'exerciseId': exerciseId,
    'section': section.name,
    'prescription': prescription.toJson(),
  };
  factory PlanBlock.fromJson(Map<String, dynamic> j) => PlanBlock(
    exerciseId: j['exerciseId'] as String,
    section: PlanSection.values.byName(j['section'] as String),
    prescription: PlanPrescription.fromJson(
      Map<String, dynamic>.from(j['prescription'] as Map),
    ),
  );
}

class StructuredPlan {
  StructuredPlan({
    required ExerciseFilters criteria,
    required this.budgetSeconds,
    required List<PlanBlock> blocks,
    required List<String> warnings,
    this.level = 'Średni',
    List<String> equipment = const [],
  }) : criteria = FilterPreset.decodeFilters(
         FilterPreset.encodeFilters(criteria),
       ),
       equipment = List.unmodifiable(equipment),
       blocks = List.unmodifiable(blocks),
       warnings = List.unmodifiable(warnings);
  final ExerciseFilters criteria;
  final String level;
  final List<String> equipment;
  final int budgetSeconds;
  final List<PlanBlock> blocks;
  final List<String> warnings;
  List<String> get exerciseIds => blocks.map((b) => b.exerciseId).toList();
  int get estimatedSeconds =>
      blocks.fold(0, (s, b) => s + b.prescription.totalSeconds);
  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'criteria': FilterPreset.encodeFilters(criteria),
    'budgetSeconds': budgetSeconds,
    'level': level,
    'equipment': equipment,
    'blocks': blocks.map((b) => b.toJson()).toList(),
    'warnings': warnings,
  };
  factory StructuredPlan.fromJson(Map<String, dynamic> j) {
    try {
      return _fromJson(j);
    } on TypeError {
      throw const FormatException('Nieprawidłowe typy w strukturze planu');
    } on ArgumentError {
      throw const FormatException('Nieprawidłowe wartości w strukturze planu');
    }
  }

  /// Trust boundary shared by pull, new outbox/restore and local history.
  /// Validate JSON serializability too; never discard unknown restrictions.
  static StructuredPlan validateJson(
    Object? value, {
    required Object? exerciseIds,
  }) {
    try {
      if (value is! Map) {
        throw const FormatException('Struktura planu musi być mapą JSON');
      }
      final plan = StructuredPlan.fromJson(
        jsonDecode(jsonEncode(value)) as Map<String, dynamic>,
      );
      if (exerciseIds is! List ||
          exerciseIds.any((id) => id is! String) ||
          exerciseIds.length != plan.blocks.length ||
          List.generate(
            plan.blocks.length,
            (i) => exerciseIds[i] == plan.blocks[i].exerciseId,
          ).contains(false)) {
        throw const FormatException('ID ćwiczeń nie odpowiadają blokom planu');
      }
      return plan;
    } on TypeError {
      throw const FormatException('Nieprawidłowe typy w strukturze planu');
    } on ArgumentError {
      throw const FormatException('Nieprawidłowe wartości w strukturze planu');
    } on JsonUnsupportedObjectError {
      throw const FormatException(
        'Struktura planu nie jest serializowalnym JSON',
      );
    }
  }

  static StructuredPlan _fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1) {
      throw const FormatException('Nieobsługiwana struktura planu');
    }
    final criteria = Map<String, dynamic>.from(j['criteria'] as Map);
    final knownCriteria = FilterPreset.encodeFilters(
      const ExerciseFilters(),
    ).keys.toSet();
    if (criteria.keys.any((key) => !knownCriteria.contains(key)) ||
        criteria.entries.any((entry) => entry.value == null) ||
        (criteria.containsKey('sortBy') &&
            !ExerciseSortBy.values.any((v) => v.name == criteria['sortBy']))) {
      throw const FormatException(
        'Nieobsługiwane lub nieprawidłowe kryteria planu',
      );
    }
    final p = StructuredPlan(
      criteria: FilterPreset.decodeFilters(criteria),
      budgetSeconds: j['budgetSeconds'] as int,
      level: j['level'] as String,
      equipment: (j['equipment'] as List).cast<String>(),
      blocks: (j['blocks'] as List)
          .map((b) => PlanBlock.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList(),
      warnings: (j['warnings'] as List).cast<String>(),
    );
    if (p.budgetSeconds < 300 ||
        p.budgetSeconds > 5400 ||
        p.estimatedSeconds > p.budgetSeconds ||
        p.exerciseIds.toSet().length != p.blocks.length ||
        p.exerciseIds.any((id) => id.isEmpty)) {
      throw const FormatException('Nieprawidłowy budżet lub bloki planu');
    }
    return p;
  }
}

/// Separate from the legacy PlanGenerator.generate API. No I/O or randomness.
class StructuredPlanGenerator {
  static const _levels = ['Początkujący', 'Średni', 'Zaawansowany'];
  static List<Exercise> candidates({
    required List<Exercise> allExercises,
    required ExerciseFilterEngine engine,
    required ExerciseFilters criteria,
    required List<String> equipment,
    required String level,
  }) {
    if ((!engine.classificationAvailable &&
            (criteria.styles.isNotEmpty || criteria.muscles.isNotEmpty)) ||
        !engine.executionFiltersVerified(criteria)) {
      throw StateError(
        'Poczekaj na klasyfikację lub ponów jej ładowanie. Kryteriów nie pominięto.',
      );
    }
    final rank = _levels.indexOf(level);
    return engine
        .filter(allExercises, criteria)
        .where(
          (e) =>
              e.sprzet.every(equipment.contains) &&
              _levels.contains(e.poziom) &&
              _levels.indexOf(e.poziom) <= rank,
        )
        .toList();
  }

  static PlanSection sectionFor(Exercise e) {
    final type = ExerciseFilterEngine.fold(e.typ);
    if (type.contains('rozgrzew')) return PlanSection.warmup;
    if (type.contains('rozciag') || type.contains('stretch')) {
      return PlanSection.cooldown;
    }
    return PlanSection.main; // yoga, recovery, mobility are valid main work
  }

  static PlanPrescription? _prescription(
    Exercise e,
    ExerciseFilterEngine engine,
    PlanSection section,
  ) {
    final entry = engine.metadata.entryFor(e.id);
    if (entry == null) {
      return null; // Never invent the tracking of custom/unknown entries.
    }
    final main = section == PlanSection.main;
    final reps = entry.tracking == 'reps' ? (main ? 10 : 6) : null;
    final work = reps == null ? (main ? 40 : 30) : reps * 3;
    return PlanPrescription(
      tracking: entry.tracking,
      sets: main ? 3 : 1,
      reps: reps,
      workSeconds: work * (entry.unilateral ? 2 : 1),
      restSeconds: main ? 30 : 0,
      transitionSeconds: 15,
    );
  }

  static StructuredPlan generate({
    required List<Exercise> allExercises,
    required ExerciseFilterEngine engine,
    required ExerciseFilters criteria,
    required List<String> equipment,
    required String level,
    required int minutes,
  }) {
    if (minutes < 5 || minutes > 90) {
      throw ArgumentError('Czas musi wynosić 5–90 minut.');
    }
    final pool = candidates(
      allExercises: allExercises,
      engine: engine,
      criteria: criteria,
      equipment: equipment,
      level: level,
    );
    final blocks = <PlanBlock>[];
    final warnings = <String>[];
    var remaining = minutes * 60;
    final patterns = <String>{}, muscles = <String>{};
    // Reserve auxiliaries, then maximize diversity in main within remaining budget.
    for (final section in [
      PlanSection.warmup,
      PlanSection.cooldown,
      PlanSection.main,
    ]) {
      final available = pool.where((e) => sectionFor(e) == section).toList();
      var count = 0;
      while (available.isNotEmpty &&
          count < (section == PlanSection.main ? 8 : 1)) {
        int novelty(Exercise e) =>
            (patterns.contains(
                  ExerciseFilterEngine.fold(
                    e.wzorzecRuchu,
                  ).split(RegExp(r'[ +(]')).first,
                )
                ? 0
                : 4) +
            (engine.musclesFor(e).difference(muscles).isEmpty ? 0 : 2);
        available.sort((a, b) {
          var cmp = novelty(b).compareTo(novelty(a));
          if (cmp == 0) {
            cmp = _levels
                .indexOf(a.poziom)
                .compareTo(_levels.indexOf(b.poziom));
          }
          return cmp == 0 ? a.id.compareTo(b.id) : cmp;
        });
        final e = available.removeAt(0);
        final pattern = ExerciseFilterEngine.fold(
          e.wzorzecRuchu,
        ).split(RegExp(r'[ +(]')).first;
        if (section == PlanSection.main &&
            pattern.isNotEmpty &&
            patterns.contains(pattern) &&
            engine.musclesFor(e).difference(muscles).isEmpty) {
          continue;
        }
        final p = _prescription(e, engine, section);
        if (p == null || p.totalSeconds > remaining) continue;
        blocks.add(
          PlanBlock(exerciseId: e.id, section: section, prescription: p),
        );
        patterns.add(
          ExerciseFilterEngine.fold(
            e.wzorzecRuchu,
          ).split(RegExp(r'[ +(]')).first,
        );
        muscles.addAll(engine.musclesFor(e));
        remaining -= p.totalSeconds;
        count++;
      }
      if (count == 0) {
        warnings.add(switch (section) {
          PlanSection.warmup => 'Brak rozgrzewki w aktywnej puli.',
          PlanSection.cooldown => 'Brak schłodzenia w aktywnej puli.',
          PlanSection.main => 'Brak pracy w aktywnej puli lub za mało czasu.',
        });
      }
    }
    if (pool.any((e) => engine.metadata.entryFor(e.id) == null)) {
      warnings.add('Pominięto ćwiczenia bez metadanych sposobu rejestrowania.');
    }
    blocks.sort((a, b) => a.section.index.compareTo(b.section.index));
    return StructuredPlan(
      criteria: criteria,
      budgetSeconds: minutes * 60,
      level: level,
      equipment: equipment,
      blocks: blocks,
      warnings: warnings,
    );
  }

  static StructuredPlan? replace({
    required StructuredPlan plan,
    required int index,
    required List<Exercise> allExercises,
    required ExerciseFilterEngine engine,
    required List<String> equipment,
    required String level,
  }) {
    final old = plan.blocks[index];
    final pool = candidates(
      allExercises: allExercises,
      engine: engine,
      criteria: plan.criteria,
      equipment: equipment,
      level: level,
    )..sort((a, b) => a.id.compareTo(b.id));
    for (final e in pool) {
      if (plan.exerciseIds.contains(e.id) || sectionFor(e) != old.section) {
        continue;
      }
      final entry = engine.metadata.entryFor(e.id);
      if (entry == null || entry.tracking != old.prescription.tracking) {
        continue;
      }
      final p = _prescription(e, engine, old.section)!;
      if (p.totalSeconds != old.prescription.totalSeconds) continue;
      final blocks = [...plan.blocks];
      blocks[index] = PlanBlock(
        exerciseId: e.id,
        section: old.section,
        prescription: p,
      );
      return StructuredPlan(
        criteria: plan.criteria,
        budgetSeconds: plan.budgetSeconds,
        level: plan.level,
        equipment: plan.equipment,
        blocks: blocks,
        warnings: plan.warnings,
      );
    }
    return null;
  }
}
