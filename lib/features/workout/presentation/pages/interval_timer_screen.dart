import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/interval_timer.dart';

/// Checkpoints contain local data only; only explicit save returns actual work.
class IntervalTimerScreen extends StatefulWidget {
  const IntervalTimerScreen({
    super.key,
    required this.label,
    this.clock,
    this.isValid,
    this.checkpoint,
    this.onCheckpoint,
    this.singleRound = false,
    this.initialWorkSeconds,
  });
  final String label;
  final Duration Function()? clock;
  final bool Function()? isValid;
  final Map<String, dynamic>? checkpoint;
  final void Function(Map<String, Object?>?)? onCheckpoint;
  final bool singleRound;
  final int? initialWorkSeconds;
  @override
  State<IntervalTimerScreen> createState() => _IntervalTimerScreenState();
}

class _IntervalTimerScreenState extends State<IntervalTimerScreen>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _preparation = TextEditingController(text: '5');
  final _work = TextEditingController(text: '30');
  final _rest = TextEditingController(text: '15');
  final _rounds = TextEditingController(text: '3');
  IntervalTimer? _engine;
  Timer? _ticker;
  bool _signals = false, _returned = false, _allowPop = false;
  bool _invalid = false, _confirming = false;
  bool _foreground = true;
  DateTime _lastTick = DateTime.now();
  String? _lastCheckpoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.singleRound) _rounds.text = '1';
    if (widget.initialWorkSeconds != null) {
      _work.text = '${widget.initialWorkSeconds}';
    }
    if (widget.checkpoint != null) {
      try {
        _engine = IntervalTimer.restore(
          widget.checkpoint!,
          clock: widget.clock,
        );
        if (widget.singleRound && _engine!.config.rounds != 1) {
          _engine = null;
          _invalid = true;
        }
      } on FormatException {
        _invalid = true;
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _engine?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    for (final c in [_preparation, _work, _rest, _rounds]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && widget.onCheckpoint != null) {
      _engine?.pause();
      _persist();
    }
    _ticker?.cancel();
    _ticker = null;
    if (_foreground) {
      _lastTick = DateTime.now();
      _refresh(signal: false);
      _schedule();
    }
  }

  bool _checkOrigin() {
    if (_invalid) return false;
    if (widget.isValid?.call() ?? true) return true;
    _engine?.cancel();
    _ticker?.cancel();
    _ticker = null;
    _invalid = true;
    return false;
  }

  void _schedule() {
    _ticker?.cancel();
    _ticker = null;
    final engine = _engine;
    if (!mounted ||
        !_foreground ||
        engine == null ||
        engine.paused ||
        engine.terminal ||
        _invalid) {
      return;
    }
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _refresh(),
    );
  }

  // No delayed sound callbacks: invoke only for a live foreground transition.
  Future<void> _signal() async {
    if (!mounted ||
        !_signals ||
        !_foreground ||
        _invalid ||
        _engine?.paused == true) {
      return;
    }
    try {
      unawaited(
        SystemSound.play(SystemSoundType.click).catchError((Object _) {}),
      );
      unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));
    } catch (_) {
      /* Visual phase/time remains the fallback on every platform. */
    }
  }

  void _refresh({bool signal = true}) {
    if (!mounted || _returned) return;
    final engine = _engine;
    final now = DateTime.now();
    if (widget.onCheckpoint != null &&
        now.difference(_lastTick).inSeconds > 3) {
      engine?.suspendUnobserved();
    }
    _lastTick = now;
    final before = engine == null ? '' : '${engine.phase}:${engine.round}';
    if (_checkOrigin()) engine?.update();
    if (signal &&
        engine != null &&
        before != '${engine.phase}:${engine.round}') {
      unawaited(_signal());
    }
    if (_invalid || engine?.terminal == true) {
      _ticker?.cancel();
      _ticker = null;
    }
    setState(() {});
    _persist();
  }

  void _persist() {
    final engine = _engine;
    if (engine == null || _invalid || _returned) return;
    final key =
        '${engine.phase}:${engine.round}:${engine.remainingSeconds}:${engine.paused}';
    if (key == _lastCheckpoint) return;
    _lastCheckpoint = key;
    widget.onCheckpoint?.call(engine.checkpoint());
  }

  void _start() {
    if (!_checkOrigin()) {
      setState(() {});
      return;
    }
    if (!_form.currentState!.validate() || _engine != null) return;
    _engine = IntervalTimer(
      IntervalConfig(
        preparation: int.parse(_preparation.text),
        work: int.parse(_work.text),
        rest: int.parse(_rest.text),
        rounds: int.parse(_rounds.text),
      ),
      clock: widget.clock,
    )..start();
    setState(() {});
    _schedule();
    _persist();
  }

  void _act(void Function(IntervalTimer) action) {
    if (!_checkOrigin()) {
      setState(() {});
      return;
    }
    action(_engine!);
    _refresh();
    _schedule();
  }

  Future<void> _cancel() async {
    if (_confirming || _returned) return;
    _confirming = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anulować interwały?'),
        content: const Text('Wyniki nie zostaną zapisane.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Wróć'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Odrzuć'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (!mounted || discard != true) return;
    _engine?.cancel();
    widget.onCheckpoint?.call(null);
    _return(null);
  }

  void _return(List<IntervalRound>? results) {
    if (_returned || !mounted) return;
    _returned = true;
    _ticker?.cancel();
    setState(() => _allowPop = true);
    // PopScope must first rebuild with canPop=true. The reservation above
    // prevents a second tap from scheduling another pop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(results);
    });
  }

  Widget _field(
    String key,
    String label,
    TextEditingController c,
    int min,
    int max,
  ) => TextFormField(
    key: Key(key),
    controller: c,
    enabled: key != 'rounds' || !widget.singleRound,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: '$label ($min–$max)'),
    validator: (text) {
      final value = int.tryParse(text ?? '');
      return value == null || value < min || value > max
          ? '$label: $min–$max'
          : null;
    },
  );

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    final complete = engine?.phase == IntervalPhase.complete;
    final phaseLabel = switch (engine?.phase) {
      IntervalPhase.preparation => 'Przygotowanie',
      IntervalPhase.work => 'Praca',
      IntervalPhase.rest => 'Przerwa',
      IntervalPhase.complete => 'Zakończenie',
      _ => 'Anulowano',
    };
    return PopScope<List<IntervalRound>>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_cancel());
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Interwały • ${widget.label}')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.onCheckpoint == null
                    ? 'W tle odliczanie może być wstrzymane przez system. Po powrocie czas jest przeliczany. Brak gwarancji sygnału lub wybudzenia w tle.'
                    : 'Wyjście w tło wstrzymuje pracę. Po powrocie wybierz Wznów. Czas poza aplikacją nie jest pracą; checkpoint nie zapisuje serii.',
              ),
              if (_invalid)
                const Text('Sesja lub konto uległy zmianie. Wyniki odrzucono.')
              else if (engine == null)
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      _field(
                        'preparation',
                        'Przygotowanie (s)',
                        _preparation,
                        0,
                        60,
                      ),
                      _field('work', 'Praca', _work, 1, 3600),
                      _field('rest', 'Przerwa (s)', _rest, 0, 600),
                      _field(
                        'rounds',
                        'Rundy',
                        _rounds,
                        1,
                        widget.singleRound ? 1 : 100,
                      ),
                      if (widget.singleRound)
                        const Text(
                          'Jeden wybrany cel, jedna runda. Wielorundowy timer jest dostępny dla ćwiczeń dodatkowych, bez potwierdzania celów planu.',
                        ),
                      FilledButton(
                        onPressed: _start,
                        child: const Text('Rozpocznij interwały'),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Runda ${engine.round} / ${engine.config.rounds}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  phaseLabel,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (!complete) ...[
                  Text(
                    '${engine.remainingSeconds} s',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  if (engine.paused) const Text('Wstrzymano'),
                  FilledButton(
                    onPressed: () =>
                        _act((e) => e.paused ? e.resume() : e.pause()),
                    child: Text(engine.paused ? 'Wznów' : 'Pauza'),
                  ),
                  TextButton(
                    onPressed: () => _act((e) => e.skip()),
                    child: const Text('Pomiń odcinek'),
                  ),
                  TextButton(
                    onPressed: () => _act((e) => e.finish()),
                    child: const Text('Zakończ odliczanie'),
                  ),
                ],
                for (final r in engine.results)
                  Text(
                    'Runda ${r.round}: ${r.seconds} s${r.shortened ? ' • skrócona' : ''}',
                  ),
                const Text(
                  'Zapisywany jest tylko czas pracy (pełne sekundy). Odcinki poniżej 1 s są pomijane. Przerwy nie są zapisywane.',
                ),
                if (complete && engine.results.isNotEmpty)
                  FilledButton(
                    onPressed: _returned
                        ? null
                        : () {
                            if (!_checkOrigin()) {
                              setState(() {});
                              return;
                            }
                            _return(engine.results);
                          },
                    child: const Text('Zapisz wykonane rundy'),
                  ),
                if (complete && engine.results.isEmpty)
                  const Text('Brak wykonanych rund do zapisania.'),
              ],
              SwitchListTile(
                title: const Text('Dźwięk i wibracja (jeśli dostępne)'),
                value: _signals,
                onChanged: (value) => setState(() => _signals = value),
              ),
              TextButton(onPressed: _cancel, child: const Text('Anuluj')),
            ],
          ),
        ),
      ),
    );
  }
}
