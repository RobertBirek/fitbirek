import 'numeric_input.dart';

int? parseProfileAge(String text) {
  final value = text.trim();
  if (!RegExp(r'^\d+$').hasMatch(value)) return null;
  final age = int.tryParse(value);
  return age != null && age > 0 ? age : null;
}

String? validateProfileAge(String? text) => parseProfileAge(text ?? '') == null
    ? 'Wpisz dodatni wiek w pełnych latach.'
    : null;

bool validProfileNumbers(int age, double height, double weight) =>
    parseProfileAge(age.toString()) != null &&
    isPositiveFinite(height) &&
    isPositiveFinite(weight);

/// Round-trip representation: never round away stored fractional digits.
String formatProfileNumber(double value) {
  final text = value.toString();
  if (!text.contains('e')) return text;
  final parts = text.split('e');
  final exponent = int.parse(parts[1]);
  final digits = parts[0].replaceAll('.', '');
  final point =
      (parts[0].contains('.') ? parts[0].indexOf('.') : parts[0].length) +
      exponent;
  if (point <= 0) return '0.${'0' * -point}$digits';
  if (point >= digits.length) return '$digits${'0' * (point - digits.length)}';
  return '${digits.substring(0, point)}.${digits.substring(point)}';
}
