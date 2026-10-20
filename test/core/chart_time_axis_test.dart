import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/weight_entry.dart';
import 'package:fitbirek_training/core/widgets/weight_line_chart.dart';
import 'package:fitbirek_training/core/widgets/test_score_chart.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  for (final kind in ['weight', 'score']) {
    testWidgets(
      '$kind same-day instants keep hour spacing and accessible times',
      (tester) async {
        final dates = [
          for (final hour in [8, 9, 11]) DateTime.utc(2026, 10, 1, hour),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: kind == 'weight'
                    ? WeightLineChart(
                        measurements: [
                          for (final date in dates)
                            WeightEntry(date: date, kg: 80),
                        ],
                      )
                    : TestScoreChart(
                        allResults: [
                          for (var i = 0; i < dates.length; i++)
                            FitnessTestResultData(
                              syncId: '$i',
                              syncVersion: 1,
                              updatedAtUtc: dates[i],
                              id: i,
                              typ: 'plank',
                              data: dates[i],
                              wynik: 30,
                              score: 50,
                            ),
                        ],
                      ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final chart = tester.widget<LineChart>(find.byType(LineChart)).data;
        final spots = chart.lineBarsData.single.spots;
        expect(
          (spots[2].x - spots[1].x) / (spots[1].x - spots[0].x),
          closeTo(2, 0.000001),
        );
        for (final time in ['08:00', '09:00', '11:00']) {
          expect(find.textContaining(time), findsWidgets);
        }
        final tooltip = chart.lineTouchData.touchTooltipData.getTooltipItems([
          LineBarSpot(chart.lineBarsData.single, 0, spots.last),
        ]).single!;
        expect(tooltip.text, contains('11:00'));
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '$kind uses sorted instants, not sample indices, with readable history',
      (tester) async {
        final dates = [
          DateTime.utc(2026, 10, 20),
          DateTime.utc(2026, 10, 1),
          DateTime.utc(2026, 10, 2),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: kind == 'weight'
                    ? WeightLineChart(
                        measurements: [
                          for (final date in dates)
                            WeightEntry(date: date, kg: 80),
                        ],
                      )
                    : TestScoreChart(
                        allResults: [
                          for (var i = 0; i < dates.length; i++)
                            FitnessTestResultData(
                              syncId: '$i',
                              syncVersion: 1,
                              updatedAtUtc: dates[i],
                              id: i,
                              typ: 'plank',
                              data: dates[i],
                              wynik: 30,
                              score: 50,
                            ),
                        ],
                      ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final chart = tester.widget<LineChart>(find.byType(LineChart)).data;
        final spots = chart.lineBarsData.single.spots;
        expect(
          (spots[2].x - spots[1].x) / (spots[1].x - spots[0].x),
          closeTo(18, 0.000001),
        );
        expect(find.textContaining('01.10.2026'), findsWidgets);
      },
    );
    for (final count in [1, 2, 3]) {
      testWidgets(
        '$kind $count duplicate instants have finite ranges and remain readable',
        (tester) async {
          final date = DateTime.utc(2026, 10, 1);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: kind == 'weight'
                      ? WeightLineChart(
                          measurements: [
                            for (var i = 0; i < count; i++)
                              WeightEntry(date: date, kg: 80 + i.toDouble()),
                          ],
                        )
                      : TestScoreChart(
                          allResults: [
                            for (var i = 0; i < count; i++)
                              FitnessTestResultData(
                                syncId: '$i',
                                syncVersion: 1,
                                updatedAtUtc: date,
                                id: i,
                                typ: 'plank',
                                data: date,
                                wynik: 30,
                                score: 50,
                              ),
                          ],
                        ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final chart in tester.widgetList<LineChart>(
            find.byType(LineChart),
          )) {
            expect(chart.data.minX.isFinite, isTrue);
            expect(chart.data.maxX.isFinite, isTrue);
            expect(chart.data.maxX, greaterThan(chart.data.minX));
            expect(
              chart.data.lineBarsData.single.spots.map((s) => s.x).toSet(),
              hasLength(1),
            );
          }
          expect(find.textContaining('01.10.2026'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
