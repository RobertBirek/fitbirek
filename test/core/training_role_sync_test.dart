import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/models/workout_session.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_repeat.dart';
import 'package:fitbirek_training/features/progress/trends/data/training_trend_repository.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'profile_collections_sync_test.dart' show saveProfile;
import 'training_sets_programs_domain_test.dart' show collection, programEntry;
import 'training_sets_programs_domain_test.dart' show planJson;
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
  });
  tearDown(() => db.close());
  test(
    'domain DTO rejects invalid role rather than treating it as working evidence',
    () {
      final dto = SetLog(
        id: 1,
        sesjaId: 1,
        cwiczenieId: 'cw001',
        nazwaCwiczeniaPl: 'X',
        numerSerii: 1,
        timestamp: DateTime.utc(2026),
      ).toJson();
      expect(dto.containsKey('setRole'), isFalse);
      expect(
        () => SetLog.fromJson({...dto, 'setRole': 'other'}),
        throwsFormatException,
      );
    },
  );
  test(
    'v2 target log is atomic, side/role exact and double consumption refuses all rows',
    () async {
      final g = WorkoutGuidance.start(StructuredPlan.fromJson(planJson()));
      final session = await repo.startSession(guidance: g);
      Future<dynamic> log({
        String role = 'warmup',
        String? side,
        int? seconds,
      }) =>
          Function.apply(repo.logSet, [], {
                #sessionId: session,
                #exerciseId: 'cw001',
                #exerciseNamePl: 'X',
                #setNumber: 1,
                #reps: 8,
                #seconds: seconds,
                #setRole: role,
                #side: side,
                #guidanceSlot: 0,
                #guidanceTargetId: 'a',
              })
              as Future<dynamic>;
      await expectLater(log(role: 'working'), throwsStateError);
      await expectLater(log(side: 'left'), throwsStateError);
      await expectLater(log(seconds: 10), throwsStateError);
      expect(await repo.getSetsForSession(session), isEmpty);
      await log();
      final before = (await db.select(db.syncOutbox).get())
          .map((o) => o.toJson())
          .toList();
      await expectLater(log(), throwsFormatException);
      expect(await repo.getSetsForSession(session), hasLength(1));
      expect(
        (await db.select(db.syncOutbox).get()).map((o) => o.toJson()).toList(),
        before,
      );
    },
  );
  test(
    'explicit log role survives row/model/repeat/outbox while legacy omits wire key',
    () async {
      final session = await repo.startSession();
      for (final role in [null, 'working', 'warmup']) {
        await Function.apply(repo.logSet, [], {
          #sessionId: session,
          #exerciseId: 'cw001',
          #exerciseNamePl: 'X',
          #setNumber: 1,
          #reps: 8,
          #setRole: role,
        });
      }
      final rows = await repo.getSetsForSession(session);
      expect(rows.map((s) => s.setRole), [null, 'working', 'warmup']);
      expect(
        (await repo.buildSessionModel(
          (await db.workoutDao.getSession(session))!,
        )).serie.map((s) => s.setRole),
        [null, 'working', 'warmup'],
      );
      expect(
        WorkoutRepeat.execution(rows).toJson()['targets'],
        unorderedMatches([
          for (final role in [null, 'working', 'warmup'])
            role == null
                ? isNot(contains('setRole'))
                : containsPair('setRole', role),
        ]),
      );
      final ops = (await db.syncDao.pendingOperations())
          .where((o) => o.entityType == SyncEntityType.workoutSet)
          .toList();
      expect(ops.first.payload.containsKey('setRole'), isFalse);
      expect(ops.last.payload['setRole'], 'warmup');
      await db.customStatement('UPDATE sync_outbox SET attempted = 1');
      final bytes = (await db.select(db.syncOutbox).get())
          .map((o) => o.toJson())
          .toList();
      await SyncStore(db).enqueueAll();
      final after = (await db.select(db.syncOutbox).get())
          .where((o) => o.attempted)
          .map((o) => o.toJson())
          .toList();
      expect(after, bytes);
      final fresh = (await db.select(db.syncOutbox).get())
          .where((o) => !o.attempted && o.entityType == 'workoutSet')
          .map((o) => jsonDecode(o.payloadJson) as Map)
          .toList();
      expect(fresh.first.containsKey('setRole'), isFalse);
      expect(fresh.last['setRole'], 'warmup');
    },
  );
  test(
    'pull omission preserves live role, explicitNULL resets, revival does not inherit',
    () async {
      final session = await repo.startSession();
      await repo.logSet(
        sessionId: session,
        exerciseId: 'cw001',
        exerciseNamePl: 'X',
        setNumber: 1,
        reps: 8,
      );
      await db.customStatement("UPDATE sets_log SET set_role = 'warmup'");
      final set = (await db.select(db.setsLog).get()).single;
      final op = (await db.syncDao.pendingOperations()).last;
      await db.delete(db.syncOutbox).go();
      var version = 0;
      Future<void> apply(
        Map<String, Object?> changes, {
        bool deleted = false,
      }) => SyncStore(db).apply({
        'entityType': 'workoutSet',
        'entityId': set.syncId,
        'version': ++version,
        'updatedAt': '2026-10-28T00:00:00Z',
        'deletedAt': deleted ? '2026-10-28T00:00:00Z' : null,
        'payload': {...op.payload, ...changes},
      });
      await apply({});
      expect((await db.select(db.setsLog).getSingle()).setRole, 'warmup');
      await apply({'setRole': null});
      expect((await db.select(db.setsLog).getSingle()).setRole, isNull);
      await apply({'setRole': 'warmup'}, deleted: true);
      await apply({});
      expect((await db.select(db.setsLog).getSingle()).setRole, isNull);
      await expectLater(
        apply({'setRole': 'WARMUP'}),
        throwsA(isA<InvalidSyncRecord>()),
      );
    },
  );
  test(
    'warmup is visible in history but absent from last/progression/preparation/trends evidence',
    () async {
      final session = await repo.startSession();
      await repo.logSet(
        sessionId: session,
        exerciseId: 'cw001',
        exerciseNamePl: 'X',
        setNumber: 1,
        reps: 8,
        weightKg: 12,
      );
      await repo.logSet(
        sessionId: session,
        exerciseId: 'cw001',
        exerciseNamePl: 'X',
        setNumber: 2,
        reps: 20,
        weightKg: 30,
      );
      await db.customStatement(
        "UPDATE sets_log SET set_role = 'warmup' WHERE numer_serii = 2",
      );
      await db.workoutDao.updateSession(
        session,
        WorkoutSessionsCompanion(dataKoniec: Value(DateTime.now())),
      );
      expect(await repo.getSetsForSession(session), hasLength(2));
      expect(await repo.getAllSetsForExercise('cw001'), hasLength(2));
      expect((await repo.getLastSet('cw001'))!.powtorzenia, 8);
      expect(
        await repo.getPreparationHistory('cw001', side: null),
        hasLength(1),
      );
      expect(
        await repo.getProgressionHistory(
          'cw001',
          side: null,
          excludingSessionId: -1,
        ),
        hasLength(1),
      );
      expect(await TrainingTrendRepository(db).readHistory(), hasLength(1));
    },
  );
  test(
    'generic collection write persists programs and refuses immutable edit/prune',
    () async {
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(accountId: 'a', deviceId: 'device'),
          );
      await saveProfile(db);
      final cloud = UserCollectionsRepository(db);
      await cloud.update(
        'a',
        'trainingPrograms',
        (entries) => entries.add(programEntry()),
      );
      expect(
        jsonDecode(
          (await db.userProfileDao.watchProfileOnce())!.trainingProgramsJson!,
        ),
        collection([programEntry()]),
      );
      final before = (await db.select(db.syncOutbox).get())
          .map((o) => o.toJson())
          .toList();
      await expectLater(
        cloud.update('a', 'trainingPrograms', (entries) => entries.clear()),
        throwsFormatException,
      );
      await expectLater(
        cloud.update(
          'a',
          'trainingPrograms',
          (entries) => entries.single['weekdays'] = [2],
        ),
        throwsFormatException,
      );
      expect(
        (await db.select(db.syncOutbox).get()).map((o) => o.toJson()).toList(),
        before,
      );
    },
  );
}
