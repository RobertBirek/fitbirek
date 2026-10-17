import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';

void main() {
  test(
    'checkpoint restores paused, no downtime, exact partial work and rounds',
    () {
      var now = Duration.zero;
      final timer = IntervalTimer(
        IntervalConfig(preparation: 0, work: 10, rest: 2, rounds: 2),
        clock: () => now,
      )..start();
      now = const Duration(seconds: 15);
      timer.update();
      final checkpoint = timer.checkpoint();
      now = const Duration(days: 1);
      final restored = IntervalTimer.restore(checkpoint, clock: () => now);
      expect(restored.paused, isTrue);
      expect(restored.round, 2);
      expect(restored.remainingSeconds, 7);
      expect(restored.results.single.seconds, 10);
      final restarted = IntervalTimer.restore(
        checkpoint,
        clock: () => now,
        restartSegment: true,
      );
      expect(restarted.results.single.seconds, 10);
      expect(restarted.remainingSeconds, 10);
      expect(restarted.round, 2);
      expect(restarted.paused, isTrue);
      restored.resume();
      now += const Duration(seconds: 2);
      restored.finish();
      expect(restored.results.last.seconds, 5);
      expect(restored.results.last.shortened, isTrue);
    },
  );
  test('checkpoint rejects impossible phase or actual work', () {
    final timer = IntervalTimer(
      IntervalConfig(preparation: 0, work: 10, rest: 0, rounds: 1),
    )..start();
    expect(
      () => IntervalTimer.restore({...timer.checkpoint(), 'elapsedMicros': -1}),
      throwsFormatException,
    );
    expect(
      () => IntervalTimer.restore({...timer.checkpoint(), 'phase': 'future'}),
      throwsFormatException,
    );
  });
}
