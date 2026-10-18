# 1.15.0+28 — blokada niezgodnego współdzielonego schematu

## Granica wyniku

Poprawka źródeł klienta, bez nowego builda web, deployu lub powtórnej akceptacji
dwóch skompilowanych wydań. Historyczny raport
`release-1.15.0-28-browser-acceptance-2026-10-18.md` pozostaje **FAIL**.
Release nadal wymaga retestu. Wersja pozostaje **1.15.0+28**.

## Potwierdzona przyczyna w Drift 2.28.2

Zbadano kod dokładnej zależności z lockfile, nie nowszą dokumentację:

- `src/remote/client_impl.dart:165–175`: klient wysyła
  `EnsureOpen(user.schemaVersion)` i zapamiętuje wynik.
- `src/remote/server_impl.dart:135–142`: serwer przekazuje nowy numer do
  istniejącego executora. `_knownSchemaVersion` to metadane protokołu,
  **nie** odczyt `PRAGMA user_version` ani wymuszenie migracji.
- `src/runtime/executor/helpers/engines.dart:452–518`: jeśli delegate jest już
  otwarty, `ensureOpen` zwraca `true` (466–470), pomijając `_runMigrations`,
  `beforeOpen` i callback nowego subskrybenta.
- `src/remote/server_impl.dart:188–192` i
  `src/remote/client_impl.dart:261–289`: exclusive executor szereguje dostęp,
  ale nie oferuje ponownej konfiguracji migracji otwartego serwera. Nie ma
  uzgodnienia ze starym writerem. Ręczne odtworzenie callbacku z wymyślonym
  `OpeningDetails` nie jest tutaj bezpiecznym kontraktem migracji.
- `src/web/wasm_setup/shared.dart:243–272,394–408`: serwer jest współdzielony
  po nazwie bazy. Zakończenie wszystkich kanałów RPC obserwowane przez serwer
  usuwa go z mapy i zamyka executor. Nie jest to jednak gwarancja wykrycia
  zamknięcia karty ani zakończenia SharedWorkera. Odrzucony nowy klient odłącza
  **swój** kanał, ale nie może obiecać recovery po zamknięciu tylko starej karty.

SHA256 zbadanych plików porównano z zainstalowanym pakietem w kontenerze testowym:

```text
client_impl.dart  8f487b73ccea8f7e3bd4b1186a925872a04fc01ae6d770ceafeabac77ee61e69
server_impl.dart  2cbff0b97f5f14ff8b9cdd71c94c5396ad870724a32deab815fa258688f75816
engines.dart      ddd53bb1c3099346c8ef8e9b64d082b381b55d604215c66d6a781f83b1da3ad5
```

## Wybrany kontrakt fail-closed

1. `guardDatabaseSchema` na obu konstruktorach `AppDatabase` pozwala Drift
   wykonać normalne pierwsze otwarcie/migrację, następnie **odczytuje rzeczywiste**
   `PRAGMA user_version`. Wymaga dokładnej zgodności, nie `>=`.
2. Nowsza baza jest odrzucana również **przed** wywołaniem callbacku migracji,
   aby Drift nie oznaczył jej numerem starszego klienta. Błąd
   `DatabaseSchemaMismatch` niesie `actual` i `expected`, również przez RPC.
3. Sprawdzenie blokuje pierwsze zapytania, zapisy, batch i transaction, nie tylko
   ekran harmonogramu. Normalne migracje nie zostały zmienione. Wrapper zachowuje
   `DatabaseConnection.streamQueries`, w tym zdalne unieważnienie odczytu konta.
4. `databaseReadyProvider` otwiera bazę przed zbudowaniem routera, auth, seed,
   sync i całego właściwego UI. Przy błędzie czeka na zamknięcie własnego DB,
   dopiero potem pokazuje możliwość ponowienia.
5. `DatabaseBootstrap` pokazuje pełnoekranową blokadę. Dla starszej bazy prosi
   o zamknięcie **wszystkich** kart/okien FitBirek, **także bieżącego**, pełne
   zamknięcie zainstalowanej aplikacji PWA i ponowne otwarcie aplikacji.
   Dla przyszłej wersji wymaga aktualnego klienta. Inne błędy otwarcia również
   nie prowadzą do onboardingu lub aplikacji.
6. „Spróbuj ponownie” unieważnia `appDatabaseProvider`: nowa instancja otwiera
   **nowy kanał**, niekoniecznie nowy serwer/worker, do tej samej bazy. Jest to
   opcjonalne sprawdzenie zgodności, bez gwarancji recovery. Przy nadal
   niezgodnym schemacie blokuje i wskazuje pełne zamknięcie FitBirek.
   Nie ma automatycznego pollingu, zmiany nazwy DB, czyszczenia storage,
   resetu konta, outboxa, wymuszania shutdown/terminateAll ani ALTER w aplikacji.

Po udanym sprawdzeniu kolejne `ensureOpen` nadal delegują do Drift, zamiast
oddawać wiecznie ten sam ukończony Future. Pierwszy pełny przebieg ujawnił
regresję przekraczania stref `testWidgets`/`runAsync` przy cache'owaniu również
udanego Future (warianty/interwały). Po ograniczeniu współdzielenia wyniku do
otwarcia/odrzucenia istniejące testy przechodzą bez ich edycji.

## Testy i dowody

Nowe pliki testowe:

- `test/core/database/shared_schema_fixture.dart`: poprzedni klient 12 i licznik
  migracji, rzeczywisty `DriftServer`, serializowane kanały RPC.
- `test/core/database/shared_schema_gate_test.dart`: stary otwarty serwer 12
  odrzuca klienta 13 i zapis/batch/transaction; stary klient działa po odłączeniu
   nowego; w kontrolowanym teście nowy serwer migruje raz (bez symulowania
   rzeczywistego cyklu życia workerów przeglądarki).
  Zachowane UUID sesji, raw payload szkicu, konto/device/offlineAccess oraz pełne
  wiersze attempted i unsent outboxa. Testowe triggery odrzucają **każdy**
  INSERT/UPDATE/DELETE outboxa — nie tylko zmianę jego końcowej treści.
  A→B→A nie przepina konta ani nie wysyła kolejki. Przyszła wersja 14 jest
  odrzucana native oraz RPC (serwer otwarty i jeszcze nieotwarty), bez downgrade.
  Zdalne powiadomienia nadal odświeżają `offlineAccess` drugiego klienta.
- `test/app/database_bootstrap_test.dart`: prawdziwe RPC12 blokuje child i nie
  tworzy auth/sync/authority; ponowienie ze starą kartą nadal blokuje. Po zamknięciu
  starego klienta zachowany serwer12 nadal blokuje; test wymaga instrukcji pełnego
  zamknięcia także bieżącej karty i PWA. Osobna kontrola z nowym serwerem daje13,
  dopiero wtedy child; nie dowodzi ona browser recovery przez sam Retry. Osobno
  właściwy `FitBirekApp` nie tworzy routera po błędzie DB.

TDD: pierwsze trzy reprodukcje dały **3 FAIL** (nowy klient dopuszczał bazę12,
także przed odrzuceniem przyszłej14). Test całej aplikacji dał RED na przedwczesnym
uruchomieniu routera. Końcowo **8 nowych testów PASS**, pełny Flutter
**821 PASS / 0 FAIL** (813 istniejących + 8), analyze **No issues found**.
Flutter **3.35.4**, Dart **3.9.2**. Istniejące debug warnings Drift o wielu
instancjach w testach RPC pozostały niewyciszone.

Logi w `/tmp/opencode/`:

```text
schema-gate-red.log
schema-bootstrap-red.log
schema-gate-focused-final.log
schema-gate-workout-check2.log
schema-gate-full-final.log
schema-gate-analyze-final.log
```

`generate_app_version --check`, format zmienionych Dart oraz `git diff --check`
przechodzą. Nie zmieniono deklaracji Drift/Freezed/JSON: generator niepotrzebny.
Nie zmieniono generated files, dependencies, lockfile ani artefaktów Web SQLite.
Hashe nadal zgodne z udokumentowanym zestawem sqlite3 **2.9.4** / Drift **2.28.2**:

```text
sqlite3.wasm         922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117
drift_worker.dart.js 6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610
```

## API / kontrakt dla retestu browserowego

Nie dodano globalnego JS ani endpointu diagnostycznego zapisującego dane.
Publiczna granica Dart: `databaseReadyProvider` (`AsyncValue<void>`) i błąd
`DatabaseSchemaMismatch.actual/expected`; retry to
`ref.invalidate(appDatabaseProvider)`. Gotowość oznacza sprawdzony schemat,
**nie** powodzenie logowania/synchronizacji lub gotowość pakietu offline.

Retest rzeczywistych dwóch buildów:

1. Pozostawić stary compiled1.14 z niepustym outboxem i trwałą sesją/szkicem;
   nowa karta ładuje poprawne main1.15. Oczekiwany wynik: **EXPLICIT BLOCK**,
   nie PASS migracji13. Tekst `Schemat bazy: 12; wymagany: 13.`, instrukcja
   zamknięcia **wszystkich kart, także bieżącej**, i całej PWA; przycisk
   `Spróbuj ponownie` opisany jako opcjonalne sprawdzenie, nie restart połączenia.
   Brak właściwego UI,
   auth bootstrap/push/pull z nowej karty; deep link nie omija blokady.
2. Ponowienie przy starej karcie nadal daje blokadę i wersję12. Stara karta
   nie jest zabijana; może niezależnie działać/synchronizować. Jej ACK nie jest
   dowodem migracji ani działania nowej karty.
3. Utrzymać API niedostępne do czasu dowodu zachowania niepustego outboxa przed
   ACK. Zamknąć normalnie **wszystkie karty i okna FitBirek, także nową zablokowaną
   kartę**, oraz całkowicie PWA. Otworzyć aplikację ponownie na **tym samym
   trwałym profilu przeglądarki**, bez kasowania danych, unregister lub wymuszania
   workerów. Jeśli konieczny jest zwykły restart przeglądarki jako czynność
   użytkownika, odnotować go osobno. Dopiero rzeczywiste13 i obecna kolumna
   `weekly_schedule_json` pozwalają wejść dalej. Przy nadal12 wynik pozostaje FAIL.
4. Osobno dowieść zachowania nonempty attempted/unsent outboxa przez migrację,
   UUID i payloadów/checkpointu, a następnie rzeczywistego ACK bez duplikatów.
   Powtórzyć A→B→A, cold/offline i przyszły schemat w izolowanej akceptacji.

To kontrakt bezpiecznej blokady przy starej karcie, **nie** deklaracja możliwości
migracji współbieżnej ze starym writerem ani zamknięcie release gate.

## Review MEDIUM — bezpośredni executor (uzupełnienie)

Pierwsza implementacja chroniła `ensureOpen` głównego executora i API
`AppDatabase`, lecz `QueryInterceptor` domyślnie deleguje surowe `run*` bez
`ensureOpen`. Zagnieżdżony `ensureOpen` również nie sprawdzał odrzucenia głównego
połączenia. Przy nadal otwartym kanale RPC12 caller korzystający z
`db.executor` mógł więc ominąć odmowę. Wcześniejsze 821 testów tego nie dowodziło.

Minimalne uzupełnienie pozostaje w `lib/core/database/schema_gate.dart`:

- `_requireVerified` wymaga potwierdzonego schematu i ponownie rzuca zapamiętany
  błąd wraz ze stacktrace po odrzuceniu. Ochrona nie zależy od późniejszego
  zamknięcia kanału przez bootstrap.
- Sprawdzenie obejmuje `runSelect`, `runCustom`, `runInsert`, `runUpdate`,
  `runDelete`, `runBatched`, `beginTransaction`, `beginExclusive` i zagnieżdżony
  `ensureOpen`. Zamknięcie i rollback pozostają dostępne do cleanupu.
- Brak globalnej flagi „trwa migracja, pozwól callerom pisać”. DDL migracji
  korzysta wyłącznie z oddzielnego executora `beforeOpen`, przekazanego przez
  Drift do callbacku. Publiczny wrapper nadal odmawia podczas tego callbacku.
- Nie zmieniono bootstrapu, routera, deklaracji DB ani migracji produkcyjnych.

Nowy `test/core/database/raw_schema_gate_test.dart`: **19 testów**. Macierz
RPC12/RPC14 sprawdza wszystkie surowe wywołania po odmowie **przed `db.close`**,
w tym transakcję/exclusive z `ensureOpen` i próbą zapisu. Dodatkowe przypadki
native/RPC przyszłej14 wymagają tego samego zapamiętanego błędu dla wszystkich
operacji, bez downgrade lub utworzenia tabel. Zatrzymany callback migracji
odmawia równoległym surowym callerom, po czym legalnie wykonuje createAll oraz
transakcyjny DDL przez scoped executor; po otwarciu13 zwykła surowa transakcja
zapisuje poprawnie.

TDD: pierwsze **17 reprodukcji RED** potwierdziło obejście; następnie GREEN.
Końcowo focused raw/shared/bootstrap **27 PASS**, pełny Flutter
**840 PASS / 0 FAIL** (821 poprzednich + 19 nowych), analyze **No issues found**.
Format, version check i diff check poprawne. Logi `/tmp/opencode/`:

```text
raw-schema-review-red.log
raw-schema-review-focused.log
raw-schema-review-analyze.log
raw-schema-review-full.log
```

W tej poprawce review nie wykonano runtime builda, commit/push/deploy, zmian
wersji, deklaracji DB, generatora, zależności lub artefaktów Web SQLite.
Kandydat zbudowany przed tą poprawką wymaga **ponownego builda i retestu**;
wcześniejszego obrazu nie należy traktować jako zawierającego to uzupełnienie.

## Korekta recovery po compiled retest 10:22–10:31 UTC

LATEST w `release-1.15.0-28-browser-acceptance-2026-10-18.md` oraz dowody w
`/tmp/opencode/schema-gate-rollout-20261018-f6a82c/` potwierdzają **FAIL** poprzedniej
obietnicy „zamknij inne karty, potem Retry”. Po zamknięciu jedynej starej karty
i dwóch ponowieniach (pierwsze z obserwacją60s) nowa zablokowana karta nadal
widziała12. Blokada i ochrona danych są osobnymi PASS: brak nowych auth/sync,
outbox/session/draft i pełny snapshot identyczne (`15-final-pending-row-comparison.json`).

W źródle Drift2.28.2 potwierdzono rozdzielenie cyklu życia RPC i workera:

- `src/remote/client_impl.dart:179–193`: `close()` w trybie współdzielonym
  zamyka tylko kanał; nie wysyła `terminateAll`.
- `src/web/wasm_setup.dart:305–330`: połączenie RPC powstaje bez
  `singleClientMode`; wcześniej `_probeShared` (136–149) zestawia osobny port
  inicjalizacyjny do SharedWorkera.
- `src/web/channel_new.dart:23–29,66–72`: explicit close odłącza port RPC, ale
  źródło wprost ostrzega, że nie ma niezawodnego zdarzenia zamknięcia kanału
  wskutek zamknięcia karty/workera.
- `src/web/wasm_setup/shared_worker.dart:29–55,86`: port inicjalizacyjny i
  współdzielony dedicated worker są osobnymi obiektami od przekazanego RPC portu.

To potwierdza brak gwarancji nowego serwera po samym `db.close`/Retry. Nie dowodzi
dokładnej przyczyny utrzymania każdego kanału w tym konkretnym browser trace;
obecność targetów workera nie jest sama w sobie dowodem wycieku. Nie dodano
heurystyk, timeoutów, wymuszania shutdown ani zmian guardów.

Aktualna polityka UI mówi wprost: **„Zamknij wszystkie karty i okna FitBirek,
także to, i otwórz aplikację ponownie”**, z pełnym zamknięciem PWA. Retry zostaje
opcjonalnym sprawdzeniem, bez obietnicy restartu współdzielonego połączenia.
Historyczny FAIL nie został zmieniony w PASS. Poprzedni cold start po zamknięciu
wszystkich kart dawał13 na wcześniejszym obrazie, ale nowy build nadal wymaga
rzeczywistego retestu z **niepustym outboxem przez udaną migrację przed ACK**.

Test TDD UI: RED na brakującej instrukcji → GREEN z instrukcją pełnego zamknięcia,
brakiem tekstu „zamknij inne, potem Retry” i utrzymaną blokadą/auth-off po zamknięciu
starego klienta, jeśli serwer12 przetrwał. Logi `/tmp/opencode/full-exit-policy-*.log`.
Focused bootstrap/shared/raw: **27 PASS / 0 FAIL**; analyze **No issues found**;
format, version-check i diff-check poprawne. Pełne **840 PASS** z poprzedniego
review pozostaje wynikiem historycznym — tej pełnej suity nie ponawiano dla
zmiany instrukcji UI. Ta korekta nie zmienia logiki guardów, DB lub sync
i nie wykonuje runtime builda. Komentarz `databaseReadyProvider` również nie
obiecuje już zakończenia workera po samym zamknięciu kanału RPC.
