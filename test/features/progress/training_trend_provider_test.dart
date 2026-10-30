import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/progress/trends/data/training_trend_repository.dart';
import 'package:fitbirek_training/features/progress/trends/domain/training_trend.dart';
import 'package:fitbirek_training/features/progress/trends/providers/training_trend_providers.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import '../workout/progression_provider_test.dart'
    show ProgressionAuth, ProgressionSync;
import '../workout/pr_cancel_test.dart' show LocalExercisesRepository;
import '../../core/push_settings_test.dart' show FakePush;

class DelayedTrends extends TrainingTrendRepository {
  DelayedTrends(super.db);
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Stream<List<TrendRow>> watchHistory() async* {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    yield [
      TrendRow(
        scope: (exerciseId: 'secret', side: null, variantId: null),
        sessionId: 1,
        setId: 1,
        endedAt: DateTime.utc(2026),
        setNumber: 1,
        exerciseName: 'Secret',
      ),
    ];
  }
}

void main() {
  test(
    'live SELECT refresh removes deleted history and creates no mutations',
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
          .insert(
            const SyncStateCompanion(
              id: Value(1),
              accountId: Value('a'),
              deviceId: Value('d'),
            ),
          );
      final session = await db.workoutDao.createSession(
        WorkoutSessionsCompanion.insert(
          dataStart: DateTime.utc(2026),
          dataKoniec: Value(DateTime.utc(2026, 1, 2)),
        ),
      );
      await db.workoutDao.addSet(
        SetsLogCompanion.insert(
          sesjaId: session,
          cwiczenieId: 'ex',
          nazwaCwiczeniaPl: 'Test',
          numerSerii: 1,
          powtorzenia: const Value(8),
        ),
      );
      final removed = Completer<void>();
      c.listen(trainingTrendHistoryProvider, (_, next) {
        if (!next.isLoading &&
            next.valueOrNull?.isEmpty == true &&
            !removed.isCompleted) {
          removed.complete();
        }
      });
      expect(await c.read(trainingTrendHistoryProvider.future), hasLength(1));
      await db
          .update(db.setsLog)
          .write(SetsLogCompanion(deletedAtUtc: Value(DateTime.utc(2026))));
      await removed.future.timeout(const Duration(seconds: 5));
      expect(await c.read(trainingTrendHistoryProvider.future), isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      expect(c.exists(authStateProvider), isFalse);
    },
  );
  for (final afterRead in [false, true]) {
    test(
      'passive auth logout ${afterRead ? 'after' : 'during'} read withdraws history without auth bootstrap',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        await db
            .into(db.syncState)
            .insert(
              const SyncStateCompanion(
                id: Value(1),
                accountId: Value('a'),
                deviceId: Value('d'),
              ),
            );
        final repo = DelayedTrends(db), api = ProgressionAuth();
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            trainingTrendRepositoryProvider.overrideWithValue(repo),
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
        final signedIn = Completer<void>();
        c.listen(authStateProvider, (_, state) {
          if (state.isSignedIn && !signedIn.isCompleted) signedIn.complete();
        }, fireImmediately: true);
        await signedIn.future;
        c.listen(trainingTrendHistoryProvider, (_, __) {});
        await repo.entered.future;
        final reads = api.sessionReads;
        if (afterRead) {
          repo.release.complete();
          expect(await c.read(trainingTrendHistoryProvider.future), isNotEmpty);
        }
        final logout = c.read(authStateProvider.notifier).logout();
        expect(c.read(authStateProvider).isLoading, isTrue);
        if (!repo.release.isCompleted) repo.release.complete();
        await logout;
        expect(await c.read(trainingTrendHistoryProvider.future), isNull);
        expect(api.sessionReads, reads);
      },
    );
  }
  for (final change in ['account', 'device', 'locked', 'ABA']) {
    test(
      'delayed read rejected after binding $change; never retarget page',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        await db
            .into(db.syncState)
            .insert(
              const SyncStateCompanion(
                id: Value(1),
                accountId: Value('a'),
                deviceId: Value('d'),
              ),
            );
        final repo = DelayedTrends(db);
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            trainingTrendRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container.dispose);
        final seen = <List<TrendRow>?>[];
        final sub = container.listen(trainingTrendHistoryProvider, (_, next) {
          if (!next.isLoading && !next.hasError) seen.add(next.valueOrNull);
        }, fireImmediately: true);
        addTearDown(sub.close);
        await repo.entered.future;
        await db
            .update(db.syncState)
            .write(
              SyncStateCompanion(
                accountId: Value(
                  change == 'account' || change == 'ABA' ? 'b' : 'a',
                ),
                deviceId: Value(change == 'device' ? 'other' : 'd'),
                offlineAccess: Value(change != 'locked'),
              ),
            );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        if (change == 'ABA') {
          await db
              .update(db.syncState)
              .write(const SyncStateCompanion(accountId: Value('a')));
        }
        repo.release.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(seen.whereType<List<TrendRow>>().expand((x) => x), isEmpty);
        expect(await db.select(db.syncOutbox).get(), isEmpty);
        expect(container.exists(authStateProvider), isFalse);
      },
    );
  }
}
