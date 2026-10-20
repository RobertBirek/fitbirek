import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants.dart';
import '../../../../app/app_version.g.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/sync/sync_status_tile.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../offline/presentation/offline_page.dart';
import '../../providers/settings_provider.dart';
import '../widgets/settings_section.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final db = ref.watch(appDatabaseProvider);
    void logout() => ref.read(authStateProvider.notifier).logout();
    SettingsLink link(
      String title,
      IconData icon,
      String path, {
      String? subtitle,
    }) => SettingsLink(
      title: title,
      icon: icon,
      subtitle: subtitle,
      onTap: () => context.push('/settings/$path'),
    );

    final training = SettingsSection(
      title: 'Trening i profil',
      children: [
        link('Edytuj profil', Icons.person_outline, 'edit-profile'),
        link(
          'Generator planu treningowego',
          Icons.auto_awesome_outlined,
          'planner',
        ),
        link(
          'Kalkulator kalorii/makro',
          Icons.calculate_outlined,
          'calculator',
        ),
        link(
          'Mentor treningowy',
          Icons.forum_outlined,
          'mentor',
          subtitle: 'Prywatność, głos i połączenia AI',
        ),
      ],
    );
    final app = SettingsSection(
      title: 'Aplikacja',
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<ThemeMode>(
            key: ValueKey(settings.themeMode),
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Motyw'),
            initialValue: settings.themeMode,
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Ciemny')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Jasny')),
            ],
            onChanged: (mode) {
              if (mode != null) notifier.setThemeMode(mode);
            },
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
        link(
          'Powiadomienia',
          Icons.notifications_outlined,
          'notifications',
          subtitle: 'Uprawnienia, kategorie i przypomnienia',
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ustawienia',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SettingsPageLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(
              children: [
                StreamBuilder(
                  stream: db.select(db.syncOutbox).watch(),
                  builder: (context, snapshot) {
                    final sync = ref.watch(syncServiceProvider);
                    return SyncStatusTile(
                      status: sync.status,
                      pending: snapshot.data?.length ?? 0,
                      onRetry: sync.synchronize,
                      onLogout: logout,
                      showLogout: false,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: FitBirekColors.accent, width: 4),
                    ),
                  ),
                  child: link(
                    'Harmonogram aktywności',
                    Icons.event_repeat,
                    'activities',
                    subtitle: 'Dni, godziny, treningi i przypomnienia',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= 760 &&
                    MediaQuery.textScalerOf(context).scale(16) < 24;
                if (!columns) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [training, const SizedBox(height: 24), app],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: training),
                    const SizedBox(width: 24),
                    Expanded(child: app),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'Dane i integracje',
              children: [
                SettingsLink(
                  title: 'Tryb offline',
                  icon: Icons.offline_bolt_outlined,
                  subtitle: 'Sprawdź zasoby i jawnie przygotuj pakiet',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OfflinePage(),
                    ),
                  ),
                ),
                link(
                  'Kopia zapasowa i przywracanie',
                  Icons.save_outlined,
                  'backup',
                ),
                link('Apple Zdrowie', Icons.favorite_border, 'health'),
              ],
            ),
            const SizedBox(height: 24),
            const SettingsSection(children: [AppInfoTile()]),
            const SizedBox(height: 24),
            SettingsSection(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Wyloguj'),
                  subtitle: const Text(
                    'Dane pozostaną przypisane do tego konta',
                  ),
                  onTap: logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared version presentation, independent of settings and sync state.
class AppInfoTile extends StatelessWidget {
  const AppInfoTile({super.key});

  @override
  Widget build(BuildContext context) => const ListTile(
    leading: Icon(Icons.info_outline),
    title: Text('O aplikacji'),
    subtitle: Text(
      '${AppConstants.appName}\nWersja ${AppVersion.name} · build ${AppVersion.buildNumber}\nAutor: ${AppConstants.author}',
    ),
  );
}
