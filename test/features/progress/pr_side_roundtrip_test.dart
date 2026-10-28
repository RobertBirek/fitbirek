import 'package:drift/native.dart';
import '../../core/database/legacy_schema.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/progress/prs/data/prs_repository.dart';

void main() {
  test(
    'v8 -> v9 preserves legacy PR and immutable attempted outbox on reopen',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      var db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      await PrsRepository(
        db,
      ).savePr(exerciseId: 'x', exerciseNamePl: 'Test', weightKg: 80, reps: 5);
      await db.customStatement('UPDATE personal_records SET sync_version = 7');
      await db.customStatement(
        'UPDATE sync_outbox SET attempted = 1, base_version = 6',
      );
      final before = (await db.select(db.personalRecords).get()).single.toJson()
        ..remove('side');
      final outbox = (await db.customSelect('SELECT * FROM sync_outbox').get())
          .single
          .data;
      await db.customStatement('ALTER TABLE personal_records DROP COLUMN side');
      await removeV12Columns(db);
      await db.customStatement('PRAGMA user_version = 8');
      await db.customStatement(
        'ALTER TABLE workout_sessions DROP COLUMN guidance_json',
      );
      await db.customStatement('DROP TABLE workout_drafts');
      await db.customStatement(
        'ALTER TABLE workout_plans DROP COLUMN structure_json',
      );
      await db.close();
      db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      final migrated = (await db.select(db.personalRecords).get()).single
          .toJson();
      expect(migrated.remove('side'), isNull);
      expect(migrated, before);
      expect(
        (await db.customSelect('SELECT * FROM sync_outbox').get()).single.data,
        outbox,
      );
      await PrsRepository(db).savePr(
        exerciseId: 'x',
        exerciseNamePl: 'Test',
        weightKg: 20,
        reps: 5,
        side: 'both',
      );
      await expectLater(
        PrsRepository(db).savePr(
          exerciseId: 'x',
          exerciseNamePl: 'Test',
          weightKg: 20,
          reps: 5,
          side: 'invalid',
        ),
        throwsA(isA<Exception>()),
      );
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(db.close);
      expect((await PrsRepository(db).getBestForExercise('x'))!.ciezarKg, 80);
      expect(
        (await PrsRepository(
          db,
        ).getBestForExercise('x', side: 'both'))!.ciezarKg,
        20,
      );
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        15,
      );
    },
  );

  test(
    'PR sides survive pull, JSON, backup restore and new outbox; missing side clears to NULL',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final store = SyncStore(db);
      for (final side in [null, 'left', 'right', 'both']) {
        await store.apply({
          'entityType': 'personalRecord',
          'entityId': 'pr-$side',
          'version': 2,
          'updatedAt': '2026-10-16T00:00:00Z',
          'deletedAt': null,
          'payload': {
            'cwiczenieId': 'x',
            'nazwaCwiczeniaPl': 'Test',
            'ciezarKg': 20.0,
            'powtorzenia': 5,
            'szacowane1Rm': 23.3,
            'data': '2026-10-16T00:00:00Z',
            if (side != null) 'side': side,
          },
        });
      }
      final rows = await db.select(db.personalRecords).get();
      expect(rows.map((r) => PersonalRecordData.fromJson(r.toJson()).side), [
        null,
        'left',
        'right',
        'both',
      ]);
      final priorRight = (await store.row(
        SyncEntityType.personalRecord,
        'pr-right',
      ))!;
      final legacyPayload = Map<String, dynamic>.from(priorRight)
        ..remove('side');
      await store.apply({
        'entityType': 'personalRecord',
        'entityId': 'pr-right',
        'version': 3,
        'updatedAt': '2026-10-16T00:00:00Z',
        'deletedAt': null,
        'payload': legacyPayload,
      });
      expect(
        (await store.row(SyncEntityType.personalRecord, 'pr-right'))!['side'],
        isNull,
      );
      await store.apply({
        'entityType': 'personalRecord',
        'entityId': 'pr-right',
        'version': 4,
        'updatedAt': '2026-10-16T00:00:00Z',
        'deletedAt': null,
        'payload': {...legacyPayload, 'side': 'right'},
      });
      final backup = BackupService(db);
      expect(
        (await backup.importFromBytes(await backup.exportToBytes())).success,
        isTrue,
      );
      final restored = await db.select(db.personalRecords).get();
      expect(restored.map((r) => r.side), [null, 'left', 'right', 'both']);
      final ops = (await db.syncDao.pendingOperations())
          .where((o) => !o.deleted && o.entityType.wireName == 'personalRecord')
          .toList();
      expect(ops.map((o) => o.payload['side']), [
        null,
        'left',
        'right',
        'both',
      ]);
      expect(ops.first.payload.containsKey('side'), isFalse);
    },
  );

  test(
    'restore does not rewrite attempted PR payloads with or without side',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = PrsRepository(db);
      for (final side in [null, 'both']) {
        await repo.savePr(
          exerciseId: 'x',
          exerciseNamePl: 'Test',
          weightKg: 20,
          reps: 5,
          side: side,
        );
      }
      await db.customStatement(
        'UPDATE sync_outbox SET attempted = 1, base_version = 5',
      );
      final before =
          (await db
                  .customSelect(
                    'SELECT * FROM sync_outbox ORDER BY operation_id',
                  )
                  .get())
              .map((r) => r.data)
              .toList();
      final backup = BackupService(db);
      expect(
        (await backup.importFromBytes(await backup.exportToBytes())).success,
        isTrue,
      );
      final attempted =
          (await db
                  .customSelect(
                    'SELECT * FROM sync_outbox WHERE attempted = 1 ORDER BY operation_id',
                  )
                  .get())
              .map((r) => r.data)
              .toList();
      expect(attempted, before);
      expect((await db.select(db.personalRecords).get()).map((r) => r.side), [
        null,
        'both',
      ]);
    },
  );
}
