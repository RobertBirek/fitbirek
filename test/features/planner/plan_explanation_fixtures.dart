import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_catalog_metadata.dart';
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';

Exercise explanationExercise(String id) => Exercise(
  id: id,
  nazwaPl: 'Ruch $id',
  nazwaEn: 'Movement',
  partiaGlowna: 'Plecy',
  partieWspierajace: const ['Brzuch'],
  sprzet: const ['Mata'],
  typ: 'Siła',
  poziom: 'Początkujący',
  wzorzecRuchu: 'Pull + stabilizacja',
  seriexPowtorzenia: '',
  tempo: '',
  kluczoweWskazowki: const [],
  czesteBledy: const [],
  progresja: '',
  regresja: '',
  zrodlo: '',
);

const explanationMetadata = ExerciseCatalogMetadata(
  styles: {
    'collection': ExerciseCatalogTag(
      id: 'collection',
      label: 'Kolekcja ruchu',
      aliases: ['ruchowa'],
    ),
  },
  muscles: {
    'back': ExerciseCatalogTag(id: 'back', label: 'Plecy'),
    'abs': ExerciseCatalogTag(id: 'abs', label: 'Brzuch'),
  },
  conditions: {
    'quiet': ExerciseCatalogTag(id: 'quiet', label: 'Cichy trening'),
  },
  positions: {
    'floor': ExerciseCatalogTag(id: 'floor', label: 'Na podłodze'),
    'standing': ExerciseCatalogTag(id: 'standing', label: 'Stojąco'),
  },
  exercises: {
    'a': ExerciseCatalogEntry(
      tracking: 'time',
      unilateral: false,
      styles: ['collection'],
      primaryMuscles: ['back'],
      secondaryMuscles: ['abs'],
      conditions: ['quiet'],
      positions: ['floor'],
    ),
    'b': ExerciseCatalogEntry(
      tracking: 'time',
      unilateral: false,
      styles: ['collection'],
      primaryMuscles: ['abs'],
      secondaryMuscles: ['back'],
      conditions: ['quiet'],
      positions: ['floor'],
    ),
  },
);

const explanationPrescription = PlanPrescription(
  tracking: 'time',
  sets: 3,
  workSeconds: 40,
  restSeconds: 30,
  transitionSeconds: 15,
);

StructuredPlan explanationPlan({
  ExerciseFilters criteria = const ExerciseFilters(),
  List<String> ids = const ['a'],
}) => StructuredPlan(
  criteria: criteria,
  budgetSeconds: 2700,
  equipment: const ['Mata', 'Krzesło'],
  level: 'Średni',
  warnings: const [],
  blocks: [
    for (final id in ids)
      PlanBlock(
        exerciseId: id,
        section: PlanSection.main,
        prescription: explanationPrescription,
      ),
  ],
);
