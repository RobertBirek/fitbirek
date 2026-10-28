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
