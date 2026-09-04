# FitBirek 🥋💪

**FitBirek** to osobisty asystent treningów domowych, zaprojektowany od podstaw dla konkretnego profilu użytkownika: mezomorfika trenującego karate (wt/czw 20:00), z celem redukcji tkanki tłuszczowej i budowy siły, korzystającego ze sprzętu domowego (hantle do 15kg, ławka regulowana, drążek na suficie, gumy oporowe, bieżnia, skakanka).

Aplikacja nie jest generycznym trackerem — to narzędzie skrojone pod realny plan treningowy, z naciskiem na szybkość logowania serii podczas treningu (timer przerw, stoper izometryczny) i śledzenie postępów w czasie.

---

## ✨ Funkcje

### MVP (zrealizowane)
- **Onboarding** (3 ekrany) — profil użytkownika, cel, dostępny sprzęt
- **5-tab bottom navigation**: Dziś / Baza / Trening / Postępy / Ustawienia
- **Baza ćwiczeń** — 38 ćwiczeń startowych (docelowo 316), filtrowanie po partii ciała, sprzęcie, poziomie
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
- Notyfikacje — *przygotowane pod implementację, patrz sekcja "Znane ograniczenia"*
- Backup/restore JSON — *przygotowane pod implementację, patrz sekcja "Znane ograniczenia"*

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
| Wykresy | fl_chart *(przygotowane, wizualizacje w toku)* |

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
| Testy per-feature (3-5 na feature) | ⚠️ Częściowe — 5 testów ogólnych, patrz "Znane ograniczenia" |
| Backup/restore JSON | ⚠️ UI placeholder, logika niezaimplementowana |
| Notyfikacje lokalne | ⚠️ Niezaimplementowane |
| Wizualizacje fl_chart (pomiary/testy) | ⚠️ Niezaimplementowane (obecnie plain listy) |

---

## ⚠️ Znane ograniczenia i zadania na później

Poniżej szczera lista tego, co **nie** zostało zrobione, z szacowanym czasem dokończenia (dla planowania dalszej pracy):

| Zadanie | Szacowany czas | Priorytet |
|---|---|---|
| Backup/restore JSON (export/import całej bazy) | 2-3h | Wysoki (funkcja Premium z briefu) |
| Notyfikacje lokalne (karate wt/czw 19:30, przypomnienia, mood-check prompt) | 3-4h | Wysoki |
| Wizualizacje fl_chart dla pomiarów i testów sprawnościowych | 4-5h | Średni |
| Testy per-feature (3-5 testów × 8 features = ~30 testów) | 6-8h | Średni |
| Plik audio `gong.mp3` (obecnie fallback na `SystemSound.play`) | 15 min | Niski |
| Ujednolicenie `applicationId` (`com.fitbirek.fitbirek_training` → docelowa nazwa pakietu) | 15 min | Niski |
| Rozszerzenie bazy ćwiczeń z 38 do 316 docelowych | 8-10h (dane + weryfikacja) | Niski (zależy od tempa dodawania) |

**Dlaczego gong ma fallback**: plik `assets/sounds/gong.mp3` nie został jeszcze dostarczony/wygenerowany. `GongService` w takim przypadku łapie wyjątek i odtwarza `SystemSoundType.alert` — użytkownik i tak słyszy sygnał końca przerwy, tylko nie jest to dedykowany gong.

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
