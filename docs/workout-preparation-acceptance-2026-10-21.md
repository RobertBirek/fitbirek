# Przygotowanie treningu — lokalna weryfikacja

## Zakres

Nowy modal przed startem z Dziś: lista sprzętu, ciężary i talerze, historia,
jawne sugestie oraz zamiany tylko na sesję lub także w szablonie. Pierwszy
trening nie dostaje wymyślonej historii. Anulowanie nie zapisuje danych.

Working set i kontrakt: [modules/workout-preparation.md](modules/workout-preparation.md).
Flutter 3.35.4 / Dart 3.9.2. Izolowany worktree z bazą `c627241`.
Bez commit/push/deploy, podniesienia wersji, zmian backendu, schematu, zależności
i plików Web SQLite. To nie jest odbiór nowego wydania produkcyjnego.

## Testy i przegląd

- Bazowy klient przed implementacją: 1432 PASS, 1 pominięcie DST w UTC.
- Po pierwszej integracji rdzenia: 160 focused PASS.
- Po poprawkach review: 94 focused PASS przygotowania/planera/progresji.
- Harmonogram i klasyczne Dziś: 96 PASS.
- Niezależny przegląd: 65 PASS przygotowania i prawdziwego routera; końcowy
  przegląd delty: 25 PASS, bez nowych P0/P1/P2.
- Pełny końcowy przebieg klienta: **1494 PASS, 0 FAIL, 1 skip w UTC**,
  `flutter test --no-pub --reporter expanded --concurrency=4` (10:28).
  Pominięty test `Warsaw spring DST gap is rejected instead of normalized`
  uruchomiony osobno z `TZ=Europe/Warsaw`: **1 PASS**.
- Pełne `flutter analyze --no-pub`: **No issues found**.
  Format zmienionego working setu: **34 pliki, 0 zmian**;
  `generate_app_version.dart --check` i `git diff --check`: PASS.
- Kompilacja zwykłego `lib/main.dart`: `flutter build web --release --no-pub`
  PASS. Standardowy JS web, nie Wasm; dry-run ostrzega o istniejącej zależności
  `flutter_secure_storage_web`. Pobranie przypiętego Web SDK wymagało sieci,
  bez zmiany SDK lub zależności.

Review i browser wykryły trzy poprawione błędy, każdy z testem RED → GREEN:

1. Natychmiastowy Start po wpisaniu kg gubił ostatnią edycję przed następną
   klatką. Zdarzenia użytkownika przekazują teraz cel synchronicznie.
2. Zmiana katalogu nie unieważniała otwartego podglądu. Start sprawdza aktualne
   modele oryginalnych ćwiczeń i zamienników.
3. Równoległe odczyty historii konkurowały o blokadę zapisu planera. Walidacja
   odczytu korzysta z repozytoryjnego checkTemplate i guardów konta bez rezerwacji
   slotu mutacji. Transakcyjny start zachowuje blokadę i pełną walidację.

## Jawne ograniczenia weryfikacji

Pierwszy pełny przebieg pobrał snapshot w trakcie integracji i zakończył się
1484 PASS / 1 skip / 5 FAIL: stara asercja Classic, stare potwierdzenia obu
hostów activity_today, stare potwierdzenie schedule_page oraz timeout
active_session_recovery (`repeat=true`). Testy wejść dostosowano, nie osłabiając
asercji zapisów. Ostatni test recovery ponowiony bez zmian: 4 PASS.

Kontrola formatowania całego repo wskazuje 10 wcześniejszych różnic poza tym
zakresem: notification_service, pliki trendów i testy bootstrap/mentor/trend.
Nie zmieniono ich w repo. Automatyczne formatowanie ich kopii w kontenerze
ujawnia dwa lints nawiasów w starym training_trend_provider_test. Końcowa
weryfikacja używa rzeczywistego drzewa oraz ścisłej kontroli formatowania
zmienionego working setu; nie deklarujemy globalnie czystego formatowania.

Browser retest PASS: `/tmp/opencode/preparation-browser/rerun/REPORT.md` i
`results.json`. Aktualny kompilat ma zgodne hashe źródeł; obie karty poprawnie
pokazują pierwszy trening. Sprawdzono cancel bez zapisów, dokładne 7,25 kg,
pojedynczy start, trwałe kg po reloadzie, natychmiastowy Start oraz oba zakresy
zamian i ich anulowanie. Zamiennik nie dziedziczy ciężaru poprzednika. Zapis
sesji daje 1 sesję / 1 draft / 0 serii / 0 PR. Screenshoty obejmują mobile,
desktop i tekst 200%; brak błędów konsoli. Żądania poza lokalnym originem
były blokowane; serwer zatrzymano po teście.

To skompilowany modal i rzeczywisty Web SQLite z izolowanym testowym kontem,
nie pełne E2E normalnego routera ani logowanie do produkcji. Retest po ostatniej
poprawce historii przeszedł. Brak odbioru na fizycznym iPhonie/VoiceOver i gwarancji
flush przy zabiciu procesu. Historia wyników, migracje i dane produkcyjne nie
były przepisywane ani kasowane.

Końcowe logi lokalne: `.superpowers/sdd/2026-10-21-workout-preparation/`
(`final-verification-4.log`, `warsaw-dst-final.log`, `app-build-network.log`).
Wersja pozostaje 1.21.0+37: nie publikowano pod nią nowej funkcji. Przyszłe
wydanie wymaga osobnej zgody, aktualizacji metadanych wersji i kontroli wdrożenia.

## Decyzja o publikacji — 2026-10-22

Po powyższym odbiorze użytkownik zatwierdził commit, push do `main` i wdrożenie.
Metadane kandydata podniesiono do **1.22.0+38**, wygenerowano wersję UI;
generator/check oraz 14 testów generatora PASS. Powyższy opis 1.21.0+37
dotyczy wyłącznie wcześniejszego lokalnego odbioru, nie nowego wydania.
Wdrożenie ma osobny raport w `docs/releases/`; nie należy utożsamiać zgody
z zakończonym wdrożeniem lub odbiorem na fizycznym telefonie.
