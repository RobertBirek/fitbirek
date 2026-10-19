# Drugi pakiet audytu: klient sync

Zakres tego dokumentu: klient sync w katalogu głównym, branch
`fix/training-continuity-ux`. Pozostałe części drugiego pakietu (backend,
Mentor, backup) i końcowe wyniki opisano w
[raporcie integracji](2026-10-18-data-integrity-audit-followup.md).
Bez wdrożenia, zmiany wersji ani zależności. Wcześniejsze zmiany
workout/progress pozostają nietknięte przez ten podpakiet.

## Trwałość bez migracji

Istniejące `SyncDeferredRecords` mają tekstowy klucz `(entityType, entityId)`
i JSON. Zachowano zwykłe odroczone snapshoty oraz `_profileCollectionConflict`.
Nowe lokalne przestrzenie kluczy nie trafiają na API:

- `_syncPullQuarantine`: klucz `[accountId, pageCursor, index]`, envelope z
  kontem, kursorem końca strony, pozycją, pełnym zdekodowanym JSON `raw`,
  przyczyną oraz znacznikiem `recovered`. To nie jest kopia bajtów HTTP.
- `_syncPushHold`: klucz UUID operacji, konto, klucz encji i surowy wynik
  konfliktu. Oryginalny `payloadJson`, UUID i baseVersion próby pozostają
  w outboxie; nie są przepisywane ani zastępowane nowym żądaniem.

Oddzielne klucze zapobiegają utracie dowodów przez zastąpienie nowszym deferred
snapshotem lub `reconcile`. Nie zmieniono deklaracji Drift/Freezed/JSON,
więc migracja i generator nie są potrzebne.

## Pull

Znane typy nadal przetwarzane są rodzic-przed-dzieckiem. Nieznane typy i błędne
rekordy trafiają do trwałego dziennika w tej samej transakcji co poprawne dane
i kursor. `InvalidSyncRecord` powstaje wyłącznie przy walidacji wejścia:
koperty, parserów, znanych ograniczeń (`side`), struktury planu i brakującego
rodzica sesji. Nie przechwytujemy dowolnych wyjątków bazy jako wadliwych danych.
Błąd SQLite nadal cofa całą transakcję wraz z kursorem.

Po stronie wykonywana jest lokalna próba odzyskania zapisanych rekordów.
Brakujący rodzic może nadejść później; poprawiony snapshot v2 może zastąpić
wadliwą historię v1. Dziennik nie znika po odzyskaniu. Nieznany typ lub przyszła
struktura planu pozostają raw, bez konwersji do starego formatu. Nierozwiązana
kwarantanna znanej encji blokuje także jej lokalny push, aby nie nadpisać
niezrozumiałego stanu serwera. Dotychczasowe per-field zachowanie kolekcji
profilu i guidance pozostaje zachowane.

## Push

Jawne konflikty z `kind` (w tym `indeterminateOperation`, `operationReuse`)
trwale wstrzymują encję, kolejne operacje tej encji oraz serie zależne od
wstrzymanej sesji. Pozostałe encje mogą przejść w następnych batchach i po
restarcie. Zwykła utrata odpowiedzi sieciowej nadal pozwala ponowić identyczne
żądanie; jawna blokada serwera nie jest traktowana jako utrata odpowiedzi.

Nie dodano przycisku „wyślij mimo wszystko” ani automatycznego odrzucania.
Odblokowanie nieznanego wyniku wymaga przyszłego, autorytatywnego rozstrzygnięcia
po stronie API/administratora. Istniejąca jawna naprawa kolekcji profilu nadal
działa, teraz również sprawdza trwałą generację powiązania.

## Wylogowanie między instancjami

`SyncDao.lockOfflineAccess` zapisuje atomowo `offlineAccess=false` i nowy UUID
`deviceId`. Ten identyfikator nie jest wysyłany przez sync; służy też jako
generacja lokalnego powiązania. AuthController używa tej operacji przy blokadzie
offline. Usługi pamiętają konto i generację przy bind, a przed batchami,
po odpowiedziach oraz wewnątrz transakcji ich zastosowania odczytują stan z bazy.
Wylogowanie, zmiana konta, ponowne logowanie na A lub A–B–A unieważniają stary
przebieg. Spóźnione odpowiedzi nie usuwają outboxa ani nie przesuwają kursora.

Istniejący kafelek statusu wyjaśnia kwarantannę, rozróżnia licznik lokalnego
outboxa od pobranych danych wymagających naprawy i informuje, że zwykły retry
nie ponawia wstrzymanych operacji.

## Weryfikacja i ograniczenia

- Obserwowano RED przed implementacją dla historii malformed→valid,
  trwałych blokad push i spóźnionych wyników po wylogowaniu. Dodatkowe RED
  sprawdzono dla blokady lokalnego nadpisania, komunikatu UI i błędnego `side`.
- Końcowy focused zestaw 10 plików: **77 testów passed**. Obejmuje audit,
  service, deferred, profile collections, persistence, status tile, auth
  offline/repository, restore regression oraz sync DAO. Wyłącznie wskazany
  kontener `fit-web:release-1.13.0-26-verified`, `--network none`, `--no-pub`.
- Testy obejmują reopen plikowej SQLite, dwie niezależne instancje bazy na tym
  samym pliku, dwie usługi, logout, A–B–A, late push/pull, brak rodzica,
  potomków blokowanej sesji, niezmienność próby i wstrzyknięty błąd SQLite.
- Testy deferred dawniej używały `indeterminateOperation` jako atrapy błędu
  sieci. Teraz osobno przygotowują retryowalną utratę odpowiedzi i równolegle
  zaobserwowany snapshot; testy jawnych blokad nie zwalniają ich automatycznie.
- Na etapie tego focused przebiegu nie wykonywano pełnego suite; końcowy
  wynik integracyjny znajduje się poniżej. Nie wykonano builda ani testu
  wielokartowego Web/OPFS. Stare uruchomione
  klienty nie znają nowych blokad; przyszłe wdrożenie wymaga odświeżenia klientów.
- Dziennik zachowywany jest bez automatycznego czyszczenia, więc może rosnąć.
  Lokalny replay jest ograniczony do jednej próby na rekord na stronę/przebieg,
  ale koszt rośnie wraz z dziennikiem. Nie dodano eksportera diagnostycznego:
  zwykły backup danych aplikacji nie zastępuje kopii surowej bazy z outboxem
  i kwarantanną. Nie usuwać danych aplikacji podczas naprawy.
- Żądania wysłanego przed wylogowaniem nie da się cofnąć na serwerze;
  gwarancja klienta dotyczy kolejnych batchy i zastosowania odpowiedzi lokalnie.

Web SQLite: lock pozostaje `drift 2.28.2`, `sqlite3 2.9.4`. SHA-256 zgodne
z wcześniej zweryfikowanymi artefaktami opisanymi w `modules/structured-planner.md`:

- wasm: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- worker: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

## Uzupełnienie po spec review: zwykły CAS i wadliwa koperta historyczna

- Zwykły konflikt CAS bez `kind` jest rozwiązywany w savepoincie. Tylko
  `InvalidSyncRecord` cofa tę pojedynczą próbę rozwiązania (także wcześniejsze
  usunięcie próby lub utworzenie operacji restore). Następnie istniejący
  `_syncPushHold` zachowuje konto, UUID, pełny wynik CAS z raw rekordem,
  przyczynę i politykę `explicit-authoritative-resolution`.
- To nie jest kwarantanna pull: rekord CAS jest autorytetem odrzucenia próby,
  a nie zgodą na nadpisanie lokalnej intencji. Oryginalna próba oraz następcy
  pozostają w outboxie; poprawiona wersja z pull pozostaje deferred. Restart
  ani zwykły retry nie zwalniają blokady. Odzyskanie wymaga jawnego rozstrzygnięcia
  lokalnej intencji względem zweryfikowanej aktualnej wersji serwera; nie dodano
  automatycznego resend/discard ani ogólnego przycisku zwalniającego tę blokadę.
- Koperta CAS musi odpowiadać typowi i ID wysłanej operacji. Nieprawidłowy
  autorytet nie może zapisać innej encji. Błędy SQLite wychodzą poza savepoint
  i nadal cofają całą odpowiedź, włącznie z niezależnymi ACK.
- Przy replay pull najpierw sprawdzany jest znany typ, niepuste tekstowe ID
  i dodatnia całkowita wersja. Ściśle nowszy już zaobserwowany stan tej samej
  encji może zastąpić starszą wadliwą kopertę (`payload: null`, błędne
  `updatedAt`). Pozostała walidacja następuje po tym porównaniu. Nieznany typ,
  niewiarygodna tożsamość/wersja ani równa lub wyższa wersja nie korzystają
  z tego wyjątku. Dziennik zachowuje raw po oznaczeniu odzyskania.
- RED: oba CAS (malformed/future) i cztery kombinacje wadliwej koperty na tej
  samej/późniejszej stronie faktycznie nie przeszły przed poprawką.
- GREEN: focused `sync_review`, `sync_audit`, `sync_service`,
  `profile_collections_sync`, `deferred_sync`: **59 passed**. Nowe testy
  sprawdzają reopen SQLite, niezależny push/pull, brak nadpisania po poprawionym
  pull, odblokowanie push po bezpiecznym zastąpieniu v1, negatywne warunki
  zastąpienia oraz rollback całej odpowiedzi po błędzie SQLite w zwykłym CAS.

### Uzupełnienie quality review: oryginalne skalary i brak wiersza po restore

- CAS waliduje oryginalny rekord wspólnym parserem `validateRecord` przed
  `preserveLocal` i merge. Tryb walidacji nie zapisuje danych i nie omija
  parsowania z powodu nowszej wersji lokalnej. Opcjonalne rozszerzenia profilu
  zachowują istniejącą tolerancję; ich osobna obsługa konfliktów nie zmienia się.
  Nieprawidłowe lub brakujące `wiek` nie może zostać zamaskowane lokalnym
  payloadem i ponowione pod nowym UUID.
- Supersession uwzględnia też nowszy deferred snapshot, gdy restore usunął
  wiersz domenowy, pozostawiając pending delete. Sprawdza zgodność typu, ID
  i wersji envelope z metadanymi deferred oraz ponownie waliduje pełny rekord
  bez zapisu i bez rekurencyjnego supersession. Błędny JSON, obca tożsamość,
  rozbieżna wersja, błędny payload i przyszły schemat nie stanowią autorytetu.
  Zastąpienie historii pull nie usuwa niezależnego push hold.
- RED: 4 przypadki (dwa błędne profile preserveLocal i dwa reopen restore
  z/bez push hold) nie przeszły przed poprawką. GREEN: **70 passed** w focused
  zestawie siedmiu plików, w tym 9 nowych testów quality review oraz istniejące
  testy opcjonalnych kolekcji profilu i rollback błędów SQLite.

### Integracja schedule cloud na wspólnym drzewie

- Odtworzono **3 PASS / 3 FAIL** w `schedule_cloud_test.dart` bez cofania
  zmian backupu. Dwa testy oczekiwały retry po `ReviewServer.blockPush`, ale
  ta flaga zwraca jawny `indeterminateOperation`, a nie błąd transportu.
  Trwały hold był prawidłowym skutkiem, nie regresją `weeklySchedule` lub
  skutkiem `offlineAccess`.
- Fixture używa teraz `DioException.connectionError` i sprawdza status offline.
  Przypadek deferred jawnie przygotowuje snapshot zaobserwowany przy nierozstrzygniętej
  próbie; nie zakłada, że nieudany push wykonuje pull. Asercje niezmienności
  attempted, safe baseVersion, merge, tombstone i explicit NULL pozostają.
- Trzeci błąd pochodził ze spread surowego `Map` do payloadu: Dart tworzył
  `Map<dynamic, dynamic>`, podczas gdy dekodowanie obiektu HTTP JSON daje
  `Map<String, dynamic>`. Uzupełniono typ fixture'u bez zmiany zawartości JSON.
  Ten sam problem reprezentacji znaleziono w pięciu payloadach powiązanych
  testów `profile_collection_quarantine`; poprawiono tylko typy, nie asercje.
- Bez zmian produkcyjnego sync, backupu, kodeka lub backendu w tym kroku.
  GREEN: **61 passed** w sześciu focused plikach, w tym wszystkie 6 schedule
  cloud oraz testy przyszłego/błędnego weeklySchedule, raw hold, reopen,
  jawnego recovery i niezależnego pull.

### Integracja po pełnym przebiegu koordynatora: osiem nieaktualnych testów

Log `tool_150191a99001uYLO1vy5NhdWK6` przeanalizowano tylko w zgłoszonych
fragmentach. Focused reprodukcja trzech pełnych plików dała **27 PASS / 8 FAIL**.
Nie zmieniano kodu produkcyjnego:

- `health_shared_cursor_test`: walidacyjny błąd rekordu wymaga teraz durable
  raw quarantine, nie rollbacku całej strony. Test rozdzielono na kwarantannę
  z późniejszym poprawionym v2 i rzeczywistą awarię SQLite (trigger na drugim
  insercie). Ta ostatnia nadal wymaga rollbacku pierwszego wiersza i fullCursor,
  ale zachowania commitu legacy cursor=501 na niezależnym połączeniu.
- Health replay: jawny `indeterminateOperation` dodaje osobny push hold.
  Zamiast `getSingle` całej tabeli sprawdzany jest dokładnie ten sam deferred
  health snapshot i osobno UUID/kind nowego hold. Pełne porównania manual row,
  attempted row oraz asercje obu kursorów pozostają.
- `plan_structure_validation_test`: pusta mapa tombstone fixture dostała
  jawny typ string-keyed odpowiadający JSON HTTP. Test strony z błędną strukturą
  wymaga teraz zachowanego raw/konta/kursora oraz niezależnego poprawnego planu;
  poprawka przychodzi jako nowszy rekord v2 na późniejszej stronie, nie przez
  podmianę już odczytanej historii. Raw pozostaje po odzyskaniu. Testy odmowy
  uszkodzonego payloadu, zachowania damaged tombstone i attempted bytes zostały.
- `profile_cloud_review_test`: trzy warianty HIGH i wariant lost ACK/reopen
  używały jawnego `indeterminateOperation` jako retryowalnego błędu transportu.
  Fixture symuluje teraz connectionError i osobno obserwację deferred snapshotu.
  Zachowano safe baseVersion, scalar authority, tombstone, explicit NULL oraz
  dokładną asercję dwóch identycznych wysłań po autentycznym lost ACK.

Końcowy focused zestaw: trzy pełne zgłoszone pliki + sync audit/review/quality
review + profile collection quarantine + schedule cloud: **78 PASS / 0 FAIL**.
Na etapie tego focused przebiegu pełnego suite ponownie nie uruchamiano.

## Końcowa weryfikacja integracyjna

Koordynator uruchomił po wszystkich poprawkach cały zestaw, obejmujący także
wcześniejszy pakiet treningowy, snapshot backupu i obsługę Mentora:

- `dart tools/generate_app_version.dart --check`: PASS.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub --reporter expanded`: **907 PASS**, zero błędów.
- Backend `.venv/bin/python -m pytest -q`: **436 PASS**, PostgreSQL Testcontainers.
- Format 52 nowych/zmienionych plików Dart: zero zmian wymaganych.

Testy Fluttera wykonano w dotychczasowym obrazie narzędziowym, z bieżącym
źródłem zamontowanym do `/app`, bez sieci. Nie jest to raport wdrożenia.
