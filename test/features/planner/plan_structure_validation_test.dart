import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'structured_plan_persistence_test.dart' show structure;
import '../../core/sync_service_test.dart' show FakeSyncApi;

Map<String, dynamic> planRecord(
  String id, {
  Object? value,
  bool legacy = false,
}) => {
  'entityType': 'workoutPlan',
  'entityId': id,
  'version': 1,
  'updatedAt': '2026-10-16T00:00:00Z',
  'deletedAt': null,
  'payload': {
    'nazwa': id,
    'cwiczeniaIds': structure.exerciseIds,
    'cel': 'mix',
    'dataUtworzenia': '2026-10-16T00:00:00Z',
    if (!legacy) 'structure': value ?? structure.toJson(),
  },
};

void main() {
  late AppDatabase db;
  late SyncStore store;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = SyncStore(db);
  });
  tearDown(() => db.close());

  for (final raw in ['{}', '{', '{"schemaVersion":999}', '[]', 'null']) {
    test(
      'existing invalid raw $raw does not hide good or legacy history',
      () async {
        await store.apply(planRecord('good'));
        await store.apply(planRecord('legacy', legacy: true));
        await store.apply(planRecord('damaged', legacy: true));
        await (db.update(db.workoutPlans)
              ..where((p) => p.syncId.equals('damaged')))
            .write(WorkoutPlansCompanion(structureJson: Value(raw)));
        final history = await PlannerRepository(db).watchAll().first;
        expect(history.map((p) => p.nazwa).toSet(), {
          'good',
          'legacy',
          'damaged',
        });
        expect(
          history.singleWhere((p) => p.nazwa == 'good').structure!.toJson(),
          structure.toJson(),
        );
        expect(
          history.singleWhere((p) => p.nazwa == 'damaged').structure,
          isNull,
        );
        final damaged = history.singleWhere((p) => p.nazwa == 'damaged');
        expect(damaged.isUnavailable, isTrue);
        expect(damaged.structureError, contains('Plan niedostępny'));
        expect(damaged.rawStructureJson, raw);
        expect(
          history.singleWhere((p) => p.nazwa == 'legacy').isUnavailable,
          isFalse,
        );
        expect(
          (await (db.select(
                db.workoutPlans,
              )..where((p) => p.syncId.equals('damaged'))).getSingle())
              .structureJson,
          raw,
        );
      },
    );
  }
  test(
    'delete damaged JSON uses identity, retains raw row and attempted bytes; tombstone pulls',
    () async {
      final repo = PlannerRepository(db);
      final id = await repo.savePlan(
        nazwa: 'damaged',
        cwiczeniaIds: structure.exerciseIds,
        cel: 'mix',
        structure: structure,
      );
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final attempted =
          (await db.customSelect('SELECT * FROM sync_outbox').getSingle()).data;
      await (db.update(db.workoutPlans)..where((p) => p.id.equals(id))).write(
        const WorkoutPlansCompanion(structureJson: Value('{')),
      );
      final row = await db.plansDao.getPlan(id);
      await repo.deletePlan(id);
      final deleted = (await db.select(db.workoutPlans).getSingle());
      expect(deleted.deletedAtUtc, isNotNull);
      expect(deleted.structureJson, '{');
      expect(await repo.watchAll().first, isEmpty);
      expect(
        (await db
                .customSelect('SELECT * FROM sync_outbox WHERE attempted = 1')
                .getSingle())
            .data,
        attempted,
      );
      final deletion = (await db.syncDao.pendingOperations()).singleWhere(
        (o) => o.deleted,
      );
      expect(deletion.entityId, row!.syncId);
      expect(deletion.payload, {
        'nazwa': row.nazwa,
        'cwiczeniaIds': structure.exerciseIds,
        'cel': row.cel,
        'dataUtworzenia': row.dataUtworzenia.toUtc().toIso8601String(),
      });
      await db.delete(db.syncOutbox).go();
      await store.apply({
        ...planRecord(row.syncId),
        'version': 2,
        'deletedAt': '2026-10-16T01:00:00Z',
        'payload': <String, dynamic>{},
      });
      expect((await db.select(db.workoutPlans).getSingle()).structureJson, '{');
      expect((await db.select(db.workoutPlans).getSingle()).syncVersion, 2);
      await store.enqueueAll();
      expect((await db.syncDao.pendingOperations()).single.deleted, isTrue);
    },
  );

  for (final value in <Object>[
    <String, Object?>{},
    {'schemaVersion': 999},
    [],
    'not a map',
    {...structure.toJson(), 'budgetSeconds': '300'},
    {
      ...structure.toJson(),
      'criteria': {
        'conditions': [false],
      },
    },
    {
      ...structure.toJson(),
      'blocks': [
        {
          'exerciseId': 'yoga',
          'section': 'unknown',
          'prescription': structure.blocks.single.prescription.toJson(),
        },
      ],
    },
    {
      ...structure.toJson(),
      'criteria': {'sortBy': 'unknown'},
    },
    {
      ...structure.toJson(),
      'criteria': {
        'futureRestriction': ['do-not-ignore'],
      },
    },
  ]) {
    test(
      'apply rejects invalid structure ${jsonEncode(value)} before persisting',
      () async {
        await store.apply(planRecord('good'));
        await store.apply(planRecord('legacy', legacy: true));
        await expectLater(
          store.apply(planRecord('bad', value: value)),
          throwsFormatException,
        );
        expect(
          (await PlannerRepository(
            db,
          ).watchAll().first).map((p) => p.nazwa).toSet(),
          {'good', 'legacy'},
        );
        expect(await db.select(db.workoutPlans).get(), hasLength(2));
      },
    );
  }
  test('structure exercise IDs must match ordered wire IDs', () async {
    final record = planRecord('mismatch');
    (record['payload'] as Map)['cwiczeniaIds'] = ['other'];
    await expectLater(store.apply(record), throwsFormatException);
    expect(await db.select(db.workoutPlans).get(), isEmpty);
  });
  test(
    'bad structure cannot update dirty row version or deferred snapshot',
    () async {
      await PlannerRepository(db).savePlan(
        nazwa: 'dirty',
        cwiczeniaIds: structure.exerciseIds,
        cel: 'mix',
        structure: structure,
      );
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final row = await db.select(db.workoutPlans).getSingle();
      final attempted =
          (await db.customSelect('SELECT * FROM sync_outbox').getSingle()).data;
      await expectLater(
        store.apply({...planRecord(row.syncId, value: {}), 'version': 8}),
        throwsFormatException,
      );
      expect(
        (await db.select(db.workoutPlans).getSingle()).toJson(),
        row.toJson(),
      );
      expect(await db.select(db.syncDeferredRecords).get(), isEmpty);
      expect(
        (await db.customSelect('SELECT * FROM sync_outbox').getSingle()).data,
        attempted,
      );
    },
  );
  test(
    'valid current conditions and positions survive validation and new outbox unchanged',
    () async {
      final value = {
        ...structure.toJson(),
        'criteria': {
          ...(structure.toJson()['criteria'] as Map),
          'conditions': ['no_jumps'],
          'positions': ['standing'],
        },
      };
      await store.apply(planRecord('restricted', value: value));
      final saved = (await PlannerRepository(db).watchAll().first).single;
      expect(saved.structure!.criteria.conditions, {'no_jumps'});
      expect(saved.structure!.criteria.positions, {'standing'});
      await store.enqueueAll();
      expect(
        (await db.syncDao.pendingOperations()).single.payload['structure'],
        value,
      );
    },
  );
  test(
    'bad structure is quarantined while independent plans and cursor advance',
    () async {
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      addTearDown(sync.dispose);
      await sync.bindAccount('account');
      await store.apply(planRecord('existing'));
      final before = (await db.syncDao.readState())!.toJson();
      final bad = planRecord('new-bad', value: {});
      api.page = {
        'cursor': 25,
        'changes': [planRecord('new-good'), bad],
      };
      await sync.synchronize();
      expect((await db.select(db.workoutPlans).get()).map((p) => p.nazwa), [
        'existing',
        'new-good',
      ]);
      expect(sync.status, SyncStatus.conflict);
      expect((await db.syncDao.readState())!.toJson(), {
        ...before,
        'fullCursor': 25,
      });
      final held = jsonDecode(
        (await db.select(db.syncDeferredRecords).getSingle()).recordJson,
      );
      expect(held['raw'], bad);
      expect(held['cursor'], 25);
      expect(held['accountId'], 'account');
      expect(held['recovered'], false);
      api.page = {
        'cursor': 26,
        'changes': [
          {...planRecord('new-bad'), 'version': 2},
        ],
      };
      await sync.synchronize();
      expect(await db.select(db.workoutPlans).get(), hasLength(3));
      expect(sync.status, SyncStatus.idle);
      expect((await db.syncDao.readState())!.toJson(), {
        ...before,
        'fullCursor': 26,
      });
      final recovered = jsonDecode(
        (await db.select(db.syncDeferredRecords).getSingle()).recordJson,
      );
      expect(recovered['raw'], bad);
      expect(recovered['recovered'], true);
    },
  );
  test(
    'new outbox rejects corrupt local structure atomically; attempted bytes unchanged',
    () async {
      await PlannerRepository(db).savePlan(
        nazwa: 'good',
        cwiczeniaIds: structure.exerciseIds,
        cel: 'mix',
        structure: structure,
      );
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final before = (await db.customSelect('SELECT * FROM sync_outbox').get())
          .map((r) => r.data)
          .toList();
      await store.apply(planRecord('bad-local', legacy: true));
      await (db.update(db.workoutPlans)
            ..where((p) => p.syncId.equals('bad-local')))
          .write(const WorkoutPlansCompanion(structureJson: Value('{}')));
      await expectLater(store.enqueueAll(), throwsFormatException);
      expect(
        (await db.customSelect('SELECT * FROM sync_outbox').get())
            .map((r) => r.data)
            .toList(),
        before,
      );
    },
  );
  test(
    'restore invalid structure rolls back original plans and attempted queue',
    () async {
      await PlannerRepository(db).savePlan(
        nazwa: 'good',
        cwiczeniaIds: structure.exerciseIds,
        cel: 'mix',
        structure: structure,
      );
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final before = (await db.customSelect('SELECT * FROM sync_outbox').get())
          .map((r) => r.data)
          .toList();
      final service = BackupService(db);
      final backup =
          jsonDecode(utf8.decode(await service.exportToBytes()))
              as Map<String, dynamic>;
      (backup['data']['workoutPlans'] as List).single['structureJson'] = '{}';
      expect(
        (await service.importFromBytes(
          utf8.encode(jsonEncode(backup)),
        )).success,
        isFalse,
      );
      expect(
        (await PlannerRepository(
          db,
        ).watchAll().first).single.structure!.toJson(),
        structure.toJson(),
      );
      expect(
        (await db.customSelect('SELECT * FROM sync_outbox').get())
            .map((r) => r.data)
            .toList(),
        before,
      );
    },
  );
}
