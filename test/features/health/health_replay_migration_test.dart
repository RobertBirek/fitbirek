import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// Drift's lockfile-pinned native driver creates the historical database before
// AppDatabase opens it. No dependency/toolchain change is needed for this test.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/health/data/health_repository.dart';
import 'health_repository_test.dart' show seedSample;
import 'health_sync_lifecycle_test.dart' show record;

class ReplayApi implements SyncApi {
  final cursors = <int>[];
  @override
  Future<Map<String, dynamic>> pull(int cursor) async {
    cursors.add(cursor);
    return {
      'cursor': 99,
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
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final version in [4, 5, 6]) {
    test(
      'real historical v$version migration, replay once across reopen, restore preserves attempted bytes',
      () async {
        final dir = await Directory.systemTemp.createTemp('health-v$version-');
        final file = File('${dir.path}/local.sqlite');
        addTearDown(() => dir.delete(recursive: true));
        final old = sqlite.sqlite3.open(file.path);
        old.execute(File('test/fixtures/schema_v4.sql').readAsStringSync());
        final legacyCursor = version == 6 ? 999 : 77;
        if (version >= 5) {
          old.execute(
            'CREATE TABLE health_samples (sync_id TEXT NOT NULL, sync_version INTEGER NOT NULL DEFAULT 0, updated_at_utc INTEGER NOT NULL, deleted_at_utc INTEGER, id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, kind TEXT NOT NULL, day TEXT NOT NULL, measured_at INTEGER, value REAL NOT NULL, source TEXT NOT NULL, method TEXT NOT NULL, imported_at INTEGER NOT NULL)',
          );
          old.execute('PRAGMA user_version = 5');
          old.execute(
            "INSERT INTO health_samples VALUES ('old-health',3,1700000000,NULL,1,'weight','2023-11-14',1700000000,81.5,'Apple Health','health_sample',1700000000)",
          );
          old.execute(
            "INSERT INTO health_samples VALUES ('deleted-health',4,1700000000,1700000001,2,'steps','2023-11-14',NULL,7000,'Apple Health','manual_verified_total',1700000000)",
          );
        }
        old.execute(
          "INSERT INTO sync_state VALUES (1,'account','device',$legacyCursor,1)",
        );
        if (version == 6) {
          old.execute(
            'ALTER TABLE sync_state ADD COLUMN health_replay_enabled INTEGER NOT NULL DEFAULT 0 CHECK(health_replay_enabled IN (0,1))',
          );
          old.execute('UPDATE sync_state SET health_replay_enabled = 1');
          old.execute('PRAGMA user_version = 6');
        }
        old.execute(
          "INSERT INTO measurements (sync_id,sync_version,updated_at_utc,id,data,waga_kg,obwod_talii,notatka) VALUES ('manual',7,1700000000,12,1699999999,82.5,90.5,'manual note')",
        );
        old.execute(
          "INSERT INTO workout_sessions VALUES ('session',9,1700000000,NULL,17,1699999000,1700000000,1000,'session note')",
        );
        old.execute(
          "INSERT INTO sets_log VALUES ('set',8,1700000000,NULL,23,17,'cw001','Exercise',2,20.5,12,45,7,1700000000)",
        );
        old.execute(
          "INSERT INTO sync_outbox VALUES ('immutable-op','measurement','manual',7,'{ \"wagaKg\":82.5, \"data\":\"2023-11-14T22:13:19Z\" }',1,1,0,1700000001)",
        );
        old.execute(
          "INSERT INTO sync_deferred_records VALUES ('measurement','manual',8,'{\"entityId\":\"manual\",\"version\":8}')",
        );
        final tables = [
          'measurements',
          'workout_sessions',
          'sets_log',
          'sync_state',
          'sync_outbox',
          'sync_deferred_records',
          if (version >= 5) 'health_samples',
        ];
        final before = {
          for (final t in tables)
            t: old
                .select('SELECT * FROM $t')
                .map((r) => Map<String, Object?>.from(r))
                .toList(),
        };
        old.dispose();
        var db = AppDatabase.forTesting(NativeDatabase(file));
        expect(db.schemaVersion, 7);
        for (final t in tables) {
          final after = (await db.customSelect('SELECT * FROM $t').get()).map((
            r,
          ) {
            final fields = {...r.data}..remove('full_cursor');
            if (version < 6) fields.remove('health_replay_enabled');
            return fields;
          }).toList();
          expect(after, before[t], reason: '$t unchanged by schema migration');
        }
        expect(
          (await db.syncDao.readState())!.healthReplayEnabled,
          version == 6,
        );
        expect((await db.syncDao.readState())!.fullCursor, 0);
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        final api = ReplayApi();
        var sync = SyncService(db, api);
        await expectLater(sync.bindAccount('other-account'), throwsStateError);
        expect((await db.syncDao.readState())!.cursor, legacyCursor);
        await sync.bindAccount('account');
        expect((await db.syncDao.readState())!.cursor, legacyCursor);
        expect((await db.syncDao.readState())!.fullCursor, 0);
        expect(
          (await db.syncDao.readState())!.healthReplayEnabled,
          version == 6,
        );
        for (final t in ['sync_outbox', 'sync_deferred_records']) {
          expect(
            (await db.customSelect('SELECT * FROM $t').get())
                .map((r) => r.data)
                .toList(),
            before[t],
          );
        }
        // Crash after migration/binding, before any full pull.
        sync.dispose();
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        sync = SyncService(db, api);
        await sync.bindAccount('account');
        await sync.synchronize();
        expect(api.cursors, [0]);
        expect(
          (await db.select(db.healthSamples).get())
              .singleWhere((s) => s.kind == 'steps' && s.deletedAtUtc == null)
              .syncId,
          'imported-steps',
        );
        expect((await db.syncDao.readState())!.fullCursor, 99);
        expect((await db.syncDao.readState())!.cursor, legacyCursor);
        sync.dispose();
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        sync = SyncService(db, api);
        await sync.bindAccount('account');
        expect((await db.syncDao.readState())!.fullCursor, 99);
        expect((await db.syncDao.readState())!.cursor, legacyCursor);
        await sync.synchronize();
        expect(api.cursors, [0, 99]);
        final health = await seedSample(
          db,
          kind: 'weight',
          day: '2026-09-10',
          value: 80,
        );
        await HealthRepository(db).deleteSample(health);
        await db.customStatement(
          "UPDATE sync_outbox SET attempted=1 WHERE entity_type='healthSample'",
        );
        final healthBefore = await db.select(db.healthSamples).get();
        final attemptedBefore = (await db.select(db.syncOutbox).get())
            .where((o) => o.attempted)
            .toList();
        final backup = BackupService(db);
        final result = await backup.importFromBytes(
          await backup.exportToBytes(),
        );
        expect(result.success, isTrue, reason: result.message);
        expect(await db.select(db.healthSamples).get(), healthBefore);
        final outbox = await db.select(db.syncOutbox).get();
        for (final op in attemptedBefore) {
          expect(
            outbox.singleWhere((o) => o.operationId == op.operationId),
            op,
          );
        }
        final manual = await db.select(db.measurements).getSingle();
        expect(manual.syncId, isNot('manual'));
        expect(manual.wagaKg, 82.5);
        expect(manual.notatka, 'manual note');
        final sessions = await db.select(db.workoutSessions).get();
        final restored = sessions.singleWhere((s) => s.deletedAtUtc == null);
        expect(restored.syncId, isNot('session'));
        expect(
          sessions.singleWhere((s) => s.syncId == 'session').deletedAtUtc,
          isNotNull,
        );
        final set = await db.select(db.setsLog).getSingle();
        expect(set.sesjaId, restored.id);
        expect(set.syncId, isNot('set'));
        expect(set.ciezarKg, 20.5);
        expect(
          (await db.syncDao.pendingOperations()).any(
            (o) => o.entityId == 'manual' && o.deleted,
          ),
          isTrue,
        );
        expect((await db.syncDao.readState())!.accountId, 'account');
        expect((await db.syncDao.readState())!.deviceId, 'device');
        expect((await db.syncDao.readState())!.fullCursor, 99);
        expect((await db.syncDao.readState())!.cursor, legacyCursor);
        expect(
          (await db.syncDao.readState())!.healthReplayEnabled,
          version == 6,
        );
        sync.dispose();
        await db.close();
      },
    );
  }
  test(
    'new binding defaults both cursors without touching the legacy marker',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sync = SyncService(db, ReplayApi());
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('new');
      expect((await db.syncDao.readState())!.healthReplayEnabled, isFalse);
      expect((await db.syncDao.readState())!.fullCursor, 0);
      expect((await db.syncDao.readState())!.cursor, 0);
      await db
          .update(db.syncState)
          .write(
            const SyncStateCompanion(cursor: Value(55), fullCursor: Value(22)),
          );
      await sync.bindAccount('new');
      expect((await db.syncDao.readState())!.cursor, 55);
      expect((await db.syncDao.readState())!.fullCursor, 22);
    },
  );
}
