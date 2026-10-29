import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/interval_timer_screen.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'per_set_guidance_provider_test.dart' show ramp;
import 'session_tracking_test.dart' show exercise;

Map<String, dynamic> checkpoint(int seconds) => {
  'schemaVersion': 1,
  'config': {'preparation': 0, 'work': seconds, 'rest': 0, 'rounds': 1},
  'phase': 'work',
  'round': 1,
  'paused': true,
  'elapsedMicros': 17000000,
  'results': <dynamic>[],
};

void main() {
  test(
    'engine and restore require explicit target context, never serialized authority',
    () {
      for (final seconds in [3601, 4000, 5400]) {
        expect(
          () =>
              IntervalConfig(preparation: 0, work: seconds, rest: 0, rounds: 1),
          throwsArgumentError,
        );
        final config = IntervalConfig(
          preparation: 0,
          work: seconds,
          rest: 0,
          rounds: 1,
          guidedTarget: true,
        );
        expect(config.work, seconds);
        expect(
          () => IntervalTimer.restore(checkpoint(seconds)),
          throwsFormatException,
        );
        final timer = IntervalTimer.restore(
          checkpoint(seconds),
          guidedTarget: true,
        );
        expect(timer.config.work, seconds);
        expect(timer.checkpoint().keys, isNot(contains('guidedTarget')));
        expect(
          (timer.checkpoint()['config'] as Map).keys,
          isNot(contains('guidedTarget')),
        );
      }
      expect(
        () => IntervalConfig(
          preparation: 0,
          work: 5401,
          rest: 0,
          rounds: 1,
          guidedTarget: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => IntervalConfig(
          preparation: 0,
          work: 10,
          rest: 0,
          rounds: 2,
          guidedTarget: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => IntervalTimer.restore(checkpoint(5401), guidedTarget: true),
        throwsFormatException,
      );
      final legacy = IntervalTimer.restore(checkpoint(3600)).checkpoint();
      expect(legacy['config'], checkpoint(3600)['config']);
    },
  );
  for (final seconds in [3601, 4000, 5400]) {
    testWidgets(
      'guided target $seconds starts without editing and saves no work automatically',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: IntervalTimerScreen(
              label: 'Cel roboczy',
              singleRound: true,
              initialWorkSeconds: seconds,
            ),
          ),
        );
        await tester.ensureVisible(find.text('Rozpocznij interwały'));
        await tester.tap(find.text('Rozpocznij interwały'));
        await tester.pump();
        expect(find.text('Runda 1 / 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('manual single round still rejects 3601', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IntervalTimerScreen(label: 'EXTRA', initialWorkSeconds: 3601),
      ),
    );
    await tester.enterText(find.byKey(const Key('rounds')), '1');
    await tester.ensureVisible(find.text('Rozpocznij interwały'));
    await tester.tap(find.text('Rozpocznij interwały'));
    await tester.pump();
    expect(find.text('Runda 1 / 1'), findsNothing);
    expect(find.textContaining('3600'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'guided input rejects 5401 and completion still requires explicit save',
    (tester) async {
      var now = Duration.zero;
      final checkpoints = <Map<String, Object?>?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: IntervalTimerScreen(
            label: 'Cel',
            singleRound: true,
            initialWorkSeconds: 5401,
            clock: () => now,
            onCheckpoint: checkpoints.add,
          ),
        ),
      );
      await tester.ensureVisible(find.text('Rozpocznij interwały'));
      await tester.tap(find.text('Rozpocznij interwały'));
      await tester.pump();
      expect(find.textContaining('5400'), findsWidgets);
      expect(checkpoints, isEmpty);
      await tester.enterText(find.byKey(const Key('work')), '4000');
      await tester.enterText(find.byKey(const Key('preparation')), '0');
      await tester.ensureVisible(find.text('Rozpocznij interwały'));
      await tester.tap(find.text('Rozpocznij interwały'));
      await tester.pump();
      // Sample often enough not to trigger the intentional unobserved-gap pause.
      for (var i = 0; i < 2000; i++) {
        now += const Duration(seconds: 2);
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.textContaining('Runda 1: 4000 s'), findsOneWidget);
      expect(find.text('Zapisz wykonane rundy'), findsOneWidget);
      expect(find.byType(IntervalTimerScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final restart in [false, true]) {
    test(
      'long target checkpoint persists, A-B-A and fresh resume immediate save restart=$restart',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        ProviderContainer fresh() => ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );
        var container = fresh();
        addTearDown(() async {
          container.dispose();
          await db.close();
        });
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        final json = ramp(time: true).toJson();
        final targets =
            (((json['blocks'] as List).first as Map)['prescription']
                    as Map)['setTargets']
                as List;
        (targets.first as Map)['seconds'] =
            4000; // estimate remains36, not timer4000
        final notifier = container.read(activeWorkoutProvider.notifier);
        await notifier.startSession(
          guidance: WorkoutGuidance.start(StructuredPlan.fromJson(json)),
        );
        notifier.addExercise(exercise);
        await notifier.flushDraft();
        final id = container.read(activeWorkoutProvider).sessionSyncId!;
        final origin = notifier.captureInterval(exercise: exercise)!;
        expect(
          notifier.updateIntervalCheckpoint(origin, checkpoint(4000)),
          true,
        );
        await notifier.flushDraft();
        final payload =
            jsonDecode(
                  (await db.select(db.workoutDrafts).getSingle()).payloadJson,
                )
                as Map<String, dynamic>;
        for (final fault in [
          'signature',
          'target',
          'side',
          'variant',
          'slot',
          'exercise',
          'extra',
        ]) {
          final corrupt =
              jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
          final fields = corrupt['fields'] as Map;
          final binding = fields['timerBinding'] as Map;
          switch (fault) {
            case 'signature':
              corrupt['guidanceSignature'] = null;
            case 'target':
              fields['targetId'] = 'missing';
              binding['targetId'] = 'missing';
            case 'side':
              binding['side'] = 'left';
            case 'variant':
              binding['variantId'] = 'other';
            case 'slot':
              binding['slotIndex'] = 1;
            case 'exercise':
              binding['exerciseId'] = 'foreign';
            case 'extra':
              binding['extra'] = true;
          }
          expect(
            () => validateWorkoutDraft(corrupt),
            throwsFormatException,
            reason: fault,
          );
        }
        expect(notifier.selectGuidedTarget('work'), true);
        expect(
          notifier.updateIntervalCheckpoint(origin, checkpoint(4000)),
          false,
        );
        expect(
          await notifier.saveIntervalRounds(origin, const [
            IntervalRound(round: 1, seconds: 4000, shortened: false),
          ]),
          false,
        );
        expect(notifier.selectGuidedTarget('warm'), true);
        await notifier.flushDraft();
        final before =
            (await db.select(db.workoutDrafts).getSingle()).payloadJson;
        expect(before, contains('4000'));
        container.dispose();
        container = fresh();
        final restored = container.read(activeWorkoutProvider.notifier);
        expect(await restored.resumeSession(id, restartSegment: restart), true);
        final draft = container.read(activeWorkoutProvider).draft;
        expect(draft['targetId'], 'warm');
        expect((draft['timer'] as Map)['config'], checkpoint(4000)['config']);
        expect(
          (draft['timer'] as Map)['elapsedMicros'],
          restart ? 0 : 17000000,
        );
        final resumed = restored.captureInterval(exercise: exercise)!;
        expect(
          await restored.saveIntervalRounds(resumed, const [
            IntervalRound(round: 1, seconds: 4100, shortened: false),
          ]),
          true,
        );
        expect(
          await restored.saveIntervalRounds(resumed, const [
            IntervalRound(round: 1, seconds: 4100, shortened: false),
          ]),
          false,
        );
        final sets = await db.select(db.setsLog).get();
        expect(sets, hasLength(1));
        expect(sets.single.czasSekund, 4100);
        expect(sets.single.setRole, 'warmup');
        final session = await db.select(db.workoutSessions).getSingle();
        final guidance = WorkoutGuidance.tryRead(session.guidanceJson)!;
        expect(guidance.events.single['targetId'], 'warm');
        expect(guidance.events.single['setSyncId'], sets.single.syncId);
        final outbox = await db.select(db.syncOutbox).get();
        expect(
          outbox.any((o) => o.payloadJson.contains(sets.single.syncId)),
          true,
        );
        expect(
          guidance.plan.blocks.first.prescription.setTargets.first.seconds,
          4000,
        );
        expect(
          guidance.plan.blocks.first.prescription.setTargets.first.workSeconds,
          36,
        );
      },
    );
  }

  test(
    'manual long result and forged EXTRA checkpoint are rejected without mutation',
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
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession();
      n.addExercise(exercise);
      await n.flushDraft();
      final origin = n.captureInterval(exercise: exercise)!;
      expect(
        await n.saveIntervalRounds(origin, const [
          IntervalRound(round: 1, seconds: 4000, shortened: false),
        ]),
        false,
      );
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(
        () => validateWorkoutDraft({
          'schemaVersion': 1,
          'currentSlot': 0,
          'selectedIds': [exercise.id],
          'fields': {
            'extraForms': {
              jsonEncode(['extra', 'session', exercise.id, null, null]): {
                'targetId': 'warm',
                'timer': checkpoint(4000),
                'timerBinding': {
                  'sessionSyncId': 'session',
                  'exerciseId': exercise.id,
                  'extra': true,
                  'targetId': 'warm',
                },
              },
            },
          },
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'archived long timer survives replacement without granting current or EXTRA authority',
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
      final json = ramp(time: true).toJson();
      final targets =
          (((json['blocks'] as List).first as Map)['prescription']
                  as Map)['setTargets']
              as List;
      for (final target in targets.cast<Map>()) {
        target['weightKg'] = null;
      }
      (targets.first as Map)['seconds'] = 4000;
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(
        guidance: WorkoutGuidance.start(StructuredPlan.fromJson(json)),
      );
      n.addExercise(exercise);
      await n.flushDraft();
      final origin = n.captureInterval(exercise: exercise)!;
      expect(n.updateIntervalCheckpoint(origin, checkpoint(4000)), true);
      expect(n.selectGuidedTarget('work'), true);
      await n.flushDraft();
      expect(
        await n.guidedEvent(replacement: 'extra', discardCurrentDraft: true),
        true,
      );
      await n.flushDraft();
      final payload =
          jsonDecode(
                (await db.select(db.workoutDrafts).getSingle()).payloadJson,
              )
              as Map<String, dynamic>;
      final fields = payload['fields'] as Map;
      final archive = fields['guidedForms'] as Map;
      expect(archive.toString(), contains('4000'));
      expect(n.updateIntervalCheckpoint(origin, checkpoint(4000)), false);
      final old = archive.values.cast<Map>().singleWhere(
        (f) => f['targetId'] == 'warm',
      );
      final forged = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
      (forged['fields'] as Map).addAll(old);
      expect(() => validateWorkoutDraft(forged), throwsFormatException);
      expect(await db.select(db.setsLog).get(), isEmpty);
    },
  );
}
