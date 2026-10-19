import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/progress/measurements/data/measurements_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import '../../core/sync_service_test.dart' show FakeSyncApi;

class TestAuthority extends CachedAuthWriteAuthority {
  int generation = 0;
  int? expireAfterReads;
  @override
  int get epoch {
    if (expireAfterReads != null && expireAfterReads! <= 0) {
      return generation + 1;
    }
    if (expireAfterReads != null) expireAfterReads = expireAfterReads! - 1;
    return generation;
  }

  @override
  AuthState get state => const AuthState.signedIn('A');
}

void main() {
  late AppDatabase db;
  late MeasurementsRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MeasurementsRepository(db);
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'A', deviceId: 'device'));
    await repo.addMeasurement(wagaKg: 72, obwodTalii: 80, notatka: 'keep');
  });
  tearDown(() => db.close());

  test('restore-intent conflict rebase retains omitted data payload', () async {
    final row = (await repo.getLatest())!;
    await db.delete(db.syncOutbox).go();
    await SyncStore(db).version(SyncEntityType.measurement, row.syncId, 1);
    await repo.updateMeasurement(
      await repo.capture(row.id),
      wagaKg: 74,
      obwodKlatki: null,
      obwodTalii: null,
    );
    await db
        .update(db.syncOutbox)
        .write(const SyncOutboxCompanion(preserveLocal: Value(true)));
    const currentDate = '2026-10-19T12:34:58.979Z';
    final original = (await db.syncDao.pendingOperations()).single;
    final api = FakeSyncApi();
    var rejected = false;
    api.onPush = (ops) async {
      final op = ops.single;
      if (!rejected) {
        rejected = true;
        return {
          'accepted': [],
          'conflicts': [
            {
              'operationId': op.operationId,
              'record': {
                'entityType': 'measurement',
                'entityId': row.syncId,
                'version': 2,
                'updatedAt': currentDate,
                'deletedAt': null,
                'payload': {'data': currentDate, 'wagaKg': 73.0},
              },
            },
          ],
        };
      }
      expect(op.baseVersion, 2);
      expect(op.operationId, isNot(original.operationId));
      expect(op.payload, original.payload);
      expect(op.payload.containsKey('data'), isFalse);
      return {
        'accepted': [
          {
            'operationId': op.operationId,
            'version': 3,
            'updatedAt': currentDate,
            'duplicate': false,
          },
        ],
        'conflicts': [],
      };
    };
    final sync = SyncService(db, api);
    addTearDown(sync.dispose);
    await sync.bindAccount('A');
    await sync.synchronize();
    await sync.synchronize();
    expect(api.requests, hasLength(2));
    expect(await db.syncDao.pendingOperations(), isEmpty);
  });

  test(
    'archive restore stays a new UUID create and edit preserves fields',
    () async {
      final before = (await repo.getLatest())!;
      final backup = BackupService(db);
      final bytes = await backup.exportToBytes();
      expect((await backup.importFromBytes(bytes)).success, isTrue);
      final restored = (await repo.getLatest())!;
      expect(restored.syncId, isNot(before.syncId));
      final create = (await db.syncDao.pendingOperations()).singleWhere(
        (o) => o.entityId == restored.syncId,
      );
      expect(create.baseVersion, 0);
      expect(create.payload.containsKey('data'), isTrue);
      await repo.updateMeasurement(
        await repo.capture(restored.id),
        wagaKg: 74,
        obwodKlatki: null,
        obwodTalii: null,
      );
      final edited = (await db.syncDao.pendingOperations()).singleWhere(
        (o) => o.entityId == restored.syncId,
      );
      expect(edited.payload['data'], create.payload['data']);
      expect(edited.payload['notatka'], 'keep');
      expect(edited.preserveLocal, create.preserveLocal);
    },
  );

  test(
    'legacy without create authority uses known date only under new UUID',
    () async {
      await db.delete(db.syncOutbox).go();
      final before = (await repo.getLatest())!;
      await repo.updateMeasurement(
        await repo.capture(before.id),
        wagaKg: 74,
        obwodKlatki: null,
        obwodTalii: null,
      );
      final op = (await db.syncDao.pendingOperations()).single;
      expect(op.entityId, isNot(before.syncId));
      expect(op.baseVersion, 0);
      expect(op.payload['data'], before.data.toUtc().toIso8601String());
    },
  );

  test(
    'remote fractional date survives SQL edit and simulated server',
    () async {
      await db.delete(db.syncOutbox).go();
      await db.delete(db.measurements).go();
      const exact = '2026-10-19T12:34:58.979Z';
      final server = <String, dynamic>{
        'data': exact,
        'wagaKg': 72.0,
        'notatka': 'remote',
      };
      await SyncStore(db).apply({
        'entityType': 'measurement',
        'entityId': 'remote',
        'version': 1,
        'updatedAt': exact,
        'deletedAt': null,
        'payload': server,
      });
      final row = (await repo.getLatest())!;
      expect(row.data.millisecond, 0);
      await repo.updateMeasurement(
        await repo.capture(row.id),
        wagaKg: 74,
        obwodKlatki: null,
        obwodTalii: null,
      );
      final op = (await db.syncDao.pendingOperations()).single;
      expect(op.payload.containsKey('data'), isFalse);
      final api = FakeSyncApi()
        ..onPush = (ops) async {
          for (final operation in ops) {
            final revised = Map<String, dynamic>.from(operation.payload);
            if (!revised.containsKey('data')) revised['data'] = server['data'];
            server
              ..clear()
              ..addAll(revised);
          }
          return {
            'accepted': [
              for (final o in ops)
                {
                  'operationId': o.operationId,
                  'version': o.baseVersion + 1,
                  'updatedAt': exact,
                  'duplicate': false,
                },
            ],
            'conflicts': [],
          };
        };
      final sync = SyncService(db, api);
      addTearDown(sync.dispose);
      await sync.bindAccount('A');
      await sync.synchronize();
      expect(server['data'], exact);
      expect(server['wagaKg'], 74);
      expect(server['notatka'], 'remote');
      await repo.deleteMeasurement(await repo.capture(row.id));
      expect(
        (await db.syncDao.pendingOperations()).single.payload.containsKey(
          'data',
        ),
        isFalse,
      );
    },
  );

  for (final lostAck in [false, true]) {
    test('original create date survives edits and ACK lost=$lostAck', () async {
      final original = (await db.syncDao.pendingOperations()).single;
      final exact = original.payload['data'];
      final api = FakeSyncApi();
      final server = <String, Object?>{};
      final receipts = <String, Map<String, Object?>>{};
      var loseResponse = lostAck;
      api.onPush = (ops) async {
        final accepted = <Map<String, Object?>>[];
        for (final op in ops) {
          final receipt = receipts[op.operationId];
          if (receipt != null) {
            expect(op.toJson(), original.toJson());
            accepted.add({...receipt, 'duplicate': true});
            continue;
          }
          final revised = Map<String, Object?>.from(op.payload);
          if (!revised.containsKey('data')) revised['data'] = server['data'];
          server
            ..clear()
            ..addAll(revised);
          final ack = <String, Object?>{
            'operationId': op.operationId,
            'version': op.baseVersion + 1,
            'updatedAt': exact,
            'duplicate': false,
          };
          receipts[op.operationId] = ack;
          accepted.add(ack);
        }
        if (loseResponse) {
          loseResponse = false;
          throw Exception('server committed, response lost');
        }
        return {'accepted': accepted, 'conflicts': []};
      };
      final sync = SyncService(db, api);
      addTearDown(sync.dispose);
      await sync.bindAccount('A');
      if (lostAck) {
        await sync.synchronize();
      }
      for (final weight in [73.0, 74.0]) {
        await repo.updateMeasurement(
          await repo.capture((await repo.getLatest())!.id),
          wagaKg: weight,
          obwodKlatki: null,
          obwodTalii: null,
        );
        for (final op in await db.syncDao.pendingOperations()) {
          expect(op.payload['data'], exact);
        }
      }
      await sync.synchronize();
      if (lostAck) expect(api.requests[1].single.toJson(), original.toJson());
      expect(api.requests.last.single.payload['data'], exact);
      expect(server['data'], exact);
      expect(server['wagaKg'], 74);
      await repo.updateMeasurement(
        await repo.capture((await repo.getLatest())!.id),
        wagaKg: 75,
        obwodKlatki: null,
        obwodTalii: null,
      );
      expect(
        (await db.syncDao.pendingOperations()).single.payload.containsKey(
          'data',
        ),
        isFalse,
      );
      await sync.synchronize();
      expect(server['data'], exact);
      expect(server['wagaKg'], 75);
    });
  }

  test(
    'synced legacy date is omitted and stays omitted through ACK rebase',
    () async {
      await db.delete(db.syncOutbox).go();
      final row = (await repo.getLatest())!;
      await SyncStore(db).version(SyncEntityType.measurement, row.syncId, 1);
      await repo.updateMeasurement(
        await repo.capture(row.id),
        wagaKg: 74,
        obwodKlatki: null,
        obwodTalii: null,
      );
      final original = (await db.syncDao.pendingOperations()).single;
      expect(original.payload.containsKey('data'), isFalse);
      await SyncStore(db).version(SyncEntityType.measurement, row.syncId, 2);
      final rebased = (await db.syncDao.pendingOperations()).single;
      expect(rebased.baseVersion, 2);
      expect(rebased.payload, original.payload);
    },
  );

  test(
    'capture owns the epoch before the first asynchronous database work',
    () async {
      final authority = TestAuthority();
      final secured = MeasurementsRepository(db, authority: authority);
      final id = (await repo.getLatest())!.id;
      final pending = secured.capture(id);
      authority.generation += 2;
      await expectLater(pending, throwsA(isA<MeasurementConflict>()));
      authority.revision.dispose();
    },
  );

  test(
    'epoch invalidates A-B-A and late transition rolls transaction back',
    () async {
      final authority = TestAuthority();
      final secured = MeasurementsRepository(db, authority: authority);
      final edit = await secured.capture((await repo.getLatest())!.id);
      final before = await db.select(db.syncOutbox).getSingle();
      authority.generation += 2;
      await expectLater(
        secured.deleteMeasurement(edit),
        throwsA(isA<MeasurementConflict>()),
      );
      final fresh = await secured.capture(edit.row.id);
      authority.expireAfterReads =
          1; // initial guard succeeds; final guard fails
      await expectLater(
        secured.deleteMeasurement(fresh),
        throwsA(isA<MeasurementConflict>()),
      );
      expect(await repo.getLatest(), edit.row);
      expect(await db.select(db.syncOutbox).getSingle(), before);
      authority.revision.dispose();
    },
  );

  test(
    'attempted bytes survive edit and delete; tombstone push/pull roundtrip',
    () async {
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      addTearDown(sync.dispose);
      await sync.bindAccount('A');
      await db
          .update(db.syncOutbox)
          .write(const SyncOutboxCompanion(attempted: Value(true)));
      final attempted = await db.select(db.syncOutbox).getSingle();
      final edit = await repo.capture((await repo.getLatest())!.id);
      await repo.updateMeasurement(
        edit,
        wagaKg: 74,
        obwodKlatki: null,
        obwodTalii: null,
      );
      expect(
        (await db.select(db.syncOutbox).get()).firstWhere((r) => r.attempted),
        attempted,
      );
      await repo.deleteMeasurement(await repo.capture(edit.row.id));
      expect(
        (await db.select(db.syncOutbox).get()).firstWhere((r) => r.attempted),
        attempted,
      );
      await sync.synchronize();
      expect(await db.syncDao.pendingOperations(), isEmpty);
      final deleted = await db.select(db.measurements).getSingle();
      expect(deleted.deletedAtUtc, isNotNull);
      expect(api.requests.last.single.deleted, isTrue);
      final deletion = api.requests.last.single;
      api.page = {
        'cursor': 5,
        'changes': [
          {
            'entityType': 'measurement',
            'entityId': deletion.entityId,
            'version': deleted.syncVersion + 1,
            'updatedAt': '2026-10-18T12:00:00Z',
            'deletedAt': '2026-10-18T12:00:00Z',
            'payload': deletion.payload,
          },
        ],
      };
      await sync.synchronize();
      expect(await repo.getLatest(), isNull);
      expect(
        (await db.select(db.measurements).getSingle()).syncId,
        edit.row.syncId,
      );
      expect(await db.syncDao.pendingOperations(), isEmpty);
    },
  );

  test(
    'edit keeps identity/date/hidden fields and sends explicit null',
    () async {
      final old = (await repo.getLatest())!;
      final edit = await repo.capture(old.id);
      await repo.updateMeasurement(
        edit,
        wagaKg: 73.5,
        obwodKlatki: 99,
        obwodTalii: null,
      );
      final row = (await repo.getLatest())!;
      expect(row.id, old.id);
      expect(row.syncId, old.syncId);
      expect(row.data, old.data);
      expect(row.notatka, 'keep');
      expect(row.obwodTalii, isNull);
      final op = (await db.syncDao.pendingOperations()).single;
      expect(op.entityId, old.syncId);
      expect(op.payload['wagaKg'], 73.5);
      expect(op.payload.containsKey('obwodTalii'), isTrue);
      expect(op.payload['obwodTalii'], isNull);
    },
  );

  test(
    'delete tombstone prevents concurrent edit and double delete without changing bytes',
    () async {
      final edit = await repo.capture((await repo.getLatest())!.id);
      await repo.deleteMeasurement(edit);
      final bytes = (await db.select(db.syncOutbox).getSingle()).payloadJson;
      expect((await db.syncDao.pendingOperations()).single.deleted, isTrue);
      expect(await repo.getLatest(), isNull);
      await expectLater(
        repo.updateMeasurement(
          edit,
          wagaKg: 90,
          obwodKlatki: null,
          obwodTalii: null,
        ),
        throwsA(isA<MeasurementConflict>()),
      );
      await expectLater(
        repo.deleteMeasurement(edit),
        throwsA(isA<MeasurementConflict>()),
      );
      expect((await db.select(db.syncOutbox).getSingle()).payloadJson, bytes);
    },
  );

  test('remote change and A-B-A binding reject stale capture', () async {
    final edit = await repo.capture((await repo.getLatest())!.id);
    await db
        .update(db.measurements)
        .write(const MeasurementsCompanion(wagaKg: Value(88)));
    final before = await db.select(db.syncOutbox).getSingle();
    await expectLater(
      repo.deleteMeasurement(edit),
      throwsA(isA<MeasurementConflict>()),
    );
    final fresh = await repo.capture(edit.row.id);
    await db.syncDao.lockOfflineAccess();
    await db
        .update(db.syncState)
        .write(const SyncStateCompanion(offlineAccess: Value(true)));
    await expectLater(
      repo.deleteMeasurement(fresh),
      throwsA(isA<MeasurementConflict>()),
    );
    expect(await db.select(db.syncOutbox).getSingle(), before);
  });

  test('outbox failure rolls back row and keeps attempted bytes', () async {
    await db
        .update(db.syncOutbox)
        .write(const SyncOutboxCompanion(attempted: Value(true)));
    final before = await db.select(db.syncOutbox).getSingle();
    final edit = await repo.capture((await repo.getLatest())!.id);
    await db.customStatement(
      "CREATE TRIGGER fail_outbox BEFORE INSERT ON sync_outbox BEGIN SELECT RAISE(ABORT, 'test'); END",
    );
    await expectLater(repo.deleteMeasurement(edit), throwsA(anything));
    expect(await repo.getLatest(), edit.row);
    expect(await db.select(db.syncOutbox).getSingle(), before);
    expect(jsonDecode(before.payloadJson)['wagaKg'], 72);
  });
}
