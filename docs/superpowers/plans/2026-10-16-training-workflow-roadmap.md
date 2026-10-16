# Training Workflow Implementation Plan

**Goal:** sześć uzgodnionych usprawnień po wydaniu katalogu.
**Architecture:** małe współdzielone czyste silniki domeny, istniejące repo,
addytywne migracje tylko gdy wymagane; osobne testy granic offline/sync.
**Tech Stack:** Flutter3.35.4/Dart3.9.2, Drift, Riverpod, existingSharedPreferences.

- [x] Wydać1.12.0+25 z363ćwiczeniami/obrazami; raportwydania zachowany.
- [x] PR perstrona: testy odtwarzające wyłączonePR i mieszanieNULL/both,
  migracja9, serializery/backup/sync i prezentacja, focusedregresje.
- [x] Zapisane filtry: serializacjacałegoExerciseFilters, scopekonta,
  restart/delete/apply/namevalidationtesty, UI Bazy.
  Architektura: `docs/modules/exercise-filter-presets.md`; focused repo/provider/UI.
- [x] Timer: fakeclocktestyprzejść/pauzy/skips/finish, widget/lifecycle,
  konfiguracja i otwarcie zsesji bez duplikacji zapisuserii.
  API, guardy transakcyjne i ograniczenia: `docs/modules/workout-intervals.md`.
  19 nowych focused testów; pełny Flutter 443 testy, analyze bez uwag.
  Bez zmian schematu/deklaracji, backendu, zależności i wersji; bez release/deploy.
- [x] Generator: jednostkowe testyzbioru kandydatów, budget/sekcji/wymiany,
  UI zBazy/Planner, zapisstarttreningu.
  Drift9→10 nullable structureJson, optional wire structure schemaVersion1,
  bez backfillu i zmian attempted payloadów. Dokumentacja/API/ograniczenia:
  `docs/modules/structured-planner.md`. 16 nowych testów, pełny Flutter459,
  analyze bez uwag; backend sync37 / pełny342. Bez release/deploy/fullDocker.
- [x] Warunki: przegląd363 wpisów, deterministycznygeneratormetadanych,
  testsflagstypeAND/facets/query/presets, UI.
  - [x] Klient UI/filterconditions: opcjonalne pola sidecara v1, AND warunków,
    OR pozycji, cross-facets/query, kodek presetów, jawny brak weryfikacji,
    guard kandydatów structured planera. API i zakres testów:
    `docs/modules/exercise-execution-filters.md`.
  - [x] Dane i audyt oznaczeń katalogu: osobny agent danych; schema1,
    363 wpisy, 37 testów Python passed według przekazanego raportu agenta danych
    (nie uruchamiano ich ponownie w weryfikacji klienta).
  - Weryfikacja klienta po wznowieniu: 58/58 focused testów, analyze bez uwag,
    format 11 plików bez zmian; rzeczywisty sidecar 363/363 ID oraz filtry/fasety
    zweryfikowane przez parser Dart, nie tylko fixtures. Polecenia i ograniczenia:
    `docs/modules/exercise-execution-filters.md`.
- [x] Progresja: tests sameweight/side/RPE/missinghistory, UI propozycja,
  brakautozapisów/riskygenericadvice.
  Polityka/API/guardy i ograniczenia: `docs/modules/fixed-load-progression.md`.
  50 nowych testów (30 engine / 1 repo / 8 provider / 11 widget),
  126/126 focused+regresje workout/PR repo/auth passed; analyze bez uwag,
  format 9 plików bez zmian. Flutter3.35.4/Dart3.9.2, aktualne tree readonly
  kopiowane do /tmp w fit-web:catalog-expanded-verified. Czas/rundy utrzymaj:
  brak zapisanej porównywalnej konfiguracji. Bez schema/codegen/version/deploy.
- [x] Pełnaweryfikacja: Dockerverification, Pythonpipeline, backendpełny,
  generatedfilechecks i dokumentacjawyników/ograniczeń.
  Wydanie1.13.0+26:560 Flutter/analyze0,344 backend,37 Python; format67 Dartów
  bez zmian,17 wygenerowanych plików zgodnych. Commit źródełb1a6017 wypchnięty
  przed backupem; backup/SHA/manifest zweryfikowane, web-only wdrożony.
  Publiczne363 WebP/type/cache/SHA, wszystkie metadane, katalog, WebSQLite,
  wersja/build, API health i SPA/bootstrap/worker poprawne. Pozostałe usługi
  bez restartów. Dowody i ograniczenia: `docs/releases/2026-10-16-web-1.13.0-26.md`.
