# Etap 3 — plan implementacji serii i programów A/B

> Wykonanie przez subagent-driven-development: zadania sekwencyjnie, TDD,
> niezależny spec/quality review po każdym. Bez publikacji w tym zadaniu.

**Goal:** Rozgrzewkowe/robocze wykonania, cele każdej serii i świadomie tworzone programy A/B.
**Architecture:** Nullable role w istniejącym logu, addytywny Drift15, jawne schema2 planu/guidance z zachowaniem v1. Nowa kolekcja trainingPrograms, bez zmiany weeklySchedulev1. Backend JSONB bez DDL; backup4 z importem1–3.
**Tech Stack:** Flutter3.35.4/Dart3.9.2/Drift2.28.2/sqlite3 2.9.4, FastAPI/Python3.12/PostgreSQL16 Testcontainers.
**Spec:** `docs/superpowers/specs/2026-10-28-training-sets-programs-design.md`.

## Global Constraints
- Zaczynać implementację dopiero po odebranym etapie2 (katalog431, raw424 i stare obrazy bez zmian).
- Bez aktualizacji narzędzi/zależności, nowego typu sync encji, Alembic lub zmian historycznych migracji.
- Nie przepisywać dawnych planów/guidance/logów/PR ani attempted payloadów, nie resetować danych.
- LegacyNULL setRole ma dotychczasowe znaczenie obliczeniowe; przechowywanie i outgoing pozostają nullable bez backfillu.
- v2 reps/time, max100 celów/blok; 5400s budżetu; jawna rola i strona; v1/rounds bez stratnej konwersji.
- Rotacja po kolejnych zaplanowanych terminach, nie mutowalny nextIndex ani modulo liczby sesji.
- Program core immutable; zakończenie jednorazową granicą endBeforeDate, nowa konfiguracja to nowy programID. Wyjątki i zaległe terminy bez przepisywania.
- Każdy implementer czyta AGENTS i odpowiednie guides; nie uruchamia subagentów. Raportuje dokładne nowe API dla następnego zadania.
- Backend/API-first wymagane przed przyszłym klientem na produkcji; teraz bez merge/push/deploy i bez versionbump.

## Review Focus
1. V1 podpis/JSON i historyczny NULL muszą przetrwać bez przepisywania po samym odczycie.
2. Omission/null/delete/revival oraz CAS nie mogą utracić warmup/programów lub zmienić requesthash.
3. Różne cele/strony/role i timer nie mogą zużywać obcego targetu, także po restart/doubletap.
4. Backup remap i własny/obcy szkic nie mogą utracić pending, UUID/ref i granicy zamknięcia programu.
5. Kalendarz A/B, zakończenie programu i cross-collection session proof nie mogą tworzyć fikcyjnego zaliczenia.

### Task 1: Backend — rola i ochrona rozszerzeń
**Files:** `backend/app/sync/{schemas,service}.py`, `backend/app/mentor/context.py`, `backend/tests/test_sync.py`, testy validation/mentor, `backend/SYNC_EXTENSIONS.md`.
**Interfaces:** `workoutSet.payload.setRole?: null|working|warmup`; `profile.payload.trainingPrograms` opaque optional JSON kolekcji. Brak defaultowania w hashowanym żądaniu i brak DDL. `structure/guidance` pozostają opaque.
- [ ] RED: typed role422 dla nie-string/bool/nieznanych; brak/NULL/working/warmup przechodzą bez mutacji requestu.
- [ ] RED: omission zachowuje tylko na właściwej encji i żywym snapshotcie, explicitNULL resetuje, DELETE/revival nie dziedziczą; operationReuse/CAS/batch rollback zachowane.
- [ ] RED: Mentor trend nie liczy warmup, legacyNULL/working zachowuje dotychczasowe wyniki.
- [ ] GREEN: allowlista optional extensions, walidacja i filtr; documented API-first/old-client limitations.
- [ ] Focused oraz pełny pytest na hash-lockedPython3.12/Testcontainers16; nie SQLite.
- [ ] Commit i raport task-1-report.md; niezależny review przed Task2.

### Task 2: Flutter — role storage, modele v2, program codec i backup
**Files:** nowe `lib/core/models/set_role.dart`, `lib/features/planner/domain/set_prescription.dart`, `lib/features/schedule/domain/training_program.dart`; `core/database/{app_database,tables}` i wygenerowane; `core/models/workout_session.dart` i wygenerowane; `core/sync/{user_collections,sync_store,sync_service,sync_dao}` właściwe pliki; `core/services/backup_service.dart`; `planner/domain/{structured_plan,session_template}.dart`; `workout/domain/{workout_guidance,workout_repeat}.dart`; `workout/data/workout_repository.dart`, odpowiednie testy.
**Interfaces (minimum):**
- `SetPrescription`: immutable targetId/setRole/side/reps/workSeconds/restSeconds/weightKg, parser+validate dla trackingu; nazwy pól/argumentów wypisać w raporcie.
- `PlanPrescription.perSet(...)` lub równoważny constructor bez zmiany dotychczasowego APIlegacy; ordered setTargets jako jedyne źródło v2. `StructuredPlan.schemaVersion` i `WorkoutGuidance.schemaVersion` zachowują1 lub2.
- `WorkoutGuidance.link(slot,setSyncId,{targetId})`, jawny skipTarget dla v2; v1toJson bez zmian.
- `TrainingPrograms.validateEntry(Map)` i guard zachowania immutable core/endBeforeDate; integracja UserCollections bez fallbacku do exerciseVariants.
- `WorkoutRepository.logSet(...,{String? setRole,...})`; outgoinginclude tylko nonNULL, SQLnullableCHECK i migration14→15 dwóchkolumn.
- helpers odczytów progression/preparation/trend effective-working bez globalnego ukrywania historii.
- backup4 i remap program copies/overrides/plans/sessions/setlinks, stare1–3obsługiwane.
- [ ] RED: role column migrate14→15/legacyNULL/invalid role, dto/raw/wire omission/NULL/attempted unchanged i nowe kolekcje.
- [ ] RED: v1byte/signature roundtrip, v2targets/dawki/role/side/order/bounds, future3quarantine; jedna lista bez spłaszczenia.
- [ ] RED: warmup nie trafia do evidence progresji/trendów, historia nadal go zwraca; heterogeniczna kopia szablonu tylko bezstratna.
- [ ] RED: backup4/legacy1–3/remap/tombstone/endBeforeDate/limit500/rollbackprzybrakuref/pending niezmienione.
- [ ] GREEN + codegen build_runner; focused data/sync/planner/backup/progression, analyze; commit wygenerowanych plików.
- [ ] Raport API i ograniczeń dla Task3/4, niezależny review.

### Task 3: Flutter — edytor celów i aktywne prowadzenie
**Files:** `planner/presentation/pages/template_editor_page.dart` + wąskie nowe widgets; `planner/providers/planner_providers.dart`; `workout/{providers/workout_providers,presentation/pages/active_session_page,domain/workout_progress}.dart`; log/history/summary/PR/trends/preparation odpowiednie pliki; nowe tests widget/provider/SQLite.
**Interfaces:** użyć faktycznych API Task2 z raportu, nie utrzymywać drugiego modelu. targetId w v2draft/checkpoint/origin, legacykeys niezmienione. Rzeczywista rola kontroluje PR i linkowanie celu.
- [ ] RED: per-set edit/add/delete/reorder/role/side/kg/reps/time/rest, stableIDs, cancel/stale/save/read bez spłaszczenia.
- [ ] RED: różne cele po start/restart; v2performed właściwego targetu atomowe, doubletap/oldview/extra nie zużywa celu, skippedTarget nie udaje wykonania.
- [ ] RED: jednostronne targetboth nie potwierdzone samymleft, target/side/variant/timer niezależne, immediate action po recovery i foreignEXTRA guards.
- [ ] RED: nowe warmup nawet z większym ciężarem nie tworzy PR/progresji, rola w manual/extra/repeat/interwałach; legacyNULL bez zmiany PRhistory.
- [ ] RED: przygotowanie i zamiana nie nadpisują całej rampy; dodatni kg w dowolnym celu blokuje active replacement; jeden target/1round, multi tylkoEXTRA.
- [ ] GREEN: rozdzielić duże widgets/provider helpers według odpowiedzialności, bez rozproszenia autoryzacji transakcji.
- [ ] Focused planner/workout/progress/sync, analyze; commit+raport; review przed Task4.

### Task 4: Flutter — programy A/B i jawne dowody wykonania
**Files:** nowy `schedule/domain/training_program_schedule.dart`, `schedule/data/training_programs_repository.dart`, `schedule/providers/training_programs_providers.dart`, wąski program UI; `planner/presentation/pages/templates_page.dart` i ewentualny router+routertest; `schedule_repository.dart` dla wspólnej kontroli session proof; testy domain/repo/widget/syncbackup.
**Interfaces:** codec/profile storage Task2. Dni `CalendarDay`; `occurrences` bounded window max366days, UUIDv5(programId,originalDate), plan A/B poordinaluzaplanowanychdat. Korzystać z istniejącego workflow szablonów i account leases.
- [ ] RED: pn/śr/ptABA/BAB, granica roku/leap/DST, effectiveFromDate, move zachowujeID/plan, endBeforeDate chroni pastdue, core mutation i conflicting cutoffs odmawiane.
- [ ] RED: create/rename/end/cancel/pendingprofile/hold i brak planu/unsupportedv2/cwiczenia; brak automatycznych zapisów na wejściu.
- [ ] RED: completed tylko jawną sesją zakończoną z>=1liveeffective-working; empty/warmuponly/start/upływczasu bez zaliczenia; deletion dowodu invalid, duplikaty acrossprogram/weekly konfliktem.
- [ ] RED: backup copies i refs po restore, LWW/accountABA/2devices/attempted/quarantine bez silentdrops.
- [ ] GREEN: minimalny UI wybierający dwa własne szablony, dni i start; tydzień/start/move/complete; nazwaeditable, structuralchange przez newprogram+endold.
- [ ] Focused schedule/planner/program/backup + analyze, commit i raport; independentreview.

### Task 5: Integracja i odbiór
- [ ] Aktualne guides training/sync/guided/planner/programs/backup i kontrakt backendu.
- [ ] Pełne Flutter i backend na aktualnymdrzewie, analizaclean, codegen/format/diffcheck i kontrola niezmiennych deps/WebSQLite/prefix424.
- [ ] Standardowa kompilacja Web i generator offline nafinalnymkodzie (bez runtimepromocji).
- [ ] Whole-branch review i konkretne poprawki z regresjami, bez wdrożenia na produkcję.
- [ ] Raport obu etapów z liczbami testów i ograniczeniami kompatybilności/ilustracji.
