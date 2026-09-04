// Testy PrDetector - szacowany 1RM (formuła Epley) i wykrywanie nowych PR.
// Uwaga: 2 podstawowe przypadki są już w test/widget_test.dart (smoke test),
// ten plik rozszerza pokrycie zgodnie z konwencją per-feature z CONTRIBUTING.md.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/core/utils/pr_detector.dart';

void main() {
  group('PrDetector.epley1Rm', () {
    test('liczy szacowany 1RM wg formuły Epley', () {
      // ciezar * (1 + powtorzenia/30) = 100 * (1 + 5/30) = 116.666...
      expect(PrDetector.epley1Rm(100, 5), closeTo(116.67, 0.01));
    });

    test('dla 1 powtórzenia 1RM jest bliski samemu ciężarowi', () {
      final result = PrDetector.epley1Rm(80, 1);
      expect(result, closeTo(82.67, 0.01));
    });

    test('dla 0 powtórzeń zwraca sam ciężar (brak bonusu)', () {
      expect(PrDetector.epley1Rm(50, 0), 50.0);
    });

    test('większa liczba powtórzeń daje wyższy szacowany 1RM', () {
      final rm5 = PrDetector.epley1Rm(60, 5);
      final rm10 = PrDetector.epley1Rm(60, 10);
      expect(rm10, greaterThan(rm5));
    });
  });

  group('PrDetector.isNewRecord', () {
    test('pierwszy wpis (brak dotychczasowego rekordu) jest zawsze PR', () {
      final isPr = PrDetector.isNewRecord(
        nowyCiezar: 20,
        nowePowtorzenia: 1,
        dotychczasowyBest1Rm: null,
      );
      expect(isPr, isTrue);
    });

    test('wyższy ciężar przy tej samej liczbie powtórzeń bije rekord', () {
      final poprzedni1Rm = PrDetector.epley1Rm(15, 10);
      final isPr = PrDetector.isNewRecord(
        nowyCiezar: 17.5,
        nowePowtorzenia: 10,
        dotychczasowyBest1Rm: poprzedni1Rm,
      );
      expect(isPr, isTrue);
    });

    test(
      'identyczny wynik (ten sam ciężar i powtórzenia) NIE jest nowym PR',
      () {
        final poprzedni1Rm = PrDetector.epley1Rm(15, 10);
        final isPr = PrDetector.isNewRecord(
          nowyCiezar: 15,
          nowePowtorzenia: 10,
          dotychczasowyBest1Rm: poprzedni1Rm,
        );
        expect(isPr, isFalse);
      },
    );

    test('zerowy ciężar nigdy nie jest traktowany jako PR', () {
      final isPr = PrDetector.isNewRecord(
        nowyCiezar: 0,
        nowePowtorzenia: 10,
        dotychczasowyBest1Rm: null,
      );
      expect(isPr, isFalse);
    });

    test('zerowa liczba powtórzeń nigdy nie jest traktowana jako PR', () {
      final isPr = PrDetector.isNewRecord(
        nowyCiezar: 20,
        nowePowtorzenia: 0,
        dotychczasowyBest1Rm: null,
      );
      expect(isPr, isFalse);
    });

    test('ujemny ciężar (błąd danych) nigdy nie jest traktowany jako PR', () {
      final isPr = PrDetector.isNewRecord(
        nowyCiezar: -5,
        nowePowtorzenia: 5,
        dotychczasowyBest1Rm: 50,
      );
      expect(isPr, isFalse);
    });
  });
}
