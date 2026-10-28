import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/template_editor_page.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import '../workout/per_set_guidance_provider_test.dart' show ramp;
import '../workout/session_tracking_test.dart' show exercise;

void main() {
  for (final settings in [
    (false, 'save'),
    (false, 'cancel'),
    (false, 'stale'),
    (true, 'save'),
  ]) {
    final time = settings.$1, outcome = settings.$2;
    testWidgets(
      'per-set edit role/side/dose add/delete/reorder preserves IDs: time=$time $outcome',
      (tester) async {
        tester.view.physicalSize = Size(time ? 320 : 390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
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
                  exercise.id: ExerciseCatalogEntry(
                    tracking: time ? 'time' : 'reps',
                    unilateral: true,
                  ),
                },
              ),
            ),
          ],
        );
        final plan = ramp(side: 'both', time: time);
        await c.read(allExercisesProvider.future);
        final workflow = c.read(plannerWorkflowProvider);
        await workflow.saveTemplate(
          await workflow.openTemplate(),
          plan,
          name: 'Rampa',
        );
        final row = await db.select(db.workoutPlans).getSingle();
        final before = await db.select(db.syncOutbox).get();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => TemplateEditorPage(syncId: row.syncId),
            ),
            GoRoute(
              path: '/workout/templates',
              builder: (_, _) => const Scaffold(body: Text('Zapisano')),
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
            child: MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(time ? 2 : 1),
                  viewInsets: EdgeInsets.only(bottom: time ? 180 : 0),
                ),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Rozgrzewkowa'), findsWidgets);
        Future<void> reveal(Finder f) async {
          await tester.scrollUntilVisible(
            f,
            200,
            scrollable: find.byType(Scrollable).first,
            maxScrolls: 60,
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
        }

        Future<void> enter(String key, String value) async {
          final f = find.byKey(ValueKey(key));
          await reveal(f);
          await tester.enterText(f, value);
        }

        final role = find.byKey(const ValueKey('target-warm-role'));
        await reveal(role);
        await tester.tap(role);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Robocza').last);
        await tester.pumpAndSettle();
        final side = find.byKey(const ValueKey('target-warm-side'));
        await reveal(side);
        await tester.tap(side);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lewa').last);
        await tester.pumpAndSettle();
        await enter('target-warm-amount', '14');
        await enter('target-warm-kg', '7,5');
        await enter('target-warm-rest', '25');
        await enter('target-warm-work', '84');
        final down = find.byKey(const ValueKey('target-warm-down'));
        await reveal(down);
        await tester.tap(down);
        await tester.pumpAndSettle();
        final add = find.text('Dodaj serię');
        await reveal(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        final deletes = find.byTooltip('Usuń serię');
        await reveal(deletes.last);
        await tester.tap(deletes.last);
        await tester.pumpAndSettle();
        expect(
          await db.select(db.syncOutbox).get(),
          before,
          reason: 'editing is not a write',
        );
        await tester.tap(find.text('Zapisz szablon'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        if (outcome == 'stale') {
          await db.customStatement('UPDATE workout_plans SET nazwa = ?', [
            'Inny widok',
          ]);
        }
        await tester.tap(
          find.text(outcome == 'cancel' ? 'Anuluj' : 'Potwierdź'),
        );
        await tester.pumpAndSettle();
        if (outcome != 'save') {
          final after = await db.select(db.workoutPlans).getSingle();
          expect(after.structureJson, row.structureJson);
          expect(await db.select(db.syncOutbox).get(), before);
        } else {
          final after = StructuredPlan.fromJson(
            jsonDecode(
                  (await db.select(db.workoutPlans).getSingle()).structureJson!,
                )
                as Map<String, dynamic>,
          );
          final targets = after.blocks.single.prescription.setTargets;
          expect(after.schemaVersion, 2);
          expect(targets.map((t) => t.targetId), ['work', 'warm']);
          expect(targets.last.setRole, 'working');
          expect(targets.last.side, 'left');
          expect(time ? targets.last.seconds : targets.last.reps, 14);
          expect(targets.last.weightKg, 7.5);
          expect(targets.last.restSeconds, 25);
          expect(targets.last.workSeconds, 84);
          expect(
            targets.first.toJson(),
            plan.blocks.single.prescription.setTargets.last.toJson(),
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
