import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_quarantine.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'sync_service_test.dart' show FakeSyncApi;
import 'sync_audit_test.dart' show session;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test(
    'supersession refuses unknown type, untrusted identity and equal/future version',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      await sync.bindAccount('account');
      final records = [
        {...session('fixed', 1), 'entityType': 'futureEntity', 'payload': null},
        {...session('fixed', 1), 'version': '1', 'payload': null},
        {...session('fixed', 1), 'entityId': null, 'payload': null},
        {...session('fixed', 2), 'payload': null},
        {...session('fixed', 3), 'payload': null},
      ];
      api.page = {
        'cursor': 6,
        'changes': [session('fixed', 2), ...records],
      };
      await sync.synchronize();
      expect(sync.status, SyncStatus.conflict);
      final rows = await db.select(db.syncDeferredRecords).get();
      expect(rows, hasLength(records.length));
      expect(
        rows.every((r) => jsonDecode(r.recordJson)['recovered'] == false),
        true,
      );
      sync.dispose();
      await db.close();
    },
  );

  test(
    'CAS database failure rolls back ACK and attempted conflict, never quarantines',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      await sync.bindAccount('account');
      await PlannerRepository(
        db,
      ).savePlan(nazwa: 'Local', cwiczeniaIds: [], cel: 'mix');
      final op = (await db.syncDao.pendingOperations()).single;
      await WorkoutRepository(db).startSession();
      await db.customStatement(
        "CREATE TRIGGER reject_cas BEFORE UPDATE ON workout_plans BEGIN SELECT RAISE(ABORT, 'storage failure'); END",
      );
      api.onPush = (ops) async => {
        'accepted': [
          for (final o in ops)
            if (o.operationId != op.operationId)
              {'operationId': o.operationId, 'version': 1},
        ],
        'conflicts': [
          {
            'operationId': op.operationId,
            'record': {
              ...session(op.entityId, 5),
              'entityType': 'workoutPlan',
              'payload': op.payload,
            },
          },
        ],
      };
      await sync.synchronize();
      expect(sync.status, SyncStatus.error);
      expect(await db.syncDao.pendingOperations(), hasLength(2));
      expect(await db.select(db.syncDeferredRecords).get(), isEmpty);
      expect((await db.syncDao.readState())!.fullCursor, 0);
      await db.customStatement('DROP TRIGGER reject_cas');
      await sync.synchronize();
      expect(sync.status, SyncStatus.idle);
      expect(await db.syncDao.pendingOperations(), isEmpty);
      sync.dispose();
      await db.close();
    },
  );
  for (final future in [false, true]) {
    test(
      'normal CAS ${future ? 'future' : 'malformed'} preserves authority and progresses after reopen',
      () async {
        final dir = await Directory('.dart_tool').createTemp('cas-review-');
        final file = File('${dir.path}/db.sqlite');
        var db = AppDatabase.forTesting(NativeDatabase(file));
        final api = FakeSyncApi();
        var sync = SyncService(db, api);
        await sync.bindAccount('account');
        await PlannerRepository(
          db,
        ).savePlan(nazwa: 'Local', cwiczeniaIds: [], cel: 'mix');
        // Exercise the restore branch too: it enqueues before applying authority.
        await SyncStore(db).enqueueAll();
        final op = (await db.syncDao.pendingOperations()).single;
        await WorkoutRepository(db).startSession();
        final raw = {
          ...session(op.entityId, 5),
          'entityType': 'workoutPlan',
          'payload': future
              ? {
                  ...op.payload,
                  'structure': {'schemaVersion': 99},
                }
              : null,
        };
        api.onPush = (ops) async => {
          'accepted': [
            for (final o in ops)
              if (o.operationId != op.operationId)
                {'operationId': o.operationId, 'version': 1},
          ],
          'conflicts': [
            if (ops.any((o) => o.operationId == op.operationId))
              {'operationId': op.operationId, 'record': raw},
          ],
        };
        api.page = {
          'cursor': 1,
          'changes': [session('remote-independent', 1)],
        };
        await sync.synchronize();
        expect(sync.status, SyncStatus.conflict);
        expect((await db.syncDao.readState())!.fullCursor, 1);
        expect(
          (await db.syncDao.pendingOperations()).single.toJson(),
          op.toJson(),
        );
        expect((await db.select(db.workoutPlans).getSingle()).nazwa, 'Local');
        final held = (await db.select(db.syncDeferredRecords).get())
            .singleWhere((r) => r.entityType == SyncQuarantine.pushType);
        expect(jsonDecode(held.recordJson)['outcome']['record'], raw);
        sync.dispose();
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        sync = SyncService(db, api);
        await sync.bindAccount('account');
        api.page = {
          'cursor': 2,
          'changes': [
            {
              ...raw,
              'version': 6,
              'payload': {...op.payload, 'nazwa': 'Corrected remote'},
            },
          ],
        };
        await WorkoutRepository(db).startSession();
        await sync.synchronize();
        expect((await db.syncDao.readState())!.fullCursor, 2);
        expect(
          api.requests
              .expand((r) => r)
              .where((o) => o.operationId == op.operationId),
          hasLength(1),
        );
        expect(
          (await db.syncDao.pendingOperations()).single.toJson(),
          op.toJson(),
        );
        expect((await db.select(db.workoutPlans).getSingle()).nazwa, 'Local');
        expect(
          sync.status,
          SyncStatus.conflict,
        ); // corrected pull is not consent to overwrite
        sync.dispose();
        await db.close();
        await dir.delete(recursive: true);
      },
    );
  }

  for (final laterPage in [false, true]) {
    for (final field in ['payload', 'updatedAt']) {
      test(
        'trusted v1 bad $field superseded by v2 laterPage=$laterPage across reopen',
        () async {
          final dir = await Directory(
            '.dart_tool',
          ).createTemp('supersede-review-');
          final file = File('${dir.path}/db.sqlite');
          var db = AppDatabase.forTesting(NativeDatabase(file));
          final api = FakeSyncApi();
          var sync = SyncService(db, api);
          await sync.bindAccount('account');
          final raw = {...session('fixed', 1), field: null};
          api.page = {
            'cursor': laterPage ? 1 : 2,
            'changes': [raw, if (!laterPage) session('fixed', 2)],
          };
          await sync.synchronize();
          expect(
            sync.status,
            laterPage ? SyncStatus.conflict : SyncStatus.idle,
          );
          sync.dispose();
          await db.close();
          db = AppDatabase.forTesting(NativeDatabase(file));
          sync = SyncService(db, api);
          await sync.bindAccount('account');
          api.page = {
            'cursor': 2,
            'changes': [if (laterPage) session('fixed', 2)],
          };
          await sync.synchronize();
          expect(sync.status, SyncStatus.idle);
          final envelope = jsonDecode(
            (await db.select(db.syncDeferredRecords).getSingle()).recordJson,
          );
          expect(envelope['raw'], raw);
          expect(envelope['recovered'], true);
          await db.syncDao.enqueueUpsert(
            entityType: SyncEntityType.workoutSession,
            entityId: 'fixed',
            baseVersion: 2,
            payload: session('fixed', 2)['payload'] as Map<String, Object?>,
          );
          api.page = {'cursor': 2, 'changes': []};
          await sync.synchronize();
          expect(await db.syncDao.pendingOperations(), isEmpty);
          sync.dispose();
          await db.close();
          await dir.delete(recursive: true);
        },
      );
    }
  }
}
