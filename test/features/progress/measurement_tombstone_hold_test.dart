import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_quarantine.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/progress/measurements/data/measurements_repository.dart';
import '../../core/sync_service_test.dart' show FakeSyncApi;

void main() {
  for (final deleted in [false, true]) {
    for (final preserveLocal in [false, true]) {
      for (final successor in [false, true]) {
        test(
          'omitted date tombstone holds delete=$deleted restore=$preserveLocal successor=$successor across reopen',
          () async {
            final directory = await Directory.systemTemp.createTemp(
              'measurement-hold-',
            );
            final file = File('${directory.path}/test.sqlite');
            var db = AppDatabase.forTesting(NativeDatabase(file));
            final api = FakeSyncApi();
            var sync = SyncService(db, api);
            addTearDown(() async {
              sync.dispose();
              await db.close();
              await directory.delete(recursive: true);
            });
            await sync.bindAccount('A');
            final repo = MeasurementsRepository(db);
            await repo.addMeasurement(wagaKg: 72, notatka: 'local intent');
            final row = (await repo.getLatest())!;
            final create = (await db.syncDao.pendingOperations()).single;
            await db.delete(db.syncOutbox).go();
            await SyncStore(
              db,
            ).version(SyncEntityType.measurement, row.syncId, 1);
            // An earlier restore mutation passes preserveLocal into the edit.
            await db.syncDao.enqueueUpsert(
              entityType: SyncEntityType.measurement,
              entityId: row.syncId,
              baseVersion: 1,
              payload: create.payload,
              preserveLocal: preserveLocal,
            );
            final edit = await repo.capture(row.id);
            if (deleted) {
              await repo.deleteMeasurement(edit);
            } else {
              await repo.updateMeasurement(
                edit,
                wagaKg: 74,
                obwodKlatki: null,
                obwodTalii: null,
              );
            }
            final original = (await db.syncDao.pendingOperations()).single;
            expect(original.payload.containsKey('data'), isFalse);
            expect(original.preserveLocal, preserveLocal);
            final before = await db.select(db.syncOutbox).getSingle();
            final tombstone = <String, dynamic>{
              'entityType': 'measurement',
              'entityId': row.syncId,
              'version': 2,
              'updatedAt': '2026-10-19T12:35:00Z',
              'deletedAt': '2026-10-19T12:35:00Z',
              'payload': {'data': '2026-10-19T12:34:58.979Z', 'wagaKg': 72.0},
            };
            Map<String, dynamic>? rawConflict;
            var measurementAttempts = 0;
            var moodAccepted = 0;
            var successorQueued = false;
            api.onPush = (ops) async {
              final conflicts = <Map<String, dynamic>>[];
              for (final op in ops) {
                if (op.entityType != SyncEntityType.measurement) continue;
                measurementAttempts++;
                // Backend contract: even at the current version omission cannot
                // take data from a tombstone. A conflict rolls back this batch.
                if (op.baseVersion != tombstone['version'] ||
                    (!op.payload.containsKey('data') &&
                        tombstone['deletedAt'] != null)) {
                  final conflict = <String, dynamic>{
                    'operationId': op.operationId,
                    'record': tombstone,
                  };
                  rawConflict ??= conflict;
                  conflicts.add(conflict);
                } else {
                  fail(
                    'Must not fabricate a date or resurrect the server record',
                  );
                }
              }
              if (measurementAttempts == 1 && successor && !successorQueued) {
                successorQueued = true;
                // A later mutation arrives while the original is in flight.
                await db.syncDao.enqueueUpsert(
                  entityType: SyncEntityType.measurement,
                  entityId: row.syncId,
                  baseVersion: 1,
                  payload: {...original.payload, 'wagaKg': 75.0},
                );
              }
              if (conflicts.isNotEmpty) {
                return {'accepted': [], 'conflicts': conflicts};
              }
              moodAccepted += ops
                  .where((o) => o.entityType == SyncEntityType.mood)
                  .length;
              return {
                'accepted': [
                  for (final op in ops)
                    {
                      'operationId': op.operationId,
                      'version': op.baseVersion + 1,
                      'updatedAt': '2026-10-19T12:36:00Z',
                      'duplicate': false,
                    },
                ],
                'conflicts': [],
              };
            };
            Future<void> enqueueIndependent(String id) =>
                db.syncDao.enqueueUpsert(
                  entityType: SyncEntityType.mood,
                  entityId: id,
                  baseVersion: 0,
                  payload: {'nastroj': 3},
                );
            await enqueueIndependent('independent-before');
            await sync.synchronize();
            expect(measurementAttempts, 1);
            expect(moodAccepted, 1);
            expect(sync.status, SyncStatus.conflict);
            final pending = await db.select(db.syncOutbox).get();
            expect(pending, hasLength(successor ? 2 : 1));
            expect(
              pending.singleWhere((o) => o.operationId == original.operationId),
              before.copyWith(attempted: true),
            );
            final hold = (await db.select(db.syncDeferredRecords).get())
                .singleWhere((r) => r.entityType == SyncQuarantine.pushType);
            final evidence = jsonDecode(hold.recordJson) as Map;
            expect(evidence['accountId'], 'A');
            expect(evidence['key'], 'measurement:${row.syncId}');
            expect(evidence['operationId'], original.operationId);
            expect(
              (evidence['outcome'] as Map)['record'],
              rawConflict!['record'],
            );
            expect(
              (evidence['outcome'] as Map)['operationId'],
              original.operationId,
            );
            expect(
              (evidence['outcome'] as Map)['localRecoveryPolicy'],
              'explicit-authoritative-resolution',
            );
            final pendingIds = pending.map((o) => o.operationId).toSet();

            // A later pull must not erase the hold or the original intent either.
            api.page = {
              'cursor': 1,
              'changes': [tombstone],
            };
            await sync.synchronize();
            api.page = {'cursor': 1, 'changes': <dynamic>[]};

            sync.dispose();
            await db.close();
            db = AppDatabase.forTesting(NativeDatabase(file));
            sync = SyncService(db, api);
            await sync.bindAccount('A');
            await enqueueIndependent('independent-after');
            await sync.synchronize();
            await sync.synchronize();
            expect(measurementAttempts, 1);
            expect(moodAccepted, 2);
            expect(sync.status, SyncStatus.conflict);
            final reopened = await db.select(db.syncOutbox).get();
            expect(reopened.map((o) => o.operationId).toSet(), pendingIds);
            expect(
              reopened.singleWhere(
                (o) => o.operationId == original.operationId,
              ),
              before.copyWith(attempted: true),
            );
            expect(
              reopened
                  .where((o) => o.operationId != original.operationId)
                  .every((o) => !o.attempted),
              isTrue,
            );
            expect(
              (await db.select(db.measurements).getSingle()).syncId,
              row.syncId,
            );
            expect(
              (await db.select(db.syncDeferredRecords).get()).singleWhere(
                (r) => r.entityType == SyncQuarantine.pushType,
              ),
              hold,
            );
          },
        );
      }
    }
  }
}
