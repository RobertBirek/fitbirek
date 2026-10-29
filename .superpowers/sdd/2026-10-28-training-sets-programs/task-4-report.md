# Task4 — checkpoint implementacji

Status: **W TOKU**, baza `bff0bc6`. Bez publikacji, migracji, nowych kolekcji,
zależności lub zmian generatorów. Niezależny review należy do sesji nadrzędnej.

## API (checkpoint 1)

- `TrainingProgramSchedule(TrainingPrograms).between(first,last)` — okno do366
  dni włącznie, ordinal zaplanowanych dat O(7), bez kursora wykonania.
- `ProgramOccurrence` — pierwotna data/UUIDv5, A/B, osobny snapshot wyjątku,
  pełny optimistic baseline, odłączona kopia snapshotu.
- `TrainingProgramsRepository.load/open/create/rename/end/move/complete/`
  `validateOccurrence/completionStatus`; read-only `ProgramLease` przechwytuje
  epoch/binding/profile i rewizję programu przed modalem. Create sprawdza oba
  zapisane szablony, katalog i metadane v2, bez generatora zastępczego.
- `SessionCompletionProof` — wspólny namespace powiązań weekly/program,
  live finished + live effective-working, konflikt obu powiązań po merge.

## RED → GREEN i polecenia

Docker `fit-catalog-program-tests`, Flutter3.35.4/Dart3.9.2, źródła
`/workspace` RO → selektywne kopiowanie własnych plików do `/app`.
Wszystkie komendy foreground, `flutter test --no-pub … --reporter expanded`.
Logi host: `/tmp/opencode/task4/`.

- `calendar-red.log`: brak nowego API kalendarza (compile RED).
- `calendar-green.log`: **8PASS**, pn/śr/pt ABA/BAB, okna, początek w środku
  tygodnia, leap day/year boundary, daty obu przejść DST, snapshot/move/cutoff.
- `proof-red.log`: rzeczywisty assertion RED: weekly akceptował warmup-only.
- `repo-red.log`: brak nowego API repo (compile RED); poprawiono też fixture
  deferred `version`, zanim uruchomiono testy implementacji.
- `repo-green1.log`: **21PASS** (14 program +7 weekly), oba kierunki odmowy
  cross-collection, zdalny duplikat, invalidation, roleNULL/working/warmup,
  stale lease/move-away-back, end/today, hold i queued accountABA.

## Checkpoint 2 — integracja i UI

- `trainingProgramsRepositoryProvider` / `trainingProgramsWeekProvider` obserwują
  profil/binding, plany, sesje, serie i deferred. Katalog/metadane są czytane przed
  transakcją; snapshot nie uruchamia auth HTTP ani zapisu. Stan `unavailable`
  planu i `writeError` profilu blokuje start/zapis bez usuwania definicji.
- `WorkoutPreparationWorkflow.open(programOccurrence:...)` i read-only
  `PreparationSnapshot.programOccurrence` ponawiają walidację optimistic baseline
  programu w istniejącym przygotowaniu i przy starcie. Start nadal wyłącznie
  przez `PlannerWorkflow.startPrepared` z jego metadanymi/budżetem/lease/v2targets.
- `/programs`: chroniony root overlay, wejścia z Moich szablonów i Rytmu tygodnia.
  Nazwa, dwa szablony A/B, dni, lokalna data, tydzień, start/move/jawne complete,
  rename/end. Istniejący motyw/typografia/karty, bez nowych zależności. Start
  używa `context.go` do istniejącego shella. Nie ma przypomnień programowych.
- Dodatkowo create lease przechwytuje baseline wybranych szablonów. Wirtualny
  kalendarz nie oblicza dnia poza końcem okna, także dla9999-12-31.

Testy i logi (`/tmp/opencode/task4/`):

- `provider-red.log` / `ui-red.log`: brak nowych API, compileRED.
- `provider-green1.log`: wykryto błędne założenie fixture (domyślne criteria
  serializera) i wywołanie ref po await przy przebudowie zależności; naprawione
  przez przechwycenie obu futures przed await, bez osłabienia guardów.
- `provider-green2.log`: **3PASS**; `ui-router-green.log`: **4PASS**.
- `calendar-planlease-red.log`: **2 rzeczywiste assertionRED** — wyjście poza
  datę9999 i brak odrzucenia równoległej edycji szablonu w create pickerze.
- `cloud-analyze1.log`: **28PASS/1FAIL**, błąd fixture: dynamiczny typ nested
  payload nie spełniał Map<String,dynamic> koperty sync, więc prawidłowo powstały
  dodatkowe quarantine/hold. `cloud-diagnostic.log` zachowuje diagnozę. Fixture
  poprawiono do prawdziwego JSON-object; nie zmieniano kodu sync ani kwarantanny.
- `cloud-analyze2.log`: **29PASS**, po czym poprawiono wyłącznie lint nawiasów.
- `program-focused1.log`: **43PASS/0FAIL**, `flutter analyze --no-pub`:
  **No issues found**. Obejmuje nowe regresje A-B-A podczas create/preparation,
  stale move-back/end/template-edit/hold, narrow320px i text200%, keyboard,
  create/cancel/rename/end/move/complete oraz start na produkcyjnym routerze.
  Dwa rzeczywiste urządzenia SQLite + CAS dowodzą program/program i program/weekly
  conflict, a konkurujące cutoffs trafiają w hold. Próba wysłana zachowuje
  payload/baseVersion/UUID i cały row przy kolejnym retry, remote raw zostaje.
  Backup4 z repo-created zakończonym/moved/completed programem: same-DB restore
  daje nieważny retained original i żywą kopię z remapem, a ponowny eksport/restore
  na inne konto zachowuje cutoff/role/referencje i binding konta docelowego.
- `host-source.sha256` / `app-source.sha256`: lib/test Dart **identyczne** między
  hostem a testowanym `/app` po formatowaniu wyłącznie19 własnych Dart.

Pozostałe: focused regressions i końcowy diff/version/WebSQLite check.
Task5: pełna suita/runtime. Nie uruchamiano pełnej suity ani znanego failing
`custom_fitness_data_test:330`; nie oznacza to jego naprawy.
