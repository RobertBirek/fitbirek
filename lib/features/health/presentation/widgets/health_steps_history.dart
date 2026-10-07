import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/health_providers.dart';
import 'health_sample_delete_button.dart';

class HealthStepsHistory extends ConsumerWidget {
  const HealthStepsHistory({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(healthSamplesProvider)
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) =>
            const Text('Nie udało się odczytać importowanych kroków.'),
        data: (rows) {
          final steps = rows.where((s) => s.kind == 'steps').toList()
            ..sort((a, b) => b.day.compareTo(a.day));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kroki — historia Apple Zdrowie (Europe/Warsaw)'),
              if (steps.isEmpty)
                const Text('Brak zaimportowanych wyników kroków.'),
              for (final s in steps)
                ListTile(
                  title: Text('${s.value.toInt()} kroków • ${s.day}'),
                  subtitle: Text(
                    '${s.source} • ręcznie potwierdzony wynik dzienny',
                  ),
                  trailing: HealthSampleDeleteButton(sample: s),
                ),
            ],
          );
        },
      );
}
