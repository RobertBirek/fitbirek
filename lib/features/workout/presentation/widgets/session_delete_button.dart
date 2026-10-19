import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../data/session_actions_repository.dart';
import '../../providers/workout_providers.dart';

class SessionDeleteButton extends ConsumerStatefulWidget {
  const SessionDeleteButton({
    super.key,
    required this.sessionId,
    this.compact = false,
    this.label = 'Usuń trening',
    this.onDeleted,
  });
  final int sessionId;
  final bool compact;
  final String label;
  final VoidCallback? onDeleted;
  @override
  ConsumerState<SessionDeleteButton> createState() =>
      _SessionDeleteButtonState();
}

class _SessionDeleteButtonState extends ConsumerState<SessionDeleteButton> {
  bool busy = false;
  Future<void> remove() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final repo = SessionActionsRepository(
        ref.read(appDatabaseProvider),
        ref.read(cachedAuthWriteAuthorityProvider),
      );
      final edit = await repo.capture(widget.sessionId);
      if (!mounted || repo.authority.epoch != edit.epoch) return;
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          scrollable: true,
          title: const Text('Usunąć trening?'),
          content: Text(
            '${Formatters.date(edit.row.dataStart)} • ${edit.sets.length} zapisanych serii.\nUsuniemy trening, wszystkie jego serie i lokalny szkic także z synchronizowanych urządzeń. Szablon pozostanie. Oddzielnie zapisane rekordy osobiste (PR) pozostają — nie mają powiązania z sesją.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Wróć'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Usuń trening'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
      await repo.delete(edit);
      if (mounted && repo.authority.epoch == edit.epoch) {
        if (ref.read(activeWorkoutProvider).sessionSyncId == edit.row.syncId) {
          ref.read(activeWorkoutProvider.notifier).discardSession();
        }
        if (widget.onDeleted case final onDeleted?) {
          onDeleted();
        } else {
          context.go('/workout');
        }
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
  Widget build(BuildContext context) => widget.compact
      ? IconButton(
          onPressed: busy ? null : remove,
          icon: const Icon(Icons.delete_outline),
          tooltip: widget.label,
        )
      : TextButton.icon(
          onPressed: busy ? null : remove,
          icon: const Icon(Icons.delete_outline),
          label: Text(widget.label),
        );
}
