import '../../../core/models/set_role.dart';

/// One immutable ordered target. Tracking belongs to its block; seconds is the
/// measured time target, workSeconds is the explicit estimate (including sides).
class SetPrescription {
  const SetPrescription({
    required this.targetId,
    required this.setRole,
    this.side,
    this.reps,
    this.seconds,
    this.weightKg,
    required this.workSeconds,
    required this.restSeconds,
  });

  final String targetId, setRole;
  final String? side;
  final int? reps, seconds;
  final double? weightKg;
  final int workSeconds, restSeconds;

  void validate(String tracking) {
    SetRole.validate(setRole);
    if (targetId.trim().isEmpty || targetId.runes.length > 80 ||
        !{'reps', 'time'}.contains(tracking) ||
        (side != null && !{'left', 'right', 'both'}.contains(side)) ||
        (weightKg != null && (!weightKg!.isFinite || weightKg! < 0)) ||
        workSeconds < 1 || workSeconds > 5400 ||
        restSeconds < 0 || restSeconds > 5400 ||
        (tracking == 'reps'
          ? (reps == null || reps! < 1 || reps! > 1800 || seconds != null)
          : (seconds == null || seconds! < 1 || seconds! > 5400 || reps != null))) {
      throw const FormatException('Nieprawidłowy indywidualny cel serii.');
    }
  }

  Map<String, Object?> toJson() => {
    'targetId': targetId, 'setRole': setRole, 'side': side,
    'reps': reps, 'seconds': seconds, 'weightKg': weightKg,
    'workSeconds': workSeconds, 'restSeconds': restSeconds,
  };

  factory SetPrescription.fromJson(Map<String, dynamic> j, {required String tracking}) {
    try {
      if (j.keys.any((k) => !{'targetId', 'setRole', 'side', 'reps', 'seconds', 'weightKg', 'workSeconds', 'restSeconds'}.contains(k))) {
        throw const FormatException('Nieobsługiwane pola celu serii.');
      }
      final p = SetPrescription(
        targetId: j['targetId'] as String, setRole: j['setRole'] as String,
        side: j['side'] as String?, reps: j['reps'] as int?, seconds: j['seconds'] as int?,
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        workSeconds: j['workSeconds'] as int, restSeconds: j['restSeconds'] as int,
      );
      p.validate(tracking);
      return p;
    } on TypeError {
      throw const FormatException('Nieprawidłowe typy celu serii.');
    }
  }
}
