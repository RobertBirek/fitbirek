# Warunki wykonania i pozycje — etap 5, klient

## API i format

- `ExerciseCatalogMetadata.conditions/positions`: mapy `ExerciseCatalogTag`
  (`id`, `label`, `aliases`). `ExerciseCatalogEntry.conditions/positions`:
  listy ID. Sidecar nadal ma `schemaVersion: 1`; oba słowniki root i obie listy
  wpisu są opcjonalne. Brak pola oznacza pusty zbiór/listę, nie potwierdzenie
  zgodności ćwiczenia. Nieprawidłowy typ obecnego pola odrzuca indeks.
- `ExerciseFilters.conditions/positions`: `Set<String>`, domyślnie puste;
  `copyWith`, `activeCount`, `isEmpty` i reset UI uwzględniają oba kryteria.
  `hasExecutionFilters` wskazuje aktywne warunki lub pozycje.
- `ExerciseFilterEngine.filter`: **wszystkie warunki naraz (AND)**,
  **dowolna wybrana pozycja (OR)**. Między grupami, query, poziomem i ulubionymi
  pozostaje AND; stare OR dla stylów/mięśni/sprzętu bez zmian. Pozycje nie są
  rozłączne. Nie wnioskujemy oznaczeń z nazw, diagnoz ani własnych ćwiczeń.
- `facets.conditions[X]` liczy wynik dla `conditions ∪ {X}` wraz z pozostałymi
  filtrami. Nie pomija całej grupy warunków. `facets.positions` pomija tylko
  własną grupę OR. Liczniki deduplikują ID; arkusz obserwuje bieżący katalog.
- Query przeszukuje także ID, etykiety i aliasy warunków/pozycji wpisu,
  z dotychczasowym składaniem znaków i AND tokenów.
- `FilterPreset.encodeFilters/decodeFilters` dodaje `conditions` i `positions`
  jako listy stringów. Stare presety dekodują brak jako puste zbiory.
  Nieznane poprawnie typowane ID pozostają zapisane i widoczne do usunięcia.
  Ten sam kodek przenosi kryteria w `StructuredPlan`; bez zmiany wersji wire.

## Brak danych, UI i granice znaczenia

`executionMetadataAvailable` jest niezależne od legacy
`classificationAvailable`. Provider nie używa poprzednich danych jako dowodu
warunków podczas loading/error odświeżenia. `executionFiltersVerified` wymaga
dostępnego indeksu i definicji wybranych warunków; dla pozycji OR wystarczy
rozpoznana alternatywa. Stary indeks bez nowych słowników jest odczytywalny,
ale nie weryfikuje tych kryteriów. Wynik przy braku weryfikacji jest pusty,
z komunikatem w UI, nie szerszym fallbackiem. Dotychczasowe zachowanie filtrów
stylu/mięśni przy niedostępnej klasyfikacji pozostaje bez zmian.

Brak oznaczeń we wpisie, także ćwiczenia własnego, nie spełnia aktywnych wymagań.
Chipy wybrane (również nieznane i z licznikiem 0) pozostają usuwalne. Stałe
etykiety PL służą tylko prezentacji wyborów przy braku indeksu, nie klasyfikacji.

Warunki: `no_jumps`, `quiet`, `no_kneeling`, `no_hand_support`, `no_floor`,
`small_space`. Pozycje: `standing`, `seated`, `floor`, `hanging`, `bench`.
„Cichy trening” oznacza względnie mały impakt, **nie gwarancję akustyki**.
„Mało miejsca” oznacza stacjonarne wykonanie bez przemieszczania; trzeba
osobno zmieścić wymagany sprzęt. Nie są to zalecenia medyczne ani gwarancja
bezpieczeństwa.

`StructuredPlanGenerator.candidates` odrzuca nieweryfikowalne kryteria przez
`StateError`. Generacja i zamiana nadal korzystają z tego samego silnika;
żadna sekcja nie otrzymuje kandydatów spoza aktywnych filtrów.

## Zakres weryfikacji

Nowe fixture/testy: `execution_filters_{test,provider_test,widgets_test}.dart`.
Obejmują AND/OR, cross-facets, query, stan loading/error i stary indeks, live
katalog, usuwanie selected-zero, reset, kodek i ograniczenia planera.
Rozszerzony test restartu repo presetów sprawdza oba nowe pola i nieznane ID.
Wyniki poleceń opisane w raporcie końcowym zadania.

### Weryfikacja po wznowieniu — 2026-10-16

Nie przepisywano implementacji. Dodano dwa testy do
`catalog_asset_integration_test.dart`: parser Dart ładuje rzeczywiste assets,
sprawdza dokładnie 363/363 ID, sześć warunków, pięć pozycji, referencje każdego
wpisu, niepuste wyniki każdego kryterium i zgodność AND/OR oraz obu faset
z jawnymi oznaczeniami wpisów. Testy nie dowodzą prawdziwości redakcyjnej
klasyfikacji ruchów — to zakres audytu agenta danych.

Obraz: `fit-web:catalog-expanded-verified`, ID
`sha256:235818d883dd7a18153a99b772b95849ccf6be1310048fb020b0f5912d5e8db1`.
`flutter --version`: Flutter 3.35.4 / Dart 3.9.2. Aktualne drzewo `/opt/fit`
zamontowano jako `/source:ro` i skopiowano do `/tmp/fit`; nie testowano starego
kodu `/app` z obrazu. Przygotowanie: `flutter pub get --offline --enforce-lockfile`.
Poniższe polecenia wykonano przez
`docker exec -w /tmp/fit fit-execution-filters-check ...`:

```bash
flutter test --no-pub --reporter expanded \
  test/features/exercises/execution_filters_test.dart \
  test/features/exercises/execution_filters_provider_test.dart \
  test/features/exercises/execution_filters_widgets_test.dart \
  test/features/exercises/filter_presets_repository_test.dart \
  test/features/exercises/filter_presets_provider_test.dart \
  test/features/exercises/filter_presets_widgets_test.dart \
  test/features/exercises/catalog_filter_test.dart \
  test/features/exercises/catalog_widgets_test.dart \
  test/features/exercises/catalog_asset_integration_test.dart \
  test/features/planner/structured_plan_test.dart
# +58: All tests passed! (35 s)

flutter analyze --no-pub
# No issues found! (63.7 s)

dart format --output=none --set-exit-if-changed \
  lib/features/exercises/domain/exercise_catalog_metadata.dart \
  lib/features/exercises/domain/exercise_filter_engine.dart \
  lib/features/exercises/domain/filter_preset.dart \
  lib/features/exercises/providers/exercises_providers.dart \
  lib/features/exercises/presentation/pages/exercises_list_page.dart \
  lib/features/planner/domain/structured_plan.dart \
  test/features/exercises/execution_filters_test.dart \
  test/features/exercises/execution_filters_provider_test.dart \
  test/features/exercises/execution_filters_widgets_test.dart \
  test/features/exercises/filter_presets_repository_test.dart \
  test/features/exercises/catalog_asset_integration_test.dart
# Formatted 11 files (0 changed).
```

`git diff --check`: bez błędów. Lockfile i oba artefakty Web SQLite są bez
zmian względem repozytorium; dodatkowo `cmp` potwierdził identyczność lockfile,
`web/sqlite3.wasm` i `web/drift_worker.dart.js` z parą z obrazu weryfikacyjnego.
Nie zmieniano deklaracji generowanych modeli, nie uruchamiano generatora.

Ograniczenia: w `catalog_widgets_test.dart` występują ostrzeżenia debug Drift
o wielu instancjach `AppDatabase`; nie spowodowały błędów testów, nie wyciszano
ich i nie zmieniano bazy w tym zadaniu. Nie uruchamiano pełnych zestawów
Flutter/Python/backend ani pełnego Docker build; wynik 37 testów Python
pochodzi z przekazanego raportu agenta danych. Bez commit/push/deploy.

Narzędzia: Docker Flutter 3.35.4 / Dart 3.9.2; aktualne `/opt/fit` montowane
read-only, testy/analyze na kopii `/tmp/fit`. Format tylko plików tego zadania.
Bez zmian deklaracji Drift/Freezed/json_serializable, więc bez generatora.
Bez zmian locka, wersji, Web SQLite, backendu, workoutu, timera i profilu.
Dane sidecara, generator danych i audyt oznaczeń są osobnym zadaniem agenta
danych — testy klienta nie dowodzą prawdziwości wszystkich oznaczeń katalogu.
Bez pełnego Flutter suite, backend tests, full Docker build, release i deploy.
