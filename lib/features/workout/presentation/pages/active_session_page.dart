import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/rpe_slider.dart';
import '../../../../core/models/exercise.dart';
import '../../providers/workout_providers.dart';
import '../../../exercises/providers/exercises_providers.dart';

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
                      child: Text('Wybierz ćwiczenia, aby zacząć logować serie'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: active.selectedExercises.length,
                      itemBuilder: (context, i) {
                        final ex = active.selectedExercises[i];
                        return _ExerciseLogCard(exercise: ex);
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
  const _ExerciseLogCard({required this.exercise});
  final Exercise exercise;

  @override
  ConsumerState<_ExerciseLogCard> createState() => _ExerciseLogCardState();
}

class _ExerciseLogCardState extends ConsumerState<_ExerciseLogCard> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  int _rpe = 7;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loggedForThis = ref
        .watch(activeWorkoutProvider)
        .loggedSets
        .where((s) => s.exerciseId == widget.exercise.id)
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
            FutureBuilder(
              future: ref.read(workoutRepositoryProvider).getLastSet(widget.exercise.id),
              builder: (context, snapshot) {
                final last = snapshot.data;
                if (last == null) {
                  return const Text('Pierwszy raz - bez porównania',
                      style: TextStyle(color: Colors.grey));
                }
                return Text(
                  'Ostatnio: ${last.ciezarKg ?? '-'} kg × ${last.powtorzenia ?? '-'} (RPE ${last.rpe ?? '-'})',
                  style: const TextStyle(color: FitBirekColors.accent),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ciężar (kg)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Powtórzenia'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RpeSlider(value: _rpe, onChanged: (v) => setState(() => _rpe = v)),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Seria wykonana (${loggedForThis.length})',
              icon: Icons.check,
              onPressed: () async {
                final weight = double.tryParse(_weightController.text);
                final reps = int.tryParse(_repsController.text);
                final isPr = await ref.read(activeWorkoutProvider.notifier).logSet(
                      exercise: widget.exercise,
                      weightKg: weight,
                      reps: reps,
                      rpe: _rpe,
                    );
                if (isPr && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Nowy rekord w ${widget.exercise.nazwaPl}!'),
                      backgroundColor: FitBirekColors.accent,
                    ),
                  );
                }
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
