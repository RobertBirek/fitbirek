import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'database/legacy_schema.dart';

void main() {
  test(
    'v11 restart migrates NULL base rows without rewriting attempted operations',
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
      final before =
          (await db
                  .customSelect(
                    'SELECT * FROM sync_outbox ORDER BY operation_id',
                  )
                  .get())
              .map((r) => r.data)
              .toList();
      await removeV12Columns(db);
      await db.customStatement('PRAGMA user_version = 11');
      await db.close();
      db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      expect((await db.select(db.setsLog).getSingle()).variantId, isNull);
      expect((await db.select(db.setsLog).getSingle()).variantLabel, isNull);
      expect(
        (await db
                .customSelect('SELECT * FROM sync_outbox ORDER BY operation_id')
                .get())
            .map((r) => r.data)
            .toList(),
        before,
      );
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);
      expect((await db.select(db.setsLog).getSingle()).variantId, isNull);
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .data
            .values
            .single,
        15,
      );
    },
  );
  test('Drift12 nullable extensions preserve legacy rows', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 15);
    final profiles = await db
        .customSelect('PRAGMA table_info(user_profiles)')
        .get();
    expect(
      profiles.map((r) => r.data['name']),
      containsAll(['filter_presets_json', 'exercise_variants_json']),
    );
    for (final table in ['sets_log', 'personal_records']) {
      final cols = await db.customSelect('PRAGMA table_info($table)').get();
      expect(
        cols.map((r) => r.data['name']),
        containsAll(['variant_id', 'variant_label']),
      );
    }
  });
}
