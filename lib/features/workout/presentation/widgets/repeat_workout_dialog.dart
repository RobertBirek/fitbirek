import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_providers.dart';
import '../../domain/workout_repeat.dart';

class RepeatWorkoutDialog extends ConsumerStatefulWidget {
  const RepeatWorkoutDialog({super.key, required this.sessionId});
  final int sessionId;
  @override
  ConsumerState<RepeatWorkoutDialog> createState() =>
      _RepeatWorkoutDialogState();
}

class _RepeatWorkoutDialogState extends ConsumerState<RepeatWorkoutDialog> {
  RepeatWorkoutRequest? request;
  bool busy = false;
  String? error;
  Future<void> preview(RepeatMode mode) async {
    setState(() {
      busy = true;
      error = null;
      request = null;
    });
    try {
      final next = await ref
          .read(activeWorkoutProvider.notifier)
          .previewRepeat(widget.sessionId, mode);
      if (mounted) setState(() => request = next);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Nie udało się odczytać źródła. Spróbuj ponownie.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Powtórz trening — nowa sesja'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wybierz źródło celów. Historia pozostanie bez zmian. Każdą nową serię zapisujesz osobno; poprzednie RPE jest tylko informacją.',
            ),
            OutlinedButton(
              onPressed: busy ? null : () => preview(RepeatMode.original),
              child: const Text('Oryginalny plan (snapshot)'),
            ),
            OutlinedButton(
              onPressed: busy ? null : () => preview(RepeatMode.execution),
              child: const Text('Potwierdzone wykonanie (wszystkie serie)'),
            ),
            if (busy) const LinearProgressIndicator(),
            if (error != null) Text(error!),
            if (ref.watch(activeWorkoutProvider).isActive)
              const Text(
                'Masz aktywną sesję. Zakończ ją lub kontynuuj; nie zostanie porzucona.',
              ),
            if (request != null) ...[
              for (final issue in request!.preview.issues) Text(issue),
              if (request!.preview.mode == RepeatMode.execution)
                const Text(
                  'Sekundy są celami pojedynczych serii, nie odtworzonym protokołem interwałów. Cele powtórzenia są lokalnym szkicem na tym urządzeniu.',
                ),
              for (final (i, t)
                  in (request!.preview.repeat?.targets ?? <RepeatSetTarget>[])
                      .indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${i + 1}. ${t.name} • ${t.exerciseId} • ${t.side ?? 'strona nieokreślona'}'
                    '${t.variantId == null ? ' • bazowy' : ' • ${t.variantLabel} (${t.variantId})'}'
                    '\nCel: ${[if (t.reps != null) '${t.reps} powt.', if (t.seconds != null) '${t.seconds} s', if (t.weightKg != null) '${t.weightKg} kg'].join(' • ')}'
                    '${t.previousRpe == null ? '' : ' • RPE poprzednio: ${t.previousRpe} (nie nowy pomiar)'}',
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context, false),
        child: const Text('Anuluj'),
      ),
      FilledButton(
        onPressed:
            busy ||
                request?.preview.canStart != true ||
                ref.watch(activeWorkoutProvider).isActive
            ? null
            : () async {
                setState(() {
                  busy = true;
                  error = null;
                });
                try {
                  final ok = await ref
                      .read(activeWorkoutProvider.notifier)
                      .confirmRepeat(request!);
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(context, true);
                    return;
                  }
                  setState(
                    () => error =
                        'Źródło, konto lub aktywna sesja zmieniły się. Otwórz nowy podgląd.',
                  );
                } catch (_) {
                  if (mounted) {
                    setState(
                      () => error =
                          'Nie rozpoczęto sesji. Sprawdź stan treningu przed ponowną próbą.',
                    );
                  }
                } finally {
                  if (mounted) setState(() => busy = false);
                }
              },
        child: const Text('Rozpocznij nową sesję'),
      ),
    ],
  );
}
