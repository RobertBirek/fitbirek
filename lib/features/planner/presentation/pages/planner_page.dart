import 'package:flutter/material.dart';
import '../../../../core/widgets/content_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants.dart';
import '../../../../core/models/exercise.dart';
import '../../../../core/models/user_profile.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../exercises/domain/filter_preset.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../onboarding/providers/user_profile_provider.dart';
import '../../domain/structured_plan.dart';
import '../../domain/plan_explanation.dart';
import '../../providers/planner_providers.dart';
import '../widgets/plan_edit_dialog.dart';

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});
  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  int _minutes = 45;
  String _level = 'Średni';
  late ExerciseFilters _criteria;
  StructuredPlan? _plan;
  int? _previewEpoch;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _criteria = FilterPreset.decodeFilters(
      FilterPreset.encodeFilters(
        ref.read(plannerEntryCriteriaProvider) ?? const ExerciseFilters(),
      ),
    );
    final entry = ref.read(plannerEntryCriteriaProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(ref.read(plannerEntryCriteriaProvider), entry)) {
        ref.read(plannerEntryCriteriaProvider.notifier).state = null;
      }
    });
  }

  void _preview(StructuredPlan plan) {
    setState(() {
      _plan = plan;
      _criteria = plan.criteria;
      _minutes = plan.budgetSeconds ~/ 60;
      _level = plan.level;
      _previewEpoch = ref.read(cachedAuthWriteAuthorityProvider).epoch;
      _message = null;
    });
  }

  List<Exercise> _pool(UserProfile profile, ExerciseFilters criteria) {
    final currentProfile = ref.read(userProfileStreamProvider);
    if (currentProfile.isLoading ||
        currentProfile.hasError ||
        !identical(currentProfile.valueOrNull, profile)) {
      throw StateError(
        'Poczekaj na aktualny profil lub ponów ładowanie. Poprzednia wartość nie uprawnia do zmiany planu.',
      );
    }
    final source = ref.read(allExercisesProvider);
    final metadata = ref.read(exerciseCatalogMetadataProvider);
    if (source.isLoading ||
        source.hasError ||
        source.valueOrNull == null ||
        metadata.isLoading ||
        metadata.hasError ||
        metadata.valueOrNull == null) {
      throw StateError(
        'Poczekaj na ćwiczenia i klasyfikację lub ponów ładowanie. Kryteriów nie pominięto.',
      );
    }
    return StructuredPlanGenerator.candidates(
      allExercises: source.requireValue,
      engine: ref.read(exerciseFilterEngineProvider),
      criteria: criteria,
      equipment: profile.dostepnySprzet,
      level: _level,
    );
  }

  Future<void> _act(UserProfile profile, {required bool start}) async {
    if (_busy) return;
    final plan = _plan!;
    final epoch = ref.read(cachedAuthWriteAuthorityProvider).epoch;
    if (_previewEpoch != epoch) {
      setState(() => _message = 'Konto zmieniło się. Otwórz planner ponownie.');
      return;
    }
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(start ? 'Rozpocząć trening?' : 'Zapisać plan?'),
          content: Text(
            'Czas ESTYMOWANY: ${plan.estimatedSeconds} s. Cele są widoczne w podglądzie; '
            'serie zapisujesz samodzielnie w sesji. Nie jest to pomiar czasu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Potwierdź'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      if (ref.read(cachedAuthWriteAuthorityProvider).epoch != epoch) {
        throw StateError('Konto zmieniło się.');
      }
      // Re-evaluate against current catalog/favorites/profile. Never silently drop IDs.
      final currentProfile = ref.read(userProfileStreamProvider).valueOrNull;
      if (currentProfile == null) {
        throw StateError('Poczekaj na aktualny profil.');
      }
      final pool = {
        for (final e in _pool(currentProfile, plan.criteria)) e.id: e,
      };
      if (plan.exerciseIds.any((id) => !pool.containsKey(id))) {
        throw StateError(
          'Ćwiczenie nie jest już dostępne w aktywnej puli. Wygeneruj plan ponownie.',
        );
      }
      final workflow = ref.read(plannerWorkflowProvider);
      if (start) {
        await workflow.start(
          plan.exerciseIds.map((id) => pool[id]!).toList(),
          plan: plan,
        );
        if (mounted &&
            ref.read(cachedAuthWriteAuthorityProvider).epoch == epoch) {
          context.push('/workout/session');
        }
      } else {
        await workflow.save(
          plan,
          name: 'Plan ${profile.cel.label}',
          goal: profile.cel.name,
        );
        if (mounted) setState(() => _message = 'Plan zapisany.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePlan(int id, String name) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Usunąć plan „$name”?'),
          content: const Text('Tej operacji nie można cofnąć.'),
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
      await ref.read(plannerRepositoryProvider).deletePlan(id);
      if (mounted) setState(() => _message = 'Plan usunięty.');
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Nie udało się usunąć planu. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _constraints(ExerciseFilters f) {
    final engine = ref.watch(exerciseFilterEngineProvider);
    final labels = [
      ...f.styles.map(engine.metadata.styleLabel),
      ...f.muscles.map(engine.muscleLabel),
      ...f.conditions.map(engine.metadata.conditionLabel),
      ...f.positions.map(engine.metadata.positionLabel),
      ...f.sprzet,
      ...f.partie,
      ...f.typy,
      ...f.poziomy,
      if (f.tylkoUlubione) 'Tylko ulubione',
      if (f.query.trim().isNotEmpty) 'Szukaj: ${f.query}',
    ];
    return Text(
      'Ograniczenia: ${labels.isEmpty ? "Brak filtrów katalogu" : labels.join(" • ")}. '
      'Dodatkowo cały sprzęt z profilu i poziom ≤ $_level.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileStreamProvider);
    ref.watch(allExercisesProvider);
    final metadata = ref.watch(exerciseCatalogMetadataProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generator planu'),
        actions: [
          IconButton(
            tooltip: 'Rytm tygodnia',
            onPressed: () => context.push('/schedule'),
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: SafeArea(
        child: ContentLayout(
          maxWidth: 640,
          child: profile.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Błąd profilu: $e'),
            data: (p) => SingleChildScrollView(
              padding: ContentLayout.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p == null)
                    const Text(
                      'Dokończ onboarding, aby generować i uruchamiać plan.',
                    ),
                  _constraints(_criteria),
                  if (p != null)
                    Text('Sprzęt z profilu: ${p.dostepnySprzet.join(", ")}'),
                  const Text('Poziom'),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.poziomyOpcje
                        .map(
                          (v) => ChoiceChip(
                            label: Text(v),
                            selected: _level == v,
                            onSelected: _busy
                                ? null
                                : (_) => setState(() {
                                    _level = v;
                                    _plan = null;
                                  }),
                          ),
                        )
                        .toList(),
                  ),
                  Text('Budżet: $_minutes min'),
                  Slider(
                    value: _minutes.toDouble(),
                    min: 5,
                    max: 90,
                    divisions: 85,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                            _minutes = v.round();
                            _plan = null;
                          }),
                  ),
                  if (metadata.valueOrNull == null) ...[
                    const Text(
                      'Poczekaj na klasyfikację lub ponów jej ładowanie. Filtry nie zostaną pominięte.',
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(exerciseCatalogMetadataProvider),
                      child: const Text('Ponów klasyfikację'),
                    ),
                  ],
                  FilledButton(
                    onPressed: p == null || _busy
                        ? null
                        : () {
                            try {
                              _pool(p, _criteria);
                              _preview(
                                StructuredPlanGenerator.generate(
                                  allExercises: ref
                                      .read(allExercisesProvider)
                                      .requireValue,
                                  engine: ref.read(
                                    exerciseFilterEngineProvider,
                                  ),
                                  criteria: _criteria,
                                  equipment: p.dostepnySprzet,
                                  level: _level,
                                  minutes: _minutes,
                                ),
                              );
                            } catch (e) {
                              setState(() => _message = '$e');
                            }
                          },
                    child: const Text('Wygeneruj plan'),
                  ),
                  if (_message != null)
                    Text(_message!, key: const Key('planner-message')),
                  if (_plan != null) ..._result(p),
                  const SizedBox(height: 24),
                  const Text('Zapisane plany'),
                  ref
                      .watch(savedPlansProvider)
                      .when(
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Błąd planów: $e'),
                        data: (plans) => Column(
                          children: plans
                              .map(
                                (saved) => ListTile(
                                  title: Text(saved.nazwa),
                                  subtitle: Text(
                                    saved.structureError ??
                                        (saved.structure == null
                                            ? 'Stary plan — lista ćwiczeń bez sekcji i celów.'
                                            : '${saved.cwiczeniaIds.length} ćwiczeń • zapisane sekcje i cele'),
                                  ),
                                  onTap:
                                      _busy ||
                                          saved.isUnavailable ||
                                          saved.structure == null
                                      ? null
                                      : () => _preview(saved.structure!),
                                  trailing: IconButton(
                                    tooltip: 'Usuń plan',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: _busy
                                        ? null
                                        : () => _deletePlan(
                                            saved.id,
                                            saved.nazwa,
                                          ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _result(UserProfile? profile) {
    final plan = _plan!;
    final all = {
      for (final e
          in ref.watch(allExercisesProvider).valueOrNull ?? <Exercise>[])
        e.id: e,
    };
    return [
      Text(
        'Czas ESTYMOWANY: ${plan.estimatedSeconds ~/ 60} min ${plan.estimatedSeconds % 60} s '
        '/ budżet ${plan.budgetSeconds ~/ 60} min',
      ),
      const Text(
        'Powtórzenia: szacunek 3 s/powt. Praca na serię obejmuje obie strony, jeśli jednostronne. '
        'Przerwy tylko między seriami; przejście liczone po każdym bloku. Cele nie zapisują serii automatycznie.',
      ),
      ...plan.warnings.map((w) => Text('Uwaga: $w')),
      for (final section in PlanSection.values) ...[
        Text(section.label, style: Theme.of(context).textTheme.titleMedium),
        if (!plan.blocks.any((b) => b.section == section))
          const Text('Brak — nie poszerzono aktywnej puli.'),
        for (var i = 0; i < plan.blocks.length; i++)
          if (plan.blocks[i].section == section)
            _block(plan.blocks[i], i, all, profile),
      ],
      if (plan.blocks.isNotEmpty && profile != null) ...[
        OutlinedButton(
          onPressed: _busy ? null : () => _act(profile, start: false),
          child: const Text('Zapisz plan'),
        ),
        FilledButton(
          onPressed: _busy ? null : () => _act(profile, start: true),
          child: const Text('Rozpocznij trening'),
        ),
      ],
    ];
  }

  Widget _block(
    PlanBlock b,
    int index,
    Map<String, Exercise> all,
    UserProfile? profile,
  ) {
    final p = b.prescription;
    return Card(
      child: ListTile(
        title: Text(
          all[b.exerciseId]?.nazwaPl ?? 'Niedostępne: ${b.exerciseId}',
        ),
        subtitle: Text(
          '${p.sets} serie × ${p.reps == null ? "${p.workSeconds} s (${p.tracking})" : "${p.reps} powt."} '
          '• praca ${p.workSeconds} s/serię • przerwa ${p.restSeconds} s • przejście ${p.transitionSeconds} s '
          '• razem ${p.totalSeconds} s',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edytuj przerwę',
              icon: const Icon(Icons.timer_outlined),
              onPressed: profile == null || _busy
                  ? null
                  : () => _editRest(index, profile),
            ),
            IconButton(
              tooltip: 'Dlaczego to ćwiczenie?',
              icon: const Icon(Icons.info_outline),
              onPressed: _busy
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Dlaczego to ćwiczenie?'),
                        content: SingleChildScrollView(
                          child: Text(
                            PlanExplanation.forBlock(
                              plan: _plan!,
                              index: index,
                              allExercises: all.values.toList(),
                              equipment: profile?.dostepnySprzet,
                              engine: ref.read(exerciseFilterEngineProvider),
                            ).join('\n\n'),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Zamknij'),
                          ),
                        ],
                      ),
                    ),
            ),
            IconButton(
              tooltip: 'Wymień ćwiczenie',
              icon: const Icon(Icons.swap_horiz),
              onPressed: profile == null || _busy
                  ? null
                  : () => _replace(index, profile),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _replace(int index, UserProfile profile) async {
    final plan = _plan!;
    final epoch = ref.read(cachedAuthWriteAuthorityProvider).epoch;
    try {
      if (_previewEpoch != epoch) {
        throw StateError('Konto zmieniło się. Otwórz planner ponownie.');
      }
      _pool(profile, plan.criteria);
      final catalog = ref.read(allExercisesProvider).requireValue;
      final engine = ref.read(exerciseFilterEngineProvider);
      final replacement = StructuredPlanGenerator.replace(
        plan: plan,
        index: index,
        allExercises: catalog,
        engine: engine,
        equipment: profile.dostepnySprzet,
        level: _level,
        allowBudgetIncrease: true,
      );
      if (replacement == null) {
        throw StateError(
          'Brak zgodnego zamiennika w aktualnej puli lub w limicie 90 min.',
        );
      }
      final names = {for (final e in catalog) e.id: e.nazwaPl};
      final accepted = await showDialog<StructuredPlan>(
        context: context,
        builder: (context) => PlanEditDialog(
          plan: plan,
          title:
              'Zamień ${names[plan.blocks[index].exerciseId] ?? plan.blocks[index].exerciseId} na ${names[replacement.blocks[index].exerciseId]}?',
          acceptLabel: 'Zamień',
          propose: (_) => replacement,
          explain: (_) => PlanExplanation.forReplacement(
            plan: plan,
            replacement: replacement,
            index: index,
            allExercises: catalog,
            engine: engine,
            equipment: profile.dostepnySprzet,
          ).join('\n\n'),
        ),
      );
      if (accepted == null || !mounted) return;
      // The explanation must still describe exactly the data accepted by the
      // user. A changed catalog/profile/account requires a fresh proposal.
      if (!identical(_plan, plan) ||
          ref.read(cachedAuthWriteAuthorityProvider).epoch != epoch ||
          !identical(
            ref.read(userProfileStreamProvider).valueOrNull,
            profile,
          ) ||
          !identical(ref.read(allExercisesProvider).valueOrNull, catalog) ||
          !identical(ref.read(exerciseFilterEngineProvider), engine)) {
        throw StateError('Dane zmieniły się. Ponów wybór zamiennika.');
      }
      _pool(profile, plan.criteria);
      _preview(replacement);
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    }
  }

  Future<void> _editRest(int index, UserProfile profile) async {
    final plan = _plan!;
    final epoch = ref.read(cachedAuthWriteAuthorityProvider).epoch;
    try {
      if (_previewEpoch != epoch) {
        throw StateError('Konto zmieniło się. Otwórz planner ponownie.');
      }
      _pool(profile, plan.criteria);
      final catalog = ref.read(allExercisesProvider).requireValue;
      final engine = ref.read(exerciseFilterEngineProvider);
      final accepted = await showDialog<StructuredPlan>(
        context: context,
        builder: (_) => PlanEditDialog(
          plan: plan,
          title: 'Edytuj przerwę',
          acceptLabel: 'Zastosuj',
          initialRest: plan.blocks[index].prescription.restSeconds,
          propose: (rest) => StructuredPlanGenerator.withRest(
            plan: plan,
            index: index,
            restSeconds: rest!,
            allowBudgetIncrease: true,
          ),
        ),
      );
      if (accepted == null || !mounted) return;
      if (!identical(_plan, plan) ||
          ref.read(cachedAuthWriteAuthorityProvider).epoch != epoch ||
          !identical(
            ref.read(userProfileStreamProvider).valueOrNull,
            profile,
          ) ||
          !identical(ref.read(allExercisesProvider).valueOrNull, catalog) ||
          !identical(ref.read(exerciseFilterEngineProvider), engine)) {
        throw StateError('Dane zmieniły się. Ponów edycję przerwy.');
      }
      _pool(profile, plan.criteria);
      _preview(accepted);
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    }
  }
}
