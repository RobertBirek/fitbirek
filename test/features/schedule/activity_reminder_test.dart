import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as data;
import 'package:fitbirek_training/features/schedule/domain/activity_reminders.dart';
import 'package:fitbirek_training/features/schedule/domain/weekly_schedule.dart';
import 'activity_schedule_test.dart' show activityEntry;
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(data.initializeTimeZones);
  for (final target in ['0001-01-01', '9999-12-31']) {
    for (final lead in [30, 1440]) {
      test(
        'native horizon excludes boundary move $target lead $lead before timezone arithmetic',
        () {
          final r = activityEntry()
            ..addAll({
              'weekdays': [2],
              'time': '18:00',
              'reminderEnabled': true,
            });
          final snapshot = {...r}
            ..removeWhere(
              (k, v) => [
                'id',
                'name',
                'kind',
                'createdAtUtc',
                'updatedAtUtc',
              ].contains(k),
            );
          snapshot.addAll({'time': '00:00', 'reminderMinutesBefore': lead});
          final o = {
            'id': WeeklySchedule.occurrenceId(
              r['id'] as String,
              CalendarDay.parse('2026-10-20'),
            ),
            'kind': 'activityOverride',
            'name': r['name'],
            'ruleId': r['id'],
            'originalDate': '2026-10-20',
            'movedDate': target,
            'ruleSnapshot': snapshot,
            'state': 'planned',
            'createdAtUtc': r['createdAtUtc'],
            'updatedAtUtc': r['updatedAtUtc'],
          };
          final independent = {
            ...r,
            'id': const Uuid().v5(r['id'] as String, 'independent'),
            'name': 'Independent',
          };
          final reminders = activityReminders(
            WeeklySchedule.fromJson({
              'version': 1,
              'entries': [r, o, independent],
            }),
            DateTime.utc(2026, 10, 19, 12),
            external: true,
            training: true,
          );
          expect(reminders.single.title, 'Independent');
          expect(
            reminders.single.at.toUtc(),
            DateTime.utc(2026, 10, 20, 15, 30),
          );
        },
      );
    }
  }
  test(
    'completed and moved overrides revalidate and disabled source never notifies saved planned history',
    () {
      final r = activityEntry()
        ..addAll({
          'weekdays': [2],
          'time': '18:00',
          'reminderEnabled': true,
        });
      final original = CalendarDay.parse('2026-10-20');
      final snapshot = {...r}
        ..removeWhere(
          (k, v) => [
            'id',
            'name',
            'kind',
            'createdAtUtc',
            'updatedAtUtc',
          ].contains(k),
        );
      final o = {
        'id': WeeklySchedule.occurrenceId(r['id'] as String, original),
        'kind': 'activityOverride',
        'name': r['name'],
        'ruleId': r['id'],
        'originalDate': original.value,
        'movedDate': '2026-10-21',
        'ruleSnapshot': snapshot,
        'state': 'planned',
        'createdAtUtc': r['createdAtUtc'],
        'updatedAtUtc': r['updatedAtUtc'],
      };
      List<ActivityReminder> project() => activityReminders(
        WeeklySchedule.fromJson({
          'version': 1,
          'entries': [r, o],
        }),
        DateTime.utc(2026, 10, 19, 12),
        external: true,
        training: true,
      );
      expect(project().single.at.toUtc(), DateTime.utc(2026, 10, 21, 15, 30));
      o['state'] = 'completed';
      expect(project(), isEmpty);
      o['state'] = 'planned';
      r['enabled'] = false;
      expect(project(), isEmpty);
    },
  );
  test(
    'more than 60 one-shot alarms gives explicit limit, never silent truncation',
    () {
      final base = activityEntry()
        ..addAll({
          'weekdays': [1, 2, 3, 4, 5, 6, 7],
          'reminderEnabled': true,
        });
      final entries = [
        for (var n = 0; n < 10; n++)
          {...base, 'id': const Uuid().v5(base['id'] as String, '$n')},
      ];
      expect(
        () => activityReminders(
          WeeklySchedule.fromJson({'version': 1, 'entries': entries}),
          DateTime.utc(2026, 10, 19, 0),
          external: true,
          training: true,
        ),
        throwsStateError,
      );
    },
  );
  test('native optin gates, finite horizon and cross-midnight lead', () {
    final r = activityEntry()
      ..addAll({
        'weekdays': [2],
        'time': '00:15',
        'reminderEnabled': true,
        'reminderMinutesBefore': 30,
      });
    final schedule = WeeklySchedule.fromJson({
      'version': 1,
      'entries': [r],
    });
    final now = DateTime.utc(2026, 10, 19, 20);
    expect(
      activityReminders(schedule, now, external: false, training: true),
      isEmpty,
    );
    final reminders = activityReminders(
      schedule,
      now,
      external: true,
      training: true,
    );
    expect(reminders.first.at.toUtc(), DateTime.utc(2026, 10, 19, 21, 45));
    expect(reminders.first.id, greaterThan(1000));
    expect(
      activityReminders(schedule, now, external: true, training: true).first.id,
      reminders.first.id,
    );
    r['reminderEnabled'] = false;
    expect(
      activityReminders(
        WeeklySchedule.fromJson({
          'version': 1,
          'entries': [r],
        }),
        now,
        external: true,
        training: true,
      ),
      isEmpty,
    );
  });
  test('nonexistent Warsaw spring time skipped, autumn fold once', () {
    final r = activityEntry()
      ..addAll({
        'weekdays': [7],
        'time': '02:30',
        'reminderEnabled': true,
        'reminderMinutesBefore': 0,
      });
    final schedule = WeeklySchedule.fromJson({
      'version': 1,
      'entries': [r],
    });
    expect(
      activityReminders(
        schedule,
        DateTime.utc(2027, 3, 27, 12),
        external: true,
        training: true,
      ),
      isEmpty,
    );
    final autumn = activityReminders(
      schedule,
      DateTime.utc(2026, 10, 24, 12),
      external: true,
      training: true,
    );
    expect(autumn.first.at.toUtc(), DateTime.utc(2026, 10, 25, 0, 30));
  });
}
