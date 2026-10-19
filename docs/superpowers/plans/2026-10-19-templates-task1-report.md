# Zadanie 1 — edytor i magazyn szablonów

## Zakres i stan drzewa

Implementacja w `/opt/fit`, na bieżącej gałęzi, bez worktree, subagentów,
commitów, release/version bump, deployu i zapisów produkcyjnych. Zachowane
zastane niezacommitowane zmiany hotfixu 1.16.1. Wspólne pliki routera i
WorkoutHome otrzymały wyłącznie dodatkowe wejście/ścieżki szablonów; istniejący
flow start/recovery hotfixu pozostaje.

Przeczytano AGENTS, working sets training/structured-planner/sync, zatwierdzoną
specyfikację i plan. Nie dodano tabel ani migracji. WorkoutPlans nadal jest
jedynym magazynem szablonów, wspólnym z generatorem. Nie zmieniono backendu,
wire schemaVersion, formatu backupu ani zależności.

## Pliki i zachowanie

- `planner/domain/structured_plan.dart`: opcjonalne `PlanPrescription.weightKg`
  (`double?`), walidacja finite i >= 0. Brak pola w starych danych nadal jest
  poprawny; serializer pomija nieustawione pole, nie dodaje nowej wersji schematu.
- `planner/data/planner_repository.dart`: `snapshot`, `checkTemplate`,
  `updateTemplate`, `deleteTemplate`, `validateTemplate`. Porównanie pełnego
  surowego wiersza Drift, odmowa przy tombstone/braku, deferred dla encji oraz
  push hold/pull quarantine. Edycja/tombstone i nowy outbox są transakcyjne.
  Dotychczasowe attempted operacje nie są przepisywane. Zachowany payload
  DELETE zgodny ze starszym klientem i możliwość usunięcia uszkodzonego wpisu.
- `planner/providers/planner_providers.dart`: `TemplateLease` obejmuje epoch,
  trwały accountId/deviceId/offlineAccess i opcjonalny bazowy WorkoutPlanData.
  `openTemplate` wywoływane przed edytorem/dialogiem; save/delete/start sprawdzają
  ten sam lease w transakcji. `_write` dodatkowo porównuje deviceId po await.
  Guard epoch i bindingu po akcji wycofuje także już wykonane SQL/outbox.
  Pasywna authority nie inicjalizuje HTTP/auth.
- `planner/presentation/pages/templates_page.dart`: lista istniejących planów
  generatora i nowych ręcznych szablonów, nowy/edycja/start/usunięcie. Start i
  usunięcie mają osobne potwierdzenia. Start przechodzi przez `startSaved`,
  ponownie rozwiązuje ID katalogu i nie zastępuje aktywnej sesji/wybranych ćwiczeń.
- `planner/presentation/pages/template_editor_page.dart`: nazwa, wyszukiwanie
  po nazwie/ID (z polskim fold), uporządkowane unikalne ćwiczenia, serie,
  powtórzenia albo łączne sekundy, przerwa, opcjonalne kg, usuń/góra/dół.
  Katalog pokazuje do 20 trafień i wyjaśnia konieczność zawężenia wyszukiwania.
  Zapis/aktualizacja wymagają potwierdzenia. Błędy/conflict nie czyszczą formularza.
  Brak katalogu/metadanych blokuje zapis; brakującego ćwiczenia nie usuwa się
  automatycznie. Zachowane sekcje, transitionSeconds, kryteria, equipment,
  level i warnings istniejącego StructuredPlan. Niezmieniony cel reps zachowuje
  także dokładne wcześniejsze workSeconds.
- `planner/domain/session_template.dart`: czysta konwersja potwierdzonych,
  żywych logów, w kolejności pierwszego wystąpienia ćwiczeń. Tylko dokładnie
  zgodne tracking/cele/kg w grupie. Różne cele, niepoprawne wartości, brak
  metadanych, warianty i strony powodują jawny błąd całej kopii, nie utratę
  niepasujących serii. Przerwy nie są wyliczane z timestampów: początkowo 0,
  z widocznym ostrzeżeniem do ręcznej edycji.
- `planner/presentation/widgets/save_as_template_button.dart`: wspólny przycisk
  kopii, wpięty do SessionSummary. Preferuje dokładny snapshot guidance;
  bez snapshotu korzysta z powyższej konwersji logów. Uszkodzony snapshot nie
  przechodzi po cichu do innego źródła. Przed nawigacją ponownie waliduje lease
  po odczytach async. Samo otwarcie nie zapisuje planu, sesji, logów ani outboxa.
- `app/router.dart`: rzeczywiste `/workout/templates`,
  `/workout/templates/new`, `/workout/templates/:syncId/edit` w istniejącej
  chronionej gałęzi Trening. WorkoutHome: „Moje szablony”.

## Interfejs do zadania 2 i Mentora

```dart
SaveAsTemplateButton(sessionId: sessionId)
SaveAsTemplateButton(initialPlan: selectedExerciseTargets)

context.push('/workout/templates/new',
  extra: TemplateEditorSeed(structuredPlan, name: 'Proponowana nazwa'));
```

`SaveAsTemplateButton` znajduje się pod
`features/planner/presentation/widgets/save_as_template_button.dart`.
`TemplateEditorSeed` jest eksportowany z pliku strony edytora. Seed to wyłącznie
podgląd/kopia, nigdy aktualizacja źródłowego planu lub historii. Aktualizacja
istniejącego szablonu jest dostępna tylko przez osobną ścieżkę z syncId i
potwierdzonym optimistic lease. Zadanie 2 może użyć przycisku dla pustej sesji
z wybranymi ćwiczeniami, przekazując jawne cele jako initialPlan.

**Koordynacja kg:** kg przechodzą przez model, backup/outbox/pull i snapshot
guidance. Nie zmieniano kart aktywnego treningu ani repeat/guidance formularzy,
aby nie wejść w pliki wykonania zadania 2. Ich domyślny ciężar należy ustawić
z `guidance.plan.blocks[slot].prescription.weightKg` tylko gdy brak własnego
szkicu/formularza; nigdy nie nadpisywać użytkownikowi już wpisanego ciężaru.

## Świadome ograniczenia modelu

- Jeden zestaw celów na ćwiczenie. Brak ukrytej redukcji wariantów/stron lub
  różnych dawek z historii; takie przypadki wymagają ręcznego ułożenia.
- Edytor obsługuje reps/time zgodne z metadanymi. Inne tracking, np. rounds,
  mają wyjaśnienie odmowy zamiast wymyślonej konwersji.
- Prawdziwy legacy plan bez structure nadal jest widoczny i może wystartować
  bez guidance. Edytor wyjaśnia brak celów i prosi o utworzenie nowego szablonu,
  nie przypisuje fikcyjnych dawek istniejącemu rekordowi.
- Estymata to suma bloków, 3 s/powtórzenie i obie strony zgodnie z metadata.
  Budżet pozostaje 5–90 min; krótki szablon nie jest sztucznie wydłużany do 5 min,
  a ponad 90 min powoduje błąd zamiast clampowania estymaty. Min. 5 min dotyczy
  pola budgetSeconds, nie faktycznej sumy pracy. Komunikaty jawnie mówią
  „ESTYMOWANY”.
- Formularz jest zachowywany przy konflikcie, nie jest nowym trwałym szkicem
  edytora. Zamknięcie strony nie wykonuje automatycznego zapisu.

## Testy i faktyczne wyniki

Wszystkie narzędzia Flutter uruchamiano w obrazie z polecenia zlecenia:

```sh
docker run --rm --network none -v /opt/fit:/app -w /app \
  fit-web:release-1.13.0-26-verified flutter test --no-pub ...
```

Nowe pliki testów: `manual_templates_test.dart` (8),
`session_template_test.dart` (2), `templates_widgets_test.dart` (3), razem **13**.

Pokrycie: realny Drift/outbox create/edit/delete, optimistic stale snapshot,
attempted bytes, rzeczywisty reopen pliku SQLite, backup/restore/pull z kg,
stary schema1 bez kg i niepoprawne kg, brak efektów wykonania, nowy UUID startu
i niezmieniony snapshot sesji po edycji/usunięciu źródła, deferred/push hold/pull
quarantine, symulowana zmiana epoch A–B–A, device rotation/offline lock,
rollback po await repozytorium, konwersja żywych grup logów oraz odmowa
nieobsługiwanych/niejednolitych danych. UI: prawdziwy createRouter, lista →
nowy → wyszukiwanie → dodawanie → reorder → save → edit; konflikt deferred
z zachowaniem formularza, istniejąca aktywna sesja chroniona po potwierdzeniu
Start, cancel/confirm delete i zachowana aktywna sesja; rzeczywista nawigacja
z podsumowania do edytora z dokładnym snapshotem bez nowych zapisów;
320 px/text200% przewijanie edytora bez overflow.

RED: pierwszy focused test nie kompilował się z powodu brakujących API
updateTemplate/deleteTemplate. Po implementacji GREEN. Pierwsze uruchomienie
widget testów wykryło błędne założenia testu o URI imperative push i wybranie
wewnętrznego Scrollable TextField; poprawiono test, nie produkcyjny routing.

Faktycznie uruchomione:

1. Wszystkie `test/features/planner`, `test/app/router_test.dart`, istniejący
   hotfix `test/features/workout/catalog_session_continuity_test.dart`:
   **128 passed** przed dodaniem ostatniego testu kopii z podsumowania.
2. Nowe testy domenowe/persistence i UI: **12 passed**, następnie ostateczny
   komplet testów UI po dodaniu kopii z podsumowania: **3 passed**. Wszystkie
   13 nowych przypadków przeszły; nie deklarujemy ponownego pełnego przebiegu
   129 testów po ostatnim dodaniu.
3. Ostateczne `flutter analyze --no-pub`: **No issues found**.
4. `dart run build_runner build --delete-conflicting-outputs`: sukces,
   wygenerowane pliki śledzone bez końcowego diffu. Pierwsze uruchomienie
   przerwał timeout 120 s; ponowiono z większym limitem i zakończono poprawnie.
5. Format ograniczony do własnych plików/wspólnych plików wejścia;
   `git diff --check` bez błędów.

W testach dwóch niezależnych baz Drift występuje znane ostrzeżenie debug
o wielu AppDatabase; nie są współdzielonym executorem i testy przechodzą.
Nie wykonano pełnego Flutter suite, testu przeglądarkowego/PWA, backend suite,
nowego obrazu release ani wdrożenia.

## Web SQLite

Lock bez zmian: drift **2.28.2**, sqlite3 **2.9.4**. Artefakty bez zmian;
SHA-256 zgodne z wartościami oficjalnych wydań zapisanymi w working set:

- sqlite3.wasm: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- drift_worker.dart.js: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

## Handoff/review

Wspólne zmiany zadania 1: router, WorkoutHome (jeden przycisk), SessionSummary
(import + jeden przycisk), planner workflow. Nie zmieniano aktywnej sesji,
repo treningów, recovery, repeat ani finish. Przed integracją zadania 2 warto
ponowić szerszy workout/repeat/schedule suite i całość analyze/test. Wersja,
changelog i dokumenty hotfixu należą do zastanego diffu, nie do tego zadania.

## Review P2 — ograniczenia liczb przed arytmetyką

Potwierdzono RED na natywnym Dart: `sets=4611686018427387904`, praca 4 s,
przerwa 0 s i przejście 15 s dawały przez przepełnienie `totalSeconds == 15`.
Niepoprawny incoming plan był wcześniej przyjmowany jako poprawny wiersz.

Poprawka ograniczona do walidacji liczb modelu, odpowiadającej jej walidacji
formularza i regresji:

- `PlanPrescription.validate()` sprawdza operandy **przed mnożeniem i odejmowaniem**.
  Serie/praca: 1..5400; przerwa/przejście: 0..5400; powtórzenia: 1..1800
  (90 min przy co najmniej 3 s/powtórzenie). Pozostaje walidacja finite >=0 kg.
  Wywołania zarówno w `fromJson`, jak i `totalSeconds` chronią incoming dane
  oraz obiekty utworzone bezpośrednio przez konstruktor. Typy całkowite pól
  są nadal wymagane; liczby ułamkowe/nieskończone i ogromne double są odrzucane
  przez istniejący normalizowany trust boundary jako FormatException.
- Generator pomija rozpoznaną dawkę przekraczającą te limity zamiast zamieniać
  ją na mniejszy fallback; replace toleruje brak zgodnej dopuszczalnej dawki.
  Poprawna rozpoznana dawka ponad budżet nadal jest pomijana, nie skracana.
- Formularz pokazuje przy polach „Maksymalnie … (limit szablonu: 90 min)”.
  Serie/sekundy/przerwa mają maks. 5400, reps maks. 1800 lub 900 dla
  jednostronnego ćwiczenia, aby także estymata obu stron mieściła się w limicie.
- Złośliwe surowe incoming nadal przechodzi istniejącą ścieżką kwarantanny:
  zachowuje oryginalny raw envelope, nie tworzy poprawnego planu ani outboxa.

Dodano `plan_numeric_bounds_test.dart` (5 testów) oraz jeden test inline UI.
Pokrycie obejmuje natywne przepełnienie, wartości graniczne JS 2^53-1/2^53,
int64 max, 1e100, infinity/NaN, ułamki, wszystkie pola całkowite, limit reps,
dokładnie 90 min, prawidłowe maksymalne operandy, dotychczasowy fixture,
quarantine z zachowaniem raw oraz generator/replace bez pozornego dopasowania.
Przypadki wielkich liczb JS sprawdzono w danych wejściowych testów natywnych;
nie uruchamiano nowego testu w przeglądarce/kompilacji JS.

Faktyczna weryfikacja po ostatecznej poprawce (ten sam Docker, network none):
`flutter test --no-pub --reporter expanded test/features/planner` —
**115 passed**; `flutter analyze --no-pub` — **No issues found**;
format ograniczony do zmienionych plików i `git diff --check` — OK.
Log: `/tmp/opencode/templates-p2-final.log`. Bez zmiany pól JSON, schematu,
zależności, SQLite artefaktów, wersji, migracji ani deployu; ponowne generowanie
artefaktów nie było wymagane dla samej zmiany walidacji.

## Final review — lease źródła i aktualizacja istniejącego szablonu

- `SaveAsTemplateButton` przenosi dokładny lease sprzed odczytu sesji do
  `TemplateEditorSeed`. Edytor nie przechwytuje ponownie konta; sprawdza lease
  przed wypełnieniem formularza. Zmiana epoch (również A–B–A) lub trwałego
  powiązania cache usuwa prywatne pola i blokuje zapis. Pasywny listener epoch
  nie inicjalizuje auth/HTTP przy kopiowaniu lokalnego treningu.
- Po poprawnym wyprowadzeniu celów użytkownik wybiera „Nowy szablon” albo
  istniejący szablon w sekcji „Zaktualizuj istniejący”. Snapshoty docelowych
  szablonów powstają transakcyjnie w workflow pod oryginalnym lease źródła;
  niedostępne, legacy, deferred i quarantined wpisy nie są oferowane.
- Wybrany istniejący szablon zachowuje nazwę/UUID, ale edytor celowo pokazuje
  odłączoną strukturę treningu, nie stare cele szablonu. Odrębny `updateLease`
  nie zmienia zwykłej ścieżki edycji. Dopiero potwierdzenie zapisu zastępuje
  cele; dialog wyjaśnia brak zmian historii. Zmiana docelowego snapshotu po
  otwarciu odmawia zapisu i zachowuje formularz. Podgląd/anulowanie nie zapisują.
- Uszkodzony snapshot sesji i cele spoza reps/time kończą się jawną odmową,
  bez częściowego kopiowania lub oferowania aktualizacji.

Weryfikacja na bieżącym `/opt/fit`, obraz
`fit-web:release-1.13.0-26-verified`, `--network none`:
`flutter test --no-pub` dla `templates_widgets_test.dart`,
`manual_templates_test.dart`, `session_template_test.dart`,
`mentor_templates_test.dart` i `session_execution_widgets_test.dart` —
**34 passed**. Pokrycie nowych regresji: zmiana konta dokładnie między finalnym
odczytem a init edytora, A–B–A po otwarciu, session→existing save/stale/cancel,
nieobsługiwane źródła oraz blokady listy docelowej deferred/quarantine.
`flutter analyze --no-pub`: **No issues found**; format i `git diff --check`: OK.
Logi: `.dart_tool/finalreview-focused.log`, `.dart_tool/finalreview-analyze.log`.
Bez zmian deklaracji Drift/Freezed/JSON, generator niewymagany. Lock i SHA-256
Web SQLite ponownie sprawdzone: zgodne z sekcją powyżej. Bez commitów, release,
wdrożenia i nowego pełnego suite.
