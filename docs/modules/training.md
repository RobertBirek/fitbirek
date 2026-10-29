# Working set: Trening

## Odpowiedzialność

Katalog ćwiczeń, planowanie, aktywna sesja, serie, podsumowanie i rekordy osobiste.

## Czytaj najpierw

- `assets/data/exercises.json`
- `lib/features/{exercises,planner,workout}/**`
- `lib/features/progress/prs/**`
- `lib/core/utils/partia_kategoria.dart`
- testy ćwiczeń, workoutu, planera i rekordów
- Role serii, cele schema2 i programy A/B: `training-sets-programs-data.md`
  oraz `training-sets-programs-ui.md` (bieżący Drift15; bez backfillu).
- Backup4 i ograniczenia starych klientów: `backup.md`.
- Interwały: `docs/modules/workout-intervals.md` (silnik, ekran, atomowy zapis rund)
- Generator z filtrów: `docs/modules/structured-planner.md` (struktura, czas, sync i testy)
- Zamienniki, domyślne/edytowane przerwy i aktywna zamiana:
  `docs/modules/planner-safe-replacements.md` (zgodność ruchowa, budżet, atomowe recovery).
- Warunki wykonania i pozycje: `docs/modules/exercise-execution-filters.md` (AND/OR, fasety, brak weryfikacji)
- Podstawowe ruchy bez obciążenia: `docs/modules/bodyweight-catalog.md` (raw424→431, źródła, pending7).
- Progresja stałego ciężaru: `docs/modules/fixed-load-progression.md` (read-only, RPE, guard konta i szkic celu)
- Własne warianty / filtry w chmurze: `docs/modules/user-variants-cloud.md`
  (Drift12, profile collections, exact exercise+side+variant UUID, CAS i restore).

## Granice

- Nie zmieniaj istniejących identyfikatorów `cw...`.
- Dane ćwiczeń aktualizuj przez `tools/xlsx_to_json.py`; nie uruchamiaj wycofanego generatora.
- Nie omijaj repozytorium treningów ani outboxa synchronizacji.
