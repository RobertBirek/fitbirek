import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_quarantine.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'sync_service_test.dart' show FakeSyncApi;
import 'sync_audit_test.dart' show session;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  for (final corruption in [
    'json',
    'identity',
    'version',
    'payload',
    'future',
  ]) {
    test('deferred $corruption is not trusted for supersession', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      await PlannerRepository(
        db,
      ).savePlan(nazwa: 'Plan', cwiczeniaIds: [], cel: 'mix');
      final op = (await db.syncDao.pendingOperations()).single;
      await db.delete(db.workoutPlans).go();
      await db.syncDao.enqueueDelete(
        entityType: SyncEntityType.workoutPlan,
        entityId: op.entityId,
        baseVersion: 0,
        payload: op.payload,
      );
      final bad = {
        ...session(op.entityId, 1),
        'entityType': 'workoutPlan',
        'payload': null,
      };
      await db.transaction(
        () => SyncQuarantine(db, SyncStore(db)).apply(bad, 'account', 1, 0),
      );
      final candidate = {...bad, 'version': 2, 'payload': op.payload};
      switch (corruption) {
        case 'identity':
          candidate['entityId'] = 'unrelated';
        case 'version':
          candidate['version'] = 1;
        case 'payload':
          candidate['payload'] = <String, dynamic>{};
        case 'future':
          candidate['payload'] = {
            ...op.payload,
            'structure': {'schemaVersion': 99},
          };
      }
      final raw = corruption == 'json' ? '{' : jsonEncode(candidate);
      await db
          .into(db.syncDeferredRecords)
          .insert(
            SyncDeferredRecordsCompanion.insert(
              entityType: 'workoutPlan',
              entityId: op.entityId,
              version: 2,
              recordJson: raw,
            ),
          );
      await sync.synchronize();
      expect(sync.status, SyncStatus.conflict);
      expect(api.requests, isEmpty);
      expect(await db.syncDao.pendingOperations(), hasLength(1));
      final rows = await db.select(db.syncDeferredRecords).get();
      expect(
        jsonDecode(
          rows
              .singleWhere((r) => r.entityType == SyncQuarantine.pullType)
              .recordJson,
        )['recovered'],
        false,
      );
      expect(
        rows.singleWhere((r) => r.entityType == 'workoutPlan').recordJson,
        raw,
      );
    });
  }
  for (final missing in [false, true]) {
    test(
      'preserveLocal profile validates original scalar missing=$missing',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final api = FakeSyncApi();
        final sync = SyncService(db, api);
        addTearDown(() async {
          sync.dispose();
          await db.close();
        });
        await sync.bindAccount('account');
        await UserProfileRepository(db).saveProfile(
          imie: 'Local',
          wiek: 40,
          wzrostCm: 180,
          wagaKg: 80,
          cel: CelTreningowy.mix,
          dostepnySprzet: [],
        );
        await SyncStore(db).enqueueAll();
        final op = (await db.syncDao.pendingOperations()).single;
        expect(op.preserveLocal, true);
        final payload = {...op.payload};
        if (missing) {
          payload.remove('wiek');
        } else {
          payload['wiek'] = 'bad';
        }
        final raw = {
          ...session(op.entityId, 5),
          'entityType': 'profile',
          'payload': payload,
        };
        api.onPush = (ops) async => {
          'accepted': [
            for (final o in ops)
              if (o.operationId != op.operationId)
                {'operationId': o.operationId, 'version': 6},
          ],
          'conflicts': [
            if (ops.any((o) => o.operationId == op.operationId))
              {'operationId': op.operationId, 'record': raw},
          ],
        };
        await sync.synchronize();
        expect(sync.status, SyncStatus.conflict);
        expect(api.requests, hasLength(1));
        expect(
          (await db.syncDao.pendingOperations()).single.toJson(),
          op.toJson(),
        );
        expect((await db.select(db.userProfiles).getSingle()).wiek, 40);
        final hold = (await db.select(db.syncDeferredRecords).get())
            .singleWhere((r) => r.entityType == SyncQuarantine.pushType);
        expect(jsonDecode(hold.recordJson)['outcome']['record'], raw);
      },
    );
  }

  for (final pushHold in [false, true]) {
    test(
      'restore missing plan uses validated deferred after reopen, pushHold=$pushHold',
      () async {
        final dir = await Directory(
          '.dart_tool',
        ).createTemp('quality-restore-');
        final file = File('${dir.path}/db.sqlite');
        var db = AppDatabase.forTesting(NativeDatabase(file));
        final api = FakeSyncApi();
        var sync = SyncService(db, api);
        addTearDown(() async {
          sync.dispose();
          await db.close();
          await dir.delete(recursive: true);
        });
        await sync.bindAccount('account');
        await PlannerRepository(
          db,
        ).savePlan(nazwa: 'Plan', cwiczeniaIds: [], cel: 'mix');
        final original = (await db.syncDao.pendingOperations()).single;
        await sync.synchronize();
        final empty = Uint8List.fromList(
          utf8.encode(jsonEncode({'schemaVersion': 2, 'data': {}})),
        );
        expect((await BackupService(db).importFromBytes(empty)).success, true);
        expect(await db.select(db.workoutPlans).get(), isEmpty);
        final deletion = (await db.syncDao.pendingOperations()).single;
        expect(deletion.deleted, true);
        final bad = {
          ...session(original.entityId, 1),
          'entityType': 'workoutPlan',
          'payload': null,
        };
        await db.transaction(() async {
          final quarantine = SyncQuarantine(db, SyncStore(db));
          await quarantine.apply(bad, 'account', 1, 0);
          if (pushHold) {
            await quarantine.hold('account', deletion, {
              'kind': 'indeterminateOperation',
            });
          }
          await SyncStore(
            db,
          ).apply({...bad, 'version': 2, 'payload': original.payload});
        });
        expect(await db.select(db.workoutPlans).get(), isEmpty);
        sync.dispose();
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        sync = SyncService(db, api);
        await sync.bindAccount('account');
        await sync.synchronize();
        final journal = (await db.select(db.syncDeferredRecords).get())
            .singleWhere((r) => r.entityType == SyncQuarantine.pullType);
        expect(jsonDecode(journal.recordJson)['raw'], bad);
        expect(jsonDecode(journal.recordJson)['recovered'], true);
        await sync.synchronize();
        expect(
          await db.syncDao.pendingOperations(),
          pushHold ? hasLength(1) : isEmpty,
        );
        expect(sync.status, pushHold ? SyncStatus.conflict : SyncStatus.idle);
        expect(await db.select(db.workoutPlans).get(), isEmpty);
      },
    );
  }
}
