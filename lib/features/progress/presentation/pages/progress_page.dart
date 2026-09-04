import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../prs/providers/prs_providers.dart';
import '../../measurements/providers/measurements_providers.dart';

/// Ekran "Postępy" - pomiary, testy, PR (lista + linki do dodawania danych).
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(allPrsProvider);
    final measurementsAsync = ref.watch(allMeasurementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Postępy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.monitor_weight_outlined),
                    label: const Text('Dodaj pomiar'),
                    onPressed: () => context.push('/progress/add-measurement'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Test sprawności'),
                    onPressed: () => context.push('/progress/run-test'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Rekordy osobiste (PR)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            prsAsync.when(
              data: (list) => list.isEmpty
                  ? const Text(
                      'Brak PR - wykonaj pierwszy trening z ciężarem',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Column(
                      children: list
                          .take(10)
                          .map(
                            (pr) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(pr.nazwaCwiczeniaPl),
                                subtitle: Text(
                                  '${pr.ciezarKg} kg × ${pr.powtorzenia} • ${Formatters.date(pr.data)}',
                                ),
                                trailing: Text(
                                  '1RM≈${pr.szacowane1Rm.toStringAsFixed(1)}kg',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Błąd: $e'),
            ),
            const SizedBox(height: 20),
            Text(
              'Pomiary ciała',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            measurementsAsync.when(
              data: (list) => list.isEmpty
                  ? const Text(
                      'Brak pomiarów - dodaj pierwszy pomiar',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Column(
                      children: list
                          .take(10)
                          .map(
                            (m) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(Formatters.weight(m.wagaKg)),
                                subtitle: Text(Formatters.date(m.data)),
                              ),
                            ),
                          )
                          .toList(),
                    ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Błąd: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
