/// Read-only, deterministic input. The repository supplies only ended, live
/// sessions/sets. No equipment assumptions, free-text IDs, writes or 1RM.
class ProgressionPerformance {
  const ProgressionPerformance({
    required this.sessionId,
    required this.exerciseId,
    required this.endedAt,
    this.side,
    this.variantId,
    this.weightKg,
    this.reps,
    this.rpe,
  });
  final int sessionId;
  final String exerciseId;
  final String? side;
  final String? variantId;
  final DateTime endedAt;
  final double? weightKg;
  final int? reps, rpe;
}

class ProgressionEvidence {
  const ProgressionEvidence(this.sessionId, this.endedAt, this.reps, this.rpe);
  final int sessionId, reps, rpe;
  final DateTime endedAt;
}

class FixedLoadSuggestion {
  const FixedLoadSuggestion(
    this.reason, {
    this.target,
    this.weightKg,
    this.evidence = const [],
  });
  final String reason;
  final int? target;
  final double? weightKg;
  final List<ProgressionEvidence> evidence;
}

FixedLoadSuggestion proposeFixedLoad({
  required String exerciseId,
  required String? side,
  String? variantId,
  required String prescription,
  required String tracking,
  required bool usesWeight,
  required double? currentWeightKg,
  required List<ProgressionPerformance> history,
}) {
  const insufficient = FixedLoadSuggestion(
    'Brak wystarczającej historii: potrzebne dwa zakończone treningi tej samej strony, z tym samym ciężarem, wynikiem w zakresie i RPE 1–10. Utrzymaj własny cel.',
  );
  if (side != null && !const {'left', 'right', 'both'}.contains(side)) {
    return insufficient;
  }
  if (tracking != 'reps') {
    return const FixedLoadSuggestion(
      'Utrzymaj własny cel: brak porównywalnej konfiguracji czasu i przerw. Same sekundy rundy nie określają progresji.',
    );
  }
  // Strict Polish notation only. Unknown/free-text prescriptions fail closed.
  final match = RegExp(
    r'^\s*([1-9]\d*)\s*[x×]\s*([1-9]\d*)(?:\s*[-–]\s*([1-9]\d*))?\s*(?:powt\.?)?\s*$',
    caseSensitive: false,
  ).firstMatch(prescription);
  if (match == null) {
    return const FixedLoadSuggestion(
      'Utrzymaj własny cel: brak jednoznacznego zakresu powtórzeń (np. 3×8–12).',
    );
  }
  final lower = int.tryParse(match[2]!);
  final upper = int.tryParse(match[3] ?? match[2]!);
  if (lower == null ||
      upper == null ||
      lower > upper ||
      int.tryParse(match[1]!) == null) {
    return const FixedLoadSuggestion(
      'Utrzymaj własny cel: nieprawidłowy zakres powtórzeń.',
    );
  }
  if (usesWeight &&
      (currentWeightKg == null ||
          !currentWeightKg.isFinite ||
          currentWeightKg <= 0)) {
    return insufficient;
  }
  final groups = <int, List<ProgressionPerformance>>{};
  for (final row in history) {
    if (row.exerciseId != exerciseId ||
        row.side != side ||
        row.variantId != variantId ||
        (row.reps ?? 0) <= 0) {
      continue;
    }
    groups.putIfAbsent(row.sessionId, () => []).add(row);
  }
  final sessions = groups.values.toList()
    ..sort((a, b) {
      final date = b.first.endedAt.compareTo(a.first.endedAt);
      return date != 0 ? date : b.first.sessionId.compareTo(a.first.sessionId);
    });
  if (sessions.length < 2) return insufficient;
  final evidence = <ProgressionEvidence>[];
  for (final rows in sessions.take(2)) {
    if (rows.any(
      (r) =>
          r.rpe == null ||
          r.rpe! < 1 ||
          r.rpe! > 10 ||
          r.reps! < lower ||
          r.reps! > upper ||
          (usesWeight
              ? r.weightKg != currentWeightKg
              : r.weightKg != null && r.weightKg != 0),
    )) {
      return insufficient;
    }
    // Weakest result and hardest effort across the session, never cherry-pick
    // two easy sets or skip the latest incompatible training.
    final reps = rows.map((r) => r.reps!).reduce((a, b) => a < b ? a : b);
    final rpe = rows.map((r) => r.rpe!).reduce((a, b) => a > b ? a : b);
    evidence.add(
      ProgressionEvidence(rows.first.sessionId, rows.first.endedAt, reps, rpe),
    );
  }
  final baseline = evidence.first.reps;
  final effort = evidence.map((e) => e.rpe).reduce((a, b) => a > b ? a : b);
  var target = baseline;
  String reason;
  if (lower == upper) {
    reason = 'Stała liczba powtórzeń: utrzymaj cel i ciężar.';
  } else if (effort >= 9) {
    target = baseline > lower ? baseline - 1 : baseline;
    reason =
        'RPE ≥9: ostrożnie odejmij jedno powtórzenie lub utrzymaj dolną granicę. Bez zwiększania ciężaru.';
  } else if (effort == 8) {
    reason = 'RPE 8: utrzymaj cel i ciężar; bez presji na progresję.';
  } else if (baseline == upper) {
    reason =
        'Osiągnięto górną granicę: utrzymaj ciężar. Opcjonalny wariant z opisu wymaga Twojej osobnej decyzji.';
  } else {
    target = baseline + 1;
    reason =
        'Dwa zakończone treningi z RPE ≤7: możliwe +1 powtórzenie, najwyżej $upper. Ciężar bez zmian.';
  }
  return FixedLoadSuggestion(
    reason,
    target: target,
    weightKg: usesWeight ? currentWeightKg : null,
    evidence: List.unmodifiable(evidence),
  );
}
