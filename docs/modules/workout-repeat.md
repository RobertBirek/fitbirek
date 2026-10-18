# Powtarzanie zakończonego treningu

## Punkty wejścia i zakres

Historia na Home otwiera istniejące podsumowanie. **Powtórz trening** otwiera
podgląd z dwoma jawnymi źródłami:

- **Oryginalny plan (snapshot)** — wyłącznie poprawny historyczny
  `WorkoutGuidance.plan`. Nie korzysta z aktualnego generatora ani zdarzeń zamian.
  Brak/uszkodzenie snapshotu blokuje ten wybór z wyjaśnieniem.
- **Potwierdzone wykonanie (wszystkie serie)** — wszystkie nieusunięte logi,
  w tym dodatkowe, w kolejności `timestamp`, następnie leksykograficzny sync UUID.
  Nie grupuje ani nie uśrednia pomiarów; NULL strony nie staje się `both`.

Wyświetlenie podglądu niczego nie zapisuje. Potwierdzenie tworzy nowy UUID sesji,
z bieżącym startem, zerowym czasem, bez starych serii, PR, notatki, zdarzeń
wykonania i checkpointów. Oryginalny plan dostaje nowy `WorkoutGuidance.start`.
Powtórzenie nie zmienia UUID ani danych źródła; późniejsze wznowienie dotyczy
już nowego UUID, a nie starego treningu.

## Model wykonania i kompatybilność

`domain/workout_repeat.dart` jest ręcznym kodekiem, bez Freezed/JSON generatora.
`WorkoutRepeat` ma listę `RepeatSetTarget`: exercise ID, snapshot nazwy,
reps/seconds, nullable kg, nullable side, nullable variant UUID i etykietę oraz
`previousRpe`. Nie zawiera starych set UUID. Cele nie są `StructuredPlan`:
powtarzające się ćwiczenia i różne protokoły kolejnych serii są dozwolone.

Wykonanie używa **lokalnego szkicu v1**, w istniejącym `fields`:

```text
repeatTargets: {version: 1, targets: [
  {exerciseId, name, reps, seconds, weightKg, side,
   variantId, variantLabel, previousRpe}
]}
repeatCompleted: [UUID nowych jawnie zapisanych serii]
```

`repeatCompleted` jest dopisywane w tej samej transakcji co rzeczywista seria,
outbox i ewentualny normalny PR. Kolejna pozycja nie zależy od liczby wszystkich
logów sesji: zewnętrzny dodatkowy log nie zużywa celu. Reload odczytuje pozycję
z SQLite, bez konieczności późniejszego flush UI. Zachowano CAS szkiców,
ich kolejkę i `_persistentDatabaseZone`; nie dopięto długowiecznej pracy do
strefy zakończonej transakcji startu.

Nowy pomiar RPE zaczyna pusty. Dawne RPE jest widocznym odniesieniem, nie
prefillem nowego pomiaru. Wartości kg/reps/seconds można świadomie edytować przed
zapisem każdej serii. Samo wyświetlenie/przejście/reload nie tworzy logu ani PR.
Sekundy oznaczają cel pojedynczej pracy; nie odtwarzamy przygotowania, przerw,
rund ani checkpointu z historycznych sekund. UI informuje o tym jawnie.

**Istotna granica:** `guidance` schema1 i `StructuredPlan` pozostają bez zmian.
Stary klient odrzuca nieznane klucze guidance, więc dodanie tam pola nie dawałoby
obietnicy „stary klient je ignoruje”. Dlatego per-set targets są opcjonalnym
polem lokalnego szkicu, którego starszy walidator zachowuje nieznane pola,
zamiast reinterpretacją guidance. Sesja i nowe wykonanie synchronizują się
zwykłą ścieżką; **same cele wykonania i ich lokalny kursor nie są synchronizowane
ani eksportowane w backupie**. Nie jest to chmurowe wznowienie powtórzenia.
Jeśli kontrakt ma wymagać przenoszenia tych celów przez guidance, to pozostaje
oddzielną, nierozwiązaną decyzją kompatybilności — nie deklarujemy jej wdrożenia.

## Guardy i niedostępność

`previewRepeat` zwraca odłączony model i fingerprint całego źródła oraz logów.
`RepeatWorkoutRequest` wiąże podgląd z właścicielem notifikatora, generacją,
account ID i authority epoch oraz nowym docelowym UUID. Wielokrotny confirm
tego samego żądania współdzieli jeden Future; repo ma dodatkową idempotencję UUID.

`startRepeat` wewnątrz jednej transakcji ponownie sprawdza konto/offlineAccess,
guard authority, zakończone nieusunięte źródło i UUID, fingerprint, katalog,
żywe warianty oraz brak aktywnej sesji także w bazie, nie tylko w RAM. Transakcja
obejmuje sesję, outbox i początkowy szkic. Utrata authority w trakcie await
wycofuje całość. Zmiana A–B–A nie przywraca ważności starego podglądu.

Brak ćwiczenia lub wariantu blokuje całe potwierdzenie i pozostawia wszystkie
wartości w podglądzie. Nie ma automatycznej zamiany wariantu na bazowy, pomijania
wierszy ani przeliczania dawnego celu według aktualnych defaultów. Można anulować
lub jawnie wybrać drugie źródło, jeśli jest dostępne. **Nie wdrożono edytora
mapowania niedostępnej pozycji na inne ćwiczenie/wariant.**

## Pliki

- `lib/features/workout/domain/workout_repeat.dart` — model i deterministyczny odczyt.
- `lib/features/workout/domain/workout_guidance.dart` — tylko walidacja nowych lokalnych pól.
- `lib/features/workout/data/workout_repository.dart` — podgląd i atomowy start.
- `lib/features/workout/providers/workout_providers.dart` — capture, confirm, cele i atomowy kursor.
- `lib/features/workout/presentation/widgets/repeat_workout_dialog.dart` — wybór, podgląd, confirm.
- `lib/features/workout/presentation/widgets/repeat_set_panel.dart` — kolejne jawne pomiary.
- `lib/features/workout/presentation/pages/{active_session_page,session_summary_page}.dart` — wpięcie UI.
- `test/features/workout/workout_repeat{,_persistence}_test.dart` — domena, repo/provider, widżety.

## Weryfikacja 2026-10-17

TDD: najpierw fixture domeny, RED na pustych celach; następnie RED startu nowej
sesji/preview, potem RED braku obu wyborów UI. Focused nowe testy na bieżącej
kopii współdzielonego drzewa: **18 passed**; analiza całego `lib/features/workout`
i obu nowych testów: **No issues found**.

Wcześniejszy szerszy przebieg `test/features/workout test/features/planner`:
**259 passed** (16 nowych testów przed dodaniem dwóch przypadków wariantów).
Ten przebieg był izolowany z bazą/plannerem z `e0fe9a6`, ponieważ równoległy agent
był wtedy w trakcie generatora harmonogramu. Nie jest dowodem integracji całej
bieżącej aplikacji; końcowy nowy focused zestaw i analiza użyły już aktualnego
drzewa z wygenerowanym modelem drugiego agenta.

Powtórzenie całego focused workout + planner na aktualnym współdzielonym drzewie:
**258 passed, 3 failed**. Wszystkie trzy błędy to historyczne fixture'y tworzące
bazę z aktualnej deklaracji, obniżające `user_version`, ale nieusuwające nowej
kolumny `weekly_schedule_json` przed ponowną migracją. Wynik:
`duplicate column name: weekly_schedule_json` w:

- `test/features/workout/guidance_migration_test.dart`
- `test/features/workout/workout_side_test.dart`
- `test/features/planner/structured_plan_persistence_test.dart`

Nie edytowano ich w tym zakresie; do uzgodnienia z właścicielem migracji
harmonogramu. Focused integracja całości **nie jest zielona**. Log:
`/root/.local/share/opencode/tool-output/tool_149e8b143001xbtFjU0QfDwvCa`.

Wszystkie testy/analizy: istniejący `fit-web:flutter-builder`, `/opt/fit`
montowane read-only jako `/source`, kopia robocza `/tmp/repeat-check` wewnątrz
kontenera. Format wyłącznie 10 własnych plików Dart. Bez build_runner,
zmian deklaracji generowanych, wersji, zależności, toolchainu, commit/push/deploy.
Brak testu prawdziwego procesu PWA i fizycznego telefonu w tym zakresie.

Lock pozostaje przy Drift 2.28.2 / sqlite3 2.9.4, artefakty niezmienione:

- `web/sqlite3.wasm`: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- `web/drift_worker.dart.js`: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

## Korekta po review SPEC — pomiary łączone i obciążenie czasowe

Potwierdzono dwie rozbieżności: `validateSet` dopuszcza jednocześnie dodatnie
powtórzenia i sekundy, podczas gdy kodek repeat wymagał dokładnie jednego pomiaru;
formularz i podgląd pomijały obciążenie serii czasowej, a zapis podstawiał NULL.

Kodek wymaga teraz **co najmniej jednego** dodatniego pomiaru. Jeśli historia
zawiera oba, podgląd pokazuje oba, formularz daje dwa niezależne edytowalne pola,
a jawny zapis zachowuje oba pomiary. Nie wnioskujemy z nich protokołu interwałów.
Obciążenie jest widoczne i edytowalne również dla sekund; zaczyna od historycznej
wartości lub pustego pola dla historycznego NULL. NULL przy zapisie oznacza puste
pole, nie automatyczne usunięcie obciążenia z powodu czasowego rodzaju pomiaru.

TDD: osiem nowych regresji najpierw było RED (blokada mieszanego źródła, brak kg
w podglądzie, brak pola ciężaru), następnie GREEN. Obejmują rzeczywisty zapis
historii przez repo, preview, start i ponowne otwarcie szkicu, oba pomiary,
brak automatycznych serii/PR, UI czas+kg, edycję kg, jawne wyczyszczenie i NULL.

Końcowa weryfikacja na aktualnym współdzielonym drzewie, w izolowanej kopii
Docker z read-only źródłem (`fit-web:flutter-builder`):

- `flutter test --no-pub -r expanded test/features/workout/workout_repeat_test.dart test/features/workout/workout_repeat_persistence_test.dart` — **26 passed**.
- `flutter test --no-pub -r expanded test/features/workout test/features/planner` — **269 passed**; wcześniejsze błędy fixture'ów migracji powyżej już nie występują po poprawce ich właściciela.
- `flutter analyze --no-pub` dla `workout_repeat.dart`, obu widżetów repeat i `workout_repeat_persistence_test.dart` — **No issues found**.

Ta korekta zmienia wyłącznie te cztery pliki Dart i niniejszy dokument.
Bez deklaracji DB, generatora, wersji, builda, deployu i commit/push.
