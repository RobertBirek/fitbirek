import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/content_layout.dart';
import '../../../../core/widgets/recovery_message.dart';
import '../../../exercises/providers/exercises_providers.dart';
import '../../providers/planner_providers.dart';

Future<bool> confirmTemplateAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
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
    ) ??
    false;

class TemplatesPage extends ConsumerStatefulWidget {
  const TemplatesPage({super.key});
  @override
  ConsumerState<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends ConsumerState<TemplatesPage> {
  bool busy = false;
  Future<void> act(String syncId, {required bool delete}) async {
    setState(() => busy = true);
    try {
      final workflow = ref.read(plannerWorkflowProvider);
      final lease = await workflow.openTemplate(syncId: syncId);
      if (!mounted) return;
      if (!await confirmTemplateAction(
        context,
        delete ? 'Usunąć szablon?' : 'Rozpocząć trening?',
        delete
            ? 'Usunięcie szablonu nie zmienia historii treningów.'
            : 'Powstanie nowa sesja bez wykonanych serii. Bieżący trening nie zostanie zastąpiony.',
      )) {
        return;
      }
      if (!mounted) return;
      if (delete) {
        await workflow.deleteTemplate(lease);
      } else {
        final catalog = ref.read(allExercisesProvider).requireValue;
        await workflow.startTemplate(lease, catalog);
        if (mounted) context.go('/workout/session');
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Moje szablony')),
    body: ref
        .watch(savedPlansProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => RecoveryMessage(
            message: 'Nie można odczytać szablonów.',
            onRetry: () => ref.invalidate(savedPlansProvider),
            backLabel: 'Wróć do treningów',
            backLocation: '/workout',
          ),
          data: (plans) => ContentLayout(
            child: ListView(
              padding: ContentLayout.pagePadding(context),
              children: [
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => context.push('/workout/templates/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nowy szablon'),
                ),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => context.go('/today', extra: 'template'),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Utwórz szablon z Mentorem'),
                ),
                if (plans.isEmpty)
                  const Text('Ułóż własny szablon bez rozpoczynania treningu.'),
                for (final plan in plans)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.nazwa,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            plan.structureError ??
                                (plan.structure == null
                                    ? 'Starszy plan — brak zapisanych celów.'
                                    : '${plan.cwiczeniaIds.length} ćwiczeń · czas ESTYMOWANY ${(plan.structure!.estimatedSeconds / 60).ceil()} min'),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed:
                                    busy ||
                                        plan.isUnavailable ||
                                        plan.syncId == null
                                    ? null
                                    : () => context.push(
                                        '/workout/templates/${plan.syncId}/edit',
                                      ),
                                child: const Text('Edytuj'),
                              ),
                              TextButton(
                                onPressed:
                                    busy ||
                                        plan.isUnavailable ||
                                        plan.syncId == null ||
                                        !ref
                                            .watch(allExercisesProvider)
                                            .hasValue
                                    ? null
                                    : () => act(plan.syncId!, delete: false),
                                child: const Text('Start'),
                              ),
                              TextButton(
                                onPressed: busy || plan.syncId == null
                                    ? null
                                    : () => act(plan.syncId!, delete: true),
                                child: const Text('Usuń'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
  );
}
