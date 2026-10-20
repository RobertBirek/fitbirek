import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../exercises/providers/filter_presets_providers.dart';
import '../../planner/data/planner_repository.dart';
import '../../planner/providers/planner_providers.dart';
import '../data/schedule_repository.dart';
import '../data/activity_repository.dart';
import '../domain/weekly_schedule.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(
    ref.watch(appDatabaseProvider),
    authority: ref.watch(cachedAuthWriteAuthorityProvider),
  ),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(
    ref.watch(appDatabaseProvider),
    authority: ref.watch(cachedAuthWriteAuthorityProvider),
  ),
);

class ScheduleWeek {
  ScheduleWeek(
    this.schedule,
    this.occurrences,
    this.plans,
    this.sessions,
    this.status,
  );
  final WeeklySchedule schedule;
  final List<ScheduleOccurrence> occurrences;
  final List<SavedPlan> plans;
  final List<WorkoutSessionData> sessions;
  final Map<String, ScheduleCompletion> status;
}

/// A single SQLite invalidation stream covers remote delete, restore and sets.
/// No HTTP bootstrap and no persisted expansion of virtual calendar days.
final scheduleWeekProvider = StreamProvider.autoDispose
    .family<ScheduleWeek?, CalendarDay>((ref, monday) {
      final binding = ref.watch(filterPresetsAccountProvider);
      final account = binding.isLoading || binding.hasError
          ? null
          : binding.valueOrNull;
      if (account == null) return Stream.value(null);
      final db = ref.watch(appDatabaseProvider);
      final repo = ref.watch(scheduleRepositoryProvider);
      final planner = ref.watch(plannerRepositoryProvider);
      final authority = ref.watch(cachedAuthWriteAuthorityProvider);
      final epoch = authority.epoch;
      var alive = true;
      ref.onDispose(() => alive = false);
      bool guard() => alive && authority.epoch == epoch;
      return db
          .customSelect(
            'SELECT 1',
            readsFrom: {
              db.userProfiles,
              db.syncState,
              db.workoutPlans,
              db.workoutSessions,
              db.setsLog,
            },
          )
          .watch()
          .asyncMap(
            (_) => db.transaction(() async {
              final schedule = await repo.load(account, isCurrent: guard);
              final occurrences = schedule.between(monday, monday.plus(6));
              final plans = await planner.readAll();
              final ended =
                  await (db.select(db.workoutSessions)..where(
                        (s) =>
                            s.deletedAtUtc.isNull() & s.dataKoniec.isNotNull(),
                      ))
                      .get();
              final sets = await (db.select(
                db.setsLog,
              )..where((s) => s.deletedAtUtc.isNull())).get();
              final actual = sets.map((s) => s.sesjaId).toSet();
              final status = <String, ScheduleCompletion>{};
              for (final o in occurrences) {
                status[o.id] = await repo.completionStatus(account, o);
              }
              await repo.load(account, isCurrent: guard);
              return ScheduleWeek(
                schedule,
                occurrences,
                plans,
                ended.where((s) => actual.contains(s.id)).toList()
                  ..sort((a, b) => b.dataStart.compareTo(a.dataStart)),
                status,
              );
            }),
          );
    });
