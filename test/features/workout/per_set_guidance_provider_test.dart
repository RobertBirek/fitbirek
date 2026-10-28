import 'dart:convert';
import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/planner/domain/set_prescription.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_repeat.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
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

class LaggingGuidanceRepository extends WorkoutRepository {
  LaggingGuidanceRepository(super.db);
  final rows = StreamController<WorkoutSessionData?>.broadcast(sync: true);
  @override
  Stream<WorkoutSessionData?> watchSession(int id) => rows.stream;
  @override
  Future<Map<String, Object?>> consumeDraftCheckpoint({
    required int sessionId,
    required String sessionSyncId,
    required String accountId,
    required String key,
    required int expectedEpoch,
    required int expectedVersion,
    required bool extra,
    required String exerciseId,
    required Map<String, Object?> fallbackPayload,
    required bool Function() guard,
  }) async {
    final result = await super.consumeDraftCheckpoint(
      sessionId: sessionId,
      sessionSyncId: sessionSyncId,
      accountId: accountId,
      key: key,
      expectedEpoch: expectedEpoch,
      expectedVersion: expectedVersion,
      extra: extra,
      exerciseId: exerciseId,
      fallbackPayload: fallbackPayload,
      guard: guard,
    );
    final row = await findSessionBySyncId(sessionSyncId);
    // Deliver the first REAL row at the narrow pending-signature boundary;
    // delay its successor until after the next explicit save has returned.
    if (WorkoutGuidance.tryRead(row?.guidanceJson)?.events.length == 1) {
      rows.add(row);
    }
    return result;
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  ProviderContainer fresh() => ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      exerciseCatalogMetadataProvider.overrideWith(
        (ref) async => ExerciseCatalogMetadata(
          exercises: {
            exercise.id: const ExerciseCatalogEntry(
              tracking: 'reps',
              unilateral: false,
            ),
          },
        ),
      ),
    ],
  );
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    c = fresh();
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
    for (final e in [exercise, exercise.copyWith(id: 'extra')]) {
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: e.id,
              nazwaPl: e.nazwaPl,
              nazwaEn: '',
              partiaGlowna: '',
              partieWspierajace: '[]',
              sprzet: '[]',
              typ: '',
              poziom: '',
              wzorzecRuchu: '',
              seriexPowtorzenia: '',
              tempo: '',
              kluczoweWskazowki: '[]',
              czesteBledy: '[]',
              progresja: '',
              regresja: '',
              zrodlo: '',
            ),
          );
    }
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
    'observed v2 replacement rehydrates an exact target that resumes and skips immediately',
    () async {
      final json = ramp().toJson();
      for (final t
          in (((json['blocks'] as List).single as Map)['prescription']
                  as Map)['setTargets']
              as List) {
        (t as Map)['weightKg'] = 0;
      }
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(
        guidance: WorkoutGuidance.start(StructuredPlan.fromJson(json)),
      );
      n.addExercise(exercise);
      await n.flushDraft();
      final active = c.read(activeWorkoutProvider);
      await c
          .read(workoutRepositoryProvider)
          .guidanceEvent(
            sessionId: active.sessionId!,
            sessionSyncId: active.sessionSyncId!,
            accountId: 'a',
            guard: () => true,
            slot: 0,
            replacement: 'extra',
          );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.read(activeWorkoutProvider).guidance!.exerciseAt(0), 'extra');
      await n.flushDraft();
      c.dispose();
      c = fresh();
      final restored = c.read(activeWorkoutProvider.notifier);
      expect(await restored.resumeSession(active.sessionSyncId!), isTrue);
      expect(c.read(activeWorkoutProvider).draft['targetId'], 'warm');
      expect(c.read(activeWorkoutProvider).draft['weight'], '0.0');
      expect(await restored.guidedEvent(), isTrue);
    },
  );

  test(
    'manual performed followed by a timer cannot replay an older deferred observer row',
    () async {
      c.dispose();
      final repo = LaggingGuidanceRepository(db);
      addTearDown(repo.rows.close);
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
        ],
      );
      await start(time: true);
      final n = c.read(activeWorkoutProvider.notifier);
      await n.logSet(exercise: exercise, seconds: 20);
      expect(n.selectGuidedTarget('work'), isTrue);
      await n.flushDraft();
      final origin = n.captureInterval(exercise: exercise)!;
      expect(
        await n.saveIntervalRounds(origin, const [
          IntervalRound(round: 1, seconds: 40, shortened: false),
        ]),
        isTrue,
      );
      expect(c.read(activeWorkoutProvider).guidance!.events, hasLength(2));
      await n.flushDraft();
      expect(
        WorkoutGuidance.tryRead(
          (await db.workoutDao.getSession(origin.sessionId))!.guidanceJson,
        )!.events,
        hasLength(2),
      );
    },
  );

  test(
    'repeating original v2 snapshot starts exact first target and permits an immediate log',
    () async {
      final repo = c.read(workoutRepositoryProvider);
      final source = await repo.startSession(
        guidance: WorkoutGuidance.start(ramp()),
        accountId: 'a',
      );
      await repo.logSet(
        sessionId: source,
        exerciseId: exercise.id,
        exerciseNamePl: exercise.nazwaPl,
        setNumber: 1,
        reps: 12,
        weightKg: 5,
        setRole: 'warmup',
        guidanceSlot: 0,
        guidanceTargetId: 'warm',
      );
      await repo.finishSession(source, DateTime.now(), accountId: 'a');
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.original);
      expect(request.preview.canStart, isTrue);
      expect(await n.confirmRepeat(request), isTrue);
      expect(c.read(activeWorkoutProvider).draft['targetId'], 'warm');
      await n.logSet(exercise: exercise, weightKg: 5, reps: 12);
      expect(
        (await repo.getSetsForSession(
          c.read(activeWorkoutProvider).sessionId!,
        )).single.setRole,
        'warmup',
      );
    },
  );

  test(
    'original v2 repeat rechecks metadata before creating its new row',
    () async {
      final repo = c.read(workoutRepositoryProvider);
      final source = await repo.startSession(
        guidance: WorkoutGuidance.start(ramp(side: 'both')),
        accountId: 'a',
      );
      await repo.logSet(
        sessionId: source,
        exerciseId: exercise.id,
        exerciseNamePl: exercise.nazwaPl,
        setNumber: 1,
        reps: 12,
        side: 'both',
        setRole: 'warmup',
        guidanceSlot: 0,
        guidanceTargetId: 'warm',
      );
      await repo.finishSession(source, DateTime.now(), accountId: 'a');
      final n = c.read(activeWorkoutProvider.notifier);
      final request = await n.previewRepeat(source, RepeatMode.original);
      final before = await db.select(db.syncOutbox).get();
      await expectLater(() => n.confirmRepeat(request), throwsStateError);
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.select(db.syncOutbox).get(), before);
    },
  );

  test(
    'fresh recovery keeps EXTRA separate, accepts multi-round warmup without target consumption',
    () async {
      final uuid = await start(time: true);
      final extra = exercise.copyWith(id: 'extra');
      final n = c.read(activeWorkoutProvider.notifier);
      n.addExercise(extra);
      n.updateExerciseDraft(extra.id, {
        'seconds': '9',
        'setRole': 'warmup',
      }, extra: true);
      await n.flushDraft();
      c.dispose();
      c = fresh();
      final restored = c.read(activeWorkoutProvider.notifier);
      expect(await restored.resumeSession(uuid), isTrue);
      expect(c.read(activeWorkoutProvider).isExtraExercise(extra.id), isTrue);
      final origin = restored.captureInterval(
        exercise: extra,
        extra: true,
        setRole: 'warmup',
      )!;
      expect(
        await restored.saveIntervalRounds(origin, const [
          IntervalRound(round: 1, seconds: 8, shortened: true),
          IntervalRound(round: 2, seconds: 9, shortened: false),
        ]),
        isTrue,
      );
      await restored.flushDraft();
      final sets = await db.select(db.setsLog).get();
      expect(sets.map((s) => s.setRole), ['warmup', 'warmup']);
      expect(c.read(activeWorkoutProvider).guidance!.events, isEmpty);
      expect(restored.captureInterval(exercise: exercise, extra: true), isNull);
      await restored.logSet(
        exercise: exercise.copyWith(id: 'foreign'),
        extra: true,
        seconds: 9,
      );
      expect(await db.select(db.setsLog).get(), hasLength(2));
      expect(c.read(activeWorkoutProvider).currentTarget!.targetId, 'warm');
    },
  );

  test(
    'foreign selected target and its timer cannot be cleared by a stale view log',
    () async {
      final uuid = await start(time: true);
      final foreign = fresh();
      addTearDown(foreign.dispose);
      final stale = foreign.read(activeWorkoutProvider.notifier);
      expect(await stale.resumeSession(uuid), isTrue);
      final n = c.read(activeWorkoutProvider.notifier);
      expect(n.selectGuidedTarget('work'), isTrue);
      final timer = IntervalTimer(
        IntervalConfig(preparation: 0, work: 40, rest: 0, rounds: 1),
      )..start();
      final origin = n.captureInterval(exercise: exercise)!;
      expect(n.updateIntervalCheckpoint(origin, timer.checkpoint()), isTrue);
      await n.flushDraft();
      final before =
          (await db.select(db.workoutDrafts).getSingle()).payloadJson;
      await stale.logSet(exercise: exercise, seconds: 20);
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(
        (await db.select(db.workoutDrafts).getSingle()).payloadJson,
        before,
      );
    },
  );

  test(
    'v2 origin cannot borrow a different selected variant even before a checkpoint exists',
    () async {
      await start(time: true, side: 'both');
      final n = c.read(activeWorkoutProvider.notifier);
      expect(
        n.selectGuidedIdentity(
          exercise.id,
          side: 'both',
          variantId: '11111111-1111-4111-8111-111111111111',
          variantLabel: 'X',
        ),
        isTrue,
      );
      expect(
        n.captureInterval(
          exercise: exercise,
          side: 'both',
          variantId: '22222222-2222-4222-8222-222222222222',
          variantLabel: 'Y',
        ),
        isNull,
      );
      expect(
        n.captureInterval(
          exercise: exercise,
          side: 'both',
          variantId: '11111111-1111-4111-8111-111111111111',
          variantLabel: 'X',
        ),
        isNotNull,
      );
    },
  );

  test(
    'foreign performed event invalidates an already open v2 origin',
    () async {
      final uuid = await start(time: true);
      final foreign = fresh();
      addTearDown(foreign.dispose);
      final stale = foreign.read(activeWorkoutProvider.notifier);
      expect(await stale.resumeSession(uuid), isTrue);
      final origin = stale.captureInterval(exercise: exercise)!;
      await c
          .read(activeWorkoutProvider.notifier)
          .logSet(exercise: exercise, seconds: 20);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(stale.isIntervalCurrent(origin), isFalse);
      expect(
        stale.updateIntervalCheckpoint(
          origin,
          IntervalTimer(
            IntervalConfig(preparation: 0, work: 20, rest: 0, rounds: 1),
          ).checkpoint(),
        ),
        isFalse,
      );
    },
  );

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
      final multi = IntervalTimer(
        IntervalConfig(preparation: 0, work: 10, rest: 0, rounds: 2),
      )..start();
      expect(n.updateIntervalCheckpoint(origin, multi.checkpoint()), isFalse);
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
