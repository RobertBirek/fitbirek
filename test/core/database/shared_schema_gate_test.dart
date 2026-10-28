import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drift/remote.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/database/schema_gate.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import '../sync_service_test.dart' show FakeSyncApi;
import 'shared_schema_fixture.dart';

Future<List<Map<String, Object?>>> _rows(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT * FROM $table').get())
        .map((r) => r.data)
        .toList();

void main() {
  test(
    'guard preserves remote stream invalidations after successful bootstrap',
    () async {
      final server = DriftServer(NativeDatabase.memory());
      final a = AppDatabase.forTesting(await connectSchemaClient(server));
      final b = AppDatabase.forTesting(await connectSchemaClient(server));
      final api = FakeSyncApi();
      final sync = SyncService(a, api);
      await sync.bindAccount('A');
      final stream = StreamIterator(a.select(a.syncState).watch());
      addTearDown(() async {
        await stream.cancel();
        sync.dispose();
        await a.close();
        await b.close();
        await server.shutdown();
      });
      expect(await stream.moveNext(), isTrue);
      expect(stream.current.single.offlineAccess, isTrue);
      await b
          .update(b.syncState)
          .write(const SyncStateCompanion(offlineAccess: Value(false)));
      expect(
        await stream.moveNext().timeout(const Duration(seconds: 3)),
        isTrue,
      );
      expect(stream.current.single.offlineAccess, isFalse);
    },
  );
  test(
    'real RPC: old open server must not admit new schema14 client or writes',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      final server = DriftServer(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      final old = OldSchemaClient(await connectSchemaClient(server));
      await old.customSelect('SELECT 1').get();
      expect(raw.userVersion, 12);
      expect(old.opens, 1);
      final db = AppDatabase.forTesting(await connectSchemaClient(server));
      addTearDown(() async {
        await db.close();
        await old.close();
        await server.shutdown();
        raw.dispose();
      });
      await expectLater(db.customSelect('SELECT 1').get(), throwsStateError);
      await expectLater(
        db.customStatement(
          "INSERT INTO sync_state (account_id) VALUES ('wrong')",
        ),
        throwsStateError,
      );
      await expectLater(
        db.transaction(() => db.customSelect('SELECT 1').get()),
        throwsStateError,
      );
      await expectLater(
        db.batch((b) => b.customStatement('DELETE FROM sync_outbox')),
        throwsStateError,
      );
      expect(raw.userVersion, 12);
      expect(raw.select('SELECT * FROM sync_state'), isEmpty);
      expect(old.opens, 1);
      // Closing the new subscriber must leave the old writer usable.
      await db.close();
      expect(await old.customSelect('SELECT 1').get(), hasLength(1));
    },
  );

  test(
    'close old and retry fresh RPC migrates once preserving identity and attempted bytes',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      var server = DriftServer(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      final old = OldSchemaClient(await connectSchemaClient(server));
      await old.customSelect('SELECT 1').get();
      await old.customStatement(
        "INSERT INTO sync_state (account_id, device_id, offline_access) VALUES ('A', 'device', 1)",
      );
      await old.customStatement(
        "INSERT INTO workout_sessions (sync_id, data_start, updated_at_utc) VALUES ('session-uuid', 123, 123)",
      );
      await old.customStatement(
        "INSERT INTO sync_outbox (operation_id, entity_type, entity_id, payload_json, base_version, attempted) VALUES ('op-uuid', 'workoutSession', 'session-uuid', '{\"kept\":  true}', 7, 1)",
      );
      await old.customStatement(
        "INSERT INTO sync_outbox (operation_id, entity_type, entity_id, payload_json, base_version, attempted) VALUES ('unsent-uuid', 'profile', 'profile-uuid', '{\"name\":\"kept\"}', 0, 0)",
      );
      await old.customStatement(
        "INSERT INTO workout_drafts (account_id, session_sync_id, payload_json) VALUES ('A', 'session-uuid', '{\"reps\":7,\"kg\":5,\"side\":\"left\",\"paused\":true}')",
      );
      final drafts = await _rows(old, 'workout_drafts');
      final before = raw
          .select('SELECT * FROM sync_outbox')
          .map((r) => Map<String, Object?>.from(r))
          .toList();
      final sessions = raw
          .select('SELECT * FROM workout_sessions')
          .map((r) => Map<String, Object?>.from(r))
          .toList();
      // Equality alone would miss an identical-value rewrite. Fail the test on
      // any outbox INSERT/UPDATE/DELETE during rejection, migration or rebind.
      for (final operation in ['INSERT', 'UPDATE', 'DELETE']) {
        raw.execute('''
          CREATE TEMP TRIGGER forbid_outbox_$operation
          BEFORE $operation ON sync_outbox BEGIN
            SELECT RAISE(ABORT, 'schema gate must not rewrite outbox');
          END
        ''');
      }
      final blocked = CountingSchemaClient(await connectSchemaClient(server));
      await expectLater(
        blocked.customSelect('SELECT 1').get(),
        throwsStateError,
      );
      expect(blocked.upgrades, 0);
      await blocked.close();
      await old.close();
      await server.shutdown();
      server = DriftServer(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      final fresh = CountingSchemaClient(await connectSchemaClient(server));
      addTearDown(() async {
        await fresh.close();
        await server.shutdown();
        raw.dispose();
      });
      await fresh.customSelect('SELECT 1').get();
      expect(raw.userVersion, 15);
      expect(fresh.upgrades, 1);
      expect(await _rows(fresh, 'sync_outbox'), before);
      expect(await _rows(fresh, 'workout_sessions'), sessions);
      expect(await _rows(fresh, 'workout_drafts'), drafts);
      expect((await _rows(fresh, 'sync_state')).single['account_id'], 'A');
      final second = CountingSchemaClient(await connectSchemaClient(server));
      await second.customSelect('SELECT 1').get();
      expect(second.upgrades, 0);
      await second.close();
      expect(await _rows(fresh, 'sync_outbox'), before);
      expect(fresh.upgrades, 1);
      final api = FakeSyncApi();
      final sync = SyncService(fresh, api);
      addTearDown(sync.dispose);
      // Schema readiness must not replace account authority. A->B->A cannot
      // rebind the persisted account or rewrite either attempted or unsent ops.
      await sync.bindAccount('A');
      await expectLater(sync.bindAccount('B'), throwsStateError);
      await sync.bindAccount('A');
      expect((await fresh.syncDao.readState())!.accountId, 'A');
      expect(await _rows(fresh, 'sync_outbox'), before);
      expect(api.requests, isEmpty);
      expect(await _rows(fresh, 'sets_log'), isEmpty);
      expect(await _rows(fresh, 'personal_records'), isEmpty);
    },
  );

  test(
    'future schema fails closed before Drift can downgrade user_version',
    () async {
      final raw = sqlite.sqlite3.openInMemory()..userVersion = 16;
      final db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      addTearDown(() async {
        await db.close();
        raw.dispose();
      });
      await expectLater(db.customSelect('SELECT 1').get(), throwsStateError);
      expect(raw.userVersion, 16);
    },
  );

  for (final alreadyOpen in [false, true]) {
    test(
      'future schema over real RPC fails closed, alreadyOpen=$alreadyOpen',
      () async {
        final raw = sqlite.sqlite3.openInMemory()..userVersion = 16;
        final executor = NativeDatabase.opened(
          raw,
          closeUnderlyingOnClose: false,
        );
        final server = DriftServer(executor);
        AppDatabase? owner;
        if (alreadyOpen) {
          // An already-open server may have been initialized by a newer release.
          owner = _FutureClient(await connectSchemaClient(server));
          await owner.customSelect('SELECT 1').get();
        }
        final db = AppDatabase.forTesting(await connectSchemaClient(server));
        addTearDown(() async {
          await db.close();
          await owner?.close();
          await server.shutdown();
          raw.dispose();
        });
        await expectLater(
          db.customSelect('SELECT 1').get(),
          throwsA(
            isA<DatabaseSchemaMismatch>()
                .having((e) => e.actual, 'actual', 16)
                .having((e) => e.expected, 'expected', 15),
          ),
        );
        expect(raw.userVersion, 16);
      },
    );
  }
}

class _FutureClient extends AppDatabase {
  _FutureClient(super.e) : super.forTesting();
  @override
  int get schemaVersion => 16;
}
