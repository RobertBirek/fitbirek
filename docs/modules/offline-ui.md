# Working set: Tryb offline — UI i adapter

## Zakres

- `lib/features/offline/{domain,data,providers,presentation}/`
- Wejście `Tryb offline` w istniejącym `SettingsPage`, przez `MaterialPageRoute`.
- `test/features/offline/` — fake bridge, kontroler/provider, widgety i lokalna kolejka.
- Projekt: `docs/superpowers/specs/2026-10-17-offline-readiness-design.md`, sekcje 3–5.
- Synchronizacja: `docs/modules/sync.md`. Aplikacja nadal dla jednego użytkownika.

## Kontrakt infrastruktury

Warunkowy import wybiera `dart:js_interop` na web i adapter `unsupported` poza web.
`window.fitOffline.status()`, `.prepare({packageId})`, `.cancel()` zwracają
`Promise<object>` — obiekt JSON-serializable, **nie JSON string**.
`protocolVersion` pozostaje **1**, ale argument `prepare` jest obowiązkowy:
`OfflineBridge.prepare(String expectedPackageId)` przekazuje obiekt JS
`{packageId: expectedPackageId}`. Jest to koordynowane doprecyzowanie kontraktu
z projektu (wcześniejszy zapis `prepare()` bez argumentu nie obowiązuje).
`prepare({packageId})` rozpoczyna pracę w tle i szybko zwraca snapshot;
UI odpytuje `status()`.
Nie przekazujemy URL-i, nazw cache ani danych konta. Brak bridge daje ponawialne
`notReady/bridgeUnavailable`, nie gotowość i nie automatyczne pobieranie.
Nie ma fallbacku do `prepare()` bez argumentu: także po błędzie, timeout,
odpowiedzi `unsupported` lub nieobsługiwanym protokole starszego workera.
Adapter natywny przyjmuje wymagany ID i nadal zwraca `unsupported`.

Parser wymaga `protocolVersion: 1`, znanego stanu, wszystkich czterech liczników
całkowitych nieujemnych w bezpiecznym zakresie JS oraz nullable stringów
`packageId`, `errorCode`, `message`. Liczniki cache nie mogą przekroczyć sum.
`ready` wymaga niepustego ID, dodatnich sum, równych liczników i braku błędu.
`errorCode: packageChanged` jest dopuszczalny wyłącznie w terminalnym `error`,
nie może uruchomić pollingu ani oznaczać `ready`.
Tekst bridge jest walidowany, ale nie wyświetlany: UI ma własne komunikaty bez
ryzyka pokazania URL-i, sekretów czy surowych wyjątków JS.

### `reloadRequired` — informacja w istniejącym ekranie

`OfflineSnapshot.requiresReload` rozpoznaje `reloadRequired`; parser dopuszcza
ten kod **wyłącznie** w terminalnym `error`, niezależnie od obecności ID/sum.
Sumy mogą opisywać pakiet innego workera, nie gotowość załadowanego dokumentu.
Kontroler odmawia `prepare(consent)` również przy poprawnym ID i rozmiarze,
niezależnie od UI. Nie zmienia kodu na `packageChanged` ani nie uruchamia retry,
pollingu lub anulowania. Niepoprawna para faza/kod daje terminalne `error/protocol`.

`OfflinePage` pokazuje osobny panel „Aktualizacja aplikacji — wymagane
odświeżenie”. Opis pozostaje neutralny: może trwać aktualizacja lub wersja karty
nie została potwierdzona. Panel nie deklaruje nowej wersji gotowej do użycia ani
gotowości offline, nie pokazuje surowego `message`, postępu innego pakietu ani
przycisku pobierania. Ewentualny rozmiar jest wyraźnie opisany jako dostępny
pakiet, nie potwierdzenie gotowości tej karty.

„Sprawdź ponownie” wywołuje tylko pasywny `status()`. Nie odświeża dokumentu,
nie wyraża zgody, nie inicjalizuje auth/sync ani nie dotyka danych treningowych.
Instrukcja zaleca normalny zapis pracy, zakończenie używania timera, zamknięcie
wszystkich kart/PWA i otwarcie tego samego profilu online, bez kasowania danych
i bez obietnicy flush po awarii. Pending/konflikty oraz niedostępny stan konta
pozostają oddzielną informacją; niedostępność nie oznacza pustej kolejki.

Nie dodano globalnego bannera, updatera, reloadbutton, pollera wersji ani nowego
właściciela lifecycle. Świeży poprawny status oraz nowa zgoda nadal pozwalają
na zwykłe pobieranie; odrębny kontrakt `packageChanged` nie zmienia się.

Weryfikacja Task 2 (2026-10-29): **53/53** testy offline (19 nowych),
**32/32** skupione regresje recovery/persistence/SQLite, analiza sześciu zmienionych
plików i format PASS. Test z prawdziwą natywną SQLite utrzymuje aktywny szkic,
trzy pending (w tym attempted) i jeden deferred; porównuje wszystkie wartości
wierszy jako bajty UTF-8 przed panelem, po nim i po ręcznym sprawdzeniu.
Obserwuje rzeczywisty provider agregatów, także dla braku authority/innego konta,
bez auth/HTTP. Widget przy 320 px i skali tekstu 200% jest przewijalny, bez overflow.
Niezmienione testy Node worker/client: **32/32** (faktyczna liczba w tym repo).
Sonda JS conditional import kompiluje się; to nie test przeglądarkowy nowego buildu.
Pełna suite/compiled Web po wszystkich zmianach należy do integracyjnego Task 5.

## Zgoda, gotowość i lifecycle

- Otwarcie ekranu wywołuje wyłącznie `status()`. Bez SharedPreferences i flag gotowości.
- Zgoda pokazuje cały rzeczywisty rozmiar w MiB i bajtach oraz liczbę plików,
  w tym ilustracje/fonty. Nieznany rozmiar nie pozwala pobrać pakietu.
- Przycisk potwierdzenia jest związany z aktualnym snapshotem; nowy odczyt,
  zmiana pakietu lub wznowienie unieważniają starą zgodę.
- Kontroler przechwytuje ID **potwierdzonego snapshotu** i wysyła dokładnie ten
  string do `prepare`, nigdy ID z późniejszej odpowiedzi lub aktualnego manifestu.
- Worker ma odrzucić brak/niedopasowanie ID **przed pobieraniem** jako
  `error/packageChanged`, zwracając aktualny pakiet B i jego rozmiar/liczbę plików.
  Błąd dotyczy żądania; nie powinien zmieniać globalnego snapshotu pracy workera.
- UI pokazuje rozmiar B i wyjaśnienie zmiany, ale nie traktuje odpowiedzi jako
  zgody na B. Ukrywa pobieranie/ponowienie i blokuje również bezpośrednie
  `controller.prepare` na tym snapshotcie. Wymaga „Sprawdź ponownie”, a następnie
  nowego dialogu z aktualnymi bajtami, MiB i liczbą plików oraz jawnej zgody.
  Sama odpowiedź `packageChanged` nie wywołuje status/retry/download. Standardowy
  odczyt przy wznowieniu aplikacji pozostaje pasywny i nigdy nie wyraża zgody.
- Status ma timeout 65 s (bridge ogranicza pełną weryfikację cache do 60 s),
  prepare/cancel 10 s (bridge 5 s). Odczyty nie nakładają się. Anulowanie czeka
  na ograniczony czasowo odczyt, unieważnia jego wynik, potem wywołuje `cancel()`.
- Polling co 2 s tylko dla `checking/downloading`, maksymalnie 120 odpytań
  przed błędem timeout. Terminalny stan nie uruchamia dalszych odpytań.
- Tło zatrzymuje polling i unieważnia wynik oczekującego odczytu. Wznowienie
  ponownie sprawdza bridge. Poprzedni `ready` podczas kontroli nie jest prezentowany
  jako zweryfikowana gotowość. Dispose ignoruje spóźnione wyniki i usuwa timer.
- Gotowość dotyczy **zasobów**, nie konta, synchronizacji ani trwałości storage.
  Pierwsze logowanie wymaga internetu; iOS może usunąć pamięć witryny.
  Nie obiecujemy pracy/pobierania w tle.

## Dane treningowe — niezależny, pasywny odczyt

`offlineSyncProvider` obserwuje istniejące lokalne `SyncState`, `SyncOutbox`,
`SyncDeferredRecords` i pasywną `CachedAuthWriteAuthority`. Nie tworzy
`AuthController`, nie wywołuje `getSession`, `synchronize` ani HTTP.
Agregat jest dostępny tylko dla aktywnego konta zgodnego z lokalnym powiązaniem,
przy `offlineAccess`. Zmiana autorytetu od razu emituje odpowiedni agregat lub
stan niedostępny; nie ujawniamy identyfikatorów ani payloadów.
Liczba deferred jest konserwatywnie opisana jako konflikty / rekordy wymagające
sprawdzenia. Pusta kolejka nie potwierdza aktualności serwera. Gotowe zasoby
nie zasłaniają oczekujących zmian.

## Weryfikacja

Używać izolowanego snapshotu w obrazie Flutter 3.35.4/Dart 3.9.2 przypiętym
digestem z Dockerfile. Bez generatora: nie zmieniamy deklaracji modeli/bazy.

Początkowa weryfikacja 2026-10-17: **29 testów PASS**, analiza tylko powyższego zakresu
**No issues found**, format 10 plików nowego modułu/testów bez dalszych zmian.
Poprawka atomowej zgody: RED — poprzednie 29 testów PASS i 5 nowych FAIL
(brak argumentu, ponowne przygotowanie B bez statusu, nieterminalne `packageChanged`).
GREEN — **34 testy PASS**, analiza własnego zakresu **No issues found**.
Nowe testy rejestrują ID wywołań i przechodzą pełne A→dialog A→odrzucenie/B→
status B→dialog z nowym rozmiarem/liczbą plików→zgoda B; bez automatycznej zgody.
Obraz: `ghcr.io/cirruslabs/flutter:3.35.4@sha256:4ce1a8455a84d39b51a6e013ad9825fab651f881d02d966928aa624695b61022`.
Bez pełnego runtime builda i bez testu realnego bridge w przeglądarce w tym zakresie.

```sh
flutter test --no-pub test/features/offline --reporter expanded
flutter analyze --no-pub lib/features/offline lib/features/settings/presentation/pages/settings_page.dart test/features/offline
```

### Wymagana sonda prawdziwego kompilatora JS

Sama analiza i testy natywne **nie sprawdzają ograniczeń kompilatora JS**.
Zgłoszony pełny build web zakończył się FAIL na tear-offach zewnętrznych funkcji
`_status` / `_cancel`, mimo wcześniejszego PASS analizy i testów natywnych.
Sonda `test/features/offline/offline_bridge_js_compile_probe.dart` importuje
publiczny adapter z conditional importem i zachowuje osiągalne wywołania
`status`, `prepare` z wymaganym ID oraz `cancel`. Dzięki kompilacji JS wybiera
rzeczywisty adapter web, a nie stub natywny.

Uruchomić z katalogu głównego klienta, w izolowanym snapshotcie z powyższym
przypiętym Flutter/Dart. Package config utworzyć przez
`flutter pub get --enforce-lockfile` w tym samym środowisku:

```sh
dart compile js --packages=.dart_tool/package_config.json -O1 -o /tmp/offline_bridge_probe.js test/features/offline/offline_bridge_js_compile_probe.dart
```

To test **wyłącznie kompilacji**: nie uruchamiać powstałego JS przeciw aplikacji,
bo celowo zawiera osiągalne `prepare`. Nie wymaga Chrome, OS integracji ani
pełnego `flutter build web`; nie jest testem działania bridge w przeglądarce.

RED przed poprawką (exit 1, ten sam compiler i ta sama komenda):

```text
lib/features/offline/data/offline_bridge_web.dart:40:37:
Error: Tear-offs of external top-level member '_status' are disallowed.
  Future<Object?> status() => _call(_status);
                                    ^
lib/features/offline/data/offline_bridge_web.dart:45:37:
Error: Tear-offs of external top-level member '_cancel' are disallowed.
  Future<Object?> cancel() => _call(_cancel);
                                    ^
Error: Compilation failed.
```

Przyczyna: dart2js zabrania tear-offów zewnętrznych top-level members JS.
Minimalna poprawka to przekazanie zwykłego domknięcia Dart wywołującego member:
`_call(() => _status())` / `_call(() => _cancel())`. Istniejące domknięcie
`prepare` oraz konstrukcja obiektu JS `{packageId}` pozostają bez zmian.

GREEN po poprawce (exit 0):

```text
Compiled 10,227,657 input bytes (5,215,722 characters source) to 221,334 characters JavaScript in 1.72 seconds
```

Po tej poprawce ponowiono również skupione testy natywne: **34/34 PASS**,
analizę własnego zakresu: **No issues found** oraz kontrolę formatowania: PASS.
Pełnego runtime builda w tym kroku nie powtarzano.

Nie zmieniamy zależności ani artefaktów Web SQLite. Lock pozostaje dla
`drift 2.28.2` / `sqlite3 2.9.4`. SHA-256 zgodne z wcześniej zweryfikowaną parą:

- `web/sqlite3.wasm`: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- `web/drift_worker.dart.js`: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

Ich zgodność runtime i prawdziwe Promise/SW w przeglądarce należą do późniejszej
integracji pełnego builda.
Test fake bridge nie dowodzi poprawności cache, pracy bez originu ani instalacji
na fizycznym iPhone/Android. Nie zastępuje akceptacji integracyjnej.
