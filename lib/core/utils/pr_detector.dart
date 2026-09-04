/// Logika wykrywania rekordów osobistych (PR) podczas sesji treningowej.
class PrDetector {
  /// Szacowany 1RM wg formuły Epley: ciezar * (1 + powtorzenia/30).
  static double epley1Rm(double ciezarKg, int powtorzenia) {
    return ciezarKg * (1 + powtorzenia / 30);
  }

  /// Zwraca true, jeśli nowa seria (ciężar x powtórzenia) bije dotychczasowy
  /// najlepszy szacowany 1RM. Używane do auto-wykrywania PR po każdej serii.
  static bool isNewRecord({
    required double nowyCiezar,
    required int nowePowtorzenia,
    required double? dotychczasowyBest1Rm,
  }) {
    if (nowyCiezar <= 0 || nowePowtorzenia <= 0) return false;
    if (dotychczasowyBest1Rm == null) return true;
    final nowy1Rm = epley1Rm(nowyCiezar, nowePowtorzenia);
    return nowy1Rm > dotychczasowyBest1Rm;
  }
}
