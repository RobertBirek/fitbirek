import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/exercises/presentation/exercise_illustrations.dart';

void main() {
  test('maps 90/90 hip stretch to its illustration asset', () {
    expect(exerciseIllustrationAsset('cw256'), 'assets/exercises/cw256.webp');
  });

  test('returns no illustration for an exercise without an asset', () {
    expect(exerciseIllustrationAsset('cw001'), isNull);
  });
}
