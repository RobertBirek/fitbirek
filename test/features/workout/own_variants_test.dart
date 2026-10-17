import 'dart:convert';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/models/workout_session.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/fixed_load_progression.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/data/exercise_variants_repository.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'package:fitbirek_training/features/progress/prs/data/prs_repository.dart';
import '../../core/profile_collections_sync_test.dart'
    show saveProfile, CollectionServer;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late WorkoutRepository workout;
  late ExerciseVariantsRepository variants;
  late SyncService sync;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sync = SyncService(db, CollectionServer());
    await sync.bindAccount('a');
    await saveProfile(db);
    await ExercisesRepository(db).syncFromAssets();
    variants = ExerciseVariantsRepository(UserCollectionsRepository(db));
    workout = WorkoutRepository(db);
  });
  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  test(
    'owned variant uses new UUID and immutable protocol; foreign/deleted cannot create sets',
    () async {
      final base = (await db.select(db.exercises).get()).firstWhere(
        (e) => (jsonDecode(e.sprzet) as List).contains('Hantle'),
      );
      final id = await variants.create(
        'a',
        base.id,
        'Wolniej',
        tempo: '3-1-1',
        pauseSeconds: 1,
        loadKg: 10,
        rangeOfMotion: 'Własny zakres',
      );
      final fork = await variants.create(
        'a',
        base.id,
        'Wolniej',
        tempo: '4-1-1',
        loadKg: 10,
      );
      expect(fork, isNot(id));
      final session = await workout.startSession();
      await workout.logSet(
        sessionId: session,
        exerciseId: base.id,
        exerciseNamePl: base.nazwaPl,
        setNumber: 1,
        reps: 8,
        weightKg: 10,
        variantId: id,
        accountId: 'a',
      );
      final set = (await workout.getSetsForSession(session)).single;
      expect(set.variantLabel, 'Wolniej');
      expect(set.variantId, id);
      await expectLater(
        workout.logSet(
          sessionId: session,
          exerciseId: 'other',
          exerciseNamePl: 'Other',
          setNumber: 1,
          reps: 8,
          variantId: id,
        ),
        throwsStateError,
      );
      await expectLater(
        workout.logSet(
          sessionId: session,
          exerciseId: base.id,
          exerciseNamePl: base.nazwaPl,
          setNumber: 2,
          reps: 8,
          variantId: id,
          accountId: 'b',
        ),
        throwsStateError,
      );
      final json = (await workout.buildSessionModel(
        (await db.workoutDao.getSession(session))!,
      )).serie.single.toJson();
      expect(SetLog.fromJson(json).variantId, id);
      await variants.rename('a', id, 'Nowa etykieta', cue: 'Ta sama technika');
      expect(
        (await workout.getSetsForSession(session)).single.variantLabel,
        'Wolniej',
      );
      expect(
        (await variants.load(
          'a',
          base.id,
        )).firstWhere((e) => e['id'] == id)['tempo'],
        '3-1-1',
      );
      await variants.delete('a', id);
      await expectLater(
        workout.logSet(
          sessionId: session,
          exerciseId: base.id,
          exerciseNamePl: base.nazwaPl,
          setNumber: 2,
          reps: 8,
          variantId: id,
        ),
        throwsStateError,
      );
      expect(
        (await workout.getSetsForSession(session)).single.variantLabel,
        'Wolniej',
      );
      expect(await workout.getLastSet(base.id), isNull);
      expect((await workout.getLastSet(base.id, variantId: id))!.id, set.id);
      final bytes = await BackupService(db).exportToBytes();
      expect((await BackupService(db).importFromBytes(bytes)).success, isTrue);
      expect((await db.select(db.setsLog).get()).single.variantId, id);
      expect(
        (await db.select(db.setsLog).get()).single.variantLabel,
        'Wolniej',
      );
    },
  );

  test(
    'PR, last-set and progression partition exercise + exact side + UUID',
    () async {
      final base = (await db.select(db.exercises).get()).firstWhere(
        (e) => (jsonDecode(e.sprzet) as List).contains('Hantle'),
      );
      final id = await variants.create('a', base.id, 'Pauza', pauseSeconds: 2);
      final prs = PrsRepository(db);
      await prs.savePr(
        exerciseId: base.id,
        exerciseNamePl: base.nazwaPl,
        weightKg: 30,
        reps: 10,
        side: 'left',
      );
      await prs.savePr(
        exerciseId: base.id,
        exerciseNamePl: base.nazwaPl,
        weightKg: 10,
        reps: 8,
        side: 'left',
        variantId: id,
      );
      expect(
        (await prs.getBestForExercise(base.id, side: 'left'))!.ciezarKg,
        30,
      );
      expect(
        (await prs.getBestForExercise(
          base.id,
          side: 'left',
          variantId: id,
        ))!.ciezarKg,
        10,
      );
      expect(
        await prs.getBestForExercise(base.id, side: 'both', variantId: id),
        isNull,
      );
      for (var i = 0; i < 2; i++) {
        final session = await workout.startSession();
        await workout.logSet(
          sessionId: session,
          exerciseId: base.id,
          exerciseNamePl: base.nazwaPl,
          setNumber: 1,
          weightKg: 10,
          reps: 8,
          rpe: 7,
          side: 'left',
          variantId: id,
        );
        await workout.logSet(
          sessionId: session,
          exerciseId: base.id,
          exerciseNamePl: base.nazwaPl,
          setNumber: 2,
          weightKg: 100,
          reps: 12,
          rpe: 7,
          side: 'left',
        );
        await workout.finishSession(session, DateTime.now());
      }
      final history = await workout.getProgressionHistory(
        base.id,
        side: 'left',
        variantId: id,
        excludingSessionId: 999,
      );
      expect(history, hasLength(2));
      expect(
        history.every((r) => r.variantId == id && r.weightKg == 10),
        isTrue,
      );
      expect(
        proposeFixedLoad(
          exerciseId: base.id,
          side: 'left',
          variantId: id,
          prescription: '3x8-12',
          tracking: 'reps',
          usesWeight: true,
          currentWeightKg: 10,
          history: history,
        ).target,
        9,
      );
      expect(
        proposeFixedLoad(
          exerciseId: base.id,
          side: 'left',
          prescription: '3x8-12',
          tracking: 'reps',
          usesWeight: true,
          currentWeightKg: 10,
          history: history,
        ).target,
        isNull,
      );
      expect(
        proposeFixedLoad(
          exerciseId: base.id,
          side: 'left',
          variantId: id,
          prescription: '3x8-12',
          tracking: 'reps',
          usesWeight: true,
          currentWeightKg: 11,
          history: history,
        ).target,
        isNull,
      );
      expect((await workout.getLastSet(base.id, side: 'left'))!.ciezarKg, 100);
      expect(
        (await workout.getLastSet(
          base.id,
          side: 'left',
          variantId: id,
        ))!.ciezarKg,
        10,
      );
    },
  );

  test(
    'unknown historical variant survives pull; malformed pair rolls back',
    () async {
      final session = await workout.startSession();
      final parent = (await db.workoutDao.getSession(session))!;
      final record = <String, dynamic>{
        'entityType': 'workoutSet',
        'entityId': 'remote-set',
        'version': 1,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'deletedAt': null,
        'payload': <String, dynamic>{
          'sessionSyncId': parent.syncId,
          'cwiczenieId': 'cw001',
          'nazwaCwiczeniaPl': 'Historyczne',
          'numerSerii': 1,
          'powtorzenia': 8,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'variantId': '11111111-1111-4111-8111-111111111111',
          'variantLabel': 'Usunięty protokół',
        },
      };
      await db.transaction(() => SyncStore(db).apply(record));
      expect(
        (await workout.getSetsForSession(session)).single.variantLabel,
        'Usunięty protokół',
      );
      (record['payload'] as Map).remove('variantLabel');
      await expectLater(
        db.transaction(() => SyncStore(db).apply({...record, 'version': 2})),
        throwsFormatException,
      );
      expect(
        (await workout.getSetsForSession(session)).single.variantLabel,
        'Usunięty protokół',
      );
    },
  );
}
