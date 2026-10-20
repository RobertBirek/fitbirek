# Frontend usability — zadanie 4: NEEDS_FIX

## Wynik

**Akceptacja zatrzymana po potwierdzeniu rzeczywistego błędu P2.**
Chromium: **30 PASS / 2 FAIL**, oba FAIL dotyczą jednego wymagania — celu
„Zapisz szablon” co najmniej 48 px. Nie poprawiano produktu ani nie uruchamiano
dalszych, niezależnych scenariuszy po reprodukcji. To nie jest pełny PASS funkcji.

Dowody: `/tmp/opencode/frontend-usability-20261020T111440Z/`.
Przeczytano AGENTS.md, DEPLOY.md, spec, plan, raporty zadań 1–3 oraz raporty
Ustawień. Zachowano całe dirty tree `feat/frontend-usability`, baza `a0ca0f8`.
Jedyna zmiana repozytorium w tym zadaniu to niniejszy raport.

## P2 — cel zapisu szablonu ma 40 px, nie 48 px

Spec wymaga minimum 48 px. Rzeczywisty Chromium 149.0.7827.55, Linux,
domyślny tekst 100%, ciemny motyw, świeży izolowany profil:

1. Zalogować fikcyjne konto, ukończyć onboarding, otworzyć
   `/#/workout/templates/new`.
2. Dodać trzy ćwiczenia i zwinąć parametry; nie trzeba zapisywać szablonu.
3. Zmierzyć przycisk w rzeczywistym drzewie dostępności i jego DOM.

| Viewport | Bounds przycisku x/y/w/h | Góra nawigacji |
|---|---|---|
| 1280×1000 | 336 / 888 / 608 / **40** | 945,5 |
| 375×812 | 16 / 700 / 343 / **40** | 757,5 |
| 320×740 | 16 / 628 / 288 / **40** | 685,5 |

**Zapis jest widoczny nad nawigacją i działa. Nie zgłaszam zasłoniętej stopki.**
Problemem jest niespełniony rozmiar celu. Nie jest to tylko różnica wizualnej
wysokości i rozszerzonego hitboxu: przy 375 px kliknięcie x=187,5/y=698
(2 px nad 40-pikselowym obszarem, wewnątrz oczekiwanego rozszerzenia do 48)
nie otwiera potwierdzenia; kliknięcie środka otwiera rzeczywisty dialog
„Zapisać nowy szablon?”. Dialog anulowano, bez zapisu szablonu.

Dowody względem katalogu `evidence-browser/`:

- `13-template-footer-mobile-inspect.png` — widoczna, lecz 40-pikselowa stopka;
- `15-template-footer-320-confirmed.png` — druga wąska reprodukcja;
- `13-template-footer-desktop-inspect.png` — reprodukcja desktop;
- `template-footer-desktop-bounds.json`, `template-footer-mobile-measure.json`,
  `footer-320-reproduction.json` — dokładne bounds;
- `template-footer-dom.json` — `role=button`, `height: 40px`;
- `footer-hit-above.json`, `footer-hit-center.json`,
  `14-template-save-center-hit.png` — rzeczywiste kliknięcia i potwierdzenie.

Miejsce do zbadania przez implementera:
`lib/features/planner/presentation/pages/template_editor_page.dart:627–639`.
Samo zadeklarowane `minimumSize: Size(48, 48)` nie zapewnia tu rzeczywistych
48 px w web runtime. Przyczyny w density/tap-target nie naprawiano ani nie
uznano za dowiedzioną wyłącznie na podstawie kodu. Potrzebny jest test
rzeczywistego rozmiaru także dla konfiguracji desktop/web, potem nowy build.

## Co faktycznie przeszło przed zatrzymaniem

`evidence-browser/checks.json` zawiera końcowe 32 asercje:

- Logowanie i onboarding przez GUI; wiek `47.5` daje komunikat
  „Wpisz dodatni wiek w pełnych latach”, bez wyjątku. Poprawny wiek 47,
  wzrost `180,5` i waga `94,5` przechodzą do konfiguracji sprzętu i profilu.
- Edycja odczytuje dokładnie 180.5 i 94.5. Zmiana **wyłącznie** celu Mix→Siła
  i ponowne otwarcie zachowują oba ułamki. Niepoprawne `bad` w wadze pozostaje
  z błędem w formularzu; po cofnięciu/ponownym otwarciu nadal 94.5.
- Plank z wpisanym 60: ten sam typ zachowuje szkic, zmiana na Max pompki
  czyści pole, pokazuje wyjaśnienie i jednostkę `powt`, nie fałszywe 60 powtórzeń.
  Poprawny wynik 24 zapisano przez GUI.
- Mentor bez konfiguracji: widoczny powód „Brak konfiguracji usługi.”,
  ustawienia i dokładnie jeden klasyczny trening offline. Brak martwego Stop
  i composera; harmonogram nadal widoczny. Nie konfigurowano dostawcy.
- Szablon trzech ćwiczeń: desktop dwupanelowy, zwijanie i ponowne otwieranie
  zachowują 4×12 / 2,5 kg / 30 s. Zmiana kolejności zachowuje te cele przy
  właściwym ćwiczeniu. Niepoprawne 0 serii, ukryte przez zwinięcie, po Save
  automatycznie otwiera sekcję z walidacją; pozostałe cele nie giną.
- Stopka widoczna nad globalną nawigacją także przy 320 px; kliknięcie środka
  daje potwierdzenie. Rozmiar 48 px **nie przeszedł**.

Zrzuty faktycznie obejmują 1280×1000, 375×812 i reprodukcję 320×740,
ciemny motyw. **35 PNG** łącznie, w tym pary viewport/full_page oraz jeden
diagnostyczny zrzut błędu kontrolera. `full_page` w aplikacji CanvasKit nie
jest obietnicą zszycia przewijalnej zawartości Fluttera.

Reprezentatywne dowody „po”, obejrzane bezpośrednio:
`02-onboarding-invalid-age-mobile.png`, `04-edit-profile-exact-mobile.png`,
`03-today-unconfigured-mobile.png`, `09-template-three-collapsed-desktop.png`,
`13-template-footer-mobile-inspect.png`. Dowody „przed” odczytano i obejrzano
w `/tmp/opencode/frontend-audit-20261020T081928Z/evidence-browser/`:
`13-template-two-exercises-{desktop,mobile}.png`,
`45-today-mentor-settled-mobile.png`, `42-trends-mobile.png`,
`09-exercise-detail-desktop.png`. Nie przedstawiam starego audytu jako nowego
przejścia nieuruchomionych scenariuszy.

Pomyłki harnessu zachowano w `actions.log`: dokładna nazwa Planka/jednostki,
oczekiwane słowo komunikatu Mentora oraz odczyt wartości niezogniskowanego
Flutter input. Poprawiono wyłącznie selektory/odczyt (focus ujawnia wartość),
ponowiono asercje; to nie błędy produktu. Końcowe dwa FAIL nie zostały wyciszone.

## Immutable build i identyczność

- Jedyny kandydat: **`fit-web:frontend-usability-20261020T111440Z`**, końcowy
  target **runtime**, z obowiązkowym etapem verification.
- ID web: `sha256:a1143ce8742e8743005c7d432003e89200a67279e2c94c2537448d75e4e588fa`.
- `build-web.log`: **1330 Flutter PASS, 0 skip**, analyze **No issues found**,
  version check PASS, finalny runtime build exit 0. Bez ponawiania backend tests.
- Wersja pozostaje **1.18.0+32** — wyłącznie kandydat, nie wydanie do publikacji.
  Nie zmieniono pubspec, generated version ani flag wersjonowania.
- Sprawdzono **443/443** pliki pakietu, **47 121 418 bajtów**, packageId
  `36181a80fb5b0ea5e01c25c68049bb2380841771d2d4e1ce3a24bdd4ef2b4ba2`.
- Rzeczywiście pobrany przez Chromium `main.dart.js` i plik obrazu mają SHA-256
  **`084e4ab9201f06beb291504a74b7cb6b3e961600c2d6dd051b45c247d482fe7e`**.

Dokładne dane: `build-complete.json`, `handoff.json`, `browser-final-counts.json`,
`screenshots-manifest.json`. Brak pageerror; zarejestrowane console errors to
oczekiwane 401 przy bootstrapie przed logowaniem, nie wyjątki formularza.

## Izolacja, integralność i sprzątanie

Świeża sprawdzona bezkolizyjna sieć **internal 172.30.239.0/24**, nowy PostgreSQL
i pusty własny wolumen, fikcyjne konto; bez dumpu, danych i sekretów produkcji.
Zero publikowanych portów Fit. Kontroler przeglądarki wyłącznie na hostowym
127.0.0.1:18766, zamknięty na końcu. HTTP spoza originu kandydata blokowane.

API i migrator uruchomiono po niezmiennych ID wydania 1.18, bez retagowania:

- API `sha256:ef3a2090568acf2d4a32eeaac61d499d8ef003f840de06eeb731bbb99341503c`;
- migrator `sha256:2220dffa959c2db667d32b69af68365fbc2b6d081454e7c738d1193fff9da57d`.

Alembic **0010**, 42/42 pliki aplikacji API zgodne ze źródłem. Drift **13**,
backend/deploy/schema/dependencies/lock/WebSQLite/version bez zmian.
`protected-paths-proof.json` potwierdza chronione ścieżki względem HEAD.

Dane tworzono tylko GUI: onboarding, edycja profilu, jeden test sprawnościowy;
szablon pozostał szkicem. Nie uruchomiono przygotowanych fixture API wykresów,
nie mockowano odpowiedzi HTTP i nie edytowano SQLite. Brak mutujących żądań
Mentor/push/health, płatnego AI, kluczy dostawcy i tokenów Zdrowia.
`Notification.permission=default`, bez prośby o pozwolenie.

`final-integrity.json`: **sourceUnchanged=true, productionUnchanged=true,
productionConfigurationUnchanged=true**, przed dodaniem tego raportu.
Porównano manifest źródeł, ID/obrazy/czasy startu produkcji i hashe jej
konfiguracji, bez ujawniania rozwiniętego Compose lub sekretów.
Nie wykonano commit/push/deploy, restartu produkcji ani zmiany proxy.

Przeglądarka zamknięta. Po sprawdzeniu własnych labeli usunięto dokładnie własne
kontenery, sieć i wolumen. Obrazy oraz dowody zachowano (`cleanup-proof.json`).

## Niewykonane po zatrzymaniu

Pozostają finalne browser checks kalkulatora, katalogu/filtrów, obrazu/gwiazdki/
wariantu, rzeczywistej sesji z wieloma seriami i podsumowania, Trendów i ich
metodologii, wykresów z ≥3 datami, error Retry/Back i ponownej regresji deep
link/back Ustawień. Nie potwierdzono finalnego zapisu i edycji istniejącego
szablonu, mobilnego pickera ani keyboard/focus pełnej macierzy.
Nie wykonano jasnego motywu ani 768 px w tym przebiegu.

STT skonfigurowanego Mentora, 200% tekst i wyścigi kont mają opisane dowody
widgetowe z zadań 1–3, nie nową akceptację przeglądarkową. CSS zoom nie był
używany jako substytut TextScaler. Fizyczny iPhone/Android, Safari, klawiatura
ekranowa i screenreader pozostają poza tym testem.

**Wymagane dalej:** poprawić potwierdzony cel 40→≥48 bez osłabiania guardów,
zbudować kolejnego unikalnego kandydata, następnie dokończyć powyższą akceptację.
Niniejszego kandydata nie zatwierdzam jako końcowego PASS.

---

## Ponowna akceptacja po poprawce Save — nowy kandydat, nadal NEEDS_FIX

Poprzedni wynik i dowody powyżej pozostają historią pierwszego obrazu.
Po lokalnej poprawce `VisualDensity.standard` wykonano **nowy**, pełny build
i świeżą izolację. **Save P2 jest naprawiony i przeszedł Chromium.**
Końcowy wynik tego podejścia: **54 PASS / 1 FAIL**, 55 asercji, **165 PNG**.
Jedyny pozostający FAIL to **inny przycisk: wybór wariantu wykonania**.
Nie zatwierdzam kandydata jako końcowego PASS i nie poprawiałem produktu.

Nowe dowody: `/tmp/opencode/frontend-usability-20261020T120901Z/`.

### Potwierdzony P2 — „Wariant: Bazowy” ma 40 zamiast ≥48 px

1. W izolowanym koncie otworzyć nowy trening, dodać z bazy Pompki klasyczne
   i przejść do aktywnej sesji.
2. Zmierzyć rzeczywisty przycisk `Wariant: Bazowy ▾`.
3. Powtórzyć przy 1280×1000, 375×812 i 320×740, Chromium Linux, tekst 100%.

We **wszystkich trzech viewportach** bounds wynoszą
**x=32, y=185, w=170,640625, h=40 px**. DOM semantycznego `role=button`
również ma `height: 40px`. Kliknięcie 2 px nad lub pod tym obszarem nie
otwiera wyboru; kliknięcie środka otwiera rzeczywisty dialog „Wariant
wykonania” z pozycją „Bazowy (osobna historia)”. Dialog anulowano.
To nie tylko mniejsze tło przy rozszerzonym 48-pikselowym hitboxie.

Miejsce: `lib/features/workout/presentation/pages/active_session_page.dart:617`
— `OutlinedButton.styleFrom(minimumSize: const Size(48, 48))`.
Tak samo jak przy wcześniejszym Save, sama deklaracja minimum nie gwarantuje
rzeczywistego celu w desktop/web density. **Nie zmieniano tego pliku.**
Warunek ≥48 dla przycisku wariantu jest jawnym wymaganiem specyfikacji i briefu.

Dowody pod nowym `evidence-browser/`:

- `43-variant-target-{desktop,mobile}.png`;
- `44-variant-target-{1280,320}-confirmed.png`;
- `variant-target-mobile375.json`, `variant-target-1280.json`,
  `variant-target-320.json` — bounds, także DOM w pierwszym pliku;
- `variant-hit-{above,below,center}.json`,
  `45-variant-center-opens-dialog.png` — rzeczywiste kliknięcia;
- `checks.json`: jedyny FAIL `variant-target-min48`.

### Save — wcześniejszy bloker rzeczywiście usunięty

| Viewport | Bounds Save x/y/w/h |
|---|---|
| 1280×1000 dark | 336 / 880 / 608 / **48** |
| 375×812 dark | 16 / 692 / 343 / **48** |
| 320×740 dark | 16 / 620 / 288 / **48** |
| 320×740 light | 16 / 620 / 288 / **48** |

W każdym pomiarze Save pozostaje w całości nad nawigacją. Rzeczywiste kliknięcia
**1 i 47 px od górnej krawędzi** otwierają potwierdzenie. Szablon zapisano,
następnie otwarto ponownie: trzy ćwiczenia, zmieniona kolejność i cele
Pompki klasyczne **4×12 / 2.5 kg / 30 s** zachowane.

Dowody: `template-save-*-48-above-nav.json`, `07-template-three-desktop.png`,
`09-template-three-mobile.png`, `11-template-three-320.png`,
`12-template-saved-list-*.png`, `12-template-saved-reopened-320.png`,
`21-template-light320.png`. Testy 200%/keyboard z sześciu regresji są nadal
dowodem widgetowym, nie browserowym.

### Pozostałe rzeczywiście wykonane scenariusze

| Obszar | Nowy wynik / dowód względem `evidence-browser/` |
|---|---|
| Profil/onboarding | Powtórzone 47.5 → błąd pola, poprawne 47 + 180,5/94,5; dokładny odczyt, goal-only Mix→Siła bez utraty ułamka, niepoprawna waga nie zapisuje się. `02-onboarding-invalid-age-*`, `04-profile-fractional-*`, `05-profile-invalid-refused.png`. |
| Typ testu | Ten sam Plank zachowuje 60, zmiana na Max pompki czyści szkic z wyjaśnieniem i jednostką powt; rzeczywisty zapis 24. `06-test-type-cleared.png`. |
| Mentor | Powód i jeden klasyczny CTA, bez Stop/martwego pola; również light 320 z rzeczywistą aktywnością harmonogramu. `03-today-unconfigured-*`, `18-today-light320-with-schedule.png`. |
| Szablon | Trzy ćwiczenia, desktop dwa panele/mobile jedna kolumna, zwijanie/reorder/reopen zachowują cele; błędne 0 serii otwiera sekcję i nie gubi 12/2,5 kg. Save i zapis jak wyżej. `07`–`12`, `21`. |
| Kalkulator | Wyniki i jednostki czytelne przy 320; desktop ograniczony, nie rozrzucony po pełnej szerokości. `14-calculator-light-{desktop,mobile}.png`, `14-calculator-light320.png`. |
| Inne formularze | Widoki planera, nowej aktywności i pomiaru D/M light; formularz pomiaru także 320. Aktywność Spacer akceptacyjny wtorek 18:30/30 min zapisana GUI. `16-planner-light-*`, `17-activity-form-light-*`, `22-measurement-form-light*`. Nie deklaruję zapisu wygenerowanego planu ani ręcznej edycji pomiaru. |
| Katalog | Wyszukiwanie pompek i filtr Bez skoków działają; ostrzeżenie o odpowiednich oznaczeniach zachowane. Jeden semantyczny pionowy scroll, nagłówek i wyniki dostępne także przy 320. `23`–`26`, `41-catalog-dark320.png`, `catalog-scrollports.json`. Nie fałszowano błędu klasyfikacji HTTP. |
| Szczegół ćwiczenia | Ilustracja desktop 360×360, mobile 343×343; nazwa i przełączenie Dodaj→Usuń z ulubionych, sama gwiazdka 48×48. `27-exercise-detail-light-*`, `28-exercise-favorite-selected.png`, `42-exercise-detail-dark-*`, `exercise-image-bounds.json`. |
| Rzeczywisty trening | Zapisane GUI **cztery serie: 2/13/14/15 powt., RPE 7**, zakończona sesja. Nie są to fixture SQLite/API. `31-active-session-*`, `32-active-four-actual-sets.png`. |
| Podsumowanie | Cztery rzeczywiste serie i rozwijane akcje wtórne. Przy 320×420 dokładnie jeden pionowy scroll, przed/po przewinięciu. D/M light i dark, dodatkowo 768 dark. `33-summary-four-sets-*`, `34-summary-short320-{before,after}-scroll.png`, `35-summary-secondary-actions.png`, `39-summary-dark*`, `summary-short-scrollports.json`. |
| Trendy | Wynik „Za mało danych” i konkretny powód braku kg przed filtrami; główne etykiety bez cw001/NULL, Strona nieokreślona. Metodologia, historyczne ID i wyłączenia dostępne po rozwinięciu klawiaturą oraz rzeczywistym zamknięciu/otwarciu wskaźnikiem. Light/dark D/M i light320. `36-trends-result-first-light*`, `37-trends-methodology-{keyboard-retry,pointer-collapse,pointer-reopen}.png`, `38-trends-dark-*`. Nie twierdzę, że jedna sesja daje porównywalny trend. |
| Ustawienia | Nowe pełne reload deep linków notifications/backup/health i Back przy 320 przeszły, bez tokenów/eksportu/importu/opt-in push. Główny panel D/M dark, dodatkowo 768; Tab daje rzeczywisty fokus „Synchronizuj teraz”. `13-settings-dark-*`, `15-settings-*-deep-reload.png`, `40-settings-*`, `keyboard-focused-element.json`. |
| Brak ćwiczenia | Rzeczywista trasa nieznanego ID: czytelny komunikat, Retry pozostawia uczciwy brak danych, Back wraca do bazy. `29-unknown-exercise-recovery-*`. Nie wymuszano awarii szablonów ani Mentora przez mock HTTP. |

### Wykresy — rzeczywiste trzy daty przez oficjalne API izolacji

Formularz pomiaru nie udostępnia zmiany daty. Zgodnie z dopuszczonym zakresem
wykonano **jeden prawdziwy uwierzytelniony POST `/api/sync/push`** z sześcioma
nowymi rekordami: measurement + fitnessTest na **1, 2 i 20 października 2026,
08:00 UTC**. To nie przechwycone odpowiedzi ani bezpośrednia edycja bazy.
Każda operacja przyjęta, zero konfliktów; odczyt i wykres przez zwykły pull
aplikacji. Wagi: 96 / 95,5 / 94,5 kg; wyniki testów: 20/22/24. Score fixture
51/52/70 jest sztuczną daną wejściową testu, nie weryfikacją algorytmu norm.
Dodatkowy wynik 24 z GUI ma rzeczywiście obliczony score i inną godzinę tego dnia.

`official-api-chart-fixtures-{request,response}.json` zachowują dokładny payload
i akceptacje. `19-progress-three-dates-light-desktop.png` pokazuje krótką przerwę
1→2 i długą 2→20, a nie równe odstępy indeksów; dostępna historia podaje wszystkie
trzy daty i godziny. `20-progress-test-chart-light-desktop.png` oraz
`20-progress-test-chart-light320.png` pokazują wykres testów i historię
z godzinami, w tym dwa odczyty tego samego dnia.
Dokładna matematyka osi 1:18 pozostaje dodatkowo sprawdzona testami widgetowymi.

### Nowy build, izolacja i integralność

- Kandydat **`fit-web:frontend-usability-20261020T120901Z`**, target **runtime**;
  ID `sha256:2e29711e30b7d1c5d86479b35f82ed0e8c6171894b1d313ebc3dd985fbeaa23c`.
- Pełny verification tego obrazu: **1336 Flutter PASS / 0 skip**, analyze
  **No issues found**, version check PASS. Nie drugi build starego kandydata.
- Wersja nadal **1.18.0+32**, tylko kandydat. Bez bumpu, commit/push/deploy.
- **443/443** pliki pakietu, **47 121 427 bajtów**, packageId
  `c6fa45a576bb93f8af3b52df3d6504178048f1e3d9abadcfd0a99c7dcd9a900a`.
- SHA-256 `main.dart.js` obrazu i **wszystkich pięciu** rzeczywistych odpowiedzi
  Chromium: `3d4abb7418c66e54690e9cab15642e492d86e4e1caaa8dbd5ffb36e25e806879`.
- Nowa bezkolizyjna sieć **internal 172.30.240.0/24**, świeży pusty PostgreSQL,
  fikcyjny właściciel; brak publikowanych portów. API/migrator po tych samych
  niezmiennych ID 1.18 opisanych wyżej, bez retagowania produkcji. Alembic0010,
  42/42 pliki API zgodne; bez zmian backendu/schema/deps/WebSQLite.
- `final-integrity.json`: źródła, produkcja i hashe konfiguracji produkcyjnej
  **bez zmian** przed dopisaniem tego aneksu. Żadnych sekretów produkcyjnych,
  danych/dumpów produkcji, zmian proxy, restartów lub wdrożenia.
- **0 pageerror**, tylko oczekiwane 401 przed logowaniem. Bez żądań dostawcy AI,
  mutujących namespace Mentor/push/health lub próśb o pozwolenia;
  `Notification.permission=default`. Prawidłowy dowód końcowy to
  `browser-privacy-proof-final.json`.
- Przeglądarka zamknięta; dokładnie własne kontenery, sieć i wolumen usunięte
  po sprawdzeniu labeli. Obrazy/dowody pozostają. `cleanup-proof.json`.

W artefaktach zachowano pomyłki harnessu, nie ukrywano ich jako błędów produktu:
case nagłówka szablonów, przecinek→kropka po prawidłowym zapisie 2.5, scroll
przywrócony na Postępach, brak scrollportu gdy cztery serie mieszczą się w dużym
viewport, pierwszy nietrafiony klik metodologii po resize. Metodologię ponowiono
klawiaturą i rzeczywistym wskaźnikiem close/reopen; finalne asercje przeszły.
Pierwsze szybkie wpisanie 12 w sesji dało 2 w rzeczywistym odczycie; raport
podaje **2**, nie zamiar harnessu. Nie deklaruję testu zachowania każdego klawisza.

Dodatkowo początkowy matcher prywatności `'/push' in URL` błędnie zaliczył
do push zwykły `/api/sync/push`. Zachowano surowy błędny wynik; po sprawdzeniu
rzeczywistych namespace `/api/push`, `/api/mentor`, `/api/health` brak takich
mutacji. Skorygowano tylko tę asercję analizy logu — **FAIL rozmiaru wariantu
pozostaje**, a końcowe liczniki to 54/1, nie wcześniejsze diagnostyczne 53/2.

### Zrzuty dla końcowego review kontrolera

Wszystkie poniższe są pod
`/tmp/opencode/frontend-usability-20261020T120901Z/evidence-browser/`:

- **`07-template-three-desktop.png`**, **`11-template-three-320.png`** — układ
  i naprawiony Save48;
- **`18-today-light320-with-schedule.png`** — fallback i harmonogram;
- **`19-progress-three-dates-light-desktop.png`** — rzeczywista oś czasu;
- **`27-exercise-detail-light-desktop.png`** — ograniczona ilustracja;
- **`39-summary-dark-mobile.png`**, **`34-summary-short320-after-scroll.png`**;
- **`38-trends-dark-mobile.png`**, **`37-trends-methodology-pointer-reopen.png`**;
- **`43-variant-target-mobile.png`** — pozostający bloker40px.

Obrazy powyżej obejrzano bezpośrednio. 165 PNG zawiera pary viewport/full_page
i jeden diagnostyczny zrzut kontrolera; nie oznacza 165 różnych ekranów ani
zszycia pełnej zawartości Fluttera. Macierz to 1280/375 i kluczowe 320 light/dark,
768 dark dla podsumowania/Ustawień oraz 320×420 dla długiego podsumowania.
Nie wszystkie strony sprawdzono w każdym motywie i każdej szerokości.

STT skonfigurowanego Mentora nadal **tylko mock/widget**, bez płatnego dostawcy.
Text200%, ekranowa klawiatura, 30-seryjny stress summary i wyścigi kont mają
opisane dowody widgetowe, nie nową akceptację przeglądarkową/urządzeniową.
Brak Safari, fizycznego iPhone/Android i screenreadera. Nie użyto CSS zoom.

**Dalsza brama:** lokalnie zapewnić wariantowi rzeczywiste ≥48 px na desktop/web,
bez zmiany guardów, potem kolejny unikalny immutable build i końcowy recheck.
Nie ma zgody na publikację obecnego kandydata jako końcowego PASS.

---

## Końcowa akceptacja po poprawce wariantu i parametrów — PASS

**Finalny kandydat: PASS — 63/63 nowe asercje Chromium, 0 FAIL.**
Oba wcześniej zgłoszone P2 są zamknięte na **nowym niezmiennym obrazie**.
Powyższe wyniki NEEDS_FIX dotyczą poprzednich obrazów i pozostają historią;
nie nadpisano ich ani nie zaliczono ich 54 PASS jako wyników nowego buildu.
To akceptacja opisanego zakresu przeglądarkowego, **nie wdrożenie** i nie
potwierdzenie działania na fizycznym telefonie/płatnym dostawcy.

Dowody końcowe: `/tmp/opencode/frontend-usability-20261020T142753Z/`.

### Nowy immutable runtime i rzeczywisty hash przeglądarki

- **`fit-web:frontend-usability-20261020T142753Z`**, target **runtime**;
  ID `sha256:6de794f19d29eb5617cb4ca050763c5296ec875dd41fa2ef946251cf4d225d20`.
- Pełna brama verification w tym buildzie: **1342 Flutter PASS, 0 skip**,
  analyze **No issues found**, version check PASS, Docker exit 0.
- Rzeczywiste `main.dart.js` ze **wszystkich pięciu** odpowiedzi Chromium
  oraz plik wyciągnięty z obrazu mają identyczny SHA-256:
  **`febb3ca5106a6d108989c8c346f9a30dfa2f88b80571fcbb789ccd766770a1d8`**.
- Pakiet **443/443** zweryfikowanych plików, **47 121 431 bajtów**, packageId
  `3d1ef6ba738acc1b88cfb86c63a861399f50e0e3427a48cff9b9ad52fa8debfb`.
- Wersja pozostaje **1.18.0+32**, zgodnie z poleceniem tylko kandydat.
  Nie jest to nowy opublikowany release; ewentualne wdrożenie wymaga osobnego
  polecenia, bumpu i procedury DEPLOY.md.

Dokładne dowody: `build-web.log`, `build-complete.json`, `handoff.json`,
`browser-final-counts.json`, `evidence-browser/events.json`.

### Wszystkie wymagane cele 48 px — pomiar i prawdziwe trafienia

Chromium149/Linux, tekst100%, rozmiary **1280×1000, 375×812 i 320×740**:

| Kontrolka | Rzeczywisty wymiar przy wszystkich trzech szerokościach | Test trafienia |
|---|---|---|
| Save szablonu | wysokość **48 px**, w całości nad nawigacją | 1 i 47 px od góry → rzeczywiste potwierdzenie; anulowanie bez mutacji |
| Parametry ćwiczenia | wysokość **48 px** | 1 px otwiera pola, 47 px zamyka je; szkic pozostaje |
| Wariant wykonania | **170,640625×48 px** | obie krawędzie otwierają rzeczywisty dialog; wybór „Bazowy (osobna historia)” działa, kolejne otwarcie można anulować |
| Gwiazdka szczegółu | **48×48 px** w obu stanach | obie krawędzie zmieniają Dodaj/Usuń z ulubionych i rzeczywisty stan |
| Strzałki kolejności, usuń i dodaj ćwiczenie w szablonie | **48×48 px** | pomiar semantycznych przycisków, nie zewnętrznego paddingu; nie wykonywano zbędnego usuwania/dodawania przy każdym resize |

Save ma szerokości 608/343/288, parametry 592,796875/319/264 px.
Dowody: `template-all-mandatory-targets.json`,
`favorite-all-targets-and-image.json`, `variant-all-targets.json`,
`checks.json` i `actions.log` pod `evidence-browser/`.
Nie pozostał FAIL40px. Pomiary 200%/keyboard z nowej regresji pozostają
dodatkowym dowodem widgetowym, nie wynikiem CSS zoom w Chromium.

### Przejście końcowego zakresu, bez powtarzania wszystkich 165 obrazów

Nowy przebieg ma **53 PNG**: 26 par viewport/full_page i jeden diagnostyczny
zrzut nietrafionego selektora. Każda asercja z końcowego `checks.json` jest PASS.
Powtórzono na tym kandydacie:

- Logowanie/onboarding: 47.5 odrzucone komunikatem pola bez wyjątku;
  47 + 180,5/94,5 zaakceptowane. Profil dokładnie 180.5/94.5; zmiana wyłącznie
  celu zachowuje ułamki; błędna waga nie zapisuje się i pozostaje w szkicu.
- Zmiana rodzaju testu czyści szkic i wyjaśnia dlaczego; ten sam typ go nie
  kasuje. Poprawny wynik 24 zapisano przez GUI.
- Mentor bez konfiguracji: widoczny prawdziwy powód, jeden klasyczny CTA,
  brak martwego Stop/composera, harmonogram pozostaje. Dark desktop/mobile
  i light320. Nie konfigurowano dostawcy.
- Trzy ćwiczenia: desktop dwa panele, mobile jedna kolumna; zwijanie,
  kolejność i ponowne otwarcie zachowują 4×12/2,5 kg/30 s. Niepoprawne 0 serii
  otwiera właściwe pola i nie gubi reszty. Zapis i ponowne otwarcie istniejącego
  szablonu zachowują kolejność oraz dokładne 2.5 kg. Kontrolki jak w tabeli.
- Szczegół ćwiczenia: ilustracja ≤360×360 przy każdej szerokości, semantyczne
  nazwy/stany gwiazdki oraz jej działające 48-pikselowe cele. Rzeczywisty wybór
  wariantu odblokowany i sprawdzony przed logowaniem serii.
- Cztery rzeczywiste serie GUI i zakończona sesja: w zapisie **2/13/14/15 powt.,
  RPE7**. Raport podaje odczyt, nie intencję szybkiego wpisania pierwszego 12
  przez harness. Podsumowanie pokazuje cztery serie, przy 320×420 ma dokładnie
  jeden pionowy scroll. Nie użyto fixture sesji/SQLite.
- Trendy: stan i powód braku porównywalności przed filtrami, przyjazne nazwy
  bez cw001/NULL w głównym UI; metodologia, historyczny identyfikator i wyłączenia
  dostępne przez rzeczywiste rozwinięcie klawiaturą. Jedna sesja bez kg nie jest
  przedstawiana jako porównywalny trend. Dark D/M i metodologia320.
- Katalog: filtr Bez skoków + wyszukiwanie, ostrzeżenie o oznaczeniach zachowane,
  jeden pionowy przepływ przy 320. Nieznany exercise ID: czytelny brak danych,
  działający Retry bez sztucznych danych i Back do bazy.
- Powiadomienia/backup/health: świeże deep-link reload i Back dla wszystkich
  trzech tras przy 320, bez opt-in, tokenów, eksportu i importu.
- Kalkulator light320: czytelne liczby/jednostki i wynik z rzeczywistego profilu.
- Wykresy: ponownie sześć rzeczywistych rekordów oficjalnym izolowanym
  `/api/sync/push`, po dwa na 1/2/20 października, wszystkie przyjęte bez konfliktu.
  Ten sam jawnie sztuczny zestaw wag/testów/score opisany w poprzednim aneksie;
  nie mock HTTP ani zapis SQLite. Nowy wykres i historia mają trzy daty;
  odstępy 1 oraz 18 dni są wizualnie różne. Score fixture nie jest testem norm.

Jedyna pomyłka selektora w tym przebiegu: zachowana fraza wyszukiwania zmieniła
liczbę facety z `Bez skoków (321)` na `(1)`. Dopasowano prawdziwy przycisk po
nazwie bez zakodowanego licznika i kontynuowano ten sam żywy kontekst.
Nie zmieniano produktu, nie uznano tego za błąd aplikacji i nie restartowano
całej akceptacji. Wcześniejsze 54 PASS/165 PNG pozostają dowodem szerszych
stanów i motywów poprzedniego obrazu, a nie dodatkową liczbą PASS nowego obrazu.

### Końcowe zrzuty dla kontrolera

Wszystkie pod `/tmp/opencode/frontend-usability-20261020T142753Z/evidence-browser/`:

- **`final-template-reopened-1280.png`** — desktop, trzy ćwiczenia, Save i parametry48;
- **`final-template-reopened-375.png`**, **`11-template-three-320.png`** — mobile;
- **`final-variant-target-320.png`**, **`final-variant-real-dialog-320.png`** — naprawiony wariant i działający wybór;
- **`03-today-unconfigured-mobile.png`**, **`final-mentor-light320.png`**;
- **`04-profile-fractional-mobile.png`**, **`final-calculator-light320.png`**;
- **`final-summary-mobile.png`**, **`final-summary-short320-scrolled.png`**;
- **`final-trends-dark-mobile.png`**, **`final-trends-methodology-320.png`**;
- **`final-progress-three-dates-light-desktop.png`** — nowy rzeczywisty wykres;
- **`final-unknown-exercise-retry.png`** — odzyskiwanie bez fikcyjnych danych.

Kluczowe obrazy profilu, Mentora, obu układów szablonu, wariantu, kalkulatora,
podsumowania, Trendów i wykresu obejrzano bezpośrednio. `full_page` nadal nie
oznacza zszywania Flutterowych scrolli. Nie wykonano ponownie macierzy768;
jej wcześniejsze dowody zachowano, bez przypisywania ich nowemu hashowi.

### Integralność, sprzątanie i granice PASS

Nowa bezkolizyjna sieć **internal 172.30.241.0/24**, świeży pusty PostgreSQL
i fikcyjne konto. API/migrator po tych samych niezmiennych ID 1.18, bez
retagowania produkcji; Alembic0010, 42/42 pliki aplikacji API zgodne ze źródłem.
**Zero publikowanych portów Fit**, żadnych sekretów/dumpów/danych produkcji.
Nie zmieniano backendu, schematu, zależności, wersji ani plików produktu.

`final-integrity.json` potwierdza **sourceUnchanged, productionUnchanged,
productionConfigurationUnchanged = true** przed dopisaniem tego aneksu.
`final-browser-privacy.json`: **0 pageerror**, brak mutujących żądań namespace
AI/Mentor/push/health, pozwolenie powiadomień nadal `default`.
Jedyny console error to oczekiwane 401 przed logowaniem. Nie wykonywano
płatnego STT/chat/TTS, generowania tokenów Zdrowia ani prośby o pozwolenie push.

Chromium zamknięty; własny listener127.0.0.1:18768 zamknięty. Dokładnie własne
kontenery, sieć i wolumen usunięto po sprawdzeniu etykiet, obrazy i dowody
zachowano. `cleanup-proof.json`; źródła po dopisaniu raportu są sprawdzane
oddzielnie, z dopuszczeniem wyłącznie appendu tego dokumentu.

**Ograniczenia pozostają jawne:** 200% tekst, klawiatura ekranowa, 30-seryjny
stress i wyścigi kont to testy widgetowe; skonfigurowane STT to mock/widget.
Nie wykonano Safari, fizycznego iPhone/Android, screenreadera, płatnego AI ani
rzeczywistego push. Nie stosowano CSS zoom jako substytutu TextScaler.
Brak commit/push/deploy. **W opisanym zakresie finalnego Chromium: PASS.**
