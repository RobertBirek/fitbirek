import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/progress/tests/domain/fitness_protocol.dart';
import 'profile_collections_sync_test.dart' show saveProfile;
import 'package:fitbirek_training/core/sync/profile_payload.dart';

Map<String, dynamic> fixture() =>
    jsonDecode(
          File('tests/fixtures/fitness_protocol_v1.json').readAsStringSync(),
        )
        as Map<String, dynamic>;
Map<String, dynamic> resultRecord({
  int version = 1,
  Map<String, dynamic>? payload,
  String? deletedAt,
}) => {
  'entityType': 'fitnessTest',
  'entityId': '22222222-2222-4222-8222-222222222222',
  'version': version,
  'updatedAt': '2026-10-21T12:00:00Z',
  'deletedAt': deletedAt,
  'payload': payload ?? fixture()['result'],
};
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());
  test(
    'custom pull stores snapshot and actual date; omission preserves extension; downgrade is refused',
    () async {
      final store = SyncStore(db);
      await store.apply(resultRecord());
      var row = (await db.testsDao.watchAll().first).single;
      expect(CustomFitnessResult.fromRow(row).isAvailable, isTrue);
      expect(row.data.toUtc(), DateTime.utc(2026, 10, 20, 16));
      final omitted = Map<String, dynamic>.from(fixture()['result'] as Map)
        ..remove('customProtocol');
      omitted['wynik'] = 19;
      await store.apply(resultRecord(version: 2, payload: omitted));
      row = (await db.testsDao.watchAll().first).single;
      expect(row.wynik, 19);
      expect(CustomFitnessResult.fromRow(row).isAvailable, isTrue);
      await expectLater(
        store.apply(
          resultRecord(version: 3, payload: {...omitted, 'typ': 'maxPompki'}),
        ),
        throwsA(isA<InvalidSyncRecord>()),
      );
      await expectLater(
        store.apply(
          resultRecord(
            version: 3,
            payload: {...omitted, 'customProtocol': null},
          ),
        ),
        throwsA(isA<InvalidSyncRecord>()),
      );
      final changed = Map<String, dynamic>.from(fixture()['result'] as Map);
      changed['customProtocol'] = {
        ...changed['customProtocol'] as Map,
        'snapshot': {
          ...changed['customProtocol']['snapshot'] as Map,
          'instructions': 'Changed',
        },
      };
      await expectLater(
        store.apply(resultRecord(version: 3, payload: changed)),
        throwsA(isA<InvalidSyncRecord>()),
      );
      expect(
        (await db.testsDao.watchAll().first).single.customProtocolJson,
        row.customProtocolJson,
      );
      await expectLater(
        store.apply(
          resultRecord(
            version: 3,
            payload: {
              ...fixture()['result'] as Map<String, dynamic>,
              'futureSemantics': true,
            },
          ),
        ),
        throwsA(isA<InvalidSyncRecord>()),
      );
    },
  );
  test(
    'unreadable result remains custom, retains raw, and tombstone works',
    () async {
      final payload = Map<String, dynamic>.from(fixture()['result'] as Map);
      payload['customProtocol'] = {
        ...(payload['customProtocol'] as Map),
        'version': 2,
      };
      await SyncStore(db).apply(resultRecord(payload: payload));
      final row = (await db.testsDao.watchAll().first).single;
      expect(CustomFitnessResult.fromRow(row).isAvailable, isFalse);
      expect(jsonDecode(row.customProtocolJson!)['version'], 2);
      await SyncStore(db).apply(
        resultRecord(
          version: 2,
          payload: {},
          deletedAt: '2026-10-21T12:00:00Z',
        ),
      );
      expect(await db.testsDao.watchAll().first, isEmpty);
    },
  );
  test(
    'profile NULL and pruning cannot erase existing fitness revisions',
    () async {
      await saveProfile(db);
      await db.delete(db.syncOutbox).go();
      final p = (await db.userProfileDao.watchProfileOnce())!;
      final record = {
        'entityType': 'profile',
        'entityId': p.syncId,
        'version': 1,
        'updatedAt': '2026-10-21T12:00:00Z',
        'deletedAt': null,
        'payload': {
          ...profilePayload(p),
          'fitnessProtocols': {
            'version': 1,
            'entries': [fixture()['protocol']],
          },
        },
      };
      await SyncStore(db).apply(record);
      final before =
          (await db.userProfileDao.watchProfileOnce())!.fitnessProtocolsJson;
      await SyncStore(db).apply({
        ...record,
        'version': 2,
        'payload': {...profilePayload(p), 'fitnessProtocols': null},
      });
      expect(
        (await db.userProfileDao.watchProfileOnce())!.fitnessProtocolsJson,
        before,
      );
      expect((await SyncStore(db).heldProfileIds()), {p.syncId});
      final deferred = jsonDecode(
        (await db.select(db.syncDeferredRecords).get()).single.recordJson,
      );
      expect(deferred['payload'].containsKey('fitnessProtocols'), isTrue);
      expect(deferred['payload']['fitnessProtocols'], isNull);
    },
  );
  test(
    'identity-only tombstone can enqueue even when custom raw JSON is unreadable',
    () async {
      await SyncStore(db).apply(resultRecord());
      await db.customStatement(
        'UPDATE fitness_test_results SET custom_protocol_json = ?',
        ['{broken'],
      );
      await SyncStore(db).enqueueAll(deleted: true);
      final op = (await db.syncDao.pendingOperations()).single;
      expect(op.deleted, isTrue);
      expect(op.payload, isEmpty);
      expect(
        (await db.testsDao.watchAll().first).single.customProtocolJson,
        '{broken',
      );
    },
  );
  test(
    'custom marker missing snapshot cannot be downgraded into a legacy result',
    () async {
      final missing = Map<String, dynamic>.from(fixture()['result'] as Map)
        ..remove('customProtocol');
      await SyncStore(db).apply(resultRecord(payload: missing));
      expect(
        CustomFitnessResult.fromRow(
          (await db.testsDao.watchAll().first).single,
        ).isAvailable,
        isFalse,
      );
      await expectLater(
        SyncStore(db).apply(
          resultRecord(version: 2, payload: {...missing, 'typ': 'maxPompki'}),
        ),
        throwsA(isA<InvalidSyncRecord>()),
      );
      expect(
        (await db.testsDao.watchAll().first).single.typ,
        'customFitnessTestV1',
      );
    },
  );
  test(
    'enqueueAll emits extension as wire map and integer reps, never database column',
    () async {
      await SyncStore(db).apply(resultRecord());
      await SyncStore(db).enqueueAll();
      final op = (await db.syncDao.pendingOperations()).single;
      expect(
        op.payload['customProtocol'],
        fixture()['result']['customProtocol'],
      );
      expect(op.payload.containsKey('customProtocolJson'), isFalse);
      expect(op.payload['wynik'], isA<int>());
    },
  );
  test(
    'future/invalid calendar normalization rejected; optional semantic keys normalize null',
    () {
      final p = Map<String, dynamic>.from(fixture()['protocol'] as Map);
      for (final invalid in [
        '2026-02-30T10:00:00Z',
        '2026-13-01T10:00:00Z',
        '2026-01-01T10:00:60Z',
        '0000-01-01T00:00:00Z',
        '2026-01-01',
      ]) {
        expect(
          () => FitnessProtocol.fromJson({...p, 'createdAtUtc': invalid}),
          throwsFormatException,
          reason: invalid,
        );
      }
      final absent = {...p}
        ..remove('loadKg')
        ..remove('loadBasis')
        ..remove('side')
        ..remove('variantSnapshot')
        ..remove('timeLimitSeconds')
        ..remove('supersedesId');
      final normalized = FitnessProtocol.fromJson(absent);
      expect(normalized.toJson()['loadKg'], isNull);
      expect(
        normalized.hasSameRevisionRules(
          FitnessProtocol.fromJson({...p, 'timeLimitSeconds': null}),
        ),
        isTrue,
      );
      expect(
        FitnessProtocol.validateResultPayload({
          ...fixture()['result'] as Map<String, dynamic>,
          'wynik': 18.0,
        }).metric,
        FitnessMetric.reps,
      );
      expect(
        () => FitnessProtocol.fromJson({...p, 'timeLimitSeconds': 1.0}),
        throwsFormatException,
      );
      expect(
        () => FitnessProtocol.validateResultPayload({
          ...fixture()['result'] as Map<String, dynamic>,
          'customProtocol': {
            ...fixture()['result']['customProtocol'] as Map,
            'version': 1.0,
          },
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'profile unknown collection is retained raw without blocking unrelated records; omission preserves it',
    () async {
      await saveProfile(db);
      await db.delete(db.syncOutbox).go();
      final p = (await db.userProfileDao.watchProfileOnce())!;
      final future = {'version': 2, 'entries': []};
      final record = {
        'entityType': 'profile',
        'entityId': p.syncId,
        'version': 1,
        'updatedAt': '2026-10-21T12:00:00Z',
        'deletedAt': null,
        'payload': {...profilePayload(p), 'fitnessProtocols': future},
      };
      await SyncStore(db).apply(record);
      expect(
        jsonDecode(
          (await db.userProfileDao.watchProfileOnce())!.fitnessProtocolsJson!,
        ),
        future,
      );
      await SyncStore(db).apply(resultRecord());
      expect(await db.testsDao.watchAll().first, hasLength(1));
      await SyncStore(
        db,
      ).apply({...record, 'version': 2, 'payload': profilePayload(p)});
      expect(
        jsonDecode(
          (await db.userProfileDao.watchProfileOnce())!.fitnessProtocolsJson!,
        ),
        future,
      );
    },
  );
}
