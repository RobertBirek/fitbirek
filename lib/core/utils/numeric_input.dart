import '../models/fitness_test.dart';

/// Decimal input only: no grouping, exponent notation or non-finite values.
double? parseDecimal(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (!RegExp(r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$').hasMatch(normalized)) {
    return null;
  }
  final value = double.tryParse(normalized);
  return value != null && value.isFinite ? value : null;
}

bool isPositiveFinite(double value) => value.isFinite && value > 0;

String? validateMeasurement(String? text, {bool optional = false}) {
  if ((text ?? '').trim().isEmpty) {
    return optional ? null : 'Wpisz wartość.';
  }
  final value = parseDecimal(text!);
  if (value == null) return 'Wpisz poprawną liczbę.';
  return isPositiveFinite(value) ? null : 'Wpisz wartość większą od zera.';
}

String? validateTestResult(String? text, TypTestu type) {
  final value = parseDecimal(text ?? '');
  if (value == null) return 'Wpisz poprawną liczbę.';
  // Skłon: negative cm means not reaching the feet. Score thresholds
  // are not validity bounds. All other catalog metrics are nonnegative.
  if (type != TypTestu.sklon && value < 0) {
    return 'Wpisz wartość nieujemną.';
  }
  if (type.jednostka == 'powt' && value != value.truncateToDouble()) {
    return 'Wpisz całkowitą liczbę powtórzeń.';
  }
  return null;
}
