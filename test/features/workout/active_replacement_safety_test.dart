import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import '../planner/structured_plan_persistence_test.dart' show structure;
import 'session_tracking_test.dart' show exercise;
import 'guided_side_checkpoint_review_test.dart' show completedLeftTimer;
import 'interval_save_test.dart' show PausedRoundRepository;
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/domain/workout_draft_write.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';

class ReplacementCatalog extends ExercisesRepository {
  ReplacementCatalog(super.db, {this.ids = const ['yoga', 'extra']});
  final List<String> ids;
  @override
  Stream<List<Exercise>> watchAll() =>
      Stream.value([for (final id in ids) exercise.copyWith(id: id)]);
}

/// Pause outside SQLite, immediately before guidedEvent reads its baseline.
class PausedBaselineRepository extends WorkoutRepository {
  PausedBaselineRepository(super.db);
  bool armed = false;
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<Map<String, Object?>?> readDraft(
    String accountId,
    String sessionSyncId,
  ) async {
    if (armed) {
      armed = false;
      entered.complete();
      await release.future;
    }
    return super.readDraft(accountId, sessionSyncId);
  }
}

class DelayedDraftRepository extends WorkoutRepository {
  DelayedDraftRepository(super.db);
  bool delay = false;
  final release = Completer<void>();
  @override
  Future<Map<String, Object?>> saveDraft({
    required int sessionId,
    required String sessionSyncId,
    required String accountId,
    required Map<String, Object?> payload,
    required bool Function() guard,
  }) async {
    if (delay) await release.future;
    return super.saveDraft(
      sessionId: sessionId,
      sessionSyncId: sessionSyncId,
      accountId: accountId,
      payload: payload,
      guard: guard,
    );
  }
}

class PausedTransitionRepository extends WorkoutRepository {
  PausedTransitionRepository(super.db);
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<({WorkoutGuidance guidance, Map<String, Object?> draft})>
  transitionGuidance({
    required int sessionId,
    required String sessionSyncId,
    required String accountId,
    required bool Function() guard,
    required String expectedSignature,
    required int expectedRevision,
    required int slot,
    String? replacement,
    String? targetId,
  }) async {
    entered.complete();
    await release.future;
    return super.transitionGuidance(
      sessionId: sessionId,
      sessionSyncId: sessionSyncId,
      accountId: accountId,
      guard: guard,
      expectedSignature: expectedSignature,
      expectedRevision: expectedRevision,
      slot: slot,
      replacement: replacement,
      targetId: targetId,
    );
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  late DelayedDraftRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
    repo = DelayedDraftRepository(db);
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        workoutRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });
  tearDown(() async {
    if (!repo.release.isCompleted) repo.release.complete();
    await c.read(activeWorkoutProvider.notifier).flushDraft();
    c.dispose();
    await db.close();
  });
  for (final recovery in ['swapped', 'reordered']) {
    for (final action in ['skip', 'replace']) {
      test(
        'fresh $recovery resume permits immediate $action without a draft edit',
        () async {
          final multiblock = recovery == 'reordered';
          final plan = multiblock
              ? StructuredPlan(
                  criteria: structure.criteria,
                  budgetSeconds: 300,
                  warnings: [],
                  blocks: [
                    structure.blocks.single,
                    PlanBlock(
                      exerciseId: 'second',
                      section: PlanSection.main,
                      prescription: structure.blocks.single.prescription,
                    ),
                  ],
                )
              : structure;
          final catalog = ReplacementCatalog(
            db,
            ids: [
              if (multiblock) 'second',
              'yoga',
              'replacement',
              'replacement2',
            ],
          );
          ProviderContainer container() => ProviderContainer(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              exercisesRepositoryProvider.overrideWithValue(catalog),
            ],
          );
          c.dispose();
          c = container();
          var n = c.read(activeWorkoutProvider.notifier);
          await n.startSession(guidance: WorkoutGuidance.start(plan));
          n.addExercise(exercise.copyWith(id: 'yoga'));
          if (multiblock) n.addExercise(exercise.copyWith(id: 'second'));
          await n.logSet(exercise: exercise.copyWith(id: 'yoga'), seconds: 8);
          await n.flushDraft();
          if (!multiblock) {
            expect(await n.guidedEvent(replacement: 'replacement'), isTrue);
          }
          final before = c.read(activeWorkoutProvider);
          final uuid = before.sessionSyncId!;
          final durable = (await repo.readDraft('a', uuid))!;
          final sets = await db.workoutDao.getAllSets();
          final outbox = await db.select(db.syncOutbox).get();
          c.dispose();
          c = container();
          n = c.read(activeWorkoutProvider.notifier);
          expect(await n.resumeSession(uuid), isTrue);
          expect(
            c
                .read(activeWorkoutProvider)
                .selectedExercises
                .map((e) => e.id)
                .toList(),
            multiblock ? ['second', 'yoga'] : ['yoga', 'replacement'],
          );
          expect(
            durable['selectedIds'],
            multiblock ? ['yoga', 'second'] : ['yoga'],
          );
          // Recovery reconstructs RAM only. Do NOT use updateDraft, navigation or
          // any form edit to accidentally normalize the durable selectedIds.
          expect(await repo.readDraft('a', uuid), durable);
          expect(await db.select(db.syncOutbox).get(), outbox);
          expect(
            await n.guidedEvent(
              replacement: action == 'replace' ? 'replacement2' : null,
            ),
            isTrue,
          );
          final after = c.read(activeWorkoutProvider);
          expect(after.guidance!.plan.toJson(), plan.toJson());
          expect(
            after.guidance!.events
                .take(before.guidance!.events.length)
                .toList(),
            before.guidance!.events,
          );
          expect(
            after.guidance!.events.last['type'],
            action == 'replace' ? 'replaced' : 'skipped',
          );
          expect(
            after.guidance!.exerciseAt(0),
            action == 'replace'
                ? 'replacement2'
                : before.guidance!.exerciseAt(0),
          );
          final committed = (await repo.readDraft('a', uuid))!;
          expect(committed['selectedIds'], durable['selectedIds']);
          expect(
            committed['guidanceSignature'],
            jsonEncode(after.guidance!.toJson()),
          );
          expect(await db.workoutDao.getAllSets(), sets);
        },
      );
    }
  }
  for (final foreignChange in ['timer', 'extra']) {
    test(
      'foreign $foreignChange before baseline read is not consent and survives later edit/resume',
      () async {
        final paused = PausedBaselineRepository(db);
        final catalog = ReplacementCatalog(db);
        c.dispose();
        c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            workoutRepositoryProvider.overrideWithValue(paused),
            exercisesRepositoryProvider.overrideWithValue(catalog),
          ],
        );
        final other = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            exercisesRepositoryProvider.overrideWithValue(catalog),
          ],
        );
        addTearDown(other.dispose);
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession(guidance: WorkoutGuidance.start(structure));
        n.addExercise(exercise.copyWith(id: 'yoga'));
        n.updateDraft({
          'side': 'left',
          'seconds': '9',
          'timer': completedLeftTimer(),
        });
        await n.flushDraft();
        final accepted = c.read(activeWorkoutProvider);
        final otherNotifier = other.read(activeWorkoutProvider.notifier);
        expect(
          await otherNotifier.resumeSession(accepted.sessionSyncId!),
          isTrue,
        );
        final beforeOutbox = await db.select(db.syncOutbox).get();
        paused.armed = true;
        final attempt = n.guidedEvent(
          replacement: 'replacement',
          discardCurrentDraft: true,
        );
        await paused.entered.future;
        var elapsed = Duration.zero;
        final timer = IntervalTimer(
          IntervalConfig(preparation: 0, work: 20, rest: 0, rounds: 1),
          clock: () => elapsed,
        )..start();
        elapsed = const Duration(seconds: 20);
        timer.update();
        final newerTimer = timer.checkpoint();
        if (foreignChange == 'timer') {
          otherNotifier.updateDraft({'timer': newerTimer});
        } else {
          otherNotifier.addExercise(exercise.copyWith(id: 'extra'));
          otherNotifier.updateExerciseDraft(
            'extra',
            {'reps': '17'},
            extra: true,
            side: 'right',
          );
        }
        await otherNotifier.flushDraft();
        final foreignPayload = (await repo.readDraft(
          'a',
          accepted.sessionSyncId!,
        ))!;
        paused.release.complete();
        expect(await attempt, isFalse);
        expect(
          (await db.workoutDao.getSession(accepted.sessionId!))!.guidanceJson,
          jsonEncode(accepted.guidance!.toJson()),
        );
        expect(await db.select(db.syncOutbox).get(), beforeOutbox);
        expect(
          await repo.readDraft('a', accepted.sessionSyncId!),
          foreignPayload,
        );
        // Do not adopt foreign selectedIds as our own deletion baseline. A later
        // unrelated local patch must keep all foreign data in the latest row.
        n.updateDraft({'note': 'later own edit'});
        await n.flushDraft();
        final latest = (await repo.readDraft('a', accepted.sessionSyncId!))!;
        expect(latest['selectedIds'], foreignPayload['selectedIds']);
        expect(
          (latest['fields'] as Map)['timer'],
          (foreignPayload['fields'] as Map)['timer'],
        );
        expect(
          (latest['fields'] as Map)['extraForms'],
          (foreignPayload['fields'] as Map)['extraForms'],
        );
        expect(checkpointEpochs(latest), checkpointEpochs(foreignPayload));
        expect(checkpointVersions(latest), checkpointVersions(foreignPayload));
        final reload = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            exercisesRepositoryProvider.overrideWithValue(catalog),
          ],
        );
        addTearDown(reload.dispose);
        expect(
          await reload
              .read(activeWorkoutProvider.notifier)
              .resumeSession(accepted.sessionSyncId!),
          isTrue,
        );
        final restored = reload.read(activeWorkoutProvider);
        expect(restored.guidance!.toJson(), accepted.guidance!.toJson());
        expect(
          restored.draft['timer'],
          (foreignPayload['fields'] as Map)['timer'],
        );
        expect(restored.draft['note'], 'later own edit');
        if (foreignChange == 'extra') {
          expect(
            restored.selectedExercises.map((e) => e.id),
            contains('extra'),
          );
          expect(
            restored.exerciseDraft('extra', extra: true, side: 'right')['reps'],
            '17',
          );
        }
      },
    );
  }
  test(
    'active weight target refuses ID replacement without rewriting original plan',
    () async {
      final p = structure.blocks.single.prescription;
      final plan = StructuredPlan(
        criteria: structure.criteria,
        budgetSeconds: 300,
        blocks: [
          PlanBlock(
            exerciseId: 'yoga',
            section: PlanSection.main,
            prescription: PlanPrescription(
              tracking: p.tracking,
              sets: p.sets,
              workSeconds: p.workSeconds,
              restSeconds: p.restSeconds,
              transitionSeconds: p.transitionSeconds,
              weightKg: 12,
            ),
          ),
        ],
        warnings: [],
      );
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(plan));
      await n.flushDraft();
      expect(await n.guidedEvent(replacement: 'other'), isFalse);
      expect(c.read(activeWorkoutProvider).guidance!.exerciseAt(0), 'yoga');
    },
  );
  test('dirty active form cannot be silently discarded', () async {
    final n = c.read(activeWorkoutProvider.notifier);
    await n.startSession(guidance: WorkoutGuidance.start(structure));
    n.updateDraft({'reps': '9', 'side': 'left'});
    await n.flushDraft();
    expect(await n.guidedEvent(replacement: 'other'), isFalse);
    expect(c.read(activeWorkoutProvider).draft['reps'], '9');
  });
  test(
    'guidance and draft signature commit atomically before any queued draft save',
    () async {
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      await n.logSet(exercise: exercise.copyWith(id: 'yoga'), seconds: 8);
      await n.flushDraft();
      final before = c.read(activeWorkoutProvider);
      final history = await db.workoutDao.getAllSets();
      repo.delay = true;
      expect(await n.guidedEvent(replacement: 'other'), isTrue);
      final row = (await db.workoutDao.getSession(before.sessionId!))!;
      final draft = (await repo.readDraft('a', before.sessionSyncId!))!;
      expect(
        draft['guidanceSignature'],
        jsonEncode(WorkoutGuidance.tryRead(row.guidanceJson)!.toJson()),
      );
      expect(
        c.read(activeWorkoutProvider).guidance!.plan.toJson(),
        structure.toJson(),
      );
      expect(await db.workoutDao.getAllSets(), history);
      repo.release.complete();
      await n.flushDraft();
      final reload = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(reload.dispose);
      expect(
        await reload
            .read(activeWorkoutProvider.notifier)
            .resumeSession(before.sessionSyncId!),
        isTrue,
      );
      expect(
        reload.read(activeWorkoutProvider).guidance!.exerciseAt(0),
        'other',
      );
    },
  );

  test(
    'discard is targeted, retires timer token, keeps history and extra drafts on immediate reload',
    () async {
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      n.addExercise(exercise.copyWith(id: 'extra'));
      n.updateExerciseDraft(
        'extra',
        {'reps': '17'},
        extra: true,
        side: 'right',
      );
      n.updateDraft({
        'seconds': '9',
        'side': 'left',
        'timer': completedLeftTimer(),
        'variantId': '11111111-1111-4111-8111-111111111111',
        'variantLabel': 'Wariant',
        'note': 'preserve',
        'futureField': {'nested': 7},
      });
      await n.flushDraft();
      final before = c.read(activeWorkoutProvider);
      final origin = n.captureInterval(
        exercise: exercise.copyWith(id: 'yoga'),
        side: 'left',
        variantId: '11111111-1111-4111-8111-111111111111',
        variantLabel: 'Wariant',
      )!;
      expect(
        await n.guidedEvent(replacement: 'other', discardCurrentDraft: true),
        isTrue,
      );
      expect(n.isIntervalCurrent(origin), isFalse);
      final payload = (await repo.readDraft('a', before.sessionSyncId!))!;
      expect(checkpointEpochs(payload)[origin.checkpointKey], 1);
      final reload = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(reload.dispose);
      expect(
        await reload
            .read(activeWorkoutProvider.notifier)
            .resumeSession(before.sessionSyncId!),
        isTrue,
      );
      final after = reload.read(activeWorkoutProvider);
      expect(after.guidance!.plan.toJson(), before.guidance!.plan.toJson());
      expect(after.draft['timer'], isNull);
      expect(after.draft['side'], isNull);
      expect(after.draft['seconds'], isNull);
      expect(after.draft['variantId'], isNull);
      expect(after.draft['note'], 'preserve');
      expect(after.draft['futureField'], {'nested': 7});
      expect(after.draft['extraForms'], before.draft['extraForms']);
      expect(await db.workoutDao.getAllSets(), isEmpty);
    },
  );

  for (final stale in ['revision', 'signature', 'guard']) {
    test(
      'SQLite transition rejects stale $stale and rolls back outbox and draft',
      () async {
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession(guidance: WorkoutGuidance.start(structure));
        await n.flushDraft();
        final state = c.read(activeWorkoutProvider);
        final payload = (await repo.readDraft('a', state.sessionSyncId!))!;
        final row = (await db.workoutDao.getSession(state.sessionId!))!;
        final operations = await db.select(db.syncOutbox).get();
        var calls = 0;
        await expectLater(
          repo.transitionGuidance(
            sessionId: state.sessionId!,
            sessionSyncId: state.sessionSyncId!,
            accountId: 'a',
            expectedSignature: stale == 'signature'
                ? 'old'
                : jsonEncode(state.guidance!.toJson()),
            expectedRevision:
                draftRevision(payload) - (stale == 'revision' ? 1 : 0),
            guard: () => stale != 'guard' || ++calls < 5,
            slot: 0,
            replacement: 'other',
          ),
          throwsStateError,
        );
        expect(
          (await db.workoutDao.getSession(state.sessionId!))!.guidanceJson,
          row.guidanceJson,
        );
        expect(await repo.readDraft('a', state.sessionSyncId!), payload);
        expect(await db.select(db.syncOutbox).get(), operations);
      },
    );
  }

  test(
    'provider rejects form mutation during await, busy blocks duplicate and interval capture',
    () async {
      final paused = PausedTransitionRepository(db);
      c.dispose();
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(paused),
        ],
      );
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      await n.flushDraft();
      final write = n.guidedEvent(
        replacement: 'other',
        discardCurrentDraft: true,
      );
      await paused.entered.future;
      expect(
        n.captureInterval(exercise: exercise.copyWith(id: 'yoga')),
        isNull,
      );
      expect(
        await n.guidedEvent(replacement: 'other', discardCurrentDraft: true),
        isFalse,
      );
      n.updateDraft({'seconds': '19'});
      paused.release.complete();
      expect(await write, isFalse);
      await n.flushDraft();
      expect(c.read(activeWorkoutProvider).draft['seconds'], '19');
      expect(c.read(activeWorkoutProvider).guidance!.exerciseAt(0), 'yoga');
    },
  );

  test(
    'active replacement is refused while checkpoint is consumed in SQLite',
    () async {
      final paused = PausedRoundRepository(db);
      c.dispose();
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(paused),
        ],
      );
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      n.updateDraft({'side': 'left', 'timer': completedLeftTimer()});
      await n.flushDraft();
      final origin = n.captureInterval(
        exercise: exercise.copyWith(id: 'yoga'),
        side: 'left',
      )!;
      final write = n.saveIntervalRounds(origin, [
        const IntervalRound(round: 1, seconds: 10, shortened: false),
      ]);
      await paused.entered.future;
      expect(
        await n.guidedEvent(replacement: 'other', discardCurrentDraft: true),
        isFalse,
      );
      paused.release.complete();
      expect(await write, isTrue);
      expect(c.read(activeWorkoutProvider).guidance!.exerciseAt(0), 'yoga');
    },
  );

  test(
    'observer does not lose an external identical event while own transition is pending',
    () async {
      final paused = PausedTransitionRepository(db);
      c.dispose();
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(paused),
        ],
      );
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      await n.flushDraft();
      final state = c.read(activeWorkoutProvider);
      final write = n.guidedEvent(
        replacement: 'other',
        discardCurrentDraft: true,
      );
      await paused.entered.future;
      await repo.guidanceEvent(
        sessionId: state.sessionId!,
        sessionSyncId: state.sessionSyncId!,
        accountId: 'a',
        guard: () => true,
        slot: 0,
        replacement: 'other',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      paused.release.complete();
      expect(await write, isFalse);
      expect(c.read(activeWorkoutProvider).guidance!.exerciseAt(0), 'other');
      await n.flushDraft();
    },
  );

  test(
    'adding an extra during transition cannot lose its durable selection',
    () async {
      final paused = PausedTransitionRepository(db);
      c.dispose();
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(paused),
        ],
      );
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      await n.flushDraft();
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      final write = n.guidedEvent(
        replacement: 'other',
        discardCurrentDraft: true,
      );
      await paused.entered.future;
      n.addExercise(exercise.copyWith(id: 'extra'));
      paused.release.complete();
      expect(await write, isFalse);
      await n.flushDraft();
      expect(
        (await repo.readDraft('a', uuid))!['selectedIds'],
        contains('extra'),
      );
      expect(c.read(activeWorkoutProvider).guidance!.exerciseAt(0), 'yoga');
    },
  );
}
