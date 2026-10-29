import 'dart:convert';
import '../../../core/sync/user_collections.dart';
import 'training_program.dart';
import 'weekly_schedule.dart';

/// Detached identity and optimistic revision of one planned date, not a cursor.
class ProgramOccurrence {
  ProgramOccurrence({
    required this.id,
    required this.programId,
    required this.originalDate,
    required this.date,
    required this.planSyncId,
    required this.planIndex,
    required this.name,
    required Map<String, dynamic> programSnapshot,
    required this.sourceRevision,
    this.sessionSyncId,
  }) : _snapshot = jsonEncode(programSnapshot);

  final String id, programId, planSyncId, name, sourceRevision;
  final int planIndex;
  final CalendarDay originalDate, date;
  final String? sessionSyncId;
  final String _snapshot;
  Map<String, dynamic> get programSnapshot =>
      jsonDecode(_snapshot) as Map<String, dynamic>;
  bool get isCompleted => sessionSyncId != null;
  String get mutationBaseline => UserCollections.canonical({
    'id': id,
    'programId': programId,
    'originalDate': originalDate.value,
    'date': date.value,
    'planSyncId': planSyncId,
    'name': name,
    'programSnapshot': programSnapshot,
    'sessionSyncId': sessionSyncId,
    'sourceRevision': sourceRevision,
  });
}

class TrainingProgramSchedule {
  TrainingProgramSchedule(this.programs);
  final TrainingPrograms programs;

  static int _days(CalendarDay a, CalendarDay b) => DateTime.parse(
    '${b.value}T12:00:00Z',
  ).difference(DateTime.parse('${a.value}T12:00:00Z')).inDays;

  /// Count the eligible dates strictly BEFORE this date in O(7), including
  /// partial first weeks. No session count, mutable index or local-midnight math.
  static int _ordinal(Map<String, dynamic> definition, CalendarDay date) {
    final first = CalendarDay.parse(definition['effectiveFromDate'] as String);
    final days = _days(first, date);
    final weekdays = (definition['weekdays'] as List).cast<int>().toSet();
    var count = (days ~/ 7) * weekdays.length;
    for (var i = 0; i < days % 7; i++) {
      if (weekdays.contains((first.weekday - 1 + i) % 7 + 1)) count++;
    }
    return count;
  }

  List<ProgramOccurrence> between(CalendarDay first, CalendarDay last) {
    if (last.compareTo(first) < 0 || _days(first, last) >= 366) {
      throw ArgumentError('Wybierz najwyżej 366 dni.');
    }
    final entries = programs.entries;
    final definitions = {
      for (final e in entries.where((e) => e['kind'] == 'program'))
        e['id'] as String: e,
    };
    final overrides = {
      for (final e in entries.where((e) => e['kind'] == 'programOverride'))
        e['id'] as String: e,
    };
    final result = <ProgramOccurrence>[];
    ProgramOccurrence occurrence(
      String programId,
      Map<String, dynamic> definition,
      CalendarDay original, {
      Map<String, dynamic>? override,
    }) {
      final index = _ordinal(definition, original) % 2;
      return ProgramOccurrence(
        id: TrainingPrograms.occurrenceId(programId, original),
        programId: programId,
        originalDate: original,
        date: override == null
            ? original
            : CalendarDay.parse(override['movedDate'] as String),
        planSyncId: (definition['planSyncIds'] as List)[index] as String,
        planIndex: index,
        name: override?['name'] as String? ?? definition['name'] as String,
        programSnapshot: definition,
        sourceRevision: UserCollections.canonical({
          'program': definitions[programId],
          'override': override,
        }),
        sessionSyncId: override?['state'] == 'completed'
            ? override!['sessionSyncId'] as String
            : null,
      );
    }

    for (final p in definitions.values.where(
      (p) => p['deletedAtUtc'] == null,
    )) {
      final start = CalendarDay.parse(p['effectiveFromDate'] as String);
      final end = p['endBeforeDate'] == null
          ? null
          : CalendarDay.parse(p['endBeforeDate'] as String);
      for (var offset = 0; offset <= _days(first, last); offset++) {
        final d = first.plus(offset);
        if (d.compareTo(start) < 0 ||
            (end != null && d.compareTo(end) >= 0) ||
            !(p['weekdays'] as List).contains(d.weekday)) {
          continue;
        }
        final id = TrainingPrograms.occurrenceId(p['id'] as String, d);
        if (!overrides.containsKey(id)) {
          result.add(
            occurrence(p['id'] as String, TrainingPrograms.snapshot(p), d),
          );
        }
      }
    }
    // Exceptions own the name and definition. Never substitute current program.
    for (final e in overrides.values.where((e) => e['deletedAtUtc'] == null)) {
      final moved = CalendarDay.parse(e['movedDate'] as String);
      if (moved.compareTo(first) < 0 || moved.compareTo(last) > 0) continue;
      result.add(
        occurrence(
          e['programId'] as String,
          Map<String, dynamic>.from(e['programSnapshot'] as Map),
          CalendarDay.parse(e['originalDate'] as String),
          override: e,
        ),
      );
    }
    return result..sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date == 0 ? a.id.compareTo(b.id) : date;
    });
  }
}
