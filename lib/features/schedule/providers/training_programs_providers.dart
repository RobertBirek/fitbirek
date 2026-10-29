import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/providers/filter_presets_providers.dart';
import '../../exercises/providers/exercises_providers.dart';
import '../../planner/data/planner_repository.dart';
import '../../planner/providers/planner_providers.dart';
import '../data/schedule_repository.dart';
import '../data/training_programs_repository.dart';
import '../domain/training_program.dart';
import '../domain/training_program_schedule.dart';
import '../domain/weekly_schedule.dart';

final trainingProgramsRepositoryProvider = Provider<TrainingProgramsRepository>(
  (ref) => TrainingProgramsRepository(
    ref.watch(appDatabaseProvider),
    authority: ref.watch(cachedAuthWriteAuthorityProvider),
  ),
);

class TrainingProgramsWeek {
  TrainingProgramsWeek(
    this.programs,
    this.occurrences,
    this.plans,
    this.sessions,
    this.status,
    this.unavailable,
    this.writeError,
  );
  final TrainingPrograms programs;
  final List<ProgramOccurrence> occurrences;
  final List<SavedPlan> plans;
  final List<WorkoutSessionData> sessions;
  final Map<String, ScheduleCompletion> status;
  final Map<String, String> unavailable;
  final String? writeError;
}

/// Passive account subscription. Catalog futures settle outside SQLite; the
/// coherent snapshot observes remote proof deletion, restore and profile holds.
final trainingProgramsWeekProvider = StreamProvider.autoDispose
    .family<TrainingProgramsWeek?, CalendarDay>((ref, monday) {
      final binding = ref.watch(filterPresetsAccountProvider);
      final account = binding.isLoading || binding.hasError
          ? null
          : binding.valueOrNull;
      if (account == null) return Stream.value(null);
      final catalogFuture = ref.watch(allExercisesProvider.future);
      final metadataFuture = ref.watch(exerciseCatalogMetadataProvider.future);
      final db = ref.watch(appDatabaseProvider);
      final repo = ref.watch(trainingProgramsRepositoryProvider);
      final planner = ref.watch(plannerRepositoryProvider);
      final authority = ref.watch(cachedAuthWriteAuthorityProvider);
      final epoch = authority.epoch;
      var alive = true;
      ref.onDispose(() => alive = false);
      bool guard() => alive && authority.epoch == epoch;
      return (() async* {
        final catalog = await catalogFuture;
        final metadata = await metadataFuture;
        if (!guard()) return;
        yield* db
            .customSelect(
              'SELECT 1',
              readsFrom: {
                db.userProfiles,
                db.syncState,
                db.workoutPlans,
                db.workoutSessions,
                db.setsLog,
                db.syncDeferredRecords,
              },
            )
            .watch()
            .asyncMap(
              (_) => db.transaction(() async {
                final programs = await repo.load(account, isCurrent: guard);
                final occurrences = TrainingProgramSchedule(
                  programs,
                ).between(monday, monday.plus(6));
                final plans = await planner.readAll();
                final unavailable = <String, String>{};
                final ids = {
                  for (final p in plans)
                    if (p.syncId != null) p.syncId!,
                  for (final p in programs.entries.where(
                    (p) => p['kind'] == 'program',
                  ))
                    ...(p['planSyncIds'] as List).cast<String>(),
                  for (final o in occurrences) o.planSyncId,
                };
                for (final id in ids) {
                  try {
                    await repo.validatePlan(id, catalog, metadata);
                  } on StateError catch (e) {
                    unavailable[id] = e.message.toString();
                  } on FormatException catch (e) {
                    unavailable[id] = e.message;
                  }
                }
                final status = <String, ScheduleCompletion>{};
                for (final o in occurrences) {
                  status[o.id] = await repo.completionStatus(account, o);
                }
                final sessions = await repo.proof.eligibleSessions();
                final profile = (await db.userProfileDao.watchProfileOnce())!;
                String? writeError;
                try {
                  await assertScheduleWritable(db, profile.syncId);
                } on StateError catch (e) {
                  writeError = e.message.toString();
                }
                await repo.load(account, isCurrent: guard);
                return TrainingProgramsWeek(
                  programs,
                  occurrences,
                  plans,
                  sessions,
                  status,
                  unavailable,
                  writeError,
                );
              }),
            );
      })();
    });
