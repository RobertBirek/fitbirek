# Task 3 — migracja i dynamiczne przypomnienia

## Status i granice

Implementacja w `/opt/fit`, gałąź `feat/recurring-activity-schedules`.
Backend + Flutter + worker, bez subagentów, commit/push/deploy. Zachowano
interfejsy task1/2. Bez zmian schematu Drift13/Alembic0010, dependencies/lock,
wersji aplikacji, generated i Web SQLite. Testy wyłącznie focused + analyze;
pełne suite i akceptacja urządzeń/PWA pozostają koordynatorowi.

## Pliki task3

Nowe:

- `backend/app/push/activity_schedule.py`
- `backend/tests/test_push_activity.py`
- `backend/tests/push-activity-worker.test.mjs`
- `lib/features/schedule/data/activity_migration.dart`
- `lib/features/schedule/domain/activity_reminders.dart`
- `lib/features/schedule/providers/activity_reminder_provider.dart`
- `test/features/schedule/activity_migration_test.dart`
- `test/features/schedule/activity_reminder_test.dart`
- `test/features/schedule/activity_reminder_provider_test.dart`
- `test/features/settings/activity_native_notification_test.dart`
- ten raport.

Zmodyfikowane:

- `backend/app/push/queue.py`, `backend/SYNC_EXTENSIONS.md`
- `lib/features/schedule/data/activity_repository.dart` (plik utworzony task1)
- `lib/core/services/notification_service.dart`
- `lib/features/settings/providers/settings_provider.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/core/push/push_settings_tile.dart`
- `lib/features/auth/providers/auth_providers.dart`, `lib/app/app.dart`
- `web/push/push-worker.js`, `docs/modules/weekly-schedule.md`
- `test/features/schedule/activity_ui_test.dart` i
  `test/features/schedule/schedule_router_start_test.dart`: wyłącznie jawny
  override migracji instalacji w istniejących fixture'ach CRUD/routera. Ich
  asercje sesji/terminów/outboxa pozostają bez osłabienia. Inaczej wejście do
  Settings prawidłowo seedowało dwa wpisy i profilowy outbox, zmieniając bazowy
  stan fixture'u, który dotąd nie zawierał instalacji powiadomień.

Pozostałe widoczne zmiany drzewa należą do task1/2, nie do tego zadania.

## Handoff API migracji

Dodano do istniejącego ActivityRepository:

```dart
Future<void> seedLegacy(ActivitySnapshot lease, {
  required bool karate,
  required bool training,
  bool Function()? isCurrent,
});
```

Jeden guarded write transaction, ponowna kontrola account/epoch/profile/device/
offline binding i deferred/hold; brak oczekiwania na sieć w transakcji.
Odczytuje wszystkie entries, także tombstone. Dodaje **tylko brakujące** IDs.
Wspólne `_write` nie enqueue'uje przy dokładnym no-op. Próby już attempted
zachowują oryginalny UUID/payload/CAS; późniejszy seed tworzy osobną operację.

Identyfikatory z zatwierdzonego task1:
UUIDv5(namespace=profileSyncId, name=`FitBirek/activity/legacyKarate` lub
`FitBirek/activity/legacyTraining`). Nie account ID. Dla profilu
`11111111-1111-4111-8111-111111111111` są to odpowiednio:

- `35b8d306-15f4-523a-abab-775435cba2d6`
- `c3dd0563-ff7a-52e7-b366-0a010e74db5f`

Karate wt/czw20:00 +30min lead; trening codziennie18:00 +0min. Początek
1970-01-01 (stała niezależna od urządzenia/dnia migracji). enabled i
reminderEnabled równe znanemu dawnemu opt-in. False nie staje się true.
Edycja nadal tombstonuje stary ID i tworzy nowy UUID; migracja nie odtwarza
markera nawet po edycji, wyłączeniu, usunięciu, reopen i sync dwóch urządzeń.
Równoległe seedy o różnych preferencjach podlegają dotychczasowemu per-ID LWW;
nie zmieniano polityki scalania task1 i nie tworzą one duplikatów.

`migrateLegacyActivities(...)` przechwytuje snapshot **przed PushClient.status**.
PWA nie czyta prywatnych preferencji native: istniejący status tej instalacji
jest jedynym źródłem enabled/categories. Offline/nieznany/nieobsługiwany status
nie staje się zgodą false: brak zapisu markerów, stan oczekujący z wyjaśnieniem
i przycisk ponowienia. Backendowy legacy fallback nadal działa. A→B→A podczas
HTTP odrzuca seed; nie ma utrzymywanej transakcji przez HTTP.

## Native i UI

- Bootstrap aplikacji obserwuje account-bound zmiany SQLite/sync oraz offline
  lock. Reconcile także po resume, co10min podczas pracy i przez jawny retry.
- Wybrano **skończony horyzont7dni**, nie bezterminowy weekly repeat: max60
  alarmów harmonogramu i max64 wszystkich oczekujących. UI jawnie wymaga
  otwarcia aplikacji co najmniej raz w tygodniu. Nie ma cichego obcięcia listy.
- Wyłącznie one-shot alarmy, żeby wykonane/przeniesione terminy nie odtwarzały
  się automatycznym repeat. Ponowne przeliczenie anuluje własne pending IDs.
- Stałe IDs dynamiczne=1000+int(first7hex occurrence UUID). Kolizja między
  terminami lub z innym pending alarmem daje jawny błąd, nie nadpisuje alarmu.
  Payload `activity:occurrenceUUID` umożliwia odnalezienie własnych IDs po
  restarcie; bieżące IDs przechwytywane przed await platformy. Wylogowanie
  unieważnia guard, a auth hook i provider disposal kolejkują własny cleanup.
  Nigdy cancelAll; mood300 pozostaje niezależne.
- 100/101/200 kasowane dopiero po guarded zgodnej migracji i udanym reconcile.
  SettingsNotifier nigdy nie nakłada ich ponownie przy starcie/zmianie zgody.
- Dotychczasowe native pref keys zachowane jako zgody kategorii urządzenia.
  Stałe opisy karate/treningu w settings zastąpiono kategoriami harmonogramu;
  istniejące wejście CRUD task2 zachowane. Mood ustawienia bez zmiany.
- Per-entry reminderEnabled=false dla nowego wpisu, nawet przy zgodzie
  kategorii. Działanie wymaga również zgody kategorii i uprawnień platformy.
  Permission request tylko w jawnym geście zmiany kategorii, nigdy podczas
  migracji/reconcile/init. Darwin initialization wyłącza automatyczne requests.
  Brak uprawnień i limity są jawnymi błędami w statusie/settings.
- InexactAllowWhileIdle nie gwarantuje dokładności; UI mówi o możliwym opóźnieniu.
  Warsaw lead liczymy w chwilach, również przez północ/DST. Luka wiosenna
  pomijana, jesienny fold raz, wcześniejszy instant jak Python fold0.
- PushSettingsTile zachowuje wire karate/training, opisuje je jako external/
  FitBirek. Guard epoch/account i czyszczenie stanu chronią wynik statusu oraz
  widok prywatnych kategorii po zmianie konta.

## Backend i worker

- Read-only adapter czyta profil po sub.user_id, nie UUID z payloadu zadania.
  Przy wielu żywych profilach nie wybiera arbitralnego. Sync nadal przechowuje
  opaque JSON; adapter nie naprawia JSON ani nie zapisuje profilu/sesji/wykonań.
- Walidacja v1/kinds/koperty/nazwy/plain/UUID/dat/czasów/typów/limitów kolekcji
  i activity fields zgodna z handoff, nieznany format nie daje dynamicznych
  eventów. Historia completed zawsze wycisza, bez tworzenia dowodu treningu.
- Virtual/override planned po movedDate, source enabled/reminderEnabled i
  tombstone sprawdzane na enqueue i ponownie przed każdą próbą dostarczenia.
  Zmiana pełnej reguły/override/revision, czasu, usunięcie, wykonanie lub move
  anuluje stare queued job. Kategoria/subskrypcja nadal osobną bramką.
- Dedup: UNIQUE installationId/eventKey, activity:SHA256 profilu+pełnej reguły+
  override+originalDate. TTL15min od due, bez catchup, zachowany retry/expiry.
- Deterministyczny marker, także tombstone i marker w przyszłym formacie,
  wycisza odpowiadający legacy event. Bez markera stare karate19:30 i trening18
  pozostają z dotychczasową zgodą, bez domyślania nowej zgody. Rewalidacja
  wycisza także wcześniej zakolejkowany legacy po nadejściu markera.
- Worker dynamic title<=80/body<=160, bez kontrolnych znaków, tylko dla
  activity events kategorii karate/training. Plain Notification API, żadnego
  HTML. URL nadal na istniejącej ścisłej allowliście same-origin; nazwa reguły
  nie staje się URL. Mood/operations i ich teksty niezmienione.
- Transport SSRF/DNS pinning/TLS/VAPID/retry bez zmian.

## Dowody RED/GREEN i weryfikacja

Nie twierdzimy, że każdy dodatkowy przypadek miał osobny RED:

- Backend początkowy rzeczywisty RED: **5 FAIL** (brak dynamicznych eventów i
  brak wyciszenia legacy przez marker), `activity-task3-backend-red.log`.
- Migration/native projector RED początkowo kompilacji brakujących API:
  `activity-task3-migration-red.log`, `activity-task3-reminder-red.log`.
- Po implementacji projektor DST dał rzeczywisty **3 PASS/1 FAIL**: timezone
  wybrało drugi fold zamiast pierwszego. Poprawiono wybór wcześniejszej chwili;
  log `task3-client-initial.log`.
- Worker dynamic plain RED: **1 FAIL**, `task3-worker-red.log`; GREEN10poniżej.
- Pośredni native mock wymagał jawnej rejestracji Android platform plugin;
  początkowo LateInitializationError/timeout. Naprawiono fixture, nie produkt.
- Pierwszy szeroki client focused: **98 PASS/3 FAIL** przez opisane wyżej
  nieizolowane fixture'y settings. Naprawiono wyłącznie override migracji;
  potem101PASS. Później rozszerzono projector/provider/auth i guarded seed tests.
- Pierwszy szeroki backend timeout120s został przerwany bez pełnego wyniku;
  uruchomiony ponownie z timeout240s, nie traktowany jako zielony wynik.

**Końcowe, świeże wyniki:**

- Backend focused **100 PASS/0 FAIL**, Python3.12.3, PostgreSQL16 przez prawdziwe
  Docker/Testcontainers. Zawiera26nowych testów dynamicznych, existing auth,
  VAPID, retry i pinned transport. HTTP dynamic delivery używa httpx.MockTransport
  w testowym send callback; production encryption/pinned transport w osobnych
  istniejących testach. Żaden prawdziwy push provider nie był wywoływany.
- Flutter focused **143 PASS/0 FAIL** (w tym14nowych testów task3), następnie
  **flutter analyze: No issues found**, version --check exit0.
- Node worker **10 PASS/0 FAIL** (9existing+1dynamic).
- `git diff --check`: sukces. Formatowano tylko wskazane zmieniane pliki Dart.

Polecenia backend (cwd=`/opt/fit/backend`):

```sh
.venv/bin/python -V
.venv/bin/python -m pip install --require-hashes -r requirements-build.lock
.venv/bin/python -m pip install --no-build-isolation --require-hashes -r requirements-dev.lock
.venv/bin/python -m pytest -q tests/test_push_activity.py tests/test_push_delivery.py tests/test_push_ops_transport.py tests/test_push_subscriptions.py
```

Flutter w przypiętym Dockerze `fit-web:release-1.13.0-26-verified`, Flutter3.35.4 /
Dart3.9.2, `--rm --network none -v /opt/fit:/app -w /app`:

```sh
flutter test --no-pub --reporter expanded test/features/schedule test/features/settings/notification_scheduler_test.dart test/features/settings/activity_native_notification_test.dart test/core/push_settings_test.dart test/features/auth
flutter analyze --no-pub
dart tools/generate_app_version.dart --check
```

```sh
node --test tools/tests/push-worker.test.mjs backend/tests/push-activity-worker.test.mjs
```

Logi wszystkie pod `/tmp/opencode/`:

- `task3-backend-verification.log`:100PASS,144.34s.
- `task3-client-verification.log`:143PASS, analyze bez uwag, version check.
- `task3-worker-verification.log`:10PASS.
- `task3-deps.log`: hash-locked instalacja, bez modyfikacji locków.
- Pośrednie/RED jak wyżej oraz `task3-client-focused.log`,
  `task3-client-focused-final.log`, `task3-client-expanded-final.log`.

Bez zmian deklaracji Drift/Freezed/json_serializable, więc generator niewymagany
i nieuruchamiany. `git diff --name-only` dla generated/deps/wersji puste.
Web SQLite SHA256 zachowane:

- wasm `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- worker `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

## HANDOFF — pozostające bramki

1. Koordynator: pełny Flutter/backend suite po zintegrowaniu wszystkich tasków,
   runtime web verification build i niezależny review. Zgodnie z dyspozycją nie
   uruchamiano tutaj pełnych suite ani subagentów.
2. Fizyczny Android/iOS: permission, OS restart i aktualizacja aplikacji z
   dawnymi100/101/200, limity pending, resume/7-dniowy refresh i logout. Mock
   platformy dowodzi wywołań/guardów, **nie dostarczenia fizycznego**.
3. Rzeczywista instalacja PWA: istniejąca zgoda karate/training, offline pending
   i retry, sync markerów dwóch urządzeń, odwołanie subskrypcji, cookie/account
   switch, worker upgrade i dynamiczny tekst. Node/MockTransport nie są dowodem
   browser/OS/provider delivery. Nie wykonano rzeczywistych push ani AI.
4. Native offline zna tylko ostatnio zsynchronizowany profil; zdalna zmiana
   podczas zamkniętej/offline aplikacji nie może wycofać lokalnego OS alarmu
   zanim nastąpi pull/reconcile. Horyzont jest jawnie skończony, nie background
   daemon. Błąd lub zawieszenie systemowego pluginu może uniemożliwić cancel;
   auth ma dotychczasowy3s bounded cleanup, nie blokujemy trwałego logout.
5. Kolizja28-bit hash jest bezpiecznie odrzucana z błędem (nie ma cichego
   nadpisania); nie obiecujemy matematycznie injektywnego odwzorowania UUID→int.
6. Nie było deploy/commit/push ani zmiany release version. Osobna zgoda na
   publikację nadal wymagana; ten raport nie stanowi akceptacji wdrożenia.

## Poprawka review P2 — granice kalendarza i izolacja sendera

Potwierdzono błąd: poprawny według wire `activityOverride` z movedDate0001-01-01,
time00:00 i lead30 przechodził walidację, lecz Warsaw→UTC wychodziło do roku0.
Nieobsłużony OverflowError przerywał cały schedule/deliver cycle, również dla
niezależnego użytkownika. Przy bardziej późnym starcie roku0001 również samo
odjęcie lead1440 mogło przekroczyć dolną granicę datetime.

Zmiany wyłącznie w adapterze i regresjach:

- `backend/app/push/activity_schedule.py`: **wyłącznie OverflowError** wokół
  UTC roundtrip i odejmowania lead na granicy pojedynczego wystąpienia.
  Pomijamy tę niedostarczalną chwilę, nie profil ani inne reguły; walidacja,
  marker suppression i brak domain writes pozostają bez zmian. Nie ma
  blanket catch wokół scheduler/deliver ani maskowania innych błędów.
- Kandydatów dnia ograniczono ordinalami do date.min/date.max przed konstrukcją
  dat, zamiast wywoływać local±dni poza latami0001..9999. Dzięki temu także
  reprezentowalny testowy zegar na obu granicach nadal rozwija poprawny dzień.
- `backend/tests/test_push_activity.py`:17regresji: movedDate0001-01-01/02 i
  9999-12-30/31 × lead0/30/1440; osobno zegar0001/9999 i poprawne przekroczenie
  dnia przy lead30/1440. Testy sprawdzają zachowanie markera i niezależnej
  reguły w tym samym profilu, nie tylko brak wyjątku.
- Real PostgreSQL/Testcontainers integration: dwóch użytkowników/subskrypcji,
  queued reminders, potem niedostarczalny boundary override jednego profilu.
  Kolejny schedule działa; jego nieaktualne zadanie zostaje cancelled, a
  niezależny użytkownik otrzymuje sent przez httpx.MockTransport. Profil ma
  dokładnie niezmieniony JSON, brak fallback karate po markerze i brak
  rzeczywistych wywołań push provider.
- Sprawdzono native: `WeeklySchedule.between` odrzuca movedDate poza żądanym
  współczesnym horyzontem **przed** konstrukcją TZDateTime i odejmowaniem lead.
  Nie wymaga zmiany produkcyjnego Darta. Dodano4regresje do
  `activity_reminder_test.dart` (0001/9999 × lead30/1440), potwierdzające również
  zachowanie niezależnego poprawnego alarmu. Nie rozszerzano sztucznie obsługi
  systemowego „teraz” do roku9999 w natywnym siedmiodniowym schedulerze.

RED przed naprawą:

```sh
.venv/bin/python -m pytest -q tests/test_push_activity.py -k 'boundary or previous_calendar'
```

**8 FAIL /9 PASS /26 deselected**, oczekiwane OverflowError przy UTC conversion,
odejmowaniu lead i rozwijaniu okna dat. Log
`/tmp/opencode/task3-p2-boundary-red.log`.

GREEN po naprawie, Python3.12.3 i dotychczasowe hash-locked dependencies,
prawdziwy Docker/Testcontainers PostgreSQL16:

```sh
.venv/bin/python -m pytest -q tests/test_push_activity.py tests/test_push_delivery.py tests/test_push_ops_transport.py tests/test_push_subscriptions.py
```

**117 PASS /0 FAIL**,148.57s. Log
`/tmp/opencode/task3-p2-boundary-green.log`.

Native w tym samym przypiętym Flutter3.35.4/Dart3.9.2 Dockerze `--network none`:

```sh
dart format test/features/schedule/activity_reminder_test.dart
flutter test --no-pub --reporter expanded test/features/schedule/activity_reminder_test.dart
```

**8 PASS /0 FAIL**, `/tmp/opencode/task3-p2-native-boundary.log`. Cztery nowe
testy native od początku zielone, bo dowodzą istniejącego bezpiecznego clippingu,
nie naprawy Darta. `git diff --check`: sukces. Analyze/pełne suite nie były
ponawiane w tej wąskiej poprawce; wcześniejsze wyniki powyżej pozostają
historyczne. Nadal bez commit/push/deploy, schematu, deps i wersji.
