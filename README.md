# FitBirek 🥋💪

**FitBirek** to osobisty asystent treningów domowych, zaprojektowany od podstaw dla konkretnego profilu użytkownika: mezomorfika trenującego karate (wt/czw 20:00), z celem redukcji tkanki tłuszczowej i budowy siły, korzystającego ze sprzętu domowego (hantle do 15kg, ławka regulowana, drążek na suficie, gumy oporowe, bieżnia, skakanka).

Aplikacja nie jest generycznym trackerem — to narzędzie skrojone pod realny plan treningowy, z naciskiem na szybkość logowania serii podczas treningu (timer przerw, stoper izometryczny) i śledzenie postępów w czasie.

🌐 **Aplikacja produkcyjna**: [fit.birek.online](https://fit.birek.online) — instrukcja wdrożenia na własny VPS: [DEPLOY.md](DEPLOY.md)

---

## ✨ Funkcje

### Produkcja (2026-09-10)

Prywatne konto i synchronizacja offline działają przez FastAPI/PostgreSQL.
Kod: `/opt/fit`, runtime: `/docker/fit`, szablony: `deploy/`. Caddy obsługuje
HTTPS. Codzienne dumpy są objęte Restic i miesięcznym testem odtworzenia.
Procedury aktualizacji, konta i backupu: [DEPLOY.md](DEPLOY.md).

### MVP (zrealizowane)
- **Onboarding** (3 ekrany) — profil użytkownika, cel, dostępny sprzęt
- **5-tab bottom navigation**: Dziś / Baza / Trening / Postępy / Ustawienia
- **Baza ćwiczeń** — 316 ćwiczeń, filtrowanie po partii ciała, sprzęcie, poziomie
- **Aktywna sesja treningowa**:
  - Logowanie serii (waga × powtórzenia) z automatycznym wykrywaniem rekordów osobistych (formuła Epley 1RM)
  - **Timer przerw** — presety 60/90/120/180s + custom, pulsowanie wizualne przy <5s, gong + wibracja, pełnoekranowy overlay
  - **Stoper izometryczny** — dla plank/wall-sit/dead-hang, liczy w górę, non-dismissible bottom sheet
- **Dziennik samopoczucia** — szybki mood-check

### Standard
- **Pomiary ciała** — historia wagi, obwodów
- **Testy sprawnościowe** — 11 typów (pompki, plank, dead-hang, itd.)
- **Rekordy osobiste (PR)** — automatyczna detekcja nowych rekordów w trakcie sesji

### Premium
- **Generator planu treningowego** — dobiera ćwiczenia pod cel, poziom i dostępny sprzęt (algorytm priorytetyzujący partie ciała), zapisywanie i historia wygenerowanych planów
- **Kalkulator BMR/TDEE** — formuła Mifflin-St Jeor, cel kaloryczny pod redukcję/utrzymanie/masę
- **Backup/restore JSON** — eksport całej bazy do pliku JSON (udostępnianie przez `share_plus`) i import z walidacją wersji formatu oraz transakcyjnym rollbackiem przy błędzie
- **Notyfikacje lokalne** — przypomnienie karate (wt+czw 19:30, cotygodniowe), przypomnienie o treningu domowym (codzienne, 18:00) i prompt dziennika samopoczucia (codzienne, 20:30); przełączniki w Ustawieniach, `flutter_local_notifications` + `timezone` (strefa `Europe/Warsaw`)

---

## 🏗️ Stos technologiczny

| Warstwa | Technologia |
|---|---|
| Framework | Flutter 3.35.4 / Dart 3.9.2 |
| Architektura | Clean Architecture, feature-first |
| State management | Riverpod 2.6.1 |
| Routing | GoRouter 14.8.1 (StatefulShellRoute, 5 branch'y) |
| Modele danych | Freezed 2.5.7 + json_serializable 6.9.0 |
| Baza danych | Drift (SQLite) — NativeDatabase (Android/iOS/desktop) / WasmDatabase (Web) |
| UI | Material 3, dark theme (#1A1D23 tło, #FF6B35 akcent) |
| Animacje | flutter_animate |
| Wykresy | fl_chart 0.69.2 — wykres wagi w czasie + progres testów sprawnościowych |

Szczegóły decyzji architektonicznych: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 🚀 Uruchamianie

### Wymagania
- Flutter 3.35.4, Dart 3.9.2 (środowisko zablokowane — **nie aktualizować**)
- Android SDK API 35, Build Tools 35.0.0, JDK 17

### Instalacja
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Android (debug)
```bash
flutter build apk --debug
# APK: build/app/outputs/flutter-apk/app-debug.apk
```

### Web (podgląd)
```bash
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0
```
> **Uwaga (Web)**: baza danych na Web działa przez Drift `WasmDatabase` (SQLite skompilowane do WebAssembly + IndexedDB/OPFS). Wymaga plików `web/sqlite3.wasm` i `web/drift_worker.dart.js` — są już w repo, wersje muszą pozostać zgodne z `pubspec.lock` (`sqlite3: 2.9.4`, `drift: 2.28.2`).

### Testy
```bash
flutter analyze   # statyczna analiza — cel: 0 issues
dart format .     # formatowanie
flutter test      # testy jednostkowe/widgetowe
```

---

## 📊 Stan projektu (checklist z briefu)

| Wymaganie | Status |
|---|---|
| `flutter analyze` — zero warnings | ✅ "No issues found!" |
| `dart format .` | ✅ |
| `flutter build apk --debug` bez błędów | ✅ (build ~156MB) |
| `flutter build web --release` | ✅ (naprawione przez WasmDatabase) |
| Pełny flow: onboarding → baza ćwiczeń → sesja → zapis do DB | ✅ |
| README / ARCHITECTURE / CHANGELOG / CONTRIBUTING | ✅ (ten zestaw plików) |
| Ikona aplikacji | ✅ |
| Testy per-feature (3-5 na feature) | ✅ 168 testów łącznie (progress: 62, planner: 11, settings: 14, smoke: 5+) |
| Backup/restore JSON | ✅ Zaimplementowane (export/import, 6 testów jednostkowych) |
| Notyfikacje lokalne | ✅ Zaimplementowane (karate, trening, mood-check; 8 testów jednostkowych) |
| Wizualizacje fl_chart (pomiary/testy) | ✅ Zaimplementowane (`WeightLineChart`, `TestScoreChart`, zintegrowane w `progress_page.dart`) |

---

## ⚠️ Znane ograniczenia i zadania na później

Poniżej szczera lista tego, co **nie** zostało zrobione, z szacowanym czasem dokończenia (dla planowania dalszej pracy):

| Zadanie | Szacowany czas | Priorytet |
|---|---|---|
| VPS deployment (fit.birek.online) | Wdrożono 2026-09-10 | Gotowe |

**Uwaga o bazie ćwiczeń**: `assets/data/exercises.json` zawiera 316 REALNYCH, ręcznie kuratorowanych ćwiczeń autorstwa Roberta Birka (2026-08-08), oparte na uznanych źródłach wiedzy (Athlean-X, Muscle & Strength, Healthline, Harvard Health, GMB Fitness, Calisthenics Family, ChairTaiChi.org, Peloton, Cleveland Clinic, AAOS OrthoInfo, Barbend). Dane pochodzą z pliku Excel (zakładka `BAZA_GLOWNA`), konwertowanego skryptem `tools/xlsx_to_json.py` (zastąpił wcześniejszy generator syntetyczny `scripts/generate_exercises.py`, oznaczony jako deprecated). Import do bazy Drift jest przyrostowy (`ExercisesRepository.syncFromAssets()`) — na urządzeniach z wcześniejszą wersją apki nowe pozycje dopiszą się automatycznie przy starcie, bez utraty oznaczeń „ulubione”. Filtrowanie i generator planu dopasowują ~163 granularne wartości `partiaGlowna` z realnej bazy do 10 kategorii UI za pomocą czystej funkcji `mapToKategoria()` (`lib/core/utils/partia_kategoria.dart`), bez zmiany schematu bazy.

**Uwaga o gongu**: prawdziwy plik `assets/sounds/gong.mp3` jest już dostarczony (wygenerowany, pojedyncze uderzenie ~2s). `GongService` zachowuje mechanizm fallbacku na `SystemSoundType.alert` na wypadek problemu z odtwarzaniem audio na konkretnym urządzeniu — to defensywny wzorzec, nie oznacza braku pliku.

**Uwaga o podpisywaniu release**: `android/app/build.gradle.kts` używa prawdziwego release keystore (`android/release-key.jks` + `android/key.properties`, poza kontrolą wersji — oba plik ignorowane przez `android/.gitignore`) — release APK/AAB nie jest już podpisywane debug-keyem. Jeśli te pliki nie istnieją (np. świeży checkout repo), build automatycznie spada na debug-signing (fallback w kodzie), żeby `flutter build apk --release` nie wywalał się na braku konfiguracji. Do dystrybucji na innej maszynie/CI trzeba wygenerować własny keystore i skopiować oba pliki do `android/`.

---

## 📁 Struktura projektu

```
lib/
├── app/                    # router, theme, constants, root widget
├── core/
│   ├── database/           # Drift: tables/, daos/, connection/ (native+web+unsupported)
│   ├── models/              # Freezed modele domenowe
│   ├── providers/            # globalne providery (np. appDatabaseProvider)
│   ├── services/             # np. GongService
│   └── widgets/              # RestTimerScreen, IsometricStopwatch, PrimaryButton...
└── features/
    ├── onboarding/
    ├── home/
    ├── exercises/
    ├── workout/             # sesja treningowa, timer, stoper
    ├── progress/            # measurements/, tests/, prs/
    ├── planner/             # generator planu + historia
    ├── calculator/          # BMR/TDEE
    └── settings/
```

---

*Zbudowane dla Roberta Birka — bo generyczna apka fitness nie zna Twojego drążka na suficie.* 🥋
