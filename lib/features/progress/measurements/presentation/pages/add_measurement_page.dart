import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../providers/measurements_providers.dart';

/// Formularz dodania pomiaru ciała.
class AddMeasurementPage extends ConsumerStatefulWidget {
  const AddMeasurementPage({super.key});
  @override
  ConsumerState<AddMeasurementPage> createState() => _AddMeasurementPageState();
}

class _AddMeasurementPageState extends ConsumerState<AddMeasurementPage> {
  final _waga = TextEditingController();
  final _talia = TextEditingController();
  final _klatka = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nowy pomiar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _waga,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Waga (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _klatka,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Obwód klatki (cm, opcjonalnie)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _talia,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Obwód talii (cm, opcjonalnie)'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Zapisz pomiar',
              onPressed: () async {
                final waga = double.tryParse(_waga.text);
                if (waga == null) return;
                await ref.read(measurementsRepositoryProvider).addMeasurement(
                      wagaKg: waga,
                      obwodKlatki: double.tryParse(_klatka.text),
                      obwodTalii: double.tryParse(_talia.text),
                    );
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
