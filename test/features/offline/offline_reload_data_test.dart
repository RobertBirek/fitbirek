import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/offline/presentation/offline_page.dart';
import 'package:fitbirek_training/features/offline/providers/offline_controller.dart';
import 'package:fitbirek_training/features/offline/providers/offline_sync_provider.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';

import 'offline_test.dart' show FakeBridge, reloadPacket;

class PassiveAuthority extends CachedAuthWriteAuthority {
  AuthState? current = const AuthState.signedIn('owner');
  @override
  AuthState? get state => current;
  @override
  int get epoch => revision.value;
}

// Compare all column values, including exact JSON UTF-8 bytes, not decoded
// payload equivalence or just counts. These are real native SQLite rows.
Future<List<int>> storedBytes(AppDatabase db) async {
  final result = <String, Object?>{};
  for (final table in [
    'workout_sessions',
    'workout_drafts',
    'sync_outbox',
    'sync_deferred_records',
    'sync_state',
  ]) {
    result[table] =
        (await db.customSelect('SELECT * FROM $table ORDER BY 1, 2').get())
            .map((row) => row.data)
            .toList();
  }
  return utf8.encode(jsonEncode(result));
}

void main() {
  for (final access in ['owner', 'unavailable', 'other']) {
    testWidgets(
      'reload panel and passive refresh preserve active draft and attempted outbox bytes: $access',
      (tester) async {
        // Keep SQLite subscriptions and their deferred shutdown timers in the
        // same real async zone; only viewport pumping uses the widget clock.
        await tester.runAsync(() async {
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          final authority = PassiveAuthority();
          final bridge = FakeBridge()..value = reloadPacket(withSize: true);
          final container = ProviderContainer(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
              offlineBridgeProvider.overrideWithValue(bridge),
              authStateProvider.overrideWith(
                (ref) => throw StateError('Auth forbidden'),
              ),
              apiClientProvider.overrideWith(
                (ref) => throw StateError('HTTP forbidden'),
              ),
            ],
          );
          addTearDown(() async {
            await tester.runAsync(() async {
              container.dispose();
              authority.revision.dispose();
              await db.close();
            });
          });
          late List<int> before;
          await db
              .into(db.syncState)
              .insert(
                SyncStateCompanion.insert(
                  accountId: 'owner',
                  deviceId: 'device',
                ),
              );
          final workout = container.read(activeWorkoutProvider.notifier);
          await workout.startSession();
          workout.updateDraft({'seconds': '17', 'rpe': 7});
          await workout.flushDraft();
          expect(container.read(activeWorkoutProvider).isActive, true);
          expect(
            (await db.select(db.workoutDrafts).getSingle()).payloadJson,
            contains('"seconds":"17"'),
          );
          // Session start enqueues one operation; keep two additional pending
          // records, including a previously attempted, byte-sensitive payload.
          expect(await db.select(db.syncOutbox).get(), hasLength(1));
          for (final i in [1, 2]) {
            await db
                .into(db.syncOutbox)
                .insert(
                  SyncOutboxCompanion.insert(
                    operationId: 'pending-$i',
                    entityType: 'profile',
                    entityId: 'profile-$i',
                    baseVersion: 4,
                    payloadJson: '{ "note" : "próba $i", "value": 1.00 }',
                    attempted: Value(i == 1),
                  ),
                );
          }
          await db
              .into(db.syncDeferredRecords)
              .insert(
                SyncDeferredRecordsCompanion.insert(
                  entityType: 'profile',
                  entityId: 'profile-1',
                  version: 5,
                  recordJson: '{ "value": 2 }',
                ),
              );
          if (access != 'owner') {
            authority.current = access == 'other'
                ? const AuthState.signedIn('other')
                : null;
            authority.revision.value++;
          }
          before = await storedBytes(db);
          final activeState = container.read(activeWorkoutProvider);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(home: OfflinePage()),
            ),
          );
          await container.read(offlineSyncProvider.future);
          await tester.pumpAndSettle();
          expect(
            find.text('Aktualizacja aplikacji — wymagane odświeżenie'),
            findsOneWidget,
          );
          expect(await storedBytes(db), before);
          await tester.ensureVisible(find.text('Sprawdź ponownie'));
          await tester.tap(find.text('Sprawdź ponownie'));
          await tester.pumpAndSettle();
          expect(bridge.statuses, 2);
          expect(bridge.prepares, 0);
          expect(bridge.cancels, 0);
          await tester.ensureVisible(
            find.text('Dane treningowe i synchronizacja'),
          );
          await tester.pumpAndSettle();
          if (access == 'owner') {
            expect(find.textContaining('3 zmian.'), findsOneWidget);
            expect(find.textContaining('sprawdzenia: 1.'), findsOneWidget);
            expect(container.read(activeWorkoutProvider), same(activeState));
            expect(container.read(activeWorkoutProvider).isActive, true);
          } else {
            expect(
              find.textContaining('Stan danych konta nie jest dostępny'),
              findsOneWidget,
            );
            expect(find.textContaining('3 zmian.'), findsNothing);
            expect(find.textContaining('sprawdzenia: 1.'), findsNothing);
            expect(
              find.textContaining('Lokalna kolejka jest pusta'),
              findsNothing,
            );
            expect(find.textContaining('0 zmian'), findsNothing);
          }
          expect(await storedBytes(db), before);
          final pending = await db.select(db.syncOutbox).get();
          expect(pending, hasLength(3));
          expect(pending.where((row) => row.attempted), hasLength(1));
          expect(await db.select(db.workoutDrafts).get(), hasLength(1));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      },
    );
  }
}
