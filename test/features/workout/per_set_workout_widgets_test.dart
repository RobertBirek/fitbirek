import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/app/theme.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/session_summary_page.dart';
import 'session_tracking_test.dart' show exercise;
import 'per_set_guidance_provider_test.dart' show ramp;

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
  });
  testWidgets(
    'mobile v2 displays distinct roles and next targets, saves deviations to selected target',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          allExercisesProvider.overrideWith((ref) => Stream.value([exercise])),
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
      addTearDown(() async {
        c.dispose();
        await tester.runAsync(db.close);
      });
      late ActiveWorkoutNotifier n;
      await tester.runAsync(() async {
        n = c.read(activeWorkoutProvider.notifier);
        await db
            .into(db.syncState)
            .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
        await n.startSession(guidance: WorkoutGuidance.start(ramp()));
        n.addExercise(exercise);
        await n.flushDraft();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: FitBirekTheme.dark,
            home: const ActiveSessionPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Rozgrzewkowa'), findsWidgets);
      expect(find.textContaining('Robocza'), findsWidgets);
      final field = find.widgetWithText(TextField, 'Powtórzenia');
      await tester.scrollUntilVisible(
        field,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(field, '11');
      final save = find.text('Seria wykonana (0)');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(save);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      final sets = await tester.runAsync(() => db.select(db.setsLog).get());
      expect(sets!.single.setRole, 'warmup');
      expect(sets.single.powtorzenia, 11);
      final next = find.byKey(const ValueKey('guided-target-work'));
      await tester.scrollUntilVisible(
        next,
        -180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(
        c.read(activeWorkoutProvider).guidance!.events.single['targetId'],
        'warm',
      );
      await tester.scrollUntilVisible(
        field,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '8');
      expect(tester.takeException(), isNull);
      var flushed = false;
      n.flushDraft().then((_) => flushed = true);
      for (var i = 0; i < 50 && !flushed; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      expect(flushed, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'summary keeps full individual goals and labels actual warmup, including skipped goals',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final repo = c.read(workoutRepositoryProvider);
      final id = await repo.startSession(
        guidance: WorkoutGuidance.start(ramp()),
      );
      await repo.logSet(
        sessionId: id,
        exerciseId: exercise.id,
        exerciseNamePl: 'Test',
        setNumber: 1,
        reps: 11,
        weightKg: 6,
        setRole: 'warmup',
        guidanceSlot: 0,
        guidanceTargetId: 'warm',
      );
      await db
          .into(db.syncState)
          .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      final row = await db.workoutDao.getSession(id);
      await repo.guidanceEvent(
        sessionId: id,
        sessionSyncId: row!.syncId,
        accountId: 'a',
        guard: () => true,
        slot: 0,
        targetId: 'work',
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(home: SessionSummaryPage(sessionId: id)),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Rozgrzewkowa'), findsWidgets);
      expect(find.textContaining('Pominięty cel'), findsOneWidget);
      expect(find.textContaining('20.0 kg'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
