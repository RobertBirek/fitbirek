import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/warsaw_time.dart';
import '../../providers/health_providers.dart';
import 'health_sample_delete_button.dart';

/// The timer also rolls the Warsaw day over while the tab remains mounted.
class HealthTodaySection extends ConsumerStatefulWidget {
  const HealthTodaySection({super.key});
  @override
  ConsumerState<HealthTodaySection> createState() => _HealthTodaySectionState();
}

class _HealthTodaySectionState extends ConsumerState<HealthTodaySection>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _active = false;
  void _refresh() {
    if (mounted && ref.read(healthAccountProvider) != null) {
      ref.invalidate(healthStatusProvider);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.of(context);
    if (active && !_active) Future<void>.microtask(_refresh);
    _active = active;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _active) _refresh();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(healthStatusProvider);
    return ref
        .watch(healthSamplesProvider)
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) =>
              const Text('Nie udało się odczytać danych Apple Zdrowie.'),
          data: (rows) {
            final weights = rows.where((s) => s.kind == 'weight').toList()
              ..sort(
                (a, b) => (b.measuredAt ?? b.importedAt).compareTo(
                  a.measuredAt ?? a.importedAt,
                ),
              );
            return HealthTodayCard(
              serverStatusKnown:
                  status.hasValue &&
                  !status.isLoading &&
                  !status.hasError &&
                  status.valueOrNull != null,
              serverLastImportAt: status.valueOrNull?.lastImportAt,
              onRefresh: status.isLoading ? null : _refresh,
              latestWeight: weights.firstOrNull,
              stepsOfDay: rows
                  .where((s) => s.kind == 'steps' && s.day == warsawDayKey())
                  .toList(),
              lastImportedAt: rows.isEmpty
                  ? null
                  : rows
                        .map((s) => s.importedAt)
                        .reduce((a, b) => a.isAfter(b) ? a : b),
            );
          },
        );
  }
}

class HealthTodayCard extends StatelessWidget {
  const HealthTodayCard({
    super.key,
    this.latestWeight,
    this.stepsOfDay = const [],
    this.lastImportedAt,
    this.serverStatusKnown = false,
    this.serverLastImportAt,
    this.onRefresh,
  });
  final HealthSampleData? latestWeight;
  final List<HealthSampleData> stepsOfDay;
  final DateTime? lastImportedAt;
  final bool serverStatusKnown;
  final DateTime? serverLastImportAt;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) {
    final w = latestWeight;
    final s = stepsOfDay.firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apple Zdrowie',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Odśwież status importu',
              icon: const Icon(Icons.refresh),
            ),
            Text(
              w == null
                  ? 'Ostatnia masa: — brak danych'
                  : 'Ostatnia masa: ${w.value.toStringAsFixed(1)} kg • ${w.source}',
            ),
            if (w != null)
              Text('Pomiar: ${formatWarsaw(w.measuredAt ?? w.importedAt)}'),
            Text(
              s == null
                  ? 'Kroki dziś: — brak danych (${warsawDayKey()})'
                  : 'Kroki: ${s.value.toInt()} • ${s.day}',
            ),
            if (s != null) HealthSampleDeleteButton(sample: s),
            const Text(
              'Kroki: ręcznie potwierdzony wynik dzienny, nie autoimport.',
            ),
            Text(
              serverStatusKnown
                  ? serverLastImportAt == null
                        ? 'Ostatni udany import: — brak importów na serwerze'
                        : 'Ostatni udany import: ${formatWarsaw(serverLastImportAt!)}'
                  : lastImportedAt == null
                  ? 'Ostatni import: —'
                  : 'Status serwera niedostępny — ostatnie lokalne dane: ${formatWarsaw(lastImportedAt!)}',
            ),
            const Text(
              'Europe/Warsaw • dane lokalne, mogą być nieaktualne. Nowe importy pojawią się po synchronizacji.',
            ),
          ],
        ),
      ),
    );
  }
}
