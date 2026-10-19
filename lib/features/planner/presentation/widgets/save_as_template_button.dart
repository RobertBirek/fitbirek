import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../../workout/domain/workout_guidance.dart';
import '../../../workout/providers/workout_providers.dart';
import '../../domain/structured_plan.dart';
import '../../domain/session_template.dart';
import '../../providers/planner_providers.dart';
import '../pages/template_editor_page.dart';

/// Task2 can pass an explicit selected-exercise target snapshot to this button.
/// Merely opening the editor never creates or updates a session/template.
class SaveAsTemplateButton extends ConsumerStatefulWidget {
  const SaveAsTemplateButton({
    super.key,
    this.sessionId,
    this.initialPlan,
    this.beforeNavigate,
  }) : assert(sessionId != null || initialPlan != null);
  final int? sessionId;
  final StructuredPlan? initialPlan;

  /// Dismiss a decision dialog before pushing into the shell navigator.
  final VoidCallback? beforeNavigate;
  @override
  ConsumerState<SaveAsTemplateButton> createState() =>
      _SaveAsTemplateButtonState();
}

class _SaveAsTemplateButtonState extends ConsumerState<SaveAsTemplateButton> {
  bool busy = false;
  Future<void> open() async {
    setState(() => busy = true);
    try {
      final workflow = ref.read(plannerWorkflowProvider);
      final lease = await workflow.openTemplate();
      var plan = widget.initialPlan;
      if (plan == null) {
        final db = ref.read(appDatabaseProvider);
        final session = await db.workoutDao.getSession(widget.sessionId!);
        if (session == null || session.deletedAtUtc != null) {
          throw StateError('Trening jest niedostępny.');
        }
        if (session.guidanceJson != null) {
          final guidance = WorkoutGuidance.tryRead(session.guidanceJson);
          if (guidance == null) {
            throw StateError(
              'Snapshot celów jest nieobsługiwany lub uszkodzony. Niczego nie pominięto.',
            );
          }
          plan = guidance.plan;
        } else {
          final sets = await ref
              .read(workoutRepositoryProvider)
              .getSetsForSession(widget.sessionId!);
          final metadata = await ref.read(
            exerciseCatalogMetadataProvider.future,
          );
          plan = templateFromSets(sets, metadata);
        }
      }
      if (plan.blocks.isEmpty ||
          plan.blocks.any(
            (block) => !{'reps', 'time'}.contains(block.prescription.tracking),
          )) {
        throw StateError(
          'Źródło nie zawiera obsługiwanych celów powtórzeń lub sekund. Niczego nie pominięto.',
        );
      }
      // Revalidate the original account epoch/device after all async reads.
      await workflow.validateTemplateLease(lease);
      if (!mounted) return;
      final choices = await workflow.templateUpdateChoices(lease);
      if (!mounted) return;
      // A selection is only a preview. No writes until the editor's explicit
      // save confirmation; cancellation also leaves the session untouched.
      final selected = await showDialog<TemplateLease>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Zapisz cele treningu'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, lease),
              child: const Text('Nowy szablon'),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Zaktualizuj istniejący — wybierz szablon. Zapis zastąpi jego cele; historia treningów pozostanie bez zmian.',
              ),
            ),
            for (final choice in choices)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, choice),
                child: Text(choice.baseline!.nazwa),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
          ],
        ),
      );
      if (selected == null) return;
      await workflow.validateTemplateLease(lease);
      if (!identical(selected, lease)) {
        await workflow.validateTemplateLease(selected);
      }
      if (!mounted) return;
      final router = GoRouter.of(context);
      widget.beforeNavigate?.call();
      router.push(
        '/workout/templates/new',
        extra: TemplateEditorSeed(
          plan,
          name: 'Kopia treningu',
          lease: lease,
          updateLease: identical(selected, lease) ? null : selected,
        ),
      );
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
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: busy ? null : open,
    icon: const Icon(Icons.copy),
    label: const Text('Zapisz jako szablon'),
  );
}
