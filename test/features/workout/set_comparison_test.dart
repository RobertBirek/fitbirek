import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/utils/set_comparison.dart';

void main() {
  test('deltas compare only shared metrics, not estimated 1RM', () {
    expect(
      setComparison(
        weightKg: 22,
        reps: 8,
        previousWeightKg: 20,
        previousReps: 10,
      ),
      '+2 kg • −2 powt.',
    );
    expect(setComparison(seconds: 30, previousSeconds: 25), '+5 s');
    expect(setComparison(reps: 8, previousReps: 8), '0 powt.');
    expect(setComparison(reps: 8, previousSeconds: 30), isNull);
    expect(setComparison(weightKg: 20, reps: 8, previousReps: 6), '+2 powt.');
  });
}
