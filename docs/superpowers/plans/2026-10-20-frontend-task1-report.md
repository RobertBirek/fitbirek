# Frontend usability — zadanie 1

## Zakres i pliki

Zmieniono wyłącznie:

- `lib/core/utils/{numeric_input,profile_input}.dart` — wspólna walidacja dodatnich finite, parser dodatniego całkowitego wieku, formatter round-trip bez zaokrąglania (także rozwinięcie notacji wykładniczej).
- `lib/features/onboarding/presentation/pages/onboarding_profile_page.dart` — wiek bez ułamków/NaN/Infinity/eksponentów, decimal przez istniejący `parseDecimal`, przecinek i zewnętrzne białe znaki, szerokość 640.
- `lib/features/onboarding/providers/user_profile_provider.dart` — walidacja repo i opcjonalna, kompatybilna ścieżka guarded edit.
- `lib/features/settings/presentation/pages/edit_profile_page.dart` — formularz bez fallbacków, dokładne wartości, busy/double-tap, komunikat błędu z zachowaniem szkicu, limit 640 i anulowanie.
- `lib/features/progress/tests/presentation/pages/run_test_page.dart` — zmiana typu czyści szkic z krótkim komunikatem; ten sam typ zachowuje tekst. Bez zmiany repozytorium/historycznych wyników.
- `lib/features/calculator/presentation/pages/calculator_page.dart` — pary label/value mają semantykę, elastyczny układ i limit 640; wzory/jednostki bez zmian.
- `test/features/settings/{profile_usability,profile_edit_repository}_test.dart` — 25 nowych testów.

Zastane niezatwierdzone Ustawienia/router/bootstrap/push/sync pozostawiono bez zmian. Nie zmieniono Mentora, innych ekranów, wersji, backendu, schematu, danych ani locków. Nie wykonano commit/push/deploy.

## API i ochrona zapisu

`UserProfileRepository(db, {authority})` zachowuje stary konstruktor pozycyjny. `saveProfile` zachowuje stare parametry i dodaje opcjonalne `ProfileEdit? edit`, `bool Function()? isCurrent`. Wszystkie wywołania walidują liczby; tylko ścieżka edycji wymaga istniejącego powiązania konta.

`captureEdit()` przechwytuje epoch **przed kolejką transakcji**, konto/device/offlineAccess i pełny immutable wiersz Drift. `checkEditAuthority(edit)` sprawdza powiązanie po powrocie zapisu do UI. Provider przekazuje istniejące pasywne `cachedAuthWriteAuthorityProvider`, bez inicjowania HTTP.

Zapis edycji porównuje pełną równość Drift (pola, kolekcje JSON, UUID, wersję i znaczniki czasu), odmawia nadpisania nowszego profilu i nie odświeża szkicu automatycznie. Sprawdza epoch/konto/binding w transakcji oraz po zapisach; utrata uprawnień wycofuje także outbox. Hold i deferred >= wersja profilu blokują edycję i pozostają nietknięte. Nieznana wersja kolekcji powoduje rollback przez istniejący serializer, bez zastąpienia kolekcji pustą. Nie zmieniono attempted/preserveLocal ani sposobu budowania payload/baseVersion.

UI wiąże szkic z przechwyconym baseline; podczas zapisu wyłącza pola i przycisk. Warunek bieżącej trasy jest konieczny oprócz `mounted`: cofnięta strona może być jeszcze zamontowana podczas animacji. Anulowanie przed odblokowaniem kolejki nie zapisuje ani nie wykonuje drugiego pop.

Kompatybilność: onboarding bez profilu/powiązania i świadome stare lokalne wywołania bez `edit` nadal działają. Te stare wywołania **nie uzyskują** automatycznie ochrony konta/baseline; produkcyjny ekran edycji zawsze przekazuje token. Repo utworzone ręcznie bez `authority` nie rozpoznaje samego A-B-A przy identycznym powiązaniu; produkcyjny provider przekazuje authority. Brak nowej trwałej generacji w schemacie.

## RED → GREEN

Wszystkie polecenia Flutter/Dart w istniejącym obrazie `fit-web:release-1.13.0-26-verified`, `/opt/fit:/app`, `--no-pub`; bez aktualizacji zależności.

1. `flutter test --no-pub test/features/settings/profile_usability_test.dart` przed implementacją: `/tmp/opencode/task1-red.log`. Potwierdzone RED: `FormatException` dla 47.5, zaokrąglenie 180.5→181 oraz sześć overflow kalkulatora (do 531 px). Początkowy test zmiany rodzaju miał błędną etykietę Planka — ten błąd testu nie jest dowodem RED produktu.
2. Po poprawieniu etykiety uruchomiono test zmiany rodzaju na oryginalnym `run_test_page.dart` z HEAD, podmontowanym read-only wyłącznie wewnątrz kontenera. `flutter test --no-pub test/features/settings/profile_usability_test.dart --plain-name 'test change clears draft but same choice retains it'`: RED oczekiwane `''`, rzeczywiste `'60'`; `/tmp/opencode/task1-red-draft.log`.
3. Test realnego anulowania kolejkującego zapisu dodatkowo wykrył RED: samo `mounted` umożliwiało zapis/pop podczas animacji cofania (`task1-verify2.log`). Dodano sprawdzanie bieżącej trasy; GREEN.
4. Testy repo sprawdzają prawdziwe SQLite/Drift i outbox: błędne liczby, dokładne ułamki, kolekcje, nowe zdalne dane, zmianę urządzenia/offlineAccess, A-B-A przy oczekującym load/write, anulowanie, hold/deferred i onboarding offline. Ręcznie sterowana authority symuluje zmiany sesji, nie zastępuje logiki repo.
5. Widgety edycji używają prawdziwego Drift/outbox i rzeczywistego GoRouter push/pop; awaria jest wymuszona SQLite triggerem, busy kolejką rzeczywistej transakcji. Nie są to testy pełnego routera aplikacji. Kalkulator: 320/375/768/1280, light/dark, tekst 200%, semantyka i limit szerokości.

## Końcowa weryfikacja

`/tmp/opencode/task1-final-verify.log`:

```sh
docker run --rm -v /opt/fit:/app fit-web:release-1.13.0-26-verified sh -lc '
  export PATH=/sdks/flutter/bin:/sdks/flutter/bin/cache/dart-sdk/bin:$PATH
  # dart format wyłącznie dziewięciu własnych plików Dart
  flutter test --no-pub --reporter expanded \
    test/features/settings/profile_usability_test.dart \
    test/features/settings/profile_edit_repository_test.dart \
    test/features/progress/numeric_forms_test.dart \
    test/features/progress/numeric_input_test.dart &&
  flutter analyze --no-pub &&
  dart tools/generate_app_version.dart --check
'
```

**37/37 PASS** (25 nowych + 12 istniejących), **analyze: No issues found**, version check PASS. `git diff --check` PASS. Formatowano tylko własne pliki.

Nie zmieniono deklaracji Drift/Freezed/JSON — generator nie był potrzebny. `pubspec.lock`, `web/sqlite3.wasm` i `web/drift_worker.dart.js` mają identyczne SHA-256 jak w obrazie bazowym; lock nadal wskazuje Drift 2.28.2 / sqlite3 2.9.4.

Samoprzegląd: zakres/spec §1, ścieżki awarii/anulowania, optimistic baseline i nieznane kolekcje sprawdzone. Pełna suita, niezależny review, pełny router aplikacji i browser/screenshoty pozostają do integracji; nie deklaruję ich jako wykonanych.
