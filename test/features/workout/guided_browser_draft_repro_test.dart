import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/core/sync/sync_models.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import '../../core/push_settings_test.dart' show FakePush;
import 'pr_cancel_test.dart' show LocalAuthRepository;

final capture =
    jsonDecode(
          File(
            'test/features/workout/fixtures/guided_browser_capture.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

class BrowserAuth extends LocalAuthRepository {
  @override
  Future<AuthSession> getSession() async =>
      AuthSession(accountId: capture['accountId'] as String);
}

/// Same ACK + echo shape as the captured browser harness, through real SyncService.
class BrowserEcho implements SyncApi {
  BrowserEcho({this.reorder = false});
  final bool reorder;
  final sent = <SyncOperation>[];
  int cursor = 2;
  final changes = <Map<String, dynamic>>[
    Map<String, dynamic>.from(capture['profile'] as Map),
  ];
  @override
  Future<Map<String, dynamic>> pull(int after) async =>
      Map<String, dynamic>.from(
        wireCopy({
              'cursor': cursor,
              'changes': changes
                  .where((r) => (r['changeCursor'] as int) > after)
                  .toList(),
            })
            as Map,
      );
  Object? wireCopy(Object? value) {
    if (value is Map) {
      return {
        for (final key in reorder ? value.keys.toList().reversed : value.keys)
          key: wireCopy(value[key]),
      };
    }
    if (value is List) return value.map(wireCopy).toList();
    return value;
  }

  @override
  Future<Map<String, dynamic>> push(List<SyncOperation> ops) async {
    sent.addAll(ops);
    for (final op in ops) {
      changes.add({
        'entityType': op.entityType.wireName,
        'entityId': op.entityId,
        'version': op.baseVersion + 1,
        'payload': jsonDecode(jsonEncode(op.payload)),
        'updatedAt': '2026-10-17T01:30:00.000Z',
        'deletedAt': null,
        'changeCursor': ++cursor,
      });
    }
    return {
      'accepted': [
        for (final op in ops)
          {'operationId': op.operationId, 'version': op.baseVersion + 1},
      ],
      'conflicts': [],
    };
  }
}

class RefusingActiveDraft extends WorkoutRepository {
  RefusingActiveDraft(super.db);
  @override
  Future<Map<String, Object?>> saveDraft({
    required int sessionId,
    required String sessionSyncId,
    required String accountId,
    required Map<String, Object?> payload,
    required bool Function() guard,
  }) async {
    throw WorkoutSessionUnavailable(sessionId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'captured guidance is already canonical; the harness did not strip or reorder it',
    () {
      final g = WorkoutGuidance.validateJson(capture['guidance']);
      expect(jsonEncode(g.toJson()), jsonEncode(capture['guidance']));
      expect(g.plan.estimatedSeconds, 1998);
      expect(g.plan.blocks[3].exerciseId, 'cw367');
    },
  );
  test(
    'a refused write for a still-owned active row is not silently treated as a saved draft',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(RefusingActiveDraft(db)),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(
              accountId: capture['accountId'] as String,
              deviceId: 'fake-device',
            ),
          );
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(
        guidance: WorkoutGuidance.validateJson(capture['guidance']),
      );
      expect(n.moveGuided(3), isTrue);
      n.updateDraft({'side': 'left', 'reps': '7'});
      await expectLater(n.flushDraft(), throwsStateError);
      expect(n.draftSaveError, contains('Nie zapisano szkicu'));
      expect(await db.select(db.workoutDrafts).get(), isEmpty);
      expect((await db.workoutDao.getAllSets()), isEmpty);
      expect(
        (await db.select(db.workoutSessions).get()).single.dataKoniec,
        isNull,
      );
    },
  );
  for (final remote in [false, true]) {
    test(
      'detached draft worker does not publish a rolled-back start remote=$remote',
      () async {
        final temp = await Directory.systemTemp.createTemp('guided-rollback-');
        final db = AppDatabase.forTesting(
          remote
              ? NativeDatabase.createInBackground(
                  File('${temp.path}/test.sqlite'),
                )
              : NativeDatabase.memory(),
        );
        final c = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );
        addTearDown(() async {
          c.dispose();
          await db.close();
          await temp.delete(recursive: true);
        });
        await db
            .into(db.syncState)
            .insert(
              SyncStateCompanion.insert(
                accountId: capture['accountId'] as String,
                deviceId: 'fake-device',
              ),
            );
        await expectLater(
          db.transaction(() async {
            await c
                .read(activeWorkoutProvider.notifier)
                .startSession(
                  guidance: WorkoutGuidance.validateJson(capture['guidance']),
                );
            throw StateError('rollback caller transaction');
          }),
          throwsStateError,
        );
        await c
            .read(activeWorkoutProvider.notifier)
            .flushDraft()
            .timeout(const Duration(seconds: 5));
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect(await db.select(db.workoutDrafts).get(), isEmpty);
        expect(await db.syncDao.pendingOperations(), isEmpty);
      },
    );
  }
  for (final setup in [
    (false, false, false),
    (true, false, false),
    (true, false, true),
    (true, true, false),
    (true, true, true),
  ]) {
    final (planner, remote, reorder) = setup;
    test(
      'captured auth/profile/echo ${planner ? 'planner' : 'direct'} remote=$remote JSONB-reorder=$reorder durably retains block 4 left 7',
      () async {
        final temp = await Directory.systemTemp.createTemp(
          'guided-browser-dart-',
        );
        var db = AppDatabase.forTesting(
          remote
              ? NativeDatabase.createInBackground(
                  File('${temp.path}/test.sqlite'),
                )
              : NativeDatabase.memory(),
        );
        final api = BrowserEcho(reorder: reorder);
        var sync = SyncService(db, api, retryInterval: const Duration(days: 1));
        ProviderContainer container(SyncService service) => ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authRepositoryProvider.overrideWithValue(BrowserAuth()),
            syncServiceProvider.overrideWith((ref) => service),
            pushClientProvider.overrideWithValue(FakePush()),
          ],
        );
        var c = container(sync);
        addTearDown(() async {
          await sync.stop();
          c.dispose();
          await db.close();
          await temp.delete(recursive: true);
        });
        final ready = Completer<void>();
        c.listen(authStateProvider, (_, state) {
          if (state.isSignedIn && !ready.isCompleted) ready.complete();
        }, fireImmediately: true);
        await ready.future;
        await sync.synchronize();
        final authorityEpoch = c.read(cachedAuthWriteAuthorityProvider).epoch;
        final g = WorkoutGuidance.validateJson(capture['guidance']);
        final exercises = await c
            .read(exercisesRepositoryProvider)
            .watchAll()
            .first;
        if (planner) {
          await c
              .read(plannerWorkflowProvider)
              .start(
                g.plan.exerciseIds
                    .map((id) => exercises.firstWhere((e) => e.id == id))
                    .toList(),
                plan: g.plan,
              );
        } else {
          await c
              .read(activeWorkoutProvider.notifier)
              .startSession(guidance: g);
        }
        final n = c.read(activeWorkoutProvider.notifier);
        await sync.synchronize();
        for (var i = 1; i <= 3; i++) {
          expect(n.moveGuided(i), isTrue);
        }
        n.updateDraft({'reps': '7', 'side': 'left', 'rpe': 7});
        await n.flushDraft().timeout(const Duration(seconds: 5));
        final rows = await db.select(db.workoutDrafts).get();
        expect(rows, hasLength(1));
        final saved = jsonDecode(rows.single.payloadJson) as Map;
        expect(saved['currentSlot'], 3);
        expect(saved['fields']['reps'], '7');
        expect(saved['fields']['side'], 'left');
        expect(await db.workoutDao.getAllSets(), isEmpty);
        expect(await db.select(db.workoutSessions).get(), hasLength(1));
        expect(
          api.sent.where((o) => o.entityType == SyncEntityType.workoutSession),
          hasLength(1),
        );
        expect(
          api.sent.where((o) => o.entityType == SyncEntityType.workoutSet),
          isEmpty,
        );
        expect(n.draftSaveError, isNull);
        expect(c.read(cachedAuthWriteAuthorityProvider).epoch, authorityEpoch);
        final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
        final id = c.read(activeWorkoutProvider).sessionId;
        await sync.stop();
        c.dispose();
        if (remote) {
          await db.close();
          db = AppDatabase.forTesting(
            NativeDatabase.createInBackground(File('${temp.path}/test.sqlite')),
          );
        }
        sync = SyncService(db, api, retryInterval: const Duration(days: 1));
        c = container(sync);
        final reopened = Completer<void>();
        c.listen(authStateProvider, (_, state) {
          if (state.isSignedIn && !reopened.isCompleted) reopened.complete();
        }, fireImmediately: true);
        await reopened.future;
        await sync.synchronize();
        final pending = await c
            .read(pendingWorkoutDraftsProvider.future)
            .timeout(const Duration(seconds: 5));
        expect(pending.map((d) => d.sessionSyncId), contains(uuid));
        expect(
          await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
          isTrue,
        );
        expect(c.read(activeWorkoutProvider).sessionId, id);
        expect(c.read(activeWorkoutProvider).currentSlot, 3);
        expect(c.read(activeWorkoutProvider).draft['reps'], '7');
        expect(c.read(activeWorkoutProvider).draft['side'], 'left');
        expect(await db.workoutDao.getAllSets(), isEmpty);
        expect(await db.select(db.workoutSessions).get(), hasLength(1));
        expect(
          api.sent.where((o) => o.entityType == SyncEntityType.workoutSession),
          hasLength(1),
        );
        expect(
          api.sent.where((o) => o.entityType == SyncEntityType.workoutSet),
          isEmpty,
        );
      },
    );
  }
}
