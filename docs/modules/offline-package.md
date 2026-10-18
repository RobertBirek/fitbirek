# Pakiet statyczny offline (web)

## Własność i granice

- Web/ops: `tools/generate_offline_package.dart`,
  `web/offline_worker.js.template`, `web/offline_client.js`, wpis skryptu
  w `web/index.html`, `web/flutter_bootstrap.js`, krok postbuild w `deploy/docker/web.Dockerfile`,
  reguła brakujących statyk w szablonie `deploy/docker/web-nginx.conf`,
  `tests/tools/offline_*` i `tests/tools/generate_offline_package_test.dart`.
- UI/adapter Dart: osobny właściciel `lib/features/offline/`; recovery treningu
  ma jeszcze oddzielnego właściciela. Nie mieszać tych zmian z training-rhythm.
- Nie zmieniać `/docker/fit`, danych, IndexedDB, outboxa, workera `/push/`,
  portów, proxy, toolchainu, zależności ani wersji aplikacji w tym zadaniu.

## Generacja

Po **finalnym** `flutter build web --release --no-web-resources-cdn` uruchomić:

```sh
dart tools/generate_offline_package.dart
```

Generator nadpisuje `build/web/flutter_service_worker.js` pod URL używanym
przez niezmienioną rejestrację loadera Flutter 3.35.4. Loader **nie wysyła**
`skipWaiting` — wcześniejsze stwierdzenie o takim handshake było błędne. Manifest
jest wbudowany w worker; cold offline nie potrzebuje fetch manifestu.
`build/web/offline_package.json` służy też inspekcji rozmiaru i hashy. Wszystkie
ścieżki są relatywne do scope workera; bridge używa `document.baseURI`.
Reguła Nginx nadal daje skryptom/manifestom `no-cache`; została rozszerzona o
rozszerzenia obrazów/fontów/CSS/pozostałych statyk, tak aby brakujący plik dawał
404 zamiast index HTML 200. Fallback SPA i routing API przez Caddy są bez zmian.

Manifest ma posortowane ścieżki, rzeczywiste długości i SHA-256. `packageId`
jest SHA-256 kanonicznego JSON zawierającego listę plików, core i sumę bajtów.
Wykluczone są manifest wynikowy, worker wynikowy, template, source maps,
ukryte pliki, kompresowane duplikaty, API/auth/export i osobny push worker.
Pozostałe lokalne statyki finalnego buildu (w tym wszystkie ilustracje, katalog,
fonty, SQLite i warianty CanvasKit) należą do pełnego pakietu.
Generator nie dodaje zależności Dart: `crypto` jest tylko zależnością przechodnią,
więc używane jest `sha256sum` obecne w przypiętym linuksowym builderze.
Uruchamianie generatora na hoście bez coreutils nie jest obsługiwane.

Generator dodaje do finalnego index znacznik `fit-offline-shell` (SHA-256 listy
plików/hashy/core całego buildu **przed** dodaniem znacznika i query do index)
i query `fit-shell` do URL bootstrap. Bootstrap przekazuje ten sam identyfikator
w URL entrypointu. Zapobiega to sytuacji, w której legacy Flutter SW pobiera nowy
index online-first, ale serwuje stary bootstrap/main cache-first. Query nie
zastępuje SHA/length verification; pełny packageId nadal zależy od rzeczywistych
finalnych bajtów całego manifestu, bez rekursywnego hashowania manifestu/workera.
Powtórna generacja zastępuje znacznik i query deterministycznie.
Shell identity obejmuje również zmiany samych statyk: ten sam `main.dart.js`
nie jest wystarczającym dowodem, że stary dokument należy do nowego pakietu.
`packageId` nadal jest SHA-256 rzeczywistego finalnego manifestu po dodaniu
znacznika, z rzeczywistymi końcowymi SHA/długościami wszystkich plików.

### Core a jawny pełny pakiet

Instalacja pobiera tylko core: index, bootstrap/loader/main JS, bridge,
mentor/push client, manifest PWA, SQLite/Drift worker, manifesty zasobów/fontów,
katalog ćwiczeń, fonty aplikacji/MaterialIcons i startup Roboto oraz
CanvasKit JS/Wasm (standard + chromium). To infrastruktura startu, nie deklaracja
gotowości wszystkich zasobów. Root dostaje jawną kopię index; fallback nawigacji
korzysta z tego samego zweryfikowanego index. Nieodwiedzone ilustracje i pełne
fallbacki symboli/emoji pobierane są dopiero po `prepare({packageId})` (albo zwykłym użyciu
konkretnego zasobu, bez pobierania reszty w tle).

Dokładne bajty **pełnego** pakietu podaje generator i `totalBytes` bridge.
Rozmiar nie jest stałą w kodzie ani rozmiarem skompresowanego transferu HTTP.
Rzeczywisty pomiar nowego buildu należy dopisać w raporcie integracji; fixture
testowe nie jest pomiarem aplikacji. Miejsce na root alias, metadane cache,
worker i stare wersje wymaga dodatkowego zapasu poza `totalBytes`.

## Kontrakt z UI — jawna korekta po review

`window.fitOffline.status()/prepare({packageId})/cancel()` zwracają Promise obiektu:

```json
{"protocolVersion":1,"state":"notReady","packageId":"hash","totalFiles":0,"cachedFiles":0,"totalBytes":0,"cachedBytes":0,"errorCode":null,"message":null}
```

Stany: unsupported/notReady/checking/downloading/ready/error/cancelled.
`prepare({packageId})` przekazuje **identyfikator pakietu zatwierdzonego w UI**,
nie nowy identyfikator pobrany automatycznie w chwili wywołania. Wiadomość
MessageChannel ma `{protocolVersion:1, action:'prepare', packageId}`. Worker
sprawdza zgodę przed uruchomieniem/coalescingiem zadania. Brak lub mismatch daje
snapshot `state:error`, `errorCode:packageChanged` z aktualnym packageId/rozmiarem;
nie uruchamia transferu i nie zmienia globalnego stanu istniejącego zadania.
UI musi ponownie pokazać rozmiar i uzyskać zgodę. Pozostaje protocolVersion 1
zgodnie z jawnym uzgodnieniem właścicieli web/UI; wywołanie bez argumentu jest
celowo odrzucane. Ta korekta wymaga odpowiadającej zmiany adaptera/UI.

**Polityka dokumentu po ponownym review:** przed status/prepare/cancel worker
ustala pakiet dokumentu na podstawie rzeczywistego `event.source.id` i zaufanego
przypięcia lub odpowiedzi bridge z metaznacznikiem dokumentu. Stara karta A pod
aktywnym workerem B oraz karta o nieznanej wersji dostają `state:error`,
`errorCode:reloadRequired`, `cachedFiles:0`, `cachedBytes:0` i komunikat proszący
o przeładowanie. Nie wolno im pokazać ready pakietu B ani uruchomić/coalescować
jego pobierania lub anulować zadania innej karty. Odmowa nie mutuje globalnego
stanu pakietu ani nie wykonuje żądań HTTP. Pola packageId/total opisują dostępną
wersję workera, **nie gotowość starego dokumentu**. Dopiero nowa nawigacja/reload
do aktualnego shell pozwala ponownie sprawdzić stan i zatwierdzić pobieranie.
Bridge przekazuje kod/komunikat bez zmian. Właściciel UI może dodać etykietę
reloadRequired; ogólne wyświetlenie komunikatu workera również działa.
Kolejność odmów: nieaktualny/nieznany dokument → reloadRequired; aktualny dokument
z nieaktualną zgodą packageId → packageChanged. Sygnatury i protocolVersion 1
pozostają bez dalszych zmian.

Poprawne wywołanie rozpoczyna lub współdzieli zadanie workera i natychmiast zwraca
snapshot; UI odpytuje status. Nie czeka na cały transfer. `status()` bez aktywnego
pobierania ponownie skanuje i hashuje faktyczne odpowiedzi CacheStorage; nie ma
trwałej flagi ready. Podczas pobierania zwraca bieżący zweryfikowany postęp.
Status jest read-only wobec sieci i nigdy nie sprawdza auth.

MessageChannel ma timeout: status 60 s, prepare/cancel 5 s. Scan ma budżet 55 s,
każde pobranie 30 s. Pierwsza wizyta bez kontrolera może komunikować się z aktywnym
workerem o **dokładnym** scope i właściwym URL; istniejący kontroler zawsze ma
pierwszeństwo. Obcy/push kontroler, brak aktywnego workera lub zły scope daje
notReady, nie gotowość. Nie oczekujemy bezterminowo na `serviceWorker.ready`.
Kody błędów: network/integrity/quota/timeout; błędny protokół: protocol;
nieaktualna/brakująca zgoda: packageChanged; stary/nieznany dokument: reloadRequired.
Brak workera może oznaczać brak packageId i zera — UI powinno wtedy ponowić
sprawdzenie, a nie proponować pakiet o rozmiarze zero.

Cancel przerywa sieć i zachowuje poprawne części. Ponowienie po zakończeniu
anulowanego zadania wykorzystuje te części. Wiele kart ma jedną blokadę zadania
w danym workerze. Zabicie workera usuwa stan w pamięci, nie części cache;
następny status skanuje ponownie i nie udaje gotowości. Zmiana content ID tworzy
osobny cache nazwany scope+packageId. Nie usuwamy starych/obcych cache ani danych
użytkownika.

### Aktywacja i spójność starych kart

Po sprawdzeniu całego core, root alias i zapisaniu metadanych routingu instalujący
worker sam wywołuje `skipWaiting()`. Nie zależy od wiadomości loadera. Nie ma
`clients.claim()`: nie przejmujemy dokumentów dotąd niekontrolowanych.
**Samo pominięcie claim nie chroni starych kontrolowanych kart** — skipWaiting
zmienia również ich kontroler. Podczas pierwszej migracji legacy zapisujemy
przypięcie istniejących clientId do snapshotu rzeczywistego cache Fluttera.
Dokumenty custom mają przypięcia powstałe przy nawigacji lub rozpoznaniu ich
znacznika. **Nie ma domyślnego wyboru bieżącego ani poprzedniego pakietu dla
nieznanego dokumentu.** Globalny deskryptor active/previous nie dowodzi wersji
konkretnego clientId i nie uzupełnia brakującego przypięcia przy instalacji następcy.
Gdy po utracie routingu zachował się cache custom, nie traktujemy tego jako
pierwszej migracji i nie podstawiamy starego cache legacy ani nowego pakietu.
Nowa nawigacja wiąże resultingClientId z aktualnym pakietem. Bootstrap/entrypoint
mają jawne query identyfikujące shell, a bridge odpowiada na ograniczone czasowo
wewnętrzne zapytanie o publiczny znacznik shell z dokumentu. Pozwala to rozróżnić
nowy HTML zwrócony przez legacy online-first od starego dokumentu nadal w pamięci.
Query fit-shell jest ograniczeniem wersji zasobu, nie dowodem wersji dokumentu:
nie może zalegalizować nieznanej karty ani nadpisać jej przypięcia. Odrzucona
próba identyfikacji nie jest zapamiętywana na zawsze; listener uruchomiony później
może pozwolić na poprawne ponowienie. Zaufane przypięcie z nowej nawigacji działa
także wtedy, gdy listener bridge nie zdążył jeszcze odpowiedzieć.

Metadane `fit-offline-v1:<scope>:routing` zawierają tylko statyczne manifesty,
hashy i mapowanie dokumentów do wersji, nie dane konta ani flagę ready. Przetrwają
restart workera. Dla legacy `flutter-app-cache` powstaje deskryptor faktycznie
istniejących odpowiedzi z SHA/length; stary cache pozostaje nietknięty. Brakujący
zasób starej wersji kończy się błędem zamiast zwrócenia nowego kodu. Nie gwarantujemy
uzupełnienia brakujących legacy bajtów po zmianie originu na nową wersję.
Stara karta może pracować na A do reloadu; nowa karta/nawigacja dostaje spójne B.
Pierwszy reload aktualizujący custom A może jeszcze pokazać spójne A; kolejny
zwykły reload po aktywacji B pokazuje B bez zamykania pozostałych kart.
Utrata routingu + zatrzymanie/restart SW odbiera możliwość bezpiecznego odczytu
staremu dokumentowi bez identyfikacji/przypięcia: jego żądanie kodu kończy się
błędem, a status/prepare/cancel — reloadRequired, nie domyślnym B. Świeży dokument
B może rozpoznać się przez znacznik i wbudowany manifest również offline.

Fetch handler obsługuje tylko GET same-origin w scope: jawnie dozwolone statyki
oraz nawigacje do znanych tras aplikacji. API/auth/export, obce originy,
nieznane trasy nie są przechwytywane. Dla potencjalnej statyki manifest wybierany
jest **po** ustaleniu wersji dokumentu, nie na podstawie samego FILES aktualnego B.
Zweryfikowany `old-only.js` z A działa z cache A także po usunięciu go z B i przy
wyłączonym originie. Brak pliku w wybranym manifeście zwraca pustą odpowiedź 404,
nigdy HTML ani plik nowej wersji. Nie dotyczy to niezależnego push workera i URL
aktualizacji workera/manifestu, które pozostają poza interceptorem. Zapis wymaga 200,
braku redirect/opaque, zgodnej długości i SHA; HTML udający font/JS jest odrzucany.
Pobieranie statyk używa `credentials: omit`, `redirect: error`, `cache: no-store`.

## Testy i dalsza akceptacja

### Klienty workerowe (18 października)

DedicatedWorker i SharedWorker dziedziczą przypięcie konkretnego twórcy przez
rzeczywiste fetchEvent clientId/resultingClientId po weryfikacji bajtów skryptu.
Nie wysyłamy protokołu DOM do workerów. Przypięcie utrzymuje się po restarcie SW;
utrata metadanych kończy fetch fail-closed, nie wyborem aktualnego pakietu.
Nie zmieniono oryginalnych SQLite/Drift ani `web_connection.dart`; wrapper nie był
potrzebny. Dowody, rzeczywisty SQL shared/dedicated offline i granice blob/nested:
[`offline-worker-clients-2026-10-18.md`](../offline-worker-clients-2026-10-18.md).
Nie deklarujemy ogólnej obsługi nieprzypiętych Blob workerów ani żądań z pustym
clientId. Obecnie Node 32 testy; dodatkowy browser suite workerów 3 testy.

```sh
node --test tests/tools/offline_worker_test.cjs tests/tools/offline_client_test.cjs
dart tests/tools/generate_offline_package_test.dart
python3 tests/tools/offline_browser_test.py
python3 tests/tools/offline_update_browser_test.py
python3 tests/tools/offline_nginx_test.py
python3 tests/tools/offline_workers_browser_test.py
```

Dart test wymaga tylko SDK i sha256sum. Python test używa **istniejącej** instalacji
Playwright/Chromium i lokalnego serwera loopback, nie produkcji. Goły oficjalny
obraz Playwright Python zawiera przeglądarki, ale nie moduł Python — pierwsza
próba w nim zakończyła się `ModuleNotFoundError`, bez instalowania zależności.
Test hostowy obejmuje pierwszy niekontrolowany load→instalacja core→zatrzymanie
originu→cold root/today/session bez prepare; drugi wariant obejmuje explicit
prepare→ready→origin stopped→nieodwiedzony zasób→utratę cache→notReady.

Po ponownym review: Node **27 testów**, dwa testy cold/offline Chromium, siedem testów aktualizacji
Chromium oraz test rzeczywistego Nginx. Reprodukcje RED wykazały waiting bez aktywacji,
legacy B HTML/A main JS, brak walidacji zgody i HTML 200 dla brakujących obrazów/fontów.
Test aktualizacji korzysta z rzeczywistego `flutter.js` 3.35.4 i kodu legacy SW
wyodrębnionego z obrazu wydanej wersji (tylko RESOURCES/CORE zastąpione danymi
małego fixture), a nie z loadera-fixture wysyłającego skipWaiting. Używa `.load()`
z minimalnym entrypointem-fixture (bez silnika Fluttera), dwóch kart, zwykłego reloadu,
niezmienionego `?v=fixed-token` i zmienionych bajtów SW. Sprawdza wykonane pary
HTML/main.dart.js, pozostawiony stary cache, IndexedDB/outbox sentinel i obcy push
cache. Scenariusz status A→aktywacja B→zgoda A kontroluje również liczbę żądań:
**zero pobrań pełnego pakietu B**, potem poprawna zgoda B doprowadza do ready.
Nowe RED potwierdziły: wykonanie B w starym dokumencie po utracie routingu/restart,
odtworzenie błędnego przypięcia przy instalacji następcy, ready B dla niekompletnego
A i pominięcie old-only pliku A przez filtr FILES B. GREEN obejmuje utratę routingu
po aktywacji i przed instalacją następcy, CDP stopAllWorkers, old-status reloadRequired
przy ready B, blokadę pobrania/anulowania z obcej starej karty oraz old-only cache
offline. Jest też przypadek niezmienionego main JS, zmienionych statyk i utraty
metadanych — identyfikacja starego dokumentu nie może wtedy wybrać B.

MessageChannel sondy testowej zamyka oba porty. Kontrola i serwowanie cache oraz
download zużywają body bez tee/clone, a zweryfikowane bajty otrzymują świeżą
buforowaną Response; nagłówki kompresji/długości są dostosowane do odkodowanych
bajtów. Nie zostawiamy stron tee ani niezużytych błędnych odpowiedzi. Testy nadal
obserwują stan aktywacji, nie zakładają, że Promise skipWaiting oznacza activated.
Chromium czeka także na zakończenie pracy poprzednika; sonda ma jawny limit 60 s
i raportuje oczekiwanie dłuższe niż 10 s, zamiast wymuszać claim/terminację.

### Końcowy stan weryfikacji po drugim review

**Nowszy wynik kontroli:** po wykluczeniu wyłącznie auto-attachment Runtime/Debugger
SW wykonano kontrolę 7/7 PASS oraz trzy standardowe przebiegi pełnego zestawu
7/7 PASS (189,3 s, 131,3 s, końcowy 80,1 s). Końcowy obejmuje rzeczywiste wywołania
bridge status/prepare/cancel podczas wstrzymanej instalacji B, bez transferu
pełnego pakietu i bez fałszywej gotowości.
Szczegóły i historyczne FAIL w końcowej sekcji raportu diagnostycznego poniżej.
Opóźnienie około 31 s nadal bywa obserwowane i raportowane; nie ma obietnicy
natychmiastowej aktywacji ani pominiętych asercji.

Standardowe `python3 tests/tools/offline_update_browser_test.py` używa teraz
`offline_browser_driver.py`, tymczasowej kopii istniejącego drivera z wykluczeniem
tylko targetów SW z auto-attachment. Sprawdza rzeczywistą obecność SW i brak
debuggera; CDP do stron/stopAllWorkers i asercje pozostają. Tryb diagnostyczny
z dotychczasowym attach: `FIT_OFFLINE_ATTACH_SW=1`. Nie zmieniono zależności ani
zainstalowanego drivera.

Bridge ma guard natywnych slotów installing/waiting: przed status/prepare/cancel
zwraca istniejący `reloadRequired` bez RPC do wycofywanego workera. Zerowy postęp,
komunikat o trwającej aktualizacji, żadnego ready/download/claim/retry aktywacji.
Po aktywacji następne wywołanie wraca do normalnej ścieżki. Nie ma nowego kodu
ani sygnatury protokołu. Node obecnie 29 testów (dwa dodatkowe RED→GREEN bridge).
Każda zmiana bridge wymaga ponownego finalnego buildu/generacji manifestu przed
akceptacją aplikacji, bo zmienia content packageId.

Uzupełniająca, ograniczona czasowo diagnostyka i konkretne ślady:
[`offline-waiting-diagnosis-2026-10-17.md`](../offline-waiting-diagnosis-2026-10-17.md).
Nieinwazyjna sonda natywnego stanu rejestracji dała jeden przebieg 7/7 PASS,
następny 6/7 PASS/1 FAIL. Bloker pozostaje; brak stabilnego powtórzenia całości.
Instrumentacja i minimalny SW poza Fit potwierdziły wyścig zatrzymania/restartu A
po zakończonym install i skipWaiting B, również z surowym CDP bez Playwright.
Nie wprowadzono spekulatywnej poprawki produkcyjnej ani retry/claim.

- Node 27/27 PASS; generator, skupiony analyze i format PASS; diff-check PASS.
- Cold/offline Chromium 2/2 PASS; rzeczywisty Nginx 1/1 PASS.
- Ostatni pełny przebieg aktualizacji Chromium: **6/7 PASS, 1 FAIL**. Scenariusz
  `test_asset_only_release_does_not_reidentify_old_document_after_metadata_loss`
  nie dotarł do utraty metadanych: B pozostał installed/waiting przez limit 60 s,
  a A nadal active/activated. Diagnostyka osobno identyfikuje pakiet active i waiting.
  Sześć pozostałych scenariuszy, w tym oba przypadki utraty routingu, stary status
  i old-only offline, przeszło. W wcześniejszych powtórzeniach waiting wystąpił też
  nieregularnie w podstawowym custom A→B; zwiększenie limitu i usunięcie tee nie
  wyeliminowało zjawiska, więc nie są uznane za dowiedzioną naprawę jego przyczyny.
- Nie ma deklaracji pełnej gotowości aktualizacji. Ten blocker wymaga dalszego
  zbadania mechanizmu/liveness aktywacji Chromium; test nie jest pomijany, wyjątki
  nie są ignorowane, nie dodano wymuszonego claim ani promocji produkcyjnej.

Artefakty loadera dostarczyć przez `FIT_FLUTTER_JS` i `FIT_LEGACY_SW_TEMPLATE`.
W tej sesji wyodrębniono je z istniejących obrazów, bez startu produkcji i bez buildu:
`fit-web:candidate-1.14.0-27:/usr/share/nginx/html/flutter.js` oraz
`fit-web:candidate-1.14.0-27:/usr/share/nginx/html/flutter_service_worker.js`.
Domyślne ścieżki fixture znajdują się w `/tmp/opencode/fit-offline-*`.
Generator fixture uruchamiany jest w istniejącym obrazie `fit-web:guided-verified`.
Nginx test używa istniejącego `nginx:alpine`, `--network none`, bez publikowania
portów; żądania wykonuje `docker exec ... wget` do loopback wewnątrz kontenera.

Testy fixture nie zastępują pełnego buildu Fluttera, testów UI/recovery, restartu
profilu ani fizycznego iPhone/Android. Aktualizacja legacy jest sprawdzona na
fixture z rzeczywistym loaderem/kodem workera, nie na pełnej produkcyjnej aplikacji.
Nie gwarantujemy trwałości storage iOS ani wykonania w tle po uśpieniu systemu.
