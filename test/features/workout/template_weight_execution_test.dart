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
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'catalog_session_continuity_test.dart' show settleDatabase;
import 'guided_side_checkpoint_review_test.dart' show completedLeftTimer;
import 'session_tracking_test.dart' show exercise;

class WeightCatalog extends ExercisesRepository {
  WeightCatalog(super.db);
  @override
  Stream<List<Exercise>> watchAll() => Stream.value([exercise]);
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
  });
  for (final tracking in ['time', 'reps', 'rounds']) {
    for (final edit in ['7', '']) {
      testWidgets(
        'weighted bodyweight $tracking edit "$edit" survives resume and explicit save',
        (tester) async {
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          ProviderContainer container() => ProviderContainer(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              exercisesRepositoryProvider.overrideWithValue(WeightCatalog(db)),
              allExercisesProvider.overrideWith(
                (ref) => Stream.value([exercise]),
              ),
              exerciseCatalogMetadataProvider.overrideWith(
                (ref) async => ExerciseCatalogMetadata(
                  exercises: {
                    exercise.id: ExerciseCatalogEntry(
                      tracking: tracking,
                      unilateral: false,
                    ),
                  },
                ),
              ),
            ],
          );
          var c = container();
          addTearDown(() async {
            c.dispose();
            await db.close();
          });
          final plan = StructuredPlan(
            criteria: const ExerciseFilters(),
            budgetSeconds: 300,
            blocks: [
              PlanBlock(
                exerciseId: exercise.id,
                section: PlanSection.main,
                prescription: PlanPrescription(
                  tracking: tracking,
                  sets: 2,
                  reps: tracking == 'reps' ? 10 : null,
                  workSeconds: 30,
                  restSeconds: 0,
                  transitionSeconds: 0,
                  weightKg: 12,
                ),
              ),
            ],
            warnings: [],
          );
          await tester.runAsync(() async {
            await db
                .into(db.syncState)
                .insert(
                  SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'),
                );
            final n = c.read(activeWorkoutProvider.notifier);
            await n.startSession(guidance: WorkoutGuidance.start(plan));
            n.addExercise(exercise);
            await n.flushDraft();
          });
          Future<void> mount() async {
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: c,
                child: const MaterialApp(home: ActiveSessionPage()),
              ),
            );
            await settleDatabase(tester);
          }

          await mount();
          final kg = find.widgetWithText(TextField, 'Ciężar (kg)');
          expect(kg, findsOneWidget);
          expect(tester.widget<TextField>(kg).controller!.text, '12.0');
          await tester.ensureVisible(kg);
          await tester.pumpAndSettle();
          await tester.enterText(kg, edit);
          await settleDatabase(tester);
          await tester.runAsync(
            () => c.read(activeWorkoutProvider.notifier).flushDraft(),
          );
          final uuid = c.read(activeWorkoutProvider).sessionSyncId!;
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          c.dispose();
          c = container();
          await tester.runAsync(() async {
            expect(
              await c.read(activeWorkoutProvider.notifier).resumeSession(uuid),
              isTrue,
            );
          });
          await mount();
          expect(tester.widget<TextField>(kg).controller!.text, edit);
          final save = find.text(
            tracking == 'reps'
                ? 'Seria wykonana (0)'
                : tracking == 'rounds'
                ? 'Zapisz rundę (0)'
                : 'Zapisz czas (0)',
          );
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          await settleDatabase(tester);
          await tester.runAsync(() async {
            final row = (await db.workoutDao.getAllSets()).single;
            expect(row.ciezarKg, edit.isEmpty ? isNull : 7);
            expect(
              tracking == 'reps' ? row.powtorzenia : row.czasSekund,
              tracking == 'reps' ? 10 : 30,
            );
            if (tracking != 'reps') {
              expect(await db.select(db.personalRecords).get(), isEmpty);
            }
          });
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(milliseconds: 1));
        },
      );
    }
  }
  for (final edit in ['5', '']) {
    testWidgets(
      'weighted rounds interval captures edited "$edit" kg and retains seconds without PR',
      (tester) async {
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
                  exercise.id: const ExerciseCatalogEntry(
                    tracking: 'rounds',
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
        final plan = StructuredPlan(
          criteria: const ExerciseFilters(),
          budgetSeconds: 300,
          blocks: [
            PlanBlock(
              exerciseId: exercise.id,
              section: PlanSection.main,
              prescription: const PlanPrescription(
                tracking: 'rounds',
                sets: 1,
                workSeconds: 30,
                restSeconds: 0,
                transitionSeconds: 0,
                weightKg: 12,
              ),
            ),
          ],
          warnings: [],
        );
        await tester.runAsync(() async {
          await db
              .into(db.syncState)
              .insert(SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
          final n = c.read(activeWorkoutProvider.notifier);
          await n.startSession(guidance: WorkoutGuidance.start(plan));
          n.addExercise(exercise);
          n.updateDraft({'timer': completedLeftTimer(), 'weight': edit});
          await n.flushDraft();
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
        await settleDatabase(tester);
        final timer = find.text('Timer interwałów');
        await tester.ensureVisible(timer);
        await tester.pumpAndSettle();
        await tester.tap(timer);
        await settleDatabase(tester);
        expect(find.text('Runda 1: 10 s'), findsOneWidget);
        await tester.ensureVisible(find.text('Zapisz wykonane rundy'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zapisz wykonane rundy'));
        await settleDatabase(tester);
        await tester.runAsync(() async {
          final row = (await db.workoutDao.getAllSets()).single;
          expect(row.ciezarKg, edit.isEmpty ? isNull : 5);
          expect(row.czasSekund, 10);
          expect(await db.select(db.personalRecords).get(), isEmpty);
        });
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1));
      },
    );
  }
}
