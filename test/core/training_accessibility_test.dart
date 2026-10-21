import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/app/theme.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/fitness_test.dart';
import 'package:fitbirek_training/core/widgets/primary_button.dart';
import 'package:fitbirek_training/core/widgets/test_score_chart.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

Future<void> mount(
  WidgetTester tester,
  ThemeData theme,
  Widget child, {
  bool inCard = false,
}) async {
  tester.view.physicalSize = const Size(320, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: inCard
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: child,
                    ),
                  )
                : child,
          ),
        ),
      ),
    ),
  );
}

FitnessTestResultData result(
  int day,
  double value, {
  String typ = 'maxPompki',
}) => FitnessTestResultData(
  syncId: '$typ$day',
  syncVersion: 1,
  updatedAtUtc: DateTime.utc(2026),
  id: day,
  typ: typ,
  data: DateTime(2026, 10, day),
  wynik: value,
  score: (day * 10) % 101,
);

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  for (final dark in [false, true]) {
    final theme = dark ? FitBirekTheme.dark : FitBirekTheme.light;
    test('text contrast theme dark=$dark', () {
      final style = theme.elevatedButtonTheme.style!;
      expect(
        contrast(
          style.foregroundColor!.resolve({})!,
          style.backgroundColor!.resolve({})!,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(FitBirekColors.onAccent, FitBirekColors.accent),
        greaterThanOrEqualTo(4.5),
      );
    });
    testWidgets('all selectors wrap and selected contrast dark=$dark', (
      tester,
    ) async {
      await mount(
        tester,
        theme,
        TestScoreChart(
          allResults: [
            for (final type in TypTestu.values) result(1, 12, typ: type.name),
          ],
        ),
        inCard: true,
      );
      expect(tester.takeException(), isNull);
      final label = find.text('Max pompki');
      final textContext = tester.element(label);
      final foreground = DefaultTextStyle.of(textContext).style.color!;
      final background =
          theme.chipTheme.selectedColor ?? theme.colorScheme.secondaryContainer;
      expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
      final unselectedContext = tester.element(find.text('Plank (czas)'));
      final unselectedForeground = DefaultTextStyle.of(
        unselectedContext,
      ).style.color!;
      // M3 ChoiceChip bez wyboru jest przezroczysty, chyba że motyw ustala tło.
      final cardMaterial = tester.widget<Material>(
        find
            .descendant(of: find.byType(Card), matching: find.byType(Material))
            .first,
      );
      final unselectedBackground =
          theme.chipTheme.backgroundColor ?? cardMaterial.color!;
      expect(
        contrast(unselectedForeground, unselectedBackground),
        greaterThanOrEqualTo(4.5),
      );
      final longLabel = find.text('Głęboki przysiad (mobilność)');
      expect(tester.getSize(longLabel).height, greaterThan(48));
    });
    for (final inCard in [false, true]) {
      testWidgets(
        'outlined and unselected contrast on card=$inCard dark=$dark',
        (tester) async {
          await mount(
            tester,
            theme,
            Column(
              children: [
                PrimaryButton(
                  label: 'Zapisz wynik',
                  outlined: true,
                  onPressed: () {},
                ),
                TestScoreChart(
                  allResults: [
                    result(1, 12),
                    result(1, 90, typ: 'plank'),
                  ],
                ),
              ],
            ),
            inCard: inCard,
          );
          final foreground = DefaultTextStyle.of(
            tester.element(find.text('Zapisz wynik')),
          ).style.color!;
          final background = inCard
              ? tester
                    .widget<Material>(
                      find
                          .descendant(
                            of: find.byType(Card),
                            matching: find.byType(Material),
                          )
                          .first,
                    )
                    .color!
              : theme.scaffoldBackgroundColor;
          expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
          final chipForeground = DefaultTextStyle.of(
            tester.element(find.text('Plank (czas)')),
          ).style.color!;
          expect(
            contrast(
              chipForeground,
              theme.chipTheme.backgroundColor ?? background,
            ),
            greaterThanOrEqualTo(4.5),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets('chart axis contrast on progress card dark=$dark', (
      tester,
    ) async {
      await mount(
        tester,
        theme,
        TestScoreChart(allResults: [result(1, 12), result(2, 15)]),
        inCard: true,
      );
      final background = tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(Card),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;
      for (final label in ['12', '1 października']) {
        final text = tester.widget<Text>(find.text(label).first);
        expect(
          contrast(text.style!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(tester.takeException(), isNull);
    });
    testWidgets('history pages bounded and keyboard navigable dark=$dark', (
      tester,
    ) async {
      await mount(
        tester,
        theme,
        TestScoreChart(
          allResults: [
            for (var day = 20; day > 0; day--) result(day, day.toDouble()),
          ],
        ),
        inCard: true,
      );
      final rows = find.textContaining(
        RegExp(r'^\d+\.0 powt • \d{2}\.\d{2}\.\d{4} \d{2}:\d{2}$'),
      );
      expect(rows, findsNWidgets(5));
      expect(find.textContaining('Najnowszy wynik: 20.0 powt'), findsOneWidget);
      expect(
        tester
            .widget<LineChart>(find.byType(LineChart))
            .data
            .lineBarsData
            .single
            .spots
            .length,
        20,
      );
      expect(find.text('Wyniki 16–20 z 20'), findsOneWidget);
      expect(
        tester.getTopLeft(find.textContaining('16.0 powt •')).dy,
        lessThan(tester.getTopLeft(find.textContaining('20.0 powt •').last).dy),
      );
      expect(find.bySemanticsLabel('Starsze wyniki'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // wybór testu
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // starsza strona
      for (final range in ['11–15', '6–10', '1–5']) {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Wyniki $range z 20'), findsOneWidget);
        expect(rows, findsNWidgets(5));
        expect(
          find.textContaining('Najnowszy wynik: 20.0 powt'),
          findsOneWidget,
        );
      }
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Starsze wyniki'),
            )
            .onPressed,
        isNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Wyniki 6–10 z 20'), findsOneWidget);
      expect(rows, findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'history partial page and reset on type or data change dark=$dark',
      (tester) async {
        final results = [
          for (var day = 1; day <= 7; day++) result(day, day.toDouble()),
          result(1, 90, typ: 'plank'),
        ];
        await mount(
          tester,
          theme,
          TestScoreChart(allResults: results),
          inCard: true,
        );
        await tester.tap(find.text('Starsze wyniki'));
        await tester.pumpAndSettle();
        expect(find.text('Wyniki 1–2 z 7'), findsOneWidget);
        expect(
          find.textContaining(
            RegExp(r'^\d+\.0 powt • \d{2}\.\d{2}\.\d{4} \d{2}:\d{2}$'),
          ),
          findsNWidgets(2),
        );
        await tester.tap(find.text('Plank (czas)'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Najnowszy wynik: 90.0 s'), findsOneWidget);
        expect(find.text('Starsze wyniki'), findsNothing);
        await tester.tap(find.text('Max pompki'));
        await tester.pumpAndSettle();
        expect(find.text('Wyniki 3–7 z 7'), findsOneWidget);
        await tester.tap(find.text('Starsze wyniki'));
        await tester.pumpAndSettle();
        await mount(
          tester,
          theme,
          TestScoreChart(allResults: [result(1, 12)]),
          inCard: true,
        );
        expect(
          find.textContaining('Najnowszy wynik: 12.0 powt'),
          findsOneWidget,
        );
        expect(find.text('Starsze wyniki'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    for (final outlined in [false, true]) {
      testWidgets('320px scale2 label dark=$dark outlined=$outlined', (
        tester,
      ) async {
        await mount(
          tester,
          theme,
          PrimaryButton(
            label: 'Zapisz wynik i zakończ trening',
            icon: Icons.check,
            outlined: outlined,
            onPressed: () {},
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(PrimaryButton)).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester
              .widget<Text>(find.text('Zapisz wynik i zakończ trening'))
              .textAlign,
          TextAlign.center,
        );
      });
      testWidgets('loading named disabled dark=$dark outlined=$outlined', (
        tester,
      ) async {
        await mount(
          tester,
          theme,
          PrimaryButton(
            label: 'Zapisz wynik',
            outlined: outlined,
            isLoading: true,
            onPressed: () => fail('loading action'),
          ),
        );
        expect(
          find.bySemanticsLabel('Zapisz wynik, trwa ładowanie'),
          findsOneWidget,
        );
        final node = tester.getSemantics(
          find.bySemanticsLabel('Zapisz wynik, trwa ładowanie'),
        );
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
        final spinner = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        final button = tester.widget<ButtonStyleButton>(
          find.byWidgetPredicate((w) => w is ButtonStyleButton),
        );
        final background = outlined
            ? theme.scaffoldBackgroundColor
            : button.style!.backgroundColor!.resolve({WidgetState.disabled})!;
        expect(contrast(spinner.color!, background), greaterThanOrEqualTo(3));
      });
    }
    testWidgets('first result visible and semantic dark=$dark', (tester) async {
      await mount(tester, theme, TestScoreChart(allResults: [result(1, 12)]));
      expect(find.textContaining('Najnowszy wynik: 12.0 powt'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('.*12.0 powt.*01.10.2026.*')),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'history chronological, selector keyboard accessible dark=$dark',
      (tester) async {
        await mount(
          tester,
          theme,
          TestScoreChart(
            allResults: [
              result(3, 20),
              result(1, 12),
              result(2, 90, typ: 'plank'),
            ],
          ),
        );
        expect(
          find.textContaining('Najnowszy wynik: 20.0 powt'),
          findsOneWidget,
        );
        final first = find.text('12.0 powt • 01.10.2026 00:00');
        final last = find.text('20.0 powt • 03.10.2026 00:00');
        expect(
          tester.getTopLeft(first).dy,
          lessThan(tester.getTopLeft(last).dy),
        );
        expect(
          find.bySemanticsLabel('12.0 powt • 01.10.2026 00:00'),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(find.textContaining('Najnowszy wynik: 90.0 s'), findsOneWidget);
        expect(first, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
