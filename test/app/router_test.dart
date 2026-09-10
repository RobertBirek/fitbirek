import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:drift/native.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';

import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/features/auth/presentation/pages/login_page.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/home/presentation/pages/main_shell.dart';
import 'package:fitbirek_training/features/onboarding/presentation/pages/onboarding_flow_page.dart';

Widget routerApp(GoRouter router) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  addTearDown(router.dispose);
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  test('redirects a signed-out deep link to login', () {
    final redirect = authRedirect(
      authState: const AuthState.signedOut(),
      onboardingComplete: true,
      location: '/settings',
    );

    expect(redirect, '/login');
  });

  test('redirects signed-in users without a profile to onboarding', () {
    final redirect = authRedirect(
      authState: const AuthState.signedIn('me@example.com'),
      onboardingComplete: false,
      location: '/progress',
    );

    expect(redirect, '/onboarding');
  });

  test('preserves a signed-in deep link after onboarding', () {
    final redirect = authRedirect(
      authState: const AuthState.signedIn('me@example.com'),
      onboardingComplete: true,
      location: '/settings/edit-profile',
    );

    expect(redirect, isNull);
  });

  test('sends authentication bootstrap to its dedicated route', () {
    final redirect = authRedirect(
      authState: const AuthState.loading(),
      onboardingComplete: null,
      location: '/today',
    );

    expect(redirect, '/bootstrap');
  });

  testWidgets('refreshes one router from auth and profile changes', (
    tester,
  ) async {
    final state = _RouterState(const AuthState.signedOut(), true);
    final router = createRouter(
      readAuthState: () => state.authState,
      readOnboardingComplete: () => state.onboardingComplete,
      refreshListenable: state,
      initialLocation: '/settings',
    );

    await tester.pumpWidget(routerApp(router));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);

    state.update(const AuthState.signedIn('account-id'), false);
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlowPage), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'restores a cold-start protected deep link after session bootstrap',
    (tester) async {
      await initializeDateFormatting('pl_PL');
      final state = _RouterState(const AuthState.loading(), null);
      final router = createRouter(
        readAuthState: () => state.authState,
        readOnboardingComplete: () => state.onboardingComplete,
        refreshListenable: state,
        initialLocation: '/settings/edit-profile',
      );

      await tester.pumpWidget(routerApp(router));
      await tester.pump();
      await tester.pump();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/bootstrap');

      state.update(const AuthState.signedIn('account-id'), true);
      await tester.pump();
      await tester.pump();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/settings/edit-profile',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('restores a protected URI after signed-out login', (
    tester,
  ) async {
    await initializeDateFormatting('pl_PL');
    const target = '/settings/edit-profile?section=privacy#notifications';
    final state = _RouterState(const AuthState.loading(), null);
    final router = createRouter(
      readAuthState: () => state.authState,
      readOnboardingComplete: () => state.onboardingComplete,
      refreshListenable: state,
      initialLocation: target,
    );

    await tester.pumpWidget(routerApp(router));
    await tester.pump();
    await tester.pump();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/bootstrap');

    state.update(const AuthState.signedOut(), null);
    await tester.pump();
    await tester.pump();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');

    state.update(const AuthState.signedIn('account-id'), true);
    await tester.pump();
    await tester.pump();

    expect(router.routerDelegate.currentConfiguration.uri.toString(), target);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  test('keeps login outside the StatefulShellRoute', () {
    final router = createRouter(
      readAuthState: () => const AuthState.signedOut(),
      readOnboardingComplete: () => true,
    );

    expect(
      router.configuration.routes.whereType<GoRoute>().map(
        (route) => route.path,
      ),
      contains('/login'),
    );
    expect(
      router.configuration.routes.whereType<StatefulShellRoute>(),
      hasLength(1),
    );
  });
}

class _RouterState extends ChangeNotifier {
  _RouterState(this.authState, this.onboardingComplete);

  AuthState authState;
  bool? onboardingComplete;

  void update(AuthState nextAuthState, bool? nextOnboardingComplete) {
    authState = nextAuthState;
    onboardingComplete = nextOnboardingComplete;
    notifyListeners();
  }
}
