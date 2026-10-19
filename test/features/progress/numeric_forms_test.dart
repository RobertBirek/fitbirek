import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/progress/measurements/data/measurements_repository.dart';
import 'package:fitbirek_training/features/progress/measurements/providers/measurements_providers.dart';
import 'package:fitbirek_training/features/progress/measurements/presentation/pages/add_measurement_page.dart';
import 'package:fitbirek_training/features/progress/tests/data/tests_repository.dart';
import 'package:fitbirek_training/features/progress/tests/providers/tests_providers.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/run_test_page.dart';

class Saves {
  final calls = <Map<Symbol, dynamic>>[];
  Completer<void>? pending;
  bool fail = false;
  Future<void> save(Invocation invocation) async {
    calls.add(invocation.namedArguments);
    if (pending != null) await pending!.future;
    if (fail) throw StateError('database unavailable');
  }
}

class MeasurementsFake implements MeasurementsRepository {
  MeasurementsFake(this.saves);
  final Saves saves;
  @override
  dynamic noSuchMethod(Invocation invocation) => saves.save(invocation);
}

class TestsFake implements TestsRepository {
  TestsFake(this.saves);
  final Saves saves;
  @override
  dynamic noSuchMethod(Invocation invocation) => saves.save(invocation);
}

void main() {
  for (final measurement in [true, false]) {
    final name = measurement ? 'measurement' : 'fitness';
    Future<void> open(WidgetTester tester, Saves saves) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementsRepositoryProvider.overrideWithValue(
              MeasurementsFake(saves),
            ),
            testsRepositoryProvider.overrideWithValue(TestsFake(saves)),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => measurement
                          ? const AddMeasurementPage()
                          : const RunTestPage(),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      if (!measurement) {
        await tester.tap(find.text('Skłon w przód'));
        await tester.pumpAndSettle();
      }
    }

    Future<void> submit(WidgetTester tester) async {
      final button = find.byType(ElevatedButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }

    testWidgets('$name submits comma, trims and preserves optional empty', (
      tester,
    ) async {
      final saves = Saves();
      await open(tester, saves);
      await tester.enterText(
        find.byType(TextField).first,
        measurement ? ' 72,5 ' : ' -2,5 ',
      );
      await submit(tester);
      await tester.pumpAndSettle();
      expect(
        saves.calls.single[measurement ? #wagaKg : #wynik],
        measurement ? 72.5 : -2.5,
      );
      if (measurement) expect(saves.calls.single[#obwodKlatki], isNull);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('$name rejects invalid input inline', (tester) async {
      final saves = Saves();
      await open(tester, saves);
      for (final text in ['', 'NaN', 'Infinity', '1,2.3', 'abc']) {
        await tester.enterText(find.byType(TextField).first, text);
        await submit(tester);
        expect(saves.calls, isEmpty);
        expect(find.textContaining('Wpisz'), findsWidgets);
      }
      if (measurement) {
        await tester.enterText(find.byType(TextField).first, '72');
        await tester.enterText(find.byType(TextField).at(1), 'oops');
        await submit(tester);
        expect(saves.calls, isEmpty);
      }
    });

    testWidgets(
      '$name decimal keyboard and zero policy are wired into submit',
      (tester) async {
        final saves = Saves();
        await open(tester, saves);
        final field = tester.widget<TextField>(find.byType(TextField).first);
        expect(field.keyboardType.decimal, isTrue);
        await tester.enterText(find.byType(TextField).first, '0');
        await submit(tester);
        await tester.pumpAndSettle();
        if (measurement) {
          expect(saves.calls, isEmpty);
          expect(find.text('Wpisz wartość większą od zera.'), findsOneWidget);
        } else {
          expect(field.keyboardType.signed, isTrue);
          expect(saves.calls.single[#wynik], 0);
        }
      },
    );

    if (!measurement) {
      testWidgets('changing metric revalidates retained text before submit', (
        tester,
      ) async {
        final saves = Saves();
        await open(tester, saves);
        await tester.enterText(find.byType(TextField).first, '-2,5');
        await tester.tap(find.text('Max pompki'));
        await tester.pump();
        await submit(tester);
        expect(saves.calls, isEmpty);
        await tester.enterText(find.byType(TextField).first, '2,5');
        await submit(tester);
        expect(saves.calls, isEmpty);
        expect(find.text('Wpisz całkowitą liczbę powtórzeń.'), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, '0');
        await submit(tester);
        await tester.pumpAndSettle();
        expect(saves.calls.single[#wynik], 0);
      });
    }

    testWidgets(
      '$name delayed save blocks duplicate; failure retains input and retries',
      (tester) async {
        final saves = Saves()
          ..pending = Completer<void>()
          ..fail = true;
        await open(tester, saves);
        await tester.enterText(find.byType(TextField).first, '12.5');
        await submit(tester);
        await submit(tester);
        expect(saves.calls, hasLength(1));
        saves.pending!.complete();
        await tester.pumpAndSettle();
        expect(find.text('12.5'), findsOneWidget);
        expect(find.textContaining('Spróbuj ponownie'), findsOneWidget);
        expect(tester.takeException(), isNull);
        saves
          ..pending = null
          ..fail = false;
        await submit(tester);
        await tester.pumpAndSettle();
        expect(saves.calls, hasLength(2));
        expect(find.text('Open'), findsOneWidget);
      },
    );
  }
}
