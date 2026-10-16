/// Pure interval engine: the clock is monotonic, UI ticks only sample it.
enum IntervalPhase { preparation, work, rest, complete, cancelled }

class IntervalConfig {
  IntervalConfig({
    required this.preparation,
    required this.work,
    required this.rest,
    required this.rounds,
  }) {
    if (preparation < 0 ||
        preparation > 60 ||
        work < 1 ||
        work > 3600 ||
        rest < 0 ||
        rest > 600 ||
        rounds < 1 ||
        rounds > 100) {
      throw ArgumentError(
        'Przygotowanie: 0–60 s, praca: 1–3600 s, '
        'przerwa: 0–600 s, rundy: 1–100.',
      );
    }
  }
  final int preparation, work, rest, rounds;
}

class IntervalRound {
  const IntervalRound({
    required this.round,
    required this.seconds,
    required this.shortened,
  });
  final int round;
  final int seconds;
  final bool shortened;
}

class IntervalTimer {
  IntervalTimer(this.config, {Duration Function()? clock}) {
    if (clock == null) {
      final stopwatch = Stopwatch()..start();
      _clock = () => stopwatch.elapsed;
    } else {
      _clock = clock;
    }
  }
  final IntervalConfig config;
  late final Duration Function() _clock;
  IntervalPhase phase = IntervalPhase.preparation;
  int round = 1;
  bool paused = false;
  bool _started = false;
  Duration _last = Duration.zero;
  Duration _elapsed = Duration.zero;
  final List<IntervalRound> _results = [];
  List<IntervalRound> get results => List.unmodifiable(_results);
  bool get terminal =>
      phase == IntervalPhase.complete || phase == IntervalPhase.cancelled;
  int get _phaseSeconds => switch (phase) {
    IntervalPhase.preparation => config.preparation,
    IntervalPhase.work => config.work,
    IntervalPhase.rest => config.rest,
    _ => 0,
  };
  int get remainingSeconds => terminal
      ? 0
      : ((_phaseSeconds * Duration.microsecondsPerSecond -
                    _elapsed.inMicroseconds) /
                Duration.microsecondsPerSecond)
            .ceil();

  void start() {
    if (_started || terminal) return;
    _started = true;
    _last = _clock();
    update();
  }

  void update() {
    if (!_started || paused || terminal) return;
    final now = _clock();
    final delta = now - _last;
    _last = now;
    if (delta.isNegative) throw StateError('Clock must be monotonic');
    _elapsed += delta;
    // Each iteration advances a phase/round; at most 201 transitions even
    // after a long background suspension, including zero prep/rest.
    while (!terminal && _elapsed >= Duration(seconds: _phaseSeconds)) {
      _elapsed -= Duration(seconds: _phaseSeconds);
      _advance(fullWork: true);
    }
  }

  void _record(int seconds, {required bool shortened}) {
    if (seconds > 0) {
      _results.add(
        IntervalRound(round: round, seconds: seconds, shortened: shortened),
      );
    }
  }

  void _advance({required bool fullWork}) {
    switch (phase) {
      case IntervalPhase.preparation:
        phase = IntervalPhase.work;
      case IntervalPhase.work:
        _record(
          fullWork ? config.work : _elapsed.inSeconds,
          shortened: !fullWork,
        );
        if (round == config.rounds) {
          phase = IntervalPhase.complete;
        } else {
          phase = IntervalPhase.rest;
        }
      case IntervalPhase.rest:
        round++;
        phase = IntervalPhase.work;
      case IntervalPhase.complete:
      case IntervalPhase.cancelled:
        break;
    }
  }

  void pause() {
    update();
    if (!terminal) paused = true;
  }

  void resume() {
    if (!paused || terminal) return;
    _last = _clock();
    paused = false;
  }

  void skip() {
    update();
    if (!_started || terminal) return;
    _advance(fullWork: false);
    _elapsed = Duration.zero;
    // Drain a zero rest even when paused, without consuming paused time.
    while (!terminal && _phaseSeconds == 0) {
      _advance(fullWork: true);
    }
  }

  /// End early for review; never writes. Sub-second work is dropped (not rounded up).
  void finish() {
    update();
    if (!_started || terminal) return;
    if (phase == IntervalPhase.work) {
      _record(_elapsed.inSeconds, shortened: true);
    }
    phase = IntervalPhase.complete;
  }

  void cancel() {
    phase = IntervalPhase.cancelled;
    _results.clear();
  }
}
