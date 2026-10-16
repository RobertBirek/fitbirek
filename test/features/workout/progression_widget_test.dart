import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'progression_provider_test.dart' show seedProgression, DelayedHistory;
import 'session_tracking_test.dart' show exercise;

void main() {
  for (final scenario in [
    'accept',
    'draft cancel',
    'draft confirm',
    'draft stale binding',
    'draft stale session',
    'side',
    'weight',
    'binding',
    'session',
    'async side',
    'async weight',
  ]) {
    testWidgets(
      'proposal $scenario changes only explicit reps draft, never saves',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final paused = scenario.startsWith('async') ? DelayedHistory(db) : null;
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            if (paused != null)
              workoutRepositoryProvider.overrideWithValue(paused),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => ExerciseCatalogMetadata(
                exercises: {
                  'ex': const ExerciseCatalogEntry(
                    tracking: 'reps',
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
        await seedProgression(db);
        final notifier = container.read(activeWorkoutProvider.notifier);
        await notifier.startSession();
        notifier.addExercise(
          exercise.copyWith(
            id: 'ex',
            seriexPowtorzenia: '3×8–12',
            sprzet: ['Sandbag'],
          ),
        );
        final initialSets = (await db.select(db.setsLog).get()).length;
        final initialOutbox = (await db.select(db.syncOutbox).get()).length;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lewa'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Ciężar (kg)'),
          '20',
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        if (paused != null) {
          expect(find.text('Przyjmij cel'), findsNothing);
          if (scenario == 'async side') {
            await tester.tap(find.text('Prawa'));
          } else {
            await tester.enterText(
              find.widgetWithText(TextField, 'Ciężar (kg)'),
              '15',
            );
          }
          paused.release.complete();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pumpAndSettle();
          expect(find.text('Przyjmij cel'), findsNothing);
          expect(
            tester
                .widget<TextField>(
                  find.widgetWithText(TextField, 'Powtórzenia'),
                )
                .controller!
                .text,
            isEmpty,
          );
          expect(
            (await tester.runAsync(
              () => db.select(db.syncOutbox).get(),
            ))!.length,
            initialOutbox,
          );
          await tester.pumpWidget(const SizedBox());
          return;
        }
        expect(find.text('Przyjmij cel'), findsOneWidget);
        final reps = find.widgetWithText(TextField, 'Powtórzenia');
        expect(tester.widget<TextField>(reps).controller!.text, isEmpty);
        if (scenario.startsWith('draft')) {
          await tester.enterText(reps, '11');
          await tester.tap(find.text('Przyjmij cel'));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pumpAndSettle();
          expect(find.text('Zastąpić wpisany cel?'), findsOneWidget);
          if (scenario == 'draft stale binding') {
            await tester.runAsync(
              () => db
                  .update(db.syncState)
                  .write(const SyncStateCompanion(accountId: Value('other'))),
            );
          } else if (scenario == 'draft stale session') {
            notifier.discardSession();
          }
          await tester.tap(
            find.text(scenario == 'draft cancel' ? 'Zachowaj' : 'Zastąp'),
          );
        } else if (scenario == 'side') {
          await tester.tap(find.text('Prawa'));
        } else if (scenario == 'weight') {
          await tester.enterText(
            find.widgetWithText(TextField, 'Ciężar (kg)'),
            '15',
          );
        } else if (scenario == 'binding') {
          await tester.runAsync(
            () => db
                .update(db.syncState)
                .write(const SyncStateCompanion(accountId: Value('other'))),
          );
        } else if (scenario == 'session') {
          notifier.discardSession();
        } else {
          await tester.tap(find.text('Przyjmij cel'));
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        if (scenario != 'session' && scenario != 'draft stale session') {
          expect(
            tester.widget<TextField>(reps).controller!.text,
            scenario == 'accept' || scenario == 'draft confirm'
                ? '9'
                : scenario.startsWith('draft')
                ? '11'
                : '',
          );
        }
        if (scenario == 'side' ||
            scenario == 'weight' ||
            scenario == 'binding' ||
            scenario == 'session') {
          expect(find.text('Przyjmij cel'), findsNothing);
        }
        expect(
          (await tester.runAsync(() => db.select(db.setsLog).get()))!.length,
          initialSets,
        );
        expect(
          (await tester.runAsync(() => db.select(db.syncOutbox).get()))!.length,
          initialOutbox,
        );
        expect(
          await tester.runAsync(() => db.select(db.personalRecords).get()),
          isEmpty,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
