import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../database/app_database.dart';
import '../models/fitness_test.dart';
import '../utils/formatters.dart';

/// Wykres liniowy wyniku (score 0-100) testu sprawnościowego w czasie,
/// z możliwością przełączania typu testu przez ChoiceChip.
///
/// Buduje listę typów testów, które mają przynajmniej 1 zapisany wynik, na
/// podstawie [allResults] - nie zakłada z góry, które testy user wykonywał.
class TestScoreChart extends StatefulWidget {
  const TestScoreChart({super.key, required this.allResults});

  final List<FitnessTestResultData> allResults;

  @override
  State<TestScoreChart> createState() => _TestScoreChartState();
}

class _TestScoreChartState extends State<TestScoreChart> {
  TypTestu? _selected;

  List<TypTestu> get _typyZWynikami {
    final typyNazwy = widget.allResults.map((r) => r.typ).toSet();
    return TypTestu.values.where((t) => typyNazwy.contains(t.name)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dostepneTypy = _typyZWynikami;

    if (dostepneTypy.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Wykonaj pierwszy test sprawności, żeby zobaczyć progres',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Domyślnie wybierz pierwszy dostępny typ (lub zachowaj wybór jeśli
    // wciąż jest dostępny po odświeżeniu danych).
    final selected = (_selected != null && dostepneTypy.contains(_selected))
        ? _selected!
        : dostepneTypy.first;

    final historia =
        widget.allResults.where((r) => r.typ == selected.name).toList()
          ..sort((a, b) => a.data.compareTo(b.data));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dostepneTypy.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final typ = dostepneTypy[i];
              return ChoiceChip(
                label: Text(typ.label),
                selected: typ == selected,
                onSelected: (_) => setState(() => _selected = typ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (historia.length < 2)
          SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Dodaj przynajmniej 2 wyniki testu "${selected.label}",\nżeby zobaczyć trend',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          _ScoreChart(history: historia, typ: selected),
      ],
    );
  }
}

class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.history, required this.typ});

  final List<FitnessTestResultData> history;
  final TypTestu typ;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < history.length; i++)
        FlSpot(i.toDouble(), history[i].score.toDouble()),
    ];

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
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
                reservedSize: 36,
                interval: 25,
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
                interval: (history.length / 4).clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= history.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      Formatters.dayMonth(history[index].data),
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
                final r = history[spot.x.round()];
                return LineTooltipItem(
                  '${r.wynik.toStringAsFixed(1)} ${typ.jednostka}\nscore ${r.score} • ${Formatters.date(r.data)}',
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
              color: FitBirekColors.success,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: FitBirekColors.success,
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FitBirekColors.success.withValues(alpha: 0.25),
                    FitBirekColors.success.withValues(alpha: 0.0),
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
