import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/sync/sync_store.dart';
import 'package:fitbirek_training/core/sync/sync_quarantine.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'structured_plan_persistence_test.dart' show structure;
import 'plan_structure_validation_test.dart' show planRecord;
import '../exercises/catalog_filter_test.dart' show exercise, metadata;
import 'package:fitbirek_training/features/exercises/domain/exercise_filter_engine.dart';

void main() {
  test(
    'recognized catalog dose outside numeric bounds is skipped, not fake-fit via fallback',
    () {
      final plan = StructuredPlanGenerator.generate(
        allExercises: [exercise('b').copyWith(seriexPowtorzenia: '5401 x 1')],
        engine: ExerciseFilterEngine(metadata),
        criteria: const ExerciseFilters(),
        equipment: ['Hantle'],
        level: 'Początkujący',
        minutes: 90,
      );
      expect(plan.blocks, isEmpty);
      final original = StructuredPlan(
        criteria: const ExerciseFilters(),
        budgetSeconds: 300,
        blocks: structure.blocks,
        warnings: [],
      );
      expect(
        StructuredPlanGenerator.replace(
          plan: original,
          index: 0,
          allExercises: [
            exercise('a').copyWith(seriexPowtorzenia: '5401 x 1 s'),
          ],
          engine: ExerciseFilterEngine(metadata),
          equipment: ['Hantle'],
          level: 'Początkujący',
        ),
        isNull,
      );
    },
  );
  Map<String, dynamic> raw(Map<String, dynamic> changes) {
    final json =
        jsonDecode(jsonEncode(structure.toJson())) as Map<String, dynamic>;
    ((json['blocks'] as List).first['prescription'] as Map).addAll(changes);
    return json;
  }

  test(
    'native overflow cannot turn a huge direct prescription into 15 seconds',
    () {
      const dose = PlanPrescription(
        tracking: 'time',
        sets: 4611686018427387904,
        workSeconds: 4,
        restSeconds: 0,
        transitionSeconds: 15,
      );
      expect(() => dose.totalSeconds, throwsFormatException);
      expect(
        () => StructuredPlan.fromJson(
          raw({'sets': dose.sets, 'workSeconds': 4, 'restSeconds': 0}),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'wire bounds reject huge native/JS integers, nonfinite and fractional numbers before arithmetic',
    () {
      for (final field in [
        'sets',
        'workSeconds',
        'restSeconds',
        'transitionSeconds',
        'reps',
      ]) {
        for (final huge in <num>[
          5401,
          9007199254740991,
          9007199254740992,
          4611686018427387904,
          9223372036854775807,
          1e100,
          double.infinity,
          double.nan,
          1.5,
        ]) {
          final changes = <String, dynamic>{field: huge};
          if (field == 'reps') changes['tracking'] = 'reps';
          expect(
            () => StructuredPlan.fromJson(raw(changes)),
            throwsFormatException,
            reason: '$field=$huge',
          );
        }
      }
      expect(
        () => StructuredPlan.fromJson(raw({'tracking': 'reps', 'reps': 1801})),
        throwsFormatException,
      );
    },
  );

  test(
    'exact 90min and bounded maximum fields remain valid; overbudget still rejects',
    () {
      final json = raw({
        'sets': 1,
        'workSeconds': 5385,
        'restSeconds': 5400,
        'transitionSeconds': 15,
      });
      json['budgetSeconds'] = 5400;
      expect(StructuredPlan.fromJson(json).estimatedSeconds, 5400);
      final reps = raw({
        'tracking': 'reps',
        'sets': 1,
        'reps': 1800,
        'workSeconds': 5400,
        'restSeconds': 0,
        'transitionSeconds': 0,
      });
      reps['budgetSeconds'] = 5400;
      expect(StructuredPlan.fromJson(reps).estimatedSeconds, 5400);
      final dose = raw({
        'sets': 5400,
        'workSeconds': 1,
        'restSeconds': 0,
        'transitionSeconds': 0,
      });
      dose['budgetSeconds'] = 5400;
      expect(StructuredPlan.fromJson(dose).estimatedSeconds, 5400);
      expect(
        StructuredPlan.fromJson(structure.toJson()).toJson(),
        structure.toJson(),
      );
      ((json['blocks'] as List).first['prescription'] as Map)['workSeconds'] =
          5386;
      expect(() => StructuredPlan.fromJson(json), throwsFormatException);
    },
  );

  test(
    'overflow incoming raw is quarantined unchanged, never persisted as a valid plan',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final incoming = planRecord(
        'bad',
        value: raw({
          'sets': 4611686018427387904,
          'workSeconds': 4,
          'restSeconds': 0,
        }),
      );
      await SyncQuarantine(db, SyncStore(db)).apply(incoming, 'A', 1, 0);
      expect(await db.select(db.workoutPlans).get(), isEmpty);
      final held = (await db.select(db.syncDeferredRecords).get()).single;
      expect(jsonDecode(held.recordJson)['raw'], incoming);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );
}
