import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/app/app.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/providers/notification_provider.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/health/providers/health_providers.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_providers.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/schedule/providers/activity_reminder_provider.dart';
import 'package:fitbirek_training/features/settings/presentation/pages/settings_notifications_page.dart';
import 'package:fitbirek_training/features/settings/presentation/pages/settings_backup_page.dart';
import 'package:fitbirek_training/features/settings/presentation/pages/settings_health_page.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/session_summary_page.dart';
import '../core/push_settings_test.dart' show FakePush;
import '../features/mentor/mentor_flow_test.dart' show ApiFake;
import '../features/schedule/schedule_router_start_test.dart'
    show LocalNotifications;
import '../features/settings/settings_backup_authority_test.dart'
    show BackupTestAuthRepository, BackupTestExercises, BackupTestSync;

class _SessionGate extends BackupTestAuthRepository {
  final response = Completer<AuthSession?>();
  @override
  Future<AuthSession?> getSession() => response.future;
}

UserProfile _profile({bool complete = true}) => UserProfile(
  imie: 'Test',
  wiek: 40,
  wzrostCm: 180,
  wagaKg: 80,
  cel: CelTreningowy.sila,
  dostepnySprzet: const [],
  onboardingZakonczony: complete,
  dataUtworzenia: DateTime(2026),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pl_PL');
  });

  Future<
    ({
      ProviderContainer container,
      Completer<void> database,
      _SessionGate auth,
      StreamController<UserProfile?> profile,
      List<String> navigation,
    })
  >
  mount(WidgetTester tester, String externalUri) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.defaultRouteNameTestValue = externalUri;
    addTearDown(dispatcher.clearDefaultRouteNameTestValue);
    final navigation = <String>[];
    // Flutter Web EnginePlatformDispatcher resets defaultRouteName to '/' on
    // every flutter/navigation message. VM widget tests do not do this by
    // themselves; emulate that exact engine boundary, not an imperative push.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.navigation, (call) async {
          navigation.add('${call.method}: ${call.arguments}');
          dispatcher.defaultRouteNameTestValue = '/';
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.navigation, null),
    );
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final database = Completer<void>();
    final auth = _SessionGate();
    final profile = StreamController<UserProfile?>();
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        databaseReadyProvider.overrideWith((ref) => database.future),
        authRepositoryProvider.overrideWithValue(auth),
        syncServiceProvider.overrideWith((ref) => BackupTestSync(db)),
        exercisesRepositoryProvider.overrideWithValue(BackupTestExercises(db)),
        userProfileStreamProvider.overrideWith((ref) => profile.stream),
        notificationServiceProvider.overrideWithValue(LocalNotifications()),
        pushClientProvider.overrideWithValue(FakePush()),
        activityReminderSyncProvider.overrideWith(
          (ref) => Stream.value('Test status'),
        ),
        healthAccountProvider.overrideWithValue(null),
        mentorApiProvider.overrideWithValue(ApiFake()),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await profile.close();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const FitBirekApp()),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      navigation,
      isEmpty,
      reason: 'DB gate must leave the engine initial URL untouched',
    );
    expect(dispatcher.defaultRouteName, externalUri);
    expect(c.exists(routerProvider), isFalse);
    expect(c.exists(authStateProvider), isFalse);
    return (
      container: c,
      database: database,
      auth: auth,
      profile: profile,
      navigation: navigation,
    );
  }

  for (final entry in <String, Type>{
    '/settings/notifications': SettingsNotificationsPage,
    '/settings/backup': SettingsBackupPage,
    '/settings/health': SettingsHealthPage,
    '/workout/summary/7': SessionSummaryPage,
  }.entries) {
    testWidgets(
      'external reload ${entry.key} survives DB gate, asynchronous auth and profile; nested back',
      (tester) async {
        final f = await mount(tester, entry.key);
        debugPrint(
          'Before router: external=${entry.key}; platform=${tester.binding.platformDispatcher.defaultRouteName}; navigation=${f.navigation}',
        );
        f.database.complete();
        await tester.pump();
        await tester.pump();
        final router = f.container.read(routerProvider);
        expect(f.container.read(authStateProvider).isLoading, isTrue);
        expect(router.state.uri.path, '/bootstrap');
        f.auth.response.complete(const AuthSession(accountId: 'account'));
        await tester.pump();
        await tester.pump();
        f.profile.add(_profile());
        await tester.pumpAndSettle();
        expect(router.state.uri.toString(), entry.key);
        expect(find.byType(entry.value), findsOneWidget);
        // The full production app uses Polish localizations (tooltip "Wstecz").
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(
          router.state.uri.path,
          entry.key.startsWith('/settings/') ? '/settings' : '/workout',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'external root still defaults to Today after asynchronous startup',
    (tester) async {
      final f = await mount(tester, '/');
      f.database.complete();
      await tester.pump();
      await tester.pump();
      f.auth.response.complete(const AuthSession(accountId: 'account'));
      f.profile.add(_profile());
      await tester.pumpAndSettle();
      expect(f.container.read(routerProvider).state.uri.path, '/today');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'external reload survives signed-out login and later onboarding load',
    (tester) async {
      const target = '/settings/notifications?source=reload#preferences';
      final f = await mount(tester, target);
      f.database.complete();
      await tester.pump();
      await tester.pump();
      f.auth.response.complete(null);
      await tester.pumpAndSettle();
      final router = f.container.read(routerProvider);
      expect(router.state.uri.path, '/login');
      await f.container
          .read(authStateProvider.notifier)
          .login('test', 'password');
      await tester.pump();
      await tester.pump();
      expect(router.state.uri.path, '/bootstrap');
      f.profile.add(_profile(complete: false));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/onboarding');
      f.profile.add(_profile());
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), target);
      expect(find.byType(SettingsNotificationsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
