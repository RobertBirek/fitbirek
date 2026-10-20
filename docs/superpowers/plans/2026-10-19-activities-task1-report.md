# Task 1 — domena i trwały CRUD aktywności

## Status i zakres

Zaimplementowano w `/opt/fit`, gałąź `feat/recurring-activity-schedules`,
bez commit/push/deploy, subagentów, nowych zależności, wersji ani schematu.
Nie wykonywano migracji domyślnych ustawień (task 3) ani nowego UI (task 2).
Dotychczasowe `rule` / `override`, ich UUID i publiczne API pozostają działające.
Nowe dane są nadal wyłącznie w `weeklySchedule` v1 profilu.

## Dokładne pliki zadania

Nowe:

- `lib/features/schedule/domain/activity_schedule.dart`
- `lib/features/schedule/data/activity_repository.dart`
- `test/features/schedule/activity_schedule_test.dart`
- `test/features/schedule/activity_repository_test.dart`
- `test/features/schedule/activity_cloud_test.dart`
- `test/features/schedule/activity_provider_test.dart`
- `docs/superpowers/plans/2026-10-19-activities-task1-report.md`

Zmienione:

- `lib/features/schedule/domain/weekly_schedule.dart`
- `lib/features/schedule/data/schedule_repository.dart`
- `lib/features/schedule/providers/schedule_providers.dart`
- `lib/core/services/backup_service.dart`
- `lib/features/schedule/presentation/schedule_page.dart` — wyłącznie nullable
  compile adaptation `startSaved(o.planSyncId!, ...)`; stary przycisk startu
  wymaga odnalezionego planu. Właściwa obsługa external/free należy do task 2.

Istniejące przed zadaniem untracked spec i plan nie były edytowane.

## Interfejsy dla następnego wykonawcy

`activity_schedule.dart`:

- `ActivityType.external|fitbirek`.
- `ActivityDraft(name:, activityType:, weekdays: Set<int>, time: String,
  effectiveFrom: CalendarDay, timeZone: 'Europe/Warsaw', durationMinutes: int?,
  enabled: true, planSyncId: String?, reminderEnabled: false,
  reminderMinutesBefore: 0)`; pola final, weekdays jest niemutowalny.
  `toFields()` zwraca wire fields z nazwą, bez koperty.
  Walidacja pełnego wpisu/limitów następuje przy zapisie; konstruktor nie
  zastępuje walidacji formularza. Nie ma `copyWith` ani Freezed.
- `ActivityRule.fromJson(...)`, `toJson()` zwraca świeżą głęboką kopię.
  Gettery: `id`, `name`, `isLegacy`, `isDeleted`, `enabled`, `activityType`,
  `weekdays`, `time`, `timeZone`, `durationMinutes`, `planSyncId`,
  `effectiveFrom`, `reminderEnabled`, `reminderMinutesBefore`.
  Legacy ma `time == null`, a nie wymyśloną godzinę.
- `LegacyActivitySource.legacyKarate|legacyTraining` oraz
  `legacyActivityRuleId(profileSyncId, source)`:
  **UUIDv5(namespace=profileSyncId, name='FitBirek/activity/${source.name}')**.
  Namespace musi być UUID profilu, nie account ID. Opcjonalne wire pole
  `legacySource` dopuszcza wyłącznie te dwie wartości.

`activity_repository.dart`:

```dart
ActivityRepository(db, {authority});
Future<ActivitySnapshot> snapshot(String account, {isCurrent});
Future<String> create(ActivitySnapshot lease, ActivityDraft draft, {isCurrent});
Future<String> update(ActivitySnapshot lease, String ruleId, ActivityDraft draft, {isCurrent});
Future<void> delete(ActivitySnapshot lease, String ruleId, {isCurrent});
Future<String> setEnabled(ActivitySnapshot lease, String ruleId, bool enabled, {isCurrent});
```

`isCurrent` ma typ `bool Function()?`. `ActivitySnapshot` ma prywatny konstruktor
oraz `account`, `profileSyncId`, `deviceId`, `epoch`, `schedule`, `rules`.
`rules` zawiera wszystkie live reguły, **także disabled i legacy**; `schedule`
zawiera również wyjątki/tombstone'y. Pełny optimistic baseline każdej reguły
jest niemutowalną kopią JSON (łącznie z kopertą i nieznanymi polami).

**Formularz przechwytuje lease przed dialogiem i przekazuje ten sam lease przy
zapisie**; ponowny `snapshot` tuż przed Save ominąłby ochronę stale-edit.
Po sukcesie trzeba odczytać świeży snapshot. `update` i zmiana `setEnabled`
zwracają **nowy UUID**, tombstonując stary w tej samej transakcji. `delete`
wyłącznie tombstonuje. Nie zmieniają żadnych zapisanych wyjątków/snapshotów.
Równoległa zmiana innej reguły nie blokuje zapisu; zmiana dowolnego pola
edytowanej reguły odrzuca stary lease.

`setEnabled` na legacy odmawia z wyjaśnieniem: najpierw jawna edycja i wybór
godziny przez `update`. Dzięki temu nie tworzymy niezgodnego starego `rule`
z flagą ignorowaną przez stary klient ani nie dopisujemy domyślnej godziny.
Identyczne `setEnabled` istniejącej activityRule zwraca ten sam ID.

Provider `activityRepositoryProvider` używa produkcyjnego cached auth authority.
Nie dodano drugiego magazynu/strumienia wystąpień: nadal `scheduleWeekProvider`.

`ScheduleOccurrence` otrzymał nullable `planSyncId`, `time`, `durationMinutes`,
`activityType`, `externalCompleted`, `isCompleted`, `isActivity`.
`ruleSnapshot` zawiera pełne pola nowej reguły bez koperty/nazwy; dla starej
reguły zachowuje dotychczasowy format. UUID wystąpienia nadal v5(ruleId,date).
Sortowanie: dzień, godzina (brak na końcu), UUID przy remisie.

`ScheduleRepository.completeExternal(account, occurrence, {isCurrent})` zapisuje
wyłącznie activityOverride completed bez sesji. `move` obsługuje oba rodzaje;
`complete` nadal wymaga rzeczywistej zakończonej sesji i live set, także przy
FitBirek bez szablonu. Duplikaty sesji są sprawdzane między starymi i nowymi
wyjątkami; status ponownie sprawdza dowód wykonania. Odczyt/wyłączenie/usunięcie
reguły nigdy nie filtruje zapisanej historii po live/enabled rules.

## Wire i bezpieczeństwo

Nowa koperta ma `kind: activityRule` i wszystkie pola `ActivityDraft.toFields()`
(wire `effectiveFromDate`, sorted ISO weekdays1..7, HH:mm, Warsaw).
Duration opcjonalne1..1440, reminder lead0..1440; plan opcjonalny/NULL wyłącznie
dla FitBirek. External z nie-NULL planem jest błędem.
`activityOverride` ma dotychczasowe pola identyfikacji, daty i snapshot;
completed FitBirek wymaga UUID sesji, external completed nie może go zawierać.
Planned nie może zawierać nie-NULL sesji. Limity kolekcji pozostają wspólne
500 wpisów/262144B, bez prune ani zamiany złego JSON na pusty.

Nowy CRUD i stare operacje ScheduleRepository odmawiają mutacji przy każdym
deferred profilu (obejmuje hold/quarantine), zanim zaczną zapisywać. Kontrola
authority epoch, binding/offline access i profilu działa wewnątrz transakcji;
nowy lease obejmuje także tożsamość profilu/urządzenia. A→B→A unieważnia lease.
Wspólny UserCollectionsRepository/SyncDao nadal enqueue'uje; attempted row,
operation UUID, payload i CAS base nie są przepisywane.

Backup schemaVersion2 remapuje plan nowych rule/override oraz sesję nowego
override; NULL/brak referencji pozostaje NULL/brakiem. UUID reguł i wystąpień
pozostają. Nie zgadujemy brakujących referencji.

### Kontrakt migracji task 3 (jeszcze bez implementacji)

Sprawdzać obecność deterministycznego ID w **całym `snapshot.schedule.entries`**,
nie tylko `rules`: tombstone jest trwałym markerem przeprowadzonej migracji.
CRUD nigdy go nie usuwa ani nie ożywia. Edycja/usunięcie domyślnej reguły
pozostawia marker pod oryginalnym deterministycznym ID; zastępnik ma nowe UUID.
Nie używać `create` do migracji (celowo tworzy losowe ID); seeding task 3 musi
otrzymać własny guarded/idempotent zapis w tej samej transakcji z markerem.
Nie ma automatycznego seeding w konstruktorach/providerach ani żądań uprawnień.
Nie zmieniono dotychczasowej polityki per-ID LWW UserCollections.

## RED / GREEN i weryfikacja

Przypięty obraz: `fit-web:release-1.13.0-26-verified`, Docker `--rm --network none`,
volume `/opt/fit:/app`, cwd `/app`, Flutter/Dart z obrazu.

- Kodek RED: **3 FAIL**, nieznany activityRule/activityOverride (`FormatException`),
  `/tmp/opencode/activity-domain-red.log`; GREEN kodek + legacy **8 PASS**.
- Nowe API: pierwszy RED kompilacji brakujących symboli zachowany osobno;
  po dodaniu samych sygnatur/stubów **8 FAIL** (`UnimplementedError`),
  `/tmp/opencode/activity-repository-red-behavior.log`.
  GREEN nowy repo + stare repo **14 PASS**.
- Backup RED: **1 FAIL / 1 PASS**, rzeczywisty restore pozostawiał stary plan
  UUID w nowym rodzaju; `/tmp/opencode/activity-cloud-red.log`.
  Naprawa objęła oba nowe rodzaje. Drugi test używa dwóch rzeczywistych baz,
  SyncService/CAS, utraty transportu, attempted row oraz reopen SQLite.
- Legacy toggle RED: **1 FAIL** (przyjmował niedozwolone wyłączenie bez godziny),
  `/tmp/opencode/activity-legacy-toggle-red.log`; poprawiono jawne odrzucenie.
- Dodatkowe regresje kolejności/strict override/500 wpisów/shared provider
  dodano po bazowym GREEN (nie twierdzimy, że miały osobny RED).
- Pierwszy focused **41 PASS**; analyze miał 9 uwag o klamrach — poprawione.
- **Końcowy focused: 46 PASS / 0 FAIL**, następnie **flutter analyze: No issues
  found**, exit0. Log: `/tmp/opencode/activity-task1-final.log`.

Końcowe polecenia w obrazie:

```sh
flutter test --no-pub --reporter expanded test/features/schedule test/features/settings/backup_snapshot_test.dart
flutter analyze --no-pub
```

Formatowano wyłącznie zmienione pliki Dart. `git diff --check`: sukces.
Nie zmieniano deklaracji Drift/Freezed/json_serializable: nowe modele są ręczne,
bez annotations/generatorów; build_runner niewymagany i nie był uruchamiany.
Generated, schema13, deps/lock i Web SQLite pozostają bez zmian. Hashe sprawdzone:

- lock: drift2.28.2 / sqlite3 2.9.4;
- wasm `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`;
- worker `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`.

## Ograniczenia i handoff

- Zgodnie z poleceniem wykonano tylko focused + analyze, nie pełną suite/build,
  backend pytest ani browser acceptance. Nie było niezależnego review/subagentów.
- UI zewnętrznych aktywności, start swobodny, formularze i Dziś pozostają task2;
  obecny stary ekran nie jest gotowym UI dla nowych typów.
- Migracja preferencji, permissions/reminders, native/push i backend codec/sender
  pozostają task3; nie wdrażać tego stanu pośredniego jako gotowej funkcji.
- Test migration-marker dowodzi stabilnego ID i pozostawienia tombstone przez
  CRUD, nie rzeczywistej migracji ani restartowej idempotencji task3.
- Lease należy brać przed dialogiem; zadanie UI musi nadal blokować double tap
  i przekazywać własny mounted/account guard przez wszystkie await.
