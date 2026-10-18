# Training Rhythm Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox syntax. No commits/push/deploy without a new explicit user request.

**Goal:** Powtarzać rzeczywiste treningi bez autologowania, planować tydzień,
czytać porównywalne trendy i uczciwie sprawdzić offline PWA.

**Architecture:** Trzy oddzielne moduły korzystają z istniejących repozytoriów,
snapshotów i synchronizacji. Rytm tygodnia posiada jedyne zmiany schematu i
kontraktu cloud; powtórzenie używa jawnych celów, a trendy wyłącznie odczytów.

**Tech Stack:** Flutter 3.35.4, Dart 3.9.2, Riverpod, Drift, FastAPI/PostgreSQL,
Python Playwright i Docker. Projekt: `../specs/2026-10-17-training-rhythm-design.md`.

---

## Stan końcowy — 2026-10-17

**Trzy funkcje zaimplementowane, testy integracyjne zakończone; nie oznacza to
pełnego PASS akceptacji.** Lokalny, niecommitowany stan na baseline `e0fe9a6`,
bez bumpa wersji (nadal 1.14.0+27), commit/push/deploy. Review implementacji:
brak otwartych HIGH/MEDIUM. Pełny Flutter **771 PASS**, analyze **0 uwag**,
backend **378 PASS**, build **`fit-web:rhythm-local-fixed` PASS**.

Końcowy [raport wyników](../../training-rhythm-results-2026-10-17.md) zawiera
źródła dowodów i granice akceptacji. Najnowszy browser retest potwierdza naprawę
startu harmonogramu i ręczne zaliczenie z pull drugiej przeglądarki. Bezpośredni
reload aktywnego URL nadal wymaga **Home → Kontynuuj → Wznów** dla odtworzenia
planu; zachowany UUID nie jest dowodem pełnego automatycznego recovery.
Pełne offline PWA na osobno badanym baseline ma **FAIL**, telefon fizyczny
pozostaje **MANUAL PENDING**. Historyczne RED w raportach zachowano.

Checkboxy poniżej oznaczają wykonane prace i weryfikacje w opisanym zakresie,
nie zbiorcze zaliczenie wszystkich kryteriów produktu.

## 1. Powtarzanie — właściciel workout

**Create:** `lib/features/workout/domain/workout_repeat.dart`,
`lib/features/workout/presentation/widgets/repeat_workout_dialog.dart`,
focused `test/features/workout/workout_repeat*_test.dart`.
**Modify:** `workout/data/workout_repository.dart`, `workout/providers/workout_providers.dart`,
`workout/presentation/pages/session_summary_page.dart` oraz istniejący snapshot
guidance wyłącznie przez addytywne, kompatybilne rozszerzenie.

- [x] Napisać i uruchomić RED dla planu vs wykonania, różnych serii/side/variant,
  usuniętych źródeł i potwierdzenia nowego UUID bez nowych set/PR.
- [x] Wprowadzić odczyt i deterministyczny podgląd celów; powtarzać plan tylko
  jeśli istnieje prawdziwy snapshot, nie z aktualnego generatora.
- [x] Dodać potwierdzenie/start i prefill kolejnych serii z istniejącymi guardami
  konta/sesji, bez kopiowania wykonanych zdarzeń i checkpointów timerów.
- [x] GREEN: workout + planner **269 PASS**; repeat **26 PASS**, w tym mixed
  reps+seconds i ciężar serii czasowych po korekcie review.
- [x] Udokumentować format snapshotu i ograniczenia legacy protokołów:
  [workout-repeat](../../modules/workout-repeat.md). Cele wykonania i kursor
  są lokalnym szkicem, nie chmurowym wznowieniem ani częścią backupu.

## 2. Harmonogram — właściciel Drift/sync/planner

**Create:** `lib/features/schedule/domain/weekly_schedule.dart`, repozytorium,
providers, page i testy pod `test/features/schedule/`.
**Modify:** profile table, `app_database.dart`/generated, profile payload,
user collection merge, sync store/service/DAO, backup, planner UUID adapter,
router, backend omission allowlist i testy rozszerzeń.

- [x] Ustalić konkretny kodek version1: reguła UUID, plan sync UUID, weekday;
  deterministyczny identyfikator wystąpienia (rule UUID + pierwotny dzień),
  wyjątek moved/completed, referencja session UUID i LWW UTC/tombstone.
- [x] RED dla reguły i pojedynczego przesunięcia, granicy tygodnia/DST,
  braku autozaliczenia i ręcznego zaliczenia tylko sesji z wykonaniem.
- [x] RED dla dwóch urządzeń, stale/deferred CAS, omission/null, backup/restore,
  usunięć reguł/planu/sesji i zachowania już wysłanych payloadów.
- [x] Wprowadzić jedno nullable rozszerzenie profilu bez nowego SyncEntityType;
  migrację wykonywać addytywnie i tylko jednym procesem build_runner.
- [x] Udostępnić tydzień, przypisanie planu, przesunięcie i jawne zaliczenie;
  ponowne użycie istniejącego startu planu bez tworzenia logów.
- [x] GREEN focused schedule + cloud tests i backend sync; zregenerować modele.
  Drift **13**, backend optional `weeklySchedule` zachowywane po hash/CAS;
  [weekly-schedule](../../modules/weekly-schedule.md) i
  [kontrakt API](../../../backend/SYNC_EXTENSIONS.md).
- [x] Naprawić review kwarantanny wszystkich trzech kolekcji profilu: trwały
  hold profilu, niezależny globalny pull, zachowany raw i attempted payload;
  jawne recovery przez API serwisu, nie zwykłą synchronizację ani auto-clear.
- [x] Naprawić browser blocker startu z root overlay i potwierdzić rzeczywisty
  aktywny ekran; RED → GREEN routera, focused **129 PASS**, browser **FIXED PASS**
  dla startu, ręcznego zaliczenia i drugiego pull. Ograniczenie reloadu pozostaje
  jawnie opisane w końcowym raporcie.

## 3. Trendy — właściciel progress, bez zmian zapisów

**Create:** `lib/features/progress/trends/domain/training_trend.dart`, data,
providers i presentation oraz `test/features/progress/training_trend*_test.dart`.
**Modify:** istniejący progress page (punkt wejścia), bez zmiany PR/progresji.

- [x] RED: 0/1/2/3 sesje, missing RPE, różny ciężar/side/variant, deleted/active,
  różna liczba serii i czas pracy vs długość sesji.
- [x] Dodać czysty agregator wyników per session/scope; jawne typy statusu i
  powód wyłączenia próbek, bez arbitralnego mieszania ciężarów i protokołów.
- [x] Dodać wybór ćwiczenia/strony/wariantu i czytelne metryki z datami próbek.
- [x] GREEN focused trends (**28 PASS**) oraz istniejące PR/progression tests
  i końcowa pełna integracja. [training-trends](../../modules/training-trends.md):
  read-only exact scope, 2 sesje = porównanie, ≥3 = trend.

## 4. Akceptacja PWA — osobny harness, bez produkcyjnych zapisów

**Create:** tymczasowy harness w `/tmp/opencode/` i raport
`docs/pwa-offline-acceptance-2026-10-17.md`.

- [x] Uruchomić izolowany origin z prawdziwym workerem i osobnym profilem;
  poczekać na SW controller i odczytać faktyczny cache przed odcięciem.
- [x] Odciąć cały origin i sprawdzić root/deep link/assets, restart procesu,
  lokalny szkic/serię i reconnect z rzeczywistym lokalnym backendem.
- [x] Zapisać rzeczywiste PASS/FAIL/UNTESTED i źródło błędu, nie dogrzewać
  wszystkich zasobów w harnessie i nie przedstawiać tego jako zachowania app.
- [x] Przygotować instrukcję manualnego testu fizycznego telefonu w
  [raporcie PWA](../../pwa-offline-acceptance-2026-10-17.md#ręczna-lista-ios--android--nadal-untested).
  **Hardware MANUAL PENDING:** potrzebne urządzenie/platforma użytkownika,
  dostępny testowy origin i wykonanie checklisty; nie oznaczono próby jako PASS.

Wykonana akceptacja PWA dotyczy **baseline 1.14.0+27, obraz `a212…`**, nie nowych
funkcji. Root po jednej wizycie, `/today` i nieodwiedzone zasoby: **FAIL**.
Warm-cache guided, jawna seria, restart offline i reconnect: **PASS w opisanym
zakresie**. Nie jest to pełna akceptacja offline nowego buildu.

## 5. Integracja i bramki końcowe

- [x] Sprawdzić łącznie start planu, powtórzenie, przesunięcie i świadome zaliczenie;
  żaden odczyt/trend/podgląd nie tworzy set/PR ani nie modyfikuje starej sesji.
- [x] Uruchomić `dart run build_runner build --delete-conflicting-outputs`
  po zakończeniu zmian deklaracji i porównać pliki generated.
- [x] Format zmienionych Dart, `flutter analyze` i `flutter test` przez przypięty
  Docker toolchain; backend `.venv/bin/python -m pytest -q` z PostgreSQL16.
- [x] Niezależna recenzja offline/CAS/backup/backcompat i naprawy TDD;
  brak otwartych HIGH/MEDIUM implementacji. Nie znosi to ograniczeń akceptacji.
- [x] Aktualizować stan planu i raporty bez twierdzeń o telefonie lub produkcji,
  których wykonane testy nie dowodzą. Nowa publikacja wymaga osobnej zgody.

Końcowe dowody właściciela integracji: **17/17 generated bez zmian**,
analyze **0**, Flutter **771 PASS**, backend **378 PASS**, runtime build PASS
([szczegóły i logi](../../training-rhythm-results-2026-10-17.md)).
[Browser report](../../training-rhythm-browser-acceptance-2026-10-17.md) zachowuje
pierwotny FAIL i późniejszy FIXED PASS wraz z osobnym FAIL automatycznego reloadu.

**Przekazanie:** implementacja/testy zakończone lokalnie; znane ograniczenia
reloadu i PWA oraz hardware manual pending są wynikiem integracji, nie mglistym
TODO. Przyszły release wymaga osobnej decyzji i bumpa wersji według AGENTS;
wdrożyć **API przed web**, bez nowej migracji Alembic (pozostaje **0010**).
Katalog, ilustracje, zależności i toolchain bez zmian.
