import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'connection/connection.dart';
import 'tables/user_profile_table.dart';
import 'tables/exercises_table.dart';
import 'tables/workout_tables.dart';
import 'tables/mood_table.dart';
import 'tables/measurements_table.dart';
import 'tables/tests_table.dart';
import 'tables/prs_table.dart';
import 'tables/plans_table.dart';
import 'tables/sync_tables.dart';
import 'tables/health_samples_table.dart';

import 'daos/user_profile_dao.dart';
import 'daos/exercises_dao.dart';
import 'daos/workout_dao.dart';
import 'daos/mood_dao.dart';
import 'daos/measurements_dao.dart';
import 'daos/tests_dao.dart';
import 'daos/prs_dao.dart';
import 'daos/plans_dao.dart';
import 'daos/sync_dao.dart';

part 'app_database.g.dart';

/// Główna baza danych aplikacji FitBirek - Drift (SQLite ORM).
/// Zobacz ARCHITECTURE.md - dlaczego Drift a nie Hive.
@DriftDatabase(
  tables: [
    UserProfiles,
    Exercises,
    WorkoutSessions,
    SetsLog,
    MoodEntries,
    Measurements,
    FitnessTestResults,
    PersonalRecords,
    WorkoutPlans,
    SyncState,
    SyncOutbox,
    SyncDeferredRecords,
    ExerciseFavorites,
    HealthSamples,
  ],
  daos: [
    UserProfileDao,
    ExercisesDao,
    WorkoutDao,
    MoodDao,
    MeasurementsDao,
    TestsDao,
    PrsDao,
    PlansDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  // Konstruktor testowy - pozwala wstrzyknąć własne połączenie (np. in-memory).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 5) await m.createTable(healthSamples);
      if (from < 6) await m.addColumn(syncState, syncState.healthReplayEnabled);
      if (from < 7) await m.addColumn(syncState, syncState.fullCursor);
      if (from == 2) {
        await m.addColumn(syncOutbox, syncOutbox.attempted);
        await m.addColumn(syncOutbox, syncOutbox.preserveLocal);
        await m.addColumn(syncState, syncState.offlineAccess);
      }
      if (from < 4) {
        await m.createTable(syncDeferredRecords);
        // The new full_cursor default 0 replays discarded v3 payloads too.
        // Never reset the legacy cursor: old tabs still own that watermark.
      }
    },
  );
}
