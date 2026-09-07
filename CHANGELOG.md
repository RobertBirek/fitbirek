# Changelog

Wszystkie znaczące zmiany w projekcie FitBirek są dokumentowane w tym pliku.

Format oparty na [Keep a Changelog](https://keepachangelog.com/), wersjonowanie projektu jest wewnętrzne (brak publicznego API/semver — aplikacja mobilna).

---

## [Unreleased]

### Planowane
- VPS deployment (fit.birek.online)

---

## [0.8.1] — Prawdziwy release keystore + drobne porządki

### Added
- `android/release-key.jks` + `android/key.properties` — wygenerowany prawdziwy keystore do podpisywania release buildów (alias `release`, ważny do 2054). Oba pliki poza kontrolą wersji (`android/.gitignore` już zawierał odpowiednie wzorce `key.properties` / `**/*.jks` — zweryfikowane, sekrety nigdy nie trafiły do repo).
- `android/app/build.gradle.kts` — dodano blok `signingConfigs { create("release") {...} }` wczytujący dane z `key.properties`; `buildTypes.release.signingConfig` przełączony z `debug` na `release` (z automatycznym fallbackiem na `debug`, gdy `key.properties` nie istnieje — np. świeży checkout repo bez wygenerowanego keystore).

### Fixed
- `lib/core/models/exercise.dart` — usunięto nieaktualny komentarz/TODO z ery "starter pack 38 ćwiczeń" i odniesienie do nieistniejącego skryptu `build_exercises.dart`; zaktualizowano na opis zgodny ze stanem faktycznym (realna baza 316, `tools/xlsx_to_json.py`).

### Verified
- `flutter build apk --release` — sukces (143.7s), APK 62.8MB (debug: ~191MB — R8/minifikacja działa poprawnie).
- `apksigner verify --print-certs` — potwierdzony podpis prawdziwym certyfikatem release (SHA-256 `72:12:8A:...:88:CF:49`), nie debug-keyem.
- `aapt dump badging` na release APK — `package: com.fitbirek.training`, `application-label: 'FitBirek Training'` — konsystencja zachowana.
- `flutter analyze` — brak problemów.

---

## [0.8.0] — Realna baza ćwiczeń (316 pozycji, autor: Robert Birek) zastępuje bazę syntetyczną

### Added
- `tools/xlsx_to_json.py` — konwerter Excel → JSON. Czyta zakładkę `BAZA_GLOWNA` (openpyxl, `data_only=True`) z `tools/source_data/baza_cwiczen_316.xlsx`, waliduje fail-fast (nagłówek, enumy `Typ`/`Poziom`, unikalność i format id `cwNNN`, dokładnie 316 pozycji), normalizuje pole `Sprzet` (aliasy, rozbijanie "X lub Y" / "X/Y" / "X opcjonalnie", fallback `["Masa własna"]`), rozdziela pola z separatorami (przecinek dla `Partie_wspierajace`, średnik dla `Kluczowe_wskazowki`/`Czeste_bledy`), zapisuje `assets/data/exercises.json`.
- `assets/data/exercises.json` — całkowicie zastąpiony: 316 PRAWDZIWYCH, ręcznie kuratorowanych ćwiczeń autorstwa Roberta Birka (2026-08-08), z realnymi źródłami wiedzy (Athlean-X, Muscle & Strength, Healthline, Harvard Health, GMB Fitness, Calisthenics Family, ChairTaiChi.org, Peloton, Cleveland Clinic, AAOS OrthoInfo, Barbend) — zastępuje syntetyczną bazę z 0.7.0.
- `lib/core/utils/partia_kategoria.dart` — funkcja czysta `mapToKategoria(partiaGlowna, {wzorzecRuchu})`, redukująca ~163 granularne wartości `Partia_glowna` z realnej bazy do 10 prostych kategorii UI (Klatka, Plecy, Barki, Biceps, Triceps, Pośladki, Nogi, Brzuch, Cardio, Mobilność), bez zmiany schematu Drift/Freezed. 100% pokrycie zweryfikowane wobec wszystkich rzeczywistych wartości z bazy.
- `test/unit/partia_kategoria_test.dart` — ~14 testów jednostkowych dla `mapToKategoria()` (kategorie podstawowe, precedencja przy wieloznacznych wartościach, branch `Full body` warunkowany `wzorzecRuchu`, fallback dla wartości resztkowych, case-insensitivity).
- Sprzęt: dodano `Krzesło` i `Ręcznik` do `AppConstants.dostepnySprzetOpcje` (realna baza wykorzystuje ćwiczenia z krzesłem — np. Chair Tai Chi — i ręcznikiem, nieobecne w bazie syntetycznej).
- `Typ` ćwiczenia: `AppConstants.typyOpcje` rozszerzone z 4 do 10 wartości (`Hipertrofia`, `Siła`, `Wytrzymałość`, `Cardio`, `Rozgrzewka`, `Regeneracja`, `Explosive`, `Rozciąganie`, `Izometria`, `Mobilność`), zgodnie z rzeczywistą taksonomią użytą w Excelu.

### Fixed
- **Krytyczne**: `active_session_page.dart` — stała `_typyIzometryczne` używała nieaktualnej wartości `'Izometryczne'`, niezgodnej z realną wartością `'Izometria'` z Excela. Bez tej naprawy stoper czasu dla 14 ćwiczeń izometrycznych (plank, wall sit itd.) w ogóle by się nie uruchamiał.
- `lib/features/exercises/providers/exercises_providers.dart` (`filteredExercisesProvider`) i `lib/features/planner/domain/plan_generator.dart` (grupowanie kandydatów) — filtrowanie/grupowanie po partii ciała przełączone z surowego `partiaGlowna` na `mapToKategoria(ex.partiaGlowna, wzorzecRuchu: ex.wzorzecRuchu)`, żeby UI (10 kategorii) poprawnie dopasowywało 163 granularne wartości z realnej bazy.
- `lib/features/onboarding/presentation/pages/onboarding_equipment_page.dart` — dodano ikony dla nowego sprzętu (`Krzesło` → `Icons.chair`, `Ręcznik` → `Icons.dry_cleaning`).
- `test/features/exercises/exercises_repository_test.dart` — enumy walidacyjne (`validTyp`, `validSprzet`) rozszerzone zgodnie z realną taksonomią; dodano test pokrycia `mapToKategoria()`; test unikalności nazw ćwiczeń zmieniony z prostego `nazwaPl` na klucz złożony `nazwaPl+partiaGlowna+typ` — realna baza zawiera zamierzone, legalne duplikaty nazw różniące się partią/typem (np. `Band pull-apart`, `Seated cat-cow` jako osobne warianty).

### Deprecated
- `scripts/generate_exercises.py` — generator bazy SYNTETYCZNEJ z 0.7.0, oznaczony jako deprecated. Zachowany wyłącznie jako historyczny wzorzec kodu (funkcja `add_family()`); NIE uruchamiać — nadpisałby realne dane. Aktualne źródło danych to `tools/xlsx_to_json.py`.

### Verified
- `flutter analyze` — brak problemów.
- `dart format .` — bez zmian formatowania poza konwersją.
- `flutter test` — **122 testy, wszystkie przechodzą** (`+122: All tests passed!`).
- `flutter build apk --debug` — sukces; `aapt dump badging` potwierdza `package: com.fitbirek.training`, `application-label: 'FitBirek Training'`.
- `flutter build web --release` — sukces (ostrzeżenia WASM dotyczące `flutter_secure_storage_web`/`dart:js` są nieszkodliwe dla standardowego JS builda).

---

## [0.7.0] — Rozszerzenie bazy ćwiczeń 38 → 316 + import przyrostowy

### Added
- `assets/data/exercises.json` rozszerzony z 38 do 316 ćwiczeń (`cw001`-`cw316`), zgodnych ze schematem Freezed (`Exercise`, 16 pól) i pełną walidacją: unikalne id/nazwyPl/nazwyEn, zgodne enumy (`poziom`, `typ`), sprzęt zawsze podzbiór `AppConstants.dostepnySprzetOpcje`. Rozkład per `partiaGlowna`: Nogi 55, Brzuch 45, Cardio 35, Klatka 32, Pośladki 30, Plecy 27, Barki 25, Mobilność 25, Biceps 21, Triceps 21.
- `scripts/generate_exercises.py` — generator Python używany do wytworzenia i scalenia nowych 278 pozycji (funkcja `add_family()` grupująca warianty ćwiczeń o wspólnym wzorcu ruchu/wskazówkach/błędach, funkcja `merge_and_write()` do przypisania sekwencyjnych ID i zapisu finalnego JSON). Pozostaje w repo jako wzorzec do kolejnych rozszerzeń bazy.
- Sprzęt "Bieżnia" (zdefiniowany w `AppConstants.dostepnySprzetOpcje`, ale dotąd nieużywany przez żadne ćwiczenie) doczekał się realnych pozycji: marsz z inklinacją, interwały HIIT na bieżni.

### Fixed
- **Krytyczne**: `ExercisesRepository.importFromAssetsIfEmpty()` (blokował import na urządzeniach z niepustą tabelą — nowe ćwiczenia nigdy nie trafiłyby do istniejących instalacji) zastąpiony przez `syncFromAssets()` — import przyrostowy, wstawiający tylko ćwiczenia o `id` jeszcze nieobecnym w bazie lokalnej. Nie nadpisuje/nie usuwa istniejących wierszy, więc `ulubione` ustawione przez użytkownika jest zachowane. Dodano `ExercisesDao.getAllIds()` do wsparcia tej logiki. Zaktualizowano call site w `lib/main.dart`.

### Docs
- `CONTRIBUTING.md` — poprawiono niezgodność nazwy pola (`sprzetWymagany` → `sprzet`, zgodnie z rzeczywistym modelem), usunięto nieaktualną wzmiankę o `applicationId` (naprawione w 0.6.1), dodano wskazówki o imporcie przyrostowym i generatorze `scripts/generate_exercises.py`.
- `README.md` — zaktualizowano opis bazy ćwiczeń (316 zamiast "38, docelowo 316"), usunięto zrealizowaną pozycję z tabeli "Znane ograniczenia".

---

## [0.6.1] — Drobiazgi: ujednolicenie applicationId + prawdziwy gong

### Fixed
- Ujednolicono Android `applicationId`/`namespace`: `com.fitbirek.fitbirek_training` → `com.fitbirek.training` (zgodnie z docelową nazwą pakietu projektu). Zaktualizowano `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml` (`android:label` → "FitBirek Training"), przeniesiono `MainActivity.kt` do nowej struktury katalogów `android/app/src/main/kotlin/com/fitbirek/training/`, usunięto starą strukturę. Zweryfikowano `flutter build apk --debug` (SUCCESS) + `aapt dump badging` potwierdzający poprawny package name w gotowym APK.

### Added
- Dodano rzeczywisty plik `assets/sounds/gong.mp3` (wygenerowany efekt dźwiękowy — pojedyncze uderzenie gongu, ~2s). `GongService` nadal zachowuje fallback na `SystemSoundType.alert` na wypadek problemów z odtwarzaniem audio na urządzeniu, ale nie jest już to jedyna dostępna ścieżka dźwiękowa.

### Docs
- Zaktualizowano README.md — usunięto z tabeli "Znane ograniczenia" pozycje `gong.mp3` i `applicationId` (zrealizowane), pozostawiono VPS deployment i rozszerzenie bazy ćwiczeń jako wciąż otwarte.

---

## [0.6.0] — Wykresy postępów (fl_chart) + testy per-feature

### Added
- `lib/core/widgets/weight_line_chart.dart` — wykres liniowy wagi w czasie (fl_chart), sortowanie chronologiczne wewnątrz widgetu, tooltip z datą i wagą, gradient pod linią, placeholder gdy < 2 pomiary
- `lib/core/widgets/test_score_chart.dart` — wykres liniowy score (0-100) testów sprawnościowych w czasie, z `ChoiceChip` do przełączania typu testu; buduje listę dostępnych typów dynamicznie na podstawie zapisanych wyników (nie zakłada z góry, które testy user wykonywał)
- Integracja obu wykresów w `progress_page.dart` — sekcje "Waga w czasie" i "Progres testów sprawnościowych" wstawione przed listami PR/pomiarów; podłączenie dotychczas nieużywanego `allTestResultsProvider`

### Tests (73 nowe testy, +73 → 168 łącznie w projekcie)
- `test/features/progress/test_score_calculator_test.dart` — 18 testów: wszystkie 11 typów testów sprawnościowych, progi low/high, clamping, zaokrąglanie
- `test/features/progress/formatters_test.dart` — 17 testów: date/dateTime/time/dayMonth/weekday/duration/weight/deltaPercent
- `test/features/progress/pr_detector_test.dart` — 10 testów dedykowanych (rozszerzenie poza 2 testy smoke w `widget_test.dart`): epley1Rm, isNewRecord, przypadki brzegowe (0/ujemne wartości)
- `test/features/planner/plan_generator_test.dart` — 11 testów: filtrowanie sprzętu/poziomu, skalowanie liczby ćwiczeń czasem, priorytety wg celu, przypadki brzegowe
- `test/features/progress/measurements_repository_test.dart` — 7 testów na `AppDatabase.forTesting(NativeDatabase.memory())`
- `test/features/progress/tests_repository_test.dart` — 6 testów (w tym auto-przeliczanie score przy zapisie)
- `test/features/progress/prs_repository_test.dart` — 6 testów (w tym auto-przeliczanie 1RM wg Epley przy zapisie)

### Fixed
- `MeasurementsDao`/`TestsDao`/`PrsDao`/`MoodDao.watchAll()` (i pochodne `getLatest`/`getHistoryFor*`) — sortowanie było oparte wyłącznie na `data` (kolumna `DateTimeColumn` w SQLite ma rozdzielczość sekundową), co dawało niezdeterminowaną kolejność przy kilku insertach w tej samej sekundzie. Dodano `id` jako drugorzędne kryterium sortowania (`OrderingTerm.desc(t.id)`) — wykryte przez nowe testy repozytoriów, naprawione w kodzie produkcyjnym (nie tylko w teście)

---

## [0.5.0] — Notyfikacje lokalne

### Added
- `lib/core/services/notification_scheduler.dart` — czysta logika obliczania terminów (`nextWeekdayTime()`, `nextDailyTime()`), bez zależności od pluginu/platform channels — testowalna w izolacji na `DateTime`
- `lib/core/services/notification_service.dart` — `NotificationService` na `flutter_local_notifications` + `timezone` (strefa zahardkodowana na `Europe/Warsaw` — aplikacja jednoosobowa, PL):
  - `setKarateReminder()` — cotygodniowe przypomnienie wt+czw 19:30 (30 min przed treningiem 20:00), powtarzane automatycznie (`DateTimeComponents.dayOfWeekAndTime`)
  - `setWorkoutReminder()` — codzienne przypomnienie o treningu domowym (domyślnie 18:00)
  - `setMoodCheckReminder()` — codzienny prompt dziennika samopoczucia (domyślnie 20:30)
  - `requestPermission()` — żądanie zgody na notyfikacje (Android 13+)
  - Guard `kIsWeb` przy inicjalizacji strefy czasowej — plugin sam jest no-op na Web, ale `timezone.initializeTimeZones()` nie jest potrzebne na tej platformie
- `notificationServiceProvider` w `core/providers/notification_provider.dart`
- Rozszerzenie `AppSettings`/`SettingsNotifier` o `notifKarate`/`notifWorkout`/`notifMood` (persystencja w `SharedPreferences`, re-aplikowanie harmonogramu przy starcie aplikacji)
- UI w `settings_page.dart` — 3 nowe `SwitchListTile` w sekcji "Powiadomienia", żądanie uprawnienia przy włączeniu
- `AndroidManifest.xml` — `RECEIVE_BOOT_COMPLETED` + `SCHEDULE_EXACT_ALARM` permissions, `ScheduledNotificationReceiver` + `ScheduledNotificationBootReceiver` (przetrwanie zaplanowanych notyfikacji po restarcie urządzenia)
- `timezone: ^0.10.1` jako bezpośrednia zależność w `pubspec.yaml` (była tranzytywna przez `flutter_local_notifications`, `flutter analyze` wymagał jawnej deklaracji)

### Tests
- `test/features/settings/notification_scheduler_test.dart` — 8 testów jednostkowych na czystej logice `NotificationScheduler` (bez platform channels): wybór najbliższego dnia tygodnia/godziny, przeskok o tydzień/dzień gdy godzina minęła, równość traktowana jako "minęło", granica miesiąca

### Fixed
- `test/widget_test.dart` — poprawiono błędną oczekiwaną wartość w teście `BmrCalculator` (1707.5 → 1835.0; sam wzór Mifflin-St Jeor w `BmrCalculator` był poprawny, błąd był wyłącznie w asercji testu — wykryty przy pełnym przebiegu `flutter test` w tej sesji, niezwiązany z notyfikacjami)

### Verified
- `flutter analyze` → **No issues found!**
- `dart format .` → sformatowane
- `flutter test` (pełny projekt) → **20/20 passed**
- `flutter build apk --debug` → **SUCCESS** (181MB)
- `flutter build web --release` → **SUCCESS** (potwierdzone, że guard `kIsWeb` nie łamie platformy web mimo że `flutter_local_notifications`/`timezone` nie deklarują wsparcia Web w swoich `pubspec.yaml`)

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
