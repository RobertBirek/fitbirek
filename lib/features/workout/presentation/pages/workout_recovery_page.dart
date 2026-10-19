import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../providers/session_recovery_provider.dart';
import '../../providers/workout_providers.dart';
import '../widgets/session_recovery_panel.dart';
import '../widgets/start_workout_button.dart';

class WorkoutRecoveryPage extends ConsumerWidget {
  const WorkoutRecoveryPage({super.key, this.exerciseId});
  final String? exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkoutProvider);
    final recovery = ref.watch(sessionRecoveryProvider);
    final exercises = ref.watch(allExercisesProvider);
    final selected = exercises.valueOrNull
        ?.where((e) => e.id == exerciseId)
        .firstOrNull;
    final canStart =
        (!recovery.isLoading &&
        !recovery.hasError &&
        recovery.valueOrNull?.sessions.every(
              (s) => active.isActive && s.syncId == active.sessionSyncId,
            ) ==
            true);
    return Scaffold(
      appBar: AppBar(title: const Text('Niedokończony trening')),
      body: SafeArea(
        child: Column(
          children: [
            if (selected != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Wybrane ćwiczenie: ${selected.nazwaPl} (bazowe)'),
              ),
            Expanded(
              child: canStart
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Dodanie ćwiczenia lub start wymaga osobnego potwierdzenia poniżej.',
                        ),
                        if (exerciseId == null || selected != null)
                          StartWorkoutButton(exercise: selected)
                        else
                          const Text(
                            'Nie można odczytać wybranego ćwiczenia. Wróć do katalogu i wybierz je ponownie.',
                          ),
                      ],
                    )
                  : const SessionRecoveryPanel(),
            ),
          ],
        ),
      ),
    );
  }
}
