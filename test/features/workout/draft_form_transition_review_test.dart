import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/data/exercise_variants_repository.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'guided_extras_review_test.dart' show reviewContainer, reviewPlan, extra;
import 'guided_side_checkpoint_review_test.dart' show completedLeftTimer;
import '../../core/profile_collections_sync_test.dart' show saveProfile;
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';

StructuredPlan guidedPlan(String id) => StructuredPlan(
  criteria: reviewPlan().criteria,
  budgetSeconds: 300,
  blocks: [
    PlanBlock(
      exerciseId: id,
      section: PlanSection.main,
      prescription: const PlanPrescription(
        tracking: 'reps',
        sets: 2,
        reps: 10,
        workSeconds: 30,
        restSeconds: 20,
        transitionSeconds: 10,
      ),
    ),
    reviewPlan().blocks.first,
  ],
  warnings: [],
);

void main() {
  for (final guided in [false, true]) {
    _identityTests(guided);
  }
}

void _identityTests(bool guided) {
  testWidgets(
    'variants load exact destination, keep cancelled timer, restore defaults only for new keys guided=$guided',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async =>
                const StandardMessageCodec().encodeMessage(<Object?>[null]),
          );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      late ProviderContainer c;
      late String uuid, exerciseId, a, b;
      Future<void> drain() async {
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.runAsync(
          () => c.read(activeWorkoutProvider.notifier).flushDraft(),
        );
      }

      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        await saveProfile(db);
        final catalog = ExercisesRepository(db);
        await catalog.syncFromAssets();
        final ex = (await catalog.watchAll().first).firstWhere(
          (e) => e.sprzet.contains('Hantle'),
        );
        exerciseId = ex.id;
        final variants = ExerciseVariantsRepository(
          UserCollectionsRepository(db),
        );
        a = await variants.create('a', ex.id, 'Wariant A', loadKg: 10);
        b = await variants.create('a', ex.id, 'Wariant B', loadKg: 20);
        c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            allExercisesProvider.overrideWith((ref) => Stream.value([ex])),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => ExerciseCatalogMetadata(
                exercises: {
                  ex.id: ExerciseCatalogEntry(
                    tracking: 'reps',
                    unilateral: guided,
                  ),
                },
              ),
            ),
          ],
        );
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession(
          guidance: WorkoutGuidance.start(
            guided ? guidedPlan(ex.id) : reviewPlan(),
          ),
        );
        n.addExercise(ex);
        await n.flushDraft();
        uuid = c.read(activeWorkoutProvider).sessionSyncId!;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await tester.runAsync(() async {
          c.dispose();
          await db.close();
        });
      });
      Finder card() => find.byKey(
        ValueKey(guided ? '$uuid:0:$exerciseId' : 'extra:$uuid:$exerciseId'),
      );
      Finder field(int i) =>
          find.descendant(of: card(), matching: find.byType(TextField)).at(i);
      String value(int i) =>
          tester.widget<TextField>(field(i)).controller!.text;
      Future<void> enter(int i, String text) async {
        await tester.scrollUntilVisible(
          field(i),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(field(i));
        await tester.pumpAndSettle();
        await tester.enterText(field(i), text);
        await tester.pump();
        await drain();
      }

      Future<void> choose(String name, {bool cancel = false}) async {
        final selector = find.descendant(
          of: card(),
          matching: find.byTooltip('Wariant wykonania'),
        );
        await tester.ensureVisible(selector);
        await tester.pumpAndSettle();
        await tester.runAsync(() => tester.tap(selector));
        await tester.pumpAndSettle();
        await tester.runAsync(() => tester.tap(find.text(name).last));
        await tester.pumpAndSettle();
        expect(find.text('Zastąpić szkic wariantu?'), findsOneWidget);
        await tester.runAsync(
          () => tester.tap(find.text(cancel ? 'Zachowaj' : 'Zastąp')),
        );
        await tester.pumpAndSettle();
        await drain();
      }

      await tester.pumpAndSettle();
      if (!guided) {
        await tester.scrollUntilVisible(
          find.text('Dodatkowe ćwiczenia'),
          400,
          maxScrolls: 8,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await enter(0, '5');
      await enter(1, '9');
      await choose('Wariant A');
      expect(value(0), '10.0');
      expect(value(1), guided ? '10' : '');
      await enter(0, '12');
      await enter(1, '8');
      await tester.runAsync(() async {
        c
            .read(activeWorkoutProvider.notifier)
            .updateExerciseDraft(
              exerciseId,
              {'timer': completedLeftTimer()},
              extra: !guided,
              variantId: a,
            );
        await c.read(activeWorkoutProvider.notifier).flushDraft();
      });
      await choose('Wariant B', cancel: true);
      expect(
        guided
            ? c.read(activeWorkoutProvider).draft['timer']
            : c
                  .read(activeWorkoutProvider)
                  .exerciseDraft(
                    exerciseId,
                    extra: true,
                    variantId: a,
                  )['timer'],
        isNotNull,
      );
      await choose('Wariant B');
      expect(value(0), '20.0');
      expect(value(1), guided ? '10' : '');
      await enter(0, '22');
      await enter(1, '6');
      await choose('Wariant A');
      expect(value(0), '12');
      expect(value(1), '8');
      await choose('Bazowy (osobna historia)');
      expect(value(0), '5');
      expect(value(1), '9');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        c.read(activeWorkoutProvider.notifier).discardSession();
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
      if (!guided) {
        await tester.scrollUntilVisible(
          find.text('Dodatkowe ćwiczenia'),
          400,
          maxScrolls: 8,
          scrollable: find.byType(Scrollable).first,
        );
      }
      expect(value(0), '5');
      expect(value(1), '9');
      await choose('Wariant B');
      expect(value(0), '22');
      expect(value(1), '6');
      expect(
        guided
            ? c.read(activeWorkoutProvider).draft['timer']
            : c
                  .read(activeWorkoutProvider)
                  .exerciseDraft(
                    exerciseId,
                    extra: true,
                    variantId: a,
                  )['timer'],
        isNull,
      );
      expect(
        guided
            ? c.read(activeWorkoutProvider).draft['variantId']
            : c
                  .read(activeWorkoutProvider)
                  .extraSelection(exerciseId)['variantId'],
        b,
      );
      if (guided) {
        Future<void> side(String label) async {
          final button = find.descendant(
            of: card(),
            matching: find.text(label),
          );
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          await tester.tap(button);
          await tester.pumpAndSettle();
          await drain();
        }

        Future<void> visitOtherBlock() async {
          c.read(activeWorkoutProvider.notifier).moveGuided(1);
          await tester.pumpAndSettle();
          c.read(activeWorkoutProvider.notifier).moveGuided(0);
          await tester.pumpAndSettle();
          await drain();
        }

        await side('Lewa');
        await choose('Wariant A');
        await enter(1, '9');
        await visitOtherBlock();
        await side('Prawa');
        await choose('Wariant B');
        await enter(1, '4');
        await visitOtherBlock();
        await side('Lewa');
        await choose('Wariant A');
        expect(value(1), '9');
        expect(c.read(activeWorkoutProvider).draft['timer'], isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          c.read(activeWorkoutProvider.notifier).discardSession();
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
        expect(value(1), '9');
        await side('Prawa');
        await choose('Wariant B');
        expect(value(1), '4');
      }
      expect(await tester.runAsync(() => db.workoutDao.getAllSets()), isEmpty);
    },
  );
  testWidgets(
    'RIGHT 9 to LEFT 7 to RIGHT restores 9 and both survive a real resume guided=$guided',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async =>
                const StandardMessageCodec().encodeMessage(<Object?>[null]),
          );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      late ProviderContainer c;
      late String uuid;
      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        c = reviewContainer(db);
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession(
          guidance: WorkoutGuidance.start(
            guided ? guidedPlan(extra.id) : reviewPlan(),
          ),
        );
        n.addExercise(extra);
        await n.flushDraft();
        uuid = c.read(activeWorkoutProvider).sessionSyncId!;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await tester.runAsync(() async {
          c.dispose();
          await db.close();
        });
      });
      Finder card() => find.byKey(
        ValueKey(guided ? '$uuid:0:${extra.id}' : 'extra:$uuid:${extra.id}'),
      );
      Finder input() =>
          find.descendant(of: card(), matching: find.byType(TextField)).first;
      Future<void> drainWrites() async {
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.runAsync(
          () => c.read(activeWorkoutProvider.notifier).flushDraft(),
        );
      }

      Future<void> side(String text) async {
        final button = find.descendant(of: card(), matching: find.text(text));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.runAsync(() => tester.tap(button));
        await tester.pumpAndSettle();
        await drainWrites();
      }

      Future<void> enter(String text) async {
        await tester.ensureVisible(input());
        await tester.pumpAndSettle();
        await tester.enterText(input(), text);
        await tester.pump();
        await drainWrites();
        await tester.pumpAndSettle();
      }

      String value() => tester.widget<TextField>(input()).controller!.text;
      await tester.pumpAndSettle();
      if (!guided) {
        await tester.scrollUntilVisible(
          find.text('Dodatkowe ćwiczenia'),
          400,
          maxScrolls: 8,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await side('Prawa');
      await enter('9');
      if (guided) {
        c.read(activeWorkoutProvider.notifier).moveGuided(1);
        await tester.pumpAndSettle();
        c.read(activeWorkoutProvider.notifier).moveGuided(0);
        await tester.pumpAndSettle();
      }
      await side('Lewa');
      await enter('7');
      if (guided) {
        c.read(activeWorkoutProvider.notifier).moveGuided(1);
        await tester.pumpAndSettle();
        c.read(activeWorkoutProvider.notifier).moveGuided(0);
        await tester.pumpAndSettle();
      }
      await side('Prawa');
      expect(value(), '9');
      await tester.runAsync(
        () => c.read(activeWorkoutProvider.notifier).flushDraft(),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        c.dispose();
        c = reviewContainer(db);
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
      if (!guided) {
        await tester.scrollUntilVisible(
          find.text('Dodatkowe ćwiczenia'),
          400,
          maxScrolls: 8,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.scrollUntilVisible(
        card(),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(input());
      await tester.pumpAndSettle();
      expect(value(), '9');
      await side('Lewa');
      expect(value(), '7');
      expect(await tester.runAsync(() => db.workoutDao.getAllSets()), isEmpty);
    },
  );
}
