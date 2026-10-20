import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/app/theme.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/providers/notification_provider.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/health/providers/health_providers.dart';
import 'package:fitbirek_training/features/home/presentation/pages/main_shell.dart';
import 'package:fitbirek_training/features/schedule/providers/activity_reminder_provider.dart';
import 'package:fitbirek_training/features/settings/presentation/pages/settings_page.dart';
import 'package:fitbirek_training/features/settings/presentation/pages/settings_backup_page.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import '../../core/push_settings_test.dart' show FakePush;
import 'settings_backup_authority_test.dart'
    show
        BackupTestAuthRepository,
        BackupTestExercises,
        BackupTestSync,
        initializeBackupTestAuth;
import '../schedule/schedule_router_start_test.dart' show LocalNotifications;
import '../mentor/mentor_flow_test.dart' show ApiFake;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pl_PL');
  });

  Future<GoRouter> mount(
    WidgetTester tester, {
    String path = '/settings',
    double width = 1280,
    double scale = 1,
    bool dark = true,
    ValueNotifier<AuthState>? gate,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sync = BackupTestSync(db);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(LocalNotifications()),
        pushClientProvider.overrideWithValue(FakePush()),
        syncServiceProvider.overrideWith((ref) => sync),
        authRepositoryProvider.overrideWithValue(BackupTestAuthRepository()),
        exercisesRepositoryProvider.overrideWithValue(BackupTestExercises(db)),
        healthAccountProvider.overrideWithValue(null),
        mentorApiProvider.overrideWithValue(ApiFake()),
        activityReminderSyncProvider.overrideWith(
          (ref) => Stream.value('Przypomnienia na najbliższe 7 dni'),
        ),
      ],
    );
    await initializeBackupTestAuth(tester, container);
    final router = createRouter(
      readAuthState: () => gate?.value ?? container.read(authStateProvider),
      refreshListenable: gate,
      readOnboardingComplete: () => true,
      initialLocation: path,
    );
    addTearDown(() async {
      router.dispose();
      container.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: dark ? FitBirekTheme.dark : FitBirekTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    if (gate?.value.isLoading == true) {
      await tester.pump();
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
    return router;
  }

  testWidgets(
    'production router: compact panel, nested details and back keep shell',
    (tester) async {
      final router = await mount(tester);
      final shell = tester.element(find.byType(MainShell));
      expect(find.text('Eksport danych (JSON)'), findsNothing);
      expect(find.text('Stan przypomnień harmonogramu'), findsNothing);
      for (final entry in {
        'Powiadomienia': 'notifications',
        'Kopia zapasowa i przywracanie': 'backup',
        'Apple Zdrowie': 'health',
      }.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/settings/${entry.value}');
        expect(tester.element(find.byType(MainShell)), same(shell));
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/settings',
        );
      }
      expect(find.text('Wyloguj'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('all existing training links retain production routes and back', (
    tester,
  ) async {
    final router = await mount(tester);
    for (final entry in {
      'Harmonogram aktywności': 'activities',
      'Edytuj profil': 'edit-profile',
      'Generator planu treningowego': 'planner',
      'Kalkulator kalorii/makro': 'calculator',
      'Mentor treningowy': 'mentor',
    }.entries) {
      await tester.ensureVisible(find.text(entry.key));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/settings/${entry.value}');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/settings');
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('footer logout uses existing account callback', (tester) async {
    final router = await mount(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsPage)),
    );
    expect(container.read(authStateProvider).isSignedIn, isTrue);
    await tester.ensureVisible(find.text('Wyloguj'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wyloguj'));
    await tester.pumpAndSettle();
    expect(container.read(authStateProvider).isSignedOut, isTrue);
    router.refresh();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/login');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  for (final width in [320.0, 375.0, 768.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [true, false]) {
        testWidgets(
          'panel $width text $scale dark $dark bounded, responsive and keyboard accessible',
          (tester) async {
            await mount(tester, width: width, scale: scale, dark: dark);
            final training = tester.getTopLeft(find.text('Trening i profil'));
            final app = tester.getTopLeft(find.text('Aplikacja'));
            if (width >= 808 && scale < 1.5) {
              expect(app.dy, training.dy);
              expect(app.dx, greaterThan(training.dx));
            } else {
              expect(app.dy, greaterThan(training.dy));
            }
            final content = find.byKey(const ValueKey('settings-content'));
            expect(tester.getSize(content).width, lessThanOrEqualTo(960));
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            expect(FocusManager.instance.primaryFocus, isNotNull);
            final retry = tester.getSize(find.byTooltip('Synchronizuj teraz'));
            expect(retry.width, greaterThanOrEqualTo(48));
            expect(retry.height, greaterThanOrEqualTo(48));
            for (final label in [
              'Harmonogram aktywności',
              'Dźwięk gongu',
              'Powiadomienia',
              'Wyloguj',
            ]) {
              final tile = find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(ListTile),
                  )
                  .first;
              expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
            }
            await tester.ensureVisible(find.text('Wyloguj'));
            expect(tester.takeException(), isNull);
            expect(find.byType(AppInfoTile), findsOneWidget);
            // Detail screens use exactly the same viewport and text constraints.
            final router = GoRouter.of(
              tester.element(find.byType(SettingsPage)),
            );
            for (final page in ['notifications', 'backup', 'health']) {
              router.go('/settings/$page');
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: page);
              expect(tester.getSize(content).width, lessThanOrEqualTo(960));
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }

  for (final path in ['notifications', 'backup', 'health']) {
    testWidgets('production auth bootstrap/login preserves $path deep link', (
      tester,
    ) async {
      final gate = ValueNotifier(const AuthState.loading());
      addTearDown(gate.dispose);
      final router = await mount(tester, path: '/settings/$path', gate: gate);
      expect(router.state.uri.path, '/bootstrap');
      gate.value = const AuthState.signedOut();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/login');
      expect(find.byType(MainShell), findsNothing);
      gate.value = const AuthState.signedIn('account-id');
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/settings/$path');
      expect(find.byType(MainShell), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/settings');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
    testWidgets('direct nested $path has settings back stack', (tester) async {
      final router = await mount(tester, path: '/settings/$path');
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/settings/$path',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/settings');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
    test('signed out $path is protected', () {
      expect(
        authRedirect(
          authState: const AuthState.signedOut(),
          onboardingComplete: true,
          location: '/settings/$path',
        ),
        '/login',
      );
    });
  }

  testWidgets(
    'backup warning preserves replacement and Apple exception; cancel does not mutate data',
    (tester) async {
      await mount(tester, path: '/settings/backup', width: 320, scale: 2);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsBackupPage)),
      );
      final db = container.read(appDatabaseProvider);
      final before = await db.syncDao.pendingOperations();
      await tester.ensureVisible(find.text('Import danych (JSON)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import danych (JSON)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('CAŁKOWICIE ZASTĄPI'), findsOneWidget);
      expect(
        find.textContaining('Apple Zdrowie pozostaje bez zmian'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Anuluj'));
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(await db.syncDao.pendingOperations(), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
