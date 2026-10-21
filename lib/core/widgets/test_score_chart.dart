import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../database/app_database.dart';
import '../models/fitness_test.dart';
import '../utils/formatters.dart';
import '../utils/chart_time_axis.dart';

/// Wykres surowego wyniku testu sprawnościowego w jego jednostce,
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
          'Najnowszy wynik: ${historia.last.wynik.toStringAsFixed(1)} ${selected.jednostka} • ${Formatters.date(historia.last.data.toLocal())} ${Formatters.time(historia.last.data.toLocal())}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'Dawny protokół nie został zapisany — wyniki dotychczasowych testów.',
        ),
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
                '${wynik.wynik.toStringAsFixed(1)} ${selected.jednostka} • ${Formatters.date(wynik.data.toLocal())} ${Formatters.time(wynik.data.toLocal())}',
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
        FlSpot(axis.x(history[i].data), history[i].wynik),
    ];
    final values = history.map((r) => r.wynik).toList()..sort();
    final span = values.last - values.first;
    final padding = span > 0
        ? span * .15
        : (values.first.abs() * .15).clamp(1.0, double.infinity);
    final interval = _rawAxisInterval(
      (span + padding * 2) / 4,
      wholeNumbers: typ.jednostka == 'powt',
    );
    final minY = ((values.first - padding) / interval).floor() * interval;
    final maxY = ((values.last + padding) / interval).ceil() * interval;
    final decimals = math.max(0, -(math.log(interval) / math.ln10).floor());
    final formatter = NumberFormat(
      '0${decimals == 0 ? '' : '.${'#' * decimals}'}',
      'pl_PL',
    );
    String label(double value) =>
        formatter.format(value.abs() < interval * 1e-6 ? 0 : value);
    final axisStyle = TextStyle(fontSize: 11, color: axisColor);
    double labelWidth(double value) {
      final painter = TextPainter(
        text: TextSpan(text: label(value), style: axisStyle),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final reservedWidth = math.max(
      36.0,
      math.max(labelWidth(minY), labelWidth(maxY)) + 8,
    );

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: axis.maxX,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
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
              axisNameWidget: Text(typ.jednostka),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: reservedWidth,
                interval: interval,
                // Do not append extrema next to an almost-equal regular tick
                // (notably negative fractional ranges in fl_chart).
                minIncluded: false,
                maxIncluded: false,
                getTitlesWidget: (value, meta) =>
                    Text(label(value), style: axisStyle),
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
                  '${r.wynik.toStringAsFixed(1)} ${typ.jednostka}\n${Formatters.date(r.data.toLocal())} ${Formatters.time(r.data.toLocal())}',
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

/// Clean 1/2/5 steps keep fractional raw units distinct without displaying
/// floating-point noise. Repetition axes never suggest fractional repetitions.
double _rawAxisInterval(double approximate, {required bool wholeNumbers}) {
  final magnitude = math
      .pow(10, (math.log(approximate) / math.ln10).floor())
      .toDouble();
  final scaled = approximate / magnitude;
  final step =
      (scaled <= 1
          ? 1
          : scaled <= 2
          ? 2
          : scaled <= 5
          ? 5
          : 10) *
      magnitude;
  return wholeNumbers ? math.max(1, step) : step;
}
