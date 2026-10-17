import 'dart:async';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/api/api_client.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/progress/prs/data/prs_repository.dart';
import 'package:fitbirek_training/features/progress/prs/providers/prs_providers.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'session_tracking_test.dart' show exercise;
import '../../core/push_settings_test.dart' show FakePush;
import '../../core/sync_service_test.dart' show FakeSyncApi;

class PausedPrs extends PrsRepository {
  PausedPrs(super.db);
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<PersonalRecordData?> getBestForExercise(
    String exerciseId, {
    String? side,
    String? variantId,
  }) async {
    final best = await super.getBestForExercise(
      exerciseId,
      side: side,
      variantId: variantId,
    );
    entered.complete();
    await release.future;
    return best;
  }
}

class LocalAuthRepository extends AuthRepository {
  LocalAuthRepository() : super(ApiClient.sameOrigin());
  int sessionReads = 0;
  int logoutCalls = 0;
  @override
  Future<AuthSession?> getSession() async {
    sessionReads++;
    return const AuthSession(accountId: 'account');
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

class LocalSyncService extends SyncService {
  LocalSyncService(AppDatabase db) : super(db, FakeSyncApi());
  @override
  void start() {} // No background sync may consume the queue under assertion.
}

class LocalExercisesRepository extends ExercisesRepository {
  LocalExercisesRepository(super.db);
  @override
  Future<void> syncFromAssets() async {}
}

class CancellingPrs extends PrsRepository {
  CancellingPrs(super.db, this.cancel);
  final void Function() cancel;
  @override
  Future<PersonalRecordData?> getBestForExercise(
    String exerciseId, {
    String? side,
    String? variantId,
  }) async {
    final best = await super.getBestForExercise(
      exerciseId,
      side: side,
      variantId: variantId,
    );
    cancel();
    return best;
  }
}

void main() {
  test(
    'logout started outside paused logSet transaction cancels set, PR and outbox',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final prs = PausedPrs(db);
      final api = LocalAuthRepository();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          prsRepositoryProvider.overrideWithValue(prs),
          authRepositoryProvider.overrideWithValue(api),
          syncServiceProvider.overrideWith((ref) => LocalSyncService(db)),
          exercisesRepositoryProvider.overrideWithValue(
            LocalExercisesRepository(db),
          ),
          pushClientProvider.overrideWithValue(FakePush()),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final signedIn = Completer<void>();
      container.listen(authStateProvider, (_, next) {
        if (next.isSignedIn && !signedIn.isCompleted) signedIn.complete();
      }, fireImmediately: true);
      await signedIn.future;
      final auth = container.read(authStateProvider.notifier);
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      final before = (await db.syncDao.pendingOperations())
          .map((o) => o.toJson())
          .toList();
      final reads = api.sessionReads;
      final authEpoch = container.read(cachedAuthWriteAuthorityProvider).epoch;
      final write = notifier.logSet(
        exercise: exercise,
        weightKg: 20,
        reps: 10,
        side: 'left',
      );
      await prs.entered.future;
      // Outside the transaction's Zone: do not await the queued SQLite lock.
      final logout = auth.logout();
      expect(container.read(authStateProvider).isLoading, isTrue);
      expect(
        container.read(cachedAuthWriteAuthorityProvider).epoch,
        greaterThan(authEpoch),
      );
      expect(api.logoutCalls, 0);
      prs.release.complete();
      final result = await write;
      await logout;
      expect(api.sessionReads, reads); // No pre-save HTTP/session read.
      expect(api.logoutCalls, 1);
      expect(container.read(authStateProvider).isSignedOut, isTrue);
      expect((await db.syncDao.readState())!.offlineAccess, isFalse);
      expect(result, isFalse);
      expect(await db.workoutDao.getAllSets(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(
        (await db.syncDao.pendingOperations()).map((o) => o.toJson()).toList(),
        before,
      );
      expect(container.read(activeWorkoutProvider).loggedSets, isEmpty);
      // The cached signed-out state also rejects a fresh attempt, even if a caller
      // still holds the notifier after navigation has started.
      await notifier.startSession();
      final signedOutQueue = (await db.syncDao.pendingOperations())
          .map((o) => o.toJson())
          .toList();
      expect(
        await notifier.logSet(
          exercise: exercise,
          weightKg: 25,
          reps: 10,
          side: 'right',
        ),
        isFalse,
      );
      expect(await db.workoutDao.getAllSets(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(
        (await db.syncDao.pendingOperations()).map((o) => o.toJson()).toList(),
        signedOutQueue,
      );
    },
  );
  test('standalone offline write never initializes auth or HTTP', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    expect(container.exists(authStateProvider), isFalse);
    final notifier = container.read(activeWorkoutProvider.notifier);
    await notifier.startSession();
    expect(
      await notifier.logSet(
        exercise: exercise,
        weightKg: 20,
        reps: 10,
        side: 'both',
      ),
      isTrue,
    );
    expect(container.exists(authStateProvider), isFalse);
    expect(container.read(cachedAuthWriteAuthorityProvider).state, isNull);
  });
  test('locked account cannot save a sided set or PR', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final notifier = container.read(activeWorkoutProvider.notifier);
    await notifier.startSession();
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(
            accountId: 'account',
            deviceId: 'device',
            offlineAccess: const Value(false),
          ),
        );
    final before = (await db.syncDao.pendingOperations())
        .map((o) => o.toJson())
        .toList();
    expect(
      await notifier.logSet(
        exercise: exercise,
        weightKg: 20,
        reps: 10,
        side: 'right',
      ),
      isFalse,
    );
    expect(await db.workoutDao.getAllSets(), isEmpty);
    expect(await db.select(db.personalRecords).get(), isEmpty);
    expect(
      (await db.syncDao.pendingOperations()).map((o) => o.toJson()).toList(),
      before,
    );
  });
  test('cancel during side PR lookup rolls back set, PR and outbox', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    late ProviderContainer container;
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        prsRepositoryProvider.overrideWithValue(
          CancellingPrs(
            db,
            () =>
                container.read(activeWorkoutProvider.notifier).discardSession(),
          ),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final notifier = container.read(activeWorkoutProvider.notifier);
    await notifier.startSession();
    final before = (await db.syncDao.pendingOperations())
        .map((o) => o.toJson())
        .toList();
    expect(
      await notifier.logSet(
        exercise: exercise,
        weightKg: 20,
        reps: 10,
        side: 'left',
      ),
      isFalse,
    );
    expect(await db.workoutDao.getAllSets(), isEmpty);
    expect(await db.select(db.personalRecords).get(), isEmpty);
    expect(
      (await db.syncDao.pendingOperations()).map((o) => o.toJson()).toList(),
      before,
    );
    expect(container.read(activeWorkoutProvider).loggedSets, isEmpty);
  });
}
