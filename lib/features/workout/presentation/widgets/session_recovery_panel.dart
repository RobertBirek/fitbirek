import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/session_recovery_provider.dart';
import '../../providers/workout_providers.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/session_actions_repository.dart';
import '../../../planner/presentation/widgets/save_as_template_button.dart';
import 'session_delete_button.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../planner/domain/structured_plan.dart';
import '../../domain/empty_session_template.dart';
import '../../domain/workout_guidance.dart';
import '../../domain/workout_repeat.dart';

class SessionRecoveryPanel extends ConsumerStatefulWidget {
  const SessionRecoveryPanel({super.key});
  @override
  ConsumerState<SessionRecoveryPanel> createState() =>
      _SessionRecoveryPanelState();
}

class _SessionRecoveryPanelState extends ConsumerState<SessionRecoveryPanel> {
  bool busy = false;
  String? error;

  Future<void> finish(
    SessionRecovery snapshot,
    RecoverableSession session,
  ) async {
    final authority = ref.read(cachedAuthWriteAuthorityProvider);
    if (busy ||
        snapshot.accountId == null ||
        authority.epoch != snapshot.epoch) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final repo = SessionActionsRepository(
        ref.read(appDatabaseProvider),
        authority,
      );
      final edit = await repo.capture(session.id);
      if (!mounted ||
          authority.epoch != snapshot.epoch ||
          edit.binding.accountId != snapshot.accountId) {
        return;
      }
      final empty = edit.sets.isEmpty;
      StructuredPlan? emptyPlan;
      if (empty && edit.row.guidanceJson == null && edit.drafts.length == 1) {
        try {
          final draft = validateWorkoutDraft(
            jsonDecode(edit.drafts.single.payloadJson),
          );
          final ids = List<String>.from(draft['selectedIds'] as List);
          final catalog = await ref.read(allExercisesProvider.future);
          final metadata = await ref.read(
            exerciseCatalogMetadataProvider.future,
          );
          if (ids.any((id) => !catalog.any((e) => e.id == id))) {
            throw const FormatException('Brak ćwiczenia.');
          }
          final fields = draft['fields'] as Map;
          emptyPlan = templateFromSelection(
            ids.map((id) => catalog.firstWhere((e) => e.id == id)).toList(),
            metadata,
            repeat: fields['repeatTargets'] == null
                ? null
                : WorkoutRepeat.fromJson(fields['repeatTargets']),
          );
        } on FormatException {
          // No lossy conversion or invented execution on corrupt/unsupported draft.
        }
        if (!mounted || authority.epoch != snapshot.epoch) return;
        await repo.check(edit);
      }
      if (!mounted || authority.epoch != snapshot.epoch) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          scrollable: true,
          title: Text(empty ? 'Pusty trening' : 'Zakończyć bez wznawiania?'),
          content: Text(
            '${session.started.toLocal()} • ${edit.sets.length} zapisanych serii.\n${empty ? 'Brak zapisanych serii. Pusty trening nie jest wykonaniem.' : 'Trening może być częściowy. Zachowamy zapisane serie i dotychczasowy zapis czasu. Nie odtworzymy szkicu ani nie doliczymy czasu nieobecności. Niezapisane formularze i wyniki timera zostaną usunięte.'}',
          ),
          actions: [
            if (empty && (edit.row.guidanceJson != null || emptyPlan != null))
              SaveAsTemplateButton(
                sessionId: session.id,
                initialPlan: emptyPlan,
                beforeNavigate: () => Navigator.pop(c, false),
              ),
            if (empty)
              SessionDeleteButton(
                sessionId: session.id,
                label: 'Odrzuć pusty trening',
              ),
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Anuluj'),
            ),
            if (!empty)
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Zakończ sesję'),
              ),
          ],
        ),
      );
      if (confirmed != true || !mounted || authority.epoch != snapshot.epoch) {
        return;
      }
      await repo.finish(edit);
    } catch (_) {
      if (mounted && authority.epoch == snapshot.epoch) {
        setState(
          () => error = 'Nie udało się zakończyć treningu. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resume(
    SessionRecovery snapshot,
    RecoverableSession session,
  ) async {
    final authority = ref.read(cachedAuthWriteAuthorityProvider);
    if (busy ||
        authority.epoch != snapshot.epoch ||
        ref.read(activeWorkoutProvider).isActive) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final restored = await ref
          .read(activeWorkoutProvider.notifier)
          .resumeSession(
            session.syncId,
            expectedAccountId: snapshot.accountId,
            expectedAuthorityEpoch: snapshot.epoch,
          );
      if (mounted && authority.epoch == snapshot.epoch && !restored) {
        setState(
          () => error = 'Sesja lub konto uległy zmianie. Sprawdź ponownie.',
        );
      }
    } catch (_) {
      if (mounted && authority.epoch == snapshot.epoch) {
        setState(
          () => error = 'Nie udało się wznowić treningu. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recovery = ref.watch(sessionRecoveryProvider);
    final active = ref.watch(activeWorkoutProvider);
    void retry() {
      setState(() => error = null);
      ref.invalidate(sessionRecoveryProvider);
    }

    return recovery.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            Text('Sprawdzanie zapisanej sesji…'),
          ],
        ),
      ),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nie udało się odczytać zapisanej sesji.'),
            TextButton(onPressed: retry, child: const Text('Spróbuj ponownie')),
          ],
        ),
      ),
      data: (snapshot) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            snapshot.sessions.isEmpty
                ? 'Brak treningu do wznowienia dla aktywnego konta.'
                : snapshot.sessions.length == 1
                ? 'Znaleziono niedokończony trening'
                : 'Znaleziono kilka aktywnych sesji — wybierz trening',
          ),
          const Text(
            'Wznowienie nie zapisuje serii. Timer pozostanie w pauzie; czas nieobecności nie jest doliczany do pracy.',
          ),
          if (error != null) ...[
            Text(error!),
            TextButton(
              onPressed: busy ? null : retry,
              child: const Text('Spróbuj ponownie'),
            ),
          ],
          if (active.isActive)
            const Text(
              'Najpierw zakończ aktywny trening, aby wznowić inną sesję. Możesz zakończyć inną sesję bez jej wznawiania.',
            ),
          for (final session in snapshot.sessions.where(
            (s) => !active.isActive || s.syncId != active.sessionSyncId,
          ))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trening ${session.started.toLocal()}'),
                    Text('Sesja: ${session.syncId}'),
                    if (session.problem != null)
                      Text(session.problem!)
                    else
                      FilledButton(
                        onPressed: busy || active.isActive
                            ? null
                            : () => resume(snapshot, session),
                        child: const Text('Wznów trening'),
                      ),
                    TextButton(
                      onPressed: busy ? null : () => finish(snapshot, session),
                      child: const Text('Zakończ bez wznawiania'),
                    ),
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => context.push(
                                  '/workout/summary/${session.id}',
                                ),
                          child: const Text('Zobacz zapisane serie'),
                        ),
                        SessionDeleteButton(
                          sessionId: session.id,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (busy) const Center(child: CircularProgressIndicator()),
          TextButton(
            onPressed: busy ? null : () => context.go('/workout'),
            child: const Text('Wróć do treningów'),
          ),
        ],
      ),
    );
  }
}
