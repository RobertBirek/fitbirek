# Task3 — DONE_WITH_CONCERNS

Baseline: `81e9f4e` (Task2 odebrany). Wyłącznie klient główny, bez zmian
toolchainu/zależności/wersji/katalogu/deployu. Implementacja zakresu Task3
zakończona; zastrzeżenie dotyczy odtworzonego błędu testu BASE i odrębnego odbioru
integracyjnego/runtime w Task5. Nie oznacza odbioru niezależnego review.

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

Pełna suita klienta i realny PWA/runtime nadal Task5; niezależny review sesji
nadrzędnej przed Task4. Backend/backup/programrepo/UI Task4 poza zmianami.

## Końcowa samokontrola i weryfikacja

Dwie dodatkowe regresje z kontroli kolejności zdarzeń, bez pomocy subagentów:

1. `/tmp/opencode/task3/deferred-observer-red.log`:1FAIL, wykonanie ręczne A →
   timer B mogło odtworzyć odroczony stary wiersz A. Test steruje wyłącznie
   czasem obserwacji prawdziwego wiersza SQLite; serie/linki/draft są zapisywane
   normalnym repo. Po ręcznym commit/rollback jego odroczony performed-row jest
   wycofywany, nie zostaje do następnego consume. GREEN:
   `deferred-observer-green.log`:23PASS z dotychczasowymi CAS/inflight regresjami.
2. `/tmp/opencode/task3/observed-replacement-red.log`:1FAIL, obserwowana zgodna
   zamiana v2 czyściła pola bez ponownego wskazania targetId. Zmiana tożsamości
   bloku teraz inicjalizuje dokładny cel nowego formularza, zachowując namespace
   EXTRA/nieaktywnych formularzy. Test świeżego providera po flush od razu
   pomija właściwy cel bez pomocniczej edycji. GREEN w końcowym zestawie.

Łącznie **35 nowych testów** Task3; obejmują realną bazę, świeże providery,
natychmiastowe log/skip/consume po resume, doubletap/stary widok, target/side/
variant/EXTRA, role/PR, edytor reps/time/cancel/stale/stableID, przygotowanie i
widżety320px/200% z klawiaturą. Istniejące asercje danych legacy pozostają.

Końcowa komenda na bieżących źródłach (Flutter3.35.4/Dart3.9.2):

```sh
docker exec fit-catalog-program-tests bash -lc '
  cd /app
  progress=$(find test/features/progress -name "*_test.dart" \
    ! -name "custom_fitness_data_test.dart" | sort)
  flutter test --no-pub -r expanded test/features/planner \
    test/features/workout $progress test/core/*sync*_test.dart
  flutter analyze --no-pub
  dart tools/generate_app_version.dart --check
'
```

W wykonanym przebiegu polecenia były połączone `&&`, więc błąd zatrzymałby
następny krok. Log `/tmp/opencode/task3/focused-green-final2.log`:
**896PASS/0FAIL/1SKIP**, analyze **No issues found**, versioncheck PASS.
Poprzedni filtered przebieg przed dwiema ostatnimi regresjami:894PASS/1SKIP
(`focused-green-final.log`). Wykluczenie dotyczy wyłącznie całego potwierdzonego
na BASE pliku backup3→4 (9 poprawnych testów i1 wadliwa asercja); wynik szerokiego
przebiegu z nim pozostaje jawnie RED powyżej — nie deklarujemy pełnego green.

`git diff --check` PASS. Format ograniczony do własnych zmienionych Dart.
Nie zmieniano deklaracji Drift/Freezed/json_serializable, więc generator nie
był potrzebny; artefakty wygenerowane Task2 pozostają niezmienione.
`pubspec.yaml`/lock i para WebSQLite niezmienione względem BASE, wersje nadal
Drift2.28.2/sqlite3 2.9.4. SHA256:
- sqlite3.wasm: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- drift_worker.dart.js: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

API i working set: `docs/modules/training-sets-programs-ui.md`.
Checkpointy: `56f0fa4` role/PR, `338b511` target identity/recovery/UI,
`2ee0112` edytor/preparation/metadata/timer. Ostatni commit dopina dwie regresje
obserwatora i ten raport. Bez push/merge/deploy/backend/backup/version bump.

### Do Task4 / integratora

- Task4 implementuje repo/UI programów A/B na odebranym kontrakcie danych;
  ten etap nie dodał alternatywnego programu/serializera ani automatycznego
  zaliczania terminów. Używa istniejącego `PlannerWorkflow.startSaved/startPrepared`.
- Przed wejściem Task4 wymagany review sesji nadrzędnej. Nie uruchamiano własnych
  reviewerów/subagentów zgodnie z poleceniem.
- Task5: decyzja o aktualizacji starego testu backup3 do4, pełna suita klienta,
  backend i rzeczywisty compiled PWA/mobile acceptance. Task3 nie daje gwarancji
  flush przy zabiciu procesu, budzenia w tle ani synchronizacji lokalnych szkiców.
- Przygotowanie v2 celowo nie oferuje zamian ani wspólnej historycznej dawki.
  Edycje są jawne per cel w edytorze; timer zachowuje dotychczasowy limit
  pojedynczej pracy3600s (dłuższy cel można zapisać ręcznie, bez przycinania celu).

## Fixround1 po review — BASE `2fcf647`

Zakres: wyłącznie P1/P2 z `task-3-review.md`, dwa pliki produkcyjne workout,
nowy stały `test/features/workout/per_set_write_authority_test.dart`, working-set
i ten raport. Bez subagentów, backendu, backupu, programu A/B, zależności,
migracji/generated, wersji lub deployu. Review P1/P2 pozostaje do ponownego
odbioru przez sesję nadrzędną; poniżej są dowody implementera, nie jej werdykt.

### Root cause / RED

Przeczytano pełny review i obie dostarczone reprodukcje
`/tmp/opencode/task3-review/{stale-widget.dart,repro.dart}`. Prześledzono ścieżki:

1. PrimaryButton starej karty A → kontrolery A → `_recordSet` czytający aktualny
   target B z providera → `logSet(guidanceTargetId:B)` → poprawna technicznie,
   lecz błędna semantycznie transakcja workingB z pomiarami warmupA. Repo nie
   mogło odrzucić tak błędnie zadeklarowanego uprawnienia.
2. `selectGuidedTarget(B)` → RAM B + queued patch → capture B →
   `saveIntervalRounds` otwierający SQL przed własnym patchem. Consume porównywał
   poprawny klucz B z trwałym A, a `expectedVersion` był przechwycony jeszcze
   przed queued checkpointem. Porównano działającą ścieżkę manualnego logSet v2,
   która już czekała na kolejkę poza transakcją.

Pierwszy przebieg **przed zmianą źródeł produktu**:

```sh
docker exec fit-catalog-program-tests bash -lc '
  cp -a /workspace/. /app/ && cd /app && timeout 180s flutter test --no-pub \
    -r expanded test/features/workout/per_set_write_authority_test.dart'
```

`/tmp/opencode/task3-fixround1/red.log`: **2PASS/3FAIL**:
- rzeczywisty stary callback A zapisał `working,12,5.0` zamiast odmówić;
- natychmiastowy timer B bez helper-flush odrzucony zarówno bez checkpointu,
  jak i z queued checkpointem;
- oba kontrolne warianty z jawnym flush przeszły.

### Pojedyncze poprawki przyczyn

- **P1:** parent wiąże niezmienną `guidedIdentity` z wyświetloną kartą:
  `(sessionSyncId,slot,targetId)`. `_recordSet` porównuje tę tożsamość, a do
  providera przekazuje ID z formularza, nie nowe ID z RAM. Ten sam guard chroni
  zapis pól i otwarcie timerów starej karty. Legacy guided ma targetIdNULL,
  manual/EXTRA nie dostają nowego wire ani klucza szkicu. GREEN pojedynczego
  callbacku: `p1-green.log`,1PASS; test rozszerzono także na zapis czasowy.
  Podczas pierwszej próby GREEN poprawiono wyłącznie pomocniczą asercję testu
  outboxa: `SyncOperation` ma equality tożsamości, więc porównywane są teraz
  pełne wygenerowane wiersze Drift, a nie dwa osobne obiekty repo.
- **P2:** po jednokrotnej rezerwacji origin v2 czeka na `flushDraft()` poza
  `db.transaction`. Następnie ponawia `requireOwnership` i pobiera aktualną
  wersję z własnych zatwierdzonych checkpointów. Epoka pozostaje epoką origin,
  zweryfikowaną ponownie po await — nie jest odświeżana z obcego durable row.
  Guardy exact-key/CAS/epoch/nonce i repo nie zostały osłabione ani zmienione.
  GREEN z dotychczasowym per-set providerem: `green.log`,19PASS.

Nowy stały plik zawiera **8 testów**: dwa rzeczywiste callbacki UI (reps/time),
macierz immediate/control-flush × brak/queued checkpoint (4), obcy checkpoint
tej samej tożsamości (odmowa bez zmiany wersji/draft/outbox), oraz zatrzymany
własny patch z anulowaniem origin podczas bariery. Ten ostatni odczytuje SQLite
przy zablokowanej kolejce, dowodząc braku trzymanej transakcji; po zmianie
generacji zapis jest odrzucony. Macierz potwierdza również zachowanie EXTRA,
jedną serię working właściwego targetu i odmowę powtórnego użycia origin.

### Końcowa weryfikacja fixround1

```sh
docker exec fit-catalog-program-tests bash -lc 'cd /app &&
  flutter test --no-pub -r expanded \
    test/features/workout/per_set_write_authority_test.dart \
    test/features/workout/per_set_guidance_provider_test.dart \
    test/features/workout/per_set_workout_widgets_test.dart \
    test/features/workout/active_session_recovery_test.dart \
    test/features/workout/guided_resume_test.dart \
    test/features/workout/guided_side_checkpoint_review_test.dart \
    test/features/workout/guided_extras_review_test.dart \
    test/features/workout/draft_consumption_review_test.dart \
    test/features/workout/draft_inflight_merge_review_test.dart \
    test/features/workout/draft_form_transition_review_test.dart \
    test/features/workout/training_continuity_test.dart \
    test/features/workout/guided_browser_draft_repro_test.dart \
    test/features/workout/interval_save_test.dart \
    test/features/workout/interval_checkpoint_test.dart \
    test/features/workout/interval_session_test.dart \
    test/features/workout/interval_timer_screen_test.dart \
    test/features/workout/active_replacement_safety_test.dart \
    test/features/workout/active_replacement_widgets_test.dart &&
  flutter analyze --no-pub && dart tools/generate_app_version.dart --check'
```

`/tmp/opencode/task3-fixround1/focused.log`: **116PASS/0FAIL**, analyze
**No issues found**, versioncheck PASS (Flutter3.35.4/Dart3.9.2). Format tylko
trzech własnych Dart, bez generatora: brak zmian deklaracji generatorów.
Nie powtarzano896 ani pełnej suity. Znany test backup3→4 pozostaje nietknięty
do Task5; wcześniejsze ograniczenia PWA/procesu/backendu pozostają bez zmian.
Końcowe diff/format oraz zgodność lock/WebSQLite kontrolowane przed commitem.
