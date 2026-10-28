# Etap 2 — implementacja podstaw katalogu

> Wykonanie: subagent-driven-development, TDD, pojedynczy implementer i niezależny review.

**Goal:** Siedem wybieralnych ćwiczeń cw425–cw431, bez naruszenia prefiksu424 i danych użytkownika.
**Architecture:** Istniejący append-only XLSX pipeline, jawne sidecary i metadane, przyrostowy importer. Brak migracji; obrazy424 +7 jawnych pending.
**Tech Stack:** Flutter3.35.4/Dart3.9.2, Python3.12/openpyxl3.1.5, istniejący Drift/sqlite3 bez zmiany wersji.
**Spec:** `docs/superpowers/specs/2026-10-28-catalog-basics-design.md`.

## Global Constraints
- Nie zmieniać raw424 (canonical SHA256 d734c9eb98c827f47d5755705fbd8819207fbe7431db65f26e61ec97c5e7c278), dawnych ID, korekt i424 obrazów.
- Zachować starsze hashe prefiksów316/363/408/412 i historyczne znaczenia countów.
- Nowe opisy autorskie, zweryfikowane źródła HTTPS; bez kopii grafik/pdf/tekstu z Drive, bez płatnej generacji.
- Bez produkcji, resetu danych, deps/toolchain/lock/WebSQLite/migracji/versionbump.
- Import nie modyfikuje favorites/history/variants/profilu/outboxa, drugi import bez SQLite total_changes.

## Review Focus
1. Stare count424 jako zakres historyczny vs nowycount431: nie robić globalnego replace.
2. Warunki no_floor/no_kneeling/no_hand_support wynikają z instrukcji.
3. Źródło i klasyfikacja każdej pozycji są jawne, nie zgadywane.
4. Pending7 nie udają ilustracji i nie naruszają istniejących424 assets.
5. Reprodukowalność i brak zmian XLSX/artefaktów przy drugim uruchomieniu.

### Task 1: Katalog431, fallback i upgrade

**Files:**
- Create: `tools/bodyweight_additions.py`, `tools/expand_bodyweight_catalog.py`, `tools/tests/test_bodyweight_expansion.py`.
- Modify: `tools/source_data/baza_cwiczen_316.xlsx` i source JSON nazw/warunków/źródeł; `tools/xlsx_to_json.py`, `build_catalog_metadata.py`, `expand_catalog.py`, `validate_catalog.py`, historyczne expand_ez/owner wyłącznie dla kompatybilnego replay/check431.
- Generate: `assets/data/exercises.json`, `exercise_catalog_metadata.json`, `backend/app/mentor/exercise_catalog.json`.
- Modify: `lib/features/exercises/presentation/exercise_illustrations.dart`, szczegóły ćwiczenia dla jawnego pending fallback.
- Test: nowe pipeline i Flutter upgrade424→431; bieżące testy katalogu, ilustracji, planner count i historycznych expansion fixtures.

**Interfaces:** dotychczasowy parser Exercise i przyrostowy importer bez zmian kontraktu. Nowe CLI `expand_bodyweight_catalog.py [--check]`. Runtime jawny zbiór awaitingIllustration IDs7, rozłączny z illustrated424.

- [ ] RED: dokładna lista nowych ID/nazw/sprzętu/tracking/pozycji,431 metadata/source coverage i guard raw424, komórki XLSX niezmienione.
- [ ] RED: idempotentny pipeline/check bez zmiany bajtów drugiego przebiegu; nieaktualne historyczne fixtures poprawić do stałych zakresów.
- [ ] RED: import424→431 z favorites/history/variants/attemptedoutbox snapshots i drugi import total_changes0.
- [ ] RED:431=424illustrated+7pending, nowe null asset+jawny tekst, dawne424 obrazy bez zmian.
- [ ] GREEN: autorskie dane, źródła i append-only pipeline, odpowiednie metadane/warunki, projekcja Mentora.
- [ ] Run: Python pipeline checks i tools unittest; Flutter exercises/planner/workout focused, analyze i pełna suite przed odbiorem etapu2. Format tylko zmienionych Dart, diffcheck.
- [ ] Commit własnych danych/kodu/testów i raport z RED/GREEN/komendami, zakresy i ograniczenia.

### Task 2: Odbiór etapu2
- [ ] Niezależny diff review spec+quality.
- [ ] Poprawki z regresjami, bez omijania guardów.
- [ ] Uaktualnić working-set guide i przekazać431 jako baseline etapu3.
- [ ] Nie scalać/push/deploy bez dalszego jawnego polecenia publikacji.
