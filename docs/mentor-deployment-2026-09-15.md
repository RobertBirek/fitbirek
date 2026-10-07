# Mentor 1.2.0+4 — wdrożenie produkcyjne

Weryfikacja na hoście: **2026-09-15 07:37:51 +02:00**, Europe/Warsaw
(05:37:51 UTC). Produkcja https://fit.birek.online pokazuje `1.2.0`, build `4`.
Wdrożono konfigurację i lokalne szyfrowanie, **nie uruchomiono providerów**.
Zatwierdzona korekta procedury rozdziela instalację od rzeczywistego użycia.
Nie wykonano commita ani resetu zastanych zmian użytkownika.

## Tożsamość i źródła

Promowano dokładnie zatwierdzone obrazy `mentor-1.2.0-4-p2`, bez nowego builda:

| Rola | SHA-256 obrazu |
| --- | --- |
| API i push-sender | `6810f3656f00e964cec708d7e7238f96c5177f26ff3f2eb73456339cc6e0d2cb` |
| Web, finalny runtime Nginx | `1500bd4121f4909f4181e2b6512b49ba755f50a78ee2656d48d36735f0b439ae` |
| Migrator | `af84d39733f79b8dc66f5b1633313b34c8154c479d2afbf4c48043b4bb58207d` |

Świeżo porównano SHA-256 plików: 38 w API oraz 50 w migratorze z aktualnym
`backend/`, w tym ledger i końcowa migracja `0009` z `subject_id`. Nginx `-t`
przeszedł; znane nieblokujące ostrzeżenie dotyczy powtórzonego MIME `wasm`.
`alembic heads` kandydata: `0009`. W skompilowanym JS potwierdzono markery
trwałego rejestru `mentor.operations.v1.`, odczytów `/api/mentor/operations`
oraz rozróżnienia stanów pending/unavailable. Nie jest to nowa kompilacja Flutter.

Chroniony manifest `/docker/fit/mentor-deployment-20260915.json` (0600)
zawiera pełne hashe zastanego drzewa, także plików untracked, ID starych i nowych
obrazów, backup oraz wyniki kontroli. Git SHA sam nie identyfikuje tego wydania.
Sprawdzono aktualny `database-backup.py`: pełny pg_dump bez wykluczania
`mentor_credentials`, automatyczne wykrywanie zainstalowanych overlayów Push
i Mentor. Zastanych poprawek backendu/backupów nie cofnięto.

## Backup, odtworzenie i migracja

Przed promocją zachowano wszystkie stare obrazy pod tagami
`fit-{api,web,migration}:rollback-pre-mentor-20260915`.
Backup wykonano, gdy tagi produkcyjne API/migratora nadal wskazywały stare obrazy:

- bundle: `/docker/fit/data/backups/20260915T053359101333Z`;
- SHA-256 dumpa: `7d6895bc7d12b0c6f81c90959d21c6245e559cf7cbc7f08c85c884d3520c4e80`;
- systemd `Result=success`, `ExecMainStatus=0`;
- manifest: rewizja `0008`, poprawne stare ID obrazów;
- uprawnienia bundle 0700, plików 0600.

Po promocji wyłącznie migratora izolowany drill odtworzył ten dump do
`fit_restore` i uruchomił migrację do head nowym obrazem. Wynik: 1 użytkownik,
10 rekordów sync, 0 niepoprawnych rekordów, kod 0; izolowaną bazę usunięto.
Następnie rzeczywista migracja pod `flock` zakończyła się kodem 0;
odczyt produkcji potwierdził `0009` i `mentor_requests.subject_id`.
Nie wykonano downgrade ani odtworzenia dumpa do produkcji.

Po migracji promowano API/web i wykonano tylko targeted `up --no-deps --no-build`
dla `web api push-sender`. API/web zdrowe; sender uruchomiony na tym samym
obrazie co API, heartbeat miał 2,95 s. PostgreSQL pozostał zdrowy i nie był
restartowany (start 2026-09-10T08:28:22.786136842Z).

## Weryfikacja bez zapisów domenowych

| Licznik | Przed | Po |
| --- | ---: | ---: |
| users | 1 | 1 |
| sync_records | 10 | 10 |
| sync_changes | 31 | 31 |
| sync_operations | 31 | 31 |
| push_subscriptions | 1 | 1 |
| push_deliveries | 1 | 1 |
| apple_health_tokens | 0 | 0 |

Mentor: credentials/settings/requests/sessions/messages = 0, włączone zgody = 0.
Domyślne wartości obu zgód w modelu obrazu API sprawdzono jako `False`.

- Publiczne `/api/health`: 200, `{"status":"ok"}`.
- `/`, `/today`, `/today/classic`, `/version.json` i sprawdzane assety: 200.
- `/api/mentor/settings`, `/operations`, `/sessions`: anonimowo 401 i `no-store`.
- Publiczne SHA-256 zgodne z obrazem:
  - `main.dart.js`: `fec5257ae9dba723b644faeb790cecc5456983408d3326307b2936d8b2866695`;
  - `mentor_voice.js`: `8882beb07dd130ed38b03ec004a98a9b4abad22ce1babcfacad733e41e62b747`;
  - `sqlite3.wasm`: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`;
  - `drift_worker.dart.js`: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`.
- Brak publikowanych portów Fit. Nie zmieniano sieci, Caddy, adresu zaufanego
  proxy, VAPID, tokenów ani konfiguracji wspólnego Restic.
- Nie logowano się, nie tworzono rozmów/propozycji, nie wykonywano importów
  Apple Zdrowie, testów OpenAI/ElevenLabs ani odświeżania głosów.

Ponownie wykorzystano wyniki P2 z raportu wydania: backend 267, Flutter 334,
voice JS 9, push JS 9, browser/tools 12 oraz analyze bez problemów. Nie
uruchamiano tych pełnych zestawów ponownie. Świeże kontrole obejmowały powyższe
testy operacyjne, trzy guardy backup/restore, `config --quiet`, `git diff --check`.

## Klucz i bramy nadal oczekujące

Klucz Fernet utworzono wyłącznie w `/var/lib/fit-mentor-secrets/master.key`
przez exclusive create; istniejącego pliku nie nadpisywano. UID:GID obrazu
sprawdzono w izolacji: **100:101**. Katalog root:root 0700, plik 100:101 0400.
Klucz zamontowany tylko do API. Test encrypt/decrypt sztucznego tekstu w pamięci
przeszedł jako nie-root zarówno w izolacji bez sieci, jak i w uruchomionym API.
Nie wypisano klucza ani szyfrogramu. Storage ready oznacza tylko szyfrowanie.

**Escrow poza hostem: OCZEKUJE.** Nie wykonano ani nie deklaruje się niezależnego
backupowania klucza. Nie skopiowano go do innego miejsca na hoście ani poza host.
Klucz nie jest objęty obecnym Restic. **Przed zapisaniem wartościowych kluczy
providerów użytkownik/operator musi osobno zabezpieczyć oryginalny master key
w szyfrowanym backupie poza hostem i zweryfikować odzyskanie.**

Przed rzeczywistym użyciem nadal wymagane są ocena umów/regionu/retencji,
świadome zgody tekst/głos, akceptacja docelowego mikrofonu/odtwarzania
(zwłaszcza Safari/iPhone/PWA), procedura retencji/rotacji i jawne testy providerów.
Nie oznaczono tych bram jako ukończonych. Model i głos nie są jeszcze aktywne.

Po zabezpieczeniu recovery i ukończeniu bram: Ustawienia → Mentor, wprowadzić
własne klucze OpenAI/ElevenLabs, wybrać model/głos i świadomie ustawić odrębne
zgody. Test połączenia i odświeżanie głosów są ręczne i mogą być płatne.
Do tego czasu pozostawić zgody wyłączone i klucze puste. Klasyczny widok działa
pod `/today/classic`.

## Komendy operacyjne i rollback

Wszystkie dalsze operacje Compose używają trzech plików:

```bash
docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
flock -w 900 /run/lock/fit-backup-restore.lock docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml run --rm --no-deps -T migrate
docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml up -d --no-deps --no-build --wait --wait-timeout 180 web api push-sender
```

Rollback aplikacji, wyłącznie w razie zatwierdzonej potrzeby: zachować aktualny
stan i wykonać świeży backup, sprawdzić zgodność starszej aplikacji z addytywnym
schematem `0009`, następnie przywrócić tagi API/web z zachowanych obrazów:

```bash
docker tag fit-api:rollback-pre-mentor-20260915 fit-api:production
docker tag fit-web:rollback-pre-mentor-20260915 fit-web:production
docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml up -d --no-deps --no-build --wait --wait-timeout 180 web api push-sender
```

**Pozostawić migrator P2 i schemat `0009`.** Stary tag migratora zachowano jako
artefakt historyczny, nie należy go promować ani uruchamiać na `0009`. Nie
wykonywać downgrade, nie usuwać danych ani automatycznie przywracać dumpa `0008`
do produkcji. Pełne odtworzenie to osobna zatwierdzona procedura DR z ochroną
bieżących danych, izolowanym sprawdzeniem i migracją nowym migratorem.
