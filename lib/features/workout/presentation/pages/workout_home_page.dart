import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/session_recovery_provider.dart';
import '../../providers/workout_providers.dart';
import '../widgets/start_workout_button.dart';
import '../widgets/session_delete_button.dart';
import '../widgets/session_progress_text.dart';
import '../../domain/workout_guidance.dart';

/// One scrollable for actions, all recoverable sessions (also without drafts),
/// and history. Recovery decisions use the guarded shared panel, not a draft ID.
class WorkoutHomePage extends ConsumerWidget {
  const WorkoutHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsProvider);
    final active = ref.watch(activeWorkoutProvider);
    final recovery = ref.watch(sessionRecoveryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Trening')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const StartWorkoutButton(),
            OutlinedButton.icon(
              onPressed: () => context.push('/schedule'),
              icon: const Icon(Icons.event_repeat),
              label: const Text('Harmonogram aktywności'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/workout/templates'),
              icon: const Icon(Icons.list_alt),
              label: const Text('Moje szablony'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/settings/planner'),
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Ułóż plan'),
            ),
            if (!recovery.isLoading && !recovery.hasError)
              for (final session
                  in (recovery.valueOrNull?.sessions ?? []).where(
                    (s) => !active.isActive || s.syncId != active.sessionSyncId,
                  ))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Niedokończony trening'),
                        Text('Trening ${session.started.toLocal()}'),
                        Text('Sesja: ${session.syncId}'),
                        if (session.problem != null) Text(session.problem!),
                        SessionDeleteButton(sessionId: session.id),
                        TextButton(
                          onPressed: () => context.push('/workout/recovery'),
                          child: const Text('Odzyskaj lub zakończ'),
                        ),
                      ],
                    ),
                  ),
                ),
            ...sessionsAsync.when(
              data: (sessions) {
                final finished = sessions
                    .where((s) => s.dataKoniec != null)
                    .toList();
                if (finished.isEmpty) {
                  return [
                    EmptyState(
                      icon: Icons.history,
                      title: 'Brak historii treningów',
                      subtitle: 'Zacznij pierwszy trening →',
                      ctaLabel: 'Wybierz ćwiczenia z bazy',
                      onCtaPressed: () => context.go('/exercises'),
                    ),
                  ];
                }
                return finished
                    .map(
                      (s) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: Text(Formatters.dateTime(s.dataStart)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Czas: ${Formatters.duration(s.czasTrwaniaSekund)}',
                              ),
                              SessionProgressText(
                                sessionId: s.id,
                                guidance: WorkoutGuidance.tryRead(
                                  s.guidanceJson,
                                ),
                              ),
                            ],
                          ),
                          trailing: SessionDeleteButton(
                            sessionId: s.id,
                            compact: true,
                          ),
                          onTap: () => context.push('/workout/summary/${s.id}'),
                        ),
                      ),
                    )
                    .toList();
              },
              loading: () => <Widget>[
                const Center(child: CircularProgressIndicator()),
              ],
              error: (_, _) => <Widget>[
                const Text('Nie udało się odczytać historii treningów.'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
