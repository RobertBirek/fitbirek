import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/data/session_actions_repository.dart';
import 'session_recovery_provider_test.dart' show RecoveryAuthority;
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_quarantine.dart';
import 'package:fitbirek_training/features/progress/prs/data/prs_repository.dart';
import 'package:fitbirek_training/features/progress/trends/data/training_trend_repository.dart';
import '../../core/sync_service_test.dart' show FakeSyncApi;

class ExpiringAuthority extends RecoveryAuthority {
  int? reads;
  @override
  int get epoch {
    if (reads == null) return super.epoch;
    final remaining = reads!;
    reads = remaining - 1;
    return remaining <= 0 ? super.epoch + 1 : super.epoch;
  }
}

void main() {
  late AppDatabase db;
  late WorkoutRepository workouts;
  late SessionActionsRepository actions;
  late RecoveryAuthority authority;
  late int id;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    workouts = WorkoutRepository(db);
    authority = RecoveryAuthority();
    actions = SessionActionsRepository(db, authority);
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
    id = await workouts.startSession(accountId: 'a');
  });
  tearDown(() => db.close());
  Future<void> set() => workouts.logSet(
    sessionId: id,
    exerciseId: 'cw1',
    exerciseNamePl: 'Test',
    setNumber: 1,
    reps: 10,
    accountId: 'a',
  );

  test(
    'empty finish is rejected atomically, also recovery; a live set permits finish',
    () async {
      final edit = await actions.capture(id);
      final queue = await db.select(db.syncOutbox).get();
      await expectLater(
        workouts.finishSession(id, edit.row.dataStart),
        throwsA(isA<EmptyWorkoutSession>()),
      );
      await expectLater(
        actions.finish(edit),
        throwsA(isA<EmptyWorkoutSession>()),
      );
      expect((await db.workoutDao.getSession(id))!.dataKoniec, isNull);
      expect(await db.select(db.syncOutbox).get(), queue);
      await set();
      await actions.finish(await actions.capture(id));
      expect((await db.workoutDao.getSession(id))!.dataKoniec, isNotNull);
    },
  );

  test(
    'delete tombstones all sets + session, clears draft; attempted bytes and PR stay',
    () async {
      await set();
      await PrsRepository(db).savePr(
        exerciseId: 'cw1',
        exerciseNamePl: 'Test',
        weightKg: 10,
        reps: 10,
      );
      final prs = await db.select(db.personalRecords).get();
      final row = (await db.workoutDao.getSession(id))!;
      await workouts.saveDraft(
        sessionId: id,
        sessionSyncId: row.syncId,
        accountId: 'a',
        payload: {
          'schemaVersion': 1,
          'currentSlot': 0,
          'selectedIds': ['cw1'],
          'fields': <String, Object?>{},
        },
        guard: () => true,
      );
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final before = await db.select(db.syncOutbox).get();
      final edit = await actions.capture(id);
      await actions.delete(edit);
      expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNotNull);
      expect(
        (await db.select(db.setsLog).get()).single.deletedAtUtc,
        isNotNull,
      );
      expect(await db.select(db.workoutDrafts).get(), isEmpty);
      final after = await db.select(db.syncOutbox).get();
      expect(after.where((s) => s.attempted).toList(), before);
      expect(
        (await db.syncDao.pendingOperations()).where((o) => o.deleted).length,
        2,
      );
      await expectLater(actions.delete(edit), throwsA(isA<SessionConflict>()));
      expect(await db.workoutDao.getAllSets(), isEmpty);
      expect(await db.workoutDao.getAllSessionsSorted(), isEmpty);
      expect(await db.select(db.personalRecords).get(), prs);
    },
  );

  test(
    'auth invalidation after delete SQL rolls back session, children, draft and outbox',
    () async {
      await set();
      final a = ExpiringAuthority();
      final secured = SessionActionsRepository(db, a);
      final edit = await secured.capture(id);
      final before = await db.select(db.syncOutbox).get();
      // check() has two authority reads; final ownership check follows the writes.
      a.reads = 2;
      await expectLater(secured.delete(edit), throwsA(isA<SessionConflict>()));
      expect(await db.select(db.syncOutbox).get(), before);
      expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNull);
      expect((await db.select(db.setsLog).get()).single.deletedAtUtc, isNull);
    },
  );

  for (final hold in ['push', 'pull']) {
    test(
      '$hold quarantine blocks parent cascade without unseen deletion',
      () async {
        await set();
        final edit = await actions.capture(id);
        final q = SyncQuarantine(db, SyncStore(db));
        final op = (await db.syncDao.pendingOperations()).firstWhere(
          (o) => o.entityId == edit.sets.single.syncId,
        );
        if (hold == 'push') {
          await q.hold('a', op, {'error': 'unknown'});
        } else {
          await q.apply(
            {
              'entityType': 'workoutSet',
              'entityId': op.entityId,
              'version': 2,
              'updatedAt': '2026-10-19T12:00:00Z',
              'deletedAt': null,
              'payload': <String, Object?>{},
            },
            'a',
            5,
            0,
          );
        }
        await expectLater(
          actions.delete(edit),
          throwsA(isA<SessionConflict>()),
        );
        expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNull);
      },
    );
  }

  test(
    'delete push ACK + pull tombstones retain identities; finished trends exclude deletion',
    () async {
      await set();
      await workouts.finishSession(id, DateTime.now());
      expect(await TrainingTrendRepository(db).readHistory(), hasLength(1));
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      addTearDown(sync.dispose);
      await sync.bindAccount('a');
      await sync.synchronize();
      final edit = await actions.capture(id);
      await actions.delete(edit);
      final deletes = await db.syncDao.pendingOperations();
      expect(deletes.every((o) => o.deleted), isTrue);
      await sync.synchronize();
      expect(await db.syncDao.pendingOperations(), isEmpty);
      api.page = {
        'cursor': 10,
        'changes': [
          for (final op in deletes)
            {
              'entityType': op.entityType.wireName,
              'entityId': op.entityId,
              'version': op.baseVersion + 2,
              'updatedAt': '2026-10-19T12:00:00Z',
              'deletedAt': '2026-10-19T12:00:00Z',
              'payload': op.payload,
            },
        ],
      };
      await sync.synchronize();
      expect((await db.workoutDao.getSession(id))!.syncId, edit.row.syncId);
      expect(await workouts.getSetsForSession(id), isEmpty);
      expect(await TrainingTrendRepository(db).readHistory(), isEmpty);
      expect((await db.syncDao.readState())!.fullCursor, 10);
    },
  );

  for (final change in [
    'new set',
    'removed set',
    'draft',
    'binding',
    'epoch',
    'deferred',
    'unseen deferred child',
  ]) {
    test(
      'unseen $change refuses delete and finish without changing outbox',
      () async {
        await set();
        final edit = await actions.capture(id);
        switch (change) {
          case 'new set':
            await set();
          case 'removed set':
            await db
                .update(db.setsLog)
                .write(SetsLogCompanion(deletedAtUtc: Value(DateTime.now())));
          case 'draft':
            await workouts.saveDraft(
              sessionId: id,
              sessionSyncId: edit.row.syncId,
              accountId: 'a',
              payload: {
                'schemaVersion': 1,
                'currentSlot': 0,
                'selectedIds': ['cw1'],
                'fields': {'reps': '12'},
              },
              guard: () => true,
            );
          case 'binding':
            await db
                .update(db.syncState)
                .write(const SyncStateCompanion(deviceId: Value('new')));
          case 'epoch':
            authority.switchTo('b');
            authority.switchTo('a');
          case 'deferred':
            await db
                .into(db.syncDeferredRecords)
                .insert(
                  SyncDeferredRecordsCompanion.insert(
                    entityType: 'workoutSet',
                    entityId: edit.sets.single.syncId,
                    version: 1,
                    recordJson: '{}',
                  ),
                );
          case 'unseen deferred child':
            await db
                .into(db.syncDeferredRecords)
                .insert(
                  SyncDeferredRecordsCompanion.insert(
                    entityType: 'workoutSet',
                    entityId: 'unseen-child',
                    version: 1,
                    recordJson:
                        '{"entityType":"workoutSet","payload":{"sessionSyncId":"${edit.row.syncId}"}}',
                  ),
                );
        }
        final queue = await db.select(db.syncOutbox).get();
        await expectLater(
          actions.delete(edit),
          throwsA(isA<SessionConflict>()),
        );
        await expectLater(
          actions.finish(edit),
          throwsA(isA<SessionConflict>()),
        );
        expect(await db.select(db.syncOutbox).get(), queue);
        expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNull);
        expect((await db.workoutDao.getSession(id))!.dataKoniec, isNull);
      },
    );
  }

  test(
    'tombstone survives reopen and late pull child is cascaded to durable DELETE',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'session-delete-',
      );
      final file = File('${directory.path}/workout.db');
      final disk = AppDatabase.forTesting(NativeDatabase(file));
      await disk
          .into(disk.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final repo = WorkoutRepository(disk);
      final sid = await repo.startSession(accountId: 'a');
      final edit = await SessionActionsRepository(disk, authority).capture(sid);
      await SessionActionsRepository(disk, authority).delete(edit);
      await disk.close();
      final reopened = AppDatabase.forTesting(NativeDatabase(file));
      try {
        expect(
          (await reopened.workoutDao.getSession(sid))!.deletedAtUtc,
          isNotNull,
        );
        await reopened.transaction(
          () => SyncStore(reopened).apply({
            'entityType': 'workoutSet',
            'entityId': '12345678-1234-4234-8234-123456789012',
            'version': 1,
            'updatedAt': '2026-10-19T12:00:00Z',
            'deletedAt': null,
            'payload': {
              'sessionSyncId': edit.row.syncId,
              'cwiczenieId': 'cw1',
              'nazwaCwiczeniaPl': 'Test',
              'numerSerii': 1,
              'powtorzenia': 10,
              'ciezarKg': null,
              'czasSekund': null,
              'rpe': null,
              'timestamp': '2026-10-19T12:00:00Z',
            },
          }),
        );
        expect(await reopened.workoutDao.getAllSets(), isEmpty);
        expect(
          (await reopened.select(reopened.setsLog).get()).single.deletedAtUtc,
          isNotNull,
        );
        expect(
          (await reopened.syncDao.pendingOperations())
              .where((o) => o.deleted)
              .length,
          2,
        );
      } finally {
        await reopened.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
