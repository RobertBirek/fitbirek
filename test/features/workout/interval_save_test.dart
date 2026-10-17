import 'dart:async';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'pr_cancel_test.dart'
    show LocalAuthRepository, LocalSyncService, LocalExercisesRepository;
import '../../core/push_settings_test.dart' show FakePush;
import 'session_tracking_test.dart' show exercise;

class PausedRoundRepository extends WorkoutRepository {
  PausedRoundRepository(super.db);
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<int> logSet({
    required int sessionId,
    required String exerciseId,
    required String exerciseNamePl,
    required int setNumber,
    double? weightKg,
    int? reps,
    int? seconds,
    int? rpe,
    String? side,
    String? variantId,
    String? variantLabel,
    String? accountId,
    bool Function()? guard,
    int? guidanceSlot,
    String? expectedSyncId,
  }) async {
    final id = await super.logSet(
      sessionId: sessionId,
      exerciseId: exerciseId,
      exerciseNamePl: exerciseNamePl,
      setNumber: setNumber,
      seconds: seconds,
      side: side,
      variantId: variantId,
      variantLabel: variantLabel,
      accountId: accountId,
      guard: guard,
      rpe: rpe,
    );
    if (!entered.isCompleted) {
      entered.complete();
      await release.future;
    }
    return id;
  }
}

const rounds = [
  IntervalRound(round: 1, seconds: 10, shortened: false),
  IntervalRound(round: 2, seconds: 3, shortened: true),
];

class IntervalAuthRepository extends LocalAuthRepository {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => const AuthSession(accountId: 'account');
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late ActiveWorkoutNotifier notifier;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    notifier = container.read(activeWorkoutProvider.notifier);
    await notifier.startSession();
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'explicit batch is atomic, actual seconds/side, single-use including double tap',
    () async {
      final origin = notifier.captureInterval(
        exercise: exercise,
        side: 'left',
        rpe: 8,
      )!;
      final first = notifier.saveIntervalRounds(origin, rounds);
      expect(await notifier.saveIntervalRounds(origin, rounds), isFalse);
      expect(await first, isTrue);
      expect(await notifier.saveIntervalRounds(origin, rounds), isFalse);
      final rows = await db.workoutDao.getAllSets();
      expect(rows.map((s) => s.czasSekund), [10, 3]);
      expect(rows.map((s) => s.side), ['left', 'left']);
      expect(rows.map((s) => s.numerSerii), [1, 2]);
      expect(
        rows.every((s) => s.ciezarKg == null && s.powtorzenia == null),
        isTrue,
      );
      expect(container.read(activeWorkoutProvider).loggedSets, hasLength(2));
      expect(container.exists(authStateProvider), isFalse);
      expect(await db.select(db.personalRecords).get(), isEmpty);
    },
  );
  for (final action in [
    'discard',
    'finish',
    'new session',
    'locked',
    'caller gone',
  ]) {
    test(
      'rejects captured origin after $action without new session or writes',
      () async {
        final origin = notifier.captureInterval(exercise: exercise)!;
        switch (action) {
          case 'discard':
            notifier.discardSession();
          case 'finish':
            await notifier.finishSession();
          case 'new session':
            notifier.discardSession();
            await notifier.startSession();
          case 'locked':
            await db
                .into(db.syncState)
                .insert(
                  SyncStateCompanion.insert(
                    accountId: 'account',
                    deviceId: 'device',
                    offlineAccess: const Value(false),
                  ),
                );
        }
        final before = (await db.syncDao.pendingOperations())
            .map((s) => s.toJson())
            .toList();
        expect(
          await notifier.saveIntervalRounds(
            origin,
            rounds,
            guard: () => action != 'caller gone',
          ),
          isFalse,
        );
        expect(await db.workoutDao.getAllSets(), isEmpty);
        expect(
          (await db.syncDao.pendingOperations())
              .map((s) => s.toJson())
              .toList(),
          before,
        );
      },
    );
  }
  for (final action in ['discard', 'finish']) {
    test(
      '$action while first round awaits rolls back entire batch and outbox',
      () async {
        container.dispose();
        final repo = PausedRoundRepository(db);
        container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            workoutRepositoryProvider.overrideWithValue(repo),
          ],
        );
        notifier = container.read(activeWorkoutProvider.notifier);
        await notifier.startSession();
        final origin = notifier.captureInterval(exercise: exercise)!;
        final before = (await db.syncDao.pendingOperations())
            .map((s) => s.toJson())
            .toList();
        final write = notifier.saveIntervalRounds(origin, rounds);
        await repo.entered.future;
        Future<void>? finishing;
        if (action == 'finish') {
          finishing = notifier.finishSession();
        } else {
          notifier.discardSession();
        }
        repo.release.complete();
        expect(await write, isFalse);
        await finishing;
        expect(await db.workoutDao.getAllSets(), isEmpty);
        if (action == 'discard') {
          expect(
            (await db.syncDao.pendingOperations())
                .map((s) => s.toJson())
                .toList(),
            before,
          );
        } else {
          expect(
            (await db.syncDao.pendingOperations()).where(
              (s) => s.entityType == SyncEntityType.workoutSet,
            ),
            isEmpty,
          );
        }
      },
    );
  }
  test(
    'logout epoch changes during transaction; full batch/outbox rolled back without HTTP reads',
    () async {
      container.dispose();
      final repo = PausedRoundRepository(db);
      final api = IntervalAuthRepository();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(api),
          syncServiceProvider.overrideWith((ref) => LocalSyncService(db)),
          exercisesRepositoryProvider.overrideWithValue(
            LocalExercisesRepository(db),
          ),
          pushClientProvider.overrideWithValue(FakePush()),
        ],
      );
      final signedIn = Completer<void>();
      container.listen(authStateProvider, (_, next) {
        if (next.isSignedIn && !signedIn.isCompleted) signedIn.complete();
      }, fireImmediately: true);
      await signedIn.future;
      notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      final origin = notifier.captureInterval(exercise: exercise)!;
      final reads = api.sessionReads;
      final before = (await db.syncDao.pendingOperations())
          .map((s) => s.toJson())
          .toList();
      final write = notifier.saveIntervalRounds(origin, rounds);
      await repo.entered.future;
      final logout = container.read(authStateProvider.notifier).logout();
      expect(notifier.isIntervalCurrent(origin), isFalse);
      repo.release.complete();
      expect(await write, isFalse);
      await logout;
      expect(api.sessionReads, reads);
      expect(await db.workoutDao.getAllSets(), isEmpty);
      expect(
        (await db.syncDao.pendingOperations()).map((s) => s.toJson()).toList(),
        before,
      );
      expect(await notifier.saveIntervalRounds(origin, rounds), isFalse);
      expect(notifier.captureInterval(exercise: exercise), isNull);
      await container.read(authStateProvider.notifier).login('test', 'test');
      expect(container.read(authStateProvider).isSignedIn, isTrue);
      expect(
        notifier.isIntervalCurrent(origin),
        isFalse,
      ); // same ID, newer epoch
      expect(await notifier.saveIntervalRounds(origin, rounds), isFalse);
      expect(await db.workoutDao.getAllSets(), isEmpty);
    },
  );
}
