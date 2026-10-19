import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/health/providers/health_providers.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/planner_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  for (final scenario in ['empty', 'history', 'active']) {
    testWidgets(
      'actual planner route preserves workout $scenario at 320 text2',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.binding.setSurfaceSize(const Size(320, 550));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            healthAccountProvider.overrideWithValue(null),
          ],
        );
        final router = createRouter(
          readAuthState: () => const AuthState.signedIn('a'),
          readOnboardingComplete: () => true,
          initialLocation: '/workout',
        );
        addTearDown(() async {
          router.dispose();
          c.dispose();
          await db.close();
        });
        await tester.runAsync(() async {
          await db
              .into(db.syncState)
              .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
          if (scenario != 'empty') {
            final n = c.read(activeWorkoutProvider.notifier);
            await n.startSession();
            if (scenario == 'history') await n.finishSession();
            await n.flushDraft();
          }
        });
        final before = c.read(activeWorkoutProvider);
        final rows = await tester.runAsync(
          () => db.select(db.workoutSessions).get(),
        );
        final operations = await tester.runAsync(
          () => db.syncDao.pendingOperations(),
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Ułóż plan').hitTestable(), findsOneWidget);
        expect(
          find
              .text(
                scenario == 'active'
                    ? 'Wróć do aktywnej sesji'
                    : 'Nowy trening',
              )
              .hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Ułóż plan'));
        await tester.pumpAndSettle();
        expect(find.byType(PlannerPage), findsOneWidget);
        expect(
          GoRouterState.of(tester.element(find.byType(PlannerPage))).uri.path,
          '/settings/planner',
        );
        expect(c.read(activeWorkoutProvider), before);
        expect(
          await tester.runAsync(() => db.select(db.workoutSessions).get()),
          rows,
        );
        expect(
          (await tester.runAsync(() => db.syncDao.pendingOperations()))!.length,
          operations!.length,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1));
      },
    );
  }
}
