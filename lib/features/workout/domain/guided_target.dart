import '../../planner/domain/set_prescription.dart';
import 'workout_guidance.dart';

/// v2-only identity. Never infers a target from actual set numbers/counts.
SetPrescription? guidedTarget(WorkoutGuidance? guidance, int slot, Map fields) {
  if (guidance?.schemaVersion != 2) return null;
  final targets = guidance!.plan.blocks[slot].prescription.setTargets;
  final id = fields['targetId'];
  if (id != null) return targets.where((t) => t.targetId == id).firstOrNull;
  return targets
          .where((t) => !targetConsumed(guidance, slot, t.targetId))
          .firstOrNull ??
      targets.first;
}

bool targetConsumed(WorkoutGuidance guidance, int slot, String targetId) =>
    guidance.events.any(
      (e) =>
          e['slotIndex'] == slot &&
          e['targetId'] == targetId &&
          const {'performed', 'skippedTarget'}.contains(e['type']),
    );

Map<String, Object?> targetFields(SetPrescription target) => {
  'targetId': target.targetId,
  'setRole': target.setRole,
  'side': target.side,
  'weight': target.weightKg?.toString() ?? '',
  'reps': target.reps?.toString() ?? '',
  'seconds': target.seconds?.toString() ?? '',
};
