import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import '../../core/sync_service_test.dart' show FakeSyncApi;
import '../../core/deferred_sync_test.dart' show remote, uncertain, accepted;

Future<void> restoreEmpty(AppDatabase db) async {
  final bytes = Uint8List.fromList(
    utf8.encode(jsonEncode({'schemaVersion': 2, 'data': {}})),
  );
  expect((await BackupService(db).importFromBytes(bytes)).success, isTrue);
}

class DelayedWatchRepository extends WorkoutRepository {
  DelayedWatchRepository(super.db);
  @override
  Stream<WorkoutSessionData?> watchSession(int id) => const Stream.empty();
}

class DelayedFinishRepository extends WorkoutRepository {
  DelayedFinishRepository(super.db);
  final written = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> finishSession(int id, DateTime start) async {
    await super.finishSession(id, start);
    written.complete();
    await release.future;
  }
}

void main() {
  for (final finish in [true, false]) {
    test(
      'notifier handles a ${finish ? "finish" : "set"} rejected before the deletion watch arrives',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            workoutRepositoryProvider.overrideWithValue(
              DelayedWatchRepository(db),
            ),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await db.close();
        });
        final notifier = container.read(activeWorkoutProvider.notifier);
        await notifier.startSession();
        await restoreEmpty(db);
        expect(container.read(activeWorkoutProvider).isActive, isTrue);
        final before = (await db.syncDao.pendingOperations())
            .map((o) => o.toJson())
            .toList();
        if (finish) {
          await notifier.finishSession();
        } else {
          const exercise = Exercise(
            id: 'cw001',
            nazwaPl: 'Test',
            nazwaEn: 'Test',
            partiaGlowna: '',
            partieWspierajace: [],
            sprzet: [],
            typ: '',
            poziom: '',
            wzorzecRuchu: '',
            seriexPowtorzenia: '',
            tempo: '',
            kluczoweWskazowki: [],
            czesteBledy: [],
            progresja: '',
            regresja: '',
            zrodlo: '',
          );
          expect(
            await notifier.logSet(exercise: exercise, weightKg: 20, reps: 10),
            isFalse,
          );
        }
        expect(container.read(activeWorkoutProvider).isActive, isFalse);
        expect(container.read(activeWorkoutProvider).loggedSets, isEmpty);
        expect(await db.select(db.personalRecords).get(), isEmpty);
        expect(
          (await db.syncDao.pendingOperations())
              .map((o) => o.toJson())
              .toList(),
          before,
        );
      },
    );
  }

  test(
    'late finish completion cannot clear a replacement active session',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DelayedFinishRepository(db);
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
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      final finishing = notifier.finishSession();
      await repo.written.future;
      notifier.discardSession();
      await notifier.startSession();
      final replacement = container.read(activeWorkoutProvider).sessionId;
      repo.release.complete();
      await finishing;
      expect(container.read(activeWorkoutProvider).sessionId, replacement);
      expect(container.read(activeWorkoutProvider).isActive, isTrue);
    },
  );
  test(
    'deferred remote deletion immediately invalidates the active session',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      final api = FakeSyncApi();
      final sync = SyncService(db, api);
      addTearDown(() async {
        container.dispose();
        sync.dispose();
        await db.close();
      });
      await sync.bindAccount('account');
      final notifier = container.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      final id = container.read(activeWorkoutProvider).sessionId!;
      final op = (await db.syncDao.pendingOperations()).single;
      final reset = Completer<void>();
      final subscription = container.listen(activeWorkoutProvider, (_, next) {
        if (!next.isActive && !reset.isCompleted) reset.complete();
      });
      addTearDown(subscription.close);
      api.onPush = (_) async => uncertain(op);
      api.page = {
        'cursor': 20,
        'changes': [remote(op, 5, deleted: true)],
      };
      await sync.synchronize();
      expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNotNull);
      await reset.future.timeout(const Duration(seconds: 2));
      await expectLater(
        WorkoutRepository(db).finishSession(id, DateTime.now()),
        throwsStateError,
      );
      expect(
        (await db.syncDao.pendingOperations()).single.toJson(),
        op.toJson(),
      );
      api.onPush = (_) async => accepted(op, 1);
      api.page = {'cursor': 20, 'changes': []};
      await sync.synchronize();
      expect(container.read(activeWorkoutProvider).isActive, isFalse);
      expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNotNull);
    },
  );
  for (final finish in [true, false]) {
    test(
      '${finish ? "finishSession" : "logSet"} rejects restored tombstoned parent without modifying row or queue',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = WorkoutRepository(db);
        final id = await repo.startSession();
        await restoreEmpty(db);
        final row = (await db.workoutDao.getSession(id))!.toJson();
        final queue = (await db.syncDao.pendingOperations())
            .map((o) => o.toJson())
            .toList();
        await expectLater(
          finish
              ? repo.finishSession(id, DateTime.now())
              : repo.logSet(
                  sessionId: id,
                  exerciseId: 'cw001',
                  exerciseNamePl: 'Test',
                  setNumber: 1,
                ),
          throwsStateError,
        );
        expect((await db.workoutDao.getSession(id))!.toJson(), row);
        expect(
          (await db.syncDao.pendingOperations())
              .map((o) => o.toJson())
              .toList(),
          queue,
        );
        expect(await db.workoutDao.getAllSets(), isEmpty);
      },
    );
  }

  for (final restored in [true, false]) {
    test(
      'active provider clears when ${restored ? "restore" : "pull"} deletes its session',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final container = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );
        final api = FakeSyncApi();
        final sync = SyncService(db, api);
        addTearDown(() async {
          container.dispose();
          sync.dispose();
          await db.close();
        });
        await sync.bindAccount('account');
        final notifier = container.read(activeWorkoutProvider.notifier);
        await notifier.startSession();
        final id = container.read(activeWorkoutProvider).sessionId!;
        final op = (await db.syncDao.pendingOperations()).single;
        await sync.synchronize();
        final reset = Completer<void>();
        final subscription = container.listen(activeWorkoutProvider, (_, next) {
          if (!next.isActive && !reset.isCompleted) reset.complete();
        });
        addTearDown(subscription.close);
        if (restored) {
          await restoreEmpty(db);
        } else {
          api.page = {
            'cursor': 1,
            'changes': [
              {
                'entityType': 'workoutSession',
                'entityId': op.entityId,
                'version': 2,
                'payload': op.payload,
                'updatedAt': '2026-09-10T00:00:00Z',
                'deletedAt': '2026-09-10T00:00:00Z',
              },
            ],
          };
          await sync.synchronize();
        }
        await reset.future.timeout(const Duration(seconds: 2));
        expect(container.read(activeWorkoutProvider).sessionId, isNull);
        expect(container.read(activeWorkoutProvider).loggedSets, isEmpty);
        final queueBefore = (await db.syncDao.pendingOperations())
            .map((o) => o.toJson())
            .toList();
        await notifier.finishSession();
        expect((await db.workoutDao.getSession(id))!.dataKoniec, isNull);
        expect((await db.workoutDao.getSession(id))!.deletedAtUtc, isNotNull);
        expect(
          (await db.syncDao.pendingOperations())
              .map((o) => o.toJson())
              .toList(),
          queueBefore,
        );
        await notifier.startSession();
        expect(container.read(activeWorkoutProvider).isActive, isTrue);
        expect(container.read(activeWorkoutProvider).sessionId, isNot(id));
      },
    );
  }
}
