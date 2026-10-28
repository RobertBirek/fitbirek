import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/widgets/primary_button.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'session_tracking_test.dart' show exercise;
import 'per_set_guidance_provider_test.dart' show ramp;
import 'active_replacement_safety_test.dart' show PausedBaselineRepository;

void main() {
  for (final timed in [false, true]) {
    testWidgets(
      'old mounted warmup callback cannot impersonate the newly selected working target: timed=$timed',
      (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(
              'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
              (_) async =>
                  const StandardMessageCodec().encodeMessage(<Object?>[null]),
            );
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            allExercisesProvider.overrideWith(
              (ref) => Stream.value([exercise]),
            ),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => ExerciseCatalogMetadata(
                exercises: {
                  exercise.id: ExerciseCatalogEntry(
                    tracking: timed ? 'time' : 'reps',
                    unilateral: false,
                  ),
                },
              ),
            ),
          ],
        );
        addTearDown(() async {
          c.dispose();
          await db.close();
        });
        late ActiveWorkoutNotifier n;
        await tester.runAsync(() async {
          n = c.read(activeWorkoutProvider.notifier);
          await db
              .into(db.syncState)
              .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
          await n.startSession(
            guidance: WorkoutGuidance.start(ramp(time: timed)),
          );
          n.addExercise(exercise);
          await n.flushDraft();
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
        await tester.pumpAndSettle();
        final save = find.widgetWithText(
          PrimaryButton,
          timed ? 'Zapisz czas (0)' : 'Seria wykonana (0)',
        );
        await tester.scrollUntilVisible(
          save,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final oldSave = tester.widget<PrimaryButton>(save).onPressed!;
        final before = await tester.runAsync(
          () => db.select(db.syncOutbox).get(),
        );
        await tester.runAsync(() async {
          expect(n.selectGuidedTarget('work'), isTrue);
          // No pump: A still owns its controls, while the notifier already holds B.
          oldSave();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        final sets = await tester.runAsync(() => db.select(db.setsLog).get());
        expect(sets, isEmpty);
        expect(c.read(activeWorkoutProvider).guidance!.events, isEmpty);
        expect(
          await tester.runAsync(() => db.select(db.personalRecords).get()),
          isEmpty,
        );
        expect(
          await tester.runAsync(() => db.select(db.syncOutbox).get()),
          before,
        );

        // A current callback still confirms the visible, independent B values.
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          save,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final currentSave = tester.widget<PrimaryButton>(save).onPressed!;
        await tester.runAsync(() async {
          currentSave();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();
        final actual = await tester.runAsync(
          () => db.select(db.setsLog).getSingle(),
        );
        expect(actual!.setRole, 'working');
        expect(actual.ciezarKg, 20);
        expect(actual.powtorzenia, timed ? isNull : 8);
        expect(actual.czasSekund, timed ? 40 : isNull);
        expect(
          c.read(activeWorkoutProvider).guidance!.events.single['targetId'],
          'work',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  test(
    'timer queue barrier stays outside SQLite and revalidates a cancelled origin',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = PausedBaselineRepository(db);
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() async {
        if (!repo.release.isCompleted) repo.release.complete();
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(ramp(time: true)));
      n.addExercise(exercise);
      await n.flushDraft();
      final outbox = await db.select(db.syncOutbox).get();
      repo.armed = true;
      expect(n.selectGuidedTarget('work'), isTrue);
      final origin = n.captureInterval(exercise: exercise)!;
      final saving = n.saveIntervalRounds(origin, const [
        IntervalRound(round: 1, seconds: 40, shortened: false),
      ]);
      await repo.entered.future;
      // A blocked own patch must not own the SQLite transaction while flushing.
      expect(
        await db.select(db.setsLog).get().timeout(const Duration(seconds: 5)),
        isEmpty,
      );
      n.discardSession();
      repo.release.complete();
      expect(await saving, isFalse);
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(await db.select(db.syncOutbox).get(), outbox);
    },
  );

  test(
    'own timer barrier does not adopt a foreign checkpoint version',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      final foreign = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        foreign.dispose();
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(ramp(time: true)));
      n.addExercise(exercise);
      expect(n.selectGuidedTarget('work'), isTrue);
      await n.flushDraft();
      final oldOrigin = n.captureInterval(exercise: exercise)!;
      final other = foreign.read(activeWorkoutProvider.notifier);
      expect(
        await other.resumeSession(c.read(activeWorkoutProvider).sessionSyncId!),
        isTrue,
      );
      final freshOrigin = other.captureInterval(exercise: exercise)!;
      final timer = IntervalTimer(
        IntervalConfig(preparation: 0, work: 40, rest: 0, rounds: 1),
      )..start();
      expect(
        other.updateIntervalCheckpoint(freshOrigin, timer.checkpoint()),
        isTrue,
      );
      await other.flushDraft();
      final before =
          (await db.select(db.workoutDrafts).getSingle()).payloadJson;
      final outbox = await db.select(db.syncOutbox).get();
      expect(
        await n.saveIntervalRounds(oldOrigin, const [
          IntervalRound(round: 1, seconds: 40, shortened: false),
        ]),
        isFalse,
      );
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(
        (await db.select(db.workoutDrafts).getSingle()).payloadJson,
        before,
      );
      expect(await db.select(db.syncOutbox).get(), outbox);
      expect(n.draftSaveError, isNotNull);
    },
  );

  for (final flushControl in [false, true]) {
    for (final queuedCheckpoint in [false, true]) {
      test(
        'immediate timer consume after select B: externalFlush=$flushControl queuedCheckpoint=$queuedCheckpoint',
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
          await n.startSession(
            guidance: WorkoutGuidance.start(ramp(time: true)),
          );
          n.addExercise(exercise);
          final extra = exercise.copyWith(id: 'extra');
          n.addExercise(extra);
          final extraTimer = IntervalTimer(
            IntervalConfig(preparation: 0, work: 9, rest: 0, rounds: 2),
          )..start();
          n.updateExerciseDraft(extra.id, {
            'seconds': '9',
            'timer': extraTimer.checkpoint(),
          }, extra: true);
          await n.flushDraft();
          final before = await c
              .read(workoutRepositoryProvider)
              .readDraft('a', c.read(activeWorkoutProvider).sessionSyncId!);
          final extraBefore = jsonEncode(
            (before!['fields'] as Map)['extraForms'],
          );

          expect(n.selectGuidedTarget('work'), isTrue);
          final origin = n.captureInterval(exercise: exercise)!;
          if (queuedCheckpoint) {
            final timer = IntervalTimer(
              IntervalConfig(preparation: 0, work: 40, rest: 0, rounds: 1),
            )..start();
            expect(
              n.updateIntervalCheckpoint(origin, timer.checkpoint()),
              isTrue,
            );
          }
          if (flushControl) await n.flushDraft();
          // No auxiliary flush on the actual regression path.
          expect(
            await n.saveIntervalRounds(origin, const [
              IntervalRound(round: 1, seconds: 40, shortened: false),
            ]),
            isTrue,
          );
          expect(n.draftSaveError, isNull);
          await n.flushDraft();
          final sets = await db.select(db.setsLog).get();
          expect(sets, hasLength(1));
          expect(sets.single.setRole, 'working');
          expect(sets.single.czasSekund, 40);
          expect(
            c.read(activeWorkoutProvider).guidance!.events.single['targetId'],
            'work',
          );
          final after = await c
              .read(workoutRepositoryProvider)
              .readDraft('a', c.read(activeWorkoutProvider).sessionSyncId!);
          expect((after!['fields'] as Map)['targetId'], 'work');
          expect((after['fields'] as Map)['timer'], isNull);
          expect(
            jsonEncode((after['fields'] as Map)['extraForms']),
            extraBefore,
          );
          expect(
            await n.saveIntervalRounds(origin, const [
              IntervalRound(round: 1, seconds: 40, shortened: false),
            ]),
            isFalse,
          );
          expect(await db.select(db.setsLog).get(), hasLength(1));
        },
      );
    }
  }
}
