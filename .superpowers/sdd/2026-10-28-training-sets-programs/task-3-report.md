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

## Pozostały zakres Task3

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
