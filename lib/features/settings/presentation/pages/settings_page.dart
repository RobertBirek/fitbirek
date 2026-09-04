import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants.dart';
import '../../providers/settings_provider.dart';

/// Ekran Ustawienia: profil, motyw, dźwięk, wibracje, backup, o aplikacji.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edytuj profil'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/edit-profile'),
            ),
            ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Kalkulator kalorii/makro'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/calculator'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Generator planu treningowego'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/planner'),
            ),
            const Divider(),
            ListTile(
              title: const Text('Motyw'),
              subtitle: Text(switch (settings.themeMode) {
                ThemeMode.dark => 'Ciemny',
                ThemeMode.light => 'Jasny',
                ThemeMode.system => 'Systemowy',
              }),
              trailing: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Ciemny'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Jasny'),
                  ),
                ],
                onChanged: (m) => m != null ? notifier.setThemeMode(m) : null,
              ),
            ),
            SwitchListTile(
              title: const Text('Dźwięk gongu'),
              value: settings.soundEnabled,
              onChanged: notifier.setSoundEnabled,
            ),
            SwitchListTile(
              title: const Text('Wibracje'),
              value: settings.vibrationEnabled,
              onChanged: notifier.setVibrationEnabled,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Eksport danych (JSON)'),
              subtitle: const Text('Funkcja w przygotowaniu'),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Import danych (JSON)'),
              subtitle: const Text('Funkcja w przygotowaniu'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('O aplikacji'),
              subtitle: Text(
                '${AppConstants.appName} v${AppConstants.appVersion}\nAutor: ${AppConstants.author}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
