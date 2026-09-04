import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/workout_providers.dart';

/// Podsumowanie zakończonej sesji treningowej.
class SessionSummaryPage extends ConsumerWidget {
  const SessionSummaryPage({super.key, required this.sessionId});
  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Podsumowanie treningu')),
      body: FutureBuilder(
        future: repo.getSetsForSession(sessionId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sets = snapshot.data!;
          if (sets.isEmpty) {
            return const Center(child: Text('Brak zalogowanych serii'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets.length,
            itemBuilder: (context, i) {
              final s = sets[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${s.nazwaCwiczeniaPl} - seria ${s.numerSerii}'),
                  subtitle: Text(
                    '${s.ciezarKg ?? '-'} kg × ${s.powtorzenia ?? '-'} (RPE ${s.rpe ?? '-'}) • ${Formatters.time(s.timestamp)}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
