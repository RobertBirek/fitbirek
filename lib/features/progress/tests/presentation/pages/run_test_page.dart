import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/models/fitness_test.dart';
import '../../../../../core/widgets/content_layout.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../../../core/utils/numeric_input.dart';
import '../../domain/fitness_protocol.dart';
import '../../providers/tests_providers.dart';
import '../fitness_test_widgets.dart';
import 'fitness_tests_section.dart';

/// Legacy URL remains valid. Query parameters select a custom protocol or an
/// exercise's existing definitions without starting a workout or writing data.
class RunTestPage extends StatelessWidget {
  const RunTestPage({super.key, this.exerciseId, this.protocolId});
  final String? exerciseId, protocolId;
  @override
  Widget build(BuildContext context) {
    if (exerciseId != null && protocolId == null) {
      return Scaffold(
        appBar: fitnessAppBar(context, 'Test sprawnościowy'),
        body: SafeArea(
          child: ContentLayout(
            child: ListView(
              padding: ContentLayout.pagePadding(context),
              children: [FitnessTestsSection(exerciseId: exerciseId)],
            ),
          ),
        ),
      );
    }
    return FitnessLeaseGate(
      key: ValueKey('result:$protocolId'),
      protocolId: protocolId,
      builder: (workflow, lease) =>
          FitnessResultForm(workflow: workflow, lease: lease),
    );
  }
}

class FitnessResultForm extends StatefulWidget {
  const FitnessResultForm({
    super.key,
    required this.workflow,
    required this.lease,
  });
  final FitnessTestsWorkflow workflow;
  final FitnessWriteLease lease;
  @override
  State<FitnessResultForm> createState() => _FitnessResultFormState();
}

class _FitnessResultFormState extends State<FitnessResultForm> {
  TypTestu? _selected;
  final _value = TextEditingController();
  final _form = GlobalKey<FormState>();
  DateTime _performedAt = DateTime.now();
  bool _saving = false, _blocked = false;
  String? _error;
  FitnessProtocol? get _protocol => widget.lease.protocol;
  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving ||
        _blocked ||
        !_form.currentState!.validate() ||
        (_protocol == null && _selected == null)) {
      return;
    }
    if (_performedAt.isAfter(DateTime.now())) {
      setState(() => _error = 'Data próby nie może być w przyszłości.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final value = parseDecimal(_value.text)!;
      if (_protocol == null) {
        await widget.workflow.addLegacyResult(
          widget.lease,
          typ: _selected!,
          value: value,
          performedAt: _performedAt,
        );
      } else {
        await widget.workflow.addCustomResult(
          widget.lease,
          value: value,
          performedAt: _performedAt,
        );
      }
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go(
            _protocol == null
                ? '/progress?section=tests'
                : '/progress/tests/${_protocol!.id}',
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _blocked = error is StateError;
          _error = _blocked
              ? 'Dostęp lub zasady uległy zmianie. Zamknij formularz i otwórz go ponownie.'
              : 'Nie udało się zapisać wyniku. Sprawdź wartość i datę.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validate(String? text) {
    if (_protocol == null) {
      return _selected == null
          ? 'Wybierz test'
          : validateTestResult(text, _selected!);
    }
    final n = parseDecimal(text ?? '');
    if (n == null || !n.isFinite || n < 0 || n > 1e9) {
      return 'Wpisz wartość od 0 do 1000000000.';
    }
    if (_protocol!.metric == FitnessMetric.reps && n != n.truncateToDouble()) {
      return 'Wpisz całkowitą liczbę powtórzeń.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: fitnessAppBar(context, 'Test sprawnościowy'),
    body: SafeArea(
      child: ContentLayout(
        child: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: ContentLayout.pagePadding(context),
            children: [
              if (_protocol != null) ...[
                _ResultProtocolCard(protocol: _protocol!),
                Text(_protocol!.instructions),
                const SizedBox(height: 16),
              ] else ...[
                const Text(
                  'Dotychczasowe testy • dawny protokół nie został zapisany.',
                ),
                const Text('Wybierz test:'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in TypTestu.values)
                      ChoiceChip(
                        label: Text(t.label),
                        selected: _selected == t,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onSelected: _saving || _blocked
                            ? null
                            : (_) {
                                if (_selected == t) return;
                                final hadDraft = _value.text.isNotEmpty;
                                setState(() {
                                  _selected = t;
                                  _value.clear();
                                  _form.currentState?.reset();
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
                      ),
                  ],
                ),
              ],
              if (_selected != null || _protocol != null) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _value,
                  enabled: !_saving && !_blocked,
                  validator: _validate,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                    signed: _selected == TypTestu.sklon,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        'Wynik (${_protocol?.metric.unitLabel ?? _selected!.jednostka})',
                  ),
                ),
                const SizedBox(height: 16),
                FitnessDateField(
                  value: _performedAt,
                  enabled: !_saving && !_blocked,
                  onChanged: (value) => setState(() => _performedAt = value),
                ),
                const Text(
                  'Podaj rzeczywistą datę i godzinę wykonania próby. Wynik zapisujesz ręcznie.',
                ),
                if (_error != null)
                  Semantics(liveRegion: true, child: Text(_error!)),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Zapisz wynik',
                  isLoading: _saving,
                  onPressed: _saving || _blocked ? null : _save,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Only the read-only card subscribes to history. Provider updates never reopen
/// the form, replace its lease, or reset its value/date draft.
class _ResultProtocolCard extends ConsumerWidget {
  const _ResultProtocolCard({required this.protocol});
  final FitnessProtocol protocol;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(customFitnessResultsProvider)
      .when(
        skipLoadingOnReload: false,
        skipLoadingOnRefresh: false,
        data: (results) => CustomTestCard(protocol: protocol, results: results),
        loading: () => CustomTestCard(
          protocol: protocol,
          results: null,
          historyStatus: 'Ładowanie historii…',
        ),
        error: (_, __) => CustomTestCard(
          protocol: protocol,
          results: null,
          historyStatus: 'Nie udało się wczytać historii.',
        ),
      );
}
