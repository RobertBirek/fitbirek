import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fitbirek_training/app/theme.dart';
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
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import '../../core/profile_collections_sync_test.dart' show saveProfile;
import 'session_tracking_test.dart' show exercise;
import 'package:drift/drift.dart' show Value;
import '../../helpers/min_interactive_target.dart';

void main() {
  testWidgets(
    'variant selection fills only confirmed draft; restart retains deleted choice and blocks logging',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async =>
                const StandardMessageCodec().encodeMessage(<Object?>[null]),
          );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      late ProviderContainer c;
      late String variant, base;
      late ExerciseVariantsRepository repository;
      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(
              SyncStateCompanion.insert(accountId: 'a', deviceId: 'device'),
            );
        await saveProfile(db);
        await ExercisesRepository(db).syncFromAssets();
        base = (await db.select(db.exercises).get())
            .firstWhere(
              (e) => (jsonDecode(e.sprzet) as List).contains('Hantle'),
            )
            .id;
        repository = ExerciseVariantsRepository(UserCollectionsRepository(db));
        variant = await repository.create(
          'a',
          base,
          'Pauza 2 s',
          loadKg: 12,
          pauseSeconds: 2,
        );
        final ex = exercise.copyWith(id: base, sprzet: ['Hantle']);
        c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            allExercisesProvider.overrideWith((ref) => Stream.value([ex])),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => ExerciseCatalogMetadata(
                exercises: {
                  base: const ExerciseCatalogEntry(
                    tracking: 'reps',
                    unilateral: false,
                  ),
                },
              ),
            ),
          ],
        );
        await c
            .read(activeWorkoutProvider.notifier)
            .startSession(
              guidance: WorkoutGuidance.start(
                StructuredPlan(
                  criteria: const ExerciseFilters(),
                  budgetSeconds: 600,
                  warnings: [],
                  blocks: [
                    PlanBlock(
                      exerciseId: base,
                      section: PlanSection.main,
                      prescription: const PlanPrescription(
                        tracking: 'reps',
                        sets: 2,
                        reps: 8,
                        workSeconds: 24,
                        restSeconds: 60,
                        transitionSeconds: 5,
                      ),
                    ),
                  ],
                ),
              ),
            );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final targetSemantics = tester.ensureSemantics();
      try {
        for (final width in [1280.0, 375.0, 320.0]) {
          for (final scale in [1.0, 2.0]) {
            tester.view.physicalSize = Size(width, 1000);
            tester.view.devicePixelRatio = 1;
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: c,
                child: MaterialApp(
                  theme: FitBirekTheme.dark,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      viewInsets: EdgeInsets.only(bottom: scale == 2 ? 180 : 0),
                    ),
                    child: child!,
                  ),
                  home: const ActiveSessionPage(),
                ),
              ),
            );
            await tester.pumpAndSettle();
            tester
                .state<ScrollableState>(
                  find
                      .byWidgetPredicate(
                        (w) =>
                            w is Scrollable &&
                            w.axisDirection == AxisDirection.down,
                      )
                      .first,
                )
                .position
                .jumpTo(0);
            await tester.pumpAndSettle();
            final target = find.widgetWithText(
              OutlinedButton,
              'Wariant: Bazowy ▾',
            );
            await tester.scrollUntilVisible(
              target,
              150,
              scrollable: find
                  .byWidgetPredicate(
                    (w) =>
                        w is Scrollable &&
                        w.axisDirection == AxisDirection.down,
                  )
                  .first,
            );
            await tester.pumpAndSettle();
            expectMinInteractiveTarget(tester, target);
          }
        }
      } finally {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        targetSemantics.dispose();
        debugDefaultTargetPlatformOverride = null;
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: ActiveSessionPage()),
        ),
      );
      await tester.pumpAndSettle();
      final semantics = tester.ensureSemantics();
      final variantButton = find.descendant(
        of: find.byTooltip('Wariant wykonania'),
        matching: find.byType(OutlinedButton),
      );
      expect(variantButton, findsOneWidget);
      expect(tester.getSize(variantButton).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(variantButton).label,
        contains('Wariant: Bazowy'),
      );
      semantics.dispose();
      await tester.tap(find.byTooltip('Wariant wykonania'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pauza 2 s').last);
      await tester.pumpAndSettle();
      expect(find.text('Zastąpić szkic wariantu?'), findsOneWidget);
      await tester.tap(find.text('Zachowaj'));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider).draft['variantId'], isNull);
      await tester.tap(find.byTooltip('Wariant wykonania'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pauza 2 s').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zastąp'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Ciężar (kg)'))
            .controller!
            .text,
        '12.0',
      );
      expect(c.read(activeWorkoutProvider).draft['variantId'], variant);
      expect(await tester.runAsync(() => db.workoutDao.getAllSets()), isEmpty);
      final id = c.read(activeWorkoutProvider).sessionSyncId!;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await c.read(activeWorkoutProvider.notifier).flushDraft();
        await repository.delete('a', variant);
        c.read(activeWorkoutProvider.notifier).discardSession();
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        expect(
          await c.read(activeWorkoutProvider.notifier).resumeSession(id),
          isTrue,
        );
      });
      // Recreate form exactly as after a reload, not the previous State object.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: ActiveSessionPage()),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider).draft['variantId'], variant);
      expect(find.textContaining('Zapis zablokowany'), findsOneWidget);
      await tester.ensureVisible(find.text('Seria wykonana (0)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seria wykonana (0)'));
      await tester.pump();
      expect(await tester.runAsync(() => db.workoutDao.getAllSets()), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  test(
    'interval origin captures variant and writes no PR or autosaved rounds',
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
          .insert(
            SyncStateCompanion.insert(accountId: 'a', deviceId: 'device'),
          );
      await saveProfile(db);
      await ExercisesRepository(db).syncFromAssets();
      final base = (await db.select(db.exercises).get()).first;
      final repository = ExerciseVariantsRepository(
        UserCollectionsRepository(db),
      );
      final id = await repository.create('a', base.id, 'Rundy');
      final notifier = c.read(activeWorkoutProvider.notifier);
      await notifier.startSession();
      final origin = notifier.captureInterval(
        exercise: exercise.copyWith(id: base.id),
        variantId: id,
        variantLabel: 'Rundy',
      )!;
      expect(await db.select(db.setsLog).get(), isEmpty);
      expect(
        await notifier.saveIntervalRounds(origin, [
          const IntervalRound(round: 1, seconds: 15, shortened: false),
        ]),
        isTrue,
      );
      expect((await db.select(db.setsLog).getSingle()).variantId, id);
      expect((await db.select(db.personalRecords).get()), isEmpty);
      final rejected = notifier.captureInterval(
        exercise: exercise.copyWith(id: base.id),
        variantId: id,
        variantLabel: 'Rundy',
      )!;
      await repository.delete('a', id);
      await expectLater(
        notifier.saveIntervalRounds(rejected, [
          const IntervalRound(round: 1, seconds: 15, shortened: false),
        ]),
        throwsStateError,
      );
      expect(await db.select(db.setsLog).get(), hasLength(1));
      expect(
        (await db.select(db.syncOutbox).get()).where(
          (o) => o.entityType == 'personalRecord',
        ),
        isEmpty,
      );
      await db
          .update(db.syncState)
          .write(const SyncStateCompanion(offlineAccess: Value(false)));
    },
  );
}
