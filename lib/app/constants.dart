/// Globalne stałe aplikacji FitBirek.
class AppConstants {
  static const String appName = 'FitBirek';
  static const String appVersion = '1.0.0';
  static const String author = 'Robert Birek';

  /// Lista dostępnego sprzętu do wyboru w onboardingu i ustawieniach.
  ///
  /// Krzesło i Ręcznik dodane w [0.8.0] po integracji prawdziwej bazy 316
  /// ćwiczeń (m.in. seria Tai Chi na krześle / regeneracja).
  static const List<String> dostepnySprzetOpcje = [
    'Masa własna',
    'Hantle',
    'Ławeczka',
    'Drążek',
    'Gumy oporowe',
    'Bieżnia',
    'Skakanka',
    'Krzesło',
    'Ręcznik',
  ];

  /// Predefiniowane czasy przerwy między seriami (sekundy).
  static const List<int> czasyPrzerwy = [60, 90, 120, 180];

  /// Partie ciała używane do filtrowania bazy ćwiczeń.
  ///
  /// Uwaga: to uproszczona kategoryzacja UI (10 grup). Prawdziwa baza 316
  /// ćwiczeń ma ~163 granularne wartości `Exercise.partiaGlowna` (np.
  /// "Latissimus dorsi", "Kwadryceps, Pośladki") - redukcja do tych 10
  /// kategorii odbywa się przez `mapToKategoria()`
  /// (lib/core/utils/partia_kategoria.dart), nie przez zmianę samego pola.
  static const List<String> partieCiala = [
    'Klatka',
    'Plecy',
    'Barki',
    'Biceps',
    'Triceps',
    'Nogi',
    'Pośladki',
    'Brzuch',
    'Cardio',
    'Mobilność',
  ];

  static const List<String> poziomyOpcje = [
    'Początkujący',
    'Średni',
    'Zaawansowany',
  ];

  /// Typy ćwiczeń - 1:1 z wartościami kolumny `Typ` w prawdziwej bazie 316
  /// ćwiczeń (Excel BAZA_GLOWNA), rozszerzone w [0.8.0] z poprzednich 4
  /// wartości (Siłowe/Cardio/Izometryczne/Mobilność) do 10, bez utraty
  /// informacji przy imporcie.
  ///
  /// UWAGA: wartość 'Izometria' (nie 'Izometryczne'!) jest sprawdzana w
  /// active_session_page.dart (_typyIzometryczne) do przełączenia UI na
  /// stoper zamiast pól ciężar/powtórzenia.
  static const List<String> typyOpcje = [
    'Hipertrofia',
    'Siła',
    'Wytrzymałość',
    'Cardio',
    'Rozgrzewka',
    'Regeneracja',
    'Explosive',
    'Rozciąganie',
    'Izometria',
    'Mobilność',
  ];
}
