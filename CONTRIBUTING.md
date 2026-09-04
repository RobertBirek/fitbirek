# Współtworzenie FitBirek

Ten dokument opisuje, jak bezpiecznie i zgodnie z architekturą projektu dodawać nowe funkcje, ćwiczenia i feature'y.

---

## 🔒 Zasady twarde (nie zmieniać bez wyraźnej decyzji)

- **Wersje środowiska są zablokowane**: Flutter 3.35.4, Dart 3.9.2. Nie uruchamiać `flutter upgrade` / `dart pub global activate`.
- **Wersje pakietów Drift/sqlite3 są zablokowane** (`drift: 2.28.2`, `sqlite3: 2.9.4`) — muszą pozostać zgodne z plikami `web/sqlite3.wasm` i `web/drift_worker.dart.js`. Zmiana wersji w `pubspec.yaml` **wymaga** ponownego pobrania odpowiadających binarek z GitHub Releases tych pakietów.
- **Paleta kolorów**: tło `#1A1D23`, akcent `#FF6B35` (zdefiniowane w `lib/app/theme.dart` jako `FitBirekColors`). Nowe ekrany muszą korzystać z `Theme.of(context)` / `FitBirekColors`, nie hardkodować kolorów.

---

## ➕ Jak dodać nowe ćwiczenie do bazy

Baza ćwiczeń (316 pozycji, `cw001`-`cw316`) jest w `assets/data/exercises.json`, synchronizowana przy każdym starcie aplikacji do tabeli Drift `Exercises` (patrz `ExercisesRepository.syncFromAssets()`).

1. Otwórz `assets/data/exercises.json`
2. Dodaj nowy obiekt zgodny ze strukturą istniejących wpisów — sprawdź `lib/core/models/exercise.dart` (Freezed) dla pełnej listy pól i ich typów. Nadaj mu kolejny wolny `id` (`cw317`, `cw318`, ...) — **nigdy nie zmieniaj istniejących ID**, bo to psuje referencje w zapisanych planach/sesjach użytkownika.
3. Pamiętaj o polach kluczowych dla logiki:
   - `typ` — jeśli ćwiczenie jest izometryczne (plank, wall-sit, dead-hang), musi mieć `typ: 'Izometryczne'` — inaczej UI sesji treningowej nie pokaże stopera, a pola waga/powtórzenia
   - `partiaGlowna` — używane przez `PlanGenerator` do doboru ćwiczeń w generatorze planu
   - `sprzet` — lista sprzętu (nazwa pola w modelu/JSON to `sprzet`, NIE `sprzetWymagany`); generator planu filtruje po dostępnym sprzęcie użytkownika (`dostepnySprzet` w `UserProfile`), wymagając że KAŻDY element tej listy musi być dostępny
   - `poziom` — 'Początkujący' / 'Średni' / 'Zaawansowany'
4. Odśwież aplikację — `syncFromAssets()` wstawia tylko ćwiczenia z ID, które jeszcze nie istnieją w bazie lokalnej (import przyrostowy), więc nowe pozycje trafią też na urządzenia z już zainstalowaną aplikacją, bez duplikowania istniejących wierszy i bez resetowania `ulubione`.

**Nie edytuj ręcznie tabeli SQLite** — zawsze przez plik JSON + mechanizm synchronizacji, żeby zmiany były wersjonowane w git.

**Generator masowy**: `scripts/generate_exercises.py` — skrypt użyty do rozszerzenia bazy z 38 do 316 pozycji (funkcja `add_family()` grupująca warianty ćwiczeń o wspólnym wzorcu ruchu). Można go użyć jako wzorca do kolejnych rozszerzeń, uruchamiając `python3 scripts/generate_exercises.py` po dopisaniu nowych `add_family(...)`.

---

## 🆕 Jak dodać nowy feature

Struktura `features/<nazwa>/` (patrz `ARCHITECTURE.md` sekcja 1):

```
features/nowy_feature/
├── data/            # repozytorium — mapowanie XxxData (Drift) ↔ Xxx (model domenowy)
├── domain/           # (opcjonalnie) czysta logika biznesowa, bez zależności od Flutter/Drift
├── providers/        # Riverpod providery
└── presentation/
    └── pages/
```

Kroki:
1. Jeśli feature potrzebuje nowej tabeli w bazie: dodaj tabelę w `lib/core/database/tables/`, **pamiętaj o `@DataClassName('XxxData')`** żeby uniknąć kolizji nazw z modelem Freezed (patrz `ARCHITECTURE.md` sekcja 3.1)
2. Dodaj tabelę do `@DriftDatabase(tables: [...])` w `app_database.dart`
3. Stwórz DAO w `lib/core/database/daos/` (wzorzec: `plans_dao.dart`)
4. Zdefiniuj model domenowy Freezed w `lib/core/models/` (jeśli potrzebny — nie każdy feature musi mieć własny model, np. proste featury mogą operować bezpośrednio na `XxxData`)
5. Uruchom regenerację kodu:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
6. Stwórz repozytorium w `features/nowy_feature/data/`
7. Stwórz providery w `features/nowy_feature/providers/` (wzorzec: `planner_providers.dart` — `Provider<Repository>` + `StreamProvider<List<Model>>`)
8. Stwórz UI w `features/nowy_feature/presentation/pages/`
9. Dodaj route w `lib/app/router.dart`
10. **Zawsze zakończ**: `flutter analyze` (cel: 0 issues) + `dart format .`

---

## 🧪 Standardy testów

Obecnie projekt ma 5 testów ogólnych w `test/widget_test.dart`. Docelowo (zgodnie z briefem) każdy feature powinien mieć 3-5 dedykowanych testów.

**Konwencja nazewnictwa**: `test/features/<nazwa>/<co_testujemy>_test.dart`

Priorytety testowania per feature:
1. **Logika domenowa bez UI** (najłatwiejsze, najwyższy ROI) — np. `PlanGenerator.generate()`, `BmrCalculator.calculateFull()`, `PrDetector.isNewRecord()`
2. **Repozytoria** — z użyciem `AppDatabase.forTesting()` (in-memory) zamiast prawdziwej bazy
3. **Widgety** — `testWidgets()` z `ProviderScope(overrides: [...])` do podstawienia mocków repozytoriów

Przykład testu repozytorium (in-memory DB):
```dart
test('PlannerRepository zapisuje i odczytuje plan', () async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = PlannerRepository(db);
  await repo.savePlan(...);
  final plans = await repo.watchAll().first;
  expect(plans, hasLength(1));
});
```

---

## 🚫 Standardy kodu — czego unikać

Zgodnie z lint rules projektu (`flutter analyze` musi zwracać "No issues found!"):

- **Nie używaj `print()`** — użyj `debugPrint()` lub `if (kDebugMode) { ... }`
- **Nie używaj `Color.withOpacity()`** (deprecated) — użyj `Color.withValues(alpha: ...)`
- **`use_build_context_synchronously`** — jeśli używasz `BuildContext` po `await`, zapisz potrzebny obiekt (np. `ScaffoldMessenger.of(context)`) do zmiennej **przed** `await`
- **`use_super_parameters`** — konstruktory typu `MyClass(super.x)` zamiast `MyClass(x) : super(x)`
- **`dangling_library_doc_comments`** — jeśli plik ma doc-comment (`///`) na górze, ale nie ma klasy/funkcji tuż pod nim (np. plik z samym `export`), dodaj deklarację `library;` albo zmień na zwykły komentarz `//`
- **Booleans w Pythonie (skrypty backend)**: `True`/`False`/`None`, nigdy `true`/`false`/`null` (błąd `NameError`)

---

## 🔄 Workflow przed commitem

```bash
cd /home/user/flutter_app
dart run build_runner build --delete-conflicting-outputs   # jeśli zmieniono Drift/Freezed
flutter analyze                                              # cel: No issues found!
dart format .
flutter test
flutter build apk --debug                                    # weryfikacja realna (nie tylko analyze)
```

Dopiero po zielonym świetle na wszystkich powyższych — commit i push.

---

## 📱 Android — checklist przy zmianach w `android/`

Jeśli zmieniasz `applicationId`/`namespace` lub dodajesz zależności wymagające natywnego kodu:
1. Zsynchronizuj `namespace` i `applicationId` w `android/app/build.gradle.kts`
2. Zsynchronizuj `package` w `AndroidManifest.xml`
3. Przenieś/zaktualizuj `MainActivity.kt` do odpowiadającej ścieżki katalogu (`android/app/src/main/kotlin/<package>/MainActivity.kt`)
4. Jeśli używasz Firebase: `google-services.json` `package_name` musi zgadzać się z powyższym
5. Wyczyść tylko cache Androida (nie `build/web`): `rm -rf android/build android/app/build android/.gradle`

`applicationId`/`namespace` jest już ujednolicony na `com.fitbirek.training` (zweryfikowane realnym buildem APK + `aapt dump badging`) — jeśli w przyszłości zmieniasz pakiet ponownie, pamiętaj o pełnej synchronizacji wg checklisty powyżej.
