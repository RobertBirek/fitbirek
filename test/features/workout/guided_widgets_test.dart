import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/session_summary_page.dart';
import '../planner/structured_plan_persistence_test.dart' show structure;
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'session_tracking_test.dart' show exercise;

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  testWidgets(
    'guided defaults are a draft; explicit side and confirmation create actual work',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async =>
                const StandardMessageCodec().encodeMessage(<Object?>[null]),
          );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final ex = exercise.copyWith(id: 'yoga');
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          allExercisesProvider.overrideWith((ref) => Stream.value([ex])),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => const ExerciseCatalogMetadata(
              exercises: {
                'yoga': ExerciseCatalogEntry(
                  tracking: 'time',
                  unilateral: true,
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
      await tester.runAsync(() async {
        await c
            .read(activeWorkoutProvider.notifier)
            .startSession(guidance: WorkoutGuidance.start(structure));
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('Cel planu: 2 serii'), findsOneWidget);
      expect(await tester.runAsync(() => db.workoutDao.getAllSets()), isEmpty);
      await tester.tap(find.text('Prawa'));
      await tester.enterText(find.byType(TextField).first, '15');
      await tester.ensureVisible(find.text('Zapisz czas (0)'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Zapisz czas (0)'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      final sets = await tester.runAsync(() => db.workoutDao.getAllSets());
      expect(sets!.single.czasSekund, 15);
      expect(sets.single.side, 'right');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'summary keeps skipped empty plan and unlinked external sets visible',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      late int id;
      await tester.runAsync(() async {
        final repo = WorkoutRepository(db);
        id = await repo.startSession(
          guidance: WorkoutGuidance.start(
            structure,
          ).replace(0, 'other').skip(0),
        );
        await repo.logSet(
          sessionId: id,
          exerciseId: 'external',
          exerciseNamePl: 'Mentor extra',
          setNumber: 1,
          seconds: 15,
        );
        await repo.finishSession(id, DateTime.now(), note: 'Moja notatka');
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
      expect(find.text('Plan a wykonanie'), findsOneWidget);
      expect(find.textContaining('Pominięte'), findsOneWidget);
      expect(find.textContaining('Dodatkowe: 1'), findsOneWidget);
      expect(find.textContaining('Moja notatka'), findsOneWidget);
      expect(find.textContaining('Mentor extra'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
