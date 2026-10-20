import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';

const activityId = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> activityEntry() => {
  'id': activityId,
  'name': 'Basen 🏊',
  'kind': 'activityRule',
  'createdAtUtc': '2026-10-19T00:00:00Z',
  'updatedAtUtc': '2026-10-19T00:00:00Z',
  'activityType': 'external',
  'weekdays': [1, 7],
  'time': '12:30',
  'timeZone': 'Europe/Warsaw',
  'durationMinutes': 60,
  'enabled': true,
  'effectiveFromDate': '2026-10-19',
  'reminderEnabled': false,
  'reminderMinutesBefore': 30,
};
WeeklySchedule decode(List<Map<String, dynamic>> entries) =>
    WeeklySchedule.fromJson({'version': 1, 'entries': entries});

void main() {
  test(
    'same-day times sort first, equal times by stable UUID, legacy last',
    () {
      final legacy =
          {
            ...activityEntry(),
            'id': const Uuid().v5(activityId, 'legacy'),
            'kind': 'rule',
            'planSyncId': activityId,
            'weekday': 1,
          }..removeWhere(
            (k, _) => [
              'activityType',
              'weekdays',
              'time',
              'timeZone',
              'durationMinutes',
              'enabled',
              'reminderEnabled',
              'reminderMinutesBefore',
            ].contains(k),
          );
      final early = {
        ...activityEntry(),
        'id': const Uuid().v5(activityId, 'early'),
        'time': '06:00',
      };
      final tie = {
        ...activityEntry(),
        'id': const Uuid().v5(activityId, 'tie'),
      };
      final day = CalendarDay.parse('2026-10-19');
      final a = decode([legacy, tie, early, activityEntry()]).between(day, day);
      final b = decode([activityEntry(), early, tie, legacy]).between(day, day);
      expect(a.map((o) => o.id), b.map((o) => o.id));
      expect(a.map((o) => o.time), ['06:00', '12:30', '12:30', null]);
      expect(a[1].id.compareTo(a[2].id), lessThan(0));
      expect(
        a.last.id,
        WeeklySchedule.occurrenceId(legacy['id'] as String, day),
      );
      expect(
        () => decode([activityEntry()]).between(day, day.plus(367)),
        throwsArgumentError,
      );
    },
  );
  test(
    'activity overrides validate completion type and snapshot date identity',
    () {
      final entry = activityEntry();
      final snapshot = {...entry}
        ..removeWhere(
          (k, _) => [
            'id',
            'name',
            'kind',
            'createdAtUtc',
            'updatedAtUtc',
          ].contains(k),
        );
      final original = CalendarDay.parse('2026-10-19');
      final override = {
        ...entry,
        'kind': 'activityOverride',
        'id': WeeklySchedule.occurrenceId(activityId, original),
        'ruleId': activityId,
        'originalDate': original.value,
        'movedDate': original.value,
        'state': 'completed',
        'ruleSnapshot': snapshot,
      };
      for (final change in <Map<String, dynamic>>[
        {'sessionSyncId': activityId},
        {'originalDate': '2026-10-20'},
        {'movedDate': '2026-02-30'},
        {'id': activityId},
        {
          'ruleSnapshot': {...snapshot, 'time': '24:00'},
        },
        {
          'ruleSnapshot': {...snapshot, 'activityType': 'fitbirek'},
        },
      ]) {
        expect(
          () => decode([
            {...override, ...change},
          ]),
          throwsFormatException,
        );
      }
      expect(
        () => decode([
          {
            ...override,
            'sessionSyncId': activityId,
            'ruleSnapshot': {...snapshot, 'activityType': 'fitbirek'},
          },
        ]),
        returnsNormally,
      );
      expect(
        () => decode([
          {
            ...override,
            'state': 'planned',
            'sessionSyncId': activityId,
            'ruleSnapshot': {...snapshot, 'activityType': 'fitbirek'},
          },
        ]),
        throwsFormatException,
      );
    },
  );
  test('activity multiweekday finite expansion across Warsaw DST', () {
    final schedule = decode([activityEntry()]);
    final occurrences = schedule.between(
      CalendarDay.parse('2026-10-19'),
      CalendarDay.parse('2026-10-26'),
    );
    expect(occurrences.map((o) => o.date.value), [
      '2026-10-19',
      '2026-10-25',
      '2026-10-26',
    ]);
    expect(occurrences.first.planSyncId, isNull);
    expect(
      occurrences.first.id,
      WeeklySchedule.occurrenceId(activityId, CalendarDay.parse('2026-10-19')),
    );
  });
  test('strict activity fields and fitbirek nullable template', () {
    for (final change in <Map<String, dynamic>>[
      {'weekdays': []},
      {
        'weekdays': [0],
      },
      {
        'weekdays': [8],
      },
      {
        'weekdays': [1, 1],
      },
      {'time': '24:00'},
      {'time': '6:00'},
      {'timeZone': 'UTC'},
      {'durationMinutes': 0},
      {'durationMinutes': 1441},
      {'reminderMinutesBefore': -1},
      {'reminderMinutesBefore': 1441},
      {'reminderEnabled': 1},
      {'enabled': null},
      {'activityType': 'unknown'},
      {'planSyncId': activityId},
    ]) {
      expect(
        () => decode([
          {...activityEntry(), ...change},
        ]),
        throwsFormatException,
        reason: '$change',
      );
    }
    expect(
      () => decode([
        {
          ...activityEntry(),
          'activityType': 'fitbirek',
          'planSyncId': null,
          'durationMinutes': 1440,
          'reminderMinutesBefore': 1440,
        },
      ]),
      returnsNormally,
    );
  });
  test('disabled rule retains independent completed external snapshot', () {
    final entry = activityEntry();
    final snapshot = {...entry}
      ..removeWhere(
        (k, _) =>
            ['id', 'name', 'kind', 'createdAtUtc', 'updatedAtUtc'].contains(k),
      );
    final original = CalendarDay.parse('2026-10-19');
    final schedule = decode([
      {...entry, 'enabled': false},
      {
        'id': WeeklySchedule.occurrenceId(activityId, original),
        'name': entry['name'],
        'kind': 'activityOverride',
        'createdAtUtc': entry['createdAtUtc'],
        'updatedAtUtc': entry['updatedAtUtc'],
        'ruleId': activityId,
        'originalDate': original.value,
        'movedDate': original.value,
        'state': 'completed',
        'ruleSnapshot': snapshot,
      },
    ]);
    final occurrences = schedule.between(original, original.plus(7));
    expect(occurrences, hasLength(1));
    expect(occurrences.single.ruleSnapshot, snapshot);
    expect(occurrences.single.sessionSyncId, isNull);
  });
}
