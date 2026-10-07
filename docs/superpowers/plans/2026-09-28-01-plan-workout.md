# Trening z zapisanego planu — etap 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Umożliwić bezpieczny start treningu z zapisanego lokalnego planu, z walidacją, potwierdzeniami i bez tworzenia fikcyjnych serii.

**Architecture:** Lokalny loader rozwiązuje identyfikator planu i identyfikatory ćwiczeń, a `ActiveWorkoutNotifier` koordynuje potwierdzenia, wspólną rezerwację startu i publikację kompletnego stanu po transakcji. `WorkoutRepository` sprawdza kontekst danych i aktywną sesję również w SQLite; dotychczasowa idempotencja Mentora pozostaje odrębnym, uwierzytelnionym kontraktem. UI odpowiada za dialogi i przejście na istniejącą trasę `/workout/session`.

**Tech Stack:** Flutter 3.35.4, Dart 3.9.2, Riverpod/StateNotifier, Drift 2.28.2, sqlite3 2.9.4, flutter_test, GoRouter.

---

## Granice, stan wejściowy i uzgodnienia integracyjne

- Źródło wymagań: `docs/superpowers/specs/2026-09-28-plany-historia-progresja-design.md`, sekcje „Etap 1”, ograniczenia, bezpieczeństwo danych i kryteria odbioru etapu 1. Akceptację przyjmujemy zgodnie z poleceniem użytkownika, mimo historycznej adnotacji w wierszu 4 specyfikacji.
- Ten dokument nie implementuje historii ćwiczeń, reguł progresji, migracji planów, backendu ani wdrożenia. Nie edytować dokumentów etapów 2 i 3.
- Pracować wyłącznie w kliencie w `/opt/fit`, bez dodatkowej kopii aplikacji. Nie cofać istniejących zmian. Ten plan nie zleca commitów; o integracji decyduje użytkownik.
- Przeczytane punkty integracji: `workout_providers.dart` (w tym istniejące `startMentorSession`, `_pendingMentorStart`, `_generation`, `_isCurrent`), `workout_repository.dart`, `planner_page.dart`, `planner_repository.dart`, `planner_providers.dart`, `active_session_page.dart`, DAO planów, ćwiczeń, sesji i synchronizacji, auth oraz istniejące testy Mentora i usuwania sesji.
- Obecne `WorkoutRepository.startSession()` zawsze tworzy wiersz. `startSessionIdempotent()` sprawdza aktywne sesje i konto, lecz wymaga `accountId` i `offlineAccess`. **Nie używać go do startu z planu ani do zwykłego startu bez konta.** Brak `SyncState` to prawidłowy lokalny kontekst. Istniejący `SyncState` z `offlineAccess == false` nie jest trybem anonimowym.
- Wybrane ćwiczenia bez serii pozostają w stanie aktywnego kontrolera, tak jak obecnie. Po restarcie można wznowić sesję i jej rzeczywiste serie; lista niezapisanych ćwiczeń nie jest obecnie trwała. Nie wprowadzać ukrytego zapisu „zerowych serii” ani nowego kontraktu synchronizacji w celu obejścia tego ograniczenia.
- Powrót do aktywnej sesji nie dopisuje do niej ćwiczeń z klikniętego planu. Jeśli sesja istnieje tylko w DB, odtworzyć rzeczywiste serie oraz możliwe do rozwiązania ćwiczenia z tych serii. Brak pozycji katalogu nie usuwa historycznej serii.
- Gdy w starej bazie jest więcej niż jedna aktywna sesja, zachować aktualną sesję kontrolera, jeśli jej wiersz nadal jest aktywny; przy odtwarzaniu bez stanu w pamięci deterministycznie wskazać najstarszą (`dataStart`, następnie `id`). Nie tworzyć kolejnej i nie usuwać pozostałych. To nie jest migracja naprawcza.
- Potwierdzenie braków nie może autoryzować innego planu po zmianie konta, edycji, usunięciu lub przywróceniu danych. Po dialogu ponownie odczytać plan i katalog w transakcji, porównać odcisk rozwiązanego planu, sprawdzić kontekst i generation guard.
- Transakcja nigdy nie czeka na dialog. Błąd zapisu wycofuje sesję i outbox; publikacja stanu dopiero po sukcesie. Zmiana kontekstu po commit, ale przed publikacją, blokuje publikację starego wyniku; nie usuwać wtedy kompensacyjnie danych, które mogą już należeć do innego kontekstu.

## Pliki i odpowiedzialności

| Operacja | Dokładna ścieżka | Odpowiedzialność |
|---|---|---|
| Utwórz | `lib/features/workout/data/plan_workout_loader.dart` | Lokalny odczyt planu, dedup, rozwiązanie katalogu, odcisk walidacji i błędy domenowe |
| Zmień | `lib/features/workout/data/workout_repository.dart` | Kontekst lokalny/kontowy i atomowy start lub zwrot istniejącej sesji |
| Zmień | `lib/features/workout/providers/workout_providers.dart` | Wspólna blokada startu, walidacja po dialogu, wznowienie, generation guards |
| Utwórz | `lib/features/workout/presentation/widgets/workout_start_ui.dart` | Wspólne komunikaty, dialogi i bezpieczna nawigacja |
| Zmień | `lib/features/planner/presentation/pages/planner_page.dart` | Przycisk na zapisanym planie i blokada przycisków podczas operacji |
| Zmień | `lib/features/workout/presentation/pages/active_session_page.dart` | Jawny stan zapisanych serii, pomijanie ćwiczeń, stabilne klucze kart |
| Zmień | `lib/features/workout/presentation/pages/workout_home_page.dart` | Obsługa odmowy/błędu zwykłego startu, brak fałszywej nawigacji |
| Zmień | `lib/features/home/presentation/pages/classic_today_page.dart` | Jak wyżej |
| Zmień | `lib/features/exercises/presentation/pages/exercise_detail_page.dart` | Nie dodawać ćwiczenia po nieudanym lub odrzuconym starcie |
| Utwórz | `test/features/workout/plan_workout_fixture.dart` | Rzeczywista baza pamięciowa, stabilny auth bez sieci, bariery testowe |
| Utwórz | `test/features/workout/plan_workout_test.dart` | Testy loadera, transakcji, kontrolera i współbieżności |
| Utwórz | `test/features/workout/plan_workout_ui_test.dart` | Dialogi, nawigacja, blokady i stan kart |

Nie zmieniać schematu Drift, Freezed ani JSON. Nie trzeba dodawać pola `planId` do sesji. `PlannerRepository.savePlan`, payload planów i `SavedPlan` pozostają nietknięte, co ogranicza konflikt z etapem 3. Etap 2 może zmieniać `active_session_page.dart` i `exercise_detail_page.dart`; integrować te hunki sekwencyjnie, nie nadpisując jego przycisków historii.

## Publiczne interfejsy po etapie 1

```dart
// workout_repository.dart — nowe, zwykłe typy Dart, bez generatora.
typedef WorkoutDataContext = ({String? accountId, String? deviceId});
// null/null oznacza brak powiązania konta, nie blokadę wylogowanego konta.

// Metody WorkoutRepository:
Future<WorkoutDataContext> readDataContext();
Future<void> requireDataContext(WorkoutDataContext expected,
    {bool Function()? guard});
Future<WorkoutSessionData?> findActiveSession();
Future<int> startSession({WorkoutDataContext? context, bool Function()? guard});

// plan_workout_loader.dart:
Future<ResolvedPlanWorkout> loadPlanWorkout(AppDatabase db, int planId);

// workout_providers.dart — dodatkowe API ActiveWorkoutNotifier:
Future<PlanWorkoutStartResult> startFromPlan(
  int planId, {
  required Future<bool> Function(List<String> ids) confirmMissing,
  required Future<bool> Function() confirmResume,
  Future<void> Function(List<String> ids)? reportEmpty,
});
// Wynik: started / resumed / cancelled / busy / unavailable / changed / empty.
// Nieoczekiwany błąd I/O jest wyjątkiem, obsługiwanym przez wspólne UI.

// Istniejące API bez zmiany typu zwrotnego:
Future<void> startSession();
// Zajęta wspólna blokada: WorkoutStartBusy. Brak kontekstu: dotychczasowy
// WorkoutAccountUnavailable. Wznowienie zwykłego startu nie wymaga dialogu.
// startMentorSession zachowuje argumenty, wynik nullable oraz identyczny Future
// dla powtórzenia tego samego accountId:syncId.
```

## Zadanie 1: fixture i lokalne rozwiązanie planu (RED → GREEN)

**Pliki:** utwórz `test/features/workout/plan_workout_fixture.dart`, `test/features/workout/plan_workout_test.dart`, `lib/features/workout/data/plan_workout_loader.dart`.

- [ ] **1.1. Dodaj fixture z prawdziwą bazą, bez HTTP.** Pełna zawartość `test/features/workout/plan_workout_fixture.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';

class NoNetworkAuth implements AuthApi {
  @override
  Future<AuthSession?> getSession() => throw StateError('Unexpected HTTP');
  @override
  Future<AuthSession> login({required String email, required String password}) =>
      throw StateError('Unexpected HTTP');
  @override
  Future<void> logout() => throw StateError('Unexpected HTTP');
}

class TestWorkoutAuth extends AuthController {
  TestWorkoutAuth() : super(NoNetworkAuth()) {
    state = const AuthState.signedOut();
  }
  void change(AuthState value) => state = value;
}

Future<void> insertExercise(AppDatabase db, String id) async {
  await db.into(db.exercises).insert(ExercisesCompanion.insert(
    id: id, nazwaPl: 'Ćwiczenie $id', nazwaEn: id,
    partiaGlowna: 'Klatka', partieWspierajace: '[]', sprzet: '[]',
    typ: 'Siła', poziom: 'Początkujący', wzorzecRuchu: 'Pchanie',
    seriexPowtorzenia: '3x8', tempo: '', kluczoweWskazowki: '[]',
    czesteBledy: '[]', progresja: '', regresja: '', zrodlo: 'test',
  ));
}

class WorkoutFixture {
  WorkoutFixture({WorkoutRepository Function(AppDatabase)? repository}) {
    repo = repository?.call(db) ?? WorkoutRepository(db);
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      workoutRepositoryProvider.overrideWithValue(repo),
      authStateProvider.overrideWith((ref) => auth),
    ]);
  }
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final auth = TestWorkoutAuth();
  late final WorkoutRepository repo;
  late final ProviderContainer container;
  ActiveWorkoutNotifier get notifier => container.read(activeWorkoutProvider.notifier);
  ActiveWorkoutState get state => container.read(activeWorkoutProvider);
  Future<int> plan(List<String> ids) => PlannerRepository(db).savePlan(
    nazwa: 'Plan testowy', cwiczeniaIds: ids, cel: 'sila',
  );
  Future<void> close() async {
    container.dispose();
    await db.close();
  }
}
```

- [ ] **1.2. Dodaj pierwszy zestaw testów.** Początek `test/features/workout/plan_workout_test.dart` (kolejne zadania dopisują testy wewnątrz tego samego `main`):

```dart
import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/planner/data/planner_repository.dart';
import 'package:fitbirek_training/features/workout/data/plan_workout_loader.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'plan_workout_fixture.dart';

void main() {
  late WorkoutFixture f;
  setUp(() => f = WorkoutFixture());
  tearDown(() => f.close());

  test('kolejność pierwszych ID, dedup i unikalne braki', () async {
    await insertExercise(f.db, 'b');
    await insertExercise(f.db, 'a');
    final id = await f.plan(['b', 'missing', 'a', 'b', 'missing']);
    final before = (await f.db.plansDao.getPlan(id))!.toJson();
    final result = await loadPlanWorkout(f.db, id);
    expect(result.exercises.map((e) => e.id), ['b', 'a']);
    expect(result.missingIds, ['missing']);
    expect((await f.db.plansDao.getPlan(id))!.toJson(), before);
    expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
    expect(await f.db.workoutDao.getAllSets(), isEmpty);
  });

  for (final ids in [<String>[], ['missing', 'missing']]) {
    test('loader zwraca pustą listę dla $ids', () async {
      final result = await loadPlanWorkout(f.db, await f.plan(ids));
      expect(result.exercises, isEmpty);
      expect(result.missingIds, ids.toSet().toList());
    });
  }

  test('usunięty i nieistniejący plan nie są przywracane', () async {
    final id = await f.plan(['a']);
    await PlannerRepository(f.db).deletePlan(id);
    await expectLater(loadPlanWorkout(f.db, id), throwsA(isA<PlanWorkoutUnavailable>()));
    await expectLater(loadPlanWorkout(f.db, -1), throwsA(isA<PlanWorkoutUnavailable>()));
  });
}
```

- [ ] **1.3. RED:** `flutter test test/features/workout/plan_workout_test.dart`. Oczekiwane: brak `plan_workout_loader.dart`/`loadPlanWorkout`, nie błąd platformy lub zależności.
- [ ] **1.4. Dodaj pełny loader.** Zawartość `lib/features/workout/data/plan_workout_loader.dart`:

```dart
import 'dart:convert';
import '../../../core/database/app_database.dart';
import '../../../core/models/exercise.dart';
import '../../exercises/data/exercises_repository.dart';

class PlanWorkoutUnavailable extends StateError {
  PlanWorkoutUnavailable() : super('Plan jest niedostępny.');
}

class ResolvedPlanWorkout {
  ResolvedPlanWorkout(this.fingerprint, List<Exercise> exercises,
      List<String> missingIds)
      : exercises = List.unmodifiable(exercises),
        missingIds = List.unmodifiable(missingIds);
  final String fingerprint;
  final List<Exercise> exercises;
  final List<String> missingIds;
}

Future<ResolvedPlanWorkout> loadPlanWorkout(AppDatabase db, int planId) async {
  final row = await db.plansDao.getPlan(planId);
  if (row == null || row.deletedAtUtc != null) throw PlanWorkoutUnavailable();
  final decoded = jsonDecode(row.cwiczeniaIds);
  if (decoded is! List || decoded.any((id) => id is! String || id.isEmpty)) {
    throw const FormatException('Nieprawidłowe identyfikatory ćwiczeń w planie.');
  }
  final ids = List<String>.from(decoded).toSet(); // LinkedHashSet: pierwsze wystąpienie.
  final catalog = ExercisesRepository(db);
  final exercises = <Exercise>[];
  final missing = <String>[];
  for (final id in ids) {
    final exercise = await catalog.getById(id);
    if (exercise == null) {
      missing.add(id);
    } else {
      exercises.add(exercise);
    }
  }
  return ResolvedPlanWorkout(
    jsonEncode([
      row.syncId, row.updatedAtUtc.toIso8601String(), row.cwiczeniaIds,
      exercises.map((e) => e.id).toList(), missing,
    ]),
    exercises,
    missing,
  );
}
```

- [ ] **1.5. GREEN:** ponownie `flutter test test/features/workout/plan_workout_test.dart`; wszystkie testy loadera przechodzą. Formatować tylko dodane pliki, bez generatora.

## Zadanie 2: lokalny kontekst i transakcyjna ochrona zwykłego startu

**Pliki:** zmień `lib/features/workout/data/workout_repository.dart`, dopisz testy do `test/features/workout/plan_workout_test.dart`.

- [ ] **2.1. Dodaj testy repozytorium.** Wewnątrz `main`:

```dart
test('bez konta: dwa starty repo dają jeden wiersz i jeden outbox', () async {
  expect(await f.db.syncDao.readState(), isNull);
  final ids = await Future.wait([f.repo.startSession(), f.repo.startSession()]);
  expect(ids[0], ids[1]);
  expect(await f.db.select(f.db.workoutSessions).get(), hasLength(1));
  expect(await f.db.syncDao.pendingOperations(), hasLength(1));
});

test('blokada konta nie jest anonimowym trybem lokalnym', () async {
  await f.db.into(f.db.syncState).insert(SyncStateCompanion.insert(
    accountId: 'a', deviceId: 'd', offlineAccess: const Value(false),
  ));
  await expectLater(f.repo.startSession(), throwsA(isA<WorkoutAccountUnavailable>()));
  expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
  expect(await f.db.syncDao.pendingOperations(), isEmpty);
});

test('zmiana kontekstu odrzuca stary start', () async {
  final local = await f.repo.readDataContext();
  await f.db.into(f.db.syncState).insert(SyncStateCompanion.insert(
    accountId: 'a', deviceId: 'd',
  ));
  await expectLater(f.repo.startSession(context: local),
      throwsA(isA<WorkoutAccountUnavailable>()));
  expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
});

test('guard po zapisie wycofuje sesję oraz kolejkę', () async {
  var allowed = true;
  await expectLater(f.db.transaction(() async {
    await f.repo.startSession(guard: () => allowed);
    allowed = false;
    await f.repo.requireDataContext((accountId: null, deviceId: null),
        guard: () => allowed);
  }), throwsA(isA<WorkoutAccountUnavailable>()));
  expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
  expect(await f.db.syncDao.pendingOperations(), isEmpty);
});

test('zakończona lub usunięta sesja nie blokuje nowej', () async {
  final first = await f.repo.startSession();
  await f.repo.finishSession(first, DateTime.now());
  final second = await f.repo.startSession();
  expect(second, isNot(first));
  await (f.db.update(f.db.workoutSessions)..where((s) => s.id.equals(second)))
      .write(WorkoutSessionsCompanion(deletedAtUtc: Value(DateTime.now().toUtc())));
  expect(await f.repo.startSession(), isNot(second));
});
```

- [ ] **2.2. RED:** `flutter test test/features/workout/plan_workout_test.dart`. Oczekiwane: brak nowego API lub dwie sesje zamiast jednej.
- [ ] **2.3. Dodaj typy przy istniejących wyjątkach repozytorium:**

```dart
typedef WorkoutDataContext = ({String? accountId, String? deviceId});

class WorkoutStartBusy extends StateError {
  WorkoutStartBusy() : super('Trwa już uruchamianie treningu.');
}
```

- [ ] **2.4. Dodaj poniższe metody i zastąp wyłącznie istniejącą metodę `WorkoutRepository.startSession`.** Nie zmieniać `startSessionIdempotent`, `_requireAccount`, logowania serii ani payloadów.

```dart
Future<WorkoutDataContext> readDataContext() async {
  final binding = await _db.syncDao.readState();
  if (binding != null && !binding.offlineAccess) {
    throw WorkoutAccountUnavailable();
  }
  return (accountId: binding?.accountId, deviceId: binding?.deviceId);
}

Future<void> requireDataContext(WorkoutDataContext expected,
    {bool Function()? guard}) async {
  _requireGuard(guard);
  final actual = await readDataContext();
  _requireGuard(guard);
  if (actual != expected) throw WorkoutAccountUnavailable();
}

Future<WorkoutSessionData?> findActiveSession() {
  return (_db.select(_db.workoutSessions)
        ..where((s) => s.dataKoniec.isNull() & s.deletedAtUtc.isNull())
        ..orderBy([
          (s) => OrderingTerm.asc(s.dataStart),
          (s) => OrderingTerm.asc(s.id),
        ])
        ..limit(1))
      .getSingleOrNull();
}

Future<int> startSession({WorkoutDataContext? context, bool Function()? guard}) async {
  _requireGuard(guard);
  final expected = context ?? await readDataContext();
  _requireGuard(guard);
  return _db.transaction(() async {
    await requireDataContext(expected, guard: guard);
    final active = await findActiveSession();
    _requireGuard(guard);
    if (active != null) {
      await requireDataContext(expected, guard: guard);
      return active.id;
    }
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    final id = await _db.workoutDao.createSession(
      WorkoutSessionsCompanion.insert(
        dataStart: now, syncId: Value(syncId), updatedAtUtc: Value(now),
      ),
    );
    _requireGuard(guard);
    await _db.syncDao.enqueueUpsert(
      entityType: SyncEntityType.workoutSession,
      entityId: syncId,
      baseVersion: 0,
      payload: _sessionPayload(
        dataStart: now, dataKoniec: null, czasTrwaniaSekund: 0, notatka: null,
      ),
    );
    await requireDataContext(expected, guard: guard);
    return id;
  });
}
```

- [ ] **2.5. GREEN i regresja repo:** `flutter test test/features/workout/plan_workout_test.dart test/features/workout/deleted_session_test.dart test/features/mentor/mentor_actions_test.dart`. Wszystkie przechodzą; test Mentora o dwóch różnych proposal nadal tworzy dokładnie jedną sesję. Ochrona DB działa także między różnymi instancjami kontrolera korzystającymi z tej samej bazy; sama blokada pamięciowa nie wystarcza.

## Zadanie 3: wspólny start, potwierdzenia i bezpieczna publikacja

**Pliki:** `lib/features/workout/providers/workout_providers.dart`, `test/features/workout/plan_workout_test.dart`.

- [ ] **3.1. Dodaj testy zachowania kontrolera:**

```dart
test('plan startuje offline, bez fikcyjnych serii i bez zmiany planu', () async {
  await insertExercise(f.db, 'b');
  await insertExercise(f.db, 'a');
  final id = await f.plan(['b', 'a', 'b']);
  final before = (await f.db.plansDao.getPlan(id))!.toJson();
  final result = await f.notifier.startFromPlan(id,
    confirmMissing: (_) async => throw StateError('Nie powinno być dialogu'),
    confirmResume: () async => false,
  );
  expect(result, PlanWorkoutStartResult.started);
  expect(f.state.selectedExercises.map((e) => e.id), ['b', 'a']);
  expect(f.state.loggedSets, isEmpty);
  expect(await f.db.workoutDao.getAllSets(), isEmpty);
  expect((await f.db.plansDao.getPlan(id))!.toJson(), before);
  f.notifier.removeExercise('b');
  final extra = await ExercisesRepository(f.db).getById('b');
  f.notifier.addExercise(extra!);
  expect(f.state.selectedExercises.map((e) => e.id), ['a', 'b']);
  expect((await f.db.plansDao.getPlan(id))!.toJson(), before);
});

for (final accept in [false, true]) {
  test('brakujące ID: potwierdzenie=$accept', () async {
    await insertExercise(f.db, 'a');
    final id = await f.plan(['a', 'missing', 'missing']);
    var dialogs = 0;
    final result = await f.notifier.startFromPlan(id,
      confirmMissing: (ids) async {
        dialogs++;
        expect(ids, ['missing']);
        expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
        return accept;
      },
      confirmResume: () async => false,
    );
    expect(dialogs, 1);
    expect(result, accept ? PlanWorkoutStartResult.started : PlanWorkoutStartResult.cancelled);
    expect(await f.db.select(f.db.workoutSessions).get(), hasLength(accept ? 1 : 0));
    expect(await f.db.workoutDao.getAllSets(), isEmpty);
  });
}

for (final ids in [<String>[], ['missing']]) {
  test('brak jakiegokolwiek ćwiczenia blokuje start $ids', () async {
    final id = await f.plan(ids);
    expect(await f.notifier.startFromPlan(id,
      confirmMissing: (_) async => throw StateError('Pusty nie wymaga zgody'),
      confirmResume: () async => false,
    ), PlanWorkoutStartResult.empty);
    expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
  });
}

for (final inMemory in [false, true]) {
  for (final accept in [false, true]) {
    test('istniejąca sesja memory=$inMemory, zgoda=$accept', () async {
      await insertExercise(f.db, 'a');
      final oldId = await f.repo.startSession();
      await f.repo.logSet(sessionId: oldId, exerciseId: 'a',
          exerciseNamePl: 'Ćwiczenie a', setNumber: 1, reps: 8);
      if (inMemory) await f.notifier.startSession();
      final planId = await f.plan(['missing']);
      final before = (await f.db.syncDao.pendingOperations()).length;
      expect(await f.notifier.startFromPlan(planId,
        confirmMissing: (_) async => throw StateError('Najpierw istniejąca sesja'),
        confirmResume: () async => accept,
      ), accept ? PlanWorkoutStartResult.resumed : PlanWorkoutStartResult.cancelled);
      expect(await f.db.select(f.db.workoutSessions).get(), hasLength(1));
      expect((await f.db.syncDao.pendingOperations()).length, before);
      if (accept) {
        expect(f.state.sessionId, oldId);
        expect(f.state.loggedSets.single.reps, 8);
        expect(f.state.selectedExercises.map((e) => e.id), ['a']);
      } else if (!inMemory) {
        expect(f.state.isActive, isFalse);
      }
    });
  }
}
```

- [ ] **3.2. RED:** `flutter test test/features/workout/plan_workout_test.dart`; brak `startFromPlan` i enumu.
- [ ] **3.3. Dodaj importy i typy do `workout_providers.dart`:**

```dart
import '../../auth/providers/auth_providers.dart';
import '../../exercises/data/exercises_repository.dart';
import '../data/plan_workout_loader.dart';
```

Zachowaj istniejący import bazy z `show WorkoutSessionData`. Typy przed `ActiveWorkoutNotifier`:

```dart
enum PlanWorkoutStartResult {
  started, resumed, cancelled, busy, unavailable, changed, empty,
}

class _PlanChanged implements Exception {}
class _PlanEmpty implements Exception {}
class _ExistingWorkout implements Exception {
  _ExistingWorkout(this.id);
  final int id;
}

class _LoadedWorkout {
  const _LoadedWorkout(this.session, this.exercises, this.sets);
  final WorkoutSessionData session;
  final List<Exercise> exercises;
  final List<ActiveSetEntry> sets;
}
```

- [ ] **3.4. Dodaj synchroniczną rezerwację i kontekst auth.** Dodatkowe pole kontrolera: `bool _startInFlight = false;`. Konstruktor zastąp poniższym; nie usuwaj dotychczasowych pól generacji ani subskrypcji:

```dart
ActiveWorkoutNotifier(this._ref) : super(const ActiveWorkoutState()) {
  _ref.listen<AuthState>(authStateProvider, (previous, next) {
    // Początkowe rozpoznanie braku konta nie unieważnia lokalnego treningu.
    if (previous == null || previous == next) return;
    if (previous.isLoading && next.isSignedOut) return;
    discardSession();
  });
}
```

Nie sprawdzaj `isSignedIn` jako warunku lokalnego startu. Auth listener służy wyłącznie natychmiastowemu unieważnianiu generacji (w tym A→loading→A). Dostęp do danych rozstrzyga lokalny `SyncState`; żadne wywołanie lokalnego startu nie pyta `getSession()`, `currentAccountId` ani Mentora. W testach provider auth jest zastąpiony stabilnym kontrolerem bez bootstrapu. W aplikacji dotychczasowy bootstrap pozostaje odpowiedzialnością warstwy auth, nie tej operacji.

- [ ] **3.5. Zastąp `ActiveWorkoutNotifier.startSession` i dodaj metody pomocnicze poniżej.** Wszystkie poniższe metody należą do tej klasy:

```dart
Future<void> startSession() async {
  if (_startInFlight) throw WorkoutStartBusy();
  _startInFlight = true;
  try {
    await _startLocal();
  } finally {
    _startInFlight = false;
  }
}

Future<PlanWorkoutStartResult> startFromPlan(
  int planId, {
  required Future<bool> Function(List<String>) confirmMissing,
  required Future<bool> Function() confirmResume,
  Future<void> Function(List<String>)? reportEmpty,
}) async {
  if (_startInFlight) return PlanWorkoutStartResult.busy;
  _startInFlight = true; // Przed pierwszym await i przed dialogiem.
  try {
    return await _startLocal(
      planId: planId,
      confirmMissing: confirmMissing,
      confirmResume: confirmResume,
      reportEmpty: reportEmpty,
    );
  } on WorkoutAccountUnavailable {
    return PlanWorkoutStartResult.unavailable;
  } on WorkoutSessionUnavailable {
    return PlanWorkoutStartResult.unavailable;
  } on PlanWorkoutUnavailable {
    return PlanWorkoutStartResult.unavailable;
  } on _PlanChanged {
    return PlanWorkoutStartResult.changed;
  } on _PlanEmpty {
    return PlanWorkoutStartResult.empty;
  } finally {
    _startInFlight = false;
  }
}

Future<PlanWorkoutStartResult> _startLocal({
  int? planId,
  Future<bool> Function(List<String>)? confirmMissing,
  Future<bool> Function()? confirmResume,
  Future<void> Function(List<String>)? reportEmpty,
}) async {
  final generation = _generation;
  final initialSessionId = state.sessionId;
  final initialExercises = List<Exercise>.of(state.selectedExercises);
  final db = _ref.read(appDatabaseProvider);
  final repo = _ref.read(workoutRepositoryProvider);
  bool ownsStart() => mounted && generation == _generation &&
      state.sessionId == initialSessionId;
  void requireOwnership() {
    if (!ownsStart()) throw WorkoutAccountUnavailable();
  }
  requireOwnership();
  final context = await repo.readDataContext();
  requireOwnership();

  Future<PlanWorkoutStartResult> resume(int id) async {
    if (confirmResume != null && !await confirmResume()) {
      requireOwnership();
      return PlanWorkoutStartResult.cancelled;
    }
    requireOwnership();
    final loaded = await db.transaction(() async {
      await repo.requireDataContext(context, guard: ownsStart);
      final current = await _loadExisting(id);
      await repo.requireDataContext(context, guard: ownsStart);
      return current;
    });
    await _publishLoaded(loaded, generation, context, ownsStart);
    return PlanWorkoutStartResult.resumed;
  }

  // Przy starych wielokrotnych sesjach nie zastępuj tej, którą użytkownik
  // już prowadzi w pamięci, inną sesją z bazy.
  final remembered = initialSessionId == null
      ? null : await db.workoutDao.getSession(initialSessionId);
  requireOwnership();
  final existing = remembered != null && remembered.deletedAtUtc == null &&
          remembered.dataKoniec == null
      ? remembered : await repo.findActiveSession();
  requireOwnership();
  if (existing != null) return resume(existing.id);

  ResolvedPlanWorkout? preview;
  if (planId != null) {
    preview = await loadPlanWorkout(db, planId);
    await repo.requireDataContext(context, guard: ownsStart);
    if (preview.exercises.isEmpty) {
      if (preview.missingIds.isNotEmpty) await reportEmpty?.call(preview.missingIds);
      await repo.requireDataContext(context, guard: ownsStart);
      throw _PlanEmpty();
    }
    if (preview.missingIds.isNotEmpty &&
        !await confirmMissing!(preview.missingIds)) {
      requireOwnership();
      return PlanWorkoutStartResult.cancelled;
    }
    requireOwnership();
  }

  late _LoadedWorkout loaded;
  try {
    loaded = await db.transaction(() async {
      await repo.requireDataContext(context, guard: ownsStart);
      final active = await repo.findActiveSession();
      requireOwnership();
      if (active != null) throw _ExistingWorkout(active.id);
      var exercises = initialExercises;
      if (planId != null) {
        final fresh = await loadPlanWorkout(db, planId);
        requireOwnership();
        if (fresh.fingerprint != preview!.fingerprint) throw _PlanChanged();
        if (fresh.exercises.isEmpty) throw _PlanEmpty();
        exercises = fresh.exercises;
      }
      final id = await repo.startSession(context: context, guard: ownsStart);
      requireOwnership();
      final row = await db.workoutDao.getSession(id);
      requireOwnership();
      if (row == null || row.deletedAtUtc != null || row.dataKoniec != null) {
        throw WorkoutSessionUnavailable(id);
      }
      await repo.requireDataContext(context, guard: ownsStart);
      return _LoadedWorkout(row, List.unmodifiable(exercises), const []);
    });
  } on _ExistingWorkout catch (existing) {
    return resume(existing.id);
  }
  await _publishLoaded(loaded, generation, context, ownsStart);
  return PlanWorkoutStartResult.started;
}

Future<void> _publishLoaded(_LoadedWorkout loaded, int generation,
    WorkoutDataContext context, bool Function() ownsStart) async {
  if (!ownsStart()) throw WorkoutAccountUnavailable();
  final db = _ref.read(appDatabaseProvider);
  final repo = _ref.read(workoutRepositoryProvider);
  await repo.requireDataContext(context, guard: ownsStart);
  // Odczyt po commit zabezpiecza przed usunięciem przed publikacją oraz
  // przed wykorzystaniem tego samego lokalnego int ID po podmianie danych.
  final latest = await db.workoutDao.getSession(loaded.session.id);
  if (!ownsStart()) throw WorkoutAccountUnavailable();
  if (latest == null || latest.syncId != loaded.session.syncId ||
      latest.deletedAtUtc != null || latest.dataKoniec != null) {
    throw WorkoutSessionUnavailable(loaded.session.id);
  }
  _attachLoaded(loaded, generation); // Bez kolejnego await przed publikacją.
}

Future<_LoadedWorkout> _loadExisting(int id) async {
  final db = _ref.read(appDatabaseProvider);
  final row = await db.workoutDao.getSession(id);
  if (row == null || row.deletedAtUtc != null || row.dataKoniec != null) {
    throw WorkoutSessionUnavailable(id);
  }
  final sets = await _ref.read(workoutRepositoryProvider).getSetsForSession(id);
  sets.sort((a, b) {
    final time = a.timestamp.compareTo(b.timestamp);
    return time != 0 ? time : a.id.compareTo(b.id);
  });
  final exercises = <Exercise>[
    if (state.isActive && state.sessionId == id) ...state.selectedExercises,
  ];
  final seen = exercises.map((e) => e.id).toSet();
  final catalog = ExercisesRepository(db);
  for (final set in sets) {
    if (seen.add(set.cwiczenieId)) {
      final exercise = await catalog.getById(set.cwiczenieId);
      if (exercise != null) exercises.add(exercise);
    }
  }
  return _LoadedWorkout(row, List.unmodifiable(exercises), [
    for (final set in sets)
      ActiveSetEntry(
        exerciseId: set.cwiczenieId, exerciseNamePl: set.nazwaCwiczeniaPl,
        setNumber: set.numerSerii, weightKg: set.ciezarKg,
        reps: set.powtorzenia, seconds: set.czasSekund, rpe: set.rpe,
      ),
  ]);
}

void _attachLoaded(_LoadedWorkout loaded, int generation) {
  final id = loaded.session.id;
  state = ActiveWorkoutState(
    sessionId: id, startTime: loaded.session.dataStart.toLocal(),
    isActive: true, selectedExercises: loaded.exercises, loggedSets: loaded.sets,
  );
  unawaited(_sessionSubscription?.cancel());
  _sessionSubscription = _ref.read(workoutRepositoryProvider).watchSession(id)
      .listen((row) {
    if (row == null || row.deletedAtUtc != null || row.dataKoniec != null) {
      _resetIfCurrent(id, generation);
    }
  });
}
```

Nie tworzyć modelu Freezed dla lokalnego wyniku. `reportEmpty` informuje o brakujących ID, gdy nie ma żadnego dostępnego ćwiczenia; nie jest pytaniem o zgodę i nigdy nie umożliwia utworzenia pustej sesji.

- [ ] **3.6. Włącz Mentora do tej samej rezerwacji, zachowując istniejącą idempotencję.** Zastąp tylko publiczną metodę `startMentorSession`, prywatnej `_startMentorSession` i `logMentorSet` nie przepisywać:

```dart
Future<IdempotentSessionWrite?> startMentorSession({
  required String syncId,
  required String accountId,
  bool Function()? guard,
  Exercise? exercise,
}) {
  final key = '$accountId:$syncId';
  final pending = _pendingMentorStart;
  if (pending != null) {
    return key == _pendingMentorStartKey ? pending : Future.value(null);
  }
  if (_startInFlight || (guard != null && !guard())) return Future.value(null);
  _startInFlight = true;
  _pendingMentorStartKey = key;
  final future = _startMentorSession(
    syncId: syncId, accountId: accountId, guard: guard, exercise: exercise,
  ).whenComplete(() {
    _pendingMentorStart = null;
    _pendingMentorStartKey = null;
    _startInFlight = false;
  });
  _pendingMentorStart = future;
  return future;
}
```

Nie zerować `_startInFlight` w `discardSession()`: stary `finally` nie może odblokować nowego startu. Zmiana generacji unieważnia operację, a rezerwację zwalnia jej własne zakończenie. Zachować dotychczasowe `discardSession`, `dispose`, `_resetIfCurrent` i wszystkie guardy zapisu serii.

- [ ] **3.7. GREEN:** `flutter test test/features/workout/plan_workout_test.dart test/features/workout/deleted_session_test.dart test/features/mentor/mentor_actions_test.dart`.

## Zadanie 4: deterministyczne wyścigi, rollback i regresje

**Pliki:** dopisz do `test/features/workout/plan_workout_test.dart`. Każdy test dodawaj osobno i uruchamiaj przez `--plain-name`, najpierw RED względem wersji bez odpowiedniej ochrony z zadania 3 (jeśli ochrona już istnieje, potwierdź GREEN bez sztucznego psucia produkcyjnego kodu).

- [ ] **4.1. Dodaj wspólną barierę repozytorium poza `main`:**

```dart
class PausedLocalStart extends WorkoutRepository {
  PausedLocalStart(super.db, {this.afterWrite = false, this.fail = false});
  final bool afterWrite;
  final bool fail;
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<int> startSession({WorkoutDataContext? context, bool Function()? guard}) async {
    if (!afterWrite) {
      entered.complete();
      await release.future;
    }
    final id = await super.startSession(context: context, guard: guard);
    if (afterWrite) {
      entered.complete();
      await release.future;
    }
    if (fail) throw StateError('Testowy błąd zapisu');
    return id;
  }
}

class PausedMentorStart extends WorkoutRepository {
  PausedMentorStart(super.db);
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<IdempotentSessionWrite> startSessionIdempotent({
    required String syncId, required String accountId, bool Function()? guard,
  }) async {
    entered.complete();
    await release.future;
    return super.startSessionIdempotent(
      syncId: syncId, accountId: accountId, guard: guard,
    );
  }
}
```

- [ ] **4.2. Testuj blokadę we wszystkich kierunkach.** W `main`:

```dart
test('dialog blokuje drugi plan, zwykły start i Mentora', () async {
  await insertExercise(f.db, 'a');
  final id = await f.plan(['a', 'missing']);
  final entered = Completer<void>();
  final decision = Completer<bool>();
  final first = f.notifier.startFromPlan(id,
    confirmMissing: (_) { entered.complete(); return decision.future; },
    confirmResume: () async => false,
  );
  await entered.future;
  expect(await f.notifier.startFromPlan(id,
    confirmMissing: (_) async => true, confirmResume: () async => false,
  ), PlanWorkoutStartResult.busy);
  await expectLater(f.notifier.startSession(), throwsA(isA<WorkoutStartBusy>()));
  expect(await f.notifier.startMentorSession(syncId: 'mentor', accountId: 'a'), isNull);
  decision.complete(true);
  expect(await first, PlanWorkoutStartResult.started);
  expect(await f.db.select(f.db.workoutSessions).get(), hasLength(1));
});

for (final mentor in [false, true]) {
  test('plan nie przerywa oczekującego startu mentor=$mentor', () async {
    final dbFixture = WorkoutFixture(repository: (db) =>
        mentor ? PausedMentorStart(db) : PausedLocalStart(db));
    addTearDown(dbFixture.close);
    await dbFixture.db.into(dbFixture.db.syncState).insert(
      SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
    dbFixture.auth.change(const AuthState.signedIn('a'));
    await insertExercise(dbFixture.db, 'a');
    final id = await dbFixture.plan(['a']);
    final Future<Object?> pending = mentor
        ? dbFixture.notifier.startMentorSession(syncId: 'mentor', accountId: 'a')
        : dbFixture.notifier.startSession().then<Object?>((_) => null);
    final entered = mentor
        ? (dbFixture.repo as PausedMentorStart).entered
        : (dbFixture.repo as PausedLocalStart).entered;
    final release = mentor
        ? (dbFixture.repo as PausedMentorStart).release
        : (dbFixture.repo as PausedLocalStart).release;
    await entered.future;
    expect(await dbFixture.notifier.startFromPlan(id,
      confirmMissing: (_) async => true, confirmResume: () async => true,
    ), PlanWorkoutStartResult.busy);
    release.complete();
    await pending;
    expect(dbFixture.state.isActive, isTrue);
    expect(await dbFixture.db.select(dbFixture.db.workoutSessions).get(), hasLength(1));
  });
}
```

- [ ] **4.3. Testuj zmiany podczas dialogu oraz aktywną sesję utworzoną przez inną instancję:**

```dart
for (final change in ['delete', 'edit', 'catalog', 'account', 'discard', 'other-session']) {
  test('zmiana podczas potwierdzenia: $change', () async {
    await insertExercise(f.db, 'a');
    final id = await f.plan(['a', 'missing']);
    final result = await f.notifier.startFromPlan(id,
      confirmMissing: (_) async {
        switch (change) {
          case 'delete':
            await PlannerRepository(f.db).deletePlan(id);
          case 'edit':
            await (f.db.update(f.db.workoutPlans)..where((p) => p.id.equals(id)))
                .write(const WorkoutPlansCompanion(cwiczeniaIds: Value('["a"]')));
          case 'catalog':
            await insertExercise(f.db, 'missing');
          case 'account':
            await f.db.into(f.db.syncState).insert(
              SyncStateCompanion.insert(accountId: 'b', deviceId: 'd'));
          case 'discard':
            f.notifier.discardSession();
          case 'other-session':
            await WorkoutRepository(f.db).startSession();
        }
        return true;
      },
      confirmResume: () async => true,
    );
    final expected = switch (change) {
      'edit' || 'catalog' => PlanWorkoutStartResult.changed,
      'other-session' => PlanWorkoutStartResult.resumed,
      _ => PlanWorkoutStartResult.unavailable,
    };
    expect(result, expected);
    expect(await f.db.select(f.db.workoutSessions).get(),
        hasLength(change == 'other-session' ? 1 : 0));
    expect(await f.db.workoutDao.getAllSets(), isEmpty);
  });
}

test('sesja usunięta w dialogu wznowienia nie jest odtwarzana', () async {
  final old = await f.repo.startSession();
  final id = await f.plan(['a']);
  expect(await f.notifier.startFromPlan(id,
    confirmMissing: (_) async => true,
    confirmResume: () async {
      await (f.db.update(f.db.workoutSessions)..where((s) => s.id.equals(old)))
          .write(WorkoutSessionsCompanion(deletedAtUtc: Value(DateTime.now().toUtc())));
      return true;
    },
  ), PlanWorkoutStartResult.unavailable);
  expect(f.state.isActive, isFalse);
  expect(await f.db.select(f.db.workoutSessions).get(), hasLength(1));
});
```

- [ ] **4.4. Testuj generation guard przed i po zapisie oraz błąd I/O.** W `main`:

```dart
for (final afterWrite in [false, true]) {
  for (final action in ['loading', 'account-b', 'dispose', 'failure']) {
    test('rollback $action afterWrite=$afterWrite', () async {
      final isolated = WorkoutFixture(repository: (db) => PausedLocalStart(
        db, afterWrite: afterWrite, fail: action == 'failure',
      ));
      var disposed = false;
      addTearDown(() async {
        if (!disposed) isolated.container.dispose();
        await isolated.db.close();
      });
      isolated.auth.change(const AuthState.signedIn('a'));
      await isolated.db.into(isolated.db.syncState).insert(
        SyncStateCompanion.insert(accountId: 'a', deviceId: 'd'));
      await insertExercise(isolated.db, 'a');
      final id = await isolated.plan(['a']);
      final baseline = (await isolated.db.syncDao.pendingOperations())
          .map((o) => o.toJson()).toList();
      final pending = isolated.notifier.startFromPlan(id,
        confirmMissing: (_) async => true, confirmResume: () async => true,
      );
      // Obsługę oczekiwanego wyjątku podłącz przed zwolnieniem bariery.
      final checked = action == 'failure'
          ? expectLater(pending, throwsStateError)
          : expectLater(pending, completion(PlanWorkoutStartResult.unavailable));
      final repo = isolated.repo as PausedLocalStart;
      await repo.entered.future;
      switch (action) {
        case 'loading': isolated.auth.change(const AuthState.loading());
        case 'account-b': isolated.auth.change(const AuthState.signedIn('b'));
        case 'dispose': isolated.container.dispose(); disposed = true;
        case 'failure': break;
      }
      repo.release.complete();
      await checked;
      expect(await isolated.db.select(isolated.db.workoutSessions).get(), isEmpty);
      expect((await isolated.db.syncDao.pendingOperations()).map((o) => o.toJson()).toList(), baseline);
      if (!disposed) expect(isolated.state.isActive, isFalse);
    });
  }
}
```

- [ ] **4.5. Uruchom cały zestaw:**

```bash
flutter test test/features/workout/plan_workout_test.dart
flutter test test/features/workout/deleted_session_test.dart test/features/mentor/mentor_actions_test.dart test/features/mentor/mentor_operations_test.dart
```

Oczekiwane: brak podwójnej sesji, brak nowych serii, odrzucenie późnych wyników, brak zmiany kolejki po rollbacku. Testy Mentora muszą nadal sprawdzać `identical(first, same)`, tombstones, odrzucenie loading po zapisie i nieprzywracanie zakończonych sesji. Nie „naprawiać” tych testów przez osłabienie asercji.

## Zadanie 5: komunikaty i start z zapisanych planów

**Pliki:** utwórz `lib/features/workout/presentation/widgets/workout_start_ui.dart`, zmień `planner_page.dart`, utwórz `test/features/workout/plan_workout_ui_test.dart`.

- [ ] **5.1. Dodaj testy widgetu startowego.** Początek pliku testowego; testuje rzeczywisty kontroler, nie atrapę zwracającą sukces:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
// Testowa implementacja transytywnego interfejsu istniejącego pluginu.
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';
import 'package:fitbirek_training/core/models/user_profile.dart';
import 'package:fitbirek_training/features/onboarding/providers/user_profile_provider.dart';
import 'package:fitbirek_training/features/planner/presentation/pages/planner_page.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/presentation/widgets/workout_start_ui.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/active_session_page.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'plan_workout_fixture.dart';

class TestWakelock extends WakelockPlusPlatformInterface {
  bool value = false;
  @override
  Future<bool> get enabled async => value;
  @override
  Future<void> toggle({required bool enable}) async { value = enable; }
}

class FailOnceStart extends WorkoutRepository {
  FailOnceStart(super.db);
  bool fail = true;
  @override
  Future<int> startSession({WorkoutDataContext? context, bool Function()? guard}) async {
    final id = await super.startSession(context: context, guard: guard);
    if (fail) {
      fail = false;
      throw StateError('Testowy błąd po zapisie');
    }
    return id;
  }
}

void main() {
  late WorkoutFixture f;
  setUp(() => f = WorkoutFixture());
  tearDown(() => f.close());

  Future<void> pumpStart(WidgetTester tester, int id) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: PlanWorkoutStartButton(planId: id))),
      GoRoute(path: '/workout/session', builder: (_, _) => const Scaffold(body: Text('SESJA'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: f.container, child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  for (final accept in [false, true]) {
    testWidgets('dialog braków zgoda=$accept', (tester) async {
      await insertExercise(f.db, 'a');
      await pumpStart(tester, await f.plan(['a', 'missing']));
      await tester.tap(find.text('Rozpocznij trening'));
      await tester.pumpAndSettle();
      expect(find.textContaining('missing'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton).first);
      expect(button.onPressed, isNull);
      await tester.tap(find.text(accept ? 'Rozpocznij z pozostałymi' : 'Anuluj'));
      await tester.pumpAndSettle();
      expect(find.text('SESJA'), accept ? findsOneWidget : findsNothing);
      expect(await f.db.select(f.db.workoutSessions).get(), hasLength(accept ? 1 : 0));
    });
  }

  testWidgets('pusty plan pokazuje komunikat i nie nawiguje', (tester) async {
    await pumpStart(tester, await f.plan([]));
    await tester.tap(find.text('Rozpocznij trening'));
    await tester.pumpAndSettle();
    expect(find.text('Plan nie zawiera dostępnych ćwiczeń.'), findsOneWidget);
    expect(find.text('SESJA'), findsNothing);
  });

  testWidgets('same brakujące ID: lista i brak możliwości zatwierdzenia startu', (tester) async {
    await pumpStart(tester, await f.plan(['missing']));
    await tester.tap(find.text('Rozpocznij trening'));
    await tester.pumpAndSettle();
    expect(find.textContaining('missing'), findsOneWidget);
    expect(find.text('Rozpocznij z pozostałymi'), findsNothing);
    await tester.tap(find.text('Zamknij'));
    await tester.pumpAndSettle();
    expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
    expect(find.text('SESJA'), findsNothing);
  });

  testWidgets('błąd zapisu odblokowuje przycisk i pozwala ponowić', (tester) async {
    await f.close();
    f = WorkoutFixture(repository: (db) => FailOnceStart(db));
    await insertExercise(f.db, 'a');
    await pumpStart(tester, await f.plan(['a']));
    await tester.tap(find.text('Rozpocznij trening'));
    await tester.pumpAndSettle();
    expect(find.text('Nie udało się rozpocząć treningu. Spróbuj ponownie.'), findsOneWidget);
    expect(find.text('SESJA'), findsNothing);
    expect(await f.db.select(f.db.workoutSessions).get(), isEmpty);
    expect(tester.widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton)).onPressed, isNotNull);
    await tester.tap(find.text('Rozpocznij trening'));
    await tester.pumpAndSettle();
    expect(find.text('SESJA'), findsOneWidget);
    expect(await f.db.select(f.db.workoutSessions).get(), hasLength(1));
  });

  testWidgets('istniejąca sesja proponuje powrót zamiast nowej', (tester) async {
    final old = await f.repo.startSession();
    await pumpStart(tester, await f.plan([]));
    await tester.tap(find.text('Rozpocznij trening'));
    await tester.pumpAndSettle();
    expect(find.text('Trening już trwa'), findsOneWidget);
    await tester.tap(find.text('Wróć do treningu'));
    await tester.pumpAndSettle();
    expect(find.text('SESJA'), findsOneWidget);
    expect(f.state.sessionId, old);
  });
}
```

- [ ] **5.2. RED:** `flutter test test/features/workout/plan_workout_ui_test.dart`; brak `PlanWorkoutStartButton`.
- [ ] **5.3. Dodaj pełny plik UI:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/exercise.dart';
import '../../data/workout_repository.dart';
import '../../providers/workout_providers.dart';

void _message(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _confirm(BuildContext context, {
  required String title, required String message, required String accept,
}) async {
  if (!context.mounted) return false;
  return await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title), content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Anuluj')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(accept)),
      ],
    ),
  ) ?? false;
}

class PlanWorkoutStartButton extends ConsumerStatefulWidget {
  const PlanWorkoutStartButton({super.key, required this.planId});
  final int planId;
  @override
  ConsumerState<PlanWorkoutStartButton> createState() => _PlanWorkoutStartButtonState();
}

class _PlanWorkoutStartButtonState extends ConsumerState<PlanWorkoutStartButton> {
  bool _busy = false;
  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(activeWorkoutProvider.notifier).startFromPlan(
        widget.planId,
        confirmMissing: (ids) => _confirm(context,
          title: 'Brakujące ćwiczenia',
          message: 'Nie znaleziono ID: ${ids.join(', ')}. Rozpocząć z pozostałymi ćwiczeniami?',
          accept: 'Rozpocznij z pozostałymi',
        ),
        confirmResume: () => _confirm(context,
          title: 'Trening już trwa',
          message: 'Plan nie zastąpi aktywnego treningu. Wrócić do niego?',
          accept: 'Wróć do treningu',
        ),
        reportEmpty: (ids) async {
          if (!mounted) return;
          await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
            title: const Text('Brak dostępnych ćwiczeń'),
            content: Text('Nie znaleziono ID: ${ids.join(', ')}. Nie można rozpocząć tego planu.'),
            actions: [TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Zamknij'),
            )],
          ));
        },
      );
      if (!mounted) return;
      switch (result) {
        case PlanWorkoutStartResult.started:
        case PlanWorkoutStartResult.resumed:
          if (ref.read(activeWorkoutProvider).isActive) context.go('/workout/session');
        case PlanWorkoutStartResult.cancelled:
          break;
        case PlanWorkoutStartResult.busy:
          _message(context, 'Trwa już uruchamianie treningu.');
        case PlanWorkoutStartResult.unavailable:
          _message(context, 'Plan, sesja lub konto nie są już dostępne. Spróbuj ponownie.');
        case PlanWorkoutStartResult.changed:
          _message(context, 'Plan lub katalog zmienił się. Rozpocznij ponownie, aby zatwierdzić aktualne dane.');
        case PlanWorkoutStartResult.empty:
          _message(context, 'Plan nie zawiera dostępnych ćwiczeń.');
      }
    } catch (_) {
      if (mounted) _message(context, 'Nie udało się rozpocząć treningu. Spróbuj ponownie.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: _busy ? null : _start,
    icon: Icon(_busy ? Icons.hourglass_top : Icons.play_arrow),
    label: Text(_busy ? 'Uruchamianie…' : 'Rozpocznij trening'),
  );
}

// Zwykłe wejścia do sesji: odmowa startu nie może skutkować nawigacją ani
// dodaniem ćwiczenia do innej sesji. Rezerwację nadal egzekwuje kontroler.
Future<void> openWorkoutSession(BuildContext context, WidgetRef ref,
    {Exercise? exercise}) async {
  try {
    await ref.read(activeWorkoutProvider.notifier).startSession();
    if (!context.mounted || !ref.read(activeWorkoutProvider).isActive) return;
    if (exercise != null) ref.read(activeWorkoutProvider.notifier).addExercise(exercise);
    context.go('/workout/session');
  } on WorkoutStartBusy {
    _message(context, 'Trwa już uruchamianie treningu.');
  } on WorkoutAccountUnavailable {
    _message(context, 'Kontekst danych zmienił się. Spróbuj ponownie.');
  } catch (_) {
    _message(context, 'Nie udało się rozpocząć treningu. Spróbuj ponownie.');
  }
}
```

- [ ] **5.4. Podepnij przycisk w `planner_page.dart`.** Dodaj import:

```dart
import '../../../workout/presentation/widgets/workout_start_ui.dart';
```

W `_buildHistory` zastąp `Card(child: ListTile(...))` w `plans.map` poniższym kodem; przycisk dotyczy **zapisanych**, nie tylko wygenerowanych planów:

```dart
(p) => Card(
  key: ValueKey('saved-plan-${p.id}'),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(
        leading: const Icon(Icons.bookmark_outline),
        title: Text(p.nazwa),
        subtitle: Text('${p.cwiczeniaIds.length} ćwiczeń'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => ref.read(plannerRepositoryProvider).deletePlan(p.id),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: PlanWorkoutStartButton(planId: p.id),
      ),
    ],
  ),
),
```

Przycisk konkretnego planu blokuje się od kliknięcia do końca dialogów i zapisu. Kliknięcie innego planu podczas operacji otrzymuje wynik `busy` ze wspólnego kontrolera; nie otwiera drugiego dialogu. Usunięcie planu w trakcie dialogu jest bezpieczne dzięki ponownej walidacji; nie trzeba zablokować funkcji usuwania.

Dopisz do `main` pliku `test/features/workout/plan_workout_ui_test.dart` test rzeczywistego osadzenia przycisku w planerze, a nie tylko samodzielnego widgetu:

```dart
testWidgets('zapisany plan w PlannerPage uruchamia sesję', (tester) async {
  await UserProfileRepository(f.db).saveProfile(
    imie: 'Test', wiek: 30, wzrostCm: 180, wagaKg: 80,
    cel: CelTreningowy.sila, dostepnySprzet: [],
  );
  await insertExercise(f.db, 'a');
  final id = await f.plan(['a']);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => const PlannerPage()),
    GoRoute(path: '/workout/session', builder: (_, _) => const Scaffold(body: Text('SESJA'))),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: f.container, child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  final card = find.byKey(ValueKey('saved-plan-$id'));
  final button = find.descendant(of: card, matching: find.text('Rozpocznij trening'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.text('SESJA'), findsOneWidget);
  expect(f.state.selectedExercises.single.id, 'a');
});
```

- [ ] **5.5. Zastąp trzy istniejące callbacki zwykłego startu.** W `workout_home_page.dart` dodaj import `../widgets/workout_start_ui.dart`; callback przycisku staje się:

```dart
onPressed: () => openWorkoutSession(context, ref),
```

W `classic_today_page.dart` dodaj `../../../workout/presentation/widgets/workout_start_ui.dart` i zastąp callback przycisku takim samym kodem. Jeśli po zmianie nie ma innego użycia `GoRouter` i `workout_providers.dart` w tym pliku, usuń oba nieużywane importy.

W `exercise_detail_page.dart` dodaj `../../../workout/presentation/widgets/workout_start_ui.dart` i zastąp callback przycisku:

```dart
onPressed: () => openWorkoutSession(context, ref, exercise: ex),
```

Usuń nieużywane importy GoRouter/workout providers tylko jeśli nie są potrzebne zmianom etapu 2. Nie zmieniaj nazw tras i nie dodawaj wyjątków do autoryzacji routera: lokalna operacja ma działać bez konta niezależnie od obecnej polityki wejścia aplikacji.

- [ ] **5.6. GREEN:** `flutter test test/features/workout/plan_workout_ui_test.dart` oraz `flutter analyze`. Sprawdź ręcznie w planerze: przycisk na każdym zapisanym planie, brak dialogu dla poprawnego planu, lista brakujących ID, anulowanie bez sesji, powrót do istniejącej sesji.

## Zadanie 6: brak serii / zapisane serie i pominięcie ćwiczenia

**Pliki:** `lib/features/workout/presentation/pages/active_session_page.dart`, `test/features/workout/plan_workout_ui_test.dart`.

- [ ] **6.1. Dopisz test widgetowy w istniejącym `main`:**

```dart
testWidgets('stan serii nie oznacza ukończenia; pominięcie nie edytuje planu', (tester) async {
  final previousWakelock = WakelockPlusPlatformInterface.instance;
  WakelockPlusPlatformInterface.instance = TestWakelock();
  addTearDown(() => WakelockPlusPlatformInterface.instance = previousWakelock);
  await insertExercise(f.db, 'a');
  await insertExercise(f.db, 'b');
  final id = await f.plan(['a', 'b']);
  final before = (await f.db.plansDao.getPlan(id))!.toJson();
  await f.notifier.startFromPlan(id,
    confirmMissing: (_) async => true, confirmResume: () async => true);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: f.container, child: const MaterialApp(home: ActiveSessionPage()),
  ));
  await tester.pumpAndSettle();
  expect(find.text('Brak zapisanych serii'), findsNWidgets(2));
  await f.notifier.logSet(exercise: f.state.selectedExercises.first, reps: 8);
  await tester.pumpAndSettle();
  expect(find.text('Zapisano serie: 1'), findsOneWidget);
  expect(find.textContaining('Ukończono'), findsNothing);
  await tester.tap(find.byTooltip('Pomiń ćwiczenie').first);
  await tester.pumpAndSettle();
  expect(f.state.selectedExercises.map((e) => e.id), ['b']);
  expect(await f.db.workoutDao.getAllSets(), hasLength(1));
  expect((await f.db.plansDao.getPlan(id))!.toJson(), before);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
});
```

Test zastępuje oficjalny interfejs platformowy (`toggle`, `enabled`, `instance`), a nie zgaduje nazwy wygenerowanego kanału Pigeon. Nie dodawać nowej wersji pluginu i nie ignorować wyjątków platformowych globalnie.

- [ ] **6.2. RED:** `flutter test test/features/workout/plan_workout_ui_test.dart --plain-name 'stan serii'`; brak tekstu stanu i przycisku pominięcia.
- [ ] **6.3. Dodaj stabilne klucze kart.** W `itemBuilder`:

```dart
return _ExerciseLogCard(key: ValueKey(ex.id), exercise: ex);
```

Konstruktor prywatnej karty:

```dart
const _ExerciseLogCard({super.key, required this.exercise});
```

- [ ] **6.4. Zastąp tekst tytułu karty poniższymi widgetami:**

```dart
Row(
  children: [
    Expanded(child: Text(
      widget.exercise.nazwaPl,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    )),
    IconButton(
      tooltip: 'Pomiń ćwiczenie',
      icon: const Icon(Icons.remove_circle_outline),
      onPressed: () => ref.read(activeWorkoutProvider.notifier)
          .removeExercise(widget.exercise.id),
    ),
  ],
),
Text(loggedForThis.isEmpty
    ? 'Brak zapisanych serii'
    : 'Zapisano serie: ${loggedForThis.length}'),
```

Nie dodawać statusu „ukończone” po jednej serii. Usunięcie karty z wyboru nie kasuje zapisanych wykonań. Dodawanie ćwiczeń nadal odbywa się przez istniejący przycisk „Dodaj ćwiczenie z bazy”; jego ścieżka startowa z zadania 5 nie nadpisuje aktywnej sesji.

- [ ] **6.5. GREEN:** `flutter test test/features/workout/plan_workout_ui_test.dart`. Zweryfikować też ręcznie, że pominięcie pierwszej karty nie przenosi wpisanego ciężaru/powtórzeń na drugą kartę (stabilny `ValueKey`).

## Zadanie 7: końcowa weryfikacja i przekazanie

- [ ] **7.1. Uruchom formatowanie tylko plików objętych etapem 1**, aby nie porządkować równoległych prac:

```bash
dart format lib/features/workout/data/plan_workout_loader.dart lib/features/workout/data/workout_repository.dart lib/features/workout/providers/workout_providers.dart lib/features/workout/presentation/widgets/workout_start_ui.dart lib/features/workout/presentation/pages/active_session_page.dart lib/features/workout/presentation/pages/workout_home_page.dart lib/features/planner/presentation/pages/planner_page.dart lib/features/home/presentation/pages/classic_today_page.dart lib/features/exercises/presentation/pages/exercise_detail_page.dart test/features/workout/plan_workout_fixture.dart test/features/workout/plan_workout_test.dart test/features/workout/plan_workout_ui_test.dart
flutter analyze
flutter test test/features/workout test/features/mentor
flutter test
dart tools/generate_app_version.dart --check
git diff --check
```

Oczekiwane: brak nowych błędów analizy, testy etapu 1, Mentora i usuwania sesji PASS, spójna wersja wygenerowana. Raportować zastane błędy niezwiązane z etapem, nie usuwać testów ani nie cofać cudzych zmian.

- [ ] **7.2. Kontrola generatorów i artefaktów Web SQLite.** W etapie 1 nie zmieniają się deklaracje ani `pubspec.lock`, więc nie regenerować dla samej dokumentacji lub zwykłych klas Dart. Jeśli podczas integracji jednak zmienią się deklaracje Drift/Freezed/JSON, obowiązkowo wykonać:

```bash
dart run build_runner build --delete-conflicting-outputs
git diff -- pubspec.lock web/sqlite3.wasm web/drift_worker.dart.js
```

Punkt odniesienia odczytany z lockfile: `drift 2.28.2`, `sqlite3 2.9.4`. Nie zakładać zgodności nowych binariów na podstawie nazwy pliku; przy aktualizacji pakietów pobrać odpowiadające artefakty zgodnie z `CONTRIBUTING.md`, sprawdzić ich pochodzenie i zweryfikować build Web. Ten etap nie zleca aktualizacji pakietów ani toolchainu.

- [ ] **7.3. Przejdź macierz akceptacji ręcznej:**
  - poprawny zapisany plan → dokładna kolejność pierwszych wystąpień ID → aktywna sesja bez serii;
  - część ID brakująca → lista braków → anuluj / potwierdź → odpowiednio zero / jedna nowa sesja;
  - pusty plan i wszystkie ID brakujące → komunikat, zero nowych sesji;
  - sesja w pamięci i osobno sesja tylko w DB → propozycja powrotu, nie zastąpienie ćwiczeniami planu;
  - wielokrotne kliknięcie oraz plan ↔ zwykły start ↔ Mentor → co najwyżej jeden zapis i jeden właściciel publikacji;
  - błąd zapisu, zmiana konta, wylogowanie, usunięcie planu w dialogu → brak częściowego stanu i nowej kolejki;
  - dodanie/pominięcie ćwiczenia → plan źródłowy bez zmian;
  - pierwsza seria → „Zapisano serie: 1”, nigdy „ukończone”.

- [ ] **7.4. Przekaż wynik bez commita i bez wdrożenia.** W raporcie podać zmienione pliki, rzeczywiście wykonane komendy, wyniki testów i ewentualne zastane blokery. Wydanie z podbiciem minor/build oraz `generate_app_version.dart` koordynować osobno z etapami 2 i 3; nie tworzyć trzech konkurencyjnych podbić wersji.

## Zależności i kolejność względem pozostałych planów

1. Ten etap nie wymaga wdrożenia kontraktu progresji ani endpointów historii. Działa offline i nie potrzebuje Mentora.
2. Zadania 1–4 muszą poprzedzić podpięcie UI. Zadania 5–6 współdzielą pliki UI z etapem 2, więc wymagają sekwencyjnej integracji hunków. Etap 3 nie powinien zmieniać podpisów `startFromPlan` ani `startMentorSession` bez uzgodnienia.
3. Odcisk planu obejmuje aktualnie listę ID i metadane planu, nie reguły progresji. Jeśli etap 3 zmieni semantykę przygotowania treningu, musi jawnie rozszerzyć odcisk o zaakceptowane cele; nie dopisywać tego poza zakresem etapu 1.
4. Warstwa historii używa rzeczywistych serii. Etap 1 nie tworzy dla niej sztucznych danych, nie zapisuje celów ani wyników ćwiczeń przy samym starcie.

## Samoprzegląd dokumentu

- Pokrycie specyfikacji: kolejność/dedup/pusty/braki — zadanie 1 i 3; potwierdzenie/anulowanie — 3 i 5; sesja DB — 2 i 3; rollback/konto/współbieżność/Mentor — 2–4; niezmienność planu/brak fikcyjnych serii — 1, 3 i 6; komunikaty/nawigacja/stan serii — 5–6; regresje i wersje — 7.
- Wszystkie nowe metody użyte w kodzie są zdefiniowane w tym dokumencie; istniejące DAO i repozytoria wskazano po odczycie źródeł. Nie zakładać nieistniejącego `getPlanById`, `createSessionFromPlan` ani auth-only API dla lokalnego użytkownika.
- Brak migracji, nowych pól synchronizacji, zmian backendu, implementacji etapów 2/3, commitów i operacji produkcyjnych.
