import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/user_profile_table.dart';
import 'tables/exercises_table.dart';
import 'tables/workout_tables.dart';
import 'tables/mood_table.dart';
import 'tables/measurements_table.dart';
import 'tables/tests_table.dart';
import 'tables/prs_table.dart';
import 'tables/plans_table.dart';

import 'daos/user_profile_dao.dart';
import 'daos/exercises_dao.dart';
import 'daos/workout_dao.dart';
import 'daos/mood_dao.dart';
import 'daos/measurements_dao.dart';
import 'daos/tests_dao.dart';
import 'daos/prs_dao.dart';
import 'daos/plans_dao.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Konstruktor testowy - pozwala wstrzyknąć własne połączenie (np. in-memory).
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fitbirek.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
