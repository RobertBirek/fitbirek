import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/workout_providers.dart';


/// Ekran "Trening" - start nowej sesji + historia treningów.
class WorkoutHomePage extends ConsumerWidget {
  const WorkoutHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsProvider);
    final active = ref.watch(activeWorkoutProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trening')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: active.isActive ? 'Wróć do aktywnej sesji' : 'Nowy trening',
                icon: active.isActive ? Icons.play_circle_fill : Icons.add,
                onPressed: () async {
                  if (!active.isActive) {
                    await ref.read(activeWorkoutProvider.notifier).startSession();
                  }
                  if (context.mounted) context.go('/workout/session');
                },
              ),
            ),
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) {
                  final finished = sessions.where((s) => s.dataKoniec != null).toList();
                  if (finished.isEmpty) {
                    return EmptyState(
                      icon: Icons.history,
                      title: 'Brak historii treningów',
                      subtitle: 'Zacznij pierwszy trening →',
                      ctaLabel: 'Wybierz ćwiczenia z bazy',
                      onCtaPressed: () => context.go('/exercises'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: finished.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = finished[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: Text(Formatters.dateTime(s.dataStart)),
                          subtitle: Text('Czas: ${Formatters.duration(s.czasTrwaniaSekund)}'),
                          onTap: () => context.push('/workout/summary/${s.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Błąd: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reeksport dla wygody importu w innych plikach (zapobiega unused import warning).
typedef _Unused = ExercisesListPage;
