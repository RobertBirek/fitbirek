# Task4 — raport implementacji i przekazania

Status: **IMPLEMENTED / ACCEPTANCE BLOCKED przez baseline test**,
baza `bff0bc6`. Zakres implementacyjny Task4 jest zrealizowany; nie zgłaszam
pełnego DONE/green acceptance. Niezależny review i Task5 pozostają sesji
nadrzędnej. Bez publikacji, migracji, nowych kolekcji, zależności lub zmian
deklaracji generatorów. Checkpoint commity: `1466f8c`, `cf4a10a`.

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

## Końcowa weryfikacja

Końcowy focused command, foreground w Dockerze:

```sh
cd /app
flutter test --no-pub \
  test/features/schedule test/features/planner \
  test/features/workout/preparation \
  test/features/settings/backup_service_test.dart \
  test/features/settings/backup_snapshot_test.dart \
  test/features/settings/settings_backup_authority_test.dart \
  test/core/training_program_backup_test.dart \
  test/core/training_program_sync_test.dart \
  test/core/training_sets_programs_domain_test.dart \
  test/core/user_collections_test.dart \
  test/core/profile_collections_sync_test.dart \
  test/core/profile_cloud_review_test.dart \
  test/core/profile_collection_quarantine_test.dart --reporter expanded
```

- `focused-regression1.log`: **514PASS/1FAIL**.
- `focused-regression-final.log`: **517PASS/1FAIL** (po dodatkowych guardach).
- Jedyny FAIL: `activity_cloud_test.dart:208`,
  `two real DB sync CAS preserves attempted bytes, tombstones and external history through reopen`.
  Asercja eksportu oczekuje schemaVersion3, aktualny Task2 eksportuje4.
  **Potwierdzone na czystym `bff0bc6`**: `git archive bff0bc6 lib` rozpakowano
  wyłącznie w roboczym `/app`, uruchomiono niezmieniony activity_cloud_test,
  wynik **1PASS/1FAIL**, identyczna linia208/expected3/actual4
  (`base-activity-cloud.log`). Potem przywrócono wszystkie własne źródła do /app.
  Nie zmieniono tej obcej asercji; pozostaje korektą baseline w Task5.
- Sam Task4, `final-verification.log`: **46PASS/0FAIL** w sześciu nowych plikach:
  calendar9, repo19, provider8, cloud/backup5, page4, production-router1.
  Dodatkowy nowy weekly warmup regression również PASS w pełnym focused.
- `generic-hold-red.log`: **2FAIL**, rzeczywiste assertionRED braku blokady
  generycznych `_syncPushHold` i `_syncPullQuarantine` profilu. Wspólny
  `assertScheduleWritable` sprawdza teraz także `SyncQuarantine.heldKeys`.
  `hold-green-verification.log`: **2PASS**, raw/attempted rows identyczne.
- `legacy-red.log`: **1FAIL**, wykryto zbyt surowe odrzucanie dostępnego legacy
  szablonu bez struktury. Usunięto ten dodatkowy warunek (nie dotyczy future/
  malformed), bez konwersji do v2 lub generowania. Końcowy repo test PASS.
- `TZ=Europe/Warsaw flutter test --no-pub test/features/schedule/training_program_schedule_test.dart --reporter expanded`:
  **9PASS** (powtórzenie kalendarza w docelowej strefie).
- `flutter analyze --no-pub`: **No issues found**.
- `dart tools/generate_app_version.dart --check`: **PASS**, wersja bez zmiany.
- `xargs dart format --output=none --set-exit-if-changed < /tmp/task4-files.txt`:
  **19 plików, 0 zmian**. Formatowano/kopiowano na host tylko własne pliki.
- `git diff --check`: **PASS**. Host i `/app` zawierają identyczne wszystkie
  `lib/test/*.dart`: `host-source-final.sha256` / `app-source-final.sha256`.
- Flutter**3.35.4**, Dart**3.9.2**, bez `pub get`/upgrade/deps. Nie zmieniano
  Drift/Freezed/JSON deklaracji, więc generator niewymagany; wszystkie generated
  są identyczne z bazą. `pubspec.lock` i Web SQLite bez zmian i zgodne:
  sqlite3**2.9.4**, drift**2.28.2**;
  `sqlite3.wasm` SHA256
  `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`;
  `drift_worker.dart.js` SHA256
  `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`.

## Pozostałe i ograniczenia odbioru

- Task5 / sesja nadrzędna: naprawa baseline expectation activity_cloud208 oraz
  znanego `custom_fitness_data_test:330`, pełny Flutter/backend i rzeczywisty
  runtime/browser/telefon/PWA. `custom_fitness_data_test` **nie był uruchamiany**,
  jego znany błąd nie został naprawiony ani uznany za green.
- Niezależny review wymagany przed odbiorem. Zgodnie z poleceniem implementer
  nie uruchamiał subagentów/reviewerów i nie publikował/pushował/mergował.
- Nie dodano narzędzia automatycznej naprawy konfliktów, garbage collection ani
  przypomnień. Conflict i invalidated pozostają jawne; brak cichego clear/retry.
- UI nie jest osobnym redesignem; używa istniejącego motywu i workflow. Narrow
  i keyboard są sprawdzone widgetami; nie jest to dowód fizycznego urządzenia.
