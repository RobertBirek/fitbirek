import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/template_editor_page.dart';
import 'package:fitbirek_training/features/planner/presentation/widgets/save_as_template_button.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';
import 'structured_plan_persistence_test.dart' show structure;
import '../exercises/catalog_filter_test.dart' show exercise, metadata;
import 'manual_templates_test.dart' show MutableAuthority;

Future<void> see(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final source in ['corrupt-session', 'unsupported-goals']) {
    testWidgets('failed $source cannot offer a partial template or update', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final id = await c.read(workoutRepositoryProvider).startSession();
      await (db.update(db.workoutSessions)..where((s) => s.id.equals(id)))
          .write(const WorkoutSessionsCompanion(guidanceJson: Value('{}')));
      final json = structure.toJson();
      (((json['blocks'] as List).single as Map)['prescription']
              as Map)['tracking'] =
          'rounds';
      final before = await db.select(db.syncOutbox).get();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: Scaffold(
              body: SaveAsTemplateButton(
                sessionId: source == 'corrupt-session' ? id : null,
                initialPlan: source == 'unsupported-goals'
                    ? StructuredPlan.fromJson(json)
                    : null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zapisz jako szablon'));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);
      expect(find.byType(TemplateEditorPage), findsNothing);
      expect(find.textContaining('Niczego nie pominięto'), findsOneWidget);
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      expect(await db.select(db.syncOutbox).get(), before);
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final transition in ['before-init', 'A-B-A']) {
    testWidgets(
      'session origin lease rejects $transition without private form or writes',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final authority = MutableAuthority();
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            cachedAuthWriteAuthorityProvider.overrideWithValue(authority),
            allExercisesProvider.overrideWith(
              (ref) => Stream.value([exercise('yoga')]),
            ),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => metadata,
            ),
          ],
        );
        final id = await c
            .read(workoutRepositoryProvider)
            .startSession(guidance: WorkoutGuidance.start(structure));
        final before = await db.select(db.syncOutbox).get();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: SaveAsTemplateButton(
                  sessionId: id,
                  beforeNavigate: () {
                    if (transition == 'before-init') authority.generation++;
                  },
                ),
              ),
            ),
            GoRoute(
              path: '/workout/templates/new',
              builder: (context, state) =>
                  TemplateEditorPage(seed: state.extra! as TemplateEditorSeed),
            ),
          ],
        );
        addTearDown(() async {
          router.dispose();
          c.dispose();
          await db.close();
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        // Exercise the real session-read button with a transition in the narrow
        // gap after its final read/check and before editor initialization.
        await tester.tap(find.text('Zapisz jako szablon'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nowy szablon'));
        await tester.pumpAndSettle();
        final seed = tester
            .widget<TemplateEditorPage>(find.byType(TemplateEditorPage))
            .seed!;
        expect(seed.lease, isNotNull);
        if (transition == 'A-B-A') {
          authority.generation += 2;
          authority.revision.value = authority.generation;
        }
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(TextFormField, 'Nazwa szablonu'),
          findsNothing,
        );
        expect(find.text('Zapisz szablon'), findsNothing);
        expect(find.textContaining('Konto zmieniło się'), findsOneWidget);
        expect(await db.select(db.workoutPlans).get(), isEmpty);
        expect(await db.select(db.syncOutbox).get(), before);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  for (final outcome in ['save', 'changed', 'cancel']) {
    testWidgets(
      'session replaces existing targets: $outcome, preserves history and detached form',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final c = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            allExercisesProvider.overrideWith(
              (ref) => Stream.value([exercise('a', name: 'Yoga')]),
            ),
            exerciseCatalogMetadataProvider.overrideWith(
              (ref) async => metadata,
            ),
          ],
        );
        final workflow = c.read(plannerWorkflowProvider);
        await workflow.saveTemplate(
          await workflow.openTemplate(),
          structure,
          name: 'Docelowy',
        );
        final target =
            (await c.read(plannerRepositoryProvider).readAll()).single;
        final sourceJson = structure.toJson();
        ((sourceJson['blocks'] as List).single as Map)['exerciseId'] = 'a';
        (((sourceJson['blocks'] as List).single as Map)['prescription']
                as Map)['sets'] =
            3;
        final source = StructuredPlan.fromJson(sourceJson);
        final id = await c
            .read(workoutRepositoryProvider)
            .startSession(guidance: WorkoutGuidance.start(source));
        final sessions = await db.select(db.workoutSessions).get();
        final operations = await db.select(db.syncOutbox).get();
        final router = createRouter(
          readAuthState: () => const AuthState.signedIn('A'),
          readOnboardingComplete: () => true,
          initialLocation: '/workout/summary/$id',
        );
        addTearDown(() async {
          router.dispose();
          c.dispose();
          await db.close();
        });
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zapisz jako szablon'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Docelowy'));
        await tester.pumpAndSettle();
        expect(find.text('Docelowy'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(
                find.widgetWithText(TextFormField, 'Serie'),
              )
              .controller!
              .text,
          '3',
        );
        expect(await db.select(db.syncOutbox).get(), operations);
        if (outcome == 'changed') {
          await (db.update(
            db.workoutPlans,
          )..where((p) => p.id.equals(target.id))).write(
            const WorkoutPlansCompanion(nazwa: Value('Zmieniony zdalnie')),
          );
        }
        await tester.tap(find.text('Zapisz szablon'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Zapis zastąpi cele istniejącego szablonu'),
          findsOneWidget,
        );
        await tester.tap(
          find.text(outcome == 'cancel' ? 'Anuluj' : 'Potwierdź'),
        );
        await tester.pumpAndSettle();
        final saved =
            (await c.read(plannerRepositoryProvider).readAll()).single;
        expect(saved.syncId, target.syncId);
        expect(
          saved.structure!.blocks.single.prescription.sets,
          outcome == 'save' ? 3 : structure.blocks.single.prescription.sets,
        );
        if (outcome != 'save') {
          expect(find.byType(TemplateEditorPage), findsOneWidget);
          expect(
            tester
                .widget<TextFormField>(
                  find.widgetWithText(TextFormField, 'Serie'),
                )
                .controller!
                .text,
            '3',
          );
          expect(await db.select(db.syncOutbox).get(), operations);
        }
        expect(await db.select(db.workoutSessions).get(), sessions);
        expect(await db.select(db.setsLog).get(), isEmpty);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'inline limits reject huge sets, reps and rest without creating records',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([exercise('b')]),
          ),
          exerciseCatalogMetadataProvider.overrideWith((ref) async => metadata),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final plan = StructuredPlan(
        criteria: const ExerciseFilters(),
        budgetSeconds: 300,
        warnings: [],
        blocks: const [
          PlanBlock(
            exerciseId: 'b',
            section: PlanSection.main,
            prescription: PlanPrescription(
              tracking: 'reps',
              sets: 2,
              reps: 10,
              workSeconds: 30,
              restSeconds: 30,
              transitionSeconds: 15,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: TemplateEditorPage(
              seed: TemplateEditorSeed(plan, name: 'Granice'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Serie'),
        '4611686018427387904',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Powtórzenia'),
        '1801',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Przerwa między seriami (s)'),
        '5401',
      );
      await tester.tap(find.text('Zapisz szablon'));
      await tester.pumpAndSettle();
      expect(
        find.text('Maksymalnie 5400 (limit szablonu: 90 min).'),
        findsNWidgets(2),
      );
      expect(
        find.text('Maksymalnie 1800 (limit szablonu: 90 min).'),
        findsOneWidget,
      );
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'session snapshot copy opens real editor route without touching session or creating logs',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([exercise('yoga', name: 'Yoga')]),
          ),
          exerciseCatalogMetadataProvider.overrideWith((ref) async => metadata),
        ],
      );
      final id = await c
          .read(workoutRepositoryProvider)
          .startSession(guidance: WorkoutGuidance.start(structure));
      final before = (await db.select(db.workoutSessions).get()).single;
      final operations = await db.select(db.syncOutbox).get();
      final router = createRouter(
        readAuthState: () => const AuthState.signedIn('A'),
        readOnboardingComplete: () => true,
        initialLocation: '/workout/summary/$id',
      );
      addTearDown(() async {
        router.dispose();
        c.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zapisz jako szablon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nowy szablon'));
      await tester.pumpAndSettle();
      final editor = tester.widget<TemplateEditorPage>(
        find.byType(TemplateEditorPage),
      );
      expect(editor.seed!.plan.toJson(), structure.toJson());
      expect(editor.seed!.lease, isNotNull);
      expect(editor.syncId, isNull);
      expect((await db.select(db.workoutSessions).get()).single, before);
      expect(await db.select(db.syncOutbox).get(), operations);
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      expect(await db.select(db.setsLog).get(), isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'real router create search reorder save edit and explicit start protects active session',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([
              exercise('a', name: 'Alpha'),
              exercise('b', name: 'Beta'),
            ]),
          ),
          exerciseCatalogMetadataProvider.overrideWith((ref) async => metadata),
        ],
      );
      final router = createRouter(
        readAuthState: () => const AuthState.signedIn('A'),
        readOnboardingComplete: () => true,
        initialLocation: '/workout/templates',
      );
      addTearDown(() async {
        router.dispose();
        c.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nowy szablon'));
      await tester.pumpAndSettle();
      expect(find.byType(TemplateEditorPage), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nazwa szablonu'),
        'Poranek',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Szukaj ćwiczenia'),
        'Alpha',
      );
      await tester.pumpAndSettle();
      expect(find.text('Beta'), findsNothing);
      await tester.tap(find.byTooltip('Dodaj ćwiczenie'));
      await tester.pumpAndSettle();
      await see(tester, find.widgetWithText(TextField, 'Szukaj ćwiczenia'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Szukaj ćwiczenia'),
        'Beta',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Dodaj ćwiczenie'));
      await tester.pumpAndSettle();
      await see(tester, find.text('2. Beta'));
      await tester.tap(find.byTooltip('Przesuń w górę').last);
      await tester.pumpAndSettle();
      await see(tester, find.text('Zapisz szablon'));
      await tester.tap(find.text('Zapisz szablon'));
      await tester.pumpAndSettle();
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      await tester.tap(find.text('Potwierdź'));
      await tester.pumpAndSettle();
      final saved = (await c.read(plannerRepositoryProvider).readAll()).single;
      expect(saved.cwiczeniaIds, ['b', 'a']);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      await tester.tap(find.text('Edytuj'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TemplateEditorPage>(find.byType(TemplateEditorPage))
            .syncId,
        saved.syncId,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nazwa szablonu'),
        'Poranek 2',
      );
      await db
          .into(db.syncDeferredRecords)
          .insert(
            SyncDeferredRecordsCompanion.insert(
              entityType: 'workoutPlan',
              entityId: saved.syncId!,
              version: 2,
              recordJson: '{}',
            ),
          );
      await see(tester, find.text('Zapisz szablon'));
      await tester.tap(find.text('Zapisz szablon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Potwierdź'));
      await tester.pumpAndSettle();
      expect(find.byType(TemplateEditorPage), findsOneWidget);
      expect(
        (await c.read(plannerRepositoryProvider).readAll()).single.nazwa,
        'Poranek',
      );
      // Form state remains intact when a remote conflict blocks the write.
      await db.delete(db.syncDeferredRecords).go();
      await see(tester, find.text('Zapisz szablon'));
      await tester.tap(find.text('Zapisz szablon'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Potwierdź'));
      await tester.pumpAndSettle();
      expect(
        (await c.read(plannerRepositoryProvider).readAll()).single.nazwa,
        'Poranek 2',
      );
      // Existing active workout must not be replaced after confirmation.
      await c.read(activeWorkoutProvider.notifier).startSession();
      final activeId = c.read(activeWorkoutProvider).sessionSyncId;
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Potwierdź'));
      await tester.pumpAndSettle();
      expect(c.read(activeWorkoutProvider).sessionSyncId, activeId);
      expect(await db.select(db.workoutSessions).get(), hasLength(1));
      expect(find.textContaining('Najpierw zakończ'), findsOneWidget);
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(await c.read(plannerRepositoryProvider).readAll(), hasLength(1));
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Potwierdź'));
      await tester.pumpAndSettle();
      expect(await c.read(plannerRepositoryProvider).readAll(), isEmpty);
      expect(c.read(activeWorkoutProvider).sessionSyncId, activeId);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    '320px text200 editor seed scrolls without overflow and does not write',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          allExercisesProvider.overrideWith(
            (ref) => Stream.value([
              exercise('b', name: 'Długie ćwiczenie z ciężarem'),
            ]),
          ),
          exerciseCatalogMetadataProvider.overrideWith((ref) async => metadata),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      final plan = StructuredPlan(
        criteria: const ExerciseFilters(),
        budgetSeconds: 300,
        warnings: [],
        blocks: const [
          PlanBlock(
            exerciseId: 'b',
            section: PlanSection.main,
            prescription: PlanPrescription(
              tracking: 'reps',
              sets: 2,
              reps: 10,
              workSeconds: 30,
              restSeconds: 30,
              transitionSeconds: 15,
              weightKg: 12.5,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: TemplateEditorPage(seed: TemplateEditorSeed(plan)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await see(tester, find.text('Zapisz szablon'));
      expect(tester.takeException(), isNull);
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      expect(await db.select(db.workoutSessions).get(), isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
