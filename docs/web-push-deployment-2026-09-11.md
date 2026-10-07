# Web Push — wykonane wdrożenie 2026-09-11

Produkcja: https://fit.birek.online. Wszystkie czasy poniżej UTC (Warszawa: +02:00).
Kod zatwierdzonego, nieczystego drzewa `5e2a28d9eceafdcb5eebfaa355078f9af1446acb`;
nie wykonano commita. Nie dodawano FaceID/passkeys.

## Kolejność i dowody

| Czas | Operacja / wynik |
| --- | --- |
| 09:58:29 | Zachowanie trzech obrazów rollback; exclusive create VAPID P-256 i konfiguracji |
| 09:58:31–09:58:33 | `fit-backup.service`: Result=success, ExecMainStatus=0, baza `0005` |
| przed 10:00:20 | Build API `runtime`, migracji `migration`, web **`runtime` Nginx**; exit 0 |
| 10:00:20–10:00:32 | Izolowany restore drill nowym migratorem: exit 0, users=1, sync_records=9, invalid=0 |
| 10:00:49–10:00:54 | Migracja produkcji pod `/run/lock/fit-backup-restore.lock`: exit 0, odczyt DB `0007` |
| 10:00:59 | Start wyłącznie nowych web/API/push-sender przez `up --no-deps --no-build --wait` |
| 10:01:54–10:01:58 | Pierwszy monitor: Result=success, ExecMainStatus=0; wszystkie kontrole prawidłowe |
| 10:05:59–10:06:03 | Kolejny automatyczny przebieg timera: Result=success, ExecMainStatus=0 |
| 10:06:08–10:06:10 | Końcowy odczyt `0007`, heartbeat wiek 2.79216 s, 0 subskrypcji; 4 testy zaufania proxy OK |

## Obrazy i backup

Nowe obrazy mają tagi `push-20260911` oraz `production`:

| Obraz | Pełny image ID |
| --- | --- |
| fit-api (także sender) | `sha256:ccf4611af6b34726e5f64ed0f681c77eced3affa16c2c381b5c0e42d88bff2c3` |
| fit-web | `sha256:ad11958015816baa0b88618c2e590b7a708137664efa8c33fd842feed5d09bcd` |
| fit-migration | `sha256:964e488f12bec71b7ce95212db90bf6096bee5b2efcf1201fa0e54cb25b2daac` |

Rollback: `/docker/fit/push-rollback.json` (0600, bez sekretów), tagi
`fit-{api,web,migration}:pre-push-20260911T095829Z`:

- API: `sha256:e44f6ce13e145fdceffd803b9a4fed10fcb828440ad496144141da9a7bbc3657`.
- Web: `sha256:964f9d8d36d9f35cc306d3f13852190865b83763b55d157b92e3ce0889a5f485`.
- Migrator: `sha256:898cdcb878d53ce5aae79629b43ec42e0c3c100853cb3c617eb131d45ec12ba2`.

Manifest wykonanego wdrożenia: `/docker/fit/push-deployment-20260911.json`
(0600, bez sekretów): nowe image IDs, odnośnik do kopii i manifestu rollback,
checksum dumpa, rewizja `0007`, target runtime i otwarty manual gate.

Backup: `/docker/fit/data/backups/20260911T095831962419Z`.
Dump 20294 bajty; SHA-256
`8f1f53ba319bf3a575775557c550020cddbbeceba58d90bc7c7eaa28e93bbd2c`.
Niezależnie przeliczono checksum i porównano z `manifest.json`. Manifest zapisuje
`0005` i **stare** image IDs API/migratora, zgodne z manifestem rollback.
Nowy migrator promowano dopiero po tej kopii. Drill odtworzył wyłącznie
`fit_restore`, zastosował nowe migracje i usunął tę izolowaną bazę; produkcji nie
odtwarzano ani nie wykonywano downgrade.

## Konfiguracja i kontrole

- Klucz wygenerowano kryptograficznie poza repo; pliki utworzono wyłącznie przez
  exclusive create/no overwrite. PEM `/docker/fit/secrets/push-vapid-private.pem`
  root:65532, 0640; katalog root 0700; `push.env` i overlay 0600.
   Kontakt VAPID: owner account (redacted). Prywatny klucz nie był drukowany,
  umieszczany w argv, obrazie ani patchu. Sender UID 65532 potwierdził odczyt PEM.
- **Historyczny zapis wdrożenia:** 11 września 2026 polecenia runtime Compose
  używały plików base i push; walidacja używała wyłącznie `config --quiet`.
  Ten zapis nie opisuje bieżącej procedury: obecne polecenia runtime wymagają
  plików base, push i mentor zgodnie z `DEPLOY.md`. Bazowy runtime Compose był
  zgodny z szablonem (porównanie bez wypisywania zawartości). Minimalna zmiana
  `database-backup.py`: wykrywanie zainstalowanego overlay także dla przyszłych
  backupów i migracji drill.
  Oddzielna kontrola obu gałęzi wyboru Compose (bez/z overlay) przeszła;
  `git diff --check` i końcowe `config --quiet` zakończyły się kodem 0.
- Zainstalowano tylko pięć jednostek: backup/restore service oraz push-monitor
  service/timer i push-failure template. Zachowano istniejący logger OnFailure,
  dodano push OnFailure, wykonano `systemd-analyze verify`, daemon-reload,
  enable/start timera. Istniejące timery backup/restore pozostały włączone.
- API: 24 pliki źródłowe zgodne hashami z finalnym drzewem; migracje: 8 plików.
  BuildKit potwierdził aktualny cache etapów Flutter verification/release;
  końcowy serwer to **nginx/1.31.0**, nie Flutter builder.
- Publiczne HTTPS `/api/health`: 200, `{"status":"ok"}`. `/`, `/today`,
  `/settings`, `/workout`: 200, poprawny fallback HTML.
- Publiczne JS, SQLite/CanvasKit Wasm, manifest assets i dane ćwiczeń zgodne
  bajt w bajt z kontenerem. JS `no-cache`, Wasm `application/wasm`; brak
  rozszerzającego scope `Service-Worker-Allowed` na workerze push.
- Chronione `/api/push/status`: 401 bez sesji; po jednej próbie logowania 200,
  `deliveryAvailable=true`, `reason=ready`, klucz zgodny z runtime, `no-store`.
  Hasło/cookies/CSRF tylko w pamięci, bez traces. Logout tej sesji 204,
  ponowny status 401. Nie unieważniono sesji użytkownika ani nie zmieniono hasła.
- Heartbeat o 10:01:48.533839 miał wiek 3.408185 s przy odczycie.
  Subskrypcji było 0. Nie tworzono testowych subskrypcji ani danych zdrowotnych.
- Kontrole `api`, `backup`, `restore`, `stale_backup`: `failing=false`, generation=0.
- API/web healthy; sender działa (overlay świadomie nie ma Docker healthcheck,
  źródłem gotowości jest heartbeat). Restarts=0, PortBindings={} dla usług Fit.
  `8000/tcp` przy senderze to odziedziczone EXPOSE obrazu, nie port hosta.
- PostgreSQL zachował start `2026-09-10T08:28:22.786136842Z`; Caddy
  `2026-08-21T10:23:31.162230163Z`. Nie zmieniano Caddy, sieci, portów, XFF ani
  usług współdzielonych. Historyczny `fit-migrate-1` nadal wskazuje stary obraz
  i exit 0; dowodem tej migracji jest nowe `run --rm` i odczyt DB `0007`.

Wybrane publiczne SHA-256:

| Plik | SHA-256 |
| --- | --- |
| push/push-client.js | `435c1f8586c4776656052ad03caade365d2305254ef88433c37fc891ba9c2cb0` |
| push/push-worker.js | `7a4c0968b0b5569de2ef5c38a41cf5327fc4e8cee256582ed7a302c7578e64c3` |
| main.dart.js | `717588f1ba0272efa1eaae0c16d51c285827dc2b50f242dbfb3f7aff91d84523` |
| sqlite3.wasm | `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117` |

## Ograniczenia i rollback

**Manual gate nadal otwarty:** prawdziwy iPhone/iPad iOS 16.4+, instalacja PWA
przez Safari, świadoma zgoda/kategoria, test przy zamkniętej aplikacji i kliknięcie
powiadomienia. Pełna lista w [web-push.md](web-push.md#weryfikacja-i-manual-gate).
`ready` nie dowodzi odbioru przez Apple ani urządzenie. Monitoring jest best effort,
zależny od DB/Dockera/hosta i opt-in operations; nie zastępuje zewnętrznego alarmu.
Nie wywoływano celowych awarii na produkcji. Istniejący Restic obejmuje runtime
i sekrety, ale podczas tej operacji nie uruchamiano ani nie potwierdzano nowej
kopii off-host VAPID. Operator powinien potwierdzić następny snapshot Restic;
nie rotować ani nie generować ponownie klucza przy restarcie.

Najmniej inwazyjne wycofanie funkcji: bezpiecznie ustawić `PUSH_ENABLED=false`
w runtime `push.env` (nie wypisywać całego pliku), wyłączyć monitor timer i
odtworzyć wyłącznie API/sender z **aktualnego** obrazu, używając plików Compose
base, push i mentor oraz `up -d --no-deps --no-build --wait api push-sender`.
Pozostawić DB `0007`,
klucz i dane. Sender może pozostać zatrzymany po wyłączeniu.

Pełny rollback aplikacji wymaga zatwierdzonego sprawdzenia zgodności starego API
z rozszerzonym schematem `0007`. Najpierw nowy backup bieżącej bazy i zachowanie
bieżących obrazów, zatrzymanie timera/sendera; dopiero wtedy promowanie zachowanych
tagów API/web i targeted up obu usług bez dependencies/build. **Nie uruchamiać
starego sendera ze starego API** (nie ma modułu push). Stary tag migratora jest
artefaktem rollback, nie narzędziem do downgrade `0007`; nie promować go do rutynowych
drillów aktualnego schematu. Odtwarzanie produkcyjnej bazy to osobna procedura DR
pod wspólnym flock, po zachowaniu obecnego stanu i akceptacji utraty zmian od kopii.
Nie usuwać katalogu danych ani wykonywać automatycznego downgrade.
