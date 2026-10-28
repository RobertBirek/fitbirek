import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'schema15 adds nullable role and programs without backfilling legacy',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 15);
      final session = await WorkoutRepository(db).startSession();
      await WorkoutRepository(db).logSet(
        sessionId: session,
        exerciseId: 'cw001',
        exerciseNamePl: 'Legacy',
        setNumber: 1,
        reps: 8,
      );
      expect(
        (await db.customSelect('SELECT set_role FROM sets_log').getSingle())
            .data['set_role'],
        isNull,
      );
      expect(
        (await db.customSelect('PRAGMA table_info(user_profiles)').get()).map(
          (r) => r.data['name'],
        ),
        contains('training_programs_json'),
      );
      await expectLater(
        db.customStatement("UPDATE sets_log SET set_role = 'invalid'"),
        throwsA(anything),
      );
    },
  );
  test(
    'real v14 reopen adds only two columns and preserves attempted bytes',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      var db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      final session = await WorkoutRepository(db).startSession();
      await WorkoutRepository(db).logSet(
        sessionId: session,
        exerciseId: 'cw001',
        exerciseNamePl: 'Legacy',
        setNumber: 1,
        reps: 8,
      );
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      await db
          .into(db.userProfiles)
          .insert(
            UserProfilesCompanion.insert(
              wiek: 40,
              wzrostCm: 180,
              wagaKg: 80,
              cel: 'mix',
              dostepnySprzet: '[]',
              syncId: const Value('legacy-profile'),
            ),
          );
      final before =
          (await db
                  .customSelect(
                    'SELECT * FROM sync_outbox ORDER BY operation_id',
                  )
                  .get())
              .map((r) => r.data)
              .toList();
      final cols = await db.customSelect('PRAGMA table_info(sets_log)').get();
      if (cols.any((c) => c.data['name'] == 'set_role')) {
        await db.customStatement('ALTER TABLE sets_log DROP COLUMN set_role');
        await db.customStatement(
          'ALTER TABLE user_profiles DROP COLUMN training_programs_json',
        );
      }
      await db.customStatement('PRAGMA user_version = 14');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);
      final profile = await db.userProfileDao.watchProfileOnce();
      expect(profile!.trainingProgramsJson, isNull);
      expect(profile.syncId, 'legacy-profile');
      expect(profile.wiek, 40);
      expect(
        (await db.customSelect('SELECT set_role FROM sets_log').getSingle())
            .data['set_role'],
        isNull,
      );
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .data['user_version'],
        15,
      );
      expect(
        (await db
                .customSelect('SELECT * FROM sync_outbox ORDER BY operation_id')
                .get())
            .map((r) => r.data)
            .toList(),
        before,
      );
    },
  );
}
