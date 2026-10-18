# Opcjonalne rozszerzenia synchronizacji treningu

Implementacja backendu specyfikacji
`docs/superpowers/specs/2026-10-16-guided-training-design.md` oraz rytmu tygodnia
z `docs/superpowers/specs/2026-10-17-training-rhythm-design.md`
i kontraktu `docs/modules/weekly-schedule.md`.
Nie oznacza wdrożenia API ani implementacji klienta.

## Kontrakt zapisu

Nie dodajemy typów encji, tabel ani migracji. Rozszerzenia są dodatkowymi
kluczami istniejącego payloadu JSONB:

| entityType | Klucze zachowywane przy pominięciu |
| --- | --- |
| `profile` | `filterPresets`, `exerciseVariants`, `weeklySchedule` |
| `workoutSession` | `guidance` |
| `workoutSet` | `variantId`, `variantLabel` |
| `personalRecord` | `variantId`, `variantLabel` |

Przy zaakceptowanym UPSERT istniejącego, żywego rekordu każdy z tych kluczy
jest kopiowany z aktualnego snapshotu tylko wtedy, gdy żądanie go **nie zawiera**.
Jawne `null` zapisuje `null` (wyczyszczenie); obecna wartość zastępuje całą
poprzednią wartość, bez deep merge. Pozostałe klucze nadal podlegają zwykłemu
zastąpieniu payloadu. Nowe rekordy nie dostają wartości domyślnych.

DELETE nie kopiuje rozszerzeń. UPSERT tombstone nie dziedziczy jego rozszerzeń,
nawet jeśli tombstone je zawierał. Dotychczasowe reguły jawnego wskrzeszania
nie zmieniają się; backend nie wykonuje automatycznego wskrzeszania profilu.

## Kolejność i atomowość

`app/sync/service.py` zachowuje blokady per konto/operacja/rekord, kontrolę
idempotencji, reguły encji serwerowych i dokładne CAS. Dopiero po tych kontrolach
`revised_record_payload` buduje osobną kopię payloadu w planie transakcji.
Kolejne zależne operacje tego samego batcha widzą aktualny planowany snapshot.
Każdy `PlannedWrite.payload` jest osobnym snapshotem danej wersji, zapisywanym
do `SyncChange`; `SyncRecord` dostaje końcowy snapshot.

`PushOperation.payload` pozostaje nietknięty. `request_digest` i utrwalony
`SyncOperation.request_digest` dotyczą oryginalnego żądania, nie rozszerzonego
snapshotu. Identyczny retry zwraca historyczne version/updatedAt/duplicate,
nawet po późniejszej zmianie rekordu. Podmieniony payload pod tym samym
operationId nadal zwraca `operationReuse`. Nowa operacja ze starym baseVersion
zwraca bieżący zatwierdzony snapshot, nie historyczny wynik retry. Konflikt
w batchu zwraca snapshot sprzed batcha i wycofuje wszystkie nowe zapisy;
błąd zapisu/commit również wycofuje rekordy, historię zmian i hashe operacji.

## Schematy należące do klienta

Format trzech kolekcji profilu (`filterPresets`, `exerciseVariants`,
`weeklySchedule`):

```json
{"version": 1, "entries": [{"id": "UUID", "name": "Nazwa", "createdAtUtc": "UTC", "updatedAtUtc": "UTC", "deletedAtUtc": null}]}
```

Wpis `filterPresets` może zawierać mapę `filters`. Wpis `exerciseVariants`
zawiera bazowe `exerciseId` oraz opcjonalne `loadKg`, `tempo`, `pauseSeconds`,
`rangeOfMotion`, `cue`. Identyfikatory wariantów są stabilnymi UUID, nie nowymi
identyfikatorami `cw...`. Tombstones wpisów kolekcji i scalanie konfliktów per ID
są odpowiedzialnością klienta. Serwer zachowuje kolekcję jako całą wartość.
`guidance` jest opcjonalną mapą klienta, początkowo `schemaVersion: 1`.

`weeklySchedule` jest nullable rozszerzeniem istniejącego `profile`, nie nowym
typem encji. Klient Flutter (lokalny schemat Drift 13) przechowuje kolekcję
`{"version": 1, "entries": [...]}` z regułami tygodnia (`kind: rule`) i wyjątkami
wystąpień (`kind: override`). Referencje `planSyncId` / `sessionSyncId` są sync UUID;
daty harmonogramu to lokalne dni kalendarza. Semantyka, limity kolekcji,
tombstone'y wpisów i deterministyczne scalanie per ID należą do klienta.
Backend przechowuje opaque JSON jako całą wartość, również dla przyszłych
wersji: nie rozwija reguł, nie scala wpisów i nie weryfikuje powiązań planów/sesji.
Omission zachowuje również uprzednio zapisany `weeklySchedule: null`;
jawny `null` czyści kolekcję, a obecna wartość zastępuje ją w całości.

Backend nie waliduje semantyki kolekcji, nazw, parametrów ani wersji mapy guidance;
nadal stosuje istniejący kontrakt JSON (w tym zakaz NaN/Infinity) i limity batcha.
Pełna walidacja, wznowienie treningu, podsumowanie i porównania wariantów
pozostają do implementacji w kliencie.

Pull nadal publikuje tylko dotychczasowe typy encji, z dodatkowymi kluczami
payloadu. Nie wprowadza więc nieznanego typu blokującego kursor starego klienta.
Testy backendu sprawdzają ten kształt wire; nie uruchamiają parsera Dart.

## Weryfikacja i przyszłe wdrożenie

Python 3.12, zależności z `requirements-build.lock` i `requirements-dev.lock`
instalowane przez `pip --require-hashes`. PostgreSQL 16 uruchamiany przez
Testcontainers w Dockerze, bez połączenia do produkcyjnej bazy:

```sh
.venv/bin/python -m pytest -q tests/test_sync.py -k extension
.venv/bin/python -m pytest -q tests/test_sync.py
.venv/bin/python -m pytest -q
```

Weryfikacja rozszerzenia `weeklySchedule` (2026-10-17, Python 3.12.3):

- TDD RED przed zmianą allowlisty: **5 failed, 29 passed, 39 deselected**
  (utrata pominiętej kolekcji / zapisanego NULL).
- Testy rozszerzeń po zmianie: **34 passed, 39 deselected**.
- Cały `tests/test_sync.py`: **73 passed**.
- Pełny backend: **378 passed** (373 dotychczasowe + 5 nowych przypadków).

Wspólne testy rozszerzeń obejmują harmonogram samodzielnie i obok pozostałych
kolekcji profilu: omission starego klienta, zastąpienie opaque JSON, jawny NULL,
DELETE i jawne wskrzeszenie bez dziedziczenia tombstone'a, retry/idempotencję,
hash oryginalnego żądania i niezmienność attempted payloadu, dokładne CAS,
rollback batcha/commit, izolację kont, zakres kluczy per typ i finite JSON.
Logi lokalnej weryfikacji:
`/tmp/opencode/weekly-schedule-backend-{red,green,sync,full}-20261017.log`.

Zachowanie wymaga przyszłego, osobno zatwierdzonego wdrożenia API przed
poleganiem na ochronie omission w nowych klientach. Ta zmiana nie wymaga nowej
migracji Alembic. Nie stanowi zgody na operacje produkcyjne ani zmiany Compose.
