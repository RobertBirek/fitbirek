# Changelog

Wszystkie znaczące zmiany w projekcie FitBirek są dokumentowane w tym pliku.

Format oparty na [Keep a Changelog](https://keepachangelog.com/), wersjonowanie projektu jest wewnętrzne (brak publicznego API/semver — aplikacja mobilna).

---

## [Unreleased]

### Planowane
- Notyfikacje lokalne (harmonogram karate wt/czw 19:30, przypomnienia treningowe, codzienny mood-check prompt)
- Wizualizacje fl_chart dla pomiarów ciała i testów sprawnościowych
- Rozszerzenie testów jednostkowych/widgetowych per-feature (docelowo 3-5 na feature)
- Rozszerzenie bazy ćwiczeń z 38 do 316 pozycji docelowych
- Dedykowany plik audio `gong.mp3` (obecnie fallback na `SystemSound.play`)

---

## [0.4.0] — Backup/restore JSON (Premium)

### Added
- `lib/core/services/backup_service.dart` — `BackupService.exportToBytes()` / `importFromBytes()` / `suggestedFileName()`:
  - Format JSON z `schemaVersion` (obecnie `1`), `appVersion`, `exportedAt`, 9 sekcji danych (wszystkie tabele Drift)
  - Eksport wykorzystuje generowane przez Drift `toJson()` na klasach danych — brak ręcznego mapowania kolumn
  - Import w `db.transaction()`: czyszczenie 9 tabel w kolejności odwrotnej do FK, re-insert z zachowaniem oryginalnych ID (`insertOnConflictUpdate`) — zachowuje relacje (np. `SetsLog.sesjaId → WorkoutSessions.id`)
  - Walidacja `schemaVersion` — odrzuca import z nieznanej/przyszłej wersji formatu, bez modyfikacji bazy
  - Błąd w trakcie importu → rollback transakcji, baza pozostaje niezmieniona
- `backupServiceProvider` w `core/providers/database_provider.dart`
- UI w `settings_page.dart` (przepisane na `ConsumerStatefulWidget`):
  - Eksport → `share_plus` (`XFile.fromData`), działa identycznie na Web i Android (bez `dart:io`)
  - Import → `file_picker` (`withData: true`, operuje na `Uint8List` w pamięci), dialog ostrzegawczy przed nieodwracalnym zastąpieniem danych, loading overlay podczas operacji

### Tests
- `test/features/settings/backup_service_test.dart` — 6 testów jednostkowych na `AppDatabase.forTesting(NativeDatabase.memory())`:
  - Eksport pustej bazy generuje poprawną strukturę JSON
  - Round-trip profilu użytkownika
  - Round-trip sesji + serii z zachowaniem relacji FK
  - Odrzucenie nieznanego `schemaVersion`
  - Odrzucenie nieprawidłowego JSON bez crasha
  - Rollback transakcji przy błędzie w trakcie importu (baza niezmieniona)

### Verified
- `flutter analyze` → **No issues found!**
- `dart format .` → bez zmian po formatowaniu (clean)
- `flutter build apk --debug` → **SUCCESS** (181MB, wzrost z 156MB — natywne zależności `file_picker`/`share_plus`)
- `flutter test test/features/settings/backup_service_test.dart` → **6/6 passed**

---

## [0.3.0] — Naprawa kompilacji web + dokumentacja + ikona

### Added
- Struktura Drift multi-platform (`core/database/connection/`): `native_connection.dart`, `web_connection.dart`, `unsupported_connection.dart`, `connection.dart` z conditional exports (`dart.library.ffi` / `dart.library.js_interop`)
- Pliki binarne `web/sqlite3.wasm` (v2.9.4) i `web/drift_worker.dart.js` (v2.28.2), zgodne z wersjami w `pubspec.lock`
- Ikona aplikacji (custom, motyw pięść+hantla, paleta #1A1D23/#FF6B35), zintegrowana we wszystkich rozdzielczościach Android (mdpi–xxxhdpi, launcher + round + adaptive foreground)
- README.md, ARCHITECTURE.md, CHANGELOG.md, CONTRIBUTING.md

### Fixed
- `flutter build web --release` — wcześniej fail (`Only JS interop members may be 'external'` z `sqlite3_flutter_libs` przez `dart:ffi` niekompatybilne z dart2js/wasm). Naprawione przez migrację do `WasmDatabase` na platformie web.
- Lint `dangling_library_doc_comments` w `connection.dart` — zamiana doc-comments (`///`) na zwykłe komentarze (`//`) + dodanie deklaracji `library;`

### Verified
- `flutter analyze` → **No issues found!**
- `flutter build web --release` → **✓ Built build/web** (60.7s), potwierdzono runtime przez log serwera: sekwencja żądań `main.dart.js → drift_worker.dart.js → sqlite3.wasm → assets/data/exercises.json` dowodzi, że baza Wasm inicjalizuje się i seed danych ćwiczeń wczytuje poprawnie w przeglądarce.

---

## [0.2.0] — Timer przerw + stoper izometryczny (MVP core loop)

### Added
- `core/widgets/rest_timer_screen.dart` — pełnoekranowy timer przerw (`showRestTimer()`):
  - Presety 60/90/120/180s + custom duration dialog
  - Pulsowanie wizualne (`flutter_animate`) przy ≤5s pozostałych
  - Haptic feedback + gong audio na zakończenie
  - Przyciski „Pomiń przerwę” / +/-15s
- `core/widgets/isometric_stopwatch.dart` — stoper izometryczny (`showIsometricStopwatch()`):
  - Non-dismissible bottom sheet (blokada przypadkowego zamknięcia w trakcie pomiaru)
  - Liczenie w górę, Start/Pauza/Wznów/Zakończ
- `core/services/gong_service.dart` — `GongService.playGong()` z fallbackiem na `SystemSound.play(SystemSoundType.alert)` gdy plik audio niedostępny
- Integracja timera i stopera w `active_session_page.dart`:
  - Auto-trigger timera przerw po każdej zalogowanej serii
  - Warunkowe UI (`_isIsometric`) — ćwiczenia izometryczne dostają stoper, siłowe dostają pola waga/powtórzenia

### Changed
- `_ExerciseLogCard` w `active_session_page.dart` zrefaktoryzowany — rozdzielenie logiki `_logStrengthSet()` vs `_startIsometricStopwatch()`, wspólny `_afterLogSet()` (obsługa PR + auto-timer)

### Feature: Planner (nowy, kompletny)
- `features/planner/domain/plan_generator.dart` — `PlanGenerator.generate()`: algorytm doboru ćwiczeń wg celu, poziomu, sprzętu i czasu sesji (mapa priorytetów partii ciała per cel treningowy)
- `features/planner/data/planner_repository.dart` — `SavedPlan` model + `PlannerRepository` (save/watch/delete)
- `features/planner/providers/planner_providers.dart`
- `features/planner/presentation/pages/planner_page.dart` — formularz generatora (poziom, czas trwania), wynik, historia zapisanych planów

### Fixed
- `use_build_context_synchronously` lint w `planner_page.dart` — `ScaffoldMessenger.of(context)` zapisywany do zmiennej przed `await`

---

## [0.1.0] — Naprawa kompilacji od 113 błędów do zera

### Fixed — Root cause: kolizja nazw Drift ↔ Freezed
- Dodano `@DataClassName('XxxData')` do 9 tabel Drift w 7 plikach (`exercises_table.dart`, `user_profile_table.dart`, `workout_tables.dart` ×2, `mood_table.dart`, `measurements_table.dart`, `tests_table.dart`, `prs_table.dart`, `plans_table.dart`) — eliminacja kolizji identyfikatorów między auto-generowanymi klasami wierszy Drift i modelami domenowymi Freezed o tych samych nazwach
- Regeneracja kodu: `dart run build_runner build --delete-conflicting-outputs` (104 outputs)

### Fixed — Błędy kompilacji i lint
- `app.dart` — brakujący import `flutter_localizations`, poprawiona lista `localizationsDelegates`
- `router.dart` — usunięcie unused import
- `workout_home_page.dart` — usunięcie leftover `typedef _Unused = ExercisesListPage;` (hack blokujący kompilację)
- `calculator_page.dart` — brakujący import `core/models/user_profile.dart` (błąd `undefined_getter 'label'`)
- Usunięcie 9 nieużywanych importów tabel Drift w plikach repozytoriów (`exercises_repository.dart`, `mood_repository.dart`, `onboarding_flow_page.dart`, `user_profile_provider.dart`, `measurements_repository.dart`, `prs_repository.dart`, `tests_repository.dart`, `workout_repository.dart`)

### Fixed — Testy
- `test/widget_test.dart` — całkowicie przepisany (wcześniej referencjonował nieistniejącą klasę `MyApp`), 5 nowych testów: `PrimaryButton` tap, `EmptyState` CTA, `ProviderScope` mount, `BmrCalculator.calculateFull`, `PrDetector.isNewRecord`
- Poprawiono błędną nazwę pola w teście: `kalorieDocelowe` → `celKalorii`

### Fixed — Android build
- `android/app/build.gradle.kts` — włączenie core library desugaring (`isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`), wymagane przez `flutter_local_notifications`

### Verified
- `flutter analyze` → **No issues found!** (z 113 błędów startowych)
- `flutter build apk --debug` → **SUCCESS** (~156MB, 141.6s)

---

## [0.0.1] — Stan wyjściowy

Projekt otrzymany z pełnym briefem technicznym: Flutter 3.35.4/Dart 3.9.2, Clean Architecture feature-first, Riverpod 2.6.1, GoRouter 14.8.1, Freezed+json_serializable, Drift, Material 3 dark theme. Struktura projektu, tabele Drift i większość features już istniały, ale projekt się nie kompilował (113 błędów `flutter analyze`, brak feature `planner` mimo referencji w routerze).
