import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/sync/user_collections.dart';
import 'weekly_schedule.dart';

/// Profile collection codec only. Calendar expansion and account-aware writes
/// belong to the program repository, not this sync/backup trust boundary.
class TrainingPrograms {
  TrainingPrograms.fromJson(Object? value)
    : _json = UserCollections.validate('trainingPrograms', value);
  final Map<String, dynamic> _json;
  List<Map<String, dynamic>> get entries =>
      (toJson()['entries'] as List).cast<Map<String, dynamic>>();
  Map<String, dynamic> toJson() =>
      jsonDecode(jsonEncode(_json)) as Map<String, dynamic>;

  static String occurrenceId(String programId, CalendarDay originalDate) =>
      const Uuid().v5(programId.toLowerCase(), originalDate.value);
  static const _core = {'planSyncIds', 'weekdays', 'effectiveFromDate'};
  static const _envelope = {
    'id',
    'kind',
    'name',
    'createdAtUtc',
    'updatedAtUtc',
    'deletedAtUtc',
  };

  static Map<String, dynamic> snapshot(Map<String, dynamic> program) =>
      jsonDecode(
            jsonEncode({
              'name': program['name'],
              for (final key in _core) key: program[key],
              if (program.containsKey('endBeforeDate'))
                'endBeforeDate': program['endBeforeDate'],
            }),
          )
          as Map<String, dynamic>;

  static void _definition(Map<String, dynamic> e) {
    final plans = e['planSyncIds'], days = e['weekdays'];
    if (plans is! List ||
        plans.length != 2 ||
        plans.any((id) => !UserCollections.isUuid(id)) ||
        plans.map((id) => (id as String).toLowerCase()).toSet().length != 2 ||
        days is! List ||
        days.isEmpty ||
        days.length > 7 ||
        days.toSet().length != days.length ||
        days.any((d) => d is! int || d < 1 || d > 7) ||
        e['effectiveFromDate'] is! String) {
      throw const FormatException('Nieprawidłowa definicja programu A/B.');
    }
    final start = CalendarDay.parse(e['effectiveFromDate'] as String);
    if (e.containsKey('endBeforeDate')) {
      if (e['endBeforeDate'] is! String ||
          CalendarDay.parse(e['endBeforeDate'] as String).compareTo(start) <
              0) {
        throw const FormatException('Nieprawidłowa granica programu.');
      }
    }
  }

  static void validateEntry(Map<String, dynamic> e) {
    Never bad() => throw const FormatException(
      'Nieprawidłowy wpis programu. Dane zachowano.',
    );
    if (e['kind'] == 'program') {
      if (e.keys.any(
        (k) => !{..._envelope, ..._core, 'endBeforeDate'}.contains(k),
      )) {
        bad();
      }
      _definition(e);
    } else if (e['kind'] == 'programOverride') {
      if (e.keys.any(
            (k) => !{
              ..._envelope,
              'programId',
              'originalDate',
              'movedDate',
              'state',
              'sessionSyncId',
              'programSnapshot',
            }.contains(k),
          ) ||
          !UserCollections.isUuid(e['programId']) ||
          e['originalDate'] is! String ||
          e['movedDate'] is! String ||
          e['programSnapshot'] is! Map ||
          !{'planned', 'completed'}.contains(e['state'])) {
        bad();
      }
      final original = CalendarDay.parse(e['originalDate'] as String);
      CalendarDay.parse(e['movedDate'] as String);
      final s = Map<String, dynamic>.from(e['programSnapshot'] as Map);
      if (s.keys.any((k) => !{..._core, 'name', 'endBeforeDate'}.contains(k)) ||
          s['name'] is! String ||
          (s['name'] as String).trim().isEmpty ||
          (s['name'] as String).runes.length > 80) {
        bad();
      }
      _definition(s);
      if (e['id'] != occurrenceId(e['programId'] as String, original) ||
          !(s['weekdays'] as List).contains(original.weekday) ||
          original.compareTo(
                CalendarDay.parse(s['effectiveFromDate'] as String),
              ) <
              0 ||
          (s['endBeforeDate'] != null &&
              original.compareTo(
                    CalendarDay.parse(s['endBeforeDate'] as String),
                  ) >=
                  0) ||
          (e['state'] == 'completed'
              ? !UserCollections.isUuid(e['sessionSyncId'])
              : e['sessionSyncId'] != null)) {
        bad();
      }
    } else {
      bad();
    }
  }

  static String _coreSignature(Map e) {
    final days = (e['weekdays'] as List).cast<int>().toList()..sort();
    return UserCollections.canonical({
      'planSyncIds': (e['planSyncIds'] as List)
          .map((v) => (v as String).toLowerCase())
          .toList(),
      'weekdays': days,
      'effectiveFromDate': e['effectiveFromDate'],
    });
  }

  /// Check BOTH revisions before LWW, including a losing/tombstoned revision.
  /// Omission can preserve a cutoff, never remove it; competing cutoffs conflict.
  static void requireCompatible(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    if (a['kind'] != b['kind'] ||
        (a['kind'] == 'program'
            ? (_coreSignature(a) != _coreSignature(b) ||
                  (a['endBeforeDate'] != null &&
                      b['endBeforeDate'] != null &&
                      a['endBeforeDate'] != b['endBeforeDate']))
            : UserCollections.canonical({
                    for (final k in [
                      'programId',
                      'originalDate',
                      'programSnapshot',
                    ])
                      k: a[k],
                  }) !=
                  UserCollections.canonical({
                    for (final k in [
                      'programId',
                      'originalDate',
                      'programSnapshot',
                    ])
                      k: b[k],
                  }))) {
      throw const FormatException(
        'Konflikt niezmiennej definicji lub granicy programu. Dane zachowano.',
      );
    }
  }

  static Map<String, dynamic> preserveCutoff(
    Map<String, dynamic> winner,
    Map<String, dynamic> other,
  ) => {
    ...winner,
    if (winner['kind'] == 'program' &&
        !winner.containsKey('endBeforeDate') &&
        other['endBeforeDate'] != null)
      'endBeforeDate': other['endBeforeDate'],
  };

  static void requirePreserved(Object? previous, Object? next) {
    final a = UserCollections.validate(
      'trainingPrograms',
      previous ?? UserCollections.empty(),
    );
    final b = UserCollections.validate(
      'trainingPrograms',
      next ?? UserCollections.empty(),
    );
    final byId = {
      for (final raw in b['entries'] as List)
        (raw['id'] as String).toLowerCase(): raw as Map<String, dynamic>,
    };
    for (final raw in a['entries'] as List) {
      final old = raw as Map<String, dynamic>;
      final fresh = byId[(old['id'] as String).toLowerCase()];
      if (fresh == null)
        throw const FormatException(
          'Nie można usunąć definicji ani wyjątków programu.',
        );
      requireCompatible(old, fresh);
      if (old['endBeforeDate'] != null &&
          fresh['endBeforeDate'] != old['endBeforeDate']) {
        throw const FormatException(
          'Nie można usunąć zamkniętej granicy programu.',
        );
      }
    }
  }
}
