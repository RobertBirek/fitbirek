import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'sync_service_test.dart' show FakeSyncApi;

void main() {
  test(
    'restore retains deleted parent mapping for unpulled remote child and delete',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      addTearDown(() async {
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      final id = await WorkoutRepository(db).startSession();
      await sync.synchronize();
      final parent = (await db.workoutDao.getSession(id))!;
      // The parent was pulled earlier; another device added a set we have not
      // pulled yet. Restore deletes the parent, but the backend has no cascade.
      await db.customStatement('UPDATE sync_state SET cursor = 1');
      final empty = Uint8List.fromList(
        utf8.encode(jsonEncode({'schemaVersion': 2, 'data': {}})),
      );
      expect((await BackupService(db).importFromBytes(empty)).success, isTrue);
      final child = {
        'entityType': 'workoutSet',
        'entityId': 'remote-child',
        'version': 1,
        'updatedAt': '2026-09-10T00:00:00Z',
        'deletedAt': null,
        'payload': {
          'sessionSyncId': parent.syncId,
          'cwiczenieId': 'cw001',
          'nazwaCwiczeniaPl': 'Test',
          'numerSerii': 1,
          'timestamp': '2026-09-10T00:00:00Z',
        },
      };
      final deletion = {
        'entityType': 'workoutSession',
        'entityId': parent.syncId,
        'version': 2,
        'updatedAt': '2026-09-10T01:00:00Z',
        'deletedAt': '2026-09-10T01:00:00Z',
        'payload': {
          'dataStart': parent.dataStart.toUtc().toIso8601String(),
          'dataKoniec': null,
          'czasTrwaniaSekund': 0,
          'notatka': null,
        },
      };
      api.page = {
        'cursor': 3,
        'changes': [child, deletion],
      };
      await sync.synchronize();
      expect(sync.status, SyncStatus.idle);
      expect((await db.syncDao.readState())!.cursor, 3);
      expect((await db.workoutDao.getSession(id))!.syncId, parent.syncId);
      expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNotNull);
      expect(await db.workoutDao.getAllSessionsSorted(), isEmpty);
      expect(await db.workoutDao.getAllSets(), isEmpty);
      final deletes = await db.syncDao.pendingOperations();
      expect(
        deletes.any((o) => o.entityId == 'remote-child' && o.deleted),
        isTrue,
      );
      // Invalid siblings still roll back both the cursor and all entity writes.
      api.page = {
        'cursor': 5,
        'changes': [
          {...child, 'entityId': 'another-child'},
          {
            'entityType': 'measurement',
            'entityId': 'bad',
            'version': 1,
            'updatedAt': '2026-09-10T00:00:00Z',
            'deletedAt': null,
            'payload': {},
          },
        ],
      };
      await sync.synchronize();
      expect(sync.status, SyncStatus.error);
      expect((await db.syncDao.readState())!.cursor, 3);
      expect(
        (await db.select(db.setsLog).get()).any(
          (s) => s.syncId == 'another-child',
        ),
        isFalse,
      );
      // A later valid child delete page advances normally, even on a retry.
      api.page = {
        'cursor': 4,
        'changes': [
          {...child, 'version': 2, 'deletedAt': '2026-09-10T02:00:00Z'},
        ],
      };
      await sync.synchronize();
      expect(sync.status, SyncStatus.idle);
      expect((await db.syncDao.readState())!.cursor, 4);
    },
  );

  test(
    'restore remaps imported session IDs without overwriting old UUIDs',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = WorkoutRepository(db);
      final id = await repo.startSession();
      await repo.logSet(
        sessionId: id,
        exerciseId: 'cw001',
        exerciseNamePl: 'Test',
        setNumber: 1,
      );
      final old = (await db.workoutDao.getSession(id))!;
      final backup = BackupService(db);
      final bytes = await backup.exportToBytes();
      expect((await backup.importFromBytes(bytes)).success, isTrue);
      expect((await db.workoutDao.getSession(id))!.syncId, old.syncId);
      expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNotNull);
      final restored = (await db.workoutDao.getAllSessionsSorted()).single;
      expect(restored.id, isNot(id));
      expect(restored.syncId, isNot(old.syncId));
      expect((await db.workoutDao.getAllSets()).single.sesjaId, restored.id);
      final exported =
          jsonDecode(utf8.decode(await backup.exportToBytes())) as Map;
      expect((exported['data'] as Map)['workoutSessions'], hasLength(1));
      // Repeated restores retain all earlier parent identities, hidden from UI.
      expect((await backup.importFromBytes(bytes)).success, isTrue);
      expect(
        (await db.workoutDao.getSession(restored.id))!.syncId,
        restored.syncId,
      );
      expect(await db.workoutDao.getAllSessionsSorted(), hasLength(1));
    },
  );
}
