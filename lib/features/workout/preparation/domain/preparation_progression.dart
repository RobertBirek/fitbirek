import '../../domain/fixed_load_progression.dart';
import 'equipment_inventory.dart';

class PreparationLoadSuggestion {
  PreparationLoadSuggestion({
    required this.reason,
    this.last,
    this.targetWeightKg,
    this.targetReps,
    List<ProgressionEvidence> evidence = const [],
  }) : evidence = List.unmodifiable(evidence);

  final String reason;
  final ProgressionPerformance? last;
  final double? targetWeightKg;
  final int? targetReps;
  final List<ProgressionEvidence> evidence;
}

/// The repository orders sets newest first within each ended session. Keep that
/// order: the last actually logged load is not the session maximum or a PR.
/// This function makes an offer only; it never edits a plan or a result.
PreparationLoadSuggestion proposePreparationLoad({
  required String exerciseId,
  required String? side,
  required String? variantId,
  required String prescription,
  required String tracking,
  required bool usesWeight,
  required LoadImplement? implement,
  required int quantity,
  required bool historyUnitConfirmed,
  required List<ProgressionPerformance> history,
  required EquipmentInventory inventory,
}) {
  final groups = <int, List<ProgressionPerformance>>{};
  for (final row in history) {
    if (row.exerciseId == exerciseId &&
        row.side == side &&
        row.variantId == variantId) {
      groups.putIfAbsent(row.sessionId, () => []).add(row);
    }
  }
  final sessions = groups.values.toList()
    ..sort((a, b) {
      final date = b.first.endedAt.compareTo(a.first.endedAt);
      return date != 0 ? date : b.first.sessionId.compareTo(a.first.sessionId);
    });
  final last = sessions.isEmpty ? null : sessions.first.first;
  PreparationLoadSuggestion none(String reason) =>
      PreparationLoadSuggestion(reason: reason, last: last);
  if (last == null) {
    return none('Pierwszy trening: wybierz własny ciężar lub cel z szablonu.');
  }
  if (!historyUnitConfirmed) {
    return none('Najpierw potwierdź sposób zapisu ciężaru w historii.');
  }
  if (tracking != 'reps') {
    return none(
      'Czas i rundy: ustaw własny cel, bez automatycznej progresji kg.',
    );
  }
  final match = RegExp(
    r'^\s*([1-9]\d*)\s*[x×]\s*([1-9]\d*)(?:\s*[-–]\s*([1-9]\d*))?\s*(?:powt\.?)?\s*$',
    caseSensitive: false,
  ).firstMatch(prescription);
  final sets = match == null ? null : int.tryParse(match[1]!);
  final lower = match == null ? null : int.tryParse(match[2]!);
  final upper = match == null ? null : int.tryParse(match[3] ?? match[2]!);
  if (sets == null ||
      lower == null ||
      upper == null ||
      sets > 5400 ||
      upper > 1800 ||
      lower > upper) {
    return none('Brak jednoznacznego zakresu serii i powtórzeń.');
  }
  if (sessions.length < 2 ||
      sessions.take(2).any((rows) => rows.length < sets)) {
    return none('Potrzebne są dwa zakończone treningi z kompletem serii.');
  }
  final recent = sessions.take(2).expand((rows) => rows).toList();
  if (recent.any((r) => (r.reps ?? 0) < lower || r.reps! > upper)) {
    return none('Ostatnie wyniki nie odpowiadają temu zakresowi powtórzeń.');
  }
  final base = proposeFixedLoad(
    exerciseId: exerciseId,
    side: side,
    variantId: variantId,
    prescription: prescription,
    tracking: tracking,
    usesWeight: usesWeight,
    currentWeightKg: last.weightKg,
    history: recent,
  );
  PreparationLoadSuggestion fixed() => PreparationLoadSuggestion(
    last: last,
    reason: base.reason,
    targetReps: base.target,
    evidence: base.evidence,
  );
  if (base.target == null ||
      lower == upper ||
      !usesWeight ||
      implement == null ||
      quantity < 1 ||
      quantity > implement.availableQuantity ||
      sessions.take(2).any((rows) => rows.length != sets) ||
      recent.any((r) => r.reps != upper || r.rpe == null || r.rpe! > 7)) {
    return fixed();
  }
  final kg = last.weightKg;
  if (kg == null || !kg.isFinite || kg <= 0) return fixed();
  final scaled = kg * 1000;
  if (!scaled.isFinite) return fixed();
  final grams = scaled.round();
  if ((scaled - grams).abs() > 0.000001 ||
      assembleLoad(
        inventory: inventory,
        implement: implement,
        targetGrams: grams,
        quantity: quantity,
      ).isEmpty) {
    return fixed();
  }
  final maximum = grams * 110 ~/ 100;
  int? next;
  if (implement == LoadImplement.fixedDumbbell) {
    final available =
        inventory.fixedDumbbells.entries
            .where(
              (e) => e.value >= quantity && e.key > grams && e.key <= maximum,
            )
            .map((e) => e.key)
            .toList()
          ..sort();
    next = available.firstOrNull;
  } else {
    final weights = inventory.plateCounts.entries
        .where((e) => e.value >= quantity * 2)
        .map((e) => e.key)
        .toList();
    if (weights.isNotEmpty) {
      final step = weights.reduce((a, b) => a.gcd(b)) * 2;
      for (
        var candidate = grams + step;
        candidate <= maximum;
        candidate += step
      ) {
        if (assembleLoad(
          inventory: inventory,
          implement: implement,
          targetGrams: candidate,
          quantity: quantity,
        ).isNotEmpty) {
          next = candidate;
          break;
        }
      }
    }
  }
  if (next == null) return fixed();
  return PreparationLoadSuggestion(
    last: last,
    reason:
        'Dwa pełne treningi na górnej granicy z RPE ≤7. Możesz wybrać najbliższy dostępny ciężar i wrócić do dolnej granicy powtórzeń. Zmiana wymaga Twojej decyzji.',
    targetWeightKg: next / 1000,
    targetReps: lower,
    evidence: base.evidence,
  );
}
