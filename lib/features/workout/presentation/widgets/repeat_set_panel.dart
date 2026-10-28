import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_providers.dart';
import '../../domain/workout_repeat.dart';
import '../../../../core/models/set_role.dart';

class RepeatSetPanel extends ConsumerWidget {
  const RepeatSetPanel({super.key, this.extras = const []});
  final List<Widget> extras;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkoutProvider),
        target = active.repeatTarget;
    if (target == null) {
      return ListView(
        children: [
          const Text(
            'Wszystkie cele mają zapisane serie. Możesz zakończyć sesję.',
          ),
          ...extras,
        ],
      );
    }
    final exercise = active.selectedExercises
        .where((e) => e.id == target.exerciseId)
        .firstOrNull;
    if (exercise == null) {
      return Text(
        'Ćwiczenie ${target.exerciseId} niedostępne. Nie zmieniono celu na inne ćwiczenie.',
      );
    }
    return _RepeatForm(
      key: ValueKey('${active.sessionSyncId}:${active.repeatCompletedCount}'),
      target: target,
      index: active.repeatCompletedCount,
      extras: extras,
    );
  }
}

class _RepeatForm extends ConsumerStatefulWidget {
  const _RepeatForm({
    super.key,
    required this.target,
    required this.index,
    required this.extras,
  });
  final List<Widget> extras;
  final RepeatSetTarget target;
  final int index;
  @override
  ConsumerState<_RepeatForm> createState() => _RepeatFormState();
}

class _RepeatFormState extends ConsumerState<_RepeatForm> {
  late final TextEditingController reps, seconds, weight;
  final rpe = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    reps = TextEditingController(text: widget.target.reps?.toString() ?? '');
    seconds = TextEditingController(
      text: widget.target.seconds?.toString() ?? '',
    );
    weight = TextEditingController(
      text: widget.target.weightKg?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    reps.dispose();
    seconds.dispose();
    weight.dispose();
    rpe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Powtórzenie wykonania • seria ${widget.index + 1}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          '${target.name} • ${target.side ?? 'strona nieokreślona'} • ${target.variantLabel ?? 'bazowy'}',
        ),
        Text(SetRole.label(target.setRole)),
        if (target.previousRpe != null)
          Text('RPE poprzednio: ${target.previousRpe} — tylko odniesienie'),
        if (target.seconds != null)
          const Text(
            'Cel czasu pracy, bez odtwarzania protokołu interwałów. Zapisz tylko faktycznie wykonaną pracę.',
          ),
        if (target.reps != null)
          TextField(
            controller: reps,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Powtórzenia'),
          ),
        if (target.seconds != null)
          TextField(
            controller: seconds,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Sekundy'),
          ),
        TextField(
          controller: weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Ciężar (kg, opcjonalnie)',
          ),
        ),
        TextField(
          controller: rpe,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nowy RPE 1–10 (opcjonalnie)',
          ),
        ),
        if (error != null) Text(error!),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  final measuredReps = target.reps == null
                          ? null
                          : int.tryParse(reps.text),
                      measuredSeconds = target.seconds == null
                          ? null
                          : int.tryParse(seconds.text),
                      effort = rpe.text.isEmpty ? null : int.tryParse(rpe.text);
                  final load = weight.text.isEmpty
                      ? null
                      : double.tryParse(weight.text.replaceAll(',', '.'));
                  if ((target.reps != null &&
                          (measuredReps == null || measuredReps <= 0)) ||
                      (target.seconds != null &&
                          (measuredSeconds == null || measuredSeconds <= 0)) ||
                      (rpe.text.isNotEmpty &&
                          (effort == null || effort < 1 || effort > 10)) ||
                      (weight.text.isNotEmpty &&
                          (load == null || !load.isFinite || load < 0))) {
                    setState(
                      () => error =
                          'Podaj poprawny pomiar; RPE pozostaw puste albo wybierz 1–10.',
                    );
                    return;
                  }
                  setState(() {
                    busy = true;
                    error = null;
                  });
                  try {
                    final active = ref.read(activeWorkoutProvider);
                    if (active.repeatCompletedCount != widget.index) return;
                    final exercise = active.selectedExercises
                        .where((e) => e.id == target.exerciseId)
                        .firstOrNull;
                    if (exercise == null) {
                      throw StateError('Ćwiczenie niedostępne.');
                    }
                    await ref
                        .read(activeWorkoutProvider.notifier)
                        .logSet(
                          exercise: exercise,
                          reps: measuredReps,
                          seconds: measuredSeconds,
                          weightKg: load,
                          rpe: effort,
                          side: target.side,
                          variantId: target.variantId,
                          variantLabel: target.variantLabel,
                        );
                    if (mounted &&
                        ref.read(activeWorkoutProvider).repeatCompletedCount ==
                            widget.index) {
                      setState(
                        () => error =
                            'Nie zapisano serii. Sprawdź konto i dostępność wariantu.',
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => error =
                            'Nie zapisano serii. Cel pozostał bez zmian; sprawdź dostępność ćwiczenia i wariantu.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: const Text('Zapisz tę serię'),
        ),
        ...widget.extras,
      ],
    );
  }
}
