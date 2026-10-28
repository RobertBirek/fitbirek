import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/session_summary_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/features/workout/domain/interval_timer.dart';
import 'guided_side_checkpoint_review_test.dart' show completedLeftTimer;
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'interval_save_test.dart'
    show PausedRoundRepository, IntervalAuthRepository;
import 'pr_cancel_test.dart' show LocalSyncService, LocalExercisesRepository;
import '../../core/push_settings_test.dart' show FakePush;
import 'package:fitbirek_training/features/exercises/data/exercise_variants_repository.dart';
import 'package:fitbirek_training/features/exercises/data/user_collections_repository.dart';
import '../../core/profile_collections_sync_test.dart' show saveProfile;
import '../planner/structured_plan_persistence_test.dart' show structure;
import 'session_tracking_test.dart' show exercise;

final planned = exercise.copyWith(id: 'yoga', nazwaPl: 'Bieżący blok');
final future = exercise.copyWith(id: 'future', nazwaPl: 'Inny planowany blok');
final extra = exercise.copyWith(id: 'outside-plan', nazwaPl: 'Dodatkowy ruch');
StructuredPlan reviewPlan() => StructuredPlan(
  criteria: structure.criteria,
  budgetSeconds: 600,
  blocks: [
    ...structure.blocks,
    PlanBlock(
      exerciseId: future.id,
      section: PlanSection.main,
      prescription: structure.blocks.first.prescription,
    ),
  ],
  warnings: [],
);

class ReviewExercises extends ExercisesRepository {
  ReviewExercises(super.db);
  @override
  Stream<List<Exercise>> watchAll() => Stream.value([planned, future, extra]);
}

ProviderContainer reviewContainer(AppDatabase db, {String tracking = 'reps'}) =>
    ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exercisesRepositoryProvider.overrideWithValue(ReviewExercises(db)),
        allExercisesProvider.overrideWith(
          (ref) => Stream.value([planned, future, extra]),
        ),
        exerciseCatalogMetadataProvider.overrideWith(
          (ref) async => ExerciseCatalogMetadata(
            exercises: {
              planned.id: const ExerciseCatalogEntry(
                tracking: 'time',
                unilateral: true,
              ),
              future.id: const ExerciseCatalogEntry(
                tracking: 'time',
                unilateral: false,
              ),
              extra.id: ExerciseCatalogEntry(
                tracking: tracking,
                unilateral: true,
              ),
            },
          ),
        ),
      ],
    );

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  test(
    'extra strength uses the existing exact-side variant PR and outbox transaction',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = reviewContainer(db);
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      await saveProfile(db);
      final catalog = ExercisesRepository(db);
      await catalog.syncFromAssets();
      final ex = (await catalog.watchAll().first).firstWhere(
        (e) => e.sprzet.contains('Hantle'),
      );
      final variants = ExerciseVariantsRepository(
        UserCollectionsRepository(db),
      );
      final variantId = await variants.create(
        'a',
        ex.id,
        'Pauza testowa',
        pauseSeconds: 2,
      );
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(ex);
      expect(
        await n.logSet(
          exercise: ex,
          side: 'left',
          variantId: variantId,
          variantLabel: 'stara etykieta',
          reps: 8,
          weightKg: 12,
          extra: true,
        ),
        isTrue,
      );
      final actual = (await db.workoutDao.getAllSets()).single;
      expect(actual.variantId, variantId);
      expect(actual.variantLabel, 'Pauza testowa');
      expect(actual.side, 'left');
      final pr = (await db.select(db.personalRecords).get()).single;
      expect(pr.variantId, variantId);
      expect(pr.side, 'left');
      expect(c.read(activeWorkoutProvider).guidance!.events, isEmpty);
      final operations = await db.syncDao.pendingOperations();
      expect(
        operations.where((o) => o.payload['variantId'] == variantId),
        hasLength(2),
      );
    },
  );
  test(
    'extra draft namespace validates forms and separates side and variant',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = reviewContainer(db);
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      n.updateExerciseDraft(extra.id, {'reps': '7'}, extra: true, side: 'left');
      n.updateExerciseDraft(
        extra.id,
        {'reps': '9'},
        extra: true,
        side: 'right',
      );
      const variant = '00000000-0000-4000-8000-000000000001';
      n.updateExerciseDraft(
        extra.id,
        {'reps': '5', 'variantLabel': 'Pauza'},
        extra: true,
        side: 'left',
        variantId: variant,
      );
      expect(n.moveGuided(1), isTrue);
      final state = c.read(activeWorkoutProvider);
      expect(
        state.exerciseDraft(extra.id, extra: true, side: 'left')['reps'],
        '7',
      );
      expect(
        state.exerciseDraft(extra.id, extra: true, side: 'right')['reps'],
        '9',
      );
      expect(
        state.exerciseDraft(
          extra.id,
          extra: true,
          side: 'left',
          variantId: variant,
        )['reps'],
        '5',
      );
      expect(
        state.extraDraftKey(extra.id, 'left', null),
        isNot(state.extraDraftKey(extra.id, 'left', variant)),
      );
      expect(
        () => validateWorkoutDraft({
          'schemaVersion': 1,
          'currentSlot': 0,
          'selectedIds': [],
          'fields': {
            'extraForms': {
              state.extraDraftKey(extra.id, 'left', null): {'side': 'alien'},
            },
          },
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'logout during extra interval write rolls back actual sets and outbox; old epoch cannot log',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = PausedRoundRepository(db);
      final api = IntervalAuthRepository();
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(api),
          syncServiceProvider.overrideWith((ref) => LocalSyncService(db)),
          exercisesRepositoryProvider.overrideWithValue(
            LocalExercisesRepository(db),
          ),
          pushClientProvider.overrideWithValue(FakePush()),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final signedIn = Completer<void>();
      c.listen(authStateProvider, (_, next) {
        if (next.isSignedIn && !signedIn.isCompleted) signedIn.complete();
      }, fireImmediately: true);
      await signedIn.future;
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      await n.flushDraft();
      final origin = n.captureInterval(
        exercise: extra,
        side: 'left',
        extra: true,
      )!;
      final before = (await db.syncDao.pendingOperations())
          .map((o) => o.toJson())
          .toList();
      final write = n.saveIntervalRounds(origin, [
        const IntervalRound(round: 1, seconds: 10, shortened: false),
      ]);
      await repo.entered.future;
      final logout = c.read(authStateProvider.notifier).logout();
      expect(n.isIntervalCurrent(origin), isFalse);
      repo.release.complete();
      expect(await write, isFalse);
      await logout;
      await n.logSet(exercise: extra, reps: 7, extra: true);
      expect(await db.workoutDao.getAllSets(), isEmpty);
      expect(
        (await db.syncDao.pendingOperations()).map((o) => o.toJson()).toList(),
        before,
      );
    },
  );
  test(
    'explicit extra mode logs unlinked work, keeps slot/checkpoints isolated and rejects trespass',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = reviewContainer(db, tracking: 'rounds');
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      n.addExercise(future);
      n.updateDraft({'side': 'left', 'timer': completedLeftTimer()});
      n.updateExerciseDraft(
        extra.id,
        {'side': 'left', 'rpe': 6, 'timer': completedLeftTimer()},
        extra: true,
        side: 'left',
      );
      final original = c.read(activeWorkoutProvider).guidance!.toJson();
      expect(n.captureInterval(exercise: future, extra: true), isNull);
      expect(
        n.captureInterval(
          exercise: exercise.copyWith(id: 'unselected'),
          extra: true,
        ),
        isNull,
      );
      final origin = n.captureInterval(
        exercise: extra,
        side: 'left',
        extra: true,
      )!;
      expect(origin.guidanceSlot, isNull);
      expect(
        await n.saveIntervalRounds(origin, [
          const IntervalRound(round: 1, seconds: 10, shortened: false),
        ]),
        isTrue,
      );
      await n.flushDraft();
      expect(c.read(activeWorkoutProvider).guidance!.toJson(), original);
      expect(c.read(activeWorkoutProvider).currentSlot, 0);
      expect(c.read(activeWorkoutProvider).draft['timer'], isNotNull);
      expect(
        c
            .read(activeWorkoutProvider)
            .exerciseDraft(extra.id, extra: true, side: 'left')['timer'],
        isNull,
      );
      final sets = await db.workoutDao.getAllSets();
      expect(sets.single.cwiczenieId, extra.id);
      expect(sets.single.side, 'left');
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      n.discardSession();
      expect(await n.resumeSession(uuid), isTrue);
      expect(c.read(activeWorkoutProvider).isExtraExercise(extra.id), isTrue);
      final stale = n.captureInterval(
        exercise: extra,
        side: 'left',
        extra: true,
      )!;
      await n.finishSession();
      final count = (await db.syncDao.pendingOperations()).length;
      await n.logSet(exercise: extra, reps: 9, extra: true);
      expect(
        await n.saveIntervalRounds(stale, [
          const IntervalRound(round: 1, seconds: 5, shortened: true),
        ]),
        isFalse,
      );
      expect((await db.syncDao.pendingOperations()).length, count);
      expect(await db.workoutDao.getAllSets(), hasLength(1));
    },
  );
  testWidgets(
    'added non-plan exercise is loggable, resumes and appears in summary as additional',
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
      final original = reviewPlan().toJson();
      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        c = reviewContainer(db);
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
        uuid = c.read(activeWorkoutProvider).sessionSyncId!;
        n.addExercise(planned);
        n.addExercise(future);
        n.addExercise(extra);
        await n.flushDraft();
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
          await c.read(activeWorkoutProvider.notifier).flushDraft();
          c.dispose();
          await db.close();
        });
      });
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Dodatkowe ćwiczenia'),
        400,
        maxScrolls: 8,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.text('Dodatkowy ruch'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Dodatkowy ruch'), findsOneWidget);
      expect(find.text('Inny planowany blok'), findsNothing);
      final card = find.byKey(ValueKey('extra:$uuid:${extra.id}'));
      final reps = find
          .descendant(of: card, matching: find.byType(TextField))
          .first;
      await tester.ensureVisible(reps);
      await tester.runAsync(() async {
        await tester.enterText(reps, '7');
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      final save = find.descendant(
        of: card,
        matching: find.text('Seria wykonana (0)'),
      );
      await tester.ensureVisible(save);
      await tester.runAsync(() async {
        await tester.tap(save);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await c.read(activeWorkoutProvider.notifier).flushDraft();
      });
      await tester.pump();
      await tester.runAsync(() async {
        final sets = await db.workoutDao.getAllSets();
        expect(sets.single.cwiczenieId, extra.id);
        expect(sets.single.powtorzenia, 7);
        final g = c.read(activeWorkoutProvider).guidance!;
        expect(g.plan.toJson(), original);
        expect(g.events, isEmpty);
        expect(g.additionalSetIds(sets.map((s) => s.syncId)), [
          sets.single.syncId,
        ]);
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        c.dispose();
        c = reviewContainer(db);
        final n = c.read(activeWorkoutProvider.notifier);
        expect(await n.resumeSession(uuid), isTrue);
        expect(c.read(activeWorkoutProvider).currentSlot, 0);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
      });
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Dodatkowe ćwiczenia'),
        400,
        maxScrolls: 8,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.text('Dodatkowy ruch'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Dodatkowy ruch'), findsOneWidget);
      await tester.runAsync(() async {
        final n = c.read(activeWorkoutProvider.notifier),
            id = c.read(activeWorkoutProvider).sessionId!;
        await n.finishSession();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(home: SessionSummaryPage(sessionId: id)),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Dodatkowe: 1'), findsOneWidget);
      expect(find.textContaining('Dodatkowe • Dodatkowy ruch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'extra rounds card restores its own checkpoint and explicitly saves without a slot link',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async =>
                const StandardMessageCodec().encodeMessage(<Object?>[null]),
          );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      late ProviderContainer c;
      await tester.runAsync(() async {
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        c = reviewContainer(db, tracking: 'rounds');
        final n = c.read(activeWorkoutProvider.notifier);
        await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
        n.addExercise(extra);
        n.updateDraft({'side': 'left', 'timer': completedLeftTimer()});
        n.updateExerciseDraft(
          extra.id,
          {'rpe': 6, 'timer': completedLeftTimer()},
          extra: true,
          side: 'left',
        );
        await n.flushDraft();
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
          await c.read(activeWorkoutProvider.notifier).flushDraft();
          c.dispose();
          await db.close();
        });
      });
      await tester.pumpAndSettle();
      final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
      final card = find.byKey(ValueKey('extra:$uuid:${extra.id}'));
      await tester.scrollUntilVisible(
        find.text('Dodatkowe ćwiczenia'),
        400,
        maxScrolls: 8,
        scrollable: find.byType(Scrollable).first,
      );
      final timer = find.descendant(
        of: card,
        matching: find.text('Timer interwałów'),
      );
      await tester.ensureVisible(timer);
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(timer));
      await tester.pumpAndSettle();
      expect(find.text('Runda 1: 10 s'), findsOneWidget);
      await tester.ensureVisible(find.text('Zapisz wykonane rundy'));
      await tester.runAsync(
        () => tester.tap(find.text('Zapisz wykonane rundy')),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
      await tester.runAsync(() async {
        await c.read(activeWorkoutProvider.notifier).flushDraft();
        final sets = await db.workoutDao.getAllSets();
        expect(sets, hasLength(1));
        expect(sets.single.side, 'left');
        expect(sets.single.cwiczenieId, extra.id);
        expect(c.read(activeWorkoutProvider).guidance!.events, isEmpty);
        expect(c.read(activeWorkoutProvider).draft['timer'], isNotNull);
        expect(
          c
              .read(activeWorkoutProvider)
              .exerciseDraft(extra.id, extra: true, side: 'left')['timer'],
          isNull,
        );
      });
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'default guided capture does not authorize an arbitrary or other planned exercise',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = reviewContainer(db);
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final n = c.read(activeWorkoutProvider.notifier);
      await n.startSession(guidance: WorkoutGuidance.start(reviewPlan()));
      n.addExercise(extra);
      n.addExercise(future);
      expect(n.captureInterval(exercise: extra), isNull);
      expect(n.captureInterval(exercise: future), isNull);
    },
  );
}
