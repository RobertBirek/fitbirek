import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/progress/tests/data/tests_repository.dart';
import 'package:fitbirek_training/core/models/fitness_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'database/legacy_schema.dart';

void main() {
  test(
    'v13 to14 adds only nullable extensions, preserves legacy date score and attempted bytes',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      var db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await TestsRepository(db).addResult(typ: TypTestu.maxPompki, wynik: 12);
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final rows = (await db.select(db.fitnessTestResults).get())
          .map((r) => r.toJson()..remove('customProtocolJson'))
          .toList();
      final outbox = (await db.customSelect('SELECT * FROM sync_outbox').get())
          .map((r) => r.data)
          .toList();
      await removeV14Columns(db);
      await db.customStatement('PRAGMA user_version = 13');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);
      expect(db.schemaVersion, 14);
      final after = await db.select(db.fitnessTestResults).get();
      expect(after.single.customProtocolJson, isNull);
      expect(
        after.map((r) => r.toJson()..remove('customProtocolJson')).toList(),
        rows,
      );
      expect(
        (await db.customSelect('SELECT * FROM sync_outbox').get())
            .map((r) => r.data)
            .toList(),
        outbox,
      );
      expect(
        (await db.customSelect('PRAGMA table_info(user_profiles)').get()).any(
          (r) =>
              r.data['name'] == 'fitness_protocols_json' &&
              r.data['notnull'] == 0,
        ),
        isTrue,
      );
    },
  );
}
