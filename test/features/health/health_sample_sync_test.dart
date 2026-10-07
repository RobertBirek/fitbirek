// Sync healthSample: enum mapowanie, SyncStore aplikuje stworzone i tombstone
// rekordy, a nigdy nie pozwala klientowi tworzyć/modyfikować próbek (tylko
// serwer przez /import). Backup enqueueAll pomija ten typ celowo.

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = SyncStore(db);
  });
  tearDown(() async => db.close());

  Map<String, dynamic> weightRecord({
    required String id,
    required int version,
    DateTime? deletedAt,
  }) {
    return {
      'entityType': 'healthSample',
      'entityId': id,
      'version': version,
      'updatedAt': '2026-09-10T08:00:00Z',
      'deletedAt': deletedAt?.toIso8601String(),
      'payload': {
        'kind': 'weight',
        'day': '2026-09-10',
        'measuredAt': '2026-09-10T06:00:00Z',
        'value': 80.5,
        'source': 'Apple Zdrowie',
        'method': 'health_sample',
        'importedAt': '2026-09-10T07:00:00Z',
      },
    };
  }

  test('wire name round-trips through the sync enum', () {
    expect(SyncEntityType.healthSample.wireName, 'healthSample');
    expect(
      syncEntityTypeFromWireName('healthSample'),
      SyncEntityType.healthSample,
    );
    expect(store.table(SyncEntityType.healthSample), db.healthSamples);
  });

  test(
    'apply inserts a remote weight sample and updates on equal id',
    () async {
      await store.apply(weightRecord(id: 'w1', version: 1));
      final rows = await db.select(db.healthSamples).get();
      expect(rows, hasLength(1));
      expect(rows.single.kind, 'weight');
      expect(rows.single.value, 80.5);
      expect(rows.single.syncVersion, 1);

      await store.apply(
        weightRecord(id: 'w1', version: 2)..update(
          'payload',
          (_) => {
            'kind': 'weight',
            'day': '2026-09-10',
            'measuredAt': '2026-09-10T06:00:00Z',
            'value': 81.0,
            'source': 'Apple Zdrowie',
            'method': 'health_sample',
            'importedAt': '2026-09-10T07:00:00Z',
          },
        ),
      );
      final updated = await db.select(db.healthSamples).get();
      expect(updated, hasLength(1));
      expect(updated.single.value, 81.0);
      expect(updated.single.syncVersion, 2);
      expect(updated.single.id, rows.single.id);
    },
  );

  test('apply stores tombstones and skips deleted unknown records', () async {
    final record = weightRecord(
      id: 'w1',
      version: 1,
      deletedAt: DateTime.utc(2026, 9, 10, 9),
    );
    await store.apply(record);
    expect(await db.select(db.healthSamples).get(), isEmpty);

    await store.apply(weightRecord(id: 'w1', version: 1));
    await store.apply(
      weightRecord(
        id: 'w1',
        version: 2,
        deletedAt: DateTime.utc(2026, 9, 10, 9),
      ),
    );
    final row = (await db.select(db.healthSamples).get()).single;
    expect(row.deletedAtUtc, isNotNull);
    expect(row.syncVersion, 2);
  });

  test('enqueueAll never queues healthSample operations', () async {
    await db
        .into(db.healthSamples)
        .insert(
          HealthSamplesCompanion.insert(
            syncId: Value('sample-weight-2026-09-10'),
            kind: 'weight',
            day: '2026-09-10',
            measuredAt: Value(DateTime.utc(2026, 9, 10, 6)),
            value: 80.5,
            source: 'Apple Zdrowie',
            method: 'health_sample',
            importedAt: DateTime.utc(2026, 9, 10, 7),
          ),
        );

    await store.enqueueAll();
    await store.enqueueAll(deleted: true);

    final pending = await db.syncDao.pendingOperations();
    expect(
      pending.where((o) => o.entityType == SyncEntityType.healthSample),
      isEmpty,
    );
  });

  test('healthSample delete payload tolerates missing optional fields', () {
    final operation = SyncOperation(
      operationId: 'op-1',
      entityType: SyncEntityType.healthSample,
      entityId: 'entity-1',
      baseVersion: 3,
      payload: {
        'kind': 'steps',
        'day': '2026-09-10',
        'measuredAt': null,
        'value': 7500,
        'source': 'Apple Zdrowie',
        'method': 'manual_verified_total',
        'importedAt': '2026-09-10T07:00:00Z',
      },
      deleted: true,
    );

    final wire = jsonDecode(jsonEncode(operation.toJson())) as Map;
    expect(wire['deleted'], isTrue);
    expect((wire['payload'] as Map)['method'], 'manual_verified_total');
    expect((wire['payload'] as Map).containsKey('measuredAt'), isTrue);
  });
}
