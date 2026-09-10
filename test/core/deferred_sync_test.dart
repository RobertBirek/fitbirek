import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'sync_service_test.dart' show FakeSyncApi;

Map<String, dynamic> remote(
  SyncOperation op,
  int version, {
  bool deleted = false,
}) => {
  'entityType': op.entityType.wireName,
  'entityId': op.entityId,
  'version': version,
  'payload': {...op.payload, 'notatka': 'Server version $version'},
  'updatedAt': '2026-09-10T12:00:00Z',
  'deletedAt': deleted ? '2026-09-10T12:00:00Z' : null,
};

Map<String, dynamic> uncertain(SyncOperation op) => {
  'accepted': [],
  'conflicts': [
    {'operationId': op.operationId, 'kind': 'indeterminateOperation'},
  ],
};

Map<String, dynamic> accepted(SyncOperation op, int version) => {
  'accepted': [
    {
      'operationId': op.operationId,
      'version': version,
      'updatedAt': '2026-09-10T00:00:00Z',
      'duplicate': true,
    },
  ],
  'conflicts': [],
};

void main() {
  for (final laterEdit in [false, true]) {
    test(
      'accepted live state clears a provisional deferred tombstone without losing later edit ($laterEdit)',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final api = FakeSyncApi();
        final sync = SyncService(db, api);
        addTearDown(() async {
          sync.dispose();
          await db.close();
        });
        await sync.bindAccount('account');
        final repo = WorkoutRepository(db);
        final id = await repo.startSession();
        final identity = (await db.workoutDao.getSession(id))!.syncId;
        await SyncStore(db).version(SyncEntityType.workoutSession, identity, 5);
        await repo.finishSession(id, DateTime.now());
        final op = (await db.syncDao.pendingOperations()).single;
        api.onPush = (_) async => uncertain(op);
        await sync.synchronize();
        if (laterEdit) {
          await repo.finishSession(
            id,
            DateTime.now().subtract(const Duration(minutes: 2)),
          );
        }
        api.page = {
          'cursor': 21,
          'changes': [
            remote(op, 5, deleted: true),
            {...remote(op, 6), 'payload': op.payload},
          ],
        };
        await sync.synchronize();
        api.page = {'cursor': 21, 'changes': []};
        api.onPush = (ops) async {
          if (ops.single.operationId == op.operationId) return accepted(op, 6);
          expect(ops.single.baseVersion, 6);
          return accepted(ops.single, 7);
        };
        await sync.synchronize();
        expect(sync.status, SyncStatus.idle);
        expect(await db.syncDao.pendingOperations(), isEmpty);
        final row = (await db.workoutDao.getSession(id))!;
        expect(row.deletedAtUtc, isNull);
        expect(row.syncVersion, laterEdit ? 7 : 6);
        if (laterEdit) expect(row.czasTrwaniaSekund, greaterThanOrEqualTo(120));
      },
    );
  }
  test(
    'failed deferred apply rolls back the final duplicate acknowledgement and retries intact',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      final id = await WorkoutRepository(db).startSession();
      final op = (await db.syncDao.pendingOperations()).single;
      api.onPush = (_) async => uncertain(op);
      api.page = {
        'cursor': 20,
        'changes': [remote(op, 5)],
      };
      await sync.synchronize();
      await db.customStatement(
        "CREATE TRIGGER reject_snapshot BEFORE UPDATE ON workout_sessions WHEN NEW.notatka = 'Server version 5' BEGIN SELECT RAISE(ABORT, 'injected apply failure'); END",
      );
      api.onPush = (_) async => accepted(op, 1);
      api.page = {'cursor': 20, 'changes': []};
      await sync.synchronize();
      expect(sync.status, SyncStatus.error);
      expect(
        (await db.syncDao.pendingOperations()).single.toJson(),
        op.toJson(),
      );
      expect((await db.workoutDao.getSession(id))!.notatka, isNull);
      await db.customStatement('DROP TRIGGER reject_snapshot');
      await sync.synchronize();
      expect(sync.status, SyncStatus.idle);
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect((await db.workoutDao.getSession(id))!.notatka, 'Server version 5');
    },
  );
  for (final preserveRestoreIntent in [false, true]) {
    test(
      'remote session deletion cannot rebase a pending finish into an implicit resurrection (restore=$preserveRestoreIntent)',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final api = FakeSyncApi();
        final sync = SyncService(db, api);
        addTearDown(() async {
          sync.dispose();
          await db.close();
        });
        await sync.bindAccount('account');
        final repo = WorkoutRepository(db);
        final id = await repo.startSession();
        final op = (await db.syncDao.pendingOperations()).single;
        if (preserveRestoreIntent) {
          await db.customStatement('UPDATE sync_outbox SET preserve_local = 1');
        }
        api.onPush = (_) async => uncertain(op);
        await sync.synchronize();
        await repo.finishSession(id, DateTime.now());
        api.page = {
          'cursor': 20,
          'changes': [remote(op, 5, deleted: true)],
        };
        await sync.synchronize();
        api.page = {'cursor': 20, 'changes': []};
        var resurrected = false;
        api.onPush = (ops) async {
          final next = ops.single;
          if (next.operationId == op.operationId) return accepted(op, 1);
          if (next.baseVersion == 5) {
            resurrected = !next.deleted;
            return accepted(next, 6);
          }
          return {
            'accepted': [],
            'conflicts': [
              {
                'operationId': next.operationId,
                'record': remote(op, 5, deleted: true),
              },
            ],
          };
        };
        await sync.synchronize();
        expect(resurrected, isFalse);
        expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNotNull);
        expect(await db.syncDao.pendingOperations(), isEmpty);
      },
    );
  }
  for (final deleted in [false, true]) {
    test(
      'older accepted duplicate reconciles deferred ${deleted ? "tombstone" : "payload"} after SQLite restart',
      () async {
        final directory = await Directory(
          '.dart_tool',
        ).createTemp('deferred-sync-');
        final file = File('${directory.path}/db.sqlite');
        var db = AppDatabase.forTesting(NativeDatabase(file));
        final api = FakeSyncApi();
        var sync = SyncService(db, api);
        addTearDown(() async {
          sync.dispose();
          await db.close();
          await directory.delete(recursive: true);
        });
        await sync.bindAccount('account');
        final id = await WorkoutRepository(db).startSession();
        final op = (await db.syncDao.pendingOperations()).single;
        api.onPush = (_) async => uncertain(op);
        api.page = {
          'cursor': 20,
          'changes': [remote(op, 5, deleted: deleted)],
        };
        await sync.synchronize();
        expect(sync.status, SyncStatus.conflict);
        expect((await db.syncDao.readState())!.cursor, 20);
        // A later page must replace, rather than lose, the deferred snapshot.
        api.page = {
          'cursor': 21,
          'changes': [remote(op, 7, deleted: deleted)],
        };
        await sync.synchronize();
        sync.dispose();
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        sync = SyncService(db, api);
        await sync.bindAccount('account');
        api.onPush = (_) async => accepted(op, 1);
        api.page = {'cursor': 21, 'changes': []};
        await sync.synchronize();
        expect(sync.status, SyncStatus.idle);
        expect(await db.syncDao.pendingOperations(), isEmpty);
        final row = (await db.workoutDao.getSession(id))!;
        expect(row.notatka, 'Server version 7');
        expect(row.syncVersion, 7);
        expect(row.deletedAtUtc != null, deleted);
        expect((await db.syncDao.readState())!.cursor, 21);
        expect(api.requests.last.single.toJson(), op.toJson());
      },
    );
  }

  test(
    'deferred payload never overwrites later queued local edit or its newer acknowledgement',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      final repo = WorkoutRepository(db);
      final id = await repo.startSession();
      final op = (await db.syncDao.pendingOperations()).single;
      api.onPush = (_) async => uncertain(op);
      api.page = {
        'cursor': 20,
        'changes': [remote(op, 5)],
      };
      await sync.synchronize();
      await repo.finishSession(id, DateTime.now());
      api.page = {'cursor': 20, 'changes': []};
      api.onPush = (ops) async {
        if (ops.single.operationId == op.operationId) return accepted(op, 1);
        expect(ops.single.baseVersion, 5);
        throw Exception('offline after later edit');
      };
      await sync.synchronize();
      expect((await db.workoutDao.getSession(id))!.dataKoniec, isNotNull);
      expect((await db.workoutDao.getSession(id))!.notatka, isNull);
      expect(await db.syncDao.pendingOperations(), hasLength(1));
      api.onPush = (ops) async => accepted(ops.single, 6);
      await sync.synchronize();
      final row = (await db.workoutDao.getSession(id))!;
      expect(row.dataKoniec, isNotNull);
      expect(row.notatka, isNull);
      expect(row.syncVersion, 6);
      expect(await db.syncDao.pendingOperations(), isEmpty);
    },
  );

  test(
    'malformed dirty snapshot rolls back payload, version and cursor atomically',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      final id = await WorkoutRepository(db).startSession();
      final op = (await db.syncDao.pendingOperations()).single;
      api.onPush = (_) async => uncertain(op);
      api.page = {
        'cursor': 20,
        'changes': [
          remote(op, 5),
          {...remote(op, 6), 'payload': {}},
        ],
      };
      await sync.synchronize();
      expect(sync.status, SyncStatus.error);
      expect((await db.syncDao.readState())!.cursor, 0);
      expect((await db.workoutDao.getSession(id))!.syncVersion, 0);
      api.onPush = (_) async => accepted(op, 1);
      api.page = {'cursor': 0, 'changes': []};
      await sync.synchronize();
      expect(sync.status, SyncStatus.idle);
      expect((await db.workoutDao.getSession(id))!.notatka, isNull);
      expect((await db.workoutDao.getSession(id))!.syncVersion, 1);
    },
  );

  test(
    'v3 upgrade replays discarded payload even when observed version already matches',
    () async {
      final directory = await Directory(
        '.dart_tool',
      ).createTemp('deferred-migration-');
      final file = File('${directory.path}/db.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      final api = FakeSyncApi();
      var sync = SyncService(db, api);
      addTearDown(() async {
        sync.dispose();
        await db.close();
        await directory.delete(recursive: true);
      });
      await sync.bindAccount('account');
      final id = await WorkoutRepository(db).startSession();
      final op = (await db.syncDao.pendingOperations()).single;
      await sync.synchronize();
      await db.customStatement('UPDATE workout_sessions SET sync_version = 5');
      await db.customStatement('UPDATE sync_state SET cursor = 20');
      await db.customStatement('DROP TABLE IF EXISTS sync_deferred_records');
      await db.customStatement('PRAGMA user_version = 3');
      sync.dispose();
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      sync = SyncService(db, api);
      await sync.bindAccount('account');
      expect((await db.syncDao.readState())!.cursor, 0);
      api.page = {
        'cursor': 20,
        'changes': [remote(op, 5)],
      };
      await sync.synchronize();
      expect((await db.workoutDao.getSession(id))!.notatka, 'Server version 5');
    },
  );
}
