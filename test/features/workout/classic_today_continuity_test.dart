import 'package:drift/native.dart';
import 'dart:async';
import 'package:fitbirek_training/features/workout/providers/session_recovery_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/features/health/providers/health_providers.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/home/presentation/pages/classic_today_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  testWidgets(
    'immediate click waits for delayed recovery instead of empty route',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final result = Completer<SessionRecovery>();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          healthAccountProvider.overrideWithValue(null),
          sessionRecoveryProvider.overrideWith(
            (ref) => Stream.fromFuture(result.future),
          ),
        ],
      );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ClassicTodayPage()),
          GoRoute(
            path: '/workout/session',
            builder: (_, _) => const Scaffold(body: Text('Session route')),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        c.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      expect(find.text('Session route'), findsNothing);
      expect(
        tester
            .widget<ElevatedButton>(find.byType(ElevatedButton).first)
            .onPressed,
        isNull,
      );
      result.complete(const SessionRecovery(null, 0, []));
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(find.text('Rozpocznij trening')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Session route'), findsOneWidget);
      expect(
        await tester.runAsync(() => db.select(db.workoutSessions).get()),
        hasLength(1),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
  for (final reload in [false, true]) {
    testWidgets('classic continues without creating session reload=$reload', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      var c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          healthAccountProvider.overrideWithValue(null),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      late String uuid;
      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        await c.read(activeWorkoutProvider.notifier).startSession();
        await c.read(activeWorkoutProvider.notifier).flushDraft();
        uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      });
      if (reload) {
        await tester.runAsync(() async {
          c.dispose();
          c = ProviderContainer(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              healthAccountProvider.overrideWithValue(null),
            ],
          );
        });
      }
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ClassicTodayPage()),
          GoRoute(
            path: '/workout/session',
            builder: (_, _) => const Scaffold(body: Text('Session route')),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Kontynuuj trening'), findsOneWidget);
      await tester.tap(find.text('Kontynuuj trening'));
      await tester.pumpAndSettle();
      expect(find.text('Session route'), findsOneWidget);
      await tester.runAsync(() async {
        final rows = await db.select(db.workoutSessions).get();
        expect(rows, hasLength(1));
        expect(rows.single.syncId, uuid);
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
      router.dispose();
    });
  }
}
