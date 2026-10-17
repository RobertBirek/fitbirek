import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/fixed_load_progression.dart';
import 'package:fitbirek_training/features/workout/providers/fixed_load_progression_provider.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'pr_cancel_test.dart'
    show LocalAuthRepository, LocalSyncService, LocalExercisesRepository;
import '../../core/push_settings_test.dart' show FakePush;

const request = (
  exerciseId: 'ex',
  side: 'left',
  prescription: '3x8-12',
  tracking: 'reps',
  usesWeight: true,
  weightKg: 20.0,
);

class DelayedHistory extends WorkoutRepository {
  DelayedHistory(super.db);
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<List<ProgressionPerformance>> getProgressionHistory(
    String id, {
    required String? side,
    String? variantId,
    required int excludingSessionId,
  }) async {
    final rows = await super.getProgressionHistory(
      id,
      side: side,
      variantId: variantId,
      excludingSessionId: excludingSessionId,
    );
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return rows;
  }
}

class ProgressionAuth extends LocalAuthRepository {
  @override
  Future<AuthSession?> getSession() async {
    sessionReads++;
    return const AuthSession(accountId: 'a');
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => AuthSession(accountId: email);
}

// Adversarial binding switch without clearing rows: the read guard must still
// reject old offers (production SyncService normally refuses this operation).
class ProgressionSync extends LocalSyncService {
  ProgressionSync(this.database) : super(database);
  final AppDatabase database;
  @override
  Future<void> bindAccount(String accountId) async {
    await database
        .update(database.syncState)
        .write(
          SyncStateCompanion(
            accountId: Value(accountId),
            offlineAccess: const Value(true),
          ),
        );
  }
}

Future<void> seedProgression(AppDatabase db) async {
  await db
      .into(db.syncState)
      .insert(
        const SyncStateCompanion(
          id: Value(1),
          accountId: Value('a'),
          deviceId: Value('device'),
          offlineAccess: Value(true),
        ),
      );
  for (var i = 1; i <= 2; i++) {
    final session = await db.workoutDao.createSession(
      WorkoutSessionsCompanion.insert(
        dataStart: DateTime.utc(2026, 10, i),
        dataKoniec: Value(DateTime.utc(2026, 10, i, 1)),
      ),
    );
    await db.workoutDao.addSet(
      SetsLogCompanion.insert(
        sesjaId: session,
        cwiczenieId: 'ex',
        nazwaCwiczeniaPl: 'Test',
        numerSerii: 1,
        side: const Value('left'),
        ciezarKg: const Value(20),
        powtorzenia: const Value(8),
        rpe: const Value(7),
      ),
    );
  }
}

void main() {
  for (final action in [
    'logout during read',
    'logout after offer',
    'account switch',
  ]) {
    test(
      'cached authority rejects $action without additional auth reads',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final api = ProgressionAuth();
        final repo = DelayedHistory(db);
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            workoutRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(api),
            syncServiceProvider.overrideWith((ref) => ProgressionSync(db)),
            exercisesRepositoryProvider.overrideWithValue(
              LocalExercisesRepository(db),
            ),
            pushClientProvider.overrideWithValue(FakePush()),
          ],
        );
        addTearDown(() async {
          c.dispose();
          await db.close();
        });
        await seedProgression(db);
        final signedIn = Completer<void>();
        c.listen(authStateProvider, (_, state) {
          if (state.isSignedIn && !signedIn.isCompleted) signedIn.complete();
        }, fireImmediately: true);
        await signedIn.future;
        await c.read(activeWorkoutProvider.notifier).startSession();
        final sub = c.listen(fixedLoadProgressionProvider(request), (_, _) {});
        addTearDown(sub.close);
        final future = c.read(fixedLoadProgressionProvider(request).future);
        await repo.entered.future;
        final reads = api.sessionReads;
        FixedLoadOffer? offer;
        if (action != 'logout during read') {
          repo.release.complete();
          offer = await future;
          expect(offer!.suggestion.target, 9);
        }
        final auth = c.read(authStateProvider.notifier);
        if (action == 'account switch') {
          await auth.login('b', 'unused');
        } else {
          final logout = auth.logout();
          expect(c.read(authStateProvider).isLoading, isTrue);
          if (offer != null) expect(await offer.isCurrent(), isFalse);
          if (!repo.release.isCompleted) repo.release.complete();
          await logout;
        }
        offer ??= await future;
        expect(offer == null || !await offer.isCurrent(), isTrue);
        expect(api.sessionReads, reads);
      },
    );
  }
  for (final change in ['account', 'lock', 'session', 'session row replaced']) {
    test('async history cannot offer after $change changes', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DelayedHistory(db);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      await seedProgression(db);
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      final sub = container.listen(
        fixedLoadProgressionProvider(request),
        (_, _) {},
      );
      addTearDown(sub.close);
      final future = container.read(
        fixedLoadProgressionProvider(request).future,
      );
      await repo.entered.future;
      if (change == 'session') {
        notifier.discardSession();
      } else if (change == 'session row replaced') {
        await (db.update(db.workoutSessions)..where(
              (s) =>
                  s.id.equals(container.read(activeWorkoutProvider).sessionId!),
            ))
            .write(
              const WorkoutSessionsCompanion(
                syncId: Value('replacement-session'),
              ),
            );
      } else {
        await db
            .update(db.syncState)
            .write(
              change == 'account'
                  ? const SyncStateCompanion(accountId: Value('b'))
                  : const SyncStateCompanion(offlineAccess: Value(false)),
            );
      }
      repo.release.complete();
      // The disposed request can complete, but never carries an applicable offer.
      final offer = await future;
      expect(offer == null || !await offer.isCurrent(), isTrue);
      expect(container.exists(authStateProvider), isFalse);
    });
  }
  test(
    'capture rechecks binding on apply, side is an isolated family key',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await seedProgression(db);
      await c.read(activeWorkoutProvider.notifier).startSession();
      final sub = c.listen(fixedLoadProgressionProvider(request), (_, _) {});
      addTearDown(sub.close);
      final offer = await c.read(fixedLoadProgressionProvider(request).future);
      expect(offer!.suggestion.target, 9);
      expect(await offer.isCurrent(), isTrue);
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(accountId: Value('b')));
      expect(await offer.isCurrent(), isFalse);
      expect(c.exists(authStateProvider), isFalse);
    },
  );
}
