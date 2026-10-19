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
            if (!active.isActive) ...[
              for (final draft
                  in ref.watch(pendingWorkoutDraftsProvider).valueOrNull ?? [])
                ListTile(
                  title: const Text('Niedokończony trening'),
                  trailing: TextButton(
                    child: const Text('Kontynuuj'),
                    onPressed: () async {
                      final choice = await showDialog<String>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Wznowić trening?'),
                          content: const Text(
                            'Czas poza aplikacją nie zostanie zaliczony jako praca. Niepotwierdzone serie pozostają szkicem.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, 'resume'),
                              child: const Text('Wznów'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, 'restart'),
                              child: const Text('Start odcinka od nowa'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, 'finish'),
                              child: const Text('Zakończ'),
                            ),
                          ],
                        ),
                      );
                      if (choice == null) return;
                      final notifier = ref.read(activeWorkoutProvider.notifier);
                      if (choice == 'finish') {
                        final id = await notifier.finishPendingSession(
                          draft.sessionSyncId,
                        );
                        if (context.mounted && id != null) {
                          context.go('/workout/summary/$id');
                        }
                        return;
                      }
                      final resumed = await notifier.resumeSession(
                        draft.sessionSyncId,
                        restartSegment: choice == 'restart',
                      );
                      if (!context.mounted) return;
                      if (!resumed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Nie można wznowić: sesja, konto lub szkic są nieaktualne.',
                            ),
                          ),
                        );
                        return;
                      }
                      context.go('/workout/session');
                    },
                  ),
                ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: active.isActive
                    ? 'Wróć do aktywnej sesji'
                    : 'Nowy trening',
                icon: active.isActive ? Icons.play_circle_fill : Icons.add,
                onPressed: () async {
                  if (!active.isActive) {
                    await ref
                        .read(activeWorkoutProvider.notifier)
                        .startSession();
                  }
                  if (context.mounted) context.go('/workout/session');
                },
              ),
            ),
            // Planning only navigates; it must not start or replace a session.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: OutlinedButton.icon(
                onPressed: () => context.push('/settings/planner'),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Ułóż plan'),
              ),
            ),
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) {
                  final finished = sessions
                      .where((s) => s.dataKoniec != null)
                      .toList();
                  if (finished.isEmpty) {
                    return SingleChildScrollView(
                      child: EmptyState(
                        icon: Icons.history,
                        title: 'Brak historii treningów',
                        subtitle: 'Zacznij pierwszy trening →',
                        ctaLabel: 'Wybierz ćwiczenia z bazy',
                        onCtaPressed: () => context.go('/exercises'),
                      ),
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
                          subtitle: Text(
                            'Czas: ${Formatters.duration(s.czasTrwaniaSekund)}',
                          ),
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
