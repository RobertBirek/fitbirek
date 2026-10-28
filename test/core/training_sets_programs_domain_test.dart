import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/sync/user_collections.dart';
import 'package:fitbirek_training/features/planner/domain/structured_plan.dart';
import 'package:fitbirek_training/features/workout/domain/workout_guidance.dart';

const programId = '10000000-0000-4000-8000-000000000001';
const planA = '20000000-0000-4000-8000-000000000001';
const planB = '20000000-0000-4000-8000-000000000002';
Map<String, dynamic> programEntry() => {
  'id': programId,
  'name': 'A/B',
  'kind': 'program',
  'createdAtUtc': '2026-10-28T00:00:00.000Z',
  'updatedAtUtc': '2026-10-28T00:00:00.000Z',
  'planSyncIds': [planA, planB],
  'weekdays': [1, 3, 5],
  'effectiveFromDate': '2026-10-28',
};
Map<String, dynamic> collection(List<Map<String, dynamic>> entries) => {
  'version': 1,
  'entries': entries,
};
Map<String, dynamic> target(String id, {String role = 'working'}) => {
  'targetId': id,
  'setRole': role,
  'side': null,
  'reps': 8,
  'seconds': null,
  'weightKg': 12.0,
  'workSeconds': 24,
  'restSeconds': 20,
};
Map<String, dynamic> planJson({int version = 2}) => {
  'schemaVersion': version,
  'criteria': {},
  'budgetSeconds': 300,
  'level': 'Średni',
  'equipment': <String>[],
  'warnings': <String>[],
  'blocks': [
    {
      'exerciseId': 'cw001',
      'section': 'main',
      'prescription': {
        'tracking': 'reps',
        'transitionSeconds': 15,
        'setTargets': [
          target('a', role: 'warmup'),
          {...target('b'), 'reps': 6, 'weightKg': 18.0},
        ],
      },
    },
  ],
};

void main() {
  test(
    'v2 preserves ordered heterogeneous targets without parallel scalar dose',
    () {
      final raw = planJson();
      final p = StructuredPlan.fromJson(raw);
      expect(p.blocks.single.prescription.sets, 2);
      expect(p.estimatedSeconds, 83);
      expect(
        (p.toJson()['blocks'] as List).single['prescription'],
        (raw['blocks'] as List).single['prescription'],
      );
      expect(
        () => StructuredPlan.fromJson(planJson(version: 3)),
        throwsFormatException,
      );
    },
  );
  test(
    'v2 rejects duplicate targets, scalar competition, rounds and unsafe operands',
    () {
      for (final mutate in <void Function(Map)>[
        (p) => (p['setTargets'] as List)[1]['targetId'] = 'a',
        (p) => p['sets'] = 2,
        (p) => p['tracking'] = 'rounds',
        (p) => (p['setTargets'] as List)[0]['reps'] = 9007199254740991,
        (p) => (p['setTargets'] as List)[0]['setRole'] = null,
        (p) => (p['setTargets'] as List)[0]['side'] = 'unknown',
        (p) => (p['setTargets'] as List)[0]['seconds'] = 10,
        (p) => p['setTargets'] = List.generate(101, (i) => target('$i')),
      ]) {
        final raw = planJson();
        mutate((raw['blocks'] as List).single['prescription'] as Map);
        expect(() => StructuredPlan.fromJson(raw), throwsFormatException);
      }
    },
  );
  test('v1 JSON and guidance signature remain exactly stable', () {
    final raw = planJson(version: 1);
    (raw['blocks'] as List).single['prescription'] = {
      'tracking': 'reps',
      'sets': 2,
      'reps': 8,
      'workSeconds': 24,
      'restSeconds': 20,
      'transitionSeconds': 15,
    };
    final p = StructuredPlan.fromJson(raw);
    final g = WorkoutGuidance.start(p).link(0, 'set-1').skip(0);
    final bytes = jsonEncode(g.toJson());
    expect(
      jsonEncode(WorkoutGuidance.validateJson(jsonDecode(bytes)).toJson()),
      bytes,
    );
    expect(g.toJson()['schemaVersion'], 1);
    expect(g.events.first, {
      'type': 'performed',
      'setSyncId': 'set-1',
      'slotIndex': 0,
    });
  });
  test(
    'v2 guidance validates target identity and rejects double consumption',
    () {
      final raw = {
        'schemaVersion': 2,
        'plan': planJson(),
        'events': [
          {
            'type': 'performed',
            'slotIndex': 0,
            'targetId': 'a',
            'setSyncId': 'set-1',
          },
          {'type': 'skippedTarget', 'slotIndex': 0, 'targetId': 'b'},
        ],
      };
      final g = WorkoutGuidance.validateJson(raw);
      expect(g.toJson()['schemaVersion'], 2);
      expect(g.events, raw['events']);
      for (final event in [
        {
          'type': 'performed',
          'slotIndex': 0,
          'targetId': 'a',
          'setSyncId': 'set-2',
        },
        {
          'type': 'performed',
          'slotIndex': 0,
          'targetId': 'absent',
          'setSyncId': 'set-2',
        },
        {'type': 'performed', 'slotIndex': 0, 'setSyncId': 'set-2'},
      ]) {
        expect(
          () => WorkoutGuidance.validateJson({
            ...raw,
            'events': [...g.events, event],
          }),
          throwsFormatException,
        );
      }
    },
  );
  test('program collection is not interpreted as exercise variants', () {
    expect(
      UserCollections.validate(
        'trainingPrograms',
        collection([programEntry()]),
      )['entries'],
      hasLength(1),
    );
    for (final change in [
      {
        'planSyncIds': [planA, planA],
      },
      {
        'weekdays': [1, 1],
      },
      {
        'weekdays': [0],
      },
      {'effectiveFromDate': '2026-02-30'},
      {'kind': 'unknown'},
    ]) {
      expect(
        () => UserCollections.validate(
          'trainingPrograms',
          collection([
            {...programEntry(), ...change},
          ]),
        ),
        throwsFormatException,
      );
    }
  });
  test(
    'program merge refuses immutable collisions and preserves closed cutoff',
    () {
      final a = programEntry();
      final closed = {...a, 'endBeforeDate': '2026-11-01'};
      final renamed = {
        ...a,
        'name': 'Renamed',
        'updatedAtUtc': '2026-10-29T00:00:00.000Z',
      };
      final merged = UserCollections.merge(
        'trainingPrograms',
        collection([closed]),
        collection([renamed]),
      );
      expect((merged['entries'] as List).single['endBeforeDate'], '2026-11-01');
      expect(
        UserCollections.merge(
          'trainingPrograms',
          collection([renamed]),
          collection([closed]),
        ),
        merged,
      );
      for (final change in [
        {
          'planSyncIds': [planB, planA],
        },
        {
          'weekdays': [2],
        },
        {'effectiveFromDate': '2026-10-29'},
        {'endBeforeDate': '2026-11-02'},
        {'endBeforeDate': null},
      ]) {
        expect(
          () => UserCollections.merge(
            'trainingPrograms',
            collection([closed]),
            collection([
              {...renamed, ...change},
            ]),
          ),
          throwsFormatException,
        );
      }
    },
  );
}
