# Podstawowe ćwiczenia bez obciążenia — katalog431

## Working set

- `tools/bodyweight_additions.py`: jawne cw425–cw431, autorskie wskazówki,
  odczytane źródła HTTPS, osobno zakres źródła i adaptacje redakcyjne.
- `tools/expand_bodyweight_catalog.py [--check]`: append-only XLSX, nazwy,
  warunki, źródła i redakcyjny sidecar EN. Potem `xlsx_to_json.py`, `build_catalog_metadata.py`
  oraz `backend/tools/generate_mentor_catalog.py`.
- `tools/source_data/`: XLSX i wersjonowane wejścia; `assets/data/`: surowy
  eksport, metadata i nadal ten sam manifest sześciu korekt.
- `tools/source_data/bodyweight_instructions_en.json`: pełne autorskie opisy
  EN siedmiu pozycji (nazwa, opis ruchu, wskazówki, błędy, tempo, dawka startowa,
  progresja i regresja), odtwarzane z `INSTRUCTIONS_EN` w
  `tools/bodyweight_additions.py` przez ten sam appender; `--check` odrzuca
  brak lub nieaktualny plik bez zapisu. To wersjonowany materiał redakcyjny,
  nie asset runtime: aplikacja nadal pokazuje instrukcje PL. Nie dodawaj pól
  do `Exercise`, wire, UI ani migracji, by przechować ten materiał EN.
- `exercise_illustrations.dart`, `exercise_detail_page.dart`: rejestr431 obrazów,
  w tym własne ilustracje cw425–cw431; pusty publiczny zbiór
  `awaitingIllustrationExerciseIds` pozostaje zgodny z ekranem szczegółów.
  Integracja2026-10-29: siedem assetów dostarczono i niezależnie oceniono
  wizualnie; testy wymagają dokładnych zbiorów i dekodowania431 obrazów512×512.
- Testy: `tools/tests/test_bodyweight_expansion.py`,
  `test/features/exercises/bodyweight_catalog_test.dart`, aktualne testy
  katalogu, ilustracji, preskrypcji i planera.

Zacznij od [training.md](training.md),
[exercise-execution-filters.md](exercise-execution-filters.md) oraz
[owner-equipment-catalog.md](owner-equipment-catalog.md).

## Kontrakt danych

Chroniony raw424 ma canonical SHA256
`d734c9eb98c827f47d5755705fbd8819207fbe7431db65f26e61ec97c5e7c278`.
Pozostają wcześniejsze guardy316/363/408/412. Nie zmieniaj starych ID,
korekt, komórek XLSX ani424 obrazów. Fixture’y historyczne muszą mieć
przypięty commit i zakres, nie ruchome `HEAD` ani otwarty ogon `[412:]`.
Nie odblokowuj dawnego `--refresh-unreleased-cw414`: cw414 jest już zamrożone.

cw425–428 i431 wymagają wyłącznie masy własnej; ściana jest obowiązkową
stabilną powierzchnią w instrukcji425, nie nową kategorią sprzętu.
cw429/430 wymagają krzesła. Nie zmieniaj profilu, nie dopisuj automatycznie
sprzętu i nie wymagaj gumy/hantli/maty. Marsze428/429 są mierzone czasem
naprzemiennej pracy, nie czasem na stronę.427/430/431 mają powtórzenia na stronę.

425 oraz429 wymagają podparcia rękami.431 wymaga podłogi, klęku i podporu.
427 trzyma tylne kolano nad podłożem. Warunki są jawne, nie wywnioskowane
z nazw ani dawnych opisów regresji. „Cichy” nie gwarantuje braku dźwięku.
Źródło ACE dla427 pokazuje sztangę: wariant bez obciążenia jest wyraźnie
oznaczoną adaptacją. OPAL dla430 ma kontekst pooperacyjny, którego katalog
nie przejmuje jako zaleceń rehabilitacyjnych. Dawka/tempo/progresja są
zachowawczymi decyzjami redakcyjnymi, nie obietnicami medycznymi.

## Kontrole

Pipeline ma być bajtowo idempotentny, również dla XLSX. `--check` nie zapisuje.
Importer zachowuje API i schemat:424→431 to dokładnie siedem insertów,
bez zmian starych wierszy, ulubionych, historii, profilu/wariantów i attempted
outboxa. Drugi import nie zmienia `total_changes()`.

Weryfikuj wszystkie Python `tools/tests` (z Playwright; `xvfb-run` uruchamia
także test rzeczywistych uprawnień powiadomień), focused Flutter
exercises/planner/workout, analyze i pełny Flutter suite. Przy tym rozszerzeniu
nie ma zmian Drift/Freezed/JSON declarations, wersji, zależności ani Web SQLite.
Nie generuj płatnych obrazów, nie publikuj na produkcji w ramach danych.
