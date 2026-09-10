# Architektura FitBirek

Ten dokument wyjaśnia **decyzje architektoniczne** i ich uzasadnienie — nie tylko "co", ale "dlaczego".

---

## Produkcja: konta i synchronizacja (2026-09-10)

Drift jest lokalnym magazynem offline, a FastAPI/PostgreSQL przechowuje konto,
sesje i zsynchronizowane dane. Outbox z UUID operacji obsługuje ponowienia,
wersje i tombstones. Jedno konto powstaje administracyjnie; brak publicznej
rejestracji. Sesje używają Secure/HttpOnly cookies i ochrony CSRF.

Źródła: `/opt/fit`; konfiguracja i trwałe dane: `/docker/fit`. Caddy jest
jedynym właścicielem 80/443. Sieć `fit_ingress` łączy go z API i web;
PostgreSQL jest wyłącznie w prywatnej `fit_internal`. Dedykowany obraz migracji
uruchamia Alembic przed API. Dumpy poprzedzają Restic; comiesięczny test odtwarza
izolowaną bazę. Procedury: [DEPLOY.md](DEPLOY.md).

## 1. Clean Architecture, feature-first

Kod jest podzielony wg **funkcji** (`features/workout`, `features/planner`...), nie wg warstwy technicznej. Każdy feature ma wewnętrznie strukturę zbliżoną do Clean Architecture:

```
features/<nazwa>/
├── data/            # repozytoria — konwersja Drift ↔ modele domenowe
├── domain/           # logika biznesowa niezależna od UI/DB (np. PlanGenerator)
├── providers/        # Riverpod — mostek między data i presentation
└── presentation/
    └── pages/        # widgety ekranów
```

**Dlaczego nie warstwowo (np. `lib/repositories/`, `lib/screens/`)?**
Przy 8 features i planowanych 316 ćwiczeniach, warstwowa struktura szybko staje się nieskalowalna — zmiana jednej funkcji wymaga skakania po całym drzewie katalogów. Feature-first izoluje zmiany: dodanie nowego ekranu do `planner` nie dotyka `workout`.

---

## 2. Riverpod, nie Bloc/Provider (v5)

**Dlaczego Riverpod 2.6.1:**
- **Testowalność bez BuildContext** — providery są globalnymi, kompozytowymi jednostkami, łatwe do nadpisania w testach (`ProviderScope(overrides: [...])`)
- **StreamProvider dla Drift** — Drift natywnie emituje `Stream<List<T>>` dla zapytań reaktywnych (`watchAll()`). Riverpod's `StreamProvider` to naturalny most bez dodatkowego boilerplate'u, jaki wymagałby Bloc (trzeba by ręcznie zarządzać `StreamSubscription` w każdym Bloc).
- **Brak potrzeby na klasy zdarzeń/stanów jak w Bloc** — dla aplikacji tej skali (nie enterprise) jawne `Event`/`State` klasy Bloc dodają ceremonię bez proporcjonalnej korzyści.
- Provider v5 (starszy) był rozważany, ale Riverpod usuwa zależność od `BuildContext` przy odczycie stanu poza drzewem widgetów (np. w `GongService` czy `PlanGenerator` wywoływanym z logiki), co jest wygodniejsze przy rozroście aplikacji.

---

## 3. Drift, nie Hive, jako główna baza danych

**Dlaczego Drift (SQLite), a nie Hive (NoSQL/dokumentowa):**

| Kryterium | Drift | Hive |
|---|---|---|
| Relacje między tabelami | ✅ natywne (foreign keys, joins) | ❌ trzeba ręcznie |
| Zapytania złożone (agregacje, filtrowanie) | ✅ SQL | ⚠️ ręczne filtrowanie w Dart |
| Reaktywność (`watch()`) | ✅ wbudowane `Stream` | ⚠️ wymaga `ValueListenable` + boilerplate |
| Typowanie i migracje schematu | ✅ generowane, wersjonowane | ⚠️ manualne |
| Wielkość danych (316 ćwiczeń × relacje z seriami/sesjami) | ✅ dobrze skaluje | ⚠️ ok, ale relacje bolą |

FitBirek ma **z natury relacyjne dane**: sesja treningowa ma wiele serii (`WorkoutSessions` 1:N `SetsLog`), ćwiczenie może być użyte w wielu sesjach, plan treningowy referencjonuje wiele ćwiczeń. To jest klasyczny przypadek dla bazy relacyjnej. Hive świetnie nadaje się do prostego key-value/cache (i dlatego `shared_preferences`/Hive są nadal rekomendowane dla ustawień), ale forsowanie relacji w Hive oznaczałoby ręczne odtwarzanie tego, co SQLite robi natywnie.

### 3.1. Kolizja nazw: `@DataClassName`

Drift domyślnie generuje klasę danych o tej samej nazwie co tabela (np. tabela `Exercises` → klasa `Exercise`). Ponieważ w `core/models/` mamy **osobne** modele domenowe Freezed o tych samych nazwach (`Exercise`, `UserProfile`, `WorkoutSession`...), powstaje kolizja identyfikatorów przy imporcie obu w jednym pliku.

**Rozwiązanie**: każda tabela Drift ma adnotację `@DataClassName('XxxData')`:
```dart
@DataClassName('ExerciseData')
class Exercises extends Table { ... }
```
Efekt: Drift generuje `ExerciseData` (surowy wiersz z bazy), a `Exercise` (Freezed) pozostaje czystym modelem domenowym używanym w UI i logice biznesowej. Repozytoria (`data/*_repository.dart`) odpowiadają za mapowanie `ExerciseData → Exercise`.

**Dlaczego to rozdzielenie ma sens, a nie jest tylko obchodzeniem błędu**: to jest właściwie granica warstwy `data` w Clean Architecture — surowy model bazy danych (`*Data`) nigdy nie powinien wyciekać do warstwy `presentation`. Kolizja nazw *wymusiła* to, co powinniśmy zrobić i tak.

### 3.2. Drift na wielu platformach (Android/iOS/Desktop vs Web)

**Problem**: `sqlite3_flutter_libs` (który daje `NativeDatabase` dostęp do natywnej biblioteki SQLite przez `dart:ffi`) **nie kompiluje się do JavaScript/Wasm** — `dart:ffi` nie istnieje w środowisku web. Próba `flutter build web` z tą zależnością kończy się błędem kompilacji (`Only JS interop members may be 'external'`).

**Rozwiązanie**: Drift oficjalnie wspiera **conditional exports** — plik `connection.dart` eksportuje różną implementację `openConnection()` zależnie od platformy kompilacji:

```dart
export 'unsupported_connection.dart'
    if (dart.library.ffi) 'native_connection.dart'
    if (dart.library.js_interop) 'web_connection.dart';
```

- **`native_connection.dart`** — `NativeDatabase.createInBackground()`, plik SQLite w katalogu dokumentów aplikacji (Android/iOS/desktop)
- **`web_connection.dart`** — `WasmDatabase.open()`, SQLite skompilowane do WebAssembly, przechowywanie w IndexedDB/OPFS przez `sqlite3.wasm` + `drift_worker.dart.js` (serwowane statycznie z `web/`)
- **`unsupported_connection.dart`** — stub rzucający `UnsupportedError` (teoretyczny fallback)

**Krytyczne**: wersje `sqlite3.wasm` i `drift_worker.dart.js` **muszą** odpowiadać wersjom pakietów `sqlite3` i `drift` w `pubspec.lock` (odpowiednio `2.9.4` i `2.28.2`) — niezgodność wersji protokołu worker↔wasm powoduje błędy runtime trudne do zdiagnozowania. Pliki binarne pobrano z oficjalnych GitHub Releases tych pakietów, nie zbudowano lokalnie.

---

## 4. GoRouter + StatefulShellRoute

5-tab bottom navigation zaimplementowany przez `StatefulShellRoute.indexedStack` — każda z 5 zakładek (Dziś/Baza/Trening/Postępy/Ustawienia) ma **własny, niezależny stack nawigacji**. Przełączenie zakładki nie resetuje stanu przewijania/nawigacji w innej zakładce (np. wejście głęboko w szczegóły ćwiczenia w "Baza", przełączenie na "Dziś" i powrót — użytkownik wraca do tego samego miejsca).

Alternatywa (`Navigator` z `IndexedStack` ręcznie) wymagałaby własnej implementacji zachowania stanu per-tab — GoRouter daje to "za darmo" i deklaratywnie.

---

## 5. Timer przerw i stoper izometryczny — decyzje UX

### Timer przerw (`rest_timer_screen.dart`)
- **Pełnoekranowy overlay** (`PageRouteBuilder` + `FadeTransition`), nie dialog — podczas przerwy między seriami użytkownik ma zwykle mokre/zapocone ręce (trening domowy), duży, jednoznaczny ekran z ogromnymi cyframi (`fontFeatures: [FontFeature.tabularFigures()]`, 76-96sp) minimalizuje błędy dotyku.
- **Auto-trigger po każdej zalogowanej serii** — zero dodatkowych kliknięć, timer startuje natychmiast, użytkownik może go pominąć (`Pomiń przerwę`) jeśli czuje się gotowy wcześniej.
- **Pulsowanie <5s** (`flutter_animate` `.scale()` z `repeat(reverse: true)`) + haptic + gong — trójkanałowe ostrzeżenie (wizualne + dotykowe + audio), bo użytkownik może nie patrzeć na telefon w trakcie przerwy.

### Stoper izometryczny (`isometric_stopwatch.dart`)
- **`showModalBottomSheet(isDismissible: false, enableDrag: false)`** — świadoma decyzja UX: podczas pomiaru plank/wall-sit/dead-hang przypadkowe zamknięcie sheet'a (np. przez swipe) zepsułoby pomiar. Blokada gestów jest tu funkcją, nie ograniczeniem.
- Liczy **w górę** (nie w dół jak timer przerw) — bo z definicji nie znamy z góry, jak długo użytkownik wytrzyma w pozycji izometrycznej.
- Renderowany warunkowo (`exercise.typ == 'Izometryczne'`) — siłowe ćwiczenia (waga×powtórzenia) i izometryczne mają fundamentalnie różny model logowania serii, stąd rozdzielenie w `_ExerciseLogCard`.

---

## 6. Wykrywanie PR — formuła Epley

`PrDetector.epley1Rm(waga, powtórzenia) = waga × (1 + powtórzenia/30)`

Standardowa formuła szacowania ciężaru maksymalnego na 1 powtórzenie (1RM) na podstawie serii wielopowtórzeniowej. Wybrana zamiast (np.) Brzycki, bo jest prostsza obliczeniowo i wystarczająco dokładna dla zakresu 1-10 powtórzeń typowego w treningu siłowym domowym — różnice między formułami są marginalne przy tej skali użycia (self-tracking, nie zawodowe programowanie treningu).

---

## 7. Kalkulator BMR/TDEE — formuła Mifflin-St Jeor

Wybrana zamiast starszej formuły Harrisa-Benedicta, bo Mifflin-St Jeor jest uznawana za dokładniejszą dla populacji ogólnej w nowszych badaniach (mniejszy błąd systematyczny przy nadwadze/niedowadze). Dla profilu użytkownika (47 lat, 180cm, 94kg, mezomorfik) różnica względem Harrisa-Benedicta wynosi zwykle 50-100 kcal — nieistotne praktycznie, ale Mifflin-St Jeor jest obecnym standardem w literaturze sportowej.

---

## 8. Generator planu (`PlanGenerator`)

Algorytm deterministyczny (nie ML/losowy), oparty na:
1. **Mapa priorytetów partii ciała per cel** (`_priorytetPartii: Map<CelTreningowy, List<String>>`) — np. dla redukcji tkanki priorytet mają ćwiczenia wielostawowe/całego ciała, dla siły — ćwiczenia bazowe konkretnych grup.
2. **Filtrowanie po dostępnym sprzęcie i poziomie** — ranking poziomów (`_poziomRanking`) zapewnia, że plan nie zaproponuje ćwiczenia zaawansowanego początkującemu.
3. **Skalowanie liczby ćwiczeń czasem sesji**: `(czasMinut/9).round().clamp(4,6)` — heurystyka: ~9 minut na ćwiczenie (rozgrzewka + serie + przerwy), ograniczona do sensownego zakresu 4-6 ćwiczeń niezależnie od ekstremalnych wartości slidera.

**Dlaczego deterministyczny algorytm, nie ML**: przy 38 (docelowo 316) ćwiczeniach i jasno zdefiniowanych regułach doboru, heurystyka reguł jest w pełni wystarczająca, przewidywalna dla użytkownika i nie wymaga danych treningowych do "uczenia się" — jest debugowalna i łatwa do rozszerzenia (nowa reguła = nowy wpis w mapie priorytetów).

---

## 9. Co zostało uproszczone / pominięte (i dlaczego to jest OK na tym etapie)

- **Backup/restore JSON**: placeholder UI istnieje, logika nie — bo wymaga przemyślenia formatu eksportu kompatybilnego ze wszystkimi 9 tabelami + wersjonowania schematu na przyszłość (migracje importu). Rozwiązanie na skróty tutaj groziłoby utratą danych użytkownika przy niekompatybilnej wersji — lepiej zrobić to poprawnie w dedykowanej sesji.
- **Notyfikacje lokalne**: wymaga `flutter_local_notifications` + `permission_handler` runtime permission flow na Androidzie 13+ (`POST_NOTIFICATIONS`), plus logika harmonogramu (karate wt/czw 19:30 to *powtarzające się* przypomnienie, nie jednorazowe) — zaplanowane, nieukończone z powodu priorytetu dla core loop treningowego (timer/stoper).
- **fl_chart wizualizacje**: dane (pomiary, testy) są już w bazie i dostępne przez repozytoria — brakuje tylko warstwy prezentacji. Niski techniczny ryzyko, czysto kwestia czasu.
