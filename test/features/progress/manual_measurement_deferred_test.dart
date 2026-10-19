import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_quarantine.dart';
import 'package:fitbirek_training/features/progress/measurements/data/measurements_repository.dart';

void main() {
  late AppDatabase db;
  late MeasurementsRepository repo;
  late SyncStore store;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MeasurementsRepository(db);
    store = SyncStore(db);
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'A', deviceId: 'd'));
    await repo.addMeasurement(wagaKg: 72, notatka: 'local');
    await db
        .update(db.syncOutbox)
        .write(const SyncOutboxCompanion(attempted: Value(true)));
  });
  tearDown(() => db.close());

  Future<Map<String, dynamic>> remote(bool deleted) async {
    final op = (await db.syncDao.pendingOperations()).first;
    return {
      'entityType': 'measurement',
      'entityId': op.entityId,
      'version': 2,
      'updatedAt': '2026-10-18T12:00:00Z',
      'deletedAt': deleted ? '2026-10-18T12:00:00Z' : null,
      'payload': <String, dynamic>{
        ...op.payload,
        'wagaKg': 90.0,
        'notatka': 'unseen remote',
      },
    };
  }

  Future<Object> snapshot() async => [
    await db.select(db.measurements).get(),
    await db.select(db.syncOutbox).get(),
    await db.select(db.syncDeferredRecords).get(),
  ];
  Future<void> unchanged(Object before) async {
    final after = await snapshot();
    expect(after, before);
  }

  for (final deleted in [false, true]) {
    test(
      'remote deleted=$deleted before capture blocks stale fields at bumped version',
      () async {
        final row = (await repo.getLatest())!;
        final attempted = await db.select(db.syncOutbox).getSingle();
        await db.transaction(() async => store.apply(await remote(deleted)));
        expect((await repo.getLatest())!.syncVersion, 2);
        expect((await repo.getLatest())!.notatka, 'local');
        final before = await snapshot();
        await expectLater(
          repo.capture(row.id),
          throwsA(isA<MeasurementSyncPending>()),
        );
        await unchanged(before);
        expect(await db.select(db.syncOutbox).getSingle(), attempted);
      },
    );

    for (final deleteAction in [false, true]) {
      for (final version in [2, 3]) {
        test(
          'remote v$version deleted=$deleted after capture rejects delete=$deleteAction',
          () async {
            // Equal-version replay can introduce deferred data without changing ANY
            // field in the captured row, including syncVersion.
            final row = (await repo.getLatest())!;
            await db.transaction(
              () => store.version(SyncEntityType.measurement, row.syncId, 2),
            );
            final edit = await repo.capture(row.id);
            final attempted = await db.select(db.syncOutbox).getSingle();
            final record = await remote(deleted);
            record['version'] = version;
            await db.transaction(() => store.apply(record));
            if (version == 2) expect(await repo.getLatest(), edit.row);
            final before = await snapshot();
            await expectLater(
              deleteAction
                  ? repo.deleteMeasurement(edit)
                  : repo.updateMeasurement(
                      edit,
                      wagaKg: 75,
                      obwodKlatki: null,
                      obwodTalii: null,
                    ),
              throwsA(isA<MeasurementSyncPending>()),
            );
            await unchanged(before);
            expect(await db.select(db.syncOutbox).getSingle(), attempted);
          },
        );
      }
    }

    test(
      'resolved deleted=$deleted snapshot is authoritative on reopen',
      () async {
        final row = (await repo.getLatest())!;
        await db.transaction(() async => store.apply(await remote(deleted)));
        // Simulate resolved pending operation, then run the real reconciler.
        await db.transaction(() async {
          await db.delete(db.syncOutbox).go();
          await store.reconcile(SyncEntityType.measurement, row.syncId);
        });
        if (deleted) {
          await expectLater(
            repo.capture(row.id),
            throwsA(isA<MeasurementConflict>()),
          );
        } else {
          final edit = await repo.capture(row.id);
          expect(edit.row.notatka, 'unseen remote');
          await repo.updateMeasurement(
            edit,
            wagaKg: 75,
            obwodKlatki: null,
            obwodTalii: null,
          );
          expect(
            (await db.syncDao.pendingOperations()).single.payload['notatka'],
            'unseen remote',
          );
        }
      },
    );
  }

  test(
    'pending local writes and unrelated deferred/other-account holds do not block',
    () async {
      final row = (await repo.getLatest())!;
      await repo.addMeasurement(wagaKg: 55);
      final other = (await repo.getLatest())!;
      final record = await remote(false);
      record['entityId'] = other.syncId;
      await db.transaction(() => store.apply(record));
      final quarantine = SyncQuarantine(db, store);
      final op = (await db.syncDao.pendingOperations()).firstWhere(
        (o) => o.entityId == row.syncId,
      );
      await quarantine.hold('B', op, {});
      final edit = await repo.capture(row.id);
      await repo.updateMeasurement(
        edit,
        wagaKg: 76,
        obwodKlatki: null,
        obwodTalii: null,
      );
      expect(
        (await db.select(db.measurements).get())
            .firstWhere((m) => m.id == row.id)
            .wagaKg,
        76,
      );
    },
  );

  test(
    'exact account-scoped hold blocks capture without changing evidence',
    () async {
      final row = (await repo.getLatest())!;
      await SyncQuarantine(
        db,
        store,
      ).hold('A', (await db.syncDao.pendingOperations()).single, {});
      final before = await snapshot();
      await expectLater(
        repo.capture(row.id),
        throwsA(isA<MeasurementConflict>()),
      );
      await unchanged(before);
    },
  );

  for (final pull in [false, true]) {
    test(
      'account-scoped ${pull ? 'quarantine' : 'hold'} after capture blocks both mutations',
      () async {
        final edit = await repo.capture((await repo.getLatest())!.id);
        final quarantine = SyncQuarantine(db, store);
        if (pull) {
          final record = await remote(false);
          record['payload'] = <String, dynamic>{};
          await db.transaction(() => quarantine.apply(record, 'A', 1, 0));
        } else {
          await quarantine.hold(
            'A',
            (await db.syncDao.pendingOperations()).single,
            {},
          );
        }
        final before = await snapshot();
        await expectLater(
          repo.updateMeasurement(
            edit,
            wagaKg: 75,
            obwodKlatki: null,
            obwodTalii: null,
          ),
          throwsA(isA<MeasurementSyncPending>()),
        );
        await expectLater(
          repo.deleteMeasurement(edit),
          throwsA(isA<MeasurementSyncPending>()),
        );
        await unchanged(before);
      },
    );
  }

  test(
    'strictly older deferred authority does not block a newer acknowledged row',
    () async {
      final row = (await repo.getLatest())!;
      await db.transaction(() async {
        await store.apply(await remote(false));
        await store.version(SyncEntityType.measurement, row.syncId, 3);
      });
      final edit = await repo.capture(row.id);
      await repo.updateMeasurement(
        edit,
        wagaKg: 78,
        obwodKlatki: null,
        obwodTalii: null,
      );
      expect((await repo.getLatest())!.wagaKg, 78);
    },
  );
}
