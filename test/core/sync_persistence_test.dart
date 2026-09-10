import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'sync_service_test.dart' show FakeSyncApi;

void main() {
  test(
    'SQLite reopen keeps immutable attempted request and later local edit',
    () async {
      final directory = await Directory(
        '.dart_tool',
      ).createTemp('sync-restart-');
      final file = File('${directory.path}/db.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      final api = FakeSyncApi()
        ..onPush = (_) async => throw Exception('offline');
      var sync = SyncService(db, api);
      await sync.bindAccount('account');
      final id = await WorkoutRepository(db).startSession();
      await sync.synchronize();
      final before = (await db.syncDao.pendingOperations()).single.toJson();
      sync.dispose();
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      sync = SyncService(db, api);
      await sync.bindAccount('account');
      await WorkoutRepository(db).finishSession(id, DateTime.now());
      expect(await db.syncDao.pendingOperations(), hasLength(2));
      api.onPush = null;
      await sync.synchronize();
      expect(api.requests[1].single.toJson(), before);
      expect(await db.syncDao.pendingOperations(), isEmpty);
      sync.dispose();
      await db.close();
      await directory.delete(recursive: true);
    },
  );

  test('schema v2 upgrades without losing account or queued data', () async {
    final directory = await Directory('.dart_tool').createTemp('sync-migrate-');
    final file = File('${directory.path}/db.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    final sync = SyncService(db, FakeSyncApi());
    await sync.bindAccount('account');
    await WorkoutRepository(db).startSession();
    final before = (await db.syncDao.pendingOperations()).single.toJson();
    await db.customStatement('ALTER TABLE sync_outbox DROP COLUMN attempted');
    await db.customStatement(
      'ALTER TABLE sync_outbox DROP COLUMN preserve_local',
    );
    await db.customStatement(
      'ALTER TABLE sync_state DROP COLUMN offline_access',
    );
    await db.customStatement('DROP TABLE IF EXISTS sync_deferred_records');
    await db.customStatement('PRAGMA user_version = 2');
    sync.dispose();
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    expect((await db.syncDao.pendingOperations()).single.toJson(), before);
    expect((await db.syncDao.readState())!.accountId, 'account');
    expect((await db.syncDao.readState())!.offlineAccess, isTrue);
    await db.close();
    await directory.delete(recursive: true);
  });
}
