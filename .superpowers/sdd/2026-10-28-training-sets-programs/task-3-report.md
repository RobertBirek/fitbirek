# Task3 — implementacja w toku

Baseline: `81e9f4e` (Task2 odebrany). Wyłącznie klient główny, bez zmian
toolchainu/zależności/wersji/katalogu/deployu. Nie jest to raport DONE.

## Checkpoint 1 — role i PR

- Provider `logSet(setRole: 'working')` wybiera jawny roboczy default nowych
  zapisów. Powtórzenie wykonania bierze dokładną nullable rolę źródła (NULL nie
  staje się working). `ActiveSetEntry.setRole` i origin interwałów zachowują rolę.
- Warmup nie przechodzi przez detektor PR. Baseline łączy niezmienny historyczny
  PR z `getAllSetsForExercise(effectiveWorkingOnly: true)`, przed insertem kandydata.
- RED `/tmp/opencode/task3/role-red.log`: 1PASS/3FAIL (brak working, utrata warmup,
  PR mimo lepszego working w historii). Pierwsza próba miała literówkę enum testu,
  poprawioną przed właściwym RED.
- GREEN `/tmp/opencode/task3/role-green.log`: 39PASS, nowe role + istniejące
  session_tracking + workout_repeat_persistence.
- Polecenie: `docker exec fit-catalog-program-tests bash -lc 'cp -a /workspace/.
  /app/ && cd /app && flutter test --no-pub -r expanded <focused files>'`.
  Kontener: Flutter3.35.4/Dart3.9.2, host RO `/workspace`, robocze `/app`.

## Pozostały zakres po checkpoincie 1 (historycznie)

Edytor per-set, pełny start/metadata guard, provider guidance v2, target identity
formularzy/checkpointów/origin, atomowe recovery skip/log, rzeczywisty fresh
provider immediate action, UI roli/targetów, przygotowanie bez spłaszczenia,
summary/history, izolacja timerów i multi-round EXTRA, regresje focused/analyze.
Task4 (program repository/UI) pozostaje poza tym zakresem.

## Checkpoint 2 — target identity i UI wykonania

- `ActiveWorkoutState.currentTarget/currentTargetConsumed`,
  `selectGuidedTarget(String)`, `logSet(guidanceTargetId:)` (opcjonalny expected
  target starych widoków). V2 bierze rzeczywistą rolę z celu. Odstępstwa pomiarów
  pozostają pomiarami użytkownika, strona jest dokładna.
- `checkpointKey(..., targetId:)` dopisuje siódmy element wyłącznie v2. Klucze
  legacy i EXTRA bez zmian. V2 `fields.targetId`, `guidedTargets` oraz
  `guidedSelections[[slot,exercise,target]]` zachowują osobne formularze. Origin
  i timerBinding mają targetId. `transitionGuidance(targetId:)` daje atomowy skip
  i recovery; jawny log v2 rebazuje durable podpis w tej samej transakcji przez
  istniejące consume/CAS, nie dopiero późniejszy flush.
- RED target: 4FAIL, `/tmp/opencode/task3/target-red.log`; GREEN i regresje:
  24PASS (6 target + guided_resume/draft_consumption/training_continuity),
  `/tmp/opencode/task3/target-regressions.log`.
- UI aktywny pokazuje pełne osobne cele, role, wybór celu i status; summary
  pokazuje również skippedTarget i nieważny link po usunięciu rzeczywistej serii.
  Nowy manual/EXTRA ma wybór roli. Powtórzenie pokazuje dokładną nullable rolę.
- Widget RED: oba widoki rzucały StateError scalar adaptera. GREEN: 2PASS,
  `/tmp/opencode/task3/widgets-green.log`. Podczas tworzenia fixture naprawiono
  locale, lazy-list scroll i fakeAsync/realAsync drain (dwie pierwsze próby
  zawisły na oczekiwaniu fakeAsync queue wewnątrz runAsync, zostały zakończone).
- Pełny focused workout na tym checkpoincie: **360PASS/8FAIL**. Nowy wybór roli
  zwiększył karty, odsłaniając założenia starych testów o tap bez przewijania:
  guided_widgets, guided_side_checkpoint_review, trzy draft_form_transition,
  guided_extras_review, active_replacement_widgets(weight). Ósmy:
  session_summary_states(many sets text200), dodana długa etykieta legacyNULL.
  Etykietę NULL usunięto (nie nadajemy historycznej roli); retest jeszcze przed nami.
  Log `/tmp/opencode/task3/workout-checkpoint2.log`. Nie deklaruję zielonej suite.
- Analyze checkpoint: 4 style infos i additive override jednego testu.
  Poprawione w źródłach, wymagają ponowienia. Brak deklaracji generatorów.

## Checkpoint 3 — edytor, przygotowanie i guardy

- Nowy per-set edytor: stable UUID celu, role/strony/reps/time/kg/przerwy i praca
  estymowana, add/delete/reorder. Nowe ręczne szablony są v2; legacy edytuje się
  nadal jako v1 do jawnej konwersji wszystkich bloków reps/time. Rounds odmawia.
- `validatePerSetCatalog` + planner save/start: bieżące ID/metryka/strony;
  start sprawdza również uporządkowaną selekcję. Headless path nie tworzy
  długowiecznego DB-streamu w transakcji planera. Legacy start bez zmiany.
- Przygotowanie v2 pokazuje wszystkie cele, bez historical scalar prefill,
  history suggestions i zamienników. Domenowy `setTarget` i `startPrepared`
  odmawiają nadpisania per-set wspólną dawką. Sandbag sprawdza każdą masę celu.
- Timer v2 ma konfigurację jednej rundy i własne sekundy celu; multiround
  checkpoint jest odrzucany, EXTRA pozostaje wielorundowe. Wybór celu ma osobny,
  ograniczony przycisk zamiast ogromnego ListTile, więc działa przy320px/200%
  i otwartej klawiaturze. Edytor/preparation mają testy320px/200%, edytor także
  z klawiaturą180px; aktywny z160px. Pozostaje istniejący motyw/komponenty.
- Poprawki wykryte przez nowe RED:
  - editor3FAIL (`editor-red.log`) → save/cancel/stale/reorder/role/side green;
    dołożono czas i mobile200% (łącznie4testy edytora).
  - start4FAIL (`start-red.log`), ordered selection1FAIL
    (`start-selection-red.log`) →5PASS walidacji bez session/outbox.
  - prep2FAIL (`preparation-red.log`) →2PASS domena+realny modal/start.
  - checkpoint multiround1FAIL (`checkpoint-rounds-red.log`) → odmowa bez zmiany.
  - foreign target1FAIL (`foreign-target-red.log`): consume starego A kasował
    timer nowego B. Repo v2 porównuje bieżący dokładny klucz przed consume;
    transakcja wycofuje set/link/outbox, zachowując obcy szkic.
  - variant1FAIL (`variant-red.log`): capture przed checkpointem mógł pożyczyć
    inną tożsamość. V2 capture/log sprawdzają wybrany wariant.
  - foreign performed1FAIL (`foreign-origin-red.log`): otwarty origin pozostawał
    ważny po wykonaniu celu w innym widoku. Consumed target unieważnia origin;
    własny commit odracza observer do atomowego merge.
  - original-repeat2FAIL (`repeat-original-red.log`): źródłowy v2 repeat tworzył
    pusty draft i nie dało się go wznowić. V2 dostaje dokładny pierwszy target
    w początkowym draft, a confirm ponawia metadata guard przed insertem.
    `repeat-green-analyze.log`:36PASS (12target +24repeat regression).
- Legacy klucz UI przywrócony bez pustego suffixu. Dotychczasowe testy widgetów
  czekają na koniec przewinięcia i przewijają do faktycznego pola/EXTRA, zamiast
  tapować poza ekranem po dodaniu wyboru roli. Nie usunięto ich asercji danych.

### Szeroki focused i istniejący problem baseline

`/tmp/opencode/task3/focused-final.log`:
`flutter test --no-pub -r expanded test/features/planner test/features/workout
test/features/progress test/core/*sync*_test.dart` → **901PASS/1FAIL/1SKIP**.
Wszystkie workout/planner i nowe testy przeszły. Jedyny FAIL:
`test/features/progress/custom_fitness_data_test.dart:330`, test
`account-bound repository backup3 keeps protocol UUID and embedded snapshot;
unknown marker fails atomically`: oczekuje backup3, Task2 eksportuje backup4.

Zweryfikowano niezależnie dokładny BASE81e9f4e przez `git archive` do prywatnej
kopii kontenera `/tmp/task3-baseline` (ten sam SDK/cache, bez zmian hosta):
`flutter test --no-pub -r expanded test/features/progress/custom_fitness_data_test.dart`
→**9PASS/ten sam1FAIL**; `/tmp/opencode/task3/baseline-custom-fitness.log`.
Nie edytowano odebranego backupu ani tego niezwiązanego testu. Wymaga decyzji
integratora Task5, nie jest regresją Task3. SKIP to istniejący guard timezone
w `fitness_protocol_widgets_test.dart:297` (Europe/DST kontra kontener UTC).

Końcowy filtered focused (bez tego potwierdzonego błędu baseline), analiza,
version/diff/format check będą dopisane po ostatnim przebiegu. Pełna suita
klienta i realny PWA/runtime nadal Task5; niezależny review sesji nadrzędnej
przed Task4. Backend/backup/programrepo/UI Task4 poza zmianami.
