import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../models/weight_entry.dart';
import '../utils/formatters.dart';
import '../utils/chart_time_axis.dart';

/// Wykres liniowy wagi w czasie na podstawie historii pomiarów.
///
/// Przyjmuje listę [WeightEntry] w KOLEJNOŚCI od najstarszego do
/// najnowszego (odwrotnie niż `watchAll()`, który zwraca desc - sortowanie
/// odbywa się wewnątrz widgetu, żeby wywołujący nie musiał o tym pamiętać).
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({super.key, required this.measurements});

  final List<WeightEntry> measurements;

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const _NotEnoughDataPlaceholder(
        message: 'Dodaj przynajmniej 2 pomiary, żeby zobaczyć trend wagi',
      );
    }

    // Sortuj od najstarszego do najnowszego - wykres czyta się od lewej.
    final sorted = [...measurements]..sort((a, b) => a.data.compareTo(b.data));
    final axis = ChartTimeAxis(sorted.first.data, sorted.last.data);

    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(axis.x(sorted[i].data), sorted[i].wagaKg),
    ];

    final minY = sorted.map((m) => m.wagaKg).reduce((a, b) => a < b ? a : b);
    final maxY = sorted.map((m) => m.wagaKg).reduce((a, b) => a > b ? a : b);
    // Margines 1kg powyżej/poniżej, żeby linia nie dotykała krawędzi wykresu.
    final chartMinY = (minY - 1).floorToDouble();
    final chartMaxY = (maxY + 1).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sorted.length < 2)
          const Text('Dodaj przynajmniej 2 pomiary, żeby zobaczyć trend wagi')
        else
          ExcludeSemantics(
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: axis.maxX,
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
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (axis.maxX / 4).clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              Formatters.dayMonth(axis.date(value)),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((
                        spot,
                      ) {
                        final m = sorted[spot.spotIndex];
                        return LineTooltipItem(
                          '${Formatters.weight(m.wagaKg)}\n${Formatters.date(m.data)} ${Formatters.time(m.data)}\n${m.source ?? 'Pomiar ręczny'}',
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
                      isCurved: false,
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
            ),
          ),
        const SizedBox(height: 16),
        Text('Historia wagi', style: Theme.of(context).textTheme.titleSmall),
        for (final m in sorted.reversed.take(5))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${Formatters.date(m.data)} ${Formatters.time(m.data)} • ${Formatters.weight(m.wagaKg)} • ${m.source ?? 'Pomiar ręczny'}',
            ),
          ),
        if (sorted.length > 5)
          ExpansionTile(
            title: const Text('Starsze pomiary'),
            children: [
              for (final m in sorted.reversed.skip(5))
                ListTile(
                  title: Text(
                    '${Formatters.date(m.data)} ${Formatters.time(m.data)} • ${Formatters.weight(m.wagaKg)} • ${m.source ?? 'Pomiar ręczny'}',
                  ),
                ),
            ],
          ),
      ],
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
