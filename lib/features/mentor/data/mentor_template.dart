import '../../../core/models/exercise.dart';
import '../../exercises/domain/exercise_filter_engine.dart';
import '../../planner/domain/structured_plan.dart';

/// Detached intent, not a write command. No arbitrary provider metadata survives.
class MentorTemplate {
  MentorTemplate._(this.name, this.minutes, this.exercises);
  final String name;
  final int minutes;
  final List<MentorTemplateExercise> exercises;

  factory MentorTemplate.fromJson(Map<dynamic, dynamic> j) {
    Never invalid() =>
        throw const FormatException('Nieprawidłowy szablon Mentora.');
    if (j.keys.toSet().difference({
          'id',
          'kind',
          'name',
          'minutes',
          'exercises',
        }).isNotEmpty ||
        j['name'] is! String ||
        (j['name'] as String).trim().isEmpty ||
        (j['name'] as String).length > 120 ||
        RegExp(r'[\x00-\x1f]').hasMatch(j['name'] as String) ||
        j['minutes'] is! int ||
        (j['minutes'] as int) < 5 ||
        (j['minutes'] as int) > 90 ||
        j['exercises'] is! List ||
        (j['exercises'] as List).isEmpty ||
        (j['exercises'] as List).length > 10) {
      invalid();
    }
    final exercises = (j['exercises'] as List)
        .map((e) => MentorTemplateExercise.fromJson(e))
        .toList();
    if (exercises.map((e) => e.id).toSet().length != exercises.length) {
      invalid();
    }
    final total = exercises.fold<int>(
      0,
      (s, e) =>
          s + e.sets * (e.seconds ?? e.reps! * 3) + (e.sets - 1) * e.rest + 15,
    );
    if (total > (j['minutes'] as int) * 60) invalid();
    return MentorTemplate._(
      (j['name'] as String).trim(),
      j['minutes'] as int,
      List.unmodifiable(exercises),
    );
  }

  StructuredPlan toPlan(List<Exercise> catalog, ExerciseFilterEngine engine) {
    final byId = {for (final e in catalog) e.id: e};
    final blocks = <PlanBlock>[];
    for (final e in exercises) {
      final exercise = byId[e.id];
      final meta = engine.metadata.entryFor(e.id);
      if (exercise == null ||
          meta == null ||
          (meta.tracking == 'reps'
              ? e.reps == null
              : meta.tracking != 'time' || e.seconds == null)) {
        throw const FormatException(
          'Ćwiczenie lub cele nie odpowiadają aktualnemu katalogowi.',
        );
      }
      blocks.add(
        PlanBlock(
          exerciseId: e.id,
          section: StructuredPlanGenerator.sectionFor(exercise),
          prescription: PlanPrescription(
            tracking: meta.tracking,
            sets: e.sets,
            reps: e.reps,
            workSeconds: e.seconds ?? e.reps! * 3 * (meta.unilateral ? 2 : 1),
            restSeconds: e.rest,
            transitionSeconds: 15,
            weightKg: e.kg,
          ),
        ),
      );
    }
    final plan = StructuredPlan(
      criteria: const ExerciseFilters(),
      budgetSeconds: minutes * 60,
      blocks: blocks,
      warnings: const [
        'Propozycja Mentora — sprawdź cele przed zapisem. Czas ESTYMOWANY.',
      ],
    );
    return StructuredPlan.validateJson(
      plan.toJson(),
      exerciseIds: plan.exerciseIds,
    );
  }
}

class MentorTemplateExercise {
  const MentorTemplateExercise._(
    this.id,
    this.sets,
    this.reps,
    this.seconds,
    this.rest,
    this.kg,
  );
  final String id;
  final int sets, rest;
  final int? reps, seconds;
  final double? kg;
  factory MentorTemplateExercise.fromJson(Object? value) {
    Never invalid() =>
        throw const FormatException('Nieprawidłowe cele Mentora.');
    bool integer(Object? v, int lo, int hi) => v is int && v >= lo && v <= hi;
    if (value is! Map ||
        value.length != 6 ||
        !value.keys.toSet().containsAll({
          'exercise_id',
          'sets',
          'reps',
          'seconds',
          'rest_seconds',
          'weight_kg',
        })) {
      invalid();
    }
    final j = value;
    if (j['exercise_id'] is! String ||
        !RegExp(r'^cw[0-9]{3}$').hasMatch(j['exercise_id'] as String) ||
        !integer(j['sets'], 1, 5400) ||
        !integer(j['rest_seconds'], 0, 5400) ||
        !((integer(j['reps'], 1, 1800) && j['seconds'] == null) ||
            (integer(j['seconds'], 1, 5400) && j['reps'] == null)) ||
        (j['weight_kg'] != null &&
            (j['weight_kg'] is! num ||
                !(j['weight_kg'] as num).isFinite ||
                (j['weight_kg'] as num) < 0 ||
                (j['weight_kg'] as num) > 1000))) {
      invalid();
    }
    return MentorTemplateExercise._(
      j['exercise_id'] as String,
      j['sets'] as int,
      j['reps'] as int?,
      j['seconds'] as int?,
      j['rest_seconds'] as int,
      (j['weight_kg'] as num?)?.toDouble(),
    );
  }
}
