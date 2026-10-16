import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';

void main() {
  var now = Duration.zero;
  late IntervalTimer timer;
  setUp(() {
    now = Duration.zero;
    timer = IntervalTimer(
      IntervalConfig(preparation: 3, work: 10, rest: 5, rounds: 2),
      clock: () => now,
    );
  });
  test('boundaries, long jump, no final rest, start is idempotent', () {
    timer.start();
    expect(timer.phase, IntervalPhase.preparation);
    now = const Duration(seconds: 3);
    timer.update();
    expect(timer.phase, IntervalPhase.work);
    expect(timer.remainingSeconds, 10);
    now = const Duration(seconds: 13);
    timer.update();
    expect(timer.phase, IntervalPhase.rest);
    timer.start();
    now = const Duration(days: 1);
    timer.update();
    expect(timer.phase, IntervalPhase.complete);
    expect(timer.results.map((r) => r.seconds), [10, 10]);
    timer.update();
    expect(timer.results, hasLength(2));
  });
  test('pause excludes elapsed, resume cannot start a second run', () {
    timer.start();
    now = const Duration(seconds: 7);
    timer.pause();
    now = const Duration(hours: 1);
    timer.update();
    expect(timer.remainingSeconds, 6);
    timer.resume();
    timer.resume();
    now += const Duration(seconds: 6);
    timer.update();
    expect(timer.phase, IntervalPhase.rest);
    expect(timer.results.single.seconds, 10);
  });
  test(
    'skip records only actual work, drops zero, finish and cancel terminal',
    () {
      timer.start();
      timer.skip(); // preparation
      timer.skip(); // zero work
      timer.skip(); // rest
      now = const Duration(milliseconds: 2900);
      timer.finish();
      expect(timer.results.single.seconds, 2);
      expect(timer.results.single.shortened, isTrue);
      expect(timer.results.single.round, 2);
      timer.skip();
      timer.resume();
      expect(timer.results, hasLength(1));
      timer.cancel();
      now += const Duration(days: 1);
      timer.update();
      timer.start();
      expect(timer.phase, IntervalPhase.cancelled);
      expect(timer.results, isEmpty);
    },
  );
  test('zero preparation/rest and maximum rounds terminate', () {
    timer = IntervalTimer(
      IntervalConfig(preparation: 0, work: 1, rest: 0, rounds: 100),
      clock: () => now,
    )..start();
    expect(timer.phase, IntervalPhase.work);
    now = const Duration(seconds: 100);
    timer.update();
    expect(timer.phase, IntervalPhase.complete);
    expect(timer.results, hasLength(100));
  });
  test('configuration validates every bound', () {
    for (final values in [
      [-1, 1, 0, 1],
      [61, 1, 0, 1],
      [0, 0, 0, 1],
      [0, 3601, 0, 1],
      [0, 1, -1, 1],
      [0, 1, 601, 1],
      [0, 1, 0, 0],
      [0, 1, 0, 101],
    ]) {
      expect(
        () => IntervalConfig(
          preparation: values[0],
          work: values[1],
          rest: values[2],
          rounds: values[3],
        ),
        throwsArgumentError,
      );
    }
    expect(
      IntervalConfig(
        preparation: 60,
        work: 3600,
        rest: 600,
        rounds: 100,
      ).rounds,
      100,
    );
  });
}
