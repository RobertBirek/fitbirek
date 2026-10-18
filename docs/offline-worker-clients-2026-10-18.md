# Klienty DedicatedWorker/SharedWorker — zakres i dowody

## Przyczyna i minimalna poprawka

Reprodukcja review jest prawdziwa dla nieprzypiętego Blob workera: po complete
prepare i zatrzymaniu originu window fetch działa, a fetch z blob kończy się
TypeError. Blob nie ma DOM znacznika ani pobranego przez SW skryptu, więc nie ma
zaufanego powiązania z konkretnym pakietem. Nie wolno uzupełniać go z PACKAGE,
globalnego active/previous, query ani przez wyszukanie „jakiejś” karty.

Osobny probe rzeczywistego Chromium wykazał, że dla plikowych workerów używanych
przez aplikację przeglądarka dostarcza potrzebne powiązanie:

```text
GET /probe-worker.js destination=worker
  clientId=<ID dokumentu A> resultingClientId=<ID dedicated workera>
GET /sqlite3.wasm
  clientId=<ten sam ID dedicated workera> resultingClientId=""

GET /probe-worker.js destination=sharedworker
  clientId=<ID dokumentu A> resultingClientId=<ID shared workera>
GET /sqlite3.wasm
  clientId=<ten sam ID shared workera> resultingClientId=""

GET /drift_worker.dart.js destination=sharedworker
  clientId=<ID dokumentu A> resultingClientId=<ID workera Drift>
GET /sqlite3.wasm
  clientId=<ID workera Drift> resultingClientId=""
```

Nie trzeba dodawać wrappera ani zmieniać URI w `web_connection.dart`.
Istniejący zapis resultingClientId częściowo obsługiwał ten przypadek, ale miał
dwie luki: zapisywał przypięcie **przed** weryfikacją skryptu i wysyłał protokół
DOM identifyShell także do workerów, ryzykując kolizję z ich protokołem wiadomości.

Poprawka w `web/offline_worker.js.template`:

1. DOM identity handshake jest wykonywany wyłącznie wobec `WindowClient`.
2. Nowy file-backed worker dziedziczy **konkretny zweryfikowany manifest twórcy**
   dopiero po poprawnej kontroli pobranych/odczytanych bajtów skryptu.
3. Dziedziczenie dotyczy destination worker/sharedworker (oraz istniejącej
   nawigacji dokumentu), nie dowolnego resultingClientId zasobu.
4. Zapis utrzymuje powiązanie clientId→manifest w routing CacheStorage; restart
   SW go nie zmienia. Sprzeczne istniejące przypięcie daje integrity, nie nadpisanie.
5. Worker bez tego przypięcia nie może uzyskać go przez wiadomość identifyShell
   lub query. Utrata routingu + restart skutkuje fail-closed.

Kontrakt window.fitOffline/protokół 1 pozostaje bez zmian. Nie dodano interfejsu
rejestrującego dowolne clientId/URL/pakiety. API/auth/export/foreign-origin nadal
poza interceptorem. Zmiana nie czyści IndexedDB, cache A ani push.

## Testy RED → GREEN

Trzy nowe testy Node najpierw FAIL, po poprawce PASS:

- worker z odziedziczonym przypięciem po restarcie SW nie otrzymuje protokołu DOM;
- błąd integralności skryptu lub zwykły request script nie tworzy worker pin;
- nieprzypięty worker/blob nie uzyskuje nowego pakietu przez sfałszowaną tożsamość/query.

Zachowane wszystkie poprzednie 29 testów; obecnie **32/32 PASS**.

`tests/tools/offline_workers_browser_test.py`: **3/3 PASS**, rzeczywisty Chromium
bez auto-attachment Runtime/Debugger SW:

1. Dedicated i SharedWorker: pełny pakiet → zatrzymanie SW przez CDP → zatrzymanie
   prawdziwego originu → fetch z cache. Rzeczywisty SQLite i CanvasKit Wasm mają
   zgodne SHA; CanvasKit przechodzi WebAssembly.validate w obu workerach.
2. Dwie karty A/B, zmienione bajty probe-worker.js i version.txt, aktywacja B,
   osobne workery A/B, restart SW i origin stopped. Worker A dostaje A, B dostaje B.
3. Ten sam scenariusz z usunięciem routing cache i ponownym restartem SW:
   workery A i B są odrzucone; window B odzyskuje swoją tożsamość, ale nie może
   przez to automatycznie przypisać sobie starego workera A.

`tests/tools/offline_drift_probe.dart` to mały harness kompilowany przez
`dart compile js` w istniejącym przypiętym builderze — nie pełny build Fluttera.
Używa faktycznego Drift 2.28.2 i **oryginalnego** `web/drift_worker.dart.js` oraz
`web/sqlite3.wasm`. Po origin stop i restarcie SW otwiera świeże remote executory
i wykonuje `SELECT 41 + 1 AS answer`:

- domyślny zdalny wybór Drift (w użytym Chromium sharedIndexedDb), bez inMemory;
- wymuszony `unsafeIndexedDb` przez istniejące WasmDatabase.probe/open: faktyczny
  DedicatedWorker, bez fallbacku na okno.

Testowy audit CacheStorage potwierdza sqlite fetch od Client typu worker/sharedworker
z URL oryginalnego Drift. Fixture dodaje odrębne query `fixture=...` tylko po to,
by wymusić świeże upstream workery i nie wykorzystać modułu SQLite z poprzedniego
połączenia online. Nie jest to dowód tożsamości pakietu: wybór zawsze wynika z
przypięcia twórcy, a sam zasób przechodzi sprawdzenie hash/length.

Oryginały pozostają byte-identical:

```text
drift_worker.dart.js 6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610
sqlite3.wasm         922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117
```

CanvasKit Wasm fixture pochodzi z istniejącego obrazu Flutter 3.35.4
`fit-web:candidate-1.14.0-27`, wyłącznie przez create/cp/rm izolowanego,
nieuruchomionego kontenera. Nie było buildu, uruchomienia runtime ani portów.

## Jawne granice wsparcia

- Wspierane i sprawdzone są file-backed DedicatedWorker i SharedWorker oraz
  rzeczywiste zdalne executory Drift. Nie zmieniono `web_connection.dart`.
- Nie deklarujemy ogólnego wsparcia dla dowolnych Blob workerów. Bez zaufanego
  pobrania skryptu nie dziedziczą client pin i ich fetch jest fail-closed.
- Chromium może wysłać fetch z nested DedicatedWorker z pustym clientId mimo
  wcześniejszego script fetch z resultingClientId. Takie żądanie jest odrzucane,
  chyba że przeglądarka poda wiarygodny clientId z przypięciem. Nie jest zgadywane
  na podstawie URL/referrer/otwartych kart. SharedWorker w użytym Chromium nie ma
  konstruktora Worker; brak tego feature jest jawnie rejestrowany w fixture.
- SQL test dowodzi realnej obsługi aktualnej konfiguracji Drift bez inMemory,
  nie wszystkich opcjonalnych backendów OPFS/COOP/COEP i threaded rendererów.
- Test CanvasKit dowodzi dostępu do prawdziwych bajtów Wasm z obu workerów i ich
  poprawności, nie pełnego renderowania przez dowolny blob/threaded renderer.
  Rzeczywisty rasteryzator całej aplikacji pozostaje przedmiotem E2E main.

## Polecenia i regresje

```sh
node --test tests/tools/offline_worker_test.cjs tests/tools/offline_client_test.cjs
python3 tests/tools/offline_workers_browser_test.py
python3 tests/tools/offline_update_browser_test.py
python3 tests/tools/offline_browser_test.py
python3 tests/tools/offline_nginx_test.py
```

Końcowe regresje w tej iteracji: update **7/7 PASS** (172,4 s, obejmuje naturalne
31 s oczekiwania w trzech scenariuszach), cold **2/2 PASS**, Nginx **1/1 PASS**,
generator i skupiony analyze PASS. Format harnessu sprawdzany osobno.
Bez pełnego buildu aplikacji, zmian UI/workout/fontów/katalogu/toolchainu/deps,
wersji, produkcji, commit/push. Main powinien ponownie wygenerować wynikowy worker
po finalnym buildzie; zmieniony template nie podmieni sam istniejącego artefaktu.
