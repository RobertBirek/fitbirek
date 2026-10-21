# Raport zadania 1 — backend własnych testów

**Status: DONE — ostatni FULL: 618 passed, exit0 (914.88s).**
Pierwszy FULL wykazał istniejącą niespójność wygenerowanego katalogu Mentora
(1 failed /617 passed). Po jawnej zgodzie rodzica rozszerzono własność wyłącznie
o `backend/app/mentor/exercise_catalog.json`, odtworzono go istniejącym
generatorem z publicznych danych412 i zweryfikowano pełny backend ponownie.
Historia wcześniejszej porażki jest zachowana poniżej.

## Zakres

- `backend/app/sync/fitness_protocols.py`: ścisły kontrakt v1 definicji, wariantu
  i wyniku; limity UTF-8, liczby bez bool, momenty UTC Z, niezmienność rewizji.
- `service.py`: omission fitnessProtocols/customProtocol, walidacja dopiero po
  CAS i rekonstrukcji, bez modyfikacji attempted payload/request_digest.
- `router.py`: kontraktowe błędy HTTP 422 z rollback całego batcha.
- Nowe testy `backend/tests/test_custom_fitness.py` i opis SYNC_EXTENSIONS.
- Po dodatkowej zgodzie: regeneracja jednego publicznego artefaktu
  `backend/app/mentor/exercise_catalog.json` (369→412) istniejącym narzędziem,
  bez zmiany logiki Mentora, testów, szablonów, providerów ani zgód.
- Bez nowych encji/tabel, migracji, zależności, Fluttera, zmian wspólnego fixture,
  operacji Git commit/push, deploy ani zapisów do produkcji.

Autorytatywne nazwy pól pozostają zgodne z
`tests/fixtures/fitness_protocol_v1.json`. Snapshot wyniku jest samowystarczalny;
backend nie wymaga obecnego katalogu ćwiczeń, definicji/rodzica ani wariantu.
Nie tworzy wyników podczas zapisu definicji, sesji, serii ani PR.

## Weryfikacja

Python **3.12.3** (`backend/.venv/bin/python`), PostgreSQL16 przez Docker
Testcontainers. Instalacja potwierdzona przez pip `--require-hashes` z
requirements-build.lock i requirements-dev.lock (no-build-isolation).
Log instalacji: `/tmp/opencode/custom-fitness-deps.log`.

1. TDD RED przed kodem produkcyjnym:
   `.venv/bin/python -m pytest -q tests/test_custom_fitness.py`
   — **38 failed, 2 passed**, 56.12s. Brak walidacji/omission/422 wywoływał
   oczekiwane porażki; dwa testy DELETE już przechodziły.
   Log `/tmp/opencode/custom-fitness-red.log`.
2. Pierwszy GREEN tym samym poleceniem — **40 passed**, 49.48s.
   Log `/tmp/opencode/custom-fitness-green.log`.
3. Dodatkowy RED dla nieparzystego surrogate Unicode i zmiany liczbowej
   reprezentacji zamrożonego snapshotu:
   `.venv/bin/python -m pytest -q tests/test_custom_fitness.py -k 'unpaired or numeric_canonical'`
   — **3 failed, 78 deselected**, 8.96s; następnie dodano obsługę 422 i
   porównanie kanonicznego JSON.
   Log `/tmp/opencode/custom-fitness-edge-red.log`.
4. Focused: `.venv/bin/python -m pytest -q tests/test_custom_fitness.py tests/test_sync.py`
   — pierwsza próba przerwana przez limit narzędzia 120s (nie pełny wynik),
   log `/tmp/opencode/custom-fitness-focused.log`. Ponowiono bez timeoutu;
   **188 passed**, 190.40s, exit0,
   log `/tmp/opencode/custom-fitness-focused-verified.log`. Po doprecyzowaniu
   kontraktu nullable/precision ponowiono na finalnym kodzie:
   **208 passed**, 255.43s (4:15), exit0;
   log `/tmp/opencode/custom-fitness-final-focused.log`. Te wyniki historyczne
   poprzedzają ostatnią zmianę integral-num; finalne wyniki poniżej.
5. FULL: `.venv/bin/python -m pytest -q`
   — pierwsza próba przerwana przez limit narzędzia 120s (nie pełny wynik),
   log `/tmp/opencode/custom-fitness-full.log`. Kolejne dwa uruchomienia
   (`/tmp/opencode/custom-fitness-full-verified.log` oraz
   `/tmp/opencode/custom-fitness-final-full.log`) zakończono SIGTERM po
   ostatniej zmianie kontraktu integral-num; procesy pytest143, wrapper exit1.
   Żadnego z tych niepełnych przebiegów nie traktujemy jako pełnego wyniku.
6. `git diff --check -- backend` oraz Python compileall dla app/sync i nowego
   pliku testów — exit0.
7. Samodzielny rozszerzony kontrakt przed doprecyzowaniem nullable:
   `.venv/bin/python -m pytest -q tests/test_custom_fitness.py`
   — **81 passed**, 67.94s; `/tmp/opencode/custom-fitness-contract-verified.log`.
8. TDD RED po doprecyzowaniu nullable i precision:
   `.venv/bin/python -m pytest -q tests/test_custom_fitness.py -k 'nullable_protocol_omission or strict_gregorian or not_coerced'`
   — **5 failed, 10 passed, 81 deselected**, 18.63s. Cztery porażki wykazały
   false collision missing/null, piąta nieodrzucanie siedmiu cyfr części
   ułamkowej. Naprawa normalizuje sześć nullable pól tylko w kopii kontrolnej
   i ogranicza precision1..6; nie zmienia attempted/digest ani raw zapisu.
   Log `/tmp/opencode/custom-fitness-nullable-red.log`.
9. GREEN dla doprecyzowanego kontraktu i integracji raw/digest:
   `.venv/bin/python -m pytest -q tests/test_custom_fitness.py -k 'nullable_protocol_omission or strict_gregorian or not_coerced or normalized_null or allowed_timestamp'`
   — **20 passed, 81 deselected**, 22.44s;
   `/tmp/opencode/custom-fitness-nullable-green.log`.
10. TDD RED dla ostatecznego doprecyzowania reps jako integral-num:
    `.venv/bin/python -m pytest -q tests/test_custom_fitness.py -k 'integral_double'`
    — **4 failed, 101 deselected**, 21.82s, exit1;
    `/tmp/opencode/custom-fitness-reps-red.log`. Nowe testy obejmują SQLite REAL
    0.0/18.0/1e9 i integracyjny roundtrip z nietkniętym attempted/digest/retry.
11. **FINAL focused na ostatecznych, zamrożonych źródłach:**
    `.venv/bin/python -m pytest -q tests/test_custom_fitness.py tests/test_sync.py`
    — **215 passed**, 232.01s (3:52), **exit0**;
    `/tmp/opencode/custom-fitness-integral-focused.log`.
12. **FINAL FULL na tych samych źródłach:**
    `.venv/bin/python -m pytest -q`
    — **1 failed, 617 passed**, 813.92s (13:33), **exit1**;
    `/tmp/opencode/custom-fitness-integral-full.log`.
    Porażka:
    `tests/test_mentor_templates.py::test_catalog_is_reproducible_and_pool_is_bounded`
    (linia87). Mentor `CATALOG` ma369 ID, a assets/data/exercises.json ma412:
    brakuje43 ćwiczeń. Potwierdzono: zarówno HEAD, jak i bieżący asset mają412;
    backend/app/mentor/templates.py nie ma diffu względem HEAD. To istniejąca
    niespójność poza własnością zadania1; nie zmieniano katalogu ani Mentora.
    Pełny log nie zawiera sekcji warnings. Bez innych porażek.

Finalna weryfikacja rozpoczęła się 2026-10-21 13:02:18+0200, focused zakończył
się13:06:14, FULL13:19:56. Zapis exitów i czasów:
`/tmp/opencode/custom-fitness-integral-times.log`. Po FULL `sha256sum -c`
potwierdził **OK** dla wszystkich czterech plików źródeł/testów; nie zmieniano
ich w trakcie ani po weryfikacji. Dodane testy kontraktu: **108**.

Nowe przypadki obejmują: shared fixture i datę przed utworzeniem protokołu,
metryki oraz granice, Unicode, nullable load/side, wariant i jego opcjonalne
pola, nieznane wersje/pola, limit kolekcji/duplikaty, gałęzie i archiwizację,
zakaz prune/null i zmiany reguł, legacy/generic payload, omission i dokładny
digest/retry, immutable custom snapshot, CAS przed walidacją, DELETE nieczytelnej
historii, batch atomowy oraz niezależne snapshoty SyncChange kolejnych korekt.

## Ograniczenia

- Nie wdrażano API. Rollout wymaga osobnej zgody i kolejności API przed webem.
- Zakaz przyszłej próby jest kontrolą formularza wg specyfikacji; backend
  waliduje moment UTC Z, nie narzuca nowego ograniczenia dat legacy.
- Nie uruchamiano Fluttera ani UI (osobne zadania).
- Wcześniejszą porażkę Mentora usunięto po rozszerzeniu zakresu przez rodzica
  wyłącznie na generowany artefakt. Nie zmieniano oczekiwań testu ani logiki.
- Reps akceptuje integralne num (18 i18.0), lecz nie bool ani18.5; wersje
  kolekcji/wrappera i timeLimitSeconds pozostają ścisłymi int (bez1.0/bool).
  Zapis nie castuje ani nie mutuje attempted operacji.

## Publiczne API walidatora dla parity backend/Dart

Moduł: `app.sync.fitness_protocols` (uruchamiać z backend/, Python3.12).

```python
from app.sync.fitness_protocols import (
    FitnessValidationError,
    validate_fitness_payload,
)

validate_fitness_payload(
    entity_type,  # "profile" lub "fitnessTest"
    payload,      # dict: pełny zrekonstruowany payload rekordu
    previous,     # dict: poprzedni payload; {} dla nowego rekordu
    live=False,   # keyword-only: poprzedni rekord istnieje i jest żywy
    deleted=False,# keyword-only: DELETE omija walidację rozszerzeń
)
```

Wynik: `None` przy akceptacji, `FitnessValidationError` (podklasa ValueError)
przy odrzuceniu; bez I/O, czasu serwera, modyfikacji argumentów ani lookupów DB.
Do samego protokołu użyć `protocol(entry)`; do kolekcji `collection(value)`
(zwraca mapę wpisów po UUID). Omission rozszerzenia z istniejącego rekordu jest
odpowiedzialnością `service.revised_record_payload` przed tym walidatorem.
Nazwy wire to dokładnie fitnessProtocols/customProtocol/typ/data/wynik/score
oraz klucze wspólnego fixture; nie wprowadzono aliasów.

## Zamrożone źródła ostatniej weryfikacji

Manifest utworzono przed finalnym focused/FULL:
`/tmp/opencode/custom-fitness-integral-sources.sha256`.
Po zakończeniu sprawdzono zgodność hashy; później zmieniano tylko dokumentację.

SHA256:

```text
94de3bfdc4db9a841fff1417d6d3eb60751cc66ec2c57987f83cb47512707ab1  backend/app/sync/fitness_protocols.py
7327798c2a594a7bb12c0e75fa4093c0c4c0a75e1c2b803fda907433ba57c554  backend/app/sync/service.py
4b88c65c22db3c9408468bed49771cb6812eb2d20156d5695564c84b5e3c3597  backend/app/sync/router.py
8737d247281be4956c16db4be030265124fcea781cf7172f0e04891788cd8ac0  backend/tests/test_custom_fitness.py
```

## Dodatkowa zgoda: odświeżenie istniejącego artefaktu Mentora

Przed pracą przeczytano `docs/modules/mentor.md`, `docs/mentor.md` i generator.
Istniejący FAIL testu87 był dowodem RED. Przyczyną był nieaktualny wygenerowany
bundle369 względem niezmienionych publicznych danych412. Zakres rozszerzono
tylko o jeden plik JSON. Nie zmieniono templates/model/vendor, schematów, zgód,
sekretów, providercalls, testów ani generatora.

Polecenia (Python3.12.3, nadal hash-locked dependencies i Docker PostgreSQL16):

```sh
backend/.venv/bin/python backend/tools/generate_mentor_catalog.py
backend/.venv/bin/python backend/tools/generate_mentor_catalog.py --check
# następnie w backend/:
.venv/bin/python -m pytest -q tests/test_mentor_templates.py
.venv/bin/python -m pytest -q
.venv/bin/python tools/generate_mentor_catalog.py --check
sha256sum -c /tmp/opencode/custom-fitness-catalog-sources.sha256
```

- Generator i oba `--check`: **exit0**; bundle zawiera dokładnie412 ID źródła.
- Cały `test_mentor_templates.py`: **19 passed**, 39.27s, **exit0**.
  Log `/tmp/opencode/custom-fitness-catalog-focused.log`. Zachowane testy
  bounded pool i prywatności, bez zmiany oczekiwań.
- Ostateczny **FULL: 618 passed**, 914.88s (15:14), **exit0**.
  Log `/tmp/opencode/custom-fitness-catalog-full.log`, bez failures/warnings.
- Weryfikacja rozpoczęta13:23:24+0200, focused zakończony13:24:11,
  FULL13:39:32. Exity i daty: `/tmp/opencode/custom-fitness-catalog-times.log`.
- Nie powtarzano focused215: kod walidacji i108 testów własnych pozostały
  identyczne, co potwierdza manifest przed weryfikacją i10 wyników **OK** po.
- Manifest `/tmp/opencode/custom-fitness-catalog-sources.sha256` obejmuje cztery
  poprzednio zamrożone pliki, nowy artefakt, templates, jego testy, generator oraz
  oba publiczne assety. Wszystkie hashe pozostały zgodne podczas weryfikacji.

Nowy artefakt SHA256:
`b6dc7243a8d8b8507e68b598f07d3a2f04f5c2e5b659b3be9699737b91ca795c`.
Niezmienione źródło412 SHA256:
`31eb961b25fe4d4b719a5c32a4efb50a223b3215ed8e67988736001bfea17667`.
Niezmienione metadata SHA256:
`f2f4fb302b2c6595c4482aba6edc54571c96507ccb40c2ebbb0313db67f5a8f3`.

Bez nowych zależności, commit/push/deploy i kontaktu z produkcją/providerami.
