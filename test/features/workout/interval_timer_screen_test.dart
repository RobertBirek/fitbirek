import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/interval_timer_screen.dart';

void main() {
  testWidgets(
    'optional system cues only for foreground transitions, visual fallback remains',
    (tester) async {
      var now = Duration.zero;
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
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
          home: IntervalTimerScreen(label: 'Test', clock: () => now),
        ),
      );
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text('Rozpocznij interwały'));
      await tester.pump();
      now = const Duration(seconds: 5);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Praca'), findsOneWidget);
      expect(
        calls,
        containsAll(['SystemSound.play', 'HapticFeedback.vibrate']),
      );
      await tester.tap(find.text('Pauza'));
      await tester.pump();
      final count = calls.length;
      now = const Duration(hours: 2);
      await tester.pump(const Duration(minutes: 1));
      expect(calls, hasLength(count));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
      expect(calls, hasLength(count));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'background long jump reconciles on resume, no automatic save; back confirms discard',
    (tester) async {
      var now = Duration.zero;
      var returned = false;
      List<IntervalRound>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<List<IntervalRound>>(
                  MaterialPageRoute(
                    builder: (_) =>
                        IntervalTimerScreen(label: 'Test', clock: () => now),
                  ),
                );
                returned = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rozpocznij interwały'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = const Duration(hours: 1);
      await tester.pump(const Duration(hours: 1));
      expect(find.text('Przygotowanie'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Zakończenie'), findsOneWidget);
      expect(returned, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Anulować interwały?'), findsOneWidget);
      await tester.tap(find.text('Wróć'));
      await tester.pumpAndSettle();
      expect(returned, isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Odrzuć'));
      await tester.pumpAndSettle();
      expect(returned, isTrue);
      expect(result, isNull);
      await tester.pump(const Duration(minutes: 1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'pause/resume, review actual shortened work; only explicit save returns once',
    (tester) async {
      var now = Duration.zero;
      List<IntervalRound>? result;
      var returns = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<List<IntervalRound>>(
                  MaterialPageRoute(
                    builder: (_) =>
                        IntervalTimerScreen(label: 'Test', clock: () => now),
                  ),
                );
                returns++;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('preparation')), '0');
      await tester.enterText(find.byKey(const Key('work')), '10');
      await tester.enterText(find.byKey(const Key('rest')), '0');
      await tester.enterText(find.byKey(const Key('rounds')), '2');
      await tester.tap(find.text('Rozpocznij interwały'));
      await tester.pump();
      now = const Duration(seconds: 3);
      await tester.tap(find.text('Pauza'));
      await tester.pump();
      now = const Duration(hours: 1);
      await tester.pump(const Duration(seconds: 20));
      expect(find.text('7 s'), findsOneWidget);
      expect(result, isNull);
      await tester.tap(find.text('Wznów'));
      await tester.pump();
      await tester.tap(find.text('Zakończ odliczanie'));
      await tester.pump();
      expect(find.textContaining('3 s • skrócona'), findsOneWidget);
      expect(returns, 0);
      await tester.tap(find.text('Zapisz wykonane rundy'));
      await tester.tap(find.text('Zapisz wykonane rundy'));
      await tester.pumpAndSettle();
      expect(result!.single.seconds, 3);
      expect(returns, 1);
    },
  );
  testWidgets(
    'invalid configuration and invalidated origin never return results',
    (tester) async {
      var valid = true;
      List<IntervalRound>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<List<IntervalRound>>(
                  MaterialPageRoute(
                    builder: (_) => IntervalTimerScreen(
                      label: 'Test',
                      isValid: () => valid,
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('work')), '0');
      await tester.tap(find.text('Rozpocznij interwały'));
      await tester.pump();
      expect(find.textContaining('Praca: 1–3600'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('work')), '1');
      await tester.tap(find.text('Rozpocznij interwały'));
      await tester.pump();
      valid = false;
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.textContaining('Sesja lub konto uległy zmianie'),
        findsOneWidget,
      );
      expect(find.text('Zapisz wykonane rundy'), findsNothing);
      expect(result, isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 1));
      expect(tester.takeException(), isNull);
    },
  );
}
