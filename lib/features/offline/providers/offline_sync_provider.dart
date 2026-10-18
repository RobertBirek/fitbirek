import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../auth/providers/auth_providers.dart';

class OfflineSyncSummary {
  const OfflineSyncSummary({
    this.available = false,
    this.pending = 0,
    this.conflicts = 0,
  });
  final bool available;
  final int pending, conflicts;
}

/// Passive local read: does not construct AuthController, call getSession,
/// start SyncService or send HTTP. Only the already active account is visible.
final offlineSyncProvider = StreamProvider.autoDispose<OfflineSyncSummary>((
  ref,
) {
  final authority = ref.watch(cachedAuthWriteAuthorityProvider);
  return watchOfflineSync(
    ref.watch(appDatabaseProvider),
    () => authority.state,
    authorityChanges: authority.revision,
  );
});

Stream<OfflineSyncSummary> watchOfflineSync(
  AppDatabase db,
  AuthState? Function() currentAuth, {
  Listenable? authorityChanges,
}) => Stream.multi((sink) {
  // Keep only an aggregate for the bound account. Never expose account IDs.
  String? account;
  bool unlocked = false;
  int pending = 0, conflicts = 0;
  void emit() {
    final auth = currentAuth();
    final allowed =
        unlocked && auth?.isSignedIn == true && auth?.accountId == account;
    sink.add(
      allowed
          ? OfflineSyncSummary(
              available: true,
              pending: pending,
              conflicts: conflicts,
            )
          : const OfflineSyncSummary(),
    );
  }

  final subscription = db
      .customSelect(
        '''
    SELECT account_id, offline_access,
      (SELECT COUNT(*) FROM sync_outbox) AS pending,
      (SELECT COUNT(*) FROM sync_deferred_records) AS conflicts
    FROM sync_state WHERE id = 1
  ''',
        readsFrom: {db.syncState, db.syncOutbox, db.syncDeferredRecords},
      )
      .watch()
      .listen(
        (rows) {
          final row = rows.firstOrNull;
          account = row?.read<String>('account_id');
          unlocked = row?.read<bool>('offline_access') ?? false;
          pending = row?.read<int>('pending') ?? 0;
          conflicts = row?.read<int>('conflicts') ?? 0;
          emit();
        },
        onError: (Object error, StackTrace stack) {
          sink.add(const OfflineSyncSummary());
        },
      );
  authorityChanges?.addListener(emit);
  sink.onCancel = () async {
    authorityChanges?.removeListener(emit);
    await subscription.cancel();
  };
});
