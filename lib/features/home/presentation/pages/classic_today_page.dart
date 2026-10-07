import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../health/presentation/widgets/health_today_card.dart';
import '../../../mood/presentation/widgets/mood_quick_entry_card.dart';
import '../../../onboarding/providers/user_profile_provider.dart';
import '../../../workout/providers/workout_providers.dart';

/// Dotychczasowy ekran Dziś pozostaje dostępny jako w pełni offline klasyka.
class ClassicTodayPage extends ConsumerWidget {
  const ClassicTodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileStreamProvider);
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
                      label: 'Rozpocznij trening',
                      icon: Icons.play_arrow,
                      onPressed: () async {
                        await ref
                            .read(activeWorkoutProvider.notifier)
                            .startSession();
                        if (context.mounted) context.go('/workout/session');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const MoodQuickEntryCard(),
            const SizedBox(height: 16),
            const HealthTodaySection(),
          ],
        ),
      ),
    );
  }
}
