import 'package:drift/native.dart';
import '../../core/database/legacy_schema.dart';
// Uses Drift's lockfile-pinned driver without changing client dependencies.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/workout_session.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';

void main() {
  test(
    'side survives domain JSON, SQLite, backup restore and sync snapshots',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = WorkoutRepository(db);
      final sessionId = await repo.startSession();
      final session = (await db.workoutDao.getSession(sessionId))!;
      final payload = {
        'sessionSyncId': session.syncId,
        'cwiczenieId': 'custom',
        'nazwaCwiczeniaPl': 'Test',
        'numerSerii': 1,
        'czasSekund': 30,
        'side': 'left',
        'timestamp': '2026-10-16T00:00:00Z',
      };
      await SyncStore(db).apply({
        'entityType': 'workoutSet',
        'entityId': 'remote-set',
        'version': 3,
        'updatedAt': '2026-10-16T00:00:00Z',
        'deletedAt': null,
        'payload': payload,
      });
      expect(
        (await db.workoutDao.getAllSets()).single.toJson()['side'],
        'left',
      );
      final model = await repo.buildSessionModel(session);
      expect(model.serie.single.toJson()['side'], 'left');
      expect(
        SetLog.fromJson(model.serie.single.toJson()).toJson()['side'],
        'left',
      );
      final backup = BackupService(db);
      expect(
        (await backup.importFromBytes(await backup.exportToBytes())).success,
        isTrue,
      );
      expect(
        (await db.workoutDao.getAllSets()).single.toJson()['side'],
        'left',
      );
      final pending = await db.syncDao.pendingOperations();
      expect(
        pending
            .where((o) => !o.deleted && o.entityType.wireName == 'workoutSet')
            .single
            .payload['side'],
        'left',
      );
      // Old snapshots have no side and must remain unclassified.
      final old = Map<String, dynamic>.from(payload)..remove('side');
      old['sessionSyncId'] =
          (await db.workoutDao.getAllSessionsSorted()).single.syncId;
      await SyncStore(db).apply({
        'entityType': 'workoutSet',
        'entityId': 'legacy-set',
        'version': 1,
        'updatedAt': '2026-10-16T00:00:00Z',
        'deletedAt': null,
        'payload': old,
      });
      expect((await db.workoutDao.getAllSets()).last.toJson()['side'], isNull);
      await SyncStore(db).enqueueAll();
      expect(
        (await db.syncDao.pendingOperations())
            .singleWhere((o) => o.entityId == 'legacy-set')
            .payload
            .containsKey('side'),
        isFalse,
      );
    },
  );

  test(
    'v7 migration leaves legacy side null and attempted payload unchanged',
    () async {
      final raw = sqlite.sqlite3.openInMemory();
      final old = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      final repo = WorkoutRepository(old);
      final id = await repo.startSession();
      await repo.logSet(
        sessionId: id,
        exerciseId: 'custom',
        exerciseNamePl: 'Test',
        setNumber: 1,
        reps: 5,
      );
      await old.customStatement(
        'UPDATE sync_outbox SET attempted = 1, base_version = 4',
      );
      final before = (await old.syncDao.pendingOperations())
          .map((o) => o.toJson())
          .toList();
      await old.customStatement('ALTER TABLE sets_log DROP COLUMN side');
      await old.customStatement(
        'ALTER TABLE personal_records DROP COLUMN side',
      );
      await removeV12Columns(old);
      await old.customStatement('PRAGMA user_version = 7');
      await old.customStatement(
        'ALTER TABLE workout_sessions DROP COLUMN guidance_json',
      );
      await old.customStatement('DROP TABLE workout_drafts');
      await old.customStatement(
        'ALTER TABLE workout_plans DROP COLUMN structure_json',
      );
      await old.close();
      var db = AppDatabase.forTesting(
        NativeDatabase.opened(raw, closeUnderlyingOnClose: false),
      );
      addTearDown(() => db.close());
      expect((await db.workoutDao.getAllSets()).single.side, isNull);
      expect(
        (await db.syncDao.pendingOperations()).map((o) => o.toJson()).toList(),
        before,
      );
      await WorkoutRepository(db).logSet(
        sessionId: id,
        exerciseId: 'custom',
        exerciseNamePl: 'Test',
        setNumber: 2,
        seconds: 20,
        side: 'right',
      );
      expect((await db.workoutDao.getAllSets()).last.side, 'right');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase.opened(raw));
      expect((await db.workoutDao.getAllSets()).last.side, 'right');
      expect((await db.workoutDao.getAllSets()).first.side, isNull);
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        15,
      );
    },
  );

  test(
    'empty and nonpositive sets never create rows or outbox operations',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = WorkoutRepository(db);
      final id = await repo.startSession();
      for (final values in [
        <String, int>{},
        {'reps': 0},
        {'seconds': -1},
      ]) {
        await expectLater(
          repo.logSet(
            sessionId: id,
            exerciseId: 'custom',
            exerciseNamePl: 'Test',
            setNumber: 1,
            reps: values['reps'],
            seconds: values['seconds'],
          ),
          throwsArgumentError,
        );
      }
      expect(await db.workoutDao.getAllSets(), isEmpty);
      expect(await db.syncDao.pendingOperations(), hasLength(1));
    },
  );
}
