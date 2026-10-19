# Workout templates implementation plan

**Goal:** Oddzielić szablony od wykonania, udostępnić edytor i bezpieczne
zarządzanie sesjami oraz generowanie propozycji przez Mentora.
**Spec:** `docs/superpowers/specs/2026-10-19-workout-templates-design.md`
**Architecture:** Istniejące WorkoutPlans/StructuredPlan jako szablony, snapshot
guidance w sesji. Guardowane transakcje istniejącego Drift/outbox. Mentor tylko
proponuje; zapis po świadomej akcji edytora.
**Tech Stack:** Flutter3.35.4/Dart3.9.2, Riverpod, Drift, FastAPI/PostgreSQL.

## Global Constraints

- Zachować wszystkie istniejące lokalne zmiany hotfixu1.16.1.
- Bez automatycznego wykonania serii, zmiany historii, upgrade SDK i zależności.
- Każde zadanie: regresje RED, implementacja, focused GREEN/analyze, review.
- Bez deploy, push i commitów cudzych/istniejących zmian.

## Review Focus

1. Zdalna zmiana szablonu przed zapisem — odmowa bez utraty formularza.
2. Wylogowanie A–B–A podczas dialogu — brak zapisu/nawigacji do prywatnych danych.
3. Dodatkowe serie repeat — brak postępu celu i zachowanie po restart.
4. Usunięcie rodzica podczas sync — brak wskrzeszenia serii i podwójnych operacji.
5. Powtórzenie płatnej propozycji — brak automatycznej nowej operacji/kosztu.

## Zadanie 1: Edytor i magazyn szablonów

- [ ] Dodać testy domenowe ręcznego StructuredPlan i zachowania opcjonalnego kg.
- [ ] Dodać guarded workflow create/update/delete z optimistic snapshot oraz
  blokadą deferred/held i testami realnego outbox/restore.
- [ ] Dodać listę szablonów i edytor na `/workout/templates`, nazwa, katalog,
  reorder i cele. Wykorzystać `PlannerWorkflow.startSaved` do jawnego startu.
- [ ] Wpiąć wejście w WorkoutHome, zapis/kopia z sesji przez jawne wejście edytora.
- [ ] Focused testy planner/templates/router; review spec i quality.

Pliki: `lib/features/planner/{domain,data,providers,presentation}/`,
`lib/app/router.dart`, `workout_home_page.dart`; testy `test/features/planner/`.
Interfejs: `SavedPlan` i `StructuredPlan` pozostają wspólne z generatorem;
edytor przyjmuje opcjonalny syncId oraz snapshot początkowego planu z sesji.

## Zadanie 2: Wykonanie, postęp i usuwanie

- [ ] Testy empty finish i transactional delete sesja+serie+draft+outbox,
  auth/deferred/attempted/reopen; statystyki bez tombstone.
- [ ] Implementować walidację, jawny discard i potwierdzenie usuwania w historii,
  recovery i podsumowaniu; pusta sesja oferuje zapis szablonu zadania1.
- [ ] Dodać progress model i prezentację guidance/repeat; limity na blok,
  only confirmed live UUID, dodatkowe poza mianownikiem.
- [ ] Włączyć dodatkowe ćwiczenia w repeat i ich trwałe formularze bez zmiany
  kursora wykonania; regresja repeat -> add -> restart -> confirmed sets.
- [ ] Focused workout/repeat/recovery/schedule tests i review.

Pliki: `workout_repository.dart`, `workout_providers.dart`,
`active_session_page.dart`, `repeat_set_panel.dart`, `session_summary_page.dart`,
`session_recovery_panel.dart`; nowe domain/widgets pod jedną odpowiedzialność.

## Zadanie 3: Propozycje szablonów Mentora

- [ ] Sprawdzić istniejący proposal/ledger i rozszerzyć o generowanie szablonu
  z nazwą, katalogowymi ID i celami, z bezpiecznym limitem rozmiaru i walidacją.
- [ ] Testy backend mock provider: malformed/unknown IDs/limits/idempotent retry,
  brak automatycznego zapisu domeny. Testy klienta: podgląd -> editor -> confirm.
- [ ] UI brak konfiguracji, koszty i nieznane wyniki zachowują obecne guardy.
- [ ] Focused mentor backend/client, review.

## Zadanie 4: Integracja i dokumentacja

- [ ] Pełne flutter analyze/test, generator version --check, backend suite
  jeśli zmieniono API; format wyłącznie własnych plików, diff --check.
- [ ] Review całego przyrostu względem baseline hotfixu; poprawki regresji.
- [ ] Raport implementacji z faktycznymi wynikami i ograniczeniami, bez
  deklarowania wdrożenia czy testu płatnego dostawcy.

## Postęp

Baseline: istniejący niezacommitowany hotfix1.16.1 na branch
`fix/training-continuity-ux`; nie resetować i nie commitować go w tych zadaniach.
Zadania wykonywać sekwencyjnie; wspólne pliki/router/providers wymagają review
po każdym zadaniu. Zapisano spec i plan po zatwierdzeniu kierunku w rozmowie.
