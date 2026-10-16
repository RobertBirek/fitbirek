import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'session_tracking_test.dart' show exercise;

void main() {
  testWidgets(
    'rounds integration keeps manual/stopwatch; no autostart, explicit batch returns to original side',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
        (_) async =>
            const StandardMessageCodec().encodeMessage(<Object?>[null]),
      );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => ExerciseCatalogMetadata(
              exercises: {
                'custom': const ExerciseCatalogEntry(
                  tracking: 'rounds',
                  unilateral: true,
                ),
              },
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final notifier = container.read(activeWorkoutProvider.notifier);
      notifier.addExercise(exercise);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ActiveSessionPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Czas pracy rundy (s)'), findsOneWidget);
      expect(find.text('Start stopera (0)'), findsOneWidget);
      await tester.tap(find.text('Timer interwałów'));
      await tester.pumpAndSettle();
      expect(container.read(activeWorkoutProvider).isActive, isFalse);
      expect(
        await tester.runAsync(() => db.workoutDao.getAllSessionsSorted()),
        isEmpty,
      );
      await tester.runAsync(() => notifier.startSession());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lewa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Timer interwałów'));
      await tester.pumpAndSettle();
      expect(find.text('Interwały • Test • Lewa'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('preparation')), '0');
      await tester.enterText(find.byKey(const Key('work')), '1');
      await tester.enterText(find.byKey(const Key('rest')), '0');
      await tester.enterText(find.byKey(const Key('rounds')), '1');
      await tester.tap(find.text('Rozpocznij interwały'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1100)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Zakończenie'), findsOneWidget);
      expect(await tester.runAsync(() => db.workoutDao.getAllSets()), isEmpty);
      await tester.tap(find.text('Zapisz wykonane rundy'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      final rows = await tester.runAsync(() => db.workoutDao.getAllSets());
      expect(rows, hasLength(1));
      expect(rows!.single.side, 'left');
      expect(rows.single.czasSekund, 1);
      expect(find.text('Aktywny trening'), findsOneWidget);
      expect(find.text('Zapisz rundę (1)'), findsOneWidget);
      expect(find.text('Start stopera (1)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
