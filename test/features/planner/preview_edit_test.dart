import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import '../exercises/catalog_filter_test.dart' show exercise;

StructuredPlan preview({
  int budget = 300,
  int sets = 3,
  int rest = 30,
  int work = 30,
}) => StructuredPlan(
  criteria: const ExerciseFilters(query: 'Ruch'),
  budgetSeconds: budget,
  level: 'Średni',
  equipment: const ['Hantle'],
  warnings: const ['Zachowaj ostrzeżenie'],
  blocks: [
    PlanBlock(
      exerciseId: 'a',
      section: PlanSection.main,
      prescription: PlanPrescription(
        tracking: 'reps',
        sets: sets,
        reps: 10,
        workSeconds: work,
        restSeconds: rest,
        transitionSeconds: 15,
        weightKg: 12.5,
      ),
    ),
    const PlanBlock(
      exerciseId: 'other',
      section: PlanSection.cooldown,
      prescription: PlanPrescription(
        tracking: 'time',
        sets: 1,
        workSeconds: 30,
        restSeconds: 0,
        transitionSeconds: 15,
      ),
    ),
  ],
);

void main() {
  test(
    'rest preview preserves every other target and block, original and wire v1',
    () {
      final original = preview();
      final before = original.toJson();
      final edited = StructuredPlanGenerator.withRest(
        plan: original,
        index: 0,
        restSeconds: 60,
      )!;
      expect(original.toJson(), before);
      expect(edited.estimatedSeconds, 270);
      expect(edited.budgetSeconds, 300);
      expect(edited.blocks[0].prescription.toJson(), {
        'tracking': 'reps',
        'sets': 3,
        'reps': 10,
        'workSeconds': 30,
        'restSeconds': 60,
        'transitionSeconds': 15,
        'weightKg': 12.5,
      });
      expect(identical(edited.blocks[1], original.blocks[1]), isTrue);
      expect(edited.criteria.query, 'Ruch');
      expect(edited.warnings, ['Zachowaj ostrzeżenie']);
      expect(
        StructuredPlan.fromJson(edited.toJson()).toJson(),
        edited.toJson(),
      );
    },
  );
  test(
    'zero and 600s allowed, invalid new values rejected without normalizing old snapshots',
    () {
      final original = preview(budget: 5400, rest: 1000);
      expect(
        StructuredPlan.fromJson(
          original.toJson(),
        ).blocks[0].prescription.restSeconds,
        1000,
      );
      for (final rest in [0, 600]) {
        final edited = StructuredPlanGenerator.withRest(
          plan: original,
          index: 0,
          restSeconds: rest,
        )!;
        expect(edited.blocks[0].prescription.restSeconds, rest);
        expect(edited.estimatedSeconds, rest == 0 ? 150 : 1350);
        expect(
          StructuredPlan.fromJson(edited.toJson()).toJson(),
          edited.toJson(),
        );
      }
      for (final rest in [-1, 601, 5400]) {
        expect(
          () => StructuredPlanGenerator.withRest(
            plan: original,
            index: 0,
            restSeconds: rest,
          ),
          throwsArgumentError,
        );
      }
      expect(original.blocks[0].prescription.restSeconds, 1000);
    },
  );
  test('single set never adds a final rest or changes budget', () {
    final original = preview(sets: 1);
    final edited = StructuredPlanGenerator.withRest(
      plan: original,
      index: 0,
      restSeconds: 600,
    )!;
    expect(edited.estimatedSeconds, 90);
    expect(edited.budgetSeconds, 300);
  });
  test(
    'over-budget preview requires explicit permission, rounded budget and unchanged blocks',
    () {
      final original = preview();
      expect(
        StructuredPlanGenerator.withRest(
          plan: original,
          index: 0,
          restSeconds: 91,
        ),
        isNull,
      );
      final edited = StructuredPlanGenerator.withRest(
        plan: original,
        index: 0,
        restSeconds: 91,
        allowBudgetIncrease: true,
      )!;
      expect(edited.estimatedSeconds, 332);
      expect(edited.budgetSeconds, 360);
      expect(identical(edited.blocks[1], original.blocks[1]), isTrue);
      expect(edited.blocks[0].prescription.sets, 3);
      expect(edited.blocks[0].prescription.restSeconds, 91);
      expect(
        StructuredPlan.fromJson(edited.toJson()).toJson(),
        edited.toJson(),
      );
      expect(original.budgetSeconds, 300);
    },
  );
  test(
    'exact 5400 accepted, over 5400 refused even with permission without truncating dose',
    () {
      final exact = preview(budget: 5400, sets: 10, rest: 0, work: 534);
      expect(exact.estimatedSeconds, 5400);
      expect(
        StructuredPlanGenerator.withRest(
          plan: exact,
          index: 0,
          restSeconds: 0,
          allowBudgetIncrease: true,
        )?.estimatedSeconds,
        5400,
      );
      expect(
        StructuredPlanGenerator.withRest(
          plan: exact,
          index: 0,
          restSeconds: 1,
          allowBudgetIncrease: true,
        ),
        isNull,
      );
      expect(exact.blocks[0].prescription.sets, 10);
    },
  );
  test(
    'replacement proposal increases budget only explicitly, max cap never silently shrinks dose',
    () {
      final a = exercise('a').copyWith(wzorzecRuchu: 'Push horyzontalny');
      final b = a.copyWith(id: 'b', seriexPowtorzenia: '3 x 30');
      final engine = ExerciseFilterEngine(
        const ExerciseCatalogMetadata(
          exercises: {
            'a': ExerciseCatalogEntry(
              tracking: 'reps',
              unilateral: false,
              primaryMuscles: ['chest'],
            ),
            'b': ExerciseCatalogEntry(
              tracking: 'reps',
              unilateral: false,
              primaryMuscles: ['chest'],
            ),
          },
        ),
      );
      final original = preview();
      StructuredPlan? propose({bool increase = false, String? dose}) =>
          StructuredPlanGenerator.replace(
            plan: original,
            index: 0,
            allExercises: [
              a,
              dose == null ? b : b.copyWith(seriexPowtorzenia: dose),
            ],
            engine: engine,
            equipment: ['Hantle'],
            level: 'Średni',
            allowBudgetIncrease: increase,
          );
      expect(propose(), isNull);
      final edited = propose(increase: true)!;
      expect(
        edited.estimatedSeconds,
        570,
      ); // 270 work + 240 rest + 15 transition +45 other
      expect(edited.budgetSeconds, 600);
      expect(edited.blocks[0].prescription.weightKg, isNull);
      expect(identical(edited.blocks[1], original.blocks[1]), isTrue);
      expect(
        StructuredPlan.fromJson(edited.toJson()).toJson(),
        edited.toJson(),
      );
      expect(propose(increase: true, dose: '1 x 1800'), isNull);
    },
  );
  test(
    'manual rest no longer claims that the 30s policy fallback is in use',
    () {
      final e = exercise('a').copyWith(seriexPowtorzenia: '3 x 10');
      final engine = ExerciseFilterEngine(
        const ExerciseCatalogMetadata(
          exercises: {
            'a': ExerciseCatalogEntry(
              tracking: 'reps',
              unilateral: false,
              primaryMuscles: ['back'],
            ),
          },
        ),
      );
      final plan = StructuredPlanGenerator.generate(
        allExercises: [e],
        engine: engine,
        criteria: const ExerciseFilters(),
        equipment: ['Hantle'],
        level: 'Średni',
        minutes: 10,
      );
      expect(plan.warnings.join(), contains('polityki przerw'));
      final edited = StructuredPlanGenerator.withRest(
        plan: plan,
        index: 0,
        restSeconds: 60,
      )!;
      expect(edited.warnings.join(), isNot(contains('polityki przerw')));
      expect(
        edited.warnings,
        plan.warnings.where((w) => !w.startsWith('a:')).toList(),
      );
      expect(plan.blocks.single.prescription.restSeconds, 30);
    },
  );
}
