import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/widgets/test_score_chart.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  for (final sample in [('plank', 150.0, 210.0), ('sklon', -12.0, -4.0)]) {
    testWidgets('${sample.$1} charts raw units, not stored score', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TestScoreChart(
                allResults: [
                  for (var i = 0; i < 2; i++)
                    FitnessTestResultData(
                      id: i,
                      syncId: '$i',
                      syncVersion: 1,
                      updatedAtUtc: DateTime.utc(2026, 10, i + 1),
                      data: DateTime.utc(2026, 10, i + 1),
                      typ: sample.$1,
                      wynik: i == 0 ? sample.$2 : sample.$3,
                      score: 50,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      expect(data.lineBarsData.single.spots.map((s) => s.y), [
        sample.$2,
        sample.$3,
      ]);
      expect(data.minY, lessThan(sample.$2));
      expect(data.maxY, greaterThan(sample.$3));
      expect(
        find.textContaining('Dawny protokół nie został zapisany'),
        findsOneWidget,
      );
    });
  }
}
