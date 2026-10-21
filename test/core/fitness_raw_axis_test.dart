import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/widgets/test_score_chart.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  for (final sample in [
    ('plank', 12.1, 12.3, 's'),
    ('sklon', -12.3, -12.1, 'cm'),
    ('cooper12min', 12.1, 12.3, 'm'),
    ('maxPompki', 999999999.0, 1000000000.0, 'powt'),
  ]) {
    testWidgets(
      'raw ${sample.$1} axis distinguishes adjacent ticks without changing values or score',
      (tester) async {
        final rows = [
          for (var i = 0; i < 2; i++)
            FitnessTestResultData(
              id: i,
              syncId: '$i',
              syncVersion: 1,
              updatedAtUtc: DateTime.utc(2026),
              data: DateTime.utc(2026, 1, i + 1),
              typ: sample.$1,
              wynik: i == 0 ? sample.$2 : sample.$3,
              score: 50,
            ),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TestScoreChart(allResults: rows),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final chart = tester.widget<LineChart>(find.byType(LineChart)).data;
        final axis = chart.titlesData.leftTitles;
        expect((axis.axisNameWidget! as Text).data, sample.$4);
        if (sample.$4 == 'powt') {
          expect(axis.sideTitles.interval, greaterThanOrEqualTo(1));
        }
        final labels = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .where((s) => RegExp(r'^-?\d+(?:[,.]\d+)?$').hasMatch(s))
            .toList();
        expect(labels.length, greaterThanOrEqualTo(2));
        expect(
          labels.toSet(),
          hasLength(labels.length),
          reason:
              'Different raw axis positions must not share a rounded label: $labels',
        );
        if (sample.$4 == 'powt') {
          expect(labels.every((s) => !s.contains(RegExp(r'[,.]'))), isTrue);
        } else {
          expect(labels.any((s) => s.contains(RegExp(r'[,.]'))), isTrue);
        }
        expect(chart.lineBarsData.single.spots.map((s) => s.y), [
          sample.$2,
          sample.$3,
        ]);
        expect(rows.map((r) => r.score), [50, 50]);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [320.0, 430.0, 960.0]) {
    testWidgets('large raw repetition labels fit $width at 200 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TestScoreChart(
                      allResults: [
                        for (var i = 0; i < 2; i++)
                          FitnessTestResultData(
                            id: i,
                            syncId: '$i',
                            syncVersion: 1,
                            updatedAtUtc: DateTime.utc(2026),
                            data: DateTime.utc(2026, 1, i + 1),
                            typ: 'maxPompki',
                            wynik: 999999999.0 + i,
                            score: 50,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('999999999'), findsOneWidget);
      expect(find.text('1000000000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
