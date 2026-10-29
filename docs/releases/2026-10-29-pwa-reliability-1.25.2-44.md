# Web1.25.2+44 — niezawodność PWA i timerów

Wdrożono **2026-10-29**: Web start **15:46:56 UTC**, publiczny pełny audyt
**15:47:47 UTC**, koniec **15:47:59 UTC**. Drugi pełny read-only audyt sesji
nadrzędnej **15:48:26 UTC**. Źródło czystego, opublikowanego obrazu:
`e1f64ee7be92f9d9ada3d0966a1e73a93be63683` na `main`.
Dokumentacja wdrożenia jest późniejszym commitem i nie wymaga nowego obrazu.

## Zakres i zgoda

Użytkownik zatwierdził scalenie, publikację i wdrożenie wyłącznie Web,
następnie polecił dokończyć po limicie dwóch subagentów release. Scalono
fast-forward bez konfliktów i opublikowano `main`; podbito patch1.25.2+44,
wersja UI i metadane pochodzą wyłącznie z pubspec/generatora, bez override.

- Dedykowana informacja `error/reloadRequired` w istniejącym Trybie offline.
  Brak automatycznego reloadu, zgody na pobieranie lub czyszczenia danych.
  Pasywny status nie inicjuje synchronizacji ani nie ukrywa pending.
- Jeden czasowy target guidancev2:1–5400s, także checkpoint, archiwum i recovery
  lub restart odcinka; manual/EXTRA/v1 nadal do3600s. `seconds` jest pomiarem,
  `workSeconds` estymacją. Zapis nadal wymaga jawnego potwierdzenia.
- Wersjonowany prepromotion checker rzeczywistych obrazów API/migratora pod
  UID100:101 i65532:65532; instrukcja wymaga4/4PASS i dokładnych immutableIDs.
  To wydanie **nie** przebudowuje ani nie promuje backendu.

Nie zmieniono katalogu431,431 ilustracji, zależności/locka, Web SQLite,
Drift15, backup4, Alembic0010, backendu domenowego, wire, Compose/Caddy,
proxy trust, portów lub sieci. Bez ponownej generacji ilustracji.
Szczegóły funkcjonalne i wcześniejszy niezależny review:
[raport niezawodności](../reports/2026-10-29-pwa-reliability.md).

## Artefakty

Finalny **Nginx runtime**, nie Flutter builder/release:
`sha256:780ba53d67fc1b51f47e9ba2cca5647e07221d8335be0f398869e727661db29d`.
Candidate: `fit-web:candidate-pwa-reliability-1.25.2-44-e1f64ee`.
OCI revision jest pełnym SHA źródła, version1.25.2+44.

Verification:
`sha256:1ac5fd77242bf144c199dbe991b0634da8889c17439b1d9ab8287b0f4ffda24a`.
PackageId:
`8c92c0f04b6a330aef375155c273e7a47df4029c7242c8f94a2578249ac58de1`.
main.dart.js SHA256:
`d967206ceaa24a901573d237725999011e8dce07c3f61c4823dbec1c2e24046b`.
Pakiet: **508 plików,48 611 881 bajtów,CORE31**. Wszystkie431 ilustracje
512×512 identyczne ze źródłem, w `assets/assets/exercises/`, poza CORE.

API/sender pozostają1.25.0+42:
`sha256:31c9eefd55b35d4adfed27d175007ceddcfaa0899c3346d2b1fa018d0e3be331`.
Migrator pozostaje:
`sha256:90923a80ad5aa1929bc36058d7816aadf0f7746528abbdd1f488cd0b173c1fdb`.
Nowy checker wykonał na tych niezmienionych obrazach **4/4PASS**, bez sieci,
sekretów, mounts, pull, portów i rootfs writes;43 moduły app w każdej próbie.

## Bramki wydania

- Niezmieniony standardowy Dockerfile: czysty snapshot `git archive` źródła,
  codegen, pełny analyze **No issues found**, **1841 Flutter PASS /1 UTC DST skip**.
  Osobny rzeczywiście wykonany Warsaw DST: **1PASS /0skip**.
- **21/21** generowanych/wersjonowanych plików, lock i para Web SQLite identyczne
  ze źródłem. Przypięte Flutter3.35.4/Dart3.9.2, bez upgrade lub edycji Dockerfile.
- Standardowy runtime zależny od verification; build Web+offlinegenerator PASS.
  Izolowany Nginx bez hostowych portów: healthy, `nginx -t`, pełne **508/508**
  HTTP200/hash/length/no-cache, worker/version/SQLite/push, MIME, SPA i static404 PASS.
- Nowy compiled browser390×844/touch na loopback: UI utworzyło target4000s
  przy estymacji36, timer wystartował1/1 bez edycji pracy; po pełnym zamknięciu
  Chromium wrócił w pauzie. Widoczna wersja1.25.2+44 i SHA pobranego JS zgodne.
- Panel reloadRequired sprawdzono z **kontrolowaną odpowiedzią bridge**, nie
  udawanym produkcyjnym wdrożeniem A→B. Pending3 widoczne, rawmessage/retry
  niewidoczne, ręczny refresh wykonał tylko1status, prepare0/cancel0.
- Odczyt kopii SQLite po zamknięciu przeglądarki: integrity ok,431 ćwiczeń,
  1sesja,0serii/PR/performed,3pending i checkpoint4000/rounds1/paused.
  Bez seedowania/SQL edits. Syntetyczne konto, wszystkie API writes i sieć
  zewnętrzna abortowane; nie jest to dowód synchronizacji/ACK.

Pełny formatter nadal zgłasza9 odziedziczonych plików poza zakresem, wymienionych
w raporcie funkcjonalnym; zmienione pliki sformatowane. Nie nazywamy tego globalnym
PASS formatowania. Istniejące ostrzeżenia optional Wasm dry-run i duplicate-wasm
MIME nie blokują wybranego JS/CanvasKit ani poprawnego rzeczywistego HTTP MIME.
Backend i Python/Node suite nie były ponawiane w tym release; wcześniejsze
wyniki funkcjonalne mają osobne dowody, nie są przedstawiane jako nowy run.

## Backup, restore i przełączenie

Nowy chroniony bundle:
`/docker/fit/data/backups/20261029T154625094819Z`.
Dump SHA256:
`6040b35c063181fbdb598d9511c6ef6e5811af802b7329b2149e692749c43ed5`.
`fit-backup.service`: Result=success,ExecMainStatus0; standardowy flock900,
retencja35, root0700/0600, checksum i manifest cleanSHA/currentAPI/MIG/0010 PASS.

Próba odtworzenia **obecnym migratorem** PASS: users1,invalid0, `fit_restore`
usunięta. Bez produkcyjnego migrate/no-op/DDL, odtwarzania produkcyjnej domeny
lub zmiany tagu migratora. Poprzednie actualIDs zachowano przed promocją.

Po backup/restore gates: base+push+mentor `config --quiet`, targeted
`up -d --no-deps --no-build --wait --wait-timeout 180 web`. Wyłącznie Web
został odtworzony. Bez instalacji niezmienionych szablonów i globalnego `up`.

Porównano **50 pozostałych kontenerów**: ID,obrazy,starty,sieci bez zmian.
API/sender mają dotychczasowe starty i świeży heartbeat; domena/operacje sync/
zmiany/constraints/indeksy/schema/config/trust/ingress bez różnic wobec świeżego
baseline. Wszystkie29 obecnych hostów zachowane; historycznego baseline28 nie
nadpisano. Zmiana liczby sesji auth od poprzedniego porannego wydania była już
obecna przed tym buildem; nie cofano normalnej aktywności użytkownika.

Publicznie **508/508** hashów i długości PASS, pełne bajty zgodne z kandydatem.
TLS/systemCA, worker/pushworker/bootstrap/SQLite/version, MIME/no-cache,
SPA,anon401,static404,health PASS. Sesja nadrzędna powtórzyła cały audyt508,
checksum/uprawnienia backupu, ciągłość usług,29hostów i brak `fit_restore`.
Po limicie subagentów jest to **self-audit kontrolera, nie niezależny review**
wdrożenia. Wcześniejszy niezależny code-review funkcji pozostaje odrębny.

## Aktualizacja i rollback

Zapisz bieżącą pracę, zakończ używanie timera, zamknij wszystkie karty/PWA
FitBirek i całkowicie przeglądarkę, potem otwórz **ten sam profil online**.
Sprawdź **1.25.2 · build44**. Nie usuwaj danych witryny, IndexedDB, cache,
outbox, deferred lub pending. Nowy pełny pakiet wymaga świadomej zgody.
Nie ma gwarancji flush po zabiciu procesu ani chmurowego recovery szkiców.

Retained rollback suffix `pwa-reliability-1.25.2-44-20261029T154623Z`
dla `fit-web`, `fit-api` i `fit-migration`. Poprzedni Web1.25.1+43:
`sha256:59f9707f99938c6df95932210aad3d7106fbe0c0eed119014c92e3f5ddd3cbd7`.
Ewentualny rollback wyłącznie Web po ocenie stanu, z ponownym audytem jego508
plików. Starszy Web nie obsługuje długich checkpointów4000–5400s; może odmówić
ich wznowienia. Nie edytować/przycinać takich danych, nie odtwarzać produkcyjnej
bazy automatycznie. Web rollback nie cofa Drift15 ani zgodności ról/backup4.

Fizyczny telefon/VoiceOver oraz rzeczywisty auth-sync/ACK pozostają osobnym
manualnym odbiorem. Nie wykonywano produkcyjnego loginu, resetu/tokenów,
odczytu bootstrap credential, zapisów domenowych, testpush lub płatnego AI.

## Dowody

Prywatny katalog0700/0600 `/tmp/opencode/pwa-release-1.25.2-44/`:
source-proof, verification/build logs,21-file codegen-match, candidate,
isolated full HTTP, browser logs/screenshots/read-only snapshot, backend UID
gate, ops preflight/snapshots, rollback, backup-proof, restore/web-up,
report.json, public-full-audit.json i controller-postdeploy-audit.json.
Bez prywatnych payloadów lub sekretów w repo. Worktree funkcjonalny zachowano.
