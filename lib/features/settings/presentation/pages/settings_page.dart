import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/constants.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/sync/sync_status_tile.dart';

/// Ekran Ustawienia: profil, motyw, dźwięk, wibracje, backup, o aplikacji.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isProcessing = false;

  Future<void> _handleExport() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isProcessing = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final bytes = await backupService.exportToBytes();
      final fileName = backupService.suggestedFileName();

      final xFile = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'application/json',
      );

      await Share.shareXFiles(
        [xFile],
        text: 'FitBirek - backup danych treningowych',
        subject: fileName,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Eksport gotowy - wybierz gdzie zapisać.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Eksport nie powiódł się: $e'),
          backgroundColor: FitBirekColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImport() async {
    final messenger = ScaffoldMessenger.of(context);

    // Krok 1: ostrzeżenie - import ZASTĘPUJE wszystkie dane.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Uwaga: import zastąpi dane'),
        content: const Text(
          'Import wczyta dane z pliku backupu i CAŁKOWICIE ZASTĄPI '
          'wszystkie obecne dane w aplikacji (profil, historia treningów, '
          'pomiary, rekordy, plany). Ta operacja jest nieodwracalna.\n\n'
          'Kontynuować?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: FitBirekColors.danger,
            ),
            child: const Text('Zastąp dane'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      // withData: true jest KRYTYCZNE na Web - tam nie ma dostępu do
      // ścieżek plików, tylko do bajtów w pamięci.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Nie udało się odczytać pliku.'),
            backgroundColor: FitBirekColors.danger,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      final backupService = ref.read(backupServiceProvider);
      final importResult = await backupService.importFromBytes(bytes);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(importResult.message),
          backgroundColor: importResult.success
              ? FitBirekColors.success
              : FitBirekColors.danger,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Import nie powiódł się: $e'),
          backgroundColor: FitBirekColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              children: [
                StreamBuilder(
                  stream: ref
                      .read(appDatabaseProvider)
                      .select(ref.read(appDatabaseProvider).syncOutbox)
                      .watch(),
                  builder: (context, snapshot) {
                    final sync = ref.watch(syncServiceProvider);
                    return SyncStatusTile(
                      status: sync.status,
                      pending: snapshot.data?.length ?? 0,
                      onRetry: sync.synchronize,
                      onLogout: () =>
                          ref.read(authStateProvider.notifier).logout(),
                    );
                  },
                ),
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
                    onChanged: (m) =>
                        m != null ? notifier.setThemeMode(m) : null,
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Powiadomienia',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.sports_martial_arts_outlined),
                  title: const Text('Przypomnienie o karate'),
                  subtitle: const Text('Wtorek i czwartek, 19:30'),
                  value: settings.notifKarate,
                  onChanged: notifier.setNotifKarate,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.fitness_center_outlined),
                  title: const Text('Przypomnienie o treningu'),
                  subtitle: const Text('Codziennie, 18:00'),
                  value: settings.notifWorkout,
                  onChanged: notifier.setNotifWorkout,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.mood_outlined),
                  title: const Text('Dziennik samopoczucia'),
                  subtitle: const Text('Codziennie, 20:30'),
                  value: settings.notifMood,
                  onChanged: notifier.setNotifMood,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Eksport danych (JSON)'),
                  subtitle: const Text(
                    'Zapisz kopię zapasową wszystkich danych',
                  ),
                  enabled: !_isProcessing,
                  onTap: _isProcessing ? null : _handleExport,
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Import danych (JSON)'),
                  subtitle: const Text(
                    'Przywróć dane z kopii zapasowej (zastąpi obecne dane)',
                  ),
                  enabled: !_isProcessing,
                  onTap: _isProcessing ? null : _handleImport,
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
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
