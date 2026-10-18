import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/backup_service.dart';

/// Globalny provider instancji bazy danych - jeden na całą aplikację.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// No auth, seed, sync or routed UI is started before the executor's actual
/// schema check completes. A rejected subscriber closes only its own RPC
/// channel, not the browser's shared worker. Recovery can require closing every
/// FitBirek tab/window (including the blocked page) and the installed PWA.
final databaseReadyProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  try {
    await db.customSelect('SELECT 1').get();
  } catch (_) {
    await db.close();
    rethrow;
  }
});

/// Provider serwisu backup/restore - operuje na tej samej instancji bazy.
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});
