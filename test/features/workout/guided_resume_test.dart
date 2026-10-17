import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import '../planner/structured_plan_persistence_test.dart' show structure;
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'session_tracking_test.dart' show exercise;
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'dart:convert';

void main() {
  test(
    'saving guided rounds consumes durable checkpoint in the set transaction',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      final timer = IntervalTimer(
        IntervalConfig(preparation: 0, work: 10, rest: 0, rounds: 1),
      )..start();
      n.updateDraft({'timer': timer.checkpoint(), 'side': 'left'});
      await n.flushDraft();
      final origin = n.captureInterval(
        exercise: exercise.copyWith(id: 'yoga'),
        side: 'left',
      )!;
      expect(
        await n.saveIntervalRounds(origin, [
          const IntervalRound(round: 1, seconds: 10, shortened: false),
        ]),
        isTrue,
      );
      final draft =
          jsonDecode(
                (await db.select(db.workoutDrafts).getSingle()).payloadJson,
              )
              as Map;
      expect(draft['fields']['timer'], isNull);
      expect(draft['fields']['side'], 'left');
      expect(
        draft['guidanceSignature'],
        jsonEncode(
          WorkoutGuidance.tryRead(
            (await db.workoutDao.getSession(origin.sessionId))!.guidanceJson,
          )!.toJson(),
        ),
      );
    },
  );
  test(
    'pulled or external sets remain additional and numbering reads transaction rows',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      final id = c.read(activeWorkoutProvider).sessionId!;
      await WorkoutRepository(db).logSet(
        sessionId: id,
        exerciseId: 'yoga',
        exerciseNamePl: 'Extra',
        setNumber: 4,
        seconds: 10,
      );
      await n.logSet(exercise: exercise.copyWith(id: 'yoga'), seconds: 20);
      final sets = await db.workoutDao.getSetsForSession(id);
      expect(sets.last.numerSerii, 5);
      final g = WorkoutGuidance.tryRead(
        (await db.workoutDao.getSession(id))!.guidanceJson,
      )!;
      expect(g.additionalSetIds(sets.map((s) => s.syncId)), [
        sets.first.syncId,
      ]);
    },
  );
  test(
    'guided start only drafts targets; navigation bounds and clear state',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      expect(c.read(activeWorkoutProvider).guidance!.plan.exerciseIds, [
        'yoga',
      ]);
      expect(await db.select(db.setsLog).get(), isEmpty);
      n.updateDraft({'reps': '12', 'side': 'left', 'rpe': 9});
      expect(c.read(activeWorkoutProvider).draft['side'], 'left');
      expect(n.moveGuided(1), isFalse);
      expect(c.read(activeWorkoutProvider).currentSlot, 0);
    },
  );
  test(
    'reload reattaches same UUID without insert or automatic log; account lock blocks it',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(
              accountId: 'a',
              deviceId: 'device',
              offlineAccess: const Value(true),
            ),
          );
      var c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      var n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      final id = c.read(activeWorkoutProvider).sessionId!,
          uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      n.updateDraft({'reps': '8', 'side': 'right', 'rpe': 8});
      await n.flushDraft();
      final operations = (await db.syncDao.pendingOperations()).length;
      c.dispose();
      c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      n = c.read(activeWorkoutProvider.notifier);
      expect(await n.resumeSession(uuid), isTrue);
      expect(c.read(activeWorkoutProvider).sessionId, id);
      expect(c.read(activeWorkoutProvider).draft['side'], 'right');
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect((await db.syncDao.pendingOperations()).length, operations);
      n.discardSession();
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(accountId: Value('b')));
      expect(await n.resumeSession(uuid), isFalse);
      expect(await WorkoutRepository(db).pendingDrafts('a'), isEmpty);
      await db
          .update(db.syncState)
          .write(
            const SyncStateCompanion(
              accountId: Value('a'),
              offlineAccess: Value(false),
            ),
          );
      expect(await n.resumeSession(uuid), isFalse);
      c.dispose();
    },
  );
  test(
    'backup restoration clears local checkpoints and remaps linked performed sets',
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
        seconds: 15,
        guidanceSlot: 0,
      );
      final backup = BackupService(db);
      expect(
        (await backup.importFromBytes(await backup.exportToBytes())).success,
        isTrue,
      );
      final row = (await repo.getAllSessionsSorted()).single;
      final sets = await repo.getSetsForSession(row.id);
      expect(
        WorkoutGuidance.tryRead(row.guidanceJson)!.events.single['setSyncId'],
        sets.single.syncId,
      );
      expect(await db.select(db.workoutDrafts).get(), isEmpty);
    },
  );
  test(
    'guided double tap writes once; account switch rejects event, checkpoint and finish',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      final id = c.read(activeWorkoutProvider).sessionId!;
      final first = n.logSet(
        exercise: exercise.copyWith(id: 'yoga'),
        seconds: 12,
        side: 'right',
      );
      await n.logSet(
        exercise: exercise.copyWith(id: 'yoga'),
        seconds: 12,
        side: 'right',
      );
      await first;
      final sets = await db.workoutDao.getSetsForSession(id);
      expect(sets, hasLength(1));
      expect(sets.single.side, 'right');
      expect(
        WorkoutGuidance.tryRead(
          (await db.workoutDao.getSession(id))!.guidanceJson,
        )!.events.single['setSyncId'],
        sets.single.syncId,
      );
      await n.flushDraft();
      final count = (await db.syncDao.pendingOperations()).length;
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(accountId: Value('b')));
      expect(await n.guidedEvent(), isFalse);
      await n.finishSession();
      expect((await db.workoutDao.getSession(id))!.dataKoniec, isNull);
      expect((await db.syncDao.pendingOperations()).length, count);
    },
  );
  test(
    'invalid local guidance cannot resume but can finish with legacy payload',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      await n.flushDraft();
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!,
          id = c.read(activeWorkoutProvider).sessionId!;
      n.discardSession();
      await db.customStatement(
        'UPDATE workout_sessions SET guidance_json = ?',
        ['{broken'],
      );
      expect(await n.resumeSession(uuid), isFalse);
      expect(await n.finishPendingSession(uuid), id);
      expect((await db.workoutDao.getSession(id))!.dataKoniec, isNotNull);
      expect(
        (await db.syncDao.pendingOperations()).last.payload.containsKey(
          'guidance',
        ),
        isFalse,
      );
    },
  );
}
