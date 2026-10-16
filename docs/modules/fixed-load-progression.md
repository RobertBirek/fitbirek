# Progresja stałego ciężaru — etap 6

## Zakres i API

- `lib/features/workout/domain/fixed_load_progression.dart` to czysty silnik
  `proposeFixedLoad(...)`. Wejście: dokładny exercise ID, nullable side,
  zapis zakresu, tracking, jawny bieżący ciężar i lista `ProgressionPerformance`.
  Wyjście: `FixedLoadSuggestion` z nullable `target`, niezmienionym `weightKg`,
  polskim uzasadnieniem i dwoma podsumowaniami sesji. Brak I/O, AI, sieci,
  zależności od providera, 1RM i zapisu.
- `WorkoutRepository.getProgressionHistory(exerciseId, side: ...,
  excludingSessionId: ...)` wykonuje tylko SELECT z JOIN sesji i serii.
  Wyklucza bieżący session ID, sesje bez końca oraz tombstones sesji i serii.
  NULL, both, left, right są osobnymi zakresami. Wszystkie serie pozostają
  w wyniku: dwa łatwe sety w jednej sesji nie zastępują dwóch treningów.
- `fixedLoadProgressionProvider` to `autoDispose.family` z kluczem-recordem
  obejmującym exercise ID, side, zakres, tracking, użycie ciężaru i wartość kg.
  `FixedLoadOffer.isCurrent()` jest asynchronicznym guardem odczytu/przyjęcia.
  Nie tworzy sesji, PR, planu ani operacji outbox.

## Polityka propozycji

1. Rozpoznawane są tylko jednoznaczne zapisy `3x8-12`, `3×8–12`, opcjonalnie
   z `powt.` oraz stałe `3x8`. Nie parsujemy progresji/regresji z wolnego tekstu
   jako identyfikatorów wariantów. Błędny, odwrócony lub przepełniony zakres
   oznacza brak liczbowej propozycji.
2. Po odrzuceniu niedodatnich/brakujących wyników wybierane są dwie najnowsze
   **różne zakończone sesje**, według daty końca, z ID jako tie-breakerem.
   Nie omijamy nowszej sesji o innym ciężarze lub bez RPE na rzecz starszej,
   łatwiejszej historii. Każda uwzględniona seria musi mieć RPE 1–10, wynik
   w zakresie i ten sam ciężar. Sesje z mieszanką obciążeń nie są podstawą
   propozycji — również gdy różnica pochodzi z rozgrzewki.
3. Wynik sesji to minimum powtórzeń, wysiłek to najwyższe RPE jej serii.
   Punktem wyjścia celu jest minimum **najnowszej** sesji; decyzja uwzględnia
   najwyższe RPE z obu sesji:
   - obie ≤7: +1 powtórzenie, nie powyżej maksimum;
   - 8: utrzymanie;
   - ≥9: −1, nie poniżej dolnej granicy, albo utrzymanie na tej granicy;
   - stałe powtórzenia: utrzymanie;
   - górna granica przy niskim RPE: utrzymanie ciężaru i jawna informacja,
     że ewentualny wariant z opisu wymaga osobnej decyzji.
4. Ćwiczenie z obciążeniem wymaga dodatniego, skończonego ciężaru wpisanego
   do formularza i dokładnie takiej samej wartości w historii. Nie zakładamy
   20 kg z samego sprzętu Sandbag; nigdy nie zwiększamy kg. Puste/niepoprawne
   pole i zmiana 20→15/25 kg dają brak wystarczającej historii, nie reset formy.
5. Masa własna nie dostaje fikcyjnego ciężaru ani 1RM. Akceptowana historia
   bez obciążenia (NULL/0) pozostaje bez dodatkowych kg.
6. Czas i rundy: wyłącznie informacja „utrzymaj własny cel”, bez przycisku
   liczbowej progresji. Obecne serie nie zapisują porównywalnej konfiguracji
   przerw/całego protokołu; sama długość rundy, nawet z RPE, nie wystarcza.
   Nie wdrożono automatycznego +5 s ani zmiany liczby rund.

## UI i bezpieczeństwo konta

W aktywnej sesji „Możliwy następny cel” pokazuje przyczynę, dwie daty/ID sesji,
minimalne powtórzenia, najwyższe RPE, stronę i jawny ciężar bez zmian.
Dotychczasowe „Ostatnio” pozostaje oddzielnym porównaniem ostatniej serii;
nie jest dowodem progresji i również przechodzi przez guard konta.

„Przyjmij cel” zmienia **tylko pole powtórzeń**. Istniejący inny szkic wymaga
potwierdzenia „Zastąp”; „Zachowaj” niczego nie zmienia. Po await i po dialogu
ponownie sprawdzane są konto, sesja, strona/ciężar/zakres oraz niezmieniony
szkic. Budowanie widżetu nie edytuje kontrolerów i niczego nie zapisuje.
Użytkownik może odrzucić propozycję; nie ma diagnoz, wskazówek treningu przez
ból ani domniemywania doświadczenia z innych dyscyplin.

Provider korzysta z pasywnego `CachedAuthWriteAuthority`, a nie uruchomienia
`authStateProvider`. Mały dodatek `revision: ValueNotifier<int>` w istniejącym
cache pozwala wycofać UI także przy rozpoczęciu logout/loading, zanim zakończy
się blokada SQLite. Nie inicjuje auth/HTTP ani nie zmienia semantyki epoch.
Przechwytywane są epoch/account, account/device binding z offlineAccess,
session ID/startTime i tożsamość wiersza sesji (syncId/dataStart). Wspólny
snapshot bindingu sesji zapobiega przeniesieniu formularza na inne konto
przy zmianie klucza strony/ciężaru. Zmiany trwałego bindingu są obserwowane
strumieniowo. Guard sprawdza binding przed i po odczycie sesji. Odświeżanie,
błąd, loading i utrata autoryzacji nie pokazują poprzedniego wyniku family.

## Ograniczenia i weryfikacja

- Historia jest snapshotem SELECT, nie nową encją synchronizacji. Zmiany
  historii w tle bez zmiany klucza/formularza nie stanowią ciągłego monitoringu
  obciążenia; wynik opisuje dane pobrane do propozycji, nie plan treningowy.
- Wymagany jest istniejący aktywny trening oraz trwałe, odblokowane powiązanie
  konta. Brak inicjalizacji auth sam w sobie nie uruchamia sieci; wtedy
  autorytetem odczytu jest trwały binding offline.
- Brak zmian Drift/Freezed/JSON declarations: generator nie jest potrzebny.
  Nie zmieniono schematu, zależności, wersji, wire, assetów, PR ani timerów.
- `pubspec.lock`, `web/sqlite3.wasm`, `web/drift_worker.dart.js` pozostają
  niezmienione; lock nadal wskazuje Drift 2.28.2 / sqlite3 2.9.4. Nie wykonano
  aktualizacji ani ponownego pobrania artefaktów Web SQLite z upstream.
- Testy uruchamiane w `fit-web:catalog-expanded-verified` (Flutter 3.35.4 /
  Dart 3.9.2): aktualne `/opt/fit` zamontowane readonly, skopiowane na bazę
  `/app` do `/tmp/fit-test`. Nie testowano wyłącznie starej zawartości obrazu.
- Focused pliki etapu: `fixed_load_progression_test.dart`,
  `progression_history_test.dart`, `progression_provider_test.dart`,
  `progression_widget_test.dart` w `test/features/workout/`.
  **50 nowych testów**: silnik 30, repo 1, provider 8, widgety 11.
  Obejmują m.in. dwa treningi zamiast dwóch setów, stały sandbag 20 kg,
  NULL/both/left/right, braki RPE, różne obciążenia, account switch/logout
  w trakcie odczytu, zastąpienie wiersza sesji pod tym samym ID,
  opóźnioną historię po zmianie strony/kg oraz nieaktualny dialog szkicu.
- Regresje: `flutter test test/features/workout
  test/features/progress/prs_repository_test.dart test/features/auth
  --reporter expanded`; `flutter analyze`; format dziewięciu zmienianych
  plików Dart z `--output=none --set-exit-if-changed`.
  Wynik końcowy: **126/126 testów passed**, analyze bez uwag, format 9 plików
  bez zmian. Jest to zestaw focused/regresyjny, nie pełna suita aplikacji.
- Bez pełnej suity klienta, backend/Python, pełnego Docker build, commitu,
  push, release i deploy. Końcową pełną weryfikację prowadzi główny agent.
