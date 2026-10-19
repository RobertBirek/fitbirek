import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/database/app_database.dart';
import '../../../../../core/utils/formatters.dart';
import '../../data/measurements_repository.dart';
import '../../providers/measurements_providers.dart';

class ManualMeasurementActions extends ConsumerStatefulWidget {
  const ManualMeasurementActions({super.key, required this.measurement});
  final MeasurementData measurement;
  @override
  ConsumerState<ManualMeasurementActions> createState() =>
      _ManualMeasurementActionsState();
}

class _ManualMeasurementActionsState
    extends ConsumerState<ManualMeasurementActions> {
  bool _busy = false;

  Future<void> _delete() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(measurementsRepositoryProvider);
      final shown = widget.measurement;
      final edit = await repo.capture(shown.id);
      if (!mounted) return;
      if (edit.row != shown) throw MeasurementConflict();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('Usunąć pomiar?'),
          content: Text(
            '${Formatters.weight(shown.wagaKg)} • ${Formatters.date(shown.data)}\nPomiar ręczny zostanie usunięty również z synchronizowanych urządzeń.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Usuń'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await repo.deleteMeasurement(edit);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is MeasurementSyncPending
                  ? MeasurementSyncPending.message
                  : error is MeasurementConflict
                  ? 'Pomiar lub konto się zmieniły. Otwórz historię ponownie.'
                  : 'Nie udało się usunąć pomiaru. Spróbuj ponownie.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    children: [
      IconButton(
        tooltip: 'Edytuj pomiar ręczny',
        icon: const Icon(Icons.edit_outlined),
        onPressed: _busy
            ? null
            : () => context.push(
                '/progress/measurement/${widget.measurement.id}',
              ),
      ),
      IconButton(
        tooltip: 'Usuń pomiar ręczny',
        icon: const Icon(Icons.delete_outline),
        onPressed: _busy ? null : _delete,
      ),
    ],
  );
}
