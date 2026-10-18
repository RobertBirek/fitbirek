# Akceptacja PWA offline — 2026-10-17

## Werdykt i zakres

**Pełna akceptacja offline: FAIL.** Lokalna trwałość treningu i synchronizacja
mają PASS w opisanym scenariuszu, ale start po pojedynczej wizycie online,
bezpośredni deep link i nieużyte wcześniej zasoby nie spełniają wymagań offline.
**Fizyczny iOS/Android oraz instalacja aplikacji przez system: UNTESTED.**

Test wykonano około **12:19–12:35 UTC**, bez implementowania poprawek.
Odczytano `AGENTS.md`, `DEPLOY.md`, working set guided oraz zatwierdzony projekt
[training-rhythm, sekcja D](superpowers/specs/2026-10-17-training-rhythm-design.md).
Równoległe funkcje repeat/schedule/trends **nie są przedmiotem tej akceptacji**:
nie budowano aplikacji z aktualnie zmienianego drzewa.

Badany, niezmienny web **1.14.0+27**:

```text
fit-web:candidate-1.14.0-27
sha256:a2121f18d6cc6ddb4f6d400bcc2ab8d4cb0b41a38d83fe4909a7717213fafa06
```

UI ponownie potwierdziło „Wersja 1.14.0 · build 27”. Chromium headless
**140.0.7339.16**, obraz narzędzi `fit-guided-browser-test:20261017`.
Prawdziwe API/migrator zachowane z wcześniejszego izolowanego testu:
`5c9bf38690cc…` / `37b0f2c61edd…` (pełne identyfikatory w `verification.json`).
Nowy PostgreSQL 16, migracje **0010**, nowe konto wyłącznie przez oficjalne
`app.cli.create_initial_account`. Login przez rzeczywisty formularz i API;
bez mocków auth/sync, bez modyfikacji SQLite czy wstrzyknięcia danych treningu.

## Izolacja i rzeczywiste odcięcie transportu

- Artefakty: **`/tmp/opencode/pwa-offline-20261017-b82e41/`**.
- Wyłącznie nowy prefix **`fit-pwa-20261017-b82e41`**, sieć `-net`
  z `internal=true`, nowy wolumen `-db`, **zero publikowanych portów**.
- Origin **`https://localhost`**, dostępny tylko w namespace testowego weba.
  Osobne tymczasowe CA/certyfikat. Nie instalowano CA na hoście.
- `service_workers='allow'`; sprawdzono rzeczywisty `navigator.serviceWorker.controller`,
  scope `/`, stan `activated` i faktyczne klucze CacheStorage. Dodatkowy worker
  `/push/` nie zastępuje workera cache aplikacji.
- Pierwsze podejście z `ignore_https_errors=True` nie wystarczyło do rejestracji
  SW: Chromium odmówił pobrania skryptu. Właściwe profile użyły wyjątku TLS
  **przypiętego do SPKI jednego testowego certyfikatu**, bez globalnego ignorowania
  certyfikatów; guard dopuszczał tylko `https://localhost/`, sieć była internal.
- Samo `context.set_offline(True)` okazało się **niewystarczającym dowodem**:
  w pierwszym podejściu worker nadal pobrał `/` i dwa skrypty. Access log
  `access-first.log` zachowano; tego podejścia nie zaliczono do PASS offline.
- Właściwy przebieg rozpoczął się w nowym `profile-acceptance`. Po normalnych
  wizytach UI ustawiono offline **i zatrzymano własny kontener web**, czyli cały
  origin HTTPS, nie tylko `/api`. Browser pozostał w jego namespace.
  Socket `127.0.0.1:443` zwracał **111 / connection refused**; cache-bypass
  fetch `/healthz?...` i `/api/health?...` kończyły się `Failed to fetch`.
- W obu fazach offline access log przed/po jest identyczny. Dla głównej fazy SHA-256:
  `805a74c702bfe2c7a103f507c8b7794c5262871864fbfef4fd7de66fa74ed851`.
  Verifier naliczył **157 odpowiedzi offline, wszystkie `from_service_worker=true`**.
  Odnotował też **842 nieudane żądania** — to nie jest test „czystej konsoli”
  ani braku retry przy odciętym serwerze.
- Reload odbywał się przy wyłączonym HTTP cache (`Network.setCacheDisabled`;
  dodatkowo routing Playwright wyłącza HTTP cache). SW celowo nie był omijany.
  Nie wywołano `downloadOffline`, nie wykonano kontrolnego pobrania całego katalogu.
  Odczyt listy cache nie pobiera zasobów.

## Wyniki per przypadek

FAIL oznacza niespełnienie oczekiwanej dostępności offline, również gdy jest
to przewidywalny skutek obecnej polityki lazy cache, a nie nowa regresja.

| Przypadek | Wynik | Dowód / ograniczenie |
|---|---|---|
| SW zainstalowany, aktywny i faktycznie kontrolujący stronę | **PASS** | scope `/`, controller `flutter_service_worker.js?v=3801261108`, zapisane cache snapshots |
| Cały origin niedostępny, bez server/cache bypass | **PASS** | zatrzymany web, socket 111, bypass probes FAIL, identyczne access logi |
| Root po normalnej ponownej nawigacji online, potem offline reload | **PASS warunkowy** | `/` był faktycznie zapisany w cache; `20-*`, `38-*` |
| Root po **jednej** pełnej wizycie online, realnym loginie i pull | **FAIL** | `profile-single-visit`: brak klucza `/`, jest `/index.html`; `35-*`, `net::ERR_FAILED` |
| Ten sam cold root po zamknięciu i ponownym uruchomieniu Chromium offline | **FAIL** | `37-cold-root-restart-result.json` |
| Kontrola `/index.html` offline w tym samym cold profilu | **PASS** | UI działa, mimo nieudanego `/`; `36-index-control-result.json` |
| Bezpośredni URL `/today`, offline | **FAIL** | brak obsługi SPA fallback w workerze; `21-*`, `22-offline-assets.json` |
| Hash deep link `/#/today` na profilu z zapisanym `/`, offline + reload | **PASS warunkowy** | rzeczywisty routing klienta, `38-hash-today-offline.png` |
| Użyty wcześniej Inter, SQLite WASM i CanvasKit | **PASS** | odpowiedzi SW: 411640 / 730989 / 5678018 B; poprawne sygnatury TTF/WASM, działający UI i odczyt DB |
| Ilustracja cw367 odwiedzona naturalnie online | **PASS** | offline 200, 16140 B, RIFF/WebP; obejrzany `23-visited-offline-painted.png` |
| Ilustracja cw369 nieodwiedzona online | **FAIL dostępności** | brak w cache, fetch FAIL, UI bez ilustracji; obejrzany `24-unvisited-offline-painted.png` |
| Niepobrany wcześniej font Noto Color Emoji shard 8 | **FAIL dostępności** | jest w RESOURCES, nie w cache; offline fetch FAIL |
| Nowe symbole/ZWJ w prawdziwej notatce offline | **FAIL pełnego renderowania próbki** | tofu widoczne w `30-offline-note-cold-fonts.png`, mimo zachowania tekstu w DB; nie tylko warning VS16 |
| Start guided offline, ręczna edycja 7/Lewa, trwały szkic | **PASS** | `19-offline-durable.json`, 1 sesja / 1 szkic / 0 serii |
| Reload w tym samym procesie, jawne Kontynuuj/Wznów | **PASS** | `25-*`, ten sam UUID, pola 7/Lewa, nadal 0 serii |
| Restart procesu Chromium, ten sam profil dyskowy, offline resume | **PASS** | `27-*`, bez nowej sesji/serii; osobny dodatkowy dowód zmiany PID 216 → 293 w `39-*` |
| Jawny zapis jednej serii i kolejny restart offline | **PASS** | `28-*`, `29-*`: ten sam set UUID, dokładnie Lewa/7, bez auto-logu ani duplikatu |
| Finish offline bez doliczenia niepotwierdzonej pracy | **PASS** | `31-*`: 1 set, brak szkicu; podsumowanie pokazuje potwierdzoną pracę czasową **0 s**, nie długość sesji |
| Reconnect → real API ACK, outbox pusty | **PASS** | `32-reconnect-acked.json`; bez deferred records |
| Powtórna synchronizacja i niezależny nowy profil | **PASS** | identyczne dwa pull, `34-independent-profile-pulled.json`, te same UUID |
| PostgreSQL bez duplikatów | **PASS** | 1 profile / 1 workoutSession / 1 workoutSet; 3 operations, 3 changes; `postgres-final.json` |
| OS instalacja PWA / standalone / fizyczny iOS i Android | **UNTESTED** | aktywny SW w headless nie jest dowodem instalacji przez system |
| Osobny timer: pauza/kill/restart i odtworzenie jego elapsed checkpointu | **UNTESTED** | ten przebieg bada szkic formularza i checkpoint jawnej serii, nie osobny scenariusz timera |
| SIGKILL, awaria zasilania, presja pamięci, wygaszenie ekranu | **UNTESTED** | restart był zamknięciem i nowym uruchomieniem procesu, nie symulacją każdego rodzaju awarii |

### Dokładne dane wykonania i synchronizacji

Sesja: **`a65faff4-30f5-4da5-99d8-c0a3bcab0cb7`**.
Seria: **`2d15869a-9fd8-4548-8e2d-c1fbd0ba3195`**.

Plan wygenerowano przez UI z kolekcji spine; cw367 miał cel **1×3**,
blok 3/10. Już po zatrzymaniu originu użytkownik uruchomił trening,
zmienił pole na **7**, wybrał **Lewa**. Przed reloadem i po dwóch rodzajach
resume lokalna SQLite ma ten sam UUID, dokładnie jeden szkic i zero serii;
outbox ma tylko jedną operację startu. Trwałość sprawdzano przez odczyt
rzeczywistych stron SQLite z IndexedDB, nie przez sam ARIA/screenshot.
W Flutterze wartość pola DOM po restore sprawdzono po jego fokusie — samo
nieaktywne pole semantyki początkowo raportuje pustą wartość.

Dopiero „Seria wykonana” utworzyła jedną serię Lewa/7; ponowny restart jej nie
powielił. Finish zapisał notatkę i usunął szkic. Przed reconnect outbox miał
dwie operacje; po realnym ACK zero. Niezależny profil pobrał te same dwie
tożsamości domenowe z API. Bez ręcznej ingerencji w tabele.

Reconnect obejmował także ponowne uruchomienie kontenera przeglądarki z tym
samym profilem dyskowym: restart testowego weba tworzył nowy namespace, podczas
gdy stary browser nadal miał stary loopback. **Nie jest to dowód same-process
reconnect po zmianie wyłącznie `navigator.onLine`**; jest dowodem wysłania
trwale zachowanego outboxa po odzyskaniu rzeczywistej łączności.

## Diagnoza — bez naprawiania aplikacji

Zachowano dokładny `sw.js` i `bootstrap.js` z badanego obrazu.

1. **Cold root:** CORE (`sw.js:451–455`) zawiera `index.html`, ale nie `/`.
   Pierwsza nawigacja dociera przed przejęciem kontroli przez SW. Worker zapisuje
   odpowiedź dla `/` dopiero przy późniejszej kontrolowanej nawigacji online.
   `onlineFirst` szuka potem dokładnie `cache.match(event.request)`; nie zastępuje
   brakującego `/` istniejącym `/index.html`. Kontrola index kontra root
   potwierdza przyczynę bez zmiany workera.
2. **`/today`:** guard `if (!RESOURCES[key]) return` (`sw.js:542–545`) oddaje
   taki URL sieci. Nginx zapewnia SPA fallback online, ale offline nie ma serwera,
   a worker nie wykonuje analogicznego fallbacku. `/#/today` żąda dokumentu `/`,
   więc to odrębny przypadek, zależny od zapisania root.
3. **Zasoby:** wpis w RESOURCES nie oznacza precache. Przy cache miss worker
   wykonuje sieciowy `fetch` (`sw.js:551–560`). Dlatego odwiedzony WebP/Inter
   działa, a nieodwiedzony WebP/emoji nie. W tej próbce niedostępne fallbacki
   dają również **widoczne** braki znaków, nie tylko znany historyczny warning
   U+FE0F. Polskie litery z użytego wcześniej Inter pozostały widoczne.

Nie zmieniano polityki precache, nie wysyłano `downloadOffline`, nie naprawiano
root/deep link/fontów. Ewentualny fix, koszt pobrania katalogu i retest koordynuje
osobno właściciel głównej pracy. Nie przenosić tych PASS na równoległy nowy build.

## Ręczna lista iOS / Android — nadal UNTESTED

Wykonać osobno dla **iPhone + Safari/A2HS** oraz **Android + Chrome/zainstalowana
PWA**, na zatwierdzonym **nieprodukcyjnym** originie osiągalnym z telefonu,
z prawidłowo zaufanym TLS i kontem testowym. Obecny `localhost` w namespace
kontenera nie jest adresem dostępnym dla telefonu. Nie logować się do produkcji
ani nie zmieniać jej danych w ramach tej listy.

- [ ] Zapisać model urządzenia, wersję OS/przeglądarki, wersję aplikacji i godzinę.
- [ ] W czystych danych testowego originu otworzyć aplikację **raz** online,
  zalogować się, poczekać na gotowość UI/SW. Nie dogrzewać całego katalogu.
- [ ] Zainstalować: iOS Safari → Udostępnij → Do ekranu początkowego;
  Android Chrome → Zainstaluj aplikację. Uruchomić z ikony, potwierdzić standalone.
  Nie utożsamiać danych Safari i aplikacji z ekranu głównego bez sprawdzenia.
- [ ] Odłączyć Wi-Fi i dane komórkowe/tryb samolotowy; sprawdzić brak transportu
  również dla statycznego niecache'owanego URL. Zanotować wszystkie FAIL.
- [ ] Porównać start z ikony/root po jednej wizycie, po ponownej zwykłej wizycie
  online oraz wejście w `/today` i `/#/today`. Nie pomijać znanych cold failures.
- [ ] Otworzyć odwiedzoną i nieodwiedzoną ilustrację; wpisać polskie litery,
  `▾ 💪 ⚠️ 👩‍💻 💪🏽` w nowej notatce; zapisać zdjęcia/ekran, nie tylko DOM.
- [ ] Offline uruchomić guided, ustawić inne niż planowane wartości i stronę;
  **bez potwierdzania serii** zablokować ekran na 60 s, odblokować i wznowić.
  Sprawdzić szkic, ten sam UUID i brak nowej serii.
- [ ] Powtórzyć z usunięciem aplikacji z ostatnich aplikacji. Na Androidzie
  odróżnić swipe-away od „Wymuś zatrzymanie”; na iOS użyć app switchera.
  Ponownie uruchomić z ikony nadal offline. Nie reinstalować/nie czyścić danych.
- [ ] Jawnie zapisać jedną serię, ponowić blokadę i kill/relaunch; oczekiwać
  dokładnie jednej serii. Prefill/odtworzony szkic nie jest wykonaniem.
- [ ] Osobno sprawdzić timer: praca → pauza → trwały checkpoint → lock/kill →
  wznowienie. Porównać zapisany elapsed i liczbę serii. Przerwa i czas zamknięcia
  aplikacji nie mogą stać się automatycznie potwierdzoną pracą.
- [ ] Powtórzyć przy włączonym trybie oszczędzania energii i po dłuższym locku.
  Zapisać odmowę Wake Lock/zawieszenie timera jako obserwację, nie ukrywać jej.
- [ ] Przywrócić sieć, otworzyć aplikację, wykonać synchronizację na pierwszym
  planie; potwierdzić pusty outbox i jeden zestaw UUID także z drugiego profilu.

**Brak gwarancji Wake Lock, pracy timera, JS, background sync lub dostarczenia
powiadomień w tle.** System może zawiesić/zabić PWA i wyczyścić dane witryny.
Test trwałości po kontrolowanym restarcie nie daje gwarancji zachowania danych
po odinstalowaniu, czyszczeniu storage ani systemowej eksmisji.

## Artefakty, weryfikacja i cleanup

W root artefaktów:

- `verification.json`, `verify.py`: asercje DB/UUID/outbox/pull/cache/izolacji,
  identyfikatory obrazów, SHA screenshotów i statystki ruchu. Wynik verifiera
  **evidenceAssertions=PASS**, ale jawnie **functionalAcceptance=FAIL**.
- `18-transport-proof.json`, cztery `access-*-cut/after.log`, `traffic.json`:
  oddzielenie rzeczywistego offline od pierwotnego niewystarczającego harnessu.
- `19-*` do `34-*`: odczyty rzeczywistej bazy, screenshoty i ARIA szkicu,
  resume, jawnej serii, summary, ACK oraz niezależnego klienta.
- `34-single-visit-cache.json`, `35-*`, `36-*`, `37-*`: zachowany cold FAIL
  oraz pozytywna kontrola `index.html`. `39-*`: rzeczywiste różne PID Chromium.
- `sw.js`, `bootstrap.js`, `runtime-manifest.json`, `postgres-final.json`;
  `provision.py`, tymczasowy Compose/Nginx, runner i zachowane profile dyskowe.
  Nie eksportowano HAR/trace ani nagłówków logowania do raportu.
- `cleanup.log`, `cleanup-result.json`: **CLEANED**, Compose down exit 0,
  brak własnych kontenerów/sieci/wolumenów. **52 pozostałe kontenery bez zmiany
  ID/obrazu/startu/sieci/portów podczas cleanupu**. Zachowano obrazy i artefakty.

Katalogi artefaktów **0700**, wszystkie pliki **0600**, w tym sekrety i profile
z cookies. Konta/sesje testowe przestały istnieć wraz z usuniętą bazą. Nie
wykonywano operacji na `/docker/fit`, produkcyjnego loginu, resetu hasła,
zmian hostowego CA/proxy/sieci istniejących, prune, commit/push ani deployu.
W repozytorium ta praca dodaje tylko niniejszy raport; równoległych zmian
aplikacji nie modyfikowano i nie zaliczono ich testów do tego wyniku.
