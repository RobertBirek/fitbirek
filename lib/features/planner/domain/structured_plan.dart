import 'dart:convert';
import '../../../core/models/exercise.dart';
import '../../exercises/domain/exercise_filter_engine.dart';
import '../../exercises/domain/filter_preset.dart';
import 'exercise_training_policy.dart';
import 'set_prescription.dart';

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
  /// schema1's maximum budget. Bound operands BEFORE any int arithmetic on
  /// native (signed 64-bit) or Web (53-bit exact integers).
  static const maxSeconds = 5400;
  static const maxReps = maxSeconds ~/ 3;
  const PlanPrescription({
    required this.tracking,
    required int sets,
    int? reps,
    required int workSeconds,
    required int restSeconds,
    required this.transitionSeconds,
    double? weightKg,
  }) : _sets = sets,
       _reps = reps,
       _workSeconds = workSeconds,
       _restSeconds = restSeconds,
       _weightKg = weightKg,
       setTargets = const [];
  PlanPrescription.perSet({
    required this.tracking,
    required List<SetPrescription> setTargets,
    required this.transitionSeconds,
  }) : setTargets = List.unmodifiable(setTargets),
       _sets = null,
       _reps = null,
       _workSeconds = null,
       _restSeconds = null,
       _weightKg = null;
  final String tracking;
  final int? _sets, _reps, _workSeconds, _restSeconds;
  final double? _weightKg;
  final int transitionSeconds;
  final List<SetPrescription> setTargets;
  bool get isPerSet => _sets == null;
  int get sets => isPerSet ? setTargets.length : _sets!;
  int? get reps => _reps;
  double? get weightKg => _weightKg;
  int get workSeconds =>
      _workSeconds ??
      (throw StateError('Użyj setTargets — cele są indywidualne.'));
  int get restSeconds =>
      _restSeconds ??
      (throw StateError('Użyj setTargets — przerwy są indywidualne.'));
  void validate() {
    if (isPerSet) {
      if (setTargets.isEmpty ||
          setTargets.length > 100 ||
          transitionSeconds < 0 ||
          transitionSeconds > maxSeconds ||
          setTargets.map((t) => t.targetId).toSet().length !=
              setTargets.length) {
        throw const FormatException('Nieprawidłowa lista celów serii.');
      }
      for (final target in setTargets) {
        target.validate(tracking);
      }
      return;
    }
    if (!{'reps', 'time', 'rounds'}.contains(tracking) ||
        (weightKg != null && (!weightKg!.isFinite || weightKg! < 0)) ||
        sets < 1 ||
        sets > maxSeconds ||
        workSeconds < 1 ||
        workSeconds > maxSeconds ||
        restSeconds < 0 ||
        restSeconds > maxSeconds ||
        transitionSeconds < 0 ||
        transitionSeconds > maxSeconds ||
        (tracking == 'reps'
            ? (reps == null || reps! < 1 || reps! > maxReps)
            : reps != null)) {
      throw const FormatException(
        'Nieprawidłowe cele planu: serie i sekundy maksymalnie 5400, powtórzenia maksymalnie 1800; ciężar musi być skończony i nieujemny.',
      );
    }
  }

  int get totalSeconds {
    validate();
    if (isPerSet) {
      return transitionSeconds +
          setTargets.fold<int>(0, (sum, t) => sum + t.workSeconds) +
          setTargets
              .take(setTargets.length - 1)
              .fold<int>(0, (sum, t) => sum + t.restSeconds);
    }
    return sets * workSeconds + (sets - 1) * restSeconds + transitionSeconds;
  }

  Map<String, Object?> toJson() => isPerSet
      ? {
          'tracking': tracking,
          'transitionSeconds': transitionSeconds,
          'setTargets': setTargets.map((t) => t.toJson()).toList(),
        }
      : {
          'tracking': tracking,
          'sets': sets,
          'reps': reps,
          'workSeconds': workSeconds,
          'restSeconds': restSeconds,
          'transitionSeconds': transitionSeconds,
          if (weightKg != null) 'weightKg': weightKg,
        };
  factory PlanPrescription.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('setTargets')) {
      if (j.keys.any(
        (k) => !{'tracking', 'transitionSeconds', 'setTargets'}.contains(k),
      )) {
        throw const FormatException(
          'Indywidualne cele nie mogą mieć równoległej dawki.',
        );
      }
      final p = PlanPrescription.perSet(
        tracking: j['tracking'] as String,
        transitionSeconds: j['transitionSeconds'] as int,
        setTargets: (j['setTargets'] as List)
            .map(
              (t) => SetPrescription.fromJson(
                Map<String, dynamic>.from(t as Map),
                tracking: j['tracking'] as String,
              ),
            )
            .toList(),
      );
      p.validate();
      return p;
    }
    final p = PlanPrescription(
      tracking: j['tracking'] as String,
      sets: j['sets'] as int,
      reps: j['reps'] as int?,
      workSeconds: j['workSeconds'] as int,
      restSeconds: j['restSeconds'] as int,
      transitionSeconds: j['transitionSeconds'] as int,
      weightKg: (j['weightKg'] as num?)?.toDouble(),
    );
    p.validate();
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
    this.schemaVersion = 1,
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
  final int schemaVersion;
  final String level;
  final List<String> equipment;
  final int budgetSeconds;
  final List<PlanBlock> blocks;
  final List<String> warnings;
  List<String> get exerciseIds => blocks.map((b) => b.exerciseId).toList();
  int get estimatedSeconds =>
      blocks.fold(0, (s, b) => s + b.prescription.totalSeconds);
  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
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
    if (j['schemaVersion'] is! int || !{1, 2}.contains(j['schemaVersion'])) {
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
      schemaVersion: j['schemaVersion'] as int,
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
        p.blocks.length > 5400 ||
        p.estimatedSeconds > p.budgetSeconds ||
        p.exerciseIds.toSet().length != p.blocks.length ||
        p.exerciseIds.any((id) => id.isEmpty) ||
        p.blocks.any(
          (b) => b.prescription.isPerSet != (p.schemaVersion == 2),
        )) {
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
              engine.supportsEquipment(e, equipment) &&
              _levels.contains(e.poziom) &&
              _levels.indexOf(e.poziom) <= rank,
        )
        .toList();
  }

  static PlanSection sectionFor(Exercise e) =>
      PlanSection.values.byName(ExerciseTrainingPolicy.sectionKeyFor(e));

  // Only complete, unambiguous dose strings. Never inspect tempo/instructions.
  // Range lower bounds are intentional; these are catalog starting doses,
  // not personal rehabilitation recommendations. No exercise-ID/style policy.
  static final _dosePattern = RegExp(
    r'^(\d+)(?:\s*-\s*(\d+))?\s*x\s*(\d+)(?:\s*-\s*(\d+))?\s*(sek\.?|sec\.?|s|min\.?|powt\.?|powtorzen)?\s*(na strone)?$',
  );
  static final _maxExactInteger = BigInt.parse('9007199254740991');

  static PlanPrescription? _catalogPrescription(
    String raw, {
    required String tracking,
    required bool unilateral,
    required int restSeconds,
  }) {
    var text = ExerciseFilterEngine.fold(
      raw,
    ).trim().replaceAll('×', 'x').replaceAll('–', '-');
    final explicitSets = text.contains('x');
    if (!explicitSets) {
      text = '1 x $text'; // standalone time only, never bare reps
    }
    final match = _dosePattern.firstMatch(text);
    if (match == null) return null;
    BigInt? lower(String lo, String? hi) {
      final a = BigInt.tryParse(lo), b = BigInt.tryParse(hi ?? lo);
      if (a == null ||
          b == null ||
          a <= BigInt.zero ||
          b < a ||
          b > _maxExactInteger) {
        return null;
      }
      return a;
    }

    final sets = lower(match[1]!, match[2]);
    final amount = lower(match[3]!, match[4]);
    final unit = match[5]?.replaceAll('.', '');
    final time = const {'s', 'sek', 'sec', 'min'}.contains(unit);
    if (sets == null ||
        amount == null ||
        (match[6] != null && !unilateral) ||
        (time ? tracking != 'time' : tracking != 'reps') ||
        (!explicitSets && !time)) {
      return null;
    }
    final work =
        amount *
        BigInt.from(time ? (unit == 'min' ? 60 : 1) : 3) *
        BigInt.from(unilateral ? 2 : 1);
    final rest = restSeconds;
    final total =
        sets * work + (sets - BigInt.one) * BigInt.from(rest) + BigInt.from(15);
    // Serialization/arithmetic guard shared by VM and Web, not a medical cap.
    if (total > _maxExactInteger) return null;
    return PlanPrescription(
      tracking: tracking,
      sets: sets.toInt(),
      reps: time ? null : amount.toInt(),
      workSeconds: work.toInt(),
      restSeconds: rest,
      transitionSeconds: 15,
    );
  }

  static String _fallbackWarning(String id) =>
      '$id: Nie rozpoznano jednoznacznej dawki katalogowej zgodnej z metadanymi; '
      'zastosowana domyślna dawka generatora; czas pozostaje ESTYMOWANY, nie pomiar ani indywidualna rehabilitacja.';

  static String _restFallbackWarning(String id) =>
      '$id: Brak jednoznacznej polityki przerw; zastosowano domyślnie 30 s między seriami.';

  static ({PlanPrescription value, bool fallback})? _prescription(
    Exercise e,
    ExerciseFilterEngine engine,
    PlanSection section,
  ) {
    final entry = engine.metadata.entryFor(e.id);
    if (entry == null) {
      return null; // Never invent the tracking of custom/unknown entries.
    }
    final catalogDose = _catalogPrescription(
      e.seriexPowtorzenia,
      tracking: entry.tracking,
      unilateral: entry.unilateral,
      restSeconds: ExerciseTrainingPolicy.restFor(e).seconds,
    );
    if (catalogDose != null) {
      // A recognized but over-limit dose must be skipped, not replaced with
      // a smaller default that would falsely appear to fit the budget.
      try {
        catalogDose.validate();
      } on FormatException {
        return null;
      }
      return (value: catalogDose, fallback: false);
    }
    final main = section == PlanSection.main;
    final reps = entry.tracking == 'reps' ? (main ? 10 : 6) : null;
    final work = reps == null ? (main ? 40 : 30) : reps * 3;
    return (
      value: PlanPrescription(
        tracking: entry.tracking,
        sets: main ? 3 : 1,
        reps: reps,
        workSeconds: work * (entry.unilateral ? 2 : 1),
        restSeconds: ExerciseTrainingPolicy.restFor(e).seconds,
        transitionSeconds: 15,
      ),
      fallback: true,
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
        final dose = _prescription(e, engine, section);
        if (dose == null || dose.value.totalSeconds > remaining) continue;
        final p = dose.value;
        if (dose.fallback) warnings.add(_fallbackWarning(e.id));
        if (ExerciseTrainingPolicy.restFor(e).fallback) {
          warnings.add(_restFallbackWarning(e.id));
        }
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

  /// ID-only selection for active sessions: no newly invented prescription or
  /// budget change. Callers retain their original guidance targets/history.
  static List<Exercise> replacementCandidates({
    required StructuredPlan plan,
    required int index,
    required List<Exercise> allExercises,
    required ExerciseFilterEngine engine,
    required List<String> equipment,
    required String level,
  }) {
    final old = plan.blocks[index];
    if (old.prescription.isPerSet &&
        old.prescription.setTargets.any((t) => (t.weightKg ?? 0) > 0))
      return [];
    final sources = allExercises.where((e) => e.id == old.exerciseId).toList();
    if (sources.length != 1 ||
        engine.metadata.entryFor(old.exerciseId)?.tracking !=
            old.prescription.tracking) {
      return [];
    }
    final pool = candidates(
      allExercises: allExercises,
      engine: engine,
      criteria: plan.criteria,
      equipment: equipment,
      level: level,
    )..sort((a, b) => a.id.compareTo(b.id));
    return pool
        .where(
          (e) =>
              !plan.exerciseIds.contains(e.id) &&
              sectionFor(e) == old.section &&
              ExerciseTrainingPolicy.compatible(
                source: sources.single,
                candidate: e,
                engine: engine,
              ),
        )
        .toList();
  }

  static StructuredPlan? replace({
    required StructuredPlan plan,
    required int index,
    required List<Exercise> allExercises,
    required ExerciseFilterEngine engine,
    required List<String> equipment,
    required String level,
    bool allowBudgetIncrease = false,
  }) {
    final old = plan.blocks[index];
    // Generating a new uniform dose would silently flatten a schema2 ramp.
    if (old.prescription.isPerSet) return null;
    for (final e in replacementCandidates(
      plan: plan,
      index: index,
      allExercises: allExercises,
      engine: engine,
      equipment: equipment,
      level: level,
    )) {
      final dose = _prescription(e, engine, old.section);
      if (dose == null) continue;
      final p = dose.value;
      final blocks = [...plan.blocks];
      blocks[index] = PlanBlock(
        exerciseId: e.id,
        section: old.section,
        prescription: p,
      );
      final proposal = proposeBlocks(
        plan: plan,
        blocks: blocks,
        allowBudgetIncrease: allowBudgetIncrease,
        warnings: [
          ...plan.warnings.where(
            (w) =>
                w != _fallbackWarning(old.exerciseId) &&
                w != _restFallbackWarning(old.exerciseId),
          ),
          if (dose.fallback) _fallbackWarning(e.id),
          if (ExerciseTrainingPolicy.restFor(e).fallback)
            _restFallbackWarning(e.id),
        ],
      );
      if (proposal != null) return proposal;
    }
    return null;
  }

  static StructuredPlan? withRest({
    required StructuredPlan plan,
    required int index,
    required int restSeconds,
    bool allowBudgetIncrease = false,
  }) {
    if (restSeconds < 0 || restSeconds > 600) {
      throw ArgumentError.value(restSeconds, 'restSeconds', 'Zakres: 0–600 s.');
    }
    final old = plan.blocks[index];
    final p = old.prescription;
    // Use the per-target editor instead; a scalar edit cannot overwrite a ramp.
    if (p.isPerSet) return null;
    final blocks = [...plan.blocks];
    blocks[index] = PlanBlock(
      exerciseId: old.exerciseId,
      section: old.section,
      prescription: PlanPrescription(
        tracking: p.tracking,
        sets: p.sets,
        reps: p.reps,
        workSeconds: p.workSeconds,
        restSeconds: restSeconds,
        transitionSeconds: p.transitionSeconds,
        weightKg: p.weightKg,
      ),
    );
    return proposeBlocks(
      plan: plan,
      blocks: blocks,
      allowBudgetIncrease: allowBudgetIncrease,
      warnings: plan.warnings
          .where((w) => w != _restFallbackWarning(old.exerciseId))
          .toList(),
    );
  }

  /// Preview-only proposal. Never reduces sets/rests or removes a block to fit.
  /// Permission allows a minute-rounded budget increase, not an invalid wire v1.
  static StructuredPlan? proposeBlocks({
    required StructuredPlan plan,
    required List<PlanBlock> blocks,
    bool allowBudgetIncrease = false,
    List<String>? warnings,
  }) {
    final seconds = blocks.fold<int>(
      0,
      (s, b) => s + b.prescription.totalSeconds,
    );
    if (seconds > PlanPrescription.maxSeconds) return null;
    var budget = plan.budgetSeconds;
    if (seconds > budget) {
      if (!allowBudgetIncrease) return null;
      budget = ((seconds + 59) ~/ 60) * 60;
      if (budget < 300) budget = 300;
    }
    final result = StructuredPlan(
      schemaVersion: plan.schemaVersion,
      criteria: plan.criteria,
      budgetSeconds: budget,
      level: plan.level,
      equipment: plan.equipment,
      blocks: blocks,
      warnings: warnings ?? plan.warnings,
    );
    StructuredPlan.validateJson(
      result.toJson(),
      exerciseIds: result.exerciseIds,
    );
    return result;
  }
}
