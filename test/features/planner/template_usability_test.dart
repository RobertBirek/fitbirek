import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/app/theme.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/template_editor_page.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import '../exercises/catalog_filter_test.dart' show exercise, metadata;
import 'structured_plan_persistence_test.dart' show structure;
import '../../helpers/min_interactive_target.dart';

Future<void> mount(
  WidgetTester tester,
  Size size, {
  double scale = 1,
  double keyboard = 0,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        allExercisesProvider.overrideWith(
          (ref) => Stream.value([
            exercise('b', name: 'Pierwsze'),
            exercise('a', name: 'Drugie'),
            exercise('c', name: 'Trzecie'),
          ]),
        ),
        exerciseCatalogMetadataProvider.overrideWith(
          (ref) async => ExerciseCatalogMetadata(
            exercises: {...metadata.exercises, 'c': metadata.entryFor('b')!},
          ),
        ),
      ],
      child: MaterialApp(
        theme: FitBirekTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: child!,
        ),
        home: Scaffold(
          bottomNavigationBar: const SizedBox(
            height: 64,
            child: Text('Globalne zakładki'),
          ),
          body: TemplateEditorPage(
            seed: TemplateEditorSeed(
              StructuredPlan(
                criteria: structure.criteria,
                budgetSeconds: structure.budgetSeconds,
                warnings: structure.warnings,
                blocks: [
                  for (final id in ['a', 'b'])
                    PlanBlock(
                      exerciseId: id,
                      section: structure.blocks.first.section,
                      prescription: structure.blocks.first.prescription,
                    ),
                ],
              ),
              name: 'Poranny',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [1280.0, 375.0, 320.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'web desktop density Save surface and hitbox >=48 width=$width text=$scale',
        (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.linux;
          final semantics = tester.ensureSemantics();
          try {
            final keyboard = scale == 2 ? 180.0 : 0.0;
            await mount(
              tester,
              Size(width, 740),
              scale: scale,
              keyboard: keyboard,
            );
            final save = find.widgetWithText(FilledButton, 'Zapisz szablon');
            final interactive = find.descendant(
              of: save,
              matching: find.byType(InkWell),
            );
            final surface = find.descendant(
              of: save,
              matching: find.byType(Material),
            );
            expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(surface).height, greaterThanOrEqualTo(48));
            expect(
              tester.getSize(interactive).height,
              greaterThanOrEqualTo(48),
            );
            expect(tester.getSize(interactive).width, greaterThanOrEqualTo(48));
            expect(
              tester.getSemantics(save).rect.height,
              greaterThanOrEqualTo(48),
            );
            final box = tester.renderObject<RenderBox>(interactive);
            final rect = tester.getRect(interactive);
            debugPrint(
              'Save width=$width text=$scale: button=${tester.getSize(save).height}, surface=${tester.getSize(surface).height}, interactive=${rect.height}, semantics=${tester.getSemantics(save).rect.height}',
            );
            for (final dy in [1.0, 47.0]) {
              final hits = tester.hitTestOnBinding(
                Offset(rect.center.dx, rect.top + dy),
              );
              expect(
                hits.path.any((entry) => identical(entry.target, box)),
                isTrue,
              );
            }
            expect(rect.bottom, lessThanOrEqualTo(740 - keyboard));
            expect(
              rect.bottom,
              lessThanOrEqualTo(
                tester.getTopLeft(find.text('Globalne zakładki')).dy,
              ),
            );
            expect(tester.takeException(), isNull);
            for (final control in [
              find
                  .ancestor(
                    of: find.text('Parametry ćwiczenia'),
                    matching: find.byWidgetPredicate((w) => w is TextButton),
                  )
                  .first,
              find.widgetWithIcon(IconButton, Icons.arrow_downward).first,
              find.widgetWithIcon(IconButton, Icons.arrow_upward).last,
              find.widgetWithIcon(IconButton, Icons.delete_outline).first,
              find.widgetWithIcon(IconButton, Icons.add).first,
            ]) {
              await tester.ensureVisible(control);
              await tester.pumpAndSettle();
              expectMinInteractiveTarget(tester, control);
            }
          } finally {
            semantics.dispose();
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );
    }
  }
  testWidgets(
    'collapse, reorder and responsive rebuild keep drafts; added exercise opens',
    (tester) async {
      await mount(tester, const Size(1280, 1500));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Serie').first,
        '7',
      );
      await tester.tap(find.text('Parametry ćwiczenia').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Przesuń w dół').first);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(768, 1500);
      await tester.pumpAndSettle();
      expect(find.textContaining('7 × 40'), findsOneWidget);
      await tester.tap(find.text('Parametry ćwiczenia').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Serie').last,
            )
            .controller!
            .text,
        '7',
      );
      final add = find.byTooltip('Dodaj ćwiczenie').first;
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      final fields = find.widgetWithText(TextFormField, 'Serie');
      expect(fields, findsNWidgets(3));
      expect(tester.widget<TextFormField>(fields.last).controller!.text, '3');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('desktop at text200 switches to one bounded column', (
    tester,
  ) async {
    await mount(tester, const Size(1280, 2000), scale: 2);
    final name = tester.getRect(
      find.widgetWithText(TextFormField, 'Nazwa szablonu'),
    );
    final search = tester.getRect(
      find.widgetWithText(TextField, 'Szukaj ćwiczenia'),
    );
    expect(search.top, greaterThan(name.bottom));
    expect(name.width, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'save remains hit-testable above tabs with two exercises and keyboard at 200%',
    (tester) async {
      await mount(tester, const Size(320, 640), scale: 2, keyboard: 180);
      final save = find.widgetWithText(FilledButton, 'Zapisz szablon');
      expect(save.hitTestable(), findsOneWidget);
      final rect = tester.getRect(save);
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.bottom, lessThanOrEqualTo(640 - 180));
      expect(
        rect.bottom,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Globalne zakładki')).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'desktop puts picker right of chosen exercises within a bounded measure',
    (tester) async {
      await mount(tester, const Size(1280, 1000));
      final name = tester.getRect(
        find.widgetWithText(TextFormField, 'Nazwa szablonu'),
      );
      final search = tester.getRect(
        find.widgetWithText(TextField, 'Szukaj ćwiczenia'),
      );
      expect(search.left, greaterThan(name.right));
      expect(name.width, lessThanOrEqualTo(640));
      expect(search.right - name.left, lessThanOrEqualTo(1100));
    },
  );
  testWidgets(
    'collapsed invalid prescription opens before validation and controllers survive reorder',
    (tester) async {
      await mount(tester, const Size(800, 1800));
      final controller = tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Serie').first,
          )
          .controller;
      final sets = find.byWidgetPredicate(
        (w) => w is TextFormField && identical(w.controller, controller),
      );
      await tester.enterText(sets, '0');
      await tester.tap(find.text('Parametry ćwiczenia').first);
      await tester.pumpAndSettle();
      expect(sets.hitTestable(), findsNothing);
      await tester.tap(find.text('Zapisz szablon'));
      await tester.pumpAndSettle();
      expect(find.text('Podaj dodatnią liczbę całkowitą.'), findsOneWidget);
      expect(sets.hitTestable(), findsOneWidget);
      expect(tester.widget<TextFormField>(sets).controller!.text, '0');
    },
  );
}
