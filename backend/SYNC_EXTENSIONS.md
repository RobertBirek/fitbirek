# Opcjonalne rozszerzenia synchronizacji treningu

Implementacja backendu specyfikacji
`docs/superpowers/specs/2026-10-16-guided-training-design.md`.
Nie oznacza wdrożenia API ani implementacji klienta.

## Kontrakt zapisu

Nie dodajemy typów encji, tabel ani migracji. Rozszerzenia są dodatkowymi
kluczami istniejącego payloadu JSONB:

| entityType | Klucze zachowywane przy pominięciu |
| --- | --- |
| `profile` | `filterPresets`, `exerciseVariants` |
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

Planowany format obu kolekcji profilu:

```json
{"version": 1, "entries": [{"id": "UUID", "name": "Nazwa", "createdAtUtc": "UTC", "updatedAtUtc": "UTC", "deletedAtUtc": null}]}
```

Wpis `filterPresets` może zawierać mapę `filters`. Wpis `exerciseVariants`
zawiera bazowe `exerciseId` oraz opcjonalne `loadKg`, `tempo`, `pauseSeconds`,
`rangeOfMotion`, `cue`. Identyfikatory wariantów są stabilnymi UUID, nie nowymi
identyfikatorami `cw...`. Tombstones wpisów kolekcji i scalanie konfliktów per ID
są odpowiedzialnością klienta. Serwer zachowuje kolekcję jako całą wartość.
`guidance` jest opcjonalną mapą klienta, początkowo `schemaVersion: 1`.

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

Zachowanie wymaga przyszłego, osobno zatwierdzonego wdrożenia API przed
poleganiem na ochronie omission w nowych klientach. Ta zmiana nie wymaga nowej
migracji Alembic. Nie stanowi zgody na operacje produkcyjne ani zmiany Compose.
