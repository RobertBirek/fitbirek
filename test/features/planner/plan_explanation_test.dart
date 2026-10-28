import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/planner/domain/plan_explanation.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'plan_explanation_fixtures.dart';

void main() {
  test(
    'safe replacement explains family, unilateral, primary and whole time/budget delta',
    () {
      final md = ExerciseCatalogMetadata(
        exercises: {
          'a': explanationMetadata.exercises['a']!,
          'b': explanationMetadata.exercises['a']!,
        },
        muscles: explanationMetadata.muscles,
      );
      final e = ExerciseFilterEngine(md);
      final catalog = [
        for (final id in ['a', 'b'])
          explanationExercise(id).copyWith(
            typ: 'Wytrzymałość',
            wzorzecRuchu: 'Pull horyzontalny',
            seriexPowtorzenia: id == 'a' ? '3 x 40 s' : '3 x 100 s',
          ),
      ];
      final base = explanationPlan();
      final plan = StructuredPlan(
        criteria: base.criteria,
        budgetSeconds: 300,
        blocks: base.blocks,
        warnings: [],
        equipment: ['Mata'],
      );
      final proposal = StructuredPlanGenerator.replace(
        plan: plan,
        index: 0,
        allExercises: catalog,
        engine: e,
        equipment: ['Mata'],
        level: plan.level,
        allowBudgetIncrease: true,
      )!;
      final text = PlanExplanation.forReplacement(
        plan: plan,
        replacement: proposal,
        index: 0,
        allExercises: catalog,
        engine: e,
      ).join('\n');
      expect(text, contains('Zgodna rodzina ruchu:'));
      expect(text, contains('Jednostronność: nie → nie'));
      expect(text, contains('195 s → 375 s'));
      expect(text, contains('300 s → 420 s'));
      expect(
        text,
        isNot(
          contains(
            'wymaga tej samej filtrowanej puli, sekcji, sposobu rejestrowania i czasu',
          ),
        ),
      );
    },
  );
  final engine = ExerciseFilterEngine(explanationMetadata);
  final a = explanationExercise('a');
  List<String> explain(
    StructuredPlan plan, {
    ExerciseFilterEngine? withEngine,
  }) => PlanExplanation.forBlock(
    plan: plan,
    index: 0,
    allExercises: [a],
    engine: withEngine ?? engine,
  );

  test(
    'matched OR alternatives only, labels and muscle roles; deterministic',
    () {
      final plan = explanationPlan(
        criteria: const ExerciseFilters(
          styles: {'missing', 'collection'},
          muscles: {'abs'},
          conditions: {'quiet'},
          positions: {'standing', 'floor'},
          sprzet: {'Krzesło', 'Mata'},
          poziomy: {'Początkujący'},
          typy: {'Siła'},
          partie: {'Plecy'},
          query: 'ruchowa',
        ),
      );
      final lines = explain(plan);
      final text = lines.join('\n');
      expect(text, contains('Styl / kolekcja: Kolekcja ruchu'));
      expect(text, contains('Mięśnie główne: Plecy'));
      expect(text, contains('Mięśnie wspierające: Brzuch'));
      expect(text, contains('Wybrane mięśnie: Brzuch'));
      expect(text, contains('Warunki: Cichy trening'));
      expect(text, contains('Pozycje: Na podłodze'));
      expect(text, isNot(contains('Stojąco')));
      expect(text, isNot(contains('missing')));
      expect(text, contains('Sprzęt wymagany: Mata'));
      expect(text, contains('Poziom: Początkujący ≤ Średni'));
      expect(text, contains('Wzorzec ruchu: Pull + stabilizacja'));
      expect(text, contains('Wyszukiwanie: ruchowa'));
      expect(explain(plan), lines);
      expect(plan.toJson().keys, isNot(contains('reasons')));
      expect(() => lines.add('mutacja'), throwsUnsupportedError);
    },
  );

  test('stale mismatch never claims criteria or profile suitability', () {
    final text = explain(
      explanationPlan(criteria: const ExerciseFilters(positions: {'standing'})),
    ).join('\n');
    expect(text, contains('nie należy do aktualnej puli'));
    expect(text, isNot(contains('Pozycje:')));
    expect(text, isNot(contains('≤')));
  });

  test(
    'missing classification and execution data fail closed, no invented reasons',
    () {
      final missing = ExerciseFilterEngine(
        const ExerciseCatalogMetadata(),
        classificationAvailable: false,
      );
      for (final filters in [
        const ExerciseFilters(styles: {'collection'}),
        const ExerciseFilters(conditions: {'quiet'}),
      ]) {
        final text = explain(
          explanationPlan(criteria: filters),
          withEngine: missing,
        ).join('\n');
        expect(text, contains('Nie można zweryfikować'));
        expect(text, isNot(contains('Warunki:')));
        expect(text, isNot(contains('Styl / kolekcja:')));
      }
    },
  );

  test(
    'missing exercise and missing metadata do not invent anatomy or tracking',
    () {
      expect(
        PlanExplanation.forBlock(
          plan: explanationPlan(),
          index: 0,
          allExercises: const [],
          engine: engine,
        ).join(),
        contains('Niedostępne'),
      );
      final text = explain(
        explanationPlan(),
        withEngine: ExerciseFilterEngine(const ExerciseCatalogMetadata()),
      ).join('\n');
      expect(text, contains('Brak metadanych'));
      expect(text, isNot(contains('Mięśnie główne:')));
    },
  );

  test(
    'diversity is checked against resolved previous preview blocks, never inferred from class',
    () {
      final b = explanationExercise(
        'b',
      ).copyWith(wzorzecRuchu: 'Push (poziomy)');
      final plan = explanationPlan(ids: ['a', 'b']);
      final lines = PlanExplanation.forBlock(
        plan: plan,
        index: 1,
        allExercises: [a, b],
        engine: engine,
      ).join('\n');
      expect(
        lines,
        contains('Nowy wzorzec względem wcześniejszych bloków podglądu'),
      );
      final same = PlanExplanation.forBlock(
        plan: plan,
        index: 1,
        allExercises: [
          a,
          b.copyWith(wzorzecRuchu: 'Pull (inny)'),
        ],
        engine: engine,
      ).join('\n');
      expect(same, isNot(contains('Nowy wzorzec')));
      final unresolved = PlanExplanation.forBlock(
        plan: plan,
        index: 1,
        allExercises: [b],
        engine: engine,
      ).join('\n');
      expect(unresolved, isNot(contains('Nowy wzorzec')));
    },
  );

  test(
    'replacement describes actual invariants and role-specific differences without mutation',
    () {
      final b = explanationExercise(
        'b',
      ).copyWith(sprzet: ['Krzesło'], poziom: 'Średni', wzorzecRuchu: 'Push');
      final plan = explanationPlan();
      final before = plan.toJson();
      // Historical snapshots may describe a formerly accepted, incompatible
      // swap. Explain that data, rather than asking the safe engine to make it.
      final replacement = explanationPlan(ids: ['b']);
      final text = PlanExplanation.forReplacement(
        plan: plan,
        replacement: replacement,
        index: 0,
        allExercises: [a, b],
        engine: engine,
      ).join('\n');
      expect(text, contains('Ta sama sekcja: Praca'));
      expect(text, contains('Ten sam sposób rejestrowania: time'));
      expect(text, contains('Ten sam czas ESTYMOWANY: 195 s'));
      expect(text, contains('Sprzęt: Mata → Krzesło'));
      expect(text, contains('Mięśnie główne: Plecy → Brzuch'));
      expect(text, contains('Mięśnie wspierające: Brzuch → Plecy'));
      expect(text, contains('Wzorzec ruchu: Pull + stabilizacja → Push'));
      expect(text, contains('Poziom: Początkujący → Średni'));
      expect(plan.toJson(), before);
    },
  );

  test('current equipment override explains the shared engine pool', () {
    final plan = explanationPlan();
    final b = explanationExercise('b').copyWith(sprzet: ['Guma']);
    final replacement = explanationPlan(ids: ['b']);
    final text = PlanExplanation.forReplacement(
      plan: plan,
      replacement: replacement,
      index: 0,
      allExercises: [a, b],
      engine: engine,
      equipment: ['Guma'],
    ).join('\n');
    expect(text, contains('Spełnia zapisane kryteria puli'));
    expect(text, isNot(contains('nie należy')));
  });

  test(
    'all equipment and explicit level ranks are verified, favorites and query too',
    () {
      for (final e in [
        a.copyWith(sprzet: ['Mata', 'Guma']),
        a.copyWith(poziom: 'Zaawansowany'),
        a.copyWith(poziom: 'Nieznany'),
      ]) {
        expect(
          PlanExplanation.forBlock(
            plan: explanationPlan(),
            index: 0,
            allExercises: [e],
            engine: engine,
          ).join(),
          contains('nie należy'),
        );
      }
      for (final criteria in [
        const ExerciseFilters(tylkoUlubione: true),
        const ExerciseFilters(query: 'brak dopasowania'),
      ]) {
        expect(
          explain(explanationPlan(criteria: criteria)).join(),
          contains('nie należy'),
        );
      }
      final text = PlanExplanation.forBlock(
        plan: explanationPlan(
          criteria: const ExerciseFilters(tylkoUlubione: true),
        ),
        index: 0,
        allExercises: [
          a.copyWith(ulubione: true, sprzet: [], wzorzecRuchu: ''),
        ],
        engine: engine,
      ).join('\n');
      expect(text, contains('Sprzęt wymagany: brak'));
      expect(text, contains('jest w ulubionych'));
      expect(text, isNot(contains('Wzorzec ruchu:')));
      expect(text, isNot(contains('Nowy wzorzec')));
    },
  );

  test('verified additional muscles refer only to previous preview blocks', () {
    final md = ExerciseCatalogMetadata(
      exercises: {
        'a': const ExerciseCatalogEntry(
          tracking: 'time',
          unilateral: false,
          primaryMuscles: ['back'],
        ),
        'b': const ExerciseCatalogEntry(
          tracking: 'time',
          unilateral: false,
          primaryMuscles: ['abs'],
        ),
      },
    );
    final lines = PlanExplanation.forBlock(
      plan: explanationPlan(ids: ['a', 'b']),
      index: 1,
      allExercises: [a, explanationExercise('b')],
      engine: ExerciseFilterEngine(md),
    ).join('\n');
    expect(
      lines,
      contains(
        'Dodatkowe mięśnie względem wcześniejszych bloków podglądu: Brzuch',
      ),
    );
    final first = PlanExplanation.forBlock(
      plan: explanationPlan(ids: ['a', 'b']),
      index: 0,
      allExercises: [a, explanationExercise('b')],
      engine: ExerciseFilterEngine(md),
    ).join('\n');
    expect(first, isNot(contains('Dodatkowe mięśnie')));
  });

  test(
    'replacement shows unchanged fields rather than fabricating differences',
    () {
      final plan = explanationPlan();
      final replacement = explanationPlan(ids: ['b']);
      final text = PlanExplanation.forReplacement(
        plan: plan,
        replacement: replacement,
        index: 0,
        allExercises: [a, explanationExercise('b')],
        engine: engine,
      ).join('\n');
      expect(text, contains('Bez zmian — Sprzęt: Mata'));
      expect(text, contains('Bez zmian — Wzorzec ruchu: Pull + stabilizacja'));
      expect(text, contains('Bez zmian — Poziom: Początkujący'));
      expect(text, isNot(contains('Sprzęt: Mata →')));
    },
  );
}
