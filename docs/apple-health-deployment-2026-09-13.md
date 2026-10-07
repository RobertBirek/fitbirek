# Wdrożenie Apple Zdrowie — 1.1.0+3

**Wdrożono za zgodą użytkownika.** Pomiar końcowy z rzeczywistego zegara hosta:
2026-09-13 **10:36:20 Europe/Warsaw / 08:36:20 UTC**.
Poprzednia produkcja: 1.0.1+2, Alembic 0007. Obecna: **1.1.0+3, Alembic 0008**.
Ręczny odbiór rzeczywistego iPhone/Skrótu pozostaje **pending**, nie jest
zastępowany testami serwera ani kontrolą skompilowanego artefaktu.

## Źródła i testy

- Zachowano zastane niezatwierdzone zmiany; nie wykonano commita ani resetu.
  Git HEAD: `5e2a28d9eceafdcb5eebfaa355078f9af1446acb`, dirty tree.
- Nie podbijano wersji: to pierwsze wydanie przygotowanego **1.1.0+3**.
- Flutter **3.35.4**, Dart **3.9.2**, bez upgrade i zmiany zależności.
- Nowy Docker `verification`: generator wersji `--check`, regeneracja Drift,
  analiza **No issues found**, pełne **286 testów zaliczonych**. Obejmuje
  niezależny pełny kursor v7, instrukcję offline i czytelną etykietę wersji.
- Pełny backend: **191 passed in 270.43s**, Python 3.12 i izolowany PostgreSQL
  przez Testcontainers. Nie używano produkcyjnej bazy do testów.
- Finalny web zbudowano przez `--target runtime` z aktualnego źródła,
  korzystając z właśnie zaliczonego etapu verification; nie promowano review3.
- API runtime i migrator zbudowano ponownie. Dodatkowo porównano SHA-256
  wszystkich **29 plików Python app/** źródła z każdym z obu obrazów: zgodne.
- Migrator bez sieci: `alembic heads` → **0008 (head)**. Nginx bez sieci i
  publikowania portów: `nginx -t` → poprawna konfiguracja.
- `git diff --check`: poprawny.

## Finalne obrazy

Wspólny tag kandydatów: `final-1.1.0-3-20260913T081840Z`.
Poniżej identyfikatory zwrócone przez `docker image inspect .Id` i potwierdzone
w uruchomionych kontenerach API/web/sendera (Docker używa indeksów OCI).

| Repozytorium | ID promowane do `production` |
| --- | --- |
| `fit-api` (API i push-sender) | `sha256:8ce2130abb1157272116e1015144c55c1347b8c8d254dca5d3591d32ef1e8f63` |
| `fit-web` (Nginx) | `sha256:19c5c5ba8b811372fdc4ebf8276e39e878006451ddac2e7efa839108d7c80ff4` |
| `fit-migration` | `sha256:a6eacfcc7920363dfaffcacf852220a6a1eaa8a904cab680382356cafebbefa0` |

Etap verification: `fit-web:verification-1.1.0-3-20260913T081840Z`,
ID `sha256:626cda3c95a652066e59fa87aade18308aa009c12e71f09cd7ad99200c83f75d`.

## Backup i migracja

Przed zmianą tagów produkcyjnych zachowano stare API/web/migration pod unikalnymi
tagami rollback. Backup uruchomiono, gdy `production` nadal wskazywało stare obrazy.

- Bundle: `/docker/fit/data/backups/20260913T083334164433Z`.
- Dump SHA-256: `2a2a513717cc7f4cfb7cb0149ed648db06112104dbba48a91e0565d92e6b4fde`.
- `fit-backup.service`: **Result=success, ExecMainStatus=0**.
- Niezależnie przeliczono SHA-256; manifest ma **0007** oraz dokładnie stare
  ID API i migratora z tabeli rollback poniżej.
- Dopiero po kontroli backupu promowano nowy migrator. Izolowane odtworzenie
  wybranego bundle przez `restore-verify.sh` wykonało `upgrade head` nowym
  migratorem: **exit 0, users=1, sync_records=10, invalid=0**.
  `fit_restore` usunięto; późniejszy odczyt katalogu baz potwierdził brak tej bazy.
- Produkcyjny migrator uruchomiono przez `flock -w 900
  /run/lock/fit-backup-restore.lock` i Compose `run --rm --no-deps -T migrate`:
  **exit 0**, osobny odczyt produkcji potwierdził **0008**.
- Oba pliki `/docker/fit/compose.yaml` i `/docker/fit/compose.push.yaml`
  uwzględniono w poleceniach runtime i `config --quiet`. Następnie promowano
  finalne API/web i wykonano wyłącznie
  `up -d --no-deps --no-build --wait --wait-timeout 180 web api push-sender`.
- Historyczny `fit-migrate-1` widoczny w `ps -a` nie jest dowodem tej migracji:
  wykonano nowe kontenery jednorazowe `run --rm` dla restore i produkcji.

## Kontrola produkcji bez logowania

- API/web/postgres healthy; sender running, ten sam obraz co API.
- Heartbeat sendera: **2026-09-13 08:36:22.265665 UTC**, wiek przy pomiarze
  **0 s**. `fit-push-monitor.timer` aktywny. Nie wysyłano testowego push.
- Odczyt transakcyjny `READ ONLY`: **1 użytkownik, 10 sync_records,
  0 niepoprawnych rekordów, 1 subskrypcja push** — liczby identyczne przed/po.
- Wszystkie trzy nowe tabele Apple Zdrowie mają **0 rekordów**.
- HTTPS z poprawną walidacją certyfikatu: `/`, `/today`, `/version.json`,
  `/main.dart.js`, `/sqlite3.wasm`, `/drift_worker.dart.js`,
  `/flutter_service_worker.js`, `/flutter_bootstrap.js`, `/push/push-worker.js`
  → **200**, statyczne odpowiedzi **Cache-Control: no-cache**.
- Wasm: **application/wasm**; JS: **application/javascript**;
  version.json: **application/json**. HTTP → **308** do HTTPS.
- `/api/health` → **200**, `{"status":"ok"}`.
- `/api/integrations/apple-health` bez sesji → **401**, **no-store**.
- Publiczne `version.json`: **version=1.1.0, build_number=3**.
  SHA-256 publiczny = kontener:
  `145b09ea524a3ca1a0e0948cf52ed6c46790aa1c32e4b48b577be4ca9eb52e9d`.
- Publiczny `main.dart.js` = kontener, SHA-256:
  `558456349d5f0372bb0659032b55363e3ce8828d8c3aea749b8698f695ce0db8`.
  Po dekodowaniu sekwencji JS potwierdzono teksty **„Wersja 1.1.0 · build 3”**,
  **„Łączenie ze Zdrowiem”**, `Find Health Samples`, `manual_verified_total`.
  To kontrola zawartości kompilacji, nie deklaracja ręcznego testu Safari.
- Brak opublikowanych portów Fit. ID kontenerów PostgreSQL/Caddy nie zmieniły się;
  nie restartowano ich ani nie modyfikowano sieci. Zaufany proxy nadal
  **172.26.0.4**, potwierdzony w API.

## Rollback — zachowane obrazy

Każde repozytorium ma tag **`rollback-before-1.1.0-3-20260913T081840Z`**:

| Repozytorium | Stary ID |
| --- | --- |
| `fit-api` | `sha256:ccf4611af6b34726e5f64ed0f681c77eced3affa16c2c381b5c0e42d88bff2c3` |
| `fit-web` | `sha256:d4c4ae779682a20d471dae49ec1381c96de5afdcee932494eb8e52e6ca25771c` |
| `fit-migration` | `sha256:964e488f12bec71b7ce95212db90bf6096bee5b2efcf1201fa0e54cb25b2daac` |

Nie wykonano rollbacku. W razie potrzeby najpierw ocenić zgodność starej aplikacji
z addytywnym schematem 0008 i bieżącymi danymi. Przy cofaniu aplikacji promować
zgodne stare API i web razem, aktualizując również sender z tego samego API,
wyłącznie przez oba pliki Compose i celowane `up --no-deps --no-build --wait`.
**Nie wykonywać Alembic downgrade ani automatycznie uruchamiać starego migratora
na 0008.** Stary tag migratora zachowano do odzyskiwania, nie do cofania schematu.
Odtworzenie produkcyjnej bazy wymaga osobnej procedury awaryjnej, zabezpieczenia
nowszych zapisów i świadomej decyzji; powyższy prebackup jest zweryfikowaną bazą
odzyskiwania, nie poleceniem nadpisania produkcji.

## Ograniczenia i ostrzeżenia

- Rzeczywisty iPhone/Skrót oraz aktualizacja starych kart Safari pozostają
  ręczną bramką. Kroki są ręcznie potwierdzonym totalem, nie automatyczną
  deduplikacją HealthKit. Nie utworzono pliku `.shortcut` ani linku iCloud.
- Nie logowano się, nie odczytywano sekretów logowania, nie tworzono tokenu
  zdrowotnego i nie importowano danych. Nie zmieniano haseł, VAPID, sesji,
  subskrypcji push ani danych domenowych. Nie uruchamiano browser-smoke.
- Istniejące ostrzeżenie opcjonalnego Dart-Wasm o flutter_secure_storage_web
  nie blokuje wybranego buildu JS + CanvasKit/SQLite Wasm. Istniejąca podwójna
  deklaracja MIME wasm w Nginx daje warning, lecz konfiguracja i MIME są poprawne.
- Diagnostyczny skrypt początkowo sprawdził nieistniejący `/push/sw.js` (404);
  poprawiono wyłącznie adres kontroli na istniejący `/push/push-worker.js` (200).
  Nie była potrzebna zmiana aplikacji ani konfiguracji.
- Brak Pushover nie został zmieniony; weryfikowano istniejący sender PWA.
