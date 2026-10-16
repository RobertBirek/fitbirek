import 'dart:convert';
import '../../../core/database/app_database.dart';

/// Older clients parse all four legacy fields even for deleted plans.
/// Never read structureJson here. Invalid IDs get a tombstone-only fallback;
/// this does not repair or broaden the persisted live plan.
Map<String, Object?> workoutPlanDeletePayload(WorkoutPlanData plan) {
  var ids = <String>[];
  try {
    final value = jsonDecode(plan.cwiczeniaIds);
    if (value is List && value.every((id) => id is String)) {
      ids = value.cast<String>().toList();
    }
  } on FormatException {
    // Keep a legacy-readable deletion possible for a damaged local ID list.
  }
  return {
    'nazwa': plan.nazwa,
    'cwiczeniaIds': ids,
    'cel': plan.cel,
    'dataUtworzenia': plan.dataUtworzenia.toUtc().toIso8601String(),
  };
}
