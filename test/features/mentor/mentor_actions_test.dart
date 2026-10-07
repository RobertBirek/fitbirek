import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fitbirek_training/features/progress/prs/data/prs_repository.dart';
import 'package:fitbirek_training/features/progress/prs/providers/prs_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/providers/mentor_actions.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';

class _TestAuthApi implements AuthApi {
  @override
  Future<AuthSession?> getSession() async => null;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

class _TestAuthController extends AuthController {
  _TestAuthController(AuthState initial) : super(_TestAuthApi()) {
    state = initial;
  }

  void signIn(String accountId) => state = AuthState.signedIn(accountId);
  void loading() => state = const AuthState.loading();
}

class _PausedPrs extends PrsRepository {
  _PausedPrs(super.db);
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<PersonalRecordData?> getBestForExercise(String exerciseId) async {
    final best = await super.getBestForExercise(exerciseId);
    entered.complete();
    await release.future;
    return best;
  }
}

class _PausedStart extends WorkoutRepository {
  _PausedStart(super.db, {this.afterWrite = false});
  final bool afterWrite;
  final entered = Completer<void>();
  final release = Completer<void>();
  int calls = 0;

  @override
  Future<IdempotentSessionWrite> startSessionIdempotent({
    required String syncId,
    required String accountId,
    bool Function()? guard,
  }) async {
    calls++;
    if (!afterWrite) {
      entered.complete();
      await release.future;
    }
    final write = await super.startSessionIdempotent(
      syncId: syncId,
      accountId: accountId,
      guard: guard,
    );
    if (afterWrite) {
      entered.complete();
      await release.future;
    }
    return write;
  }
}

Future<void> _bind(AppDatabase db, String accountId) {
  return db
      .into(db.syncState)
      .insert(
        SyncStateCompanion.insert(
          accountId: accountId,
          deviceId: 'test-device',
        ),
      );
}

Future<void> _insertExercise(AppDatabase db, {String id = 'cw001'}) {
  return db
      .into(db.exercises)
      .insert(
        ExercisesCompanion.insert(
          id: id,
          nazwaPl: 'Pompki',
          nazwaEn: 'Push-up',
          partiaGlowna: 'Klatka',
          partieWspierajace: '[]',
          sprzet: '[]',
          typ: 'Siła',
          poziom: 'Początkujący',
          wzorzecRuchu: 'Pchanie',
          seriexPowtorzenia: '3x8',
          tempo: 'normalne',
          kluczoweWskazowki: '[]',
          czesteBledy: '[]',
          progresja: '',
          regresja: '',
          zrodlo: 'test',
        ),
      );
}

void main() {
  late AppDatabase db;
  late _TestAuthController auth;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _bind(db, 'account-a');
    await _insertExercise(db);
    auth = _TestAuthController(const AuthState.signedIn('account-a'));
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authStateProvider.overrideWith((_) => auth),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  MentorProposal proposal(MentorProposalKind kind, String id) => MentorProposal(
    id: id,
    kind: kind,
    exerciseId: kind == MentorProposalKind.logSet ? 'cw001' : null,
    weightKg: kind == MentorProposalKind.logSet ? 42.5 : null,
    reps: kind == MentorProposalKind.logSet ? 8 : null,
  );

  void useRepository(WorkoutRepository repo) {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authStateProvider.overrideWith((_) => auth),
        workoutRepositoryProvider.overrideWithValue(repo),
      ],
    );
  }

  test(
    'pending notifier start is shared across executors before async write',
    () async {
      final repo = _PausedStart(db);
      useRepository(repo);
      final notifier = container.read(activeWorkoutProvider.notifier);
      final first = notifier.startMentorSession(
        syncId: 'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
        accountId: 'account-a',
      );
      await repo.entered.future;
      final same = notifier.startMentorSession(
        syncId: 'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
        accountId: 'account-a',
      );
      final other = notifier.startMentorSession(
        syncId: 'a8b743b4-4a1e-4209-b749-e35b3a2b6766',
        accountId: 'account-a',
      );
      expect(identical(first, same), isTrue);
      expect(await other, isNull);
      expect(repo.calls, 1);
      repo.release.complete();
      final write = await first;
      expect(identical(await same, write), isTrue);
      expect(
        container.read(activeWorkoutProvider).sessionId,
        write!.session.id,
      );
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.syncDao.pendingOperations(), hasLength(1));
    },
  );

  for (final afterWrite in [false, true]) {
    test(
      'loading at start barrier afterWrite=$afterWrite rolls back session/outbox',
      () async {
        final repo = _PausedStart(db, afterWrite: afterWrite);
        useRepository(repo);
        final pending = container
            .read(mentorActionsProvider)
            .confirm(
              proposal(
                MentorProposalKind.startWorkout,
                'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
              ),
              accountId: 'account-a',
              expectedSessionId: null,
            );
        await repo.entered.future;
        auth.loading();
        repo.release.complete();
        expect(await pending, MentorActionResult.unavailable);
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect(await db.syncDao.pendingOperations(), isEmpty);
        expect(container.read(activeWorkoutProvider).isActive, isFalse);
      },
    );
  }

  test(
    'repository alone serializes different starts inside write transaction',
    () async {
      final repo = WorkoutRepository(db);
      final writes = await Future.wait([
        for (final id in [
          'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
          'a8b743b4-4a1e-4209-b749-e35b3a2b6766',
        ])
          () async {
            try {
              await repo.startSessionIdempotent(
                syncId: id,
                accountId: 'account-a',
              );
              return true;
            } on WorkoutSessionUnavailable {
              return false;
            }
          }(),
      ]);
      expect(writes.where((created) => created), hasLength(1));
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.syncDao.pendingOperations(), hasLength(1));
    },
  );

  test(
    'concurrent set retries use explicit edited values and never invent RPE',
    () async {
      await container.read(activeWorkoutProvider.notifier).startSession();
      final sessionId = container.read(activeWorkoutProvider).sessionId!;
      final set = proposal(
        MentorProposalKind.logSet,
        'b3e7a93d-8a9f-43a2-a427-11f9d3ba7796',
      );
      final action = container.read(mentorActionsProvider);
      final results = await Future.wait(
        List.generate(
          2,
          (_) => action.confirm(
            set,
            accountId: 'account-a',
            expectedSessionId: sessionId,
            weightKg: 17.25,
            reps: 11,
          ),
        ),
      );
      expect(
        results,
        containsAll([
          MentorActionResult.applied,
          MentorActionResult.alreadyApplied,
        ]),
      );
      final rows = await db.select(db.setsLog).get();
      expect(rows, hasLength(1));
      expect(rows.single.ciezarKg, 17.25);
      expect(rows.single.powtorzenia, 11);
      expect(rows.single.rpe, isNull);
      expect(container.read(activeWorkoutProvider).loggedSets, hasLength(1));
      expect(await db.syncDao.pendingOperations(), hasLength(3));
      await (db.update(db.setsLog)..where((s) => s.id.equals(rows.single.id)))
          .write(SetsLogCompanion(deletedAtUtc: Value(DateTime.now().toUtc())));
      final before = await db.syncDao.pendingOperations();
      expect(
        await container
            .refresh(mentorActionsProvider)
            .confirm(set, accountId: 'account-a', expectedSessionId: sessionId),
        MentorActionResult.alreadyApplied,
      );
      expect(await db.select(db.setsLog).get(), hasLength(1));
      expect(
        (await db.select(db.setsLog).get()).single.deletedAtUtc,
        isNotNull,
      );
      expect(await db.syncDao.pendingOperations(), hasLength(before.length));
    },
  );

  for (final deleted in [false, true]) {
    test(
      'replay never resumes finished/deleted start deleted=$deleted',
      () async {
        final start = proposal(
          MentorProposalKind.startWorkout,
          'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
        );
        final action = container.read(mentorActionsProvider);
        await action.confirm(
          start,
          accountId: 'account-a',
          expectedSessionId: null,
        );
        final id = container.read(activeWorkoutProvider).sessionId!;
        final now = DateTime.now().toUtc();
        await (db.update(
          db.workoutSessions,
        )..where((s) => s.id.equals(id))).write(
          deleted
              ? WorkoutSessionsCompanion(deletedAtUtc: Value(now))
              : WorkoutSessionsCompanion(dataKoniec: Value(now)),
        );
        container.read(activeWorkoutProvider.notifier).discardSession();
        expect(
          await action.confirm(
            start,
            accountId: 'account-a',
            expectedSessionId: null,
          ),
          MentorActionResult.alreadyApplied,
        );
        expect(container.read(activeWorkoutProvider).isActive, isFalse);
        expect(await db.select(db.workoutSessions).get(), hasLength(1));
        expect(await db.syncDao.pendingOperations(), hasLength(1));
      },
    );
  }

  test(
    'repeated start confirmation creates one durable session and outbox row',
    () async {
      final action = container.read(mentorActionsProvider);
      final start = proposal(
        MentorProposalKind.startWorkout,
        'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
      );

      expect(
        await action.confirm(
          start,
          accountId: 'account-a',
          expectedSessionId: null,
        ),
        MentorActionResult.applied,
      );
      final recreated = container.refresh(mentorActionsProvider);
      expect(
        await recreated.confirm(
          start,
          accountId: 'account-a',
          expectedSessionId: null,
        ),
        MentorActionResult.alreadyApplied,
      );

      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.syncDao.pendingOperations(), hasLength(1));
    },
  );

  test('concurrent same start keeps a single active session', () async {
    final action = container.read(mentorActionsProvider);
    final start = proposal(
      MentorProposalKind.startWorkout,
      'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
    );
    final results = await Future.wait(
      List.generate(
        2,
        (_) => action.confirm(
          start,
          accountId: 'account-a',
          expectedSessionId: null,
        ),
      ),
    );
    expect(results, everyElement(MentorActionResult.applied));
    final rows = await db.select(db.workoutSessions).get();
    expect(rows, hasLength(1));
    expect(container.read(activeWorkoutProvider).sessionId, rows.single.id);
    expect(await db.syncDao.pendingOperations(), hasLength(1));
  });

  test('different concurrent starts cannot create two sessions', () async {
    final action = container.read(mentorActionsProvider);
    await Future.wait([
      for (final id in [
        'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
        'a8b743b4-4a1e-4209-b749-e35b3a2b6766',
      ])
        action.confirm(
          proposal(MentorProposalKind.startWorkout, id),
          accountId: 'account-a',
          expectedSessionId: null,
        ),
    ]);
    expect(await db.select(db.workoutSessions).get(), hasLength(1));
    expect(container.read(activeWorkoutProvider).isActive, isTrue);
  });

  test('replay resumes owned unfinished session without a new write', () async {
    final action = container.read(mentorActionsProvider);
    final start = proposal(
      MentorProposalKind.startWorkout,
      'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
    );
    await action.confirm(
      start,
      accountId: 'account-a',
      expectedSessionId: null,
    );
    final id = container.read(activeWorkoutProvider).sessionId;
    container.read(activeWorkoutProvider.notifier).discardSession();
    expect(
      await action.confirm(
        start,
        accountId: 'account-a',
        expectedSessionId: null,
      ),
      MentorActionResult.alreadyApplied,
    );
    expect(container.read(activeWorkoutProvider).sessionId, id);
    expect(await db.syncDao.pendingOperations(), hasLength(1));
  });

  test('start validates optional catalogue exercise and UUID', () async {
    final action = container.read(mentorActionsProvider);
    for (final invalid in [
      MentorProposal(id: 'not-a-uuid', kind: MentorProposalKind.startWorkout),
      MentorProposal(
        id: 'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
        kind: MentorProposalKind.startWorkout,
        exerciseId: 'missing',
      ),
    ]) {
      expect(
        await action.confirm(
          invalid,
          accountId: 'account-a',
          expectedSessionId: null,
        ),
        MentorActionResult.unavailable,
      );
    }
    expect(await db.select(db.workoutSessions).get(), isEmpty);
    expect(
      await action.confirm(
        MentorProposal(
          id: 'd2719ea8-1a37-4f51-8b49-c71cbaa87e50',
          kind: MentorProposalKind.startWorkout,
          exerciseId: 'cw001',
        ),
        accountId: 'account-a',
        expectedSessionId: null,
      ),
      MentorActionResult.applied,
    );
    expect(
      container.read(activeWorkoutProvider).selectedExercises.single.id,
      'cw001',
    );
  });

  for (final transition in ['loading', 'account', 'session', 'roundtrip']) {
    test('$transition during PR read rolls back set, outbox and PR', () async {
      final prs = _PausedPrs(db);
      container.dispose();
      container = ProviderContainer(
        overrides: [
          prsRepositoryProvider.overrideWithValue(prs),
          appDatabaseProvider.overrideWithValue(db),
          authStateProvider.overrideWith((_) => auth),
        ],
      );
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      final sessionId = container.read(activeWorkoutProvider).sessionId!;
      final pending = container
          .read(mentorActionsProvider)
          .confirm(
            proposal(
              MentorProposalKind.logSet,
              'b3e7a93d-8a9f-43a2-a427-11f9d3ba7796',
            ),
            accountId: 'account-a',
            expectedSessionId: sessionId,
          );
      await prs.entered.future;
      switch (transition) {
        case 'loading':
          auth.loading();
        case 'account':
          auth.signIn('account-b');
        case 'session':
          notifier.discardSession();
        case 'roundtrip':
          auth.loading();
          auth.signIn('account-a');
      }
      prs.release.complete();
      expect(await pending, MentorActionResult.unavailable);
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(await db.syncDao.pendingOperations(), hasLength(1));
    });
  }

  test(
    'repeated identified set confirmation writes one set and updates active state once',
    () async {
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      final sessionId = container.read(activeWorkoutProvider).sessionId!;
      final set = proposal(
        MentorProposalKind.logSet,
        'b3e7a93d-8a9f-43a2-a427-11f9d3ba7796',
      );

      expect(
        await container
            .read(mentorActionsProvider)
            .confirm(set, accountId: 'account-a', expectedSessionId: sessionId),
        MentorActionResult.applied,
      );
      final outboxAfterFirst = await db.syncDao.pendingOperations();
      expect(
        await container
            .refresh(mentorActionsProvider)
            .confirm(set, accountId: 'account-a', expectedSessionId: sessionId),
        MentorActionResult.alreadyApplied,
      );

      expect(await db.select(db.setsLog).get(), hasLength(1));
      expect(container.read(activeWorkoutProvider).loggedSets, hasLength(1));
      expect(outboxAfterFirst, hasLength(3));
      expect(
        await db.syncDao.pendingOperations(),
        hasLength(outboxAfterFirst.length),
      );
    },
  );

  test(
    'finished or switched session ownership is rejected without writes',
    () async {
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      final sessionId = container.read(activeWorkoutProvider).sessionId!;
      await WorkoutRepository(db).finishSession(sessionId, DateTime.now());
      final before = await db.syncDao.pendingOperations();

      expect(
        await container
            .read(mentorActionsProvider)
            .confirm(
              proposal(
                MentorProposalKind.logSet,
                '49c60d60-7cc3-48a9-a5f7-29a56a03723c',
              ),
              accountId: 'account-a',
              expectedSessionId: sessionId,
            ),
        MentorActionResult.unavailable,
      );
      auth.signIn('account-b');
      expect(
        await container
            .read(mentorActionsProvider)
            .confirm(
              proposal(
                MentorProposalKind.startWorkout,
                'a8b743b4-4a1e-4209-b749-e35b3a2b6766',
              ),
              accountId: 'account-a',
              expectedSessionId: null,
            ),
        MentorActionResult.unavailable,
      );
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(await db.syncDao.pendingOperations(), hasLength(before.length));
    },
  );

  test(
    'unknown exercise and ambiguous values are rejected without writes',
    () async {
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      final sessionId = container.read(activeWorkoutProvider).sessionId!;
      final invalidExercise = MentorProposal(
        id: 'edbfc663-c7fb-4740-95fd-a299f3f47e10',
        kind: MentorProposalKind.logSet,
        exerciseId: 'missing',
        weightKg: 20,
        reps: 8,
      );
      final invalidValues = MentorProposal(
        id: '8f871024-c8cf-4210-adfc-d4d2206dd4ed',
        kind: MentorProposalKind.logSet,
        exerciseId: 'cw001',
        weightKg: 501,
        reps: 0,
      );

      expect(
        await container
            .read(mentorActionsProvider)
            .confirm(
              invalidExercise,
              accountId: 'account-a',
              expectedSessionId: sessionId,
            ),
        MentorActionResult.unavailable,
      );
      expect(
        await container
            .read(mentorActionsProvider)
            .confirm(
              invalidValues,
              accountId: 'account-a',
              expectedSessionId: sessionId,
            ),
        MentorActionResult.unavailable,
      );
      expect(await db.select(db.setsLog).get(), isEmpty);
    },
  );

  test(
    'classic offline workout repository remains usable without an account state',
    () async {
      await db.delete(db.syncState).go();
      final repo = WorkoutRepository(db);

      final sessionId = await repo.startSession();
      await repo.logSet(
        sessionId: sessionId,
        exerciseId: 'cw001',
        exerciseNamePl: 'Pompki',
        setNumber: 1,
        weightKg: 20,
        reps: 10,
      );

      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.select(db.setsLog).get(), hasLength(1));
    },
  );
}
