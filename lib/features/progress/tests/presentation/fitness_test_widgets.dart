import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../exercises/presentation/exercise_illustrations.dart';
import '../domain/fitness_protocol.dart';
import '../providers/tests_providers.dart';

String fitnessNumber(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
String fitnessDate(DateTime value) =>
    '${Formatters.date(value.toLocal())} ${Formatters.time(value.toLocal())}';
String fitnessMetricLabel(FitnessMetric metric) => switch (metric) {
  FitnessMetric.reps => 'Powtórzenia · powt.',
  FitnessMetric.time => 'Czas · s',
  FitnessMetric.distance => 'Dystans · m',
};
String fitnessConditions(FitnessProtocol p) => [
  p.direction == FitnessDirection.higher ? 'Więcej = lepiej' : 'Mniej = lepiej',
  if (p.loadKg != null)
    '${fitnessNumber(p.loadKg!)} kg ${p.loadBasis == FitnessLoadBasis.total ? 'łącznie' : 'na przyrząd'}',
  switch (p.side) {
    FitnessSide.left => 'Lewa strona',
    FitnessSide.right => 'Prawa strona',
    FitnessSide.both => 'Obie strony',
    null => 'Strona nieokreślona',
  },
  if (p.timeLimitSeconds != null) 'Limit ${p.timeLimitSeconds} s',
  if (p.variantSnapshot != null) 'Wariant: ${p.variantSnapshot!['name']}',
].join(' • ');

AppBar fitnessAppBar(BuildContext context, String title) => AppBar(
  title: Text(title),
  leading: IconButton(
    tooltip: 'Wróć do testów',
    onPressed: () => context.canPop()
        ? context.pop()
        : context.go('/progress?section=tests'),
    icon: const Icon(Icons.arrow_back),
  ),
);

const fitnessUnavailable =
    'Testy są teraz niedostępne. Odblokuj dostęp do konta lub otwórz ekran ponownie. Nie zmieniono zapisanych danych.';

/// Captures once before exposing any editable form. Never re-captures on save.
class FitnessLeaseGate extends ConsumerStatefulWidget {
  const FitnessLeaseGate({super.key, this.protocolId, required this.builder});
  final String? protocolId;
  final Widget Function(FitnessTestsWorkflow, FitnessWriteLease) builder;
  @override
  ConsumerState<FitnessLeaseGate> createState() => _FitnessLeaseGateState();
}

class _FitnessLeaseGateState extends ConsumerState<FitnessLeaseGate> {
  late final FitnessTestsWorkflow _workflow;
  FitnessWriteLease? _lease;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _workflow = ref.read(fitnessTestsWorkflowProvider);
    _capture();
  }

  Future<void> _capture() async {
    try {
      final lease = await _workflow.captureLease(protocolId: widget.protocolId);
      if (mounted) setState(() => _lease = lease);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => _lease != null
      ? widget.builder(_workflow, _lease!)
      : Scaffold(
          appBar: fitnessAppBar(context, 'Test sprawnościowy'),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _failed
                  ? const Text(fitnessUnavailable)
                  : const CircularProgressIndicator(
                      semanticsLabel: 'Przygotowanie formularza',
                    ),
            ),
          ),
        );
}

class FitnessIllustration extends StatelessWidget {
  const FitnessIllustration({
    super.key,
    required this.exerciseId,
    required this.name,
  });
  final String exerciseId, name;
  @override
  Widget build(BuildContext context) {
    final asset = exerciseIllustrationAsset(exerciseId);
    Widget placeholder() => Semantics(
      label: 'Brak ilustracji: $name',
      child: const SizedBox(
        height: 120,
        child: Center(child: Icon(Icons.accessibility_new, size: 48)),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: asset == null
          ? placeholder()
          : Image.asset(
              asset,
              height: 160,
              fit: BoxFit.contain,
              semanticLabel: 'Ilustracja: $name',
              errorBuilder: (_, __, ___) => placeholder(),
            ),
    );
  }
}

class CustomTestCard extends StatelessWidget {
  const CustomTestCard({
    super.key,
    required this.protocol,
    required this.results,
    this.onTap,
    this.historyStatus,
  });
  final FitnessProtocol protocol;
  final List<CustomFitnessResult>? results;
  final VoidCallback? onTap;

  /// Explicit loading/read-error state; null retains the normal data semantics.
  final String? historyStatus;
  @override
  Widget build(BuildContext context) {
    final comparison = compareFitnessResults(protocol, results ?? const []);
    final latest = comparison.latest, previous = comparison.previous;
    final unit = protocol.metric.unitLabel;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FitnessIllustration(
              exerciseId: protocol.exerciseId,
              name: protocol.exerciseName,
            ),
            const SizedBox(height: 12),
            Text(
              protocol.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'FitnessTestDisplay',
                fontFamilyFallback: const ['Inter'],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(protocol.exerciseName),
            Text(fitnessMetricLabel(protocol.metric)),
            if (protocol.isArchived)
              const Text('Archiwum • historia zachowana'),
            const SizedBox(height: 12),
            Text(
              historyStatus ??
                  (results == null
                      ? 'Historia niedostępna'
                      : latest == null
                      ? 'Jeszcze bez wyniku'
                      : '${previous == null ? '—' : fitnessNumber(previous.value)} → ${fitnessNumber(latest.value)} $unit'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'FitnessTestDisplay',
                fontFamilyFallback: const ['Inter'],
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (latest != null) Text(fitnessDate(latest.performedAt)),
            if (previous != null)
              Text('Poprzednio: ${fitnessDate(previous.performedAt)}'),
            Text(fitnessConditions(protocol)),
            const Text('Porównanie tylko identycznej wersji zasad.'),
            if (onTap != null)
              TextButton(
                onPressed: onTap,
                child: const Text('Zasady i historia'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rejects local DST gaps instead of silently accepting DateTime normalization.
DateTime? fitnessLocalDateTime(DateTime day, TimeOfDay time) {
  final result = DateTime(day.year, day.month, day.day, time.hour, time.minute);
  return result.year == day.year &&
          result.month == day.month &&
          result.day == day.day &&
          result.hour == time.hour &&
          result.minute == time.minute
      ? result
      : null;
}

class FitnessDateField extends StatelessWidget {
  const FitnessDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
    icon: const Icon(Icons.event_outlined),
    label: Text('Wykonano: ${fitnessDate(value)}'),
    onPressed: !enabled
        ? null
        : () async {
            final day = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (day == null || !context.mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(value),
            );
            if (time == null || !context.mounted) return;
            final selected = fitnessLocalDateTime(day, time);
            if (selected == null || selected.isAfter(DateTime.now())) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Wybierz istniejącą lokalną godzinę, nie późniejszą niż teraz.',
                  ),
                ),
              );
              return;
            }
            onChanged(selected);
          },
  );
}
