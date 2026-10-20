import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/providers/filter_presets_providers.dart';
import '../domain/activity_schedule.dart';
import '../domain/weekly_schedule.dart';
import '../providers/schedule_providers.dart';

class ActivityListPage extends ConsumerStatefulWidget {
  const ActivityListPage({super.key});
  @override
  ConsumerState<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends ConsumerState<ActivityListPage> {
  bool _busy = false;
  Future<void> _change(ActivityRule rule, {bool delete = false}) async {
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
      final repo = ref.read(activityRepositoryProvider);
      final lease = await repo.snapshot(account, isCurrent: guard);
      if (!mounted || !guard()) return;
      if (delete) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Usunąć aktywność?'),
            content: const Text(
              'Przyszłe terminy znikną. Zapisana historia pozostanie.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Usuń'),
              ),
            ],
          ),
        );
        if (confirmed != true || !guard()) return;
        await repo.delete(lease, rule.id, isCurrent: guard);
      } else {
        await repo.setEnabled(lease, rule.id, !rule.enabled, isCurrent: guard);
      }
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

  @override
  Widget build(BuildContext context) {
    final week = ref.watch(
      scheduleWeekProvider(CalendarDay.local(DateTime.now()).monday),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Harmonogram aktywności')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Europe/Warsaw • Terminy nie tworzą treningów ani serii automatycznie.',
          ),
          TextButton(
            onPressed: () => context.push('/schedule'),
            child: const Text('Widok tygodnia'),
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
              final rules = data.schedule.entries
                  .where(
                    (e) =>
                        ['rule', 'activityRule'].contains(e['kind']) &&
                        e['deletedAtUtc'] == null,
                  )
                  .map(ActivityRule.fromJson)
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final type in ActivityType.values) ...[
                    Text(
                      type == ActivityType.external
                          ? 'Aktywności zewnętrzne'
                          : 'Treningi FitBirek',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () => context.push(
                              '/settings/activities/new?type=${type.name}',
                            ),
                      child: Text(
                        type == ActivityType.external
                            ? 'Dodaj aktywność zewnętrzną'
                            : 'Dodaj trening FitBirek',
                      ),
                    ),
                    if (!rules.any((r) => r.activityType == type))
                      const Text('Brak aktywności'),
                    for (final r in rules.where((r) => r.activityType == type))
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${r.weekdays.map((d) => activityWeekdays[d - 1]).join(', ')} • ${r.time ?? 'Bez godziny'}${r.durationMinutes == null ? '' : ' • ${r.durationMinutes} min'} • ${r.enabled ? 'Włączona' : 'Wyłączona'}',
                              ),
                              if (type == ActivityType.fitbirek)
                                Text(
                                  r.planSyncId == null
                                      ? 'Trening swobodny'
                                      : data.plans
                                                .where(
                                                  (p) =>
                                                      p.syncId ==
                                                          r.planSyncId &&
                                                      !p.isUnavailable,
                                                )
                                                .firstOrNull
                                                ?.nazwa ??
                                            'Plan niedostępny — wybierz istniejący szablon w edycji.',
                                ),
                              if (r.isLegacy)
                                const Text(
                                  'Starsza reguła bez godziny. Najpierw edytuj i jawnie wybierz godzinę, aby włączać lub wyłączać.',
                                ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => context.push(
                                            '/settings/activities/${r.id}/edit',
                                          ),
                                    child: const Text('Edytuj'),
                                  ),
                                  TextButton(
                                    onPressed: _busy || r.isLegacy
                                        ? null
                                        : () => _change(r),
                                    child: Text(r.enabled ? 'Wyłącz' : 'Włącz'),
                                  ),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _change(r, delete: true),
                                    child: const Text('Usuń'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

const activityWeekdays = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];
