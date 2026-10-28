import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/planner/domain/exercise_training_policy.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/planner/providers/planner_providers.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/workout_preparation.dart';
import '../exercises/catalog_filter_test.dart' show exercise;

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
  Exercise real(String id) => catalog.singleWhere((e) => e.id == id);
  const chest = ExerciseCatalogEntry(
    tracking: 'reps',
    unilateral: false,
    primaryMuscles: ['chest'],
    secondaryMuscles: ['triceps'],
  );
  final source = real('cw001');
  final engine = ExerciseFilterEngine(metadata);
  StructuredPlan generate(
    List<Exercise> all, {
    ExerciseFilterEngine? using,
    int minutes = 45,
  }) => StructuredPlanGenerator.generate(
    allExercises: all,
    engine: using ?? engine,
    criteria: const ExerciseFilters(),
    equipment: all.expand((e) => e.sprzet).toSet().toList(),
    level: 'Zaawansowany',
    minutes: minutes,
  );
  StructuredPlan? replace(
    StructuredPlan plan,
    List<Exercise> all, {
    ExerciseFilterEngine? using,
    List<String>? equipment,
  }) => StructuredPlanGenerator.replace(
    plan: plan,
    index: 0,
    allExercises: all,
    engine: using ?? engine,
    equipment: equipment ?? plan.equipment,
    level: plan.level,
  );

  // A previous implementation admitted any same-time/same-tracking movement.
  final incompatible = <String, (Exercise, ExerciseCatalogEntry?)>{
    'vertical push': (
      source.copyWith(id: 'bad', wzorzecRuchu: 'Push wertykalny'),
      chest,
    ),
    'horizontal pull': (
      source.copyWith(id: 'bad', wzorzecRuchu: 'Pull horyzontalny'),
      chest,
    ),
    'different tracking': (
      source.copyWith(id: 'bad'),
      const ExerciseCatalogEntry(
        tracking: 'time',
        unilateral: false,
        primaryMuscles: ['chest'],
      ),
    ),
    'different section': (source.copyWith(id: 'bad', typ: 'Rozgrzewka'), chest),
    'overlapping primary sets are not equal': (
      source.copyWith(id: 'bad'),
      const ExerciseCatalogEntry(
        tracking: 'reps',
        unilateral: false,
        primaryMuscles: ['chest', 'triceps'],
      ),
    ),
    'secondary overlap is insufficient': (
      source.copyWith(id: 'bad'),
      const ExerciseCatalogEntry(
        tracking: 'reps',
        unilateral: false,
        primaryMuscles: ['triceps'],
        secondaryMuscles: ['chest'],
      ),
    ),
    'missing metadata': (source.copyWith(id: 'bad'), null),
    'empty primary set': (
      source.copyWith(id: 'bad'),
      const ExerciseCatalogEntry(tracking: 'reps', unilateral: false),
    ),
    'unilateral': (
      source.copyWith(id: 'bad'),
      const ExerciseCatalogEntry(
        tracking: 'reps',
        unilateral: true,
        primaryMuscles: ['chest'],
      ),
    ),
    'recovery cannot become strength': (
      source.copyWith(id: 'bad', typ: 'Mobilność'),
      chest,
    ),
  };
  for (final item in incompatible.entries) {
    test('planner and preparation refuse ${item.key}', () {
      final (bad, md) = item.value;
      final using = ExerciseFilterEngine(
        ExerciseCatalogMetadata(
          exercises: {
            source.id: metadata.entryFor(source.id)!,
            if (md != null) bad.id: md,
          },
        ),
      );
      final plan = generate([source], using: using);
      expect(replace(plan, [source, bad], using: using), isNull);
      final draft = preparation(plan, [source, bad], using);
      expect(draft.candidatesFor(0), isEmpty);
      expect(
        () => draft.replace(0, bad.id, ReplacementScope.sessionOnly),
        throwsStateError,
      );
    });
  }
  for (final pattern in [
    'Push',
    'Pull',
    'Full body',
    'Ruch złożony',
    'Kontrolowany ruch',
    'Flow',
    'Izometria',
    '',
    'Push nieznany',
  ]) {
    test('ambiguous family "$pattern" refuses even identical labels', () {
      final a = source.copyWith(wzorzecRuchu: pattern);
      final b = a.copyWith(id: 'b');
      final using = ExerciseFilterEngine(
        ExerciseCatalogMetadata(exercises: {a.id: chest, b.id: chest}),
      );
      final plan = generate([a], using: using);
      expect(replace(plan, [a, b], using: using), isNull);
      expect(preparation(plan, [a, b], using).candidatesFor(0), isEmpty);
    });
  }
  test(
    'real catalog aliases replace with a different dose, deterministically and without touching other blocks',
    () {
      final plan = generate([source, real('cw364')]);
      final index = plan.blocks.indexWhere((b) => b.exerciseId == source.id);
      StructuredPlan run(List<Exercise> all) => StructuredPlanGenerator.replace(
        plan: plan,
        index: index,
        allExercises: all,
        engine: engine,
        equipment: ['Masa własna', 'Hantle', 'Ławka'],
        level: plan.level,
      )!;
      final all = [source, real('cw029'), real('cw003'), real('cw002')];
      final changed = run(all);
      expect(changed.blocks[index].exerciseId, 'cw003');
      expect(changed.blocks[index].prescription.reps, 10);
      expect(changed.blocks[index].prescription.totalSeconds, 285);
      expect(changed.estimatedSeconds, isNot(plan.estimatedSeconds));
      expect(run(all.reversed.toList()).toJson(), changed.toJson());
      for (var i = 0; i < plan.blocks.length; i++) {
        if (i != index) {
          expect(identical(changed.blocks[i], plan.blocks[i]), isTrue);
        }
      }
      expect(
        StructuredPlan.fromJson(changed.toJson()).toJson(),
        changed.toJson(),
      );
      final tempo = run([source, real('cw029')]);
      expect(tempo.blocks[index].exerciseId, 'cw029');
    },
  );
  test(
    'whole alternative equipment sets remain AND within OR and respect level and filters',
    () {
      final b = source.copyWith(id: 'b', sprzet: ['Hantle', 'Ławka']);
      final using = ExerciseFilterEngine(
        ExerciseCatalogMetadata(
          exercises: {
            source.id: chest,
            'b': const ExerciseCatalogEntry(
              tracking: 'reps',
              unilateral: false,
              primaryMuscles: ['chest'],
              equipmentSets: [
                ['Hantle', 'Ławka'],
                ['Gumy', 'Drążek'],
              ],
            ),
          },
        ),
      );
      final plan = generate([source], using: using);
      expect(
        replace(plan, [source, b], using: using, equipment: ['Hantle', 'Gumy']),
        isNull,
      );
      expect(
        replace(
          plan,
          [source, b],
          using: using,
          equipment: ['Gumy', 'Drążek'],
        )?.exerciseIds,
        ['b'],
      );
      final draft = preparation(
        plan,
        [source, b],
        using,
        equipment: ['Hantle', 'Gumy'],
      );
      expect(draft.candidatesFor(0), isEmpty);
      expect(
        replace(
          plan,
          [source, b.copyWith(poziom: 'nieznany')],
          using: using,
          equipment: ['Gumy', 'Drążek'],
        ),
        isNull,
      );
    },
  );
  test(
    'preparation shares compatibility and never offers an occupied block',
    () {
      final plan = generate([source]);
      final b = source.copyWith(id: 'b');
      final using = ExerciseFilterEngine(
        ExerciseCatalogMetadata(exercises: {source.id: chest, 'b': chest}),
      );
      final occupied = StructuredPlan(
        criteria: plan.criteria,
        budgetSeconds: 1800,
        blocks: [
          plan.blocks.single,
          PlanBlock(
            exerciseId: 'b',
            section: PlanSection.main,
            prescription: plan.blocks.single.prescription,
          ),
        ],
        warnings: [],
      );
      expect(
        preparation(occupied, [source, b], using).candidatesFor(0),
        isEmpty,
      );
    },
  );
  test(
    'ID-only active selection is independent of new catalog dose and never alters original targets',
    () {
      final a = source.copyWith(seriexPowtorzenia: '1 x 10');
      final b = a.copyWith(id: 'b', seriexPowtorzenia: '5 x 100');
      final using = ExerciseFilterEngine(
        ExerciseCatalogMetadata(exercises: {a.id: chest, b.id: chest}),
      );
      final plan = generate([a], using: using, minutes: 5);
      final before = plan.toJson();
      expect(
        StructuredPlanGenerator.replacementCandidates(
          plan: plan,
          index: 0,
          allExercises: [b, a],
          engine: using,
          equipment: plan.equipment,
          level: plan.level,
        ).map((e) => e.id),
        ['b'],
      );
      expect(replace(plan, [a, b], using: using), isNull);
      expect(plan.toJson(), before);
      expect(plan.blocks.single.prescription.totalSeconds, 45);
    },
  );
  test(
    'primary metadata is a set, not an ordered list, but must exist on the source too',
    () {
      final a = real('cw125');
      final b = real('cw126');
      final using = ExerciseFilterEngine(
        ExerciseCatalogMetadata(
          exercises: {
            a.id: metadata.entryFor(a.id)!,
            b.id: const ExerciseCatalogEntry(
              tracking: 'reps',
              unilateral: false,
              primaryMuscles: ['glutes', 'quadriceps'],
            ),
          },
        ),
      );
      final plan = generate([a], using: using);
      expect(replace(plan, [a, b], using: using)?.exerciseIds, [b.id]);
      final missingSource = ExerciseFilterEngine(
        ExerciseCatalogMetadata(exercises: {b.id: metadata.entryFor(b.id)!}),
      );
      expect(replace(plan, [a, b], using: missingSource), isNull);
    },
  );
  for (final pattern in ['Hinge', 'Lunge']) {
    test('squat is not $pattern even with identical primary muscles', () {
      final a = real('cw125');
      final b = a.copyWith(id: 'b', wzorzecRuchu: pattern);
      final using = ExerciseFilterEngine(
        ExerciseCatalogMetadata(
          exercises: {
            a.id: metadata.entryFor(a.id)!,
            b.id: metadata.entryFor(a.id)!,
          },
        ),
      );
      final plan = generate([a], using: using);
      expect(replace(plan, [a, b], using: using), isNull);
      expect(preparation(plan, [a, b], using).candidatesFor(0), isEmpty);
    });
  }
  test(
    'real recovery-style isometry cannot become strength despite identical movement and primary',
    () {
      final a = real('cw365');
      final b = a.copyWith(id: 'b', typ: 'Siła');
      final using = ExerciseFilterEngine(
        ExerciseCatalogMetadata(
          exercises: {
            a.id: metadata.entryFor(a.id)!,
            b.id: const ExerciseCatalogEntry(
              tracking: 'time',
              unilateral: false,
              primaryMuscles: ['abs'],
              styles: ['strength'],
            ),
          },
        ),
      );
      final plan = generate([a], using: using);
      expect(
        ExerciseTrainingPolicy.compatible(
          source: a,
          candidate: b,
          engine: using,
        ),
        isFalse,
      );
      expect(replace(plan, [a, b], using: using), isNull);
      expect(preparation(plan, [a, b], using).candidatesFor(0), isEmpty);
      expect(plan.blocks.single.prescription.restSeconds, 30);
    },
  );
  for (final id in ['cw111', 'cw112']) {
    test('ambiguous Triceps refuses real $id bench dip to cw105 isolation', () {
      final benchDip = real(id);
      final isolation = real('cw105');
      final plan = generate([benchDip]);
      expect(
        ExerciseTrainingPolicy.compatible(
          source: benchDip,
          candidate: isolation,
          engine: engine,
        ),
        isFalse,
      );
      expect(
        replace(plan, [benchDip, isolation], equipment: ['Hantle', 'Ławeczka']),
        isNull,
      );
      expect(
        preparation(
          plan,
          [benchDip, isolation],
          engine,
          equipment: ['Hantle', 'Ławeczka'],
        ).candidatesFor(0),
        isEmpty,
      );
    });
    test(
      'real $id bench dip has explicit rest fallback for catalog and fallback doses',
      () {
        for (final e in [real(id), real(id).copyWith(seriexPowtorzenia: '')]) {
          final plan = generate([e]);
          final p = plan.blocks.single.prescription;
          expect(p.restSeconds, 30);
          expect(
            plan.warnings,
            contains(
              '$id: Brak jednoznacznej polityki przerw; zastosowano domyślnie 30 s między seriami.',
            ),
          );
          expect(
            p.totalSeconds,
            e.seriexPowtorzenia.isEmpty || id == 'cw111' ? 165 : 201,
          );
          expect(
            StructuredPlan.fromJson(plan.toJson()).toJson(),
            plan.toJson(),
          );
        }
      },
    );
  }
  test(
    'ambiguous Triceps denies automation even for a cloned real isolated exercise',
    () {
      final original = real('cw105');
      final clone = original.copyWith(id: 'custom-triceps');
      final using = ExerciseFilterEngine(
        ExerciseCatalogMetadata(
          exercises: {
            original.id: metadata.entryFor(original.id)!,
            clone.id: metadata.entryFor(original.id)!,
          },
        ),
      );
      final plan = generate([original], using: using);
      expect(replace(plan, [original, clone], using: using), isNull);
      expect(plan.blocks.single.prescription.restSeconds, 30);
      expect(ExerciseTrainingPolicy.restFor(clone), (
        seconds: 30,
        fallback: true,
      ));
    },
  );
  test(
    'manual rest removes only the edited real Triceps block fallback warning',
    () {
      final first = generate([real('cw111')]);
      final second = generate([real('cw105')]);
      final plan = StructuredPlan(
        criteria: first.criteria,
        budgetSeconds: 2700,
        blocks: [...first.blocks, ...second.blocks],
        warnings: [...first.warnings, ...second.warnings],
      );
      final originalWarnings = [...plan.warnings];
      final edited = StructuredPlanGenerator.withRest(
        plan: plan,
        index: 0,
        restSeconds: 60,
      )!;
      expect(edited.blocks.first.prescription.restSeconds, 60);
      expect(
        edited.warnings,
        originalWarnings.where((w) => !w.startsWith('cw111:')).toList(),
      );
      expect(
        edited.warnings.where((w) => w.startsWith('cw105:')),
        hasLength(1),
      );
      expect(identical(edited.blocks[1], plan.blocks[1]), isTrue);
      expect(plan.warnings, originalWarnings);
      expect(plan.blocks.first.prescription.restSeconds, 30);
    },
  );
  final rests = <(String, String, String, int)>[
    ('Hipertrofia', 'Push horyzontalny', '3 x 10', 90),
    ('Siła', 'Squat', '3 x 10', 120),
    ('Hipertrofia', 'Biceps', '3 x 10', 60),
    ('Siła', 'Zginanie łokci', '3 x 10', 60),
    ('Izolacja', 'Nierozpoznany wzorzec', '3 x 10', 60),
    ('Explosive', 'Push horyzontalny', '3 x 10', 120),
    ('Wytrzymałość', 'Push horyzontalny', '3 x 10', 30),
    ('Izometria', 'Anty-ekstensja', '3 x 10', 30),
    ('Regeneracja', 'Push horyzontalny', '3 x 10', 0),
    ('Mobilność', 'Push horyzontalny', '3 x 10', 0),
    ('Joga', 'Push horyzontalny', '3 x 10', 0),
    ('Rozciąganie', 'Push horyzontalny', '3 x 10', 0),
    ('Rozgrzewka', 'Push horyzontalny', '3 x 10', 0),
    ('Siła', 'Ruch złożony', '3 x 10', 30),
  ];
  for (final (type, pattern, dose, rest) in rests) {
    test(
      'rest for $type/$pattern applies to both catalog and fallback without last rest',
      () {
        for (final raw in [dose, 'Według możliwości']) {
          final e = exercise(
            'r',
          ).copyWith(typ: type, wzorzecRuchu: pattern, seriexPowtorzenia: raw);
          final using = ExerciseFilterEngine(
            const ExerciseCatalogMetadata(exercises: {'r': chest}),
          );
          final plan = generate([e], using: using);
          final p = plan.blocks.single.prescription;
          final auxiliary = ['Rozciąganie', 'Rozgrzewka'].contains(type);
          final sets = raw == dose || !auxiliary ? 3 : 1;
          final work = raw == dose || !auxiliary ? 30 : 18;
          expect(p.restSeconds, rest);
          expect(plan.estimatedSeconds, sets * work + (sets - 1) * rest + 15);
          if (pattern == 'Ruch złożony') {
            expect(plan.warnings.join(), contains('przerw'));
          }
        }
      },
    );
  }
}

PreparationDraft preparation(
  StructuredPlan plan,
  List<Exercise> catalog,
  ExerciseFilterEngine engine, {
  List<String>? equipment,
}) => PreparationDraft(
  PreparationSnapshot(
    lease: TemplateLease(0, 'A', 'device', true, null),
    savedPlan: SavedPlan(
      id: 1,
      nazwa: 'Test',
      cwiczeniaIds: plan.exerciseIds,
      cel: 'sila',
      dataUtworzenia: DateTime.utc(2026),
      structure: plan,
    ),
    profileSyncId: 'profile',
    catalog: catalog,
    availableEquipment: equipment ?? plan.equipment,
    engine: engine,
  ),
);
