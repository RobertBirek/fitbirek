import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/planner/domain/plan_explanation.dart';
import 'plan_explanation_fixtures.dart';

void main() {
  final catalog =
      (jsonDecode(File('assets/data/exercises.json').readAsStringSync())
              as List)
          .map((j) => Exercise.fromJson(j as Map<String, dynamic>))
          .toList();
  final metadata = ExerciseCatalogMetadata.fromJson(
    jsonDecode(
          File('assets/data/exercise_catalog_metadata.json').readAsStringSync(),
        )
        as Map<String, dynamic>,
  );
  final engine = ExerciseFilterEngine(metadata);
  StructuredPlan generate(
    List<Exercise> exercises, {
    ExerciseFilterEngine? using,
    int minutes = 45,
    ExerciseFilters filters = const ExerciseFilters(),
  }) => StructuredPlanGenerator.generate(
    allExercises: exercises,
    engine: using ?? engine,
    criteria: filters,
    equipment: exercises.expand((e) => e.sprzet).toSet().toList(),
    level: 'Zaawansowany',
    minutes: minutes,
  );

  final expected = <String, (int, int?, int, int)>{
    // sets, reps per side (if unilateral), work per set BOTH sides, total incl rests/transition
    'cw364': (1, 3, 9, 24), 'cw365': (3, null, 5, 90),
    'cw366': (1, 3, 18, 33), 'cw367': (1, 3, 18, 33),
    'cw368': (1, 3, 18, 33), 'cw369': (1, 5, 15, 30),
  };
  for (final entry in expected.entries) {
    test(
      'actual ${entry.key}: catalog lower dose, correct seconds and wire v1',
      () {
        final e = catalog.singleWhere((e) => e.id == entry.key);
        final plan = generate([
          e,
        ], filters: const ExerciseFilters(styles: {'spine'}));
        final p = plan.blocks.single.prescription;
        expect((p.sets, p.reps, p.workSeconds, p.totalSeconds), entry.value);
        if (e.id == 'cw365') expect(p.sets * p.workSeconds, 15);
        expect(plan.toJson()['schemaVersion'], 1);
        expect(StructuredPlan.fromJson(plan.toJson()).toJson(), plan.toJson());
        expect(plan.warnings.join(), isNot(contains('domyśln')));
      },
    );
  }

  PlanPrescription fixture(
    String raw, {
    String tracking = 'reps',
    bool side = false,
  }) {
    final e = explanationExercise(
      'fixture',
    ).copyWith(seriexPowtorzenia: raw, tempo: '4-2-8; 20 sekund pauzy');
    final md = ExerciseCatalogMetadata(
      exercises: {
        'fixture': ExerciseCatalogEntry(tracking: tracking, unilateral: side),
      },
    );
    return generate([
      e,
    ], using: ExerciseFilterEngine(md)).blocks.single.prescription;
  }

  final forms = <String, (String, bool, int, int?, int)>{
    '1 x 3-5': ('reps', false, 1, 3, 9),
    '2–3 × 4–6 powt. na stronę': ('reps', true, 2, 4, 24),
    '3 x 5 sek': ('time', false, 3, null, 5),
    '1 x 1-2 min': ('time', false, 1, null, 60),
    '2 x 5 s na stronę': ('time', true, 2, null, 10),
    '1 x 5 sec': ('time', false, 1, null, 5),
    '1 min': ('time', false, 1, null, 60),
  };
  for (final form in forms.entries) {
    test('strict dose grammar ${form.key}', () {
      final (tracking, side, sets, reps, work) = form.value;
      final p = fixture(form.key, tracking: tracking, side: side);
      expect((p.sets, p.reps, p.workSeconds), (sets, reps, work));
    });
  }

  test(
    'unknown text, invalid ranges and mismatched units never supply digits as targets',
    () {
      for (final raw in [
        '',
        'tempo 4-2-1',
        '1 x 3-5 wolno',
        '3 x 5 x 5 sek',
        '0 x 3',
        '1 x 0',
        '3-1 x 5',
        '1 x 5-3',
        '1 x -3',
        '1 x 3.5',
        '1 x 5 sek',
        '1 x 3 na stronę',
        '1 x 3 lub 6',
        '2 x 20 kg',
        '999999999999999999999999999999 x 99999999999999999999999',
      ]) {
        final e = explanationExercise(
          'fixture',
        ).copyWith(seriexPowtorzenia: raw, tempo: '1 x 2; 5 sek');
        final md = ExerciseCatalogMetadata(
          exercises: {
            'fixture': const ExerciseCatalogEntry(
              tracking: 'reps',
              unilateral: false,
            ),
          },
        );
        final plan = generate([e], using: ExerciseFilterEngine(md));
        final p = plan.blocks.single.prescription;
        expect((p.sets, p.reps, p.workSeconds), (3, 10, 30), reason: raw);
        expect(plan.warnings.join(), contains('domyślna dawka'), reason: raw);
        expect(plan.warnings.join(), contains('ESTYMOWANY'), reason: raw);
      }
      expect(fixture('1 x 5', tracking: 'time').workSeconds, 40);
      expect(fixture('1 x 5 min', tracking: 'reps').reps, 10);
      expect(fixture('1 x 5', tracking: 'rounds').workSeconds, 40);
    },
  );

  test(
    'all current catalog budgets, explicit spine and no filter broadening',
    () {
      expect(catalog, hasLength(424));
      for (final filters in [
        const ExerciseFilters(),
        const ExerciseFilters(styles: {'spine'}),
      ]) {
        final pool = engine.filter(catalog, filters).map((e) => e.id).toSet();
        final budgets = filters.styles.isEmpty
            ? [5, 15, 45, 90]
            : [for (var m = 5; m <= 90; m++) m];
        for (final m in budgets) {
          final p = generate(catalog, minutes: m, filters: filters);
          expect(p.blocks, isNotEmpty);
          expect(p.estimatedSeconds, lessThanOrEqualTo(p.budgetSeconds));
          expect(p.exerciseIds.every(pool.contains), isTrue);
          expect(
            p.blocks.every(
              (b) => b.prescription.workSeconds > 0 && b.prescription.sets > 0,
            ),
            isTrue,
          );
        }
      }
    },
  );

  test('clone gets source dose independent of cw ID or collection', () {
    final original = catalog.singleWhere((e) => e.id == 'cw367');
    final clone = original.copyWith(id: 'custom-open-book');
    final entry = metadata.entryFor(original.id)!;
    final md = ExerciseCatalogMetadata(
      exercises: {
        clone.id: ExerciseCatalogEntry(
          tracking: entry.tracking,
          unilateral: entry.unilateral,
        ),
      },
    );
    final p = generate([
      clone,
    ], using: ExerciseFilterEngine(md)).blocks.single.prescription;
    expect((p.sets, p.reps, p.workSeconds), (1, 3, 18));
  });

  test(
    'valid catalog dose over budget is skipped, never shrunk to a default',
    () {
      final e = explanationExercise(
        'long',
      ).copyWith(seriexPowtorzenia: '1 x 120 min');
      final using = ExerciseFilterEngine(
        const ExerciseCatalogMetadata(
          exercises: {
            'long': ExerciseCatalogEntry(tracking: 'time', unilateral: false),
          },
        ),
      );
      final plan = generate([e], using: using, minutes: 90);
      expect(plan.blocks, isEmpty);
      expect(plan.estimatedSeconds, 0);
      expect(plan.warnings.join(), isNot(contains('domyślna dawka')));
    },
  );

  test(
    'replacement recomputes source goals, preserves other blocks and total',
    () {
      final original = catalog.singleWhere((e) => e.id == 'cw367');
      final clone = original.copyWith(id: 'clone');
      final md = ExerciseCatalogMetadata(
        exercises: {
          ...metadata.exercises,
          clone.id: metadata.entryFor(original.id)!,
        },
      );
      final using = ExerciseFilterEngine(md);
      final plan = generate([
        catalog.singleWhere((e) => e.id == 'cw369'),
        original,
      ], using: using);
      final index = plan.blocks.indexWhere((b) => b.exerciseId == original.id);
      final replacement = StructuredPlanGenerator.replace(
        plan: plan,
        index: index,
        allExercises: [original, clone],
        engine: using,
        equipment: plan.equipment,
        level: plan.level,
      )!;
      final p = replacement.blocks[index].prescription;
      expect((p.sets, p.reps, p.workSeconds), (1, 3, 18));
      expect(replacement.estimatedSeconds, plan.estimatedSeconds);
      expect(identical(replacement.blocks.first, plan.blocks.first), isTrue);
      final legacy = StructuredPlan(
        criteria: plan.criteria,
        budgetSeconds: 2700,
        equipment: plan.equipment,
        blocks: [
          PlanBlock(
            exerciseId: original.id,
            section: PlanSection.main,
            prescription: const PlanPrescription(
              tracking: 'reps',
              sets: 3,
              reps: 10,
              workSeconds: 60,
              restSeconds: 30,
              transitionSeconds: 15,
            ),
          ),
        ],
        warnings: [],
      );
      expect(
        StructuredPlanGenerator.replace(
          plan: legacy,
          index: 0,
          allExercises: [original, clone],
          engine: using,
          equipment: plan.equipment,
          level: plan.level,
        ),
        isNull,
      );
    },
  );

  test(
    'replacement with same total but different goals explains actual differences',
    () {
      final a = explanationExercise('a').copyWith(seriexPowtorzenia: '1 x 22');
      final b = explanationExercise('b').copyWith(seriexPowtorzenia: '2 x 6');
      final plan = generate(
        [a],
        using: ExerciseFilterEngine(
          const ExerciseCatalogMetadata(
            exercises: {
              'a': ExerciseCatalogEntry(tracking: 'reps', unilateral: false),
            },
          ),
        ),
      );
      final using = ExerciseFilterEngine(
        const ExerciseCatalogMetadata(
          exercises: {
            'a': ExerciseCatalogEntry(tracking: 'reps', unilateral: false),
            'b': ExerciseCatalogEntry(tracking: 'reps', unilateral: false),
          },
        ),
      );
      final replacement = StructuredPlanGenerator.replace(
        plan: plan,
        index: 0,
        allExercises: [a, b],
        engine: using,
        equipment: plan.equipment,
        level: plan.level,
      )!;
      expect(replacement.estimatedSeconds, plan.estimatedSeconds);
      expect(replacement.blocks.single.prescription.reps, 6);
      final text = PlanExplanation.forReplacement(
        plan: plan,
        replacement: replacement,
        index: 0,
        allExercises: [a, b],
        engine: using,
      ).join('\n');
      expect(text, contains('Serie: 1 → 2'));
      expect(text, contains('Powtórzenia: 22 → 6'));
    },
  );

  test(
    'fallback warning follows replacement without changing unrelated warnings',
    () {
      final a = explanationExercise('a');
      final b = explanationExercise('b');
      final using = ExerciseFilterEngine(
        const ExerciseCatalogMetadata(
          exercises: {
            'a': ExerciseCatalogEntry(tracking: 'reps', unilateral: false),
            'b': ExerciseCatalogEntry(tracking: 'reps', unilateral: false),
          },
        ),
      );
      final plan = generate([a], using: using);
      final replacement = StructuredPlanGenerator.replace(
        plan: plan,
        index: 0,
        allExercises: [a, b],
        engine: using,
        equipment: plan.equipment,
        level: plan.level,
      )!;
      expect(replacement.warnings.where((w) => w.startsWith('a:')), isEmpty);
      expect(
        replacement.warnings.where((w) => w.startsWith('b:')),
        hasLength(1),
      );
      expect(
        replacement.warnings,
        containsAll(plan.warnings.where((w) => !w.startsWith('a:'))),
      );
      expect(plan.warnings.any((w) => w.startsWith('a:')), isTrue);
    },
  );
}
