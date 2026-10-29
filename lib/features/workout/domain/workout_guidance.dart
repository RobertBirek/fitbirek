import 'dart:convert';
import '../../planner/domain/structured_plan.dart';
import 'interval_timer.dart';
import '../../../core/sync/user_collections.dart';
import 'workout_repeat.dart';
import '../../../core/models/set_role.dart';

Map<String, dynamic> validateWorkoutDraft(Object? value) {
  try {
    final j = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
    if (j['draftRevision'] != null &&
        (j['draftRevision'] is! int || (j['draftRevision'] as int) < 0)) {
      throw const FormatException('Nieprawidłowa rewizja szkicu');
    }
    if (j['checkpointEpochs'] != null &&
        (j['checkpointEpochs'] is! Map ||
            (j['checkpointEpochs'] as Map).entries.any(
              (e) =>
                  e.key is! String || e.value is! int || (e.value as int) < 0,
            ))) {
      throw const FormatException('Nieprawidłowe generacje checkpointów');
    }
    if (j['schemaVersion'] != 1 ||
        j['currentSlot'] is! int ||
        (j['currentSlot'] as int) < 0 ||
        j['selectedIds'] is! List ||
        (j['selectedIds'] as List).any((id) => id is! String)) {
      throw const FormatException('Nieprawidłowy szkic');
    }
    final fields = Map<String, dynamic>.from(j['fields'] as Map);
    if (fields['repeatTargets'] != null) {
      final repeat = WorkoutRepeat.fromJson(fields['repeatTargets']);
      final completed = fields['repeatCompleted'] ?? <String>[];
      if (repeat.plan != null ||
          completed is! List ||
          completed.any((id) => id is! String || !UserCollections.isUuid(id)) ||
          completed.toSet().length != completed.length ||
          completed.length > repeat.targets.length) {
        throw const FormatException('Nieprawidłowy postęp powtórzenia');
      }
    }
    if (j['checkpointVersions'] != null &&
        (j['checkpointVersions'] is! Map ||
            (j['checkpointVersions'] as Map).entries.any(
              (e) =>
                  e.key is! String || e.value is! int || (e.value as int) < 0,
            ))) {
      throw const FormatException('Nieprawidłowe wersje checkpointów');
    }
    final guidance = WorkoutGuidance.tryRead(j['guidanceSignature'] as String?);
    _validateWorkoutForm(
      fields,
      guidedTarget: isGuidedTimeTargetForm(
        guidance,
        j['currentSlot'] as int,
        fields,
      ),
    );
    if (fields['guidedForms'] != null) {
      for (final entry in (fields['guidedForms'] as Map).entries) {
        final key = jsonDecode(entry.key as String) as List;
        final form = Map<String, dynamic>.from(entry.value as Map);
        if (!{6, 7}.contains(key.length) ||
            key[0] != 'guided' ||
            key[1] is! String ||
            key[2] is! int ||
            (key[2] as int) < 0 ||
            key[3] is! String ||
            form['side'] != key[4] ||
            form['variantId'] != key[5] ||
            (key.length == 7 &&
                (key[6] is! String || form['targetId'] != key[6]))) {
          throw const FormatException('Nieprawidłowy klucz szkicu bloku');
        }
        final binding = form['timerBinding'];
        final matchesKey =
            key.length == 7 &&
            binding is Map &&
            binding['sessionSyncId'] == key[1] &&
            binding['slotIndex'] == key[2] &&
            binding['exerciseId'] == key[3];
        _validateWorkoutForm(
          form,
          guidedTarget:
              matchesKey &&
              isGuidedTimeTargetForm(
                guidance,
                key[2] as int,
                form,
                archived: true,
              ),
        );
      }
    }
    if (fields['guidedSelections'] != null) {
      for (final entry in (fields['guidedSelections'] as Map).entries) {
        final slot = jsonDecode(entry.key as String) as List;
        final key = jsonDecode(entry.value as String) as List;
        if (!{2, 3}.contains(slot.length) ||
            key.length != slot.length + 4 ||
            key[0] != 'guided' ||
            slot[0] != key[2] ||
            slot[1] != key[3] ||
            (slot.length == 3 && slot[2] != key[6])) {
          throw const FormatException('Nieprawidłowy wybór szkicu bloku');
        }
      }
    }
    if (fields['extraForms'] != null) {
      for (final entry in (fields['extraForms'] as Map).entries) {
        final key = jsonDecode(entry.key as String) as List;
        final form = Map<String, dynamic>.from(entry.value as Map);
        if (key.length != 5 ||
            key[0] != 'extra' ||
            key[1] is! String ||
            key[2] is! String ||
            form['side'] != key[3] ||
            form['variantId'] != key[4]) {
          throw const FormatException('Nieprawidłowy klucz dodatkowego szkicu');
        }
        _validateWorkoutForm(form);
      }
    }
    if (fields['extraSelections'] != null) {
      for (final entry in (fields['extraSelections'] as Map).entries) {
        if (entry.key is! String) {
          throw const FormatException('Nieprawidłowy wybór ćwiczenia');
        }
        _validateWorkoutForm(Map<String, dynamic>.from(entry.value as Map));
      }
    }
    return j;
  } on TypeError {
    throw const FormatException('Nieprawidłowe typy szkicu');
  } on ArgumentError {
    throw const FormatException('Nieprawidłowy szkic');
  }
}

/// Derived from validated guidance and the exact form/binding, never from a
/// serialized flag or a targetId in an EXTRA namespace.
bool isGuidedTimeTargetForm(
  WorkoutGuidance? guidance,
  int slot,
  Map fields, {
  bool archived = false,
}) {
  if (guidance?.schemaVersion != 2 ||
      slot < 0 ||
      slot >= guidance!.plan.blocks.length) {
    return false;
  }
  final prescription = guidance.plan.blocks[slot].prescription;
  if (prescription.tracking != 'time') return false;
  final target = prescription.setTargets
      .where((t) => t.targetId == fields['targetId'])
      .firstOrNull;
  final binding = fields['timerBinding'];
  // An archive belongs to its historical identity, not a replacement's active
  // form. Keeping it readable does not permit capture/save under that identity.
  final exerciseIds = {
    guidance.exerciseAt(slot),
    if (archived) guidance.plan.blocks[slot].exerciseId,
    if (archived)
      ...guidance.events
          .where((e) => e['type'] == 'replaced' && e['slotIndex'] == slot)
          .map((e) => e['exerciseId']),
  };
  return target?.seconds != null &&
      target!.side == fields['side'] &&
      binding is Map &&
      binding['extra'] == false &&
      binding['sessionSyncId'] is String &&
      binding['slotIndex'] == slot &&
      exerciseIds.contains(binding['exerciseId']) &&
      binding['targetId'] == target.targetId &&
      binding['side'] == fields['side'] &&
      binding['variantId'] == fields['variantId'];
}

void _validateWorkoutForm(
  Map<String, dynamic> fields, {
  bool guidedTarget = false,
}) {
  SetRole.validate(fields['setRole']);
  if (fields['targetId'] != null &&
      (fields['targetId'] is! String ||
          (fields['targetId'] as String).trim().isEmpty ||
          (fields['targetId'] as String).runes.length > 80)) {
    throw const FormatException('Nieprawidłowy cel szkicu');
  }
  if (fields['variantId'] != null) UserCollections.validateVariantPair(fields);
  for (final key in ['reps', 'seconds', 'weight']) {
    if (fields[key] != null && fields[key] is! String) {
      throw const FormatException('Nieprawidłowe pola szkicu');
    }
  }
  if ((fields['side'] != null &&
          !{'left', 'right', 'both'}.contains(fields['side'])) ||
      (fields['rpe'] != null &&
          (fields['rpe'] is! int ||
              (fields['rpe'] as int) < 1 ||
              (fields['rpe'] as int) > 10))) {
    throw const FormatException('Nieprawidłowa strona lub RPE');
  }
  if (fields['timer'] != null) {
    final timer = IntervalTimer.restore(
      Map<String, dynamic>.from(fields['timer'] as Map),
      guidedTarget: guidedTarget,
    );
    if (fields['targetId'] != null &&
        (timer.config.rounds != 1 ||
            fields['timerBinding'] is! Map ||
            (fields['timerBinding'] as Map)['targetId'] !=
                fields['targetId'])) {
      throw const FormatException(
        'Timer indywidualnego celu wymaga jego tożsamości i jednej rundy.',
      );
    }
  }
  if (fields['timerBinding'] != null) {
    final binding = fields['timerBinding'];
    if (binding is! Map ||
        binding['sessionSyncId'] is! String ||
        binding['exerciseId'] is! String ||
        (binding['slotIndex'] != null &&
            (binding['slotIndex'] is! int ||
                (binding['slotIndex'] as int) < 0)) ||
        (binding['side'] != null &&
            !{'left', 'right', 'both'}.contains(binding['side'])) ||
        (binding['variantId'] != null && binding['variantId'] is! String) ||
        (binding['extra'] != null && binding['extra'] is! bool)) {
      throw const FormatException('Nieprawidłowe przypisanie timera');
    }
    if (binding['targetId'] != null &&
        (binding['targetId'] is! String ||
            binding['targetId'] != fields['targetId'])) {
      throw const FormatException('Nieprawidłowy cel timera');
    }
  }
}

/// Immutable original prescription and append-only execution facts. Slot identity
/// is positional, never encoded in an exercise name or a measurement.
class WorkoutGuidance {
  WorkoutGuidance._(
    this.schemaVersion,
    this.plan,
    List<Map<String, Object?>> events,
  ) : events = List.unmodifiable(events.map(Map<String, Object?>.unmodifiable));
  factory WorkoutGuidance.start(StructuredPlan plan) =>
      WorkoutGuidance.validateJson({
        'schemaVersion': plan.schemaVersion,
        'plan': plan.toJson(),
        'events': [],
      });
  final StructuredPlan plan;
  final int schemaVersion;
  final List<Map<String, Object?>> events;
  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'plan': plan.toJson(),
    'events': events,
  };
  static WorkoutGuidance validateJson(Object? value) {
    try {
      final j = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
      if (j['schemaVersion'] is! int ||
          !{1, 2}.contains(j['schemaVersion']) ||
          j.keys.any((k) => !{'schemaVersion', 'plan', 'events'}.contains(k))) {
        throw const FormatException('Nieobsługiwane prowadzenie');
      }
      final rawPlan = Map<String, dynamic>.from(j['plan'] as Map);
      if (rawPlan.keys.any(
        (k) => !{
          'schemaVersion',
          'criteria',
          'budgetSeconds',
          'level',
          'equipment',
          'blocks',
          'warnings',
        }.contains(k),
      )) {
        throw const FormatException('Nieobsługiwany snapshot planu');
      }
      for (final raw in rawPlan['blocks'] as List) {
        final b = Map<String, dynamic>.from(raw as Map);
        final prescription = Map<String, dynamic>.from(
          b['prescription'] as Map,
        );
        if (b.keys.any(
              (k) => !{'exerciseId', 'section', 'prescription'}.contains(k),
            ) ||
            prescription.keys.any(
              (k) => !{
                'tracking',
                'sets',
                'reps',
                'workSeconds',
                'restSeconds',
                'transitionSeconds',
                'weightKg',
                if (j['schemaVersion'] == 2) 'setTargets',
              }.contains(k),
            )) {
          throw const FormatException('Nieobsługiwane cele');
        }
      }
      final p = StructuredPlan.fromJson(
        Map<String, dynamic>.from(j['plan'] as Map),
      );
      if (p.blocks.isEmpty || p.schemaVersion != j['schemaVersion']) {
        throw const FormatException('Prowadzenie wymaga bloków');
      }
      final events = (j['events'] as List)
          .map((e) => Map<String, Object?>.from(e as Map))
          .toList();
      final linked = <String>{};
      final consumed = <String>{};
      final v2 = p.schemaVersion == 2;
      for (final e in events) {
        final keys = switch (e['type']) {
          'performed' => {'type', 'slotIndex', 'setSyncId', if (v2) 'targetId'},
          'skippedTarget' => {'type', 'slotIndex', 'targetId'},
          'replaced' => {'type', 'slotIndex', 'exerciseId'},
          _ => {'type', 'slotIndex'},
        };
        if (e.keys.any((k) => !keys.contains(k))) {
          throw const FormatException('Nieobsługiwane zdarzenie');
        }
        final slot = e['slotIndex'];
        if (slot is! int ||
            slot < 0 ||
            slot >= p.blocks.length ||
            !(v2
                    ? {'performed', 'skippedTarget', 'replaced'}
                    : {'performed', 'skipped', 'replaced'})
                .contains(e['type'])) {
          throw const FormatException('Nieprawidłowe zdarzenie prowadzenia');
        }
        if (v2 && {'performed', 'skippedTarget'}.contains(e['type'])) {
          final target = e['targetId'];
          if (target is! String ||
              !p.blocks[slot].prescription.setTargets.any(
                (t) => t.targetId == target,
              ) ||
              !consumed.add(jsonEncode([slot, target]))) {
            throw const FormatException('Nieprawidłowy lub już zużyty cel.');
          }
        }
        if (e['type'] == 'performed' &&
            (e['setSyncId'] is! String ||
                (e['setSyncId'] as String).isEmpty ||
                !linked.add(e['setSyncId'] as String))) {
          throw const FormatException('Nieprawidłowe powiązanie serii');
        }
        if (e['type'] == 'replaced' &&
            (e['exerciseId'] is! String ||
                (e['exerciseId'] as String).isEmpty)) {
          throw const FormatException('Nieprawidłowy zamiennik');
        }
        if (v2 &&
            e['type'] == 'replaced' &&
            p.blocks[slot].prescription.setTargets.any(
              (t) => (t.weightKg ?? 0) > 0,
            )) {
          throw const FormatException(
            'Nie można przenieść indywidualnego obciążenia na inny ruch.',
          );
        }
      }
      return WorkoutGuidance._(p.schemaVersion, p, events);
    } on TypeError {
      throw const FormatException('Nieprawidłowe typy prowadzenia');
    } on ArgumentError {
      throw const FormatException('Nieprawidłowe prowadzenie');
    } on JsonUnsupportedObjectError {
      throw const FormatException('Prowadzenie nie jest JSON');
    }
  }

  static WorkoutGuidance? tryRead(String? raw) {
    if (raw == null) return null;
    try {
      return validateJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  WorkoutGuidance _append(int slot, Map<String, Object?> event) {
    RangeError.checkValidIndex(slot, plan.blocks);
    return validateJson({
      ...toJson(),
      'events': [
        ...events,
        {...event, 'slotIndex': slot},
      ],
    });
  }

  WorkoutGuidance skip(int slot) => _append(slot, {'type': 'skipped'});
  WorkoutGuidance skipTarget(int slot, String targetId) =>
      _append(slot, {'type': 'skippedTarget', 'targetId': targetId});
  WorkoutGuidance replace(int slot, String exerciseId) {
    RangeError.checkValidIndex(slot, plan.blocks);
    if (schemaVersion == 2 &&
        plan.blocks[slot].prescription.setTargets.any(
          (t) => (t.weightKg ?? 0) > 0,
        )) {
      throw StateError(
        'Nie można przenieść indywidualnego obciążenia na inny ruch.',
      );
    }
    return _append(slot, {'type': 'replaced', 'exerciseId': exerciseId});
  }

  WorkoutGuidance link(int slot, String setSyncId, {String? targetId}) {
    RangeError.checkValidIndex(slot, plan.blocks);
    if (schemaVersion == 1 && events.any((e) => e['setSyncId'] == setSyncId)) {
      return this;
    }
    return _append(slot, {
      'type': 'performed',
      'setSyncId': setSyncId,
      if (targetId != null) 'targetId': targetId,
    });
  }

  String exerciseAt(int slot) {
    var id = plan.blocks[slot].exerciseId;
    for (final e in events) {
      if (e['slotIndex'] == slot && e['type'] == 'replaced') {
        id = e['exerciseId'] as String;
      }
    }
    return id;
  }

  List<String> additionalSetIds(Iterable<String> ids) {
    final linked = events
        .where((e) => e['type'] == 'performed')
        .map((e) => e['setSyncId'])
        .toSet();
    return ids.where((id) => !linked.contains(id)).toList();
  }
}
