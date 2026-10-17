# Niezależna lokalna akceptacja browser — 2026-10-17

## Werdykt: NIE ZAAKCEPTOWANO pełnej ścieżki guided/resume

Rzeczywisty compiled runtime, Chromium headless, CanvasKit, rzeczywisty Drift
WASM/IndexedDB. Bez zmian kodu aplikacji, generatorów, zależności i wdrożenia.
Przeszły częściowe przypadki katalogu/ilustracji, formularza i jawnego zapisu
z podsumowaniem. **Nie przeszedł lokalny szkic/wznowienie.** Dodatkowo w warunkach
pełnej izolacji sieciowej tekst nie jest malowany na screenshotach; treści
formularzy i summary potwierdzono w rzeczywistym drzewie accessibility, nie
jako poprawny wygląd tekstu na ekranie.

## Artefakt i izolacja

- Początkowo `fit-web:guided-local` nie istniał. Oczekiwanie warunkowe:
  `docker image inspect` co 15 s, limit 15 min; obraz wykryto o 01:44:22 UTC.
  Nie uruchamiano starego obrazu ani alternatywnego wydania aplikacji.
- Testowany runtime: `fit-web:guided-local`, ID
  `sha256:99b63f1f1a62a9fb99e0d2e5fdd36cd9be2aad92b938dc27244f0c1c567f4548`.
  Created `2026-10-17T03:44:08.919104195+02:00` (01:44:08 UTC).
- `main.dart.js` wewnątrz obrazu: mtime **01:43:59 UTC**. Najnowszy sprawdzony
  source guided provider: **01:23:39 UTC**, domena i UI: **01:21:46 UTC**.
  Jest to kontrola dat źródeł/kompilatu, nie niezależna reprodukcja builda.
  Nie przypisuję tej akceptacji wykonania 640 testów Flutter ani testów backendu.
- Testowy Nginx: `guided-accept-web-20261017-0144`, `--network none`, bez portów
  hosta. Browser: własne jednorazowe kontenery
  `--network container:guided-accept-web-20261017-0144`.
  Adres wyłącznie `http://127.0.0.1:80`, `isSecureContext == true`.
- Playwright Python **1.55.0**, Chromium **140.0.7339.16**, viewport 1440×1100.
  Obraz narzędziowy bazuje na poprawnym tagu
  `mcr.microsoft.com/playwright/python:v1.55.0-noble`; pakiet zainstalowano
  wyłącznie w obrazie testowym, nie w aplikacji/hoście.
- Profil persistent: `/tmp/opencode/guided-acceptance-20261017/fake-profile`.
  Włączanie semantyki przez kliknięcie `flt-semantics-placeholder` i TAB.
  Akcje wykonywano rzeczywistymi locatorami i klawiaturą. `fill` nie wywoływał
  aktualizacji Fluttera w rozpoznaniu; właściwe wpisy wykonano click/Ctrl+A/type.
- Na wejściu oczekiwanie `networkidle`, później konkretne locatory. Kolejne
  `networkidle` potrafiły przekroczyć timeout przez ponawiane zewnętrzne fonty;
  finalny reload używa `domcontentloaded`, placeholdera i locatora gotowego UI.
- Nie użyto produkcyjnych kont, domeny ani kontenerów, sieci `fit_ingress`,
  publicznych portów, hostowego Nginx ani providerów płatnych.

## API jest stubowane — granice dowodu

Przeczytano `AuthRepository`, `ApiClient`, `cookie_store_web.dart`,
`HttpSyncApi`, `SyncService`, `SyncStore` i deklaracje danych.
Przechwycenie Playwright dotyczy lokalnego `/api/**`; wszystko poza loopback
jest blokowane. Jedynym zaobserwowanym blokowanym hostem był `fonts.gstatic.com`.
Brak żądań do `fit.birek.online`.

- `GET /api/auth/session`: fake `accountId`
  `a1000000-0000-4000-8000-000000000001`.
- Cookie `fit_csrf=LOCAL-FAKE-CSRF`; zapisano faktyczne nagłówki mutacji.
- `GET /api/sync/pull?cursor=N&include_health=true`: profil fixture przez
  rzeczywisty klientowy parser i SQLite, monotoniczny cursor, kolejne zmiany.
  Fixture profilu doposażono na v2 o `Masa własna`, `Krzesło`,
  `Gumy oporowe`, `Ławeczka`, zanim wykonano właściwe scenariusze planu.
- `POST /api/sync/push`: rejestr rzeczywistych requestów; idempotentny ACK
  po operationId, inkrementacja wersji i echo rekordu na pull. Harness **nie
  tworzy** serii ani zdarzeń `performed`; przyjmuje tylko operacje klienta.
- Plany generowano przyciskami aplikacji z aktualnego lokalnego katalogu,
  nie wstrzykiwano planu ani frontendowego stanu/szkicu.
- Niezwiązane `/api/push/status` i `/api/mentor/settings` zwracały jawne 501
  i zostały oznaczone `UNEXPECTED` w logu. Nie udawano działającego mentora/push.
- To **nie jest** dowód serwerowego CAS, walidacji backendu, auth bezpieczeństwa
  ani rzeczywistej chmury. Nie wykonywano testów backendu.
- Service workery były blokowane przez Playwright, aby żadne API nie ominęło
  routingu. Dedykowany Drift worker działał rzeczywiście. **Nie zaliczono**
  instalacji PWA, cache/offline service workera ani restartu PWA na telefonie.

## Wyniki rzeczywistego UI

| Przypadek | Wynik | Dowód / ograniczenie |
|---|---|---|
| Start klienta, fake signed-in, profil | PASS funkcjonalny | API session/pull, UI gotowe; SQLite `sync_state.offline_access=1` |
| Pełny katalog | PASS | `Wyniki: 369` w semantyce |
| Kolekcja „Kręgosłup — ruch i stabilizacja” | PASS | filtr stylu daje `Wyniki: 19` |
| Wyszukiwanie samego słowa `kręgosłup` | Zaobserwowano 25, nie 19 | to szersze wyszukiwanie tekstowe, nie kolekcja; wczesne oczekiwanie 19 w harnessie poprawiono, nie w aplikacji |
| cw364–cw369 | PASS ładowania | otwarto sześć szczegółów, sześć lokalnych WebP HTTP 200, sześć screenshotów z namalowaną ilustracją i semantyką `img` |
| Generator → potwierdzenie startu guided | PASS funkcjonalny | plan 10 bloków, estymacja 33:18, budżet 45 min, faktyczny nowy UUID sesji |
| Cele/prefill bez automatycznej serii | PASS | blok 4/10 `cw367`: cel 3×10, po focusie textbox miał `10`; ręczna zmiana na `7`, „Lewa”; licznik 0, SQLite sets 0 |
| Reload bez tworzenia sesji/serii | PASS wąski | przed i po finalnym reloadzie te same cztery UUID, sessions 4→4, sets 0→0, API operations 4→4 |
| Trwały szkic i jawne „Kontynuuj/Wznów” | **FAIL/BLOCKER** | `workout_drafts` puste jeszcze przed reloadem; po nim brak „Kontynuuj”; nie przywrócono kroku/pól |
| Jawna seria i zakończenie | PASS funkcjonalny osobno, **nie po resume** | w osobnej próbie click `Seria wykonana (0)`→`(1)`, dialog zakończenia, notatka i osobny confirm |
| Summary plan kontra wykonanie | PASS semantyki/danych | cel cw367 3×10, wykonane 1; rzeczywiste Lewa/7/RPE7, pozostałe bez potwierdzenia, dodatkowe 0, praca czasowa 0 s |
| Wygląd tekstu offline | **FAIL w tym środowisku** | brak namalowanego tekstu przy zablokowanych fontach; sama semantyka nie dowodzi poprawnego wyglądu |
| Timer checkpoint/pauza/reload/downtime | NIE WYKONANO | brak zaliczonego resume; wybrany plan ma reps/time, nie rounds |
| Warianty A/B/history scopes | NIE WYKONANO | tylko rzeczywisty selector „Bazowy” był obecny, nie zaliczono wariantów |
| Migracja starszego profilu/presetów | NIE WYKONANO | użyto nowego fake profilu i bieżącego schematu; nie jest to test migracji |

### Dokładna reprodukcja blockera resume

1. Baza → Filtry → Kręgosłup (19) → Ułóż trening → Wygeneruj plan.
2. Rozpocznij trening → Potwierdź.
3. Trzy razy „Następny blok”: `Praca • blok 4/10`, Otwarta książka (`cw367`).
4. Click textbox: `10`; Ctrl+A/type `7`; click „Lewa”.
5. Accessibility: textbox `7`, radio „Lewa” checked, `Seria wykonana (0)`.
6. Odczyt rzeczywistego IndexedDB `fitbirek_v2`, store `blocks`: kopia stron
   `/database` do SQLite **tylko w temp** i SELECT; bez modyfikacji bazy klienta.
   `workout_sessions=4`, `workout_drafts=0`, `sets_log=0`, konto odblokowane.
7. `page.reload()` w tym samym persistent context, ponowne włączenie semantyki,
   karta Trening. Brak „Kontynuuj”; locator timeout 15 s. Powtórny odczyt SQLite:
   sessions 4, te same UUID, drafts 0, sets 0.

Sesja właściwej finalnej reprodukcji:
`269886bf-7d18-45ba-93c0-7ab847e78fb4`, lokalne ID 4.
Wcześniejsze próby rozpoznawcze pozostają jawnie w fake profilu; nie usuwano ich
ani nie tworzono fałszywego „czystego” wyniku. Łącznie po dodatkowych próbach
summary są **6 sesji i 2 rzeczywiście kliknięte serie**, jedna sesja zakończona.
To nie wzrost licznika podczas reloadu: w samym porównaniu było dokładnie 4→4.
Nie ustalono przyczyny źródłowej braku szkicu; nie przypisuję jej bez dowodu
CAS/backendowi. Nie obchodzono błędu przez wpisanie `workout_drafts` lub JS state.

## Screenshoty i pozostałe artefakty

Katalog: **`/tmp/opencode/guided-acceptance-20261017/`**.
Każdy istotny snapshot ma `.png`, `.html` oraz `.aria.txt`.

- `06-spine-collection-19.png` / `.aria.txt` — 19 kolekcji (tekst z semantyki).
- `04-spine-search-25.png` / `.aria.txt` — wyszukiwanie tekstowe.
- `image-cw364.png`, `image-cw365.png`, `image-cw366.png`, `image-cw367.png`,
  `image-cw368.png`, `image-cw369.png` — faktycznie namalowane nowe ilustracje.
  Są większe niż wysokość viewportu szczegółów; zrzuty pokazują widoczny wycinek,
  nie stanowią akceptacji pełnego układu wszystkich kadrów na telefonie.
- `08-plan-preview.png`, `09-guided-start.png`, `12-guided-side-prefill.png`.
- **`15-before-page-reload-left7.png` / `.aria.txt`**.
- **`16-after-page-reload-home.png` / `.aria.txt`** — brak resume.
- `18-explicit-set-saved.png`, `19-finish-confirmation.png`.
- **`20-summary-plan-actual.png` / `.aria.txt`** — porównanie dostępne w semantyce;
  tekst na PNG nie jest poprawnie namalowany przy niedostępnych fontach.
- `15-before-reload-db.json`, `16-after-reload-db.json`, odpowiadające `.sqlite`,
  `20-finished-db.json` / `.sqlite` — odczytane dane rzeczywistej bazy browsera.
- `storage-inspection.json`: secure context, IndexedDB blocks/files, brak OPFS.
- `fake-api-state.json`: pełne requesty, prawdziwe wysłane payloady i stub ACK.
- `console-*.json`, `traffic-*.json`: logi wszystkich prób, także nieudanych
  rozpoznań locatorów. `evidence-verification.json`: niezależne asercje danych,
  SHA screenshotów, liczniki oraz inspekcja izolacji kontenera.
- `browser.py`, `collection.py`, `start.py`, `repro.py`, `images.py`, `finish.py`,
  `dbread.py`, `verify_evidence.py`, `wait_image.py`, `Dockerfile`: zachowany harness.

Przykład uruchomienia (wymaga własnego kontenera runtime; obecny testowy usunięto):

```sh
docker run --rm --network container:NAZWA_WLASNEGO_TESTWEB \
  -v /tmp/opencode/guided-acceptance-20261017:/evidence \
  fit-guided-browser-test:20261017 python browser.py repro.py
```

`repro.py` kończy się kodem 1 na brakującym „Kontynuuj”. `images.py` i ostatni
`finish.py` zakończyły się kodem 0. Wczesny harness miał błędne ustawienie kodu
wyjścia przy wyjątku (`sys.exitcode`); zostało to poprawione **wyłącznie w temp**
przed finalną reprodukcją. Nie traktowano starych exit 0 jako PASS: ich tracebacki
i screenshoty pozostawiono w dowodach.

## Konsola, SQLite i ograniczenia końcowe

- Zaobserwowano `pageerror: Error` po błędach pobierania Inter Regular/Bold,
  ostrzeżenia Roboto/Noto, software WebGL i celowe zablokowanie service workera.
  Łączny agregat wszystkich prób: 42 zdarzenia `pageerror`, nie 42 crashe
  przeglądarki. Nie zaobserwowano zakończenia procesu/renderer crash; UI nadal
  reagowało i zapisywało rzeczywiste serie. Nie jest to czysta konsola PASS.
- Brak tekstu na zrzutach jest istotnym ograniczeniem offline wizualnym, a nie
  powodem do podmieniania frontendowych assetów przez harness. Fontów nie
  dosyłano z hosta ani z internetu.
- Web SQLite z testowanego runtime porównano z rootowymi plikami i lockfile:
  Drift **2.28.2**, sqlite3 **2.9.4**. Oba SHA-256 zgodne:
  - wasm: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
  - worker: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`
- Zachowano freeze. Jedyna repozytoryjna zmiana tej akceptacji: ten nowy raport,
  po przejściu częściowych przypadków katalogu/ilustracji i summary. Bez commita,
  pushu, wersji, generatora, deployu, prune i usuwania istniejących danych.
- Własne browsery zamknięto, jednorazowe kontenery usunięły się przez `--rm`;
  własny Nginx testowy usunięto na końcu. Harness, fake profil i dowody w temp
  zachowano. Nie usuwano żadnego cudzego kontenera ani obrazu.

## Dopisek diagnostyczny — przyczyna braku draftów i poprawka source

**Nie zmienia to historycznego wyniku RED powyżej. Nie wykonano jeszcze
akceptacji browserowej nowego kompilatu.** Obraz `sha256:99b63f1…` pozostaje
artefaktem nieudanej próby; poprawka opisana tutaj wymaga nowego obrazu od main
i powtórzenia oryginalnej ścieżki przez harness. Nie uruchamiano automatycznego
builda/runtime ani nie zmieniano danych fake profilu.

### Sprawdzenie oryginalnych dowodów, bez zapisu

W tym środowisku artefakty są bezpośrednio pod
`/tmp/opencode/guided-acceptance-20261017/`, nie pod `harness/report/`.
`15-before-reload.sqlite` otwarto URI SQLite `mode=ro` i `PRAGMA query_only=ON`:

- `PRAGMA user_version = 12`; `workout_drafts` istnieje z właściwym złożonym
  PK `account_id, session_sync_id` i kolumną `payload_json`.
- Rzeczywiste liczniki: sessions **4**, sets **0**, drafts **0**.
- `sync_state`: poprawne fake konto, `offline_access=1`, `full_cursor=6`.
- Profil lokalny ma version **2**, onboarding zakończony; `filter_presets_json`
  i `exercise_variants_json` są NULL, zgodnie z omission w fixture.
- Dla wszystkich czterech UUID guidance z wysłanej operacji i z SQLite jest
  identyczne **wartościami i kolejnością kluczy**. Nie zostało usunięte przez echo.
  Raw SHA-256 guidance JSON: `457353208ffb0942605752e64b45fbec3d1e2424d62f2774c6e39c37b2c70df8`.
- Nowa testowa kopia guidance/profilu jest porównana do zachowanych JSON,
  a parser domenowy potwierdza canonical roundtrip, 10 bloków i estymację 1998 s.
  Nie ma dowodu błędu fixture, brakującego guidance ani przyczyny w JSONB order.

Pomocnicze, wyłącznie odczytowe skrypty diagnostyczne są w
`/tmp/opencode/guided_draft_diagnose.py` i
`/tmp/opencode/inspect_drift_guard.dart`. Nie wstawiają draftu do browsera.

### Root cause potwierdzony różnicowym testem integracyjnym Dart

`PlannerWorkflow.start` działa w `_write → db.transaction`. Tworzył tam
notifier, rejestrował długowieczny `watchSession` i callbacki `_draftWrites`.
Callbacki dziedziczyły strefę Drifta z executorem tej transakcji, mimo że miały
działać później. Po zakończeniu parent transaction korzystały ze starego
executora. Kolejne edycje RAM były dopinane do tej samej zablokowanej kolejki.

Na **niepoprawionym baseline** nowy test z przechwyconym guidance/profilowym
payloadem oraz rzeczywistymi AuthController, PlannerWorkflow, SyncService,
SyncStore i SQLite wykazał:

- bezpośredni start notifikatora: PASS;
- start przez planner, native SQLite: `A transaction was used after being closed`;
- start przez planner, transport remote/RPC: timeout `flushDraft` po 5 s;
- te same wyniki po odwróceniu kolejności kluczy map w echo (kontrola JSONB).

Inspekcja faktycznie zainstalowanego **Drift 2.28.2** wyjaśnia różnicę:
`runtime/api/connection_user.dart` wiąże `resolvedEngine` ze strefą,
`runtime/executor/helpers/engines.dart` odrzuca zamkniętą transakcję native,
a `remote/server_impl.dart:_waitForTurn` czeka na aktywność wskazanego executora.
Zwolniony identyfikator nie wraca do backlogu. To odpowiada zaobserwowanemu
brakowi wpisu i brakowi widocznego błędu, gdy zdalny future nigdy się nie kończy.
Nie jest to problem kształtu profilu ani CAS serwerowego.

### Zmiana i granica dowodu GREEN

Poprawka jest w `workout_providers.dart`: kolejka i obserwatory sesji rejestrują
callbacki poza krótkotrwałą strefą danej bazy. Zachowany zostaje nadrzędny
kontekst UI/error/test (nie jest to bezwarunkowe `Zone.root`). Jeden jawny punkt
kompatybilności korzysta z `resolvedEngine` wersji 2.28.2; zabezpieczają go testy
native i RPC. Nie zmieniono SyncStore, protokołu profilu ani harnessu.

Ponadto odmowa zapisu nie jest już automatycznie wyciszana, jeśli po ponownej
weryfikacji nadal istnieją to samo aktywne konto i wiersz/UUID sesji. Wtedy
działają istniejący komunikat `draftSaveError` i błąd `flushDraft`, zamiast
pozornego sukcesu checkpointu. Prawdziwy logout/delete/finish pozostaje
anulowaniem starego zapisu bez odradzania sesji.

`guided_browser_draft_repro_test.dart` ma **9 przypadków**: canonical fixture,
jawna odmowa zapisu, rollback caller transaction native/RPC oraz pięć wariantów
start/auth/pull/ACK/echo. W wariantach pozytywnych draft powstaje wyłącznie przez
produkcyjną kolejkę/repo. Krok 4, Lewa/7 przechodzą flush; po nowym kontenerze
providerów, a dla RPC także po zamknięciu i otwarciu pliku SQLite, oferta pending
zawiera **ten sam UUID** i resume odtwarza pola. Sesje 1→1, sets 0→0, operacje
startu 1→1. Nie jest to jednak dowód locatora „Kontynuuj” ani screenshotu nowego
compiled web. Historyczne `.sqlite`, screenshoty i fake-api-state pozostawiono.

**Do main/harness:** zbudować nowy zatwierdzony kompilat dopiero w osobnym etapie,
podać jego nowy digest agentowi browserowemu i ponowić sekcję „Dokładna
reprodukcja blockera resume” oraz timer. Osobny problem fontów/workerów pozostaje
zakresem równoległego agenta.
Sam test Dart nie zamyka browser acceptance i nie zmienia werdyktu tego raportu.
Nowa próba powinna mieć osobny katalog dowodów, bez nadpisywania obecnych RED
JSON/SQLite/screenshotów. Należy wykonać nowy potwierdzony start i edycję przed
reloadem: nie da się odzyskać kroku/Lewa/7 utraconych przez poprzedni kompilat,
który nigdy nie zapisał tych pól w `workout_drafts`.

Końcowa weryfikacja source po poprawce (istniejący obraz narzędziowy
Flutter 3.35.4 / Dart 3.9.2, aktualny root bind-mounted):

```sh
docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter test --no-pub -r expanded test/features/workout/guided_browser_draft_repro_test.dart
# 9 passed
docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter test --no-pub -r expanded test/features/workout
# 148 passed
docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter analyze --no-pub
# No issues found
```

Dotychczasowe przypadki workflow nie obejmowały całego zestawienia:
zalogowane konto + transakcyjny start planera + durable flush + worker RPC.
Liczba wcześniejszych testów nie zastępowała tej integracji. Nie uruchamiano
pełnego zestawu aplikacji ani nowego browser runtime po tej poprawce. Nie
wpisywano draftów ręcznie, nie wykonywano zapisu produkcyjnego ani deployu.
