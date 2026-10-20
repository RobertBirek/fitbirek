# Brama repeat 1.18.1+33 — diagnoza i korekta testu

**Wynik: poprawka testu zweryfikowana. Pełny Flutter: 1343 PASS / 0 FAIL /
0 skip; analyze bez uwag. Bez commit/push/deploy.**

## Zakres i klasyfikacja

Praca na `/opt/fit`, `feat/frontend-usability`, HEAD `11c4b1f` (źródło
wydania `4f763e5`), bez resetu, commit/push, wdrożenia i zmiany wersji.
Przeczytano AGENTS, working set workout-repeat/sync oraz raport zablokowanej
próby wydania. Użyto istniejącego obrazu narzędziowego
`fit-web:tooling-release-1.18.1-33-20261020T145531Z` (Flutter 3.35.4,
Dart 3.9.2); źródło montowane read-only, wykonanie w `/app` kontenera.

**Przyczyna: błędna synchronizacja testu widgetowego, nie wykazana regresja
produktu.** Test po tapnięciu confirm odczekiwał 100 ms w `tester.runAsync`,
po czym przechodził do `pumpAndSettle` w FakeAsync. Nie czekał na wynik
`confirmRepeat -> startRepeat -> resumeSession`. Wznowienie obejmuje kolejne
odczyty, transakcję, katalog i ponowną walidację przed publikacją aktywnego
stanu. Upływ 100 ms nie jest barierą zakończenia tych operacji.
Porównanie `a0ca0f8..4f763e5` nie pokazuje zmian w tym teście, dialogu,
`workout_repository.dart` ani `workout_providers.dart`.

Dowód z instrumentowanej kopii starego testu (`diagnostic-failure.log`):

```text
DIAG before settle active=false
DIAG timeout active=false progress=1
DIAG rows=2
DIAG real time resumed active=true
pumpAndSettle timed out
```

Śledzenie providera (`trace-1.log`, `trace-2.log`) zawęża to do wznowienia:
startRepeat już zatwierdzony, odczyt pendingDrafts/katalogu/serii zakończony;
po 100 ms brak jeszcze powrotu z transakcji odczytowej i publikacji stanu.
Podczas pumpAndSettle spinner pozostaje aktywny. Ponowne `runAsync` pozwala
dokończyć transakcję i opublikować aktywną sesję. Występuje także w focused
bez pełnego zestawu; nie jest to jedynie hipoteza „CI było obciążone”.
Sztuczne 10 minut pumpAndSettle nie oznacza 10 minut rzeczywistego postępu
operacji DB; zwiększenie tego timeoutu nie naprawia brakującej bariery.

Mechanizm w przypiętym Drift 2.28.2: odczyt katalogu `.watchAll().first`
w `resumeSession` tworzy krótką subskrypcję wewnątrz transakcji. Jej zamknięcie
przechodzi przez `StreamQueryStore.markAsClosed`, które używa `Timer.run`
do usunięcia cache. `transaction()` w finally oczekuje
`disposeChildStreams -> _TransactionStreamStore._dispatchAndClose ->
StreamQueryStore.close`, a ten czeka na `_pendingTimers.first.future`.
Timer utworzony w prawdziwej strefie runAsync nie jest timerem FakeAsync.
To wyjaśnia, dlaczego odczyty mogły już być zakończone, a publikacja aktywnego
stanu była nadal zablokowana. Kopia odpowiednich źródeł zależności:
`drift-transaction-stream-cleanup.txt`; nie edytowano zależności projektu.

Potwierdzenie przez instrumentację samego Drift w jednorazowym kontenerze
(`trace-drift.log`, proces testowy exit **1**, **0 PASS / 1 FAIL**):

```text
TRACE Drift schedule real cleanup timer
TRACE after catalog.first
TRACE after sets
TRACE Drift close pending=1
DIAG before settle active=false
DIAG timeout active=false progress=1
DIAG rows=2
TRACE Drift cleanup timer fired
TRACE after read transaction
TRACE publish active
DIAG real time resumed active=true
```

Timer faktycznie uruchamia się dopiero po powrocie do runAsync; nie ma tu
nieukończonego zewnętrznego native I/O ani potrzeby zmiany transakcji produktu.

## Minimalna korekta

Zmiana wyłącznie `test/features/workout/workout_repeat_persistence_test.dart`:

- rzeczywisty tap confirm pozostaje; zamiast opóźnienia 100 ms test oczekuje
  w `runAsync` na zdarzenie `activeWorkoutProvider.isActive`;
- Completer i nasłuch powstają w rzeczywistej strefie async, przed tapnięciem;
  Completer utworzony w FakeAsync sam przenosiłby oczekiwanie do złego zegara;
- wszystkie dotychczasowe asercje pozostają (oba źródła, historyczne RPE,
  brak aktywnej sesji/zapisu po preview, start dopiero po confirm, brak serii);
- drugi wariant używa istniejącego PausedRepeatRepository: jawnie zatrzymuje
  zapis szkicu w transakcji, sprawdza spinner i brak aktywnego stanu, następnie
  zwalnia zapis i czeka na rzeczywistą publikację stanu. Bez arbitralnego
  sleep i bez zależności od szybkości maszyny dla potwierdzenia.

Nie zmieniono kodu produktu, guardów, semantyki serii/RPE/NULL ani outboxa,
deklaracji Drift/Freezed/JSON, zależności lub artefaktów generowanych.
Generator nie jest wymagany. Drift 2.28.2 / sqlite3 2.9.4 pozostają zgodne
z niezmienionymi artefaktami:

```text
sqlite3.wasm: 922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117
drift_worker.dart.js: 6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610
```

## RED / GREEN i weryfikacja

Dowody: `/tmp/opencode/repeat-gate-debug/`. Pełne komendy i exit codes
końcowej weryfikacji zapisuje `verify.sh` do `*.command`, `*.exit`, `*.log`.

- RED, niezmieniony test: `flutter test --no-pub -r expanded
  test/features/workout/workout_repeat_persistence_test.dart --plain-name
  "preview has two explicit choices and confirm alone starts"`:
  exit **1**, **0 PASS / 1 FAIL**, timeout oryginalnej linii 653 (`baseline.log`).
- Diagnostyczne kopie starego testu również RED; przy dodatkowym rzeczywistym
  oczekiwaniu przechodzą, co potwierdza granicę real/FakeAsync, ale nie stanowi
  docelowej poprawki. `trace-1.log`, `trace-2.log`: każdy **0 PASS / 1 FAIL**.
- Pierwsza próba bariery z Completer utworzonym poza runAsync została przerwana
  limitem narzędzia 120 s (`green-focused.log`); nie deklarujemy jej PASS.
  Została zastąpiona prawidłową strefą tworzenia Completer.
- GREEN focused dla końcowej bariery (`green-focused-2.log`): ta sama komenda,
  **exit 0, 2 PASS / 0 FAIL / 0 skip** (zwykły i jawnie wstrzymany zapis).
- Pełny format-check lib/test/tools: **exit 1**, 10 już istniejących różnic
  formatowania poza zakresem (`format.log`). Użyto `--output=none`; tych plików
  nie zmieniono. Nie deklarujemy zielonego formatowania całego repozytorium.
- Obciążenie równoległe do weryfikacji: trzy osobne uruchomienia tej samej
  komendy focused, każde **exit 0, 2 PASS / 0 FAIL / 0 skip**
  (`stress-{1,2,3}.log`, odpowiadające `*.exit`, `stress-runner.exit=0`).
- Końcowy focused repeat/sync (`focused.log`, `focused.command`):
  **exit 0, 46 PASS / 0 FAIL / 0 skip**, 34 s:

  ```sh
  flutter test --no-pub --reporter expanded \
    test/features/workout/workout_repeat_test.dart \
    test/features/workout/workout_repeat_persistence_test.dart \
    test/core/sync_persistence_test.dart \
    test/core/sync_quality_review_test.dart \
    test/core/profile_collections_sync_test.dart \
    test/core/restore_sync_regression_test.dart
  ```

- `flutter analyze --no-pub`: **exit 0, No issues found**, 107,2 s
  (`analyze.log`, `analyze.exit`).
- `flutter test --no-pub --reporter expanded`: **exit 0, 1343 PASS /
  0 FAIL / 0 skip**, 7 min (`full.log`, `full.exit`). Pełny zestaw nie był
  filtrowany ani serializowany; nie zmieniano concurrency i timeoutów.
  Wcześniejsze 1342 przypadki + 1 dodatkowy wariant jawnie wolnego zapisu.
- `dart tools/generate_app_version.dart --check`: **exit 0** (`version.*`).
- Format-check zmienionego testu: **exit 0, 0 changed** (`format-focused.*`).
- Po doprecyzowaniu wyłącznie komentarza o timerach Drift powtórzono na
  końcowym pliku format-check (**exit 0, 0 changed**) i oba pliki repeat:
  `flutter test --no-pub -r expanded
  test/features/workout/workout_repeat_test.dart
  test/features/workout/workout_repeat_persistence_test.dart`:
  **exit 0, 27 PASS / 0 FAIL / 0 skip**, 26 s
  (`final-repeat.log`, `final-repeat.exit`, `final-format.*`).

`verification-runner.exit=0`. Przed weryfikacją potwierdzono zgodność całego
`lib/` i `test/` kopii kontenera z roboczym źródłem (puste
`source-{lib,test}-diff.log`). Podczas przebiegu pełnego zestawu jedyna późniejsza
zmiana Dart to doprecyzowanie komentarza, bez zmiany kodu wykonywalnego.
Po zakończeniu `git diff --check` bez uwag; HEAD nadal `11c4b1f`.

## Pozostałe granice

Bez nowego runtime/Docker release builda, Chromium i produkcyjnego deployu.
Te bramy pozostają zadaniem kontrolera wydania; ten raport nie zmienia
historycznego FAIL wydania na PASS. Istniejące 100 ms przy samym preview
i innych testach zapisu pozostawiono poza wąską poprawką potwierdzenia;
nie oznacza to dowodu, że wszystkie inne arbitralne oczekiwania są odporne.
Brak zmian produkcyjnych danych, API, migracji, sekretów i konfiguracji.
