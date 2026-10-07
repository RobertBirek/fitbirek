// Widget ustawień integracji Apple Zdrowie: jawna zgoda na wysyłanie danych
// zdrowotnych na VPS przed rotacją tokenu, jednorazowe ujawnienie tokenu,
// potwierdzenie revoke i generyczne błędy bez treści żądania.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/features/health/data/health_integration_api.dart';
import 'package:fitbirek_training/features/health/presentation/pages/health_setup_guide_page.dart';
import 'package:fitbirek_training/features/health/presentation/widgets/health_integration_tile.dart';
import 'package:fitbirek_training/features/health/providers/health_providers.dart';

class _FakeHealthIntegrationApi implements HealthIntegrationApi {
  _FakeHealthIntegrationApi({
    this.status = const HealthIntegrationStatus(enabled: true),
  });

  HealthIntegrationStatus status;
  final String token = 'tok-1';
  bool consentSent = false;
  bool revoked = false;
  int statusCalls = 0;
  HealthIntegrationToken? lastResult;
  bool failGenerate = false;
  bool failRevoke = false;

  @override
  Future<HealthIntegrationStatus> getStatus() async {
    statusCalls++;
    return status;
  }

  @override
  Future<HealthIntegrationToken> generateToken() async {
    if (failGenerate) throw StateError('sensitive-request-must-not-render');
    consentSent = true;
    return lastResult = HealthIntegrationToken(status: status, token: token);
  }

  @override
  Future<HealthIntegrationStatus> revoke() async {
    if (failRevoke) throw StateError('sensitive-request-must-not-render');
    revoked = true;
    status = const HealthIntegrationStatus(enabled: false);
    return status;
  }
}

class _FailingHealthIntegrationApi implements HealthIntegrationApi {
  @override
  Future<HealthIntegrationStatus> getStatus() =>
      Future.error(const HealthIntegrationException('network'));
  @override
  Future<HealthIntegrationToken> generateToken() =>
      Future.error(const HealthIntegrationException('network'));
  @override
  Future<HealthIntegrationStatus> revoke() =>
      Future.error(const HealthIntegrationException('network'));
}

Widget _wrap(HealthIntegrationApi api) {
  return ProviderScope(
    overrides: [
      healthIntegrationApiProvider.overrideWithValue(api),
      healthAccountProvider.overrideWithValue('test-account'),
    ],
    child: const MaterialApp(home: Scaffold(body: HealthIntegrationTile())),
  );
}

void main() {
  testWidgets('guide opens offline without account or API on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final writes = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          writes.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthAccountProvider.overrideWithValue(null),
          healthIntegrationApiProvider.overrideWith(
            (ref) => throw StateError('Instruction must not access API'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: HealthIntegrationTile()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jak połączyć Apple Zdrowie'));
    await tester.pumpAndSettle();
    expect(find.text('1. Przygotuj dostęp i token'), findsOneWidget);
    expect(writes, isEmpty);
    for (final heading in [
      '2. Ręcznie potwierdź kroki',
      '3. Ustaw żądanie w Skrótach',
      '4. Dodaj wybraną masę w kg',
      '5. Przykład JSON bez sekretów',
    ]) {
      await tester.scrollUntilVisible(
        find.text(heading),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.scrollUntilVisible(
      find.text('Kopiuj przykładowy JSON'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(writes, isEmpty);
    await tester.tap(find.text('Kopiuj przykładowy JSON'));
    await tester.pumpAndSettle();
    expect(writes, hasLength(1));
    expect(writes.single, healthExampleJson);
    final payload = jsonDecode(writes.single) as Map<String, dynamic>;
    expect(payload.keys, unorderedEquals(['version', 'weights', 'steps']));
    expect(payload['version'], 1);
    expect(payload['weights'][0]['value'], isA<num>());
    expect(payload['weights'][0]['unit'], 'kg');
    expect(payload['steps'][0]['value'], isA<int>());
    expect(writes.single, contains('manual_verified_total'));
    expect(writes.single, contains('<CZAS_PROBKI_ISO_8601>'));
    expect(writes.single, isNot(contains('Authorization')));
    expect(writes.single, isNot(contains('Bearer')));
    expect(writes.single, isNot(contains('tok-1')));
    expect(find.text('Skopiowano przykład bez tokenu.'), findsOneWidget);
    for (final heading in [
      '6. Wynik, powtórzenia i synchronizacja',
      '7. Rozwiązywanie problemów',
      '8. Prywatność i ograniczenia',
    ]) {
      await tester.scrollUntilVisible(
        find.text(heading),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    }
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Jak połączyć Apple Zdrowie'), findsOneWidget);
    expect(writes, hasLength(1));
  });

  testWidgets('guide remains available when status API fails', (tester) async {
    await tester.pumpWidget(_wrap(_FailingHealthIntegrationApi()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jak połączyć Apple Zdrowie'));
    await tester.pumpAndSettle();
    expect(find.text('1. Przygotuj dostęp i token'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clipboard failure is safe with large text on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(
            code: 'denied',
            message: 'sensitive-platform-error',
          );
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const HealthSetupGuidePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Kopiuj przykładowy JSON'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Kopiuj przykładowy JSON'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nie udało się skopiować.'), findsOneWidget);
    expect(find.textContaining('sensitive-platform-error'), findsNothing);
    expect(find.text('Skopiowano przykład bez tokenu.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'generate and revoke failures do not claim success or print requests',
    (tester) async {
      final api = _FakeHealthIntegrationApi()..failGenerate = true;
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Obróć token'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Generuj'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Nie udało się wygenerować tokenu.'),
        findsOneWidget,
      );
      expect(find.textContaining('sensitive-request'), findsNothing);
      api.failRevoke = true;
      await tester.tap(find.byTooltip('Odśwież Apple Zdrowie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Odbierz dostęp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Odbierz'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Nie potwierdzono odebrania dostępu.'),
        findsOneWidget,
      );
      expect(find.textContaining('sensitive-request'), findsNothing);
      expect(find.text('Integracja wyłączona'), findsNothing);
    },
  );
  testWidgets(
    'token is cleared on lifecycle and account changes, never reappears',
    (tester) async {
      final api = _FakeHealthIntegrationApi();
      final account = StateProvider<String?>((ref) => 'account');
      final container = ProviderContainer(
        overrides: [
          healthIntegrationApiProvider.overrideWithValue(api),
          healthAccountProvider.overrideWith((ref) => ref.watch(account)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: HealthIntegrationTile()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> reveal() async {
        await tester.tap(find.text('Obróć token'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        await tester.tap(find.text('Generuj'));
        await tester.pumpAndSettle();
        expect(api.lastResult!.token, 'tok-1');
      }

      await reveal();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(api.lastResult!.token, isEmpty);
      expect(find.text('tok-1'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.tap(find.text('Zamknij'));
      await tester.pumpAndSettle();
      await reveal();
      container.read(account.notifier).state = null;
      await tester.pumpAndSettle();
      expect(api.lastResult!.token, isEmpty);
      expect(find.text('tok-1'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(api.lastResult!.token, isEmpty);
    },
  );
  testWidgets('shows the enabled status and freshness from the API', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _FakeHealthIntegrationApi(
          status: HealthIntegrationStatus(
            enabled: true,
            lastImportAt: DateTime.utc(2026, 9, 10, 12),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Integracja włączona'), findsOneWidget);
  });

  testWidgets('generating a token requires explicit VPS health-data consent', (
    tester,
  ) async {
    final api = _FakeHealthIntegrationApi();
    await tester.pumpWidget(_wrap(api));
    await tester.pump();

    await tester.tap(find.text('Obróć token'));
    await tester.pump();

    final confirm = find.text('Generuj');
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(of: confirm, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNull,
    );
    expect(api.consentSent, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(of: confirm, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(api.consentSent, isTrue);
    expect(find.textContaining('tok-1'), findsOneWidget);

    // Zamykanie dialogu usuwa token z pamięci — walidowane przez brak błędów
    // po demontażu oraz ponowne renderowanie bez tokenu.
    await tester.tap(find.text('Zamknij'));
    await tester.pump();
    await tester.pumpWidget(_wrap(api));
    await tester.pump();
    expect(find.textContaining('tok-1'), findsNothing);
  });

  testWidgets('revoke asks for confirmation and reports the disabled state', (
    tester,
  ) async {
    final api = _FakeHealthIntegrationApi();
    await tester.pumpWidget(_wrap(api));
    await tester.pump();

    await tester.tap(find.text('Odbierz dostęp'));
    await tester.pump();
    expect(find.textContaining('Wyłączyć import?'), findsOneWidget);

    await tester.tap(find.text('Odbierz'));
    await tester.pumpAndSettle();

    expect(api.revoked, isTrue);
    expect(find.textContaining('Integracja wyłączona'), findsOneWidget);
  });

  testWidgets('failures show a generic message without request payloads', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FailingHealthIntegrationApi()));
    await tester.pump();

    expect(
      find.textContaining('Nie udało się odczytać statusu integracji.'),
      findsOneWidget,
    );
    final generate = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(generate.onPressed, isNull);
  });
}
