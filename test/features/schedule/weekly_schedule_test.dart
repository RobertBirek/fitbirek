import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/sync/user_collections.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'package:uuid/uuid.dart';

const ruleId = '11111111-1111-4111-8111-111111111111';
const planId = '22222222-2222-4222-8222-222222222222';
Map<String, dynamic> rule({
  String stamp = '2026-10-17T12:00:00.000Z',
  bool deleted = false,
}) => {
  'id': ruleId,
  'name': 'Trening',
  'kind': 'rule',
  'createdAtUtc': '2026-10-17T12:00:00.000Z',
  'updatedAtUtc': stamp,
  if (deleted) 'deletedAtUtc': stamp,
  'planSyncId': planId,
  'weekday': 1,
  'effectiveFromDate': '2026-10-19',
};
Map<String, dynamic> collection(List<Map<String, dynamic>> entries) => {
  'version': 1,
  'entries': entries,
};

void main() {
  test(
    'schedule validates version, ISO weekday, UUID references and finite limits including tombstones',
    () {
      for (final json in [
        {'version': 2, 'entries': []},
        collection([
          {...rule(), 'weekday': 0},
        ]),
        collection([
          {...rule(), 'planSyncId': 123},
        ]),
        collection([
          {...rule(), 'effectiveFromDate': '2026-02-30'},
        ]),
        collection([
          {...rule(), 'kind': 'unknown'},
        ]),
        collection([
          for (var i = 0; i < 501; i++)
            {...rule(deleted: true), 'id': const Uuid().v4()},
        ]),
        collection([
          {...rule(), 'futureData': 'a' * 262144},
        ]),
      ]) {
        expect(() => WeeklySchedule.fromJson(json), throwsFormatException);
      }
    },
  );
  test(
    'calendar week crosses DST and year boundary by calendar components',
    () {
      final sunday = CalendarDay.local(DateTime(2026, 10, 25, 23, 30));
      expect(sunday.value, '2026-10-25');
      expect(sunday.monday.value, '2026-10-19');
      expect(sunday.plus(1).value, '2026-10-26');
      expect(CalendarDay.parse('2027-01-01').monday.value, '2026-12-28');
      expect(() => CalendarDay.parse('2026-02-30'), throwsFormatException);
    },
  );
  test(
    'a moved exception retains original identity without moving next week',
    () {
      final original = CalendarDay.parse('2026-10-19');
      final id = WeeklySchedule.occurrenceId(ruleId, original);
      final e = {
        'id': id,
        'kind': 'override',
        'name': 'Trening',
        'createdAtUtc': '2026-10-17T12:00:00.000Z',
        'updatedAtUtc': '2026-10-17T12:00:00.000Z',
        'ruleId': ruleId,
        'originalDate': original.value,
        'movedDate': '2026-10-20',
        'state': 'planned',
        'ruleSnapshot': {
          'planSyncId': planId,
          'weekday': 1,
          'effectiveFromDate': '2026-10-19',
        },
      };
      final schedule = WeeklySchedule.fromJson(collection([rule(), e]));
      final items = schedule.between(original, original.plus(13));
      expect(items.map((e) => e.date.value), ['2026-10-20', '2026-10-26']);
      expect(items.first.id, id);
      final history = WeeklySchedule.fromJson(
        collection([
          rule(deleted: true),
          {...e, 'state': 'completed', 'sessionSyncId': planId},
        ]),
      );
      expect(history.between(original, original.plus(13)).single.id, id);
    },
  );
  test('weeklySchedule accepts typed rule in existing collection envelope', () {
    expect(
      UserCollections.validate(
        'weeklySchedule',
        collection([rule()]),
      )['entries'],
      [rule()],
    );
  });
  test('weeklySchedule merge is per-ID and deletion wins ties', () {
    final live = collection([rule()]);
    final dead = collection([rule(deleted: true)]);
    expect(UserCollections.merge('weeklySchedule', live, dead), dead);
    expect(UserCollections.merge('weeklySchedule', dead, live), dead);
  });
}
