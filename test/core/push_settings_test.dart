import 'dart:async';

import 'package:fitbirek_training/core/push/push_client.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/core/push/push_settings_tile.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/auth/offline_auth_test.dart' show SessionApi;

class FakePush implements PushClient {
  bool enabled = false;
  bool ready = true;
  int enables = 0;
  int tests = 0;
  @override
  Future<Map<String, dynamic>> status(String accountId) async => {
    'supported': true,
    'enabled': enabled,
    'permission': 'default',
    'server': {
      'deliveryAvailable': ready,
      'publicKey': 'public',
      'reason': ready ? 'ready' : 'disabled',
    },
  };
  @override
  Future<Map<String, dynamic>> enable(
    String key,
    Map<String, bool> categories,
    String accountId,
  ) async {
    enables++;
    enabled = true;
    return status(accountId);
  }

  @override
  Future<Map<String, dynamic>> save(Map<String, bool> categories) =>
      status('account');
  @override
  Future<Map<String, dynamic>> disable() async {
    enabled = false;
    return status('account');
  }

  @override
  Future<Map<String, dynamic>> test() async {
    tests++;
    return {'queued': true};
  }

  @override
  Future<void> logout() async {
    enabled = false;
  }
}

class LogoutObservedApi extends SessionApi {
  bool loggedOut = false;

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

void main() {
  testWidgets('hung push bridge cannot hang logout', (tester) async {
    final api = LogoutObservedApi();
    final auth = AuthController(
      api,
      disablePush: () => Completer<void>().future,
    );
    await auth.bootstrap();
    var done = false;
    final logout = auth.logout().then((_) {
      done = true;
    });
    await tester.pump();
    expect(api.loggedOut, isTrue);
    await tester.pump(const Duration(seconds: 4));
    expect(done, isTrue);
    await logout;
    expect(auth.state.isSignedOut, isTrue);
    auth.dispose();
  });
  Future<void> show(WidgetTester tester, FakePush push) async {
    final auth = AuthController(SessionApi());
    await auth.bootstrap();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pushClientProvider.overrideWithValue(push),
          authStateProvider.overrideWith((ref) => auth),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PushSettingsTile()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'permission is requested only by enable button; test reports queued',
    (tester) async {
      final push = FakePush();
      await show(tester, push);
      expect(push.enables, 0);
      await tester.ensureVisible(find.text('Włącz Web Push'));
      await tester.tap(find.text('Włącz Web Push'));
      await tester.pumpAndSettle();
      expect(push.enables, 1);
      await tester.ensureVisible(find.text('Wyślij test'));
      await tester.tap(find.text('Wyślij test'));
      await tester.pumpAndSettle();
      expect(push.tests, 1);
      expect(
        find.text('Test dodany do kolejki. Sprawdź powiadomienia urządzenia.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('unconfigured sender disables optin', (tester) async {
    final push = FakePush()..ready = false;
    await show(tester, push);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Włącz Web Push'),
    );
    expect(button.onPressed, isNull);
    expect(push.enables, 0);
  });

  test('logout disables push even when server logout is offline', () async {
    final api = SessionApi();
    final push = FakePush()..enabled = true;
    final auth = AuthController(api, disablePush: push.logout);
    await auth.bootstrap();
    api.offline = true;
    await auth.logout();
    expect(push.enabled, isFalse);
    expect(auth.state.isSignedOut, isTrue);
    auth.dispose();
  });

  test(
    'slow push cleanup does not delay server logout or reopen login',
    () async {
      final api = LogoutObservedApi();
      final cleanup = Completer<void>();
      final auth = AuthController(api, disablePush: () => cleanup.future);
      await auth.bootstrap();
      final logout = auth.logout();
      await Future<void>.delayed(Duration.zero);
      expect(api.loggedOut, isTrue);
      expect(auth.state.isLoading, isTrue);
      cleanup.complete();
      await logout;
      expect(auth.state.isSignedOut, isTrue);
      auth.dispose();
    },
  );
}
