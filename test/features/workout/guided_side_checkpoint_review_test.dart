import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import '../planner/structured_plan_persistence_test.dart' show structure;
import 'session_tracking_test.dart' show exercise;

Map<String, Object?> completedLeftTimer() {
  var now = Duration.zero;
  final timer = IntervalTimer(
    IntervalConfig(preparation: 0, work: 10, rest: 0, rounds: 1),
    clock: () => now,
  )..start();
  now = const Duration(seconds: 10);
  timer.update();
  return timer.checkpoint();
}

void main() {
  test(
    'capture and save reject checkpoint side mismatch even without UI',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(structure));
      n.updateDraft({'side': 'left', 'timer': completedLeftTimer()});
      final ex = exercise.copyWith(id: 'yoga');
      expect(n.captureInterval(exercise: ex, side: 'right'), isNull);
      final left = n.captureInterval(exercise: ex, side: 'left')!;
      n.updateDraft({'side': 'right'}); // bypass widget confirmation
      expect(n.captureInterval(exercise: ex, side: 'right'), isNull);
      expect(
        await n.saveIntervalRounds(left, [
          const IntervalRound(round: 1, seconds: 10, shortened: false),
        ]),
        isFalse,
      );
      expect(await db.workoutDao.getAllSets(), isEmpty);
      n.updateDraft({'side': 'left'});
      expect(
        n.captureInterval(
          exercise: ex,
          side: 'left',
          variantId: '00000000-0000-4000-8000-000000000001',
        ),
        isNull,
      );
    },
  );

  testWidgets(
    'reload left checkpoint; cancel side change keeps left; discard cannot save old work as right',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async =>
                const StandardMessageCodec().encodeMessage(<Object?>[null]),
          );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final ex = exercise.copyWith(id: 'yoga');
      ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          allExercisesProvider.overrideWith((ref) => Stream.value([ex])),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => const ExerciseCatalogMetadata(
              exercises: {
                'yoga': ExerciseCatalogEntry(
                  tracking: 'rounds',
                  unilateral: true,
                ),
              },
            ),
          ),
        ],
      );
      var c = makeContainer();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await tester.runAsync(() async {
          await c.read(activeWorkoutProvider.notifier).flushDraft();
          c.dispose();
          await db.close();
        });
      });
      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(
              SyncStateCompanion.insert(accountId: 'a', deviceId: 'device'),
            );
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession(guidance: WorkoutGuidance.start(structure));
        n.updateDraft({
          'side': 'left',
          'rpe': 7,
          'timer': completedLeftTimer(),
        });
        await n.flushDraft();
        final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
        c.dispose();
        c = makeContainer();
        expect(
          await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
          isTrue,
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(find.text('Prawa')));
      await tester.pumpAndSettle();
      expect(find.text('Odrzucić niezapisany timer?'), findsOneWidget);
      await tester.tap(find.text('Zachowaj'));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider).draft['side'], 'left');
      expect(c.read(activeWorkoutProvider).draft['timer'], isNotNull);
      await tester.runAsync(() => tester.tap(find.text('Prawa')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Odrzuć timer'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider).draft['side'], 'right');
      expect(c.read(activeWorkoutProvider).draft['timer'], isNull);
      await tester.ensureVisible(find.text('Timer interwałów'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Timer interwałów'));
      await tester.pumpAndSettle();
      expect(find.text('Rozpocznij interwały'), findsOneWidget);
      expect(find.text('Zapisz wykonane rundy'), findsNothing);
      expect(await tester.runAsync(() => db.workoutDao.getAllSets()), isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(
        () => c.read(activeWorkoutProvider.notifier).flushDraft(),
      );
    },
  );
}
