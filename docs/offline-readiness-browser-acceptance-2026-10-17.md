# Offline readiness — final compiled-app E2E, 2026-10-17

## Wynik i granice

**PASS głównych przypadków skompilowanego offline/recovery/real sync.**
**FAIL dodatkowej kontroli lokalnych fontów: powtarzające się 404/retry sharda
Noto Sans SC.** Próbka emoji jest namalowana bez widocznego tofu; nie jest to
deklaracja braku błędów fontów ani pełnego pokrycia Unicode.

| Przypadek | Wynik |
|---|---|
| Jedna wizyta online → aktywny SW → zatrzymany origin → cold root/deep/today | **PASS** startu rzeczywistej aplikacji; tylko core, bez pełnej gotowości ilustracji/fontów |
| UI początkowe notReady, rozmiar i zgoda, prepare/progress/cancel/retry | **PASS** rzeczywistego adaptera Dart–JS–SW |
| Pakiet ready, wszystkie 442 długości i SHA256 z faktycznego cache | **PASS** |
| Utrata pliku → UI notReady → jawna naprawa | **PASS** |
| Origin zatrzymany podczas próby naprawy → error/network, 441/442, bez ready → retry po reconnect | **PASS** |
| Cold root/deep i restart procesu przy nadal zatrzymanym originie | **PASS** |
| Nieodwiedzone w UI cw369/cw364, ilustracje namalowane offline | **PASS** |
| Próbka `💪 ⚠️ 👩‍💻 💪🏽`, bez zewnętrznych żądań i widocznego tofu | **PASS** wyglądu próbki; zob. osobny FAIL konsoli niżej |
| Direct active URL → nowy panel recovery → Wznów trening, ten sam UUID i 7/5/Lewa, 0 serii/PR | **PASS** |
| To samo po restarcie przeglądarki → jeden jawny log → offline finish | **PASS** |
| Reconnect, realne ACK, outbox/deferred 0, brak duplikatu, drugi profil real pull | **PASS** |
| API nie trafia do CacheStorage; missing webp/woff2 daje 404 zamiast SPA HTML | **PASS** |
| Zero lokalnych font 404/retry | **FAIL**, nie wyciszano ani nie naprawiano |
| Fizyczny iPhone/Android, usypianie, trwałość storage i praca w tle | **UNTESTED / manual pending** |
| Aktualizacja pomiędzy dwiema różnymi skompilowanymi wersjami | **UNTESTED w tym przebiegu** |

Historyczne RED/FAIL w `pwa-offline-acceptance-2026-10-17.md`,
`training-rhythm-browser-acceptance-2026-10-17.md` i
`offline-waiting-diagnosis-2026-10-17.md` pozostają nienadpisane. Nowy wynik
dotyczy wskazanego nowego obrazu i wymienionych przypadków. Nie ma deklaracji
„wszystkie PWA/device/update scenariusze PASS”.

## Środowisko i artefakty

Nowy katalog: **`/tmp/opencode/offline-final-20261017-c4e831/`**.
Prefiks własnych zasobów: `fit-offline-final-20261017-c4e831`.
Przeczytano AGENTS, DEPLOY, projekt offline-readiness, moduły offline-package,
offline-ui, active-session-recovery oraz diagnozę lifecycle waiting.

- Gotowy runtime **`fit-web:offline-local-fixed`**:
  index `sha256:efabff047879cf554c5fb6a0c8265e805b943950d95ce7d7fbc6fc68923d6393`,
  config `sha256:85a2e1185eb5294b64a514690ddfdecc475a7adb6a1d3d4cb621e79170940984`.
  Index sprawdzony przez Docker inspect; config niezależnie przez image save.
- Pakiet **`7d654384c0aacd3df98b82a7a9400e8ef20ce9f20b2b3817ab6bd01b1b87a454`**,
  **442 pliki / 46 801 539 bajtów / 44.63 MiB**. Fingerprint manifestu
  przeliczony niezależnie z jego treści; suma oraz SHA256 każdego pliku
  zweryfikowane na faktycznych odpowiedziach CacheStorage, czterokrotnie.
- Świeży PostgreSQL 16, wolumen, nowy certyfikat i konto utworzone oficjalnym CLI
  przez stdin. Sekrety **0600**, katalog **0700**, bez wartości w logach.
- API reused jako niezmienny obraz, bez starej bazy/kontenera:
  `sha256:b6eac82f54561df0de716b57f58ae61bd029189757f15ce2d37193bbc884f4ab`.
  Wszystkie **40 plików Python app/** zgodne z aktualnym backendem przed provision
  i w działającym kontenerze. `backend/app/sync/service.py` SHA256:
  `d0ca8a0bc581ec6db43843dcf8cea8fa1ce5ece71371f37b384bee87c46625ff`.
  Backend source manifest SHA256:
  `b4887d229b109def1ba70d0ca795f8319d19760baa6a21db05c43a1bcd88d2c3`.
- Drift **13**, Alembic **0010**. Wszystkie zapisy domenowe przez UI.
  Brak SQL/SQLite injection, seedów danych, stubów API/auth/ACK.
- HTTPS localhost z SAN/SPKI i `isSecureContext=true`; SW rzeczywiście włączone.
  Wewnętrzna sieć Docker, bez host ports; browser `--network container:<own web>`.
  Routing żądań stron dopuszcza tylko `https://localhost/`; SW pobiera statyki
  własnego originu. Nie zmieniano bezpieczeństwa przeglądarki lub produkcji.
- Chromium **140.0.7339.16**. Użyto wskazanego
  **`tests/tools/offline_browser_driver.py`**, wykluczającego tylko targety SW
  z CDP auto-attach. Potwierdzono rzeczywiste SW z `attached:false`.
  Brak ręcznego claim/skipWaiting/terminacji SW dla uzyskania sukcesu.
- Stary obraz harnessu miał driver bez oczekiwanego coreBundle; pomocnik odmówił
  startu, zanim uruchomiono test. Zamontowano **read-only istniejący hostowy
  Playwright 1.60.0**, z jawną ścieżką istniejącego Chromium w obrazie. Pomocnik
  tworzył swoją tymczasową kopię drivera. Nie instalowano ani nie zmieniano
  zainstalowanego Playwrighta, zależności lub kodu helpera.
- Przekazane wcześniej **812 Flutter PASS / analyze 0 / build PASS** oraz
  **378 backend PASS** nie były ponawiane tutaj. To nowa akceptacja runtime E2E.

## 1. Core przy jednej wizycie

Świeży `profile-core` zalogował się, przeszedł onboarding i pozostał w pierwszym
dokumencie. Stan natywny: **active=activated, controller=NULL**, bez installing
lub waiting — bez drugiej kontrolowanej nawigacji i bez prepare.

Zatrzymano **własny kontener web**, a nie tylko `/api`, routing lub stronę CDP.
Zamknięto proces Chromium i otwarto zachowany profil. Cold `/`, `/today` oraz
`/workout/session` dostały powłokę i uruchomiły rzeczywistą aplikację.
`/healthz?…` nie działał. Hash-router aplikacji jest odrębny od testu fallbacku
HTML ścieżek: bezpośrednie recovery sprawdzono pod `/#/workout/session` w sekcji 3.

Dowody: `02-core-native-sw.json`, `02-core-cache.json`,
`02-driver-proof.json`, `03-core-cold-root.png`, `04-core-deep-today.png`,
`05-core-deep-session.png`, `03-origin-stopped-probe.json`.
Core-only generował błędy niepobranych fontów Cupertino/Noto Symbols; ten
przypadek dowodzi startu shell, **nie** pełnej gotowości fontów bez zgody.

## 2. Pakiet przez skompilowany UI

Osobny świeży `profile-package` zalogował się do tego samego real API.
**Ustawienia → Tryb offline** pokazało `notReady`, **27/442** pliki,
22 362 189 zweryfikowanych bajtów, pełny rozmiar **46 801 539**.
Nie wykonywano ręcznego warmowania pełnego cache.

Wyłącznie przyciski UI uruchamiały prepare/cancel. Dialog podał bajty, MiB i 442
pliki. Po potwierdzeniu pokazano postęp, następnie **Anuluj pobieranie** dało
„Pobieranie anulowane” przy częściowym cache (65/442 w snapshotcie UI).
**Ponów pobieranie** i kolejna zgoda doprowadziły do „Zasoby gotowe offline”,
**442/442** i dokładnej liczby bajtów. Diagnostic `fitOffline.status()` był tylko
odczytem — nie zastępował kliknięć prepare/cancel skompilowanego Darta.

Kontrolowana mutacja testowa dotyczyła **wyłącznie CacheStorage**: usunięto
rzeczywisty plik ilustracji cw369. UI „Sprawdź ponownie” odebrało gotowość,
status pokazał **441/442**. Jawne pobieranie naprawiło plik; read-only audit
potwierdził znowu wszystkie 442 długości i SHA256.

Po późniejszym offline finish drugi kontrolowany eviction usunął cw364.
Przy nadal zatrzymanym originie UI prepare zakończyło się **error/network,
441/442**, z opisem przerwanego połączenia, a obok pozostała kolejka **3 zmian**.
Nie pokazano fałszywego ready. Po reconnect i ponownej zgodzie UI naprawiło
cache do 442/442; ponowiony pełny audit był zgodny.

To obejmuje anulowanie **w trakcie transferu** i rzeczywisty błąd sieci przy
próbie naprawy brakującego pliku. Nie deklarujemy osobnego przebiegu polegającego
na wyłączeniu serwera w środku pierwszego pełnego transferu.

Dowody: `06-package-initial-ui`, `06-package-status.json`, `07-size-consent`,
`08-downloading-ui`, `09-cancelled-ui`, `10-retry-progress-ui`, **`11-ready-ui.png`**,
`12-all442-cache-hash-audit.json`, `13-controlled-cache-eviction.json`,
`14-eviction-not-ready`, `15-repaired-all442-audit.json`,
**`32-network-error-no-falseReady.png`**, **`35-network-retry-ready-ui.png`**,
`35-final-all442-audit.json`.

Artefakt `15-repaired-status.json` uchwycił jeszcze **downloading**, a plik PNG
`15-repaired-ready-ui` mimo nazwy pokazuje **checking**. Nie używano ich jako
dowodu ready; właściwy dowód to późniejszy audit oraz ready 30/35. Nazw i
nieudanych asercji harnessu nie przepisywano, żeby zachować chronologię.

API nie pojawiło się w żadnym CacheStorage, także po loginach i real sync.
Brakujące `.webp` i `.woff2` online dostały **404**, nie index aplikacji pod 200.
Strona błędu 404 Nginx jest HTML, lecz nie jest fallbackiem SPA.

## 3. Recovery i wykonanie offline

Plan wygenerowano i rozpoczęto przez UI online. Ustawiono **7 powtórzeń,
5 kg, Lewa**, bez jawnego zapisu. Po flush: 1 sesja, 1 szkic, 0 serii, 0 PR.
Ponownie zatrzymano cały origin.

Pod **`/#/workout/session`** świeży dokument pokazał nowy panel:
„Znaleziono niedokończony trening”, UUID i **Wznów trening**. Nie używano obejścia
Home → Kontynuuj. Kliknięcie przywróciło plan/formularz, te same wartości i
UUID **`bba67693-b7e4-4b05-abf4-996ddb047d40`**, nadal bez logów/PR.

Zamknięto proces Chromium i ponownie uruchomiono zachowany profil przy
**nadal zatrzymanym web**. PIDs przed/po są różne. Cold root/deep uruchomiły
aplikację, a bezpośredni active URL znów pokazał panel. Jawne wznowienie ponownie
zachowało pola i UUID. Brak automatycznego wykonania lub dodatkowej sesji.

Offline pierwszy raz otwarto w UI **cw369 i cw364**, z prawidłowo namalowanymi
ilustracjami. Dopiero potem **Seria wykonana (0)** zapisała jeden log
**7 × 5 kg, left, wariant NULL, RPE 7**. Finish dostał notatkę
`💪 ⚠️ 👩‍💻 💪🏽`; screenshot obejrzano — symbole, ZWJ i modyfikator skóry
namalowane, bez widocznych prostokątów brakujących glifów.
Offline finish zostawił dokładnie **1 sesję / 1 serię / 1 PR / 3 operacje outbox**.
PR powstał przy rzeczywistym jawnym zapisie, nie przy recovery.

Dowody: `17-guided-7-left-online`, `17-online-guided-db.json`,
**`20-direct-active-recovery.png`**, **`21-offline-direct-resumed-fields.png`**,
`22-process-restart.json`, `22-offline-restart-root`, `23-offline-restart-deep-today`,
`24-restart-recovery-panel`, **`25-offline-unvisited-cw369.png`**,
**`26-offline-unvisited-cw364.png`**, `27-restarted-resumed-same-fields`,
`28-explicit-one-offline-set.json`, **`29-offline-emoji-painted.png`**,
`30-offline-finished-db.json`, `30-transport-proof.json`.

Pierwsza próba reload po plannerze pozostawała na URL gałęzi Ustawień; nie była
dowodem direct active URL. Dlatego następnie jawnie nawigowano do właściwego
`/#/workout/session`, a wynik panelu i wznowienia zapisano osobno jako 20/21.

## 4. Reconnect, rzeczywiste API i PostgreSQL

`docker stop web` usuwa endpoint jego sieci. Próba zastępczego Nginx w starym
namespace nie rozwiązała upstream `api` i nie została wykorzystana jako wynik.
Kontener próby usunięto. Poprawny reconnect: start własnego web, restart własnego
kontenera browser, ponowne otwarcie **tego samego trwałego profilu** w nowym
namespace. Nie zastępowano DNS/ACK ani nie otwierano portów hosta.

Rzeczywiste **Synchronizuj teraz** wysłało kolejkę: outbox/deferred **0**.
Powtórzenie synchronizacji zachowało identyczny API pull, bez duplikatu.
Nowy `profile-second` wykonał rzeczywisty login i pull, pokazał historię oraz
podsumowanie jednej serii, strony Lewa i notatki emoji.

Log UUID **`d88bd462-6174-41df-b4ab-49d32d9dc17f`** jest ten sam w offline
SQLite, po ACK, w drugim profilu i PostgreSQL. Najnowsze payloady/wersje każdego
UUID z API są identyczne z read-only SELECT PostgreSQL. Stan końcowy:
**1 profil, 1 sesja, 1 seria, 1 PR**; brak zapisanych planów i sztucznych fixture'ów.
Trzy logowania UI dostały **204**, session/push/pull **200**.
401 przed loginem i 403 opcjonalnego mentora pozostały w pełnym logu.

Dowody: `34-reconnected-acked-db.json`, `34-real-api-pull.json`,
`36-repeat-api-pull.json`, `37-second-pulled-db.json`,
**`38-second-summary-single-set.png`**, `39-final-postgres.json`.

## 5. Pozostały FAIL fontów — bez maskowania

Końcowy przegląd konsoli wykazał lokalne żądania nieobecnego w pakiecie sharda:

```text
/font-fallbacks/notosanssc/v37/k3kCo84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYkldv7JjxkkgFsFSSOPMOkySAZ73y9ViAt3acb8NexQ2w.87.woff2
```

**Noto Sans SC 69 → 404/retry**: 395 komunikatów HTTP404 w fazie restart/offline,
5 po reconnect i 27 w końcowym ponownym cold/offline odczycie notatki.
Wystąpił też jeden ogólny „Could not find a set of Noto fonts…”. Nie ustalano
kodpunktu przez instrumentowanie skompilowanego kodu w tym przebiegu.
**Nie przypisujemy automatycznie tych 404 znanemu U+FE0F** ani nie wyciszamy ich.

Próbka nadal jest namalowana bez widocznego tofu, wszystkie **zadeklarowane**
442 statyki mają prawidłowe SHA/długości, a żądanie nieznanego sharda prawidłowo
nie dostaje HTML aplikacji. To nie dowodzi kompletności fontów żądanych przez
silnik. Kontrolę **zero lokalnych font HTTP errors/retries oznaczono FAIL**.
Brak zewnętrznych żądań jest osobnym PASS; obserwacje resource URLs są same-origin.
Logi obejmują również oczekiwane błędy fontów w profilu **core-only**.

Dowody: **`43-font-console-by-phase.json`**, `traffic.json`,
`40-offline-origin-resource-proof.json`, `40-final-offline-emoji-summary.png`.
Problem odtworzył się podczas ponownego cold/offline wyświetlenia zapisanej
notatki. Po odczycie dowodów nie wykonywano napraw źródeł ani dalszych przypadków
fontowych; stos był już zatrzymany i posprzątany. Historyczna diagnoza FE0F jest
w `docs/modules/offline-fonts.md` i pozostaje odrębnym świadectwem.

## Weryfikacja, sprzątanie, manual pending

`verify.py` zakończył się **exit 0** dla jawnych asercji danych/route/cache.
`verification.json` rozdziela główne PASS od residual font FAIL; exit 0 nie
oznacza zatajenia tego problemu. PIDs, natywne sloty SW, Docker stop/start,
request/response statusy bez auth headers, ARIA i screenshoty zachowano.
`41-origin-lifecycle-events.json`, `41-origin-final-stopped.json` i
`42-nginx-access.log` potwierdzają własny origin oraz rzeczywiste transfery.

`cleanup.py`: **exit 0**, zero własnych kontenerów/sieci/wolumenów.
Zachowano artefakty, profile, sekrety 0600 w katalogu 0700 i candidate images.
Bez edycji kodu aplikacji, zależności, toolchainu, wersji, produkcji,
commit/push/deploy. Dodano wyłącznie ten raport w repo i tymczasowy harness.

**UNTESTED:** fizyczne iPhone/Android i instalacja na urządzeniu, usypianie i
zabijanie procesu przez system mobilny, trwałość storage, timer czasowy/rounds po
recovery (wybrany blok reps nie uruchamiał timera), recovery repeat cursora w tym
nowym obrazie, wiele aktywnych sesji/account-switch/CAS, quota exhaustion,
zatrzymanie SW podczas download, równoległe karty pobierania i aktualizacja
dwóch różnych skompilowanych wydań. Istniejące fixture/native testy oraz wcześniejsze
812/378 nie są przedstawiane jako wykonanie tych przypadków w tym E2E.

---

## LATEST — 2026-10-18 UTC: final image, SC font i worker pin — GREEN

**PASS ponowionych przypadków pełnej skompilowanej aplikacji na
`fit-web:offline-final`. Historyczny font FAIL powyżej pozostaje zachowany;
na nowym obrazie jego reprodukcja SC 404/retry już nie występuje.**

Rzeczywisty czas rozpoczęcia przeglądarek: **2026-10-18T06:49:51Z**;
weryfikacja dowodów: **2026-10-18 około 07:06 UTC**. Data w nazwie dokumentu
jest historyczna, nie datą tego ponowienia.

### Nowe środowisko i identyfikacja

- Nowy katalog: **`/tmp/opencode/offline-final-20261018-e9a276/`**.
  Nowy prefiks zasobów `fit-offline-final-20261018-e9a276`, nowy PG/wolumen/konto,
  nowe profile `profile-core`, `profile-package`, `profile-second` i certyfikat.
  Starych profili/danych/cache nie kopiowano.
- Web index: **`sha256:590c5c6cc9d9cbe8b7ae3032493bd4c1c34c7597e688892fb052f888bc16dae8`**.
  Config: **`sha256:369b498b9cafe2d185f6d0c4b2ffba6410cf195a3e778d9da7a341c793ca2ee8`**.
  Sprawdzone odpowiednio przez inspect i odczyt configu z image save.
- Pakiet: **`4e1f9fb52f809558e14e454bcab31962cac7508afbae248d5a728e15bdfd7d47`**,
  **443 pliki / 46 808 551 bajtów / 44.64 MiB**. Niezależnie przeliczono
  fingerprint treści manifestu. Cztery read-only audyty faktycznego cache
  sprawdziły długość i SHA256 **443/443** plików, nie samą flagę ready.
- API reused bez starej bazy/kontenera:
  `sha256:b6eac82f54561df0de716b57f58ae61bd029189757f15ce2d37193bbc884f4ab`.
  Przed provision i w działającym API: **40/40 plików Python zgodnych z aktualnym
  backendem**. Hash service.py nadal
  `d0ca8a0bc581ec6db43843dcf8cea8fa1ce5ece71371f37b384bee87c46625ff`.
  Drift **13**, Alembic **0010**.
- HTTPS localhost, SPKI, internal network, **zero host ports**. Konto przez
  oficjalny CLI, sekrety **0600**, katalog **0700**, bez auth headers/sekretów
  w logach. Wszystkie zapisy domenowe przez UI. Bez DB injection, API/auth/ACK stubów.
- Ten sam dostarczony helper `offline_browser_driver.py`, tymczasowa kopia
  istniejącego drivera i istniejący Chromium **140.0.7339.16**. Zainstalowanego
  Playwrighta i polityk bezpieczeństwa nie zmieniano. Potwierdzono prawdziwy SW
  **attached:false**. Dedicated worker może być podłączony standardowo — helper
  wyklucza tylko SW. Nie wymuszano skipWaiting/claim ani zatrzymania workera.
- Przekazane **813 Flutter PASS / analyze 0 / compiled build OK**,
  log `tool_14dbc9eca001JF887YvejngkQw`, oraz wcześniejsze 378 backend PASS
  nie były ponawiane. Niniejsza sekcja jest nowym świadectwem browser E2E.

### Macierz ponowiona na nowym obrazie

| Przypadek | Wynik i rzeczywisty dowód |
|---|---|
| Pierwszy dokument online, aktywny SW bez drugiej kontrolowanej nawigacji | **PASS**; active=activated, controller=NULL; `02-core-native-sw.json`. |
| Zatrzymanie całego originu, cold root/today/deep i actual app paint | **PASS**; `03-core-cold-root`, `05a-core-cold-today-confirmed`, `05b-core-cold-deep-confirmed`, socket probe refused. Core nie udaje pełnej gotowości fontów. |
| Skompilowane UI settings → Tryb offline, notReady przed zgodą | **PASS**, **27/443**, 22 362 188 cached bytes, rozmiar **46 808 551**; `06-package-initial-ui`, `06-package-status.json`. |
| Jawna zgoda rozmiaru → prepare/progress → cancel → retry → ready | **PASS**; rzeczywiste kliknięcia Darta, `07-size-consent`, `08-downloading-ui`, `09-cancelled-ui`, `10-retry-progress-ui`, **`11-ready-ui.png`**. Bez ręcznego full warm. |
| Pełny pakiet i API poza CacheStorage | **PASS 443/443**, wszystkie rzeczywiste długości/SHA; `12-all443-cache-hash-audit.json`, audyty 15/30/35. |
| Cache eviction po ready, UI check nie udaje ready, naprawa | **PASS**; kontrolowane usunięcie cw369 wyłącznie z CacheStorage, **442/443**, jawne UI pobiera brak; `13-controlled-eviction`, `14-eviction-notReady-ui`, `15-repaired-ready-ui`. |
| Direct `/workout/session` hash-route **reload** → panel → Wznów | **PASS**; prawdziwy reload `/#/workout/session`, UUID, pola **7, 5 kg, Lewa**, **0 set/PR**; `20-direct-active-recovery`, **`21-direct-resumed-7-left.png`**. |
| Cold proces na tym samym profilu przy wciąż zatrzymanym originie | **PASS**; inne PIDs, root/today/deep, panel po rzeczywistym reloadzie, te same pola i UUID; `22-process-restart`, `24-restart-recovery-panel`, `27-restarted-resumed-fields`. |
| Nieodwiedzone wcześniej w UI cw369/cw364 i ilustracje offline | **PASS**; brak wcześniejszych page requestów, `17-unvisited-proof.json`, `25/26-offline-unvisited-*.png`. |
| Jedna jawna seria → offline finish z notatką **tylko emoji** | **PASS**, dokładnie `💪 ⚠️ 👩‍💻 💪🏽`, 7×5/Lewa, 1 sesja/1 seria/1 PR/3 outbox; `28-explicit-offline-set-db.json`, **`29-emoji-only-offline-painted.png`**, `30-offline-finished-db.json`. |
| Naturalny SC, emoji-only, bez asset 404/retry/remote fontów/tofu | **PASS**, szczegóły binarne poniżej. |
| Cold restart i ponowny odczyt notatki z nadal zatrzymanym originem | **PASS**, ponownie naturalny SC z SW, `31-cold-restart-emoji-summary`, `31-natural-font-responses.json`. |
| Brak pliku przy origin OFF → error/network → reconnect i UI retry | **PASS**; drugie kontrolowane usunięcie cw364, **442/443**, brak false ready i osobno **3 zmiany**; `33-network-error-no-falseReady`, `35-network-retry-ready-ui`. |
| Actual API reconnect, repeated sync bez duplikatu, drugi profil pull | **PASS**, outbox/deferred 0, identyczne UUID i 1 seria w UI; `34/36-*-api-pull.json`, `37-second-pulled-db.json`, `38-second-summary-single-set`. |
| Missing webp/woff2 online zwraca 404 bez SPA HTML | **PASS**, `35-missing-statics-online.json`. |

Cancellation rzeczywiście przerwało transfer. Błąd sieci sprawdzono osobno
przy naprawie brakującego pliku na zatrzymanym originie; nie przedstawiamy tego
jako wyłączenia serwera w połowie pierwszego pełnego transferu.

### Dokładny naturalny dobór SC — naprawiony historyczny FAIL

Wartość formularza/notatki była **dokładnie** `💪 ⚠️ 👩‍💻 💪🏽`, bez polskiego
prefiksu. Przed wpisaniem nie było page requestu SC (`29-sc-before-input.json`
jest puste). Audit cache nie wykonywał fetch zasobu z dokumentu i nie zastępował
naturalnego wyboru silnika.

Naturalna odpowiedź strony z SW dla:

```text
/font-fallbacks/notosanssc/v37/k3kCo84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYkldv7JjxkkgFsFSSOPMOkySAZ73y9ViAt3acb8NexQ2w.87.woff2
HTTP 200, fromServiceWorker=true, Content-Type: font/woff2
bytes: 5256, signature: 77 4F 46 32 (wOF2)
SHA256: e4b7e47d39dc977a198121b39c448c698a5ccb33f14a48d945e25d122f6904e8
```

| Epoka dokumentu | Naturalne fallback font requests | SC | Wynik |
|---|---|---|---|
| Wpisanie emoji-only offline | Emoji 9 ×1, **SC 69 ×1**, Emoji 8 ×1 | 1×5256 B z SW | wszystkie 200, poprawne binaria, brak retry |
| Pierwszy cold restart, offline summary | Roboto ×1, **SC 69 ×1**, Emoji 9 ×1, Emoji 8 ×1 | 1×5256 B z SW | wszystkie 200, brak retry |
| Końcowy kolejny cold restart, ponownie origin OFF | Roboto ×1, **SC 69 ×1**, Emoji 8 ×1, Emoji 9 ×1 | 1×5256 B z SW | wszystkie 200, brak retry |

Łącznie **3 naturalne offline SC requests**, po jednym na dokument, oraz **1**
w niezależnej przeglądarce online po real pull — wszystkie **4** odpowiedzi mają
ten sam WOFF2/5256/SHA. To normalne ponowne pobrania przez nowy dokument/proces,
nie pętla retry. Dokładne ścieżki, hashy pozostałych fontów i statusy:
**`29-natural-font-responses.json`**, **`31-natural-font-responses.json`**,
**`40-natural-font-responses.json`**, **`45-exact-sc-request-summary.json`**.

**Zero fontowych HTTP failures i zero remote requests po pełnym przygotowaniu.**
Obejrzano screenshoty edycji oraz obu cold summary — brak widocznego tofu.
Core-only świadomie nie zawiera całego pakietu: jego wcześniejsze nieudane próby
Cupertino/Symbols są zachowane i nie są liczone jako test pełnej gotowości.

Pozostał **jeden ogólny warning Noto coverage na każdy z czterech dokumentów
wyświetlających próbkę**; nie wyciszano go. To jest zgodne z odrębną znaną
diagnozą nominalnego FE0F; w tym nieinstrumentowanym E2E nie mierzono ponownie
tablicy brakujących kodpunktów. Nie ma już lokalnego asset 404/retry, nie ma
deklaracji „zero warnings” ani pełnego pokrycia Unicode.
`43-font-console-by-phase.json` zachowuje oryginalne komunikaty.

### Recovery, worker i actual API — integralność

Sesja **`9a4e23a5-94b3-4962-98be-204ab5bc3986`**, seria
**`a8b370bd-baeb-47b3-a7c5-27722dd34e18`**. Recovery i restart nie dopisały
serii/PR. Nowy log powstał dopiero po `Seria wykonana (0)`. Po finish pozostały
3 operacje; po prawdziwym reconnect i przycisku synchronizacji: **0 outbox,
0 deferred**, a ponowny pełny API pull identyczny. Drugi kontekst pobrał te same
UUID i wyświetlił tę samą notatkę i pojedynczą serię. Najnowsze payloady i wersje
każdego UUID są zgodne z read-only PostgreSQL SELECT: **1 profil, 1 sesja,
1 seria, 1 PR**. Dane tego retestu powstały wyłącznie przez UI.

`44-runtime-worker-targets.json` potwierdza oryginalny **shared_worker „drift worker”**
oraz dedicated worker pod `https://localhost/drift_worker.dart.js`, przy
**service_worker attached:false**. Skompilowana aplikacja rzeczywiście otworzyła
trwałą lokalną bazę, odczytała recovery, zapisała offline serię/finish i później
zsynchronizowała je. Jest to E2E aktualnego układu Drift i rasteryzatora, bez
inMemory/SQL injection. Nie jest to ponowne wykonanie całej macierzy fixture
worker A/B, utraty routing lub opcjonalnych backendów; ograniczenia Blob/nested
worker z `docs/offline-worker-clients-2026-10-18.md` pozostają w mocy.

Origin fizycznie zatrzymywano przez `docker stop` własnego web. Health/API socket
probes przy nim zawodziły, a po zakończeniu pozostawał stopped. Na reconnect
uruchamiano własny web i restartowano własny kontener browser, aby dołączył do
nowego namespace, z zachowanym profilem. Dowody: `18/24/31/40-*-probe/proof.json`,
`41-origin-lifecycle-events.json`, `41-origin-final-stopped.json`, `42-nginx-access.log`.

Zachowano także błędy samego harnessu: jedna próba oczekiwała panelu po zmianie
samego hash, gdy sesja nadal była w RAM; kolejna zbyt szybko reloadowała dopiero
zmieniany hash i pozostała na today. Nie uznano tych timeoutów za PASS recovery.
Następne próby wykonały **rzeczywisty reload ustabilizowanego active URL** i
sprawdziły panel oraz odtworzone wartości. Snapshoty diagnostyczne i komendy
pozostały w nowym katalogu. Nie obchodzono recovery przez Home/Kontynuuj.

### Zakończenie i review limitations

`verify.py` **exit 0**: niezależny fingerprint, cztery audyty 443 plików,
naturalne WOFF2, brak font HTTP errors po prepare, actual API/PG i UUID/counts.
Wynik oraz niewyciszone warningi są w **`verification.json`**.
`cleanup.py` **exit 0**: zero własnych kontenerów/sieci/wolumenów.
Artefakty, profile, obrazy i chronione sekrety zachowane. Stare katalogi i wyniki
nie zostały nadpisane. W repo dopisano tylko niniejszą najnowszą sekcję;
bez source app changes, zależności, wersji, commit/push/deploy.

**Manual pending / UNTESTED:** fizyczny iPhone/Android, instalacja i usypianie
na telefonie, trwałość iOS storage, mobilne zabijanie procesu, praca w tle;
nie wolno przedstawiać tego Chromium jako „iPhone verified”. Nie ponawiano
aktualizacji między dwiema różnymi skompilowanymi wersjami, quota exhaustion,
timer time/rounds, repeat cursor recovery ani całej macierzy Blob/nested/
Dedicated/Shared/OPFS/COOP/COEP. Wcześniejszy review CLEAR i fixture wyniki
opisane przez właścicieli nie są nowym niezależnym review tych wszystkich
granic. PASS dotyczy powyższych rzeczywiście ponowionych przypadków.
