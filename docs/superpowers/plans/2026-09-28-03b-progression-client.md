# Klient progresji — etap 3b Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Nie delegować self-review; przegląd wykona użytkownik.

**Goal:** Udostępnić offline jawne reguły progresji, deterministyczne sugestie i atomową akceptację celu w planie, bez tworzenia wykonanych serii i bez utraty danych podczas sync lub restore.

**Architecture:** Niemutowalne modele i czysty silnik korzystają z surowego API historii etapu 2. Plan przechowuje pełny snapshot kontraktu 3a, a transakcyjna warstwa zapisu sprawdza konto, rewizje i historię oraz zapisuje cel razem z outboxem. Aktywna sesja otrzymuje zamrożoną kopię zaakceptowanych celów w punkcie startu z planu, niezależnym od późniejszych edycji planu.

**Tech Stack:** Flutter 3.35.4, Dart 3.9.2, Riverpod 2.6.1, Drift 2.28.2, sqlite3 2.9.4, UUID v4, SHA-256, flutter_test, NativeDatabase.memory().

---

## Status dokumentu i granice kompletności

**To plan do przeglądu, nie kompletny patch implementacyjny.** Zawiera jednoznaczne decyzje, checklisty TDD, kod rdzenia obliczeń i konkretne przykłady testów. Nie zawiera pełnego kodu wszystkich adapterów persistence, formularza, kontrolera akceptacji ani testów integracyjnych. Braki są wyliczone w ostatniej sekcji; nie traktować dokumentu jako gotowego do bezrefleksyjnego wykonania przez kopiowanie bloków. Fragmenty integracyjne są oznaczone jako kontrakty lub szkielety, nie jako istniejące API.

W tej sesji zapisano wyłącznie `/opt/fit/docs/superpowers/plans/2026-09-28-03b-progression-client.md`. Wszystkie dalsze polecenia generatora, testów i zmiany aplikacji dotyczą **przyszłej implementacji**. Nie commitować, nie wdrażać, nie tworzyć worktree klienta, nie porządkować wcześniejszych zmian. Praca klienta tylko w `/opt/fit`. Nie zmieniać backendu ani dwóch planów zależnych w ramach 3b.

Źródła nadrzędne:

- `/opt/fit/AGENTS.md`.
- `/opt/fit/docs/superpowers/specs/2026-09-28-plany-historia-progresja-design.md` — zaakceptowany zakres, przede wszystkim etap 3.
- `/opt/fit/docs/superpowers/plans/2026-09-28-02-exercise-history.md` — dokładne typy i API historii.
- `/opt/fit/docs/superpowers/plans/2026-09-28-03a-progression-contract.md` — normatywne nazwy JSON, ograniczenia i przejścia sync. Dokument nazywa kontrakt propozycją; implementację klienta v1 uruchomić dopiero po uzgodnieniu wdrożenia ochrony backendowej. Nie wysyłać v1 do starego backendu, który zaakceptowałby późniejszy downgrade.

## 1. Stan zastany i zależności

1. `/opt/fit/lib/core/database/app_database.dart`: `schemaVersion => 7`. Wersję 8 opisujemy jako migrację **z obecnego v7**, nie rezerwację numeru przeciw równoległemu etapowi 1. Przed implementacją ponownie odczytać schemat; jeśli etap 1 podniósł numer, użyć następnego wolnego i zachować obie migracje.
2. `/opt/fit/lib/features/planner/data/planner_repository.dart`: `SavedPlan` jest zwykłą klasą, ma lokalne `id`, bez `syncId` i progresji; `_payload` składa cztery pola. `savePlan` i `deletePlan` zapisują outbox w transakcji.
3. `/opt/fit/lib/core/database/tables/plans_table.dart`: lista ćwiczeń jest tekstem JSON. Nowe pole lokalne będzie `progressionJson`, ale na wire i w backupie nazywa się **`progression` i jest obiektem**.
4. `/opt/fit/lib/core/database/daos/sync_dao.dart`: scala wszystkie niewysłane operacje jednej encji, zachowuje attempted. Trzeba zachować początkową bazową rewizję przy scalaniu.
5. `/opt/fit/lib/core/sync/sync_store.dart`: waliduje pull przed obsługą dirty, odkłada rekord do `syncDeferredRecords`; `version` zmienia tylko niewysłane `baseVersion`. Progresję trzeba walidować przed generated parserem.
6. `/opt/fit/lib/core/sync/sync_service.dart`: wybiera jedną operację encji do batcha; `kind != null` blokuje całą rundę. Zwykły konflikt może wykonać `preserveLocal` rebase. Dla v1 zakazać tego również przy konflikcie bez `kind`.
7. `/opt/fit/lib/core/services/backup_service.dart`: backup v2; część castów envelope jest dziś poza `try`; restore usuwa plany i nadaje nowe UUID. Zabezpieczyć walidację **przed** kasowaniem i nie zgubić usunięć starych chronionych planów.
8. `/opt/fit/lib/features/workout/providers/workout_providers.dart`: stan sesji jest w pamięci; nie ma obecnie operacji startu z planu. Nie projektujemy jej nazwy ani nie zastępujemy równoległego etapu 1.
9. `/opt/fit/lib/features/workout/presentation/pages/active_session_page.dart`: formularz wykonania operuje kg `double`, RPE integer; nie zmieniać formatu historycznych serii ani logiki PR/Mentora.
10. `/opt/fit/pubspec.lock`: zachować Drift 2.28.2/sqlite3 2.9.4. `crypto` jest obecny w locku; przy bezpośrednim imporcie upewnić się, że ma bezpośrednią deklarację w `/opt/fit/pubspec.yaml`, bez aktualizowania pozostałych pakietów.

### Dokładne API etapu 2 — nie tworzyć alternatywy

Importy:

```dart
import 'package:fitbirek_training/features/workout/history/domain/exercise_history.dart';
import 'package:fitbirek_training/features/workout/history/data/exercise_history_repository.dart';
```

`ExerciseHistorySet`: `String syncId`, `int syncVersion`, `DateTime updatedAtUtc`, `int number`, `DateTime timestamp`, `double? weightKg`, `int? reps`, `int? seconds`, `int? rpe`.

`ExercisePerformance`: `String exerciseId`, `String exerciseName`, `String sessionSyncId`, `int sessionSyncVersion`, `DateTime sessionUpdatedAtUtc`, `DateTime finishedAt`, `List<ExerciseHistorySet> sets`.

```dart
Future<List<ExercisePerformance>> getCompletedHistory({
  required String accountId, required String exerciseId,
});
Stream<List<ExercisePerformance>> watchCompletedHistory({
  required String accountId, required String exerciseId,
});
```

Historia jest już filtrowana po żywych zakończonych sesjach, żywych seriach oraz `syncState.accountId/ offlineAccess`. Kolejność: `finishedAt DESC`, `sessionSyncId DESC`; serie: `number ASC`, `timestamp ASC`, `syncId ASC`. Pusta historia **nie autoryzuje zapisu**. Do akceptacji tworzyć repo historii z **tą samą instancją AppDatabase**, wewnątrz jej transakcji. Nie używać providera streamu jako źródła walidacji zapisu.

## 2. Mapa przyszłych plików

### Nowe pliki

| Pełna ścieżka | Odpowiedzialność |
|---|---|
| `/opt/fit/lib/features/planner/progression/domain/progression_models.dart` | Reguła, cel, źródło, snapshot; niemutowalne modele, bez Drift/Flutter |
| `/opt/fit/lib/features/planner/progression/domain/progression_codec.dart` | Ścisły parser/serializer kontraktu 3a, walidacja referencji |
| `/opt/fit/lib/features/planner/progression/domain/progression_engine.dart` | Normalizacja kg→gramy, wynik z powodem, silnik |
| `/opt/fit/lib/features/planner/progression/domain/progression_fingerprint.dart` | Kanonikalizacja źródła i tokenu, SHA-256 |
| `/opt/fit/lib/features/planner/progression/data/progression_repository.dart` | Odczyt sugestii, zapis reguły, atomowa akceptacja, ochrona konta |
| `/opt/fit/lib/features/planner/progression/providers/progression_providers.dart` | Auth-scoped stream sugestii i akcje UI |
| `/opt/fit/lib/features/planner/progression/presentation/widgets/progression_rule_dialog.dart` | Formularz z walidacją i usuwaniem reguły |
| `/opt/fit/lib/features/planner/progression/presentation/widgets/plan_progression_section.dart` | Reguła, zaakceptowany cel, sugestia, konflikt i przyciski |
| `/opt/fit/lib/features/workout/presentation/widgets/session_target_hint.dart` | Informacja o zamrożonym celu, bez zapisu wykonania |
| `/opt/fit/lib/core/database/tables/progression_receipts_table.dart` | Lokalny, niesynchronizowany ślad idempotentnej akceptacji |
| `/opt/fit/test/features/planner/progression/progression_models_test.dart` | JSON, referencje, daty, granice |
| `/opt/fit/test/features/planner/progression/progression_engine_test.dart` | Determinizm i kompletna macierz warunków |
| `/opt/fit/test/features/planner/progression/progression_fingerprint_test.dart` | Wrażliwość fingerprintu, stabilne sortowanie |
| `/opt/fit/test/features/planner/progression/progression_repository_test.dart` | Akceptacja, rollback, aktualność, konto |
| `/opt/fit/test/features/planner/progression/progression_ui_test.dart` | Edycja, sugestia, stany UI |
| `/opt/fit/test/features/workout/session_target_hint_test.dart` | Podpowiedź nie tworzy serii, nie nadpisuje wpisanego tekstu |
| `/opt/fit/test/core/progression_migration_test.dart` | Realne otwarcie bazy v7 i migracja |

### Zmiany istniejących plików

- `/opt/fit/lib/core/database/tables/plans_table.dart`, `/opt/fit/lib/core/database/tables/sync_tables.dart`, `/opt/fit/lib/core/database/app_database.dart`: pola i migracja.
- `/opt/fit/lib/core/database/daos/sync_dao.dart`: trwałe `planWrite`, scalanie, blokowanie łańcucha.
- `/opt/fit/lib/core/database/daos/plans_dao.dart`: transakcyjny odczyt żywego planu i aktualizacja snapshotu (nie zastępować zmian etapu 1).
- `/opt/fit/lib/core/sync/sync_models.dart`, `/opt/fit/lib/core/sync/sync_store.dart`, `/opt/fit/lib/core/sync/sync_service.dart`: envelope, pull, round-trip, konflikty i retry.
- `/opt/fit/lib/core/services/backup_service.dart`: backup v3 i restore.
- `/opt/fit/lib/features/planner/data/planner_repository.dart`: `SavedPlan.syncId`, nullable progresja, pełny payload wszystkich zapisów/usunięć.
- `/opt/fit/lib/features/planner/presentation/pages/planner_page.dart`: sekcja progresji przy zapisanym planie; nie przy niezapisanej propozycji generatora.
- `/opt/fit/lib/features/workout/providers/workout_providers.dart`, `/opt/fit/lib/features/workout/data/workout_repository.dart`: punkt integracji snapshotu startu, zgodnie z wynikiem etapu 1.
- `/opt/fit/lib/features/workout/presentation/pages/active_session_page.dart`: widoczna podpowiedź i opcjonalne jawne wstawienie wartości.
- `/opt/fit/test/core/sync_persistence_test.dart`, `/opt/fit/test/core/sync_service_test.dart`, `/opt/fit/test/core/deferred_sync_test.dart`, `/opt/fit/test/core/restore_sync_regression_test.dart`, `/opt/fit/test/features/settings/backup_service_test.dart`: regresje istniejącej infrastruktury.
- `/opt/fit/lib/core/database/app_database.g.dart`, `/opt/fit/lib/core/database/daos/plans_dao.g.dart`, `/opt/fit/lib/core/database/daos/sync_dao.g.dart`: wynik generatora, nie ręczna edycja. Jeśli generator zmieni inne mixiny DAO wskutek wspólnego schematu, sprawdzić i uwzględnić te artefakty.

## 3. Kontrakt modeli i JSON — bez odstępstw od 3a

### Typy domenowe

Poniższy kompletny blok deklaracji przeznaczony jest do `/opt/fit/lib/features/planner/progression/domain/progression_models.dart`. Rekordy Darta mają nazwane pola; mapy należy tworzyć przez `Map.unmodifiable`. Nie ma potrzeby Freezed w tym module; manualny codec umożliwia ścisłą walidację zamiast tolerancyjnego generatora.

```dart
typedef ProgressionRule = ({
  String revision,
  int sets,
  int repMin,
  int repMax,
  int incrementGrams,
  int maxWeightGrams,
  int maxRpe,
});

typedef TargetSource = ({DateTime endedAt, String fingerprint});

typedef AcceptedTarget = ({
  String ruleRevision,
  int weightGrams,
  int sets,
  int repMin,
  int repMax,
  DateTime acceptedAt,
  TargetSource source,
});

class PlanProgression {
  PlanProgression({
    required this.revision,
    required Map<String, ProgressionRule> rules,
    required Map<String, AcceptedTarget> acceptedTargets,
  }) : rules = Map.unmodifiable(rules),
       acceptedTargets = Map.unmodifiable(acceptedTargets);

  final String revision;
  final Map<String, ProgressionRule> rules;
  final Map<String, AcceptedTarget> acceptedTargets;
}

typedef PlanWrite = ({int schemaVersion, String? baseRevision});
typedef TargetDraft = ({int weightGrams, int sets, int repMin, int repMax});

enum ProgressionReason {
  increase, maintain, equipmentLimit,
  unsupportedExercise, noHistory, setCount,
  invalidWeight, mixedWeight, invalidReps, missingOrInvalidRpe,
  sourceAboveLimit,
}

typedef ProgressionDecision = ({
  ProgressionReason reason,
  TargetDraft? target,
});
```

### Nazwy w wire

```json
{
  "schemaVersion": 1,
  "revision": "30000000-0000-4000-8000-000000000001",
  "rules": {
    "cw001": {
      "revision": "40000000-0000-4000-8000-000000000001",
      "sets": 3,
      "repMin": 8,
      "repMax": 12,
      "incrementGrams": 1250,
      "maxWeightGrams": 20000,
      "maxRpe": 8
    }
  },
  "acceptedTargets": {
    "cw001": {
      "ruleRevision": "40000000-0000-4000-8000-000000000001",
      "weightGrams": 11250,
      "sets": 3,
      "repMin": 8,
      "repMax": 12,
      "acceptedAt": "2026-09-28T10:05:00.000Z",
      "source": {
        "endedAt": "2026-09-27T18:00:00.000Z",
        "fingerprint": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      }
    }
  }
}
```

Fingerprint powyżej jest przykładem składni, nie obliczonym hashem.

Envelope operacji ma **osobne**, opcjonalne `planWrite`. Gdy go nie ma, serializer pomija klucz (nie emituje `null`). Dla v1:

```dart
final PlanWrite write = (schemaVersion: 1, baseRevision: null);
final json = <String, Object?>{
  'schemaVersion': write.schemaVersion,
  'baseRevision': write.baseRevision,
};
```

Na aktualizacji `baseRevision` to rewizja sprzed lokalnej mutacji; pełny payload ma nowe UUID v4 planu. Nazwa, lista ćwiczeń i `cel` również zmieniają rewizję całego planu. Reguła zachowuje własną rewizję, jeśli wartości nie zmieniły się. Edycja reguły nadaje jej nowe UUID i usuwa jej zaakceptowany cel. Delete zachowuje **dokładny ostatni payload i tę samą rewizję**; nie generuje nowej. Czytanie planu legacy niczego nie zapisuje i nie włącza domyślnych reguł.

### Publiczne API codec do zaimplementowania

Plik `/opt/fit/lib/features/planner/progression/domain/progression_codec.dart`:

```dart
abstract interface class ProgressionCodec {
  PlanProgression decode(Object? value, {required List<String> exerciseIds});
  Map<String, Object?> encode(PlanProgression value);
  ProgressionRule decodeRule(Object? value);
}
```

Docelowa implementacja: `StrictProgressionCodec implements ProgressionCodec`. To **nowe** API planu, nie istniejąca klasa. Cały parser ma odrzucać błędy przez `FormatException`; konstrukcja rekordu poza codec nie oznacza walidacji. Repozytorium przed zapisem wykonuje encode→decode z bieżącymi ID.

Walidacja:

- Dokładny zbiór kluczy na każdym poziomie (także `source`), wszystkie wymagane pola obecne, bez `extra`.
- `schemaVersion == 1`, wyłącznie integer; dodatnie int do `9007199254740991`; brak bool/string/float. `maxRpe` 1–10; `repMin <= repMax`; `incrementGrams <= maxWeightGrams`.
- UUID: regex `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`.
- Daty: `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?Z$`, rzeczywista data kalendarzowa. Sam `DateTime.parse` normalizuje nieistniejące daty: porównać rok/miesiąc/dzień/godzinę/minutę/sekundę z wejściem po parsowaniu; odrzucić np. 30 lutego i 24:00. Encode zawsze `toUtc().toIso8601String()`.
- Mapy: niepusty string ID należący do `exerciseIds`; duplikaty w liście starego planu dozwolone. Nie stosować regexu `cw...`.
- Cel wymaga istniejącej reguły, zgodnego `ruleRevision`, identycznych `sets/repMin/repMax`, dodatniego ciężaru nie większego niż maksimum reguły.
- Fingerprint: `^[0-9a-f]{64}$`. Brak FK do sesji; `source` zawiera tylko `endedAt/fingerprint`.
- Brak `progression` to legacy; `progression:null`, string JSON, zła wersja lub uszkodzony obiekt to błąd, **nigdy** puste mapy.
- Nieznana przyszła wersja blokuje zapis/pull strony bez przesunięcia kursora; komunikat aktualizacji aplikacji, bez „naprawiania” przez wyzerowanie.

**Ryzyko Web wymagające domknięcia parsera:** Dart skompilowany do JS nie zapewnia po `jsonDecode` rozróżnienia leksykalnego `1` i `1.0` przez samo `is int`. Walidator backupu i wejściowego JSON sync musi albo zachować rodzaj tokenów liczbowych przed dekodowaniem, albo korzystać ze sprawdzonego ścisłego dekodera. Nie deklarować pełnej zgodności strict na Web na podstawie testów VM. Wyjściowy JSON zawsze serializuje pola kontraktu jako integer. To otwarta luka kodu parsera w tym dokumencie, nie zgoda na poluzowanie kontraktu 3a.

## 4. Zadanie TDD: modele i walidacja

**Pliki:** `/opt/fit/lib/features/planner/progression/domain/progression_models.dart`, `/opt/fit/lib/features/planner/progression/domain/progression_codec.dart`, `/opt/fit/test/features/planner/progression/progression_models_test.dart`.

- [ ] RED: w teście zadeklarować dokładny fixture poniżej i sprawdzić round-trip.

```dart
Map<String, Object?> ruleJson() => {
  'revision': '40000000-0000-4000-8000-000000000001',
  'sets': 3, 'repMin': 8, 'repMax': 12,
  'incrementGrams': 1250, 'maxWeightGrams': 20000, 'maxRpe': 8,
};

Map<String, Object?> progressionJson() => {
  'schemaVersion': 1,
  'revision': '30000000-0000-4000-8000-000000000001',
  'rules': {'cw001': ruleJson()},
  'acceptedTargets': <String, Object?>{},
};

test('ścisłe round-trip reguły, bez zmiany gramów', () {
  final codec = StrictProgressionCodec();
  final raw = progressionJson();
  expect(codec.encode(codec.decode(raw, exerciseIds: ['cw001'])), raw);
});

test('odrzuca niepoprawne typy i granice', () {
  final codec = StrictProgressionCodec();
  for (final entry in <(String, Object?)>[
    ('sets', 0), ('sets', true), ('sets', '3'), ('sets', 3.5),
    ('repMin', 13), ('maxRpe', 0), ('maxRpe', 11),
    ('incrementGrams', 0), ('incrementGrams', 20001),
    ('maxWeightGrams', 9007199254740992), ('extra', 1),
  ]) {
    final raw = ruleJson()..[entry.$1] = entry.$2;
    expect(() => codec.decodeRule(raw), throwsFormatException);
  }
});
```

- [ ] RED: `flutter test /opt/fit/test/features/planner/progression/progression_models_test.dart` z `workdir=/opt/fit`; oczekiwany brak codec, potem nieprzechodzące asercje walidacji.
- [ ] GREEN: dodać deklaracje modeli z §3 i ścisły codec według wymienionych inwariantów. Pełny kod codec jest luką planu — wymaga dopisania przed realizacją tego checkboxa.
- [ ] RED/GREEN: osobne przypadki celu bez reguły, niezgodnej rewizji, limitu, niezgodnych reps/sets, obcego ID, `null`, nieznanej wersji, niekanonicznego UUID i daty 30 lutego. Fixture prawidłowego celu to dokładny JSON z §3.
- [ ] GREEN: ponowić test; dodać wykonanie przeglądarkowe: `flutter test --platform chrome /opt/fit/test/features/planner/progression/progression_models_test.dart`. Testy leksykalne używają surowych tekstów JSON z `1.0`, `1e0`, `true`, nie tylko map utworzonych w Dart.

## 5. Zadanie TDD: silnik w integer gramach

**Pliki:** `/opt/fit/lib/features/planner/progression/domain/progression_engine.dart`, `/opt/fit/test/features/planner/progression/progression_engine_test.dart`.

### Decyzje algorytmu

- Typ ćwiczenia musi być obsługiwany: nie izometria; źródło musi mieć dodatni ciężar i dodatnie powtórzenia w każdej serii. Sama lista sprzętu nie rozstrzyga obciążenia — ćwiczenie z masą ciała bez dodatniego ciężaru nie dostanie celu.
- Brak ćwiczenia w katalogu → brak automatycznej sugestii. Istniejący cel zachować jako dane, ale nie podpowiadać dla nieobsługiwanego typu.
- Wziąć ostatnie wykonanie, **nie ostatnie spełniające regułę**. Nie odfiltrowywać brakujących RPE, rozgrzewek, nadmiarowych serii ani zmiennego ciężaru.
- Kompletne, jednociężarowe wyniki poniżej progu reps albo powyżej maxRpe → utrzymanie ciężaru. Brak/nieprawidłowe RPE → brak akceptowalnej rekomendacji.
- Przy spełnionym progu i kroku ponad maksimum: utrzymanie z powodem `equipmentLimit`, nie przycinanie kroku do limitu i nie redukcja.
- Źródłowy ciężar już ponad limitem: `sourceAboveLimit`, brak celu (inaczej łamałby kontrakt albo sugerował redukcję).
- Obliczenia nie korzystają z poprzedniego zaakceptowanego celu, daty bieżącej ani UUID. Limit sprawdzać przez odejmowanie przed dodaniem, żeby uniknąć przepełnienia safe integer Web.
- Dla historii przyjmujemy dokładną reprezentację dziesiętną `double.toString()`. Wartość `10.000000000000002` nie zostaje zaokrąglona do 10 kg; brak akceptowalnego celu. Nie zmieniać oryginalnych serii.

### Kod rdzenia

```dart
import 'package:fitbirek_training/features/workout/history/domain/exercise_history.dart';
import 'progression_models.dart';

const maxSafeInteger = 9007199254740991;

// UI przekazuje tekst po zamianie pojedynczego przecinka na kropkę.
// Brak tolerancji/round(); BigInt zapewnia identyczny wynik VM i Web.
int? exactPositiveGrams(String input) {
  final match = RegExp(r'^(\d+)(?:\.(\d+))?(?:[eE]([+-]?\d+))?$')
      .firstMatch(input.trim());
  if (match == null) return null;
  final fraction = match.group(2) ?? '';
  final exponent = int.tryParse(match.group(3) ?? '0');
  if (exponent == null || exponent.abs() > 400 || input.length > 512) return null;
  final coefficient = BigInt.parse('${match.group(1)}$fraction');
  final scale = 3 + exponent - fraction.length;
  BigInt grams;
  if (scale >= 0) {
    grams = coefficient * BigInt.from(10).pow(scale);
  } else {
    final divisor = BigInt.from(10).pow(-scale);
    if (coefficient.remainder(divisor) != BigInt.zero) return null;
    grams = coefficient ~/ divisor;
  }
  if (grams <= BigInt.zero || grams > BigInt.from(maxSafeInteger)) return null;
  return grams.toInt();
}

int? historyGrams(double? kg) => kg == null || !kg.isFinite || kg <= 0
    ? null : exactPositiveGrams(kg.toString());

ExercisePerformance? latestPerformance(List<ExercisePerformance> history) {
  final ordered = [...history]..sort((a, b) {
    final date = b.finishedAt.compareTo(a.finishedAt);
    return date != 0 ? date : b.sessionSyncId.compareTo(a.sessionSyncId);
  });
  return ordered.firstOrNull;
}

ProgressionDecision evaluateProgression({
  required ProgressionRule rule,
  required ExercisePerformance? source,
  required bool supportsWeightAndReps,
}) {
  ProgressionDecision none(ProgressionReason reason) => (reason: reason, target: null);
  if (!supportsWeightAndReps) return none(ProgressionReason.unsupportedExercise);
  if (source == null) return none(ProgressionReason.noHistory);
  if (source.sets.length != rule.sets) return none(ProgressionReason.setCount);
  final grams = source.sets.map((s) => historyGrams(s.weightKg)).toList();
  if (grams.any((g) => g == null)) return none(ProgressionReason.invalidWeight);
  final weight = grams.first!;
  if (grams.any((g) => g != weight)) return none(ProgressionReason.mixedWeight);
  if (source.sets.any((s) => s.reps == null || s.reps! <= 0 || s.reps! > maxSafeInteger)) {
    return none(ProgressionReason.invalidReps);
  }
  if (source.sets.any((s) => s.rpe == null || s.rpe! < 1 || s.rpe! > 10)) {
    return none(ProgressionReason.missingOrInvalidRpe);
  }
  if (weight > rule.maxWeightGrams) return none(ProgressionReason.sourceAboveLimit);
  final reached = source.sets.every((s) => s.reps! >= rule.repMax && s.rpe! <= rule.maxRpe);
  final fits = rule.incrementGrams <= rule.maxWeightGrams - weight;
  final reason = !reached ? ProgressionReason.maintain
      : fits ? ProgressionReason.increase : ProgressionReason.equipmentLimit;
  return (
    reason: reason,
    target: (
      weightGrams: reached && fits ? weight + rule.incrementGrams : weight,
      sets: rule.sets, repMin: rule.repMin, repMax: rule.repMax,
    ),
  );
}
```

Silnik przyjmuje **uprzednio zwalidowaną** regułę. Repo filtruje historię tego samego ID, nie przekazuje wykonania innego ćwiczenia. Klasyfikacja `supportsWeightAndReps` ma korzystać z tego samego zbioru typów izometrycznych co aktywna sesja; przenieść istniejącą stałą do współdzielonej funkcji, nie utrzymywać dwóch rozbieżnych list. Nie zmieniać modelu katalogu ani ID.

### Konkretne testy

Test importuje fixture `sampleSet/samplePerformance` z `/opt/fit/test/features/workout/history/history_fixtures.dart` etapu 2; nie zmienia ich podpisów.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/planner/progression/domain/progression_models.dart';
import 'package:fitbirek_training/features/planner/progression/domain/progression_engine.dart';
import '../../workout/history/history_fixtures.dart';

const ProgressionRule rule = (
  revision: '40000000-0000-4000-8000-000000000001',
  sets: 3, repMin: 8, repMax: 12,
  incrementGrams: 1250, maxWeightGrams: 20000, maxRpe: 8,
);

void main() {
  test('ułamkowy krok dodaje dokładnie 1250 gramów', () {
    final source = samplePerformance(sets: [
      for (var i = 0; i < 3; i++) sampleSet(id: 's$i', number: i + 1, reps: 12, rpe: 8),
    ]);
    final result = evaluateProgression(rule: rule, source: source, supportsWeightAndReps: true);
    expect(result.reason, ProgressionReason.increase);
    expect(result.target, (weightGrams: 11250, sets: 3, repMin: 8, repMax: 12));
    expect(evaluateProgression(rule: rule, source: source, supportsWeightAndReps: true), result);
  });
  test('brak RPE i nadmiar serii nie są pomijane', () {
    final sets = [for (var i = 0; i < 3; i++) sampleSet(id: 's$i', reps: 12, rpe: null)];
    expect(evaluateProgression(rule: rule, source: samplePerformance(sets: sets),
      supportsWeightAndReps: true).reason, ProgressionReason.missingOrInvalidRpe);
    expect(evaluateProgression(rule: rule,
      source: samplePerformance(sets: [...sets, sampleSet(id: 'extra')]),
      supportsWeightAndReps: true).reason, ProgressionReason.setCount);
  });
  test('limit nie przycina kroku ani nie obniża ciężaru', () {
    final source = samplePerformance(sets: [
      for (var i = 0; i < 3; i++) sampleSet(id: 's$i', kg: 19, reps: 12),
    ]);
    final result = evaluateProgression(rule: rule, source: source, supportsWeightAndReps: true);
    expect(result.reason, ProgressionReason.equipmentLimit);
    expect(result.target!.weightGrams, 19000);
  });
  test('normalizacja jest dokładna, a nie zaokrąglająca', () {
    expect(exactPositiveGrams('1.250'), 1250);
    expect(exactPositiveGrams('1e-3'), 1);
    expect(exactPositiveGrams('0.0001'), isNull);
    expect(historyGrams(10.000000000000002), isNull);
    expect(historyGrams(double.nan), isNull);
    expect(exactPositiveGrams('9007199254740.991'), maxSafeInteger);
    expect(exactPositiveGrams('9007199254740.992'), isNull);
  });
}
```

- [ ] RED: zapisać testy przed silnikiem; uruchomić `flutter test /opt/fit/test/features/planner/progression/progression_engine_test.dart`.
- [ ] GREEN: dodać kod rdzenia; ponowić komendę, oczekiwany PASS.
- [ ] RED/GREEN: osobno testować brak historii, nieobsługiwany typ, 2 zamiast 3 serii, 4 zamiast 3, różne ciężary, null/0/ujemny ciężar, null/0 reps, RPE 1 i 10, RPE 11, kompletne reps 11, kompletne RPE 9, ciężar ponad maksimum. Dla braków `target == null`; reps 11/RPE 9 dają utrzymanie.
- [ ] RED/GREEN: limit dokładnie osiągnięty przez krok daje `increase`; duże safe integer nie przepełnia się; identyczna data źródeł wybiera większy `sessionSyncId`; ostatnia niekompletna sesja blokuje zwiększenie mimo starszej kompletnej.
- [ ] GREEN: uruchomić testy VM i `flutter test --platform chrome /opt/fit/test/features/planner/progression/progression_engine_test.dart`.

## 6. Zadanie TDD: fingerprint i token aktualności

**Pliki:** `/opt/fit/lib/features/planner/progression/domain/progression_fingerprint.dart`, `/opt/fit/test/features/planner/progression/progression_fingerprint_test.dart`.

Rozdzielamy:

1. **Fingerprint źródła**: SHA-256 kanonicznego wykonania; trwały `source.fingerprint`, bez danych konta i planu. Archiwalny po restore, nie ponownie wyliczany w celu.
2. **Token sugestii**: SHA-256 lokalnego kontekstu + fingerprint + wersja planu/reguły + wyliczona propozycja. Nie trafia do payloadu planu ani backupu. Nie jest tokenem autoryzacyjnym.
3. **Kontekst auth**: `accountId` i licznik generacji w pamięci. Zwiększać generację przy `loading`, logout, zmianie konta i utracie dostępu; chroni również wylogowanie/zalogowanie do tego samego konta podczas await. Nie używać samej daty zegara.

Kod kanonikalizacji (listy mają ustaloną kolejność i nie polegają na kolejności kluczy mapy):

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fitbirek_training/features/workout/history/domain/exercise_history.dart';
import 'progression_models.dart';

String digestJson(Object value) => sha256.convert(utf8.encode(jsonEncode(value))).toString();

String sourceFingerprint(ExercisePerformance p) {
  final sets = [...p.sets]..sort((a, b) {
    final number = a.number.compareTo(b.number);
    if (number != 0) return number;
    final time = a.timestamp.compareTo(b.timestamp);
    return time != 0 ? time : a.syncId.compareTo(b.syncId);
  });
  return digestJson([
    'fitbirek-progression-source-v1', p.exerciseId,
    p.sessionSyncId, p.sessionSyncVersion,
    p.sessionUpdatedAtUtc.toUtc().toIso8601String(),
    p.finishedAt.toUtc().toIso8601String(),
    'completed', 'not-deleted',
    for (final s in sets) [
      s.syncId, s.syncVersion, s.updatedAtUtc.toUtc().toIso8601String(),
      s.number, s.timestamp.toUtc().toIso8601String(),
      s.weightKg?.toString(), s.reps, s.seconds, s.rpe,
    ],
  ]);
}

String suggestionToken({
  required String accountId,
  required int authGeneration,
  required String planSyncId,
  required String planRevision,
  required String ruleRevision,
  required String catalogType,
  required String fingerprint,
  required TargetDraft target,
}) => digestJson([
  'fitbirek-progression-suggestion-v1', accountId, authGeneration,
  planSyncId, planRevision, ruleRevision, catalogType, fingerprint,
  target.weightGrams, target.sets, target.repMin, target.repMax,
]);
```

Aktualność zakończenia/usunięcia sprawdzana jest przez ponowny JOIN historii. Jeśli sesja przestaje istnieć w historii, nie ma tego samego źródła i akceptacja jest odrzucona. Hash obejmuje **wszystkie** ID i wartości serii, więc zamiana jednej serii na inną przy tej samej liczbie zmienia hash. `syncVersion` może konserwatywnie unieważnić sugestię po ack bez zmiany wyników; to dopuszczalne, UI wymaga ponownego potwierdzenia zamiast cichego zapisu.

Przykład testów:

```dart
test('kolejność wejściowej listy nie zmienia hasha, zamiana serii zmienia', () {
  final a = sampleSet(id: 'a', number: 1);
  final b = sampleSet(id: 'b', number: 2);
  final first = samplePerformance(sets: [a, b]);
  expect(sourceFingerprint(samplePerformance(sets: [b, a])), sourceFingerprint(first));
  expect(sourceFingerprint(samplePerformance(sets: [a, sampleSet(id: 'c', number: 2)])),
    isNot(sourceFingerprint(first)));
  expect(sourceFingerprint(samplePerformance(sets: [a, sampleSet(id: 'b', number: 2, rpe: 8)])),
    isNot(sourceFingerprint(first)));
});
```

- [ ] RED: zapisać test powyżej, następnie `flutter test /opt/fit/test/features/planner/progression/progression_fingerprint_test.dart`.
- [ ] GREEN: dodać kod kanonikalizacji, ponowić test.
- [ ] RED/GREEN: przetestować każdą istotną wartość osobno: ciężar, reps, sekundy, RPE, numer, timestamp, syncId, wersję, koniec sesji, inny plan/regułę/konto/generację auth/typ katalogowy.
- [ ] GREEN: VM i Chrome muszą dać identyczny hash dla jednego zamrożonego fixture; zapisać jeden literalny golden SHA po niezależnym wyliczeniu, nie generować oczekiwanej wartości tą samą funkcją.

## 7. Zadanie TDD: migracja z obecnej wersji Drift

**Pliki:** `/opt/fit/lib/core/database/tables/plans_table.dart`, `/opt/fit/lib/core/database/tables/sync_tables.dart`, `/opt/fit/lib/core/database/tables/progression_receipts_table.dart`, `/opt/fit/lib/core/database/app_database.dart`, `/opt/fit/test/core/progression_migration_test.dart`.

Nowe deklaracje w istniejących tabelach:

```dart
// WorkoutPlans — NULL oznacza wyłącznie legacy, nie pustą progresję v1.
TextColumn get progressionJson => text().nullable()();

// SyncOutbox — pole operacji, nie część payloadJson.
TextColumn get planWriteJson => text().nullable()();
// Lokalna trwała blokada; obiekt {kind, reason, record} z odpowiedzi.
TextColumn get blockedConflictJson => text().nullable()();
```

Lokalna tabela receipt jest potrzebna do odróżnienia ponownego kliknięcia tej samej sugestii od akceptacji po niepowiązanej edycji planu. Nie zmienia JSON kontraktu.

```dart
import 'package:drift/drift.dart';

@DataClassName('ProgressionReceiptData')
class ProgressionReceipts extends Table {
  TextColumn get token => text()();
  TextColumn get accountId => text()();
  TextColumn get planSyncId => text()();
  TextColumn get resultRevision => text()();
  TextColumn get sourceFingerprint => text()();

  @override
  Set<Column> get primaryKey => {token};
}
```

Dodać tabelę/import do `@DriftDatabase`. Jeśli v8 nadal wolne:

```dart
@override
int get schemaVersion => 8;

// W istniejącym onUpgrade, zachowując wszystkie dotychczasowe gałęzie:
if (from < 8) {
  await m.addColumn(workoutPlans, workoutPlans.progressionJson);
  await m.addColumn(syncOutbox, syncOutbox.planWriteJson);
  await m.addColumn(syncOutbox, syncOutbox.blockedConflictJson);
  await m.createTable(progressionReceipts);
}
```

Nie aktualizować starych payloadów, UUID, `attempted`, dat ani rewizji przy migracji. Legacy attempted musi po otwarciu generować **dokładnie ten sam** `toJson()` co przed aktualizacją. Puste mapy nie są backfillem nullable kolumny.

- [ ] RED: utworzyć fizyczną bazę v7 w katalogu testowym, z planem legacy, bindingiem, attempted operacją i kolejną niewysłaną. Najlepiej fixture prawdziwego v7; można zastosować obecny wzorzec testu downgrade tabel, ale wyłącznie na pliku testowym, nigdy produkcyjnym.
- [ ] RED: w `/opt/fit/test/core/progression_migration_test.dart` oczekiwać po ponownym otwarciu: plan istnieje, `progressionJson == null`, dwa payloady bez `planWrite`, attempted niezmieniony, receipts puste, binding i kursory zachowane. Nie wywoływać zapisu repo podczas samego testu migracji.
- [ ] RED: `flutter test /opt/fit/test/core/progression_migration_test.dart` — oczekiwany brak nowych pól/schematu.
- [ ] GREEN: dodać deklaracje i migrację; wykonać `dart run build_runner build --delete-conflicting-outputs` z `/opt/fit`.
- [ ] GREEN: uruchomić test migracji i `/opt/fit/test/core/sync_persistence_test.dart`. Dostosować istniejący test symulujący v2: oprócz dotychczasowych kolumn usunąć nowe kolumny i receipts przed ustawieniem `PRAGMA user_version = 2`, inaczej migracja będzie próbowała dodać istniejące kolumny.
- [ ] GREEN: test fresh create i migracji z v7 oraz aktualnego schematu etapu 1. Nie zastępować upgrade testem samego `NativeDatabase.memory()` na nowym schemacie.

## 8. Zadanie TDD: pełny zapis planu, outbox, pull i konflikty

**Pliki:** `/opt/fit/lib/features/planner/data/planner_repository.dart`, `/opt/fit/lib/core/database/daos/sync_dao.dart`, `/opt/fit/lib/core/sync/sync_models.dart`, `/opt/fit/lib/core/sync/sync_store.dart`, `/opt/fit/lib/core/sync/sync_service.dart`; cztery testy sync z mapy.

### Rozszerzenie SyncOperation

Do konstruktora i `fromPersisted` dodać nullable `PlanWrite? planWrite`; do `toJson()`:

```dart
if (planWrite case final write?)
  'planWrite': {
    'schemaVersion': write.schemaVersion,
    'baseRevision': write.baseRevision,
  },
```

Nie synchronizować `preserveLocal`, `blockedConflictJson` ani receipts. `PlanWrite` odczytywać z `planWriteJson` przez walidację, nie z `payload.progression.revision` — to **inne rewizje**. `SyncOperation` ma nadal zawierać oryginalny payload attempted.

### Zapis i scalenie — decyzje obowiązkowe

| Przypadek | Baza operacji | Payload końcowy / działanie |
|---|---|---|
| Nowy plan v1 | `baseVersion=0`, `baseRevision=null` | Nowy UUID planu, puste mapy lub jawne reguły |
| Jawny upgrade legacy | znane `baseVersion`, `baseRevision=null` | Nowa rewizja v1, brak automatycznych reguł |
| Niewysłane A→B, potem B→C | zachować bazę A | jedna nowa niewysłana operacja z C |
| Attempted A→B, potem B→C | osobno A i B | dwa wpisy; C wysłać dopiero po rozstrzygnięciu B |
| ACK pierwszej operacji | wolno podnieść `baseVersion` następnej | nie zmieniać `baseRevision=B` |
| Pull gdy dirty | zwalidować i odłożyć pełny snapshot | nie zastępować lokalnego payloadu, nie zmieniać `planWrite` |
| Konflikt A→B | zablokować również zależne B→C | nie próbować wysłać C na przypadkowo nowej bazie |
| Delete chronionego planu | bazą ostatnia rewizja | payload identyczny z ostatnim snapshotem |
| Upsert po tombstone | niedozwolony | utworzenie nowego planu tylko z nowym UUID |

**Pułapka upsert→delete przed wysłaniem:** nie scalać chronionego niewysłanego A→B z usunięciem B w jedną operację delete na bazie A z payloadem B; backend prawidłowo odrzuci `deletePayloadMismatch`. Zachować poprzednik upsert oraz delete jako osobny łańcuch, nawet gdy oba nieattempted, i wysyłać kolejno. Analogicznie nowy offline plan może wysłać create, potem delete; nie wysyłać delete „nieznanego snapshotu” w miejsce create. To wyjątek od ogólnego scalania do najnowszego snapshotu, wymagany przez 3a.

Kolejność wpisów musi być trwała i jednoznaczna. Obecne sortowanie po `createdAtUtc` może remisować. Zamiast zakładać kolejność losowych UUID, przy dodawaniu zależnej operacji nadać `createdAtUtc` większe od największego poprzednika co najmniej o **1 sekundę** (Drift domyślnie zapisuje DateTime z dokładnością sekund). To techniczny znacznik kolejki, nie data wykonania/akceptacji. Alternatywa z osobnym monotonicznym `sequence` wymaga rozszerzenia migracji — nie wprowadzać jej częściowo.

Blokowanie:

- Rozpoznać `kind=planContract`, powody dokładnie: `requiresUpgrade`, `revisionMismatch`, `deletedPlan`, `invalidRevision`, `deletePayloadMismatch`, `ruleRevisionReuse`.
- Zachować odpowiedź w `blockedConflictJson` dla encji; oznaczyć cały jej zależny łańcuch. `pendingOperations()` służące wysyłce pomija zablokowane encje. Nie usuwać dowodów nierozstrzygniętego attempted przy timeout.
- Zwykły `SyncConflict` planu v1 też zatrzymać do analizy; **żadnego automatycznego `preserveLocal` rebase**.
- Po zablokowaniu jednej encji wysyłać pozostałe w następnej rundzie i nadal wykonywać pull; `SyncStatus.conflict` trwa, dopóki istnieje blokada.
- UI pokazuje przyczynę i opcję przyjęcia wersji serwera, z jawnym potwierdzeniem odrzucenia lokalnych zmian. Tylko gdy wynik operacji jest definitywnie znany, transakcyjnie usunąć jej łańcuch, zastosować najnowszy deferred snapshot i usunąć receipts. Reaplikacja lokalnych intencji to nowy odczyt + nowa jawna akcja, nowe UUID operacji i rewizji, nie zmiana starego żądania.
- Zdalny tombstone dirty planu natychmiast oznacza lokalny plan usunięty, tak jak obecnie sesja; zachować attempted niezmienione. Strażnik akceptacji sprawdza tombstone i deferred. Nie stosować do planu obecnej gałęzi przywracającej marker sesji po starszym ACK.

### Konwersja wire ↔ DB

W `SyncStore.apply` przed `WorkoutPlanData.fromJson`:

```dart
// Fragment adaptera; codec i exerciseIds są lokalnie uzyskane z payloadu.
if (json.containsKey('progression')) {
  final validated = codec.decode(json.remove('progression'), exerciseIds: exerciseIds);
  json['progressionJson'] = jsonEncode(codec.encode(validated));
} else {
  json['progressionJson'] = null;
}
```

Nie pozwolić, aby nowszy legacy snapshot wyzerował istniejący chroniony plan; stary replay niższej wersji można pominąć istniejącym strażnikiem. Nowszy downgrade oznacza błąd protokołu i rollback strony, nie konwersję do legacy. Zapis pełnego nullable snapshotu przez `toCompanion(false)` pozostaje.

`enqueueAll` i `_payload` repo muszą używać wspólnego codec planu: z local `progressionJson` robić wire `progression`, usuwać lokalną nazwę. Dla istniejącego chronionego planu `enqueueAll` nie może tworzyć upsertu z tą samą rewizją jako „nowej edycji”; przy restore nowe plany mają już świeżą rewizję i bazę null, a delete starych zachowuje oryginalną. Nie używać jednej heurystyki `baseRevision = current.revision` dla każdej ścieżki.

### TDD i przykładowe asercje

- [ ] RED: w `/opt/fit/test/core/sync_persistence_test.dart` rozszerzyć istniejący realny test zamknięcia/otwarcia SQLite o attempted plan v1 oraz drugą edycję. `api.requests[1].single.toJson()` musi być identyczne z żądaniem sprzed restartu, razem z `planWrite`.
- [ ] RED: w `/opt/fit/test/core/sync_service_test.dart` użyć istniejącego `FakeSyncApi` i odpowiedzi HTTP-envelope z 3a; asercje po konflikcie:

```dart
expect(response['accepted'], isEmpty);
expect((response['conflicts'] as List).single['kind'], 'planContract');
expect((await db.syncDao.pendingOperations()).where(
  (op) => op.entityId == protectedPlanId), isEmpty); // kolejka wysyłkowa
final retained = await (db.select(db.syncOutbox)
  ..where((o) => o.entityId.equals(protectedPlanId))).get();
expect(retained, isNotEmpty); // dane nie zostały usunięte
expect(retained.every((o) => o.blockedConflictJson != null), isTrue);
```

Ten fragment wymaga fixture `protectedPlanId/response` w teście; nie jest samodzielnym kompletnym testem.

- [ ] RED: `flutter test /opt/fit/test/core/sync_persistence_test.dart /opt/fit/test/core/sync_service_test.dart /opt/fit/test/core/deferred_sync_test.dart`.
- [ ] GREEN: rozszerzyć modele, DAO, repo i store zgodnie z tabelą; generator po zmianach DAO/Drift. Pełny kod scalenia/blokowania jest luką do dopisania przed implementacją.
- [ ] RED/GREEN: testy niewysłanego A→B→C, attempted A→B + B→C, konfliktu poprzednika, pull podczas dirty, delete po niewysłanym upsercie, retry legacy bez `planWrite:null`, retry v1 z identycznym operationId, zdalnego usunięcia i aktualizacji zwykłej nazwy planu z zachowaniem reguł.
- [ ] RED/GREEN: test konfliktu planu i niezależnego zapisu mood w jednym batchu: po rollback mood trafia w kolejnej rundzie, plan pozostaje blokowany, pull działa. Zwykły konflikt v1 z `preserveLocal:true` nie tworzy nowej operacji automatycznie.
- [ ] GREEN: test round-trip przez dwa lokalne magazyny sync oraz zgodność JSON z fixture backendu 3a; żadne `progressionJson`, receipts ani `blockedConflictJson` nie wychodzą na wire.

## 9. Zadanie TDD: atomowa akceptacja i edycja reguł

**Pliki:** `/opt/fit/lib/features/planner/progression/data/progression_repository.dart`, `/opt/fit/lib/features/planner/progression/providers/progression_providers.dart`, `/opt/fit/test/features/planner/progression/progression_repository_test.dart`.

### Nowe kontrakty lokalne

```dart
typedef SuggestionTicket = ({
  String accountId,
  int authGeneration,
  String planSyncId,
  String planRevision,
  String exerciseId,
  String ruleRevision,
  String sessionSyncId,
  String fingerprint,
  String token,
  TargetDraft target,
});

enum AcceptanceStatus { accepted, alreadyAccepted, stale, unavailable }
typedef AcceptanceResult = ({AcceptanceStatus status, SuggestionTicket? replacement});
```

`ProgressionRepository` otrzymuje DB, `ExerciseHistoryRepository(db)`, codec, zegar UTC, generator UUID, synchroniczny getter aktualnego `(accountId, authGeneration)` i strażnik katalogu. Te zależności umożliwiają kontrolowane testy; implementacja nie odczytuje `DateTime.now` ani auth globalnie. API akcji:

```dart
abstract interface class ProgressionActions {
  Future<AcceptanceResult> accept(SuggestionTicket ticket);
  Future<void> saveRule({
    required String accountId,
    required int authGeneration,
    required String planSyncId,
    required String expectedPlanRevision,
    required String exerciseId,
    required ProgressionRule? rule,
  });
}
```

`rule:null` w lokalnej metodzie oznacza usunięcie wpisu, **nie** wpis null w JSON. Dla legacy bez rewizji edycja wymaga osobnego odczytu identyfikującego pełny snapshot legacy i jawnego upgrade; nie udawać pustego UUID w `expectedPlanRevision`. Przed implementacją dodać typ warunku edycji obejmujący legacy (opisany brak kodu API); akceptacja sugestii zachodzi już na planie v1 z zapisaną regułą.

### Transakcja akceptacji — kolejność ma znaczenie

1. Przed transakcją oraz po każdym `await` sprawdzić synchroniczny auth getter przeciw ticketowi. W transakcji odczytać `syncState`: zgodne konto i `offlineAccess=true`. Sama pusta historia nie wystarczy.
2. Odczytać plan po `syncId`, żywy, ten sam kontekst konta; brak/upsert po tombstone zabroniony. Jeśli istnieje nierozstrzygnięty zdalny snapshot lub blokada dla tego planu, zwrócić `unavailable`, nie akceptować na ukrytym starym stanie.
3. Odczytać bieżącą regułę, typ katalogowy i ostatnią historię przez `getCompletedHistory` wewnątrz tej samej transakcji. Sprawdzić także deferred źródłowej sesji/serii, jeśli istnieje oczekujący zdalny stan: nie uznawać lokalnego widoku dirty za aktualny wobec ujawnionej zmiany.
4. Przeliczyć decyzję, fingerprint, token. Brak akceptowalnego celu lub zmiana źródła/reguły → `stale`/`unavailable`; nic nie zapisywać. Wynik `replacement` może zawierać nową sugestię, ale nigdy nie akceptować jej automatycznie.
5. **Idempotencja przed porównaniem starej rewizji planu:** szukać receipt po tokenie. Zwrócić `alreadyAccepted` tylko gdy jego konto, aktualny fingerprint i bieżąca `progression.revision == receipt.resultRevision`, reguła oraz wartości aktualnego celu nadal odpowiadają ticketowi. Zachować istniejące `acceptedAt` i outbox bez zmian. To pozwala ponowić kliknięcie po własnej zmianie rewizji spowodowanej pierwszą akceptacją.
6. Gdy receipt nie pasuje, wymagać identycznej rewizji planu/reguły i całego tokenu. Sama zgodność ciężaru nie wystarcza; nowsza sesja z takim samym wynikiem to nowe źródło.
7. Utworzyć cel z `acceptedAt=clock().toUtc()`, źródłem `{endedAt: source.finishedAt, fingerprint}`, nową rewizją planu `uuid()`. `sets/repMin/repMax` skopiować z reguły. Zachować inne reguły i cele.
8. W tej samej transakcji: aktualizacja `progressionJson/updatedAtUtc`, enqueue pełnego payloadu z bazą wcześniejszej rewizji, zapis receipt z wynikową rewizją. Usunąć wcześniejsze receipts danego planu — nie przechowywać nieograniczonego logu kliknięć. Po niepowiązanym zapisie planu/pull/restore również je skasować.
9. Ostatni auth guard po zapisie/outbox, przed wyjściem z callbacku transakcji. Jeśli rzuci, rollback obejmuje wszystko. Zmiana auth po commit nie cofa legalnej operacji starego konta, ale UI nie może pokazać jej danych w nowym kontekście.

To jedna lokalna transakcja, bez HTTP, bez zapisu serii/PR. Zewnętrzna edycja DB jest serializowana przez SQLite; jeśli druga karta spowoduje `busy/snapshot` error, wycofać całość i odświeżyć sugestię, nie ponawiać zaakceptowania na nowych danych bez potwierdzenia.

Edycja reguły ma analogiczny guard konta/planu i transakcję z outbox. Te same wartości → no-op bez nowego UUID. Różne wartości → nowe UUID reguły i planu, usunięcie celu. Usunięcie ćwiczenia z planu usuwa jego regułę i cel w tym samym snapshotcie. Puste mapy v1 pozostają z rewizją; nigdy downgrade do legacy.

### Checklisty testów

- [ ] RED: seeding na `NativeDatabase.memory()` z bindingiem, planem v1 i trzema seriami zakończonej sesji, za pomocą fixture etapu 2; wyczyścić outbox seedingu przed pomiarem. `accept(ticket)` ma dodać jeden upsert planu i zero serii/PR.
- [ ] RED: drugie `accept` **tego samego ticketu** zwraca `alreadyAccepted`, bez zmiany `acceptedAt`, rewizji planu, operationId i liczby wpisów outbox. Użyć stałego zegara i UUID generatora z kolejką wartości.
- [ ] RED: wymusić wyjątek przy enqueue przez trigger SQLite `BEFORE INSERT ON sync_outbox ... RAISE(ABORT, ...)`; oczekiwać rollback `progressionJson`, receipts, updatedAt i outbox. Trigger tylko w teście.
- [ ] RED: osobne zmiany między pobraniem ticketu a accept: reps, RPE, ciężar, zastąpienie jednej serii innym UUID, usunięcie serii, usunięcie sesji, nowsza zakończona sesja, zmiana reguły, nazwy planu, usunięcie planu, zmiana katalogowego typu. Żadna nie zapisuje starego celu.
- [ ] RED: dwa równoległe `accept` tego samego ticketu kończą jednym zapisem; dopuszczalne `alreadyAccepted` drugiego lub kontrolowany błąd busy z późniejszym retry, nigdy drugi krok progresji.
- [ ] RED: kontrolowany barrier podczas await historii: auth→loading, logout/login tego samego konta, inne konto, `offlineAccess=false`; brak zapisu i brak późnego renderowania.
- [ ] RED: ten sam exerciseId w dwóch planach ma niezależne reguły/cele; historia wspólna, ale ticket planu A nie pasuje do B.
- [ ] RED: `flutter test /opt/fit/test/features/planner/progression/progression_repository_test.dart`.
- [ ] GREEN: zaimplementować sekwencję transakcji; pełny kod repository i fixtures nie został zawarty w tym dokumencie. Nie oznaczać zadania zakończonym przed testami rollback/idempotencji.
- [ ] GREEN: ponowić komendę i regresję `/opt/fit/test/features/workout/deleted_session_test.dart`.

## 10. Zadanie TDD: backup schemaVersion 3 i stary klient

**Pliki:** `/opt/fit/lib/core/services/backup_service.dart`, `/opt/fit/test/features/settings/backup_service_test.dart`, `/opt/fit/test/core/restore_sync_regression_test.dart`.

Eksport:

```dart
static const int currentSchemaVersion = 3;
```

Każdy wiersz `data.workoutPlans` zachowuje lokalne `id`, tekst `cwiczeniaIds`, datę Drift i pozostałe dotychczasowe pola backupu. Usunąć `progressionJson` i wstawić obiekt `progression`. Legacy row normalizować do pustego v1 z nową rewizją **wyłącznie w eksportowanym dokumencie**, bez mutacji DB/outbox. Wyeksportowana kopia nie aktywuje reguł w źródłowej bazie.

Import:

- Cały envelope parse/version/type check wewnątrz `try`; `schemaVersion` int 1/2/3, nie `true`, string, null ani nieznana wersja. Błąd → `ImportResult(success:false)`.
- Przed `enqueueAll(deleted:true)` i kasowaniem zwalidować wszystkie plany oraz ich progression. Dla v3 każdy plan ma obiekt; dla v1/v2 obecność klucza progression jest błędem niezgodnego formatu, nie ignorowanym rozszerzeniem.
- Dla v1/v2 brak progresji daje puste v1 podczas restore (nowe UUID/revision, bez domyślnych reguł). Nie zmieniać formatu pozostałych starych tabel.
- Odtworzyć nowy `syncId`, `syncVersion=0`, nową rewizję planu; zachować rewizje reguł, cele, acceptedAt, source dokładnie semantycznie. `planWrite.baseRevision=null`.
- Usunięcia zastępowanych chronionych planów mają oryginalne snapshoty i bazy; nie usuwać attempted ani nie scalać ich nielegalnie z delete (zob. §8).
- Usunąć lokalne receipts dla odtwarzanych/zastępowanych planów; nie eksportować receipts, tokenów auth ani blokad.
- Jeśli restore trafia na nierozstrzygnięty konflikt planu, nie udawać sukcesu synchronizacji. Lokalny restore jest atomowy, jego operacje mogą wymagać późniejszego jawnego rozstrzygnięcia zgodnie z 3a.

Przykład asercji w istniejącym teście backupu:

```dart
final bytes = await BackupService(db).exportToBytes();
final root = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
expect(root['schemaVersion'], 3);
final plans = (root['data'] as Map)['workoutPlans'] as List;
final plan = plans.single as Map;
expect(plan['cwiczeniaIds'], isA<String>());
expect(plan['progression'], isA<Map>());
expect(plan.containsKey('progressionJson'), isFalse);
expect(plan.containsKey('syncId'), isFalse);
```

- [ ] RED: round-trip reguły 1250 g i celu 11250 g; porównać wszystkie domenowe pola poza nową rewizją całego planu; sprawdzić nowe UUID i bazę null.
- [ ] RED: dwa plany w pliku, drugi z niezgodnym `ruleRevision`; wynik failure, baza i outbox identyczne przed/po, także jeśli pierwszy plan był poprawny.
- [ ] RED: backup v1 i v2 bez nowych pól, v2 z polem progression, v3 bez pola, `schemaVersion:'3'`, `schemaVersion:true`, nieznana wersja. Żaden błąd nie ucieka wyjątkiem poza `ImportResult`.
- [ ] RED: stary importer obsługujący do v2 odrzuca v3 **przed transakcją**. Test kompatybilności ma uruchomić zamrożony parser envelope starego klienta jako fixture testowy; nie zmieniać produkcyjnego starego klienta ani uruchamiać go na nowym pliku SQLite.
- [ ] RED: `flutter test /opt/fit/test/features/settings/backup_service_test.dart /opt/fit/test/core/restore_sync_regression_test.dart`.
- [ ] GREEN: dodać dwukierunkowy adapter backupu i walidację przed kasowaniem; ponowić testy.
- [ ] GREEN: sprawdzić wysyłkę delete starych i create nowych planów przez FakeSyncApi, w tym pending attempted przed restore.

**Granica gwarancji:** stary klient może utracić nieznane pola we własnym lokalnym eksporcie; nie da się tego naprawić nowym klientem. Chronione są dane serwera przez kontrakt 3a oraz nowy backup v3 przez odrzucenie w starym importerze. Stary restore tworzący nowe UUID nie odtwarza nieobecnych reguł. Nie obiecywać zgodności downgrade pliku SQLite ze starszą aplikacją; starsza karta powinna odświeżyć aplikację, a nie pisać do nowszego schematu.

## 11. Zadanie TDD: UI reguł i sugestii na zapisanym planie

**Pliki:** `/opt/fit/lib/features/planner/progression/providers/progression_providers.dart`, `/opt/fit/lib/features/planner/progression/presentation/widgets/progression_rule_dialog.dart`, `/opt/fit/lib/features/planner/progression/presentation/widgets/plan_progression_section.dart`, `/opt/fit/lib/features/planner/presentation/pages/planner_page.dart`, `/opt/fit/test/features/planner/progression/progression_ui_test.dart`.

Provider family kluczować `(accountId, planSyncId, exerciseId)`; obserwować auth, plan, historię, katalog oraz blokady/deferred wpływające na aktualność. `autoDispose`; przy loading/signedOut nie renderować poprzedniego AsyncData. Zmiana konta unieważnia ticket i zamyka/pasywuje formularz. Żadnego globalnego cache sugestii.

UI:

- Przy ćwiczeniu zapisanego planu przycisk „Ustaw regułę progresji” / „Edytuj regułę”. Brak reguły to neutralny stan, nie sugestia domyślna. Izometria/nieobsługiwane ćwiczenie: wyjaśnienie i historia, bez automatycznej progresji.
- Formularz: serie, min/max powtórzeń, krok kg, maksymalny ciężar kg, maksymalne RPE 1–10. Pola ciężaru akceptują przecinek albo kropkę; dokładna konwersja do integer gramów; błąd przy niezerowej precyzji poniżej 0,001 kg. Bez `double.parse()*1000.round()`.
- Usunięcie reguły wymaga potwierdzenia: „Usunięcie reguły usunie również zaakceptowany cel”. Anulowanie nie zapisuje niczego.
- Osobno pokazać „Zaakceptowany cel” i „Sugestia na podstawie treningu z …”. Nowsza historia nie nadpisuje zaakceptowanego celu automatycznie.
- Sugestia: ciężar, liczba serii, zakres powtórzeń, data i powód. `increase`, `maintain`, `equipmentLimit` mogą mieć aktywny przycisk „Zaakceptuj cel”; pozostałe tylko wyjaśnienie braków i przejście do historii.
- „Zignoruj” zamyka aktualną kartę/lokalne powiadomienie bez mutacji bazy, celu, rewizji, outbox. Nie synchronizować stanu ignorowania.
- Podczas accept wyłączyć przycisk, ale polegać także na atomowej ochronie repo. `stale`: „Dane się zmieniły. Sprawdź nową sugestię i potwierdź ponownie”; pokazać replacement bez automatycznej akceptacji.
- Konflikt planu nie jest sukcesem: wyświetlić przyczynę i osobne potwierdzenie przyjęcia wersji serwera. Brak sieci nie blokuje lokalnej akceptacji, jeśli binding offline jest poprawny i nie ma ujawnionego konfliktu.

Przykład walidacji tekstu kroku w formularzu:

```dart
String? validateWeightText(String? text) {
  final normalized = (text ?? '').trim().replaceAll(',', '.');
  if (exactPositiveGrams(normalized) == null) {
    return 'Podaj dodatni ciężar z dokładnością do 0,001 kg.';
  }
  return null;
}
```

Nie używać tego walidatora samodzielnie do sprawdzenia kroku <= maksimum; walidację relacyjną wykonuje codec przy submit i repo ponownie przed zapisem.

- [ ] RED: widget test otwiera formularz, wpisuje `1,25`, zapisuje i odczytuje `incrementGrams=1250` z DB oraz jedną operację planu.
- [ ] RED: `0`, `0,0001`, min>max, krok>limit, RPE poza zakresem nie zamykają dialogu i niczego nie zapisują.
- [ ] RED: anulowanie/ignorowanie pozostawia dokładnie poprzedni snapshot i outbox; zmiana reguły usuwa cel.
- [ ] RED: karta sugeruje 11,25 kg z datą źródła, accept zapisuje cel, liczba serii w DB się nie zmienia; podwójny tap nie zwiększa do 12,5 kg.
- [ ] RED: zmiana historii podczas otwartego UI pokazuje ponowną akceptację; utrata auth ukrywa dane, także po opóźnionej emisji poprzedniego providera.
- [ ] RED: `flutter test /opt/fit/test/features/planner/progression/progression_ui_test.dart`.
- [ ] GREEN: dodać widgety i provider; kompletnego kodu tych widgetów i harnessu testowego dokument nie zawiera.
- [ ] GREEN: ponowić test oraz test na wąskim ekranie z klawiaturą i dużym text scale; komunikaty i pola nie mogą być ucięte.

## 12. Zadanie TDD: snapshot celów przy starcie z planu — punkt integracji etapu 1

**Pliki:** `/opt/fit/lib/features/workout/providers/workout_providers.dart`, `/opt/fit/lib/features/workout/data/workout_repository.dart`, `/opt/fit/lib/features/workout/presentation/pages/active_session_page.dart`, `/opt/fit/lib/features/workout/presentation/widgets/session_target_hint.dart`, `/opt/fit/test/features/workout/session_target_hint_test.dart`.

**Nie zakładamy istnienia `startFromPlan`, `startPlanSession`, `PlanStartResult` ani żadnej innej nowej metody etapu 1.** Po scaleniu etapu 1 odszukać rzeczywistą operację przyjmującą identyfikator planu i punkt transakcyjnego tworzenia sesji. Właśnie tam wymagany jest poniższy kontrakt, nie dodatkowa niezależna operacja uruchomienia treningu.

W tym samym spójnym odczycie co walidacja planu i rozwiązanie ćwiczeń:

1. Odczytać zaakceptowane cele z bieżącego snapshotu planu, nie z widgetu ani dawno pobranego `SavedPlan`.
2. Wybrać cele wyłącznie dla ćwiczeń rzeczywiście pozostawionych po deduplikacji i potwierdzeniu brakujących ID, z ważną zgodnością reguły i typem katalogowym.
3. Zbudować głęboko niemutowalny snapshot: planSyncId, rewizja źródłowego planu, mapa zaakceptowanych celów. Żadnego obliczania ani automatycznego akceptowania nowych sugestii przy starcie.
4. Zwrócić snapshot wraz z wynikiem stworzenia sesji; opublikować w stanie aktywnej sesji **dopiero po commit i ponownym guardzie konta/generacji**. Błąd zapisu nie może zostawić ćwiczeń/celów częściowo opublikowanych.
5. Jeśli istnieje aktywna sesja i użytkownik wraca do niej, pozostawić jej dotychczasowy snapshot; nie podmieniać celów na cele właśnie klikniętego planu.

Proponowany nowy typ danych, niezależny od nazwy wyniku startu etapu 1:

```dart
class SessionTargetSnapshot {
  SessionTargetSnapshot({
    required this.planSyncId,
    required this.planRevision,
    required Map<String, AcceptedTarget> targets,
  }) : targets = Map.unmodifiable(targets);
  final String planSyncId;
  final String planRevision;
  final Map<String, AcceptedTarget> targets;
}
```

Typ umieścić w `/opt/fit/lib/features/planner/progression/domain/progression_models.dart`. Dodać nullable `SessionTargetSnapshot? targetSnapshot` do `ActiveWorkoutState`, propagować w `copyWith`, resetować przy zakończeniu/discard/konto. Start ręczny i Mentor dostają null; nie odziedziczają snapshotu poprzedniej sesji. Jeśli etap 1 utrwala stan wybranych ćwiczeń do restartu procesu, uzgodnić wspólne utrwalenie snapshotu w tej samej lokalnej strukturze; nie dodawać samowolnie pola do synchronizowanego `workoutSession` w ramach kontraktu `workoutPlan`.

**Bieżąca decyzja:** przy obecnym in-memory ActiveWorkoutState snapshot jest w pamięci i żyje tyle co aktywny stan. Po restarcie bez odtworzonego snapshotu nie pobierać „na nowo” celów z aktualnego planu, udając dawny snapshot. Jawnie brak podpowiedzi. Trwałość aktywnej sesji po restarcie nie jest dodatkową obietnicą tego etapu.

### Podpowiedź wykonania

Wyświetlić: „Cel z planu: 3 × 8–12 przy 11,25 kg — to podpowiedź, nie zapis wykonania”. Domyślnie tylko hint/etykieta, bez automatycznej zmiany kontrolerów i RPE. Opcjonalny przycisk „Wstaw cel” może wstawić ciężar oraz dolny próg reps po jawnym kliknięciu; nie wstawia RPE, bo target nie zawiera wyniku RPE. Ręcznie zmienione pola pozostają pod kontrolą użytkownika. „Seria wykonana” pozostaje jedyną standardową akcją zapisu.

Minimalny samodzielny widget informacyjny do `/opt/fit/lib/features/workout/presentation/widgets/session_target_hint.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:fitbirek_training/features/planner/progression/domain/progression_models.dart';

String gramsLabel(int grams) {
  final whole = grams ~/ 1000;
  final fraction = (grams % 1000).toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '');
  return fraction.isEmpty ? '$whole' : '$whole,$fraction';
}

class SessionTargetHint extends StatelessWidget {
  const SessionTargetHint({super.key, required this.target});
  final AcceptedTarget target;

  @override
  Widget build(BuildContext context) => Text(
    'Cel z planu: ${target.sets} × ${target.repMin}–${target.repMax} '
    'przy ${gramsLabel(target.weightGrams)} kg — podpowiedź, nie zapis wykonania.',
  );
}
```

- [ ] RED: test widgetu `SessionTargetHint` z targetem JSON §3 oczekuje tekstu `11,25 kg`; render nie wykonuje żadnej operacji repo/outbox.
- [ ] RED: test integracyjny rzeczywistego startu etapu 1 odczytuje aktualny cel 11250 g; potem zmiana celu planu na 12500 g nie zmienia snapshotu aktywnej sesji.
- [ ] RED: powrót do istniejącej sesji zachowuje jej snapshot; start ręczny/Mentor ma null; brakujące ćwiczenie nie pozostawia osieroconego celu; usunięcie planu po starcie nie usuwa historii ani nie zmienia zaakceptowanej kopii sesji.
- [ ] RED: zmiana konta/błąd tworzenia sesji nie publikuje snapshotu; brak sztucznych serii i PR. Zmiana tekstu użytkownika nie jest nadpisywana przy rebuildzie po pull.
- [ ] RED: `flutter test /opt/fit/test/features/workout/session_target_hint_test.dart` oraz rzeczywisty plik testów startu dodany w etapie 1 (jego ścieżka jest punktem uzgodnienia, nie zgadywać).
- [ ] GREEN: dołączyć snapshot w ustalonym punkcie transakcji i dodać hint; ponowić test oraz regresje Mentora i usuwania sesji.

## 13. Weryfikacja końcowa przyszłej implementacji

Wszystkie polecenia poniżej mają `workdir=/opt/fit`; żadne nie jest poleceniem wdrożenia.

- [ ] `flutter --version` — potwierdzić Flutter 3.35.4/Dart 3.9.2, bez upgrade.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — po zmianach Drift/JSON/Freezed, uwzględnić wygenerowane pliki. Nie uruchamiać generatora podczas samego pisania tego planu.
- [ ] `flutter test /opt/fit/test/features/planner/progression /opt/fit/test/core/progression_migration_test.dart /opt/fit/test/features/workout/session_target_hint_test.dart` — wszystkie nowe testy PASS.
- [ ] `flutter test /opt/fit/test/core/sync_persistence_test.dart /opt/fit/test/core/sync_service_test.dart /opt/fit/test/core/deferred_sync_test.dart /opt/fit/test/core/restore_sync_regression_test.dart /opt/fit/test/features/settings/backup_service_test.dart` — regresje sync/restore PASS.
- [ ] `flutter test /opt/fit/test/features/workout/history` — zgodność z etapem 2, bez zmiany jego API.
- [ ] `flutter test --platform chrome /opt/fit/test/features/planner/progression/progression_engine_test.dart /opt/fit/test/features/planner/progression/progression_models_test.dart /opt/fit/test/features/planner/progression/progression_fingerprint_test.dart` — arytmetyka, strict JSON i hash zgodne na Web.
- [ ] Kontrola Web SQLite: porównać `/opt/fit/pubspec.lock` z przypisanymi artefaktami `/opt/fit/web/sqlite3.wasm` i `/opt/fit/web/drift_worker.dart.js`. Przy niezmienionym locku nie regenerować ich tylko z powodu migracji tabel. Jeśli zależności się zmieniły, dobrać oba artefakty według wersji locka i potwierdzić web smoke test bazy; nie akceptować przypadkowego `pub upgrade`.
- [ ] `dart format . && flutter analyze && flutter test` — polecenie repo z AGENTS; przed formatowaniem zabezpieczyć wiedzę o wcześniejszych zmianach, nie przypisywać ich tej funkcji i nie cofać ich. Wynik formatowania niezwiązanych plików wymaga jawnego rozdzielenia zakresu.
- [ ] `dart tools/generate_app_version.dart --check` przed buildem. Ten plan nie jest wydaniem: nie bumpować wersji podczas pisania. Przy osobnym wydaniu funkcji podnieść minor i N w `/opt/fit/pubspec.yaml`, uruchomić `dart tools/generate_app_version.dart`, uwzględnić `/opt/fit/lib/app/app_version.g.dart` bez build-name overrides.
- [ ] `git diff --check` oraz przegląd diffu względem stanu początkowego; bez commitów i bez operacji na produkcyjnej bazie.
- [ ] Wspólna bramka z 3a: backendowe testy kontraktu muszą przejść przed publikacją nowego klienta. Frontend sam nie zapewni ochrony przed starym klientem na starym backendzie.

## 14. Macierz odbioru i jawne luki planu

| Wymaganie | Miejsce planu / dowód wymagany w implementacji |
|---|---|
| Modele reguł/celów, zgodny JSON | §3–4, strict codec VM + Web |
| Integer gramy i deterministyczny silnik | §5, testy każdej gałęzi |
| Fingerprint całego zestawu serii | §6, zamiana ID przy tej samej liczbie |
| Aktualność, atomowość, idempotencja | §9, rollback + double accept + auth barriers |
| UI reguł i sugestii | §11, widget/integration tests |
| Snapshot przy starcie z planu | §12, realny punkt integracji etapu 1 |
| Migracja z obecnego v7 | §7, realny reopen v7 i legacy attempted |
| Outbox/sync/stary klient | §8, niezmienne retry, blokady, delete-chain, backend 3a |
| Backup v3, v1/v2, rollback | §10, domenowy round-trip i odrzucenie v3 przez stary importer |
| Brak sztucznego wykonania | §9/§12, stała liczba serii i PR |

**Braki kodu, których nie należy ukrywać:**

1. Nie ma pełnej implementacji `StrictProgressionCodec`, adaptera pełnego payloadu planu ani zachowania leksykalnych typów integer na Web. Są dokładne inwarianty i przykłady testów, ale to nadal zadanie projektowo-kodowe przed wykonaniem.
2. Nie ma pełnego patcha DAO scalającego łańcuchy, trwałego blokowania konfliktów, obsługi delete po niewysłanym upsercie i odbioru najnowszego deferred snapshotu. Tabela przejść jest normatywna; same fragmenty nie wystarczą do bezpiecznego sync.
3. Nie ma kompletnego `ProgressionRepository`, kodu auth-generation provider ani fixtures/barier testów współbieżności. Publiczny warunek edycji legacy wymaga doprecyzowania typu zamiast `expectedPlanRevision:String`; akceptacja v1 nie ma tej niejednoznaczności.
4. Nie ma pełnego kodu dialogu, providerów reaktywnych, sekcji konfliktu ani wszystkich widget tests. Wymagania UI i konkretne wartości są opisane, ale nie są gotowymi plikami.
5. Nie ma pełnego adaptera backupu v3 i kompletnego kodu testu migracji na historycznym schemacie. Wymagane są rzeczywiste testy, nie tylko asercje na fixture JSON.
6. Nazwa i dokładny podpis operacji startu oraz ścieżka jej testu zostaną uzgodnione po równoległym etapie 1. Punkt integracji snapshotu jest określony, ale dokument celowo nie wymyśla nowych istniejących metod. Jeśli etap 1 rozszerzy trwałość aktywnej sesji, trzeba zamknąć wspólne utrwalanie snapshotu.
7. Przykłady testów poza samodzielnym blokiem silnika są fragmentami wymagającymi importów/fixture z opisanych plików. Nie uruchamiano testów ani generatora podczas tworzenia planu; nie ma deklaracji PASS.

Dokument jest przekazany do **osobistego przeglądu użytkownika**, bez delegowanego self-review, bez implementacji i bez commitów. Przed uznaniem go za kompletny plan wykonawczy należy uzupełnić powyższe luki, przede wszystkim parser strict Web, transakcję akceptacji oraz state machine outbox.
