import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import '../planner/structured_plan_persistence_test.dart' show structure;
import 'session_tracking_test.dart' show exercise;

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.syncState)
        .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
    c = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  test('repeated start keeps UUID, guidance, draft and actual sets', () async {
    final n = c.read(activeWorkoutProvider.notifier);
    await n.startSession(guidance: WorkoutGuidance.start(structure));
    await n.logSet(exercise: exercise.copyWith(id: 'yoga'), seconds: 12);
    n.updateDraft({'reps': '9', 'side': 'left'});
    await n.flushDraft();
    final before = c.read(activeWorkoutProvider);
    final operations = (await db.syncDao.pendingOperations()).length;
    await n.startSession();
    final after = c.read(activeWorkoutProvider);
    expect(after.sessionSyncId, before.sessionSyncId);
    expect(after.guidance, before.guidance);
    expect(after.draft, before.draft);
    expect(await db.select(db.workoutSessions).get(), hasLength(1));
    expect(await db.select(db.setsLog).get(), hasLength(1));
    expect((await db.syncDao.pendingOperations()).length, operations);
  });

  test(
    'fresh notifier refuses start while persisted recovery awaits choice',
    () async {
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      await n.flushDraft();
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      c.dispose();
      c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      final fresh = c.read(activeWorkoutProvider.notifier);
      await expectLater(fresh.startSession(), throwsStateError);
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await fresh.resumeSession(uuid), isTrue);
      expect(c.read(activeWorkoutProvider).sessionSyncId, uuid);
    },
  );

  test(
    'A B A and reload preserve exact form and paused checkpoint without logs',
    () async {
      final plan = StructuredPlan(
        criteria: structure.criteria,
        budgetSeconds: 300,
        blocks: [
          structure.blocks.single,
          PlanBlock(
            exerciseId: 'other',
            section: PlanSection.main,
            prescription: structure.blocks.single.prescription,
          ),
        ],
        warnings: [],
      );
      var n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(plan));
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      var elapsed = Duration.zero;
      final timer = IntervalTimer(
        IntervalConfig(preparation: 0, work: 30, rest: 0, rounds: 1),
        clock: () => elapsed,
      )..start();
      elapsed = const Duration(seconds: 7);
      timer.update();
      n.updateDraft({
        'reps': '9',
        'weight': '12',
        'side': 'left',
        'rpe': 8,
        'timer': timer.checkpoint(),
      });
      final checkpoint = c.read(activeWorkoutProvider).draft['timer'];
      expect(n.moveGuided(0), isTrue);
      expect(c.read(activeWorkoutProvider).draft['reps'], '9');
      expect(n.moveGuided(1), isTrue);
      expect(c.read(activeWorkoutProvider).draft['timer'], isNull);
      n.updateDraft({'reps': '4', 'side': 'right'});
      expect(n.moveGuided(0), isTrue);
      expect(c.read(activeWorkoutProvider).draft['reps'], '9');
      expect(c.read(activeWorkoutProvider).draft['side'], 'left');
      expect(c.read(activeWorkoutProvider).draft['timer'], checkpoint);
      n.moveGuided(1);
      await n.flushDraft();
      c.dispose();
      c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      n = c.read(activeWorkoutProvider.notifier);
      expect(await n.resumeSession(uuid), isTrue);
      expect(c.read(activeWorkoutProvider).draft['reps'], '4');
      n.moveGuided(0);
      expect(c.read(activeWorkoutProvider).draft['weight'], '12');
      final restored = IntervalTimer.restore(
        Map<String, dynamic>.from(
          c.read(activeWorkoutProvider).draft['timer'] as Map,
        ),
        clock: () => elapsed,
      );
      elapsed = const Duration(days: 1);
      restored.update();
      expect(restored.checkpoint()['elapsedMicros'], 7000000);
      expect(restored.checkpoint()['paused'], isTrue);
      await n.flushDraft();
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(await db.select(db.setsLog).get(), isEmpty);
      final origin = n.captureInterval(
        exercise: exercise.copyWith(id: 'yoga'),
        side: 'left',
      )!;
      expect(
        await n.saveIntervalRounds(origin, [
          const IntervalRound(round: 1, seconds: 7, shortened: true),
        ]),
        isTrue,
      );
      n.moveGuided(1);
      n.moveGuided(0);
      expect(
        n.selectGuidedIdentity('yoga', side: 'right', variantId: null),
        isTrue,
      );
      expect(
        n.selectGuidedIdentity('yoga', side: 'left', variantId: null),
        isTrue,
      );
      await n.flushDraft();
      expect(c.read(activeWorkoutProvider).draft['timer'], isNull);
      expect(await db.select(db.setsLog).get(), hasLength(1));
      c.dispose();
      c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      expect(
        await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
        isTrue,
      );
      expect(c.read(activeWorkoutProvider).draft['timer'], isNull);
      expect(await db.select(db.setsLog).get(), hasLength(1));
    },
  );

  test(
    'block navigation keeps variant identity and replacement never borrows another exercise form',
    () async {
      final plan = StructuredPlan(
        criteria: structure.criteria,
        budgetSeconds: 300,
        blocks: [
          structure.blocks.single,
          PlanBlock(
            exerciseId: 'other',
            section: PlanSection.main,
            prescription: structure.blocks.single.prescription,
          ),
        ],
        warnings: [],
      );
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(plan));
      n.updateDraft({
        'variantId': '11111111-1111-4111-8111-111111111111',
        'variantLabel': 'A',
        'side': 'left',
        'reps': '9',
      });
      n.moveGuided(1);
      n.updateDraft({
        'variantId': '22222222-2222-4222-8222-222222222222',
        'variantLabel': 'B',
        'side': 'right',
        'reps': '4',
      });
      n.moveGuided(0);
      expect(c.read(activeWorkoutProvider).draft['variantLabel'], 'A');
      expect(c.read(activeWorkoutProvider).draft['side'], 'left');
      await n.flushDraft();
      expect(
        await n.guidedEvent(
          replacement: 'replacement',
          discardCurrentDraft: true,
        ),
        isTrue,
      );
      expect(c.read(activeWorkoutProvider).draft['reps'], isNull);
      n.moveGuided(1);
      expect(c.read(activeWorkoutProvider).draft['variantLabel'], 'B');
      expect(c.read(activeWorkoutProvider).draft['side'], 'right');
      n.moveGuided(0);
      expect(c.read(activeWorkoutProvider).draft['variantId'], isNull);
      await n.flushDraft();
      expect(await db.select(db.setsLog).get(), isEmpty);
    },
  );
}
