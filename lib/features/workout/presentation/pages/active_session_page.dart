import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/active_replacement_dialog.dart';
import '../widgets/repeat_set_panel.dart';
import '../widgets/session_recovery_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/rpe_slider.dart';
import '../../../../core/widgets/rest_timer_screen.dart';
import '../../../../core/widgets/isometric_stopwatch.dart';
import '../../../../core/models/exercise.dart';
import '../../../../core/utils/set_comparison.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../exercises/domain/exercise_catalog_metadata.dart';
import '../../providers/workout_providers.dart';
import '../../domain/interval_timer.dart';
import '../../providers/fixed_load_progression_provider.dart';
import 'interval_timer_screen.dart';
import '../../../planner/domain/structured_plan.dart';
import '../../../exercises/presentation/exercise_illustrations.dart';
import '../../../exercises/providers/exercise_variants_providers.dart';
import '../../../exercises/providers/filter_presets_providers.dart';
import '../../../exercises/presentation/widgets/own_variants.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../onboarding/providers/user_profile_provider.dart';
import '../widgets/session_finish_button.dart';
import '../widgets/session_progress_text.dart';
import '../widgets/session_delete_button.dart';
import '../widgets/set_role_selector.dart';
import '../../../../core/models/set_role.dart';
import '../widgets/guided_target_card.dart';
import '../../domain/guided_target.dart';

/// Ćwiczenia tego typu korzystają ze stopera (czas w górę) zamiast pól
/// ciężar/powtórzenia - plank, wall-sit, dead-hang itp.
///
/// Wartość 'Izometria' (nie 'Izometryczne') zgodna z realną bazą 316
/// ćwiczeń (Excel BAZA_GLOWNA, kolumna Typ) od [0.8.0].
const _typyIzometryczne = {'Izometria', 'time'};

double? _newTargetWeight(Map draft, PlanPrescription? target) =>
    ['weight', 'reps', 'seconds'].any((key) => '${draft[key] ?? ''}'.isNotEmpty)
    ? null
    : target?.weightKg;

/// Aktywna sesja treningowa: wybór ćwiczeń, logowanie serii, timer przerw.
class ActiveSessionPage extends ConsumerStatefulWidget {
  const ActiveSessionPage({super.key});

  @override
  ConsumerState<ActiveSessionPage> createState() => _ActiveSessionPageState();
}

class _ActiveSessionPageState extends ConsumerState<ActiveSessionPage> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktywny trening'),
        actions: [
          if (active.sessionId != null)
            SessionDeleteButton(sessionId: active.sessionId!, compact: true),
          if (active.isActive || active.selectedExercises.isNotEmpty)
            const SessionFinishButton(),
        ],
      ),
      body: SafeArea(
        child: !active.isActive && active.selectedExercises.isEmpty
            ? const SessionRecoveryPanel()
            : Column(
                children: [
                  if (ref.read(activeWorkoutProvider.notifier).draftSaveError
                      case final String error)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: PrimaryButton(
                      label: 'Dodaj ćwiczenie z bazy',
                      icon: Icons.add,
                      outlined: true,
                      onPressed: () => context.push('/exercises'),
                    ),
                  ),
                  Expanded(
                    child: active.repeat != null
                        ? RepeatSetPanel(
                            extras: [
                              if (active.sessionId != null)
                                SessionProgressText(
                                  sessionId: active.sessionId!,
                                  repeat: active.repeat,
                                  repeatCompleted: List<String>.from(
                                    active.draft['repeatCompleted'] as List? ??
                                        [],
                                  ),
                                ),
                              if (active.selectedExercises.any(
                                (e) => active.isExtraExercise(e.id),
                              ))
                                const Text('Dodatkowe ćwiczenia'),
                              for (final e in active.selectedExercises.where(
                                (e) => active.isExtraExercise(e.id),
                              ))
                                _ExerciseLogCard(
                                  key: ValueKey(
                                    'extra:${active.sessionSyncId}:${e.id}',
                                  ),
                                  exercise: e,
                                  extra: true,
                                ),
                            ],
                          )
                        : active.guidance != null
                        ? _guided(context, active)
                        : active.selectedExercises.isEmpty
                        ? const Center(
                            child: Text(
                              'Wybierz ćwiczenia, aby zacząć logować serie',
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              for (final ex in active.selectedExercises)
                                _ExerciseLogCard(
                                  key: ValueKey(ex.id),
                                  exercise: ex,
                                ),
                              if (active.sessionId != null)
                                SessionProgressText(
                                  sessionId: active.sessionId!,
                                ),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _guided(BuildContext context, ActiveWorkoutState active) {
    final g = active.guidance!, slot = active.currentSlot;
    final block = g.plan.blocks[slot],
        target = g.plan.blocks[slot].prescription;
    final catalog =
        ref.watch(allExercisesProvider).valueOrNull ?? active.selectedExercises;
    final exercise = catalog
        .where((e) => e.id == g.exerciseAt(slot))
        .firstOrNull;
    final n = ref.read(activeWorkoutProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.sessionId != null)
          SessionProgressText(sessionId: active.sessionId!, guidance: g),
        Text(
          '${block.section.label} • blok ${slot + 1}/${g.plan.blocks.length}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (!target.isPerSet)
          Text(
            'Cel planu: ${target.sets} serii • ${target.reps == null ? '${target.workSeconds} s' : '${target.reps} powt.'} • odpoczynek ${target.restSeconds} s',
          ),
        if (target.isPerSet) ...[
          const Text('Kolejne cele serii — wybierz cel do potwierdzenia'),
          for (var i = 0; i < target.setTargets.length; i++)
            GuidedTargetCard(
              target: target.setTargets[i],
              index: i,
              selected:
                  active.currentTarget?.targetId ==
                  target.setTargets[i].targetId,
              status:
                  g.events.any(
                    (e) =>
                        e['type'] == 'performed' &&
                        e['slotIndex'] == slot &&
                        e['targetId'] == target.setTargets[i].targetId,
                  )
                  ? 'Cel wykonany'
                  : targetConsumed(g, slot, target.setTargets[i].targetId)
                  ? 'Pominięty cel — bez wykonania'
                  : 'Bez potwierdzenia',
              onSelect: () =>
                  n.selectGuidedTarget(target.setTargets[i].targetId),
            ),
        ],
        const Text(
          'Cele są szkicem. Zapis nastąpi dopiero po potwierdzeniu wykonania.',
        ),
        if (exercise == null)
          const Text(
            'Ćwiczenie niedostępne w aktualnym katalogu — możesz pominąć blok.',
          )
        else ...[
          if (exerciseIllustrationAsset(exercise.id) case final String asset)
            Image.asset(
              asset,
              height: 180,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          if (exercise.kluczoweWskazowki.isNotEmpty)
            Text(exercise.kluczoweWskazowki.first),
          _ExerciseLogCard(
            key: ValueKey(
              '${active.sessionSyncId}:$slot:${exercise.id}${active.currentTarget == null ? '' : ':${active.currentTarget!.targetId}'}',
            ),
            exercise: exercise,
            guided: true,
          ),
        ],
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: slot == 0 ? null : () => n.moveGuided(slot - 1),
              child: const Text('Wstecz'),
            ),
            TextButton(
              onPressed: () async {
                await n.guidedEvent();
              },
              child: const Text('Pomiń'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final snapshot = ref.read(activeWorkoutProvider);
                  final g = snapshot.guidance!, slot = snapshot.currentSlot;
                  final epoch = ref
                      .read(cachedAuthWriteAuthorityProvider)
                      .epoch;
                  final dose = g.plan.blocks[slot].prescription;
                  if (dose.isPerSet
                      ? dose.setTargets.any((t) => (t.weightKg ?? 0) > 0)
                      : (dose.weightKg ?? 0) > 0) {
                    throw StateError(
                      'Zmiana z indywidualnym ciężarem wymaga edycji przed startem lub dodania osobnego ćwiczenia. Nie przenosimy kilogramów na inny ruch.',
                    );
                  }
                  // Resolve the live profile on demand. Merely displaying an
                  // active session must not introduce another database reader.
                  final profile = await ref.read(
                    userProfileStreamProvider.future,
                  );
                  if (!mounted ||
                      ref.read(cachedAuthWriteAuthorityProvider).epoch !=
                          epoch ||
                      ref.read(activeWorkoutProvider).sessionSyncId !=
                          snapshot.sessionSyncId ||
                      ref.read(activeWorkoutProvider).currentSlot != slot ||
                      jsonEncode(
                            ref.read(activeWorkoutProvider).guidance?.toJson(),
                          ) !=
                          jsonEncode(g.toJson()) ||
                      jsonEncode(ref.read(activeWorkoutProvider).draft) !=
                          jsonEncode(snapshot.draft)) {
                    throw StateError(
                      'Dane zmieniły się. Ponów wybór zamiennika.',
                    );
                  }
                  final source = ref.read(allExercisesProvider);
                  final metadata = ref.read(exerciseCatalogMetadataProvider);
                  final profileSource = ref.read(userProfileStreamProvider);
                  if (source.isLoading ||
                      source.hasError ||
                      source.valueOrNull == null ||
                      metadata.isLoading ||
                      metadata.hasError ||
                      metadata.valueOrNull == null ||
                      profileSource.isLoading ||
                      profileSource.hasError ||
                      profile == null) {
                    throw StateError(
                      'Poczekaj na aktualny katalog, klasyfikację i sprzęt profilu.',
                    );
                  }
                  final catalog = source.requireValue;
                  final engine = ref.read(exerciseFilterEngineProvider);
                  final signature = jsonEncode(g.toJson());
                  final form = jsonEncode(snapshot.draft);
                  bool currentProposal() {
                    if (!mounted) return false;
                    final now = ref.read(activeWorkoutProvider);
                    return mounted &&
                        now.isActive &&
                        now.sessionSyncId == snapshot.sessionSyncId &&
                        now.currentSlot == slot &&
                        jsonEncode(now.guidance?.toJson()) == signature &&
                        jsonEncode(now.draft) == form &&
                        ref.read(cachedAuthWriteAuthorityProvider).epoch ==
                            epoch &&
                        !ref.read(allExercisesProvider).isLoading &&
                        !ref.read(allExercisesProvider).hasError &&
                        identical(
                          ref.read(allExercisesProvider).valueOrNull,
                          catalog,
                        ) &&
                        !ref.read(userProfileStreamProvider).isLoading &&
                        !ref.read(userProfileStreamProvider).hasError &&
                        identical(
                          ref.read(userProfileStreamProvider).valueOrNull,
                          profile,
                        ) &&
                        !ref.read(exerciseCatalogMetadataProvider).isLoading &&
                        !ref.read(exerciseCatalogMetadataProvider).hasError &&
                        identical(
                          ref.read(exerciseFilterEngineProvider),
                          engine,
                        );
                  }

                  final current = StructuredPlan(
                    schemaVersion: g.plan.schemaVersion,
                    criteria: g.plan.criteria,
                    budgetSeconds: g.plan.budgetSeconds,
                    equipment: g.plan.equipment,
                    level: g.plan.level,
                    warnings: g.plan.warnings,
                    blocks: List.generate(
                      g.plan.blocks.length,
                      (i) => PlanBlock(
                        exerciseId: g.exerciseAt(i),
                        section: g.plan.blocks[i].section,
                        prescription: g.plan.blocks[i].prescription,
                      ),
                    ),
                  );
                  final replacements =
                      StructuredPlanGenerator.replacementCandidates(
                        plan: current,
                        index: slot,
                        allExercises: catalog,
                        engine: engine,
                        equipment: profile.dostepnySprzet,
                        level: g.plan.level,
                      );
                  if (replacements.isEmpty) {
                    throw StateError(
                      'Brak zgodnego zamiennika w aktualnej puli.',
                    );
                  }
                  final candidate = replacements.first;
                  final id = candidate.id;
                  if (!context.mounted) return;
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (c) => ActiveReplacementDialog(
                      description:
                          '${exercise?.nazwaPl ?? g.exerciseAt(slot)} → ${candidate.nazwaPl}. '
                          'Zgodna rodzina ruchu, mięśnie główne, metryka i jednostronność w aktualnej puli i sprzęcie profilu.',
                    ),
                  );
                  if (yes == true && mounted) {
                    if (!currentProposal()) {
                      throw StateError(
                        'Dane zmieniły się. Ponów wybór zamiennika.',
                      );
                    }
                    if (!await n.guidedEvent(
                      replacement: id,
                      discardCurrentDraft: true,
                      isCurrent: currentProposal,
                    )) {
                      throw StateError(
                        'Zamiana niedostępna podczas zapisu lub po zmianie danych. Ponów wybór.',
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              child: const Text('Zamień'),
            ),
            TextButton(
              onPressed: slot + 1 >= g.plan.blocks.length
                  ? null
                  : () => n.moveGuided(slot + 1),
              child: const Text('Następny blok'),
            ),
          ],
        ),
        if (active.selectedExercises.any(
          (e) => active.isExtraExercise(e.id),
        )) ...[
          const Divider(),
          Text(
            'Dodatkowe ćwiczenia',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'Poza planem — zapis nie zmienia celów ani bieżącego bloku.',
          ),
          for (final extra in active.selectedExercises.where(
            (e) => active.isExtraExercise(e.id),
          ))
            _ExerciseLogCard(
              key: ValueKey('extra:${active.sessionSyncId}:${extra.id}'),
              exercise: extra,
              extra: true,
            ),
        ],
      ],
    );
  }
}

class _ExerciseLogCard extends ConsumerStatefulWidget {
  const _ExerciseLogCard({
    super.key,
    required this.exercise,
    this.guided = false,
    this.extra = false,
  });
  final Exercise exercise;
  final bool guided;
  final bool extra;

  @override
  ConsumerState<_ExerciseLogCard> createState() => _ExerciseLogCardState();
}

class _ExerciseLogCardState extends ConsumerState<_ExerciseLogCard> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _secondsController = TextEditingController();
  int _rpe = 7;
  String _selectedSide = 'both';
  String _setRole = SetRole.working;
  bool _intervalBusy = false;
  bool _loadingForm = false;
  bool get _durable => widget.guided || widget.extra;
  Map<String, Object?> get _formDraft => ref
      .read(activeWorkoutProvider)
      .exerciseDraft(
        widget.exercise.id,
        extra: widget.extra,
        side: _side,
        variantId: _variantId,
      );
  String? _variantId, _variantLabel;
  int? _variantEpoch;

  ExerciseCatalogEntry? get _entry => ref
      .read(exerciseCatalogMetadataProvider)
      .asData
      ?.value
      .entryFor(widget.exercise.id);
  String get _tracking =>
      (widget.guided && ref.read(activeWorkoutProvider).currentTarget != null
          ? ref
                .read(activeWorkoutProvider)
                .guidance!
                .plan
                .blocks[ref.read(activeWorkoutProvider).currentSlot]
                .prescription
                .tracking
          : null) ??
      _entry?.tracking ??
      (_typyIzometryczne.contains(widget.exercise.typ) ? 'time' : 'reps');
  bool get _isIsometric => _tracking != 'reps';
  String? get _side =>
      _entry?.unilateral == true ||
          (widget.guided &&
              ref.read(activeWorkoutProvider).currentTarget?.side != null)
      ? _selectedSide
      : null;
  double? get _templateWeight {
    final active = ref.read(activeWorkoutProvider);
    return widget.guided
        ? active.currentTarget?.weightKg ??
              active
                  .guidance
                  ?.plan
                  .blocks[active.currentSlot]
                  .prescription
                  .weightKg
        : null;
  }

  bool get _usesWeight =>
      _templateWeight != null ||
      // A sandbag carry remains explicitly loaded when measured in seconds;
      // the prepared weight belongs to the form, not the global prescription.
      widget.exercise.sprzet.contains('Sandbag') ||
      (!_isIsometric &&
          (!widget.exercise.sprzet.contains('Masa własna') ||
              widget.exercise.sprzet.any(
                const {'Hantle', 'Sandbag'}.contains,
              )));

  double? get _enteredWeight => _usesWeight
      ? double.tryParse(_weightController.text.replaceAll(',', '.'))
      : null;
  bool get _validWeight =>
      !_usesWeight ||
      _weightController.text.isEmpty ||
      (_enteredWeight != null &&
          _enteredWeight!.isFinite &&
          _enteredWeight! >= 0);

  FixedLoadRequest get _progressionRequest {
    final parsed = double.tryParse(_weightController.text.replaceAll(',', '.'));
    return (
      exerciseId: widget.exercise.id,
      side: _side,
      prescription: widget.exercise.seriexPowtorzenia,
      tracking: _tracking,
      usesWeight: _usesWeight,
      weightKg: _usesWeight && parsed != null && parsed.isFinite
          ? parsed
          : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_weightChanged);
    _variantEpoch = ref
        .read(userCollectionsRepositoryProvider)
        .authority
        ?.epoch;
    if (_durable) {
      final state = ref.read(activeWorkoutProvider);
      if (widget.extra) {
        final selection = state.extraSelection(widget.exercise.id);
        _selectedSide = selection['side'] is String
            ? selection['side'] as String
            : 'both';
        _variantId = selection['variantId'] as String?;
        _variantLabel = selection['variantLabel'] as String?;
      }
      final selectionSide = state.extraSelection(widget.exercise.id)['side'];
      final draft = widget.extra
          ? state.exerciseDraft(
              widget.exercise.id,
              extra: true,
              side: selectionSide is String ? selectionSide : null,
              variantId: _variantId,
            )
          : state.draft;
      final target = widget.guided
          ? state.guidance!.plan.blocks[state.currentSlot].prescription
          : null;
      _setRole =
          (widget.guided ? state.currentTarget?.setRole : null) ??
          draft['setRole'] as String? ??
          SetRole.working;
      _repsController.text =
          '${draft['reps'] ?? (widget.guided ? state.currentTarget?.reps : null) ?? target?.reps ?? ''}';
      _secondsController.text =
          '${draft['seconds'] ?? (widget.guided ? state.currentTarget?.seconds : null) ?? (target == null || target.isPerSet || target.tracking == 'reps' ? '' : target.workSeconds)}';
      _weightController.text =
          '${draft['weight'] ?? _newTargetWeight(draft, target) ?? ''}';
      _selectedSide = draft['side'] is String
          ? draft['side'] as String
          : 'both';
      _rpe = draft['rpe'] is int ? (draft['rpe'] as int).clamp(1, 10) : 7;
      _variantId = draft['variantId'] as String?;
      _variantLabel = draft['variantLabel'] as String?;
      for (final c in [
        _weightController,
        _repsController,
        _secondsController,
      ]) {
        c.addListener(_saveForm);
      }
    }
  }

  void _saveForm() {
    if (!_durable || !mounted || _loadingForm) return;
    ref
        .read(activeWorkoutProvider.notifier)
        .updateExerciseDraft(
          widget.exercise.id,
          {
            'weight': _weightController.text,
            'reps': _repsController.text,
            'seconds': _secondsController.text,
            'side': _side,
            'rpe': _rpe,
            'variantId': _variantId,
            'variantLabel': _variantLabel,
            'setRole': _setRole,
          },
          extra: widget.extra,
          side: _side,
          variantId: _variantId,
        );
  }

  void _clearTimer() => ref
      .read(activeWorkoutProvider.notifier)
      .updateExerciseDraft(
        widget.exercise.id,
        {'timer': null},
        extra: widget.extra,
        side: _side,
        variantId: _variantId,
      );

  void _weightChanged() {
    if (mounted && !_loadingForm) setState(() {});
  }

  void _loadDurableForm({Map<String, dynamic>? definition}) {
    final draft = _formDraft;
    final active = ref.read(activeWorkoutProvider);
    final target = widget.guided
        ? active.guidance!.plan.blocks[active.currentSlot].prescription
        : null;
    definition ??=
        (ref.read(exerciseVariantsProvider(widget.exercise.id)).valueOrNull ??
                [])
            .where((e) => e['id'] == _variantId)
            .firstOrNull;
    _loadingForm = true;
    try {
      _weightController.text =
          '${draft['weight'] ?? (_usesWeight && definition?['loadKg'] != null ? definition!['loadKg'] : _newTargetWeight(draft, target) ?? '')}';
      _repsController.text = '${draft['reps'] ?? target?.reps ?? ''}';
      _secondsController.text =
          '${draft['seconds'] ?? (widget.guided ? active.currentTarget?.seconds : null) ?? (target == null || target.isPerSet || target.tracking == 'reps' ? '' : target.workSeconds)}';
      _setRole =
          (widget.guided ? active.currentTarget?.setRole : null) ??
          draft['setRole'] as String? ??
          SetRole.working;
      _rpe = draft['rpe'] is int ? (draft['rpe'] as int).clamp(1, 10) : 7;
      _variantLabel =
          definition?['name'] as String? ?? draft['variantLabel'] as String?;
    } finally {
      _loadingForm = false;
    }
  }

  Future<void> _selectSide(String side) async {
    if (side == _selectedSide || _intervalBusy) return;
    final active = ref.read(activeWorkoutProvider);
    final authority = ref.read(cachedAuthWriteAuthorityProvider);
    final epoch = authority.epoch, previousSide = _selectedSide;
    final variant = _variantId;
    bool current() =>
        mounted &&
        authority.epoch == epoch &&
        ref.read(activeWorkoutProvider).sessionSyncId == active.sessionSyncId &&
        ref.read(activeWorkoutProvider).currentSlot == active.currentSlot &&
        _selectedSide == previousSide &&
        _variantId == variant;
    if (_durable && _formDraft['timer'] != null) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Odrzucić niezapisany timer?'),
          content: const Text(
            'Zmiana strony usunie timer i niezapisane rundy poprzedniej strony. Nie zostaną przeniesione ani zaliczone nowej stronie.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Zachowaj'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Odrzuć timer'),
            ),
          ],
        ),
      );
      if (discard != true || !current()) return;
      _clearTimer();
    }
    if (!current()) return;
    if (_durable) _saveForm(); // old exact key, before changing identity
    if (widget.guided &&
        !ref
            .read(activeWorkoutProvider.notifier)
            .selectGuidedIdentity(
              widget.exercise.id,
              side: _entry?.unilateral == true ? side : null,
              variantId: _variantId,
              variantLabel: _variantLabel,
            )) {
      return;
    }
    setState(() {
      _selectedSide = side;
      if (_durable) _loadDurableForm();
    });
    _saveForm(); // loaded destination/defaults, never previous controllers
  }

  bool _validVariant() {
    if (_variantId == null) return true;
    if (ref.read(userCollectionsRepositoryProvider).authority?.epoch !=
        _variantEpoch) {
      return false;
    }
    final values = ref.read(exerciseVariantsProvider(widget.exercise.id));
    if (!values.isLoading &&
        !values.hasError &&
        (values.valueOrNull ?? []).any((e) => e['id'] == _variantId)) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Wariant niedostępny. Wybierz świadomie wariant bazowy lub inny własny wariant.',
        ),
      ),
    );
    return false;
  }

  Widget _variantSelector() {
    final result = ref.watch(exerciseVariantsProvider(widget.exercise.id));
    final account = ref.watch(filterPresetsAccountProvider);
    if (account.isLoading ||
        account.hasError ||
        account.valueOrNull == null ||
        ref.read(userCollectionsRepositoryProvider).authority?.epoch !=
            _variantEpoch) {
      return const Text('Wariant: Bazowy');
    }
    final items = result.isLoading || result.hasError
        ? <Map<String, dynamic>>[]
        : result.valueOrNull ?? [];
    final known = _variantId == null || items.any((e) => e['id'] == _variantId);
    final selected = items.where((e) => e['id'] == _variantId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: 'Wariant wykonania',
          child: Semantics(
            value: _variantId == null
                ? 'Bazowy'
                : selected?['name'] ?? _variantLabel ?? 'Niedostępny',
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                visualDensity: VisualDensity.standard,
              ),
              onPressed: _intervalBusy ? null : _chooseVariant,
              child: Text(
                'Wariant: ${_variantId == null ? 'Bazowy' : selected?['name'] ?? _variantLabel ?? 'Niedostępny'} ▾',
              ),
            ),
          ),
        ),
        if (!known)
          const Text(
            'Wariant usunięty lub niedostępny. Zapis zablokowany — wybierz bazowy zamiast automatycznego zastąpienia.',
          ),
        if (selected != null) Text(variantDescription(selected)),
        if (result.hasError)
          Text('Nie udało się odczytać wariantów: ${result.error}'),
      ],
    );
  }

  Future<void> _chooseVariant() async {
    final account = ref.read(filterPresetsAccountProvider).valueOrNull;
    final authority = ref.read(userCollectionsRepositoryProvider).authority;
    final epoch = authority?.epoch;
    if (account == null) return;
    bool current() =>
        mounted &&
        authority?.epoch == epoch &&
        ref.read(filterPresetsAccountProvider).valueOrNull == account;
    final id = await showDialog<String>(
      context: context,
      builder: (c) => Consumer(
        builder: (c, dialogRef, _) {
          final binding = dialogRef.watch(filterPresetsAccountProvider);
          final values = dialogRef.watch(
            exerciseVariantsProvider(widget.exercise.id),
          );
          final visible =
              !binding.isLoading &&
              !binding.hasError &&
              binding.valueOrNull == account &&
              current();
          final entries = visible && !values.isLoading && !values.hasError
              ? values.valueOrNull ?? <Map<String, dynamic>>[]
              : <Map<String, dynamic>>[];
          return AlertDialog(
            title: const Text('Wariant wykonania'),
            content: !visible
                ? const Text('Konto zostało zmienione.')
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          title: const Text('Bazowy (osobna historia)'),
                          onTap: () => Navigator.pop(c, ''),
                        ),
                        for (final e in entries)
                          ListTile(
                            title: Text(e['name'] as String),
                            subtitle: Text(variantDescription(e)),
                            onTap: () => Navigator.pop(c, e['id'] as String),
                          ),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Anuluj'),
              ),
            ],
          );
        },
      ),
    );
    if (id == null || !current()) return;
    final values = ref.read(exerciseVariantsProvider(widget.exercise.id));
    if (values.isLoading || values.hasError) return;
    await _selectVariant(id.isEmpty ? null : id, values.valueOrNull ?? []);
  }

  Future<void> _selectVariant(
    String? id,
    List<Map<String, dynamic>> items,
  ) async {
    if (id == _variantId) return;
    final selected = items.where((e) => e['id'] == id).firstOrNull;
    if (id != null && selected == null) return;
    final account = ref.read(filterPresetsAccountProvider).valueOrNull;
    final authority = ref.read(userCollectionsRepositoryProvider).authority;
    final epoch = authority?.epoch;
    final session = ref.read(activeWorkoutProvider).sessionSyncId;
    final slot = ref.read(activeWorkoutProvider).currentSlot;
    bool current() =>
        mounted &&
        ref.read(activeWorkoutProvider).sessionSyncId == session &&
        ref.read(activeWorkoutProvider).currentSlot == slot &&
        authority?.epoch == epoch &&
        ref.read(filterPresetsAccountProvider).valueOrNull == account;
    if (_weightController.text.isNotEmpty ||
        _repsController.text.isNotEmpty ||
        _secondsController.text.isNotEmpty ||
        _formDraft['timer'] != null) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Zastąpić szkic wariantu?'),
          content: const Text(
            'Zmiana wariantu zastąpi domyślne obciążenie i usunie niezapisany timer. Nie zapisze serii ani nie zmieni historii.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Zachowaj'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Zastąp'),
            ),
          ],
        ),
      );
      if (yes != true || !current()) return;
    }
    if (!current()) return;
    if (id != null &&
        !(ref.read(exerciseVariantsProvider(widget.exercise.id)).valueOrNull ??
                [])
            .any((e) => e['id'] == id)) {
      return;
    }
    if (_durable) _saveForm();
    if (_durable) _clearTimer();
    if (widget.guided &&
        !ref
            .read(activeWorkoutProvider.notifier)
            .selectGuidedIdentity(
              widget.exercise.id,
              side: _side,
              variantId: id,
              variantLabel: selected?['name'] as String?,
            )) {
      return;
    }
    setState(() {
      _variantId = id;
      _variantLabel = selected?['name'] as String?;
      if (_durable) {
        _loadDurableForm(definition: selected);
      } else {
        _weightController.text = _usesWeight && selected?['loadKg'] != null
            ? '${selected!['loadKg']}'
            : '';
      }
    });
    _saveForm();
  }

  Future<void> _acceptProgression(
    FixedLoadRequest request,
    FixedLoadOffer offer,
  ) async {
    final variant = _variantId;
    bool owns() =>
        mounted && _progressionRequest == request && _variantId == variant;
    if (!owns() || !await offer.isCurrent() || !owns()) return;
    if (!mounted) return;
    final target = offer.suggestion.target;
    if (target == null) return;
    // Only reps are offered until timed configuration is persisted/comparable.
    final draft = _repsController.text;
    if (draft.isNotEmpty && draft != '$target') {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Zastąpić wpisany cel?'),
          content: Text(
            'Wpisano: $draft. Propozycja: $target powtórzeń. Seria nie zostanie zapisana.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Zachowaj'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Zastąp'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    if (!owns() ||
        _repsController.text != draft ||
        !await offer.isCurrent() ||
        !owns() ||
        _repsController.text != draft) {
      return;
    }
    _repsController.text = '$target';
  }

  Widget _progression() {
    final request = _progressionRequest;
    final result = _variantId == null
        ? ref.watch(fixedLoadProgressionProvider(request))
        : ref.watch(variantFixedLoadProgressionProvider((request, _variantId)));
    // Do not keep previous-account/side data during refresh/loading/errors.
    final offer = result.isLoading || result.hasError
        ? null
        : result.asData?.value;
    if (offer == null) {
      return const Text(
        'Możliwy następny cel: brak dostępnej, wiarygodnej historii.',
      );
    }
    final suggestion = offer.suggestion;
    final last = offer.lastSet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (last == null)
          const Text(
            'Pierwszy raz - bez porównania',
            style: TextStyle(color: Colors.grey),
          )
        else
          Text(
            _isIsometric
                ? 'Ostatnio: ${last.czasSekund ?? '-'} s (RPE ${last.rpe ?? '-'})'
                : 'Ostatnio: ${last.ciezarKg == null ? '' : '${last.ciezarKg} kg × '}${last.powtorzenia ?? '-'} powt. (RPE ${last.rpe ?? '-'})',
            style: const TextStyle(color: FitBirekColors.accent),
          ),
        const Text(
          'Możliwy następny cel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(suggestion.reason),
        if (suggestion.target != null) ...[
          Text(
            '${suggestion.target} powt. • ${suggestion.weightKg == null ? 'masa własna / bez dodatkowego ciężaru' : '${suggestion.weightKg} kg (bez zmian)'} • ${setSideLabel(request.side)}',
          ),
          for (final e in suggestion.evidence)
            Text(
              'Trening ${e.endedAt.toLocal().toString().split(' ').first}: minimum ${e.reps} powt., najwyższe RPE ${e.rpe} (sesja ${e.sessionId}).',
            ),
          const Text(
            'To opcja na najbliższą sesję, nie obowiązek. Możesz ją odrzucić. Przyjęcie zmienia tylko pole powtórzeń, nie zapisuje serii.',
          ),
          TextButton(
            onPressed: () => _acceptProgression(request, offer),
            child: const Text('Przyjmij cel'),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _weightController.removeListener(_weightChanged);
    _weightController.dispose();
    _repsController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  /// Wspólna logika po zalogowaniu serii: powiadomienie o PR + auto-timer przerwy.
  Future<void> _afterLogSet(bool isPr) async {
    if (!mounted) return;
    final workout = ref.read(activeWorkoutProvider);
    if (!workout.isActive || workout.loggedSets.isEmpty) return;
    final saved = workout.loggedSets.last;
    if (isPr) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Nowy rekord w ${widget.exercise.nazwaPl} • ${setSideLabel(saved.side)}!',
          ),
          backgroundColor: FitBirekColors.accent,
        ),
      );
    }
    setState(() {});
    // Automatyczny timer przerwy po zalogowanej serii - domyślnie 90s,
    // użytkownik może zmienić na 60/120/180s lub własny czas na ekranie timera.
    if (mounted && !_durable) {
      await showRestTimer(context, initialSeconds: 90);
    }
  }

  Future<void> _startIsometricStopwatch() async {
    if (!_validVariant()) return;
    if (!_validWeight) {
      _invalidSet();
      return;
    }
    final weight = _enteredWeight;
    final side = _side;
    final variantId = _variantId, variantLabel = _variantLabel;
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final origin = _durable
        ? notifier.captureInterval(
            exercise: widget.exercise,
            side: side,
            variantId: variantId,
            variantLabel: variantLabel,
            extra: widget.extra,
            weightKg: weight,
            setRole: _setRole,
          )
        : null;
    if (_durable && origin == null) return;
    final seconds = await showIsometricStopwatch(
      context,
      label: widget.exercise.nazwaPl,
    );
    if (seconds == null || seconds <= 0) return;
    if (_durable && !notifier.isIntervalCurrent(origin!)) return;
    await _recordSet(
      weightKg: weight,
      seconds: seconds,
      side: side,
      variantId: variantId,
      variantLabel: variantLabel,
    );
  }

  Future<void> _startIntervals() async {
    if (_intervalBusy) return;
    if (!_validVariant()) return;
    if (!_validWeight) {
      _invalidSet();
      return;
    }
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final origin = notifier.captureInterval(
      exercise: widget.exercise,
      side: _side,
      rpe: _rpe,
      variantId: _variantId,
      variantLabel: _variantLabel,
      extra: widget.extra,
      weightKg: _enteredWeight,
      setRole: _setRole,
    );
    if (origin == null) return;
    setState(() => _intervalBusy = true);
    try {
      final result = await Navigator.of(context).push<List<IntervalRound>>(
        MaterialPageRoute(
          builder: (_) => IntervalTimerScreen(
            singleRound: origin.targetId != null,
            initialWorkSeconds: origin.targetId == null
                ? null
                : ref.read(activeWorkoutProvider).currentTarget?.seconds,
            label: '${widget.exercise.nazwaPl} • ${setSideLabel(origin.side)}',
            isValid: () => mounted && notifier.isIntervalCurrent(origin),
            checkpoint: _durable && _formDraft['timer'] is Map
                ? Map<String, dynamic>.from(_formDraft['timer'] as Map)
                : null,
            onCheckpoint: !_durable
                ? null
                : (checkpoint) {
                    if (mounted &&
                        notifier.isIntervalCheckpointCurrent(origin)) {
                      _saveForm();
                      notifier.updateIntervalCheckpoint(origin, checkpoint);
                    }
                  },
          ),
        ),
      );
      if (!mounted || result == null) return;
      final saved = await notifier.saveIntervalRounds(
        origin,
        result,
        guard: () => mounted,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Zapisano wykonane rundy.'
                : 'Nie zapisano rund: sesja lub konto są nieaktualne.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nie udało się zapisać rund. Wyniki nie zostały zapisane.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _intervalBusy = false);
    }
  }

  Future<void> _logStrengthSet() async {
    if (!_validVariant()) return;
    final weight = _usesWeight
        ? double.tryParse(_weightController.text.replaceAll(',', '.'))
        : null;
    final reps = int.tryParse(_repsController.text);
    if (reps == null ||
        reps <= 0 ||
        (_usesWeight &&
            _weightController.text.isNotEmpty &&
            (weight == null || !weight.isFinite || weight < 0))) {
      _invalidSet();
      return;
    }
    await _recordSet(
      weightKg: weight,
      reps: reps,
      side: _side,
      variantId: _variantId,
      variantLabel: _variantLabel,
    );
  }

  void _invalidSet() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Podaj dodatnią liczbę powtórzeń lub sekund; ciężar musi być nieujemny.',
      ),
    ),
  );

  Future<void> _logTimedSet() async {
    if (!_validVariant()) return;
    final seconds = int.tryParse(_secondsController.text);
    if (seconds == null || seconds <= 0 || !_validWeight) {
      _invalidSet();
      return;
    }
    await _recordSet(
      weightKg: _enteredWeight,
      seconds: seconds,
      side: _side,
      variantId: _variantId,
      variantLabel: _variantLabel,
    );
  }

  Future<void> _recordSet({
    double? weightKg,
    int? reps,
    int? seconds,
    String? side,
    required String? variantId,
    required String? variantLabel,
  }) async {
    try {
      final before = ref.read(activeWorkoutProvider).loggedSets.length;
      final isPr = await ref
          .read(activeWorkoutProvider.notifier)
          .logSet(
            exercise: widget.exercise,
            weightKg: weightKg,
            reps: reps,
            seconds: seconds,
            side: side,
            rpe: _rpe,
            variantId: variantId,
            variantLabel: variantLabel,
            extra: widget.extra,
            setRole: _setRole,
            guidanceTargetId: widget.guided
                ? ref.read(activeWorkoutProvider).currentTarget?.targetId
                : null,
          );
      if (mounted &&
          ref.read(activeWorkoutProvider).loggedSets.length == before) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nie zapisano serii. Sprawdź wybrany cel, jego stronę i aktualność sesji.',
            ),
          ),
        );
        return;
      }
      await _afterLogSet(isPr);
    } on StateError catch (error) {
      // A definition can be removed by pull between the selector and SQLite's
      // transactional proof. Never fall back to a base set silently.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading/error/missing metadata intentionally falls back to the legacy type.
    ref.watch(exerciseCatalogMetadataProvider);
    final loggedForThis = ref
        .watch(activeWorkoutProvider)
        .loggedSets
        .where(
          (s) =>
              s.exerciseId == widget.exercise.id &&
              s.side == _side &&
              s.variantId == _variantId,
        )
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.nazwaPl,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            _variantSelector(),
            if (widget.guided &&
                ref.watch(activeWorkoutProvider).currentTarget != null)
              Text('Rodzaj celu: ${SetRole.label(_setRole)}')
            else
              SetRoleSelector(
                value: _setRole,
                onChanged: _intervalBusy
                    ? null
                    : (value) => setState(() {
                        _setRole = value;
                        _saveForm();
                      }),
              ),
            if (widget.guided &&
                ref.watch(activeWorkoutProvider).currentTarget?.side != null)
              Text(
                'Cel potwierdza wyłącznie strona: ${setSideLabel(ref.watch(activeWorkoutProvider).currentTarget!.side)}. Lewa i prawa osobno nie potwierdzają celu Obie.',
              ),
            if (_entry?.unilateral == true) ...[
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'left', label: Text('Lewa')),
                  ButtonSegment(value: 'right', label: Text('Prawa')),
                  ButtonSegment(value: 'both', label: Text('Obie')),
                ],
                selected: {_selectedSide},
                onSelectionChanged: _intervalBusy
                    ? null
                    : (value) => _selectSide(value.single),
              ),
              const Text(
                'PR i porównania są liczone osobno dla każdej strony. 1RM tylko dla kg + powtórzeń.',
              ),
            ],
            if (loggedForThis.isNotEmpty &&
                loggedForThis.last.comparison != null)
              Text(
                'Zmiana względem poprzedniej serii • ${setSideLabel(_side)}: ${loggedForThis.last.comparison}',
              ),
            if (_setRole != SetRole.warmup)
              _progression()
            else
              const Text('Rozgrzewkowa — bez PR i propozycji progresji.'),
            const SizedBox(height: 12),
            if (_isIsometric) ...[
              if (_usesWeight)
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ciężar (kg)'),
                ),
              if (_tracking == 'rounds' ||
                  (widget.guided &&
                      ref.watch(activeWorkoutProvider).currentTarget?.seconds !=
                          null) ||
                  widget.extra)
                PrimaryButton(
                  label: _intervalBusy
                      ? 'Interwały w toku…'
                      : widget.guided &&
                            ref.watch(activeWorkoutProvider).currentTarget !=
                                null
                      ? 'Timer celu (1 seria)'
                      : 'Timer interwałów',
                  icon: Icons.av_timer,
                  onPressed:
                      _intervalBusy ||
                          (widget.guided &&
                              ref
                                  .watch(activeWorkoutProvider)
                                  .currentTargetConsumed)
                      ? null
                      : _startIntervals,
                ),
              TextField(
                controller: _secondsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _tracking == 'rounds'
                      ? 'Czas pracy rundy (s)'
                      : 'Czas (s)',
                ),
              ),
              PrimaryButton(
                label: _tracking == 'rounds'
                    ? 'Zapisz rundę (${loggedForThis.length})'
                    : 'Zapisz czas (${loggedForThis.length})',
                icon: Icons.check,
                onPressed:
                    widget.guided &&
                        ref.watch(activeWorkoutProvider).currentTargetConsumed
                    ? null
                    : _logTimedSet,
              ),
              RpeSlider(
                value: _rpe,
                onChanged: (v) => setState(() {
                  _rpe = v;
                  _saveForm();
                }),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Start stopera (${loggedForThis.length})',
                icon: Icons.timer_outlined,
                onPressed:
                    widget.guided &&
                        ref.watch(activeWorkoutProvider).currentTargetConsumed
                    ? null
                    : _startIsometricStopwatch,
              ),
            ] else ...[
              Row(
                children: [
                  if (_usesWeight)
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ciężar (kg)',
                        ),
                      ),
                    ),
                  if (_usesWeight) const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Powtórzenia',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RpeSlider(
                value: _rpe,
                onChanged: (v) => setState(() {
                  _rpe = v;
                  _saveForm();
                }),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Seria wykonana (${loggedForThis.length})',
                icon: Icons.check,
                onPressed:
                    widget.guided &&
                        ref.watch(activeWorkoutProvider).currentTargetConsumed
                    ? null
                    : _logStrengthSet,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
