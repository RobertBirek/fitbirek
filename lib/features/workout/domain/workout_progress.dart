import 'workout_guidance.dart';
import 'workout_repeat.dart';

/// Evidence is exclusively live set UUIDs, never selection, skips or wall time.
class WorkoutProgress {
  const WorkoutProgress(this.actual, this.confirmed, this.target);
  final int actual, confirmed;
  final int? target;
  int? get percent => target == null || target == 0
      ? null
      : (100 * confirmed ~/ target!).clamp(0, 100);
  int get remaining =>
      target == null ? 0 : (target! - confirmed).clamp(0, target!);
  String get label => target == null
      ? 'Zapisane serie: $actual'
      : 'Postęp celu: $confirmed/$target • $percent% • zapisane serie: $actual';

  factory WorkoutProgress.from({
    required Iterable<String> liveSetIds,
    WorkoutGuidance? guidance,
    WorkoutRepeat? repeat,
    Iterable<String> repeatCompleted = const [],
  }) {
    final live = liveSetIds.toSet();
    if (guidance != null) {
      final seen = <String>{};
      var confirmed = 0, target = 0;
      for (var slot = 0; slot < guidance.plan.blocks.length; slot++) {
        final goal = guidance.plan.blocks[slot].prescription.sets;
        target += goal;
        var actual = 0;
        for (final e in guidance.events) {
          if (e['type'] == 'performed' &&
              e['slotIndex'] == slot &&
              live.contains(e['setSyncId']) &&
              seen.add(e['setSyncId'] as String)) {
            actual++;
          }
        }
        confirmed += actual.clamp(0, goal);
      }
      return WorkoutProgress(live.length, confirmed, target);
    }
    if (repeat != null) {
      final target = repeat.targets.length;
      return WorkoutProgress(
        live.length,
        repeatCompleted.toSet().intersection(live).length.clamp(0, target),
        target,
      );
    }
    return WorkoutProgress(live.length, 0, null);
  }
}
