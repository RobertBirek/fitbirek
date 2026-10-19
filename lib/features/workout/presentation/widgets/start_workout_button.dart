import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/exercise.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/workout_repository.dart';
import '../../providers/session_recovery_provider.dart';
import '../../providers/workout_providers.dart';

/// One explicit start/add intent. Recovery only carries the exercise ID; it
/// never schedules a deferred addition to an unknown or subsequently resumed session.
class StartWorkoutButton extends ConsumerStatefulWidget {
  const StartWorkoutButton({super.key, this.exercise});
  final Exercise? exercise;

  @override
  ConsumerState<StartWorkoutButton> createState() => _StartWorkoutButtonState();
}

class _StartWorkoutButtonState extends ConsumerState<StartWorkoutButton> {
  bool busy = false;

  Future<void> recover() async {
    final id = widget.exercise?.id;
    await context.push<void>(
      Uri(
        path: '/workout/recovery',
        queryParameters: {if (id != null) 'exercise': id},
      ).toString(),
    );
  }

  Future<void> start(int epoch) async {
    final authority = ref.read(cachedAuthWriteAuthorityProvider);
    if (busy || authority.epoch != epoch) return;
    setState(() => busy = true);
    try {
      final snapshot = ref.read(sessionRecoveryProvider);
      if (!ref.read(activeWorkoutProvider).isActive) {
        if (snapshot.isLoading || snapshot.hasError || !snapshot.hasValue) {
          return;
        }
        if (snapshot.requireValue.sessions.isNotEmpty) {
          await recover();
          return;
        }
      }
      final notifier = ref.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      if (!mounted || authority.epoch != epoch) return;
      if (!ref.read(activeWorkoutProvider).isActive) {
        throw StateError('Session not started');
      }
      final exercise = widget.exercise;
      if (exercise != null) {
        if (ref
            .read(activeWorkoutProvider)
            .selectedExercises
            .any((e) => e.id == exercise.id)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ćwiczenie jest już w treningu. Zachowano jego cele i formularz; nie dodano kopii.',
              ),
            ),
          );
        } else {
          notifier.addExercise(exercise);
        }
      }
      context.go('/workout/session');
    } on ActiveSessionExists {
      if (mounted && authority.epoch == epoch) await recover();
    } catch (_) {
      if (mounted && authority.epoch == epoch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nie udało się otworzyć treningu. Sprawdź konto i spróbuj ponownie.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeWorkoutProvider).isActive;
    final recovery = ref.watch(sessionRecoveryProvider);
    final epoch = ref.watch(cachedAuthWriteAuthorityProvider).epoch;
    final unavailable =
        !active &&
        (recovery.isLoading || recovery.hasError || !recovery.hasValue);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(
          label: widget.exercise != null
              ? (active
                    ? 'Dodaj wybrane ćwiczenie i przejdź do sesji'
                    : 'Rozpocznij trening z tym ćwiczeniem')
              : (active ? 'Wróć do aktywnej sesji' : 'Nowy trening'),
          icon: Icons.play_arrow,
          isLoading: busy || (!active && recovery.isLoading),
          onPressed: unavailable ? null : () => start(epoch),
        ),
        if (!active && recovery.hasError)
          TextButton(
            onPressed: () => ref.invalidate(sessionRecoveryProvider),
            child: const Text(
              'Nie udało się sprawdzić sesji. Spróbuj ponownie',
            ),
          ),
      ],
    );
  }
}
