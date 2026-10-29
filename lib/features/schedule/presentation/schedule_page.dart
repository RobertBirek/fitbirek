import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/weekly_schedule.dart';
import '../providers/schedule_providers.dart';
import 'widgets/today_schedule.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});
  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  CalendarDay _monday = CalendarDay.local(DateTime.now()).monday;
  static const _days = [
    'Poniedziałek',
    'Wtorek',
    'Środa',
    'Czwartek',
    'Piątek',
    'Sobota',
    'Niedziela',
  ];
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
                'Europe/Warsaw • Terminy zaliczasz ręcznie. Start, upływ daty i pusta sesja nie zaliczają. Aktywność zewnętrzna nie tworzy sesji ani serii.',
              ),
              TextButton(
                onPressed: () => context.push('/programs'),
                child: const Text('Programy A/B — dwa szablony na zmianę'),
              ),
              TextButton(
                onPressed: () => context.go('/settings/activities'),
                child: const Text('Zarządzaj aktywnościami'),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Poprzedni tydzień',
                    onPressed: () => setState(() => _monday = _monday.plus(-7)),
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
                    onPressed: () => setState(() => _monday = _monday.plus(7)),
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
                      for (var i = 0; i < 7; i++) ...[
                        const Divider(height: 32),
                        Text(
                          '${_days[i]} • ${_monday.plus(i).value}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (!data.occurrences.any(
                          (o) => o.date == _monday.plus(i),
                        ))
                          const Text('Bez terminu'),
                        for (final o in data.occurrences.where(
                          (o) => o.date == _monday.plus(i),
                        ))
                          ScheduleOccurrenceCard(
                            key: ValueKey(o.id),
                            occurrence: o,
                            week: data,
                          ),
                      ],
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
}
