import '../../../core/models/exercise.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/utils/partia_kategoria.dart';

/// Generator planu treningowego (funkcja Premium).
///
/// Algorytm: na podstawie celu, poziomu, dostępnego czasu i sprzętu
/// wybiera 4-6 zbalansowanych ćwiczeń (różne partie ciała, zgodne
/// z dostępnym sprzętem i poziomem użytkownika).
class PlanGenerator {
  /// Kolejność priorytetów partii ciała w zależności od celu treningowego.
  static const Map<CelTreningowy, List<String>> _priorytetPartii = {
    CelTreningowy.redukcja: [
      'Cardio',
      'Nogi',
      'Brzuch',
      'Klatka',
      'Plecy',
      'Pośladki',
      'Barki',
      'Biceps',
      'Triceps',
      'Mobilność',
    ],
    CelTreningowy.sila: [
      'Klatka',
      'Plecy',
      'Nogi',
      'Barki',
      'Pośladki',
      'Biceps',
      'Triceps',
      'Brzuch',
      'Cardio',
      'Mobilność',
    ],
    CelTreningowy.masa: [
      'Klatka',
      'Plecy',
      'Nogi',
      'Barki',
      'Pośladki',
      'Biceps',
      'Triceps',
      'Brzuch',
      'Mobilność',
      'Cardio',
    ],
    CelTreningowy.kondycja: [
      'Cardio',
      'Nogi',
      'Pośladki',
      'Brzuch',
      'Klatka',
      'Plecy',
      'Barki',
      'Mobilność',
      'Biceps',
      'Triceps',
    ],
    CelTreningowy.mix: [
      'Klatka',
      'Nogi',
      'Plecy',
      'Brzuch',
      'Barki',
      'Cardio',
      'Pośladki',
      'Biceps',
      'Triceps',
      'Mobilność',
    ],
  };

  static const List<String> _poziomRanking = [
    'Początkujący',
    'Średni',
    'Zaawansowany',
  ];

  /// Generuje listę ćwiczeń dla planu.
  ///
  /// [iloscCwiczen] - docelowa liczba ćwiczeń w planie (4-6, per brief).
  /// [czasMinut] - dostępny czas na trening (im mniej czasu, tym mniej ćwiczeń).
  static List<Exercise> generate({
    required List<Exercise> wszystkieCwiczenia,
    required CelTreningowy cel,
    required String poziom,
    required List<String> dostepnySprzet,
    int czasMinut = 45,
  }) {
    // Liczba ćwiczeń skalowana czasem: ~8-10 min na ćwiczenie (rozgrzewka+serie).
    var iloscCwiczen = (czasMinut / 9).round().clamp(4, 6);

    final userPoziomRank = _poziomRanking.indexOf(poziom).clamp(0, 2);

    // Krok 1: filtruj po sprzęcie (każdy wymagany element musi być dostępny)
    // i po poziomie (nie wyżej niż poziom użytkownika).
    final kandydaci = wszystkieCwiczenia.where((ex) {
      final sprzetOk = ex.sprzet.every((s) => dostepnySprzet.contains(s));
      final exPoziomRank = _poziomRanking.indexOf(ex.poziom).clamp(0, 2);
      final poziomOk = exPoziomRank <= userPoziomRank;
      return sprzetOk && poziomOk;
    }).toList();

    if (kandydaci.isEmpty) return [];

    // Krok 2: grupuj po uproszczonej kategorii partii ciała (nie po
    // surowym, granularnym `partiaGlowna` z bazy - tam jest ~163 unikalne
    // wartości, a priorytety celu operują na 10 szerokich kategoriach).
    final wgPartii = <String, List<Exercise>>{};
    for (final ex in kandydaci) {
      final kategoria = mapToKategoria(
        ex.partiaGlowna,
        wzorzecRuchu: ex.wzorzecRuchu,
      );
      wgPartii.putIfAbsent(kategoria, () => []).add(ex);
    }

    final priorytety =
        _priorytetPartii[cel] ?? _priorytetPartii[CelTreningowy.mix]!;
    final wybrane = <Exercise>[];
    final uzytePartie = <String>{};

    // Krok 3: jedno ćwiczenie z każdej priorytetowej partii, w kolejności.
    for (final partia in priorytety) {
      if (wybrane.length >= iloscCwiczen) break;
      final pulaPartii = wgPartii[partia];
      if (pulaPartii == null || pulaPartii.isEmpty) continue;
      // Preferuj ćwiczenia siłowe/typowe dla celu, ale nie wymagaj sztywno.
      pulaPartii.sort((a, b) => a.poziom.compareTo(b.poziom));
      wybrane.add(pulaPartii.first);
      uzytePartie.add(partia);
    }

    // Krok 4: jeśli brakuje ćwiczeń do docelowej liczby, dobierz z pozostałych
    // partii (drugie ćwiczenie z tej samej partii, jeśli inne niedostępne).
    if (wybrane.length < iloscCwiczen) {
      for (final partia in priorytety) {
        if (wybrane.length >= iloscCwiczen) break;
        final pulaPartii = wgPartii[partia] ?? [];
        for (final ex in pulaPartii) {
          if (wybrane.length >= iloscCwiczen) break;
          if (!wybrane.contains(ex)) wybrane.add(ex);
        }
      }
    }

    return wybrane.take(iloscCwiczen).toList();
  }
}
