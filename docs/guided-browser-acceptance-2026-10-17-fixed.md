# Retest compiled browser po poprawkach — 2026-10-17

**Najnowszy retest mirroru fontów:** [guided-browser-acceptance-2026-10-17-fonts.md](guided-browser-acceptance-2026-10-17-fonts.md).
Na `guided-local-fonts` zero external attempts ma PASS; pełne zero local font
errors ma FAIL przez niemirroredowany Noto Sans v37 zwracający HTML z HTTP 200.
Poniższy raport zachowuje wcześniejszy wynik obrazu `guided-local-fixed`.

## Historyczny wynik obrazu fixed: PASS guided/resume i timer recovery; FAIL ścisłego zero-font-fetch

Rzeczywisty retest nowego compiled runtime wykonano po ponownym komunikacie
o ukończeniu builda. **Trwały szkic → reload → jawne wznowienie → ręczny zapis
→ finish → summary przeszły.** Polski tekst jest rzeczywiście namalowany
z lokalnymi Inter TTF (5 plików HTTP 200). Silnik nadal próbuje pobierać
fallback Roboto/Noto z `fonts.gstatic.com`, więc warunek całkowitego braku
zewnętrznych prób fontów nie przeszedł. Pełne wyniki i dowody są w końcowej
sekcji „Wykonany retest”. Poniższy BLOCKED pozostaje historycznym zapisem
pierwszego okna oczekiwania, nie aktualnym werdyktem funkcji.

## Historyczne okno 06:15–06:31 UTC: BLOCKED — brak artefaktu

**Nie uruchomiono retestu przeglądarkowego**, ponieważ wymagany nowy obraz
`fit-web:guided-local-fixed` nie pojawił się w dozwolonym oknie oczekiwania.
Nie użyto starego `fit-web:guided-local`, obrazu produkcyjnego ani narzędziowego
jako zastępczego klienta. Brak artefaktu nie dowodzi błędu poprawionej funkcji.
Nie ustalono też, czy main nadal buduje obraz, czy build zakończył się błędem.

### Wykonane kontrole

- Odczytano `AGENTS.md`, working set guided/plannera/interwałów oraz bieżące
  źródła kontraktu auth. Użyto instrukcji `webapp-testing`,
  `fit-flutter-workflow` i `verification-before-completion`.
- Pierwsza inspekcja **06:15:11 UTC**: `No such image`.
- Warunkowe `docker image inspect fit-web:guided-local-fixed` co **15 sekund**,
  limit **900 sekund**. Początek **06:16:23 UTC**, ostatnia próba w pętli
  **06:31:14 UTC**. Pętla zakończyła się statusem:
  `BLOCKED: no fresh fixed image within 15 minutes; no fallback`.
- Końcowa kontrola **06:31:45 UTC**, po zakończeniu limitu:

  ```text
  Error response from daemon: No such image: fit-web:guided-local-fixed
  ```

- Zapisano SHA-256 i mtime źródeł przyszłej kontroli świeżości kompilatu,
  m.in. providera guided, parsera planu, theme, pubspec i lockfile.
  W chwili przygotowania najnowszy sprawdzony theme/pubspec miał mtime
  **06:00:04 UTC**. Nie ma nowego `main.dart.js`, którego datę/hash można
  byłoby porównać. Nie deklaruję zgodności nieistniejącego runtime.
- Potwierdzono dostępność istniejącego, wyłącznie narzędziowego obrazu
  `fit-guided-browser-test:20261017` z poprzedniej akceptacji. Nie uruchamiano
  za jego pomocą starej aplikacji.

## Nowy, odseparowany harness

Katalog: **`/tmp/opencode/guided-acceptance-fixed-20261017T061511Z/`**.

- `browser.py`: nowa kopia/adaptacja poprzedniego drivera; lokalny fake auth,
  CSRF, pull/push z idempotentnym ACK i wersjami; blokada hostów poza loopback;
  persistent context w nowym katalogu przypadku; screenshot/HTML/ARIA,
  logowanie konsoli, pageerror, crash i ruchu.
- `guided.py`: przygotowany, **nieuruchomiony** scenariusz:
  kolekcja 19 → rzeczywisty generator i potwierdzenie → odkrywanie bloku
  „Otwarta książka” po nazwie, bez dawnego hardcode trzech kliknięć/10 powtórzeń
  → kontrola prefillu `3` → ręczne `7` i Lewa → warunkowy odczyt realnego
  SQLite z IndexedDB aż do trwałego szkicu → reload → jawne Kontynuuj/Wznów
  → identyczny UUID/krok/pola, bez nowej sesji/serii → jawna seria i zakończenie
  z notatką → summary celu 1×3 kontra rzeczywista Lewa/7.
- Odczyt SQLite w harnessie wykonuje SELECT na kopii rzeczywistych bloków
  IndexedDB w temp. Nie wstrzykuje szkicu ani frontendowego stanu.
- `wait_image.py`: ograniczona pętla inspekcji i kontrola świeżości względem
  zapisanych źródeł.
- `source-baseline.json`: zapisane mtime i SHA-256 źródeł.
- `blocked-status.json`: dokładne czasy i wynik braku obrazu.

Nowe fake UUID i osobny persistent profile są przewidziane w nowym driverze;
żaden profil jeszcze nie powstał, bo nie uruchomiono przeglądarki.
Historyczny katalog **`/tmp/opencode/guided-acceptance-20261017/`** i jego
RED evidence pozostały nietknięte przez ten retest.

## Zakres niewykonany — nie zaliczono

| Obszar | Wynik tego retestu |
|---|---|
| Nowy compiled klient / świeżość JS | BLOCKED: tag nie istnieje |
| Namalowany polski tekst z lokalnych Inter TTF | NIE TESTOWANO |
| Brak zewnętrznych fetchy fontów | NIE TESTOWANO |
| Trwały szkic 7/Lewa, krok, jeden UUID | NIE TESTOWANO |
| Reload i jawne wznowienie bez auto-logu | NIE TESTOWANO |
| Jawna seria, finish, summary plan 1×3 kontra actual 7 | NIE TESTOWANO |
| Timer checkpoint/pauza/reload/bez downtime | NIE TESTOWANO |
| Warianty/presety chmurowe | NIE TESTOWANO; poza wymaganym minimum |
| Instalacja PWA/telefon/service-worker offline | NIE TESTOWANO |
| Backend/CAS | NIE TESTOWANO |

Nie ma nowych screenshotów, logów przeglądarki ani dowodu PAINTED tekstu.
Historyczne screenshoty nie zostały przedstawione jako wyniki fixed.
Podane przez inne zadania wyniki 9 testów reprodukcji, testów fontów,
oczekiwanego pełnego zestawu Flutter i 373 testów backendu nie są wynikami
tej niezależnej akceptacji.

## Freeze i sprzątanie

Nie zmieniono feature code, assetów, modeli, zależności, generatorów, wersji,
deployu ani backendu. Jedyna repozytoryjna zmiana tego retestu to ten nowy
dokument. Reszta przygotowań jest wyłącznie w nowym katalogu `/tmp/opencode`.
Nie wykonywano commit/push/deploy, nie uruchamiano produkcji ani publicznych
portów. **Nie utworzono żadnego kontenera testowego ani procesu browsera**,
więc nie było własnych runtime'ów do usuwania. Nie usuwano cudzych danych,
kontenerów, obrazów ani historycznego evidence.

Dalszy rzeczywisty retest wymaga najpierw ukończonego nowego
`fit-web:guided-local-fixed`; statusu BLOCKED nie należy traktować ani jako
powtórzonego RED aplikacji, ani jako GREEN po poprawce.

---

## Wykonany retest po udostępnieniu obrazu — 2026-10-17, około 06:55–07:04 UTC

### Artefakt, rzeczywisty browser i izolacja

- Runtime wyłącznie `fit-web:guided-local-fixed`.
- Inspekcja Docker potwierdza manifest/index:
  `sha256:d82491301ff7f427b3c7733fd95e6763fd6133c153f6f4bf7c72de2244853a8c`.
  Created **06:53:31 UTC**. Podany przez main config digest
  `0373c253c4b5c9154b4d749039b42a89e055f0ef1a482c413c5b48890ed5db27`
  nie jest tu mylony z `.Id` indeksu zwracanym przez Docker.
- Rzeczywisty `main.dart.js` w kontenerze: mtime **06:53:22 UTC**, SHA-256
  `eb8774e5c9f7bfd1d8177a4bbd22c1706c12508633f6a03a91a308c0e1918f93`.
  Jest nowszy niż theme **06:00:04 UTC**, guided provider **02:34:16 UTC**
  i parser planu **02:18:31 UTC**. SHA źródeł provider/parser/theme/pubspec/lock
  pozostały zgodne z wcześniejszym `source-baseline.json`.
- Playwright **1.55.0**, prawdziwy headless Chromium **140.0.7339.16**,
  viewport **1200×1000**, CanvasKit. `isSecureContext=true`,
  `crossOriginIsolated=false`; rzeczywista baza korzysta z IndexedDB blocks.
- Własny Nginx `guided-accept-fixed-web-20261017-0655` miał `--network none`
  i puste `PortBindings`. Własne jednorazowe browsery używały
  `--network container:guided-accept-fixed-web-20261017-0655`.
  Adres wyłącznie `http://127.0.0.1:80`; nie wystawiono portów hosta.
- Osobne świeże profile/konta i pliki fake API dla `guided/` i `timer/`.
  Nie zmieniano historycznego profilu ani dowodów RED w starym katalogu.
  Każdy przypadek ma dokładnie jedną sesję; kolejne próby harnessu nie
  tworzyły nowych sesji, tylko jawnie wznawiały istniejącą.
- Semantykę włączano prawdziwym placeholderem Fluttera i TAB; wpisy przez
  click/Ctrl+A/type. Nie wstrzykiwano formularza, szkicu, timera ani SQL.

### Wyniki poszczególnych scenariuszy

| Scenariusz | Wynik | Rzeczywisty dowód |
|---|---|---|
| Nowy właściwy compiled runtime | **PASS** | manifest, data JS, SHA JS i źródeł |
| Kolekcja spine 19 | **PASS** | filtr UI, semantyka i namalowany screenshot |
| Generator/current source dose cw367 | **PASS** | rzeczywisty plan 10 bloków; 1 seria × 3 powt., 18 s estymowanej pracy na obie strony |
| Target/prefill, własne 7/Lewa, brak auto-logu | **PASS** | po focusie pole miało `3`, potem ręczne `7` i radio Lewa; seria 0 |
| Trwały szkic w SQLite przed reloadem | **PASS** | 1 session, 1 draft, 0 sets; payload `currentSlot=3`, reps `7`, side `left` |
| Reload i jawne Kontynuuj/Wznów | **PASS** | ten sam UUID/krok/7/Lewa, 1 session i 0 sets; brak nowej operacji startu |
| Jawna seria, note/finish/summary | **PASS** | jedna seria Lewa/7/RPE7; pierwotny cel 1×3; note i data zakończenia; draft usunięty |
| Rzeczywiście namalowany polski tekst i lokalne Inter TTF | **PASS** | oglądnięte PNG formularza, resume, summary, timera; pięć Inter TTF HTTP 200 |
| Brak zewnętrznych prób fontów, rozumiany dosłownie | **FAIL** | Roboto/Noto fallback `fonts.gstatic.com`, wszystkie blokowane; brak żądań zewnętrznego Inter |
| Timer: praca → trwała pauza → reload/resume bez downtime | **PASS w tym zakresie** | 4 441 401 µs przed i po, pauza, 16 s pozostało, 12,848 s wall-time poza timerem, sets 0 |
| Timer: review bez logu i jawne zapisanie rundy raz | **PASS** | review 4 s skrócone, jeszcze sets 0; dopiero click save daje 1 set/4 s i konsumuje checkpoint |
| Warianty A/B i migracja presetów | **NIE TESTOWANO** | obecność selektora Bazowy nie jest zaliczeniem wariantów/historii/migracji |
| Instalowana PWA/telefon, background OS, SW cache | **NIE TESTOWANO** | desktop headless browser, SW celowo blokowany dla pełnego przechwycenia API |
| Backend/CAS | **NIE TESTOWANO** | auth/sync są lokalnym stubem, nie serwerem produkcyjnym |

### Guided — dokładny stan i granica przed/po reloadzie

Fake konto: `b2000000-0000-4000-8000-000000000001`.
Sesja: **`83fc6c48-8542-41a6-b85c-0b78bc86f38a`**, lokalne ID 1.

Wybór bloku następował po rzeczywistej nazwie „Otwarta książka — obrót klatki
w leżeniu bokiem”, nie po dawnym hardcode trzech kliknięć. W tym planie wyszedł
akurat blok 4/10, zero-based slot 3. Cel odczytany z realnego snapshotu:
`sets=1`, `reps=3`, `workSeconds=18`, `restSeconds=30`.

Przed reloadem warunkowo odczytywano prawdziwe strony bazy IndexedDB i SELECT
na ich kopii w temp, aż istniał trwały wiersz szkicu z `7/left`. Nie oparto
werdyktu na samym stanie RAM lub screenshotcie.

| Stan | workout_sessions | workout_drafts | sets_log |
|---|---:|---:|---:|
| Przed reloadem | 1 | 1 | 0 |
| Po reloadzie / przed wznowieniem | 1 | 1 | 0 |
| Po jawnym Wznów | 1 | 1 | 0 |
| Po jawnym potwierdzeniu serii | 1 | 1 | 1 |
| Po potwierdzeniu zakończenia | 1 | 0 | 1 |

UUID pozostał identyczny. `reload-proof.json` zapisuje kopertę requestów od
granicy reloadu do odtworzenia formularza: **same GET, zero POST**. Liczba
zaakceptowanych operacji na tej granicy: `workoutSession: 1` przed i po,
bez workoutSet. Późniejsze jawne logowanie i finish tworzą normalne aktualizacje.
Cały przypadek guided: **3 unikalne operacje workoutSession, 1 workoutSet**;
to aktualizacje jednej sesji, nie trzy sesje.

Summary faktycznie maluje obok siebie cel **cw367 1×3** oraz wykonaną jedną
serię, a niżej **Lewa • 7 powt. (RPE 7)**. Zapisana notatka:
„Lokalny retest: lewa strona, siedem powtórzeń.” Pozostałe bloki mają brak
potwierdzenia; nie uznano ich za wykonane przez nawigację lub upływ czasu.

### Timer — osobny profil, rzeczywiste UI i bez dopisywania downtime

Z aktualnego statycznego katalogu/metadanych obrazu wybrano dostępne z profilem
ćwiczenie `tracking=rounds`: **cw281, Powitanie słońca A**. Wyszukanie, generacja
planu, start i konfiguracja timera odbyły się przez UI. Nie podszyto timera
fixture Dart ani JSON-em checkpointu.

Osobna sesja: **`59c95488-da00-4f8d-8c88-904e653b09ee`**.
Konfiguracja ręczna: przygotowanie 0 s, praca 20 s, przerwa 0 s, 1 runda.
Po rzeczywistej pracy i kliknięciu pauzy utrwalono:

```json
{"phase":"work","round":1,"paused":true,"elapsedMicros":4441401,"results":[]}
```

Po reloadzie, Kontynuuj/Wznów i ponownym otwarciu „Timer interwałów” cały
checkpoint jest **identyczny**, przy **12,847755932 s** wall-time między
odczytami. UI maluje **16 s / Wstrzymano / Wznów**. Nadal 1 sesja, 0 serii
i jedna operacja startu. „Zakończ odliczanie” daje review **4 s • skrócona**,
ale nie zapisuje serii. Dopiero „Zapisz wykonane rundy” zapisuje dokładnie
**4 s**, jeden set, i czyści `fields.timer`. Nie naliczono przerwy/reloadu
jako pracy. Nie testowano 100 rund ani background OS/telefonu.

### Fonty, błędy konsoli i zachowane nieudane próby harnessu

- Każdy przypadek pobrał lokalnie HTTP 200:
  `Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`,
  `Inter-Bold.ttf`, `Inter-ExtraBold.ttf` spod `/assets/assets/fonts/`.
  Nie podstawiano fontów z hosta ani przez route.fulfill.
- Zewnętrzny Inter/google_fonts nie był pobierany. Są jednak próby engine
  fallback: **Roboto**, **Noto Sans Symbols**, **Noto Sans Symbols 2/3**,
  miejscami dodatkowe Noto. To nie jest „zero żądań do Google fonts”.
  Wszystkie były abortowane przed połączeniem, a sieć kontenera była izolowana.
  W formularzu widać m.in. niepoprawny/brakujący glif przy „Bazowy” (dropdown).
- Łączne zarejestrowane próby fallback we wszystkich zachowanych przebiegach:
  guided **243**, timer **702**. Wielokrotne retry powodują, że `networkidle`
  nie jest wiarygodną granicą gotowości tej aplikacji w pełnej izolacji.
  Pierwszy przebieg guided osiągnął poprawny trwały draft, po czym harness
  przerwał na 30-sekundowym oczekiwaniu `networkidle` przy reloadzie.
  Zachowano jego `result.json` z FAIL i `failure-*.png`, bez kasowania sesji.
  Następnie wykonano kolejny rzeczywisty reload i całą dalszą ścieżkę tej samej
  sesji. Driver teraz próbuje `networkidle` przez 2 s, zapisuje timeout i czeka
  na rzeczywisty placeholder/locatory gotowego UI. Nie zmienia to aplikacji.
- Timer miał zachowane nieudane próby locatorów: pola zawierają w aria także
  zakres `(0–60)` itd., a statusy fazy/czasu są scalone w tekście grupy.
  Poprawiono wyłącznie harness na rzeczywiste selektory, przy zachowaniu
  profilu/UUID. Nie uznaje się tych wcześniejszych tracebacków za PASS.
- W pierwszej próbie uruchomienia po konfiguracji obserwowano timer w pauzie
  na 20 s. Po jawnym „Wznów” faktyczna praca i pauza działały. Ta obserwacja
  pozostaje w `timer/failure-1792220508804340967.*`; nie przypisano bez dowodu
  przyczyny ani nie uznano za pełną akceptację startu/lifecycle timera.
  Recovery utrwalonej pracy potwierdzono odrębnie opisanym porównaniem.
- W całym nowym materiale: **0 pageerror i 0 renderer/page crash**. Są warningi
  SW/WebGL, błędy blokowanych fontów i jawne 501 dla niezaimplementowanych
  endpointów fixture. To nie jest deklaracja „czystej konsoli”.

### API stub — co zostało i czego nie udowodniono

Auth/session, CSRF i sync są jawnie lokalnym fake backendem Playwright.
Profile seedowano przez prawdziwy pull/parsing/SQLite. Plan i wszystkie
workoutSession/workoutSet pochodzą wyłącznie z działań klienta; fixture nie
generuje serii/wykonań ani draftów. ACK idempotentny po operationId, version
inkrementowane, cursor monotoniczny, echo na pull. Endpointy niezwiązane
z celem `/api/mentor/settings` i `/api/push/status` zwracają rejestrowane 501;
nie uruchamiano mentora ani płatnego providera.

Requesty całych przypadków, wraz z ponownymi otwarciami:

| Path | guided | timer |
|---|---:|---:|
| GET auth/session | 16 | 18 |
| GET sync/pull | 12 | 13 |
| POST sync/push | 3 | 2 |
| GET push/status (fixture 501) | 4 | 5 |
| GET mentor/settings (fixture 501) | 9 | 13 |

Nie zaobserwowano żądań do `fit.birek.online` ani realnego API. Nie wykonano
backend testów ani nie claimuje się serwerowego CAS. Podane przez main
**677 Flutter / analyzer 0** oraz oddzielne **373 backend** pozostają wynikami
innych przebiegów, nie liczbami testów tej akceptacji browser.
Service workery blokowano, aby całe API przechodziło przez routing harnessu;
dedykowany Drift worker i SQLite WASM były rzeczywiste. Nie jest to test
instalacji PWA, cache SW ani fizycznego telefonu.

### Dokładne ścieżki dowodów

Wspólny katalog **`/tmp/opencode/guided-acceptance-fixed-20261017T061511Z/`**:

- `guided/01-spine-19-painted.png`.
- `guided/03-guided-target3-no-log.png`.
- **`guided/04-left7-durable-painted.png`** + `.aria.txt`.
- **`guided/04-before-reload-durable-db.json`** i `.sqlite`.
- `guided/04b-before-controlled-reload-db.json` i `.sqlite`.
- `guided/05-reload-explicit-offer.png`, `guided/06-resume-dialog.png`.
- **`guided/07-resumed-left7-painted.png`**, `guided/07-resumed-db.json`.
- `guided/reload-proof.json` — UUID, krok, liczniki i requesty granicy reloadu.
- **`guided/10-summary-plan1x3-actual-left7-painted.png`** + `.aria.txt`.
- `guided/10-finished-db.json` i `.sqlite`.
- **`timer/02-paused-work-painted.png`**.
- **`timer/03-restored-pause-no-downtime-painted.png`**.
- `timer/timer-proof.json`, `timer/02-paused-before-reload-db.json`,
  `timer/03-restored-paused-db.json` — identyczny checkpoint i czas wall.
- `timer/04-review-no-auto-save.png`, `timer/05-round-saved-once-painted.png`,
  `timer/05-explicit-round-saved-db.json`.
- `guided/` i `timer/`: `fake-api-state.json`, `traffic-*.json`,
  `console-*.json`, `result*.json`, własny `fake-profile/`, zachowane `failure-*`.
- **`actual-verification.json`** — końcowe asercje realnych danych,
  SHA screenshotów, fonty HTTP 200, próby fallback, request counts i wyniki.
- `image-inspection-runtime.json`, `container-inspection-runtime.json`.
- Driver i skrypty `guided.py`, `continue_guided.py`, `timer.py`,
  `continue_timer.py`, `timer_recovery.py`, `timer_checkpoint.py`,
  `verify_actual.py`; wcześniejsze `blocked-status.json` zachowano.

Końcowy `verify_actual.py` zakończył się sukcesem: porównał UUID, szkic,
zero serii przed zapisem, dawną dawkę planu 1×3, dokładną serię Lewa/7,
checkpoint przed/po i jedyną serię 4 s, lokalne fonty oraz brak produkcyjnych
requestów. To kontrola dowodów, nie dodatkowy test backendu.

### Sprzątanie i zakres zmian tej kontynuacji

Własne browsery zamknięto; jednorazowe kontenery usuwały się przez `--rm`.
Własny Nginx testowy usunięto po utrwaleniu inspekcji. Wszystkie harnessy,
profile i dowody zachowano w temp. Nie dotykano produkcyjnych kontenerów,
sieci `fit_ingress`, portów, cudzych danych ani historycznego RED evidence.
Jedyna zmiana repo w tej kontynuacji to aktualizacja tego raportu. Bez zmian
aplikacji/assetów/DB, generatorów, zależności, wersji, commit/push/deploy/prune.
