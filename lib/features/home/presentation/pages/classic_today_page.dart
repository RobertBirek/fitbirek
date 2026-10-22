import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../health/presentation/widgets/health_today_card.dart';
import '../../../mood/presentation/widgets/mood_quick_entry_card.dart';
import '../../../onboarding/providers/user_profile_provider.dart';
import '../../../workout/providers/workout_providers.dart';
import '../../../workout/providers/session_recovery_provider.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../workout/preparation/providers/preparation_providers.dart';
import '../../../workout/preparation/presentation/workout_preparation_sheet.dart';
import '../../../schedule/presentation/widgets/today_schedule.dart';

/// Dotychczasowy ekran Dziś pozostaje dostępny jako w pełni offline klasyka.
class ClassicTodayPage extends ConsumerStatefulWidget {
  const ClassicTodayPage({super.key});

  @override
  ConsumerState<ClassicTodayPage> createState() => _ClassicTodayPageState();
}

class _ClassicTodayPageState extends ConsumerState<ClassicTodayPage> {
  bool _preparing = false;
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final active = ref.watch(activeWorkoutProvider).isActive;
    final recovery = ref.watch(sessionRecoveryProvider);
    final continueSession =
        active || (recovery.asData?.value.sessions.isNotEmpty ?? false);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Klasyczny trening')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${Formatters.weekday(now)}, ${Formatters.dayMonth(now)}'),
            const SizedBox(height: 4),
            profileAsync.when(
              data: (p) => Text(
                'Cześć, ${p?.imie ?? 'Sportowcu'}! 💪',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              loading: SizedBox.shrink,
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gotowy na trening?'),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: continueSession
                          ? 'Kontynuuj trening'
                          : 'Rozpocznij trening',
                      icon: Icons.play_arrow,
                      isLoading: _opening || (!active && recovery.isLoading),
                      onPressed: _preparing
                          ? null
                          : () async {
                              if (_preparing) return;
                              if (continueSession || recovery.hasError) {
                                context.go('/workout/session');
                                return;
                              }
                              if (recovery.isLoading) return;
                              final authority = ref.read(
                                cachedAuthWriteAuthorityProvider,
                              );
                              final epoch = authority.epoch;
                              bool guard() =>
                                  mounted && authority.epoch == epoch;
                              setState(() {
                                _preparing = true;
                                _opening = true;
                              });
                              try {
                                final snapshot = await ref
                                    .read(workoutPreparationWorkflowProvider)
                                    .open();
                                if (!context.mounted || !guard()) return;
                                setState(() => _opening = false);
                                final started = await showWorkoutPreparation(
                                  context,
                                  ref,
                                  snapshot: snapshot,
                                );
                                if (started == true &&
                                    context.mounted &&
                                    guard() &&
                                    ref.read(activeWorkoutProvider).isActive) {
                                  context.go('/workout/session');
                                }
                              } catch (e) {
                                if (context.mounted && guard()) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _preparing = false;
                                    _opening = false;
                                  });
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const MoodQuickEntryCard(),
            const SizedBox(height: 16),
            const TodaySchedule(),
            const SizedBox(height: 16),
            const HealthTodaySection(),
          ],
        ),
      ),
    );
  }
}
