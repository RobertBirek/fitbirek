import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../mood/presentation/widgets/mood_quick_entry_card.dart';
import '../../../onboarding/providers/user_profile_provider.dart';
import '../../../workout/providers/workout_providers.dart';

/// Ekran "Dziś" - główny landing: powitanie, quick start, dziennik samopoczucia.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
    final now = DateTime.now();
    final isKarateDay = now.weekday == DateTime.tuesday || now.weekday == DateTime.thursday;

    return Scaffold(
      appBar: AppBar(title: const Text('Dziś')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${Formatters.weekday(now)}, ${Formatters.dayMonth(now)}',
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 4),
            profileAsync.when(
              data: (p) => Text(
                'Cześć, ${p?.imie ?? 'Sportowcu'}! 💪',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            if (isKarateDay)
              Card(
                color: FitBirekColors.accent.withValues(alpha: 0.15),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.sports_martial_arts, color: FitBirekColors.accent),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Dziś karate 20:00 - pamiętaj o rozgrzewce!'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gotowy na trening?',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Rozpocznij trening',
                      icon: Icons.play_arrow,
                      onPressed: () async {
                        final notifier = ref.read(activeWorkoutProvider.notifier);
                        await notifier.startSession();
                        if (context.mounted) context.go('/workout/session');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const MoodQuickEntryCard(),
          ],
        ),
      ),
    );
  }
}
