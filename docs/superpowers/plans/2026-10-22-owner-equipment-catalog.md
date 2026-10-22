# Owner Equipment Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Uzupełnić katalog o12 brakujących ćwiczeń i poprawne wymagania sprzętu.
**Architecture:** Chroniony raw katalog412 + append12 + jawne wersjonowane korekty6;
metadata sprzętu OR-of-AND, wspólny matcher i kontrolowana edycja profilu.
**Tech Stack:** Flutter3.35.4/Dart3.9.2, Drift14 bez migracji, XLSX/Python.
**Spec:** docs/superpowers/specs/2026-10-22-owner-equipment-catalog-design.md

## Global Constraints
- Bez zmiany istniejących ID, zdjęć użytkownika, backend sync enumów i toolchain.
- Sandbag stale20kg; step150kg, wysokość niezmierzona; brak automatycznej inwersji.
- Brak globalnej zamiany Ławeczka na decline lub automatycznej edycji profilu.
- Export XLSX przez tools/xlsx_to_json.py, nigdy deprecated generator.
- Początkowo scope lokalny; po odbiorze użytkownik osobno zatwierdził naprawę
  driftu Alembica i publikację1.23.0+39. Każda promocja dopiero po bramkach wydania.

## Review Focus
- Upgrade z istniejącymi pomiarami/favorites/pending nie traci żadnych danych.
- Brak jednego elementu kompletnego zestawu nie przechodzi przez OR.
- Decline do brzuszków nie implikuje ławki do wyciskania ani incline/flat.
- Step only/bez hantli nie podkłada pary i historycznych kg innego wykonania.
- Nieznane equipment/profile i błędne equipmentSets nie są cichym pozwoleniem.

### Task 1: Dane i reprodukowalny dodatek
**Files:** tools/expand_owner_equipment_catalog.py; tools/source_data/**;
tools/xlsx_to_json.py; tools/build_catalog_metadata.py; tools/validate_catalog.py;
tools/expand_catalog.py, expand_ez_catalog.py; assets/data/**;
tools/tests/test_owner_equipment_expansion.py i istniejące testy pipeline;
backend/tools/generate_mentor_catalog.py i wygenerowana projekcja tylko wg potrzeb.
**Produces:**424 raw wiersze,6 korekt schemaVersion1, equipmentSets we metadata.
- [x] RED: prefiks412,12 ciągłych ID,6 korekt bez duplikatu cw009/cw123,
  dopuszczalnegear, źródła, warunki, idempotencja/replay, reprodukowalność.
- [x] Implement append12 i manifest korekt6 według spec; kompletne source URLs.
- [x] Export właściwym narzędziem; GREEN Python pipeline + conditions + EZ.
- [x] Utrzymać stare412 ilustracji; brak fałszywych plików dla nowych ID.

### Task 2: Matcher sprzętu, generatory i profil
**Files:** lib/features/exercises/domain/exercise_catalog_metadata.dart,
exercise_filter_engine.dart; lib/features/planner/domain/{plan_generator,structured_plan}.dart;
lib/app/constants.dart; onboarding_equipment_page.dart; edit_profile_page.dart;
test/features/exercises/*equipment*_test.dart, test/features/planner/ i profile tests.
**Produces:** equipmentOptions(Exercise) -> List<List<String>>;
supportsEquipment(Exercise,Iterable<String>) -> bool;
matchingEquipment(Exercise,Iterable<String>) -> List<String>? w ExerciseFilterEngine.
- [x] RED: parser puste/błędne grupy, fallback AND; body+step/chair/bench dla cw009,
  brak sprzętu odmowa; dumbbells-only nie spełnia dumbbells+bench.
- [x] Implement wspólny matcher, strict generators, alternative facets/query,
  nowegear i jawny profile picker zachowujący unknown strings; bez auto zaznaczeń.
- [x] GREEN: oba generatory, filtry, UI profilu; decline nie daje flat/incline.

### Task 3: Wąskie korekty importu i przygotowanie
**Files:** lib/features/exercises/data/exercises_repository.dart;
nowy exercise_catalog_corrections.dart; lib/features/workout/preparation/**;
lib/features/workout/presentation/pages/active_session_page.dart;
test/features/exercises/exercises_repository_test.dart i preparation tests;
test/features/workout/weighted_time_preparation_test.dart.
**Consumes:** korekty zTask1 i matcher zTask2; test fixtures mogą deklarować te same dane.
- [x] RED: upgrade412 favorites/history/pending zachowane, nowe12 importowane;
  update tylko sześciu katalogowych rekordów, idempotencja bez replace.
- [x] Implement walidowany manifest i celowane aktualizacje pól (bez migracji).
- [x] RED: wristroller ma zawieszony ciężar, niekg/szt./parę; body-step nie
  wymaga hantli; explicit sandbag20 i brak kg progresji/innej masy w historii.
- [x] Implement przygotowanie przez matchingEquipment; stały zasób20kg i
  ostrzeżenia rzeczywistych ograniczeń, nie fake history/default dla innych ruchów.
- [x] GREEN import/preparation i regressions konta/recovery.
- [x] Integracyjna regresja carry time: przygotowane20kg bez prescriptionkg
  przechodzi przez aktywną kartę, zapis czasu i historię/recovery bez utratykg;
  zwykły bodyweight time nie dostaje fikcyjnego ciężaru.

### Task 4: Integracja i odbiór
**Files:** test/features/exercises/catalog_asset_integration_test.dart,
test/features/planner/structured_plan_test.dart i count/repro fixtures;
docs/modules/ i nowy raport odbioru.
- [x] Dostosować literalne count424 i projekcje bez osłabiania istniejących testów.
- [x] Focused Python/Flutter, pełna analiza i Flutter suite; generator tylko
  gdy zmieniono deklaracje (plan ich nie wymaga), SQLite/lock bez zmian.
- [x] Niezależny review danych, zachowania profilu, importu i sprzętu; poprawki
  dopiero po reprodukcji RED. Raport jawnych braków ilustracji/telefonu.

### Task 5: Ograniczenie propozycji Mentora bez zweryfikowanego sprzętu
**Files:** backend/app/mentor/templates.py; backend/tests/test_mentor_templates.py.
- [x] RED: tekst o wyciskaniu ujemnym nie może wprowadzić cw418 do puli ani
  zaakceptować propozycji z tym ID bez autorytatywnej kontroli sprzętu.
- [x] Dodać wąskie wyłączenie cw418 z puli i walidacji Mentora. Nie przesyłać
  nowych danych profilu do AI ani nie udawać, że ranking tekstu weryfikuje sprzęt.
- [x] GREEN targeted backend templates; pozostałe ID/katalog i limity bez zmian.
  Zaznaczyć, że pełna kontrola wyposażenia Mentora jest osobnym projektem.

## Wykonanie
Użytkownik wybrał wykonanie w tej sesji („ok, działaj”), bez ponawiania pytań
o zatwierdzone korekty sprzętu. Task1 iTask2 są niezależne przy powyższym API;
Task3 zaczyna od testów i scala zależności poTask1/2. Specjalizowani implementerzy
mają rozłączne pliki; parent integruje count/testy i jeden końcowy review.

## Odbiór końcowy

Lokalny zakres zaimplementowany i sprawdzony:1561FlutterPASS/1UTCskip,
WarsawDST1PASS, analiza czysta, scopedformat82/0changes;65PythonpipelinePASS,
628backendPASS (snapshot, potem29currenttemplatesPASS),32offlineNodePASS.
Compiledbrowserpo poprawcecarryPASS, real20s/20kg,424/6import i profileeditor;
hashy772 wejść skompilowanego kodu zgodne. Finalreview+fixrereviewPASS.
Osobny Alembic metadata check ma zastany FAIL indeksu token_hash; bez zmiany
modeli/migracji/prod. Nie deklarujemy całego łącznego gate schematu jako zielonego.
Szczegóły: docs/owner-equipment-catalog-acceptance-2026-10-22.md.
Nowy katalog pozostaje bez commit/push/deploy i bez nowych12 ilustracji.

## Późniejsza decyzja o wydaniu

Użytkownik zatwierdził commit/push/main/deploy1.23.0+39 i usunięcie zastanego
driftu. Model AppleHealth dostosowano do fizycznego schematu0008 bez zmian
migracji; scoped3PASS i command.checkPASS. Nowy pełny backendgate oraz obrazy
wydania muszą przejść przed promocją. Zdania o braku publikacji powyżej opisują
stan lokalnego odbioru, nie dowód zakończenia wdrożenia.
