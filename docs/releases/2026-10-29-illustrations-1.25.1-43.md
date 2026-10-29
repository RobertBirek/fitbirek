# Web 1.25.1+43 — komplet431 ilustracji

Wdrożono **2026-10-29**: web start **10:00:33 UTC**, publiczny audyt
**10:01:22 UTC**, zakończenie **10:01:34 UTC**. Sesja nadrzędna niezależnie
sprawdziła wszystkie pliki ponownie **10:03:34 UTC**.
Źródło artefaktu: clean pushed `main`
`073e11d06272b067f50380abea9f3417fe6dc659`.
Dokumentacja wdrożenia jest późniejszym commitem, niewymagającym nowego builda.

## Zakres

- Dodano siedem gotowych ilustracji `cw425–cw431` z osobnej sesji.
  Niezależnie obejrzano każdy obraz i porównano z rzeczywistą instrukcją PL:
  **7 PASS**. Wszystkie431 pliki mają512×512; stare424 zachowane bajtowo.
- Rejestr zawiera431 ilustracji, zbiór oczekujących jest pusty; nowe szczegóły
  pokazują własne obrazy zamiast komunikatu pending. Testy sprawdzają dokładne
  zbiory i rzeczywiste dekodowanie wszystkich obrazów, nie samą liczebność.
- Obrazy pozostają poza CORE; przygotowanie całego pakietu offline nadal
  wymaga zgody użytkownika. Ilustracje nie zastępują instrukcji techniki.

Nie zmieniono surowego katalogu431, metadanych, historii, backendu, sync,
Drift15, backup4, Alembic0010, zależności, Web SQLite, Compose/Caddy lub portów.
Raport pochodzenia i lokalnej integracji:
[ilustracje ćwiczeń bez obciążenia](../bodyweight-illustrations-2026-10-29-results.md).
Generacja była zakończona w osobnej sesji; ta publikacja nie wykonywała płatnych
wywołań ani ponownej generacji. Historyczne opisy pending w raportach1.25.0
odnoszą się do ówczesnego, nie obecnego stanu.

## Obrazy produkcyjne

Web — finalny **Nginx runtime**, nie Flutter builder/release:
`sha256:59f9707f99938c6df95932210aad3d7106fbe0c0eed119014c92e3f5ddd3cbd7`.
OCI revision073e11d, version1.25.1+43. Candidate:
`fit-web:candidate-bodyweight-illustrations-1.25.1-43-073e11d`.

API/sender pozostają1.25.0+42, bez restartu:
`sha256:31c9eefd55b35d4adfed27d175007ceddcfaa0899c3346d2b1fa018d0e3be331`.
Migrator bez zmiany/promocji:
`sha256:90923a80ad5aa1929bc36058d7816aadf0f7746528abbdd1f488cd0b173c1fdb`.

## Backup, restore i przełączenie

Świeży chroniony bundle:
`/docker/fit/data/backups/20261029T095947170085Z`.
Dump SHA256:
`9d1ee0bb303404edef042069a65a9ec2618beae266d9f39eac7e20bd894b1a26`.
Checksum, root0700/0600, revision0010, sourceSHA/dirtyfalse i dotychczasowe
actual API/migrationIDs w manifest: PASS. WebactualID zachowano osobno.
To nowy backup obecnego środowiska, nie ponowne użycie backupu częściowej próby1.25.

Izolowane odtworzenie **obecnym** migratorem PASS; `fit_restore` usunięta.
Nie było produkcyjnej migracji/no-op/DDL, zmiany tagu migratora ani restore
produkcji. Standardowy flock900 i retencja35 pozostają bez zmian.

Po bramkach build/backup/restore promowano wyłącznie web. Compose base+push+mentor
`config --quiet` PASS; targeted `up -d --no-deps --no-build --wait
--wait-timeout 180 web`. Brak globalnego `up`, restartu API/sendera/PG/Caddy,
instalacji niezmienionych szablonów lub zmiany proxy trust.

Porównano50 pozostałych kontenerów hosta: ID, obrazy, starty i sieci zachowane.
API/sender mają dotychczasowe ID i świeży heartbeat, dane/schemat/indeksy/
constraints/syncoperations/changes/config/trust/ingress bez różnic.
Wszystkie29 bieżących hostów, w tym oryginalne28 i niezależny sober, bez zmian;
prywatny baseline29 bez nadpisania historycznego runtimebaseline28.

## Weryfikacja

- Przygotowanie wersji: **59 Flutter PASS**, analyze bez uwag, format zmienionych
  plików bez dalszych zmian; nie generowano ponownie deklaracji danych.
- Stary Python guard całego katalogu424 dostosowano do dokładnego zbioru431,
  zachowując przypiętą ochronę wszystkich424 dawnych blobów i ścieżek.
  TDD assertion RED → focused1PASS → **102 Python PASS /0 skip**.
- Finalny standardowy Dockerfile: codegen, analyze oraz **1812 Flutter PASS /
  1 warunkowy UTC skip**. Oddzielny Warsaw DST **1 PASS /0 skip**.
  **21/21** kontrolowanych generated/lock/SQLite identycznych ze źródłem.
- Standardowy release Web i generator offline PASS. Izolowany rzeczywisty
  finalny Nginx healthy, bez hostowych portów; lokalny pakiet i HTTP PASS.
- Produkcja: **508/508 SHA256 i długości**, **48 608 913 B**, **CORE31**.
  Wszystkie431 ilustracje poza CORE, siedem nowych HTTP200/image-webp/512×512
  i bajty identyczne ze źródłem. Parent powtórzył cały publiczny audyt.
- PackageId:
  `17a29ec70950aafa5646d55dd03acd265903f30eca1a55790ff7527476948214`.
- main.dart.js SHA256:
  `4284d50f7adac013ab5a0619545dc5f7b12d5ce9a11bd3fe9261072230552047`.
- Version1.25.1/43, UI/pubspec/OCI spójne, bez override.
  TLS/systemCA, exact worker/pushworker/SQLite/bootstrap, MIME/no-cache,
  SPA/programs i nowe karty ćwiczeń, static404/anon401/health PASS.

Backend nie zmienił się; nie powtarzano jego suite ani nie przypisywano694
historycznych PASS jako nowego przebiegu tego wydania. Również Python102 to
osobny udokumentowany przebieg przygotowania, nie drugi run w deployment.
Znane optional Wasm dry-run i duplicate-wasm MIME warnings nie blokują
wybranego JS/CanvasKit ani poprawnego publicznego MIME.

## Rollback i granice

Zachowano tagi z suffixem
`rollback-bodyweight-illustrations-1.25.1-43-20261029T095945Z` dla web/API/migratora.
Poprzedni web1.25.0+42:
`sha256:e3ea707e028226af5d36c35cdf4d20d1ce76c50c2de94e25295f3efe25959b26`.
Ewentualny rollback wyłącznie weba wymaga oceny stanu i ponownego publicznego
audytu jego501 plików; nie cofa Drift15, nie przywraca bazy ani staregoAPI1.23.
Ograniczenia zgodności starych klientów z rolami/planami/backup4 nadal obowiązują.

Nowa pełna paczka wymaga ponownego świadomego przygotowania w aplikacji.
Nie kasowano i nie zaleca się kasowania danych witryny/IndexedDB/cache/outbox/
deferred/pending. W razie starej wersji zamknąć wszystkie okna/karty Fit oraz
całkowicie przeglądarkę/PWA, potem otworzyć ten sam profil online i sprawdzić
**1.25.1+43**. Fizyczny telefon, VoiceOver i lifecycle istniejącej PWA pozostają
ręcznym odbiorem. Nie wykonano logowania, zapisów domenowych, resetów,
tokenów, testpush, płatnego AI ani odczytu bootstrap credential.

## Dowody

Prywatne0700/0600:
`/tmp/opencode/bodyweight-illustrations-release-1.25.1-43-20261029T084809Z/` —
preflight, snapshot źródła, verification/runtime, backup/restore, invariants,
report.json i `parent-independent-public-audit.json`.
Źródłowy review: `/tmp/opencode/bodyweight-illustrations-release-review.md`
i `bodyweight-illustrations-release-final-source-review.md` w tym samym `/tmp/opencode`.
Nie kopiowano sekretów lub prywatnych payloadów do repo.

Końcową kontrolę po wyczerpaniu limitu subagenta wykonała sesja nadrzędna
**10:14:22 UTC: 45 PASS /0 FAIL**. Nie przedstawiamy jej jako ukończonego
niezależnego audytu subagenta. Sprawdzono ponownie actual IDs/OCI, ciągłość
API/sendera i świeży heartbeat,50 innych kontenerów,29 hostów, domenę/schemat/
syncoperations/changes, backup checksum/uprawnienia oraz brak `fit_restore`.
Wykonano17 krytycznych GET, w tym nowe7 obrazów; wcześniejszy pełny audyt508
pozostaje odrębnym dowodem. Poprawiono tylko błąd składania warunku anon401
w zewnętrznym skrypcie audytowym; nie zmieniono produktu lub produkcji.
Dowód: `independent-postdeploy-review.json` w prywatnym katalogu wydania.
