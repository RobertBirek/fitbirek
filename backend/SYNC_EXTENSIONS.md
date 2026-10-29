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
| `profile` | `filterPresets`, `exerciseVariants`, `weeklySchedule`, `fitnessProtocols`, `trainingPrograms` |
| `fitnessTest` | `customProtocol` |
| `workoutSession` | `guidance` |
| `workoutSet` | `variantId`, `variantLabel`, `side`, `setRole` |
| `personalRecord` | `variantId`, `variantLabel`, `side` |
| `workoutPlan` | `structure` (z kontrolą zgodności ID opisaną poniżej) |

Przy zaakceptowanym UPSERT istniejącego, żywego rekordu każdy z tych kluczy
jest kopiowany z aktualnego snapshotu tylko wtedy, gdy żądanie go **nie zawiera**.
Jawne `null` zapisuje `null` (wyczyszczenie); obecna wartość zastępuje całą
poprzednią wartość, bez deep merge (wyjątek: niezmienne rewizje testów poniżej).
Pozostałe klucze nadal podlegają zwykłemu
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

Backend nie waliduje semantyki tych trzech kolekcji, nazw, parametrów ani wersji mapy guidance;
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

## Własne testy sprawnościowe v1 — 2026-10-21

Kontrakt: `docs/superpowers/specs/2026-10-21-custom-fitness-tests.md`;
wspólny fixture: `tests/fixtures/fitness_protocol_v1.json` w katalogu repozytorium.
Walidator `app/sync/fitness_protocols.py` dotyczy wyłącznie dwóch istniejących
typów encji, bez SQL/migracji, treningów, PR ani fikcyjnych wyników definicji:

- `profile.fitnessProtocols`: opcjonalne/null lub ścisłe `{version:1, entries}`,
  maksymalnie 500 wpisów wraz z tombstone'ami i 262144 bajty kanonicznego JSON
  UTF-8. Wpis ma wyłącznie znane pola v1 i maksymalnie 32768 bajtów. Nieznane
  wersje/pola są odrzucane, nie obcinane. Długości tekstów to punkty Unicode
  (`len` w Pythonie), nie bajty ani jednostki UTF-16.
- UUID rewizji/rodziny i opcjonalnego rodzica są niezależne od katalogu oraz
  kolejności pull. Nie ma FK do innych protokołów, wariantów ani ćwiczeń.
  Istniejące ID nie mogą zniknąć (także przez pustą kolekcję/null). Dla tego
  samego ID można zmienić tylko `updatedAtUtc`/`deletedAtUtc`. Zmiana zasad lub
  nazwy wymaga nowego UUID; gałęzie z niedostępnym rodzicem są dozwolone.
- `fitnessTest` z markerem `typ: customFitnessTestV1` **lub obecnym kluczem**
  `customProtocol` wymaga pełnego payloadu z fixture: typ/data/wynik/score oraz
  `{version:1, protocolId, familyId, snapshot}`. ID muszą zgadzać się ze
  snapshotem. `score:0` to padding, nie punktacja. Reps to całkowita wartość
  numeryczna 0..1e9 (18 i18.0 są dozwolone, SQLite REAL nie zmienia semantyki);
  time/distance to skończone liczby 0..1e9; bool nie jest liczbą wyniku.
- `loadKg` null lub 0..1000; `loadBasis` null wtedy i tylko wtedy, gdy kg null,
  w przeciwnym razie total/perImplement. Nullable side nie oznacza both.
  Snapshot wariantu stosuje dotychczasową kopertę i limity (loadKg >0..1000,
  pauseSeconds int 0..3600, opcjonalne teksty do 1000 znaków), tylko znane
  pola i zgodny exerciseId; nie wymaga wariantu w bieżącej kolekcji.
- Nullable pola protokołu supersedesId/loadKg/loadBasis/side/variantSnapshot/
  timeLimitSeconds można pominąć: walidacja i porównanie semantyczne traktują
  omission jak null. Normalizacja jest wyłącznie kopią na potrzeby kontroli;
  nie zmienia raw payloadu, attempted operacji ani request_digest.
- Znaczniki czasu to ścisłe momenty gregoriańskie ISO8601 UTC z Z (rok1..9999,
  opcjonalna część ułamkowa1..6 cyfr), updated>=created,
  deleted<=updated. Data próby może poprzedzać utworzenie protokołu i nie jest
  zastępowana czasem synchronizacji. Zakaz przyszłej próby pozostaje kontrolą
  formularza; backend nie wprowadza ograniczenia dat dla starych wyników.

Walidacja działa **po CAS oraz `revised_record_payload`**. Omission zachowuje
rozszerzenie z żywego rekordu; attempted payload i jego request_digest pozostają
nietknięte. Istniejący żywy custom wynik nie może przejść w legacy, wyczyścić
protokołu ani zmienić zamrożonego wrappera/snapshotu (porównanie kanonicznego
JSON, bez zależności od kolejności kluczy). Korekty daty/wartości są dozwolone.
Brak rozszerzenia i markera zachowuje dotychczasową, ogólną akceptację legacy,
w tym typy z wartościami cm i nieznane payloady. Inne kolekcje pozostają opaque.

Błąd kontraktu daje czytelne HTTP 422 `Invalid fitness extension: ...` i rollback
całego batcha: bez częściowego SyncRecord, SyncChange ani SyncOperation. DELETE
pomija walidację custom/profilu, by umożliwić usunięcie nieczytelnej historii;
nadal obowiązuje generic finite JSON envelope, CAS i idempotencja. Tombstone
nie dziedziczy rozszerzeń przy jawnym revival, jak dotychczas.

API wymaga osobnego wdrożenia **przed** nowym klientem; ta implementacja nie
oznacza wdrożenia ani zgody na zmianę produkcji.

## Role serii i programy A/B — 2026-10-28

Kontrakt: `docs/superpowers/specs/2026-10-28-training-sets-programs-design.md`,
sekcje 1/5/6. Bez nowych typów encji, DDL, migracji Alembic ani backfillu.
Bieżący klient: [dane i restore](../docs/modules/training-sets-programs-data.md),
[prowadzenie i programy](../docs/modules/training-sets-programs-ui.md),
[backup4 i zgodność](../docs/modules/backup.md). Backend nie implementuje
klientowego merge immutable core, rotacji ani oceny dowodu ukończenia.

- `workoutSet.payload.setRole` jest opcjonalne: jawne `null` albo dokładnie
  string `working` / `warmup`. Pydantic waliduje typowany literal w trybie
  strict, bez konwersji liczb/bool/list/map i bez wartości domyślnej. Inne
  wartości dają HTTP 422 podczas walidacji całego żądania, **przed zapisami**,
  także dla DELETE. Nie wprowadzamy tej walidacji dla innych typów encji.
- Brak / `null` zachowuje dotychczasową semantykę obliczeń (legacy), nie stanowi
  dowodu historycznie świadomie wybranej roli. Nie przepisujemy logów ani PR.
  Omission przy aktualizacji żywej serii zachowuje jej rolę, także zapisany
  `null`; explicit `null` resetuje rolę do legacy. DELETE nie dziedziczy roli,
  a revival nie kopiuje jej z tombstone'a. Dotyczy to tylko `workoutSet`, nie PR.
- `profile.payload.trainingPrograms` jest optional/nullable opaque JSON.
  Omission zachowuje całą kolekcję wyłącznie z żywego profilu, również `null`;
  explicit `null` czyści ją, obecna wartość zastępuje całość bez deep merge.
  DELETE/revival nie dziedziczą kolekcji. Backend nie waliduje wersji/koperty,
  programów, terminów, granicy zakończenia, referencji ani dowodów ukończenia;
  nie scala wpisów i nie planuje powiadomień. To odpowiedzialność klienta.
  Nadal obowiązuje ogólny kontrakt finite JSON i limit 100 operacji w batchu.
- `structure` i `guidance` pozostają opaque, również dla schema2 i przyszłych
  wersji. Istniejący guard zgodności `cwiczeniaIds` przy omission struktury
  pozostaje bez zmian; nie dodajemy walidacji całego schematu programu/planu.
- Walidacja nie zmienia attempted payloadu ani hasha. Zachowanie optional
  extensions następuje wyłącznie na kopii snapshotu po CAS/idempotencji;
  retry, `operationReuse`, historia wersji i rollback całego batcha bez zmian.
- Mentor wyklucza **wyłącznie jawny `setRole: "warmup"`** z projekcji serii
  i trendu. Filtr działa w SQL przed limitem 144 serii, więc nowsze rozgrzewki
  nie wypierają working/legacy. Missing/JSON null i working nadal liczą się
  jak wcześniej. Nie zmieniamy selekcji zakończonych sesji ani ich licznika;
  warmup-only może mieć pustą listę serii, bez dowodu progresji. Projekcja
  nie zapisuje zmian do źródłowych rekordów.

### Zgodność i przyszła publikacja

Przeczytano `DEPLOY.md`. **API-first** pozostaje wymaganą kolejnością przyszłego,
osobno zatwierdzonego wydania: stary backend nie ochroni pominiętych nowych pól
i nie odfiltruje rozgrzewek w Mentorze. Ochrona omission nie daje staremu
klientowi semantycznej zgodności: może on liczyć warmup jako PR/progresję,
nie rozumieć schema2, programów ani backup4. Potrzebny jest plan aktualizacji
klientów, bez resetowania danych/outboxa. Ten task niczego nie publikuje;
produkcja, konfiguracja i wersja wydania pozostają nietknięte.

### Weryfikacja Task 1

Python **3.12.3**, istniejący `.venv` z zależnościami instalowanymi przez
`make test-health` z `--require-hashes`; Docker/Testcontainers, izolowany
PostgreSQL16 z przypiętym obrazem z `tests/conftest.py`, bez SQLite/produkcji.

```sh
# RED przed implementacją i GREEN po niej (ten sam selektor):
.venv/bin/python -m pytest -q tests/test_sync.py tests/test_mentor_context.py \
  -k 'extension or set_role or training_v2 or only_explicit_warmup'
# Cały backend na aktualnym kodzie:
.venv/bin/python -m pytest -q
```

- RED: **40 failed, 62 passed, 112 deselected**, 150.39s; oczekiwane błędy
  invalid role zaakceptowane zamiast422, utrata omission i trend warmup.
- GREEN focused: **102 passed, 112 deselected**, 173.84s.
- GREEN pełny backend: **691 passed**, 867.71s.
- Logi: `/tmp/opencode/training-programs-backend-{red,green,full}.log`.
  Baseline hash-locked health: `training-programs-backend-baseline-health.log`
  w tym samym katalogu. Niezależny review przed Task2 pozostaje osobną bramą.
