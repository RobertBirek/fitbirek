import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import '../planner/structured_plan_persistence_test.dart' show structure;
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'dart:typed_data';

void main() {
  test(
    'session DELETE keeps four-field legacy shape without decoding invalid guidance',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await WorkoutRepository(db).startSession();
      await db.customStatement(
        'UPDATE workout_sessions SET guidance_json = ?',
        ['{bad'],
      );
      await SyncStore(db).enqueueAll(deleted: true);
      final operation = (await db.syncDao.pendingOperations()).last;
      expect(operation.payload.keys.toSet(), {
        'dataStart',
        'dataKoniec',
        'czasTrwaniaSekund',
        'notatka',
      });
      expect(
        DateTime.parse(operation.payload['dataStart'] as String).isUtc,
        isTrue,
      );
      expect(operation.payload['czasTrwaniaSekund'], 0);
    },
  );
  test(
    'valid wire round trips; invalid restore rolls back rows and attempted bytes',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = WorkoutRepository(db);
      final id = await repo.startSession(
        guidance: WorkoutGuidance.start(structure).skip(0),
      );
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final before =
          (await db.customSelect('SELECT * FROM sync_outbox').getSingle()).data;
      final operation = (await db.syncDao.pendingOperations()).single;
      await SyncStore(db).apply({
        'entityType': 'workoutSession',
        'entityId': 'remote',
        'version': 1,
        'updatedAt': '2026-10-16T00:00:00Z',
        'deletedAt': null,
        'payload': operation.payload,
      });
      expect(
        WorkoutGuidance.tryRead(
          (await repo.findSessionBySyncId('remote'))!.guidanceJson,
        )!.events.single['type'],
        'skipped',
      );
      final backup = BackupService(db);
      final j =
          jsonDecode(utf8.decode(await backup.exportToBytes()))
              as Map<String, dynamic>;
      (j['data']['workoutSessions'] as List).first['guidanceJson'] = '{}';
      expect(
        (await backup.importFromBytes(
          Uint8List.fromList(utf8.encode(jsonEncode(j))),
        )).success,
        isFalse,
      );
      expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNull);
      expect(
        (await db
                .customSelect('SELECT * FROM sync_outbox WHERE attempted = 1')
                .getSingle())
            .data,
        before,
      );
    },
  );
  test(
    'guidance wire is optional and atomic with set links; invalid pull isolates guidance not history',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = WorkoutRepository(db);
      final id = await repo.startSession(
        guidance: WorkoutGuidance.start(structure),
      );
      await repo.logSet(
        sessionId: id,
        exerciseId: 'yoga',
        exerciseNamePl: 'Yoga',
        setNumber: 1,
        seconds: 20,
        side: 'left',
        guidanceSlot: 0,
      );
      final row = (await db.workoutDao.getSession(id))!;
      final g = WorkoutGuidance.tryRead(row.guidanceJson)!;
      final sets = await repo.getSetsForSession(id);
      expect(g.events.single['setSyncId'], sets.single.syncId);
      expect(
        (await db.syncDao.pendingOperations()).last.payload['guidance'],
        g.toJson(),
      );
      expect(sets.single.side, 'left');
      final store = SyncStore(db);
      await store.apply({
        'entityType': 'workoutSession',
        'entityId': 'bad',
        'version': 1,
        'updatedAt': '2026-10-16T00:00:00Z',
        'deletedAt': null,
        'payload': {
          'dataStart': '2026-10-16T00:00:00Z',
          'dataKoniec': null,
          'czasTrwaniaSekund': 0,
          'notatka': null,
          'guidance': {},
        },
      });
      expect(await repo.getAllSessionsSorted(), hasLength(2));
      final bad = (await repo.findSessionBySyncId('bad'))!;
      expect(bad.guidanceJson, '{}');
      expect(WorkoutGuidance.tryRead(bad.guidanceJson), isNull);
      final legacy = await repo.startSession();
      expect((await db.workoutDao.getSession(legacy))!.guidanceJson, isNull);
      expect(
        (await db.syncDao.pendingOperations()).last.payload.containsKey(
          'guidance',
        ),
        isFalse,
      );
      await db.customStatement(
        'UPDATE workout_sessions SET guidance_json = ? WHERE id = ?',
        ['{bad', id],
      );
      await repo.finishSession(id, row.dataStart);
      expect((await db.workoutDao.getSession(id))!.dataKoniec, isNotNull);
      expect(
        (await db.syncDao.pendingOperations()).last.payload.containsKey(
          'guidance',
        ),
        isFalse,
      );
      expect(jsonDecode(jsonEncode(g.toJson())), isA<Map>());
    },
  );
}
