import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/push/push_settings_tile.dart';
import '../../../schedule/providers/activity_reminder_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/settings_section.dart';

class SettingsNotificationsPage extends ConsumerWidget {
  const SettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Powiadomienia')),
      body: SettingsPageLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(
              title: kIsWeb ? 'Ta instalacja PWA' : 'To urządzenie',
              children: [
                if (kIsWeb) const PushSettingsTile(),
                if (!kIsWeb)
                  SwitchListTile(
                    secondary: const Icon(Icons.sports_martial_arts_outlined),
                    title: const Text('Aktywności zewnętrzne — powiadomienia'),
                    subtitle: const Text(
                      'Zgoda urządzenia; terminy i osobny opt-in w Harmonogramie',
                    ),
                    value: settings.notifKarate,
                    onChanged: (value) async {
                      try {
                        await notifier.setNotifKarate(value);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
                  ),
                if (!kIsWeb)
                  SwitchListTile(
                    secondary: const Icon(Icons.fitness_center_outlined),
                    title: const Text('Treningi FitBirek — powiadomienia'),
                    subtitle: const Text(
                      'Zgoda urządzenia; terminy i osobny opt-in w Harmonogramie',
                    ),
                    value: settings.notifWorkout,
                    onChanged: (value) async {
                      try {
                        await notifier.setNotifWorkout(value);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
                  ),
                if (!kIsWeb)
                  SwitchListTile(
                    secondary: const Icon(Icons.mood_outlined),
                    title: const Text('Dziennik samopoczucia'),
                    subtitle: const Text('Codziennie, 20:30'),
                    value: settings.notifMood,
                    onChanged: notifier.setNotifMood,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Harmonogram',
              children: [
                ListTile(
                  title: const Text('Stan przypomnień harmonogramu'),
                  subtitle: Text(
                    ref.watch(activityReminderSyncProvider).valueOrNull ??
                        'Sprawdzanie migracji i przypomnień…',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Ponów migrację i przypomnienia',
                    onPressed: () =>
                        ref.invalidate(activityReminderSyncProvider),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
