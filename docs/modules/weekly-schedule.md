# Rytm tygodnia — harmonogram zapisanych planów

## Aktywności i migracja przypomnień (2026-10-19)

Ta sama kolekcja v1 obsługuje `activityRule` / `activityOverride` obok starych
rule/override. Dokładny wire sample, walidacja sendera i obliczone przykładowe
UUID znajdują się w `backend/SYNC_EXTENSIONS.md` → „Aktywności i sender push”.
Schema Drift13/Alembic0010, zależności i Web SQLite bez zmian.

- `activity_repository.dart`: `seedLegacy(ActivitySnapshot lease, karate: bool,
  training: bool, isCurrent:)` zapisuje brakujące deterministyczne wpisy w jednej
  guarded transakcji. Używa namespace **profileSyncId**, nazw
  `FitBirek/activity/legacyKarate` / `FitBirek/activity/legacyTraining`.
  Całe entries (z tombstone'ami) to markery; nie odtwarzamy usuniętych/edytowanych
  reguł. No-op nie enqueue'uje. Istniejące attempted operacje zachowują bajty/CAS.
- Karate wt/czw20:00, lead30; trening codziennie18:00, lead0; effectiveFromDate
  1970-01-01. enabled/reminderEnabled od znanego starego opt-in, false nie staje
  się true. Stare pref keys notif_karate/notif_workout pozostają jako **native
  category consent**, nie są usuwane. Równoległy seed dwóch urządzeń scala się
  istniejącym LWW per ID, nie dodaje następnych UUID.
- `activity_migration.dart` przechwytuje konto/epoch/profil **przed HTTP**.
  PWA czyta zgodę tej instalacji przez istniejący PushClient.status, nigdy przez
  prywatny cache prefs. Nieznany/offline status nie jest false: brak zapisu
  markerów, jawny komunikat pending i ręczny retry. Stary push działa do markera.
  Sieć nie jest oczekiwana w SQLite transaction; deferred/hold/quarantine blokuje
  migrację także przy obecnych już markerach. Nie żądamy uprawnień automatycznie.
- `activity_reminder_provider.dart`: bootstrap aplikacji, zmiany profilu/sync,
  binding/offline lock, powrót aplikacji i odświeżenie co10min przeliczają adapter.
  Stan i jawny retry w Ustawieniach; kategorie opisują harmonogram. Nowe reguły
  zawsze domyślnie reminderEnabled=false, niezależnie od zgody kategorii.
- Native: **one-shot horyzont7dni**, max60 alarmów harmonogramu /64 wszystkich.
  Nie jest to bezterminowy scheduler: trzeba otworzyć aplikację co najmniej raz
  w tygodniu. Jawny błąd limitu/uprawnień/kolizji, bez cichego obcięcia listy.
  InexactAllowWhileIdle może zostać opóźnione przez system. Zmiana/wykonanie/
  przesunięcie terminu anuluje stare pending i tworzy aktualne. Nie ma weekly
  repeat, który odtworzyłby zaliczone wystąpienie. DST: luka pomijana, fold0 raz.
- Native IDs:1000+int(first7hex(UUID wystąpienia)); kolizja jest odrzucana, nie
  nadpisuje innego alarmu. Payload `activity:occurrenceUUID` umożliwia odczyt
  własnych pending IDs po restarcie. Anulujemy wyłącznie własne IDs, nigdy
  cancelAll/mood300. Stare100/101/200 kasujemy dopiero po guarded zgodnej migracji
  i udanym replanowaniu; SettingsNotifier już ich nie nakłada przy starcie.
  Logout od razu unieważnia guard i wywołuje bounded cleanup także z auth hook.
- Backend kategoriami pozostają karate/training; marker (również tombstone)
  wyłącza tylko odpowiadający stary event. Rewalidacja tuż przed wysyłką, dedup
  reguła+originalDate+pełna rewizja/czas+instalacja, TTL15min. Worker przyjmuje
  bounded plain title/body, a cel pozostaje na istniejącej allowliście same-origin.

Fizyczne dostarczenie Android/iOS i prawdziwy PWA/provider wymagają osobnej
akceptacji. Mockowane testy platformy/HTTP nie są dowodem dostarczenia.

## Pliki i granice

- `lib/features/schedule/{domain,data,providers,presentation}/` i focused testy
  `test/features/schedule/`.
- Wejście: przycisk kalendarza w istniejącym generatorze, chroniona trasa
  `/schedule`. Nie jest to drugi generator ani drugi mechanizm zapisu sesji.
- Lokalny Drift **13**, addytywna migracja **12→13**: wyłącznie nullable
  `UserProfiles.weeklyScheduleJson` / `user_profiles.weekly_schedule_json TEXT`.
  Bez backfillu, nowych tabel, `SyncEntityType`, zależności, zmian wersji aplikacji
  lub toolchainu. Pole nie trafia do publicznego Freezed `UserProfile`.
- Start używa `PlannerWorkflow.startSaved` i istniejącego aktywnego notyfikatora.
  Adapter `SavedPlan.syncId` / `getBySyncId` rozwiązuje zapisany plan ponownie
  w transakcji. Nie generuje zamiennika i nie pomija brakujących ćwiczeń.
- Nie zmienia implementacji workout, PR, progresji ani katalogu.

## Kontrakt kodeka dla backendu i innych klientów

Opcjonalne rozszerzenie istniejącego `profile.payload`:

```json
{
  "weeklySchedule": {
    "version": 1,
    "entries": [{
      "id": "11111111-1111-4111-8111-111111111111",
      "name": "Plan siłowy",
      "kind": "rule",
      "createdAtUtc": "2026-10-17T12:00:00.000Z",
      "updatedAtUtc": "2026-10-17T12:00:00.000Z",
      "planSyncId": "22222222-2222-4222-8222-222222222222",
      "weekday": 1,
      "effectiveFromDate": "2026-10-19"
    }]
  }
}
```

Wspólna koperta `UserCollections`: UUID `id`, `name` 1–80 znaków Unicode,
`createdAtUtc`, `updatedAtUtc` (UTC ISO8601 z `Z`), opcjonalny `deletedAtUtc`.
Usunięcie to tombstone wpisu; nie prune i nie NULL całej kolekcji.

`kind: rule` zawiera `planSyncId` (UUID planu), `weekday` (int ISO **1..7**),
`effectiveFromDate` (włącznie). Brak reguły przed tą datą. UI zmienia rytm przez
usunięcie reguły i dodanie nowego UUID; zakończona historia nie jest przepisywana.

Wirtualne wystąpienie identyfikuje para UUID reguły + **pierwotny** dzień.
Jego ID to standardowy **UUIDv5(namespace = rule UUID, name = YYYY-MM-DD)**.
Nie zapisujemy kolejnych tygodni kalendarza. Dopiero pojedyncze przesunięcie lub
jawne zaliczenie zapisuje wpis o tym deterministycznym UUID:

```json
{
  "id": "UUIDv5 obliczony z reguły i originalDate",
  "name": "Plan siłowy",
  "kind": "override",
  "createdAtUtc": "2026-10-17T12:00:00.000Z",
  "updatedAtUtc": "2026-10-17T12:00:00.000Z",
  "ruleId": "11111111-1111-4111-8111-111111111111",
  "originalDate": "2026-10-19",
  "movedDate": "2026-10-20",
  "state": "completed",
  "sessionSyncId": "33333333-3333-4333-8333-333333333333",
  "ruleSnapshot": {
    "planSyncId": "22222222-2222-4222-8222-222222222222",
    "weekday": 1,
    "effectiveFromDate": "2026-10-19"
  }
}
```

`state` to `planned|completed`. `planned` nie może zawierać nie-NULL
`sessionSyncId`, `completed` wymaga UUID sesji. Bez przesunięcia `movedDate`
równa się `originalDate`. Pierwotny dzień musi pasować do weekday i daty
początku snapshotu. Snapshot i nazwa wpisu pozwalają wyświetlać wyjątek/historię
również po usunięciu lub zmianie reguły. **Nie filtrujemy historii po live rules.**

Daty to dni lokalnego kalendarza `YYYY-MM-DD`, nie chwile UTC. Arytmetyka
`CalendarDay` działa po składnikach kalendarza, z neutralnym kalkulatorem
gregoriańskim UTC; nie dodaje 24h do lokalnej północy. Tydzień zaczyna się
w poniedziałek. Rozwijamy tylko żądane skończone okno (UI: 7 dni; API: max rok).
Przesunięcie w przeszłość jest dozwolone, nie ma autoskip po upływie daty.

## Ręczne wykonanie, dostępność i konto

- Start, odczyt, upływ terminu i zakończenie pustej sesji **nie zaliczają**.
  Ekran wyjaśnia: po zakończeniu treningu wróć i wybierz rzeczywistą sesję.
- `complete` przechwytuje konto i epoch przed await; w jednej SQLite write
  transaction ponownie sprawdza binding/offlineAccess, aktywny profil, aktualne
  wystąpienie, nieusuniętą zakończoną sesję i >=1 live `SetsLog`. Nie kopiuje
  sesji, serii ani PR. Wybrana sesja nie musi pochodzić ze startu planu — jest
  świadomie wskazywana przez użytkownika.
- Jedna sesja nie może lokalnie zaliczyć dwóch wystąpień: zapis odmawia
  z wyjaśnieniem. Jeśli dwa urządzenia niezależnie przypiszą tę samą sesję do
  różnych wystąpień, merge zachowuje dane, a oba oznaczone są **konfliktem**, nie
  dwoma zaliczeniami. Brak automatycznych zaliczeń i automatycznej naprawy.
- Odczyt sprawdza dowód wykonania ponownie. Usunięta zdalnie sesja lub wszystkie
  jej serie powodują status **zaliczenie nieważne**, bez przepisywania historii.
- Brak/usunięcie/uszkodzenie planu jest jawnie pokazane. Start niedostępny;
  definicja i historia nie znikają, nie uruchamiamy generatora zastępczego.
- Przesuwać można wyłącznie niezaliczony termin. Zapis odczytuje aktualny
  wyjątek z SQLite, więc stary snapshot UI nie cofnie równoległego zaliczenia.
- UI blokuje double tap, przechwytuje konto/epoch przed dialogami; A→B→A
  unieważnia akcję. Planner sprawdza guard także **po odczycie planu, przed
  startem notyfikatora**, żeby rollback SQLite nie pozostawiał aktywnej sesji
  w pamięci. Subskrypcja konta jest pasywna, bez HTTP bootstrapu.
- Stream tygodnia obserwuje profil, konto, plany, sesje i serie; reaguje na pull,
  restore i usunięcia. Snapshot używa `readAll()`, nie zagnieżdżonego `.watch()`
  planów wewnątrz transakcji odczytu.

## Synchronizacja, limity i backup

`weeklySchedule` jest trzecim elementem `UserCollections.keys`. Istniejące
`profilePayload`, `SyncStore`, `SyncService`, `SyncDao` i restore iterują po tej
wspólnej liście: nowa kolekcja dziedziczy te same zabezpieczenia co warianty
i filtry (szczegóły: `user-variants-cloud.md`). Nie ma drugiej ścieżki sieciowej.

- Per-ID deterministyczny LWW po UTC, tombstone wygrywa remis, potem canonical
  JSON; UUID sortowane w wyniku. Merge nie usuwa zapisanych wyjątków przy
  tombstone reguły.
- Max **500 wpisów wraz z tombstone'ami**, max **262144 bajty UTF-8** na
  kolekcję, także po merge i restore. Przekroczenie daje błąd, bez cichego prune.
- Omission zachowuje lokalne rozszerzenie, jawny wire NULL czyści. Zwykłe
  nullable lokalne NULL bez intencji pomija klucz, aby nie skasować nieznanych
  zdalnych danych. Restore jawnego NULL zachowuje intencję w kolejnych świeżych
  upsertach/coalescing/CAS; attempted payloady pozostają bajtowo niezmienione.
- Deferred observed version nie staje się bazą CAS dla niezastosowanego
  snapshotu. Zwykłe edycje profilu zachowują kolumnę oraz safe base version.
- Błędne/przyszłe incoming rozszerzenie jest kwarantannowane jako oryginalny
  raw JSON; reader zgłasza błąd, nie konwertuje go na pusty harmonogram.
  Przy dirty profilu i odrzuconym CAS obowiązuje trwały hold opisany poniżej:
  lokalna kolekcja pozostaje czytelna, raw remote leży w istniejącym defer,
  a status synchronizacji pozostaje `conflict`, nie „gotowa”.
- Backup schemaVersion nadal **2**. Raw profil zawiera `weeklyScheduleJson`;
  restore scala per-ID i chroni tombstone'y. Brak pola w starym backupie
  zachowuje lokalną kolekcję, explicit NULL to odrębna intencja.
- Ponieważ restore nadaje nowe UUID treningom i planom, eksport dodaje optional
  `archiveSessionSyncId` / `archivePlanSyncId` (analogicznie do istniejącego
  `archiveSetSyncId`). W tej samej transakcji restore remapuje referencje
  harmonogramu na odtworzone UUID i podnosi timestamp zmienionych wpisów,
  zachowując UUID reguł/wystąpień. Nie przepisuje attempted outboxa.
  Referencje nieobecne w archiwum pozostają jawnie niedostępne, nigdy zgadywane
  po int ID. Nowsza lokalna definicja wygrywająca merge może odnosić się do
  zastąpionego treningu — wtedy widoczny jest stan nieważnego zaliczenia.

**Integracja API wymagana przed publikacją:** osobny właściciel backendu musi
dodać `weeklySchedule` do optional omission allowlist istniejącego profilu po
CAS/hash. Ten moduł nie zmienia backendu, nie publikuje API/web ani nowej wersji.

## Weryfikacja

Focused testy obejmują kodek/limity/LWW, granicę tygodnia/DST, przesunięcie
jednego wystąpienia, zachowanie historii po tombstone reguły, aktywne/puste
sesje, brak nowych set/PR, remote session deletion, podwójne powiązania,
A→B→A podczas kolejki SQLite i odczytu planu, start przez istniejący workflow,
odświeżenie po zniknięciu planu, dialog start/anuluj oraz ręczną notę UI.
Cloud tests: dwie bazy/CAS/defer, attempted immutable, omission/explicit NULL,
NULL restore z późniejszym profile edit, roundtrip referencji i migracja 12→13
z zachowaniem starego outboxa.

Generator: izolowana kopia aktualnego `/opt/fit`, Docker Flutter **3.35.4** /
Dart **3.9.2**; skopiowany wyłącznie `lib/core/database/app_database.g.dart`.
Zależności, lock i Web SQLite bez zmian. Hashy odpowiadają lockfile sqlite3
**2.9.4** i Drift **2.28.2**:

- `sqlite3.wasm`: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- `drift_worker.dart.js`: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

Końcowy focused zestaw schedule + profile cloud/review + user collections +
schema + backup + cały planner: **149 PASS / 0 FAIL**. `flutter analyze`:
**No issues found**. `dart tools/generate_app_version.dart --check`: sukces,
bez zmiany wersji. Format zmienionych plików i `git diff --check`: sukces.
Historyczne fixture'y migracji współdzielące `removeV12Columns` usuwają teraz
także kolumnę v13 przed symulacją starszej bazy; asercje wersji w core/planner
zaktualizowano do 13.

### Integracja wspólnego drzewa — 2026-10-17

Po zgodzie na zmiany historycznych fixture'ów workout/progress/health:

- RED na świeżym snapshotcie: **27 PASS / 7 FAIL**. Wszystkie siedem błędów to
  sztywne asercje 12 zamiast 13: PR side roundtrip, guidance migration, workout
  side migration, health repository oraz trzy historyczne migracje health
  (v4/v5/v6). W aktualnym drzewie duplicate weekly column nie występował już
  dzięki shared helperowi; wcześniejszy raport dotyczył starszego snapshotu.
- `removeV13Columns` buduje rzeczywisty fixture v12, a `removeV12Columns`
  wywołuje go dla wcześniejszych schematów. Helper nie ignoruje błędu DROP:
  nieprawidłowy kształt fixture'u nadal kończy test błędem. Test v12→13 używa
  tego samego helpera. Zachowano asercje NULL, danych, FK, reopen i attempted
  bytes; nie zmieniono produkcyjnej migracji ani logiki repeat/trends.
- GREEN focused migracje/core/defer/restore/schedule cloud: **40 PASS / 0 FAIL**.
- **Pełny Flutter na nowej izolowanej kopii całego aktualnego drzewa, wraz
  z repeat i trends: 752 PASS / 0 FAIL.** `flutter analyze`: **No issues found**.
  Stare 22 uwagi analyze nie występują w tym snapshotcie. W teście występują
  istniejące debug warnings Drift o wielu instancjach DB, bez błędów testów;
  nie wyciszano ich globalnie.
- Generator ponowiony: **sukces**, 169 s. Porównanie wszystkich **17** plików
  `*.g.dart` / `*.freezed.dart` przed/po: **0 zmian**, 17/17 zgodne. Nie kopiowano
  żadnego wygenerowanego pliku z powrotem. Schemat pozostaje 13; pełny zestaw
  zawiera rzeczywiste migracje od starych schematów oraz krytyczne backup/restore.
- `generate_app_version --check`, format wyłącznie zmienionych Dart oraz
  `git diff --check`: sukces. Web SQLite i lock bez zmian, hashe jak powyżej.
- Manifesty SHA256 `lib/test` porównano przed i po pełnej weryfikacji:
  **brak zmian źródeł podczas uruchomienia**.

Logi i dowody lokalne:

```text
/tmp/opencode/fit-schedule-integration/baseline/verification.log
/tmp/opencode/fit-schedule-integration/fixtures-green/verification.log
/tmp/opencode/fit-schedule-integration/full-current/verification.log
/tmp/opencode/fit-schedule-integration/full-current/generated-before.json
/tmp/opencode/fit-schedule-integration/full-current/generated-comparison.json
/tmp/opencode/fit-schedule-integration/full-current/snapshot-manifest.json
/tmp/opencode/fit-schedule-integration/full-current/source-drift.json
```

### HIGH review — izolacja konfliktu nieczytelnej kolekcji

Przyczyna: CAS usuwał odrzuconą operację, po czym `UserCollections.merge`
rzucał `FormatException` przed `SyncStore.apply`. Transakcja odpowiedzi push
wycofywała usunięcie, a `_run` kończył się przed globalnym pull. Błąd dotyczył
także wcześniejszych filterPresets/exerciseVariants, nie tylko weeklySchedule.

Polityka dla **wszystkich trzech** kolekcji:

- Przed usunięciem odrzuconej operacji walidujemy każdy nie-NULL zdalny klucz,
  również gdy local omission/NULL lub późniejsza edycja ominęłyby merge.
  `FormatException` walidacji lub samego merge wstrzymuje tylko ten profil.
  Nie chwytamy globalnie wszystkich wyjątków ani nie rozluźniamy kodeka.
- Odrzucony attempted request zostaje w outbox **bajtowo niezmieniony**,
  z tym samym UUID/payload/baseVersion/hashem. Lokalne kolumny i późniejsze
  edycje zostają. Nie ma automatycznego clear ani zastąpienia list pustymi.
- Istniejący `SyncDeferredRecords.recordJson` przechowuje zdalny rekord oraz
  wyłącznie lokalną kopertę `_profileCollectionConflict`: lista potwierdzonych
  odrzuconych operation IDs i oryginalny `quarantinedRecord`. To nie jest wire
  key, nowa tabela, encja lub zmiana schematu. Kolejne pull aktualizują najnowszy
  snapshot, zachowując pierwszą kwarantannę i marker hold, także po restartach.
- Scheduler push pomija **wszystkie** operacje wstrzymanego profilu, nie tylko
  pierwszą. Potwierdzonej odrzuconej próby nie ponawia na serwerze. Niezależne
  encje nadal push/pull, globalny kursor idzie naprzód; status pozostaje
  `SyncStatus.conflict`. Sam poprawiony zdalny profil nie zwalnia hold.
- Recovery jest **jawne**, przez account/generation-guarded
  `SyncService.retryProfileCollectionConflict(accountId, profileId)` po ręcznej
  weryfikacji. Zwykły przycisk „Synchronizuj teraz” go nie wywołuje. Nie ma
  automatycznej naprawy ani nowego UI odrzucającego lokalne dane.
  Przed recovery należy zachować zwykły backup **oraz osobny eksport surowego
  deferred record i outboxa** (sam standardowy backup nie zawiera tej koperty).
  Dla przyszłego schematu najpierw potrzebny zgodny klient; dla błędnych danych
  jawna naprawa źródła, a potem pull poprawionego snapshotu. Nie edytować SQLite
  ręcznie i nie usuwać outboxa/markerów w celu „odblokowania”.
- Recovery waliduje zdalne, lokalne i scalone kolekcje oraz limity **przed**
  jakimkolwiek usunięciem. Odmawia przy nieznanym wyniku attempted następcy,
  oczekującym delete, usuniętym profilu lub innym koncie. Zachowuje explicit
  NULL i najnowsze lokalne wpisy; stosuje istniejącą politykę CAS skalarów
  (server-authoritative, z dotychczasowym wyjątkiem preserveLocal restore).
  Dopiero zaakceptowana ręcznie rekonstrukcja zastępuje potwierdzone odrzucone
  i unsent operacje jednym **nowym UUID** na najnowszej zdalnej wersji. Nowy
  request nadal musi dostać ACK, zanim status będzie „gotowa”.

Testy review: sześć reprodukcji remote unknown v2/malformed dla trzech kolekcji,
nieczytelny local raw, restart SQLite + poprawiony remote + jawne recovery,
exact payload/hash/cały attempted row, późniejsza edycja/NULL, niezależny remote
workoutSession/workoutSet i wielokrotne synchronizacje. Dodatkowo rzeczywisty
restore na innym koncie weryfikuje plan/session UUID remap i binding, a dwa
niezależne urządzenia/CAS dowodzą konfliktu dwóch zaliczeń tej samej sesji bez
kopiowania set/PR. Focused cloud/core/schedule/backup przed testami dodatkowymi:
**101 PASS / 0 FAIL**; dwa dodatkowe integration tests: **2 PASS / 0 FAIL**.

Ostatnia pełna weryfikacja po rozszerzeniu regresji o nowe zdalne aktualizacje
sesji/serii **już po ustanowieniu hold**: **770 PASS / 0 FAIL**, analyze
**No issues found**, version check i format sukces. Snapshot obejmuje aktualne
repeat/trends; nie edytowano ich implementacji. W tym review nie zmieniano
deklaracji Drift/Freezed/JSON, więc generator nie był potrzebny; wszystkie
**17 generated** pozostały bez zmian, schemat nadal 13. Manifest źródeł przed/po
uruchomieniu: **0 zmian**. Istniejące debug warnings Drift pozostają niewyciszone.

Logi review (prefiks `/tmp/opencode/fit-schedule-integration/`):

- `quarantine-red/verification.log`: sześć pierwotnych reprodukcji **6 FAIL**.
- `quarantine-local-red/verification.log`: local quarantine **1 FAIL / 7 PASS**.
- `quarantine-core-green/verification.log`: focused **101 PASS**.
- `quarantine-extra-green/verification.log`: dwa dodatkowe integration **2 PASS**
  (analyze w tym pośrednim przebiegu wykrył siedem brakujących klamer, już
  poprawionych; końcowy analyze poniżej bez uwag).
- `quarantine-final/verification.log`: końcowy analyze i pełne **770 PASS**.
- `quarantine-final/generated-comparison.json`, `snapshot-manifest.json`,
  `source-drift.json`: porównania artefaktów i źródeł.

### Browser blocker — start z root overlay do istniejącego shella

Raport `training-rhythm-browser-acceptance-2026-10-17.md` zachowuje pierwotny
wynik browser **FAIL**. Sesja/szkic powstawały, ale ekran po potwierdzeniu startu
z Ustawienia → Generator → Rytm tygodnia był pusty poza dolną nawigacją.

Reprodukcja TDD na **produkcyjnym `createRouter`**, rzeczywistym
`PlannerWorkflow` i `ActiveSessionPage` dała **RED 1 FAIL**:
`navigator.dart:4029: !keyReservation.contains(key)`. `/schedule` jest stroną
root Navigatora ponad gałęzią settings. Dotychczasowe
`context.push('/workout/session')` próbowało w tym układzie ułożyć ponownie
stronę tego samego `StatefulShellRoute` z tym samym kluczem. To błąd topologii
stosu, nie brak zapisu, nie opóźnienie katalogu ani auth redirect wymagający
dłuższego oczekiwania. Wcześniejszy płaski test z zastępczą „Sesją testową”
nie zawierał wspólnego shella i dlatego nie wykrywał tego przypadku.

Minimalna poprawka: wyłącznie końcowa nawigacja w `SchedulePage._start` używa
`context.go('/workout/session')`. Usuwa root overlay i wybiera workout branch
istniejącego shella zamiast dokładać jego drugą stronę. Bez opóźnień, zmian
router declarations, workoutu, workflow, zapisów, PWA lub zależności.

Nowy `schedule_router_start_test.dart` przechodzi rzeczywistą ścieżkę UI od
settings, przez planner, schedule i zamknięcie dialogu; wymaga widocznego
**prawdziwego** `ActiveSessionPage`, nagłówka „Aktywny trening” i ćwiczenia
planu, `/workout/session` oraz tego samego elementu `MainShell`. Sprawdza
anulowanie bez sesji/szkicu/outboxa, dwa szybkie naciśnięcia bez drugiego dialogu
i UUID, dokładnie jedną sesję, jeden powiązany szkic i jeden start w outboxie,
0 set/PR oraz brak automatycznego zaliczenia terminu. Platformowe powiadomienia
i wakelock są zastąpione w fixture; router, zapis i ekran sesji nie są stubami.

Wyniki: RED **1 FAIL** → GREEN **1 PASS**; focused schedule/planner/router
**129 PASS / 0 FAIL**; końcowy pełny Flutter **771 PASS / 0 FAIL**;
`flutter analyze`: **No issues found**. Format zmienionych Dart, version check
i `git diff --check` OK. Docker Flutter 3.35.4 / Dart 3.9.2, 17 generated bez
zmian, brak zmian źródeł podczas przebiegu. Generator niewymagany.

Logi pod `/tmp/opencode/fit-schedule-integration/`:

- `schedule-router-red3/verification.log` — czysty RED duplicate page key;
- `schedule-router-green1/verification.log` — GREEN rzeczywistego ekranu;
- `schedule-router-focused/verification.log` — 129 PASS;
- `schedule-router-full/verification.log` — analyze i 771 PASS;
- `schedule-router-full/{generated-comparison,snapshot-manifest,source-drift}.json`.

Nie wykonywano nowego runtime build ani ponownej akceptacji browserowej.
Koordynator musi przebudować web i ponowić rzeczywistą reprodukcję; wynik PWA
pozostaje osobnym znanym problemem i nie został zamaskowany tą poprawką.

Nie wykonywano pełnego runtime build, browser acceptance, testów backendu,
commit/push/deploy ani zmian logiki lub nowych testów repeat/trends.
