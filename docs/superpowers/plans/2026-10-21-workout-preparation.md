# Workout Preparation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Modal przygotowania treningu z panelu Dziś, przed utworzeniem sesji.
**Architecture:** Czysty solver konfiguracji i sugestii, account-bound workflow
przygotowania, istniejący planner/start/outbox oraz osobny modal. Snapshot
sesji może różnić się od szablonu; do szablonu trafiają wyłącznie jawne zamiany.
**Tech Stack:** Flutter3.35.4/Dart3.9.2, Riverpod, Drift14, StructuredPlan v1.
**Spec:** docs/superpowers/specs/2026-10-21-workout-preparation-design.md

## Global Constraints

- Właściciel nie wykonał jeszcze ćwiczeń:brak historii jest podstawowym przypadkiem.
  Hantle od początku kg/szt. z uchwytem, gryf całościowo z7kg; bez fikcyjnej progresji.
- Wszystkie30 talerzy/58,5kg, masy gryfu/uchwytów oraz hantle1,5/2kg według spec.
- Nie bundle'ować prywatnych zdjęć. Brak nowego sprzętu z domysłu lub kasowania profilu.
- Nie zmieniać istniejącego proposeFixedLoad, PR, testów sprawnościowych i dat historii.
- Brak backendu/migracji/nowego wire/deps. Brak zapisów przed końcowym Start.
- Konto/epoch/TemplateLease i tożsamość terminu sprawdzane po await i w transakcji.
- Bez automatycznego commit/push/deploy. Ewentualne wydanie minor1.22.0+38 osobno.

## Review Focus

1. Zamiana podczas odczytu historii:wynik starego ćwiczenia nie nadpisuje nowego.
2. A→B→A lub zdalna zmiana szablonu/terminu podczas modala:start odmawia bez zapisu.
3. Łączone decyzje Tylko ten/Także szablon:szablon nie dostaje zmian sesyjnych.
4. Błąd po starcie w transakcji:zero osieroconego RAM, start/outbox dokładnie raz.
5.320px/tekst200%, braki historii/katalogu i active recovery:czytelne UI bez nowej sesji.

## File Structure

- Create lib/features/workout/preparation/domain/equipment_inventory.dart:
  potwierdzona konfiguracja, typ implementu, solver symetrycznych talerzy.
- Create lib/features/workout/preparation/domain/preparation_progression.dart:
  propozycje reps/kg i pochodzenie celu, bez I/O lub zmiany istniejącego silnika.
- Create lib/features/workout/preparation/domain/workout_preparation.dart:
  immutable baseline, szkic per slot, scope zamian i obie struktury wynikowe.
- Create lib/features/workout/preparation/providers/preparation_providers.dart:
  konto/lease, odczyty historii, workflow open/refresh/start.
- Modify lib/features/planner/providers/planner_providers.dart:
  startPrepared wewnątrz istniejącej guardowanej transakcji.
- Create lib/features/workout/preparation/presentation/workout_preparation_sheet.dart:
  modal, karty, pola kg, sprzęt, wybór scope i stan zapisu.
- Modify lib/features/schedule/presentation/widgets/today_schedule.dart:
  modal zamiast prostego confirm startu planu w obu hostach Dziś.
- Modify lib/features/home/presentation/pages/classic_today_page.dart:
  wolny trening bez fikcyjnego planu; Kontynuuj/recovery bez zmian.
- Modify lib/features/workout/data/workout_repository.dart:
  tylko potrzebny read-only odczyt zakończonej historii z deterministycznym porządkiem.
- Tests test/features/workout/preparation/ oraz schedule/router existing fixtures.

### Task 1: Sprzęt i deterministyczny solver

**Produces:** EquipmentInventory.ownerConfirmed();
enum LoadImplement { smallDumbbell, largeDumbbell, ezBar, fixedDumbbell };
List<LoadAssembly> assembleLoad({required EquipmentInventory inventory,
required LoadImplement implement, required int targetGrams, required int quantity});
LoadAssembly:implement, quantity, totalGramsPerImplement, platesPerSide,
inventoryUsed; wynik pusty oznacza brak dokładnego złożenia.

- [ ] Write equipment_inventory_test.dart:30/58500; gryf7000, uchwyty2250/2500;
  hantle1500/2000. Dla pary7250 na małych uchwytach potrzeba4 talerzy2500;
  dla pary8250 dodatkowo4×500; przy zapasie2×500 druga konfiguracja niedostępna.
- [ ] Run flutter test test/features/workout/preparation/equipment_inventory_test.dart;
  potwierdzić RED braku API, nie brak fixture/importu.
- [ ] Implement API w equipment_inventory.dart, całkowite gramy, ograniczony
  solver multiset, symetria i wspólny zapas, deterministyczne preferowanie mniej talerzy.
- [ ] Test niezłożonej masy7300, minimum gryfu7000, braku ujemnych/NaN,
  ograniczenia liczby talerzy i braku gwarancji fizycznego montażu; focused GREEN.
- [ ] Zachować diff do review; nie commitować bez osobnej zgody.

### Task 2: Historia i jawne sugestie progresji

**Consumes:** Task1; ProgressionPerformance i proposeFixedLoad.
**Produces:** PreparationLoadSuggestion proposePreparationLoad({required String
exerciseId, required String? side, required String? variantId, required String
prescription, required String tracking, required LoadImplement? implement,
required int quantity,
required bool historyUnitConfirmed, required List<ProgressionPerformance> history,
required EquipmentInventory inventory}); DTO:last/evidence/reason/targetWeightKg/
targetReps, bez zapisu. Pola null oznaczają brak sugestii, nie0.

- [ ] Write preparation_progression_test.dart:ostatnie dwie zakończone sesje,
  oba ćwiczenie/strona/wariant zgodne;3×8–12 na7250g, po3 serie po12/RPE7,
  najbliższe osiągalne7750g ≤10% → sugestia7750 i8 reps; brak RPE lub2/3serii
  → brak sugestii kg. Test wejścia korzysta z pełnego potwierdzonego zestawu.
- [ ] Run nowy test RED; najpierw potwierdzić dokładną konfigurację7750 solverem.
- [ ] Implement helper:nie omijać nowszego nieporównywalnego treningu na rzecz
  starego; brak potwierdzonej jednostki → nie sugerować kg. Bez zmiany starego silnika.
- [ ] Add repo preparation history tests:wykluczone aktywne/deleted sesje i serie,
  NULL/both/left/right i warianty osobno, żadnych PR/fitnessTest jako źródło.
- [ ] Test pierwszego treningu:brak historii nie jest błędem; brak sugestii i
  fałszywego Ostatnio, jawny Z szablonu jeśli jest, inaczej ręczne puste pole.
- [ ] Run focused + istniejące fixed_load_progression_test.dart GREEN; zachować diff.

### Task 3: Szkic, guards i atomowy start

**Consumes:** Tasks1–2; TemplateLease/StructuredPlan/PlannerWorkflow.
**Produces:** PreparationSnapshot, PreparationDraft, ReplacementScope
{sessionOnly, templateAndSession}; WorkoutPreparationWorkflow.open({required
String planSyncId, ScheduleOccurrence? occurrence}), readHistory(snapshot,
exerciseId, side, variantId), start(draft,{required bool Function() isCurrent}).
PlannerWorkflow.startPrepared(TemplateLease lease,List<Exercise> catalog,
{required StructuredPlan sessionPlan, StructuredPlan? templatePlan,
required Map<int, PreparedTarget> targets,
required bool Function() isCurrent}) → Future<void>.

- [ ] Write preparation_workflow_test.dart:open/cancel brak sesji/planu/outbox;
  obca epokaA→B→A; zdalna zmiana szablonu/terminu; aktywna sesja blokuje start.
- [ ] Run RED. Implement snapshot i szkic, weryfikacja bazowego szablonu i terminu
  jak TodaySchedule._start. Historia account-bound, bez auth/HTTP bootstrapu.
- [ ] Write mixed scopes test:zamiana slot0 sessionOnly, slot1 templateAndSession;
  sessionPlan zawiera obie, templatePlan tylko slot1; manual kg i sugestie nigdy
  nie przenoszą się niejawnie do szablonu. Cancel wszystko odrzuca.
- [ ] Implement startPrepared przez istniejące repo i start; transakcyjne
  checkTemplate/updateTemplate+jedna sesja, zero set/PR i zero zaliczenia terminu.
- [ ] Add rollback/doubletap/inflight history tests. Jeśli start odrzucono po
  await, brak wiersza i brak osieroconego aktywnego RAM; nie czyścić obcej sesji.
- [ ] Define PreparedTarget:weightKg?,reps?,side?,variantId?; seed tylko dokładne
  klucze guidedForms, nie globalne kg innych stron/wariantów. Test przejścia
  base/both→left lub inny wariant nie dziedziczy przygotowanego ciężaru.
- [ ] Test kolizji mieszanych scope:A→C tylko sesja/B→A także szablon odrzucone,
  bo template nadal zawieraA. Test legacy bez structure:informacyjny modal,
  unguided start, brak fikcyjnych celów; future/corrupt nie przechodzi na legacy.
- [ ] Run preparation + planner_workflow + schedule start + recovery tests GREEN.

### Task 4: Modal i wejścia Dziś

**Consumes:** Tasks1–3, shared filter engine i lokalny rejestr ilustracji.
**Produces:** Future<bool?> showWorkoutPreparation(BuildContext context,
WidgetRef ref,{required PreparationSnapshot snapshot}); true tylko po start PASS.

- [ ] Write preparation_sheet_test.dart:lista sprzętu, pochodzenie ostatnich kg,
  ręczna zmiana, jawny Przyjmij, niezłożona masa bez zaokrąglenia i poprawnekg/szt.
- [ ] Run RED. Build sheet:sekcje czasu/sprzętu/kart, scroll, CTA Start/Anuluj,
  osobne loading/error/empty bez udawanej historii, zwykłeTheme w obu trybach.
- [ ] Add zamiennik/scope test:reset starego kg, nowa ilustracja/ustawienie,
  filtr dostępnego sprzętu/tracking i brak automatycznego luzowania ograniczeń.
- [ ] Test zachowania oryginalnej dawki przy zamianie, pustego kg zamiennika,
  fallback Z szablonu tylko dla oryginalnego ćwiczenia, zmiany quantity1→2
  przeliczającej wspólny zapas oraz konfliktu w sesji/docelowym szablonie.
- [ ] Integrate TodaySchedule oba hosty; wolny trening jawnie bez listy, zewnętrzne
  aktywności bez fałszywego podglądu. Kontynuuj prowadzi do istniejącej sesji.
- [ ] Widget tests320/390/960 i text200:wszystkie akcje osiągalne scrollem,
  błąd historii nie nadpisuje ręcznego szkicu, back/cancel zero zapisów.
- [ ] Router integration prawdziwy shell, zamknięcie root modala i context.go
  na istniejący workout branch, bez duplicate key. Focused GREEN i analiza.

### Task 5: Review i akceptacja lokalnego kandydata

- [ ] Niezależny scoped review nowych odczytów, guards, atomowego startu i UI.
- [ ] Pełne dart format check, flutter analyze/flutter test na przypiętym SDK;
  migracje/wire/lock/sqlite worker bez zmian. Uzupełnić plan realnymi wynikami.
- [ ] Dopiero po zgodzie na release metadata podnieść pubspec1.22.0+38,
  wygenerować/check app_version; nie wymuszać build-name/build-number.
- [ ] Izolowany compiled browser320/390/text200:modal nie tworzy sesji, cancel
  zero writes, zamiana każdej scope, ręczne kg/progres przyjmowany jawnie,
  start dokładnie jednej sesji i poprawny plan/guidance, offline i A→B→A.
- [ ] Raport z rzeczywistymi screenshotami i ograniczeniami telefonu; osobna
  decyzja użytkownika o commit/push/deploy. Bez zmian produkcyjnych w tym planie.

## Handoff / stan

Zadania 1–4 zaimplementowane; zadanie 5 zakończone w zakresie lokalnego kandydata.
Końcowo:1494 Flutter PASS/0FAIL/1 skipUTC; ten DST test osobno Warsaw1PASS,
analiza bez uwag, build web PASS, scoped format34/0changes. Niezależny review
pozytywny; retest compiled browser PASS (cancel, oba scope, kg/start/reload,
mobile/desktop/text200). Pełny raport i ograniczenia:
`docs/workout-preparation-acceptance-2026-10-21.md`. Pozostaje osobna decyzja
o publikacji/metadanych wersji; nie jest to akceptacja wydania produkcyjnego.
Szczegółowy dziennik dowodów: `.superpowers/sdd/2026-10-21-workout-preparation/progress.md`.
Brak historycznych ćwiczeń wyjaśniony przez właściciela; nowy UI przyjmuje jawne
kg/szt. i nie zmienia starych danych.
Po wyjaśnieniu pierwszego treningu użytkownik zatwierdził rozpoczęcie implementacji
w tej sesji z jednym niezależnym review na końcu. Wykonanie inline/native,
w izolowanym worktree, bez wielu równoległych implementerów i bez publikacji.
