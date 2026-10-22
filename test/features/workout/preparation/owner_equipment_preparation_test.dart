import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/workout/domain/fixed_load_progression.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/workout_preparation.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/equipment_inventory.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/preparation_progression.dart';
import 'package:fitbirek_training/features/workout/preparation/presentation/preparation_exercise_card.dart';
import 'package:fitbirek_training/features/workout/preparation/presentation/workout_preparation_sheet.dart';
import 'package:fitbirek_training/features/workout/preparation/providers/preparation_providers.dart';
import '../../exercises/catalog_filter_test.dart' show exercise;
import '../../planner/manual_templates_test.dart' show MutableAuthority;
import 'preparation_progression_test.dart' show session;
import 'preparation_workflow_test.dart' show PreparationFixture;

Future<List<PreparedTarget>> showCard(
  WidgetTester tester,
  Exercise e, {
  List<String>? available,
  List<List<String>>? options,
  List<ProgressionPerformance> history = const [],
  double? templateKg,
  bool sheet = false,
  List<Exercise> candidates = const [],
}) async {
  final authority = MutableAuthority();
  final plan = StructuredPlan(
    criteria: const ExerciseFilters(),
    budgetSeconds: 600,
    equipment: available ?? e.sprzet,
    warnings: const [],
    blocks: [
      PlanBlock(
        exerciseId: e.id,
        section: PlanSection.main,
        prescription: PlanPrescription(
          tracking: 'reps',
          sets: 3,
          reps: 10,
          workSeconds: 30,
          restSeconds: 30,
          transitionSeconds: 15,
          weightKg: templateKg,
        ),
      ),
    ],
  );
  final snapshot = PreparationSnapshot(
    lease: TemplateLease(authority.epoch, 'A', 'device', true, null),
    savedPlan: SavedPlan(
      id: 1,
      nazwa: 'Plan',
      cwiczeniaIds: [e.id],
      cel: 'sila',
      dataUtworzenia: DateTime.utc(2026),
      structure: plan,
    ),
    profileSyncId: 'profile',
    catalog: [e, ...candidates],
    availableEquipment: available ?? e.sprzet,
    engine: ExerciseFilterEngine(
      ExerciseCatalogMetadata(
        exercises: {
          for (final item in [e, ...candidates])
            item.id: ExerciseCatalogEntry(
              tracking: 'reps',
              unilateral: false,
              equipmentSets: options,
            ),
        },
      ),
    ),
  );
  final emitted = <PreparedTarget>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
        preparationHistoryProvider.overrideWith((ref, key) async => history),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: sheet
              ? Consumer(
                  builder: (context, ref, _) => WorkoutPreparationSheet(
                    snapshot: snapshot,
                    workflow: ref.read(workoutPreparationWorkflowProvider),
                  ),
                )
              : SingleChildScrollView(
                  child: Form(
                    child: PreparationExerciseCard(
                      draft: PreparationDraft(snapshot),
                      index: 0,
                      enabled: true,
                      onTarget: emitted.add,
                      onReplace: () {},
                    ),
                  ),
                ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return emitted;
}

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  testWidgets(
    'replacement picker labels use matched step support, not canonical dumbbells and bench',
    (tester) async {
      await showCard(
        tester,
        exercise(
          'cw135',
          name: 'Ruch źródłowy',
          equipment: ['Hantle', 'Ławeczka'],
        ),
        available: ['Step'],
        options: [
          ['Hantle', 'Ławeczka'],
          ['Hantle', 'Step'],
          ['Masa własna', 'Step'],
        ],
        candidates: [
          exercise(
            'cw136',
            name: 'Ruch zastępczy',
            equipment: ['Hantle', 'Ławeczka'],
          ),
        ],
        sheet: true,
      );
      final button = find.text('Zmień ćwiczenie');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('Ruch zastępczy')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Masa własna, Step')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining('Hantle')),
        findsNothing,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining('Ławeczka')),
        findsNothing,
      );
    },
  );
  testWidgets(
    'sheet first block and aggregate use matched body step equipment without dumbbells or bench',
    (tester) async {
      await showCard(
        tester,
        exercise('cw135', equipment: ['Hantle', 'Ławeczka']),
        available: ['Step'],
        options: [
          ['Hantle', 'Ławeczka'],
          ['Hantle', 'Step'],
          ['Masa własna', 'Step'],
        ],
        sheet: true,
      );
      expect(find.text('Na początek: Masa własna, Step'), findsOneWidget);
      expect(
        find.text('Sprzęt do treningu: Masa własna, Step'),
        findsOneWidget,
      );
      expect(find.textContaining('Hantle'), findsNothing);
      expect(find.textContaining('Ławeczka'), findsNothing);
    },
  );
  testWidgets(
    'sheet summary retains canonical missing equipment and explains informational fallback without decline alias',
    (tester) async {
      await showCard(
        tester,
        exercise('cw135', equipment: ['Hantle', 'Ławeczka']),
        available: ['Hantle', 'Ławka ujemna do wyciskania'],
        options: [
          ['Hantle', 'Ławeczka'],
          ['Masa własna', 'Step'],
        ],
        sheet: true,
      );
      expect(find.text('Na początek: Hantle, Ławeczka'), findsOneWidget);
      expect(find.text('Sprzęt do treningu: Hantle, Ławeczka'), findsOneWidget);
      expect(
        find.textContaining('Podsumowanie sprzętu jest informacyjne'),
        findsOneWidget,
      );
    },
  );
  test(
    'sandbag inventory is optional for old fixtures, explicit and 20000g for owner',
    () {
      expect(EquipmentInventory(plateCounts: const {}).sandbagGrams, isNull);
      expect(EquipmentInventory.ownerConfirmed().sandbagGrams, 20000);
      expect(
        () => EquipmentInventory(plateCounts: const {}, sandbagGrams: 0),
        throwsArgumentError,
      );
    },
  );
  test(
    'confirmed sandbag cannot gain kg even if caller supplies an adjustable implement',
    () {
      PreparationLoadSuggestion offer(List<ProgressionPerformance> history) =>
          proposePreparationLoad(
            exerciseId: 'cw424',
            side: null,
            variantId: null,
            prescription: '3×8–12',
            tracking: 'reps',
            usesWeight: true,
            implement: LoadImplement.ezBar,
            quantity: 1,
            historyUnitConfirmed: true,
            history: history,
            inventory: EquipmentInventory.ownerConfirmed(),
            fixedWeightKg: 20,
          );
      final result = offer([
        ...session(2, exerciseId: 'cw424', side: null, kg: 20),
        ...session(1, exerciseId: 'cw424', side: null, kg: 20),
      ]);
      expect(result.targetWeightKg, isNull);
      expect(result.last!.weightKg, 20);
      expect(result.evidence, hasLength(2));
      final wrongMass = offer([
        ...session(2, exerciseId: 'cw424', side: null, kg: 15),
        ...session(1, exerciseId: 'cw424', side: null, kg: 15),
      ]);
      expect(wrongMass.targetWeightKg, isNull);
      expect(wrongMass.targetReps, isNull);
      expect(wrongMass.evidence, isEmpty);
      final wrongIdentity = offer([
        ...session(2, exerciseId: 'cw424', side: 'left', kg: 20),
        ...session(
          1,
          exerciseId: 'cw424',
          side: null,
          variantId: 'other',
          kg: 20,
        ),
      ]);
      expect(wrongIdentity.last, isNull);
      expect(wrongIdentity.evidence, isEmpty);
    },
  );
  testWidgets(
    'wrist roller kg is suspended load, without dumbbell kind, pair or handle mass',
    (tester) async {
      final emitted = await showCard(
        tester,
        exercise('cw123', equipment: ['Wrist roller']),
      );
      expect(find.text('Zawieszony ciężar (kg)'), findsOneWidget);
      expect(find.textContaining('bez masy uchwytu'), findsOneWidget);
      expect(find.text('Uchwyty / hantle'), findsNothing);
      expect(find.text('Ile przygotować?'), findsNothing);
      await tester.enterText(find.byType(TextFormField), '2,5');
      expect(emitted.last.weightKg, 2.5);
      expect(emitted.last.implement, isNull);
      expect(find.textContaining('Na każdą stronę'), findsNothing);
    },
  );
  testWidgets(
    'body step matches full set rather than showing or assembling canonical dumbbells',
    (tester) async {
      final emitted = await showCard(
        tester,
        exercise('cw135', equipment: ['Hantle', 'Ławeczka']),
        available: ['Step'],
        options: [
          ['Hantle', 'Ławeczka'],
          ['Hantle', 'Step'],
          ['Masa własna', 'Step'],
        ],
      );
      expect(find.text('Sprzęt: Masa własna, Step'), findsOneWidget);
      expect(find.text('Uchwyty / hantle'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(emitted.last.implement, isNull);
      expect(emitted.last.weightKg, isNull);
    },
  );
  testWidgets(
    'unavailable equipment remains informational canonical fallback',
    (tester) async {
      await showCard(
        tester,
        exercise('cw135', equipment: ['Hantle', 'Ławeczka']),
        available: [],
        options: [
          ['Hantle', 'Ławeczka'],
          ['Masa własna', 'Step'],
        ],
      );
      expect(find.text('Sprzęt: Hantle, Ławeczka'), findsOneWidget);
      expect(find.textContaining('Brak zgodnego zestawu'), findsOneWidget);
    },
  );
  testWidgets(
    'confirmed sandbag seeds 20 as equipment, not fictional history or kg progression',
    (tester) async {
      final emitted = await showCard(
        tester,
        exercise('cw424', equipment: ['Sandbag']),
      );
      expect(emitted.last.weightKg, 20);
      expect(
        find.textContaining('Potwierdzony sandbag: 20 kg'),
        findsOneWidget,
      );
      expect(find.textContaining('Ostatnio:'), findsNothing);
      expect(find.text('Przyjmij propozycję'), findsNothing);
      await tester.enterText(find.byType(TextFormField), '21');
      await tester.pump();
      expect(
        find.textContaining('Sandbag ma potwierdzone 20 kg'),
        findsOneWidget,
      );
      expect(emitted.last.weightKg, 20);
    },
  );
  testWidgets(
    'different sandbag history does not overwrite confirmed 20 or earn progression',
    (tester) async {
      final emitted = await showCard(
        tester,
        exercise(
          'cw424',
          equipment: ['Sandbag'],
        ).copyWith(seriexPowtorzenia: '3×8–12'),
        history: [
          ...session(2, exerciseId: 'cw424', side: null, kg: 15),
          ...session(1, exerciseId: 'cw424', side: null, kg: 15),
        ],
      );
      expect(emitted.last.weightKg, 20);
      expect(find.textContaining('Ostatnio: 15 kg'), findsOneWidget);
      expect(find.text('Przyjmij propozycję'), findsNothing);
    },
  );
  testWidgets(
    'incompatible sandbag template stays visible and fails validation, never silently coerced',
    (tester) async {
      final emitted = await showCard(
        tester,
        exercise('cw424', equipment: ['Sandbag']),
        templateKg: 15,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '15',
      );
      final form = tester.state<FormState>(find.byType(Form));
      expect(form.validate(), isFalse);
      await tester.pump();
      expect(
        find.textContaining('Sandbag ma potwierdzone 20 kg'),
        findsOneWidget,
      );
      expect(emitted, isEmpty);
    },
  );
  test(
    'workflow rejects incompatible sandbag template even without UI targets',
    () async {
      final e = exercise('cw424', equipment: ['Sandbag']);
      final f = await PreparationFixture.create(catalogReader: () => [e]);
      addTearDown(f.close);
      await f.db
          .update(f.db.userProfiles)
          .write(
            const UserProfilesCompanion(dostepnySprzet: Value('["Sandbag"]')),
          );
      final plan = StructuredPlan(
        criteria: const ExerciseFilters(),
        budgetSeconds: 600,
        equipment: const ['Sandbag'],
        warnings: const [],
        blocks: [
          PlanBlock(
            exerciseId: e.id,
            section: PlanSection.main,
            prescription: const PlanPrescription(
              tracking: 'reps',
              sets: 3,
              reps: 10,
              workSeconds: 30,
              restSeconds: 30,
              transitionSeconds: 15,
              weightKg: 15,
            ),
          ),
        ],
      );
      await f.container
          .read(plannerRepositoryProvider)
          .savePlan(
            nazwa: 'Sandbag',
            cwiczeniaIds: [e.id],
            cel: 'sila',
            structure: plan,
          );
      final saved =
          (await f.container.read(plannerRepositoryProvider).readAll())
              .firstWhere((p) => p.nazwa == 'Sandbag');
      final draft = PreparationDraft(
        await f.workflow.open(planSyncId: saved.syncId),
      );
      await expectLater(
        f.workflow.start(draft, isCurrent: () => true),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Sandbag'),
          ),
        ),
      );
      expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
    },
  );
  for (final bench in ['Ławka do brzuszków', 'Ławka ujemna do wyciskania']) {
    testWidgets('explicit bench warning for $bench', (tester) async {
      await showCard(tester, exercise('cw418', equipment: [bench]));
      expect(find.textContaining('nośność'), findsWidgets);
    });
  }
}
