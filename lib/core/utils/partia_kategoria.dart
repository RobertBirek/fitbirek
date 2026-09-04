/// Mapowanie granularnej wartości `Exercise.partiaGlowna` (~163 unikalne
/// wartości w prawdziwej bazie 316 ćwiczeń, np. 'Latissimus dorsi',
/// 'Kwadryceps, Pośladki', 'Rotatory (infraspinatus, teres minor)') do
/// prostych, stabilnych 10 kategorii UI używanych przez filtry
/// (ExercisesListPage), generator planu (PlanGenerator) i onboarding.
///
/// Dlaczego osobna funkcja mapująca, a nie zmiana pola `partiaGlowna`?
/// Zachowujemy oryginalną, bogatą wartość z bazy w polu `partiaGlowna`
/// (widoczna na ekranie szczegółów ćwiczenia jako precyzyjna informacja
/// anatomiczna), a redukcję do prostej kategorii robimy "on the fly" tam,
/// gdzie UI/algorytm potrzebuje tylko 10 szerokich grup. Dzięki temu nie
/// modyfikujemy schematu Drift/Freezed i nie tracimy informacji.
///
/// Kategorie: Klatka, Plecy, Barki, Biceps, Triceps, Nogi, Pośladki,
/// Brzuch, Cardio, Mobilność (zgodne z AppConstants.partieCiala).
///
/// Reguła dopasowania: pierwsze trafienie po kolejności priorytetów
/// (case-insensitive, substring match na polskich słowach kluczowych).
/// Kolejność została dobrana tak, by uniknąć konfliktów (np. "biodra"
/// pojawia się w kontekście Nogi/Mobilność - sprawdzane po ogólniejszych
/// kategoriach mięśniowych).
library;

String mapToKategoria(String partiaGlowna, {String wzorzecRuchu = ''}) {
  final s = partiaGlowna.toLowerCase();
  final w = wzorzecRuchu.toLowerCase();

  bool has(List<String> keys) => keys.any(s.contains);

  if (has(['klatka'])) return 'Klatka';
  if (has([
    'lat',
    'trapez',
    'romboid',
    'plecy',
    'grzbiet',
    'erector',
    'erektor',
    'łańcuch',
  ])) {
    return 'Plecy';
  }
  if (has([
    'bark',
    'akton',
    'rotator',
    'supraspinatus',
    'infraspinatus',
    'subscapularis',
  ])) {
    return 'Barki';
  }
  if (has(['biceps', 'ramienny', 'brachialis', 'przedrami'])) return 'Biceps';
  if (has(['triceps'])) return 'Triceps';
  if (has(['pośladk', 'glute', 'odwodziciel'])) return 'Pośladki';
  if (has([
    'kwadryceps',
    'dwugłow',
    'nog',
    'łydk',
    'goleń',
    'lunge',
    'squat',
    'biodr',
    'adduktor',
    'kostk',
  ])) {
    return 'Nogi';
  }
  if (has(['brzuch', 'core', 'skośne', 'proste', 'ql'])) return 'Brzuch';
  if (has(['cardio', 'hiit', 'mleczanow', 'tlenow'])) return 'Cardio';
  if (has([
    'mobilność',
    'rozciąga',
    'regeneracj',
    'th kręgosłup',
    'szyj',
    'szyja',
    'nadgarst',
    'grip',
    'koordynacj',
    'równowag',
    'flow',
    'przepona',
    'nerw błędny',
    'kręgosłup',
  ])) {
    return 'Mobilność';
  }
  if (has(['full body'])) {
    if (w.contains('cardio') || w.contains('explosive') || w.contains('hiit')) {
      return 'Cardio';
    }
    return 'Nogi';
  }
  // Przypadki resztkowe niedopasowane przez klucze anatomiczne (np. "Cała
  // tylna łańcuch" bez dokładnego dopasowania, "Zginacze bioder (iliopsoas)")
  // trafiają do Mobilność jako bezpieczny fallback (raczej rozgrzewka/
  // regeneracja/prehab niż trening siłowy głównej partii).
  return 'Mobilność';
}
