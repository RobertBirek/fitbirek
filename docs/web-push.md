# FitBirek PWA Web Push

Kod obejmuje opt-in w ustawieniach Flutter web, osobny worker, VAPID, trwałą
kolejkę i scheduler oraz alarmy operacyjne. **Wdrożono produkcję 2026-09-11,
10:00:59 UTC** z trwałym VAPID i `PUSH_ENABLED=true`. Status chroniony potwierdził
`ready`; odbiór na prawdziwym iPhonie pozostaje manual gate. Dowody i rollback:
[raport wdrożenia](web-push-deployment-2026-09-11.md).
Domyślnie w kodzie `PUSH_ENABLED=false`; bez konfiguracji
API nadal działa, ale UI nie pozwala włączyć wysyłki. Powiadomienia natywnego
Androida zachowują dotychczasowy scheduler i ustawienia.

## Kontrakt i model

Wszystkie trasy `/api/push` wymagają istniejącej sesji FitBirek. Mutacje wymagają
dokładnego zaufanego `Origin` i `X-CSRF-Token` powiązanego z sesją.

| Metoda i ścieżka | Wynik |
| --- | --- |
| `GET /status` | `deliveryAvailable`, `reason`, publiczny `publicKey`; `no-store` |
| `GET /subscriptions/{installationUUID}` | Kategorie własnej instalacji lub 404; bez endpointu/kluczy; `no-store` |
| `PUT /subscriptions/{installationUUID}` | Zapis/aktualizacja opt-in, 204 |
| `DELETE /subscriptions/{installationUUID}` | Idempotentne usunięcie własnej instalacji, 204 |
| `POST /subscriptions/{installationUUID}/test` | 202 `{"queued":true}`, nie potwierdzenie dostarczenia; 429 z Retry-After lub 503 |

PUT przyjmuje:

```json
{
  "endpoint": "https://fcm.googleapis.com/fcm/send/PROVIDER_TOKEN",
  "keys": {"p256dh": "BROWSER_PUBLIC_KEY", "auth": "BROWSER_AUTH_SECRET"},
  "vapidPublicKey": "PUBLIC_KEY_FROM_STATUS",
  "categories": {"karate": true, "training": true, "mood": true, "operations": false}
}
```

Brak kategorii oznacza wszystkie wyłączone. Nieznane pola, nieboolowskie
preferencje, niekanoniczny base64url, niepoprawne długości i punkty poza krzywą
P-256 są odrzucane. Właściciel pochodzi wyłącznie z uwierzytelnienia. Cudza
instalacja lub zajęty endpoint daje ogólny 409, bez przenoszenia własności.
Limit 10 instalacji na konto jest serializowany blokadą konta. Test push ma
osobny trwały limit **1 żądanie na 60 sekund na użytkownika**, wspólny dla
instalacji i procesów API; odrzucone żądanie nie wydłuża okna.

Migracje:

- `0006`: `push_subscriptions`, właściciel, sesja, endpoint, klucze i kategorie.
- `0007`: powiązanie z publicznym kluczem VAPID; `push_deliveries`,
  `push_test_limits`, `push_sender_state`, `push_incidents`.

Endpoint i auth są poufne i przechowywane w DB jawnie, potrzebne do wysyłki.
Hash endpointu służy unikalności, nie szyfrowaniu. Chronić DB i kopie jak dane
konta. Odpowiedzi API ich nie ujawniają. Sender loguje tylko typ błędu, nigdy
pełny wyjątek, endpoint, payload ani klucz prywatny.

## Dostarczanie i harmonogram

Proces **`python -m app.push.worker`**, poza Uvicornem:

- ładuje wyłącznie wskazany plik PEM; nigdy nie generuje klucza;
- sprawdza P-256, zgodność kluczy i możliwość podpisania VAPID;
- publikuje heartbeat w DB; API uznaje sender za dostępny przez 90 sekund,
  wyłącznie przy zgodnym kluczu publicznym i włączonej konfiguracji;
- co kilka sekund planuje i wysyła małe partie, ponownie sprawdzając opt-in,
  klucz VAPID, TTL oraz aktualność incydentu tuż przed wysyłką.

Terminy są liczone w `Europe/Warsaw`, z uwzględnieniem DST:

| Kategoria | Termin | TTL / okno nadrabiania |
| --- | --- | --- |
| Karate | wtorek i czwartek 19:30 | 15 minut |
| Trening | codziennie 18:00 | 15 minut |
| Samopoczucie | codziennie 20:30 | 15 minut |
| Test | po żądaniu użytkownika | 5 minut |
| Operations | zmiana stanu alarm/recovery | 1 godzina |

Unikalny `(installation_id, event_key)` zabezpiecza kolejkę przed duplikacją
przez kolejne przebiegi lub kilka schedulerów. Nie ma lawiny starych przypomnień.
Blokada transakcyjna subskrypcji i zadania jest dzierżawą wysyłki: `SKIP LOCKED`
umożliwia współbieżność, a śmierć procesu zwalnia blokady przez rollback.
Blokady mają tę samą kolejność co kaskadowe usuwanie przy logout.

Błędy sieciowe, 408, 429 i 5xx: backoff 30 s, 60 s, 120 s… do 900 s,
maksymalnie 8 prób i zawsze w granicach TTL. 404/410 usuwają subskrypcję wraz
z zadaniami. Pozostałe błędy, także 3xx, są końcowe. Historia i klucze dedup
mają retencję 7 dni. Nieaktualny alarm jest pomijany po nowszej zmianie stanu,
więc retry starego alarmu nie jest wysyłane po recovery.

To **at-least-once**, nie exactly-once: utrata procesu/DB po przyjęciu push
przez dostawcę, ale przed commitem, może spowodować powtórzenie. Stały tag
powiadomienia ogranicza duplikaty widoczne na urządzeniu. Nie można odwołać
wiadomości już wysłanej; worker dodatkowo sprawdza TTL i zgodę lokalną.

## Transport i SSRF

Dokładna allowlista: `fcm.googleapis.com`,
`updates.push.services.mozilla.com`, `web.push.apple.com`. HTTPS, brak wildcardów,
userinfo, jawnego portu, fragmentów, backslash i znaków kontrolnych. Rozszerzenie
listy dla innego dostawcy wymaga sprawdzenia rzeczywistego endpointu.

Przy każdej próbie sender ponownie waliduje URL, rozwiązuje DNS i odrzuca
cały zestaw odpowiedzi, jeśli którykolwiek adres nie jest publiczny. Odrzuca
również multicast, adresy zarezerwowane/site-local, IPv4-mapped IPv6, 6to4,
Teredo i znane prefiksy translacji NAT64. Łączy się socketem z dokładnie
sprawdzonym numerycznym adresem, bez ponownego DNS dla nazwy. TLS weryfikuje
certyfikat i oryginalny hostname/SNI. Całe DNS/TCP/TLS/POST/status ma timeout
10 sekund, wspólny dla wszystkich prób połączenia. Nieosiągalny adres lub błąd
TCP/TLS przed wysłaniem żądania powoduje próbę kolejnego już zweryfikowanego IP.
Pojedyncza próba TCP/TLS ma limit 3 sekund, aby pierwszy blackhole nie zużył
całego budżetu. Po rozpoczęciu POST nie ma fallbacku IP: błąd write/drain/read
lub niejednoznaczny wynik wraca do kolejki, bez natychmiastowego ponowienia POST
pod innym adresem. Obowiązuje opisana wyżej semantyka retry at-least-once kolejki.
Nie korzysta z proxy z otoczenia, nie czyta ani nie podąża za
`Location`. Czyta ograniczoną linię statusu, nie pobiera body odpowiedzi.

Szyfrowanie RFC 8291: `http-ece` i `cryptography`; podpis RFC 8292: `py-vapid`.
Oba główne hash-locki włączają `requirements-push.lock`. `http-ece` publikuje
sdist, więc również narzędzia jego budowania są przypięte w
`requirements-build.lock`; Docker i Makefile wyłączają izolowane pobieranie
nieprzypiętych build dependencies. Dotychczasowe zależności nie są aktualizowane.

## PWA i lifecycle

`push-client.js` jest ładowany przed Flutter bootstrap; Dart używa warunkowego
JS interop. Ustawienia pokazują wsparcie, potrzebę instalacji, permission,
stan sendera, cztery kategorie, włączenie/wyłączenie, odnowienie po rotacji
VAPID i test. „Dodano do kolejki” nie oznacza „dostarczono”.

`Notification.requestPermission()` jest wywoływane synchronicznie w obsłudze
przycisku, przed pierwszym await. Status, bootstrap i odświeżenie nigdy nie
pytają o zgodę ani nie tworzą nowej subskrypcji. Istniejący świadomy opt-in jest
ponownie wiązany z sesją po zalogowaniu; zmiana konta resetuje go.

Osobna rejestracja:

```javascript
navigator.serviceWorker.register('/push/push-worker.js', {
  scope: '/push/', updateViaCache: 'none'
});
```

Klient używa tego konkretnego obiektu, **nie** `serviceWorker.ready`. Worker
nie ma handlera fetch, `clients.claim()` ani logiki cache Fluttera. Istniejący
Nginx daje JS `no-cache`; nie rozszerzać `Service-Worker-Allowed` do `/`.

Zgoda, UUID instalacji, właściciel i kategorie są lokalne w osobnej IndexedDB
`fit-push-state`, poza synchronizacją danych domenowych. Operacje klienta są
serializowane, również między kartami przy wsparciu Web Locks, **z wyjątkiem
cofnięcia zgody**. Generacja intencji subscribe/save/test jest pobierana
synchronicznie ze stanu ostatniego statusu, przed oczekiwaniem na kolejkę/lock
(także asynchroniczny odczyt IndexedDB mógłby zakończyć się dopiero po logout).
Jej kontrola wobec aktualnej IndexedDB przed żądaniem i przy
commicie uniemożliwia przywrócenie opt-in przez stary request po logout.

Logout od razu uruchamia niezależny zapis `enabled=false` i nowej generacji w
IndexedDB, równolegle z blokadą lokalnego konta w Drift. Transakcja cofnięcia
zgody ma `durability: strict` i nie oczekuje na kolejkę, Web Locks, sieć ani
PushManager. Dopiero po commicie w tle kolejkuje zamknięcie powiadomień oraz
`unsubscribe`; cleanup sprawdza generację, aby nie usunąć nowszego opt-in.
API usuwa subskrypcje powiązane z wylogowywaną sesją. Sam cleanup nie opóźnia
zakończenia logout. JS zgłasza błąd, jeśli lokalny commit nie potwierdzi się
w 2 sekundy; Flutter ogranicza oczekiwanie na bridge do 3 sekund. Bootstrap
z `offlineAccess=false` ponawia lokalne cofnięcie zgody także bez sieci, naprawiając
zamknięcie PWA pomiędzy zapisami w dwóch bazach. „Wyłącz Web Push” również
cofa zgodę poza kolejką, a usuwanie po stronie dostawcy/serwera odbywa się w tle.
Przy braku sieci lokalny worker odrzuca nawet
wcześniej zakolejkowane push. Przeglądarka może pokazać własny ogólny komunikat
o aktywności w tle dla zdarzenia bez widocznego powiadomienia; treści aplikacji
są tłumione. Wygaśnięcie sesji samo nie kasuje opt-in w DB (przypomnienia mają
działać przy zamkniętej aplikacji); obsłużone przez klienta 401 wyłącza go lokalnie.

Worker wyświetla stałe, krótkie teksty; alarmy identyfikują rodzaj kontroli i
recovery, bez szczegółów błędów ani danych zdrowotnych. Kliknięcie ponownie
waliduje exact same-origin `/today`, `/workout` lub `/settings`, bez query/hash
i normalizowanych aliasów. Skupia kartę dokładnego celu albo otwiera nową,
nie przekierowuje aktywnego treningu.

## Alarmy operacyjne

`deploy/ops/push-monitor.py` odczytuje stan systemd, kompletne manifesty backupów
i publiczne `/api/health`. Zapisuje obserwacje **lokalnym CLI sendera przez
Docker exec**, nie przez proces/HTTP API. Odbiorcy muszą mieć opt-in `operations`.
Nie ma publicznej trasy zgłaszania alarmów.

- Backup/restore: istniejący logger pozostaje; dodatkowy `OnFailure` uruchamia
  `fit-push-failure@.service`. Timer monitoringu sprawdza też utrzymujące się błędy.
- Recovery backup/restore wymaga zakończonego sukcesem uruchomienia jednostki;
  samo rozpoczęcie retry lub reset stanu po restarcie hosta nie jest recovery.
- Stare kopie: brak ukończonego manifestu i niepustego dumpa albo wiek >30 h.
  Nie jest to ponowny checksum całego dumpa — robi go drill restore.
- API: błąd HTTPS, redirect, inny status lub body niż `{"status":"ok"}`.
- Timer co 2 minuty, pierwszy przebieg po 2 minutach od startu. Incydenty,
  generacje i chronologia obserwacji są trwałe w PostgreSQL; powtarzające się
  obserwacje nie tworzą kolejnych alarmów.

**Zależności:** DB musi działać do odczytu odbiorców, zapisu dedup i kolejki.
Awaria DB uniemożliwia gwarantowane wysłanie alarmu przez ten kanał. Monitoring
korzysta także z Dockera i działającego kontenera sendera. Nie wykryje i nie
zgłosi śmierci całego hosta/utraconej łączności: do tego potrzebny jest zewnętrzny
monitoring. Web Push jest best effort i nie zastępuje gwarantowanego kanału alarmowego.

## Procedura wdrożenia — wykonano 2026-09-11

1. Wykonać testy poniżej, przegląd zmian, buildy i backup według `DEPLOY.md`.
   Migracje do `0007` muszą zakończyć się **przed** uruchomieniem nowego API.
2. Operator dostarcza parę VAPID P-256: prywatny PEM i odpowiadający mu publiczny
   klucz uncompressed base64url. Utworzyć ją poza repo, przechować w menedżerze
   sekretów; nie generować przy starcie kontenera. Nie używać kluczy z testów.
3. Umieścić prywatny PEM w `/docker/fit/secrets/push-vapid-private.pem`.
   Sender działa jako **65532:65532**: plik root:65532, tryb **0640**, katalog
   sekretów root **0700**. Compose bind-mountuje konkretny plik tylko do sendera;
   API dostaje wyłącznie klucz publiczny. Nie polegać na `uid`/`mode` Compose
   secrets dla pliku bind-mounted. Sprawdzić czytelność jako UID 65532 bez
   wypisywania zawartości, np. `test -r /run/secrets/push_vapid_private`.
4. Zainstalować szablon `deploy/compose.push.yaml` jako
   `/docker/fit/compose.push.yaml`. Z `deploy/push.env.example` przygotować
   `/docker/fit/push.env` (0600): prawdziwy publiczny klucz i kontakt `mailto:`
   operatora. Początkowo `PUSH_ENABLED=false`, następnie świadomie ustawić true.
   Klucz prywatny nie może trafić do `.env`, argv, obrazu, logów ani Git.
5. Każde bieżące polecenie Compose dla instalacji z push musi uwzględniać
   **trzy pliki: base, push i mentor**. Walidować wyłącznie `config --quiet`:

   ```bash
   docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
   # Po buildach, backupie i migracji zgodnie z DEPLOY.md:
   docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml up -d --no-deps --no-build --wait --wait-timeout 180 web api push-sender
   ```

6. Zainstalować **wyłącznie** wskazane zmienione jednostki (bez wildcardów):

   ```bash
   install -m 0644 \
      /opt/fit/deploy/ops/systemd/fit-push-monitor.service \
      /opt/fit/deploy/ops/systemd/fit-push-monitor.timer \
      /opt/fit/deploy/ops/systemd/fit-push-failure@.service \
      /opt/fit/deploy/ops/systemd/fit-backup.service \
      /opt/fit/deploy/ops/systemd/fit-restore-verify.service \
      /etc/systemd/system/
   systemctl daemon-reload
   systemctl enable --now fit-push-monitor.timer
   ```

   Warunki `ConditionPathExists` nie pozwalają uruchamiać monitoringu push bez
   plików konfiguracyjnych. Nie zmieniać sieci ingress, portów, Caddy ani zaufania XFF.
7. Sprawdzić chroniony `/api/push/status`: `ready` potwierdza konfigurację i
   heartbeat, **nie** dostępność dostawcy. Otworzyć ustawienia, wybrać kategorie,
   świadomie włączyć Web Push i wysłać test. Zweryfikować otrzymanie na urządzeniu.

Wyłączenie: `PUSH_ENABLED=false` dla API i sendera oraz ich restart zgodnie
z procedurą ops; wyłączyć timer, jeśli monitoring ma być zatrzymany. Istniejące
API nie wymaga VAPID. Rotacja klucza wymaga nowej subskrypcji w przeglądarce;
UI pokaże „Odnów subskrypcję”, a sender nie wyśle do starego klucza.
Backupy runtime muszą obejmować także PEM, push.env, overlay i jednostki.

## Wynik weryfikacji implementacji

- Pełny backend po poprawkach P1/P2: **146 passed**, 236,32 s, PostgreSQL 16 Testcontainers.
- Flutter: **220 testów**, `flutter analyze` bez uwag; build web release udany.
- Browser/ops: **12 testów** pod Xvfb, w tym rzeczywisty service worker i IndexedDB.
- Worker JS: **9 testów**, bez pominięć.
- Obraz API runtime z hash-lockami zbudowany; Compose overlay sprawdzony przez
  `config --quiet --no-env-resolution` bez czytania plików runtime.
- Nowe/zmienione jednostki systemd przeszły `systemd-analyze verify`.

Regresje P1 obejmują zablokowany refresh/PushManager, Web Lock w innej karcie,
opóźniony odczyt IndexedDB przy włączeniu, późne subscribe/PUT, zamknięcie PWA
i restart bez sieci oraz naprawę przy zablokowanym offline bootstrap i timeout
bridge. Regresje P2 obejmują niedostępny pierwszy IP, błędy/timeout TCP i TLS,
wspólny deadline oraz brak fallbacku po write/drain/read POST.

Obrazy testowe: `fit-api:push-verified`, `fit-web:push-release`. Build release
przechodzi przez etap `verification`, ale jest builderem, nie serwerem WWW.
Produkcja używa końcowego targetu `runtime` Nginx: `fit-web:push-20260911`;
API/sender: `fit-api:push-20260911`, migrator: `fit-migration:push-20260911`.
Te obrazy promowano również do tagów `production` po backupie i migracji.
Ostrzeżenie opcjonalnego Wasm dry-run dotyczy istniejącego
`flutter_secure_storage_web`; wybrany build JavaScript zakończył się sukcesem.

## Weryfikacja i manual gate

Izolowane polecenia:

```bash
# /opt/fit/backend
.venv/bin/python -m pip install --require-hashes -r requirements-build.lock
.venv/bin/python -m pip install --no-build-isolation --require-hashes -r requirements-dev.lock
.venv/bin/python -m pytest -q
# /opt/fit
xvfb-run -a python3 -m unittest discover -s tools/tests -p 'test_push_*.py' -v
node --test tools/tests/push-worker.test.mjs
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:push-verified .
docker build --target release -f deploy/docker/web.Dockerfile -t fit-web:push-release .
# Obraz uruchamiany w produkcji (release powyżej jest tylko builderem):
docker build --target runtime -f deploy/docker/web.Dockerfile -t fit-web:push-candidate .
docker build --target runtime -t fit-api:push-verified backend
git diff --check
```

Backend używa osobnego PostgreSQL 16 Testcontainers. Klucze testowe są tymczasowe,
wyłącznie lokalne. Chromium testuje realną IndexedDB i gest przycisku przy
zamockowanych usługach push/API. Dodatkowy test pod Xvfb uruchamia prawdziwy
worker i sprawdza powiadomienie po syntetycznym zdarzeniu CDP oraz jego zamknięcie
przy logout. Xvfb jest potrzebne, bo Chromium headless w tym środowisku odmawia
systemowego permission notifications; bez DISPLAY ten jeden test jest pomijany.
Testy transportu sprawdzają pinning, TLS/SNI,
brak redirectów, szyfrowanie/dekryptowanie i podpis VAPID. Testy Fluttera obejmują
UI i logout. Toolchain wyłącznie **Flutter 3.35.4 / Dart 3.9.2**.

**Manual gate na urządzeniu (bez niego brak deklaracji rzeczywistego odbioru):**
iPhone/iPad iOS 16.4+ → Safari → Udostępnij → Do ekranu początkowego → uruchom
z ikony → zaloguj → włącz kategorię i push → zaakceptuj permission → test przy
zamkniętej aplikacji → kliknięcie do właściwego ekranu. Następnie odmowa
uprawnień, wyłączenie kategorii, offline logout, zmiana konta i rotacja VAPID.
Analogiczny test Chrome/Firefox oraz natywnego Androida (brak regresji lokalnych
przypomnień). Do testu alarm/recovery użyć izolowanego środowiska i syntetycznych
obserwacji CLI — nie psuć produkcyjnego backupu ani API na potrzeby testu.
