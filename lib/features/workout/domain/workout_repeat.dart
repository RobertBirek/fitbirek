import '../../../core/database/app_database.dart';
import '../../../core/models/set_role.dart';
import '../../planner/domain/structured_plan.dart';
import 'workout_guidance.dart';

enum RepeatMode { original, execution }

class WorkoutRepeatPreview {
  WorkoutRepeatPreview({
    required this.sourceId,
    required this.sourceSyncId,
    required this.fingerprint,
    required this.mode,
    required this.repeat,
    required List<String> issues,
  }) : issues = List.unmodifiable(issues);
  final int sourceId;
  final String sourceSyncId, fingerprint;
  final RepeatMode mode;
  final WorkoutRepeat? repeat;
  final List<String> issues;
  bool get canStart => issues.isEmpty && repeat?.targets.isNotEmpty == true;
}

/// Targets, not evidence of a workout. No source set/session identity or timer
/// authority is carried into a new session.
class RepeatSetTarget {
  const RepeatSetTarget({
    required this.exerciseId,
    required this.name,
    this.reps,
    this.seconds,
    this.weightKg,
    this.side,
    this.setRole,
    this.variantId,
    this.variantLabel,
    this.previousRpe,
  });
  final String exerciseId, name;
  final int? reps, seconds, previousRpe;
  final double? weightKg;
  final String? side, variantId, variantLabel, setRole;
  Map<String, Object?> get prefill => {
    'reps': reps?.toString() ?? '',
    'seconds': seconds?.toString() ?? '',
    'weight': weightKg?.toString() ?? '',
    'side': side,
    'setRole': setRole,
    'variantId': variantId,
    'variantLabel': variantLabel,
  };
  Map<String, Object?> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'reps': reps,
    'seconds': seconds,
    'weightKg': weightKg,
    'side': side,
    'variantId': variantId,
    'variantLabel': variantLabel,
    'previousRpe': previousRpe,
    'setRole': setRole,
  };
  factory RepeatSetTarget.fromJson(Map j) {
    try {
      final t = RepeatSetTarget(
        exerciseId: j['exerciseId'] as String,
        name: j['name'] as String,
        reps: j['reps'] as int?,
        seconds: j['seconds'] as int?,
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        side: j['side'] as String?,
        setRole: SetRole.validate(j['setRole']),
        variantId: j['variantId'] as String?,
        variantLabel: j['variantLabel'] as String?,
        previousRpe: j['previousRpe'] as int?,
      );
      if (t.exerciseId.isEmpty ||
          t.name.isEmpty ||
          (t.reps == null && t.seconds == null) ||
          (t.reps != null && t.reps! <= 0) ||
          (t.seconds != null && t.seconds! <= 0) ||
          (t.weightKg != null && (!t.weightKg!.isFinite || t.weightKg! < 0)) ||
          (t.side != null && !{'left', 'right', 'both'}.contains(t.side)) ||
          (t.previousRpe != null &&
              (t.previousRpe! < 1 || t.previousRpe! > 10)) ||
          (t.variantId == null) != (t.variantLabel == null)) {
        throw const FormatException('Nieprawidłowy cel powtórzenia');
      }
      return t;
    } on TypeError {
      throw const FormatException('Nieprawidłowy cel powtórzenia');
    }
  }
}

class WorkoutRepeat {
  WorkoutRepeat._(List<RepeatSetTarget> targets, {this.plan})
    : targets = List.unmodifiable(targets);
  final List<RepeatSetTarget> targets;
  final StructuredPlan? plan;
  factory WorkoutRepeat.execution(List<SetLogData> sets) {
    final ordered = sets.where((s) => s.deletedAtUtc == null).toList()
      ..sort((a, b) {
        final time = a.timestamp.compareTo(b.timestamp);
        return time == 0 ? a.syncId.compareTo(b.syncId) : time;
      });
    return WorkoutRepeat._(
      ordered
          .map(
            (s) => RepeatSetTarget.fromJson({
              'exerciseId': s.cwiczenieId,
              'name': s.nazwaCwiczeniaPl,
              'reps': s.powtorzenia,
              'seconds': s.czasSekund,
              'weightKg': s.ciezarKg,
              'side': s.side,
              'setRole': s.setRole,
              'variantId': s.variantId,
              'variantLabel': s.variantLabel,
              'previousRpe': s.rpe,
            }),
          )
          .toList(),
    );
  }
  factory WorkoutRepeat.original(WorkoutGuidance guidance) => WorkoutRepeat._([
    for (final block in guidance.plan.blocks)
      if (block.prescription.isPerSet)
        for (final target in block.prescription.setTargets)
          RepeatSetTarget(
            exerciseId: block.exerciseId,
            name: block.exerciseId,
            reps: target.reps,
            seconds: target.seconds,
            weightKg: target.weightKg,
            side: target.side,
            setRole: target.setRole,
          )
      else
        for (var i = 0; i < block.prescription.sets; i++)
          RepeatSetTarget(
            exerciseId: block.exerciseId,
            name: block.exerciseId,
            reps: block.prescription.reps,
            seconds: block.prescription.reps == null
                ? block.prescription.workSeconds
                : null,
          ),
  ], plan: guidance.plan);
  factory WorkoutRepeat.fromJson(Object? json) {
    try {
      final j = json as Map;
      if (j['version'] != 1) {
        throw const FormatException('Nieobsługiwane powtórzenie');
      }
      return WorkoutRepeat._(
        (j['targets'] as List)
            .map((t) => RepeatSetTarget.fromJson(t as Map))
            .toList(),
        plan: j['plan'] == null
            ? null
            : StructuredPlan.fromJson(
                Map<String, dynamic>.from(j['plan'] as Map),
              ),
      );
    } on TypeError {
      throw const FormatException('Nieprawidłowe powtórzenie');
    }
  }
  Map<String, Object?> toJson() => {
    'version': 1,
    'targets': targets.map((t) => t.toJson()).toList(),
    if (plan != null) 'plan': plan!.toJson(),
  };
}
