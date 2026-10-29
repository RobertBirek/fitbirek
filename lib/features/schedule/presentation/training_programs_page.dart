import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/content_layout.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/providers/filter_presets_providers.dart';
import '../../exercises/providers/exercises_providers.dart';
import '../../planner/data/planner_repository.dart';
import '../../workout/preparation/presentation/workout_preparation_sheet.dart';
import '../../workout/preparation/providers/preparation_providers.dart';
import '../../workout/providers/workout_providers.dart';
import '../data/schedule_repository.dart';
import '../domain/training_program_schedule.dart';
import '../domain/weekly_schedule.dart';
import '../providers/training_programs_providers.dart';

const _weekdays = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Niedz'];

/// Same FitBirek cards/type/controls; A/B labels encode the actual planned
/// rotation, never color-only status or completion progress.
class TrainingProgramsPage extends ConsumerStatefulWidget {
  const TrainingProgramsPage({super.key});
  @override
  ConsumerState<TrainingProgramsPage> createState() =>
      _TrainingProgramsPageState();
}

class _TrainingProgramsPageState extends ConsumerState<TrainingProgramsPage> {
  CalendarDay _monday = CalendarDay.local(DateTime.now()).monday;
  bool _busy = false;

  Future<void> _act(
    Future<void> Function(String, bool Function()) action,
  ) async {
    if (_busy) return;
    final account = ref.read(filterPresetsAccountProvider).valueOrNull;
    if (account == null) return;
    final authority = ref.read(cachedAuthWriteAuthorityProvider);
    final epoch = authority.epoch;
    bool guard() =>
        mounted &&
        authority.epoch == epoch &&
        ref.read(filterPresetsAccountProvider).valueOrNull == account;
    setState(() => _busy = true);
    try {
      await action(account, guard);
    } catch (e) {
      if (mounted && guard()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create(TrainingProgramsWeek week) =>
      _act((account, guard) async {
        final repo = ref.read(trainingProgramsRepositoryProvider);
        final lease = await repo.open(account, isCurrent: guard);
        final choices = week.plans
            .where(
              (p) =>
                  p.syncId != null &&
                  p.structure != null &&
                  !p.isUnavailable &&
                  !week.unavailable.containsKey(p.syncId),
            )
            .toList();
        if (!mounted || !guard()) return;
        final draft = await showDialog<_ProgramDraft>(
          context: context,
          builder: (_) => _ProgramForm(plans: choices),
        );
        if (draft == null || !guard()) return;
        final catalog = await ref.read(allExercisesProvider.future);
        final metadata = await ref.read(exerciseCatalogMetadataProvider.future);
        if (!mounted || !guard()) return;
        await repo.create(
          lease,
          name: draft.name,
          planSyncIds: draft.plans,
          weekdays: draft.weekdays,
          effectiveFrom: draft.start,
          catalog: catalog,
          metadata: metadata,
          isCurrent: guard,
        );
      });

  Future<void> _edit(Map<String, dynamic> p, {required bool end}) => _act((
    account,
    guard,
  ) async {
    final repo = ref.read(trainingProgramsRepositoryProvider);
    final lease = await repo.open(
      account,
      programId: p['id'] as String,
      isCurrent: guard,
    );
    if (!mounted || !guard()) return;
    final today = CalendarDay.local(DateTime.now());
    final start = CalendarDay.parse(p['effectiveFromDate'] as String);
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _TextPrompt(
        title: end ? 'Zakończ program' : 'Zmień nazwę programu',
        label: end ? 'Granica (RRRR-MM-DD)' : 'Nazwa programu',
        initial: end
            ? (today.compareTo(start) < 0 ? start.value : today.value)
            : p['name'] as String,
        action: end ? 'Potwierdź zakończenie' : 'Zapisz nazwę',
        message: end
            ? 'Wybrany dzień nie należy już do programu. Wcześniejsze zaległe terminy zostają. Granicy nie można potem zmienić. Inne plany lub dni wybierz w nowym programie.'
            : null,
        date: end,
      ),
    );
    if (value == null || !guard()) return;
    if (end) {
      await repo.end(lease, CalendarDay.parse(value), isCurrent: guard);
    } else {
      await repo.rename(lease, value, isCurrent: guard);
    }
  });

  Future<void> _start(ProgramOccurrence o) => _act((account, guard) async {
    final snapshot = await ref
        .read(workoutPreparationWorkflowProvider)
        .open(planSyncId: o.planSyncId, programOccurrence: o);
    if (!mounted || !guard()) return;
    final started = await showWorkoutPreparation(
      context,
      ref,
      snapshot: snapshot,
    );
    if (started == true &&
        mounted &&
        guard() &&
        ref.read(activeWorkoutProvider).isActive) {
      context.go('/workout/session');
    }
  });

  Future<void> _move(ProgramOccurrence o) => _act((account, guard) async {
    final value = await showDatePicker(
      context: context,
      initialDate: o.date.localDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(9999, 12, 31),
      helpText: 'Przesuń tylko ten termin — plan A/B pozostaje',
    );
    if (value == null || !guard()) return;
    await ref
        .read(trainingProgramsRepositoryProvider)
        .move(account, o, CalendarDay.local(value), isCurrent: guard);
  });

  Future<void> _complete(
    ProgramOccurrence o,
    TrainingProgramsWeek week,
  ) => _act((account, guard) async {
    if (week.sessions.isEmpty) {
      throw StateError(
        'Brak zakończonej sesji z serią roboczą. Zakończ trening i wróć tutaj.',
      );
    }
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Wybierz faktycznie wykonaną sesję'),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Jedna sesja zalicza jeden termin, także w Rytmie tygodnia. Częściowy trening wybierz tylko świadomie.',
            ),
          ),
          for (final s in week.sessions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, s.syncId),
              child: Text(
                '${s.dataStart.toLocal()} • ${s.czasTrwaniaSekund ~/ 60} min${s.notatka == null ? '' : ' • ${s.notatka}'}',
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted || !guard()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zaliczyć ten termin?'),
        content: SingleChildScrollView(
          child: Text(
            '${o.name} • ${o.date.value}\nPotwierdzam wykonanie i powiązanie wybranej sesji, również gdy była częściowa. Nie kopiujemy serii ani rekordów.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zalicz termin'),
          ),
        ],
      ),
    );
    if (confirmed != true || !guard()) return;
    await ref
        .read(trainingProgramsRepositoryProvider)
        .complete(account, o, selected, isCurrent: guard);
  });

  @override
  Widget build(BuildContext context) {
    final week = ref.watch(trainingProgramsWeekProvider(_monday));
    return Scaffold(
      appBar: AppBar(title: const Text('Programy A/B')),
      body: ContentLayout(
        child: ListView(
          padding: ContentLayout.pagePadding(context),
          children: [
            const Text(
              'Dwa szablony na zmianę według zaplanowanych dat. Niewykonany termin zostaje do wykonania lub przesunięcia.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Start, upływ daty i samo zakończenie treningu nie zaliczają terminu. Wróć tutaj i jawnie wybierz zakończoną sesję z serią roboczą.',
            ),
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
              error: (e, _) => Text('Programy niedostępne. Dane zachowano. $e'),
              data: (data) {
                if (data == null) {
                  return const Text(
                    'Programy wymagają lokalnego dostępu do konta i aktywnego profilu.',
                  );
                }
                final blocked = _busy || data.writeError != null;
                final choices = data.plans.where(
                  (p) =>
                      p.syncId != null &&
                      p.structure != null &&
                      !p.isUnavailable &&
                      !data.unavailable.containsKey(p.syncId),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.writeError != null)
                      Text(
                        '${data.writeError} Zapis i start wstrzymane; niczego nie usuwamy.',
                      ),
                    FilledButton.icon(
                      onPressed: blocked || choices.length < 2
                          ? null
                          : () => _create(data),
                      icon: const Icon(Icons.add),
                      label: const Text('Nowy program A/B'),
                    ),
                    if (choices.length < 2)
                      const Text(
                        'Najpierw zapisz dwa różne dostępne szablony w Moich szablonach.',
                      ),
                    for (final p in data.programs.entries.where(
                      (p) =>
                          p['kind'] == 'program' && p['deletedAtUtc'] == null,
                    ))
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name'] as String,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${(p['weekdays'] as List).map((d) => _weekdays[(d as int) - 1]).join(' • ')} • od ${p['effectiveFromDate']}',
                              ),
                              if (p['endBeforeDate'] != null)
                                Text(
                                  'Zakończony przed ${p['endBeforeDate']}. Zaległe terminy pozostają.',
                                ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: blocked
                                        ? null
                                        : () => _edit(p, end: false),
                                    child: const Text('Zmień nazwę'),
                                  ),
                                  if (p['endBeforeDate'] == null)
                                    TextButton(
                                      onPressed: blocked
                                          ? null
                                          : () => _edit(p, end: true),
                                      child: const Text('Zakończ program'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    for (var i = 0; i < 7; i++) ...[
                      const Divider(height: 32),
                      Text(
                        '${_weekdays[i]} • ${_monday.plus(i).value}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (!data.occurrences.any(
                        (o) => o.date == _monday.plus(i),
                      ))
                        const Text('Bez terminu programu'),
                      for (final o in data.occurrences.where(
                        (o) => o.date == _monday.plus(i),
                      ))
                        _occurrenceCard(o, data, blocked),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _occurrenceCard(
    ProgramOccurrence o,
    TrainingProgramsWeek week,
    bool blocked,
  ) {
    final status = week.status[o.id] ?? ScheduleCompletion.planned;
    final plan = week.plans.where((p) => p.syncId == o.planSyncId).firstOrNull;
    final unavailable =
        plan == null || week.unavailable.containsKey(o.planSyncId);
    final label = switch (status) {
      ScheduleCompletion.planned => 'Do wykonania',
      ScheduleCompletion.completed => 'Zaliczone — jawnie powiązana sesja',
      ScheduleCompletion.invalidated =>
        'Zaliczenie nieważne — brak żywego wykonania',
      ScheduleCompletion.conflict =>
        'Konflikt — jedna sesja przypisana do kilku terminów. Nie liczymy podwójnie.',
    };
    return Card(
      key: ValueKey(o.id),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(o.name, style: Theme.of(context).textTheme.titleMedium),
            Text(
              'Plan ${o.planIndex == 0 ? 'A' : 'B'} • ${plan?.nazwa ?? 'Szablon niedostępny'}',
            ),
            Text(label),
            if (o.date != o.originalDate)
              Text(
                'Przesunięty z ${o.originalDate.value} — plan A/B bez zmiany',
              ),
            if (unavailable)
              Text(
                week.unavailable[o.planSyncId] ??
                    'Szablon niedostępny. Nie generujemy zamiennika.',
              ),
            if (status == ScheduleCompletion.planned)
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: blocked || unavailable ? null : () => _start(o),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Rozpocznij plan'),
                  ),
                  TextButton(
                    onPressed: blocked ? null : () => _move(o),
                    child: const Text('Przesuń termin'),
                  ),
                  TextButton(
                    onPressed: blocked ? null : () => _complete(o, week),
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

class _ProgramDraft {
  _ProgramDraft(this.name, this.plans, this.weekdays, this.start);
  final String name;
  final List<String> plans;
  final Set<int> weekdays;
  final CalendarDay start;
}

String? _validateDate(String? value) {
  try {
    CalendarDay.parse(value?.trim() ?? '');
    return null;
  } on FormatException {
    return 'Podaj poprawny dzień RRRR-MM-DD.';
  }
}

class _ProgramForm extends StatefulWidget {
  const _ProgramForm({required this.plans});
  final List<SavedPlan> plans;
  @override
  State<_ProgramForm> createState() => _ProgramFormState();
}

class _ProgramFormState extends State<_ProgramForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _date = TextEditingController(
    text: CalendarDay.local(DateTime.now()).value,
  );
  final _days = <int>{1, 3, 5};
  late String _a = widget.plans.first.syncId!, _b = widget.plans[1].syncId!;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.all(16),
    title: const Text('Nowy program A/B'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nazwa programu'),
                maxLength: 80,
                textInputAction: TextInputAction.next,
                validator: (s) =>
                    s == null || s.trim().isEmpty ? 'Podaj nazwę.' : null,
              ),
              for (final a in [true, false])
                DropdownButtonFormField<String>(
                  initialValue: a ? _a : _b,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: a ? 'Szablon A' : 'Szablon B',
                  ),
                  items: [
                    for (final p in widget.plans)
                      DropdownMenuItem(
                        value: p.syncId,
                        child: Text(
                          p.nazwa,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        if (a) {
                          _a = value;
                        } else {
                          _b = value;
                        }
                      });
                    }
                  },
                ),
              const SizedBox(height: 12),
              const Text('Dni treningów'),
              Wrap(
                spacing: 4,
                children: [
                  for (var i = 1; i <= 7; i++)
                    FilterChip(
                      label: Text(_weekdays[i - 1]),
                      selected: _days.contains(i),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _days.add(i);
                        } else {
                          _days.remove(i);
                        }
                      }),
                    ),
                ],
              ),
              TextFormField(
                controller: _date,
                decoration: const InputDecoration(
                  labelText: 'Data początku (RRRR-MM-DD)',
                ),
                keyboardType: TextInputType.datetime,
                validator: _validateDate,
              ),
              const SizedBox(height: 12),
              const Text(
                'Plany zmieniają się A–B–A, potem B–A–B dla pon/śr/pt. Start niczego nie zalicza. Inny rytm wymaga nowego programu.',
              ),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Anuluj'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          if (_a == _b || _days.isEmpty) {
            setState(
              () => _error =
                  'Wybierz dwa różne szablony i co najmniej jeden dzień.',
            );
            return;
          }
          Navigator.pop(
            context,
            _ProgramDraft(
              _name.text.trim(),
              [_a, _b],
              Set.of(_days),
              CalendarDay.parse(_date.text.trim()),
            ),
          );
        },
        child: const Text('Zapisz program'),
      ),
    ],
  );
}

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({
    required this.title,
    required this.label,
    required this.initial,
    required this.action,
    this.message,
    this.date = false,
  });
  final String title, label, initial, action;
  final String? message;
  final bool date;
  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  final _form = GlobalKey<FormState>();
  late final _text = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.message != null) Text(widget.message!),
            TextFormField(
              controller: _text,
              decoration: InputDecoration(labelText: widget.label),
              maxLength: widget.date ? 10 : 80,
              keyboardType: widget.date
                  ? TextInputType.datetime
                  : TextInputType.text,
              validator: widget.date
                  ? _validateDate
                  : (s) =>
                        s == null || s.trim().isEmpty ? 'Podaj nazwę.' : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Anuluj'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _text.text.trim());
          }
        },
        child: Text(widget.action),
      ),
    ],
  );
}
