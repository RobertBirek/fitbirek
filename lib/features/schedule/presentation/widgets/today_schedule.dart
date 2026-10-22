import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../exercises/providers/filter_presets_providers.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../workout/providers/workout_providers.dart';
import '../../../workout/preparation/providers/preparation_providers.dart';
import '../../../workout/preparation/presentation/workout_preparation_sheet.dart';
import '../../domain/activity_schedule.dart';
import '../../domain/weekly_schedule.dart';
import '../../data/schedule_repository.dart';
import '../../providers/schedule_providers.dart';

/// This widget deliberately has no scrollable/Expanded: both Today hosts own
/// their scrolling. The calendar follows the app's local calendar everywhere.
class TodaySchedule extends ConsumerWidget {
  const TodaySchedule({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = CalendarDay.local(DateTime.now());
    final week = ref.watch(scheduleWeekProvider(day.monday));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dziś w harmonogramie • Europe/Warsaw',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        week.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) =>
              const Text('Harmonogram niedostępny. Dane zachowano.'),
          data: (data) {
            if (data == null) {
              return const Text('Brak lokalnego dostępu do harmonogramu.');
            }
            final today = data.occurrences.where((o) => o.date == day).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (today.isEmpty) const Text('Brak terminów na dziś'),
                for (final o in today)
                  ScheduleOccurrenceCard(
                    key: ValueKey(o.id),
                    occurrence: o,
                    week: data,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class ScheduleOccurrenceCard extends ConsumerStatefulWidget {
  const ScheduleOccurrenceCard({
    super.key,
    required this.occurrence,
    required this.week,
  });
  final ScheduleOccurrence occurrence;
  final ScheduleWeek week;
  @override
  ConsumerState<ScheduleOccurrenceCard> createState() =>
      _ScheduleOccurrenceCardState();
}

class _ScheduleOccurrenceCardState
    extends ConsumerState<ScheduleOccurrenceCard> {
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

  Future<void> _start() => _act((account, guard) async {
    final chosen = widget.occurrence;
    final snapshot = await ref
        .read(workoutPreparationWorkflowProvider)
        .open(planSyncId: chosen.planSyncId, occurrence: chosen);
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

  Future<void> _complete() => _act((account, guard) async {
    final o = widget.occurrence;
    if (o.activityType == ActivityType.external) {
      if (!await _confirm(
            'Potwierdzić wykonanie aktywności?',
            '${o.name} — ręczne potwierdzenie. Nie tworzy sesji, serii ani rekordów.',
          ) ||
          !guard()) {
        return;
      }
      await ref
          .read(scheduleRepositoryProvider)
          .completeExternal(account, o, isCurrent: guard);
      return;
    }
    if (widget.week.sessions.isEmpty) {
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
              'Jedna sesja zalicza tylko jeden termin. Bez kopiowania serii i rekordów.',
            ),
          ),
          for (final s in widget.week.sessions)
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
          '${o.name} — powiązać z wybraną sesją?',
        ) ||
        !guard()) {
      return;
    }
    await ref
        .read(scheduleRepositoryProvider)
        .complete(account, o, id, isCurrent: guard);
  });

  Future<void> _move() => _act((account, guard) async {
    final o = widget.occurrence;
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

  @override
  Widget build(BuildContext context) {
    final o = widget.occurrence;
    final external = o.activityType == ActivityType.external;
    if (!external && o.planSyncId != null) ref.watch(allExercisesProvider);
    final plan = widget.week.plans
        .where((p) => p.syncId == o.planSyncId)
        .firstOrNull;
    final unavailable =
        !external &&
        o.planSyncId != null &&
        (plan == null || plan.isUnavailable);
    final status = widget.week.status[o.id] ?? ScheduleCompletion.planned;
    final label = switch (status) {
      ScheduleCompletion.planned => 'Do wykonania',
      ScheduleCompletion.completed =>
        external ? 'Zaliczone ręcznie' : 'Zaliczone — powiązana sesja',
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
            Text(
              '${o.time ?? 'Bez godziny'} • ${external ? 'Aktywność zewnętrzna' : 'FitBirek'}${o.durationMinutes == null ? '' : ' • ${o.durationMinutes} min'}',
            ),
            Text(label),
            if (!external && o.planSyncId == null)
              const Text('Trening swobodny'),
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
                  if (!external)
                    TextButton.icon(
                      onPressed: _busy || unavailable ? null : _start,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        o.planSyncId == null
                            ? 'Rozpocznij swobodny'
                            : 'Rozpocznij plan',
                      ),
                    ),
                  TextButton(
                    onPressed: _busy ? null : _move,
                    child: const Text('Przesuń termin'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _complete,
                    child: Text(
                      external ? 'Potwierdź wykonanie' : 'Zalicz z sesji',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
