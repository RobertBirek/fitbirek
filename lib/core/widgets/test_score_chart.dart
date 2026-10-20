import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../database/app_database.dart';
import '../models/fitness_test.dart';
import '../utils/formatters.dart';
import '../utils/chart_time_axis.dart';

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
  static const _pageSize = 5;
  int _historyPage = 0;

  @override
  void didUpdateWidget(covariant TestScoreChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allResults != widget.allResults) _historyPage = 0;
  }

  List<TypTestu> get _typyZWynikami {
    final typyNazwy = widget.allResults.map((r) => r.typ).toSet();
    return TypTestu.values.where((t) => typyNazwy.contains(t.name)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dostepneTypy = _typyZWynikami;

    if (dostepneTypy.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Wykonaj pierwszy test sprawności, żeby zobaczyć progres',
            textAlign: TextAlign.center,
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
    // Strony liczone od najnowszych, wiersze w obrębie strony chronologicznie.
    // Wykres nadal korzysta z pełnej historii.
    final page = _historyPage.clamp(0, (historia.length - 1) ~/ _pageSize);
    final end = historia.length - page * _pageSize;
    final start = (end - _pageSize).clamp(0, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final typ in dostepneTypy)
              ChoiceChip(
                // Chip domyślnie ogranicza etykietę do jednej linii.
                label: Builder(
                  builder: (context) => DefaultTextStyle(
                    style: DefaultTextStyle.of(context).style,
                    child: Text(typ.label),
                  ),
                ),
                selected: typ == selected,
                onSelected: (_) => setState(() {
                  _selected = typ;
                  _historyPage = 0;
                }),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Najnowszy wynik: ${historia.last.wynik.toStringAsFixed(1)} ${selected.jednostka} • ${Formatters.date(historia.last.data)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (historia.length < 2)
          Text(
            'Dodaj przynajmniej 2 wyniki testu "${selected.label}",\nżeby zobaczyć trend',
          )
        else
          ExcludeSemantics(
            child: _ScoreChart(history: historia, typ: selected),
          ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text(
            'Historia wyników',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final wynik in historia.sublist(start, end))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Semantics(
              container: true,
              child: Text(
                '${wynik.wynik.toStringAsFixed(1)} ${selected.jednostka} • ${Formatters.date(wynik.data)} ${Formatters.time(wynik.data)} • score ${wynik.score}/100',
              ),
            ),
          ),
        if (historia.length > _pageSize) ...[
          Semantics(
            liveRegion: true,
            child: Text('Wyniki ${start + 1}–$end z ${historia.length}'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: start > 0
                    ? () => setState(() => _historyPage = page + 1)
                    : null,
                child: const Text(
                  'Starsze wyniki',
                  textAlign: TextAlign.center,
                ),
              ),
              OutlinedButton(
                onPressed: page > 0
                    ? () => setState(() => _historyPage = page - 1)
                    : null,
                child: const Text('Nowsze wyniki', textAlign: TextAlign.center),
              ),
            ],
          ),
        ],
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
    final axisColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final axis = ChartTimeAxis(history.first.data, history.last.data);
    final spots = <FlSpot>[
      for (var i = 0; i < history.length; i++)
        FlSpot(axis.x(history[i].data), history[i].score.toDouble()),
    ];

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: axis.maxX,
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
                  style: TextStyle(fontSize: 11, color: axisColor),
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
                      style: TextStyle(fontSize: 10, color: axisColor),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final r = history[spot.spotIndex];
                return LineTooltipItem(
                  '${r.wynik.toStringAsFixed(1)} ${typ.jednostka}\nscore ${r.score} • ${Formatters.date(r.data)} ${Formatters.time(r.data)}',
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
