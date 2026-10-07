import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../providers/health_providers.dart';

class HealthSampleDeleteButton extends ConsumerWidget {
  const HealthSampleDeleteButton({super.key, required this.sample});
  final HealthSampleData sample;
  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: 'Usuń importowaną próbkę',
    icon: const Icon(Icons.delete_outline),
    onPressed: () async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Usunąć importowaną próbkę?'),
          content: const Text(
            'Usunięcie zostanie zsynchronizowane także po pracy offline. Import nie odtworzy tej próbki. Dane w Apple Zdrowie pozostaną bez zmian.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Usuń'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      try {
        await ref.read(healthRepositoryProvider).deleteSample(sample);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nie udało się usunąć próbki. Dane zachowano.'),
            ),
          );
        }
      }
    },
  );
}
