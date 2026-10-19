import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/presentation/widgets/session_recovery_panel.dart';
import 'session_recovery_provider_test.dart' show RecoveryAuthority;
import 'deleted_session_test.dart' show DelayedFinishRepository;

class WaitingFinishLookup extends WorkoutRepository {
  WaitingFinishLookup(super.db);
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<WorkoutSessionData?> findSessionBySyncId(String id) async {
    final row = await super.findSessionBySyncId(id);
    entered.complete();
    await release.future;
    return row;
  }
}

void main() {
  for (final recorded in [0, 17]) {
    test(
      'explicit finish without draft preserves recorded duration $recorded and unlocks start',
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
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        final repo = WorkoutRepository(db);
        final id = await repo.startSession(accountId: 'a');
        await db.workoutDao.updateSession(
          id,
          WorkoutSessionsCompanion(
            dataStart: Value(DateTime.now().subtract(const Duration(days: 3))),
            czasTrwaniaSekund: Value(recorded),
          ),
        );
        final uuid = (await db.workoutDao.getSession(id))!.syncId;
        {
          await repo.logSet(
            sessionId: id,
            exerciseId: 'saved',
            exerciseNamePl: 'Zapisane',
            setNumber: 1,
            seconds: 7,
            accountId: 'a',
          );
        }
        final setsBefore = await db.select(db.setsLog).get();
        final n = c.read(activeWorkoutProvider.notifier);
        expect(await n.resumeSession(uuid), isFalse);
        await expectLater(n.startSession(), throwsStateError);
        expect(await n.finishPendingSession(uuid), id);
        final row = (await db.workoutDao.getSession(id))!;
        expect(row.dataKoniec, isNotNull);
        expect(row.czasTrwaniaSekund, recorded);
        expect(
          (await db.syncDao.pendingOperations())
              .lastWhere((op) => op.entityId == uuid)
              .payload['czasTrwaniaSekund'],
          recorded,
        );
        expect(await db.select(db.setsLog).get(), setsBefore);
        expect(await db.select(db.personalRecords).get(), isEmpty);
        await n.startSession();
        expect(c.read(activeWorkoutProvider).sessionSyncId, isNot(uuid));
      },
    );
  }

  test(
    'account A B A while finish awaits refuses mutation and outbox',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final authority = RecoveryAuthority();
      final repo = WaitingFinishLookup(db);
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
          cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
        authority.revision.dispose();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final id = await repo.startSession(accountId: 'a');
      final uuid = (await db.workoutDao.getSession(id))!.syncId;
      await repo.logSet(
        sessionId: id,
        exerciseId: 'saved',
        exerciseNamePl: 'Wykonane',
        setNumber: 1,
        seconds: 5,
        accountId: 'a',
      );
      final before = (await db.syncDao.pendingOperations())
          .map((e) => e.toJson())
          .toList();
      final finish = c
          .read(activeWorkoutProvider.notifier)
          .finishPendingSession(uuid);
      await repo.entered.future.timeout(const Duration(seconds: 2));
      authority.switchTo('b');
      authority.switchTo('a');
      repo.release.complete();
      expect(await finish, isNull);
      expect((await db.workoutDao.getSession(id))!.dataKoniec, isNull);
      expect(
        (await db.syncDao.pendingOperations()).map((e) => e.toJson()).toList(),
        before,
      );
    },
  );

  testWidgets(
    'missing draft offers explicit finish with cancel and confirmation',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      late int id;
      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        id = await WorkoutRepository(db).startSession(accountId: 'a');
        await WorkoutRepository(db).logSet(
          sessionId: id,
          exerciseId: 'saved',
          exerciseNamePl: 'Wykonane',
          setNumber: 1,
          seconds: 5,
          accountId: 'a',
        );
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: Scaffold(body: SessionRecoveryPanel()),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zakończ bez wznawiania'), findsOneWidget);
      await tester.tap(find.text('Zakończ bez wznawiania'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(
        await tester.runAsync(
          () async => (await db.workoutDao.getSession(id))!.dataKoniec,
        ),
        isNull,
      );
      await tester.tap(find.text('Zakończ bez wznawiania'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => tester.tap(find.text('Zakończ sesję')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(
        await tester.runAsync(
          () async => (await db.workoutDao.getSession(id))!.dataKoniec,
        ),
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  test(
    'account invalidation after finish SQL rolls back session and outbox',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final authority = RecoveryAuthority();
      final repo = DelayedFinishRepository(db);
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
          cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
        authority.revision.dispose();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final id = await repo.startSession(accountId: 'a');
      final uuid = (await db.workoutDao.getSession(id))!.syncId;
      await repo.logSet(
        sessionId: id,
        exerciseId: 'saved',
        exerciseNamePl: 'Wykonane',
        setNumber: 1,
        seconds: 5,
        accountId: 'a',
      );
      final before = (await db.syncDao.pendingOperations())
          .map((e) => e.toJson())
          .toList();
      final finish = c
          .read(activeWorkoutProvider.notifier)
          .finishPendingSession(
            uuid,
            expectedAccountId: 'a',
            expectedAuthorityEpoch: authority.epoch,
          );
      await repo.written.future.timeout(const Duration(seconds: 2));
      authority.switchTo('b');
      repo.release.complete();
      expect(await finish, isNull);
      expect((await db.workoutDao.getSession(id))!.dataKoniec, isNull);
      expect(
        (await db.syncDao.pendingOperations()).map((e) => e.toJson()).toList(),
        before,
      );
    },
  );

  test(
    'stale recovery snapshot, wrong binding, lock and foreign draft cannot finish',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final authority = RecoveryAuthority();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
        authority.revision.dispose();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final id = await WorkoutRepository(db).startSession(accountId: 'a');
      final uuid = (await db.workoutDao.getSession(id))!.syncId;
      final n = c.read(activeWorkoutProvider.notifier);
      final oldEpoch = authority.epoch;
      authority.switchTo('b');
      authority.switchTo('a');
      expect(
        await n.finishPendingSession(
          uuid,
          expectedAccountId: 'a',
          expectedAuthorityEpoch: oldEpoch,
        ),
        isNull,
      );
      expect(
        await n.finishPendingSession(
          uuid,
          expectedAccountId: 'b',
          expectedAuthorityEpoch: authority.epoch,
        ),
        isNull,
      );
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(offlineAccess: Value(false)));
      expect(await n.finishPendingSession(uuid), isNull);
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(offlineAccess: Value(true)));
      await db
          .into(db.workoutDrafts)
          .insert(
            WorkoutDraftsCompanion.insert(
              accountId: 'b',
              sessionSyncId: uuid,
              payloadJson: '{}',
            ),
          );
      expect(await n.finishPendingSession(uuid), isNull);
      expect((await db.workoutDao.getSession(id))!.dataKoniec, isNull);
    },
  );
}
