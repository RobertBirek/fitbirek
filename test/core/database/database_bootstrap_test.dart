import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/database/database_names.dart';

void main() {
  test('defines the clean-slate v2 database names', () {
    expect(nativeDatabaseName, 'fitbirek_v2.sqlite');
    expect(webDatabaseName, 'fitbirek_v2');
  });

  test('opens the v2 database with an empty sync state', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    expect(await db.syncDao.readState(), isNull);

    await db.close();
  });

  test('permits only SyncState singleton id 1', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await db.into(db.syncState).insert(
      SyncStateCompanion.insert(
        id: const Value(1),
        accountId: 'account-1',
        deviceId: 'device-1',
      ),
    );

    await expectLater(
      db.into(db.syncState).insert(
        SyncStateCompanion.insert(
          id: const Value(2),
          accountId: 'account-2',
          deviceId: 'device-2',
        ),
      ),
      throwsA(isA<SqliteException>()),
    );

    expect((await db.syncDao.readState())!.id, 1);

    await db.close();
  });
}
