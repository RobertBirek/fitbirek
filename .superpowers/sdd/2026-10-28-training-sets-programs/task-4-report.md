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

Pozostałe: provider, preparation/start integration, UI/entrypoint, widgety,
rzeczywiste dwa urządzenia/CAS, backup-reference integration, focused regression
i końcowy analyze/format/diff/version/WebSQLite check. Task5: pełna suita/runtime.
Nie uruchamiano pełnej suity ani znanego failing `custom_fitness_data_test:330`.
