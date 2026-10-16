import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/rpe_slider.dart';
import '../../../../core/widgets/rest_timer_screen.dart';
import '../../../../core/widgets/isometric_stopwatch.dart';
import '../../../../core/models/exercise.dart';
import '../../../../core/utils/set_comparison.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../exercises/domain/exercise_catalog_metadata.dart';
import '../../providers/workout_providers.dart';
import '../../domain/interval_timer.dart';
import '../../providers/fixed_load_progression_provider.dart';
import 'interval_timer_screen.dart';

/// Ćwiczenia tego typu korzystają ze stopera (czas w górę) zamiast pól
/// ciężar/powtórzenia - plank, wall-sit, dead-hang itp.
///
/// Wartość 'Izometria' (nie 'Izometryczne') zgodna z realną bazą 316
/// ćwiczeń (Excel BAZA_GLOWNA, kolumna Typ) od [0.8.0].
const _typyIzometryczne = {'Izometria', 'time'};

/// Aktywna sesja treningowa: wybór ćwiczeń, logowanie serii, timer przerw.
class ActiveSessionPage extends ConsumerStatefulWidget {
  const ActiveSessionPage({super.key});

  @override
  ConsumerState<ActiveSessionPage> createState() => _ActiveSessionPageState();
}

class _ActiveSessionPageState extends ConsumerState<ActiveSessionPage> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktywny trening'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(activeWorkoutProvider.notifier).finishSession();
              if (context.mounted) context.go('/workout');
            },
            child: const Text('Zakończ'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'Dodaj ćwiczenie z bazy',
                icon: Icons.add,
                outlined: true,
                onPressed: () => context.push('/exercises'),
              ),
            ),
            Expanded(
              child: active.selectedExercises.isEmpty
                  ? const Center(
                      child: Text(
                        'Wybierz ćwiczenia, aby zacząć logować serie',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: active.selectedExercises.length,
                      itemBuilder: (context, i) {
                        final ex = active.selectedExercises[i];
                        return _ExerciseLogCard(
                          key: ValueKey(ex.id),
                          exercise: ex,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseLogCard extends ConsumerStatefulWidget {
  const _ExerciseLogCard({super.key, required this.exercise});
  final Exercise exercise;

  @override
  ConsumerState<_ExerciseLogCard> createState() => _ExerciseLogCardState();
}

class _ExerciseLogCardState extends ConsumerState<_ExerciseLogCard> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _secondsController = TextEditingController();
  int _rpe = 7;
  String _selectedSide = 'both';
  bool _intervalBusy = false;

  ExerciseCatalogEntry? get _entry => ref
      .read(exerciseCatalogMetadataProvider)
      .asData
      ?.value
      .entryFor(widget.exercise.id);
  String get _tracking =>
      _entry?.tracking ??
      (_typyIzometryczne.contains(widget.exercise.typ) ? 'time' : 'reps');
  bool get _isIsometric => _tracking != 'reps';
  String? get _side => _entry?.unilateral == true ? _selectedSide : null;
  bool get _usesWeight =>
      !_isIsometric &&
      (!widget.exercise.sprzet.contains('Masa własna') ||
          widget.exercise.sprzet.any(const {'Hantle', 'Sandbag'}.contains));

  FixedLoadRequest get _progressionRequest {
    final parsed = double.tryParse(_weightController.text.replaceAll(',', '.'));
    return (
      exerciseId: widget.exercise.id,
      side: _side,
      prescription: widget.exercise.seriexPowtorzenia,
      tracking: _tracking,
      usesWeight: _usesWeight,
      weightKg: _usesWeight && parsed != null && parsed.isFinite
          ? parsed
          : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_weightChanged);
  }

  void _weightChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _acceptProgression(
    FixedLoadRequest request,
    FixedLoadOffer offer,
  ) async {
    bool owns() => mounted && _progressionRequest == request;
    if (!owns() || !await offer.isCurrent() || !owns()) return;
    if (!mounted) return;
    final target = offer.suggestion.target;
    if (target == null) return;
    // Only reps are offered until timed configuration is persisted/comparable.
    final draft = _repsController.text;
    if (draft.isNotEmpty && draft != '$target') {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Zastąpić wpisany cel?'),
          content: Text(
            'Wpisano: $draft. Propozycja: $target powtórzeń. Seria nie zostanie zapisana.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Zachowaj'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Zastąp'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    if (!owns() ||
        _repsController.text != draft ||
        !await offer.isCurrent() ||
        !owns() ||
        _repsController.text != draft) {
      return;
    }
    _repsController.text = '$target';
  }

  Widget _progression() {
    final request = _progressionRequest;
    final result = ref.watch(fixedLoadProgressionProvider(request));
    // Do not keep previous-account/side data during refresh/loading/errors.
    final offer = result.isLoading || result.hasError
        ? null
        : result.asData?.value;
    if (offer == null) {
      return const Text(
        'Możliwy następny cel: brak dostępnej, wiarygodnej historii.',
      );
    }
    final suggestion = offer.suggestion;
    final last = offer.lastSet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (last == null)
          const Text(
            'Pierwszy raz - bez porównania',
            style: TextStyle(color: Colors.grey),
          )
        else
          Text(
            _isIsometric
                ? 'Ostatnio: ${last.czasSekund ?? '-'} s (RPE ${last.rpe ?? '-'})'
                : 'Ostatnio: ${last.ciezarKg == null ? '' : '${last.ciezarKg} kg × '}${last.powtorzenia ?? '-'} powt. (RPE ${last.rpe ?? '-'})',
            style: const TextStyle(color: FitBirekColors.accent),
          ),
        const Text(
          'Możliwy następny cel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(suggestion.reason),
        if (suggestion.target != null) ...[
          Text(
            '${suggestion.target} powt. • ${suggestion.weightKg == null ? 'masa własna / bez dodatkowego ciężaru' : '${suggestion.weightKg} kg (bez zmian)'} • ${setSideLabel(request.side)}',
          ),
          for (final e in suggestion.evidence)
            Text(
              'Trening ${e.endedAt.toLocal().toString().split(' ').first}: minimum ${e.reps} powt., najwyższe RPE ${e.rpe} (sesja ${e.sessionId}).',
            ),
          const Text(
            'To opcja na najbliższą sesję, nie obowiązek. Możesz ją odrzucić. Przyjęcie zmienia tylko pole powtórzeń, nie zapisuje serii.',
          ),
          TextButton(
            onPressed: () => _acceptProgression(request, offer),
            child: const Text('Przyjmij cel'),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _weightController.removeListener(_weightChanged);
    _weightController.dispose();
    _repsController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  /// Wspólna logika po zalogowaniu serii: powiadomienie o PR + auto-timer przerwy.
  Future<void> _afterLogSet(bool isPr) async {
    if (!mounted) return;
    final workout = ref.read(activeWorkoutProvider);
    if (!workout.isActive || workout.loggedSets.isEmpty) return;
    final saved = workout.loggedSets.last;
    if (isPr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Nowy rekord w ${widget.exercise.nazwaPl} • ${setSideLabel(saved.side)}!',
          ),
          backgroundColor: FitBirekColors.accent,
        ),
      );
    }
    setState(() {});
    // Automatyczny timer przerwy po zalogowanej serii - domyślnie 90s,
    // użytkownik może zmienić na 60/120/180s lub własny czas na ekranie timera.
    if (mounted) {
      await showRestTimer(context, initialSeconds: 90);
    }
  }

  Future<void> _startIsometricStopwatch() async {
    final side = _side;
    final seconds = await showIsometricStopwatch(
      context,
      label: widget.exercise.nazwaPl,
    );
    if (seconds == null || seconds <= 0) return;
    final isPr = await ref
        .read(activeWorkoutProvider.notifier)
        .logSet(
          exercise: widget.exercise,
          seconds: seconds,
          rpe: _rpe,
          side: side,
        );
    await _afterLogSet(isPr);
  }

  Future<void> _startIntervals() async {
    if (_intervalBusy) return;
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final origin = notifier.captureInterval(
      exercise: widget.exercise,
      side: _side,
      rpe: _rpe,
    );
    if (origin == null) return;
    setState(() => _intervalBusy = true);
    try {
      final result = await Navigator.of(context).push<List<IntervalRound>>(
        MaterialPageRoute(
          builder: (_) => IntervalTimerScreen(
            label: '${widget.exercise.nazwaPl} • ${setSideLabel(origin.side)}',
            isValid: () => mounted && notifier.isIntervalCurrent(origin),
          ),
        ),
      );
      if (!mounted || result == null) return;
      final saved = await notifier.saveIntervalRounds(
        origin,
        result,
        guard: () => mounted,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Zapisano wykonane rundy.'
                : 'Nie zapisano rund: sesja lub konto są nieaktualne.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nie udało się zapisać rund. Wyniki nie zostały zapisane.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _intervalBusy = false);
    }
  }

  Future<void> _logStrengthSet() async {
    final weight = _usesWeight
        ? double.tryParse(_weightController.text.replaceAll(',', '.'))
        : null;
    final reps = int.tryParse(_repsController.text);
    if (reps == null ||
        reps <= 0 ||
        (_usesWeight &&
            _weightController.text.isNotEmpty &&
            (weight == null || !weight.isFinite || weight < 0))) {
      _invalidSet();
      return;
    }
    final isPr = await ref
        .read(activeWorkoutProvider.notifier)
        .logSet(
          exercise: widget.exercise,
          weightKg: weight,
          reps: reps,
          rpe: _rpe,
          side: _side,
        );
    await _afterLogSet(isPr);
  }

  void _invalidSet() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Podaj dodatnią liczbę powtórzeń lub sekund; ciężar musi być nieujemny.',
      ),
    ),
  );

  Future<void> _logTimedSet() async {
    final seconds = int.tryParse(_secondsController.text);
    if (seconds == null || seconds <= 0) {
      _invalidSet();
      return;
    }
    final isPr = await ref
        .read(activeWorkoutProvider.notifier)
        .logSet(
          exercise: widget.exercise,
          seconds: seconds,
          rpe: _rpe,
          side: _side,
        );
    await _afterLogSet(isPr);
  }

  @override
  Widget build(BuildContext context) {
    // Loading/error/missing metadata intentionally falls back to the legacy type.
    ref.watch(exerciseCatalogMetadataProvider);
    final loggedForThis = ref
        .watch(activeWorkoutProvider)
        .loggedSets
        .where((s) => s.exerciseId == widget.exercise.id && s.side == _side)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.nazwaPl,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            if (_entry?.unilateral == true) ...[
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'left', label: Text('Lewa')),
                  ButtonSegment(value: 'right', label: Text('Prawa')),
                  ButtonSegment(value: 'both', label: Text('Obie')),
                ],
                selected: {_selectedSide},
                onSelectionChanged: (value) =>
                    setState(() => _selectedSide = value.single),
              ),
              const Text(
                'PR i porównania są liczone osobno dla każdej strony. 1RM tylko dla kg + powtórzeń.',
              ),
            ],
            if (loggedForThis.isNotEmpty &&
                loggedForThis.last.comparison != null)
              Text(
                'Zmiana względem poprzedniej serii • ${setSideLabel(_side)}: ${loggedForThis.last.comparison}',
              ),
            _progression(),
            const SizedBox(height: 12),
            if (_isIsometric) ...[
              if (_tracking == 'rounds')
                PrimaryButton(
                  label: _intervalBusy
                      ? 'Interwały w toku…'
                      : 'Timer interwałów',
                  icon: Icons.av_timer,
                  onPressed: _intervalBusy ? null : _startIntervals,
                ),
              TextField(
                controller: _secondsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _tracking == 'rounds'
                      ? 'Czas pracy rundy (s)'
                      : 'Czas (s)',
                ),
              ),
              PrimaryButton(
                label: _tracking == 'rounds'
                    ? 'Zapisz rundę (${loggedForThis.length})'
                    : 'Zapisz czas (${loggedForThis.length})',
                icon: Icons.check,
                onPressed: _logTimedSet,
              ),
              RpeSlider(
                value: _rpe,
                onChanged: (v) => setState(() => _rpe = v),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Start stopera (${loggedForThis.length})',
                icon: Icons.timer_outlined,
                onPressed: _startIsometricStopwatch,
              ),
            ] else ...[
              Row(
                children: [
                  if (_usesWeight)
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ciężar (kg)',
                        ),
                      ),
                    ),
                  if (_usesWeight) const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Powtórzenia',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RpeSlider(
                value: _rpe,
                onChanged: (v) => setState(() => _rpe = v),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Seria wykonana (${loggedForThis.length})',
                icon: Icons.check,
                onPressed: _logStrengthSet,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
