# Sprzęt właściciela i alternatywne wymagania katalogu

## Working set

- `tools/expand_owner_equipment_catalog.py`, `tools/source_data/`,
  `tools/xlsx_to_json.py`, generatory metadata/warunków i walidator katalogu.
- `assets/data/exercises.json`: chroniony raw prefiks412 i dodatek12.
- `assets/data/exercise_catalog_corrections.json`: jawne wersjonowane korekty.
- `exercise_catalog_metadata.dart`, `exercise_filter_engine.dart`:
  definicja i wspólny matcher alternatywnych zestawów sprzętu.
- `exercises_repository.dart`, `exercise_catalog_corrections.dart`:
  walidacja manifestu i przyrostowy import bez zastępowania wierszy.
- `plan_generator.dart`, `structured_plan.dart`: wykonalność sprzętowa.
- `edit_profile_page.dart`, `onboarding_equipment_page.dart`, `constants.dart`:
  jawny wybór sprzętu, bez automatycznego zaznaczania nowych kategorii.
- `features/workout/preparation/`: sprzęt konkretnego wykonania, wrist roller
  i stałe20kg worka właściciela.
- `tools/generate_offline_package.dart`: wymagany manifest korekt w core cache.

Zacznij od [training.md](training.md), [exercise-execution-filters.md](exercise-execution-filters.md)
i [workout-preparation.md](workout-preparation.md). Specyfikacja i zakres lokalnego
rozszerzenia: `docs/superpowers/specs/2026-10-22-owner-equipment-catalog-design.md`.

## Zasady danych

Nie zmieniaj istniejących `cw...` ani chronionych surowych prefiksów. Nowe
ćwiczenia dopisuje pipeline XLSX; korekty sześciu istniejących wpisów są osobnym
zatwierdzonym manifestem, nie pretekstem do resetu katalogu lub bazy.
Aktualizacja dotyka wyłącznie dozwolonych pól katalogowych i nazw. Ulubione,
historia, warianty, sync metadata i pending outbox pozostają bez zmian.
Ponowny import ma być bez zapisów: sprawdzaj także SQLite `total_changes()`,
nie tylko równość końcowych wartości.

`equipmentSets` we wpisie metadata oznacza OR kompletnych zestawów, wewnątrz
każdego AND. Brak pola zachowuje ścisłe wymaganie `Exercise.sprzet`. Nie zmieniaj
go na ogólne `any`: same hantle nie zastępują hantli i ławki. Przeglądanie bazy
ma osobną semantykę OR filtrów. Query i fasety mają widzieć także alternatywy,
bez podwójnego liczenia ćwiczeń.

Wymagane assety korekt i metadanych należą do podstawowego pakietu offline;
możliwość startu aplikacji nie może zależeć od zgody na pobranie całego pakietu.
Nowe stringi sprzętu nie są nowym enumem protokołu synchronizacji profilu.

## Znaczenie sprzętu

- Step: deklarowane150kg, regulacja podstawą;10–15cm to orientacyjne niskie
  ustawienie, nie pomiar posiadanego sprzętu ani zgoda na skoki.
- Ławka do brzuszków nie implikuje ławki płaskiej, dodatniej ani dopuszczonej
  do wyciskania ujemnego. Ta ostatnia ma osobną kategorię i jawne zastrzeżenia.
- Wrist roller to uchwyt, linka i zawieszony ciężar. Kg nie oznaczają masy
  uchwytu ani sztuki hantla; nie uruchamiaj solvera pary hantli.
- Sandbag właściciela jest operacyjnie stałym zasobem20kg. Nie jest uniwersalnym
  ciężarem startowym innych osób ani historycznym wynikiem użytkownika.
- Pasy do zwisu za nogi nie są TRX ani podporami ramion i nie uruchamiają
  automatycznego doboru inwersji.
- Mata nie staje się obowiązkowa dla wszystkich dawnych ruchów podłogowych.

Profil zmienia się tylko przez jawny zapis. Zachowuj nieznane starsze wartości
sprzętu i pozostałe pola użytkownika. Nie edytuj profilu produkcji w ramach
wdrożenia kodu/danych.

## Kontrole

Python pipeline: reprodukowalność, prefiks412,12 nowych ID,6 korekt, źródła,
metadata i warunki wykonania. Flutter: poprawne OR-of-AND, parser fail-closed,
profil cancel/save/unknown, upgrade412→424 z favorites/history/outbox,
przygotowanie/recovery, fallback ilustracji. Stare412 ilustracji pozostają
bez zmian;12 nowych wpisów ma jawnie oczekujące ilustracje, nie obrazy innych
ruchów. Pełny odbiór i publikacja nowego katalogu są oddzielne od1.22.0+38.
