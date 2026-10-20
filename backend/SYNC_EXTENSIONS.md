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
| `workoutSet` | `variantId`, `variantLabel`, `side` |
| `personalRecord` | `variantId`, `variantLabel`, `side` |
| `workoutPlan` | `structure` (z kontrolą zgodności ID opisaną poniżej) |

Przy zaakceptowanym UPSERT istniejącego, żywego rekordu każdy z tych kluczy
jest kopiowany z aktualnego snapshotu tylko wtedy, gdy żądanie go **nie zawiera**.
Jawne `null` zapisuje `null` (wyczyszczenie); obecna wartość zastępuje całą
poprzednią wartość, bez deep merge. Pozostałe klucze nadal podlegają zwykłemu
zastąpieniu payloadu. Nowe rekordy nie dostają wartości domyślnych.

`side` jest chronione tylko dla serii i rekordów osobistych. Jawne `null`
oznacza brak strony, zgodnie z nullable polem klienta; nie jest zamieniane
na lewą/prawą stronę ani na wartość domyślną.

Dla żywego planu z niepustą (`!= null`) strukturą pominięcie `structure`
wymaga identycznej uporządkowanej listy `cwiczeniaIds` jak przed zapisem oraz
zgodności z `structure.blocks[*].exerciseId`. Brak listy, zmiana kolejności,
zmiana ćwiczeń lub struktura, której zgodności nie można potwierdzić, powoduje
zwykły konflikt sync ze snapshotem sprzed batcha i rollback całego batcha.
Nie usuwamy struktury po cichu i nie łączymy jej z inną listą ćwiczeń.
Klient musi przesłać świadomie nową strukturę lub jawne `structure: null`.
Serwer nadal nie waliduje pełnego schematu struktury jawnie przesłanej przez
klienta; ochrona dotyczy dziedziczenia przy omission. DELETE i revival pozostają
wyjątkami opisanymi niżej. Stary klient nie może rozwiązać takiego konfliktu
samym ponownym CAS — potrzebna jest decyzja klienta obsługującego strukturę.

DELETE nie kopiuje rozszerzeń. UPSERT tombstone nie dziedziczy jego rozszerzeń,
nawet jeśli tombstone je zawierał. Dotychczasowe reguły jawnego wskrzeszania
nie zmieniają się; backend nie wykonuje automatycznego wskrzeszania profilu.

## Zachowanie dokładnej daty pomiaru przy korekcie

Osobny kontrakt dla `measurement.data` pozwala edycji zachować dokładny czas
serwera mimo sekundowej precyzji lokalnego pola DateTime w Drift:

- Żądanie bez klucza `data`, po poprawnym CAS, kopiuje tę wartość z aktualnego
  żywego pomiaru. Dotyczy zarówno UPSERT, jak i DELETE, odmiennie od rozszerzeń
  treningowych opisanych powyżej.
- Brak aktualnego rekordu, tombstone lub brak/NULL daty źródłowej powodują
  konflikt. Backend nie wymyśla daty i nie wskrzesza rekordu przez omission.
- Jawne `data`, również jawne `null`, zachowuje dotychczasowy kontrakt zapisu;
  ta ochrona nie jest pełną walidacją dat ani globalną niezmiennością pola.
- Hash idempotencji nadal obejmuje oryginalne żądanie bez daty, nie wynik
  rozszerzenia payloadu.

Nowy klient pomija datę przy edycji/usuwaniu zsynchronizowanego pomiaru.
Dla niewysłanego create zachowuje dokładną datę z oczekującej operacji; nie
zmienia bajtów rozpoczętej próby. Konflikt omission z tombstone'em ustanawia
trwały hold zamiast ponawiać niewykonalny zapis pod kolejnymi UUID.

**API musi zostać wdrożone przed klientem korzystającym z tego kontraktu.**
Stary backend nie uzupełni pominiętej daty. Naprawa nie odzyskuje precyzji
historycznie utraconej w lokalnej bazie lub archiwach backupu.

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
Dotyczy to ścieżki **sync**. Osobny read-only adapter push opisany poniżej
waliduje obsługiwany v1 przed zaplanowaniem powiadomień; nie naprawia JSON.
Omission zachowuje również uprzednio zapisany `weeklySchedule: null`;
jawny `null` czyści kolekcję, a obecna wartość zastępuje ją w całości.

Backend nie waliduje semantyki kolekcji, nazw, parametrów ani wersji mapy guidance;
nadal stosuje istniejący kontrakt JSON (w tym zakaz NaN/Infinity) i limity batcha.
Pełna walidacja, wznowienie treningu, podsumowanie i porównania wariantów
pozostają do implementacji w kliencie.

### Aktywności i sender push — 2026-10-19

`activityRule` i `activityOverride` rozszerzają tę samą kolekcję v1, bez migracji
SQL/API. Przykład deterministycznej reguły migracji dla profilu
`11111111-1111-4111-8111-111111111111`:

```json
{
  "weeklySchedule": {"version": 1, "entries": [{
    "id": "35b8d306-15f4-523a-abab-775435cba2d6",
    "name": "Karate", "kind": "activityRule",
    "createdAtUtc": "2026-10-19T12:00:00.000Z",
    "updatedAtUtc": "2026-10-19T12:00:00.000Z",
    "activityType": "external", "weekdays": [2, 4],
    "time": "20:00", "timeZone": "Europe/Warsaw",
    "durationMinutes": null, "planSyncId": null,
    "effectiveFromDate": "1970-01-01", "enabled": true,
    "reminderEnabled": true, "reminderMinutesBefore": 30,
    "legacySource": "legacyKarate"
  }]}
}
```

`activityType` external/fitbirek, niepuste unikalne weekdays ISO1..7, time HH:mm,
Warsaw, duration opcjonalne1..1440, reminder lead0..1440, jawne bool enabled /
reminderEnabled. Nowy wpis domyślnie reminderEnabled=false. planSyncId nullable
UUID wyłącznie dla FitBirek. effectiveFromDate / originalDate / movedDate są
ścisłymi dniami gregoriańskimi YYYY-MM-DD. Koperta: UUID, nazwa1..80 Unicode,
UTC timestamps, opcjonalny tombstone; <=500 wpisów /262144B UTF-8.

Wyjątek `activityOverride` ma `ruleId`, `originalDate`, `movedDate`,
`state: planned|completed` oraz pełny `ruleSnapshot` pól aktywności (bez koperty
i nazwy). ID=UUIDv5(ruleId,originalDate). Np. dla powyższej reguły i2026-10-20
ID=`dab2733d-181d-52b4-8be0-f782084ea8c7`. Completed FitBirek wymaga sessionSyncId
UUID; external completed i każdy planned mają brak/NULL sessionSyncId.

Przykładowy wpis przenoszący pojedyncze wystąpienie (w tej samej entries):

```json
{
  "id": "dab2733d-181d-52b4-8be0-f782084ea8c7",
  "name": "Karate", "kind": "activityOverride",
  "createdAtUtc": "2026-10-19T12:00:00.000Z",
  "updatedAtUtc": "2026-10-19T12:00:00.000Z",
  "ruleId": "35b8d306-15f4-523a-abab-775435cba2d6",
  "originalDate": "2026-10-20", "movedDate": "2026-10-21",
  "state": "planned", "sessionSyncId": null,
  "ruleSnapshot": {
    "activityType": "external", "weekdays": [2, 4],
    "time": "20:00", "timeZone": "Europe/Warsaw",
    "durationMinutes": null, "planSyncId": null,
    "effectiveFromDate": "1970-01-01", "enabled": true,
    "reminderEnabled": true, "reminderMinutesBefore": 30,
    "legacySource": "legacyKarate"
  }
}
```

`app/push/activity_schedule.py` czyta wyłącznie żywy profil z `SyncRecord.user_id`
równym `PushSubscription.user_id`; przy >1 żywym profilu nie wybiera arbitralnie.
Unknown/malformed v1 nie tworzy dynamicznych zadań i nie modyfikuje profilu.
Obowiązuje schema whitelist rodzajów, limity i plain nazwy bez kontrolnych znaków.
Sender uwzględnia enabled/reminderEnabled, tombstone i planned/moved/completed
wyjątki. Nie tworzy sesji ani fikcyjnych wykonań, nie sprawdza dowodu sesji
w celu przywrócenia reminderów completed. Zapisany completed zawsze wycisza.

Deterministyczne markery: UUIDv5(namespace=**profile UUID**,
name=`FitBirek/activity/legacyKarate` albo `FitBirek/activity/legacyTraining`).
Dla przykładowego profilu trening ma ID=`c3dd0563-ff7a-52e7-b366-0a010e74db5f`.
Obecność markera **także tombstone'a** wyłącza odpowiedni stary event; edycja
ma tombstone markera+nowy UUID. Bez markera pozostaje dotychczasowy fallback
karate wt/czw19:30 i training codziennie18:00, z istniejącą zgodą kategorii.
Pola legacySource same w sobie nie zastępują sprawdzenia deterministycznego ID.

Wire category keys nadal karate=external, training=fitbirek; mood/operations
bez zmiany. Instalacja musi mieć aktywną subskrypcję i zgodę kategorii; reguła
ma dodatkowy niezależny opt-in. Push queue używa event key `activity:SHA256`
(profil+pełna rewizja reguły/wyjątku+originalDate, zawiera czas i lead), a UNIQUE
installationId/eventKey deduplikuje dostawę. TTL15min liczone od due, bez catchup.
Przed każdą próbą sender ponownie czyta profil i sprawdza event+zgodę;
zmieniony/usunięty/przesunięty/zaliczony termin anuluje stare zadanie.
Kolejkowane legacy również anuluje po pojawieniu się markera.

Warsaw: lead odejmowany od chwili UTC startu, może przejść przez północ/DST.
Nieistniejące wiosenne HH:mm pomijamy, jesienną podwójną godzinę wybieramy raz,
pierwszy instant (fold0). Plain payload title<=80/body<=160 dla activity events;
worker nadal przyjmuje tylko allowlist tras same-origin, bez query/fragmentów
i URL z prywatnych danych. Transport SSRF/DNS pinning/VAPID/retry bez zmiany.

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
