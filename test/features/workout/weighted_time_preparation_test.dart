import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/equipment_inventory.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/preparation_progression.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'preparation/preparation_workflow_test.dart' show PreparationFixture;
import 'preparation/preparation_sheet_test.dart' show openSheet, pressStart;
import 'session_tracking_test.dart' show exercise;

Future<PreparationFixture> timedCarryFixture() async {
  final e = exercise.copyWith(
    id: 'cw424',
    nazwaPl: 'Chód z sandbagiem',
    sprzet: ['Sandbag'],
    typ: 'Wytrzymałość',
  );
  final f = await PreparationFixture.create(catalogReader: () => [e]);
  f.container.updateOverrides([
    appDatabaseProvider.overrideWithValue(f.db),
    cachedAuthWriteAuthorityProvider.overrideWithValue(f.authority),
    allExercisesProvider.overrideWith((ref) => Stream.value([e])),
    exerciseCatalogMetadataProvider.overrideWith(
      (ref) async => ExerciseCatalogMetadata(
        exercises: {
          e.id: const ExerciseCatalogEntry(tracking: 'time', unilateral: false),
        },
      ),
    ),
  ]);
  await f.db
      .update(f.db.userProfiles)
      .write(
        UserProfilesCompanion(dostepnySprzet: Value(jsonEncode(e.sprzet))),
      );
  final plan = StructuredPlan(
    criteria: const ExerciseFilters(),
    budgetSeconds: 600,
    equipment: e.sprzet,
    warnings: const [],
    blocks: [
      PlanBlock(
        exerciseId: e.id,
        section: PlanSection.main,
        prescription: const PlanPrescription(
          tracking: 'time',
          sets: 1,
          workSeconds: 20,
          restSeconds: 0,
          transitionSeconds: 0,
        ),
      ),
    ],
  );
  await f.container
      .read(plannerRepositoryProvider)
      .savePlan(
        nazwa: 'Czas bez prescription kg',
        cwiczeniaIds: [e.id],
        cel: 'sila',
        structure: plan,
      );
  final saved = (await f.container.read(plannerRepositoryProvider).readAll())
      .singleWhere((p) => p.nazwa == 'Czas bez prescription kg');
  expect(saved.structure!.blocks.single.prescription.weightKg, isNull);
  return PreparationFixture(f.db, f.container, f.authority, saved.syncId!);
}

Future<void> saveTime(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextField, 'Czas (s)'), '20');
  final save = find.text('Zapisz czas (0)');
  await tester.ensureVisible(save);
  await tester.runAsync(() async {
    await tester.tap(save);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });
  await tester.pump();
}

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
  for (final manualWeight in ['20', '19,5']) {
    testWidgets(
      'real preparation, recovery and timed logging preserve actual controller weight $manualWeight',
      (tester) async {
        final f = (await tester.runAsync(timedCarryFixture))!;
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          await f.close();
        });
        await tester.runAsync(
          () => f.container.read(activeWorkoutProvider.notifier).flushDraft(),
        );
        await openSheet(tester, f);
        expect(
          find.textContaining('Potwierdzony sandbag: 20 kg'),
          findsOneWidget,
        );
        expect(find.text('Przyjmij propozycję'), findsNothing);
        expect(
          await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
          isEmpty,
        );
        expect(
          await tester.runAsync(() => f.db.select(f.db.setsLog).get()),
          isEmpty,
        );
        await pressStart(tester);
        final n = f.container.read(activeWorkoutProvider.notifier);
        final before = f.container.read(activeWorkoutProvider);
        final session = before.sessionSyncId!;
        final draftWeight = before.draft['weight'];
        expect(draftWeight, '20.0');
        expect(
          before.guidance!.plan.blocks.single.prescription.weightKg,
          isNull,
        );
        await tester.runAsync(() async {
          n.discardSession();
          await n.resumeSession(session);
        });
        expect(
          f.container.read(activeWorkoutProvider).draft['weight'],
          draftWeight,
        );
        expect(
          await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
          hasLength(1),
        );
        expect(
          await tester.runAsync(() => f.db.select(f.db.setsLog).get()),
          isEmpty,
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: f.container,
            child: const MaterialApp(home: ActiveSessionPage()),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        final weightField = find.widgetWithText(TextField, 'Ciężar (kg)');
        expect(weightField, findsOneWidget);
        expect(
          double.parse(tester.widget<TextField>(weightField).controller!.text),
          20,
        );
        for (final invalid in ['NaN', 'Infinity', '-1']) {
          await tester.enterText(weightField, invalid);
          await saveTime(tester);
          expect(
            await tester.runAsync(() => f.db.select(f.db.setsLog).get()),
            isEmpty,
          );
        }
        await tester.enterText(weightField, manualWeight);
        await saveTime(tester);
        final rows = (await tester.runAsync(
          () => f.db.workoutDao.getAllSets(),
        ))!;
        expect(rows, hasLength(1));
        expect(rows.single.czasSekund, 20);
        final actualWeight = double.parse(manualWeight.replaceAll(',', '.'));
        expect(rows.single.ciezarKg, actualWeight);
        expect(rows.single.powtorzenia, isNull);
        expect(
          await tester.runAsync(() => f.db.select(f.db.personalRecords).get()),
          isEmpty,
        );
        await tester.runAsync(() => n.finishSession());
        final history = (await tester.runAsync(
          () => f.container
              .read(workoutRepositoryProvider)
              .getPreparationHistory('cw424', side: null, variantId: null),
        ))!;
        expect(history, hasLength(1));
        expect(history.single.weightKg, actualWeight);
        final offer = proposePreparationLoad(
          exerciseId: 'cw424',
          side: null,
          variantId: null,
          prescription: '1×20 s',
          tracking: 'time',
          usesWeight: true,
          implement: null,
          quantity: 1,
          historyUnitConfirmed: true,
          history: history,
          inventory: EquipmentInventory.ownerConfirmed(),
          fixedWeightKg: 20,
        );
        expect(offer.targetWeightKg, isNull);
        expect(offer.targetReps, isNull);
      },
    );
  }
  testWidgets(
    'bodyweight time has no weight field and logs seconds without invented kilograms',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exerciseCatalogMetadataProvider.overrideWith(
            (ref) async => const ExerciseCatalogMetadata(
              exercises: {
                'body-time': ExerciseCatalogEntry(
                  tracking: 'time',
                  unilateral: false,
                ),
              },
            ),
          ),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        c.dispose();
        await db.close();
      });
      await c.read(exerciseCatalogMetadataProvider.future);
      final n = c.read(activeWorkoutProvider.notifier);
      n.addExercise(
        exercise.copyWith(id: 'body-time', sprzet: ['Masa własna']),
      );
      await tester.runAsync(n.startSession);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: ActiveSessionPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Ciężar (kg)'), findsNothing);
      await saveTime(tester);
      final rows = (await tester.runAsync(db.workoutDao.getAllSets))!;
      expect(rows, hasLength(1));
      expect(rows.single.czasSekund, 20);
      expect(rows.single.ciezarKg, isNull);
      expect(rows.single.powtorzenia, isNull);
    },
  );
}
