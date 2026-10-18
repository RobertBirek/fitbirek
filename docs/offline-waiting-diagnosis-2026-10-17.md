# Diagnostyka pozostającego waiting — 2026-10-17

## Wynik poprzedniej iteracji: BLOCKED, nie ready

Aktualizacja dalszej kontroli bez Runtime/Debugger SW znajduje się na końcu:
„Kontrola bez SW auto-attachment i ograniczenie RPC bridge”. Historyczne FAIL
poniżej pozostają zachowane; nie są zastępowane deklaracją naprawy Chromium.

Praca ograniczona czasowo. Nie zmieniono workera, bridge, bootstrap, generatora,
zależności, runtime ani wersji w ramach tej diagnostyki. Nie ma commit/push/deploy,
prune ani pełnego buildu Fluttera. Zachowano wszystkie siedem testów aktualizacji
i asercje spójności HTML/JS, utraty metadanych, reloadRequired oraz old-only cache.

Zmieniono wyłącznie sposób obserwacji w `tests/tools/offline_update_browser_test.py`:
podczas oczekiwania nie wysyła się już co 50 ms RPC status do poprzednika. Zamiast
tego test obserwuje natywną tożsamość `registration.active` względem zapamiętanego
obiektu A i stan activated, bez installing/waiting. Dopiero potem pojedyncza
wiadomość potwierdza content packageId B. Limit 60 s pozostaje bez zmiany.
To korekta sondy, **nie udowodniona naprawa liveness**: pierwszy przebieg 7/7 PASS,
kolejny 6/7 PASS, basic custom A→B FAIL z waiting przez 60 s. Dalszy przebieg
instrumentowany potwierdził ten sam FAIL przy nieinwazyjnej sondzie.

## Co wykazała instrumentacja

Runner tymczasowy `/tmp/opencode/offline_waiting_trace.py` generuje instrumentowany
worker tylko w katalogu fixture. Produkcyjne pliki wejściowe pozostają nietknięte.
Śledzi install start/core/root/manifest/beforeSkip/afterSkip/end, call i wynik
Promise skipWaiting, activate start/end, waitUntil/respondWith, cache open/match/
put/keys, konsumowanie body, SHA zasobów, clients.get/matchAll, błędy/rejections,
zdarzenia registration/statechange i CDP workerVersionUpdated.

Konkretny FAIL bez ciągłego RPC do A:
`/tmp/opencode/offline-waiting-evidence-204808/events.jsonl`.
Podsumowanie: `python3 /tmp/opencode/summarize_waiting_trace.py /tmp/opencode/offline-waiting-evidence-204808`.

Względem początku run:

| czas [s] | zdarzenie |
|---:|---|
| 8.076 | B install.start; A activated, B installing |
| 8.317 | wszystkie pliki core zweryfikowane SHA/length |
| 8.339 | root alias cache.put zakończony |
| 8.361 | zapis manifestu metadanych zakończony |
| 8.362 | rzeczywiste wywołanie self.skipWaiting |
| 8.363 | Promise skipWaiting fulfilled, install.afterSkip |
| 8.364 | install.end, waitUntil fulfilled; B → installed |
| 8.367 | CDP: A activated/running → activated/stopping |
| 8.392 | CDP: A → activated/stopped |
| 8.393 | CDP: A ponownie starting dla żądania main.dart.js A |
| 8.409 | CDP: A znowu activated/running; B nadal installed |
| ~68 | limit: A active, B waiting; brak activate.start B |

Nie ma oczekującego Promise install, cache.put, odczytu/hashowania body lub
handshake klienta. Przy zrzucie oba workery mają `__fitPending: {}`. Żądanie main
obsłużone po restarcie A kończy respondWith; wszystkie zaobserwowane operacje
zostały rozstrzygnięte. Oczekiwanie następuje **pomiędzy installed a activating
w zarządzaniu rejestracją przez przeglądarkę**, nie wewnątrz funkcji install Fit.

Stack rzeczywistego wywołania skipWaiting w instrumentowanym B:

```text
at http://127.0.0.1:46409/flutter_service_worker.js?v=fixed-token:11:64
at http://127.0.0.1:46409/flutter_service_worker.js?v=fixed-token:290:46
```

Pierwsza linia to wrapper rejestrujący native call, druga odpowiada końcowi
install po core/root/metadata. Oryginalny hash skryptu B:
`b82cc6bcf7542bdced33dd822d7e65317b119cd1462cc575b1bbdbb8503535ae`;
hash faktycznie serwowanego skryptu instrumentowanego:
`6bdb91486a94ee28c3c4ac79d1b6e7337ca0f7bde6d6dda42bad9e2918541cf1`.
Content packageId B:
`00724bd7c2fcf5ca3cbe4de6cdc399715d7a14db2e1b8d152061107ceaf375b6`.
Log HTTP zapisuje hash dostarczanych bajtów i ten sam URL z ?v=fixed-token.
Nie jest to worker A omyłkowo uznany za B ani nieodświeżony kod bez skipWaiting.

Wcześniejszy FAIL asset-only ma analogiczny ślad w
`/tmp/opencode/offline-waiting-evidence-201215/`; kontrolowana próba diagnostyczna
w `...-201447/` pokazuje, że **drugie** wywołanie native skipWaiting, już w
zainstalowanym B, zmieniło active na activating, potem activated. Nie wprowadzono
tego jako retry do aplikacji ani testów akceptacyjnych.

## Izolacja od kodu Fit i Playwright

`/tmp/opencode/pure_sw_waiting_repro.py` zawiera mały SW: trzy pliki precache,
install/skipWaiting/activate, fetch z cache do bufora oraz message z publicznym
VERSION/trace. Nie ma generatora, SHA manifestu Fit, pinów, metadanych routingu,
MessageChannel identyfikacji dokumentu, Fluttera, API, IndexedDB ani kont.

Odtworzenie na Chromium **148.0.7778.96**:

```sh
FIT_PURE_RELAUNCH=1 FIT_PURE_DIAG=1 python3 /tmp/opencode/pure_sw_waiting_repro.py async 10
```

W run `pure-sw-async-203333.json` 2/10 pozostają waiting. Oba potwierdzają zakończenie
core i install waitUntil, skipWaiting fulfilled. Po dodatkowym 10-sekundowym okresie
**bez wiadomości do SW** nadal A active/B installed; pojedyncze diagnostyczne
skipWaiting w zainstalowanym B daje B activating/activated. Ten okres jest sondą
minimalnego repro, nie zwiększeniem timeoutu aplikacji lub siedmiu testów.

Warianty nie wykazały naprawy:

- skipWaiting synchronicznie na początku install: również waiting (3/10);
- skipWaiting po core, bez await: również waiting (2/10);
- zapisanie Promise na początku i await po core: również waiting (1/10);
- bez ponownego register przy reloadzie: również waiting (2/15);
- wyłączenie inspekcji sieci SW w Playwright: również waiting (2/15).

Minimalny repro uruchomiono również na Chromium **140.0.7339.16** z istniejącego
obrazu Playwright 1.55; 1/10 waiting. Nie zmieniano toolchainu aplikacji.

`/tmp/opencode/pure_sw_raw_cdp.py` uruchamia Chromium przez subprocess i używa
surowego WebSocket CDP wyłącznie do stron — bez sterownika Playwright:

```sh
FIT_RAW_RPC=1 python3 /tmp/opencode/pure_sw_raw_cdp.py 15
```

3/15 waiting (próby 11,13,14): A active z pustym trace po ponownym uruchomieniu,
B trace ma core.done/skip.call/skip.fulfilled/install.end/waitUntil.fulfilled.
Dowód: `/tmp/opencode/pure-sw-raw-cdp-plain-2043.json`.
Bez RPC w serii 15/15 PASS; samo dołączenie debuggera SW 15/15 PASS. Wcześniejsze
30 ukończonych prób bez RPC także PASS; oddzielna seria skończyła się błędem
odczytu niepełnego DevToolsActivePort przy starcie Chrome (nie jest PASS).

**Wniosek o zakresie przyczyny:** jest reprodukowalny wyścig liveness przeglądarki
przy wycofywaniu i ponownym uruchomieniu poprzednika; ruch do A może go wyzwolić.
Sonda 50 ms zwiększa ryzyko, ale jej usunięcie nie usuwa problemu, bo prawdziwy
reload nadal żąda entrypointu. Minimalny repro wyklucza potrzebę dowolnego
z powyższych mechanizmów Fit. Nie ustalono konkretnego błędnego pola/warunku C++
w binarce Chromium — nie przypisujemy temu niezweryfikowanego numeru znanego buga.

Kod referencyjny Chromium `ServiceWorkerRegistration::ActivateWaitingVersionWhenReady`,
`OnNoWork` i `IsReadyToActivate` uzależnia promocję od zakończenia pracy poprzednika;
spełnienie Promise JS skipWaiting nie jest potwierdzeniem activated:
https://raw.githubusercontent.com/chromium/chromium/main/content/browser/service_worker/service_worker_registration.cc

## Alternatywa wymagająca decyzji właściciela

Zamiast automatycznego przełączania w wyścigu reloadu: jawne „Aktualizacja gotowa —
zastosuj i przeładuj” skierowane do **konkretnego installed/waiting packageId**,
po sprawdzeniu core i potwierdzeniu aktualnej rejestracji. Jednorazowa akcja
użytkownika, bez pętli skipWaiting, bez claim, bez przeładowania innych kart i bez
pobrania pełnego pakietu. Czeka na faktyczną zmianę active/controller, po czym
przeładowuje tylko kartę wywołującą; stare karty nadal podlegają pinom/fail-closed
i reloadRequired. Stale/replaced waiting worker musi dać jawny błąd/nową ofertę,
nie być potraktowany jak sukces dla innego workera.

W minimalnym SW taki **osobny** tryb, z wywołaniem dopiero po installed,
dał 15/15 PASS (`pure-sw-explicit-205051.json`). Nie dowodzi to pełnej akceptacji:
próba symulacji tej polityki przez tymczasowy runner dla siedmiu testów dała
6/7 PASS; legacy lostAfter miał zastąpienie waiting workera nową instancją, więc
jednorazowa komenda do poprzedniego waiting nie może oznaczać sukcesu. To wymaga
oddzielnego projektu/testu obsługi replacement, nie ukrytego ponawiania.

Dlatego alternatywa **nie została wdrożona** i nie ma deklaracji stable 7/7.
Main powinien zdecydować o jawnej ścieżce aktualizacji lub dalszym badaniu natywnej
aktywacji. Sam wzrost timeoutów, bezwarunkowy claim, cykliczne skipWaiting lub
pominięcie testu nie są naprawą.

## Kontrola bez SW auto-attachment i ograniczenie RPC bridge

Dalszy research z `unattached-*.json` wykazał autonomiczne opóźnienie także bez
jakiegokolwiek CDP/Playwright. Przy RPC do poprzednika wystąpiło 3/30 opóźnień
ponad 5 s w Chrome 140; po pozostawieniu natywnej obserwacji i ciszy następca
aktywował się po około 31 s, bez zamykania dokumentów. Kontrola bez RPC: 30/30.
Mechanizm źródłowy Chromium: restart poprzednika resetuje jego expedited idle
termination (`needs_terminated_asap`), pozostawiając zwykły próg idle. Dlatego
Runtime/Debugger utrzymujący worker albo kolejne RPC mogą znacznie wydłużyć
obserwowane waiting. Nie jest to dowód, że wszystkie dotychczasowe opóźnienia
miały jedną przyczynę, ani gwarancja natychmiastowej aktywacji.

Wykonano kontrolę wszystkich siedmiu rzeczywistych testów z **jedną różnicą**
w sterowniku: wykluczono typ `service_worker` z `Target.setAutoAttach`. Nie
wyłączono samych SW, żądań RPC z dokumentów, kontroli stron, CDP stopAllWorkers,
asercji bezpieczeństwa ani polityk sieci/przeglądarki. Potwierdzenie poprzez
`Target.getTargets`: istnieją rzeczywiste SW, wszystkie `attached:false`;
`context.service_workers` jest pusty (brak Runtime sterownika).

Pomocnik `tests/tools/offline_browser_driver.py` tworzy **tymczasową kopię**
istniejącego drivera. Nie modyfikuje instalacji, nie instaluje zależności i
weryfikuje dokładnie dwa oczekiwane miejsca konfiguracji auto-attachment.
Standardowe wykluczenie browser/tab pozostaje, dodane jest tylko service_worker.
Nieznany układ drivera jest błędem, nie pominięciem testu. Oryginalny tryb
instrumentowany pozostaje dostępny: `FIT_OFFLINE_ATTACH_SW=1`.

Old-only test zatrzymuje teraz **rzeczywisty origin** oprócz ustawienia offline
strony, bo emulacja sieci dla stron nie obejmuje niepodłączonego targetu SW.
Wszystkie asercje HTML/JS, utraty routingu, stop/restart, statusu, consent,
IndexedDB/push cache i old-only offline pozostają zachowane.

Nowe świadectwa:

- Kontrola tymczasowa: 7/7 PASS, 126,9 s; dowód
  `/tmp/opencode/offline-no-sw-attach-2v6eh9i8/report.json`, bez podłączonych SW.
- Dwa kolejne standardowe przebiegi z pomocnikiem: **7/7 PASS w 189,3 s** oraz
  **7/7 PASS w 131,3 s**. Niektóre scenariusze jawnie raportują 31,1–31,3 s
  oczekiwania. Limit testu 60 s bez zmian; brak retry skipWaiting/claim.
- Końcowy, trzeci standardowy przebieg po dodaniu rzeczywistej bramki instalacji
  w teście oldStatus: **7/7 PASS w 80,1 s**. Wstrzymano pobranie core B w lokalnym
  serwerze, następnie dokument A wywołał status/prepare/cancel po trzy razy podczas
  installing. Każde wywołanie dało error/reloadRequired, zero postępu i brak pobrań
  pełnego pakietu. Zwolnienie bramki pozwoliło na zwykłą aktywację; pozostałe
  asercje starego dokumentu i gotowego B pozostają bez zmian.
- Node 29/29 PASS, cold Chromium 2/2 PASS, Nginx 1/1 PASS, generator/analyze/
  format/diff-check PASS.

Poprawka produktu ma wąski zakres: `offline_client.js` odczytuje natywne sloty
rejestracji **przed RPC**. Gdy następca jest installing/waiting, status/prepare/
cancel zwracają `state:error`, istniejący kod `reloadRequired`, zerowy postęp i
komunikat o trwającej aktualizacji oraz potrzebie przeładowania. Nie otwierają
MessageChannel, nie budzą A/B, nie pobierają pakietu, nie anulują zadania i nie
wywołują aktywacji. Po zmianie slotów kolejne wywołanie znów może komunikować się
z aktualnym workerem. TDD: oba testy braku RPC/tymczasowości najpierw FAIL, po
guardzie PASS. Protokół 1 i sygnatury niezmienione; UI używa istniejącego
reloadRequired/komunikatu, bez nowego kodu updatePending.

To usuwa własny polling aplikacji jako źródło wybudzania poprzednika i rozdziela
native lifecycle od ingerencji testowego Runtime. Nie naprawia implementacji
Chromium ani nie obiecuje braku naturalnego opóźnienia 31 s. Pełny build i E2E
aplikacji oraz fizyczne urządzenia pozostają obowiązkiem integracji głównej.
