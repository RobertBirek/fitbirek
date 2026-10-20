import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/providers/auth_providers.dart';
import '../widgets/settings_section.dart';

/// Eksport i jawne, destrukcyjne przywracanie kopii danych.
class SettingsBackupPage extends ConsumerStatefulWidget {
  const SettingsBackupPage({super.key});

  @override
  ConsumerState<SettingsBackupPage> createState() => _SettingsBackupPageState();
}

class _SettingsBackupPageState extends ConsumerState<SettingsBackupPage> {
  bool _isProcessing = false;
  int _operation = 0;
  late final CachedAuthWriteAuthority _authority;

  @override
  void initState() {
    super.initState();
    _authority = ref.read(cachedAuthWriteAuthorityProvider);
    _authority.revision.addListener(_invalidateOperation);
  }

  void _invalidateOperation() {
    _operation++;
    if (mounted && _isProcessing) setState(() => _isProcessing = false);
  }

  @override
  void dispose() {
    _operation++;
    _authority.revision.removeListener(_invalidateOperation);
    super.dispose();
  }

  _BackupOperation _beginOperation() {
    final operation = ++_operation;
    final route = ModalRoute.of(context);
    return _BackupOperation(
      ref.read(appDatabaseProvider),
      _authority,
      // A popped route can remain mounted during its reverse animation.
      () => mounted && (route?.isCurrent ?? true) && operation == _operation,
    );
  }

  Future<void> _handleExport() async {
    final operation = _beginOperation();
    final backupService = ref.read(backupServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isProcessing = true);

    try {
      if (!await operation.captureBinding()) return;
      final bytes = await backupService.exportToBytes();
      // No private bytes cross the plugin boundary after back, logout or ABA.
      if (!await operation.isAuthorized()) return;
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

      if (!await operation.isAuthorized()) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Eksport gotowy - wybierz gdzie zapisać.'),
        ),
      );
    } catch (e) {
      if (!await operation.isAuthorized()) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Eksport nie powiódł się: $e'),
          backgroundColor: FitBirekColors.danger,
        ),
      );
    } finally {
      if (operation.isCurrent) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleImport() async {
    final operation = _beginOperation();
    final backupService = ref.read(backupServiceProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (!await operation.captureBinding()) return;
      if (!mounted) return;
      // Krok 1: ostrzeżenie - import ZASTĘPUJE wszystkie dane.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: const Text('Uwaga: import zastąpi dane'),
          content: const Text(
            'Import wczyta dane z pliku backupu i CAŁKOWICIE ZASTĄPI '
            'wszystkie obecne dane w aplikacji (profil, historia treningów, '
            'pomiary, rekordy, plany). Ta operacja jest nieodwracalna.\n\n'
            'Apple Zdrowie pozostaje bez zmian: próbki z kopii nie są '
            'odtwarzane, importów ani oczekujących usunięć nie kasujemy. '
            'Na nowym urządzeniu importy pobierze synchronizacja bieżącego konta.\n\n'
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
      if (!await operation.isAuthorized()) return;
      setState(() => _isProcessing = true);

      // withData: true jest KRYTYCZNE na Web - tam nie ma dostępu do
      // ścieżek plików, tylko do bajtów w pamięci.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (!await operation.isAuthorized()) return;

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Nie udało się odczytać pliku.'),
            backgroundColor: FitBirekColors.danger,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Keep the service's atomic restore intact; an outer transaction rolls
      // it back if this page/account is invalidated while restore is awaiting.
      final importResult = await operation.db.transaction(() async {
        if (!await operation.isAuthorized()) throw const _BackupCancelled();
        final result = await backupService.importFromBytes(bytes);
        if (!await operation.isAuthorized()) throw const _BackupCancelled();
        return result;
      });

      if (!await operation.isAuthorized()) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(importResult.message),
          backgroundColor: importResult.success
              ? FitBirekColors.success
              : FitBirekColors.danger,
          duration: const Duration(seconds: 5),
        ),
      );
    } on _BackupCancelled {
      // Deliberate rollback: never display a previous account's result.
    } catch (e) {
      if (!await operation.isAuthorized()) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Import nie powiódł się: $e'),
          backgroundColor: FitBirekColors.danger,
        ),
      );
    } finally {
      if (operation.isCurrent) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kopia zapasowa i przywracanie')),
      body: SafeArea(
        child: Stack(
          children: [
            SettingsPageLayout(
              child: Column(
                children: [
                  SettingsSection(
                    title: 'Zapisz kopię',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.upload_file_outlined),
                        title: const Text('Eksport danych (JSON)'),
                        subtitle: const Text(
                          'Zapisz kopię zapasową wszystkich danych',
                        ),
                        enabled: !_isProcessing,
                        onTap: _isProcessing ? null : _handleExport,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SettingsSection(
                    title: 'Przywróć dane',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.download_outlined),
                        title: const Text('Import danych (JSON)'),
                        subtitle: const Text(
                          'Przywróć dane z kopii zapasowej (zastąpi obecne dane)',
                        ),
                        enabled: !_isProcessing,
                        onTap: _isProcessing ? null : _handleImport,
                      ),
                    ],
                  ),
                ],
              ),
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

/// Captured synchronously, without bootstrapping auth or HTTP. The durable
/// deviceId is a revocation generation and also protects against other tabs.
class _BackupOperation {
  _BackupOperation(this.db, this.authority, this.isAlive)
    : epoch = authority.epoch,
      account = authority.state?.accountId;

  final AppDatabase db;
  final CachedAuthWriteAuthority authority;
  final bool Function() isAlive;
  final int epoch;
  final String? account;
  String? _bindingId;

  bool get isCurrent =>
      isAlive() &&
      authority.epoch == epoch &&
      authority.state?.isSignedIn == true &&
      account != null &&
      authority.state?.accountId == account;

  Future<bool> captureBinding() async {
    if (!isCurrent) return false;
    try {
      final binding = await db.syncDao.readState();
      if (!isCurrent ||
          binding?.accountId != account ||
          binding?.offlineAccess != true) {
        return false;
      }
      _bindingId = binding!.deviceId;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isAuthorized() async {
    if (!isCurrent || _bindingId == null) return false;
    try {
      final binding = await db.syncDao.readState();
      return isCurrent &&
          binding?.accountId == account &&
          binding?.offlineAccess == true &&
          binding?.deviceId == _bindingId;
    } catch (_) {
      return false;
    }
  }
}

class _BackupCancelled implements Exception {
  const _BackupCancelled();
}
