import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/fitness_test.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/utils/numeric_input.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _wynikController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _selected == null || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(testsRepositoryProvider)
          .addResult(
            typ: _selected!,
            wynik: parseDecimal(_wynikController.text)!,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zapisać wyniku. Spróbuj ponownie.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test sprawnościowy')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    onSelected: _saving
                        ? null
                        : (_) {
                            if (_selected == t) return;
                            final hadDraft = _wynikController.text.isNotEmpty;
                            setState(() {
                              _selected = t;
                              _wynikController.clear();
                              _formKey.currentState?.reset();
                            });
                            if (hadDraft) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Szkic wyniku został wyczyszczony po zmianie testu.',
                                  ),
                                ),
                              );
                            }
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (_selected != null) ...[
                TextFormField(
                  controller: _wynikController,
                  enabled: !_saving,
                  validator: (text) => validateTestResult(text, _selected!),
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                    signed: _selected == TypTestu.sklon,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Wynik (${_selected!.jednostka})',
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Zapisz wynik',
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
