import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../database/app_database.dart';
import '../utils/formatters.dart';

/// Wykres liniowy wagi w czasie na podstawie historii pomiarów.
///
/// Przyjmuje listę [MeasurementData] w KOLEJNOŚCI od najstarszego do
/// najnowszego (odwrotnie niż `watchAll()`, który zwraca desc - sortowanie
/// odbywa się wewnątrz widgetu, żeby wywołujący nie musiał o tym pamiętać).
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({super.key, required this.measurements});

  final List<MeasurementData> measurements;

  @override
  Widget build(BuildContext context) {
    if (measurements.length < 2) {
      return const _NotEnoughDataPlaceholder(
        message: 'Dodaj przynajmniej 2 pomiary, żeby zobaczyć trend wagi',
      );
    }

    // Sortuj od najstarszego do najnowszego - wykres czyta się od lewej.
    final sorted = [...measurements]..sort((a, b) => a.data.compareTo(b.data));

    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), sorted[i].wagaKg),
    ];

    final minY = sorted.map((m) => m.wagaKg).reduce((a, b) => a < b ? a : b);
    final maxY = sorted.map((m) => m.wagaKg).reduce((a, b) => a > b ? a : b);
    // Margines 1kg powyżej/poniżej, żeby linia nie dotykała krawędzi wykresu.
    final chartMinY = (minY - 1).floorToDouble();
    final chartMaxY = (maxY + 1).ceilToDouble();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((chartMaxY - chartMinY) / 4).clamp(
              1,
              double.infinity,
            ),
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (sorted.length / 4).clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      Formatters.dayMonth(sorted[index].data),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final m = sorted[spot.x.round()];
                return LineTooltipItem(
                  '${Formatters.weight(m.wagaKg)}\n${Formatters.date(m.data)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: FitBirekColors.accent,
              barWidth: 3,
              dotData: FlDotData(
                show: sorted.length <= 30,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: FitBirekColors.accent,
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FitBirekColors.accent.withValues(alpha: 0.25),
                    FitBirekColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotEnoughDataPlaceholder extends StatelessWidget {
  const _NotEnoughDataPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
