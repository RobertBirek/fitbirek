import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/workout/preparation/presentation/workout_preparation_sheet.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'preparation_workflow_test.dart' show PreparationFixture;

Future<void> openSheet(
  WidgetTester tester,
  PreparationFixture f, {
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final snapshot = (await tester.runAsync(
    () => f.workflow.open(planSyncId: f.planId),
  ))!;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: f.container,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () =>
                    showWorkoutPreparation(context, ref, snapshot: snapshot),
                child: const Text('Otwórz'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Otwórz'));
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

Future<PreparationFixture> fixture(WidgetTester tester) async {
  final f = (await tester.runAsync(PreparationFixture.create))!;
  // Create the notifier's initial Future.value in the real async zone, matching
  // the real SQLite fixture. FakeAsync must not strand an unrelated empty queue.
  await tester.runAsync(
    () => f.container.read(activeWorkoutProvider.notifier).flushDraft(),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await f.close();
  });
  return f;
}

Future<void> enterWeight(
  WidgetTester tester,
  String value, {
  int slot = 0,
}) async {
  final finder = find.byKey(ValueKey('preparation-weight-$slot'));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pump();
}

Future<void> pressStart(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.text('Rozpocznij trening'));
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  testWidgets(
    'immediate Start captures the last typed weight without an intervening frame',
    (tester) async {
      final f = await fixture(tester);
      await openSheet(tester, f);
      final field = find.byKey(const ValueKey('preparation-weight-0'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '7,25');
      await pressStart(tester);
      expect(f.container.read(activeWorkoutProvider).draft['weight'], '7.25');
    },
  );
  testWidgets('invalid numeric values cannot create results or a session', (
    tester,
  ) async {
    final f = await fixture(tester);
    await openSheet(tester, f);
    for (final raw in ['NaN', 'Infinity', '-1', '7,2501', '1001']) {
      await enterWeight(tester, raw);
      await pressStart(tester);
      expect(find.text('Przygotuj trening'), findsOneWidget);
      expect(
        await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
        isEmpty,
      );
    }
    await enterWeight(tester, '');
    await pressStart(tester);
    expect(
      await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
      hasLength(1),
    );
    expect(
      await tester.runAsync(() => f.db.select(f.db.setsLog).get()),
      isEmpty,
    );
    expect(f.container.read(activeWorkoutProvider).draft['weight'], '');
  });
  testWidgets(
    'first training preview has actual equipment, explicit units and no fictional history',
    (tester) async {
      final f = await fixture(tester);
      final before = await tester.runAsync(
        () => f.db.select(f.db.syncOutbox).get(),
      );
      await openSheet(tester, f);
      expect(find.text('Przygotuj trening'), findsOneWidget);
      expect(find.text('Ruch a'), findsOneWidget);
      expect(find.textContaining('Hantle'), findsWidgets);
      expect(find.textContaining('Pierwszy trening'), findsWidgets);
      expect(find.textContaining('Historia niedostępna'), findsNothing);
      expect(find.textContaining('kg/szt.'), findsWidgets);
      expect(find.text('Przyjmij propozycję'), findsNothing);
      expect(
        await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
        isEmpty,
      );
      await tester.tap(find.byTooltip('Zamknij przygotowanie'));
      await tester.pumpAndSettle();
      expect(
        await tester.runAsync(() => f.db.select(f.db.syncOutbox).get()),
        before,
      );
      expect(
        await tester.runAsync(() => f.db.select(f.db.workoutDrafts).get()),
        isEmpty,
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'manual7250 shows symmetric assembly and seeds actual active form only on start',
    (tester) async {
      final f = await fixture(tester);
      await openSheet(tester, f);
      await enterWeight(tester, '7,25');
      expect(find.textContaining('Na każdą stronę: 2,5 kg'), findsWidgets);
      expect(
        await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
        isEmpty,
      );
      await pressStart(tester);
      expect(find.text('Przygotuj trening'), findsNothing);
      expect(f.container.read(activeWorkoutProvider).draft['weight'], '7.25');
      expect(
        await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
        hasLength(1),
      );
      expect(
        await tester.runAsync(() => f.db.select(f.db.setsLog).get()),
        isEmpty,
      );
      expect(
        await tester.runAsync(() => f.db.select(f.db.personalRecords).get()),
        isEmpty,
      );
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );

  testWidgets(
    'unreachable7300 is not silently rounded and cannot create a session',
    (tester) async {
      final f = await fixture(tester);
      await openSheet(tester, f);
      await enterWeight(tester, '7,3');
      await pressStart(tester);
      expect(find.textContaining('Brak dokładnej konfiguracji'), findsWidgets);
      expect(
        find.textContaining('Dostępne w pobliżu: 7,25 / 7,75 kg/szt.'),
        findsOneWidget,
      );
      final field = tester.widget<TextFormField>(
        find.byKey(const ValueKey('preparation-weight-0')),
      );
      expect(field.controller!.text, '7,3');
      expect(
        await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
        isEmpty,
      );
    },
  );

  for (final template in [false, true]) {
    testWidgets(
      'replacement asks scope and clears old weight; updateTemplate=$template',
      (tester) async {
        final f = await fixture(tester);
        await openSheet(tester, f);
        await enterWeight(tester, '7,25');
        await tester.ensureVisible(find.text('Zmień ćwiczenie').first);
        await tester.tap(find.text('Zmień ćwiczenie').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ruch c'));
        await tester.pumpAndSettle();
        expect(find.text('Gdzie zastosować zmianę?'), findsOneWidget);
        await tester.tap(
          find.text(template ? 'Ten trening i szablon' : 'Tylko ten trening'),
        );
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        final field = tester.widget<TextFormField>(
          find.byKey(const ValueKey('preparation-weight-0')),
        );
        expect(field.controller!.text, isEmpty);
        expect(
          (await tester.runAsync(
            () => f.db.select(f.db.workoutPlans).get(),
          ))!.single.cwiczeniaIds,
          '["a","b"]',
        );
        await pressStart(tester);
        final rows = (await tester.runAsync(
          () => f.db.select(f.db.workoutPlans).get(),
        ))!;
        expect(rows.single.cwiczeniaIds, template ? '["c","b"]' : '["a","b"]');
        expect(
          f.container
              .read(activeWorkoutProvider)
              .selectedExercises
              .map((e) => e.id),
          ['c', 'b'],
        );
      },
    );
  }

  testWidgets(
    'last load is displayed but a progression needs explicit acceptance',
    (tester) async {
      final f = await fixture(tester);
      await tester.runAsync(() async {
        for (var i = 1; i <= 2; i++) {
          final session = await f.db.workoutDao.createSession(
            WorkoutSessionsCompanion.insert(
              dataStart: DateTime.utc(2026, 10, i),
              dataKoniec: Value(DateTime.utc(2026, 10, i, 1)),
            ),
          );
          for (var n = 1; n <= 3; n++) {
            await f.db.workoutDao.addSet(
              SetsLogCompanion.insert(
                sesjaId: session,
                cwiczenieId: 'a',
                nazwaCwiczeniaPl: 'Ruch a',
                numerSerii: n,
                side: const Value('both'),
                powtorzenia: const Value(12),
                ciezarKg: const Value(7.25),
                rpe: const Value(7),
              ),
            );
          }
        }
      });
      await openSheet(tester, f);
      expect(find.textContaining('Ostatnio: 7,25'), findsOneWidget);
      final finder = find.byKey(const ValueKey('preparation-weight-0'));
      expect(tester.widget<TextFormField>(finder).controller!.text, '7,25');
      await tester.ensureVisible(find.text('Przyjmij propozycję'));
      await tester.tap(find.text('Przyjmij propozycję'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(finder).controller!.text, '7,75');
      expect(
        await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
        hasLength(2),
      );
    },
  );

  testWidgets('account change hides private preparation and cannot start', (
    tester,
  ) async {
    final f = await fixture(tester);
    await openSheet(tester, f);
    f.authority.generation += 2;
    f.authority.revision.value++;
    await tester.pumpAndSettle();
    expect(find.text('Ruch a'), findsNothing);
    expect(find.textContaining('Konto zmieniło się'), findsOneWidget);
    await pressStart(tester);
    expect(
      await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
      isEmpty,
    );
  });

  for (final width in [320.0, 390.0, 960.0]) {
    testWidgets(
      'preparation controls remain reachable at width$width and text200',
      (tester) async {
        final f = await fixture(tester);
        await openSheet(tester, f, width: width, scale: 2);
        expect(tester.takeException(), isNull);
        await enterWeight(tester, '7,25');
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Zmień ćwiczenie').first);
        await tester.tap(find.byTooltip('Zamknij przygotowanie'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          await tester.runAsync(() => f.db.select(f.db.workoutSessions).get()),
          isEmpty,
        );
      },
    );
  }
}
