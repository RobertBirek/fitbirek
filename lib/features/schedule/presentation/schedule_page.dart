import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/providers/exercises_providers.dart';
import '../../exercises/providers/filter_presets_providers.dart';
import '../../planner/data/planner_repository.dart';
import '../../planner/providers/planner_providers.dart';
import '../data/schedule_repository.dart';
import '../domain/weekly_schedule.dart';
import '../providers/schedule_providers.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});
  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  CalendarDay _monday = CalendarDay.local(DateTime.now()).monday;
  bool _busy = false;
  static const _days = [
    'Poniedziałek',
    'Wtorek',
    'Środa',
    'Czwartek',
    'Piątek',
    'Sobota',
    'Niedziela',
  ];

  Future<void> _act(
    Future<void> Function(String account, bool Function() guard) action,
  ) async {
    if (_busy) return;
    final account = ref.read(filterPresetsAccountProvider).valueOrNull;
    final authority = ref.read(cachedAuthWriteAuthorityProvider);
    final epoch = authority.epoch;
    bool guard() =>
        mounted &&
        authority.epoch == epoch &&
        ref.read(filterPresetsAccountProvider).valueOrNull == account;
    if (account == null) return;
    setState(() => _busy = true);
    try {
      await action(account, guard);
    } catch (e) {
      if (mounted && guard()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Potwierdź'),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _add(ScheduleWeek data) => _act((account, guard) async {
    final plans = data.plans
        .where((p) => !p.isUnavailable && p.syncId != null)
        .toList();
    if (plans.isEmpty) throw StateError('Najpierw zapisz plan w generatorze.');
    var plan = plans.first;
    var weekday = 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Przypisz plan do dnia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<SavedPlan>(
                initialValue: plan,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Zapisany plan'),
                items: [
                  for (final p in plans)
                    DropdownMenuItem(
                      value: p,
                      child: Text(p.nazwa, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (p) {
                  if (p != null) setDialogState(() => plan = p);
                },
              ),
              DropdownButtonFormField<int>(
                initialValue: weekday,
                decoration: const InputDecoration(labelText: 'Co tydzień w'),
                items: [
                  for (var i = 1; i <= 7; i++)
                    DropdownMenuItem(value: i, child: Text(_days[i - 1])),
                ],
                onChanged: (d) {
                  if (d != null) setDialogState(() => weekday = d);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Od tygodnia ${_monday.value}. Kolejne terminy są wirtualne. Zmiana rytmu: usuń regułę i dodaj nową; historia pozostaje.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Przypisz'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !guard()) return;
    await ref
        .read(scheduleRepositoryProvider)
        .addRule(
          account,
          planSyncId: plan.syncId!,
          name: plan.nazwa,
          weekday: weekday,
          effectiveFrom: _monday,
          isCurrent: guard,
        );
  });

  Future<void> _move(ScheduleOccurrence o) => _act((account, guard) async {
    final date = await showDatePicker(
      context: context,
      initialDate: o.date.localDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(9999, 12, 31),
      helpText: 'Przesuń tylko ten termin',
    );
    if (date == null || !guard()) return;
    await ref
        .read(scheduleRepositoryProvider)
        .move(account, o, CalendarDay.local(date), isCurrent: guard);
  });

  Future<void> _complete(ScheduleOccurrence o, ScheduleWeek data) => _act((
    account,
    guard,
  ) async {
    if (data.sessions.isEmpty) {
      throw StateError(
        'Brak zakończonej sesji z zapisaną serią. Zakończ trening i wróć tutaj.',
      );
    }
    final id = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Wybierz faktycznie wykonaną sesję'),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Jedna sesja może zaliczyć tylko jeden termin. Nie kopiujemy serii ani rekordów.',
            ),
          ),
          for (final s in data.sessions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, s.syncId),
              child: Text(
                '${s.dataStart.toLocal()} • ${s.czasTrwaniaSekund ~/ 60} min${s.notatka == null ? '' : ' • ${s.notatka}'}',
              ),
            ),
        ],
      ),
    );
    if (id == null || !guard()) return;
    if (!await _confirm(
          'Zaliczyć ten termin?',
          'Powiąż ${o.name} (${o.date.value}) z wybraną sesją. To ręczne zaliczenie, bez dopisywania wykonania.',
        ) ||
        !guard()) {
      return;
    }
    await ref
        .read(scheduleRepositoryProvider)
        .complete(account, o, id, isCurrent: guard);
  });

  Future<void> _start(ScheduleOccurrence o) => _act((account, guard) async {
    if (!await _confirm(
          'Rozpocząć zapisany plan?',
          '${o.name}. Serie zapisujesz w sesji. Po zakończeniu wróć do harmonogramu, by jawnie zaliczyć termin.',
        ) ||
        !guard()) {
      return;
    }
    final catalog = ref.read(allExercisesProvider);
    if (catalog.isLoading || catalog.hasError || catalog.valueOrNull == null) {
      throw StateError('Poczekaj na wczytanie katalogu ćwiczeń.');
    }
    await ref
        .read(plannerWorkflowProvider)
        .startSaved(o.planSyncId, catalog.requireValue);
    // Schedule is a root overlay above the settings branch. Pushing another
    // branch of the same StatefulShellRoute would stack the shell page twice
    // with the same key. Switch to its workout branch, removing the overlay.
    if (mounted && guard()) context.go('/workout/session');
  });

  @override
  Widget build(BuildContext context) {
    final week = ref.watch(scheduleWeekProvider(_monday));
    return Scaffold(
      appBar: AppBar(title: const Text('Rytm tygodnia')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Terminy zaliczasz ręcznie tutaj po zakończeniu treningu z zapisaną serią. Start, upływ daty i pusta sesja nie zaliczają terminu.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Poprzedni tydzień',
                    onPressed: _busy
                        ? null
                        : () => setState(() => _monday = _monday.plus(-7)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      '${_monday.value} — ${_monday.plus(6).value}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Następny tydzień',
                    onPressed: _busy
                        ? null
                        : () => setState(() => _monday = _monday.plus(7)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              week.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Nie można odczytać harmonogramu. Dane zachowano. $e'),
                data: (data) {
                  if (data == null) {
                    return const Text(
                      'Harmonogram wymaga lokalnego dostępu do konta i aktywnego profilu.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _add(data),
                        icon: const Icon(Icons.event_repeat),
                        label: const Text('Przypisz zapisany plan'),
                      ),
                      for (var i = 0; i < 7; i++) ...[
                        const Divider(height: 32),
                        Text(
                          '${_days[i]} • ${_monday.plus(i).value}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (!data.occurrences.any(
                          (o) => o.date == _monday.plus(i),
                        ))
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Bez terminu'),
                          ),
                        for (final o in data.occurrences.where(
                          (o) => o.date == _monday.plus(i),
                        ))
                          _card(o, data),
                      ],
                      const Divider(height: 32),
                      Text(
                        'Reguły cykliczne',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final r in data.schedule.entries.where(
                        (e) => e['kind'] == 'rule' && e['deletedAtUtc'] == null,
                      ))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(r['name'] as String),
                          subtitle: Text(
                            '${_days[(r['weekday'] as int) - 1]} • od ${r['effectiveFromDate']}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Usuń regułę',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _busy
                                ? null
                                : () => _act((account, guard) async {
                                    if (await _confirm(
                                          'Usunąć regułę?',
                                          'Przyszłe wirtualne terminy znikną. Zapisane wyjątki i historia zaliczeń pozostaną.',
                                        ) &&
                                        guard()) {
                                      await ref
                                          .read(scheduleRepositoryProvider)
                                          .deleteRule(
                                            account,
                                            r['id'] as String,
                                            isCurrent: guard,
                                          );
                                    }
                                  }),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(ScheduleOccurrence o, ScheduleWeek data) {
    final catalog = ref.watch(allExercisesProvider);
    final plan = data.plans.where((p) => p.syncId == o.planSyncId).firstOrNull;
    final unavailable = plan == null || plan.isUnavailable;
    final status = data.status[o.id] ?? ScheduleCompletion.planned;
    final label = switch (status) {
      ScheduleCompletion.planned => 'Do wykonania',
      ScheduleCompletion.completed => 'Zaliczone — powiązana sesja',
      ScheduleCompletion.invalidated =>
        'Zaliczenie nieważne — sesja usunięta lub brak wykonania',
      ScheduleCompletion.conflict =>
        'Konflikt — ta sama sesja przypisana do kilku terminów. Nie liczymy podwójnie.',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(o.name, style: Theme.of(context).textTheme.titleMedium),
            Text(label),
            if (o.date != o.originalDate)
              Text('Przesunięty z ${o.originalDate.value}'),
            if (unavailable)
              const Text(
                'Plan niedostępny — usunięty, brak synchronizacji lub uszkodzone dane. Nie generujemy zamiennika.',
              ),
            if (status == ScheduleCompletion.planned)
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed:
                        _busy ||
                            unavailable ||
                            catalog.isLoading ||
                            catalog.hasError ||
                            catalog.valueOrNull == null
                        ? null
                        : () => _start(o),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Rozpocznij plan'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _move(o),
                    child: const Text('Przesuń termin'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _complete(o, data),
                    child: const Text('Zalicz z sesji'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
