# API/sender i Web 1.25.0+42 — katalog, serie i programy A/B

Wdrożono **2026-10-29**. Bramka API-first **07:22:41 UTC**, start web
**07:22:43 UTC**, publiczny audyt **07:23:30 UTC**, zakończenie odbioru
**07:23:41 UTC**. Sesja nadrzędna niezależnie sprawdziła wszystkie publiczne
pliki ponownie **07:27:10 UTC**. Źródło artefaktów: clean pushed `main`
`e30707d963d65bd07e71d00a1cadeb7f69999345`.
Dokumentacja publikacji jest późniejszym commitem, bez ponownego builda.

## Zakres i dane

- Katalog431: nowe `cw425–cw431`, zachowane poprzednie424 rekordy i ilustracje.
  Siedem nowych ruchów ma jawny fallback instrukcji tekstowej, nie cudzą grafikę.
- Role rozgrzewkowa/robocza, indywidualne cele kolejnych serii, edytor,
  prowadzenie i recovery według konkretnego celu. Nowa jawna rozgrzewka nie
  tworzy PR ani dowodu progresji/trendu; historia i dawne NULL pozostają.
- Programy dwóch własnych planów A/B, ABA/BAB według zaplanowanych dat;
  wykonanie terminu wyłącznie jawnie, z dowodem zakończonej sesji roboczej.
- Backend chroni omission `setRole` i `trainingPrograms`, Mentor wyklucza
  rozgrzewki. Bez nowych typów encji i bez migracji PostgreSQL.
- Addytywny lokalny Drift14→15; eksport backup4 z importem1–3, remapowaniem
  referencji oraz zachowaniem usuniętych dowodów bez ożywiania serii.

Pełny odbiór funkcji, decyzje i ograniczenia opisuje
[raport implementacji](../reports/2026-10-29-catalog-training-programs.md).
Nie zmieniono zależności, Web SQLite, historycznych migracji, konfiguracji
Compose/Caddy, proxy trust, portów ani sieci.

## Dokładne obrazy produkcyjne

Wszystkie mają OCI version `1.25.0+42` i revision `e30707d…`.

| Rola | Actual immutable image ID |
|---|---|
| API i sender | `sha256:31c9eefd55b35d4adfed27d175007ceddcfaa0899c3346d2b1fa018d0e3be331` |
| Migrator | `sha256:90923a80ad5aa1929bc36058d7816aadf0f7746528abbdd1f488cd0b173c1fdb` |
| Web, finalny Nginx runtime | `sha256:e3ea707e028226af5d36c35cdf4d20d1ce76c50c2de94e25295f3efe25959b26` |

Candidate tagi:
`fit-api:candidate-catalog-programs-1.25.0-42-e30707d-r2`,
`fit-migration:candidate-catalog-programs-1.25.0-42-e30707d-r2`,
`fit-web:candidate-catalog-programs-1.25.0-42-e30707d`.

Standardowy niezmieniony Dockerfile Web wykonał verification, codegen, release
i generator offline przed finalnym Nginx. Nie serwujemy obrazu builder/release.
API i migrator przebudowano bez cache z tego samego źródła po błędzie metadanych
prywatnego kontekstu; manifest44 plików i43 Python zgodny ze źródłem.
Import workera i czytelność całości sprawdzono zarówno jako UID100:101,
jak i rzeczywisty UID65532:65532 sendera, bez połączeń z DB/providerem.

## Początkowy FAIL i kontrolowany roll-forward

Pierwsza próba zatrzymała się **07:05:00 UTC**: API healthy, sender w restart
loop, bo `/app/app/push` odziedziczył0700 z prywatnego kontekstu/cache.
Poprzednia walidacja jako app100 nie wykryła braku dostępu UID65532.
**Web pozostał wtedy1.24.0+41**, bez promocji i bez pozornego API-first PASS.

Nie zmieniano produkcyjnego użytkownika Compose, uprawnień sekretów ani kodu.
Świeże archiwum tego samego Git SHA z prawidłowymi katalogami0755/plikami0644
i rebuild bez cache usunęły wadę obrazu. Testy obu użytkowników przeszły.
Po drugim backupie/restore i no-op migracji wymieniono API/sendera; potwierdzono
dwa różne świeże heartbeat po nowym starcie i stabilne0 restartów. Dopiero
wtedy promowano web. Historia pierwszego FAIL pozostaje zachowana.
Późniejsza korekta trybu prywatnego pliku dowodowego0644→0600 nie zmieniała
produktu lub runtime; ledger nadrzędny cały czas miał0700.

## Backupy i migracje

Oba chronione bundle zachowano; root0700/0600, checksum i sourceSHA/clean PASS.

1. **Przed pierwszą aktualizacją**, ze starymi API1.23/migratorem:
   `/docker/fit/data/backups/20261029T070358376662Z`.
   Dump SHA256:
   `e83210bc0ada044c572cef3f02bcd5f615f132492c79e6a7d6e51fc1d5df3987`.
2. **Po częściowym pierwszym przełączeniu**, przed naprawionym kandydatem:
   `/docker/fit/data/backups/20261029T072124097940Z`.
   Dump SHA256:
   `709c189d59b26b2bf6b4488f41b5e2d78835ab135f7b07b129364aedb1b2ee7d`.
   Manifest wskazuje pierwszy API1.25 z wadliwymi metadanymi obrazu, nie stare
   API1.23. Nie przedstawiamy tego jako backupu dawnego środowiska.

Izolowane odtworzenie nowym migratorem PASS; użyto wyłącznie `fit_restore`,
która po próbie nie istnieje. Produkcyjny migrator pod flock900 wykonał
**no-op0010**, exit0, bez DDL. Pełny schemat, indeksy i constraints bez zmian.
Nie wykonano odtwarzania produkcyjnej bazy, downgrade'u ani backfillu.

## Przełączenie i niezmienniki

Użyto wszystkich overlayów: `/docker/fit/compose.yaml`, `compose.push.yaml`,
`compose.mentor.yaml`; `config --quiet` PASS, bez wypisywania sekretów.
Targeted `up -d --no-deps --no-build --wait --wait-timeout 180` najpierw
`api push-sender`, po bramce health/image/heartbeat oddzielnie `web`.

PG/Caddy nie odtwarzano ani nie restartowano. Porównano48 pozostałych
kontenerów; domena, operacje/zmiany sync, konfiguracja, trust i ingress bez zmian.
Alembic0010, invalidrecords0; agregaty podczas odbioru: records28,
operations60, changes60. Nie wykonywano zapisów domenowych testem.

Bieżący współdzielony baseline obejmuje **29 hostów**: poprzednie28 i niezależnie
dodany `sober.birek.online`200. Jawnie przyjęto prywatny baseline tego wydania;
wszystkie29 i oryginalne28 bez zmian. Nie nadpisano historycznego runtimebaseline28
ani nie przedstawiano starego checkera, zgłaszającego dodatkowy host, jako PASS.

## Weryfikacja wydania

- **1812 Flutter PASS / 1 warunkowy skip UTC**, analyze bez uwag,
  wymagany generator uruchomiony w standardowym Docker verification.
- **36 Warsaw PASS**, bez skip, z rzeczywiście wykonanym testem luki DST;
  szerszy zestaw niż33 z odbioru implementacji.
- **694 backend PASS**, bez failure/error/skip/deselected; Python3.12.3,
  hash-locked zależności, izolowany PostgreSQL16 Testcontainers, stabilny manifest.
- Finalny Nginx runtime healthy. Wasm MIME/no-cache workerów/manifestu,
  SPA w tym `/programs`, statyczne404, anon401, health i systemCA TLS PASS.
- Publiczne **501/501 SHA256 i długości**, **48 501 382 B**, CORE31.
  Sesja nadrzędna pobrała cały pakiet ponownie i porównała również z lokalnym
  kandydatem, nie wyłącznie z manifestem z internetu.
- PackageId:
  `bca77a45d948db334ae864d5789e0ad54cc22e781b44ee08ba8d5c1a80f2989e`.
- main.dart.js SHA256:
  `56d1876d765cf9efb0ddce4ec016520e8c9b514bdeda49b6805f4b216a5e0d4e`.
- Catalog431,424 dawnych ilustracji poza CORE, siedem nowych pending;
  metadata/wersja UI/package zgodne1.25.0+42, brak override.

Nie przenosimy historycznych Python/Node/browser liczb na rzekomo nowy run
wdrożeniowy. Compiled funkcjonalny UI i offline były osobno sprawdzone przed
wydaniem; ten audyt produkcji jest anonimowy/read-only.

## Aktualizacja klienta i rollback

Przed nowymi funkcjami zapisz normalnie bieżącą pracę, zamknij **wszystkie**
karty/okna FitBirek, całkowicie wyjdź z przeglądarki/PWA i otwórz online
**ten sam profil**. Sprawdź wersję1.25.0+42; powtórz na innych urządzeniach.
Nie kasuj IndexedDB, danych witryny, cache/outbox/deferred/pending i nie
resetuj konta. Retry nie zastępuje pełnego zamknięcia starego współdzielonego
połączenia SQLite. Stary JS w otwartej karcie nie aktualizuje się przez samą
aktywację nowego workera.

Stare klienty nie rozumieją warmup/schema2/programów/backup4. Ochrona omission
nie daje im poprawnego PR/progresji. Fizyczny telefon/VoiceOver i lifecycle
istniejącej produkcyjnej PWA pozostają ręcznym odbiorem; nie czyścić danych,
aby „naprawić” test. Nie wykonywano logowania, resetu hasła, tokenów, testpush
lub płatnego AI. Nie używano historycznego bootstrap credential.

Zachowano tagi `rollback-catalog-programs-1.25.0-42-20261029T070355Z` dla:

- API1.23: `sha256:873d996b8a93b95a555dac913acd6eedee557e0a6121e99b3a0c7f0b87659e0b`;
- migratora: `sha256:fede69fba5265aa69b8e5a44ecc5d7b01dffcf398442f0ef3d86a68c80a3d116`;
- web1.24: `sha256:9a78a03342ffb0f7ef2e89b44a767ca5055bb8d9cadfe323402bcdcf35bfcbf8`.

**Nie wykonywać ślepego rollbacku API po zapisaniu nowych rozszerzeń**:
stary backend nie chroni ich omission. Rollback weba nie cofa Drift15 i nie
czyni starego klienta zgodnym. Preferować poprawkę roll-forward; ewentualny
rollback wymaga odrębnej oceny stanu danych, zgodności klientów i obrazu.
Nie przywracać całej bazy ani nie obniżać Alembic/Drift automatycznie.

## Dowody

Prywatne0700/0600:
`/tmp/opencode/catalog-programs-release-1.25.0-42-20261029T064048Z/` — raport,
historia FAIL/naprawy, backup/restore/no-op, image dual-UID gates, snapshoty,
publiczny audyt i `parent-independent-public-audit.json`.
Build Web: `/tmp/opencode/catalog-programs-release-web/`.
Backend: `/tmp/opencode/catalog-programs-release-backend-report.md` i pełny log.
Żadnych sekretów, danych osobowych lub prywatnych payloadów nie kopiowano do repo.
