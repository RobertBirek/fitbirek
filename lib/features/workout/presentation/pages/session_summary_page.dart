import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/content_layout.dart';
import '../../providers/workout_providers.dart';
import '../../../../core/providers/database_provider.dart';
import '../../domain/workout_guidance.dart';
import '../widgets/repeat_workout_dialog.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/app_database.dart';
import '../../data/workout_repository.dart';
import '../../../planner/presentation/widgets/save_as_template_button.dart';
import '../widgets/session_delete_button.dart';
import '../../domain/workout_progress.dart';

/// Podsumowanie zakończonej sesji treningowej.
class SessionSummaryPage extends ConsumerStatefulWidget {
  const SessionSummaryPage({super.key, required this.sessionId});
  final int sessionId;

  @override
  ConsumerState<SessionSummaryPage> createState() => _SessionSummaryPageState();
}

class _SessionSummaryPageState extends ConsumerState<SessionSummaryPage> {
  Future<({List<SetLogData> sets, WorkoutSessionData? session})>? _summary;
  WorkoutRepository? _repository;
  AppDatabase? _database;
  int? _loadedId;

  Widget _unavailable(String message, {bool retry = false}) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        if (retry)
          TextButton(
            onPressed: () => setState(() => _summary = null),
            child: const Text('Spróbuj ponownie'),
          ),
        TextButton(
          onPressed: () => context.go('/workout'),
          child: const Text('Przejdź do historii treningów'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sessionId = widget.sessionId;
    final repo = ref.watch(workoutRepositoryProvider);
    final db = ref.watch(appDatabaseProvider);
    if (_summary == null ||
        _loadedId != sessionId ||
        !identical(_repository, repo) ||
        !identical(_database, db)) {
      _loadedId = sessionId;
      _repository = repo;
      _database = db;
      _summary = (() async => (
        sets: await repo.getSetsForSession(sessionId),
        session: await db.workoutDao.getSession(sessionId),
      ))();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Podsumowanie treningu')),
      body: FutureBuilder(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _unavailable(
              'Nie udało się odczytać podsumowania treningu.',
              retry: true,
            );
          }
          final sets = snapshot.data!.sets, session = snapshot.data!.session;
          if (session == null || session.deletedAtUtc != null) {
            return _unavailable('Nie znaleziono treningu.');
          }
          final g = WorkoutGuidance.tryRead(session.guidanceJson);
          final additional =
              g?.additionalSetIds(sets.map((s) => s.syncId)).toSet() ??
              <String>{};
          return ContentLayout(
            child: SingleChildScrollView(
              child: Padding(
                padding: ContentLayout.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      WorkoutProgress.from(
                        liveSetIds: sets.map((s) => s.syncId),
                        guidance: g,
                      ).label,
                    ),
                    ExpansionTile(
                      title: const Text('Akcje treningu'),
                      children: [
                        SaveAsTemplateButton(sessionId: sessionId),
                        SessionDeleteButton(sessionId: sessionId),
                        if (session.dataKoniec != null)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.repeat),
                            label: const Text('Powtórz trening'),
                            onPressed: () async {
                              final started = await showDialog<bool>(
                                context: context,
                                builder: (_) =>
                                    RepeatWorkoutDialog(sessionId: sessionId),
                              );
                              if (started == true && context.mounted) {
                                context.go('/workout/session');
                              }
                            },
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (session.notatka?.isNotEmpty == true)
                          Text('Notatka: ${session.notatka}'),
                        if (session.guidanceJson != null && g == null)
                          const Text(
                            'Plan niedostępny — uszkodzone lub nieobsługiwane dane. Historia wykonania poniżej.',
                          ),
                        if (g != null) ...[
                          Text(
                            'Plan a wykonanie',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Czas estymowany: ${Formatters.duration(g.plan.estimatedSeconds)} • czas sesji: ${Formatters.duration(session.czasTrwaniaSekund)}',
                          ),
                          Text(
                            'Potwierdzona praca czasowa: ${sets.fold<int>(0, (n, s) => n + (s.czasSekund ?? 0))} s. Czas sesji obejmuje również przerwy; nie jest pomiarem pracy.',
                          ),
                          for (var i = 0; i < g.plan.blocks.length; i++)
                            Builder(
                              builder: (_) {
                                final block = g.plan.blocks[i],
                                    p = g.plan.blocks[i].prescription;
                                final events = g.events.where(
                                  (e) => e['slotIndex'] == i,
                                );
                                final ids = events
                                    .where((e) => e['type'] == 'performed')
                                    .map((e) => e['setSyncId'])
                                    .toSet();
                                final actual = sets
                                    .where((s) => ids.contains(s.syncId))
                                    .toList();
                                final changed = events.any(
                                  (e) => e['type'] == 'replaced',
                                );
                                final skipped = events.any(
                                  (e) => e['type'] == 'skipped',
                                );
                                return Text(
                                  '${block.section.label} • ${block.exerciseId}${changed ? ' → ${g.exerciseAt(i)} • Zmienione' : ''}'
                                  '\nCel: ${p.sets} serii × ${p.reps == null ? '${p.workSeconds} s' : '${p.reps} powt.'}'
                                  '\nWykonane: ${actual.length} serii${skipped ? ' • Pominięte (zdarzenie)' : ''}'
                                  '${actual.any((s) => s.variantId != null) ? '\nWariant zamiast bazowego (Zmienione): ${actual.where((s) => s.variantId != null).map((s) => s.variantLabel ?? s.variantId).toSet().join(', ')}' : ''}'
                                  '${actual.isEmpty && !skipped ? ' • Bez potwierdzenia' : ''}',
                                );
                              },
                            ),
                          Text(
                            'Dodatkowe: ${g.additionalSetIds(sets.map((s) => s.syncId)).length} serii (bez powiązania z blokiem)',
                          ),
                        ],
                      ],
                    ),
                    if (sets.isEmpty) const Text('Brak zalogowanych serii'),
                    for (var i = 0; i < sets.length; i++)
                      Builder(
                        builder: (context) {
                          final s = sets[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                '${additional.contains(s.syncId) ? 'Dodatkowe • ' : ''}${s.nazwaCwiczeniaPl} - seria ${s.numerSerii}',
                              ),
                              subtitle: Text(
                                '${s.variantId == null ? '' : '${s.variantLabel ?? s.variantId} • '}'
                                '${s.side == null ? '' : '${const {'left': 'Lewa', 'right': 'Prawa', 'both': 'Obie'}[s.side]} • '}'
                                '${s.czasSekund != null ? '${s.czasSekund} s' : '${s.ciezarKg == null ? '' : '${s.ciezarKg} kg × '}${s.powtorzenia ?? '-'} powt.'}'
                                ' (RPE ${s.rpe ?? '-'}) • ${Formatters.time(s.timestamp)}',
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
