# Task5 — integracja Flutter, dokumentacja i testy

Status implementera: **DONE_WITH_CONCERNS**. Zakres Flutter/doc wykonany;
to nie jest odbiór całego Task5 ani wydanie. Baza:
`d0e375aa4f1fb6b300a2f89dcadd162e38c985ea`. Commit zmian testów/dokumentacji:
`cbc247cc9dc2e35d8e9ef3e725c90b391107ccb2`.
Kolejny commit dodaje wyłącznie niniejszy raport. Whole-branch review wykonuje
kontroler po commitach, nie implementer.

## Zmiany i API

- Brak nowych funkcji, zmian produkcyjnego Dart, API, deklaracji generatorów,
  migracji, wersji, zależności, lockfile'a i Web SQLite.
- Dwa potwierdzone stare oczekiwania backup3 → backup4:
  `custom_fitness_data_test.dart` (nazwa i version expect),
  `activity_cloud_test.dart` (version expect i zgodny komentarz).
  Wszystkie asercje UUID/protocol snapshot/atomic failure/attempted bytes/
  tombstone/reopen/external history pozostały. Pełna suita nie ujawniła innych
  stale fixtures ani produktu wymagającego poprawki.
- Uzupełniono bieżące odsyłacze i granice w README, guides training/sync/guided/
  planner/preparation/weekly oraz data/UI etapu3. Dodano `docs/modules/backup.md`
  z backup4, import1–3, remapowaniem programów i biernym syncRecovery.
  `backend/SYNC_EXTENSIONS.md` dostał wyłącznie odsyłacze do klienta.
  Nie przepisano historii DEPLOY ani dawnych raportów testowych.

## Środowisko i sekwencja

Istniejący kontener `fit-catalog-program-tests`, Flutter **3.35.4**, Dart
**3.9.2**, bez upgrade/builda obrazu. Host repo jest zamontowane RO jako
`/workspace`; źródła lib/test/tools i pubspec/lock skopiowano do `/app`.
Kontrole potwierdziły zgodność wszystkich host lib/test Dart z testowanym
`/app`, a manifest SHA256 lib/test przed/po pełnym uruchomieniu i po read-only
format check nie wykazał zmiany. Domyślna strefa kontenera: **UTC +0000**.

Komendy poniżej uruchamiano foreground przez `docker exec … bash -lc
'cd /app && …'`, z timeout1200000 i `set -o pipefail`, logując `2>&1 | tee`.
W sekwencjach sukcesowych polecenia łączono `&&`; RED świadomie zwrócił1.
Nie uruchamiano backend pytest, agentów/reviewerów ani builda Web.

### RED → GREEN

```sh
flutter test --no-pub --reporter expanded \
  test/features/progress/custom_fitness_data_test.dart \
  test/features/schedule/activity_cloud_test.dart
```

- RED przed korektą: **10 PASS / 2 FAIL**, oba `Expected: <3>, Actual: <4>`
  na wskazanych liniach330/208. Log: `/tmp/opencode/task5-red.log`.
- Po minimalnej korekcie: **12 PASS / 0 FAIL**. Zachowano wszystkie pozostałe
  asercje, nie wykluczano plików ani przypadków. Log:
  `/tmp/opencode/task5-green-codegen.log`.

### Generator, pełna analiza i suita

```sh
dart format test/features/progress/custom_fitness_data_test.dart \
  test/features/schedule/activity_cloud_test.dart
flutter test --no-pub --reporter expanded \
  test/features/progress/custom_fitness_data_test.dart \
  test/features/schedule/activity_cloud_test.dart
dart run build_runner build --delete-conflicting-outputs
# Następny, pełny przebieg:
flutter analyze --no-pub && flutter test --no-pub --reporter expanded && \
  sha256sum --check --quiet /tmp/task5-source-before.sha256 && \
  dart tools/generate_app_version.dart --check
```

- Generator: **PASS**,154s;17/17 śledzonych `*.g.dart`/`*.freezed.dart`
  identycznych bajtowo host vs wygenerowane `/app`. Nie kopiowano nic z powrotem;
  komunikat build_runner „wrote759 outputs” obejmuje także jego cache/pośrednie
  wyniki, nie oznacza zmian17 commitowanych artefaktów.
- Analyze: **No issues found**,20.3s.
- Pełny Flutter **bez filtrów/wykluczeń**: **1806 PASS / 0 FAIL / 1 SKIP**,
 7:57. Log: `/tmp/opencode/task5-full-flutter.log`.
- Warunkowo pominięty w UTC:
  `fitness_protocol_widgets_test.dart` →
  `Warsaw spring DST gap is rejected instead of normalized`, skip warunkowany
  offsetem lokalnym29.03.2026. Nie dodano skip ani nie zmieniono jego guardu.
- Debug warnings Drift o wielu instancjach DB pozostały niewyciszone;
  nie są błędami analizy/testów.

### Europe/Warsaw

```sh
docker exec -e TZ=Europe/Warsaw fit-catalog-program-tests bash -lc \
  'cd /app && date +"%Z %z" && flutter test --no-pub --reporter expanded \
  test/features/progress/fitness_protocol_widgets_test.dart \
  test/features/schedule/training_program_schedule_test.dart'
```

**27 PASS / 0 FAIL / 0 SKIP**. Uruchomiony również powyższy test luki DST;
kalendarz programów obejmuje obie granice DST, rok i dzień przestępny.
Log: `/tmp/opencode/task5-warsaw.log`.

## Format i chronione dane

- Zmienione2 Dart: format **PASS**,0 zmian. `git diff --check`: **PASS**.
  `dart tools/generate_app_version.dart --check`: **PASS**, bez zapisu.
- Read-only `dart format --output=none --set-exit-if-changed .` zwraca1:
 498 plików,9 wymaga formatowania. Wszystkie9 są bajtowo identyczne z BASE,
  nie zostały zmienione ani masowo sformatowane:
  - `lib/core/services/notification_service.dart`
  - `lib/features/progress/trends/domain/training_trend.dart`
  - `lib/features/progress/trends/providers/training_trend_providers.dart`
  - `test/core/database/database_bootstrap_test.dart`
  - `test/features/mentor/mentor_api_test.dart`
  - `test/features/mentor/mentor_privacy_boundary_test.dart`
  - `test/features/progress/training_trend_provider_test.dart`
  - `test/features/progress/training_trend_repository_test.dart`
  - `test/features/progress/training_trend_test.dart`
- 481 chronionych plików wersji/lock/Web SQLite/assets/source_data/deploy
  identycznych z Task5 BASE. `DEPLOY.md` również bez zmian.
- Lock: Drift **2.28.2**, sqlite3 **2.9.4**. Przypięta para SHA256 zgodna:
  - wasm: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
  - worker: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`
- Standardlib read-only kontrola:431 kolejnych IDs cw001–cw431;
  canonical frozen raw424 SHA256
  `d734c9eb98c827f47d5755705fbd8819207fbe7431db65f26e61ec97c5e7c278`.
  Wszystkie424 bloby obrazów identyczne z przypiętym `acd52d8`, brak nowych
  obrazów. EN i źródła/XLSX niezmienione względem BASE.
- Sprawdzono istnienie lokalnych plików z linków zmienionych Markdown
  (nie walidowano automatycznie kotwic).

Logi: `/tmp/opencode/task5-protected.log`,
`/tmp/opencode/task5-format-readonly.log`,
`/tmp/opencode/task5-final-checks.log`.

## Pozostały odbiór i ograniczenia

- Pełny backend wykonuje osobny readonly fit-backend agent; **nie przypisuję**
  temu raportowi691 ani innej liczby backendPASS.
- Standardowy build Web, generator offline oraz runtime/browser wykona następny
  ops agent po pełnym Flutterze. Nie wykonywano ich tu ani nie deklarowanoPASS.
  Pełny Python/browser pipeline katalogu pozostawiono temu osobnemu odbiorowi;
  tutejsze katalog checks są wyłącznie read-only standardlib + pełny Flutter.
- Niezależny whole-branch review należy do kontrolera. Nie uruchamiano
  subagentów, deploy/push/merge ani operacji na danych produkcyjnych.
- Pozostaje9 baseline format violations (jawne powyżej), nie produktowy FAIL.
- API-first i plan aktualizacji klientów nadal wymagane przed przyszłym wydaniem.
  Stary klient nie rozumie warmup/schema2/programów/backup4; omission nie daje
  zgodności semantycznej. Nie ma gwarancji flush po zabiciu procesu ani odbioru
  fizycznego telefonu/PWA. cw425–cw431 nadal oczekują na ilustracje;424 dawnych
  obrazów nie zastąpiono obrazami innych ruchów.
