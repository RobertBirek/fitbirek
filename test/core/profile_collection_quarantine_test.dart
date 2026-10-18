import 'dart:convert';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import '../features/schedule/weekly_schedule_test.dart'
    show rule, ruleId, planId, collection;
import 'profile_collections_sync_test.dart' show CollectionServer, saveProfile;
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;

const sessionId = '33333333-3333-4333-8333-333333333333';
Map<String, dynamic> sessionRecord() => {
  'entityType': 'workoutSession',
  'entityId': sessionId,
  'version': 1,
  'updatedAt': '2026-10-21T12:00:00Z',
  'deletedAt': null,
  'payload': {
    'dataStart': '2026-10-21T11:00:00Z',
    'dataKoniec': '2026-10-21T12:00:00Z',
    'czasTrwaniaSekund': 3600,
    'notatka': 'Remote independent',
  },
};
Map<String, dynamic> setRecord() => {
  'entityType': 'workoutSet',
  'entityId': '44444444-4444-4444-8444-444444444444',
  'version': 1,
  'updatedAt': '2026-10-21T12:00:00Z',
  'deletedAt': null,
  'payload': {
    'sessionSyncId': sessionId,
    'cwiczenieId': 'cw001',
    'nazwaCwiczeniaPl': 'Remote',
    'numerSerii': 1,
    'ciezarKg': null,
    'powtorzenia': 8,
    'czasSekund': null,
    'rpe': null,
    'timestamp': '2026-10-21T11:30:00Z',
  },
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test(
    'a local raw collection that cannot merge also holds only the profile, retaining both raw sides',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final server = CollectionServer();
      final sync = SyncService(db, server);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      await saveProfile(db);
      await UserCollectionsRepository(
        db,
      ).update('account', 'weeklySchedule', (e) => e.add(rule()));
      await sync.synchronize();
      await saveProfile(db, name: 'Pending');
      await db.customStatement(
        'UPDATE user_profiles SET weekly_schedule_json = ?',
        [
          jsonEncode({'version': 2, 'entries': []}),
        ],
      );
      server.record = {...server.record!, 'version': 2};
      server.log.addAll([server.record!, sessionRecord(), setRecord()]);
      final pending = (await db.syncDao.pendingOperations()).single.toJson();
      await sync.synchronize();
      expect(sync.status, SyncStatus.conflict);
      expect(
        (await db.select(db.workoutSessions).getSingle()).syncId,
        sessionId,
      );
      expect((await db.syncDao.pendingOperations()).single.toJson(), pending);
      expect(
        jsonDecode(
          (await db.userProfileDao.watchProfileOnce())!.weeklyScheduleJson!,
        )['version'],
        2,
      );
      expect(
        jsonDecode(
          (await db.select(db.syncDeferredRecords).getSingle()).recordJson,
        )['payload']['weeklySchedule'],
        collection([rule()]),
      );
    },
  );
  test(
    'hold survives SQLite reopen and valid remote replacement; only explicit recovery merges pending intent into a NEW request',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      final server = CollectionServer();
      final a = AppDatabase.forTesting(NativeDatabase.memory());
      var b = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      final sa = SyncService(a, server);
      var sb = SyncService(b, server);
      addTearDown(() async {
        sa.dispose();
        sb.dispose();
        await a.close();
        await b.close();
        raw.dispose();
      });
      await sa.bindAccount('account');
      await sb.bindAccount('account');
      await saveProfile(a);
      await UserCollectionsRepository(
        a,
      ).update('account', 'weeklySchedule', (e) => e.add(rule()));
      await sa.synchronize();
      await sb.synchronize();
      await UserCollectionsRepository(b).update(
        'account',
        'weeklySchedule',
        (e) => e.add({...rule(), 'id': planId, 'name': 'Local pending'}),
      );
      final profile = (await b.userProfileDao.watchProfileOnce())!;
      server.record = {
        ...server.record!,
        'version': 2,
        'payload': {
          ...server.record!['payload'] as Map,
          'weeklySchedule': {'version': 2, 'entries': []},
        },
      };
      final badRemote = jsonDecode(jsonEncode(server.record));
      server.log.add(server.record!);
      await b.customStatement('UPDATE sync_outbox SET attempted = 1');
      final attempted = (await b.syncDao.pendingOperations()).single.toJson();
      await sb.synchronize();
      expect(sb.status, SyncStatus.conflict);
      await expectLater(
        sb.retryProfileCollectionConflict('account', profile.syncId),
        throwsFormatException,
      );
      expect((await b.syncDao.pendingOperations()).single.toJson(), attempted);
      sb.dispose();
      await b.close();
      b = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      sb = SyncService(b, server);
      await sb.bindAccount('account');
      await saveProfile(b, name: 'Later local edit');
      // Explicit NULL of a sibling must survive holding and recovery too.
      await b.syncDao.enqueueUpsert(
        entityType: SyncEntityType.profile,
        entityId: profile.syncId,
        baseVersion: 1,
        payload: {
          ...(await b.syncDao.pendingOperations()).last.payload,
          'filterPresets': null,
        },
      );
      server.record = {
        ...server.record!,
        'version': 3,
        'payload': {
          ...server.record!['payload'] as Map,
          'weeklySchedule': collection([rule()]),
          'filterPresets': collection([
            {...rule(), 'filters': <String, dynamic>{}},
          ]),
          'wzrostCm': 195.0,
        },
      };
      server.log.addAll([server.record!, sessionRecord(), setRecord()]);
      final sent = server.attempts.length;
      await sb.synchronize();
      expect(server.attempts.length, sent);
      expect(sb.status, SyncStatus.conflict);
      final deferred =
          jsonDecode(
                (await b.select(b.syncDeferredRecords).getSingle()).recordJson,
              )
              as Map;
      expect(
        deferred[SyncStore.profileCollectionHold]['quarantinedRecord'],
        badRemote,
      );
      expect((await b.syncDao.pendingOperations()).first.toJson(), attempted);
      await expectLater(
        sb.retryProfileCollectionConflict('other-account', profile.syncId),
        throwsStateError,
      );
      await sb.retryProfileCollectionConflict('account', profile.syncId);
      final fresh = (await b.syncDao.pendingOperations()).single;
      expect(fresh.operationId, isNot(attempted['operationId']));
      expect(fresh.baseVersion, 3);
      expect((fresh.payload['weeklySchedule'] as Map)['entries'], hasLength(2));
      expect(fresh.payload.containsKey('filterPresets'), isTrue);
      expect(fresh.payload['filterPresets'], isNull);
      expect((await b.userProfileDao.watchProfileOnce())!.wzrostCm, 195);
      await sb.synchronize();
      expect(sb.status, SyncStatus.idle);
      expect(await b.syncDao.pendingOperations(), isEmpty);
      expect(
        server.attempts.where((o) => o.operationId == attempted['operationId']),
        hasLength(1),
      );
    },
  );
  for (final key in ['weeklySchedule', 'filterPresets', 'exerciseVariants']) {
    for (final malformed in [false, true]) {
      test(
        '$key ${malformed ? 'malformed nested entry' : 'future v2'} CAS is held without blocking independent global pull or rewriting attempted hash',
        () async {
          final a = AppDatabase.forTesting(NativeDatabase.memory()),
              b = AppDatabase.forTesting(NativeDatabase.memory());
          final server = CollectionServer();
          final sa = SyncService(a, server), sb = SyncService(b, server);
          addTearDown(() async {
            sa.dispose();
            sb.dispose();
            await a.close();
            await b.close();
          });
          await sa.bindAccount('account');
          await sb.bindAccount('account');
          await saveProfile(a);
          final ca = UserCollectionsRepository(a),
              cb = UserCollectionsRepository(b);
          await ca.update('account', 'weeklySchedule', (e) => e.add(rule()));
          await sa.synchronize();
          await sb.synchronize();
          await cb.update(
            'account',
            'weeklySchedule',
            (e) => e.add({...rule(), 'id': planId, 'name': 'Local pending'}),
          );
          final invalid = malformed
              ? collection([
                  key == 'weeklySchedule'
                      ? {
                          ...rule(),
                          'kind': 'override',
                          'ruleId': ruleId,
                          'originalDate': '2026-10-19',
                          'movedDate': '2026-10-20',
                          'state': 'planned',
                          'ruleSnapshot': {'planSyncId': 123},
                        }
                      : {
                          ...rule(),
                          if (key == 'filterPresets') 'filters': 123,
                          if (key == 'exerciseVariants') 'exerciseId': 123,
                        },
                ])
              : {'version': 2, 'entries': []};
          server.record = {
            ...server.record!,
            'version': 2,
            'payload': {...server.record!['payload'] as Map, key: invalid},
          };
          server.log.addAll([server.record!, setRecord(), sessionRecord()]);
          await b.customStatement('UPDATE sync_outbox SET attempted = 1');
          final beforeRow =
              (await b.customSelect('SELECT * FROM sync_outbox').getSingle())
                  .data;
          final before = (await b.syncDao.pendingOperations()).single;
          final hash = sha256
              .convert(utf8.encode(jsonEncode(before.toJson())))
              .toString();
          await sb.synchronize();
          expect(sb.status, SyncStatus.conflict);
          expect((await b.syncDao.readState())!.fullCursor, server.log.length);
          expect(
            (await b.select(b.workoutSessions).getSingle()).syncId,
            sessionId,
          );
          expect((await b.select(b.setsLog).getSingle()).powtorzenia, 8);
          final quarantined =
              jsonDecode(
                    (await b.select(b.syncDeferredRecords).getSingle())
                        .recordJson,
                  )
                  as Map;
          expect(quarantined['payload'][key], invalid);
          final after = (await b.syncDao.pendingOperations()).firstWhere(
            (op) => op.operationId == before.operationId,
          );
          expect(after.toJson(), before.toJson());
          expect(
            sha256.convert(utf8.encode(jsonEncode(after.toJson()))).toString(),
            hash,
          );
          // Later local intent must survive alongside the immutable rejected request.
          await saveProfile(b, name: 'Later local edit');
          final attempts = server.attempts.length;
          server.log.addAll([
            {
              ...sessionRecord(),
              'version': 2,
              'payload': {
                ...sessionRecord()['payload'] as Map,
                'notatka': 'Remote after hold',
              },
            },
            {
              ...setRecord(),
              'version': 2,
              'payload': {...setRecord()['payload'] as Map, 'powtorzenia': 10},
            },
          ]);
          for (var i = 0; i < 3; i++) {
            await sb.synchronize();
          }
          expect(sb.status, SyncStatus.conflict);
          expect((await b.syncDao.readState())!.fullCursor, server.log.length);
          expect(
            (await b.select(b.workoutSessions).getSingle()).notatka,
            'Remote after hold',
          );
          expect((await b.select(b.setsLog).getSingle()).powtorzenia, 10);
          expect(
            server.attempts.length,
            attempts,
            reason: 'a confirmed rejected operation must be held, not resent',
          );
          expect(
            (await b.userProfileDao.watchProfileOnce())!.imie,
            'Later local edit',
          );
          final local = await cb.load('account', 'weeklySchedule');
          expect(
            (local['entries'] as List).any((e) => e['name'] == 'Local pending'),
            isTrue,
          );
          final rows = await b.customSelect('SELECT * FROM sync_outbox').get();
          expect(
            rows
                .firstWhere((r) => r.data['operation_id'] == before.operationId)
                .data,
            beforeRow,
          );
        },
      );
    }
  }
}
