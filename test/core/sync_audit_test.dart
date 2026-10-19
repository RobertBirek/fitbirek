import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../helpers/recorded_workout_fixture.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'sync_service_test.dart' show FakeSyncApi;

Map<String, dynamic> session(String id, int version) => {
  'entityType': 'workoutSession',
  'entityId': id,
  'version': version,
  'updatedAt': '2026-09-10T00:00:00Z',
  'deletedAt': null,
  'payload': {'dataStart': '2026-09-10T00:00:00Z', 'czasTrwaniaSekund': 0},
};

class GatedPull extends FakeSyncApi {
  final started = Completer<void>();
  final result = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> pull(int cursor) {
    started.complete();
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('unsupported plan schema stays raw without legacy conversion', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final raw = {
      ...session('future-plan', 1),
      'entityType': 'workoutPlan',
      'payload': {
        'nazwa': 'Future',
        'cwiczeniaIds': <String>[],
        'cel': 'mix',
        'structure': {
          'schemaVersion': 99,
          'futureField': [1, 2, 3],
        },
      },
    };
    final api = FakeSyncApi()
      ..page = {
        'cursor': 1,
        'changes': [raw],
      };
    final service = SyncService(db, api);
    await service.bindAccount('account');
    await service.synchronize();
    expect(service.status, SyncStatus.conflict);
    expect((await db.syncDao.readState())!.fullCursor, 1);
    expect(
      jsonDecode(
        (await db.select(db.syncDeferredRecords).getSingle()).recordJson,
      )['raw'],
      raw,
    );
    expect(await db.select(db.workoutPlans).get(), isEmpty);
    service.dispose();
    await db.close();
  });

  test(
    'invalid side is data validation, not a database page failure',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi();
      final service = SyncService(db, api);
      await service.bindAccount('account');
      api.page = {
        'cursor': 2,
        'changes': [
          session('parent', 1),
          {
            ...session('child', 1),
            'entityType': 'workoutSet',
            'payload': {
              'sessionSyncId': 'parent',
              'cwiczenieId': 'cw001',
              'nazwaCwiczeniaPl': 'Test',
              'numerSerii': 1,
              'side': 'future-side',
              'timestamp': '2026-09-10T00:00:00Z',
            },
          },
        ],
      };
      await service.synchronize();
      expect(service.status, SyncStatus.conflict);
      expect((await db.syncDao.readState())!.fullCursor, 2);
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.select(db.syncDeferredRecords).get(), hasLength(1));
      service.dispose();
      await db.close();
    },
  );

  test(
    'missing parent recovers on a later page without dropping raw evidence',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi();
      final service = SyncService(db, api);
      await service.bindAccount('account');
      final child = {
        ...session('child', 1),
        'entityType': 'workoutSet',
        'payload': {
          'sessionSyncId': 'parent',
          'cwiczenieId': 'cw001',
          'nazwaCwiczeniaPl': 'Test',
          'numerSerii': 1,
          'powtorzenia': 5,
          'timestamp': '2026-09-10T00:00:00Z',
        },
      };
      api.page = {
        'cursor': 2,
        'changes': [child, session('independent', 1)],
      };
      await service.synchronize();
      expect(service.status, SyncStatus.conflict);
      expect((await db.syncDao.readState())!.fullCursor, 2);
      api.page = {
        'cursor': 3,
        'changes': [session('parent', 1)],
      };
      await service.synchronize();
      expect(service.status, SyncStatus.idle);
      expect(await db.select(db.setsLog).get(), hasLength(1));
      final raw =
          jsonDecode(
                (await db.select(db.syncDeferredRecords).getSingle())
                    .recordJson,
              )
              as Map;
      expect(raw['raw'], child);
      expect(raw['recovered'], true);
      service.dispose();
      await db.close();
    },
  );

  test(
    'database write failures roll back page, not quarantined as bad data',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi()
        ..page = {
          'cursor': 1,
          'changes': [session('valid', 1)],
        };
      final service = SyncService(db, api);
      await service.bindAccount('account');
      await db.customStatement(
        "CREATE TRIGGER fail_sync BEFORE INSERT ON workout_sessions BEGIN SELECT RAISE(ABORT, 'temporary storage failure'); END",
      );
      await service.synchronize();
      expect(service.status, SyncStatus.error);
      expect((await db.syncDao.readState())!.fullCursor, 0);
      expect(await db.select(db.syncDeferredRecords).get(), isEmpty);
      await db.customStatement('DROP TRIGGER fail_sync');
      await service.synchronize();
      expect(service.status, SyncStatus.idle);
      service.dispose();
      await db.close();
    },
  );

  test(
    'unresolved remote payload blocks local overwrite but not independent entity',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi()
        ..page = {
          'cursor': 1,
          'changes': [
            {...session('broken', 1), 'payload': {}},
          ],
        };
      final service = SyncService(db, api);
      await service.bindAccount('account');
      await service.synchronize();
      await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              syncId: const Value('broken'),
              dataStart: DateTime.now(),
            ),
          );
      final row = await db.select(db.workoutSessions).getSingle();
      await seedRecordedWorkoutSet(db, row.id);
      await WorkoutRepository(db).finishSession(row.id, DateTime.now());
      await WorkoutRepository(db).startSession();
      api.page = {'cursor': 1, 'changes': []};
      await service.synchronize();
      expect(
        api.requests.expand((r) => r).any((o) => o.entityId == 'broken'),
        false,
      );
      expect(await db.syncDao.pendingOperations(), hasLength(1));
      service.dispose();
      await db.close();
    },
  );

  test(
    'two SQLite connections reject late response after logout and A-B-A',
    () async {
      final dir = await Directory('.dart_tool').createTemp('audit-binding-');
      final file = File('${dir.path}/db.sqlite');
      final db = AppDatabase.forTesting(NativeDatabase(file));
      final other = AppDatabase.forTesting(NativeDatabase(file));
      final api = GatedPull();
      final one = SyncService(db, api);
      final two = SyncService(other, FakeSyncApi());
      await one.bindAccount('account');
      await two.bindAccount('account');
      final run = one.synchronize();
      await api.started.future;
      await other.syncDao.lockOfflineAccess();
      await other
          .update(other.syncState)
          .write(const SyncStateCompanion(accountId: Value('B')));
      await other
          .update(other.syncState)
          .write(
            const SyncStateCompanion(
              accountId: Value('account'),
              offlineAccess: Value(true),
            ),
          );
      api.result.complete({
        'cursor': 1,
        'changes': [session('late', 1)],
      });
      await run;
      expect(one.status, SyncStatus.signedOut);
      expect((await db.syncDao.readState())!.fullCursor, 0);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      await two.synchronize();
      expect(two.status, SyncStatus.signedOut);
      one.dispose();
      two.dispose();
      await db.close();
      await other.close();
      await dir.delete(recursive: true);
    },
  );

  test(
    'historical malformed then corrected and unknown raw survive SQLite reopen',
    () async {
      final dir = await Directory('.dart_tool').createTemp('audit-sync-');
      final file = File('${dir.path}/db.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      final bad = {...session('fixed', 1), 'payload': <String, dynamic>{}};
      final future = {...session('future', 1), 'entityType': 'futureSchema'};
      final api = FakeSyncApi()
        ..page = {
          'cursor': 4,
          'changes': [
            bad,
            session('fixed', 2),
            future,
            session('independent', 1),
          ],
        };
      var service = SyncService(db, api);
      await service.bindAccount('account');
      await service.synchronize();
      expect((await db.syncDao.readState())!.fullCursor, 4);
      expect(
        (await db.select(db.workoutSessions).get()).map((r) => r.syncId),
        containsAll(['fixed', 'independent']),
      );
      expect(service.status, SyncStatus.conflict);
      service.dispose();
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      service = SyncService(db, api..page = {'cursor': 4, 'changes': []});
      await service.bindAccount('account');
      await service.synchronize();
      final raw = (await db.select(db.syncDeferredRecords).get())
          .map((r) => jsonDecode(r.recordJson) as Map)
          .toList();
      expect(
        raw.any(
          (r) =>
              jsonEncode(r['raw']) == jsonEncode(bad) &&
              r['accountId'] == 'account' &&
              r['cursor'] == 4,
        ),
        isTrue,
      );
      expect(
        raw.any((r) => jsonEncode(r['raw']) == jsonEncode(future)),
        isTrue,
      );
      expect(service.status, SyncStatus.conflict);
      service.dispose();
      await db.close();
      await dir.delete(recursive: true);
    },
  );

  for (final kind in ['indeterminateOperation', 'operationReuse']) {
    test(
      '$kind holds successors but independent entities progress after reopen',
      () async {
        final dir = await Directory('.dart_tool').createTemp('audit-push-');
        final file = File('${dir.path}/db.sqlite');
        var db = AppDatabase.forTesting(NativeDatabase(file));
        final api = FakeSyncApi();
        var service = SyncService(db, api);
        await service.bindAccount('account');
        final id = await WorkoutRepository(db).startSession();
        api.onPush = (ops) async => {
          'accepted': [],
          'conflicts': [
            {'operationId': ops.first.operationId, 'kind': kind},
          ],
        };
        await service.synchronize();
        final immutable = (await db.select(db.syncOutbox).getSingle()).toJson();
        await WorkoutRepository(db).logSet(
          sessionId: id,
          exerciseId: 'cw001',
          exerciseNamePl: 'Test',
          setNumber: 1,
          reps: 5,
        );
        await WorkoutRepository(db).finishSession(id, DateTime.now());
        service.dispose();
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        service = SyncService(db, api..onPush = null);
        await service.bindAccount('account');
        await WorkoutRepository(db).startSession();
        await service.synchronize();
        expect(await db.syncDao.pendingOperations(), hasLength(3));
        expect(
          (await db.select(db.syncOutbox).get())
              .firstWhere((r) => r.operationId == immutable['operationId'])
              .toJson(),
          immutable,
        );
        expect(api.requests, hasLength(2));
        expect(service.status, SyncStatus.conflict);
        await service.synchronize();
        expect(api.requests, hasLength(2));
        service.dispose();
        await db.close();
        await dir.delete(recursive: true);
      },
    );
  }

  for (final latePush in [false, true]) {
    test(
      'shared persisted logout rejects late ${latePush ? 'push' : 'pull'}',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final api = GatedPull();
        final one = SyncService(db, api);
        final two = SyncService(db, FakeSyncApi());
        await one.bindAccount('account');
        await two.bindAccount('account');
        final pushStarted = Completer<void>();
        final pushGate = Completer<Map<String, dynamic>>();
        if (latePush) {
          await WorkoutRepository(db).startSession();
          api.onPush = (_) {
            pushStarted.complete();
            return pushGate.future;
          };
        }
        final run = one.synchronize();
        await (latePush ? pushStarted.future : api.started.future);
        await db
            .update(db.syncState)
            .write(const SyncStateCompanion(offlineAccess: Value(false)));
        if (latePush) {
          api.result.complete({'cursor': 0, 'changes': []});
          pushGate.complete({
            'accepted': [
              {
                'operationId': api.requests.single.single.operationId,
                'version': 1,
              },
            ],
            'conflicts': [],
          });
        } else {
          api.result.complete({
            'cursor': 1,
            'changes': [session('late', 1)],
          });
        }
        await run;
        expect((await db.syncDao.readState())!.fullCursor, 0);
        expect(one.status, SyncStatus.signedOut);
        if (latePush) {
          expect(await db.syncDao.pendingOperations(), hasLength(1));
        }
        await two.synchronize();
        expect(two.status, SyncStatus.signedOut);
        one.dispose();
        two.dispose();
        await db.close();
      },
    );
  }
}
