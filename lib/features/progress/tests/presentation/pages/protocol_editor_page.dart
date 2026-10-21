import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/content_layout.dart';
import '../../../../../core/utils/numeric_input.dart';
import '../../../../exercises/providers/exercises_providers.dart';
import '../../../../exercises/providers/exercise_variants_providers.dart';
import '../../../../exercises/presentation/widgets/own_variants.dart'
    show variantDescription;
import '../../domain/fitness_protocol.dart';
import '../../providers/tests_providers.dart';
import '../fitness_test_widgets.dart';

class ProtocolEditorPage extends StatelessWidget {
  const ProtocolEditorPage({super.key, this.exerciseId, this.protocolId});
  final String? exerciseId, protocolId;
  @override
  Widget build(BuildContext context) => FitnessLeaseGate(
    key: ValueKey('editor:$protocolId:$exerciseId'),
    protocolId: protocolId,
    builder: (workflow, lease) => ProtocolEditorForm(
      workflow: workflow,
      lease: lease,
      exerciseId: exerciseId,
    ),
  );
}

class ProtocolEditorForm extends ConsumerStatefulWidget {
  const ProtocolEditorForm({
    super.key,
    required this.workflow,
    required this.lease,
    this.exerciseId,
  });
  final FitnessTestsWorkflow workflow;
  final FitnessWriteLease lease;
  final String? exerciseId;
  @override
  ConsumerState<ProtocolEditorForm> createState() => _ProtocolEditorFormState();
}

class _ProtocolEditorFormState extends ConsumerState<ProtocolEditorForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _load, _limit, _instructions;
  String? _exerciseId;
  FitnessMetric _metric = FitnessMetric.reps;
  FitnessDirection _direction = FitnessDirection.higher;
  FitnessLoadBasis? _basis;
  FitnessSide? _side;
  Map<String, dynamic>? _variant;
  bool _busy = false, _blocked = false;
  String? _error;
  FitnessProtocol? get _baseline => widget.lease.protocol;
  @override
  void initState() {
    super.initState();
    final p = _baseline;
    _exerciseId = p?.exerciseId ?? widget.exerciseId;
    _name = TextEditingController(text: p?.name ?? '');
    _load = TextEditingController(
      text: p?.loadKg == null ? '' : fitnessNumber(p!.loadKg!),
    );
    _limit = TextEditingController(text: p?.timeLimitSeconds?.toString() ?? '');
    _instructions = TextEditingController(text: p?.instructions ?? '');
    _metric = p?.metric ?? FitnessMetric.reps;
    _direction = p?.direction ?? FitnessDirection.higher;
    _basis = p?.loadBasis;
    _side = p?.side;
    _variant = p?.variantSnapshot;
  }

  @override
  void dispose() {
    for (final c in [_name, _load, _limit, _instructions]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _blocked || !_form.currentState!.validate()) return;
    final exercises = ref.read(allExercisesProvider).valueOrNull;
    final exercise = exercises?.where((e) => e.id == _exerciseId).firstOrNull;
    final snapshotName =
        exercise?.nazwaPl ??
        (_baseline?.exerciseId == _exerciseId ? _baseline?.exerciseName : null);
    if (_exerciseId == null || snapshotName == null) {
      setState(() => _error = 'Wybierz dostępne ćwiczenie.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = FitnessProtocolDraft(
        name: _name.text.trim(),
        exerciseId: _exerciseId!,
        exerciseName: snapshotName,
        metric: _metric,
        direction: _direction,
        loadKg: _load.text.trim().isEmpty ? null : parseDecimal(_load.text),
        loadBasis: _load.text.trim().isEmpty ? null : _basis,
        side: _side,
        variantSnapshot: _variant,
        timeLimitSeconds: _limit.text.trim().isEmpty
            ? null
            : int.parse(_limit.text.trim()),
        instructions: _instructions.text,
      );
      final saved = _baseline == null
          ? await widget.workflow.createProtocol(widget.lease, draft)
          : await widget.workflow.reviseProtocol(widget.lease, draft);
      if (mounted) {
        context.go('/progress/tests/${saved.id}');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _blocked = error is StateError;
          _error = _blocked
              ? 'Dostęp lub zasady uległy zmianie. Zamknij formularz i otwórz go ponownie.'
              : 'Nie można zapisać zasad. Sprawdź pola i spróbuj ponownie.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(allExercisesProvider);
    final variants = _exerciseId == null
        ? null
        : ref.watch(exerciseVariantsProvider(_exerciseId!));
    final items = catalog.valueOrNull ?? [];
    final historicalExercise =
        _baseline != null && !items.any((e) => e.id == _baseline!.exerciseId);
    // A variant ID does not identify its rules. Keep the selected map unchanged
    // across live collection edits; only an explicit selection replaces it.
    final currentVariants = {
      for (final v in variants?.valueOrNull ?? <Map<String, dynamic>>[])
        _variantSnapshotKey(v): v,
    };
    final savedVariants = {
      for (final v in [
        if (_baseline?.exerciseId == _exerciseId) _baseline?.variantSnapshot,
        _variant,
      ])
        if (v != null && !currentVariants.containsKey(_variantSnapshotKey(v)))
          _variantSnapshotKey(v): v,
    };
    final variantChoices = {
      for (final e in currentVariants.entries) 'current:${e.key}': e.value,
      for (final e in savedVariants.entries) 'saved:${e.key}': e.value,
    };
    final selectedVariantKey = _variant == null
        ? ''
        : '${currentVariants.containsKey(_variantSnapshotKey(_variant!)) ? 'current' : 'saved'}:${_variantSnapshotKey(_variant!)}';
    return Scaffold(
      appBar: fitnessAppBar(
        context,
        _baseline == null ? 'Nowy test' : 'Nowa wersja zasad',
      ),
      body: SafeArea(
        child: ContentLayout(
          child: Form(
            key: _form,
            child: ListView(
              padding: ContentLayout.pagePadding(context),
              children: [
                const Text(
                  'Test mierzy próbę, nie trening. Nie tworzy serii ani rekordów PR.',
                ),
                if (_baseline != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Zapis utworzy osobną wersję. Dotychczasowe zasady pozostaną aktywne, a historia nie zostanie przeniesiona.',
                    ),
                  ),
                if (_error != null)
                  Semantics(liveRegion: true, child: Text(_error!)),
                if (catalog.isLoading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Ładowanie ćwiczeń',
                  ),
                if (catalog.hasError)
                  TextButton(
                    onPressed: () => ref.invalidate(allExercisesProvider),
                    child: const Text('Nie wczytano ćwiczeń. Ponów'),
                  ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue:
                      items.any((e) => e.id == _exerciseId) ||
                          (historicalExercise &&
                              _exerciseId == _baseline!.exerciseId)
                      ? _exerciseId
                      : null,
                  decoration: const InputDecoration(labelText: 'Ćwiczenie'),
                  items: [
                    for (final e in items)
                      DropdownMenuItem(value: e.id, child: Text(e.nazwaPl)),
                    if (historicalExercise)
                      DropdownMenuItem(
                        value: _baseline!.exerciseId,
                        child: Text('${_baseline!.exerciseName} (zapisane)'),
                      ),
                  ],
                  onChanged: _busy || _blocked
                      ? null
                      : (id) => setState(() {
                          _exerciseId = id;
                          _variant = null;
                        }),
                  validator: (v) => v == null ? 'Wybierz ćwiczenie' : null,
                ),
                const SizedBox(height: 16),
                if (_exerciseId != null)
                  FitnessIllustration(
                    exerciseId: _exerciseId!,
                    name:
                        items
                            .where((e) => e.id == _exerciseId)
                            .firstOrNull
                            ?.nazwaPl ??
                        _baseline?.exerciseName ??
                        'Ćwiczenie',
                  ),
                TextFormField(
                  controller: _name,
                  enabled: !_busy && !_blocked,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Nazwa testu'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Podaj nazwę testu'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FitnessMetric>(
                  isExpanded: true,
                  initialValue: _metric,
                  decoration: const InputDecoration(labelText: 'Co mierzysz?'),
                  items: const [
                    DropdownMenuItem(
                      value: FitnessMetric.reps,
                      child: Text('Powtórzenia (powt.)'),
                    ),
                    DropdownMenuItem(
                      value: FitnessMetric.time,
                      child: Text('Czas (s)'),
                    ),
                    DropdownMenuItem(
                      value: FitnessMetric.distance,
                      child: Text('Dystans (m)'),
                    ),
                  ],
                  onChanged: _busy || _blocked
                      ? null
                      : (v) => setState(() => _metric = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FitnessDirection>(
                  isExpanded: true,
                  initialValue: _direction,
                  decoration: const InputDecoration(
                    labelText: 'Kierunek poprawy',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: FitnessDirection.higher,
                      child: Text('Więcej = lepiej'),
                    ),
                    DropdownMenuItem(
                      value: FitnessDirection.lower,
                      child: Text('Mniej = lepiej'),
                    ),
                  ],
                  onChanged: _busy || _blocked
                      ? null
                      : (v) => setState(() => _direction = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _load,
                  enabled: !_busy && !_blocked,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Obciążenie (kg), opcjonalnie',
                    helperText: 'Puste pole nie oznacza 0 kg.',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = parseDecimal(v);
                    return n == null || !n.isFinite || n < 0 || n > 1000
                        ? 'Podaj od 0 do 1000 kg'
                        : null;
                  },
                ),
                if (_load.text.trim().isNotEmpty)
                  DropdownButtonFormField<FitnessLoadBasis>(
                    isExpanded: true,
                    initialValue: _basis,
                    decoration: const InputDecoration(
                      labelText: 'Sposób podania kg',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: FitnessLoadBasis.total,
                        child: Text('Łącznie'),
                      ),
                      DropdownMenuItem(
                        value: FitnessLoadBasis.perImplement,
                        child: Text('Na przyrząd'),
                      ),
                    ],
                    onChanged: _busy || _blocked
                        ? null
                        : (v) => setState(() => _basis = v),
                    validator: (v) =>
                        v == null ? 'Określ sposób podania obciążenia' : null,
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _side?.name ?? '',
                  decoration: const InputDecoration(labelText: 'Strona'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Nieokreślona')),
                    DropdownMenuItem(value: 'left', child: Text('Lewa')),
                    DropdownMenuItem(value: 'right', child: Text('Prawa')),
                    DropdownMenuItem(value: 'both', child: Text('Obie')),
                  ],
                  onChanged: _busy || _blocked
                      ? null
                      : (v) => setState(
                          () => _side = FitnessSide.values
                              .where((s) => s.name == v)
                              .firstOrNull,
                        ),
                ),
                const SizedBox(height: 16),
                if (variants?.isLoading == true)
                  const LinearProgressIndicator(),
                if (variants?.hasError == true)
                  const Text(
                    'Nie wczytano wariantów. Możesz zachować zapisany wariant lub wybrać brak wariantu.',
                  ),
                DropdownButtonFormField<String>(
                  key: ValueKey('$_exerciseId:$selectedVariantKey'),
                  isExpanded: true,
                  isDense: false,
                  itemHeight: null,
                  initialValue: selectedVariantKey,
                  decoration: const InputDecoration(
                    labelText: 'Wariant ćwiczenia',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Bez wariantu'),
                    ),
                    for (final entry in variantChoices.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          '${entry.value['name']} (${entry.key.startsWith('saved:') ? 'zapisany snapshot' : 'bieżący wariant'})',
                        ),
                      ),
                  ],
                  onChanged: _busy || _blocked
                      ? null
                      : (key) => setState(
                          () =>
                              _variant = key == '' ? null : variantChoices[key],
                        ),
                ),
                if (_variant != null) Text(variantDescription(_variant!)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _limit,
                  enabled: !_busy && !_blocked,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Limit czasu (s), opcjonalnie',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    return n == null || n < 1 || n > 86400
                        ? 'Podaj całkowitą liczbę od 1 do 86400 s'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instructions,
                  enabled: !_busy && !_blocked,
                  maxLength: 4000,
                  minLines: 4,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'Zasady wykonania',
                    hintText: 'Technika, zakres ruchu, kiedy kończysz próbę…',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: _busy || _blocked || catalog.isLoading
                      ? null
                      : _save,
                  child: Text(
                    _busy
                        ? 'Zapisywanie…'
                        : _baseline == null
                        ? 'Utwórz test'
                        : 'Zapisz nową wersję',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stable, full-map identity, independent of JSON object key order. List order
/// and all values (including variant metadata) remain significant.
String _variantSnapshotKey(Map<String, dynamic> value) {
  Object? canonical(Object? node) {
    if (node is Map<String, dynamic>) {
      final keys = node.keys.toList()..sort();
      return {for (final key in keys) key: canonical(node[key])};
    }
    if (node is List) return node.map(canonical).toList();
    return node;
  }

  return jsonEncode(canonical(value));
}
