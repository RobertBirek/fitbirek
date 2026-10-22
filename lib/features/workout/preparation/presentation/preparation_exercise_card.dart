import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/exercise.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/numeric_input.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../exercises/presentation/exercise_illustrations.dart';
import '../../../planner/domain/structured_plan.dart';
import '../../domain/fixed_load_progression.dart';
import '../domain/equipment_inventory.dart';
import '../domain/preparation_progression.dart';
import '../domain/workout_preparation.dart';
import '../providers/preparation_providers.dart';

String preparationKg(num value) {
  final text = value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  return text.replaceAll('.', ',');
}

class PreparationExerciseCard extends ConsumerStatefulWidget {
  const PreparationExerciseCard({
    super.key,
    required this.draft,
    required this.index,
    required this.enabled,
    required this.onTarget,
    required this.onReplace,
  });
  final PreparationDraft draft;
  final int index;
  final bool enabled;
  final ValueChanged<PreparedTarget> onTarget;
  final VoidCallback onReplace;
  @override
  ConsumerState<PreparationExerciseCard> createState() =>
      _PreparationExerciseCardState();
}

class _PreparationExerciseCardState
    extends ConsumerState<PreparationExerciseCard> {
  late final TextEditingController _weight;
  LoadImplement? _implement;
  int _quantity = 2;
  int? _reps;
  bool _weightDirty = false, _implementDirty = false, _loadedHistory = false;
  AsyncValue<List<ProgressionPerformance>> _history = const AsyncLoading();
  Exercise get _exercise =>
      widget.draft.snapshot.exercise(widget.draft.exerciseIdAt(widget.index));
  PlanPrescription get _dose =>
      widget.draft.sessionPlan!.blocks[widget.index].prescription;
  String? get _side => widget.draft.snapshot.defaultSide(_exercise.id);
  bool get _dumbbells => _exercise.sprzet.contains('Hantle');
  bool get _ez => _exercise.sprzet.contains('Gryf łamany EZ');
  // cw010 uses dumbbells as stable push-up handles, not as an external load.
  bool get _usesWeight =>
      _exercise.id != 'cw010' &&
      (_dumbbells ||
          _ez ||
          _exercise.sprzet.contains('Sandbag') ||
          _dose.weightKg != null);

  bool get _current =>
      mounted &&
      widget.enabled &&
      ref.read(cachedAuthWriteAuthorityProvider).epoch ==
          widget.draft.snapshot.lease.epoch;

  @override
  void initState() {
    super.initState();
    final target = widget.draft.targets[widget.index];
    _implement =
        target?.implement ??
        (_dumbbells
            ? LoadImplement.smallDumbbell
            : _ez
            ? LoadImplement.ezBar
            : null);
    _quantity = target?.quantity ?? (_ez ? 1 : 2);
    _reps = target?.reps ?? _dose.reps;
    final kg = target?.weightKg ?? _dose.weightKg;
    _weight = TextEditingController(text: kg == null ? '' : preparationKg(kg));
    ref.listenManual(
      preparationHistoryProvider((
        snapshot: widget.draft.snapshot,
        exerciseId: _exercise.id,
        side: _side,
        variantId: null,
      )),
      (_, next) {
        if (!mounted) return;
        setState(() => _history = next);
        if (!next.isLoading && !next.hasError && !_loadedHistory) {
          _loadedHistory = true;
          final offer = _offer;
          final last = offer?.last?.weightKg;
          if (_usesWeight &&
              !_weightDirty &&
              last != null &&
              last.isFinite &&
              last >= 0) {
            if (!_implementDirty && _dumbbells) {
              final scaled = last * 1000;
              if (scaled.isFinite && scaled == scaled.roundToDouble()) {
                final stock = ref.read(preparationEquipmentProvider);
                for (final kind in [
                  LoadImplement.fixedDumbbell,
                  LoadImplement.smallDumbbell,
                  LoadImplement.largeDumbbell,
                ]) {
                  if (assembleLoad(
                    inventory: stock,
                    implement: kind,
                    targetGrams: scaled.toInt(),
                    quantity: _quantity,
                  ).isNotEmpty) {
                    _implement = kind;
                    break;
                  }
                }
              }
            }
            _weight.text = preparationKg(last);
          }
          _emitAfterFrame();
        }
      },
      fireImmediately: true,
    );
    _emitAfterFrame();
  }

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  /// Keep the actual set count; accept only a clear catalogue range containing
  /// the current plan target. It is shown separately, never rewrites the plan.
  String get _range {
    final match = RegExp(
      r'^\s*\d+\s*[x×]\s*(\d+)\s*[-–]\s*(\d+)\s*(?:powt\.?)?\s*$',
      caseSensitive: false,
    ).firstMatch(_exercise.seriexPowtorzenia);
    final low = match == null ? null : int.tryParse(match[1]!);
    final high = match == null ? null : int.tryParse(match[2]!);
    if (low != null &&
        high != null &&
        low > 0 &&
        low < high &&
        high <= 1800 &&
        _dose.reps != null &&
        _dose.reps! >= low &&
        _dose.reps! <= high) {
      return '${_dose.sets}×$low–$high';
    }
    return '${_dose.sets}×${_dose.reps ?? 0}';
  }

  PreparationLoadSuggestion? get _offer =>
      _history.isLoading || _history.hasError
      ? null
      : proposePreparationLoad(
          exerciseId: _exercise.id,
          side: _side,
          variantId: null,
          prescription: _range,
          tracking: _dose.tracking,
          usesWeight: _usesWeight,
          implement: _implement,
          quantity: _quantity,
          historyUnitConfirmed: true,
          history: _history.valueOrNull ?? [],
          inventory: ref.read(preparationEquipmentProvider),
        );

  String? _validate(String? raw) {
    if ((raw ?? '').trim().isEmpty) return null;
    final kg = parseDecimal(raw!);
    if (kg == null || kg < 0 || kg > 1000) {
      return 'Podaj poprawny ciężar od 0 do 1000 kg.';
    }
    final grams = kg * 1000;
    if ((grams - grams.round()).abs() > 0.000001) {
      return 'Podaj masę z dokładnością do 0,001 kg.';
    }
    if (_implement != null &&
        assembleLoad(
          inventory: ref.read(preparationEquipmentProvider),
          implement: _implement!,
          targetGrams: grams.round(),
          quantity: _quantity,
        ).isEmpty) {
      return 'Brak dokładnej konfiguracji. Zmień ciężar lub uchwyt.';
    }
    return null;
  }

  void _emitAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitTarget());
  }

  // User events must update the detached draft synchronously: a Start tap may
  // arrive before the next frame. Only initial/history hydration is deferred.
  void _emitTarget() {
    if (!_current || _validate(_weight.text) != null) return;
    widget.onTarget(
      PreparedTarget(
        weightKg: _usesWeight ? parseDecimal(_weight.text) : null,
        reps: _reps,
        side: _side,
        implement: _implement,
        quantity: _quantity,
      ),
    );
  }

  Future<void> _accept(PreparationLoadSuggestion offer) async {
    if (!_current) return;
    if (_weightDirty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Zastąpić ręczny cel?'),
          content: const Text(
            'Propozycja zastąpi wybrany ciężar lub powtórzenia tylko w tym treningu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Zachowaj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Zastąp'),
            ),
          ],
        ),
      );
      if (replace != true || !_current) return;
    }
    setState(() {
      if (offer.targetWeightKg != null) {
        _weight.text = preparationKg(offer.targetWeightKg!);
      }
      _reps = offer.targetReps ?? _reps;
      _weightDirty = true;
    });
    _emitTarget();
  }

  Widget _image() {
    final asset = exerciseIllustrationAsset(_exercise.id);
    Widget fallback() => const Icon(Icons.fitness_center, size: 36);
    return Semantics(
      label: _exercise.nazwaPl,
      image: true,
      child: SizedBox(
        width: 80,
        height: 80,
        child: asset == null
            ? fallback()
            : Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => fallback(),
              ),
      ),
    );
  }

  List<int> _nearbyLoads(double kg) {
    final kind = _implement;
    if (kind == null || !kg.isFinite || kg < 0 || kg > 1000) return const [];
    final inventory = ref.read(preparationEquipmentProvider);
    final target = kg * 1000;
    Set<int> masses;
    if (kind == LoadImplement.fixedDumbbell) {
      masses = inventory.fixedDumbbells.entries
          .where((e) => e.value >= _quantity)
          .map((e) => e.key)
          .toSet();
    } else {
      var sums = <int>{0};
      for (final e in inventory.plateCounts.entries) {
        sums = {
          for (final sum in sums)
            for (var n = 0; n <= e.value ~/ (2 * _quantity); n++)
              sum + n * e.key,
        };
      }
      masses = {for (final sum in sums) kind.baseGrams + 2 * sum};
    }
    final sorted = masses.toList()..sort();
    return [
      if (sorted.any((m) => m < target)) sorted.lastWhere((m) => m < target),
      if (sorted.any((m) => m > target)) sorted.firstWhere((m) => m > target),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    final kg = parseDecimal(_weight.text);
    final assemblies =
        _implement == null || kg == null || _validate(_weight.text) != null
        ? const <LoadAssembly>[]
        : assembleLoad(
            inventory: ref.read(preparationEquipmentProvider),
            implement: _implement!,
            targetGrams: (kg * 1000).round(),
            quantity: _quantity,
          );
    final assembly = assemblies.firstOrNull;
    final proposedReps = offer?.targetReps;
    final actionable =
        offer != null &&
        (offer.targetWeightKg != null ||
            (proposedReps != null && proposedReps != _reps));
    final usesBench = _exercise.sprzet.contains('Ławeczka');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _image(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _exercise.nazwaPl,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _dose.tracking == 'reps'
                            ? '${_dose.sets}×${_reps ?? _dose.reps} powt.'
                            : '${_dose.sets}×${_dose.workSeconds} s${_dose.tracking == 'rounds' ? ' · rundy' : ''}',
                      ),
                      Text('Przerwy: ${_dose.restSeconds} s'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Sprzęt: ${_exercise.sprzet.join(', ')}'),
            if (usesBench)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Ławka: sprawdź ustawienie, blokadę i możliwość wykonania ruchu zgodnie z opisem. Kąt nie jest zgadywany.',
                ),
              ),
            if (_exercise.kluczoweWskazowki.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Ustawienie i technika'),
                children: [
                  for (final tip in _exercise.kluczoweWskazowki)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(tip),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            _history.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Text('Wczytywanie historii…'),
              error: (_, __) => const Text(
                'Historia niedostępna. Wpisany cel pozostaje bez zmian.',
              ),
              data: (_) {
                final last = offer?.last;
                return Text(
                  last == null
                      ? 'Pierwszy trening — wybierz własny cel.'
                      : 'Ostatnio: ${last.weightKg == null ? 'bez dodatkowego ciężaru' : '${preparationKg(last.weightKg!)} ${_dumbbells ? 'kg/szt.' : 'kg'}'} · ${Formatters.date(last.endedAt.toLocal())}',
                );
              },
            ),
            if (_usesWeight) ...[
              const SizedBox(height: 12),
              if (_dumbbells) ...[
                DropdownButtonFormField<LoadImplement>(
                  isExpanded: true,
                  isDense: false,
                  itemHeight: null,
                  initialValue: _implement,
                  decoration: const InputDecoration(
                    labelText: 'Uchwyty / hantle',
                  ),
                  items: [
                    for (final kind in [
                      LoadImplement.smallDumbbell,
                      LoadImplement.largeDumbbell,
                      LoadImplement.fixedDumbbell,
                    ])
                      DropdownMenuItem(
                        value: kind,
                        child: Text(
                          '${kind.label}${kind == LoadImplement.fixedDumbbell ? ' · 1,5 / 2 kg' : ' · ${preparationKg(kind.baseGrams / 1000)} kg'}',
                        ),
                      ),
                  ],
                  onChanged: widget.enabled
                      ? (kind) {
                          setState(() {
                            _implement = kind;
                            _implementDirty = true;
                          });
                          _emitTarget();
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  isDense: false,
                  itemHeight: null,
                  initialValue: _quantity,
                  decoration: const InputDecoration(
                    labelText: 'Ile przygotować?',
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 hantel')),
                    DropdownMenuItem(
                      value: 2,
                      child: Text('Para · 2 jednakowe hantle'),
                    ),
                  ],
                  onChanged: widget.enabled
                      ? (quantity) {
                          setState(() => _quantity = quantity!);
                          _emitTarget();
                        }
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                key: ValueKey('preparation-weight-${widget.index}'),
                controller: _weight,
                enabled: widget.enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validate,
                decoration: InputDecoration(
                  labelText: _dumbbells
                      ? 'Ciężar (kg/szt.)'
                      : 'Ciężar łączny (kg)',
                  helperText:
                      'Z uchwytem lub gryfem i talerzami. Puste pole: wybierzesz w trakcie.',
                  helperMaxLines: 4,
                  errorMaxLines: 4,
                ),
                onChanged: (_) {
                  setState(() => _weightDirty = true);
                  _emitTarget();
                },
              ),
              if (_dose.weightKg != null &&
                  !_weightDirty &&
                  offer?.last == null)
                Text(
                  'Z szablonu: ${preparationKg(_dose.weightKg!)} ${_dumbbells ? 'kg/szt.' : 'kg'}',
                ),
              if (_implement != null &&
                  kg != null &&
                  _validate(_weight.text) != null &&
                  _nearbyLoads(kg).isNotEmpty)
                Text(
                  'Dostępne w pobliżu: ${_nearbyLoads(kg).map((g) => preparationKg(g / 1000)).join(' / ')} ${_dumbbells ? 'kg/szt.' : 'kg'}. Wpisana wartość nie została zmieniona.',
                ),
              if (assembly != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assembly.implement == LoadImplement.fixedDumbbell
                            ? 'Przygotuj ${assembly.quantity}×${preparationKg(assembly.totalGramsPerImplement / 1000)} kg.'
                            : 'Na każdą stronę: ${assembly.platesPerSide.isEmpty ? 'bez talerzy' : assembly.platesPerSide.entries.map((e) => '${e.value > 1 ? '${e.value}×' : ''}${preparationKg(e.key / 1000)} kg').join(' + ')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (assembly.implement != LoadImplement.fixedDumbbell)
                        Text(
                          '${assembly.quantity} ${assembly.quantity == 1 ? 'sztuka' : 'sztuki'} · ${assembly.quantity * 2} strony ze wspólnego zapasu. Sprawdź miejsce na talerze i zaciski.',
                        ),
                    ],
                  ),
                ),
            ],
            if (actionable) ...[
              const SizedBox(height: 12),
              Text(
                'Propozycja: ${offer.targetWeightKg == null ? '' : '${preparationKg(offer.targetWeightKg!)} ${_dumbbells ? 'kg/szt.' : 'kg'} · '}${_dose.sets}×${offer.targetReps} powt.',
              ),
              Text('Zakres z opisu: $_range'),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Dlaczego taka propozycja?'),
                children: [
                  Text(offer.reason),
                  for (final e in offer.evidence)
                    Text(
                      '${Formatters.date(e.endedAt.toLocal())}: minimum ${e.reps} powt., najwyższe RPE ${e.rpe}',
                    ),
                ],
              ),
              FilledButton(
                onPressed: widget.enabled ? () => _accept(offer) : null,
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Przyjmij propozycję'),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: widget.enabled ? widget.onReplace : null,
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Zmień ćwiczenie'),
            ),
            if (widget.draft.scopeAt(widget.index) != null)
              Text(
                widget.draft.scopeAt(widget.index) ==
                        ReplacementScope.sessionOnly
                    ? 'Zmiana tylko w tym treningu.'
                    : 'Zmiana szablonu zostanie zapisana przy rozpoczęciu.',
              ),
          ],
        ),
      ),
    );
  }
}
