# Task 2 — Chromium: akceptacja ZABLOKOWANA

## Wynik

**FAIL / nie akceptować jeszcze kandydata.** Rzeczywisty Chromium dwukrotnie
zgubił podstronę powiadomień po pełnym przeładowaniu: z
`/#/settings/notifications` przeszedł do `/#/today` (Mentor treningowy).
Zgodnie z poleceniem zatrzymano dalsze scenariusze po potwierdzeniu błędu.
Nie poprawiano produktu ani testów. Poniższe wyniki częściowe nie oznaczają
pełnej akceptacji wszystkich podstron.

## Bloker P1 — deep link / reload

Warunki: Chromium **149.0.7827.55**, świeży izolowany profil, zalogowane nowe
konto testowe po standardowym onboardingu; viewport 320×812, motyw ciemny.

1. W działającej aplikacji otworzyć `/#/settings/notifications`.
2. Poczekać na ekran „Powiadomienia”, status PWA i stan harmonogramu.
3. Wykonać pełne przeładowanie strony (`page.reload`, odpowiednik Ctrl+R).
4. Po zakończeniu bootstrapu adres to `/#/today`, a ekran to Mentor treningowy.

Oczekiwane: nadal `/#/settings/notifications`, ekran Powiadomienia i możliwość
cofnięcia do Ustawień. Nie jest to problem braku konfiguracji push: przed reload
ekran i prawdziwy status serwera są poprawnie dostępne.

Dowody, wszystkie pod katalogiem
`/tmp/opencode/settings-ui-20261020T064625Z/evidence-browser/`:

- **`deep-notifications-before-reload.png`** — właściwy ekran przed reload;
- **`deep-notifications-after-reload.png`** — niewłaściwy ekran po reload;
- **`deep-reproduction.json`** — dokładne URL i drzewo dostępności przed/po;
- `checks.json`: `notifications-320-dark-deep-reload = FAIL`;
- `actions.log`, `events.json`, `proof.json` — rzeczywiste akcje i odpowiedzi.

Powtórzenie wykonano osobno po pierwszym niepowodzeniu, z dodatkowym oczekiwaniem
5 s po reload. Efekt identyczny. Nie proponowano ani nie wdrażano obejścia.
Nie ustalano w tym zadaniu, czy przyczyna jest starsza od refaktoru.

## Build i identyczność artefaktu

Źródło `/opt/fit`, gałąź `feat/settings-ui`, baza `a0ca0f8`, istniejący dirty tree.
Wczytano AGENTS.md, DEPLOY.md, specyfikację, raport Task 1 i working set sync.
Skrypty poprzedniego wydania dostosowano wyłącznie pod `/tmp/opencode`.

- Jedyny nowy obraz: **`fit-web:settings-ui-20261020T064625Z`**, końcowy target
  **runtime**, zależny od verification. Nie jest to opublikowane wydanie.
- ID web: `sha256:48dbab574a12022accf6bb62fcf01854e0d7f82cdeecd9af9cfeb8672593c808`.
- `build-web.log`: analyze **No issues found**, 87,6 s; **1248 Flutter PASS**,
  0 pominiętych, testy zakończone przy 05:58; finalny build web i Docker exit 0.
- Wersja pozostaje **1.18.0+32** w UI i `version.json`; bez bumpu/generatora
  w źródłach, zmian pubspec/lock, changelogu ani DEPLOY.md.
- Sprawdzono **443/443** pliki offline package, **47 095 454 bajty**, packageId
  `b96a9132afc891df23626639cbe689c7399c31f4158e9db9b6ae07f262e05594`.
- SHA-256 `main.dart.js` z obrazu i rzeczywistych odpowiedzi Chromium:
  **`49b49c67e8f825ef41b8e1ed0dc85c9306774a68afe90722082abb62d0ad96c6`**.
  Wszystkie zaobserwowane odpowiedzi z tym plikiem miały identyczny hash.
- Manifest **1338** plików źródła przed/po buildzie i po Chromium identyczny.
  `source-final-delta.json = {}` przed dodaniem niniejszego raportu.

Dowody w `/tmp/opencode/settings-ui-20261020T064625Z/`:
`build-complete.json`, `build-web-result.json`, `build-web.log`,
`source-before.json`, `source-after.json`, `source-final.json`,
`preserved-files.json`, `handoff.json`, `evidence-browser/proof.json`.

## Izolacja i dane

- Nowa, sprawdzona pod kątem kolizji sieć **internal**
  `fit-settings-ui-20261020T064625Z-net`, `172.30.235.0/24`.
- Nowy PostgreSQL i własny pusty wolumen; brak danych, dumpów, sekretów oraz
  poświadczeń produkcyjnych. Konto wyłącznie testowe, onboarding jawnie wykonany
  w izolacji przed pomiarem niezmienności danych.
- Własne kontenery API/migratora uruchomiono po niezmiennych lokalnych ID:
  API `sha256:ef3a2090568acf2d4a32eeaac61d499d8ef003f840de06eeb731bbb99341503c`,
  migrator `sha256:2220dffa959c2db667d32b69af68365fbc2b6d081454e7c738d1193fff9da57d`.
  Żadnych retagów produkcyjnych. Alembic **0010**; **42/42** pliki API z obrazu
  zgodne ze źródłem. **93** pliki backendu zgodne z manifestem wydania 1.18.
  Nie powtarzano 510 testów backendu — to wynik odziedziczony z niezmienionego
  wydania, nie nowy wynik tego zadania.
- **0** opublikowanych portów usług; testowy TLS proxy tylko w prywatnej sieci.
  Jedyny hostowy listener sterujący Chromium: `127.0.0.1:18763`, zamknięty na końcu.
  Ruch stron poza origin kandydata był blokowany.
- Push wyłączony w izolowanym API, brak sendera/kluczy dostawców AI.
  `Notification.permission` pozostało `default`. Brak mutujących żądań
  push/health/mentor, generowania tokenów, importu, eksportu i wywołań AI.
- Fingerprinty **20** tabel, z wyłączeniem sesji logowania i login_attempts,
  identyczne przed/po scenariuszach: `domain-before.json`, `domain-after.json`.
  Dotyczy również rekordów sync, tabel Apple Zdrowie, Mentor i push.

## Wykonane sprawdzenia i screenshoty

**21 końcowych asercji: 20 PASS, 1 FAIL; 42 oryginalne PNG.** Dokładna lista:
`evidence-browser/checks.json`, `evidence-browser/final-counts.json` oraz
`screenshots-manifest.json` (rozmiary/hash każdego PNG).

Nie należy mylić wczesnej asercji adresu po `context.push` z blokerem reload:
imperatywny push domyślnie pozostawia w GoRouter URL rodzica. Tę asercję harnessu
zastąpiono sprawdzeniem rzeczywiście wyrenderowanego ekranu/back; zapis pozostaje
w actions.log. Osobny test bezpośredniego URL i pełnego reload nadal zawiódł.

Główny ekran rzeczywiście wyrenderowano po resize przy **1280×1000,
768×1000, 375×812, 320×812, każdy dark/light**. Dla każdego są trzy ujęcia:
`main-{szerokość}-{dark|light}-{top|middle|footer}.png`. Pokazują wszystkie
sekcje i osobną stopkę wylogowania, bez jej uruchamiania.

Najłatwiejsze do oceny pliki (w katalogu `evidence-browser` podanym wyżej):

- `main-1280-dark-complete.png`, `main-1280-light-complete.png` — dodatkowy
  rzeczywisty viewport 1280×1200 z całym panelem, także logout;
- `main-375-dark-top.png`, `main-375-dark-middle.png`, `main-375-dark-footer.png`;
- `main-375-light-top.png`, `main-375-light-middle.png`, `main-375-light-footer.png`;
- `main-320-dark-top.png`, `main-320-dark-middle.png`, `main-320-dark-footer.png`;
- `main-320-light-top.png`, `main-320-light-middle.png`, `main-320-light-footer.png`;
- `theme-menu-320-dark.png`, `theme-menu-320-light.png` — pełne etykiety menu
  oraz widoczny wybór; motyw faktycznie przełączono kontrolką;
- `notifications-1280-dark-collapsed.png`, `notifications-1280-dark-expanded.png`;
- `notifications-375-dark-{top|bottom}.png`,
  `notifications-320-dark-{top|bottom}.png` — zawijanie długich etykiet i statusu.

Na desktopie dwie kolumny, przy 768/375/320 jedna. Zmierzone w Chromium granice
karty synchronizacji przy 1280: **x=184, width=912**, środek x=640. Z paddingiem
24 z obu stron odpowiada to wyśrodkowanemu canvasowi **960 px**. Dowód:
`main-1280-dark-top-semantics-boxes.json`; limit sprawdzają również pełne testy.
Nie zaobserwowano przepełnienia ani trwałego obcięcia treści kontrolek na tych
ujęciach. Zwykłe odcięcie przewijanej treści na krawędzi viewportu nie jest
obcięciem wysokości samego wiersza. Globalna dolna nawigacja eliduje nazwę
Ustawienia przy 320 px; nie jest to etykieta nowej kontrolki panelu.

Powiadomienia otwarto rzeczywistym linkiem, cofnięcie wróciło do Ustawień.
Instrukcje początkowo zwinięte, rozwinięto i ponownie zwinięto ręcznie.
Status zgodny z izolowanym API, akcje wysyłki niedostępne; nie proszono o zgodę.

### Krytyka wizualna

Panel zachowuje powściągliwy charakter planera: jeden cienki pomarańczowy
znacznik harmonogramu, spokojne karty, lokalny Inter, bez hero, ogromnych
pustych nagłówków/przycisków i dodatkowych ozdobników. W jasnym motywie czytelny
ciemny tekst; w ciemnym dobrze rozdzielone poziomy informacji. Dropdown i długie
etykiety PWA przy 320 px mieszczą się i zawijają. Widoczne szare podświetlenia
niektórych wierszy to stan hover po ruchu myszy. **Nie znaleziono wizualnego
blokera w obejrzanych ujęciach; nie usuwa to funkcjonalnego blokera reload.**

## Nieukończone / ograniczenia

Po znalezieniu błędu przerwano: rzeczywiste trasy backup/health i ich reload/back,
auth redirect z zachowaniem deep linku, ostrzeżenie/anulowanie importu, fokus
klawiatury Tab oraz jasny motyw podstrony powiadomień **nie mają akceptacji
przeglądarkowej w tym zadaniu**. Nie deklarować ich jako PASS.

Mobilne ujęcia są rzeczywistym Chromium ze zmienionym viewportem CSS, nie
fizycznym telefonem ani testem Safari/touch. Tekst **200%** sprawdzony w
zakończonej pełnej bramce widgetów: 320/375/768/1280 × 100/200% × dark/light,
z podstronami. Nie emulowano go niewiarygodnym zoomem CSS i nie deklaruje się
browser/native text200 ani natywnego horyzontu powiadomień jako sprawdzonych.

## Zamknięcie i produkcja

Chromium zamknięty poprawnie (proces kontrolera exit 0). Po weryfikacji labela
usunięto **dokładnie własne 5 kontenerów, 1 sieć, 1 wolumen**; pozostało
**0/0/0** własnych zasobów. Obrazy, manifesty, logi i screenshoty zachowano.
Dowód `cleanup-proof.json`.

`production-before.json` i `production-after.json` identyczne: kontenery Fit
i Caddy, ich ID, obrazy, StartedAt, restarty, zdrowie i tagi produkcyjne bez zmian.
Produkcja nadal **1.18.0+32**. Brak produkcyjnego logowania/zapisów, backupu,
restore, deploy, push, zmian proxy/sieci ingress, commit i git push.
Przed napisaniem raportu `final-integrity.json` potwierdził niezmienność źródła
i produkcji. Jedynym plikiem repozytorium dodanym przez Task 2 jest ten raport.

---

## Ponowna akceptacja po poprawce bootstrapu — końcowy PASS

**Aktualny wynik: PASS dla zleconej izolowanej akceptacji Chromium.** Powyższy
FAIL starego obrazu pozostaje historycznym, prawdziwym wynikiem; nie usunięto
ani nie zmieniono jego treści. Nowy kandydat zawiera zrecenzowaną minimalną
poprawkę `DatabaseBootstrap`: tymczasowe `MaterialApp.builder` zamiast `home`,
bez konsumowania początkowej trasy przez dodatkowy Navigator. W tej iteracji
akceptacji nie edytowano kodu produktu ani testów.

### Nowy niezmienny kandydat i bramka

Cały nowy materiał: **`/tmp/opencode/settings-ui-20261020T072616Z/`**.

- Obraz **`fit-web:settings-ui-20261020T072616Z`**, target **runtime**, ID
  `sha256:f2d024e5e21da732d0f881a4d940a383d179056b002f357465c3c4239dd726d6`.
- Pełna zależna bramka Docker verification: **1254 Flutter PASS**, bez skipped,
  **No issues found** (84,8 s); testy zakończone przy 05:51, runtime build exit 0.
  Wersja i metadane nadal **1.18.0+32**, bez publikacji/promocji obrazu.
- Rzeczywisty `main.dart.js` z Chromium zgodny z artefaktem po każdym reload:
  **`1ca25d95891384caee84610df0027c0d95af14958758df7f0f2393a96c94e099`**.
- Pakiet **443/443** pliki, **47 095 565 bajtów**, packageId
  `3b1d0a12d2760b6d3aa76163e07eb3120c5b512a7e0a6f839650789b710dfe0f`.
- Manifest **1340** plików przed/po buildzie i po Chromium identyczny przed
  dopisaniem tej sekcji. Od pierwszego kandydata różnią się wyłącznie poprawka
  bootstrapu, jej nowy test i dwa raporty: `delta-from-first-candidate.json`.
- API i migrator po tych samych niezmiennych ID co wyżej, ale we własnych nowych
  kontenerach; **42/42** pliki API zgodne ze źródłem, Alembic **0010**.
  **93** pliki backendu nadal zgodne z wydaniem 1.18; 510 testów nie powtarzano.

Dowody: `build-web.log`, `build-web-result.json`, `build-complete.json`,
`handoff.json`, `source-{before,after,final}.json`, `backend-inherited-proof.json`,
`evidence-browser/proof.json`.

### Wyniki rzeczywistego Chromium

**70 końcowych asercji PASS / 0 FAIL**, **76 oryginalnych screenshotów PNG**,
Chromium **149.0.7827.55**. Liczba obejmuje asercje scenariuszy, pomiarów,
weryfikacji runtime i jawnie oznaczone oceny wizualne, nie 70 osobnych przepływów.
Listy: `evidence-browser/checks.json`, `evidence-browser/final-counts.json`,
`screenshots-manifest.json`.

- **Notifications / backup / health:** rzeczywisty link z głównego panelu,
  prawidłowy ekran, Wstecz do Ustawień; niezależnie bezpośredni URL, pełny reload
  i Wstecz. Powtórzono przy **1280** i **320 px**. Dawny błąd notifications
  sprawdzony dodatkowym drugim pełnym reload — podstrona zostaje zachowana.
- **Auth:** rzeczywiste wylogowanie stopką, dla każdej z trzech podstron
  bezpośredni chroniony URL i pełny reload → login → logowanie kontem izolowanym
  → pierwotna podstrona → Wstecz do Ustawień. Wszystkie trzy PASS.
- **Backup:** ostrzeżenie zastępowania danych, nieodwracalność oraz wyjątek Apple
  Zdrowie zachowane. Anulowano przy 1280 dark i 320 dark/light; bez wejścia do
  pickera, importu, eksportu czy Share. Dialog przy 320 mieści tekst i akcje.
- **Powiadomienia:** desktop i 375/320 dark/light; instrukcje początkowo zwinięte,
  rozwijane i zwijane ręcznie. Prawdziwy status wyłączonego izolowanego sendera,
  poprawnie niedostępne akcje dostawy. Brak requestPermission; zgoda `default`.
- **Motyw i fokus:** wybór dark/light rzeczywiście kontrolką, pełne etykiety
  dropdown przy 320. Prawdziwy Tab daje widoczny fokus na synchronizacji oraz
  harmonogramie w dark, na stopce w light; screenshoty wymieniono poniżej.
- **Main:** wszystkie sekcje i logout po resize **1280/768/375/320 × dark/light**.
  Dwie kolumny przy 1280, jedna na pozostałych szerokościach. Zmierzona karta
  desktop: x=184, width=912, środek x=640; z paddingiem24 wyśrodkowany canvas960.
  Brak przewijania dokumentu w poziomie we wszystkich ośmiu kombinacjach.
- **Bezpieczeństwo:** brak pageerror, generowania tokenu, zgód health, eksportu,
  importu, push i AI. Fingerprinty **20 tabel** (poza auth sessions/login_attempts)
  identyczne przed/po wszystkich scenariuszach, również po ponownych logowaniach.
  Dwa początkowe POST sync dotyczą jawnego onboardingu pustego konta, przed
  pomiarem danych; potem mutujące żądania to wyłącznie login/logout.

Kontroler miał trzy jawne korekty harnessu, nie produktu; pełny ślad zachowano
w `actions.log` / `proof.json`: po jednym reload trzeba było ponownie włączyć
semantykę Flutter przed szukaniem headingu; założenie, że pięć Tab trafia w Motyw,
było błędne (Space zmienił lokalny gong, natychmiast przywrócony); dla 320 pomiar
`body.scrollWidth=328` dotyczył ukrytego overflow poddrzewa, nie szerokości
dokumentu. Prawidłowy pomiar: document scroll/client **320/320**, brak elementów
poza viewportem, próba scrollX pozostaje **0**. Powtórzono poprawny pomiar dla
wszystkich ośmiu kombinacji. Nie oznaczano tych pomyłek jako błędów aplikacji.
Pliki `keyboard-theme-*` są diagnostyczne, nie dowodzą aktywacji menu klawiaturą.

### Końcowe obrazy do oceny projektu

Wszystkie ścieżki poniżej względem
**`/tmp/opencode/settings-ui-20261020T072616Z/evidence-browser/`**:

1. **`final-main-1280-dark-complete.png`** — cały finalny główny panel i logout;
2. **`final-main-375-dark-top.png`**, **`final-main-375-dark-middle.png`**,
   **`final-main-375-dark-footer.png`** — finalny mobilny panel;
3. `main-1280-light-complete.png`; `main-{320,375,768,1280}-{dark,light}-`
   `{top,middle,footer}.png` — pełna macierz głównego panelu;
4. `notifications-{320,375}-{dark,light}-{top,bottom}.png`,
   `notifications-1280-{dark,light}-{collapsed,expanded}.png`;
5. `notifications-fixed-second-reload.png`,
   `{notifications,backup,health}-320-dark-final-deep-reload.png`;
6. `auth-{notifications,backup,health}-{protected-login,returned}.png`;
7. `backup-warning-320-dark-top.png`, `backup-warning-320-light.png`,
   `backup-warning-1280-dark.png`, `health-320-{dark,light}.png`;
8. `keyboard-tab-dark-first.png`, `keyboard-tab-dark-second.png`,
   `keyboard-tab-light-first.png`, `theme-menu-320-{dark,light}.png`.

**Ocena wizualna:** główny panel zgodny z briefem: cichy grafit/jasny scheme,
lokalny Inter, dyskretny pojedynczy znacznik harmonogramu zamiast hero i ozdób,
spójne karty i rytm. Bez ogromnych pustych nagłówków/przycisków. Długie etykiety
powiadomień i treść ostrzeżenia zawijają się przy 320; brak trwałego obcięcia
wierszy. Sprawdzono widoczny wybór i fokus, nie tylko drzewo semantyczne.
Standardowa elipsa długiego AppBar backupu i dolnej nawigacji przy320 pozostaje
odrębnym, istniejącym zachowaniem; nie jest obcięciem nowych etykiet wewnątrz
panelu. Nie znaleziono nowego wizualnego blokera.

### Zakres PASS i ograniczenia

PASS dotyczy powyższej pełnej zleconej akceptacji UI w izolowanym Chromium,
nie zezwolenia na deploy. Mobilne obrazy to rzeczywiste viewporty CSS, nie
urządzenie fizyczne, Safari ani natywny klient. Tekst200% ma pokrycie widgetów
w pełnej bramce1254, nie jest deklarowany jako sprawdzony w Chromium. Natywny
horyzont powiadomień nie był rzeczywiście uruchamiany na telefonie. Nie wywoływano
eksportu, pickera/importu, health tokenu, permission, faktycznej wysyłki push
ani dostawcy AI. Status sync pozostał rzeczywisty — w trakcie bezczynności
obserwowano też przejściowy „Offline” z pending0, później ponownie „gotowa”;
nie zastępowano ani nie mockowano tych stanów.

### Końcowe sprzątanie i niezmienność produkcji

Nowa sieć internal `fit-settings-ui-20261020T072616Z-net` (**172.30.236.0/24**),
nowy wolumen oraz pięć własnych kontenerów miały własny label i żadnych host
portów. Po zamknięciu Chromium (exit0) usunięto wyłącznie te **5 kontenerów,
1 sieć, 1 wolumen**; zostało **0/0/0**. Obrazy i dowody zachowane:
`cleanup-proof.json`. Kontroler localhost również zamknięty.

`production-before.json == production-after.json`, dodatkowo zgodne z pomiarem
pierwszej próby: Fit/Caddy ID, obrazy, StartedAt, restarty i tagi produkcyjne
niezmienione. Produkcja nadal **1.18.0+32**; bez logowania, zapisu, backup/restore,
promocji/retagu, deployu, zmiany proxy/sekretów, subagentów, commit/git push.
`final-integrity.json` potwierdza identyczne źródła przed dopisaniem tej sekcji.
Jedyna zmiana repozytorium w tej ponownej akceptacji to append tego raportu;
historyczny prefiks zachowano bajt w bajt (`historical-report-prefix.md`).
