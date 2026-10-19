import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../planner/domain/structured_plan.dart';
import '../../../planner/presentation/widgets/save_as_template_button.dart';
import '../../data/session_actions_repository.dart';
import '../../domain/workout_progress.dart';
import '../../domain/empty_session_template.dart';
import '../../providers/workout_providers.dart';
import 'session_delete_button.dart';

class SessionFinishButton extends ConsumerStatefulWidget {
  const SessionFinishButton({super.key});
  @override
  ConsumerState<SessionFinishButton> createState() =>
      _SessionFinishButtonState();
}

class _SessionFinishButtonState extends ConsumerState<SessionFinishButton> {
  bool busy = false;

  StructuredPlan? emptyTemplate(ActiveWorkoutState active) {
    if (active.guidance != null) return active.guidance!.plan;
    final metadata = ref.read(exerciseCatalogMetadataProvider).valueOrNull;
    if (active.selectedExercises.isEmpty || metadata == null) return null;
    try {
      return templateFromSelection(
        active.selectedExercises,
        metadata,
        repeat: active.repeat,
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> finish() async {
    if (busy) return;
    setState(() => busy = true);
    final authority = ref.read(cachedAuthWriteAuthorityProvider),
        epoch = ref.read(cachedAuthWriteAuthorityProvider).epoch;
    final shown = ref.read(activeWorkoutProvider);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    var note = '';
    try {
      await notifier.flushDraft();
      if (!mounted ||
          authority.epoch != epoch ||
          ref.read(activeWorkoutProvider).sessionSyncId !=
              shown.sessionSyncId) {
        return;
      }
      final repo = SessionActionsRepository(
        ref.read(appDatabaseProvider),
        authority,
      );
      final edit = shown.sessionId == null
          ? null
          : await repo.capture(shown.sessionId!);
      if (!mounted || authority.epoch != epoch) return;
      final empty = edit == null || edit.sets.isEmpty;
      final plan = empty ? emptyTemplate(shown) : null;
      final progress = WorkoutProgress.from(
        liveSetIds: edit?.sets.map((s) => s.syncId) ?? [],
        guidance: shown.guidance,
        repeat: shown.repeat,
        repeatCompleted: List<String>.from(
          shown.draft['repeatCompleted'] as List? ?? [],
        ),
      );
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          scrollable: true,
          title: Text(empty ? 'Pusty trening' : 'Zakończyć trening?'),
          content: empty
              ? Text(
                  'Brak zapisanych serii. Wybrane cele nie są wykonaniem; nie utworzymy zakończonego treningu.${plan == null && shown.selectedExercises.isNotEmpty ? '\nNie można bezstratnie skopiować celów do szablonu (brak metadanych, różne cele, strony, warianty lub nieobsługiwany sposób śledzenia). Ułóż szablon ręcznie; niczego nie pominięto.' : ''}',
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${progress.label}\nPozostałe serie celu: ${progress.remaining}. Możesz świadomie zakończyć częściowe wykonanie. Niezapisane formularze i wyniki timera zostaną odrzucone; nie staną się seriami.',
                    ),
                    TextField(
                      onChanged: (value) => note = value,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Krótka notatka (opcjonalna)',
                      ),
                    ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Wróć'),
            ),
            if (empty && plan != null)
              SaveAsTemplateButton(
                initialPlan: plan,
                beforeNavigate: () => Navigator.pop(c, false),
              ),
            if (empty && shown.sessionId != null)
              SessionDeleteButton(
                sessionId: shown.sessionId!,
                label: 'Odrzuć pusty trening',
                onDeleted: () {
                  Navigator.pop(c, false);
                  context.go('/workout');
                },
              ),
            if (empty && shown.sessionId == null)
              TextButton(
                onPressed: () {
                  if (authority.epoch != epoch ||
                      ref.read(activeWorkoutProvider).sessionId != null) {
                    return;
                  }
                  Navigator.pop(c, false);
                  notifier.discardSession();
                  context.go('/workout');
                },
                child: const Text('Odrzuć pusty trening'),
              ),
            if (!empty)
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Zakończ'),
              ),
          ],
        ),
      );
      if (yes != true ||
          !mounted ||
          authority.epoch != epoch ||
          ref.read(activeWorkoutProvider).sessionSyncId !=
              shown.sessionSyncId) {
        return;
      }
      await notifier.finishSession(note: note, expectedEdit: edit);
      if (mounted &&
          authority.epoch == epoch &&
          !ref.read(activeWorkoutProvider).isActive) {
        context.go('/workout/summary/${shown.sessionId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: busy ? null : finish, child: const Text('Zakończ'));
}
