# Task 1 — lokalny katalog EZ + rowerek

## Zakres

Dopisano cw409–cw412 zgodnie z uzupełnioną specyfikacją. Sprzęt dokładnie
`Gryf łamany EZ`, dodatkowo `Ławeczka` przy cw411, oraz `Rower stacjonarny`
przy cw412. EZ: bilateralne reps, kg sumy gryfu i talerzy; rowerek: bilateralny
czas, spokojna rozmowa, bez stref HR, wieku i arbitralnych watów. Instrukcje
zawierają technikę, oddech, przerwanie przy bólu, progresję/regresję. Limit
40 kg nie jest zaleceniem roboczym. Źródła odczytano przez Exa (M&S,
Endomondo, Arthritis Foundation) i webfetch (NHS). Pierwsze zgadywane adresy
M&S zwróciły 403; wyszukano i użyto rzeczywistych adresów wydawcy, zapisanych
z opisami przeczytanych sekcji w ledgerze.

## Pliki będące własnością zadania

- `tools/ez_additions.py`, `tools/expand_ez_catalog.py`
- `tools/expand_catalog.py`, `tools/expand_partner_catalog.py`
- `tools/xlsx_to_json.py`, `tools/build_catalog_metadata.py`, `tools/validate_catalog.py`
- `tools/source_data/baza_cwiczen_316.xlsx` (nazwa historyczna zachowana)
- `tools/source_data/{catalog_sources,exercise_names_pl,exercise_execution_conditions}.json`
- `assets/data/{exercises,exercise_catalog_metadata}.json`
- `lib/app/constants.dart`
- `lib/features/exercises/presentation/exercise_illustrations.dart`
- `tools/tests/{test_ez_expansion,test_partner_expansion,test_execution_conditions}.py`
- `test/features/exercises/{catalog_asset_integration,exercise_illustrations}_test.dart`
- `test/features/planner/{catalog_prescription,structured_plan}_test.dart`
- `docs/modules/partner-exercise-catalog.md` i ten raport.

Ilustracji, prywatnych helperów, danych konta, wersji ani changelogu zadanie
nie modyfikowało. Równoległe zmiany tych plików należą do innych wykonawców.

## Dowody testów

- RED Python: `/tmp/opencode/ez-python-red.log` — 408 zamiast 411 oraz brak
  nowego ekspandera. Po zmianie zakresu RED
  `/tmp/opencode/ez-bike-python-red.log`: 408 zamiast 412 i brak dopisanych map.
- RED Flutter: `/tmp/opencode/ez-dart-red.log` — stary licznik i brak opcji EZ.
- GREEN Python katalog: **53 testy**, `/tmp/opencode/ez-catalog-final.log`.
  Obejmuje odtworzenie z fixture commitu `1b67bd5` (408), zgodność bajtową JSON,
  drugi replay i ekspander partnerski bez zmiany bajtów XLSX/JSON, `--check`,
  pełne stare metadane/rejestry, odrzucenie mutacji cw408 i ścisły licznik 412.
- SHA256 kanonicznego prefiksu 408:
  `98fea910a93c5f85796533c217d11ce437492307c9c9aea315b4f14804438ed9`.
  Stare hashe 316/363 i zakresy 369/408 pozostają bez zmian.
- GREEN focused Flutter: **53 testy**, `/tmp/opencode/ez-dart-final.log`,
  obraz `fit-web:illustrations-408-verified`, mounty zmienionych lib, assets i
  testów read-only. Oba generatory: pozytywne i negatywne wymagania EZ/ławki
  i rowerka; filtry, dawki, timed rowerek, metadane. Rejestr/ładowanie/dekodowanie
  wszystkich **412** ilustracji 512×512 również PASS po dostarczeniu plików
  przez osobnego wykonawcę. Ocena wizualna należy do jego raportu.
- `expand_ez_catalog.py --check`, `expand_partner_catalog.py --check`,
  `build_catalog_metadata.py --check`, `validate_catalog.py`, `git diff --check`: PASS.
- Format sześciu zmienionych plików Dart wykonany pinned Dart z tego obrazu.
- Próba całego `unittest discover -s tools/tests`: 73 testy, 1 błąd importu
  `test_push_browser` — brak `playwright` w izolowanym catalog venv. Nie
  instalowano zależności. To nie jest pełny zielony zestaw Python; reszta
  przeprowadzonych testów przeszła. Pełna analiza/Flutter suite i kanoniczny
  Docker verification pozostają zadaniem sesji głównej, bez drugiego buildu.

## Ograniczenia i bezpieczeństwo

Przejrzano kopie sprzętu: lista i onboarding korzystają z AppConstants;
ustawienia profilu zachowują sprzęt bez własnej listy wyboru. Nie dodawano
nowego ekranu ustawień. Nowe etykiety są w jedynym wspólnym słowniku.
Brak zmian deklaracji Drift/Freezed/JSON-model, dlatego build_runner nie był
wymagany. Bez zmian zależności, `pubspec.lock`, Web SQLite i toolchainu.
Bez subagentów, commitów, push, brancha, deployu i zapisu danych osobistych.
Wszystko pozostaje lokalne; publikacja wymaga osobnej zgody użytkownika.
