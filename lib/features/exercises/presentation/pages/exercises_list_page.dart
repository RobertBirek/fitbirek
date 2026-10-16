import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../providers/exercises_providers.dart';
import '../../providers/filter_presets_providers.dart';
import '../../data/filter_presets_repository.dart';
import '../../domain/filter_preset.dart';
import '../../domain/exercise_catalog_metadata.dart';
import '../../../planner/providers/planner_providers.dart';

class ExercisesListPage extends ConsumerStatefulWidget {
  const ExercisesListPage({super.key});
  @override
  ConsumerState<ExercisesListPage> createState() => _ExercisesListPageState();
}

class _ExercisesListPageState extends ConsumerState<ExercisesListPage> {
  late final TextEditingController _search;
  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(exerciseFiltersProvider).query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(exerciseFiltersProvider, (_, next) {
      if (_search.text != next.query) _search.text = next.query;
    });
    final source = ref.watch(allExercisesProvider);
    final catalog = ref.watch(exerciseCatalogMetadataProvider);
    final exercises = ref.watch(filteredExercisesProvider);
    final filters = ref.watch(exerciseFiltersProvider);
    final executionVerified = ref
        .watch(exerciseFilterEngineProvider)
        .executionFiltersVerified(filters);
    final presets = ref.watch(filterPresetsProvider);
    final presetsController = ref.watch(filterPresetsProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baza ćwiczeń'),
        actions: [
          IconButton(
            tooltip: 'Zapisane filtry',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: presetsController.accountId == null || presets.isLoading
                ? null
                : () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _PresetsDialog(controller: presetsController),
                    );
                  },
          ),
          IconButton(
            tooltip: 'Filtry',
            icon: Badge(
              isLabelVisible: filters.activeCount > 0,
              label: Text('${filters.activeCount}'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const _FilterSheet(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Szukaj ćwiczenia...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: filters.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Wyczyść wyszukiwanie',
                          icon: const Icon(Icons.clear),
                          onPressed: () => ref
                              .read(exerciseFiltersProvider.notifier)
                              .update((f) => f.copyWith(query: '')),
                        ),
                ),
                onChanged: (v) => ref
                    .read(exerciseFiltersProvider.notifier)
                    .update((f) => f.copyWith(query: v)),
              ),
            ),
            if (!filters.isEmpty) const _ActiveFilters(),
            TextButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ułóż trening z tych ćwiczeń'),
              onPressed: () {
                ref
                    .read(plannerEntryCriteriaProvider.notifier)
                    .state = FilterPreset.decodeFilters(
                  FilterPreset.encodeFilters(filters),
                );
                context.push('/settings/planner');
              },
            ),
            if (catalog.isLoading)
              const LinearProgressIndicator(
                semanticsLabel: 'Ładowanie klasyfikacji',
              ),
            if (!executionVerified)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Nie można zweryfikować wybranych warunków lub pozycji — dane niedostępne albo niezweryfikowane. Kryteriów nie pominięto; wyniki nie są poszerzane.',
                ),
              ),
            if (filters.hasExecutionFilters && executionVerified)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Wyniki obejmują tylko ćwiczenia z odpowiednimi oznaczeniami. Ćwiczenia bez tych danych, także własne, są pomijane.',
                ),
              ),
            if (catalog.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        catalog.valueOrNull == null
                            ? 'Klasyfikacja niedostępna — filtry stylu i mięśni są czasowo pomijane. Wybory zachowano.'
                            : 'Klasyfikacja niedostępna do odświeżenia — używane są ostatnie dane.',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ponów klasyfikację',
                      onPressed: () =>
                          ref.invalidate(exerciseCatalogMetadataProvider),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            if (catalog.isLoading &&
                catalog.valueOrNull == null &&
                (filters.styles.isNotEmpty || filters.muscles.isNotEmpty))
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Ładowanie klasyfikacji — filtry stylu i mięśni są czasowo pomijane. Wybory zachowano.',
                ),
              ),
            Expanded(
              child: source.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Nie udało się wczytać ćwiczeń'),
                      TextButton(
                        onPressed: () => ref.invalidate(allExercisesProvider),
                        child: const Text('Spróbuj ponownie'),
                      ),
                    ],
                  ),
                ),
                data: (_) => catalog.isLoading && exercises.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('Wyniki: ${exercises.length}'),
                          ),
                          Expanded(
                            child: exercises.isEmpty
                                ? const EmptyState(
                                    icon: Icons.search_off,
                                    title: 'Brak wyników',
                                    subtitle:
                                        'Zmień filtry lub wyszukiwaną frazę',
                                  )
                                : ListView.separated(
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    itemCount: exercises.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final ex = exercises[index];
                                      return Card(
                                        child: ListTile(
                                          title: Text(
                                            ex.nazwaPl,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${ex.partiaGlowna} • ${ex.poziom}',
                                          ),
                                          trailing: IconButton(
                                            tooltip: ex.ulubione
                                                ? 'Usuń z ulubionych'
                                                : 'Dodaj do ulubionych',
                                            icon: Icon(
                                              ex.ulubione
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: ex.ulubione
                                                  ? FitBirekColors.accent
                                                  : Colors.grey,
                                            ),
                                            onPressed: () => ref
                                                .read(
                                                  exercisesRepositoryProvider,
                                                )
                                                .toggleFavorite(
                                                  ex.id,
                                                  !ex.ulubione,
                                                ),
                                          ),
                                          onTap: () => context.push(
                                            '/exercises/${ex.id}',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetsDialog extends ConsumerStatefulWidget {
  const _PresetsDialog({required this.controller});
  final FilterPresetsController controller;
  @override
  ConsumerState<_PresetsDialog> createState() => _PresetsDialogState();
}

class _PresetsDialogState extends ConsumerState<_PresetsDialog> {
  final _name = TextEditingController();
  String? _error;
  bool _busy = false;
  bool get _current =>
      mounted &&
      identical(ref.read(filterPresetsProvider.notifier), widget.controller);
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final filters = ref.read(exerciseFiltersProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final name = FilterPreset.validateName(_name.text);
      try {
        await widget.controller.save(name, filters);
      } on DuplicatePresetName catch (duplicate) {
        if (!mounted || !_current) return;
        final overwrite = await showDialog<bool>(
          context: context,
          builder: (context) => Consumer(
            builder: (context, ref, _) {
              ref.watch(filterPresetsProvider);
              if (!identical(
                ref.watch(filterPresetsProvider.notifier),
                widget.controller,
              )) {
                return AlertDialog(
                  title: const Text('Konto zostało zmienione.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Zamknij'),
                    ),
                  ],
                );
              }
              return AlertDialog(
                title: Text('Zastąpić zestaw „${duplicate.existing.name}”?'),
                content: const Text(
                  'Zapisane kryteria zostaną zastąpione aktualnymi.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Anuluj'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Zastąp'),
                  ),
                ],
              );
            },
          ),
        );
        if (overwrite == true && _current) {
          await widget.controller.save(
            name,
            filters,
            overwriteId: duplicate.existing.id,
          );
        }
      }
    } on ArgumentError {
      if (_current) {
        setState(() => _error = 'Nazwa musi mieć od 1 do 80 znaków.');
      }
    } catch (_) {
      if (_current) {
        setState(
          () => _error = 'Nie udało się zapisać filtrów. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(String id) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.delete(id);
    } catch (_) {
      if (_current) setState(() => _error = 'Nie udało się usunąć zestawu.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(filterPresetsProvider);
    final current = identical(
      ref.watch(filterPresetsProvider.notifier),
      widget.controller,
    );
    return AlertDialog(
      title: const Text('Zapisane filtry'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!current)
                const Text(
                  'Konto zostało zmienione. Otwórz zapisane filtry ponownie.',
                )
              else ...[
                const Text(
                  'Zestawy są zapisane tylko na tym urządzeniu, dla bieżącego konta.',
                ),
                TextField(
                  key: const Key('preset-name'),
                  controller: _name,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: 'Nazwa zestawu',
                    errorText: _error,
                  ),
                ),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: const Text('Zapisz aktualne'),
                ),
                if (_busy || presets.isLoading) const LinearProgressIndicator(),
                if (presets.hasError)
                  const Text('Nie udało się wczytać zestawów.'),
                if (presets.valueOrNull?.isEmpty ?? false)
                  const Text('Brak zapisanych zestawów'),
                for (final preset in presets.valueOrNull ?? <FilterPreset>[])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(preset.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Wczytaj ${preset.name}',
                          icon: const Icon(Icons.download),
                          onPressed: _busy
                              ? null
                              : () {
                                  if (!_current) return;
                                  ref
                                      .read(exerciseFiltersProvider.notifier)
                                      .state = widget.controller.apply(
                                    preset.id,
                                  );
                                  Navigator.pop(context);
                                },
                        ),
                        IconButton(
                          tooltip: 'Usuń ${preset.name}',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _busy ? null : () => _delete(preset.id),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zamknij'),
        ),
      ],
    );
  }
}

class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(exerciseFiltersProvider);
    final metadata = ref.watch(exerciseCatalogMetadataProvider).valueOrNull;
    final notifier = ref.read(exerciseFiltersProvider.notifier);
    List<Widget> chips(
      Set<String> values,
      String Function(String) label,
      ExerciseFilters Function(ExerciseFilters, Set<String>) update,
    ) => [
      for (final value in values)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text(label(value)),
            onDeleted: () => notifier.update(
              (current) => update(current, {...values}..remove(value)),
            ),
          ),
        ),
    ];
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...chips(
            f.conditions,
            (id) => (metadata ?? const ExerciseCatalogMetadata())
                .conditionLabel(id),
            (f, s) => f.copyWith(conditions: s),
          ),
          ...chips(
            f.positions,
            (id) =>
                (metadata ?? const ExerciseCatalogMetadata()).positionLabel(id),
            (f, s) => f.copyWith(positions: s),
          ),
          ...chips(
            f.styles,
            (id) => metadata?.styleLabel(id) ?? id,
            (f, s) => f.copyWith(styles: s),
          ),
          ...chips(
            f.muscles,
            ref.watch(exerciseFilterEngineProvider).muscleLabel,
            (f, s) => f.copyWith(muscles: s),
          ),
          ...chips(f.sprzet, (s) => s, (f, s) => f.copyWith(sprzet: s)),
          ...chips(
            f.partie,
            (s) => 'Partia: $s',
            (f, s) => f.copyWith(partie: s),
          ),
          ...chips(f.poziomy, (s) => s, (f, s) => f.copyWith(poziomy: s)),
          ...chips(f.typy, (s) => s, (f, s) => f.copyWith(typy: s)),
          if (f.tylkoUlubione)
            InputChip(
              label: const Text('Ulubione'),
              onDeleted: () =>
                  notifier.update((f) => f.copyWith(tylkoUlubione: false)),
            ),
        ],
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(exerciseFiltersProvider);
    final facets = ref.watch(exerciseFacetsProvider);
    final metadata = ref.watch(exerciseCatalogMetadataProvider);
    final source = ref.watch(allExercisesProvider);
    final notifier = ref.read(exerciseFiltersProvider.notifier);
    final title = source.isLoading || metadata.isLoading
        ? 'Filtry • ładowanie…'
        : source.hasError
        ? 'Filtry • błąd danych'
        : 'Filtry • wyniki: ${ref.watch(filteredExercisesProvider).length}';
    Widget group(
      String title,
      Map<String, int> counts,
      Set<String> selected,
      Iterable<String> options,
      String Function(String) label,
      ExerciseFilters Function(ExerciseFilters, Set<String>) update,
    ) {
      final visible = {
        ...options,
        ...counts.keys,
        ...selected,
      }.where((id) => (counts[id] ?? 0) > 0 || selected.contains(id)).toList();
      if (visible.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final id in visible)
                  FilterChip(
                    label: Text('${label(id)} (${counts[id] ?? 0})'),
                    selected: selected.contains(id),
                    onSelected: (value) => notifier.update(
                      (current) => update(
                        current,
                        {...selected}
                          ..remove(id)
                          ..addAll(value ? [id] : []),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return FractionallySizedBox(
      heightFactor: .9,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Zamknij filtry',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => notifier.state = const ExerciseFilters(),
                child: const Text('Wyczyść filtry'),
              ),
              if (source.isLoading || metadata.isLoading)
                const LinearProgressIndicator(),
              if (source.hasError) const Text('Nie udało się wczytać ćwiczeń'),
              if (metadata.valueOrNull == null)
                const Text(
                  'Filtry stylu i mięśni są czasowo pomijane. Wybory zachowano.',
                ),
              if (!ref
                  .watch(exerciseFilterEngineProvider)
                  .executionFiltersVerified(filters))
                const Text(
                  'Nie można zweryfikować warunków lub pozycji. Kryteriów nie pominięto; usuń wybór albo ponów ładowanie danych.',
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tylko ulubione'),
                        value: filters.tylkoUlubione,
                        onChanged: (v) => notifier.update(
                          (f) => f.copyWith(tylkoUlubione: v),
                        ),
                      ),
                      group(
                        'Warunki wykonania (wszystkie naraz)',
                        facets.conditions,
                        filters.conditions,
                        metadata.valueOrNull?.conditions.keys ?? [],
                        (id) =>
                            (metadata.valueOrNull ??
                                    const ExerciseCatalogMetadata())
                                .conditionLabel(id),
                        (f, s) => f.copyWith(conditions: s),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Cichy trening: względnie mały impakt, nie gwarancja ciszy ani akustyki. Mało miejsca: ćwiczenie w miejscu, bez przemieszczania; potrzebny sprzęt musi się zmieścić. Oznaczenia opisują wykonanie, nie są poradą medyczną.',
                        ),
                      ),
                      group(
                        'Pozycja (dowolna z wybranych)',
                        facets.positions,
                        filters.positions,
                        metadata.valueOrNull?.positions.keys ?? [],
                        (id) =>
                            (metadata.valueOrNull ??
                                    const ExerciseCatalogMetadata())
                                .positionLabel(id),
                        (f, s) => f.copyWith(positions: s),
                      ),
                      group(
                        'Styl',
                        facets.styles,
                        filters.styles,
                        metadata.valueOrNull?.styles.keys ?? [],
                        (id) => metadata.valueOrNull?.styleLabel(id) ?? id,
                        (f, s) => f.copyWith(styles: s),
                      ),
                      group(
                        'Sprzęt',
                        facets.equipment,
                        filters.sprzet,
                        AppConstants.dostepnySprzetOpcje,
                        (s) => s,
                        (f, s) => f.copyWith(sprzet: s),
                      ),
                      group(
                        'Mięśnie główne lub wspierające',
                        facets.muscles,
                        filters.muscles,
                        metadata.valueOrNull?.muscles.keys ?? [],
                        ref.watch(exerciseFilterEngineProvider).muscleLabel,
                        (f, s) => f.copyWith(muscles: s),
                      ),
                      group(
                        'Poziom',
                        facets.levels,
                        filters.poziomy,
                        AppConstants.poziomyOpcje,
                        (s) => s,
                        (f, s) => f.copyWith(poziomy: s),
                      ),
                      group(
                        'Typ aktywności (nie mięśnie)',
                        facets.types,
                        filters.typy,
                        AppConstants.typyOpcje,
                        (s) => s,
                        (f, s) => f.copyWith(typy: s),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
