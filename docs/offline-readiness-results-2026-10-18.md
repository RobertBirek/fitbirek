# Offline Readiness — wyniki końcowe, 2026-10-18

## Werdykt i zakres

**Implementacja offline/recovery oraz wykonane scenariusze finalnej skompilowanej
aplikacji: PASS. Fizyczny iPhone/Android: MANUAL PENDING / UNTESTED.
Rollout między dwoma pełnymi skompilowanymi wydaniami: NOT TESTED.** Nie jest to
zbiorczy PASS wszystkich bramek produktu ani deklaracja gotowości iOS.

Ten raport konsoliduje już wykonane kontrole. Podczas tej aktualizacji
dokumentacji nie uruchamiano testów aplikacji, generatorów ani builda.
Najświeższe źródło browser:
[LATEST — 2026-10-18 UTC](offline-readiness-browser-acceptance-2026-10-17.md#latest--2026-10-18-utc-final-image-sc-font-i-worker-pin--green),
[verification.json](file:///tmp/opencode/offline-final-20261018-e9a276/verification.json)
i [katalog dowodów](file:///tmp/opencode/offline-final-20261018-e9a276/).
Przeglądarki wystartowały **06:49:51 UTC**, verification zapisano **07:08:17 UTC**.

Nowsze dowody zastępują wcześniejsze baseline FAIL reloadu/PWA i SC 404/retry
**tylko w ponowionych przypadkach na nowym obrazie**. Nie wymazują historii w
[training-rhythm](training-rhythm-results-2026-10-17.md),
[baseline PWA](pwa-offline-acceptance-2026-10-17.md) ani wcześniejszych sekcjach
raportu browser. Nie rozszerzają też wcześniejszych smoke testów repeat/trends
do pełnej ponownej akceptacji tych funkcji.

## Finalny artefakt i stan lokalny

| Identyfikator | Wartość |
|---|---|
| Obraz web | `fit-web:offline-final` |
| Docker index SHA-256 | `590c5c6cc9d9cbe8b7ae3032493bd4c1c34c7597e688892fb052f888bc16dae8` |
| Docker config SHA-256 | `369b498b9cafe2d185f6d0c4b2ffba6410cf195a3e778d9da7a341c793ca2ee8` |
| Content packageId | `4e1f9fb52f809558e14e454bcab31962cac7508afbae248d5a728e15bdfd7d47` |
| Pełny pakiet | **443 pliki / 46 808 551 bajtów / około 44.64 MiB** |
| Toolchain | Flutter **3.35.4**, Dart **3.9.2** |
| Schematy | Drift **13**, Alembic **0010** |

Rozmiar oznacza rzeczywiste bajty statyk, nie skompresowany transfer HTTP ani
całe zużycie storage (cache metadata, root alias i starsze pakiety potrzebują
dodatkowego miejsca). Content identity wyliczono z finalnych bajtów po buildzie;
manifest i wynikowy worker są **generowanymi artefaktami weryfikacji buildu**,
nie ręcznie utrzymywaną ani ręcznie commitowaną wersją treści.

Implementacja pozostaje lokalna i **niecommitowana**, bez bumpa wersji,
commit/push/deploy. Produkcyjne **1.14.0+27** pozostaje bez zmian. Multi-user
jest odłożone zgodnie z [decyzją o przyszłych prywatnych kontach](future-private-accounts.md).

## Weryfikacja techniczna — pochodzenie wyników

| Kontrola | Wynik i granica dowodu |
|---|---|
| Finalny build verification Flutter | **813 PASS**, analyze **0**, compiled web build **PASS**; [log `tool_14dbc9eca001JF887YvejngkQw`](file:///root/.local/share/opencode/tool-output/tool_14dbc9eca001JF887YvejngkQw). |
| Pełny backend | **378 PASS — wcześniejszy przebieg training-rhythm/weekly schedule**, nie nowy run offline; zakres backendu od tamtego wyniku bez zmian. [Poprzedni log](file:///tmp/opencode/weekly-schedule-backend-full-20261017.log). |
| Generated modele | Wcześniejsza kontrola **17/17 zgodnych**, deklaracje/metadane generowane bez dalszych zmian; nie ponawiano generatora podczas tej aktualizacji. [Dowód](file:///tmp/opencode/fit-schedule-integration/schedule-router-full/generated-comparison.json). |
| Worker/bridge Node | **32/32 PASS**, w tym worker pin, integralność i odmowa nieufnej tożsamości. |
| Worker browser | **3/3 PASS**, realne Dedicated/SharedWorker, SQL i utrata metadanych. |
| Updates browser | **7/7 PASS**; po korekcie drivera trzy kolejne pełne przebiegi **7/7** (189.3 s, 131.3 s, 80.1 s), potem regresja workerów **7/7** (172.4 s). |
| Cold browser / Nginx | **2/2 PASS / 1/1 PASS**; fixture cold shell oraz rzeczywisty Nginx missing statics. |
| Generator pakietu | PASS generatora i niezależnego fingerprintu finalnego manifestu; nie mylić z wcześniejszą kontrolą 17 modeli. |
| Focused review | **CLEAR po poprawkach** recovery, worker/cache/auth/API/route scope i bridge/UI; wcześniejszy wynik review, nie nowy niezależny audyt wszystkich platform. |

Źródła i chronologia RED/GREEN: [recovery](modules/active-session-recovery.md),
[UI/adapter i sonda kompilatora JS](modules/offline-ui.md),
[pakiet/aktualizacje](modules/offline-package.md),
[diagnoza waiting](offline-waiting-diagnosis-2026-10-17.md),
[worker clients](offline-worker-clients-2026-10-18.md).
Starsze liczniki i waiting FAIL w tych dokumentach dotyczą poprzednich etapów.

Testy aktualizacji używają rzeczywistego loadera Flutter 3.35.4 i kodu legacy SW,
ale **małego fixture entrypointu**, nie dwóch pełnych compiled aplikacji.
Tymczasowy driver wyklucza wyłącznie auto-attachment Runtime/Debugger targetów
SW; pozostawia prawdziwy SW, CDP stron, stopAllWorkers i asercje. Nie zmieniono
zainstalowanego drivera ani zależności. Zdarzające się około 31 s oczekiwania
pozostaje raportowane; PASS nie oznacza natychmiastowej aktywacji.

## Finalny real-browser E2E — rzeczywiście wykonane PASS

Nowe profile core/package/second, nowe konto i PostgreSQL, HTTPS localhost,
internal network bez host ports. Dane domenowe powstały przez UI; bez SQL
injection i stubów auth/API/ACK. Reused image API ma **40/40** plików Python
zgodnych z aktualnym backendem; to kontrola źródeł runtime, nie nowy pełny pytest.
Chromium **140.0.7339.16**, prawdziwy SW **attached:false**.

| Scenariusz | Dowód w katalogu finalnego E2E |
|---|---|
| Jedna zwykła wizyta online wystarcza do instalacji core; następnie cold root, `/today` i deep link przy zatrzymanym **całym originie**, z namalowaną aplikacją | `02-core-native-sw.json`, `03-core-cold-root`, `05a-core-cold-today-confirmed`, `05b-core-cold-deep-confirmed`, socket probes. |
| Skompilowane UI pokazuje rzeczywisty rozmiar i notReady, wymaga zgody, wykonuje prepare/progress/cancel/retry/ready | `06-package-status.json` (27/443 przed zgodą), `07-size-consent`, `08-downloading-ui`, `09-cancelled-ui`, `10-retry-progress-ui`, `11-ready-ui.png`. Bez ręcznego dogrzania całego pakietu. |
| Cztery niezależne read-only kontrole faktycznych odpowiedzi CacheStorage: **443/443 długości i SHA**, API poza cache | `12-all443-cache-hash-audit.json`, `15-repaired-all443-audit.json`, `30-offline-all443-audit.json`, `35-final-all443-audit.json`. |
| Eviction odbiera ready; UI naprawia brak. Kolejna eviction przy origin OFF daje **error/network**, 442/443, bez false ready; reconnect i jawne retry naprawiają pakiet | `13/14/15-*`, `32-controlled-eviction.json`, `33-network-error-no-falseReady`, `35-network-retry-ready-ui`. Osobno widoczne 3 oczekujące zmiany. |
| Rzeczywisty reload `/#/workout/session` → panel recovery → jawne Wznów; ten sam UUID, **7 powtórzeń / 5 kg / Lewa**, **0 automatycznych serii/PR** | `20-recovery-read-db.json`, `20-direct-active-recovery`, `21-direct-resumed-7-left`. |
| Faktyczny restart procesu na tym samym profilu offline, ponowny cold root/today/deep i reload recovery; te same pola i UUID | `22-process-restart.json`, `24-restart-recovery-panel`, `24b-restart-actual-reload-db.json`, `27-restarted-resumed-fields`. |
| Nieodwiedzone wcześniej cw369/cw364 i ich ilustracje są dostępne offline | `17-unvisited-proof.json`, `25/26-offline-unvisited-*.png`. |
| Jedna jawna seria, offline finish i dokładna notatka emoji-only `💪 ⚠️ 👩‍💻 💪🏽`; cold restart zachowuje wynik | `28-explicit-offline-set-db.json`, `29-emoji-only-offline-painted.png`, `30-offline-finished-db.json`, `31-cold-restart-emoji-summary`. |
| Prawdziwy reconnect i ACK: **outbox 0 / deferred 0**, repeated sync bez duplikatów; niezależny drugi profil wykonuje login/pull i pokazuje tę samą serię/notatkę | `34-reconnected-acked-db.json`, `34-real-api-pull.json`, `36-repeat-api-pull.json`, `37-second-pulled-db.json`, `38-second-summary-single-set.png`, `39-final-postgres.json`. |
| Brakujące webp/woff2 online dają 404, bez HTML aplikacji | `35-missing-statics-online.json`. |

Sesja **`9a4e23a5-94b3-4962-98be-204ab5bc3986`**, seria
**`a8b370bd-baeb-47b3-a7c5-27722dd34e18`**. Dopiero jawny zapis utworzył serię/PR;
po finish były 3 operacje. Końcowe API/pull/SQLite i read-only PostgreSQL są zgodne:
**1 profil, 1 sesja, 1 seria, 1 PR**. Recovery nie wymagało obejścia Home/Kontynuuj.
Zachowano timeouty harnessu poprzedzające poprawny test rzeczywistego reloadu;
nie zaliczono samych timeoutów jako PASS.

Cancel rzeczywiście przerywał transfer. Network error był osobną próbą naprawy
brakującego zasobu przy origin OFF, **nie** zatrzymaniem originu w połowie
pierwszego pełnego transferu. Core-only zapewnia start, nie pełny repertuar
fontów/ilustracji ani stan ready pełnego pakietu.

## Font SC i worker — naprawa z jawnymi granicami

Próbka nie miała polskiego prefiksu: **`💪 ⚠️ 👩‍💻 💪🏽`**. Przed wpisaniem brak
page requestu SC. Naturalny wybór silnika pobrał z SW **Noto Sans SC 69**, plik
`notosanssc/v37/…87.woff2`: **5256 bajtów**, `font/woff2`, sygnatura `wOF2`, SHA-256
**`e4b7e47d39dc977a198121b39c448c698a5ccb33f14a48d945e25d122f6904e8`**.
Po jednym requestcie w każdym z trzech offline dokumentów (edycja i dwa cold
summary), dodatkowo jeden w niezależnym profilu po pull. Wszystkie cztery
odpowiedzi zgodne; nowe dokumenty nie są pętlą retry.

**PASS: zero remote requests, zero font HTTP 404/retry po pełnym prepare,
brak widocznego tofu.** Naturalne odpowiedzi i painted screenshoty są w
`29/31/40-natural-font-responses.json`, `45-exact-sc-request-summary.json`
oraz `29/31/40-*.png`. Audyt cache nie zastępował naturalnego requestu silnika.

Pozostaje niewyciszony **ogólny warning Noto coverage**, po jednym w czterech
dokumentach z próbką. Jest zgodny z osobną diagnozą nominalnego **U+FE0F/VS16**
w [module fontów](modules/offline-fonts.md); w tym nieinstrumentowanym E2E nie
odczytywano ponownie tablicy brakujących kodpunktów. **Nie ma zero-warning PASS
ani gwarancji dowolnego Unicode.** Historyczny realny SC 404/retry jest naprawiony
w tej reprodukcji; nie wolno utożsamiać go z samym warningiem FE0F.

[Worker suite](offline-worker-clients-2026-10-18.md) obejmuje prawdziwe
file-backed DedicatedWorker/SharedWorker, restart SW, origin OFF, wersje A/B
i fail-closed po utracie routing metadata. Faktyczny Drift wykonuje
**`SELECT 41 + 1 AS answer` → 42** domyślnie (sharedIndexedDb) i po wymuszeniu
dedicated `unsafeIndexedDb`, bez inMemory. Oryginalne Drift/SQLite pozostają
byte-identical. Finalny compiled E2E dodatkowo potwierdza trwałą bazę, oba typy
workerów, recovery, zapis i synchronizację (`44-runtime-worker-targets.json`).
Nie daje to uniwersalnego wsparcia dla nieufnych Blob/nested workerów, pustego
clientId ani wszystkich backendów OPFS/COOP/COEP czy threaded rendererów.
Brak zaufanego przypięcia pozostaje fail-closed.

## Otwarte bramki i przekazanie

- **NOT TESTED — rollout dwóch różnych pełnych compiled buildów.** Fixture
  legacy/custom A→B i wiele kart ma PASS, ale nie zalicza migracji dwóch pełnych
  aplikacji. Wymagane przed deklaracją takiej gotowości rollout.
- **MANUAL PENDING / UNTESTED — fizyczny iPhone/Android**: instalacja standalone,
  cold/warm start, lock, usypianie, OS kill, storage eviction, timer/checkpoint
  i foreground reconnect. [Checklista urządzeń](pwa-offline-acceptance-2026-10-17.md#ręczna-lista-ios--android--nadal-untested).
  Nie ma dowodu trwałości iOS storage ani pracy JS/timera/Wake Lock/background
  sync w tle. Adapter poza web zwraca **unsupported**, nie gotowość PWA.
- **Nie ponowiono pełnej macierzy w finalnym E2E:** quota exhaustion, zabicie SW
  podczas pobierania, równoległe pobieranie kart, corruption, unknown protocol,
  timer time/rounds, repeat cursor, wiele aktywnych sesji, account-switch/CAS.
  Istniejące native/widget/Node/fixture dowody mają własny zakres i nie są nowym
  compiled-browser wykonaniem tych przypadków.

Finalne `verify.py` ma **exit 0**, asercje w `verification.json` są PASS.
`cleanup.py` ma **exit 0**: zero własnych kontenerów/sieci/wolumenów; historyczne
artefakty, profile i obrazy zachowano. Sekrety pozostają chronione i nie są
treścią raportu. Aktualizacja dotyczy wyłącznie dokumentacji wyników i statusu.

Podstawa: [AGENTS](../AGENTS.md),
[master design](superpowers/specs/2026-10-17-offline-readiness-design.md),
[plan z checklistą](superpowers/plans/2026-10-17-offline-readiness.md),
[offline package](modules/offline-package.md), [offline UI](modules/offline-ui.md)
i źródłowy raport browser LATEST. Przyszłe wydanie wymaga osobnej decyzji oraz
wersjonowania według AGENTS; ten raport nie jest wdrożeniem.
