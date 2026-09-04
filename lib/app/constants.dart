/// Globalne stałe aplikacji FitBirek.
class AppConstants {
  static const String appName = 'FitBirek';
  static const String appVersion = '1.0.0';
  static const String author = 'Robert Birek';

  /// Lista dostępnego sprzętu do wyboru w onboardingu i ustawieniach.
  static const List<String> dostepnySprzetOpcje = [
    'Masa własna',
    'Hantle',
    'Ławeczka',
    'Drążek',
    'Gumy oporowe',
    'Bieżnia',
    'Skakanka',
  ];

  /// Predefiniowane czasy przerwy między seriami (sekundy).
  static const List<int> czasyPrzerwy = [60, 90, 120, 180];

  /// Partie ciała używane do filtrowania bazy ćwiczeń.
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

  static const List<String> typyOpcje = [
    'Siłowe',
    'Cardio',
    'Izometryczne',
    'Mobilność',
  ];
}
