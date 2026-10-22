# Web1.23.1+40 — komplet424 ilustracji

Wdrożono2026-10-22. Źródło clean pushed main:
`d40943856558cc3d7ef70c1e7a28fb399f33ad5a`. Web start13:03:57.580UTC
(15:03:57 Europe/Warsaw), końcowy publiczny audyt13:04:48.708UTC.

## Zakres i obrazy

Dodano12 ilustracji cw413–cw424; 424 ćwiczenia mają424 obrazy. Poprzednie412
pozostają identyczne bajtowo. Nowy rejestr i ścisłe testy sprawdzają dokładne
zbiory katalogu/plików/manifestu oraz dekodowanie każdego WebP512×512.
Nie zmieniano katalogu, backendu, Drift, Web SQLite, zależności lub protokołu.

Web final Nginx runtime:
`sha256:db5be555a21059ebb476c5519ee1b631540a40fe6848fc0bbc8ff59bf6efc64a`.
Revision label=d409438, version label1.23.1+40. Użyto zatwierdzonego immutable
kandydata, bez ponownego builda przed publikacją. Runtime zależy od pełnego
verification; nie serwowano buildera/release.

API/sender bez zmian:
`sha256:873d996b8a93b95a555dac913acd6eedee557e0a6121e99b3a0c7f0b87659e0b`.
Migrator bez zmian:
`sha256:fede69fba5265aa69b8e5a44ecc5d7b01dffcf398442f0ef3d86a68c80a3d116`.

## Backup i bezpieczne przełączenie

Przed promocją webtagu zachowano rzeczywiste stare obrazy i wykonano standardowy
backup `/docker/fit/data/backups/20261022T130337023842Z`.
Dump SHA256 `57b7151b68c8749b23e24709d0479ad51a203d536553cb311b61c82940f840c5`.
Exit0, checksum/uprawnienia/sourceSHA/dirtyfalse/revision0010 PASS.
Isolated restore **obecnym** migratorem PASS; users/sync IDs/wersje zgodne,
`fit_restore` usunięta. Standardowe lock900 i retencja35 bez zmian; bez systemctl
i ewentualnego OnFailure push. Nie wykonywano production migrate ani DDL.

Promowano tylko web. Compose base+push+mentor `config --quiet` PASS;
targeted `up -d --no-deps --no-build --wait --wait-timeout 180 web`.
API/sender/PG/Caddy IDs, obrazy, starty i network endpoints niezmienione.
Heartbeat świeży, domena i fizyczny schemat ze wszystkimi indeksami/constraints
identyczne, konfiguracja/ingress/trust i28 współdzielonych hostów bez zmian.
Alembic0010, Drift14 i backupformat3 bez zmian.

## Testy i publiczny audyt

- Focused release35PASS:21 ilustracje/integracja katalogu i14 wersja.
- Niezależny przegląd wizualny12PASS, integracja bez P0/P1/P2.
- Dockerverification1561PASS/1UTCskip; izolowany Warsaw DST1PASS, analiza czysta.
- Backend suite nie ponawiano dla identycznego kodu; wydanie1.23 ma631PASS
  i Alembic checkPASS. Nie przypisujemy tego jako nowego przebiegu1.23.1.
- PackageId `86ceee4e7e599febce4a907cb530285d304ad6e662c40d625bc68498b905b7de`.
- **501/501 publicznych SHA256 i długości PASS**,48 364 768B; manifest bajtowo
  zgodny z wyekstrahowanym kandydatem, a424 obrazy zgodne ze źródłem.
- Osobno exact worker/pushworker, version1.23.1/40, health/TLS/systemCA,
  SPA/MIME/no-cache/static404/anon401 PASS. Parent niezależnie potwierdził
  lokalne501hashów,424 obrazy, actualimageID oraz publiczne version/health.

Ilustracje pozostają poza CORE i wymagają zgody na pełny pakiet; metadata
i korekty nadal w CORE. Nie uruchamiano pobierania pakietu na urządzeniu ani
nie kasowano IndexedDB/PWA/storage/outbox/pending. Bez loginów, domain-writing
smoke, resetów haseł, edycji profilu/subskrypcji, testpushdelivery lub nowych
wywołań płatnego AI w procedurze deploy. Bez portów/sieci/Caddy/configchanges.

## Ograniczenia i rollback

Telefon/VoiceOver i rzeczywisty cykl istniejącej PWA wymagają odbioru. Ilustracja
nie certyfikuje techniki ani nośności sprzętu. Dalsza dłoń cw421 jest zasłonięta
perspektywą, a cw424 nie dowodzi pełnego naprzemiennego cyklu chodu. Tekstowe
instrukcje pozostają konieczne. Generacja:18 żądań, górny szacunek0.425721USD;
[provenance i kontrola](../owner-equipment-illustrations-2026-10-22-results.md).

Zachowane tagi `rollback-illustrations-1.23.1-40-20261022T130335Z`, niewykorzystane.
Stary web1.23.0: `sha256:74ca4058731d8238ee7f9cec4ff6f1ce2b452d941a3669707f5527cbb1915221`;
API i migrator jak wyżej. Cofanie wyłącznie webobrazu po ocenie danych i ponowny
audyt poprzedniego pakietu489. Katalog424 ten sam; wróciłby fallback12 obrazów,
bez cofania danych. Nigdy downgrade Alembic/Drift lub restore całej produkcji.

Dowody prywatne: `/tmp/opencode/illustrations-release-1.23.1-40-20261022/`.
Ten raport jest docs-onlycommitem; runtime nadal ze źródła d409438, bez nowej
kompilacji i ponownego wdrożenia dla dokumentacji.
