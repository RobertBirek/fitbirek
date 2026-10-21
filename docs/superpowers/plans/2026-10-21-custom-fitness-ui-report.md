# Task 3 — Flutter UI / własne testy sprawnościowe

## Zakres i decyzje

- Wyłącznie presentation, routing, lokalny font i testy UI. Bez zmian modeli,
  repozytoriów, providerów, Drift, sync, backupu lub backendu przez tego agenta.
- Postępy: Ciało / Testy / Trening. Zachowane źródła i akcje ręcznych pomiarów,
  usuwanie importów Health, kroki, PR oraz dotychczasowe trendy treningowe.
- Własne testy są osobne od 11 dawnych typów. Wykres dawnych testów używa surowego
  wyniku i dynamicznej osi (także ujemny skłon), bez zmiany zapisanej punktacji.
- Definicja korzysta z całego katalogu i istniejących wariantów. Metryka nie
  zależy od workout tracking. Kg wymagają sposobu podania; strona nieokreślona
  pozostaje odrębna od obu stron. Zmiana zasad tworzy nową rewizję przez workflow.
- Formularz wyniku: ręczna wartość, lokalna data i godzina, domyślnie teraz,
  możliwość wpisania wcześniejszej próby. Odrzucenie przyszłości i normalizacji
  nieistniejącej godziny DST. Bez stopera, autosave ani obietnic działania w tle.
- Lease pobierany raz przed udostępnieniem formularza; przekazywany bez wymiany
  do zapisu. StateError blokuje ponowny zapis i wymaga ponownego otwarcia.
  Archiwizacja ma własny lease pobrany przed dialogiem potwierdzenia.
- Historia korzysta ze snapshotów, pokazuje wykluczone wersje/rozbieżne zasady,
  a porównanie deleguje wyłącznie do `compareFitnessResults`.
- Brak ilustracji to jawny placeholder; brak zewnętrznych URL obrazów.

## Projekt wizualny

Paleta wynika z istniejącego ThemeData: grafit `#1A1D23`, powierzchnia `#23262E`,
jasny `#F4F6F8`, pomocniczy `#A7B0BE`, akcja `#FF6B35`, pozytywny `#4CAF50`.
Bez osobnego ciemnego motywu zaszytego w kartach. Inter pozostaje krojem opisów
i kontrolek; lokalny FitnessTestDisplay / Barlow Condensed SemiBold jest użyty
oszczędnie w nazwie i wyniku. Cyfry wyników są tablicowe.

Element charakterystyczny: lokalna ilustracja + **poprzednio → teraz**, surowa
jednostka, daty obu prób i warunki. Nie ma arbitralnego hero-score ani animacji.
Układ to spokojna karta protokołu i pionowy, przewijany formularz; brak ciasnych
dwukolumnowych pól na telefonie.

## Stabilne linki

- `/progress?section=body|tests|training`
- `/progress/run-test` — zachowany dawny formularz
- `/progress/run-test?exerciseId=...` — istniejące testy dla ćwiczenia + tworzenie
- `/progress/run-test?protocolId=...` — wynik konkretnej rewizji
- `/progress/tests/new?exerciseId=...`
- `/progress/tests/:protocolId`, `/edit`, `/history`

Nie wymagają `extra`. Menu wiersza i dodatkowy przycisk szczegółów ćwiczenia
otwierają wybór; nie zapisują wyniku ani treningu. Ulubione i StartWorkoutButton
pozostają na miejscu.

## Font / provenance

`assets/fonts/fitness_tests/BarlowCondensed-SemiBold.ttf`, niezmieniony plik
publicznego Google Fonts, pobrany 2026-10-21. SIL OFL 1.1 w `OFL.txt`;
źródła i SHA-256 w `PROVENANCE.md` obok. W pubspec zmieniono tylko sekcję fonts.
Nie zmieniono zależności, wersji aplikacji, lockfile ani artefaktów SQLite.

## Weryfikacja

Środowisko: kontener testowy z obrazu `fit-web:illustrations-408-verified`,
Flutter 3.35.4 / Dart 3.9.2. Bez pełnego Docker build, loginu produkcyjnego,
operacji HTTP aplikacji, commitu, pushu lub deployu.

- Test-first wykresu: najpierw 2 oczekiwane porażki (50 zamiast surowych
  150/210 oraz -12/-4), następnie 2/2 zielone po zmianie osi.
- Testy własnych kart/stanów formularzy/routingu: uruchomienie 21 zielonych,
  1 test DST pominięty przy UTC. Odrębne uruchomienie z `TZ=Europe/Warsaw`:
  test nieistniejącej godziny DST zielony, bez pominięcia.
- Numeryczne formularze i profile: wcześniejsze uruchomienie 35 zielonych,
  1 porażka testowego scrollUntilVisible (wielokrotny Scrollable); poprawiona
  selekcja scrolla, a ponowne uruchomienie testu formularza zielone.
- Karty 320/430/960 px w obu jasnościach motywu przy tekście 200%; kreator 320 px przy tekście 200%.
  To testy widgetowe braku wyjątków/overflow, nie przegląd rzeczywistego obrazu.
- Końcowy zestaw UI: **70 zielonych, 1 pominięty DST przy UTC**:
  `fitness_protocol_widgets_test.dart`, `custom_fitness_ui_test.dart`,
  `fitness_routes_test.dart`, `fitness_entry_links_test.dart`,
  `numeric_forms_test.dart`, `profile_usability_test.dart`,
  `health_progress_test.dart`, `manual_measurement_widget_test.dart`,
  `chart_time_axis_test.dart`. Obejmuje też custom reps, datę z 2020 r., ten sam
  lease przy zapisie, blokadę zapisu, archiwizację z potwierdzeniem i brak
  workouts/sets/PR przy wejściu z ćwiczenia.
- Po rozszerzeniu testu routingu: **9/9 zielonych**, w tym wszystkie trzy
  sekcje query, nowe/edycja/historia, oba parametry run-test i rzeczywisty Back.
- Końcowy zestaw accessibility + asset/catalog regressions: **79/79 zielonych**:
  `training_accessibility_test.dart`, `exercise_illustrations_test.dart`,
  `catalog_asset_integration_test.dart`, `structured_plan_test.dart`,
  `catalog_prescription_test.dart`. Testy accessibility zaktualizowano do
  surowych osi/jednostek i historii bez nieuzasadnionego score.
- Analiza 15 wskazanych pozycji zakresu UI: **No issues found**.
- Globalne `flutter analyze --no-pub` w ostatnim snapshotcie: 5 infos, wyłącznie
  `curly_braces_in_flow_control_structures` poza zakresem UI:
  `sync_dao.dart:78`, `user_collections_repository.dart:80`,
  `tests_repository.dart:427,450,470`. Nie poprawiano cudzej warstwy danych.

### Pełny suite — rzeczywisty wynik, nie deklaracja zielonego builda

Uruchomiono `flutter test --no-pub --reporter expanded`: **1354 zielone,
1 pominięty, 25 porażek**, 7:33. Pełny log:
`/tmp/opencode/custom-fitness-20261021/ui-full-tests-initial.log`.
Był to snapshot w trakcie równoległego wdrażania danych. W pierwszym kontenerze
omyłkowo pozostały też assets z obrazu 408; końcowy kontener ma pełne aktualne
assets 412. Nie zmieniano źródłowych assets, aby „naprawić” testy.

19 porażek zweryfikowano następnie jako usunięte:

- 4 z `exercise_illustrations_test.dart` (registry/file set/manifest/decode),
  3 z `catalog_asset_integration_test.dart` (412/EZ/easy bike), po 1 z
  `structured_plan_test.dart` i `catalog_prescription_test.dart`: ponowne
  uruchomienie z właściwymi assets zielone.
- `health_progress_test.dart` / chart merges sources oraz
  `manual_measurement_widget_test.dart` / real route edits manual row:
  selektor pionowego scrolla po dodaniu TabBarView; ponownie zielone.
- 8 z `training_accessibility_test.dart`: axis contrast, paginacja,
  partial page/reset i chronological/keyboard w obu motywach; oczekiwały
  dawnej osi 25 i tekstu score. Zmienione na faktyczne raw jednostki, zielone.

Pozostałe 6 zaobserwowanych porażek przekazano do integracji danych; ten agent
ich nie modyfikował ani nie deklaruje ich naprawienia:

1. `workout_side_test.dart` / v7 migration leaves legacy side null and attempted
   payload unchanged: oczekiwany schema13, rzeczywisty14.
2. `pr_side_roundtrip_test.dart` / v8 -> v9 preserves legacy PR and immutable
   attempted outbox on reopen: oczekiwany schema13, rzeczywisty14.
3. `activity_cloud_test.dart` / two real DB sync CAS preserves attempted bytes,
   tombstones and external history through reopen: oczekiwany backup2, rzeczywisty3.
4. Ładowanie `custom_fitness_data_test.dart`: brak widocznego rozszerzenia
   `NativeDatabase.interceptWith` w snapshotcie testu.
5. Ładowanie `custom_fitness_providers_test.dart`: ten sam błąd importowanego testu.
6. `database_bootstrap_test.dart` / RPC12 instructs full exit including this tab:
   oczekuje dosłownie „Schemat bazy: 12; wymagany: 13.” po przejściu na14.

Pełnej, zielonej weryfikacji wspólnego repozytorium musi dokonać sesja nadrzędna
po zakończeniu równoległych zmian. Końcowy kontener testowy:
`fit-custom-ui-final-20261021` (bez portów/serwera); zawiera snapshot końcowych
testów UI i pełne assets. Nie wykonano pełnego Docker build.

Nie wykonano screenshotów, testów przeglądarkowych ani pełnego e2e. Nie
deklaruję wizualnego odbioru na urządzeniu, testu VoiceOver ani produkcyjnej
autoryzacji. Dane testów są w pamięci SQLite lub override providerów.

## Poprawki po recenzji UI (2026-10-21)

Przeczytano całe `/tmp/opencode/custom-fitness-20261021/ui-review.md` i
zweryfikowano trzy P2 na bieżącym kodzie. Wszystkie były zasadne. Powyższe
wcześniejsze wyniki pozostają zapisem historycznych uruchomień, nie aktualnego
stanu integracji danych (sesja nadrzędna zgłosiła później zakończenie core).

### 1. Historyczny i bieżący wariant o tym samym ID

- RED: 4 uruchomione regresje pokazywały `Szybko` lub `Wolno` zamiast jawnie
  wybranego `Wolno (zapisany snapshot)`.
- Wybór UI ma teraz stabilną tożsamość całej mapy snapshotu: rekurencyjnie
  sortowane klucze obiektów JSON, zachowana kolejność list i wszystkie wartości.
  Klucze pozycji rozróżniają `saved:` i `current:`, nie samo ID. Nie zmieniają
  identyfikatorów wariantów ani protokołów na wire.
- Stary snapshot nie jest zastępowany aktualnymi danymi providera. Jest opisany
  jako zapisany snapshot; wariant bieżący jest osobną, jawną opcją. Wybrane
  parametry wariantu (m.in. tempo) są pokazane pod polem.
- GREEN: wszystkie 4 regresje zapisują i odczytują rzeczywiste rewizje w SQLite
  in-memory przez istniejący workflow/repozytorium. Testowane: zmieniona nazwa
  lub ta sama nazwa, zmienione tempo, zachowanie historycznych zasad albo jawny
  wybór bieżących. Poprzednia rewizja pozostaje niezmieniona i aktywna.
- Jeden pośredni harness testowy zatrzymywał się na `watchProtocols().first`
  wewnątrz fake-clock testera; odczyt asercji zastąpiono bezpośrednim odczytem
  faktycznie zapisanego profilu SQLite. Nie zmieniono produkcyjnych odczytów.

### 2. Metryka i jednostka przed pierwszą próbą

- RED: 12 regresji nie znajdowało etykiet metryki/jednostki.
- Karta zawsze pokazuje `Powtórzenia · powt.`, `Czas · s` lub `Dystans · m`,
  niezależnie od historii. Szczegóły korzystają z tej samej karty, więc kierunek
  poprawy ma widoczny kontekst tego, co jest mierzone.
- GREEN: 12/12 — wszystkie trzy metryki, karta i szczegóły, pusta oraz
  niedostępna historia. Nie zmieniono kanonicznych jednostek i domeny.

### 3. Czytelna oś surowych, ułamkowych wyników legacy

- RED: plank/metry miały 6 napisów `12`, skłon 6 napisów `-12`; oś powtórzeń
  przy 999999999–1000000000 miała odstęp około 0.325 powtórzenia.
- Krok osi to teraz czytelne 1/2/5 × potęga 10; dla powtórzeń minimum 1.
  Granice są dopasowane do kroku. `NumberFormat` PL dobiera liczbę miejsc
  dziesiętnych do kroku i usuwa zbędne zera; brak zmiany wyników, punktacji,
  jednostek i definicji dawnych testów.
- Wyłączono dopisywanie etykiet ekstremów obok niemal identycznego regularnego
  ticka (osobny duplikat wykryty testem ujemnego zakresu w fl_chart). Szerokość
  osi wynika z pomiaru etykiet i bieżącego skalowania tekstu, nie stałych 36 px.
- GREEN: 4 regresje odrębnych ticków: sekundy 12.1/12.3, cm -12.3/-12.1,
  metry 12.1/12.3, duże całkowite powtórzenia. Dodatkowo 3 testy dużych liczb
  na 320/430/960 px przy tekście 200%, bez wyjątków/overflow.

### Weryfikacja po poprawkach

- `fitness_ui_review_test.dart` + `fitness_raw_axis_test.dart`: **23/23 zielone**.
- Łączny zestaw wcześniejszego zakresu UI, routingu, pomiarów/Health,
  chart_time_axis, training_accessibility oraz obu nowych regresji:
  **122 zielone, 1 pominięty test DST przy UTC, 0 porażek**, 50 sekund. Log:
  `/tmp/opencode/custom-fitness-20261021/ui-review-focused.log`.
- Powtórzony test DST z `TZ=Europe/Warsaw`: **1/1 zielony**, bez pominięcia.
- Analiza wszystkich 5 plików Dart zmienionych w tej rundzie recenzji:
  **No issues found**. Pierwsze uruchomienie zgłosiło 3 infos nawiasów klamrowych
  w nowym teście osi; poprawione, analiza uruchomiona ponownie.
- Zestaw 122 obejmuje:
  `fitness_protocol_widgets_test.dart`, `custom_fitness_ui_test.dart`,
  `fitness_routes_test.dart`, `fitness_entry_links_test.dart`,
  `numeric_forms_test.dart`, `profile_usability_test.dart`,
  `health_progress_test.dart`, `manual_measurement_widget_test.dart`,
  `chart_time_axis_test.dart`, `training_accessibility_test.dart`,
  `fitness_ui_review_test.dart`, `fitness_raw_axis_test.dart`.
  Polecenie: `flutter test --no-pub <powyższe ścieżki testów> --reporter expanded`.
- Nie zmieniono `pubspec.yaml` (wersja 1.21.0+37, font i asset OFL pozostają
  własnością sesji nadrzędnej), zależności, domeny, danych, wygenerowanych plików
  ani backendu. Użyto istniejącego kontenera przypiętego Fluttera wyłącznie do
  testów/analizy. Bez Docker build/runtime build, Git, produkcji i delegacji.
- Nadal brak screenshotów, urządzeniowego odbioru wizualnego i pełnego e2e.

## Poprawka po nadrzędnym odczycie rzeczywistych screenshotów

Parent E2E wykrył hardcoded results:null w karcie formularza: wyświetlało
Historia niedostępna mimo dostępnych danych. Karta ma teraz osobną subskrypcję
tylko do odczytu customFitnessResultsProvider i rozróżnia loading, błąd,
rzeczywisty pusty wynik oraz prawdziwe wcześniejsze próby. Aktualizacja karty
nie odtwarza formularza, nie resetuje szkicu/daty i nie pobiera nowego lease.

Dodano6 regresji run_test_history_test.dart; końcowy scoped run
ui-result-history-final-focused.log:128 PASS,1 wcześniejszy DST skip w UTC.
Analiza zmienionych plików bez problemów. Bez zmian wersji, domeny i danych.
Build oraz przeglądarkowy re-smoke nowego kandydata pozostają zadaniem parent;
wcześniejszych dowodów E2E nie traktować jako automatycznego PASS nowego obrazu.
