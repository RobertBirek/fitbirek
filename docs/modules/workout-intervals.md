# Interwały w aktywnej sesji

## Aktualne granice indywidualnych celów (2026-10-29)

`IntervalConfig.workLimit(guidedTarget:)` jest wspólną granicą silnika, UI
i zapisu: ręczny/EXTRA/guidancev1 nadal **3600 s**, dokładny czasowy cel
guidancev2 **5400 s i dokładnie jedna runda**. Przygotowanie 0–60 s i przerwa
0–600 s bez zmian. `guidedTarget` w konfiguracji i `IntervalTimer.restore`
jest jawnym kontekstem wywołania, domyślnie false, nigdy polem checkpointu.
`singleRound` ekranu jest przekazywane wyłącznie z opaque `origin.targetId`.

Walidator szkicu wyprowadza kontekst z poprawnego guidance i zgodności
target/metryki/slotu/bindingu/strony/wariantu. Archiwum wymaga dokładnego
7-elementowego klucza oraz bieżącej lub historycznej tożsamości ćwiczenia
tego slotu; aktywny formularz nadal wymaga bieżącej. EXTRA nie dostaje
rozszerzenia po samym podsunięciu targetId. Recovery, także restart odcinka,
zachowuje zakres i kontekst. JSON checkpoint1/draft1 pozostaje bez zmian.

Timer zaczyna od rzeczywistego `target.seconds`, nie `workSeconds` estymacji.
Wynik może świadomie odbiegać od celu (np. 4100 przy celu 4000), do 5400 s.
Zakończenie odliczania nie zapisuje serii; nadal wymagane jawne potwierdzenie.
CAS, epoch/version, nonce i atomowość serii/performed/outbox pozostają.
Regresje: `test/features/workout/long_guided_timer_test.dart`; końcowy odbiór:
[raport niezawodności](../reports/2026-10-29-pwa-reliability.md).

Etap 3 zatwierdzonej roadmapy z 2026-10-16. Dotyczy wyłącznie klienta
w katalogu głównym. Nie zmienia deklaracji Drift/Freezed/JSON, wire ani backendu.

## Pliki i API

- `lib/features/workout/domain/interval_timer.dart`: czysta maszyna stanów.
  `IntervalConfig(preparation:, work:, rest:, rounds:)` odrzuca przez
  `ArgumentError` wartości poza zakresami 0–60 / 1–3600 / 0–600 sekund
  i 1–100 rund. Formularz pokazuje te same granice i błędy przy polach.
- `IntervalTimer(config, clock:)`: opcjonalny monotoniczny zegar
  `Duration Function()` (domyślnie działający `Stopwatch`). `start()` jest
  jednokrotne; `update()` przelicza upływ przez wszystkie zaległe fazy.
  `pause()`, `resume()`, `skip()`, `finish()` (wcześniejsze zakończenie do
  przeglądu), `cancel()` (odrzucenie wyników). Silnik nie tworzy timerów UI,
  nie zależy od Fluttera, nie zapisuje do bazy i nie uruchamia nowej sesji.
- Fazy: `preparation → work → rest → work … → complete`, dodatkowo terminalne
  `cancelled`. Brak przerwy po ostatniej rundzie. Zerowe przygotowanie/przerwa
  są opróżniane bez zużywania czasu; liczba przejść jest ograniczona rundami.
- `results` to niemodyfikowalna lista `IntervalRound(round, seconds, shortened)`.
  Tylko praca, bez przygotowania, przerw i pauzy. Skrócone odcinki pokazują
  faktyczny czas, obcięty do pełnych sekund; poniżej 1 s są pomijane.
- `IntervalTimerScreen(label:, clock:, isValid:)`: lokalna trasa
  `Navigator.push<List<IntervalRound>>()`. Zwraca listę wyłącznie po
  **„Zapisz wykonane rundy”**, po zakończeniu odliczania/przeglądzie wyników.
  Zakończenie faz, pauza, skip i przejście aplikacji w tło niczego nie zapisują.
  Anulowanie/back wymagają potwierdzenia i zwracają `null`.
- `ActiveWorkoutNotifier.captureInterval(exercise:, side:, rpe:)` zwraca
  nieprzenoszalny, jednokrotnego użytku `IntervalWriteOrigin?`. Capture przy
  otwarciu ekranu obejmuje notifier/generację, sessionID, exerciseID, stronę,
  RPE i pasywny `CachedAuthWriteAuthority.epoch`, bez inicjowania auth/HTTP.
  `isIntervalCurrent(origin)` sprawdza jego aktualność.
- `saveIntervalRounds(origin, results, guard:) → Future<bool>`: `true` oznacza
  zapis całej paczki, **nie** informację o PR. `false` oznacza odrzucenie
  nieaktualnego/zajętego capture, niewłaściwych wyników lub braku uprawnień.
  Pozostałe błędy zapisu są propagowane do obsługi błędu w UI. Capture jest
  rezerwowany przed pierwszym await i nie można go ponowić ani po sukcesie,
  ani po odrzuconej/nieudanej próbie.

## Atomowość i integracja

Karta ćwiczenia pokazuje nowy przycisk tylko dla metadata `tracking == 'rounds'`.
Ręczne sekundy i dotychczasowy stoper pozostają bez zmian. Powrót nie uruchamia
auto-timera przerwy. Zapis wymaga nadal zamontowanego właściciela i pierwotnej
aktywnej sesji; nie startuje sesji i nie wybiera nowszej sesji zastępczej.

Jedna zewnętrzna transakcja Drift obejmuje wszystkie `repo.logSet`, w tym
outbox. Numery serii są wyznaczane wewnątrz transakcji z istniejących wierszy.
Guard po awaitach sprawdza sesję/generację, epoch konta, mounted oraz uprawnienia
offline/binding konta. Początek `finishSession()` synchronicznie unieważnia
capture, nawet gdy zakończenie sesji czeka za transakcją zapisu rund. Zmiana
konta/wylogowanie, discard lub utrata właściciela podczas transakcji wycofują
całą paczkę, nie tylko pozostałe rundy. Powtórny tap nie tworzy drugiego zapisu.
Sekundy nie przechodzą przez detektor Epleya i nie tworzą PR.

## Tło, sygnały i ograniczenia

- UI ma najwyżej jeden ticker odświeżania co 200 ms; nie jest on źródłem czasu.
  Pauza, tło, terminalny stan i dispose usuwają ticker. Resume przelicza cały
  elapsed z zegara, zamiast dodawać liczbę callbacków. Pauza użytkownika nie
  wlicza czasu spędzonego w tle. Brak nadrabiania dawnych sygnałów na resume.
- Opcjonalny, domyślnie wyłączony przełącznik korzysta wyłącznie z Flutter
  `SystemSound`/`HapticFeedback`. Brak nowych zależności, uprawnień i usług
  audio. Przeglądarka/urządzenie mogą nie obsłużyć sygnału; faza i pozostały czas
  zawsze pozostają widoczne. Brak obietnicy budzenia/powiadomień w tle.
- Timer i niezapisane wyniki żyją tylko w pamięci. Zamknięcie procesu lub
  odświeżenie strony je traci. Upływ czasu nie potwierdza wykonania ćwiczenia;
  użytkownik przegląda wyniki przed jawnym zapisem.
- Bez zmiany schematu nie zapisujemy osobnej konfiguracji interwałów ani flagi
  `shortened` w historii; zapisane serie zawierają faktyczne sekundy pracy.
  Oznaczenie skrócenia i oryginalny numer rundy są dostępne w przeglądzie/API
  wyniku timera przed zapisem.
- Przy nieaktualnym koncie/sesji wstrzymany ekran wykrywa unieważnienie przy
  wznowieniu aplikacji lub akcji użytkownika, bez dodatkowego tickera w pauzie.
  Zapis zawsze wykonuje niezależny guard transakcyjny.

## Weryfikacja 2026-10-16

Narzędzia z `fit-web:catalog-expanded-verified`, `/opt/fit` montowane read-only,
robocza kopia w `/tmp/interval-check` w kontenerze. Bez budowania obrazu.

- `dart format --output=none --set-exit-if-changed` dla 8 zmienionych/nowych
  plików Dart: 0 zmian.
- `flutter analyze --no-pub`: brak uwag.
- 19 focused testów w `test/features/workout/interval_{timer,save,timer_screen,session}_test.dart`:
  granice konfiguracji i faz, duży skok czasu, zerowe fazy, 100 rund, pauza,
  skip/finish/cancel, brak drugiego startu, jawny save/double tap, lifecycle,
  sygnały/dispose, ręczne sekundy/stoper, brak auto-startu sesji,
  strona i faktyczne sekundy, atomowość/outbox, discard/finish podczas zapisu,
  logout podczas transakcji i powrót na to samo konto z nowszym epoch.
- Pełny `flutter test --no-pub -r expanded`: **443 testy, sukces** (424 wcześniejsze
  + 19 nowych). Testy obejmują również lokalnie gotowe PR i presety. Ponowny
  pełny przebieg zakończył się w 1:52; log:
  `/tmp/opencode/fit-interval-final.log` na hoście. Emituje ostrzeżenia Drift
  o wielokrotnym tworzeniu `AppDatabase` ze stosami testów katalogu/presetów,
  bez nieudanych testów. Nie zmieniano tych testów w etapie interwałów.
- `git diff --check`: bez błędów. `pubspec.yaml`, `pubspec.lock`,
  `web/sqlite3.wasm` i `web/drift_worker.dart.js` niezmienione; zachowana para
  artefaktów dla Drift 2.28.2 / sqlite3 2.9.4 z lockfile. Bez regeneracji modeli.
- Nie uruchamiano backendu, pipeline metadanych ani pełnego Docker verification;
  ten etap nie zmienia ich wejść. Bez zmiany wersji, commit/push ani wdrożenia.
