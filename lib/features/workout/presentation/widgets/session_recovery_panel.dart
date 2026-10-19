import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/session_recovery_provider.dart';
import '../../providers/workout_providers.dart';

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
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Zakończyć bez wznawiania?'),
          content: const Text(
            'Zachowamy zapisane serie i dotychczasowy zapis czasu. Nie odtworzymy szkicu ani nie doliczymy czasu nieobecności. Niezapisany szkic zostanie usunięty.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Anuluj'),
            ),
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
      final id = await ref
          .read(activeWorkoutProvider.notifier)
          .finishPendingSession(
            session.syncId,
            expectedAccountId: snapshot.accountId,
            expectedAuthorityEpoch: snapshot.epoch,
          );
      if (mounted && authority.epoch == snapshot.epoch && id == null) {
        setState(
          () => error = 'Sesja lub konto uległy zmianie. Sprawdź ponownie.',
        );
      }
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
    if (busy || authority.epoch != snapshot.epoch) return;
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
          for (final session in snapshot.sessions)
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
                        onPressed: busy
                            ? null
                            : () => resume(snapshot, session),
                        child: const Text('Wznów trening'),
                      ),
                    TextButton(
                      onPressed: busy ? null : () => finish(snapshot, session),
                      child: const Text('Zakończ bez wznawiania'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () =>
                                context.push('/workout/summary/${session.id}'),
                      child: const Text('Zobacz zapisane serie'),
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
