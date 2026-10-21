# Task 2 — dane własnych testów sprawnościowych

## Zakres

Zaimplementowane w głównym `/opt/fit`, bez zmian presentation/router/pubspec,
backendu ani produkcji. Publiczne nazwy, konstruktory i metody pozostają zgodne
z `/tmp/opencode/custom-fitness-20261021/flutter-public-api.md`.
Nowe providery odczytu mają autoDispose: ponowne otwarcie zamkniętego ekranu może
przechwycić nową epokę, ale bieżąca subskrypcja nie zmienia konta po A→B→A.
Sposób użycia przez UI (`ref.watch`, `.future`, AsyncValue) pozostaje taki sam.

- `FitnessProtocol`, draft, enumy, defensive DTO wyniku i czyste porównanie
  surowych wartości dokładnej rewizji/niezmiennego snapshotu.
- Ścisłe daty Gregorian/UTC Z, bez normalizacji błędnego miesiąca/dnia/sekundy;
  części ułamkowe 1–6 cyfr, lata 1–9999. Nullable pola zasad mogą być pominięte;
  odczyt/porównanie normalizuje je do null, nowe JSON emituje komplet pól.
- Reps akceptuje integralne num (18 i 18.0), nie bool/fractional/NaN/Infinity.
  Wersje i timeLimitSeconds nadal wymagają int. Legacy punktacja i ograniczenia
  nie zostały przeniesione na własne testy ani przeliczone wstecz.
- Drift 13→14: wyłącznie nullable UserProfiles.fitnessProtocolsJson oraz
  FitnessTestResults.customProtocolJson, bez backfillu i nowych tabel/encji.
  Artefakty wygenerowane przez build_runner, nie edytowane ręcznie.
- Lease przechwytywany przed formularzem; epoch/account/device/offlineAccess,
  profil i baseline kontrolowane w transakcji. Guard po końcowym await wycofuje
  również już wstawiony row+outbox przy utracie lifecycle/uprawnień.
- Create/revise sprawdza istniejące ćwiczenie bez ograniczeń tracking;
  nowy wariant musi być dokładnym live wpisem. Niezmieniony historyczny snapshot
  wariantu może przejść do rewizji po archiwizacji/usunięciu wariantu.
- Rewizja jest nowym UUID w rodzinie; rodzic nie jest automatycznie archiwizowany.
  Równoległe gałęzie pozostają odrębne. Archiwizacja nie kasuje historii.
- Wynik ma jawne performedAt, zapisywane jako moment UTC, niezależnie od
  updatedAtUtc. Przyszłe próby są odrzucane; wcześniejsza data może poprzedzać
  utworzenie protokołu. Brak zapisów sesji, serii i PR.
- Profil: nowe kolekcje we wszystkich dynamicznych mapowaniach i pełnym CAS;
  osobna gałąź walidacji, zachowanie omission, blokada prune/NULL istniejących
  rewizji. Kolizja zasad tego samego UUID nie podlega arbitralnemu LWW.
- Nieczytelne wyniki zachowują raw i są oddzielone od legacy. Omission wyniku
  zachowuje customProtocol; downgrade i podmiana snapshotu są odrzucane.
  Tombstone działa także dla nieczytelnego custom JSON.
- Konflikty i nieobsługiwane kolekcje zachowują raw/deferred/hold; niezależne
  rekordy globalnego pull nadal przechodzą. Attempted request/digest nie są
  modyfikowane. Recovery pozostaje istniejącą, jawną operacją synchronizacji.
- Backup format3, czytanie1/2, stabilne UUID protokołów/rodzin i snapshoty przez
  restore także na inne konto. Nieczytelny custom marker bez snapshotu powoduje
  atomowe odrzucenie restore, nie konwersję do legacy. Stare backupy nie kasują
  istniejących definicji/tombstone'ów.

## Weryfikacja

Toolchain: Flutter3.35.4 / Dart3.9.2, kontener `fit-web:illustrations-408-verified`,
bez sieci i instalowania zależności. Logi pod `/tmp/opencode/custom-fitness-20261021/`.

- Pierwszy RED: brak nowego API; następnie rzeczywiste RED asercji sync snapshotu
  i backupu2→3. Omyłkowy względny import fixture pomocniczego poprawiono przed GREEN.
- `focused-final.log`: **22 testy PASS** (domena, repo/lease, pasywne providery,
  dwie bazy przez SyncService/CAS, utrata ACK, immutable attempted, sync/raw,
  migracja13→14, backup/restore między kontami).
- `scoped1.log`: **81 testów PASS**, obejmujące dodatkowo schema gate RPC,
  stare migracje, profile collections/quarantine, backup, restore, planner,
  guidance i historyczne health replay. W tej serii istniejące testy RPC emitują
  ostrzeżenie Drift o wielu instancjach bazy; nie jest błędem testu.
- `final-integration-focused.log`: **32 testy PASS**, obejmujące także wskazane
  przez sesję nadrzędną workout_side (v7), pr_side_roundtrip (v8), activity_cloud
  oraz database_bootstrap. Poprawione są wyłącznie oczekiwania bieżącej wersji
  14/backup3; rzeczywiste wersje historycznych fixture'ów i attempted payloady
  nie zostały osłabione. **Analiza wszystkich plików danych i tych testów: brak
  problemów.**
- Dodatkowe RED→GREEN: custom marker z brakującym snapshotem nie może stać się
  legacy (`downgrade-red.log`); mutacja zagnieżdżonego snapshotu przez callback
  kolekcji nie może zmienić bazowego porównania przez alias mapy
  (`nested-immutability-red.log`). Baseline jest ponownie dekodowany z niezmiennego
  wiersza, a podmiana zasad wycofuje transakcję.
- Szeroka seria w trakcie dodawania powyższych regresji miała tylko oczekiwane
  RED nowego testu aliasowania; wcześniejsza wykryła oczekiwanie backup2 w
  activity_cloud. Oba przypadki poprawione i potwierdzone w finalnych 32 testach.
  Końcowa szeroka seria po zamrożeniu kodu, `data-core-final.log`: **411 testów
  PASS, zero porażek**, 155 s. Obejmuje całe `test/core`, `test/features/settings`,
  `test/features/schedule`, oba nowe pliki progress, structured_plan_persistence,
  guidance_migration, health_replay_migration, health_repository oraz wszystkie
  wskazane przez sesję nadrzędną ścieżki workout_side, pr_side_roundtrip i
  database_bootstrap. Po tym przebiegu nie zmieniano kodu ani testów.
- Ostatnia regeneracja: build_runner zakończony poprawnie (148 s); brak ręcznych
  zmian plików generowanych.

SQLite/worker zachowane zgodnie z lockiem: drift2.28.2, sqlite3 2.9.4.
SHA256:

```text
sqlite3.wasm         922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117
drift_worker.dart.js 6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610
```

## Granice potwierdzenia

Nie wykonano builda runtime, testów przeglądarkowych ani testu telefonu;
integracyjna weryfikacja całej aplikacji po połączeniu UI/backend należy do
sesji nadrzędnej. Test dwóch urządzeń używa rzeczywistych baz Drift i produkcyjnego
SyncService z deterministycznym transportem testowym CAS, nie produkcyjnego HTTP.
Stary klient nie jest deklarowany jako zdolny do bezstratnego odczytu backup3.
Brak Git commit/push, deploy, zmian źródeł ćwiczeń i operacji na danych produkcji.

## Poprawka P2 po niezależnym review — CAS z późniejszą lokalną rewizją

Potwierdzono reprodukcję z `data-review.md` i `review_fitness_cas_test.dart`.
Przed poprawką własny test integracyjny dawał rzeczywisty RED permanentnego hold
oraz ujawnił usunięcie rozstrzygniętego attempted requestu przed zachowaniem
dowodów rzeczywistej kolizji (`review-cas-red.log`).

Przyczyna: dirty wiersz profilu zawiera także nieopublikowane lokalne rewizje,
więc nie jest baseline'em historii znanej serwerowi. Ich brak w rekordzie CAS
z gałęzią drugiego urządzenia nie dowodzi prune.

- `lib/core/sync/sync_store.dart:356–384`: dla dirty profilu walidowany jest pełny
  per-ID union przed kontrolą zachowania historii. Walidatory wersji/limitów,
  niezmienności reguł tego samego UUID i tombstone'ów pozostają aktywne. Nie
  zastępujemy oryginalnego remote JSON syntetycznym merge: defer zachowuje raw
  rekord serwera, a bieżący lokalny wiersz/późniejszy outbox zachowuje lokalne
  gałęzie. Następnik przechodzi przez dotychczasowy pełny CAS i dopiero nowa
  operacja zawiera scalone wpisy. Nie zmieniamy attempted payloadu/digestu ani
  nie rebazujemy go w ciemno.
- `lib/core/sync/sync_service.dart:324–348`: preflight merge dla profilu z `later`
  wykrywa rzeczywistą kolizję UUID przed usunięciem rozstrzygniętego requestu;
  zachowuje attempted, późniejszy request i remote raw w istniejącym hold.
- Czysty, wcześniej zsynchronizowany profil nadal stosuje ścisły check prune;
  usunięcie znanych opublikowanych rewizji pozostawia hold i obie strony danych.
  Dla dirty wiersza brak wpisu jest niejednoznaczny, dlatego żadnego lokalnego
  wpisu nie kasujemy: walidowany union chroni także jego wcześniejszą historię.
- Bez zmian UI/backendu, schematu, publicznego API, zależności i guardów konta.

Dowód: `test/core/custom_fitness_interleaved_cas_test.dart:31–32,192` zawiera oryginalny
przypadek review rozszerzony o zbieżność obu baz do czterech gałęzi, puste outboxy,
brak hold, niezmienność obu requestów i kontrolę oryginalnego raw defer między
dwoma CAS. Negatywne przypadki sprawdzają kolizję reguł tego samego UUID oraz
prune historii wcześniej opublikowanej i zsynchronizowanej.

`review-cas-focused-final.log`: **27 testów PASS**, analiza sync i nowego testu
bez problemów; obejmuje także dotychczasowe malformed/future collections,
prune/NULL, attempted immutable oraz profile CAS/quarantine.

Pierwszy szeroki przebieg review (`review-cas-broad-final.log`) zakończył się
417 PASS / 1 FAIL: dodany równolegle test UI `fitness_raw_axis_test` zgłaszał
zdublowaną etykietę `-12` dla skłonu. Nie zmieniano tego testu ani UI w zadaniu2.
Na bieżących źródłach niezależnego agenta UI osobny ponowny przebieg tego pliku
(`review-ui-axis-followup.log`) daje **7 PASS**.

**Końcowa świeża seria na bieżących źródłach:**
`review-cas-broad-current-final.log` — **421 testów PASS, zero porażek**, 114 s.
Obejmuje wszystkie wcześniejsze 411 testów, trzy nowe regresje CAS/prune oraz
siedem dodanych równolegle testów osi UI. Kod danych i testy regresyjne nie były
zmieniane podczas tego końcowego przebiegu; po nim uzupełniono wyłącznie raport.
