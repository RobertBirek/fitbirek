import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import '../exercises/catalog_filter_test.dart' show exercise;

void main() {
  test(
    'real catalog: yoga and regeneration stay inside engine pool at every budget',
    () {
      final catalog =
          (jsonDecode(File('assets/data/exercises.json').readAsStringSync())
                  as List)
              .map((j) => Exercise.fromJson(j as Map<String, dynamic>))
              .toList();
      final md = ExerciseCatalogMetadata.fromJson(
        jsonDecode(
              File(
                'assets/data/exercise_catalog_metadata.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      expect(catalog, hasLength(424));
      expect(md.exercises, hasLength(catalog.length));
      final engine = ExerciseFilterEngine(md);
      for (final criteria in [
        const ExerciseFilters(styles: {'yoga'}),
        const ExerciseFilters(typy: {'Regeneracja'}),
      ]) {
        final equipment = catalog.expand((e) => e.sprzet).toSet().toList();
        final ids = engine.filter(catalog, criteria).map((e) => e.id).toSet();
        for (var minutes = 5; minutes <= 90; minutes++) {
          final plan = StructuredPlanGenerator.generate(
            allExercises: catalog,
            engine: engine,
            criteria: criteria,
            equipment: equipment,
            level: 'Zaawansowany',
            minutes: minutes,
          );
          expect(plan.blocks, isNotEmpty);
          expect(plan.blocks.any((b) => b.section == PlanSection.main), isTrue);
          expect(plan.exerciseIds.every(ids.contains), isTrue);
          expect(plan.estimatedSeconds, lessThanOrEqualTo(minutes * 60));
        }
      }
    },
  );
  final all = [
    exercise('squat').copyWith(wzorzecRuchu: 'Squat', partiaGlowna: 'Nogi'),
    exercise('squat2').copyWith(wzorzecRuchu: 'Squat', partiaGlowna: 'Nogi'),
    exercise('pull').copyWith(wzorzecRuchu: 'Pull'),
    exercise('push').copyWith(wzorzecRuchu: 'Push', partiaGlowna: 'Klatka'),
    exercise('warm').copyWith(typ: 'Rozgrzewka'),
    exercise('cool').copyWith(typ: 'Rozciąganie'),
  ];
  final metadata = ExerciseCatalogMetadata(
    exercises: {
      for (final e in all)
        e.id: ExerciseCatalogEntry(
          tracking: 'reps',
          unilateral: false,
          primaryMuscles: e.id.startsWith('squat')
              ? const ['quadriceps', 'glutes']
              : const ['back'],
          styles: const ['strength'],
        ),
    },
  );
  StructuredPlan generate({
    int minutes = 10,
    ExerciseFilters filters = const ExerciseFilters(),
  }) => StructuredPlanGenerator.generate(
    allExercises: all,
    engine: ExerciseFilterEngine(metadata),
    criteria: filters,
    equipment: const ['Hantle'],
    level: 'Średni',
    minutes: minutes,
  );

  test(
    'computed work/rest/transitions fit every budget 5..90 and round trip',
    () {
      for (var m = 5; m <= 90; m++) {
        final p = generate(minutes: m);
        expect(p.toJson()['level'], 'Średni');
        expect(p.toJson()['equipment'], ['Hantle']);
        expect(p.blocks, isNotEmpty);
        expect(p.estimatedSeconds, lessThanOrEqualTo(m * 60));
        expect(
          p.estimatedSeconds,
          p.blocks.fold<int>(0, (s, b) => s + b.prescription.totalSeconds),
        );
        expect(StructuredPlan.fromJson(p.toJson()).toJson(), p.toJson());
        expect(p.blocks.map((b) => b.section), containsAll(PlanSection.values));
      }
    },
  );
  test('stable diversity selects patterns before second squat', () {
    final p = generate(minutes: 45);
    final main = p.blocks.where((b) => b.section == PlanSection.main).toList();
    expect(main.where((b) => b.exerciseId.startsWith('squat')), hasLength(1));
    expect(main.take(3).map((b) => b.exerciseId).toSet(), {
      'squat',
      'pull',
      'push',
    });
    expect(
      StructuredPlanGenerator.generate(
        allExercises: all.reversed.toList(),
        engine: ExerciseFilterEngine(metadata),
        criteria: const ExerciseFilters(),
        equipment: const ['Hantle'],
        level: 'Średni',
        minutes: 45,
      ).toJson(),
      p.toJson(),
    );
  });
  test(
    'strict filters no outside warmup; whole equipment and numeric level',
    () {
      final p = generate(
        filters: const ExerciseFilters(query: 'Ruch', typy: {'Siła'}),
      );
      expect(
        p.blocks.every((b) => !{'warm', 'cool'}.contains(b.exerciseId)),
        isTrue,
      );
      expect(p.warnings, contains('Brak rozgrzewki w aktywnej puli.'));
      final restricted = StructuredPlanGenerator.generate(
        allExercises: [
          all.first.copyWith(sprzet: ['Hantle', 'Ławka']),
          all[1].copyWith(poziom: 'Zaawansowany'),
          all[2].copyWith(poziom: 'Średni'),
        ],
        engine: ExerciseFilterEngine(metadata),
        criteria: const ExerciseFilters(),
        equipment: ['Hantle'],
        level: 'Średni',
        minutes: 10,
      );
      expect(restricted.exerciseIds, ['pull']);
    },
  );
  test('unavailable metadata never broadens explicit classification', () {
    expect(
      () => StructuredPlanGenerator.generate(
        allExercises: all,
        engine: ExerciseFilterEngine(
          const ExerciseCatalogMetadata(),
          classificationAvailable: false,
        ),
        criteria: const ExerciseFilters(styles: {'yoga'}),
        equipment: ['Hantle'],
        level: 'Średni',
        minutes: 10,
      ),
      throwsStateError,
    );
  });
  test(
    'empty and too short explicit, replacement keeps other blocks and metric',
    () {
      expect(() => generate(minutes: 4), throwsArgumentError);
      expect(
        generate(filters: const ExerciseFilters(query: 'missing')).blocks,
        isEmpty,
      );
      final p = generate(minutes: 15);
      final index = p.blocks.indexWhere((b) => b.exerciseId == 'squat');
      final replaced = StructuredPlanGenerator.replace(
        plan: p,
        index: index,
        allExercises: all,
        engine: ExerciseFilterEngine(metadata),
        equipment: ['Hantle'],
        level: 'Średni',
      );
      expect(replaced, isNotNull);
      for (var i = 0; i < p.blocks.length; i++) {
        if (i != index) {
          expect(identical(p.blocks[i], replaced!.blocks[i]), isTrue);
        }
      }
      expect(replaced!.estimatedSeconds, p.estimatedSeconds);
      expect(replaced.exerciseIds.toSet().length, replaced.exerciseIds.length);
    },
  );
  test('time-only yoga can be main; incompatible replacement refused', () {
    final yoga = all.first.copyWith(id: 'y', typ: 'Joga');
    final md = ExerciseCatalogMetadata(
      exercises: {
        'y': const ExerciseCatalogEntry(tracking: 'time', unilateral: false),
        'pull': const ExerciseCatalogEntry(tracking: 'reps', unilateral: false),
      },
    );
    final p = StructuredPlanGenerator.generate(
      allExercises: [yoga],
      engine: ExerciseFilterEngine(md),
      criteria: const ExerciseFilters(),
      equipment: ['Hantle'],
      level: 'Średni',
      minutes: 5,
    );
    expect(p.blocks.single.section, PlanSection.main);
    expect(p.blocks.single.prescription.reps, isNull);
    expect(
      StructuredPlanGenerator.replace(
        plan: p,
        index: 0,
        allExercises: [yoga, all[2]],
        engine: ExerciseFilterEngine(md),
        equipment: ['Hantle'],
        level: 'Średni',
      ),
      isNull,
    );
  });
  test(
    'legal five-minute budget may be too short; no false estimated completion',
    () {
      final md = ExerciseCatalogMetadata(
        exercises: {
          'a': const ExerciseCatalogEntry(tracking: 'time', unilateral: true),
        },
      );
      final p = StructuredPlanGenerator.generate(
        allExercises: [exercise('a')],
        engine: ExerciseFilterEngine(md),
        criteria: const ExerciseFilters(),
        equipment: ['Hantle'],
        level: 'Średni',
        minutes: 5,
      );
      expect(p.blocks, isEmpty);
      expect(p.estimatedSeconds, 0);
      expect(
        p.warnings,
        contains('Brak pracy w aktywnej puli lub za mało czasu.'),
      );
    },
  );
}
