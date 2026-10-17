import 'package:drift/native.dart';
import '../../core/database/legacy_schema.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';

void main() {
  test(
    'real v10 shape upgrades additively and leaves attempted legacy bytes intact',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      var db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await WorkoutRepository(db).startSession();
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final before =
          (await db.customSelect('SELECT * FROM sync_outbox').getSingle()).data;
      await db.customStatement(
        'ALTER TABLE workout_sessions DROP COLUMN guidance_json',
      );
      await db.customStatement('DROP TABLE workout_drafts');
      await removeV12Columns(db);
      await db.customStatement('PRAGMA user_version = 10');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);
      expect(
        (await db.select(db.workoutSessions).getSingle()).guidanceJson,
        isNull,
      );
      expect(await db.select(db.workoutDrafts).get(), isEmpty);
      expect(
        (await db.customSelect('SELECT * FROM sync_outbox').getSingle()).data,
        before,
      );
      expect(db.schemaVersion, 12);
    },
  );
}
