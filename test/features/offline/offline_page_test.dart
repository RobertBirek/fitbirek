import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/offline/presentation/offline_page.dart';
import 'package:fitbirek_training/features/offline/providers/offline_controller.dart';
import 'package:fitbirek_training/features/offline/providers/offline_sync_provider.dart';

import 'offline_test.dart' show FakeBridge, packet;

void main() {
  Future<void> open(
    WidgetTester tester,
    FakeBridge bridge, {
    int pending = 0,
    int conflicts = 0,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineBridgeProvider.overrideWithValue(bridge),
          offlineSyncProvider.overrideWith(
            (ref) => Stream.value(
              OfflineSyncSummary(
                available: true,
                pending: pending,
                conflicts: conflicts,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: OfflinePage()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'A confirmation rejected for B shows new size but requires status and new consent',
    (tester) async {
      final packageB = {
        ...packet('notReady'),
        'packageId': 'pack-b',
        'totalBytes': 4194304,
        'totalFiles': 3,
      };
      final bridge = FakeBridge();
      await open(tester, bridge);
      await tester.tap(find.text('Przygotuj do pracy offline'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('2097152 bajtów'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('2 plików'),
        ),
        findsOneWidget,
      );
      bridge.value = packageB;
      bridge.prepareResult = {
        ...packageB,
        'state': 'error',
        'errorCode': 'packageChanged',
      };
      await tester.tap(find.text('Pobierz cały pakiet'));
      await tester.pumpAndSettle();
      expect(bridge.preparedPackageIds, ['pack-a']);
      expect(find.textContaining('Pakiet zmienił się'), findsOneWidget);
      expect(
        find.textContaining('4.00 MiB (4194304 bajtów) · 3 plików'),
        findsOneWidget,
      );
      expect(find.text('Ponów pobieranie'), findsNothing);
      expect(find.text('Przygotuj do pracy offline'), findsNothing);
      await tester.pump(const Duration(seconds: 10));
      expect(bridge.prepares, 1);
      expect(bridge.statuses, 1);
      await tester.tap(find.text('Sprawdź ponownie'));
      await tester.pumpAndSettle();
      expect(bridge.statuses, 2);
      expect(bridge.prepares, 1);
      await tester.tap(find.text('Przygotuj do pracy offline'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('4.00 MiB (4194304 bajtów)'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('3 plików'),
        ),
        findsOneWidget,
      );
      expect(bridge.prepares, 1);
      bridge.prepareResult = {...packageB, 'state': 'downloading'};
      await tester.tap(find.text('Pobierz cały pakiet'));
      await tester.pump();
      await tester.pump();
      expect(bridge.preparedPackageIds, ['pack-a', 'pack-b']);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'checking polls verified progress then ready, never auto prepares',
    (tester) async {
      final bridge = FakeBridge()..value = packet('checking');
      await open(tester, bridge);
      expect(find.text('Sprawdzanie zasobów…'), findsOneWidget);
      bridge.value = packet('downloading', cached: 1);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.textContaining('1/2 plików'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.5,
      );
      bridge.value = packet('ready', cached: 2);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('Zasoby gotowe offline'), findsOneWidget);
      expect(bridge.prepares, 0);
      final count = bridge.statuses;
      await tester.pump(const Duration(seconds: 10));
      expect(bridge.statuses, count);
    },
  );

  testWidgets(
    'resume hides old ready until fresh verification and revokes lost cache',
    (tester) async {
      final bridge = FakeBridge()..value = packet('ready', cached: 2);
      await open(tester, bridge);
      expect(find.text('Zasoby gotowe offline'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final late = Completer<Object?>();
      bridge.read = () => late.future;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Zasoby gotowe offline'), findsNothing);
      expect(find.text('Weryfikacja zasobów…'), findsOneWidget);
      late.complete(packet('notReady'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Zasoby nie są jeszcze gotowe offline'), findsOneWidget);
      expect(bridge.prepares, 0);
    },
  );

  testWidgets(
    'open is status only; entire pack size confirmation can be cancelled',
    (tester) async {
      final bridge = FakeBridge();
      await open(tester, bridge);
      expect(bridge.statuses, 1);
      expect(bridge.prepares, 0);
      expect(find.textContaining('2.00 MiB'), findsOneWidget);
      await tester.tap(find.text('Przygotuj do pracy offline'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ilustracjami'), findsOneWidget);
      expect(bridge.prepares, 0);
      await tester.tap(find.text('Nie teraz'));
      await tester.pumpAndSettle();
      expect(bridge.prepares, 0);
      await tester.tap(find.text('Przygotuj do pracy offline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pobierz cały pakiet'));
      await tester.pump();
      await tester.pump();
      expect(bridge.prepares, 1);
      expect(find.text('Anuluj pobieranie'), findsOneWidget);
      await tester.tap(find.text('Anuluj pobieranie'));
      await tester.pump();
      await tester.pump();
      expect(bridge.cancels, 1);
      expect(find.text('Pobieranie anulowane'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'ready resources never claim synced data when outbox/conflict exists',
    (tester) async {
      await open(
        tester,
        FakeBridge()..value = packet('ready', cached: 2),
        pending: 3,
        conflicts: 1,
      );
      expect(find.text('Zasoby gotowe offline'), findsOneWidget);
      expect(find.textContaining('Dane treningowe czekają'), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets);
      expect(find.textContaining('Konflikty'), findsOneWidget);
    },
  );

  for (final code in ['quota', 'network', 'integrity', 'timeout', 'protocol']) {
    testWidgets('error $code gives explanation and check again', (
      tester,
    ) async {
      await open(
        tester,
        FakeBridge()..value = {...packet('error'), 'errorCode': code},
      );
      expect(find.text('Nie udało się przygotować zasobów'), findsOneWidget);
      expect(find.text('Sprawdź ponownie'), findsOneWidget);
      expect(find.text('Ponów pobieranie'), findsOneWidget);
    });
  }
  testWidgets('unknown size never enables download or shows 100%', (
    tester,
  ) async {
    await open(
      tester,
      FakeBridge()
        ..value = {
          ...packet('notReady'),
          'packageId': null,
          'totalBytes': 0,
          'totalFiles': 0,
        },
    );
    expect(find.text('Przygotuj do pracy offline'), findsNothing);
    expect(find.textContaining('100%'), findsNothing);
    expect(
      find.textContaining('Rozmiar pakietu nie jest jeszcze znany'),
      findsOneWidget,
    );
  });
  testWidgets('unsupported is not presented as PWA ready', (tester) async {
    await open(tester, FakeBridge()..value = packet('unsupported'));
    expect(find.textContaining('nie obsługuje'), findsOneWidget);
    expect(find.text('Przygotuj do pracy offline'), findsNothing);
  });
}
