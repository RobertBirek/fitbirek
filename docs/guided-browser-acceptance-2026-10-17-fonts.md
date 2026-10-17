# Browser acceptance: lokalny mirror fontów — 2026-10-17

## Najnowszy retest `guided-local-fonts-complete` (21 plików): ścisły warunek zero warnings — FAIL

**Poprawka odpowiedzi Noto Sans v37 ma PASS:** ta sama notatka wpisana od
pustego pola wywołała **naturalny** request; otrzymano prawdziwy WOFF2,
199616 bajtów, SHA `62a7417925f89dc84917c38d96b7b2e68092106dc3832c7a48129030322e73d8`.
Zero HTML/font parse warnings, zero font 404/retries i zero external attempts.
Oddzielny audyt kontrolny ma **21/21 PASS**. Guided/resume/log/finish i wygląd
próbki również mają PASS.

**Pozostał jeden warning** `Could not find a set of Noto fonts to display all
missing characters`. Zatem wymagane **zero missing-glyph warnings ma FAIL**,
mimo poprawnych bajtów Noto Sans i wyglądu końcowej próbki. Szczegółowe wyniki
nowego obrazu i dowody poniżej w sekcji „Retest 21 plików”. Poprzedni RED
z HTTP 200 HTML jest zachowany jako historyczny, nie aktualny stan zasobu.

### Latest status po diagnozie: functional font acceptance PASS / known engine warning 1

**Funkcjonalna akceptacja fontów: PASS w opisanej próbce** — zero remote font
attempts, **21/21 prawdziwych WOFF2** z poprawnym SHA/rozmiarem (2777300 bajtów),
zero HTML/font parse errors oraz brak widocznych brakujących glifów w realnym
browser paint. Nie oznacza to pełnego Unicode ani użycia wszystkich 21 plików
przez rasteryzator: kontrolny audyt i naturalne odpowiedzi pozostają osobne.
**Known engine warning: 1; ścisłe zero-warning: nadal FAIL**,
`strictFontPass: false` w oryginalnym `verification.json` pozostaje aktualne.

Potwierdzono przyczynę w Flutter **3.35.4**: w samej gałęzi warningu tablica
silnika zawierała dokładnie `[65039]` / **U+FE0F (VS16)**. Przechwycone wejście
było już pełną poprawną próbką `Zażółć gęślą jaźń ▾ 💪 ⚠️ 👩‍💻 💪🏽`, nie urwanym
ZWJ ani samotnym surogatem. Pełna mapa **724 fontów** (6892 komponenty, 29518
zakresów do U+10FFFF) nie ma nominalnego kandydata dla FE0F. Audyt `cmap`
21 WOFF2 i Inter potwierdza brak samodzielnego glifu selektora, ale
**Noto Color Emoji 2, cmap format 14**, obsługuje **U+26A0 U+FE0F** przez
default UVS, czyli glif bazowy. Nominalny test `getGlyphIDs`/lookup nie modeluje
tej obsługiwanej sekwencji: potwierdzony false positive diagnostyki pokrycia
silnika, nie dowód brakującego widocznego glifu w namalowanej próbce.

Dowody: **`/tmp/opencode/font-warning-research/DIAGNOSIS.md`**,
**`/tmp/opencode/font-warning-research/conclusion.json`** oraz
**`/tmp/opencode/font-warning-research/codepoint-map-cmap-audit.json`**;
log argumentu: `guided/console-1792225155490307210.json` w tym samym root,
wraz z osobnymi PNG/ARIA/traffic. Diagnoza użyła świeżego profilu i tego samego
runtime, ale **tymczasowa instrumentacja JS była wyłącznie diagnostyczna**:
logger w odpowiedzi JS routowanej tylko dla osobnego browsera, przed oryginalną
gałęzią warningu, bez zmiany warunków, danych glifów czy odpowiedzi fontów.
Oryginalny warning zachowano raz. Source app i produkcja pozostały nietknięte;
nieinstrumentowana akceptacja poniżej nie została zastąpiona tym przebiegiem.

Najnowszy runtime: `fit-web:guided-local-fonts-complete`, Docker manifest/index
**`sha256:e25b29c3ab64c48e74fbf8cf68e21aeaa6e45dc280dcddf80698e2d3dd86c007`**.
Latest acceptance artifacts:
**`/tmp/opencode/guided-acceptance-fonts-complete-20261017T081018Z/`** —
`verification.json`, `guided/natural-font-bodies.json`,
`guided/direct-font-audit.json`, `guided/09-finish-confirmation-painted.png`
i `guided/10-summary-plan1x3-actual-left7-painted.png`; szczegóły niżej.
Przekazane wyniki main: **pełna suita Flutter 682 passed, analyze 0 issues**;
przekazany review: **bez HIGH/MEDIUM**. To zapis wcześniejszej weryfikacji,
nie nowe testy/review wykonane w ramach aktualizacji dokumentacji.

Użytkownik **nie zatwierdził engine upgrade**; pozostają Flutter 3.35.4 / Dart
3.9.2. Poprawka coverage silnika wymaga osobnej jawnej decyzji. Nie wyciszano
warningu, nie usuwano VS16 ani nie wyłączano fallbacku. Zachowano historyczne
failures i ścisły FAIL; brak gwarancji full Unicode. Nie ma tu akceptacji
zainstalowanej PWA/telefonu/odcięcia lokalnego serwera ani integracji z realnym
backend API/CAS — API pozostaje lokalnym fixture.

## Historyczny werdykt `guided-local-fonts` (20 plików): częściowy PASS / font errors FAIL

**PASS:** zero zewnętrznych prób fontów; pięć lokalnych Inter i podstawowe
fallbacki; rzeczywiście namalowane polskie litery, `▾`, `💪`, `⚠️`, próbka ZWJ
`👩‍💻` i odcień `💪🏽`; 20/20 plików mirroru HTTP 200/SHA/rozmiar; guided draft,
reload/resume i jawne log/finish/summary; timer pause recovery bez downtime.

**FAIL:** podczas wpisywania próbki emoji w prawdziwą notatkę UI silnik zażądał
dodatkowego **Noto Sans v37**, którego nie ma w manifeście 20 plików. Serwer
zwrócił **HTTP 200 z `index.html` zamiast WOFF2**, a silnik zgłosił błędy fontu.
Brak HTTP 404 nie jest tu dowodem poprawnego lokalnego fontu. Nie naprawiano
aplikacji, nie rozszerzano mirroru ani nie ukrywano komunikatów.

Historyczne RED i poprzednie wyniki w dokumentach `...2026-10-17.md` oraz
`...2026-10-17-fixed.md` pozostają zachowane. Ten raport dotyczy wyłącznie
nowego `fit-web:guided-local-fonts`.

## Artefakt i środowisko

- Właściwy manifest/index potwierdzony przez `docker image inspect`:
  `sha256:a0edef5c91e730311d5c38396f0ce38a4d951ab33cb9c478aceefb7394558bdb`.
  Created **2026-10-17 07:40:12 UTC**. Podany przez main config digest
  `8a0e6098657ed7685509887d500da1aeebe44c0e8eea5df9182bd4a686a81923`
  nie jest mylony z Docker `.Id` indeksu.
- `main.dart.js`: mtime **07:40:02 UTC**, SHA
  `eb8774e5c9f7bfd1d8177a4bbd22c1706c12508633f6a03a91a308c0e1918f93`.
  Niezmieniony hash JS względem poprzedniego runtime jest zgodny z zakresem
  poprawki: zmieniono bootstrap i zasoby, nie feature code.
- Skompilowany `flutter_bootstrap.js`: mtime **07:38:14 UTC**, SHA
  `3922f0b6480ab8a1a65eb459e7427af07a626e167948ab4318ba81650afc582d`.
  Source bootstrap miał mtime **07:21:15 UTC**. Hash źródeł bootstrapu,
  manifestu mirroru, provider/plannera/theme/pubspec/lock pozostał niezmieniony
  przez akceptację; zapis w `source-baseline.json` i `verification.json`.
- Playwright Python **1.55.0**, rzeczywisty Chromium headless
  **140.0.7339.16**, CanvasKit, viewport **1200×1000**.
- Własny Nginx `guided-fonts-web-20261017-0742`, **`--network none`**, brak
  host port bindings. Jednorazowe własne browsery współdzieliły jego namespace
  przez `--network container:guided-fonts-web-20261017-0742`.
  Origin wyłącznie `http://127.0.0.1:80`, secure context.
- Nowy katalog i puste profile, bez fontów/cache ze starszych wersji:
  **`/tmp/opencode/guided-acceptance-fonts-20261017T074217Z/`**.
  Główne przypadki to osobne `guided-clean/` i `timer/`, z oddzielnymi fixture
  API i IndexedDB. Pierwszą nieudaną próbę harnessu zachowano w `guided/`.
- Odczytano `AGENTS.md`, working set offline-fonts i guided. Użyto
  `webapp-testing` i zasad diagnostyki/verification. Nie wykonano przebiegu
  680 Flutter/analyzer: to przekazany wynik main, nie wynik tego browser testu.

## Tabela wyników

| Przypadek | Wynik | Zakres dowodu |
|---|---|---|
| Zero external font attempts | **PASS** | wszystkie requesty runtime/audytu wyłącznie loopback; brak blokowanych zewnętrznych URL |
| 20 zadeklarowanych mirror WOFF2 | **PASS integralności/HTTP** | kontrolny browser fetch: 20×200, SHA i rozmiary zgodne z deployed manifest i repo; 2 577 684 bajty |
| Naturalny start Roboto i symbole | **PASS** | lokalny Roboto, Noto Sans Symbols i Symbols 2 shard 3; HTTP 200; namalowane `▾` |
| Polski Inter / tekst UI | **PASS wizualny** | screenshoty formularza, note, summary, timer; pięć Inter TTF 200 |
| Próbka emoji/ZWJ/odcienia | **PASS wyglądu próbki** | notatka wpisana klawiaturą w UI, oglądnięte PNG; nie tylko ARIA |
| Zero lokalnych HTTP 404 i retry fontów | **PASS obserwacji HTTP** | brak 404/failed requests; najwyżej jeden request danej ścieżki w danej epoce nawigacji/przebiegu |
| Zero lokalnych błędów fontów / wszystkie naturalne fonty poprawne | **FAIL** | dodatkowy Noto Sans v37 → HTTP 200 HTML → błąd parsowania i warning brakujących znaków |
| Guided ręczne 7/Lewa durable przed reloadem | **PASS** | rzeczywisty SQLite: 1 session, 1 draft, 0 sets; krok 3, reps 7, side left |
| Reload i jawne Kontynuuj/Wznów, ten sam UUID | **PASS** | brak nowej sesji/serii/operacji startu; przywrócone 7/Lewa |
| Jawna seria, finish, plan 1×3 kontra actual 7 | **PASS** | jedna seria Lewa/7; notatka; usunięcie szkicu po finish |
| Timer pauza/reload/bez dopisania pracy | **PASS** | identyczny checkpoint 9 198 400 µs, 10,120 s wall-time poza timerem; potem jawny pojedynczy zapis 9 s |
| Dowolny Unicode i wszystkie kombinacje emoji | **NIE TESTOWANO / brak gwarancji** | tylko opisana próbka i widoki |
| Warianty A/B, migracja presetów, pełny backend/CAS | **NIE TESTOWANO** | poza tym przebiegiem |
| Zainstalowana PWA, telefon, SW cache, odcięty również lokalny serwer | **NIE TESTOWANO** | test compiled browsera przy działającym lokalnym HTTP |

## Naturalne pobieranie a kontrolny audyt — osobne dowody

Driver zapisuje zdarzenia `request`, `response`, `requestfailed`, fazę
`natural` / `direct-audit` / `direct-diagnosis`, URL i epokę nawigacji.
**Audyt 20 plików następuje dopiero po screenshotach i scenariuszu UI.**
Nie rejestruje fontów przez FontFace/CanvasKit i nie dostarcza ich z harnessu.
Wykonuje tylko `fetch` z kontekstu strony, liczy SHA-256 przez Web Crypto,
porównuje rozmiary i statusy. Jego wynik nie jest dowodem użycia wszystkich
20 plików przez rasteryzator.

Naturalny runtime zażądał:

- pięciu `Inter-*.ttf` i ikon z bundla;
- `font-fallbacks/roboto/v32/...woff2`;
- `font-fallbacks/notosanssymbols/v43/...woff2`;
- `font-fallbacks/notosanssymbols2/v24/...-vrgfE71.woff2` — shard 3;
- w notatce `Noto Color Emoji` shardy **8 i 9**;
- dodatkowo brakującego **Noto Sans v37**, opisanego niżej.

Pozostałych shardów z 20-plikowego pakietu nie deklaruję jako naturalnie
użytych tylko dlatego, że kontrolny fetch zwrócił poprawne bajty. Timer bez
próbki emoji ma zero font warnings; guided z notatką ma dwa font warnings.
W obu przypadkach **0 pageerror i 0 crash**. Są osobne warningi SW/WebGL,
odmowa Wake Lock i 501 fixture niezwiązanych endpointów — nie ukrywano ich.

## Dokładny blocker lokalnego fallbacku

Podczas prawdziwego wpisywania notatki:

```text
Zażółć gęślą jaźń ▾ 💪 ⚠️ 👩‍💻 💪🏽
```

silnik zażądał ścieżki nieobecnej w manifeście:

```text
/font-fallbacks/notosans/v37/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A99Y41P6zHtY.woff2
```

Naturalny request i response 200 są w
`guided-clean/traffic-1792223224288401949.json`. Konsola tego samego przebiegu:

```text
Failed to parse fallback font Noto Sans as a font.
Could not find a set of Noto fonts to display all missing characters.
```

Oddzielny, read-only fetch w kontekście browsera potwierdził:

- status **200**, `Content-Type: text/html`, **1474 bajty**;
- treść zaczyna się od `<!DOCTYPE html>`;
- SHA **`b604cc37f1160c9ac87966c1fb1419b237f55da27a7fddd9933718df1e014718`**,
  identyczne z `/index.html` tego runtime.

Dowód: `guided-clean/missing-font-diagnosis.json`. Nginx SPA fallback maskuje
brak pliku statusem 200. Nie podmieniano odpowiedzi w harnessie i nie zmieniano
Nginx. Jest to konkretny FAIL kryterium „zero font errors”, mimo poprawnych
20/20 zadeklarowanych plików i poprawnie namalowanej końcowej próbki.

Nie rozstrzygnięto, który pojedynczy kodpunkt lub przejściowa niepełna
sekwencja podczas wpisywania wywołuje Noto Sans v37. `keyboard.type` wysyła
rzeczywiste zdarzenia tekstu kolejno, a nie bezpośrednią zmianę stanu Fluttera.
Nie wolno z tego przebiegu wyprowadzać ani gwarancji dowolnego Unicode,
ani twierdzenia, że wszystkie gotowe sekwencje ZWJ wymagają tego pliku.

## Rasteryzacja i próbka

Obejrzano PNG, nie tylko drzewo semantyki:

- `guided-clean/07-resumed-left7-painted.png`: polskie teksty, rzeczywista
  strzałka `▾` przy „Bazowy”, `7`, zaznaczona Lewa i licznik 0;
- `guided-clean/09-finish-confirmation-painted.png`: wpisana przez UI próbka
  polskich liter, symbolu, emoji bicepsa, ostrzeżenia, kobiety przy komputerze
  oraz bicepsa z odcieniem skóry;
- `guided-clean/10-summary-plan1x3-actual-left7-painted.png`: ta sama notatka
  odczytana z zapisu oraz plan 1×3 / rzeczywista Lewa/7;
- `timer/03-restored-pause-no-downtime-painted.png`: namalowane 11 s,
  Wstrzymano/Wznów i polski opis.

Próbka `👩‍💻` jest widoczna jako złożona postać przy komputerze, a `💪🏽`
ma inny odcień niż `💪`. Ostrzeżenie jest widoczne jako glif; nie deklaruję
kolorowego stylu emoji dla każdego symbolu ani kompletnej kontroli shapingu
wszystkich sekwencji, platform, wag i wersji Unicode.

## Guided i timer — dokładne dane

Guided UUID **`e81a051f-5320-48a9-9706-33704c8ae3f3`**, lokalne ID 1.
Wygenerowany aktualnym klientem plan zawiera cw367 z celem **1×3**.
Po rzeczywistej edycji pola z prefillu `3` na `7` i wyborze Lewa oczekiwano
warunkowo na trwały payload w IndexedDB. Przed i po reloadzie oraz jawnym
Wznów: **1 sesja / 1 szkic / 0 serii**, ten sam UUID i `currentSlot=3`,
`fields.reps="7"`, `fields.side="left"`. Na granicy reloadu pozostała jedna
operacja startu workoutSession; nie było POST/logowania serii. Zapis nastąpił
dopiero po „Seria wykonana”, następnie jawne finish z notatką: 1 set i 0 draft.

Timer w odrębnym profilu: cw281 Powitanie słońca A, UUID
**`0efaa18e-9094-4c11-a5d2-f6c45c6432bb`**. Konfiguracja UI: prep 0, work 20,
rest 0, rounds 1. Po rzeczywistej pracy i pauzie:
`phase=work`, `paused=true`, `elapsedMicros=9198400`, results puste.
Po reloadzie/jawnym resume/otwarciu timera cały checkpoint jest identyczny,
choć minęło **10,120279499 s** wall-time. Nadal 0 sets. „Zakończ odliczanie”
daje review 9 s, bez zapisu; dopiero „Zapisz wykonane rundy” tworzy jeden set
**9 s** i konsumuje timer. Nie doliczono downtime jako pracy.

## API, błędy harnessu i ograniczenia dowodu

Auth/session, profil pull, CSRF i sync push/ACK są **jawnie lokalnym fixture
Playwright**. Plan, szkic i serie powstały przez rzeczywisty frontend i SQLite;
nie wstrzykiwano wierszy DB ani JS state. Istniejące 501 dla mentor/settings
i push/status pozostały jawne. Brak produkcyjnej domeny, kont, API i opłat.
Service worker był blokowany dla pełnego przechwycenia API; dedykowany Drift
worker i WASM działały naprawdę. To nie jest test serwerowego CAS ani SW/PWA.

Pierwszy świeży przypadek `guided/` zatrzymał harness na globalnym
`networkidle`, jeszcze przed startem sesji. Logi zachowano. Nie było tam
font errors ani retry; nie ustalono przyczyny globalnego oczekiwania i nie
przypisano jej fontom. Po tej obserwacji w zupełnie nowym profilu
`guided-clean/` użyto gotowych locatorów i warunkowego oczekiwania na
zakończenie wszystkich rzeczywistych requestów fontów przed screenshotem.
Nie było ślepych opóźnień ani podmiany zasobów. Również nieudane asercje
verifiera zachowano w logu narzędzia; końcowy verifier jawnie zapisuje
`strictFontPass=false` dla guided, a nie udaje pełnego GREEN.

## Artefakty i sprzątanie

Root: **`/tmp/opencode/guided-acceptance-fonts-20261017T074217Z/`**.

- `verification.json`: końcowe liczniki, granica natural/direct, ostrzeżenia,
  SHA screenshotów, UUID, timer i hashe źródeł.
- `guided-clean/reload-proof.json` oraz `04-before-reload-durable-db.json`,
  `05-after-reload-db.json`, `07-resumed-db.json`, `10-finished-db.json`
  i odpowiadające kopie `.sqlite` z realnego IndexedDB.
- Screenshoty `guided-clean/04-left7-durable-painted.png`,
  `07-resumed-left7-painted.png`, `09-finish-confirmation-painted.png`,
  `10-summary-plan1x3-actual-left7-painted.png` oraz pliki `.aria.txt`/`.html`.
- `timer/timer-proof.json`, `02-paused-before-reload-db.json`,
  `03-restored-paused-db.json`, `05-explicit-round-saved-db.json` i PNG.
- `guided-clean/direct-font-audit.json`, `timer/direct-font-audit.json`:
  20 wyników SHA/status/rozmiar, **oddzielnie od naturalnego renderowania**.
- `guided-clean/missing-font-diagnosis.json`, pełne `console-*.json`,
  `traffic-*.json`, `result-*.json`, fake API payloady i profile.
- `image-inspection.json`, `container-inspection.json`, `source-baseline.json`;
  wszystkie skrypty przygotowania, drivera, audytu i kontroli.

Własne browsery zamknięto, kontenery browsera usuwały się przez `--rm`.
Własny testowy Nginx usunięto po końcowej weryfikacji. Zachowano całość temp
i historyczny RED. Nie zmieniono source app, fontów, DB klienta, zależności,
wersji, produkcji, portów, sieci `fit_ingress`; bez commit/push/deploy/prune.
Repozytorium zmieniono wyłącznie w dokumentacji wyników.

---

## Retest 21 plików — `fit-web:guided-local-fonts-complete`, 2026-10-17 około 08:10–08:12 UTC

### Dokładny artefakt i fresh context

- Docker manifest/index potwierdzony inspekcją:
  **`sha256:e25b29c3ab64c48e74fbf8cf68e21aeaa6e45dc280dcddf80698e2d3dd86c007`**.
  Created **08:09:37 UTC**. Config digest przekazany przez main:
  `52585f4a25ec84938d23afc6e0fbe43390e89f6eb3fd128d5b12e455fe0f0863`;
  `.Id` indeksu Dockera nie jest przedstawiany jako config digest.
- `main.dart.js`: mtime **08:09:30 UTC**, SHA
  `eb8774e5c9f7bfd1d8177a4bbd22c1706c12508633f6a03a91a308c0e1918f93`.
- Compiled `flutter_bootstrap.js`: mtime **08:07:51 UTC**, SHA
  `369899adc3f8ebb7b9181dfdc9e150da4593c2a5ab3812760e11ebd98229be74`.
  Manifest fontów w obrazie: mtime **08:09:34 UTC**; source manifest miał
  mtime **07:56:19 UTC**. Nowy runtime jest późniejszy od dodania 21. fontu.
- Nowy root: **`/tmp/opencode/guided-acceptance-fonts-complete-20261017T081018Z/`**,
  pusty persistent profile `guided/fake-profile`, fake konto z nowym prefiksem
  `d400…`. Bez cache/profile z poprzedniego mirroru i bez seedowania draftów.
- Prawdziwy headless Chromium **140.0.7339.16**, Playwright **1.55.0**,
  viewport 1200×1000, CanvasKit. Własny web
  `guided-fonts-complete-web-20261017-0810`: `--network none`, bez portów hosta.
  Browser współdzielił tylko jego namespace; secure loopback HTTP.
- Ponownie odczytano AGENTS i aktualny working set offline-fonts. Raportowany
  main wynik **682 Flutter/analyzer 0** nie jest wynikiem tego browser testu.

### Odtworzenie wcześniejszej sekwencji i naturalna odpowiedź Noto Sans

Przez rzeczywisty UI: kolekcja spine 19 → generator → start/potwierdzenie →
cw367 → prefill 3 → ręczne 7/Lewa → durable draft → reload → jawne Wznów →
zapis serii → dialog finish. Pole notatki najpierw sprawdzono jako **puste**,
następnie wykonano `keyboard.type` z dokładnie tą samą próbką:

```text
Zażółć gęślą jaźń ▾ 💪 ⚠️ 👩‍💻 💪🏽
```

To wpisywanie, nie wklejenie końcowej wartości ani zmiana JS/DB state.
`guided/typing-sequence.json` zapisuje `before: ""`, pełny tekst, metodę
`keyboard.type` i czas. Nie pominięto przejściowych stanów edycji.

**Naturalny Noto Sans v37 został rzeczywiście zażądany raz**, podczas tej
sekwencji, przed kontrolnym audytem. `guided/natural-font-bodies.json` zawiera
bajty/metadata odebrane w callbacku prawdziwej odpowiedzi runtime:

```text
status: 200
Content-Type: font/woff2
bytes: 199616
signatureHex: 774f4632  (wOF2)
SHA-256: 62a7417925f89dc84917c38d96b7b2e68092106dc3832c7a48129030322e73d8
```

Ścieżka jest dokładnie wcześniejszym `notosans/v37/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A99Y41P6zHtY.woff2`.
Nie było HTML, parse warning ani błędu HTTP dla tej odpowiedzi. Tak samo
sprawdzono nagłówek/SHA/rozmiar pozostałych **naturalnie** pobranych WOFF2
względem manifestu. To mocniejszy dowód niż sam kontrolny fetch.

### Wynik warunków, bez rozszerzania zakresu

| Warunek | Wynik |
|---|---|
| Naturalny Noto Sans v37 odtworzony, rzeczywisty WOFF2/SHA/199616 bytes | **PASS** |
| Zero HTML/parse warnings | **PASS** |
| Zero external font attempts | **PASS — 0** |
| Zero lokalnych font HTTP 404 / requestfailed | **PASS — 0** |
| Zero obserwowanych retry fontów w danej epoce nawigacji | **PASS — max 1 request/ścieżkę/epokę**; ponowne poprawne pobrania po reloadzie są oddzielne |
| Zero missing-glyph warnings | **FAIL — jeden komunikat** |
| Painted polskie litery, `▾ 💪 ⚠️ 👩‍💻 💪🏽` | **PASS wyglądu opisanej próbki**, screenshoty obejrzano |
| Oddzielny direct audit 21 plików | **PASS — 21×HTTP200, wOF2, SHA i rozmiar**, razem **2777300 bajtów** |
| Guided 7/Lewa durable i resume tego samego UUID bez auto-logu | **PASS** |
| Jawny zapis/finish/summary plan 1×3 kontra rzeczywiste Lewa/7 | **PASS** |
| Timer, warianty A/B, preset migration na tym obrazie | **NIE PONAWIANO**; wcześniejszych wyników nie przypisano nowemu przebiegowi |
| Dowolny Unicode / pełna PWA / telefon / backend CAS | **NIE TESTOWANO** |

Pozostały dokładny komunikat, bez towarzyszącego parse failure:

```text
Could not find a set of Noto fonts to display all missing characters.
Please add a font asset for the missing characters.
See: https://flutter.dev/docs/cookbook/design/fonts
```

Dowód: `guided/console-1792224724426412248.json`, końcowy wpis warning.
W tym nieinstrumentowanym reteście nie ustalono pojedynczego kodpunktu ani
ramki edycji; późniejsza odseparowana diagnoza potwierdziła U+FE0F (patrz
„Latest status” powyżej). Nie utożsamiono komunikatu z brakującym widocznym glifem
w gotowej notatce: końcowa próbka jest namalowana. Wymaganie użytkownika
obejmuje jednak **zero warnings**, dlatego pełny font verdict pozostaje FAIL.
Nie wyciszano konsoli ani nie zmieniano tekstu, opóźnień wpisywania lub fontów.

### Guided — aktualne potwierdzone dane

Sesja **`ebd44568-d6a9-4735-b406-8538aaf667c0`**, lokalne ID 1, slot 3/cw367.
Przed reloadem i po jawnym resume: **1 sesja / 1 draft / 0 sets**, identyczny
UUID i trwałe `reps="7"`, `side="left"`. Na granicy reloadu same GET i jedna
operacja startu workoutSession przed/po, bez nowego startu ani automatycznej
serii. Dopiero click „Seria wykonana” tworzy set Lewa/7; finish zapisuje notatkę
i usuwa draft. Summary maluje cel **1×3** oraz jedną rzeczywistą serię Lewa/7.

### Rozdzielenie audytów i artefakty

W powyższym nowym root temp:

- **`guided/natural-font-bodies.json`** — faktyczne odpowiedzi rasteryzatora,
  w tym poprawny naturalny Noto Sans v37; żaden dodatkowy fetch nie jest
  potrzebny do tego dowodu.
- **`guided/direct-font-audit.json`** — osobny read-only browser fetch 21 plików,
  wykonany dopiero po wszystkich screenshotach; nie rejestruje fontów.
- `guided/traffic-1792224724426412248.json`: fazy `natural` i `direct-audit`,
  request/response/requestfailed, URL i epoka nawigacji.
- `guided/typing-sequence.json`, `guided/reload-proof.json`, rzeczywiste
  kopie stron IndexedDB/SQLite i odczyty `*-db.json`.
- **`guided/09-finish-confirmation-painted.png`** — próbka w polu UI;
  **`guided/10-summary-plan1x3-actual-left7-painted.png`** — próbka po zapisie;
  `guided/07-resumed-left7-painted.png` — rzeczywisty przywrócony formularz.
- **`verification.json`** — jawne `strictFontPass: false`, naturalne bajty
  Noto Sans, 21/21 audit, warning, liczniki i SHA screenshotów.
- `image-inspection.json`, `container-inspection.json`, `source-baseline.json`
  oraz driver/skrypty. Porównanie source SHA potwierdza freeze.

Driver nadal próbuje `networkidle`, a po jego globalnym timeout korzysta
z locatorów gotowego UI i warunkowego oczekiwania na wszystkie odpowiedzi
fontów. Zapisano taki timeout przy reloadzie; nie przypisano go font retry,
bo font request trace nie pokazuje pętli. Nie było arbitralnego sleep.

Auth/session, profil, CSRF i sync pozostają jawnym lokalnym fixture API.
Frontend, WASM/worker, SQLite/IndexedDB i wszystkie działania UI są rzeczywiste.
Brak real API, produkcyjnego konta/domeny/provider charges. SW blokowano dla
pełnego przechwycenia API. Są osobne 501 endpointów fixture, odmowa Wake Lock
i warningi SW/WebGL; **0 pageerror i 0 crash**. Nie jest to „czysta cała konsola”.

Własne browsery zamknięto, browser kontener usunięty przez `--rm`, własny Nginx
testowy usunięto po inspekcji końcowej. Zachowano wszystkie dowody nowe i stare.
Jedyna repozytoryjna zmiana tego retestu to ten raport. Bez zmian source app,
fontów/DB, produkcji, portów, cudzych kontenerów, commit/push/deploy/prune.
