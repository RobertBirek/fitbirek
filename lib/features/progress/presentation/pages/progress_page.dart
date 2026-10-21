import 'package:flutter/material.dart';
import '../../../../core/widgets/content_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/weight_line_chart.dart';
import '../../prs/presentation/pr_records_list.dart';
import '../../../health/providers/health_providers.dart';
import '../../../health/presentation/widgets/health_sample_delete_button.dart';
import '../../../health/presentation/widgets/health_steps_history.dart';
import '../../tests/presentation/pages/fitness_tests_section.dart';
import '../../trends/presentation/training_trends_page.dart';
import '../../measurements/presentation/widgets/manual_measurement_actions.dart';

/// Ekran "Postępy" - pomiary, testy, PR (lista + linki do dodawania danych).
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key, this.section = 'body'});
  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(mergedWeightsProvider);

    return DefaultTabController(
      key: ValueKey(section),
      length: 3,
      initialIndex: section == 'tests'
          ? 1
          : section == 'training'
          ? 2
          : 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Postępy'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ciało', height: 48),
              Tab(text: 'Testy', height: 48),
              Tab(text: 'Trening', height: 48),
            ],
          ),
        ),
        body: SafeArea(
          child: ContentLayout(
            child: TabBarView(
              children: [
                ListView(
                  padding: ContentLayout.pagePadding(context),
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.monitor_weight_outlined),
                      label: const Text('Dodaj pomiar'),
                      onPressed: () =>
                          context.push('/progress/add-measurement'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Waga w czasie',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pomiar ręczny + Apple Zdrowie • źródło w dymku i historii',
                    ),
                    measurementsAsync.when(
                      data: (list) => Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                          child: WeightLineChart(measurements: list),
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, st) => const Text(
                        'Nie udało się wczytać pomiarów. Otwórz ekran ponownie.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Pomiary ciała',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    measurementsAsync.when(
                      data: (list) => list.isEmpty
                          ? const Text(
                              'Brak pomiarów - dodaj pierwszy pomiar',
                              style: TextStyle(color: Colors.grey),
                            )
                          : Column(
                              children: list.reversed
                                  .map(
                                    (m) => Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            title: Text(
                                              Formatters.weight(m.wagaKg),
                                            ),
                                            subtitle: Text(
                                              '${Formatters.date(m.data)} • ${m.source ?? 'Pomiar ręczny'}',
                                            ),
                                            trailing: m.sample == null
                                                ? null
                                                : HealthSampleDeleteButton(
                                                    sample: m.sample!,
                                                  ),
                                          ),
                                          if (m.manual != null && !m.imported)
                                            ManualMeasurementActions(
                                              key: ValueKey(m.manual!.syncId),
                                              measurement: m.manual!,
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, st) => const Text(
                        'Nie udało się wczytać pomiarów. Otwórz ekran ponownie.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const HealthStepsHistory(),
                  ],
                ),
                ListView(
                  padding: ContentLayout.pagePadding(context),
                  children: const [FitnessTestsSection()],
                ),
                ListView(
                  padding: ContentLayout.pagePadding(context),
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.trending_up),
                      label: const Text('Trendy treningowe'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TrainingTrendsPage(),
                        ),
                      ),
                    ),
                    Text(
                      'Rekordy osobiste (PR)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const PrRecordsList(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
