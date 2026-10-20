import 'package:timezone/timezone.dart' as tz;
import 'weekly_schedule.dart';
import 'activity_schedule.dart';

class ActivityReminder {
  const ActivityReminder(
    this.id,
    this.occurrenceId,
    this.title,
    this.body,
    this.at,
  );
  final int id;
  final String occurrenceId, title, body;
  final tz.TZDateTime at;
}

/// One-shot, seven-day horizon. No repeating alarm can resurrect a completed or
/// moved occurrence. Opening/resuming the app refreshes this finite horizon.
List<ActivityReminder> activityReminders(
  WeeklySchedule schedule,
  DateTime now, {
  required bool external,
  required bool training,
}) {
  final zone = tz.getLocation('Europe/Warsaw');
  final local = tz.TZDateTime.from(now, zone);
  final first = CalendarDay.local(local);
  final live = {for (final e in schedule.entries) e['id']: e};
  final result = <ActivityReminder>[];
  final ids = <int>{};
  for (final o in schedule.between(first.plus(-1), first.plus(8))) {
    final source = live[o.ruleId];
    if (!o.isActivity ||
        o.isCompleted ||
        source == null ||
        source['deletedAtUtc'] != null ||
        source['enabled'] != true ||
        source['reminderEnabled'] != true ||
        o.ruleSnapshot['enabled'] != true ||
        o.ruleSnapshot['reminderEnabled'] != true ||
        !(o.activityType == ActivityType.external ? external : training)) {
      continue;
    }
    final date = o.date.localDate;
    final parts = o.time!.split(':').map(int.parse).toList();
    var start = tz.TZDateTime(
      zone,
      date.year,
      date.month,
      date.day,
      parts[0],
      parts[1],
    );
    // timezone normalizes nonexistent times. Do not silently notify an hour late.
    if (start.year != date.year ||
        start.month != date.month ||
        start.day != date.day ||
        start.hour != parts[0] ||
        start.minute != parts[1]) {
      continue;
    }
    final earlier = tz.TZDateTime.from(
      start.subtract(const Duration(hours: 1)),
      zone,
    );
    if (earlier.year == start.year &&
        earlier.month == start.month &&
        earlier.day == start.day &&
        earlier.hour == start.hour &&
        earlier.minute == start.minute) {
      start = earlier;
    }
    final at = tz.TZDateTime.from(
      start.subtract(
        Duration(minutes: o.ruleSnapshot['reminderMinutesBefore'] as int),
      ),
      zone,
    );
    if (!at.isAfter(now) || !at.isBefore(now.add(const Duration(days: 7)))) {
      continue;
    }
    final id =
        1000 + int.parse(o.id.replaceAll('-', '').substring(0, 7), radix: 16);
    if (!ids.add(id)) {
      throw StateError(
        'Kolizja identyfikatorów przypomnień. Zmień harmonogram.',
      );
    }
    result.add(
      ActivityReminder(id, o.id, o.name, '${o.time} · Europe/Warsaw', at),
    );
  }
  if (result.length > 60) {
    throw StateError(
      'Limit 60 przypomnień na 7 dni. Ogranicz liczbę terminów lub wyłącz część przypomnień.',
    );
  }
  result.sort(
    (a, b) => a.at.compareTo(b.at) != 0
        ? a.at.compareTo(b.at)
        : a.occurrenceId.compareTo(b.occurrenceId),
  );
  return result;
}
