import 'dart:convert';

class WorkoutDraftConflict extends StateError {
  WorkoutDraftConflict({this.revisionOnly = false})
    : super(
        'Szkic zmienił się w innym zapisie. Nowsze dane zachowano; wznów sesję ponownie.',
      );
  final bool revisionOnly;
}

Map<String, Object?> draftDomain(Map<String, Object?> payload) => {
  for (final key in [
    'schemaVersion',
    'currentSlot',
    'guidanceSignature',
    'fields',
    'selectedIds',
  ])
    if (payload.containsKey(key)) key: payload[key],
};

int draftRevision(Map<String, Object?>? payload) =>
    payload?['draftRevision'] as int? ?? 0;
Map<String, int> checkpointEpochs(Map<String, Object?>? payload) =>
    Map<String, int>.from(payload?['checkpointEpochs'] as Map? ?? {});
Map<String, int> checkpointVersions(Map<String, Object?>? payload) =>
    Map<String, int>.from(payload?['checkpointVersions'] as Map? ?? {});

/// Reconcile a committed consume against CURRENT RAM, not the snapshot taken
/// before SQLite awaits. Only the matching old timer may be retired. Selections,
/// metrics, other namespaces and a newer timer/binding keep their JSON values.
Map<String, Object?> mergeConsumedCheckpointFields(
  Map<String, Object?> current, {
  required String key,
  required bool extra,
  required Map<String, Object?> expectedForm,
}) {
  final merged = Map<String, Object?>.from(
    jsonDecode(jsonEncode(current)) as Map,
  );
  final forms = merged['extraForms'];
  final target = extra ? (forms is Map ? forms[key] : null) : merged;
  if (target is Map &&
      draftValueEquals(target['timer'], expectedForm['timer']) &&
      draftValueEquals(target['timerBinding'], expectedForm['timerBinding'])) {
    target['timer'] = null;
    target['timerBinding'] = null;
  }
  return merged;
}

Set<String> changedCheckpointKeys(
  String session,
  Map<String, Object?>? before,
  Map<String, Object?> after,
) {
  final a = before?['fields'] as Map? ?? {}, b = after['fields'] as Map? ?? {};
  bool changed(Map x, Map y) =>
      (x['timer'] != null || y['timer'] != null) &&
      (!draftValueEquals(x['timer'], y['timer']) ||
          !draftValueEquals(x['timerBinding'], y['timerBinding']));
  final result = <String>{};
  void mainKey(Map fields, Map? payload) {
    if (fields['timer'] == null || payload == null) return;
    final binding = fields['timerBinding'] as Map? ?? {};
    final signature = payload['guidanceSignature'];
    final plan = signature is String
        ? (jsonDecode(signature) as Map)['plan'] as Map
        : null;
    final slot = binding['slotIndex'] as int? ?? payload['currentSlot'] as int;
    final exerciseId =
        binding['exerciseId'] ??
        (plan == null ? null : (plan['blocks'] as List)[slot]['exerciseId']);
    if (exerciseId is String) {
      result.add(
        checkpointKey(
          session,
          exerciseId,
          fields['side'] as String?,
          fields['variantId'] as String?,
          extra: false,
          slot: slot,
          targetId:
              binding['targetId'] as String? ?? fields['targetId'] as String?,
        ),
      );
    }
  }

  if (changed(a, b)) {
    mainKey(a, before);
    mainKey(b, after);
  }
  final oldForms = {...?a['extraForms'] as Map?, ...?a['guidedForms'] as Map?},
      newForms = {...?b['extraForms'] as Map?, ...?b['guidedForms'] as Map?};
  for (final key in {
    ...oldForms.keys.cast<String>(),
    ...newForms.keys.cast<String>(),
  }) {
    if (changed(oldForms[key] as Map? ?? {}, newForms[key] as Map? ?? {})) {
      result.add(key);
    }
  }
  return result;
}

String checkpointKey(
  String? session,
  String exercise,
  String? side,
  String? variant, {
  required bool extra,
  int? slot,
  String? targetId,
}) => jsonEncode(
  extra
      ? ['extra', session, exercise, side, variant]
      : [
          'guided',
          session,
          slot,
          exercise,
          side,
          variant,
          if (targetId != null) targetId,
        ],
);

final _missing = Object();

bool draftValueEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && draftValueEquals(a[k], b[k]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        List.generate(
          a.length,
          (i) => draftValueEquals(a[i], b[i]),
        ).every((e) => e);
  }
  return a == b;
}

class _DraftChange {
  _DraftChange(this.path, this.before, this.after);
  final List<String> path;
  final Object? before, after;
}

/// Rebase only the captured edits, never an old full form snapshot. A concurrent
/// edit of the SAME leaf is an explicit conflict, not last-writer-wins data loss.
class WorkoutDraftPatch {
  WorkoutDraftPatch.between(
    Map<String, Object?> before,
    Map<String, Object?> after,
    this.expectedEpochs,
  ) {
    _diff(before, after, []);
  }
  final Map<String, int> expectedEpochs;
  final List<_DraftChange> _changes = [];

  void _diff(Object? before, Object? after, List<String> path) {
    if (draftValueEquals(before, after)) return;
    if (identical(before, _missing) && after is Map && after.isEmpty) {
      _changes.add(_DraftChange(path, before, after));
      return;
    }
    if ((before is Map || identical(before, _missing)) && after is Map) {
      final old = before is Map ? before : const {};
      for (final key in {
        ...old.keys.cast<String>(),
        ...after.keys.cast<String>(),
      }) {
        _diff(
          old.containsKey(key) ? old[key] : _missing,
          after.containsKey(key) ? after[key] : _missing,
          [...path, key],
        );
      }
      return;
    }
    if (before is Map && identical(after, _missing)) {
      _changes.add(_DraftChange(path, before, after));
      return;
    }
    _changes.add(_DraftChange(path, before, after));
  }

  Map<String, Object?> apply(
    Map<String, Object?> current, {
    Set<String> retiredByOwner = const {},
    String? ownGuidanceSignature,
  }) {
    final epochs = checkpointEpochs(current);
    for (final entry in expectedEpochs.entries) {
      if ((epochs[entry.key] ?? 0) != entry.value &&
          !retiredByOwner.contains(entry.key)) {
        throw WorkoutDraftConflict();
      }
    }
    final result = Map<String, Object?>.from(
      jsonDecode(jsonEncode(current)) as Map,
    );
    for (final change in _changes) {
      final path = change.path;
      if (path.length == 1 &&
          path.first == 'guidanceSignature' &&
          ownGuidanceSignature != null) {
        result['guidanceSignature'] = ownGuidanceSignature;
        continue;
      }
      final extraTimer =
          path.length >= 4 &&
          path[0] == 'fields' &&
          (path[1] == 'extraForms' || path[1] == 'guidedForms') &&
          (path[3] == 'timer' || path[3] == 'timerBinding');
      final mainTimer =
          path.length >= 2 &&
          path[0] == 'fields' &&
          (path[1] == 'timer' || path[1] == 'timerBinding');
      if ((extraTimer && retiredByOwner.contains(path[2])) ||
          (mainTimer &&
              retiredByOwner.any(
                (key) => (jsonDecode(key) as List).first == 'guided',
              ))) {
        continue;
      }
      Map node = result;
      var alreadyRemoved = false;
      for (final key in change.path.take(change.path.length - 1)) {
        if (node[key] == null) {
          if (identical(change.after, _missing)) {
            alreadyRemoved = true;
            break;
          }
          node[key] = <String, Object?>{};
        }
        if (node[key] is! Map) throw WorkoutDraftConflict();
        node = node[key] as Map;
      }
      if (alreadyRemoved) continue;
      final key = change.path.last;
      final actual = node.containsKey(key) ? node[key] : _missing;
      if (identical(change.before, _missing) &&
          change.after is Map &&
          (change.after as Map).isEmpty &&
          actual is Map) {
        continue;
      }
      if (path.length == 1 &&
          key == 'selectedIds' &&
          actual is List &&
          change.after is List &&
          (change.before is List || identical(change.before, _missing))) {
        final before = change.before is List ? change.before as List : const [];
        final after = change.after as List;
        node[key] = {
          ...actual.where((e) => !before.contains(e) || after.contains(e)),
          ...after.where((e) => !before.contains(e)),
        }.toList();
        continue;
      }
      if (identical(change.after, _missing) && actual == null) {
        node.remove(key);
        continue;
      }
      if (draftValueEquals(actual, change.after)) continue;
      if (!draftValueEquals(actual, change.before)) {
        throw WorkoutDraftConflict();
      }
      if (identical(change.after, _missing)) {
        node.remove(key);
      } else {
        node[key] = change.after;
      }
    }
    return result;
  }
}
