import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/models/fitness_test.dart';
import 'package:fitbirek_training/core/utils/numeric_input.dart';

void main() {
  test('decimal parser trims and supports either separator, not nonfinite', () {
    expect(parseDecimal(' 12,5 '), 12.5);
    expect(parseDecimal('-2.5'), -2.5);
    expect(parseDecimal('0'), 0);
    for (final text in [
      '',
      ' ',
      'NaN',
      'Infinity',
      '-Infinity',
      '1e999',
      '1,2.3',
      '1 234',
      '--2',
      'abc',
    ]) {
      expect(parseDecimal(text), isNull, reason: text);
    }
  });
  test(
    'optional empty differs from malformed; body dimensions are positive',
    () {
      expect(validateMeasurement(' ', optional: true), isNull);
      for (final text in ['abc', '0', '-1', 'NaN']) {
        expect(validateMeasurement(text, optional: true), isNotNull);
      }
      expect(validateMeasurement(''), isNotNull);
      expect(validateMeasurement('1000,5'), isNull);
    },
  );
  test('catalog units constrain results without score-derived maxima', () {
    for (final type in TypTestu.values) {
      expect(validateTestResult('0', type), isNull, reason: type.name);
      expect(validateTestResult('100000', type), isNull);
      expect(
        validateTestResult('-2,5', type),
        type == TypTestu.sklon ? isNull : isNotNull,
      );
      expect(
        validateTestResult('1,5', type),
        type.jednostka == 'powt' ? isNotNull : isNull,
      );
      expect(validateTestResult('NaN', type), isNotNull);
    }
  });
}
