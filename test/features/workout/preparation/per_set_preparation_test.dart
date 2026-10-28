import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/workout_preparation.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import '../per_set_guidance_provider_test.dart' show ramp;
import 'preparation_workflow_test.dart' show PreparationFixture;
import 'preparation_sheet_test.dart' show openSheet, pressStart;

Future<PreparationFixture> rampFixture() async {
  final f = await PreparationFixture.create();
  await f.container.read(allExercisesProvider.future);
  final json = ramp(side: 'both').toJson();
  ((json['blocks'] as List).single as Map)['exerciseId'] = 'a';
  await f.container
      .read(plannerWorkflowProvider)
      .saveTemplate(
        await f.container
            .read(plannerWorkflowProvider)
            .openTemplate(syncId: f.planId),
        StructuredPlan.fromJson(json),
        name: 'Rampa',
      );
  return f;
}

void main() {
  test(
    'v2 preparation never applies a scalar historical target or flattens replacements',
    () async {
      final f = await rampFixture();
      addTearDown(f.close);
      final snapshot = await f.workflow.open(planSyncId: f.planId);
      final draft = PreparationDraft(snapshot);
      expect(draft.sessionPlan!.toJson(), snapshot.plan!.toJson());
      expect(
        () => draft.setTarget(
          0,
          const PreparedTarget(weightKg: 80, reps: 20, side: 'both'),
        ),
        throwsStateError,
      );
      expect(draft.candidatesFor(0), isEmpty);
    },
  );

  testWidgets(
    'preparation shows every target and starts unchanged ramp without historical kg prefill',
    (tester) async {
      final f = (await tester.runAsync(rampFixture))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await f.close();
      });
      await tester.runAsync(
        () => f.container.read(activeWorkoutProvider.notifier).flushDraft(),
      );
      await openSheet(tester, f, width: 320, scale: 2);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Rozgrzewkowa'), findsOneWidget);
      expect(find.textContaining('Robocza'), findsOneWidget);
      expect(find.textContaining('5.0 kg'), findsOneWidget);
      expect(find.textContaining('20.0 kg'), findsOneWidget);
      expect(find.byKey(const ValueKey('preparation-weight-0')), findsNothing);
      expect(find.text('Przyjmij propozycję'), findsNothing);
      await pressStart(tester);
      final active = f.container.read(activeWorkoutProvider);
      expect(active.isActive, isTrue);
      expect(active.currentTarget!.targetId, 'warm');
      expect(active.draft['weight'], '5.0');
      expect(
        active
            .guidance!
            .plan
            .blocks
            .single
            .prescription
            .setTargets
            .last
            .weightKg,
        20,
      );
      expect(
        await tester.runAsync(() => f.db.select(f.db.setsLog).get()),
        isEmpty,
      );
    },
  );
}
