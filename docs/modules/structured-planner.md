# Working set: Generator z filtrów (etap 4)

> Aktualizacja zamienników, przerw i edycji czasu: obowiązuje
> [planner-safe-replacements.md](planner-safe-replacements.md).
> Zastępuje opisane niżej historyczne stałe 30 s i wymóg identycznego czasu zamiany.

## Pliki i wejście

- `lib/features/planner/domain/structured_plan.dart`: czysty silnik, model i kodek.
- `lib/features/planner/{data,providers,presentation}/`: repo, workflow i podgląd.
- `exercises_list_page.dart`: jeden przycisk **Ułóż trening z tych ćwiczeń**.
  Przenosi kopię kryteriów przez `plannerEntryCriteriaProvider` do istniejącego
  `/settings/planner`. Router i publiczne ścieżki pozostają bez zmian.
- `PlanGenerator.generate` jest niezmienionym API legacy, z dotychczasowymi testami.
- Nowe API: `StructuredPlanGenerator.generate`, `candidates`, `replace`.
  Generacja przyjmuje aktualne `allExercises`, shared `ExerciseFilterEngine`,
  snapshot `ExerciseFilters`, cały sprzęt profilu, poziom i minuty 5..90.
  Nie przyjmuje utrwalonej listy wyników katalogu ani ID presetu.

## Reguły wyboru i czasu

Kandydaci = wynik shared engine AND `ex.sprzet.every(equipment.contains)` AND
poziom nie wyższy od wybranego. Rank jawny: Początkujący / Średni / Zaawansowany;
nieznany poziom nie jest uznawany automatycznie za początkujący.
Jawne filtry stylu lub mięśni przy niedostępnej klasyfikacji rzucają `StateError`.
Etap 5: także aktywne warunki/pozycje bez weryfikowalnych metadanych blokują
`candidates`; oba kryteria utrwala istniejący kodek presetów. Szczegóły:
`docs/modules/exercise-execution-filters.md`.
UI czeka także na aktualny katalog/metadane zamiast generować szerszy plan.
Ćwiczenia bez metadanych tracking są pomijane z jawnym ostrzeżeniem.

Sekcje: `Rozgrzewka` (typ rozgrzewka), `Schłodzenie` (rozciąganie/stretching),
pozostałe typy jako `Praca`, także joga, mobilność i regeneracja. Dobór odbywa się
wyłącznie w aktywnej puli, również w sekcjach pomocniczych. Brak sekcji daje
ostrzeżenie, nie fallback do całego katalogu. Najpierw rezerwowane są po jednym
bloku pomocniczym, potem do 8 bloków pracy. Ranking premiuje nowy wzorzec ruchu
(pierwszy człon pola `wzorzecRuchu`) i nowe mięśnie, następnie niższy poziom i ID.
Nie powiela wzorca pracy, jeśli nie wnosi już nowych mięśni. Jest deterministyczny
i niezależny od kolejności wejściowej; nie jest klinicznym ani indywidualnym
doborem obciążeń.

Domyślne prescriptions: praca 3 serie, 10 powt. lub 40 s, odpoczynek 30 s;
sekcja pomocnicza 1 seria, 6 powt. lub 30 s, odpoczynek 0 s. Każdy blok ma 15 s
przejścia. Dla `reps` przyjęto jawnie **3 s/powt.**; dla ćwiczeń jednostronnych
czas pracy jest podwojony (obie strony). `workSeconds` oznacza czas jednej serii.

`totalSeconds = sets * workSeconds + (sets - 1) * restSeconds + transitionSeconds`.
`estimatedSeconds` jest sumą bloków, nie wybranym budżetem. Suma nie przekracza
`budgetSeconds`; silnik nie rozciąga sztucznie krótkiej puli do wybranego czasu.
UI wyświetla **Czas ESTYMOWANY**, budżet i wszystkie składowe prescriptions.
5 minut może nie wystarczyć na żaden blok: wynik pusty i ostrzeżenie, bez zapisu.

`replace` ponownie filtruje aktualny katalog według zapisanych kryteriów,
wyklucza wszystkie użyte ID, wymaga tej samej sekcji, tracking i łącznego czasu.
Przelicza prescription dla nowego ćwiczenia; nie zmienia pozostałych obiektów
bloków. Jeśli brak zgodnego zamiennika, zwraca `null`, UI wyjaśnia odmowę.

## Dokładny format utrwalania

Drift **9 → 10**: wyłącznie nullable `WorkoutPlans.structureJson` /
`workout_plans.structure_json TEXT`. Bez backfillu, stare shallow plany mają NULL.
`SavedPlan.structure` to `StructuredPlan?`. Nie tworzymy celów z legacy samych ID.
Repo wymaga zgodności uporządkowanego `cwiczeniaIds` z ID bloków struktury.

Wire `workoutPlan.payload` zachowuje stare pola `nazwa`, `cwiczeniaIds`, `cel`,
`dataUtworzenia`; dodaje opcjonalne **`structure` (mapa JSON, nie string)**:

```json
{
  "schemaVersion": 1,
  "criteria": {
    "styles": ["yoga"],
    "muscles": [],
    "sprzet": [],
    "typy": [],
    "partie": [],
    "poziomy": [],
    "tylkoUlubione": false,
    "query": "",
    "sortBy": "alfabetycznie"
  },
  "budgetSeconds": 300,
  "level": "Średni",
  "equipment": ["Mata"],
  "blocks": [{
    "exerciseId": "cw317",
    "section": "main",
    "prescription": {
      "tracking": "time",
      "sets": 2,
      "reps": null,
      "workSeconds": 40,
      "restSeconds": 20,
      "transitionSeconds": 15
    }
  }],
  "warnings": ["Brak rozgrzewki w aktywnej puli."]
}
```

Dozwolone `section`: `warmup|main|cooldown`; tracking: `reps|time|rounds`.
`reps` jest dodatnim int tylko dla `reps`, w innych metrykach null.
`sets >= 1`, `workSeconds >= 1`, przerwa/przejście >= 0. Nie zapisujemy osobno
sumy estymacji — jest wyliczana, więc nie może rozjechać się z blokami.

`SyncStore.apply`: optional wire map → lokalny JSON string lub NULL przy braku.
`enqueueAll`: JSON string → optional mapa; brak pola dla shallow planu.
Backup v2 już eksportuje/importuje wiersze przez wygenerowane kodeki Drift:
zachowuje nullable `structureJson`, bloki i wszystkie kryteria bez zmiany formatu
backupu. Nowe operacje restore zachowują strukturę. Nie przepisujemy żadnego
starego attempted payloadu. Backend ma generyczny JSONB, bez zmian usług/Alembic.

## Podgląd, zapis, start

Podgląd nie inicjalizuje HTTP/auth ani repo presetów i niczego nie zapisuje.
Zapis i start mają osobny dialog potwierdzenia. Przed akcją UI ponownie sprawdza
aktualne ćwiczenia, filtry, ulubione i profil — nie usuwa po cichu brakujących ID.
Wczytanie structured planu odtwarza dokładne bloki, kryteria i wybrany poziom,
bez ponownej generacji. Legacy historia jawnie opisuje brak sekcji i celów.

`PlannerWorkflow.save/start` sprawdza pasywny `cachedAuthWriteAuthorityProvider`,
epoch i stan cache konta w transakcji. Start wywołuje istniejące
`ActiveWorkoutNotifier.startSession` i `addExercise`, nie osobny serializer sesji.
Istniejący start otrzymał guard generacji/auth oraz transakcyjny account guard
repozytorium. Wylogowanie lub discard podczas await wycofuje sesję i outbox.
Nie zastępujemy bieżącej aktywnej sesji ani wybranych już ćwiczeń.

Cele pozostają jawne w podglądzie i zapisanej strukturze; karty aktywnej sesji
nie dostają automatycznych targetów. Serie użytkownik zapisuje sam. Timer,
PR, repo presetów, metadane, narzędzia katalogowe i sprzęt pozostają bez zmian
funkcjonalnych. Nie wykonano release/version bump/deploy/full Docker build.

## Weryfikacja 2026-10-16

- Docker uruchomieniowy narzędzi: Flutter 3.35.4 / Dart 3.9.2, bind-mount
  **aktualnego `/opt/fit`**, bez kopii drzewa i bez pełnego Docker build.
- `dart run build_runner build --delete-conflicting-outputs`: zakończony;
  wygenerowana zmiana `app_database.g.dart`, bez zmian modeli Freezed.
- 16 nowych testów Fluttera: 8 domain, 3 persistence, 3 workflow, 2 widget.
  Realny katalog i metadata po 363 rekordy: joga/regeneracja przy każdym budżecie
  5..90, zgodność kandydatów i suma czasu; filtry, all-equipment, rank/diversity,
  zamiana, brak puli, za krótki czas, brak metadanych; migracja, attempted bytes,
  backup/restore/pull/outbox; potwierdzenie save/start i anulowanie async startu.
- Pełny Flutter: **459 passed** (wcześniejsze 443 zachowane); analyze: bez uwag;
  app version check: OK. Format wykonany; niezwiązane zmiany formatu Mentora
  usunięte, aby zachować zakres etapu.
- Backend focused sync: **37 passed**; pełny backend: **342 passed**.
- Lock, wersja i Web SQLite niezmienione. SHA-256 zweryfikowane względem
  oficjalnych wydań: sqlite3-2.9.4 `sqlite3.wasm`:
  `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`;
  drift-2.28.2 `drift_worker.js` (lokalnie `drift_worker.dart.js`):
  `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`.
- Pełny Flutter zgłasza istniejące ostrzeżenia debug Drift o wielu instancjach
  baz w testach katalogu; nie są błędami testów ani komunikatami analyze.
- Brak nowego testu przeglądarkowego/PWA i wdrożenia; testy UI są widget tests.
  Czasy są świadomym uproszczeniem, nie gwarancją rzeczywistej długości sesji.

## Poprawka po review: walidacja granic i izolacja uszkodzonej historii

Repro (TDD) potwierdziło, że `SyncStore.apply` zapisywał `structure: {}` jako
`structureJson = '{}'`. Odczyt wszystkich planów kończył się wtedy wyjątkiem,
a błędny pull utrwalał stronę i przesuwał kursor. Tak samo brakowało walidacji
przy tworzeniu nowych operacji restore/outbox.

Poprawka nie zmienia Drift 10, tabel, wire schemaVersion 1, generatora ćwiczeń,
warunków ani progresji. Nowe API domeny:

```dart
StructuredPlan.validateJson(Object? value, {required Object? exerciseIds})
```

Sprawdza serializowalność JSON, mapę, `StructuredPlan.fromJson`, kryteria i
zgodność uporządkowanych ID z blokami. Błędy typów/wartości są normalizowane
do `FormatException`, nie do awarii castu. Nieobsługiwany schemat, nieznane
pola kryteriów, niepoprawne `sortBy` lub jawne null kryterium są odrzucane,
nie pomijane. Brak opcjonalnych pól dawnych kryteriów nadal oznacza ich
domyślne wartości. Obecne `conditions`/`positions` oraz ich ID są zachowane.

- `apply` waliduje strukturę przed zapisem wiersza, aktualizacją wersji lub
  deferred snapshot, także gdy istnieje attempted operacja. Błąd strony pull
  powoduje rollback wszystkich jej wierszy i kursora; poprawiona strona może
  zostać ponowiona bez utraty wcześniejszej historii.
- `enqueueAll` działa transakcyjnie i waliduje nowe live payloady. Istniejąca
  transakcja restore obejmuje tę walidację, więc nieprawidłowy backup wycofuje
  cały import. Nigdy nie naprawiamy ani nie przepisujemy attempted bytes.
- `PlannerRepository.watchAll` izoluje błąd do pojedynczego `SavedPlan`.
  Dodane pola: `String? structureError`, `String? rawStructureJson` i getter
  `bool isUnavailable`. Uszkodzony lub nieobsługiwany wpis ma `structure == null`
  **oraz** jawny błąd; nie jest to plan legacy. Surowy wiersz nie jest zmieniany.
  Pozostałe plany są nadal dostępne.
- UI pokazuje „Plan niedostępny — uszkodzone dane lub nieobsługiwana struktura.
  Możesz usunąć ten wpis.”, blokuje otwarcie podglądu (a więc start/wymianę),
  lecz pozostawia przycisk usunięcia. Prawdziwe legacy NULL zachowuje dotychczasową
  obsługę bez oznaczenia błędu i bez dopisywania fikcyjnych prescriptions.
- `deletePlan` i planowe tombstone’y `enqueueAll` zachowują kopertę legacy
  (`nazwa`, lista `cwiczeniaIds`, `cel`, `dataUtworzenia` UTC ISO), bez pola
  `structure` i bez dekodowania `structureJson`. Uszkodzona lista ID daje `[]`
  wyłącznie w kopercie usunięcia, nigdy jako naprawa surowego planu.
  `apply` przy usunięciu zachowuje surowe dane istniejącego wiersza i zmienia
  metadane usunięcia. Nieznany lokalnie tombstone nadal nie tworzy wiersza.

Weryfikacja na aktualnym `/opt/fit`, Docker Flutter 3.35.4 / Dart 3.9.2:

- 22 nowe testy: repro mapy `{}`, przyszłego schematu, non-map, złych typów,
  sekcji i kryteriów; niespójne ID; rollback strony/kursora i retry; dirty/deferred;
  rollback nowego outboxa i restore z ochroną attempted bytes; 5 postaci istniejącego
  raw uszkodzenia; usunięcie i odbiór tombstone’a; zachowanie conditions/positions;
  widget dostępnej historii i usuwania niedostępnego wpisu bez startu/wymiany.
- Pełny Flutter: **546 passed** (524 dotychczasowe + 22); analyze: **bez uwag**.
- Pełny backend: **342 passed**; pipeline katalogu/conditions: **37 passed**
  (`/tmp/opencode/catalog-venv/bin/python -m unittest
  tools.tests.test_catalog_pipeline tools.tests.test_execution_conditions`).
  Systemowy Python nie ma openpyxl — użyto istniejącego izolowanego venv.
- Format tylko plików poprawki; app version check i `git diff --check` OK.
  Bez zmian deklaracji Drift/Freezed/json_serializable — generator niewymagany.
  Lock i Web SQLite bez zmian. Bez commit/version/release/deploy/full Docker build.

### Kolejny review: zgodność DELETE z klientem 3397b83

Powyższy wynik pełnego zestawu 546 dotyczy stanu przed tą korektą DELETE.
`git show 3397b83:lib/core/sync/sync_store.dart` potwierdził, że starszy klient
parsuje cztery wymagane pola planu także dla istniejącego tombstone’a. Pusty
payload powodował rollback pull/kursora starego odbiorcy.

Wspólny builder `workoutPlanDeletePayload(WorkoutPlanData)` w
`lib/features/planner/data/plan_sync_payload.dart` przywraca wymaganą kopertę
dla **nowych** operacji repo/delete oraz `enqueueAll` (restore i tombstone’y).
Nie odczytuje `structureJson`, nie dodaje `structure`, nie zmienia raw danych.
Fallback `cwiczeniaIds: []` dotyczy tylko uszkodzonego JSON/listy ID w DELETE.
Pozostałe pola są kopiowane z wiersza; tożsamość sync i baseVersion bez zmian.
Walidacja nowych live struktur i rollback pozostają bez osłabienia.

Istniejące attempted operacje, także dawne DELETE z `{}`, pozostają dokładnie
niezmienione — poprawka nie naprawia ich historycznych payloadów. Nowy klient
nadal toleruje takie incoming tombstone’y dla istniejących wierszy.

TDD: 13 nowych regresji początkowo nie przechodziło z powodu pustej koperty;
osobny test-repro pokazuje blokadę kursora dla starego pustego payloadu.
Dodano łącznie 14 testów Fluttera: repo / `enqueueAll(deleted: true)` / lokalny
tombstone × poprawna struktura, uszkodzona struktura, zły JSON ID, mieszane ID;
minimalny kontrakt starego parsera z zapisem snapshotu i kursora w transakcji;
restore z zachowaniem attempted `{}` bajt w bajt i nową poprawną kopertą.
Backend ma dwa testy generic JSONB live→delete→retry→pull, zachowujące wszystkie
cztery pola, dla normalnej listy ID i fallbacku `[]`. Usługi backendu bez zmian.

Weryfikacja: focused Planner/SyncStore/backup **106 passed**, `flutter analyze`
**bez uwag**; backend focused `tests/test_sync.py`: **39 passed** (w tym dwa nowe
roundtripy DELETE). Format tylko plików korekty. Pełny Flutter/build/release ma ponowić
main; nie uruchamiano ich w tej korekcie. Bez migracji DB, zmiany wersji i deployu.
