import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/set_comparison.dart';
import '../providers/prs_providers.dart';

class PrRecordsList extends ConsumerWidget {
  const PrRecordsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(prGroupsProvider)
        .when(
          data: (groups) => groups.isEmpty
              ? const Text(
                  'Brak PR - wykonaj pierwszy trening z ciężarem',
                  style: TextStyle(color: Colors.grey),
                )
              : Column(
                  children: [
                    for (final history in groups.values)
                      Builder(
                        builder: (context) {
                          final best = history.reduce(
                            (a, b) => a.szacowane1Rm >= b.szacowane1Rm ? a : b,
                          );
                          final side = setSideLabel(best.side);
                          return Card(
                            child: ExpansionTile(
                              key: PageStorageKey((
                                best.cwiczenieId,
                                best.side,
                              )),
                              title: Text('${best.nazwaCwiczeniaPl} • $side'),
                              subtitle: Text(
                                'Najlepszy: ${best.ciezarKg} kg × ${best.powtorzenia} • 1RM≈${best.szacowane1Rm.toStringAsFixed(1)} kg',
                              ),
                              children: [
                                for (final pr in history)
                                  ListTile(
                                    title: Text(
                                      '${pr.ciezarKg} kg × ${pr.powtorzenia} • $side',
                                    ),
                                    subtitle: Text(Formatters.date(pr.data)),
                                    trailing: Text(
                                      '1RM≈${pr.szacowane1Rm.toStringAsFixed(1)} kg',
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
          loading: () => const CircularProgressIndicator(),
          error: (e, st) => Text('Błąd: $e'),
        );
  }
}
