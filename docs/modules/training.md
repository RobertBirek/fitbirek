# Working set: Trening

## Odpowiedzialność

Katalog ćwiczeń, planowanie, aktywna sesja, serie, podsumowanie i rekordy osobiste.

## Czytaj najpierw

- `assets/data/exercises.json`
- `lib/features/{exercises,planner,workout}/**`
- `lib/features/progress/prs/**`
- `lib/core/utils/partia_kategoria.dart`
- testy ćwiczeń, workoutu, planera i rekordów
- Interwały: `docs/modules/workout-intervals.md` (silnik, ekran, atomowy zapis rund)
- Generator z filtrów: `docs/modules/structured-planner.md` (struktura, czas, sync i testy)
- Warunki wykonania i pozycje: `docs/modules/exercise-execution-filters.md` (AND/OR, fasety, brak weryfikacji)
- Progresja stałego ciężaru: `docs/modules/fixed-load-progression.md` (read-only, RPE, guard konta i szkic celu)

## Granice

- Nie zmieniaj istniejących identyfikatorów `cw...`.
- Dane ćwiczeń aktualizuj przez `tools/xlsx_to_json.py`; nie uruchamiaj wycofanego generatora.
- Nie omijaj repozytorium treningów ani outboxa synchronizacji.
