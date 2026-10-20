import 'package:uuid/uuid.dart';
import '../../../core/sync/user_collections.dart';
import 'activity_schedule.dart';

/// Calendar arithmetic uses UTC only as a neutral Gregorian calculator, never
/// as the instant corresponding to a local midnight (DST days need not be 24h).
class CalendarDay implements Comparable<CalendarDay> {
  CalendarDay._(this.value);
  factory CalendarDay.parse(String value) {
    final d = DateTime.tryParse('${value}T12:00:00Z');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
        d == null ||
        _format(d) != value) {
      throw const FormatException('Nieprawidłowy dzień kalendarza.');
    }
    return CalendarDay._(value);
  }
  factory CalendarDay.local(DateTime local) =>
      CalendarDay.parse(_format(local));
  final String value;
  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  DateTime get _date => DateTime.parse('${value}T12:00:00Z');
  DateTime get localDate => DateTime(_date.year, _date.month, _date.day);
  int get weekday => _date.weekday;
  CalendarDay plus(int days) =>
      CalendarDay.parse(_format(_date.add(Duration(days: days))));
  CalendarDay get monday => plus(1 - weekday);
  @override
  int compareTo(CalendarDay other) => value.compareTo(other.value);
  @override
  bool operator ==(Object other) =>
      other is CalendarDay && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

class ScheduleOccurrence {
  ScheduleOccurrence({
    required this.id,
    required this.ruleId,
    required this.originalDate,
    required this.date,
    required this.planSyncId,
    required this.name,
    required this.ruleSnapshot,
    this.sessionSyncId,
    this.time,
    this.activityType = ActivityType.fitbirek,
    this.durationMinutes,
    this.externalCompleted = false,
    this.sourceRevision,
  });
  final String id, ruleId, name;
  final String? planSyncId, time;
  final ActivityType activityType;
  final int? durationMinutes;
  final bool externalCompleted;
  bool get isCompleted => externalCompleted || sessionSyncId != null;
  bool get isActivity => ruleSnapshot.containsKey('activityType');
  final CalendarDay originalDate, date;
  final Map<String, dynamic> ruleSnapshot;
  final String? sessionSyncId;

  /// Local optimistic baseline, not a wire field. Canonical strings retain an
  /// immutable copy of the full source rule and previous override envelopes,
  /// including timestamps/unknown fields and explicit absence of either entry.
  /// A move away and back must not renew a confirmation already on screen.
  final String? sourceRevision;

  String get mutationBaseline => UserCollections.canonical({
    'id': id,
    'ruleId': ruleId,
    'originalDate': originalDate.value,
    'date': date.value,
    'planSyncId': planSyncId,
    'name': name,
    'ruleSnapshot': ruleSnapshot,
    'sessionSyncId': sessionSyncId,
    'time': time,
    'activityType': activityType.name,
    'durationMinutes': durationMinutes,
    'externalCompleted': externalCompleted,
    'sourceRevision': sourceRevision,
  });
}

class WeeklySchedule {
  WeeklySchedule.fromJson(Object? json)
    : entries = List<Map<String, dynamic>>.unmodifiable(
        (UserCollections.validate('weeklySchedule', json)['entries'] as List)
            .map((e) => Map<String, dynamic>.unmodifiable(e as Map)),
      );
  final List<Map<String, dynamic>> entries;
  Map<String, dynamic> toJson() => {'version': 1, 'entries': entries};
  static String occurrenceId(String ruleId, CalendarDay original) =>
      const Uuid().v5(ruleId, original.value);

  static void validateEntry(Map<String, dynamic> e) {
    Never bad() => throw const FormatException(
      'Nieprawidłowy wpis harmonogramu. Dane zachowano.',
    );
    void rule(Map r) {
      if (!UserCollections.isUuid(r['planSyncId']) ||
          r['weekday'] is! int ||
          (r['weekday'] as int) < 1 ||
          (r['weekday'] as int) > 7 ||
          r['effectiveFromDate'] is! String) {
        bad();
      }
      CalendarDay.parse(r['effectiveFromDate'] as String);
    }

    if (e['kind'] == 'activityRule') {
      validateActivityFields(e);
    } else if (e['kind'] == 'activityOverride') {
      if (!UserCollections.isUuid(e['ruleId']) ||
          e['originalDate'] is! String ||
          e['movedDate'] is! String ||
          e['ruleSnapshot'] is! Map ||
          !['planned', 'completed'].contains(e['state'])) {
        bad();
      }
      final snapshot = e['ruleSnapshot'] as Map;
      validateActivityFields(snapshot);
      final original = CalendarDay.parse(e['originalDate'] as String);
      CalendarDay.parse(e['movedDate'] as String);
      if (!(snapshot['weekdays'] as List).contains(original.weekday) ||
          original.compareTo(
                CalendarDay.parse(snapshot['effectiveFromDate'] as String),
              ) <
              0 ||
          e['id'] != occurrenceId(e['ruleId'] as String, original)) {
        bad();
      }
      if (e['state'] == 'completed' && snapshot['activityType'] == 'fitbirek'
          ? !UserCollections.isUuid(e['sessionSyncId'])
          : e['sessionSyncId'] != null) {
        bad();
      }
    } else if (e['kind'] == 'rule') {
      rule(e);
    } else if (e['kind'] == 'override') {
      if (!UserCollections.isUuid(e['ruleId']) ||
          e['originalDate'] is! String ||
          e['movedDate'] is! String ||
          e['ruleSnapshot'] is! Map ||
          !['planned', 'completed'].contains(e['state'])) {
        bad();
      }
      final original = CalendarDay.parse(e['originalDate'] as String);
      CalendarDay.parse(e['movedDate'] as String);
      rule(e['ruleSnapshot'] as Map);
      final snapshot = e['ruleSnapshot'] as Map;
      if (original.weekday != snapshot['weekday'] ||
          original.compareTo(
                CalendarDay.parse(snapshot['effectiveFromDate'] as String),
              ) <
              0 ||
          e['id'] != occurrenceId(e['ruleId'] as String, original)) {
        bad();
      }
      if (e['state'] == 'completed'
          ? !UserCollections.isUuid(e['sessionSyncId'])
          : e['sessionSyncId'] != null) {
        bad();
      }
    } else {
      bad();
    }
  }

  /// Only the requested finite window is expanded. Persisted exceptions are
  /// considered independently of live rules: deletion never erases history.
  List<ScheduleOccurrence> between(CalendarDay first, CalendarDay last) {
    if (last.compareTo(first) < 0 ||
        last._date.difference(first._date).inDays > 366) {
      throw ArgumentError('Wybierz najwyżej rok.');
    }
    final overrides = {
      for (final e in entries.where(
        (e) => ['override', 'activityOverride'].contains(e['kind']),
      ))
        e['id'] as String: e,
    };
    final sourceRules = {
      for (final e in entries.where(
        (e) => ['rule', 'activityRule'].contains(e['kind']),
      ))
        e['id'] as String: e,
    };
    final result = <String, ScheduleOccurrence>{};
    ScheduleOccurrence occurrence(
      Map<String, dynamic> rule,
      CalendarDay original, {
      Map<String, dynamic>? override,
    }) => ScheduleOccurrence(
      id: occurrenceId(rule['id'] as String, original),
      ruleId: rule['id'] as String,
      sourceRevision: UserCollections.canonical({
        'rule': sourceRules[rule['id']],
        'override': override,
      }),
      originalDate: original,
      date: override == null
          ? original
          : CalendarDay.parse(override['movedDate'] as String),
      planSyncId: rule['planSyncId'] as String?,
      time: rule['time'] as String?,
      activityType: rule['activityType'] == 'external'
          ? ActivityType.external
          : ActivityType.fitbirek,
      durationMinutes: rule['durationMinutes'] as int?,
      externalCompleted:
          rule['activityType'] == 'external' &&
          override?['state'] == 'completed',
      name: override?['name'] as String? ?? rule['name'] as String,
      ruleSnapshot: rule.containsKey('activityType')
          ? {
              for (final key in rule.keys.where(
                (k) => ![
                  'id',
                  'name',
                  'kind',
                  'createdAtUtc',
                  'updatedAtUtc',
                  'deletedAtUtc',
                ].contains(k),
              ))
                key: rule[key],
            }
          : {
              'planSyncId': rule['planSyncId'],
              'weekday': rule['weekday'],
              'effectiveFromDate': rule['effectiveFromDate'],
            },
      sessionSyncId: override?['state'] == 'completed'
          ? override!['sessionSyncId'] as String?
          : null,
    );
    for (final r in entries.where(
      (e) =>
          ['rule', 'activityRule'].contains(e['kind']) &&
          e['deletedAtUtc'] == null &&
          e['enabled'] != false,
    )) {
      for (var d = first; d.compareTo(last) <= 0; d = d.plus(1)) {
        if ((r['kind'] == 'rule'
                ? d.weekday != r['weekday']
                : !(r['weekdays'] as List).contains(d.weekday)) ||
            d.compareTo(CalendarDay.parse(r['effectiveFromDate'] as String)) <
                0) {
          continue;
        }
        final id = occurrenceId(r['id'] as String, d);
        if (!overrides.containsKey(id)) result[id] = occurrence(r, d);
      }
    }
    for (final e in overrides.values.where((e) => e['deletedAtUtc'] == null)) {
      final d = CalendarDay.parse(e['movedDate'] as String);
      if (d.compareTo(first) < 0 || d.compareTo(last) > 0) continue;
      final r = Map<String, dynamic>.from(e['ruleSnapshot'] as Map)
        ..['id'] = e['ruleId']
        ..['name'] = e['name'];
      result[e['id'] as String] = occurrence(
        r,
        CalendarDay.parse(e['originalDate'] as String),
        override: e,
      );
    }
    return result.values.toList()..sort((a, b) {
      final c = a.date.compareTo(b.date);
      if (c != 0) return c;
      final time = (a.time ?? '99:99').compareTo(b.time ?? '99:99');
      return time == 0 ? a.id.compareTo(b.id) : time;
    });
  }
}
