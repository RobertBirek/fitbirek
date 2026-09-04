import '../models/fitness_test.dart';

/// Kalkulator punktacji (score 0-100) dla testów sprawnościowych.
/// Progi ustalone dla mężczyzny 40-50 lat, poziom średnio-zaawansowany
/// (kontekst użytkownika: 47 lat, karate 1 DAN, trening domowy).
class TestScoreCalculator {
  /// Zwraca score 0-100 na podstawie typu testu i wyniku.
  static int calculateScore(TypTestu typ, double wynik) {
    switch (typ) {
      case TypTestu.maxPompki:
        return _scoreFromRange(wynik, low: 10, high: 50);
      case TypTestu.pullUp:
        return _scoreFromRange(wynik, low: 1, high: 15);
      case TypTestu.chinUp:
        return _scoreFromRange(wynik, low: 1, high: 18);
      case TypTestu.plank:
        return _scoreFromRange(wynik, low: 30, high: 240); // sekundy
      case TypTestu.wallSit:
        return _scoreFromRange(wynik, low: 30, high: 180);
      case TypTestu.deadHang:
        return _scoreFromRange(wynik, low: 15, high: 120);
      case TypTestu.przysiady60s:
        return _scoreFromRange(wynik, low: 15, high: 50);
      case TypTestu.skakanka:
        return _scoreFromRange(wynik, low: 30, high: 300);
      case TypTestu.cooper12min:
        return _scoreFromRange(wynik, low: 1600, high: 3000); // metry
      case TypTestu.sklon:
        // Dodatnie cm = poniżej stóp (lepiej), ujemne = nie dosięga.
        return _scoreFromRange(wynik, low: -20, high: 20);
      case TypTestu.glebokiPrzysiad:
        return _scoreFromRange(wynik, low: 0, high: 10);
    }
  }

  /// Liniowe skalowanie wyniku do zakresu 0-100 na podstawie progów low/high.
  static int _scoreFromRange(double value, {required double low, required double high}) {
    if (high == low) return 0;
    final ratio = (value - low) / (high - low);
    final clamped = ratio.clamp(0.0, 1.0);
    return (clamped * 100).round();
  }
}
