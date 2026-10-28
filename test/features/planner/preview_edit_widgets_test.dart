import 'dart:async';
import 'package:drift/native.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/planner_page.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'plan_explanation_fixtures.dart';
import 'plan_explanation_widgets_test.dart'
    show compatibleExercise, compatibleMetadata;

Future<ProviderContainer> openPreview(
  WidgetTester tester,
  StructuredPlan plan, {
  Stream<List<Exercise>>? catalog,
  CachedAuthWriteAuthority? authority,
  AppDatabase? db,
  Future<ExerciseCatalogMetadata> Function()? metadataLoader,
  Stream<UserProfile?> Function()? profileLoader,
}) async {
  final c = ProviderContainer(
    overrides: [
      if (db != null) appDatabaseProvider.overrideWithValue(db),
      if (authority != null)
        cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
      allExercisesProvider.overrideWith(
        (ref) =>
            catalog ??
            Stream.value([
              compatibleExercise('a'),
              compatibleExercise('b').copyWith(seriexPowtorzenia: '3 x 100 s'),
            ]),
      ),
      exerciseCatalogMetadataProvider.overrideWith(
        (ref) => metadataLoader?.call() ?? Future.value(compatibleMetadata),
      ),
      userProfileStreamProvider.overrideWith(
        (ref) =>
            profileLoader?.call() ??
            Stream.value(
              UserProfile(
                imie: 'T',
                wiek: 30,
                wzrostCm: 180,
                wagaKg: 80,
                cel: CelTreningowy.mix,
                dostepnySprzet: ['Mata'],
                dataUtworzenia: DateTime(2026),
              ),
            ),
      ),
      savedPlansProvider.overrideWith(
        (ref) => Stream.value([
          SavedPlan(
            id: 1,
            nazwa: 'Podgląd',
            cwiczeniaIds: plan.exerciseIds,
            cel: 'mix',
            dataUtworzenia: DateTime(2026),
            structure: plan,
          ),
        ]),
      ),
    ],
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: PlannerPage()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Podgląd'));
  await tester.tap(find.text('Podgląd'));
  await tester.pumpAndSettle();
  return c;
}

StructuredPlan shortPlan({int sets = 3}) => StructuredPlan(
  criteria: explanationPlan().criteria,
  budgetSeconds: 300,
  equipment: ['Mata'],
  level: 'Średni',
  warnings: [],
  blocks: [
    PlanBlock(
      exerciseId: 'a',
      section: PlanSection.main,
      prescription: PlanPrescription(
        tracking: 'time',
        sets: sets,
        workSeconds: 40,
        restSeconds: 30,
        transitionSeconds: 15,
      ),
    ),
  ],
);

class PreviewAuthority extends CachedAuthWriteAuthority {
  int value = 0;
  @override
  int get epoch => value;
}

void main() {
  testWidgets('rest invalid/cancel/accept and explicit budget increase', (
    tester,
  ) async {
    final plan = shortPlan();
    await openPreview(tester, plan);
    await tester.ensureVisible(find.byTooltip('Edytuj przerwę'));
    await tester.tap(find.byTooltip('Edytuj przerwę'));
    await tester.pumpAndSettle();
    final input = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    for (final invalid in ['601', '-1', '1.5', '', 'abc']) {
      await tester.enterText(input, invalid);
      await tester.pump();
      expect(find.text('Wpisz całkowite sekundy od 0 do 600.'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Zastosuj'))
            .onPressed,
        isNull,
      );
    }
    await tester.enterText(find.byType(TextField).last, '100');
    await tester.pump();
    expect(find.textContaining('195 s → 335 s'), findsOneWidget);
    expect(find.textContaining('300 s → 360 s'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Zastosuj'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(find.textContaining('przerwa 30 s'), findsOneWidget);
    await tester.tap(find.byTooltip('Edytuj przerwę'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '100');
    await tester.pump();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Zastosuj'));
    await tester.pumpAndSettle();
    expect(find.textContaining('przerwa 100 s'), findsOneWidget);
    expect(find.textContaining('/ budżet 6 min'), findsOneWidget);
    expect(plan.blocks.single.prescription.restSeconds, 30);
  });

  testWidgets('one-set rest has zero time delta and catalog stale guard', (
    tester,
  ) async {
    final stream = StreamController<List<Exercise>>.broadcast();
    addTearDown(stream.close);
    final pending = openPreview(
      tester,
      shortPlan(sets: 1),
      catalog: stream.stream,
    );
    stream.add([compatibleExercise('a')]);
    await pending;
    // Ensure the non-replaying catalog has emitted after its subscription.
    stream.add([compatibleExercise('a')]);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Edytuj przerwę'));
    await tester.tap(find.byTooltip('Edytuj przerwę'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '600');
    await tester.pump();
    expect(find.textContaining('55 s → 55 s'), findsOneWidget);
    stream.add([compatibleExercise('a')]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zastosuj'));
    await tester.pumpAndSettle();
    expect(find.textContaining('przerwa 30 s'), findsOneWidget);
    expect(find.textContaining('Dane zmieniły się'), findsOneWidget);
  });

  testWidgets('replacement shows full duration and requires budget consent', (
    tester,
  ) async {
    await openPreview(tester, shortPlan());
    await tester.ensureVisible(find.byTooltip('Wymień ćwiczenie'));
    await tester.tap(find.byTooltip('Wymień ćwiczenie'));
    await tester.pumpAndSettle();
    expect(find.text('Zamień Ruch a na Ruch b?'), findsOneWidget);
    expect(find.textContaining('195 s → 375 s'), findsWidgets);
    expect(find.textContaining('300 s → 420 s'), findsWidgets);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Zamień'))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Zamień'));
    await tester.pumpAndSettle();
    expect(find.text('Ruch b'), findsOneWidget);
    expect(find.textContaining('/ budżet 7 min'), findsOneWidget);
  });

  for (final source in ['catalog', 'profile', 'engine', 'account']) {
    testWidgets('rest rejects stale $source dialog', (tester) async {
      final authority = PreviewAuthority();
      final c = await openPreview(tester, shortPlan(), authority: authority);
      await tester.ensureVisible(find.byTooltip('Edytuj przerwę'));
      await tester.tap(find.byTooltip('Edytuj przerwę'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '0');
      await tester.pump();
      if (source == 'catalog') c.invalidate(allExercisesProvider);
      if (source == 'profile') c.invalidate(userProfileStreamProvider);
      if (source == 'engine') c.invalidate(exerciseFilterEngineProvider);
      if (source == 'account') authority.value++;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zastosuj'));
      await tester.pumpAndSettle();
      expect(find.textContaining('przerwa 30 s'), findsOneWidget);
      expect(find.textContaining('Dane zmieniły się'), findsOneWidget);
    });
  }

  testWidgets('one-set accepts 0 and 600 without changing duration or budget', (
    tester,
  ) async {
    await openPreview(tester, shortPlan(sets: 1));
    for (final rest in [0, 600]) {
      await tester.ensureVisible(find.byTooltip('Edytuj przerwę'));
      await tester.tap(find.byTooltip('Edytuj przerwę'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '$rest');
      await tester.pump();
      expect(find.byType(Checkbox), findsNothing);
      await tester.tap(find.text('Zastosuj'));
      await tester.pumpAndSettle();
      expect(find.textContaining('przerwa $rest s'), findsOneWidget);
      expect(find.textContaining('razem 55 s'), findsOneWidget);
      expect(find.textContaining('/ budżet 5 min'), findsOneWidget);
    }
  });

  testWidgets(
    'rest above 90 minutes is refused without modifying other blocks',
    (tester) async {
      final base = shortPlan();
      final plan = StructuredPlan(
        criteria: base.criteria,
        budgetSeconds: 5400,
        equipment: base.equipment,
        blocks: [
          const PlanBlock(
            exerciseId: 'a',
            section: PlanSection.main,
            prescription: PlanPrescription(
              tracking: 'time',
              sets: 40,
              workSeconds: 100,
              restSeconds: 0,
              transitionSeconds: 15,
            ),
          ),
        ],
        warnings: [],
      );
      await openPreview(tester, plan);
      await tester.ensureVisible(find.byTooltip('Edytuj przerwę'));
      await tester.tap(find.byTooltip('Edytuj przerwę'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '600');
      await tester.pump();
      expect(
        find.textContaining('przekracza maksymalny budżet 90 min'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Zastosuj'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(find.textContaining('przerwa 0 s'), findsOneWidget);
    },
  );

  testWidgets('accepted rest survives explicit save and real SQLite read', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = await openPreview(tester, shortPlan(), db: db);
    await tester.ensureVisible(find.byTooltip('Edytuj przerwę'));
    await tester.tap(find.byTooltip('Edytuj przerwę'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '0');
    await tester.pump();
    await tester.tap(find.text('Zastosuj'));
    await tester.pumpAndSettle();
    expect(c.exists(plannerWorkflowProvider), isFalse);
    await tester.ensureVisible(find.text('Zapisz plan'));
    await tester.tap(find.text('Zapisz plan'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Potwierdź'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(() => PlannerRepository(db).readAll());
    expect(saved!.single.structure!.blocks.single.prescription.restSeconds, 0);
    expect(saved.single.structure!.estimatedSeconds, 135);
    expect(find.text('Plan zapisany.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'metadata reloading blocks a new rest proposal even with cached data',
    (tester) async {
      final pending = Completer<ExerciseCatalogMetadata>();
      var refreshing = false;
      final c = await openPreview(
        tester,
        shortPlan(),
        metadataLoader: () =>
            refreshing ? pending.future : Future.value(compatibleMetadata),
      );
      refreshing = true;
      c.invalidate(exerciseCatalogMetadataProvider);
      await tester.pump();
      await tester.ensureVisible(find.byTooltip('Edytuj przerwę'));
      await tester.tap(find.byTooltip('Edytuj przerwę'));
      await tester.pump();
      expect(find.text('Przerwa między seriami (s)'), findsNothing);
      expect(
        find.textContaining('Poczekaj na ćwiczenia i klasyfikację'),
        findsOneWidget,
      );
      pending.complete(compatibleMetadata);
      await tester.pumpAndSettle();
    },
  );
}
