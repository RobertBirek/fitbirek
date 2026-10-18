import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/workout/providers/session_recovery_provider.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import '../planner/structured_plan_persistence_test.dart' show structure;

class RecoveryAuthority extends CachedAuthWriteAuthority {
  String account = 'a';
  int serial = 0;
  @override
  int get epoch => serial;
  @override
  AuthState get state => AuthState.signedIn(account);
  void switchTo(String next) {
    account = next;
    revision.value = ++serial;
  }
}

class WaitingRecoveryRepository extends WorkoutRepository {
  WaitingRecoveryRepository(super.db);
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<List<SetLogData>> getSetsForSession(int id) async {
    entered.complete();
    await release.future;
    return super.getSetsForSession(id);
  }
}

Future<SessionRecovery> waitFor(
  ProviderContainer c,
  bool Function(SessionRecovery) match,
) {
  final done = Completer<SessionRecovery>();
  final sub = c.listen(sessionRecoveryProvider, (_, next) {
    final value = next.asData?.value;
    if (value != null && match(value) && !done.isCompleted) {
      done.complete(value);
    }
  }, fireImmediately: true);
  return done.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(sub.close);
}

void main() {
  for (final rpc in [false, true]) {
    test(
      'reactive read-only account snapshot, legacy, multiple, corrupt and deletion rpc=$rpc',
      () async {
        final temp = await Directory.systemTemp.createTemp('session-recovery-');
        final db = AppDatabase.forTesting(
          rpc
              ? NativeDatabase.createInBackground(
                  File('${temp.path}/test.sqlite'),
                )
              : NativeDatabase.memory(),
        );
        final authority = RecoveryAuthority();
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
            authStateProvider.overrideWith(
              (ref) =>
                  throw StateError('Unexpected auth/network initialization'),
            ),
          ],
        );
        addTearDown(() async {
          c.dispose();
          await db.close();
          authority.revision.dispose();
          await temp.delete(recursive: true);
        });
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession(guidance: WorkoutGuidance.start(structure));
        await n.flushDraft();
        final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
        n.discardSession();
        final repo = WorkoutRepository(db);
        final legacy = await repo.startSession(accountId: 'a');
        final before = await db.syncDao.pendingOperations();
        final drafts = await db.select(db.workoutDrafts).get();
        final hold = c.listen(sessionRecoveryProvider, (_, _) {});
        addTearDown(hold.close);
        final initial = await waitFor(c, (v) => v.sessions.length == 2);
        expect(
          initial.sessions.where((s) => s.syncId == uuid).single.problem,
          isNull,
        );
        expect(
          initial.sessions.where((s) => s.id == legacy).single.problem,
          contains('Brak lokalnego szkicu'),
        );
        expect(c.read(activeWorkoutProvider).isActive, isFalse);
        expect(
          (await db.syncDao.pendingOperations()).map((o) => o.operationId),
          before.map((o) => o.operationId),
        );
        expect(await db.select(db.workoutDrafts).get(), drafts);
        authority.switchTo('b');
        await waitFor(c, (v) => v.sessions.isEmpty);
        await db
            .update(db.syncState)
            .write(const SyncStateCompanion(accountId: Value('b')));
        final forB = await waitFor(
          c,
          (v) => v.sessions.length == 1 && v.accountId == 'b',
        );
        expect(forB.sessions.any((s) => s.syncId == uuid), isFalse);
        authority.switchTo('a');
        await db
            .update(db.syncState)
            .write(const SyncStateCompanion(accountId: Value('a')));
        final back = await waitFor(
          c,
          (v) => v.sessions.length == 2 && v.epoch == 2,
        );
        expect(
          await n.resumeSession(
            uuid,
            expectedAccountId: initial.accountId,
            expectedAuthorityEpoch: initial.epoch,
          ),
          isFalse,
        );
        expect(back.epoch, isNot(initial.epoch));
        await db
            .update(db.workoutDrafts)
            .write(const WorkoutDraftsCompanion(payloadJson: Value('{broken')));
        await waitFor(
          c,
          (v) => v.sessions.any((s) => s.syncId == uuid && s.problem != null),
        );
        await (db.update(
          db.workoutSessions,
        )..where((s) => s.syncId.equals(uuid))).write(
          WorkoutSessionsCompanion(deletedAtUtc: Value(DateTime.now().toUtc())),
        );
        await waitFor(c, (v) => v.sessions.length == 1);
        await db
            .update(db.syncState)
            .write(const SyncStateCompanion(offlineAccess: Value(false)));
        await waitFor(c, (v) => v.sessions.isEmpty);
        expect(await db.select(db.setsLog).get(), isEmpty);
        expect(await db.select(db.personalRecords).get(), isEmpty);
      },
    );
  }
  test(
    'A-B-A during awaited restore rejects old request, including its read snapshot',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final authority = RecoveryAuthority();
      var c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      await c
          .read(activeWorkoutProvider.notifier)
          .startSession(guidance: WorkoutGuidance.start(structure));
      await c.read(activeWorkoutProvider.notifier).flushDraft();
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      c.dispose();
      final repo = WaitingRecoveryRepository(db);
      c = ProviderContainer(
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
      final request = c
          .read(activeWorkoutProvider.notifier)
          .resumeSession(
            uuid,
            expectedAccountId: 'a',
            expectedAuthorityEpoch: 0,
          );
      await repo.entered.future;
      authority.switchTo('b');
      authority.switchTo('a');
      repo.release.complete();
      expect(await request, isFalse);
      expect(c.read(activeWorkoutProvider).isActive, isFalse);
    },
  );
}
