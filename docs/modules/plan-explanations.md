# Wyjaśnienia planera — osobny etap

## Zakres i API

`lib/features/planner/domain/plan_explanation.dart` jest czystym helperem:

```dart
PlanExplanation.forBlock(
  plan: plan, index: index, allExercises: catalog, engine: engine,
  equipment: currentEquipment, // opcjonalnie; domyślnie plan.equipment
); // niemodyfikowalna List<String>

PlanExplanation.forReplacement(
  plan: original, replacement: proposal, index: index,
  allExercises: catalog, engine: engine, equipment: currentEquipment,
); // niemodyfikowalna List<String>
```

Indeks musi wskazywać istniejący blok. `replacement` musi pochodzić z
`StructuredPlanGenerator.replace`, dla tego samego indeksu, katalogu, silnika,
sprzętu i poziomu planu. Helper opisuje propozycję, ale jej nie wybiera, nie
autoryzuje i nie modyfikuje żadnego planu. Nie jest API walidacji dowolnego
zewnętrznego planu. `forBlock` sprawdza przynależność do aktualnej puli przez
istniejące `candidates`, z zapisanymi kryteriami i poziomem oraz wskazanym sprzętem.

## Co wyjaśnienia potwierdzają

- Tylko dopasowane alternatywy OR: styl/kolekcja, mięśnie, sprzęt, typ, poziom,
  partia i pozycje. Warunki zachowują semantykę AND silnika.
- Wyszukiwanie i ulubione są wymieniane dopiero po sprawdzeniu pełnej puli.
- Role mięśni głównych i wspierających pochodzą z metadanych, nie z domysłu.
  Etykiety pochodzą z istniejącego słownika/silnika, także dla dynamicznych stylów.
  Helper nie ma listy sześciu stylów ani specjalnego przypadku `spine`.
- Wzorzec jest rzeczywistym polem tekstowym `Exercise.wzorzecRuchu`.
- Nowość wzorca (pierwszy człon, tak jak w generatorze) i dodatkowe mięśnie
  są sprawdzane względem **wcześniejszych bloków podglądu**. Nie są deklaracją
  odtworzenia rankingu generatora: kolejność rezerwacji sekcji jest inna niż
  kolejność prezentacji, a plan mógł być wcześniej zamieniany. Przy brakujących
  danych porównawczych helper pomija takie twierdzenia.
- Brak danych / niezgodność aktualnej puli daje jawny komunikat zamiast
  wymyślonego uzasadnienia. Czas pozostaje oznaczony jako ESTYMOWANY.

## UI i zamiana

Karta ma przyciski „Dlaczego to ćwiczenie?” i „Wymień ćwiczenie”. Zamiana
najpierw uruchamia dotychczasowy `replace`, a następnie pokazuje dialog
„Zamień X na Y?” z sekcją, trackingiem, estymowanym czasem oraz porównaniem
sprzętu, obu ról mięśni, pełnego wzorca i poziomu. Równe wartości są jawnie
opisane jako niezmienione. Anulowanie i zamknięcie dialogu nie zmieniają planu.

Akceptacja zmienia tylko lokalny podgląd. Zmiana konta, profilu, katalogu,
silnika lub podglądu podczas dialogu blokuje zastosowanie starej propozycji.
UI przekazuje aktualny sprzęt profilu, ten sam co do `replace`; zapisany snapshot
sprzętu w strukturze nie jest przepisywany. Zapis i start zachowują dotychczasowe
osobne potwierdzenia i walidację aktualnej puli.

## Cele z katalogu — korekta po integracji przeglądarkowej

`StructuredPlanGenerator` odczytuje teraz `seriexPowtorzenia`, zamiast zawsze
narzucać 3 × 10 / 3 × 40 s. Publiczne API i wire v1 pozostają takie same.
Prywatny, częściowy parser akceptuje wyłącznie pełny zapis:

- `serie x dawka`, z `x` lub `×`; serie i dawka to dodatnia liczba całkowita
  albo uporządkowany dodatni zakres (`-`/`–`). W obu zakresach wybiera minimum.
- Dawka powtórzeniowa: bez jednostki lub `powt`, `powt.`, `powtórzeń`, tylko
  przy metadanych `reps`. Dla `time` wymagane `s`, `sek`, `sec`, `min`
  (także skróty z kropką). Całe minuty są przeliczane na sekundy.
- Samodzielny czas, np. `1 min`, oznacza jedną serię. Samodzielna liczba
  powtórzeń bez serii nie jest parsowana.
- Opcjonalne `na stronę` wymaga `unilateral`. Metadane jednostronności zawsze
  podwajają czas pracy serii, również bez dopisku. `reps` pozostaje liczbą
  powtórzeń jednej strony. Dla reps estymacja nadal wynosi **3 s/powt.**;
  parser nigdy nie czyta cyfr z tempa ani wskazówek.

Nie ma warunku po cwID, stylu ani wyborze kolekcji: ta sama reguła obejmuje
stare i nowe wpisy oraz klony. Nie interpretuje komentarzy, alternatyw „lub”,
obciążeń, dystansu, pauz w nawiasach, złożonych dawek, ułamków ani `rounds`.
Odrzuca zera, odwrócone zakresy, niezgodność jednostek i wartości przekraczające
bezpieczną reprezentację liczb całkowitych Web (nie jest to limit medyczny).

Nieznany zapis używa dotychczasowych defaults: praca 3 serie × 10 powt. lub
40 s, sekcje pomocnicze 1 × 6 powt. lub 30 s. **Każdy wybrany blok z takim
fallbackiem ma jawne ostrzeżenie z ID, „domyślna dawka” i „ESTYMOWANY”.**
Brak metadanych tracking nadal wyklucza ćwiczenie zamiast zgadywać.

Przerwa pozostaje polityką generatora: 30 s między seriami pracy, 0 s
w sekcjach pomocniczych; przejście 15 s. Nie wydłuża się dawki do budżetu.

| Ruch | Rzeczywisty cel | Praca na serię, obie strony | Cały blok z przerwami/przejściem |
|---|---|---:|---:|
| cw364 | 1 × 3 powt. (minimum 3–5) | 9 s | 24 s |
| cw365 | 3 × 5 s | 5 s, **15 s pracy łącznie** | 90 s = 15 + 60 przerw + 15 przejścia |
| cw366 | 1 × 3 na stronę | 18 s | 33 s |
| cw367 | 1 × 3 na stronę (minimum 3–5) | 18 s | 33 s |
| cw368 | 1 × 3 na stronę | 18 s | 33 s |
| cw369 | 1 × 5 powt., rozgrzewka | 15 s | 30 s |

To zachowawcze dawki kuratora katalogu, nie osobista rehabilitacja. Estymacja
3 s/powt. nie udaje rzeczywistego czasu ruchu opisanego jako wolny/pauzowany.

`replace` przelicza dawkę zamiennika z jego danych; nadal wymaga tej samej
sekcji, trackingu **i łącznego czasu**. Dawka 1 × 3 nie przejmuje starego 3 × 10;
przy niezgodnym czasie zamiana jest odmawiana. Pozostałe bloki są zachowane.
Helper porównuje teraz także serie, powtórzenia, pracę na serię, przerwy i
przejście — równy czas całkowity nie oznacza takich samych celów. Ostrzeżenie
fallbacku wymienianego bloku zastępowane jest ostrzeżeniem nowego, jeśli potrzebne.

Bez zmian schematu `StructuredPlan`, kryteriów, parsera wire, providerów
i kontraktu startu. Zmiana generatora dotyczy wyłącznie opisanych powyżej dawek.
Bez sesji/draftów, automatycznych serii/PR, DB, sieci, AI
i rekomendacji medycznych. Nie zmieniono deklaracji Drift/Freezed/JSON, więc
regeneracja kodu nie jest wymagana.

## Weryfikacja pierwotnego etapu wyjaśnień

Docker `fit-web:workflow-verified`, Flutter 3.35.4 / Dart 3.9.2. Bieżące źródła
z `/opt/fit` montowane read-only i kopiowane do roboczego katalogu kontenera;
nie uruchamiano testów na starym kodzie z obrazu. Format wyłącznie pięciu plików
Dart tego etapu.

Focused: **19 testów**, w tym **10 nowych helpera i 3 nowe widgetowe**:

```sh
flutter test --no-pub \
  test/features/planner/plan_explanation_test.dart \
  test/features/planner/plan_explanation_widgets_test.dart \
  test/features/planner/planner_widgets_test.dart \
  test/features/planner/unavailable_plan_widget_test.dart \
  test/features/planner/planner_workflow_test.dart
flutter analyze --no-pub
```

Regresje obejmują jawne accept/cancel bez inicjalizacji repo/workflow/auth,
niezmienność źródłowego planu, zmianę katalogu podczas dialogu, dopasowane
alternatywy, alias wyszukiwania dynamicznego stylu, brak metadanych, warunki,
pozycje, wymaganie całego sprzętu, poziom, role mięśni i zweryfikowaną nowość.

`pubspec.lock` i Web SQLite niezmienione; zgodność sprawdzona dla `sqlite3`
2.9.4 i `drift` 2.28.2, SHA-256 zgodne z wartościami w `structured-planner.md`.
Bez pełnego zestawu testów, Docker build, zmiany wersji, commit/push/deploy.

### Weryfikacja korekty dawek 2026-10-17

- `flutter test --no-pub test/features/planner`: **95 passed**, w tym
  **20 nowych** w `catalog_prescription_test.dart`; stare fixtures i oczekiwania
  pozostawiono bez osłabiania. W szczególności test widgetowy zachowuje jeden
  nagłówek „Czas ESTYMOWANY”, a ostrzeżenia mają odrębne sformułowanie.
- Nowe testy: sześć rzeczywistych wpisów assets i ich wire roundtrip, gramatyka
  reps/time/min/sek/range/side, niepoprawne formaty i jednostki, brak odczytu tempa,
  klon bez specjalnego ID/stylu, odmowa przeniesienia starego 3 × 10,
  zachowanie pozostałych bloków, porównanie różnych celów o równym czasie,
  przeniesienie ostrzeżenia fallbacku i pominięcie poprawnej dawki ponad budżet.
- Aktualne **369 wpisów**: budżety 5/15/45/90 min dla całego katalogu,
  wszystkie budżety **5–90 min** dla jawnego `styles: {'spine'}`. Dotychczasowe
  regresje joga/regeneracja nadal przechodzą dla każdego budżetu 5–90 min.
- Flutter 3.35.4 / Dart 3.9.2, `fit-web:workflow-verified`, kopia bieżących
  źródeł z montowania read-only. Format tylko trzech plików Dart korekty.
- Analyze trzech plików korekty: **No issues found**. Pełny analyze wspólnego
  drzewa w tym przebiegu zgłosił jedną uwagę `curly_braces_in_flow_control_structures`
  w równolegle zmienianym `lib/features/workout/providers/workout_providers.dart:464`;
  plik poza zakresem pozostawiono bez zmian. `git diff --check`: OK.
- Bez zmiany publicznego API generatorów ani wire v1/kluczy. Brak zmian
  deklaracji generowanych modeli; generator niewymagany. Lock, wersja oraz
  oba SHA-256 Web SQLite niezmienione. Bez browser/full-suite/build/deploy.
