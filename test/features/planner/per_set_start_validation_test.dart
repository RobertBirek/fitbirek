import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import '../workout/per_set_guidance_provider_test.dart' show ramp;
import '../workout/session_tracking_test.dart' show exercise;

void main() {
  for (final invalid in [
    'missing',
    'tracking',
    'side-required',
    'side-forbidden',
    'selection',
  ]) {
    test(
      'v2 start rechecks live catalog: $invalid refuses without session/outbox',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            allExercisesProvider.overrideWith(
              (ref) => Stream.value(invalid == 'missing' ? [] : [exercise]),
            ),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => ExerciseCatalogMetadata(
                exercises: {
                  exercise.id: ExerciseCatalogEntry(
                    tracking: invalid == 'tracking' ? 'time' : 'reps',
                    unilateral: invalid == 'side-required',
                  ),
                },
              ),
            ),
          ],
        );
        addTearDown(() async {
          c.dispose();
          await db.close();
        });
        await c.read(allExercisesProvider.future);
        await expectLater(
          () => c.read(plannerWorkflowProvider).start([
            invalid == 'selection' ? exercise.copyWith(id: 'other') : exercise,
          ], plan: ramp(side: invalid == 'side-forbidden' ? 'both' : null)),
          throwsStateError,
        );
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect(await db.select(db.syncOutbox).get(), isEmpty);
      },
    );
  }
}
