import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/sync/user_collections.dart';
import 'weekly_schedule.dart';

enum ActivityType { external, fitbirek }

enum LegacyActivitySource { legacyKarate, legacyTraining }

/// Stable presence marker: migration must check this ID including tombstones.
/// Editing replaces the rule, but never removes/reuses the original marker.
String legacyActivityRuleId(String profileSyncId, LegacyActivitySource source) {
  if (!UserCollections.isUuid(profileSyncId)) {
    throw ArgumentError.value(profileSyncId, 'profileSyncId');
  }
  return const Uuid().v5(profileSyncId, 'FitBirek/activity/${source.name}');
}

class ActivityDraft {
  ActivityDraft({
    required this.name,
    required this.activityType,
    required Set<int> weekdays,
    required this.time,
    required this.effectiveFrom,
    this.timeZone = 'Europe/Warsaw',
    this.durationMinutes,
    this.enabled = true,
    this.planSyncId,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 0,
  }) : weekdays = Set.unmodifiable(weekdays);
  final String name, time, timeZone;
  final ActivityType activityType;
  final Set<int> weekdays;
  final CalendarDay effectiveFrom;
  final int? durationMinutes;
  final bool enabled, reminderEnabled;
  final int reminderMinutesBefore;
  final String? planSyncId;

  Map<String, dynamic> toFields() => {
    'name': name,
    'activityType': activityType.name,
    'weekdays': weekdays.toList()..sort(),
    'time': time,
    'timeZone': timeZone,
    'durationMinutes': durationMinutes,
    'enabled': enabled,
    'planSyncId': planSyncId,
    'effectiveFromDate': effectiveFrom.value,
    'reminderEnabled': reminderEnabled,
    'reminderMinutesBefore': reminderMinutesBefore,
  };
}

/// Complete, immutable optimistic baseline, including the envelope and unknown
/// fields. Legacy rules are exposed too; their time stays null until edited.
class ActivityRule {
  ActivityRule.fromJson(Map<String, dynamic> json) : _raw = jsonEncode(json) {
    UserCollections.validate('weeklySchedule', {
      'version': 1,
      'entries': [json],
    });
    if (!['rule', 'activityRule'].contains(json['kind'])) {
      throw const FormatException('To nie jest reguła.');
    }
  }
  final String _raw;
  Map<String, dynamic> toJson() => jsonDecode(_raw) as Map<String, dynamic>;
  String get id => toJson()['id'] as String;
  String get name => toJson()['name'] as String;
  bool get isLegacy => toJson()['kind'] == 'rule';
  bool get isDeleted => toJson()['deletedAtUtc'] != null;
  bool get enabled => !isDeleted && toJson()['enabled'] != false;
  ActivityType get activityType => toJson()['activityType'] == 'external'
      ? ActivityType.external
      : ActivityType.fitbirek;
  String? get time => toJson()['time'] as String?;
  String get timeZone => toJson()['timeZone'] as String? ?? 'Europe/Warsaw';
  String? get planSyncId => toJson()['planSyncId'] as String?;
  int? get durationMinutes => toJson()['durationMinutes'] as int?;
  Set<int> get weekdays => Set.unmodifiable(
    isLegacy
        ? [toJson()['weekday'] as int]
        : (toJson()['weekdays'] as List).cast<int>(),
  );
  CalendarDay get effectiveFrom =>
      CalendarDay.parse(toJson()['effectiveFromDate'] as String);
  bool get reminderEnabled => toJson()['reminderEnabled'] == true;
  int get reminderMinutesBefore =>
      toJson()['reminderMinutesBefore'] as int? ?? 0;
}

void validateActivityFields(Map r) {
  Never bad() =>
      throw const FormatException('Nieprawidłowa aktywność. Dane zachowano.');
  if (!['external', 'fitbirek'].contains(r['activityType']) ||
      r['weekdays'] is! List ||
      (r['weekdays'] as List).isEmpty ||
      (r['weekdays'] as List).any((d) => d is! int || d < 1 || d > 7) ||
      (r['weekdays'] as List).toSet().length !=
          (r['weekdays'] as List).length ||
      r['time'] is! String ||
      !RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(r['time'] as String) ||
      r['timeZone'] != 'Europe/Warsaw' ||
      r['enabled'] is! bool ||
      r['reminderEnabled'] is! bool ||
      r['reminderMinutesBefore'] is! int ||
      (r['reminderMinutesBefore'] as int) < 0 ||
      (r['reminderMinutesBefore'] as int) > 1440 ||
      r['effectiveFromDate'] is! String) {
    bad();
  }
  CalendarDay.parse(r['effectiveFromDate'] as String);
  final duration = r['durationMinutes'];
  if (duration != null &&
      (duration is! int || duration < 1 || duration > 1440)) {
    bad();
  }
  final plan = r['planSyncId'];
  if (plan != null &&
      (r['activityType'] != 'fitbirek' || !UserCollections.isUuid(plan))) {
    bad();
  }
  if (r['legacySource'] != null &&
      !LegacyActivitySource.values.any((s) => s.name == r['legacySource'])) {
    bad();
  }
}
