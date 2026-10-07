import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// Historical clients use SQLite directly without knowledge of new columns.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/health/data/health_repository.dart';
import 'health_sync_lifecycle_test.dart' show record;

class _SharedApi implements SyncApi {
  final cursors = <int>[];
  Future<Map<String, dynamic>> Function(int)? onPull;
  @override
  Future<Map<String, dynamic>> pull(int cursor) async {
    cursors.add(cursor);
    if (onPull != null) return onPull!(cursor);
    return {
      'cursor': 1,
      'changes': cursor == 0 ? [record(1)] : [],
    };
  }

  @override
  Future<Map<String, dynamic>> push(List<SyncOperation> ops) async => {
    'accepted': [],
    'conflicts': [
      for (final op in ops)
        {'operationId': op.operationId, 'kind': 'indeterminateOperation'},
    ],
  };
}

void main() {
  test(
    'two SQLite connections: held full pull, late legacy advance/regression and restart are independent',
    () async {
      final dir = await Directory.systemTemp.createTemp('shared-held-');
      final file = File('${dir.path}/db.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      final api = _SharedApi();
      var sync = SyncService(db, api);
      await sync.bindAccount('account');
      final legacy = sqlite.sqlite3.open(file.path);
      addTearDown(() async {
        legacy.dispose();
        sync.dispose();
        await db.close();
        await dir.delete(recursive: true);
      });
      final entered = Completer<void>();
      final response = Completer<Map<String, dynamic>>();
      api.onPull = (cursor) {
        entered.complete();
        return response.future;
      };
      final running = sync.synchronize();
      await entered.future;
      legacy.execute('UPDATE sync_state SET cursor=999 WHERE id=1');
      response.complete({
        'cursor': 1,
        'changes': [record(1)],
      });
      await running;
      expect(api.cursors, [0]);
      expect((await db.syncDao.readState())!.fullCursor, 1);
      expect(
        legacy.select('SELECT cursor FROM sync_state').single['cursor'],
        999,
      );
      // Response that was already in flight in another old tab arrives later.
      legacy.execute('UPDATE sync_state SET cursor=0 WHERE id=1');
      expect((await db.syncDao.readState())!.fullCursor, 1);
      final second = record(1)..['entityId'] = 'second-health';
      api.onPull = (cursor) async => {
        'cursor': 2,
        'changes': cursor == 1 ? [second] : [],
      };
      await sync.synchronize();
      expect(api.cursors, [0, 1]);
      expect(await db.select(db.healthSamples).get(), hasLength(2));
      expect((await db.syncDao.readState())!.cursor, 0);
      sync.dispose();
      await db.close();
      legacy.execute('UPDATE sync_state SET cursor=1001 WHERE id=1');
      db = AppDatabase.forTesting(NativeDatabase(file));
      sync = SyncService(db, api);
      await sync.bindAccount('account');
      api.onPull = (cursor) async => {'cursor': 2, 'changes': []};
      await sync.synchronize();
      expect(api.cursors, [0, 1, 2]);
      expect((await db.syncDao.readState())!.fullCursor, 2);
      expect((await db.syncDao.readState())!.cursor, 1001);
    },
  );

  test(
    'failed full page rolls back sample and full cursor but not independent legacy commit',
    () async {
      final dir = await Directory.systemTemp.createTemp('shared-rollback-');
      final file = File('${dir.path}/db.sqlite');
      final db = AppDatabase.forTesting(NativeDatabase(file));
      final api = _SharedApi();
      final sync = SyncService(db, api);
      await sync.bindAccount('account');
      final legacy = sqlite.sqlite3.open(file.path);
      addTearDown(() async {
        legacy.dispose();
        sync.dispose();
        await db.close();
        await dir.delete(recursive: true);
      });
      final entered = Completer<void>();
      final response = Completer<Map<String, dynamic>>();
      api.onPull = (_) {
        entered.complete();
        return response.future;
      };
      final running = sync.synchronize();
      await entered.future;
      legacy.execute('UPDATE sync_state SET cursor=501 WHERE id=1');
      // Same entity type preserves ordering: valid row inserted before bad row.
      response.complete({
        'cursor': 2,
        'changes': [
          record(1),
          record(1)
            ..['entityId'] = 'bad'
            ..['payload'] = {},
        ],
      });
      await running;
      expect(sync.status, SyncStatus.error);
      expect(await db.select(db.healthSamples).get(), isEmpty);
      expect((await db.syncDao.readState())!.fullCursor, 0);
      expect((await db.syncDao.readState())!.cursor, 501);
      api.onPull = (_) async => {
        'cursor': 1,
        'changes': [record(1)],
      };
      await sync.synchronize();
      expect(api.cursors, [0, 0]);
      expect((await db.syncDao.readState())!.fullCursor, 1);
      expect((await db.syncDao.readState())!.cursor, 501);
    },
  );

  test(
    'full replay preserves newer manual fields, attempted bytes and newer deferred tombstone',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = _SharedApi();
      final sync = SyncService(db, api);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      final stamp = DateTime.utc(2026, 9, 10);
      await db
          .into(db.measurements)
          .insert(
            MeasurementsCompanion.insert(
              wagaKg: 82,
              syncId: const Value('manual'),
              syncVersion: const Value(10),
              data: Value(stamp),
              notatka: const Value('newer local'),
            ),
          );
      final measurementBefore = await db.select(db.measurements).getSingle();
      await SyncStore(db).apply(record(2));
      final health = await db.select(db.healthSamples).getSingle();
      await HealthRepository(db).deleteSample(health);
      await db.customStatement('UPDATE sync_outbox SET attempted=1');
      final tombstone = record(4, deleted: true);
      await db
          .into(db.syncDeferredRecords)
          .insert(
            SyncDeferredRecordsCompanion.insert(
              entityType: 'healthSample',
              entityId: health.syncId,
              version: 4,
              recordJson: jsonEncode(tombstone),
            ),
          );
      final deferredBefore = await db
          .select(db.syncDeferredRecords)
          .getSingle();
      final operationBefore = await db.select(db.syncOutbox).getSingle();
      api.onPull = (_) async => {
        'cursor': 10,
        'changes': [
          {
            'entityType': 'measurement',
            'entityId': 'manual',
            'version': 9,
            'updatedAt': stamp.toIso8601String(),
            'deletedAt': null,
            'payload': {'data': stamp.toIso8601String(), 'wagaKg': 79},
          },
          record(3),
        ],
      };
      await sync.synchronize();
      expect(await db.select(db.measurements).getSingle(), measurementBefore);
      expect(await db.select(db.syncOutbox).getSingle(), operationBefore);
      expect(
        await db.select(db.syncDeferredRecords).getSingle(),
        deferredBefore,
      );
      expect(await HealthRepository(db).watchAll().first, isEmpty);
      expect((await db.syncDao.readState())!.fullCursor, 10);
      expect((await db.syncDao.readState())!.cursor, 0);
    },
  );
  test(
    'legacy filtered response after new bind must not skip health history',
    () async {
      final dir = await Directory.systemTemp.createTemp('shared-health-');
      final file = File('${dir.path}/db.sqlite');
      final db = AppDatabase.forTesting(NativeDatabase(file));
      final api = _SharedApi();
      final sync = SyncService(db, api);
      await sync.bindAccount('account');
      final legacy = sqlite.sqlite3.open(file.path);
      addTearDown(() async {
        legacy.dispose();
        sync.dispose();
        await db.close();
        await dir.delete(recursive: true);
      });
      // A real second connection emulates a v4/v6 filtered empty response.
      // It only knows and writes the original cursor column.
      legacy.execute('UPDATE sync_state SET cursor = 1 WHERE id = 1');
      await sync.synchronize();
      expect(
        api.cursors,
        [0],
        reason: 'new full stream must start at zero despite the legacy writer',
      );
      expect(await db.select(db.healthSamples).get(), hasLength(1));
    },
  );
}
