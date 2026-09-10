import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions, Value;
import 'package:dio/dio.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'dart:async';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/progress/measurements/data/measurements_repository.dart';
import 'package:fitbirek_training/features/progress/prs/data/prs_repository.dart';
import 'package:fitbirek_training/features/progress/tests/data/tests_repository.dart';
import 'package:fitbirek_training/core/models/fitness_test.dart';
import 'package:fitbirek_training/features/mood/data/mood_repository.dart';

class FakeSyncApi implements SyncApi {
  final requests = <List<SyncOperation>>[];
  Future<Map<String, dynamic>> Function(List<SyncOperation>)? onPush;
  Map<String, dynamic> page = {'cursor': 0, 'changes': <dynamic>[]};
  @override
  Future<Map<String, dynamic>> push(List<SyncOperation> ops) async {
    requests.add(ops);
    if (onPush != null) return onPush!(ops);
    return {
      'accepted': [
        for (final op in ops)
          {
            'operationId': op.operationId,
            'version': op.baseVersion + 1,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
            'duplicate': false,
          },
      ],
      'conflicts': [],
    };
  }

  @override
  Future<Map<String, dynamic>> pull(int cursor) async => page;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late FakeSyncApi api;
  late SyncService sync;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    api = FakeSyncApi();
    sync = SyncService(db, api);
    await sync.bindAccount('account');
  });
  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  test(
    'push acknowledges persisted operations and binds the account',
    () async {
      await WorkoutRepository(db).startSession();
      await sync.synchronize();
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect((await db.select(db.workoutSessions).getSingle()).syncVersion, 1);
      await expectLater(sync.bindAccount('other'), throwsStateError);
    },
  );

  test('uncertain request survives retry and a later edit', () async {
    final repo = WorkoutRepository(db);
    final id = await repo.startSession();
    api.onPush = (_) async {
      throw Exception('offline');
    };
    await sync.synchronize();
    final first = api.requests.single.single;
    await repo.finishSession(id, DateTime.now());
    expect(await db.syncDao.pendingOperations(), hasLength(2));
    api.onPush = null;
    await sync.synchronize();
    expect(api.requests[1].single.toJson(), first.toJson());
    expect(api.requests.last.single.baseVersion, 1);
    expect(await db.syncDao.pendingOperations(), isEmpty);
    expect((await db.workoutDao.getSession(id))!.dataKoniec, isNotNull);
  });

  test('bad pull rolls back all rows and cursor', () async {
    api.page = {
      'cursor': 2,
      'changes': [
        {
          'entityType': 'workoutSession',
          'entityId': 'remote',
          'version': 1,
          'updatedAt': '2026-09-10T00:00:00Z',
          'deletedAt': null,
          'payload': {
            'dataStart': '2026-09-10T00:00:00Z',
            'dataKoniec': null,
            'czasTrwaniaSekund': 0,
            'notatka': null,
          },
        },
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
    expect(await db.select(db.workoutSessions).get(), isEmpty);
    expect((await db.syncDao.readState())!.cursor, 0);
    expect(sync.status, SyncStatus.error);
  });

  test(
    'all entity payloads round trip, mapping session UUID to local FK',
    () async {
      await ExercisesRepository(db).syncFromAssets();
      await ExercisesRepository(db).toggleFavorite('cw001', true);
      await UserProfileRepository(db).saveProfile(
        imie: 'Test',
        wiek: 40,
        wzrostCm: 180,
        wagaKg: 80,
        cel: CelTreningowy.mix,
        dostepnySprzet: ['Hantle'],
      );
      final repo = WorkoutRepository(db);
      final id = await repo.startSession();
      await repo.logSet(
        sessionId: id,
        exerciseId: 'cw001',
        exerciseNamePl: 'Test',
        setNumber: 1,
        weightKg: 10,
        reps: 12,
        rpe: 7,
      );
      await MoodRepository(db).addEntry(
        snGodziny: 8,
        energia: 4,
        nastroj: 3,
        apetyt: 2,
        alkohol: false,
        alkoholJednostki: 0,
      );
      await MeasurementsRepository(db).addMeasurement(
        wagaKg: 80,
        obwodTalii: 90,
        cisnienie: '120/80',
        notatka: 'test',
      );
      await TestsRepository(
        db,
      ).addResult(typ: TypTestu.values.first, wynik: 10);
      await PrsRepository(db).savePr(
        exerciseId: 'cw001',
        exerciseNamePl: 'Test',
        weightKg: 10,
        reps: 12,
      );
      await PlannerRepository(
        db,
      ).savePlan(nazwa: 'Plan', cwiczeniaIds: ['cw001'], cel: 'mix');
      final operations = await db.syncDao.pendingOperations();
      expect(
        operations.map((o) => o.entityType).toSet(),
        SyncEntityType.values.toSet(),
      );
      final other = AppDatabase.forTesting(NativeDatabase.memory());
      final remoteApi = FakeSyncApi();
      final remote = SyncService(other, remoteApi);
      await remote.bindAccount('account');
      await ExercisesRepository(other).syncFromAssets();
      await other
          .into(other.workoutSessions)
          .insert(WorkoutSessionsCompanion.insert(dataStart: DateTime.now()));
      remoteApi.page = {
        'cursor': operations.length,
        'changes': [
          for (final op in operations.reversed)
            {
              'entityType': op.entityType.wireName,
              'entityId': op.entityId,
              'version': 1,
              'payload': op.payload,
              'updatedAt': '2026-09-10T00:00:00Z',
              'deletedAt': null,
            },
        ],
      };
      await remote.synchronize();
      expect(remote.status, SyncStatus.idle);
      final set = await other.select(other.setsLog).getSingle();
      expect(set.sesjaId, isNot(id));
      expect(
        (await other.workoutDao.getSession(set.sesjaId))!.syncId,
        operations
            .singleWhere((o) => o.entityType == SyncEntityType.workoutSession)
            .entityId,
      );
      expect(
        (await other.select(other.measurements).getSingle()).cisnienie,
        '120/80',
      );
      expect(
        (await other.select(other.userProfiles).getSingle()).dostepnySprzet,
        '["Hantle"]',
      );
      expect(
        (await other.select(other.workoutPlans).getSingle()).cwiczeniaIds,
        '["cw001"]',
      );
      expect(await other.syncDao.pendingOperations(), isEmpty);
      remote.dispose();
      await other.close();
    },
  );

  test(
    'atomic rejected batch keeps unreported operations and later edits',
    () async {
      final repo = WorkoutRepository(db);
      final id = await repo.startSession();
      await repo.startSession();
      var calls = 0;
      api.onPush = (ops) async {
        calls++;
        if (calls > 1) {
          return {
            'accepted': [
              for (final o in ops)
                {'operationId': o.operationId, 'version': o.baseVersion + 1},
            ],
            'conflicts': [],
          };
        }
        await repo.finishSession(id, DateTime.now());
        final op = ops.first;
        return {
          'accepted': [],
          'conflicts': [
            {
              'operationId': op.operationId,
              'record': {
                'entityType': op.entityType.wireName,
                'entityId': op.entityId,
                'version': 4,
                'payload': op.payload,
                'updatedAt': '2026-09-10T00:00:00Z',
                'deletedAt': null,
              },
            },
          ],
        };
      };
      await sync.synchronize();
      expect(await db.syncDao.pendingOperations(), isEmpty);
      expect((await db.workoutDao.getSession(id))!.dataKoniec, isNotNull);
      expect(api.requests[1].any((o) => o.baseVersion == 4), isTrue);
      expect(
        (await db.select(db.workoutSessions).get()).map((s) => s.syncVersion),
        containsAll([5, 1]),
      );
    },
  );

  for (final kind in ['indeterminateOperation', 'operationReuse']) {
    test('$kind retains immutable request through service restart', () async {
      await WorkoutRepository(db).startSession();
      api.onPush = (ops) async => {
        'accepted': [],
        'conflicts': [
          {'operationId': ops.first.operationId, 'kind': kind},
        ],
      };
      await sync.synchronize();
      expect(sync.status, SyncStatus.conflict);
      final before = (await db.syncDao.pendingOperations()).single.toJson();
      sync.dispose();
      sync = SyncService(db, api);
      await sync.bindAccount('account');
      await sync.synchronize();
      expect((await db.syncDao.pendingOperations()).single.toJson(), before);
    });
  }

  test('overlapping triggers share one pass', () async {
    await WorkoutRepository(db).startSession();
    final gate = Completer<void>();
    api.onPush = (ops) async {
      await gate.future;
      return {
        'accepted': [
          for (final o in ops) {'operationId': o.operationId, 'version': 1},
        ],
        'conflicts': [],
      };
    };
    final a = sync.synchronize();
    final b = sync.synchronize();
    expect(identical(a, b), isTrue);
    gate.complete();
    await a;
    expect(api.requests, hasLength(1));
  });

  test(
    'backup restore retains binding and queues restored data and old deletes',
    () async {
      await WorkoutRepository(db).startSession();
      final backup = BackupService(db);
      final bytes = await backup.exportToBytes();
      await sync.synchronize();
      final old = (await db.select(db.workoutSessions).getSingle()).syncId;
      expect((await backup.importFromBytes(bytes)).success, isTrue);
      expect((await db.syncDao.readState())!.accountId, 'account');
      final ops = await db.syncDao.pendingOperations();
      expect(ops.any((o) => o.entityId == old && o.deleted), isTrue);
      expect(ops.any((o) => o.entityId != old && !o.deleted), isTrue);
      await sync.synchronize();
      expect(await db.syncDao.pendingOperations(), isEmpty);
    },
  );

  test('profile and favorite identities are stable on two devices', () async {
    final other = AppDatabase.forTesting(NativeDatabase.memory());
    final remote = SyncService(other, FakeSyncApi());
    await remote.bindAccount('account');
    for (final d in [db, other]) {
      await ExercisesRepository(d).syncFromAssets();
      await ExercisesRepository(d).toggleFavorite('cw001', true);
      await UserProfileRepository(d).saveProfile(
        imie: 'Test',
        wiek: 40,
        wzrostCm: 180,
        wagaKg: 80,
        cel: CelTreningowy.mix,
        dostepnySprzet: [],
      );
    }
    expect(
      (await db.select(db.userProfiles).getSingle()).syncId,
      (await other.select(other.userProfiles).getSingle()).syncId,
    );
    expect(
      (await db.select(db.exerciseFavorites).getSingle()).syncId,
      (await other.select(other.exerciseFavorites).getSingle()).syncId,
    );
    remote.dispose();
    await other.close();
  });

  test('backup does not resurrect deleted plans', () async {
    final repo = PlannerRepository(db);
    final id = await repo.savePlan(
      nazwa: 'Removed',
      cwiczeniaIds: [],
      cel: 'mix',
    );
    await repo.deletePlan(id);
    final backup = BackupService(db);
    final bytes = await backup.exportToBytes();
    expect((await backup.importFromBytes(bytes)).success, isTrue);
    expect(await db.plansDao.watchAll().first, isEmpty);
  });

  test('pull tombstone for replaced row does not resurrect it', () async {
    api.page = {
      'cursor': 1,
      'changes': [
        {
          'entityType': 'workoutSession',
          'entityId': 'old',
          'version': 2,
          'payload': {},
          'updatedAt': '2026-09-10T00:00:00Z',
          'deletedAt': '2026-09-10T00:00:00Z',
        },
      ],
    };
    await sync.synchronize();
    expect(sync.status, SyncStatus.idle);
    expect((await db.syncDao.readState())!.cursor, 1);
    expect(await db.select(db.workoutSessions).get(), isEmpty);
  });

  test(
    'backup queue uses the same ISO payload contract as local mutations',
    () async {
      await WorkoutRepository(db).startSession();
      await SyncStore(db).enqueueAll();
      expect(
        (await db.syncDao.pendingOperations()).single.payload['dataStart'],
        isA<String>(),
      );
    },
  );

  test(
    'late duplicate acknowledgement cannot regress a newer observed version',
    () async {
      final repo = WorkoutRepository(db);
      final id = await repo.startSession();
      await SyncStore(db).version(
        SyncEntityType.workoutSession,
        (await db.workoutDao.getSession(id))!.syncId,
        5,
      );
      await repo.finishSession(id, DateTime.now());
      final row = (await db.workoutDao.getSession(id))!;
      await SyncStore(db).version(SyncEntityType.workoutSession, row.syncId, 1);
      expect((await db.syncDao.pendingOperations()).single.baseVersion, 5);
    },
  );

  test(
    'restore to an already synced singleton keeps imported edit on version conflict',
    () async {
      final repo = UserProfileRepository(db);
      await repo.saveProfile(
        imie: 'Restored',
        wiek: 40,
        wzrostCm: 180,
        wagaKg: 80,
        cel: CelTreningowy.mix,
        dostepnySprzet: [],
      );
      final backup = BackupService(db);
      final bytes = await backup.exportToBytes();
      await sync.synchronize();
      await repo.saveProfile(
        imie: 'Changed',
        wiek: 40,
        wzrostCm: 180,
        wagaKg: 80,
        cel: CelTreningowy.mix,
        dostepnySprzet: [],
      );
      await sync.synchronize();
      await backup.importFromBytes(bytes);
      final restored = (await db.syncDao.pendingOperations()).single;
      expect(restored.payload['imie'], 'Restored');
      expect(restored.baseVersion, 2);
    },
  );

  test(
    'restored singleton rebases safely when another device advanced it',
    () async {
      await UserProfileRepository(db).saveProfile(
        imie: 'Restore me',
        wiek: 40,
        wzrostCm: 180,
        wagaKg: 80,
        cel: CelTreningowy.mix,
        dostepnySprzet: [],
      );
      final backup = BackupService(db);
      final bytes = await backup.exportToBytes();
      await sync.synchronize();
      await backup.importFromBytes(bytes);
      var calls = 0;
      api.onPush = (ops) async {
        final op = ops.single;
        if (calls++ == 0) {
          return {
            'accepted': [],
            'conflicts': [
              {
                'operationId': op.operationId,
                'record': {
                  'entityType': op.entityType.wireName,
                  'entityId': op.entityId,
                  'version': 5,
                  'payload': {...op.payload, 'imie': 'Other device'},
                  'updatedAt': '2026-09-10T00:00:00Z',
                  'deletedAt': null,
                },
              },
            ],
          };
        }
        return {
          'accepted': [
            {'operationId': op.operationId, 'version': op.baseVersion + 1},
          ],
          'conflicts': [],
        };
      };
      await sync.synchronize();
      expect((await db.select(db.userProfiles).getSingle()).imie, 'Restore me');
      expect(api.requests.last.single.baseVersion, 5);
      expect(await db.syncDao.pendingOperations(), isEmpty);
    },
  );

  test(
    'changed remote account never receives bound local operations',
    () async {
      await WorkoutRepository(db).startSession();
      sync.dispose();
      sync = SyncService(db, api, currentAccountId: () async => 'other');
      await sync.bindAccount('account');
      await sync.synchronize();
      expect(api.requests, isEmpty);
      expect(await db.syncDao.pendingOperations(), hasLength(1));
      expect(sync.status, SyncStatus.signedOut);
    },
  );

  test('startup, local mutation and reconnect retry automatically', () async {
    sync.dispose();
    sync = SyncService(
      db,
      api,
      retryInterval: const Duration(milliseconds: 20),
    );
    await sync.bindAccount('account');
    final first = Completer<void>();
    final retried = Completer<void>();
    var online = false;
    api.onPush = (ops) async {
      if (!online) {
        if (!first.isCompleted) first.complete();
        throw Exception('offline');
      }
      if (!retried.isCompleted) retried.complete();
      return {
        'accepted': [
          for (final o in ops)
            {'operationId': o.operationId, 'version': o.baseVersion + 1},
        ],
        'conflicts': [],
      };
    };
    sync.start();
    await WorkoutRepository(db).startSession();
    await first.future.timeout(const Duration(seconds: 2));
    online = true;
    await retried.future.timeout(const Duration(seconds: 2));
    await sync.synchronize();
    expect(await db.syncDao.pendingOperations(), isEmpty);
    await sync.stop();
  });

  test('fresh device replays profile deletion and remote revival', () async {
    final store = SyncStore(db);
    final record = {
      'entityType': 'profile',
      'entityId': 'remote-profile',
      'version': 1,
      'updatedAt': '2026-09-10T00:00:00Z',
      'deletedAt': null,
      'payload': {
        'imie': 'Test',
        'wiek': 40,
        'wzrostCm': 180,
        'wagaKg': 80,
        'cel': 'mix',
        'dostepnySprzet': <String>[],
        'onboardingZakonczony': true,
        'dataUtworzenia': '2026-09-10T00:00:00Z',
      },
    };
    await store.apply(record);
    await store.apply({
      ...record,
      'version': 2,
      'deletedAt': '2026-09-10T01:00:00Z',
    });
    expect(await UserProfileRepository(db).getProfileOnce(), isNull);
    await store.apply({...record, 'version': 3});
    final profile = await UserProfileRepository(db).getProfileOnce();
    expect(profile?.onboardingZakonczony, isTrue);
    expect((await db.userProfileDao.watchProfileOnce())!.syncVersion, 3);
  });

  test(
    'remote profile deletion hides profile and next save revives it',
    () async {
      final repo = UserProfileRepository(db);
      await repo.saveProfile(
        imie: 'Test',
        wiek: 40,
        wzrostCm: 180,
        wagaKg: 80,
        cel: CelTreningowy.mix,
        dostepnySprzet: [],
      );
      final op = (await db.syncDao.pendingOperations()).single;
      await sync.synchronize();
      api.page = {
        'cursor': 1,
        'changes': [
          {
            'entityType': 'profile',
            'entityId': op.entityId,
            'version': 2,
            'payload': op.payload,
            'updatedAt': '2026-09-10T00:00:00Z',
            'deletedAt': '2026-09-10T00:00:00Z',
          },
        ],
      };
      await sync.synchronize();
      expect(await repo.getProfileOnce(), isNull);
      expect(await repo.watchProfile().first, isNull);
      await repo.saveProfile(
        imie: 'Revived',
        wiek: 40,
        wzrostCm: 180,
        wagaKg: 80,
        cel: CelTreningowy.mix,
        dostepnySprzet: [],
      );
      expect((await repo.getProfileOnce())!.imie, 'Revived');
      expect((await db.syncDao.pendingOperations()).single.baseVersion, 2);
    },
  );

  test(
    'resolved conflict applies previously observed remote version',
    () async {
      await WorkoutRepository(db).startSession();
      final op = (await db.syncDao.pendingOperations()).single;
      final record = {
        'entityType': op.entityType.wireName,
        'entityId': op.entityId,
        'version': 5,
        'payload': {...op.payload, 'notatka': 'Server'},
        'updatedAt': '2026-09-10T00:00:00Z',
        'deletedAt': null,
      };
      api.onPush = (_) async => {
        'accepted': [],
        'conflicts': [
          {'operationId': op.operationId, 'kind': 'indeterminateOperation'},
        ],
      };
      api.page = {
        'cursor': 1,
        'changes': [record],
      };
      await sync.synchronize();
      api.onPush = (_) async => {
        'accepted': [],
        'conflicts': [
          {'operationId': op.operationId, 'record': record},
        ],
      };
      api.page = {'cursor': 1, 'changes': []};
      await sync.synchronize();
      expect(
        (await db.select(db.workoutSessions).getSingle()).notatka,
        'Server',
      );
      expect(await db.syncDao.pendingOperations(), isEmpty);
    },
  );

  test(
    'clock rollback cannot send later edits before uncertain operations',
    () async {
      final repo = WorkoutRepository(db);
      final id = await repo.startSession();
      api.onPush = (_) async => throw Exception('offline');
      await sync.synchronize();
      final attempted = api.requests.single.single;
      await repo.finishSession(id, DateTime.now());
      await (db.update(db.syncOutbox)..where((o) => o.attempted.equals(false)))
          .write(SyncOutboxCompanion(createdAtUtc: Value(DateTime(2000))));
      api.onPush = null;
      await sync.synchronize();
      expect(api.requests[1].single.operationId, attempted.operationId);
      expect(api.requests.last.single.payload['dataKoniec'], isNotNull);
    },
  );

  test('stopped pass ignores a late unauthorized response', () async {
    sync.dispose();
    var unauthorized = 0;
    sync = SyncService(
      db,
      api,
      onUnauthorized: () async {
        unauthorized++;
      },
    );
    await sync.bindAccount('account');
    await WorkoutRepository(db).startSession();
    final started = Completer<void>();
    final gate = Completer<void>();
    api.onPush = (_) async {
      started.complete();
      await gate.future;
      final options = RequestOptions();
      throw DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      );
    };
    final run = sync.synchronize();
    await started.future;
    final stopped = sync.stop();
    gate.complete();
    await stopped;
    await run;
    expect(unauthorized, 0);
    expect(await db.syncDao.pendingOperations(), hasLength(1));
  });

  test('session is pushed before its sets after coalescing a finish', () async {
    final repo = WorkoutRepository(db);
    final id = await repo.startSession();
    await repo.logSet(
      sessionId: id,
      exerciseId: 'cw001',
      exerciseNamePl: 'Test',
      setNumber: 1,
    );
    await repo.finishSession(id, DateTime.now());
    await (db.update(db.syncOutbox)
          ..where((o) => o.entityType.equals('workoutSet')))
        .write(SyncOutboxCompanion(createdAtUtc: Value(DateTime(2000))));
    await sync.synchronize();
    expect(api.requests.single.first.entityType, SyncEntityType.workoutSession);
  });
}
