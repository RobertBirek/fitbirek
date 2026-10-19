import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../domain/workout_guidance.dart';
import '../../domain/workout_repeat.dart';
import '../../domain/workout_progress.dart';
import '../../../../core/database/app_database.dart';

final sessionLiveSetsProvider = StreamProvider.autoDispose
    .family<List<SetLogData>, int>((ref, id) {
      final db = ref.watch(appDatabaseProvider);
      return (db.select(
        db.setsLog,
      )..where((s) => s.sesjaId.equals(id) & s.deletedAtUtc.isNull())).watch();
    });

class SessionProgressText extends ConsumerWidget {
  const SessionProgressText({
    super.key,
    required this.sessionId,
    this.guidance,
    this.repeat,
    this.repeatCompleted = const [],
  });
  final int sessionId;
  final WorkoutGuidance? guidance;
  final WorkoutRepeat? repeat;
  final List<String> repeatCompleted;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sets = ref.watch(sessionLiveSetsProvider(sessionId));
    return sets.when(
      data: (rows) => Text(
        WorkoutProgress.from(
          liveSetIds: rows.map((s) => s.syncId),
          guidance: guidance,
          repeat: repeat,
          repeatCompleted: repeatCompleted,
        ).label,
      ),
      loading: () => const Text('Odczytywanie postępu…'),
      error: (_, _) => const Text('Postęp niedostępny.'),
    );
  }
}
