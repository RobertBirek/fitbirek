import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/offline/providers/offline_sync_provider.dart';

void main() {
  test(
    'authority departure and return clear aggregate without auth requests',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final changes = ValueNotifier<int>(0);
      AuthState current = const AuthState.signedIn('owner');
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(accountId: 'owner', deviceId: 'device'),
          );
      final events = StreamIterator(
        watchOfflineSync(db, () => current, authorityChanges: changes),
      );
      addTearDown(() async {
        await events.cancel();
        changes.dispose();
        await db.close();
      });
      expect(await events.moveNext(), true);
      expect(events.current.available, true);
      current = const AuthState.signedOut();
      changes.value++;
      expect(await events.moveNext(), true);
      expect(events.current.available, false);
      current = const AuthState.signedIn('other');
      changes.value++;
      expect(await events.moveNext(), true);
      expect(events.current.available, false);
      current = const AuthState.signedIn('owner');
      changes.value++;
      expect(await events.moveNext(), true);
      expect(events.current.available, true);
    },
  );
  test('passive local queue does not initialize auth or HTTP', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWith(
          (ref) => throw StateError('HTTP forbidden'),
        ),
        authStateProvider.overrideWith(
          (ref) => throw StateError('Auth forbidden'),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final summary = await container.read(offlineSyncProvider.future);
    expect(summary.available, false);
  });
  test(
    'local snapshot counts pending and deferred without marking globally ready',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(accountId: 'owner', deviceId: 'device'),
          );
      await db
          .into(db.syncOutbox)
          .insert(
            SyncOutboxCompanion.insert(
              operationId: 'op',
              entityType: 'profile',
              entityId: 'id',
              baseVersion: 0,
              payloadJson: '{}',
              deleted: const Value(false),
            ),
          );
      await db
          .into(db.syncDeferredRecords)
          .insert(
            SyncDeferredRecordsCompanion.insert(
              entityType: 'profile',
              entityId: 'id',
              version: 1,
              recordJson: '{}',
            ),
          );
      final summary = await watchOfflineSync(
        db,
        () => const AuthState.signedIn('owner'),
      ).first;
      expect(summary.pending, 1);
      expect(summary.conflicts, 1);
      expect(summary.available, true);
      final other = await watchOfflineSync(
        db,
        () => const AuthState.signedIn('other'),
      ).first;
      expect(other.available, false);
      expect(other.pending, 0);
      final signedOut = await watchOfflineSync(
        db,
        () => const AuthState.signedOut(),
      ).first;
      expect(signedOut.available, false);
      await (db.update(
        db.syncState,
      )).write(const SyncStateCompanion(offlineAccess: Value(false)));
      final locked = await watchOfflineSync(
        db,
        () => const AuthState.signedIn('owner'),
      ).first;
      expect(locked.available, false);
    },
  );
}
