/// Neutral differences against the preceding set of the exact same scope.
/// Callers select exercise + side; incompatible/missing metrics are omitted.
String? setComparison({
  double? weightKg,
  int? reps,
  int? seconds,
  double? previousWeightKg,
  int? previousReps,
  int? previousSeconds,
}) {
  final parts = <String>[];
  void delta(num? current, num? previous, String unit) {
    if (current == null || previous == null) return;
    final difference = current - previous;
    final magnitude = difference.abs();
    final value = magnitude == magnitude.roundToDouble()
        ? magnitude.toInt().toString()
        : magnitude
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');
    parts.add(
      '${difference > 0
          ? '+'
          : difference < 0
          ? '−'
          : ''}$value $unit',
    );
  }

  delta(weightKg, previousWeightKg, 'kg');
  delta(reps, previousReps, 'powt.');
  delta(seconds, previousSeconds, 's');
  return parts.isEmpty ? null : parts.join(' • ');
}

String setSideLabel(String? side) => switch (side) {
  'left' => 'Lewa',
  'right' => 'Prawa',
  'both' => 'Obie',
  _ => 'Bez oznaczenia',
};
