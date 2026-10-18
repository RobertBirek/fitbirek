# Training rhythm — real-browser acceptance, 2026-10-17

## Wynik

| Funkcja | Wynik w wykonanym zakresie | Najważniejszy dowód |
|---|---|---|
| Powtórz trening | **PASS** | Źródło wykonane w UI: 9/7 powt. przy 5 kg; nowy UUID, zero skopiowanych serii/PR; jeden jawny zapis; reload zachowuje drugi cel i kursor. |
| Rytm tygodnia | **FAIL** | Start planu tworzy sesję, ale pozostawia pustą główną część ekranu. Odtworzone dwukrotnie. Reguła, pojedyncze przesunięcie, ręczne zaliczenie i realny pull drugiej przeglądarki przeszły. |
| Trendy | **PASS** | UI rozróżnia 1/2/3 porównywalne sesje, obciążenia, NULL/Obie i UUID wariantu; SQLite/API/PostgreSQL nie zmieniają się podczas odczytu. |

PASS dotyczy przypadków opisanych poniżej, nie wszystkich guardów modułów.
Źródła aplikacji nie były zmieniane ani naprawiane. Dodano wyłącznie ten raport
w repozytorium; harness i dowody są w `/tmp/opencode`.

## Środowisko i identyfikacja

Dowody i skrypty: `/tmp/opencode/rhythm-accept-20261017-f7c921/`.
Prefiks własnych zasobów: `fit-rhythm-20261017-f7c921`.

- Przeczytano `AGENTS.md`, `DEPLOY.md`, trzy przewodniki modułów oraz
  `docs/superpowers/specs/2026-10-17-training-rhythm-design.md`.
- Web: gotowy `fit-web:rhythm-local`, index
  `sha256:58ddbc31670a57f6b656ef694703509f03ed157837e3760c04c172ffc6cd3ab1`.
  Config `sha256:c0048ad513647a392ae1e239a810b72e3353160d3028e1f83fb8a81b9c605c15`
  niezależnie sprawdzony w strumieniu `docker image save`.
- API zbudowano z aktualnego `backend/`, osobny kandydat
  `fit-rhythm-20261017-f7c921-runtime:candidate`:
  `sha256:b6eac82f54561df0de716b57f58ae61bd029189757f15ce2d37193bbc884f4ab`.
- Migrator: `fit-rhythm-20261017-f7c921-migration:candidate`,
  `sha256:902ad03060876f460bb5af38e302d9595565b98838052ac4583a94702225afca`.
- Wszystkie **40 plików Python `app/`** uruchomionego API zgodne SHA256 ze
  snapshotem aktualnych źródeł. `backend/app/sync/service.py`:
  `d0ca8a0bc581ec6db43843dcf8cea8fa1ce5ece71371f37b384bee87c46625ff`.
  Manifest źródeł `backend-source.json` SHA256:
  `b4887d229b109def1ba70d0ca795f8319d19760baa6a21db05c43a1bcd88d2c3`.
- PostgreSQL 16: świeża własna baza i wolumen, Alembic **0010**.
  Lokalny Drift w obu przeglądarkach: **schema 13**.
- Chromium **140.0.7339.16**, rzeczywiste procesy przeglądarek z dwoma niezależnymi
  profilami. Obraz harnessu `fit-guided-browser-test:20261017`:
  `sha256:a5720739025054d5c70b137d25ea1e4989334b3f44e0f40a4bfaa67879621c8f`.
- HTTPS `https://localhost`, SAN localhost, nowy tymczasowy certyfikat.
  Chromium ufa wyłącznie wskazanemu SPKI; `isSecureContext=true`.
  Sieć Docker `internal=true`, bez host ports; przeglądarka używa
  `--network container:<własny-web>`. Brak dostępu do produkcyjnych zasobów.
- Nowe konto przez oficjalne `app.cli.create_initial_account`, hasło podane
  przez stdin, output CLI przechwycony i niewypisany. Sekrety mają **0600**,
  katalog dowodów **0700**. Nie zapisywano nagłówków Cookie/Authorization/CSRF.
- Dwa logowania UI otrzymały rzeczywiste **HTTP 204**, session **200**;
  realne sync push/pull **200**, bez stubów, podmienionych ACK ani auth.
  `traffic.json` obejmuje również 401 przed loginem oraz 403 opcjonalnych
  mentor/Apple Health; nie są to niepowodzenia sync.

Podane na wejściu wcześniejsze wyniki **770 Flutter / analyze 0 / build PASS**
(log `tool_14a550446001U8T9imwrDwcIbt`) oraz **378 backend PASS** nie były ponawiane
w tej sesji. Niniejszy raport dowodzi runtime/browser acceptance aktualnego API
i wskazanego gotowego web image, nie nowego przebiegu tych zestawów.

## A. Powtórzenie — PASS

1. W UI zakończono pustą sesję, następnie wygenerowano i zapisano `Plan Mix`.
2. Sesja z historycznym snapshotem planu została uruchomiona z harmonogramu.
   Po udokumentowaniu błędu nawigacji wrócono na główny ekran i użyto
   **Wróć do aktywnej sesji**. Wykonanie źródła odbyło się w UI.
3. Dla `cw090` zapisano dwie różne serie: **5 kg × 9** i **5 kg × 7**,
   strona `both`, wariant NULL, RPE 7. Zakończono sesję.
4. Podgląd potwierdzonego wykonania pokazał dokładnie te dwa cele, nazwę,
   stronę, bazowy wariant i historyczne RPE jako odniesienie.
   Osobno sprawdzony podgląd oryginalnego planu pokazał jego 30 celów,
   m.in. 3×12 dla `cw090`, zamiast reinterpretacji jako 9/7.
   Podgląd oryginalny pokazuje identyfikatory ćwiczeń jako etykiety.
5. Potwierdzenie wykonania utworzyło UUID
   `921a0405-c224-4a70-89e6-ecd3abd09990`, różny od źródłowego
   `6c530301-cd09-405b-872a-13a7c4d08790`, czas 0, brak notatki,
   brak odziedziczonego guidance/zdarzeń i zero własnych logów.
   Liczba PR pozostała 1 — rekord wcześniej rzeczywiście zdobyty w źródle.
6. Reload pokazał pierwszy cel 9/5. Po jednym **Zapisz tę serię** powstał jeden
   nowy UUID logu, RPE NULL. Reload pokazał cel drugi **7/5**;
   `repeatCompleted` zawierał wyłącznie UUID nowego zapisu.
   Powtórzenie zakończono z dokładnie jedną rzeczywistą serią.
7. Źródło pozostało niezmienione. Późniejsze porównanie obu podglądów, przy
   aktywnej sesji z reprodukcji, nie zmieniło żadnego wiersza snapshotu SQLite;
   przycisk startu był prawidłowo zablokowany przez aktywną sesję.

Dowody: `30-source-summary`, `33-repeat-actual`, `35-repeat-db`,
`36-repeat-reload.png`, `37-one-new-set.json`, `38-cursor-db.json`,
`60-repeat-one-set-finished`, `65-original-plan-preview`,
`66-actual-preview-compare`, `66-preview-readonly.json`.

Uwaga harnessu: Flutter pokazuje prefille na canvasie, ale DOM input potrafi
zwracać pusty string przed focus. Po kliknięciu pola wartości 9/5 i później 7
sprawdzono ponownie. Nie uznano pustego DOM input za błąd aplikacji.

## B. Harmonogram — FAIL, jeden odtworzony blocker UI

Przypadki **PASS**:

- Zapisany w UI plan ma UUID `7ac5cd5e-3dd9-434a-a4c2-7a574c4eab1c`.
  Reguła poniedziałkowa `033ac133-0d05-4e7f-8450-bed9d38ff19e`, od 2026-10-12.
- Przesunięto wyłącznie wystąpienie 2026-10-12 → **2026-10-13**.
  Wyjątek `bdcbb367-13c1-5444-ba23-bcf4b951b0de` odpowiada UUIDv5 reguły +
  pierwotnej daty. Następny tydzień nadal ma poniedziałek **2026-10-19**;
  po powrocie do bieżącego tygodnia przesunięcie pozostaje we wtorek.
- Zakończona pusta sesja została odrzucona: „Brak zakończonej sesji z zapisaną
  serią”. Start sesji oraz finish źródła nie zaliczyły terminu automatycznie.
- Ręcznie wybrano zakończone źródło z dwiema seriami i potwierdzono zaliczenie.
  UI pokazało „Zaliczone — powiązana sesja”. Nie dopisano sesji, serii ani PR.
- Drugi rzeczywisty profil przeglądarki zalogował się i pobrał z API identyczne
  UUID planu/reguły/wyjątku oraz stan completed i UUID sesji.

### Blocker: pusta treść po „Rozpocznij plan”

Reprodukcja wyłącznie przez UI:

1. **Ustawienia → Generator planu treningowego → Rytm tygodnia**.
2. Otwórz tydzień z niezaliczonym terminem.
3. **Rozpocznij plan → Potwierdź**.
4. Nowa aktywna sesja oraz szkic powstają i synchronizują się, ale główna
   część ekranu jest pusta; widoczny pozostaje dolny pasek nawigacji.

Pierwszy przebieg pozostał pod `/#/settings/planner`; po 3 s nadal pusto.
Drugi, odtworzony po zakończeniu powtórzenia i wejściu ścieżką UI, pozostał
pod `/#/settings`. Screenshot i ARIA ponownie wykazały brak ekranu sesji.
Sesja nie została automatycznie zaliczona i nie powstał automatyczny log/PR.
Wrócono na główny ekran Trening i zatrzymano przypadek. Bez poprawki źródeł.

Dowody: `20-empty-disqualified`, `22-moved`, `23-next-week`,
`25-active-db.json`, **`26-active.png`**, `26-blank-diagnostics.json`,
`39-schedule-still-planned`, `42-manually-completed`, `42-complete-acked.json`,
`44-second-pull.json`, `44-second-schedule`, `61-repro-before`,
**`62-repro-start-blank.png`**, `62-repro-db.json`, `63-return-main-stop`.

## C. Trendy — PASS

- Widoczne wejście **Postępy → Trendy treningowe**.
- Przy jednej zakończonej sesji z dwiema seriami: **za mało danych**.
  Dwie serie nie stały się dwiema sesjami. Aktywne powtórzenie nie weszło do próbek.
- Dodano przez **rzeczywisty `/api/sync/push`** dwie kontrolowane sesje,
  po dwie serie, obie 5 kg / both / wariant NULL: 10+8 oraz 11+9.
  UI najpierw pokazało **tylko porównanie 2 sesji**, 16→18, +2;
  po kolejnym pull **trend ≥3 sesji**, 16→18→20, +4.
- RPE nadal ma oddzielne kontrakty o zbyt małej liczbie próbek, ponieważ
  zmieniła się zapisana praca. Nie utożsamiono tego z trendem powtórzeń.
- Kolejne jawne fixture'y przez real API: 99+99 przy **6 kg**, 88+88 przy
  stronie **NULL**, 77+77 przy wariancie UUID
  `30964b4b-49fe-4025-8f66-4a9de1c18ef3` i etykiecie snapshotu.
  6 kg utworzyło osobny kontrakt, nie zmieniło +4 dla 5 kg.
  NULL pokazało wyłącznie 176; wybrany wariant wyłącznie 154, bez mieszania bazowego.
- Brak udawania, że fixture'y zostały wykonane w UI: `seed.py`, requesty
  `48/50/52-*-request.json` i odpowiedzi realnego API dokumentują ich pochodzenie.
  Daty 18–22 października są syntetycznymi datami testowych payloadów, bez
  zmiany zegara przeglądarki lub serwera. Źródło 9/7 było wykonane w UI.
- Snapshoty całego zestawu tabel SQLite i całego API pull przed/po odczycie
  są identyczne w dwóch oknach. PostgreSQL snapshot w transakcji **read-only**
  przed/po drugim oknie także identyczny, wraz z liczbą operacji i zmian.

Dowody: `45-progress-entry`, `46-trend-one`, **`49-current.png`**,
`49-two-status.json`, `50-trend-three`, `52-multiple-scopes`,
`54-load-separate`, `57-variant-force-click`, `47-read-only-proof.json`,
`58-pg-before-read.json`, `59-pg-after-read.json`, `59-read-only-proof.json`.

Ograniczenia harnessu: część snapshotów pobranych bezpośrednio podczas przebudowy
Fluttera zawiera tylko nagłówek/pasek; nie używano ich jako pozytywnego dowodu.
Zachowano także timeouty i nieudane asercje harnessu w `commands.jsonl`.
Wybór wariantu wymagał `click(force=True)` na rzeczywistym menuitem, ponieważ
Playwright tracił element przy oczekiwaniu na stabilność. Było to kliknięcie UI,
bez ustawiania stanu aplikacji lub DB. Pełna ocena dostępności pozostaje UNTESTED.

## Integralność, sprzątanie i zakres niewykonany

Końcowy API pull zredukowano do najnowszej wersji każdego UUID i porównano
z `sync_records` PostgreSQL: identyczne payloady, wersje, UUID i liczności.
Stan końcowy: **1 profil, 1 plan, 9 sesji, 13 logów, 1 PR**.
Pięć sesji i dziesięć logów to opisane fixture'y real API; pozostałe są z UI.
Outbox i deferred pierwszej przeglądarki puste. `verification.json` zawiera
szczegółowe asercje; `verify.py` zakończył się exit 0.

`cleanup.py` zakończył się exit 0. Usunięto wyłącznie własne kontenery,
wewnętrzną sieć i wolumen PostgreSQL. `cleanup-result.json`: zero pozostałych
zasobów z własnym prefiksem. Artefakty, profile przeglądarek i candidate images
pozostawiono. Nie zmieniano produkcji, wersji, zależności; bez commit/push/deploy.

**UNTESTED w tej akceptacji:** pełna macierz guardów/missing variants/CAS,
potwierdzony start powtórzenia oryginalnego planu (sprawdzono jego preview),
browserowe protokoły czasowe/mieszane, pozostałe ćwiczenia w selectorze trendów,
pełne 1/2/3 próbek RPE przy identycznej pracy, urządzenie fizyczne i pełna
akceptacja SW/PWA/offline. Wcześniejszy **PWA FULL offline FAIL** pozostaje
obowiązującym znanym wynikiem; ten raport go nie zastępuje ani nie maskuje.

---

## RETEST po poprawce nawigacji — 2026-10-17, najnowszy wynik

**GREEN / PASS dla krytycznej ścieżki startu z harmonogramu.**
Historyczny RED powyżej pozostaje bez zmian. Nowy runtime nie odtwarza pustej
treści po potwierdzeniu startu: pokazuje prawdziwy ekran sesji i ćwiczenie.
Przepływ anulowanie → start → reload → **jawne wznowienie** → seria → finish →
ręczne zaliczenie → pull drugiej przeglądarki przeszedł. Osobna obserwacja
bezpośredniego reloadu URL, opisana niżej, pozostaje nierozwiązana.

### Nowe środowisko, bez ponownego używania danych/profile'u

- Nowy katalog dowodów: `/tmp/opencode/rhythm-retest-20261017-a6d482/`.
  Nowy prefiks zasobów: `fit-rhythm-retest-20261017-a6d482`.
- Nowy PostgreSQL, wolumen, konto utworzone oficjalnym CLI, certyfikat localhost
  i dwa świeże profile przeglądarek. HTTPS secure context; sieć internal,
  przeglądarka `--network container:<własny-web>`, bez host ports.
- Web **`fit-web:rhythm-local-fixed`**, index:
  `sha256:d93e53313b83fb16316fe55498c65a76ef75c418ae22760179704c657ef2741e`.
  Config potwierdzony w `docker image save`:
  `sha256:2900840cfeb6a4adff4e67139b7e406232d2a8751be896cf6fa05e2a13c14ac3`.
- Ponownie użyty wyłącznie niezmienny obraz API, nie stary kontener/baza:
  `sha256:b6eac82f54561df0de716b57f58ae61bd029189757f15ce2d37193bbc884f4ab`.
  Przed provision oraz w działającym API zweryfikowano zgodność wszystkich
  **40 plików Python** z aktualnym backendem. Hash `service.py` nadal
  `d0ca8a0bc581ec6db43843dcf8cea8fa1ce5ece71371f37b384bee87c46625ff`;
  hash manifestu backendu nadal `b4887d229b109def1ba70d0ca795f8319d19760baa6a21db05c43a1bcd88d2c3`.
- Alembic **0010**, Drift **13** w obu przeglądarkach.
  Dwa rzeczywiste logowania UI **204**, session/push/pull **200**.
  Brak seedów, podmian API, ACK, auth lub zmian DB; wszystkie dane domenowe
  tego retestu powstały przez UI. Sekrety 0600, bez wypisywania wartości.
- Podane przez koordynatora **771 Flutter PASS**, analyze oraz runtime build
  (log `tool_14a8f6e19001IMqk4rOm2tFhh5`) nie były ponawiane w retestcie.

### Dowód UI i danych

| Przypadek | Wynik | Dowód |
|---|---|---|
| Ustawienia → Generator → Rytm tygodnia | PASS | Plan wygenerowany i zapisany w UI, reguła przypisana w UI. `02-rule-ready`. |
| Start → Anuluj | PASS | Cały snapshot SQLite i API przed/po identyczny; brak sesji, szkicu, serii i PR. `03/04-*-cancel-*`. |
| Start → Potwierdź | **PASS** | URL **`https://localhost/#/workout/session`**, nagłówek **Aktywny trening**, ilustracja i **Rotacja zewnętrzna ramienia z hantlem w leżeniu bokiem**, pola ciężaru/powtórzeń, przycisk `Seria wykonana (0)`. **`05-active-real-exercise.png`**, `05-route-proof.json`. |
| Stan po starcie | PASS | Dokładnie 1 UUID sesji, 1 powiązany szkic, czas 0, **0 serii / 0 PR**. Reguła nadal bez completed override. `05-confirmed-db.json`, `05-real-api.json`. |
| Reload i jawne wznowienie | PASS | Po reloadzie **Trening → Kontynuuj → Wznów** przywraca plan i formularz. Ten sam UUID, 0 nowych serii/PR. `10-explicit-resume`, **`11-resumed-real-exercise.png`**, `11-resume-proof.json`. |
| Brak autozaliczenia na start/finish | PASS | UI „Do wykonania” po starcie i po zakończeniu; w profilu nadal sama reguła. `07-start-not-auto-completed`, `14-finish-not-completed`. |
| Jawna seria i finish | PASS | UI zapisuje **5 kg × 9, both, bazowy, RPE 7**. Nadal jedna sesja. Podsumowanie wykazuje jedną serię przy celu 3×12, bez fikcyjnej reszty. `12-explicit-set`, `13-summary`. |
| Ręczne zaliczenie | PASS | UI wybiera faktyczną sesję i potwierdza. Status „Zaliczone — powiązana sesja”; bez dopisywania wykonania lub PR. `14-session-choice`, `15-manual-dialog`, **`15-completed-ui.png`**. |
| Druga przeglądarka, realny pull | PASS | Niezależny login, wejście z Ustawień do harmonogramu. Identyczna kolekcja weeklySchedule i UUID powiązanej sesji. **`16-second-completed-ui.png`**, `16-second-pulled-db.json`, `16-second-api.json`. |

UUID sesji: **`53b0dc4b-2acf-4614-8d66-3a0a18d32fbe`**.
UUID reguły: `81ec90e8-a521-468c-b5c4-216d4146cf36`.
UUIDv5 ręcznie zaliczonego wystąpienia: `d93d52b6-6e1f-59fc-902b-0b87f85823c0`.

### Osobna nierozwiązana obserwacja: reload bezpośredniego URL

**FAIL / ograniczenie UX dla automatycznego odtworzenia ekranu po reloadzie
`/#/workout/session`.** Po bezpośrednim reloadzie pozostał nagłówek aktywnej
sesji, ale zamiast planu pokazało się „Wybierz ćwiczenia, aby zacząć logować serie”.
Odtworzone ponownym reloadem, bez utraty UUID, snapshotu guidance lub szkicu.
Oczekiwanie na pole powtórzeń zakończyło się timeoutem. Dowody:
`06-reload-active.png`, `08-resume-missing-exercise.png`,
`08-repro-reload-missing.png`, `08-reload-failure.json`.

Po powrocie do głównego ekranu był widoczny **Niedokończony trening → Kontynuuj**.
**Kontynuuj → Wznów** pokazało rzeczywisty plan pod tym samym UUID, po czym
wykonano resztę testu bez ręcznego dodawania ćwiczeń i bez modyfikowania danych.
Nie jest to utrata zapisanej sesji ani odtworzenie poprzedniego błędu startu.
Nie traktować poprawki nawigacji jako naprawy automatycznego reloadu URL.
Artefakt `09-reload-case-result.json` zawiera wstępny FAIL przed jawnym
wznowieniem; końcowe rozróżnienie jest w `11-resume-proof.json` i `verification.json`.

### Smoke repeat/trends i końcowa weryfikacja

- Na fixed runtime wykonano **smoke obu podglądów powtórzenia** bez startu:
  oryginalny plan i faktyczna jedna seria 9×5, historyczne RPE 7.
  `18-repeat-original-smoke`, `18-repeat-actual-smoke`.
- **Smoke trendu jednej sesji**: widoczne wejście z Postępów, za mało danych,
  jedna próbka 9 przy 5 kg i osobne RPE 7. `19-trend-one-smoke`.
- Nie ponawiano pełnych wcześniejszych przypadków repeat ani trendów 2/3 i
  separacji scope'ów. Ich PASS wyżej pozostaje historycznym wynikiem poprzedniego
  obrazu; dla fixed wykonano tylko opisany smoke.
- Przed/po smoke: identyczne całe snapshoty SQLite, API i read-only PostgreSQL,
  w tym liczba operacji i zmian. `17-pg-before-smoke.json`,
  `20-pg-after-smoke.json`, `19-smoke-readonly-proof.json`.
- Najnowsze wersje wszystkich UUID z API porównano z PostgreSQL: zgodne payloady,
  wersje i liczności. Stan końcowy: **1 profil, 1 plan, 1 sesja, 1 seria, 1 PR**.
  PR powstał przy rzeczywistym zapisie serii, nie przy starcie lub zaliczeniu.
  Outbox/deferred puste w obu przeglądarkach. `verify.py`: exit 0;
  szczegółowe asercje i jawny status ograniczenia reloadu w `verification.json`.
- `cleanup.py`: exit 0, zero własnych kontenerów/sieci/wolumenów. Pozostawiono
  nowe dowody, profile i obrazy. Historycznego katalogu nie nadpisywano.
  Bez zmian źródeł aplikacji, zależności, wersji, deploy/commit/push.
- Pełne SW/PWA i urządzenie fizyczne nadal **UNTESTED w retestcie**;
  poprzedni **PWA FULL offline FAIL** pozostaje bez zmian.
