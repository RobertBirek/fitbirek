import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/mood/data/mood_repository.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/progress/measurements/data/measurements_repository.dart';
import 'package:fitbirek_training/features/progress/prs/data/prs_repository.dart';
import 'package:fitbirek_training/features/progress/tests/data/tests_repository.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/core/models/fitness_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test(
    'a local mood entry has sync metadata and one outbox operation',
    () async {
      final repository = MoodRepository(db);

      await repository.addEntry(
        snGodziny: 7.5,
        energia: 8,
        nastroj: 7,
        apetyt: 6,
        alkohol: false,
        alkoholJednostki: 0,
      );

      final entry = (await db.select(db.moodEntries).get()).single;
      final pending = await db.syncDao.pendingOperations();

      expect(entry.syncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(entry.syncVersion, 0);
      expect(entry.updatedAtUtc.toUtc(), isA<DateTime>());
      expect(entry.deletedAtUtc, isNull);
      expect(pending, hasLength(1));
      expect(pending.single, isA<SyncOperation>());
      expect(pending.single.entityType, SyncEntityType.mood);
      expect(pending.single.entityId, entry.syncId);
      expect(pending.single.payload, containsPair('energia', 8));
    },
  );

  test('workout session and set writes each queue stable metadata', () async {
    final repository = WorkoutRepository(db);

    final sessionId = await repository.startSession();
    await repository.logSet(
      sessionId: sessionId,
      exerciseId: 'cw001',
      exerciseNamePl: 'Pompki',
      setNumber: 1,
      reps: 12,
    );

    final session = (await db.select(db.workoutSessions).get()).single;
    final set = (await db.select(db.setsLog).get()).single;
    final pending = await db.syncDao.pendingOperations();

    expect(session.syncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(set.syncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(session.updatedAtUtc.toUtc(), isA<DateTime>());
    expect(set.updatedAtUtc.toUtc(), isA<DateTime>());
    expect(
      pending.map((operation) => operation.entityType),
      containsAll([SyncEntityType.workoutSession, SyncEntityType.workoutSet]),
    );
    final setOperation = pending.singleWhere(
      (operation) => operation.entityType == SyncEntityType.workoutSet,
    );
    expect(setOperation.payload['sessionSyncId'], session.syncId);
    expect(setOperation.payload, isNot(contains('sesjaId')));
  });

  test(
    'profile and plan writes preserve sync metadata and plan deletion tombstones',
    () async {
      final profileRepository = UserProfileRepository(db);
      final plannerRepository = PlannerRepository(db);

      await profileRepository.saveProfile(
        imie: 'Robert',
        wiek: 35,
        wzrostCm: 180,
        wagaKg: 90,
        cel: CelTreningowy.sila,
        dostepnySprzet: const ['Hantle'],
      );
      final planId = await plannerRepository.savePlan(
        nazwa: 'Siła',
        cwiczeniaIds: const ['cw001'],
        cel: 'sila',
      );
      await plannerRepository.deletePlan(planId);

      final profile = (await db.select(db.userProfiles).get()).single;
      final plan = (await db.select(db.workoutPlans).get()).single;
      final pending = await db.syncDao.pendingOperations();

      expect(profile.syncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(profile.updatedAtUtc.toUtc(), isA<DateTime>());
      expect(plan.syncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(plan.deletedAtUtc, isNotNull);
      expect(plan.updatedAtUtc.toUtc(), isA<DateTime>());
      expect(
        pending
            .where((operation) => operation.entityId == plan.syncId)
            .single
            .deleted,
        isTrue,
      );
    },
  );

  test('sync operation serializes the API mutation envelope', () {
    const operation = SyncOperation(
      operationId: 'c11da0c2-e308-4d9b-a63c-e790ec4d1e49',
      entityType: SyncEntityType.mood,
      entityId: 'db647f4e-0ce8-4112-a2eb-82cf37519eb7',
      baseVersion: 0,
      payload: {'energia': 8},
      deleted: false,
    );

    expect(operation.toJson(), {
      'operationId': 'c11da0c2-e308-4d9b-a63c-e790ec4d1e49',
      'entityType': 'mood',
      'entityId': 'db647f4e-0ce8-4112-a2eb-82cf37519eb7',
      'baseVersion': 0,
      'payload': {'energia': 8},
      'deleted': false,
    });
  });

  test('pending operations deserialize persisted outbox rows', () async {
    await db.syncDao.enqueueDelete(
      entityType: SyncEntityType.workoutPlan,
      entityId: 'f32d8724-247c-4489-8557-aa49c6aa2834',
      baseVersion: 3,
      payload: {'nazwa': 'Plan'},
    );

    final operation = (await db.syncDao.pendingOperations()).single;

    expect(operation, isA<SyncOperation>());
    expect(operation.entityType, SyncEntityType.workoutPlan);
    expect(operation.entityId, 'f32d8724-247c-4489-8557-aa49c6aa2834');
    expect(operation.baseVersion, 3);
    expect(operation.payload, {'nazwa': 'Plan'});
    expect(operation.deleted, isTrue);
  });

  test(
    'measurement, PR, and fitness-test writes queue typed payloads',
    () async {
      await MeasurementsRepository(db).addMeasurement(wagaKg: 90);
      await PrsRepository(db).savePr(
        exerciseId: 'cw001',
        exerciseNamePl: 'Pompki',
        weightKg: 20,
        reps: 10,
      );
      await TestsRepository(db).addResult(typ: TypTestu.maxPompki, wynik: 30);

      final pending = await db.syncDao.pendingOperations();
      final measurement = pending.singleWhere(
        (operation) => operation.entityType == SyncEntityType.measurement,
      );
      final record = pending.singleWhere(
        (operation) => operation.entityType == SyncEntityType.personalRecord,
      );
      final fitnessTest = pending.singleWhere(
        (operation) => operation.entityType == SyncEntityType.fitnessTest,
      );

      expect(measurement.payload['wagaKg'], 90.0);
      expect(
        record.payload['szacowane1Rm'],
        closeTo(26.666666666666668, 0.0001),
      );
      expect(fitnessTest.payload, containsPair('typ', 'maxPompki'));
      expect(fitnessTest.toJson()['entityType'], 'fitnessTest');
    },
  );
}
