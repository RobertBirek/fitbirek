import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/fitness_test.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../providers/tests_providers.dart';

/// Wybór i wykonanie testu sprawnościowego (11 predefiniowanych testów).
class RunTestPage extends ConsumerStatefulWidget {
  const RunTestPage({super.key});
  @override
  ConsumerState<RunTestPage> createState() => _RunTestPageState();
}

class _RunTestPageState extends ConsumerState<RunTestPage> {
  TypTestu? _selected;
  final _wynikController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test sprawnościowy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Wybierz test:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TypTestu.values.map((t) {
                return ChoiceChip(
                  label: Text(t.label),
                  selected: _selected == t,
                  onSelected: (_) => setState(() => _selected = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (_selected != null) ...[
              TextField(
                controller: _wynikController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Wynik (${_selected!.jednostka})',
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Zapisz wynik',
                onPressed: () async {
                  final wynik = double.tryParse(_wynikController.text);
                  if (wynik == null) return;
                  await ref
                      .read(testsRepositoryProvider)
                      .addResult(typ: _selected!, wynik: wynik);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
