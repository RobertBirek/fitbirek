# Historia ćwiczenia — etap 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Udostępnić offline historię zakończonych wykonań ćwiczenia, ostrożne porównanie dwóch ostatnich wykonań i osobne wykresy ciężaru oraz czasu, z wejściem ze szczegółów ćwiczenia i aktywnej sesji.

**Architecture:** Oddzielne repozytorium wykonuje reaktywny JOIN istniejących tabel Drift, filtruje tombstones i sprawdza lokalne powiązanie konta. Niegenerowane, niemutowalne modele oraz czyste funkcje obliczeniowe nie zależą od Fluttera, Drift ani sieci. Riverpod udostępnia historię w kluczu `(accountId, exerciseId)`, a ekran i wykresy wyłącznie prezentują wyniki; etap 3 korzysta z tych samych surowych wykonań, nie z metryk wykresu.

**Tech Stack:** Flutter 3.35.4, Dart 3.9.2, Riverpod 2.6.1, Drift 2.28.2, sqlite3 2.9.4, go_router 14.x, fl_chart 0.69.x, flutter_test i NativeDatabase.memory().

---

## Zakres, źródła i warunki wykonania

To samodzielny plan wyłącznie etapu 2 zaakceptowanej specyfikacji `docs/superpowers/specs/2026-09-28-plany-historia-progresja-design.md`, sekcje „Etap 2” i „Weryfikacja / Etap 2”. Nie implementuje uruchamiania planu, reguł progresji, akceptacji celu, migracji planów ani backendu. Nie wymaga ukończenia etapu 1. Nie wykonuje wdrożenia ani operacji na produkcyjnej bazie.

Przeczytane źródła i ustalenia:

- `AGENTS.md`: pracować w kliencie `/opt/fit`, nie aktualizować toolchainu, zachować niezwiązane zmiany. W chwili pisania repozytorium zawiera liczne lokalne zmiany, także w plikach integracyjnych tego etapu.
- `lib/core/database/tables/workout_tables.dart`: `dataKoniec` nullable; serie mają nullable `ciezarKg`, `powtorzenia`, `czasSekund`, `rpe`. Nie zmieniać schematu.
- `lib/core/database/tables/sync_metadata.dart`: `syncId`, `syncVersion`, `updatedAtUtc`, `deletedAtUtc` są dostępne w sesjach i seriach.
- `lib/core/database/daos/workout_dao.dart:57-73`: obecne odczyty pojedynczego ćwiczenia nie filtrują stanu rodzica. Nie używać ich do historii i nie zmieniać ich kontraktu w tym etapie.
- `lib/features/workout/data/workout_repository.dart`: zapis wyników i kolejki synchronizacji pozostaje nietknięty; historia nie zapisuje PR ani outboxu.
- `lib/core/providers/database_provider.dart`: jedna instancja bazy; brak bazy per konto.
- `lib/features/auth/providers/auth_providers.dart`: `AuthState.signedIn(accountId)` obejmuje również poprawnie odblokowany dostęp offline. Logout przechodzi przez `loading`; blokada trwała to `syncState.offlineAccess = false`.
- `lib/core/sync/sync_service.dart:62-81`: `bindAccount` odrzuca inne konto, nie przenosi właścicielstwa istniejących danych. Nowy moduł nie może obchodzić tej blokady.
- `lib/features/workout/presentation/pages/active_session_page.dart:175-203`: obecne „Ostatnio” jest `FutureBuilder` na ostatniej serii. Zastąpić je wejściem do historii, aby nie prezentować bieżącej serii jako zakończonego wykonania. Nie zmieniać formularza, stopera, RPE ani timera przerw.
- `lib/features/exercises/presentation/pages/exercise_detail_page.dart:61-74`: dodać niezależny przycisk historii, bez uruchamiania treningu.
- `lib/app/router.dart`: istnieje chroniony router i indeksowany shell. Dodać trasę historii na poziomie głównym, nad shellem; `push`/powrót zachowuje aktywną sesję i pola formularza.
- `lib/core/widgets/weight_line_chart.dart`: dotyczy masy ciała, nie nadaje się do ponownego użycia z ciężarem ćwiczenia. Użyć tego samego pakietu `fl_chart`, lecz osobnego widgetu.
- Testowe wzorce: `test/features/workout/deleted_session_test.dart`, `test/features/auth/offline_auth_test.dart`, `test/app/router_test.dart`. Wykorzystać rzeczywistą bazę pamięciową, nie mock SQL.
- `pubspec.lock`: Drift 2.28.2 i sqlite3 2.9.4. Nie zmieniać zależności ani artefaktów Web SQLite w tym etapie.

**Reguły wykonania:** każdy checkbox to jedna czynność, zwykle 2–5 minut. Dłuższe bloki kodu są kompletną docelową zawartością pliku; można wpisywać je w kawałkach, lecz nie pomijać cyklu RED → GREEN. Komendy uruchamiać z `/opt/fit`. Nie tworzyć worktree klienta. Nie commitować bez osobnej zgody użytkownika; zamiast standardowych checkpointów commit stosować przegląd diffu. Obecne zadanie to tylko zapis planu — wszystkie poniższe zmiany i komendy testów dotyczą przyszłej implementacji.

## Kontrakty i jednoznaczne decyzje

1. Wykonanie = jedna zakończona, żywa sesja mająca co najmniej jedną żywą serię danego `exerciseId`. Usunięcie ostatniej serii usuwa wykonanie z historii. Brak katalogowego ćwiczenia nie usuwa historycznych wyników.
2. Sesje: `dataKoniec DESC`, następnie `syncId DESC`. Serie: `numerSerii ASC`, `timestamp ASC`, `syncId ASC`. Identyfikatory synchronizacji zapewniają stabilność po restore/pull; lokalne `id` służą tylko JOIN-owi.
3. Repo wymaga jawnego `accountId`; to warunek dopasowany do singletonu `syncState` w **tym samym zapytaniu SQL**, nie filtr po zakończonym `await`. `offlineAccess=false`, brak bindingu albo inne konto dają pustą listę. Pusta lista nie stanowi autoryzacji do zapisów etapu 3.
4. Provider ma klucz konta i ćwiczenia, obserwuje auth i nie rozpoczyna odczytu przy niedopasowanym auth. UI dodatkowo nie renderuje danych podczas `loading`/`signedOut`. Nie stosować `keepAlive` ani cache globalnego poza Riverpod.
5. Brak wartości pozostaje `null`. W liście wyświetlać „brak danych”, nie zero. Jawnie zapisane zero pozostaje zerem; wartości ujemne/niefinitywne nie wchodzą do metryk, ale pozostają w surowych seriach.
6. Suma powtórzeń ma wartość tylko, jeśli wszystkie serie mają nieujemne powtórzenia. Porównanie kierunkowe wymaga również tej samej liczby serii i jednego identycznego, skończonego, nieujemnego ciężaru we wszystkich seriach **obu** wykonań. Nie zgadywać ciężaru ciała przy `null`. Dopuszczenie jawnego `0 kg` w porównaniu nie uprawnia etapu 3 do progresji.
7. Objętość sumuje tylko serie z dodatnim skończonym ciężarem i dodatnimi powtórzeniami. Brak takich serii = `null`; pokazać też liczbę uwzględnionych serii. Etykieta: „Objętość zarejestrowanych serii”; nie przedstawiać jej jako uniwersalnego postępu.
8. Maksymalny ciężar bierze najwyższy zapisany skończony, nieujemny ciężar; zachować **wszystkie** związane z nim serie, wraz z nullable powtórzeniami. Najdłuższa seria czasowa wymaga dodatnich sekund. Te metryki są niezależne od aktualnego typu ćwiczenia w katalogu.
9. Wykresy mają odrębne osie i jednostki. Oś X to kolejne zakończone wykonania, daty w opisach. Brak metryki zostawia przerwę (`FlSpot.nullSpot`), nie punkt zero. Jeden punkt jest widoczny, ale ma komunikat „Jedno wykonanie — brak trendu”. Brak kwalifikujących punktów ma własny komunikat.
10. Historia jest wyłącznie odczytem; nie wprowadza DTO synchronizacji, migracji, pól backupu, Freezed ani JSON. Metadane źródłowe w modelach są dla etapu 3, nie są synchronizowaną kopią danych.

## Mapa plików

Nowe pliki produkcyjne:

| Ścieżka | Odpowiedzialność |
| --- | --- |
| `lib/features/workout/history/domain/exercise_history.dart` | Niemutowalne surowe serie i wykonania; publiczny kontrakt etapu 3 |
| `lib/features/workout/history/domain/exercise_history_calculator.dart` | Sortowanie kopii, metryki i porównanie dwóch ostatnich wykonań |
| `lib/features/workout/history/data/exercise_history_repository.dart` | Jeden account-scoped JOIN, grupowanie, `watch` i `get` |
| `lib/features/workout/history/providers/exercise_history_providers.dart` | Repo i rodzina streamów według konta/ćwiczenia |
| `lib/features/workout/history/presentation/widgets/exercise_history_chart.dart` | Wykres jednej metryki, stany puste, opisy punktów |
| `lib/features/workout/history/presentation/pages/exercise_history_page.dart` | Auth gate, stan asynchroniczny, porównanie, wykresy, lista serii |

Istniejące pliki do minimalnej integracji:

- `lib/app/router.dart`: import i główna trasa `/exercise-history/:exerciseId`.
- `lib/features/exercises/presentation/pages/exercise_detail_page.dart`: przycisk przed rozpoczęciem treningu.
- `lib/features/workout/presentation/pages/active_session_page.dart`: zastąpienie opisanego `FutureBuilder` przyciskiem historii.

Nowe pliki testowe:

- `test/features/workout/history/history_fixtures.dart`: deterministyczne modele i seeding Drift bez sieci.
- `test/features/workout/history/exercise_history_calculator_test.dart`.
- `test/features/workout/history/exercise_history_repository_test.dart`.
- `test/features/workout/history/exercise_history_providers_test.dart`.
- `test/features/workout/history/exercise_history_chart_test.dart`.
- `test/features/workout/history/exercise_history_page_test.dart`.
- `test/features/workout/history/exercise_history_navigation_test.dart`.

## Zadanie 1: modele i czyste obliczenia

**Pliki:** utworzyć oba pliki `domain/`, `history_fixtures.dart` oraz `exercise_history_calculator_test.dart` z mapy powyżej.

- [ ] **1.1 RED — utwórz fixture modeli.** Zapisz w `test/features/workout/history/history_fixtures.dart`:

```dart
import 'package:fitbirek_training/features/workout/history/domain/exercise_history.dart';

ExerciseHistorySet sampleSet({
  String id = 'set-1', int number = 1, double? kg = 10,
  int? reps = 8, int? seconds, int? rpe = 7,
}) => ExerciseHistorySet(
  syncId: id, syncVersion: 1, updatedAtUtc: DateTime.utc(2026, 9, 1),
  number: number, timestamp: DateTime.utc(2026, 9, 1),
  weightKg: kg, reps: reps, seconds: seconds, rpe: rpe,
);

ExercisePerformance samplePerformance({
  String? id, int day = 1, List<ExerciseHistorySet>? sets,
}) => ExercisePerformance(
  exerciseId: 'cw001', exerciseName: 'Przysiad', sessionSyncId: id ?? 'session-$day',
  sessionSyncVersion: 1, sessionUpdatedAtUtc: DateTime.utc(2026, 9, day),
  finishedAt: DateTime.utc(2026, 9, day),
  sets: sets ?? [sampleSet()],
);
```

- [ ] **1.2 RED — zapisz testy obliczeń** w `exercise_history_calculator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/history/domain/exercise_history_calculator.dart';
import 'history_fixtures.dart';

void main() {
  test('pusta historia i jedno wykonanie nie mają porównania', () {
    expect(calculateExerciseHistory([]).comparison, isNull);
    expect(calculateExerciseHistory([samplePerformance()]).comparison, isNull);
  });
  test('sortuje kopię po zakończeniu i stabilnym ID; bierze dwa ostatnie', () {
    final input = [
      samplePerformance(id: 'a', day: 2),
      samplePerformance(id: 'old', day: 1),
      samplePerformance(id: 'z', day: 2, sets: [sampleSet(reps: 10)]),
    ];
    final result = calculateExerciseHistory(input);
    expect(input.first.sessionSyncId, 'a');
    expect(result.sessions.map((s) => s.source.sessionSyncId), ['z', 'a', 'old']);
    expect(result.comparison!.repsDelta, 2);
  });
  test('liczy sumę powtórzeń tylko przy kompletnych danych', () {
    final result = summarizePerformance(samplePerformance(sets: [
      sampleSet(reps: 8), sampleSet(id: 's2', reps: null),
    ]));
    expect(result.totalReps, isNull);
    expect(result.volumeKgReps, 80);
    expect(result.volumeSetCount, 1);
  });
  test('różne liczby serii, różne ciężary i brak ciężaru nie dają oceny', () {
    for (final sets in [
      [sampleSet(), sampleSet(id: 's2')],
      [sampleSet(kg: 11)],
      [sampleSet(kg: null)],
      [sampleSet(reps: null)],
    ]) {
      final result = calculateExerciseHistory([
        samplePerformance(day: 2, sets: sets), samplePerformance(),
      ]);
      expect(result.comparison!.repsDelta, isNull);
    }
  });
  test('mieszane ciężary wewnątrz sesji nie są porównywalne', () {
    final sets = [sampleSet(), sampleSet(id: 's2', kg: 12)];
    expect(calculateExerciseHistory([
      samplePerformance(day: 2, sets: sets), samplePerformance(sets: sets),
    ]).comparison!.repsDelta, isNull);
  });
  test('ciężar maksymalny zachowuje powtórzenia każdej związanej serii', () {
    final result = summarizePerformance(samplePerformance(sets: [
      sampleSet(kg: 20, reps: 6),
      sampleSet(id: 's2', kg: 20, reps: null),
      sampleSet(id: 's3', kg: 10, reps: 12),
    ]));
    expect(result.maxWeightKg, 20);
    expect(result.maxWeightSets.map((s) => s.reps), [6, null]);
  });
  test('sekundy i kilogramy nie są łączone; brak danych nie jest zerem', () {
    final time = summarizePerformance(samplePerformance(sets: [
      sampleSet(kg: null, reps: null, seconds: 30),
      sampleSet(id: 's2', kg: null, reps: null, seconds: 45),
    ]));
    expect(time.longestSeconds, 45);
    expect(time.maxWeightKg, isNull);
    expect(time.volumeKgReps, isNull);
    final empty = summarizePerformance(samplePerformance(sets: [
      sampleSet(kg: null, reps: null, seconds: null, rpe: null),
    ]));
    expect(empty.totalReps, isNull);
    expect(empty.longestSeconds, isNull);
  });
  test('jawne zero zostaje zerem, wartości ujemne i NaN nie tworzą metryk', () {
    final zero = summarizePerformance(samplePerformance(sets: [sampleSet(kg: 0, reps: 0)]));
    expect(zero.totalReps, 0);
    expect(zero.maxWeightKg, 0);
    expect(zero.volumeKgReps, isNull);
    for (final kg in [-1.0, double.nan, double.infinity]) {
      final result = summarizePerformance(samplePerformance(sets: [
        sampleSet(kg: kg, reps: -1, seconds: -1),
      ]));
      expect(result.maxWeightKg, isNull);
      expect(result.volumeKgReps, isNull);
      expect(result.totalReps, isNull);
      expect(result.longestSeconds, isNull);
    }
  });
  test('surowe listy są niemutowalne, ułamki i RPE pozostają bez zmian', () {
    final sets = [sampleSet(kg: 10.5, reps: 8, rpe: null)];
    final source = samplePerformance(sets: sets);
    sets.clear();
    expect(source.sets, hasLength(1));
    expect(() => source.sets.clear(), throwsUnsupportedError);
    expect(summarizePerformance(source).volumeKgReps, 84);
    expect(source.sets.single.rpe, isNull);
  });
}
```

- [ ] **1.3 Uruchom RED:** `flutter test test/features/workout/history/exercise_history_calculator_test.dart`. Oczekiwany błąd: brak importowanych plików/modeli/funkcji, nie awaria środowiska.
- [ ] **1.4 GREEN — utwórz modele** w `lib/features/workout/history/domain/exercise_history.dart`:

```dart
class ExerciseHistorySet {
  const ExerciseHistorySet({
    required this.syncId, required this.syncVersion, required this.updatedAtUtc,
    required this.number, required this.timestamp,
    this.weightKg, this.reps, this.seconds, this.rpe,
  });
  final String syncId;
  final int syncVersion;
  final DateTime updatedAtUtc;
  final int number;
  final DateTime timestamp;
  final double? weightKg;
  final int? reps;
  final int? seconds;
  final int? rpe;
}

class ExercisePerformance {
  ExercisePerformance({
    required this.exerciseId, required this.exerciseName,
    required this.sessionSyncId, required this.sessionSyncVersion,
    required this.sessionUpdatedAtUtc, required this.finishedAt,
    required List<ExerciseHistorySet> sets,
  }) : sets = List.unmodifiable(sets);
  final String exerciseId;
  final String exerciseName;
  final String sessionSyncId;
  final int sessionSyncVersion;
  final DateTime sessionUpdatedAtUtc;
  final DateTime finishedAt;
  final List<ExerciseHistorySet> sets;
}
```

- [ ] **1.5 GREEN — utwórz obliczenia** w `lib/features/workout/history/domain/exercise_history_calculator.dart`:

```dart
import 'exercise_history.dart';

class ExercisePerformanceSummary {
  ExercisePerformanceSummary({
    required this.source, required this.totalReps, required this.volumeKgReps,
    required this.volumeSetCount, required this.maxWeightKg,
    required List<ExerciseHistorySet> maxWeightSets, required this.longestSeconds,
  }) : maxWeightSets = List.unmodifiable(maxWeightSets);
  final ExercisePerformance source;
  final int? totalReps;
  final double? volumeKgReps;
  final int volumeSetCount;
  final double? maxWeightKg;
  final List<ExerciseHistorySet> maxWeightSets;
  final int? longestSeconds;
}

class ExerciseHistoryComparison {
  const ExerciseHistoryComparison(this.latest, this.previous, this.repsDelta);
  final ExercisePerformanceSummary latest;
  final ExercisePerformanceSummary previous;
  // null = brak podstaw do kierunkowego porównania, NIE remis.
  final int? repsDelta;
}

class ExerciseHistorySummary {
  ExerciseHistorySummary(List<ExercisePerformanceSummary> sessions, this.comparison)
    : sessions = List.unmodifiable(sessions);
  final List<ExercisePerformanceSummary> sessions; // najnowsze pierwsze
  final ExerciseHistoryComparison? comparison;
}

bool _validWeight(double? value) => value != null && value.isFinite && value >= 0;

ExercisePerformanceSummary summarizePerformance(ExercisePerformance source) {
  final sets = source.sets;
  final completeReps = sets.isNotEmpty && sets.every((s) => s.reps != null && s.reps! >= 0);
  final volumeSets = sets.where((s) => _validWeight(s.weightKg) && s.weightKg! > 0 &&
    s.reps != null && s.reps! > 0).toList();
  final weights = sets.where((s) => _validWeight(s.weightKg)).map((s) => s.weightKg!).toList();
  final seconds = sets.where((s) => s.seconds != null && s.seconds! > 0).map((s) => s.seconds!).toList();
  final maxWeight = weights.isEmpty ? null : weights.reduce((a, b) => a > b ? a : b);
  return ExercisePerformanceSummary(
    source: source,
    totalReps: completeReps ? sets.fold<int>(0, (sum, s) => sum + s.reps!) : null,
    volumeKgReps: volumeSets.isEmpty ? null : volumeSets.fold<double>(0, (sum, s) => sum + s.weightKg! * s.reps!),
    volumeSetCount: volumeSets.length,
    maxWeightKg: maxWeight,
    maxWeightSets: maxWeight == null ? [] : sets.where((s) => s.weightKg == maxWeight).toList(),
    longestSeconds: seconds.isEmpty ? null : seconds.reduce((a, b) => a > b ? a : b),
  );
}

ExerciseHistorySummary calculateExerciseHistory(List<ExercisePerformance> input) {
  final sorted = [...input]..sort((a, b) {
    final time = b.finishedAt.compareTo(a.finishedAt);
    return time != 0 ? time : b.sessionSyncId.compareTo(a.sessionSyncId);
  });
  final summaries = sorted.map(summarizePerformance).toList();
  ExerciseHistoryComparison? comparison;
  if (summaries.length >= 2) {
    final latest = summaries[0];
    final previous = summaries[1];
    final allSets = [...latest.source.sets, ...previous.source.sets];
    final weight = allSets.isEmpty ? null : allSets.first.weightKg;
    final comparable = latest.source.sets.isNotEmpty &&
      latest.source.sets.length == previous.source.sets.length &&
      latest.totalReps != null && previous.totalReps != null &&
      _validWeight(weight) && allSets.every((s) => s.weightKg == weight);
    comparison = ExerciseHistoryComparison(latest, previous,
      comparable ? latest.totalReps! - previous.totalReps! : null);
  }
  return ExerciseHistorySummary(summaries, comparison);
}
```

- [ ] **1.6 GREEN:** ponownie `flutter test test/features/workout/history/exercise_history_calculator_test.dart`; wszystkie testy PASS. Brak importów Drift/Flutter w `domain/`.
- [ ] **1.7 Checkpoint:** `git diff --check`; przejrzyj nowo utworzone pliki, bez commitowania.

## Zadanie 2: repozytorium, tombstones i kontekst konta

**Pliki:** nowy `lib/features/workout/history/data/exercise_history_repository.dart`; rozszerzyć fixture testową; nowy `test/features/workout/history/exercise_history_repository_test.dart`. Nie edytować DAO ani tabel.

- [ ] **2.1 RED — dopisz importy i funkcje bazodanowe do fixture:**

```dart
import 'package:drift/drift.dart';
import 'package:fitbirek_training/core/database/app_database.dart';

Future<void> bindHistoryAccount(AppDatabase db, {String account = 'account'}) =>
  db.into(db.syncState).insert(SyncStateCompanion.insert(
    id: const Value(1), accountId: account, deviceId: 'device',
  )).then((_) {});

Future<int> seedSession(AppDatabase db, {
  required String id, int day = 1, bool active = false, bool deleted = false,
}) => db.into(db.workoutSessions).insert(WorkoutSessionsCompanion.insert(
  syncId: Value(id), dataStart: DateTime.utc(2026, 8, 1),
  dataKoniec: Value(active ? null : DateTime.utc(2026, 9, day)),
  deletedAtUtc: Value(deleted ? DateTime.utc(2026, 9, 28) : null),
));

Future<int> seedSet(AppDatabase db, int sessionId, {
  required String id, String exercise = 'cw001', int number = 1,
  bool deleted = false, double? kg = 10, int? reps = 8, int? seconds, int? rpe = 7,
}) => db.into(db.setsLog).insert(SetsLogCompanion.insert(
  syncId: Value(id), sesjaId: sessionId, cwiczenieId: exercise,
  nazwaCwiczeniaPl: 'Przysiad', numerSerii: number,
  timestamp: Value(DateTime.utc(2026, 9, 1)),
  ciezarKg: Value(kg), powtorzenia: Value(reps), czasSekund: Value(seconds), rpe: Value(rpe),
  deletedAtUtc: Value(deleted ? DateTime.utc(2026, 9, 28) : null),
));
```

- [ ] **2.2 RED — zapisz testy repo:**

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/workout/history/data/exercise_history_repository.dart';
import 'history_fixtures.dart';

void main() {
  late AppDatabase db;
  late ExerciseHistoryRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ExerciseHistoryRepository(db);
    await bindHistoryAccount(db);
  });
  tearDown(() => db.close());

  test('JOIN grupuje i sortuje; wyklucza aktywne, tombstones i obce ćwiczenie', () async {
    final a = await seedSession(db, id: 'a', day: 2);
    final z = await seedSession(db, id: 'z', day: 2);
    final old = await seedSession(db, id: 'old');
    final active = await seedSession(db, id: 'active', active: true);
    final deleted = await seedSession(db, id: 'deleted', deleted: true);
    final noLiveSets = await seedSession(db, id: 'no-live-sets');
    await seedSet(db, a, id: 's2', number: 2);
    await seedSet(db, a, id: 's1b');
    await seedSet(db, a, id: 's1a');
    await seedSet(db, z, id: 'z1', kg: null, reps: null, seconds: 30, rpe: null);
    await seedSet(db, old, id: 'old1');
    await seedSet(db, active, id: 'active1');
    await seedSet(db, deleted, id: 'deleted-parent-live-child');
    await seedSet(db, a, id: 'deleted-child', deleted: true);
    await seedSet(db, noLiveSets, id: 'only-deleted', deleted: true);
    await seedSet(db, a, id: 'other', exercise: 'cw002');
    final result = await repo.getCompletedHistory(accountId: 'account', exerciseId: 'cw001');
    expect(result.map((p) => p.sessionSyncId), ['z', 'a', 'old']);
    expect(result[1].sets.map((s) => s.syncId), ['s1a', 's1b', 's2']);
    expect(result.first.sets.single.weightKg, isNull);
    expect(result.first.sets.single.reps, isNull);
    expect(result.first.sets.single.rpe, isNull);
    expect(result.first.sets.single.seconds, 30);
    expect(await db.syncDao.pendingOperations(), isEmpty);
    expect(await db.select(db.personalRecords).get(), isEmpty);
  });
  test('złe konto, blokada offline i brak bindingu odcinają dane', () async {
    final id = await seedSession(db, id: 's');
    await seedSet(db, id, id: 'set');
    Future<dynamic> read(String account) => repo.getCompletedHistory(accountId: account, exerciseId: 'cw001');
    expect(await read('other'), isEmpty);
    await db.update(db.syncState).write(const SyncStateCompanion(offlineAccess: Value(false)));
    expect(await read('account'), isEmpty);
    await db.delete(db.syncState).go();
    expect(await read('account'), isEmpty);
  });
  test('żywy stream reaguje na edycję, koniec, tombstone serii i rodzica oraz blokadę', () async {
    final id = await seedSession(db, id: 's', active: true);
    final setId = await seedSet(db, id, id: 'set');
    final emissions = <List<String>>[];
    final subscription = repo.watchCompletedHistory(accountId: 'account', exerciseId: 'cw001')
      .listen((rows) => emissions.add([
        for (final p in rows) '${p.sessionSyncId}:${p.sets.first.reps}',
      ]));
    addTearDown(subscription.cancel);
    Future<void> waitFor(List<String> wanted) async {
      for (var i = 0; i < 100; i++) {
        if (emissions.isNotEmpty && emissions.last.toString() == wanted.toString()) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('Brak emisji $wanted; odebrano $emissions');
    }
    await waitFor([]);
    await (db.update(db.workoutSessions)..where((t) => t.id.equals(id)))
      .write(WorkoutSessionsCompanion(dataKoniec: Value(DateTime.utc(2026, 9, 2))));
    await waitFor(['s:8']);
    await (db.update(db.setsLog)..where((t) => t.id.equals(setId)))
      .write(const SetsLogCompanion(powtorzenia: Value(12)));
    await waitFor(['s:12']);
    await db.update(db.syncState).write(const SyncStateCompanion(offlineAccess: Value(false)));
    await waitFor([]);
    await db.update(db.syncState).write(const SyncStateCompanion(offlineAccess: Value(true)));
    await waitFor(['s:12']);
    await (db.update(db.setsLog)..where((t) => t.id.equals(setId)))
      .write(SetsLogCompanion(deletedAtUtc: Value(DateTime.utc(2026, 9, 28))));
    await waitFor([]);
    await seedSet(db, id, id: 'replacement');
    await waitFor(['s:8']);
    await (db.update(db.workoutSessions)..where((t) => t.id.equals(id)))
      .write(WorkoutSessionsCompanion(deletedAtUtc: Value(DateTime.utc(2026, 9, 28))));
    await waitFor([]);
  });
}
```

- [ ] **2.3 RED:** `flutter test test/features/workout/history/exercise_history_repository_test.dart`; oczekiwany brak klasy repozytorium.
- [ ] **2.4 GREEN — zapisz kompletne repozytorium:**

```dart
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../domain/exercise_history.dart';

class ExerciseHistoryRepository {
  ExerciseHistoryRepository(this._db);
  final AppDatabase _db;

  Stream<List<ExercisePerformance>> watchCompletedHistory({
    required String accountId, required String exerciseId,
  }) => _query(accountId, exerciseId).watch().map(_group);

  Future<List<ExercisePerformance>> getCompletedHistory({
    required String accountId, required String exerciseId,
  }) async => _group(await _query(accountId, exerciseId).get());

  Selectable<TypedResult> _query(String accountId, String exerciseId) {
    final sessions = _db.workoutSessions;
    final sets = _db.setsLog;
    final binding = _db.syncState;
    return _db.select(sets).join([
      innerJoin(sessions, sessions.id.equalsExp(sets.sesjaId)),
      innerJoin(binding, binding.id.equals(1) & binding.accountId.equals(accountId) &
        binding.offlineAccess.equals(true)),
    ])
      ..where(sets.cwiczenieId.equals(exerciseId) & sets.deletedAtUtc.isNull() &
        sessions.deletedAtUtc.isNull() & sessions.dataKoniec.isNotNull())
      ..orderBy([
        OrderingTerm.desc(sessions.dataKoniec), OrderingTerm.desc(sessions.syncId),
        OrderingTerm.asc(sets.numerSerii), OrderingTerm.asc(sets.timestamp),
        OrderingTerm.asc(sets.syncId),
      ]);
  }

  List<ExercisePerformance> _group(List<TypedResult> rows) {
    final sessions = <String, WorkoutSessionData>{};
    final names = <String, String>{};
    final exercises = <String, String>{};
    final grouped = <String, List<ExerciseHistorySet>>{};
    for (final row in rows) {
      final session = row.readTable(_db.workoutSessions);
      final set = row.readTable(_db.setsLog);
      final key = session.syncId;
      sessions[key] = session;
      names.putIfAbsent(key, () => set.nazwaCwiczeniaPl);
      exercises[key] = set.cwiczenieId;
      grouped.putIfAbsent(key, () => []).add(ExerciseHistorySet(
        syncId: set.syncId, syncVersion: set.syncVersion,
        updatedAtUtc: set.updatedAtUtc.toUtc(), number: set.numerSerii,
        timestamp: set.timestamp.toUtc(), weightKg: set.ciezarKg,
        reps: set.powtorzenia, seconds: set.czasSekund, rpe: set.rpe,
      ));
    }
    return List.unmodifiable([
      for (final entry in grouped.entries)
        ExercisePerformance(
          exerciseId: exercises[entry.key]!, exerciseName: names[entry.key]!,
          sessionSyncId: entry.key, sessionSyncVersion: sessions[entry.key]!.syncVersion,
          sessionUpdatedAtUtc: sessions[entry.key]!.updatedAtUtc.toUtc(),
          finishedAt: sessions[entry.key]!.dataKoniec!.toUtc(), sets: entry.value,
        ),
    ]);
  }
}
```

Zapytanie ma trzy obserwowane tabele, więc lokalny zapis, pull i restore korzystające z Drift odświeżają je bez ręcznego invalidate. Nie dodawać `customSelect` z niepełnym `readsFrom`. Publiczny typ Drift `Selectable<TypedResult>` ukrywa szczegóły generyków JOIN i zapewnia wspólne `get()`/`watch()` bez generatora.

- [ ] **2.5 GREEN:** `flutter test test/features/workout/history/exercise_history_repository_test.dart`; PASS, w tym reakcja na zmianę wyłącznie tabeli sesji i wyłącznie bindingu.
- [ ] **2.6 Checkpoint:** `git diff --check`; sprawdzić, że nie zmieniono deklaracji Drift, bazy ani outboxu poza seedingiem w testach.

## Zadanie 3: provider i brak przenikania danych konta

**Pliki:** nowy provider i `exercise_history_providers_test.dart`.

- [ ] **3.1 RED — zapisz testy providera:**

```dart
import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/workout/history/domain/exercise_history.dart';
import 'package:fitbirek_training/features/workout/history/data/exercise_history_repository.dart';
import 'package:fitbirek_training/features/workout/history/providers/exercise_history_providers.dart';
import 'history_fixtures.dart';

class NoNetworkAuthApi implements AuthApi {
  @override
  Future<AuthSession?> getSession() => throw StateError('Nie wywoływać sieci');
  @override
  Future<AuthSession> login({required String email, required String password}) => throw StateError('Nie wywoływać sieci');
  @override
  Future<void> logout() => throw StateError('Nie wywoływać sieci');
}

class HistoryTestAuth extends AuthController {
  HistoryTestAuth(AuthState initial) : super(NoNetworkAuthApi()) { state = initial; }
  void change(AuthState value) { state = value; }
}

class DelayedHistoryRepository extends ExerciseHistoryRepository {
  DelayedHistoryRepository(super.db);
  final a = StreamController<List<ExercisePerformance>>.broadcast();
  final b = StreamController<List<ExercisePerformance>>.broadcast();
  @override
  Stream<List<ExercisePerformance>> watchCompletedHistory({required String accountId, required String exerciseId}) =>
    accountId == 'a' ? a.stream : b.stream;
}

void main() {
  test('klucz konta i auth odrzucają późną emisję poprzedniego konta', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = DelayedHistoryRepository(db);
    final auth = HistoryTestAuth(const AuthState.signedIn('a'));
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      authStateProvider.overrideWith((ref) => auth),
      exerciseHistoryRepositoryProvider.overrideWithValue(repo),
    ]);
    final keyA = (accountId: 'a', exerciseId: 'cw001');
    final keyB = (accountId: 'b', exerciseId: 'cw001');
    final aSub = container.listen(exerciseHistoryProvider(keyA), (_, _) {});
    final bSub = container.listen(exerciseHistoryProvider(keyB), (_, _) {});
    addTearDown(() async {
      aSub.close(); bSub.close(); container.dispose();
      await repo.a.close(); await repo.b.close(); await db.close();
    });
    repo.a.add([samplePerformance(id: 'private-a')]);
    expect((await container.read(exerciseHistoryProvider(keyA).future)).single.sessionSyncId, 'private-a');
    expect(await container.read(exerciseHistoryProvider(keyB).future), isEmpty);
    auth.change(const AuthState.loading());
    expect(await container.read(exerciseHistoryProvider(keyA).future), isEmpty);
    auth.change(const AuthState.signedIn('b'));
    // Wymuś zbudowanie nowego streamu przed emisją broadcast.
    final bFuture = container.read(exerciseHistoryProvider(keyB).future);
    repo.a.add([samplePerformance(id: 'late-a')]);
    repo.b.add([samplePerformance(id: 'private-b')]);
    expect((await bFuture).single.sessionSyncId, 'private-b');
    expect(await container.read(exerciseHistoryProvider(keyA).future), isEmpty);
    auth.change(const AuthState.signedOut());
    expect(await container.read(exerciseHistoryProvider(keyB).future), isEmpty);
  });
}
```

- [ ] **3.2 RED:** `flutter test test/features/workout/history/exercise_history_providers_test.dart`; brak providera.
- [ ] **3.3 GREEN — zapisz provider:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/exercise_history_repository.dart';
import '../domain/exercise_history.dart';

typedef ExerciseHistoryKey = ({String accountId, String exerciseId});

final exerciseHistoryRepositoryProvider = Provider<ExerciseHistoryRepository>((ref) =>
  ExerciseHistoryRepository(ref.watch(appDatabaseProvider)));

final exerciseHistoryProvider = StreamProvider.autoDispose
  .family<List<ExercisePerformance>, ExerciseHistoryKey>((ref, key) {
    final auth = ref.watch(authStateProvider);
    if (!auth.isSignedIn || auth.accountId != key.accountId) {
      return Stream.value(const <ExercisePerformance>[]);
    }
    return ref.watch(exerciseHistoryRepositoryProvider).watchCompletedHistory(
      accountId: key.accountId, exerciseId: key.exerciseId,
    );
  });
```

- [ ] **3.4 GREEN:** powtórz komendę 3.2; PASS. Test nie tworzy produkcyjnego AuthController ani połączenia HTTP.

## Zadanie 4: osobne wykresy i stany puste

**Pliki:** nowy widget wykresu i `exercise_history_chart_test.dart`.

- [ ] **4.1 RED — testy wykresu:**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/features/workout/history/domain/exercise_history_calculator.dart';
import 'package:fitbirek_training/features/workout/history/presentation/widgets/exercise_history_chart.dart';
import 'history_fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  testWidgets('brak metryki nie produkuje zera, jeden punkt nie udaje trendu', (tester) async {
    final sessions = calculateExerciseHistory([samplePerformance(sets: [
      sampleSet(kg: null, reps: null, seconds: 45),
    ])]).sessions;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ExerciseHistoryChart(
      sessions: sessions, metric: ExerciseHistoryMetric.weight,
    ))));
    expect(find.text('Brak danych dla wykresu ciężaru'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ExerciseHistoryChart(
      sessions: sessions, metric: ExerciseHistoryMetric.seconds,
    ))));
    expect(find.text('Jedno wykonanie — brak trendu'), findsOneWidget);
    expect(tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.single.spots.single.y, 45);
  });
  testWidgets('osobne metryki, chronologia i kontekst powtórzeń', (tester) async {
    final sessions = calculateExerciseHistory([
      samplePerformance(day: 3, sets: [sampleSet(kg: 20, reps: 6, seconds: 60)]),
      samplePerformance(day: 2, sets: [sampleSet(kg: null, reps: null)]),
      samplePerformance(day: 1, sets: [sampleSet(kg: 10, reps: 8, seconds: 30)]),
    ]).sessions;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ExerciseHistoryChart(
      sessions: sessions, metric: ExerciseHistoryMetric.weight,
    ))));
    final points = tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.single.spots;
    expect(points.first.y, 10);
    expect(points[1], FlSpot.nullSpot);
    expect(points.last.y, 20);
    expect(find.textContaining('20.0 kg; powtórzenia: 6'), findsOneWidget);
    expect(find.text('Najwyższy ciężar (kg)'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ExerciseHistoryChart(
      sessions: sessions, metric: ExerciseHistoryMetric.seconds,
    ))));
    final time = tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.single.spots;
    expect(time.first.y, 30);
    expect(time.last.y, 60);
    expect(find.text('Najdłuższa seria (s)'), findsOneWidget);
  });
}
```

- [ ] **4.2 RED:** `flutter test test/features/workout/history/exercise_history_chart_test.dart`.
- [ ] **4.3 GREEN — widget wykresu:**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/formatters.dart';
import '../../domain/exercise_history_calculator.dart';

enum ExerciseHistoryMetric { weight, seconds }

class ExerciseHistoryChart extends StatelessWidget {
  const ExerciseHistoryChart({super.key, required this.sessions, required this.metric});
  final List<ExercisePerformanceSummary> sessions;
  final ExerciseHistoryMetric metric;

  @override
  Widget build(BuildContext context) {
    final sorted = [...sessions]..sort((a, b) {
      final time = a.source.finishedAt.compareTo(b.source.finishedAt);
      return time != 0 ? time : a.source.sessionSyncId.compareTo(b.source.sessionSyncId);
    });
    final weight = metric == ExerciseHistoryMetric.weight;
    double? value(ExercisePerformanceSummary s) => weight ? s.maxWeightKg : s.longestSeconds?.toDouble();
    final count = sorted.where((s) => value(s) != null).length;
    if (count == 0) return Text(weight ? 'Brak danych dla wykresu ciężaru' : 'Brak danych dla wykresu czasu');
    String label(ExercisePerformanceSummary s) {
      final date = Formatters.dateTime(s.source.finishedAt.toLocal());
      if (!weight) return '$date: ${s.longestSeconds} s';
      final reps = s.maxWeightSets.map((set) => set.reps?.toString() ?? 'brak danych').join(', ');
      return '$date: ${s.maxWeightKg!.toStringAsFixed(1)} kg; powtórzenia: $reps';
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(weight ? 'Najwyższy ciężar (kg)' : 'Najdłuższa seria (s)'),
      const Text('Oś X: kolejne zakończone wykonania'),
      if (count == 1) const Text('Jedno wykonanie — brak trendu'),
      SizedBox(height: 200, child: LineChart(LineChartData(
        minX: 0, maxX: sorted.length < 2 ? 1 : (sorted.length - 1).toDouble(),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((spot) => LineTooltipItem(
            label(sorted[spot.x.round()]), const TextStyle(color: Colors.white),
          )).toList(),
        )),
        lineBarsData: [LineChartBarData(
          spots: [for (var i = 0; i < sorted.length; i++)
            value(sorted[i]) == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), value(sorted[i])!)],
          isCurved: false, dotData: const FlDotData(show: true),
          color: Theme.of(context).colorScheme.primary,
        )],
      ))),
      // Czytelny również bez gestu, na klawiaturze i dla czytnika ekranu.
      for (final session in sorted)
        if (value(session) != null) Text(label(session)),
    ]);
  }
}
```

- [ ] **4.4 GREEN:** powtórz 4.2; PASS. Weryfikować też płaski przebieg dwóch identycznych punktów podczas smoke testu; `fl_chart` wyznacza własny zakres Y.

## Zadanie 5: ekran historii i reaktywna lista

**Pliki:** nowy ekran i `exercise_history_page_test.dart`. Nazwę ćwiczenia pobierać z ostatniego wykonania; dla pustej historii pokazać ID. To pozwala oglądać historię również po usunięciu ćwiczenia z katalogu, bez dodatkowego zapytania i nowego zależnego stanu błędu.

- [ ] **5.1 RED — testy ekranu:**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/workout/history/domain/exercise_history.dart';
import 'package:fitbirek_training/features/workout/history/providers/exercise_history_providers.dart';
import 'package:fitbirek_training/features/workout/history/presentation/pages/exercise_history_page.dart';
import 'exercise_history_providers_test.dart' show HistoryTestAuth;
import 'history_fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  testWidgets('loading, pusto, jedno wykonanie, brak wartości i aktualizacja', (tester) async {
    final stream = StreamController<List<ExercisePerformance>>();
    final auth = HistoryTestAuth(const AuthState.signedIn('account'));
    await tester.pumpWidget(ProviderScope(overrides: [
      authStateProvider.overrideWith((ref) => auth),
      exerciseHistoryProvider((accountId: 'account', exerciseId: 'cw001'))
        .overrideWith((ref) => stream.stream),
    ], child: const MaterialApp(home: ExerciseHistoryPage(exerciseId: 'cw001'))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    stream.add([]); await tester.pumpAndSettle();
    expect(find.text('Brak zakończonych wykonań tego ćwiczenia'), findsOneWidget);
    stream.add([samplePerformance(sets: [sampleSet(kg: null, reps: null, rpe: null)])]);
    await tester.pumpAndSettle();
    expect(find.text('Jedno wykonanie — brak porównania'), findsOneWidget);
    expect(find.textContaining('kg: brak danych'), findsOneWidget);
    expect(find.textContaining('RPE: brak danych'), findsOneWidget);
    stream.add([]); await tester.pumpAndSettle();
    expect(find.text('Brak zakończonych wykonań tego ćwiczenia'), findsOneWidget);
    expect(find.textContaining('RPE:'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await stream.close();
  });
  testWidgets('porównanie nieporównywalnych pokazuje wartości bez oceny lepiej', (tester) async {
    final data = [samplePerformance(day: 2, sets: [sampleSet(kg: 20)]), samplePerformance()];
    await tester.pumpWidget(ProviderScope(overrides: [
      authStateProvider.overrideWith((ref) => HistoryTestAuth(const AuthState.signedIn('account'))),
      exerciseHistoryProvider((accountId: 'account', exerciseId: 'cw001'))
        .overrideWith((ref) => Stream.value(data)),
    ], child: const MaterialApp(home: ExerciseHistoryPage(exerciseId: 'cw001'))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bez oceny: różne ciężary'), findsOneWidget);
    expect(find.textContaining('Ostatnie:'), findsOneWidget);
    expect(find.textContaining('Poprzednie:'), findsOneWidget);
  });
  testWidgets('błąd ma retry, auth loading natychmiast usuwa poprzednią historię', (tester) async {
    final auth = HistoryTestAuth(const AuthState.signedIn('account'));
    var attempts = 0;
    await tester.pumpWidget(ProviderScope(overrides: [
      authStateProvider.overrideWith((ref) => auth),
      exerciseHistoryProvider((accountId: 'account', exerciseId: 'cw001')).overrideWith((ref) {
        attempts++;
        return attempts == 1 ? Stream.error(StateError('db')) : Stream.value([samplePerformance()]);
      }),
    ], child: const MaterialApp(home: ExerciseHistoryPage(exerciseId: 'cw001'))));
    await tester.pumpAndSettle();
    expect(find.text('Nie udało się odczytać historii'), findsOneWidget);
    await tester.tap(find.text('Spróbuj ponownie')); await tester.pumpAndSettle();
    expect(find.text('Przysiad'), findsOneWidget);
    auth.change(const AuthState.loading()); await tester.pump();
    expect(find.text('Przysiad'), findsNothing);
    expect(find.text('Historia niedostępna w tym kontekście konta'), findsOneWidget);
  });
}
```

- [ ] **5.2 RED:** `flutter test test/features/workout/history/exercise_history_page_test.dart`.
- [ ] **5.3 GREEN — zapisz ekran:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../auth/providers/auth_providers.dart';
import '../../domain/exercise_history.dart';
import '../../domain/exercise_history_calculator.dart';
import '../../providers/exercise_history_providers.dart';
import '../widgets/exercise_history_chart.dart';

class ExerciseHistoryPage extends ConsumerWidget {
  const ExerciseHistoryPage({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    Widget body;
    if (!auth.isSignedIn || auth.accountId == null) {
      body = const Center(child: Text('Historia niedostępna w tym kontekście konta'));
    } else {
      final key = (accountId: auth.accountId!, exerciseId: exerciseId);
      body = ref.watch(exerciseHistoryProvider(key)).when(
        skipLoadingOnReload: false, skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Nie udało się odczytać historii'),
          TextButton(onPressed: () => ref.invalidate(exerciseHistoryProvider(key)),
            child: const Text('Spróbuj ponownie')),
        ])),
        data: (data) => _HistoryContent(exerciseId: exerciseId, data: data),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Historia ćwiczenia')),
      body: SafeArea(child: body));
  }
}

String _value(Object? value) => value?.toString() ?? 'brak danych';
String _date(ExercisePerformance p) => Formatters.dateTime(p.finishedAt.toLocal());
String _sets(ExercisePerformance p) => p.sets.map((s) =>
  '#${s.number}: kg ${_value(s.weightKg)}, powt. ${_value(s.reps)}').join('; ');

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.exerciseId, required this.data});
  final String exerciseId;
  final List<ExercisePerformance> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(exerciseId), const Text('Brak zakończonych wykonań tego ćwiczenia'),
    ]));
    final result = calculateExerciseHistory(data);
    final comparison = result.comparison;
    final delta = comparison?.repsDelta;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(result.sessions.first.source.exerciseName, style: Theme.of(context).textTheme.titleLarge),
      if (comparison == null) const Text('Jedno wykonanie — brak porównania')
      else Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dwa ostatnie zakończone wykonania'),
          Text('Ostatnie: ${_date(comparison.latest.source)}; ${_sets(comparison.latest.source)}; suma powtórzeń: ${_value(comparison.latest.totalReps)}'),
          Text('Poprzednie: ${_date(comparison.previous.source)}; ${_sets(comparison.previous.source)}; suma powtórzeń: ${_value(comparison.previous.totalReps)}'),
          Text(delta == null
            ? 'Bez oceny: różne ciężary, liczba serii lub brak danych'
            : 'Zmiana sumy powtórzeń: ${delta > 0 ? '+' : ''}$delta (ten sam ciężar i liczba serii)'),
        ],
      ))),
      const SizedBox(height: 16),
      ExerciseHistoryChart(sessions: result.sessions, metric: ExerciseHistoryMetric.weight),
      const SizedBox(height: 16),
      ExerciseHistoryChart(sessions: result.sessions, metric: ExerciseHistoryMetric.seconds),
      const SizedBox(height: 16),
      for (final session in result.sessions)
        Card(key: ValueKey('history-session-${session.source.sessionSyncId}'), child: Padding(
          padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_date(session.source)),
            Text('Objętość zarejestrowanych serii: ${_value(session.volumeKgReps)}${session.volumeKgReps == null ? '' : ' kg × powt.'}; uwzględniono ${session.volumeSetCount}/${session.source.sets.length} serii'),
            const Text('Objętość nie jest uniwersalną miarą postępu.'),
            for (final set in session.source.sets)
              Text('Seria ${set.number} — kg: ${_value(set.weightKg)}; powtórzenia: ${_value(set.reps)}; sekundy: ${_value(set.seconds)}; RPE: ${_value(set.rpe)}'),
          ]),
        )),
    ]);
  }
}
```

- [ ] **5.4 GREEN:** powtórz 5.2. PASS, bez wyświetlania wyjątków zawierających prywatne dane w UI.

## Zadanie 6: wejścia z obu ekranów i zachowanie aktywnej sesji

**Pliki:** `lib/app/router.dart`, `lib/features/exercises/presentation/pages/exercise_detail_page.dart`, `lib/features/workout/presentation/pages/active_session_page.dart`, nowy `exercise_history_navigation_test.dart`.

- [ ] **6.1 RED — testy integracji nawigacji:**

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/models/exercise.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/history/presentation/pages/exercise_history_page.dart';
import 'exercise_history_providers_test.dart' show HistoryTestAuth;
import 'history_fixtures.dart';

const exercise = Exercise(
  id: 'cw001', nazwaPl: 'Przysiad', nazwaEn: 'Squat', partiaGlowna: '',
  partieWspierajace: [], sprzet: [], typ: '', poziom: '', wzorzecRuchu: '',
  seriexPowtorzenia: '', tempo: '', kluczoweWskazowki: [], czesteBledy: [],
  progresja: '', regresja: '', zrodlo: '',
);

void main() {
  setUpAll(() => initializeDateFormatting('pl_PL'));
  // Wakelock używa kanału Pigeon; brak realnego wywołania platformowego w testach.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(
        const BasicMessageChannel<Object?>('dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle', StandardMessageCodec()),
        (message) async => <Object?>[null],
      );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(
        const BasicMessageChannel<Object?>('dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle', StandardMessageCodec()), null,
      );
  });
  for (final fromSession in [false, true]) {
    testWidgets('wejście ${fromSession ? 'z aktywnego treningu' : 'ze szczegółów'} i powrót niczego nie zapisują', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await bindHistoryAccount(db);
      final completed = await seedSession(db, id: 'completed');
      await seedSet(db, completed, id: 'completed-set', kg: null, reps: null, rpe: null);
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authStateProvider.overrideWith((ref) => HistoryTestAuth(const AuthState.signedIn('account'))),
        allExercisesProvider.overrideWith((ref) => Stream.value([exercise])),
      ]);
      if (fromSession) {
        final notifier = container.read(activeWorkoutProvider.notifier);
        await notifier.startSession(); notifier.addExercise(exercise);
      }
      final before = container.read(activeWorkoutProvider);
      final queue = (await db.syncDao.pendingOperations()).map((o) => o.toJson()).toList();
      final router = createRouter(
        readAuthState: () => const AuthState.signedIn('account'),
        readOnboardingComplete: () => true,
        initialLocation: fromSession ? '/workout/session' : '/exercises/cw001',
      );
      await tester.pumpWidget(UncontrolledProviderScope(container: container,
        child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      if (fromSession) await tester.enterText(find.widgetWithText(TextField, 'Ciężar (kg)'), '12.5');
      final button = find.byKey(const ValueKey('exercise-history-cw001'));
      await tester.ensureVisible(button); await tester.tap(button); await tester.pumpAndSettle();
      expect(find.byType(ExerciseHistoryPage), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/exercise-history/cw001');
      expect(find.textContaining('Seria 1 — kg: brak danych'), findsOneWidget);
      router.pop(); await tester.pumpAndSettle();
      expect(container.read(activeWorkoutProvider), same(before));
      if (fromSession) expect(find.text('12.5'), findsOneWidget);
      expect((await db.syncDao.pendingOperations()).map((o) => o.toJson()).toList(), queue);
      expect(await db.select(db.personalRecords).get(), isEmpty);
      await tester.pumpWidget(const SizedBox());
      router.dispose(); container.dispose(); await db.close();
    });
  }
  test('deep link historii jest chroniony', () {
    expect(authRedirect(authState: const AuthState.signedOut(), onboardingComplete: true,
      location: '/exercise-history/cw001'), '/login');
  });
}
```

Kanał platformowy sprawdzić z zablokowaną wersją `wakelock_plus_platform_interface` w `.dart_tool/package_config.json` i jej wygenerowanym Pigeon, jeżeli RED ujawni inny kanał. To naprawa testowego adaptera, nie zgoda na zmianę pakietu ani kodu aplikacji.

- [ ] **6.2 RED:** `flutter test test/features/workout/history/exercise_history_navigation_test.dart`; oczekiwane brak przycisku/trasy. Jeśli błąd dotyczy Google Fonts/shella, najpierw użyć istniejącej konfiguracji testowej projektu, nie zamieniać routera produkcyjnego atrapą.
- [ ] **6.3 GREEN — trasa:** w `lib/app/router.dart` dodaj import:

```dart
import '../features/workout/history/presentation/pages/exercise_history_page.dart';
```

W głównym `routes`, po `/onboarding`, przed `StatefulShellRoute.indexedStack`, dodaj:

```dart
GoRoute(
  path: '/exercise-history/:exerciseId',
  builder: (context, state) => ExerciseHistoryPage(
    exerciseId: state.pathParameters['exerciseId']!,
  ),
),
```

- [ ] **6.4 GREEN — szczegóły:** w `exercise_detail_page.dart`, przed istniejącym `PrimaryButton(label: 'Rozpocznij trening z tym ćwiczeniem', ...)`, dodaj:

```dart
OutlinedButton.icon(
  key: ValueKey('exercise-history-${ex.id}'),
  onPressed: () => context.push('/exercise-history/${Uri.encodeComponent(ex.id)}'),
  icon: const Icon(Icons.history),
  label: const Text('Historia ćwiczenia'),
),
const SizedBox(height: 12),
```

- [ ] **6.5 GREEN — aktywna sesja:** zastąp cały `FutureBuilder` z `getLastSet(widget.exercise.id)` w `_ExerciseLogCardState.build` następującym widgetem:

```dart
OutlinedButton.icon(
  key: ValueKey('exercise-history-${widget.exercise.id}'),
  onPressed: () => context.push('/exercise-history/${Uri.encodeComponent(widget.exercise.id)}'),
  icon: const Icon(Icons.history),
  label: const Text('Historia ćwiczenia'),
),
```

Nie usuwać `getLastSet` z repozytorium — inni konsumenci mogą go używać. Nie dodawać nowej obserwacji aktywnego treningu ani przełączania `isActive`; historia nakłada stronę na stos nawigacji.

- [ ] **6.6 GREEN:** powtórz 6.2; oba wejścia i powrót PASS, stan aktywnej sesji zachowany, brak nowych serii/PR/outboxu. Skontrolować lokalny diff tego pliku względem aktualnego etapu 1, bez zastępowania całego pliku starszą kopią.

## Zadanie 7: domknięcie regresji, zgodność i odbiór

**Pliki:** wyłącznie pliki z mapy; nie zmieniać backendu, deploymentu, `pubspec.lock` ani wersji aplikacji w ramach tego etapu bez decyzji o wydaniu.

- [ ] **7.1 Uruchom cały nowy podzbiór:** `flutter test test/features/workout/history`. Oczekiwane PASS; brak sieci w nowych testach, brak ostrzeżeń o żywych subskrypcjach po teardown.
- [ ] **7.2 Uruchom regresje istniejących operacji:**

```bash
flutter test test/features/workout/deleted_session_test.dart test/features/mentor/mentor_actions_test.dart test/features/mentor/mentor_operations_test.dart test/features/auth/offline_auth_test.dart test/app/router_test.dart test/core/restore_sync_regression_test.dart
```

Oczekiwane PASS. Jeżeli etap 1 dodał testy uruchamiania z planu, uruchomić również jego wskazany zestaw — nie zmieniać kontraktu kontrolera treningu, aby „naprawić” historię.

- [ ] **7.3 Sformatuj tylko dotknięte pliki i wykonaj analizę:**

```bash
dart format lib/features/workout/history test/features/workout/history lib/app/router.dart lib/features/exercises/presentation/pages/exercise_detail_page.dart lib/features/workout/presentation/pages/active_session_page.dart
flutter analyze
flutter test
git diff --check
```

Nie uruchamiać bezrefleksyjnie `dart format .` w zastanym brudnym drzewie: pełny standard projektu to `dart format . && flutter analyze && flutter test`, lecz formatowanie niezwiązanych plików musi zostać wyłączone z zakresu tego etapu. Oczekiwane zero nowych błędów analizy i PASS testów; zastane awarie raportować z nazwą i wynikiem, nie deklarować pełnego sukcesu.

- [ ] **7.4 Sprawdź brak konieczności generatora:** modele są zwykłym Dart, zapytanie zdefiniowane jest w repozytorium, nie zmieniono `@DriftAccessor`, tabel, Freezed ani JSON. Jeśli podczas implementacji jednak zmieniono takie deklaracje, obowiązkowo `dart run build_runner build --delete-conflicting-outputs`, przegląd wygenerowanych plików oraz ponowne testy; nie rozszerzać schematu dla samej historii.
- [ ] **7.5 Sprawdź Web SQLite:** odczytaj sekcje `drift` i `sqlite3` w `pubspec.lock`, potwierdź 2.28.2 / 2.9.4, wykonaj `git diff -- pubspec.lock web/sqlite3.wasm web/drift_worker.dart.js` i sprawdź, że etap nie zmienił tych plików. Istniejące README/CONTRIBUTING deklarują zgodność tych wersji; nie nazywać samego braku diffu kryptograficznym potwierdzeniem binarek. Jeżeli potrzebne jest ponowne potwierdzenie pochodzenia, porównać artefakty z oficjalnymi wydaniami dokładnie tych wersji. Nie aktualizować pakietów tylko dla historii.
- [ ] **7.6 Smoke offline na Web:** przed buildem `dart tools/generate_app_version.dart --check`, potem `flutter build web --release`. Uruchomić lokalnie zgodnie z istniejącym workflow klienta (bez deployu). Z kontem mającym lokalną historię przełączyć przeglądarkę offline, wejść z obu ekranów, wrócić do treningu, zakończyć nową sesję i ponownie otworzyć historię. Sprawdzić dwie różne daty, jeden punkt, brak danych, dwie równe wartości, wąski ekran oraz działanie Back. Żadne wejście nie powinno wymagać żądania API.
- [ ] **7.7 Kontrola odbioru:** przejrzyj poniższą macierz, sprawdź `git status --short` i diff wyłącznie własnych ścieżek. Nie commituj ani nie wdrażaj. Główny agent przeprowadza przegląd planu/implementacji; nie delegować samorecenzji planu.

### Macierz kryteriów odbioru

| Wymaganie | Dowód |
| --- | --- |
| Historia zakończonych sesji jednego ćwiczenia | Test JOIN w zadaniu 2 |
| Tombstone rodzica z żywą serią, tombstone dziecka, sesja aktywna | Testy 2.2; istniejące testy usuwania w 7.2 |
| Stabilna kolejność przy równych datach i numerach serii | Testy 1.2 i 2.2 |
| Brak wartości nie jest zerem | Testy 1.2, 2.2, 5.1 |
| Dwie ostatnie sesje; różne ciężary/liczby serii bez oceny | Testy 1.2 i 5.1 |
| Osobne metryki ciężaru, objętości i czasu | Testy 1.2 i 4.1 |
| Maksymalny ciężar ma kontekst wszystkich odpowiadających powtórzeń | Test 1.2 i etykiety 4.3 |
| Pusta historia, jedna sesja i brak metryki wykresu | Testy 1.2, 4.1, 5.1 |
| Reakcja na lokalny zapis/pull/restore | Obserwowany JOIN wszystkich trzech tabel; test 2.2 oraz istniejące regresje restore |
| Auth loading/logout nie pozostawia danych poprzedniego konta | Testy 3.1 i 5.1; binding w 2.2 |
| Dwa wejścia i Back bez modyfikacji treningu | Testy 6.1 |
| Brak dodatkowych PR i operacji synchronizacji | Testy 2.2, 6.1 |
| Obliczenia i odczyt bez sieci | Czyste funkcje; repo z bazą pamięciową; auth testowy zabrania sieci; smoke 7.6 |
| Brak zmian kontraktu danych i artefaktów | Kontrole 7.4–7.5 |

## Publiczne interfejsy dla etapu 3

Importy:

```dart
import 'package:fitbirek_training/features/workout/history/domain/exercise_history.dart';
import 'package:fitbirek_training/features/workout/history/data/exercise_history_repository.dart';
import 'package:fitbirek_training/features/workout/history/providers/exercise_history_providers.dart';
```

- `ExerciseHistorySet`: `syncId`, `syncVersion`, `updatedAtUtc`, `number`, `timestamp`, nullable `weightKg`, `reps`, `seconds`, `rpe`. Wszystkie serie, bez selekcji „najlepszych”.
- `ExercisePerformance`: `exerciseId`, `exerciseName`, `sessionSyncId`, `sessionSyncVersion`, `sessionUpdatedAtUtc`, `finishedAt`, niemutowalne `sets`.
- `ExerciseHistoryRepository.watchCompletedHistory({required String accountId, required String exerciseId}) → Stream<List<ExercisePerformance>>`.
- `ExerciseHistoryRepository.getCompletedHistory({required String accountId, required String exerciseId}) → Future<List<ExercisePerformance>>`.
- Lista repo jest uporządkowana od najnowszego zakończonego wykonania. `list.firstOrNull` jest źródłem silnika progresji; pusty wynik oznacza brak dostępnego wykonania, nie uprawnienie do zapisu.
- `ExerciseHistoryKey = ({String accountId, String exerciseId})` i `exerciseHistoryProvider(key)` dla widoku sugestii. `exerciseHistoryRepositoryProvider` dla operacji aplikacyjnych.
- `summarizePerformance(ExercisePerformance)` i `calculateExerciseHistory(List<ExercisePerformance>)` są publiczne, ale silnik progresji powinien używać surowych serii: agregaty celowo dopuszczają niepełne dane i nie sprawdzają warunków progresji.

Przykład użycia w przyszłym etapie 3 (odczyt, nie akceptacja):

```dart
final history = await ref.read(exerciseHistoryRepositoryProvider)
  .getCompletedHistory(accountId: accountId, exerciseId: exerciseId);
final ExercisePerformance? latest = history.isEmpty ? null : history.first;
```

### Granica aktualności i luki, które musi rozwiązać etap 3

- `getCompletedHistory` zwraca spójny snapshot jednego zapytania, ale nie blokuje późniejszej edycji ani zmiany konta. Etap 3 musi ponownie sprawdzić auth/binding i odczytać źródło **w transakcji akceptacji celu**, razem z regułą planu. Nie opierać bezpieczeństwa zapisu na stanie strony ani starej przyszłości.
- Same `syncVersion` nie wykrywają wszystkich lokalnych edycji przed synchronizacją. Fingerprint sugestii powinien obejmować identyfikator sesji, datę zakończenia, metadane, wszystkie ID i wartości serii, a także regułę planu; nie tylko maksimum ciężaru czy liczbę serii. Format fingerprintu i zapis celu należą do etapu 3.
- Obecna baza nie wspiera równoległego przechowywania kont A/B: binding odrzuca inne konto. Plan nie dodaje przełączania właściciela bazy. Test „A → B” providera symuluje zmianę kontekstu i sprawdza brak wycieku; w realnej bazie niedopasowany binding zwraca pusto.
- Historia nie zawiera `planId`, zgodnie ze specyfikacją: źródłem progresji ma być ostatnie wykonanie tego ćwiczenia również poza planem. Powiązanie reguły z planem i unieważnienie po usunięciu planu należą do etapu 3.
- Historia nie zmienia istniejącego kontraktu synchronizacji ani backupu. Rozszerzenia chroniące reguły/cele przed starszym klientem wymagają odrębnej pracy etapu 3.
- Polityka remisu `syncId DESC`, traktowanie jawnego zera oraz kontekst wielu serii o najwyższym ciężarze są decyzjami tego planu uszczegóławiającymi specyfikację; nie wymagają nowych danych.
- Nie ma paginacji: pierwsza wersja ogląda całą lokalną historię jednego ćwiczenia. W razie pomiaru problemu wydajności można osobno dodać okno/paginację, zachowując pełne dwa najnowsze wykonania i nie zmieniając semantyki etapu 3.
- W chwili zapisania planu nie wykonywano kodu z bloków ani testów implementacji. Adapter kanału platformowego należy zweryfikować w RED/GREEN z aktualnym lockfile, nie przez aktualizację zależności. Zapis planu nie stanowi deklaracji gotowej lub przetestowanej funkcji.
