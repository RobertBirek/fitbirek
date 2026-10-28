import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/planner/domain/set_prescription.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'session_tracking_test.dart' show exercise;

StructuredPlan ramp({bool time = false, String? side}) => StructuredPlan(
  schemaVersion: 2,
  criteria: const ExerciseFilters(),
  budgetSeconds: 600,
  blocks: [
    PlanBlock(
      exerciseId: exercise.id,
      section: PlanSection.main,
      prescription: PlanPrescription.perSet(
        tracking: time ? 'time' : 'reps',
        transitionSeconds: 15,
        setTargets: [
          SetPrescription(
            targetId: 'warm',
            setRole: 'warmup',
            side: side,
            reps: time ? null : 12,
            seconds: time ? 20 : null,
            weightKg: 5,
            workSeconds: 36,
            restSeconds: 20,
          ),
          SetPrescription(
            targetId: 'work',
            setRole: 'working',
            side: side,
            reps: time ? null : 8,
            seconds: time ? 40 : null,
            weightKg: 20,
            workSeconds: 40,
            restSeconds: 60,
          ),
        ],
      ),
    ),
  ],
  warnings: [],
);

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  ProviderContainer fresh() =>
      ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    c = fresh();
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });
  Future<String> start({bool time = false, String? side}) async {
    final n = c.read(activeWorkoutProvider.notifier);
    await n.startSession(
      guidance: WorkoutGuidance.start(ramp(time: time, side: side)),
    );
    n.addExercise(exercise);
    await n.flushDraft();
    return c.read(activeWorkoutProvider).sessionSyncId!;
  }

  test(
    'start hydrates one exact target and its role without flattening ramp',
    () async {
      await start();
      final state = c.read(activeWorkoutProvider);
      expect(state.draft['targetId'], 'warm');
      expect(state.draft['weight'], '5.0');
      expect(state.draft['reps'], '12');
      expect(state.draft['setRole'], 'warmup');
      expect(await db.select(db.setsLog).get(), isEmpty);
    },
  );

  test(
    'fresh provider resumes then immediately logs exact warmup target',
    () async {
      final uuid = await start();
      c.dispose();
      c = fresh();
      final n = c.read(activeWorkoutProvider.notifier);
      expect(await n.resumeSession(uuid), isTrue);
      expect(
        await n.logSet(exercise: exercise, weightKg: 6, reps: 11),
        isFalse,
      );
      final sets = await db.select(db.setsLog).get();
      expect(sets, hasLength(1));
      expect(sets.single.setRole, 'warmup');
      final row = await db.workoutDao.getSession(
        c.read(activeWorkoutProvider).sessionId!,
      );
      final g = WorkoutGuidance.tryRead(row!.guidanceJson)!;
      expect(g.events.single['targetId'], 'warm');
      expect(
        sets.single.powtorzenia,
        11,
        reason: 'deviation is real, not corrected to 12',
      );
      expect(await db.select(db.personalRecords).get(), isEmpty);
      await n.flushDraft();
      c.dispose();
      c = fresh();
      expect(
        await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
        isTrue,
      );
      expect(c.read(activeWorkoutProvider).draft['targetId'], 'warm');
      final before = (await db.syncDao.pendingOperations()).length;
      await c
          .read(activeWorkoutProvider.notifier)
          .logSet(exercise: exercise, reps: 11);
      expect(await db.select(db.setsLog).get(), hasLength(1));
      expect((await db.syncDao.pendingOperations()).length, before);
    },
  );

  test(
    'fresh provider immediate skip records skippedTarget, not performed',
    () async {
      final uuid = await start();
      c.dispose();
      c = fresh();
      final n = c.read(activeWorkoutProvider.notifier);
      expect(await n.resumeSession(uuid), isTrue);
      expect(await n.guidedEvent(), isTrue);
      final row = await db.workoutDao.getSession(
        c.read(activeWorkoutProvider).sessionId!,
      );
      expect(WorkoutGuidance.tryRead(row!.guidanceJson)!.events.single, {
        'type': 'skippedTarget',
        'targetId': 'warm',
        'slotIndex': 0,
      });
      expect(await db.select(db.setsLog).get(), isEmpty);
      await n.flushDraft();
      expect(
        jsonDecode(
          (await db.select(db.workoutDrafts).getSingle()).payloadJson,
        )['guidanceSignature'],
        row.guidanceJson,
      );
    },
  );

  test(
    'guided v2 rejects multi-round timer without any set or target event',
    () async {
      await start(time: true);
      final n = c.read(activeWorkoutProvider.notifier);
      final origin = n.captureInterval(exercise: exercise)!;
      expect(
        await n.saveIntervalRounds(origin, const [
          IntervalRound(round: 1, seconds: 10, shortened: false),
          IntervalRound(round: 2, seconds: 10, shortened: false),
        ]),
        isFalse,
      );
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(c.read(activeWorkoutProvider).guidance!.events, isEmpty);
    },
  );

  test(
    'target selection preserves independent values, timer and ID on recovery',
    () async {
      final uuid = await start(time: true, side: 'both');
      final n = c.read(activeWorkoutProvider.notifier);
      n.updateDraft({'seconds': '17'});
      final origin = n.captureInterval(exercise: exercise, side: 'both')!;
      final engine = IntervalTimer(
        IntervalConfig(preparation: 0, work: 20, rest: 0, rounds: 1),
      )..start();
      expect(n.updateIntervalCheckpoint(origin, engine.checkpoint()), isTrue);
      await n.flushDraft();
      expect(n.selectGuidedTarget('work'), isTrue);
      expect(c.read(activeWorkoutProvider).draft['seconds'], '40');
      expect(c.read(activeWorkoutProvider).draft['weight'], '20.0');
      expect(c.read(activeWorkoutProvider).draft['timer'], isNull);
      expect(n.isIntervalCurrent(origin), isFalse);
      n.updateDraft({'seconds': '39'});
      expect(n.selectGuidedTarget('warm'), isTrue);
      expect(c.read(activeWorkoutProvider).draft['seconds'], '17');
      expect(c.read(activeWorkoutProvider).draft['timer'], isNotNull);
      await n.flushDraft();
      c.dispose();
      c = fresh();
      final restored = c.read(activeWorkoutProvider.notifier);
      expect(await restored.resumeSession(uuid), isTrue);
      final current = c.read(activeWorkoutProvider);
      expect(current.draft['targetId'], 'warm');
      expect(current.draft['seconds'], '17');
      final recoveredOrigin = restored.captureInterval(
        exercise: exercise,
        side: 'both',
      )!;
      expect(recoveredOrigin.targetId, 'warm');
      expect(recoveredOrigin.checkpointKey, contains('warm'));
      expect(
        await restored.saveIntervalRounds(recoveredOrigin, const [
          IntervalRound(round: 1, seconds: 17, shortened: true),
        ]),
        isTrue,
      );
      await restored.flushDraft();
      expect((await db.select(db.setsLog).getSingle()).setRole, 'warmup');
      c.dispose();
      c = fresh();
      expect(
        await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
        isTrue,
      );
      expect(c.read(activeWorkoutProvider).draft['timer'], isNull);
      expect(
        c.read(activeWorkoutProvider.notifier).selectGuidedTarget('work'),
        isTrue,
      );
      expect(c.read(activeWorkoutProvider).draft['seconds'], '39');
    },
  );

  test(
    'left cannot confirm both; stale target, double tap and foreign view do not consume another',
    () async {
      final uuid = await start(side: 'both');
      final n = c.read(activeWorkoutProvider.notifier);
      await n.logSet(exercise: exercise, reps: 12, side: 'left');
      expect(await db.select(db.setsLog).get(), isEmpty);
      final foreign = fresh();
      addTearDown(foreign.dispose);
      final stale = foreign.read(activeWorkoutProvider.notifier);
      expect(await stale.resumeSession(uuid), isTrue);
      final first = n.logSet(exercise: exercise, reps: 11, side: 'both');
      await n.logSet(exercise: exercise, reps: 11, side: 'both');
      await first;
      expect(await db.select(db.setsLog).get(), hasLength(1));
      await stale.logSet(exercise: exercise, reps: 11, side: 'both');
      expect(await db.select(db.setsLog).get(), hasLength(1));
      expect(n.selectGuidedTarget('work'), isTrue);
      await n.logSet(
        exercise: exercise,
        reps: 8,
        side: 'both',
        guidanceTargetId: 'warm',
      );
      expect(await db.select(db.setsLog).get(), hasLength(1));
      await n.logSet(
        exercise: exercise,
        reps: 7,
        side: 'both',
        guidanceTargetId: 'work',
      );
      expect((await db.select(db.setsLog).get()).map((s) => s.setRole), [
        'warmup',
        'working',
      ]);
      expect(
        c
            .read(activeWorkoutProvider)
            .guidance!
            .events
            .map((e) => e['targetId']),
        ['warm', 'work'],
      );
    },
  );
}
