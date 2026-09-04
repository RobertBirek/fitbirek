import '../models/user_profile.dart';

/// Wynik kalkulacji kalorii i makroskładników.
class KalorieResult {
  const KalorieResult({
    required this.bmr,
    required this.tdee,
    required this.celKalorii,
    required this.bialkoG,
    required this.tluszczG,
    required this.weglowodanyG,
  });

  final double bmr;
  final double tdee;
  final double celKalorii;
  final double bialkoG;
  final double tluszczG;
  final double weglowodanyG;
}

/// Kalkulator BMR (Mifflin-St Jeor) i TDEE z celami makro.
/// Zakładamy mężczyznę (aplikacja projektowana dla jednego użytkownika - Roberta).
class BmrCalculator {
  /// BMR wg formuły Mifflin-St Jeor dla mężczyzn:
  /// BMR = 10 * waga(kg) + 6.25 * wzrost(cm) - 5 * wiek + 5
  static double calculateBmr({
    required double wagaKg,
    required double wzrostCm,
    required int wiek,
  }) {
    return 10 * wagaKg + 6.25 * wzrostCm - 5 * wiek + 5;
  }

  /// TDEE = BMR * współczynnik aktywności.
  /// Przyjmujemy "umiarkowanie aktywny" (trening 3-5x/tydz) jako domyślny współczynnik 1.55,
  /// z korektą dla treningu karate + siłowego w domu.
  static double calculateTdee(double bmr, {double activityFactor = 1.55}) {
    return bmr * activityFactor;
  }

  /// Wylicza pełny wynik kalorii/makro na podstawie profilu użytkownika i celu.
  static KalorieResult calculateFull(UserProfile profile) {
    final bmr = calculateBmr(
      wagaKg: profile.wagaKg,
      wzrostCm: profile.wzrostCm,
      wiek: profile.wiek,
    );
    final tdee = calculateTdee(bmr);

    // Deficyt/nadwyżka kaloryczna w zależności od celu.
    double celKalorii;
    switch (profile.cel) {
      case CelTreningowy.redukcja:
        celKalorii = tdee - 500; // deficyt ~0.5kg/tydzień
        break;
      case CelTreningowy.masa:
        celKalorii = tdee + 300; // umiarkowana nadwyżka
        break;
      case CelTreningowy.sila:
      case CelTreningowy.kondycja:
      case CelTreningowy.mix:
        celKalorii = tdee;
        break;
    }

    // Makro: białko 2g/kg masy ciała, tłuszcz 25% kalorii, reszta węglowodany.
    final bialkoG = profile.wagaKg * 2.0;
    final tluszczG = (celKalorii * 0.25) / 9;
    final kalorieBialkoTluszcz = bialkoG * 4 + tluszczG * 9;
    final weglowodanyG = (celKalorii - kalorieBialkoTluszcz) / 4;

    return KalorieResult(
      bmr: bmr,
      tdee: tdee,
      celKalorii: celKalorii,
      bialkoG: bialkoG,
      tluszczG: tluszczG,
      weglowodanyG: weglowodanyG < 0 ? 0 : weglowodanyG,
    );
  }
}
