// Testy TestScoreCalculator - skalowanie wyniku testu sprawnościowego do
// score 0-100 na podstawie progów low/high per typ testu.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/models/fitness_test.dart';
import 'package:fitbirek_training/core/utils/test_score_calculator.dart';

void main() {
  group('TestScoreCalculator.calculateScore - progi podstawowe', () {
    test('wynik poniżej progu low daje score 0', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.maxPompki, 5), 0);
    });

    test('wynik na progu low daje score 0', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.maxPompki, 10), 0);
    });

    test('wynik na progu high daje score 100', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.maxPompki, 50), 100);
    });

    test('wynik powyżej progu high jest clampowany do score 100', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.maxPompki, 999), 100);
    });

    test('wynik w połowie zakresu daje score ~50', () {
      // low=10, high=50 -> środek = 30
      expect(TestScoreCalculator.calculateScore(TypTestu.maxPompki, 30), 50);
    });
  });

  group('TestScoreCalculator.calculateScore - wszystkie 11 typów testów', () {
    test('pullUp: low=1, high=15', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.pullUp, 1), 0);
      expect(TestScoreCalculator.calculateScore(TypTestu.pullUp, 15), 100);
      expect(TestScoreCalculator.calculateScore(TypTestu.pullUp, 8), 50);
    });

    test('chinUp: low=1, high=18', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.chinUp, 1), 0);
      expect(TestScoreCalculator.calculateScore(TypTestu.chinUp, 18), 100);
    });

    test('plank: low=30, high=240 (sekundy)', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.plank, 30), 0);
      expect(TestScoreCalculator.calculateScore(TypTestu.plank, 240), 100);
      expect(TestScoreCalculator.calculateScore(TypTestu.plank, 135), 50);
    });

    test('wallSit: low=30, high=180', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.wallSit, 30), 0);
      expect(TestScoreCalculator.calculateScore(TypTestu.wallSit, 180), 100);
    });

    test('deadHang: low=15, high=120', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.deadHang, 15), 0);
      expect(TestScoreCalculator.calculateScore(TypTestu.deadHang, 120), 100);
    });

    test('przysiady60s: low=15, high=50', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.przysiady60s, 15), 0);
      expect(
        TestScoreCalculator.calculateScore(TypTestu.przysiady60s, 50),
        100,
      );
    });

    test('skakanka: low=30, high=300', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.skakanka, 30), 0);
      expect(TestScoreCalculator.calculateScore(TypTestu.skakanka, 300), 100);
    });

    test('cooper12min: low=1600, high=3000 (metry)', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.cooper12min, 1600), 0);
      expect(
        TestScoreCalculator.calculateScore(TypTestu.cooper12min, 3000),
        100,
      );
      expect(
        TestScoreCalculator.calculateScore(TypTestu.cooper12min, 2300),
        50,
      );
    });

    test('sklon: low=-20, high=20 (cm, dodatnie=lepiej)', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.sklon, -20), 0);
      expect(TestScoreCalculator.calculateScore(TypTestu.sklon, 20), 100);
      expect(TestScoreCalculator.calculateScore(TypTestu.sklon, 0), 50);
    });

    test('sklon: wartość ujemna poniżej progu low wciąż daje score 0', () {
      expect(TestScoreCalculator.calculateScore(TypTestu.sklon, -50), 0);
    });

    test('glebokiPrzysiad: low=0, high=10 (cm)', () {
      expect(
        TestScoreCalculator.calculateScore(TypTestu.glebokiPrzysiad, 0),
        0,
      );
      expect(
        TestScoreCalculator.calculateScore(TypTestu.glebokiPrzysiad, 10),
        100,
      );
    });

    test('maxPompki jest pokryty w grupie progów podstawowych', () {
      // Potwierdza że wszystkie 11 wartości enuma TypTestu mają obsłużony case
      // (celowo redundant - jeśli ktoś doda 12. typ bez obsługi, switch w
      // TestScoreCalculator nie skompiluje się bez tego case'a, więc ten test
      // dokumentuje kompletność, a nie wykrywa błąd w runtime).
      for (final typ in TypTestu.values) {
        expect(
          () => TestScoreCalculator.calculateScore(typ, 10),
          returnsNormally,
        );
      }
    });
  });

  group('TestScoreCalculator - wartości pośrednie i ujemne', () {
    test('wartość ujemna dla testu z low=0 daje score 0 (clamp)', () {
      expect(
        TestScoreCalculator.calculateScore(TypTestu.glebokiPrzysiad, -5),
        0,
      );
    });

    test('wynik zaokrąglany do najbliższej liczby całkowitej', () {
      // low=10, high=50, wynik=23 -> ratio=(23-10)/40=0.325 -> 32.5 -> round=33 (banker's? .round())
      final score = TestScoreCalculator.calculateScore(TypTestu.maxPompki, 23);
      expect(score, 33);
    });
  });
}
