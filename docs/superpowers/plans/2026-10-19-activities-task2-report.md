# Task 2 — UI harmonogramu aktywności

## Zakres

Praca wyłącznie w głównym `/opt/fit`, gałąź
`feat/recurring-activity-schedules`. Zachowano domenę/repozytoria task1.
Bez subagentów, commit/push/deploy, nowych zależności, wersji, schematu,
backendu ani zmian serwisów/providerów powiadomień.

## Pliki tego zadania

Nowe:

- `lib/features/schedule/presentation/activity_list_page.dart`
- `lib/features/schedule/presentation/activity_editor_page.dart`
- `lib/features/schedule/presentation/widgets/today_schedule.dart`
- `test/features/schedule/activity_ui_test.dart`
- `test/features/schedule/activity_today_test.dart`
- `docs/superpowers/plans/2026-10-19-activities-task2-report.md`

Zmodyfikowane:

- `lib/app/router.dart`
- `lib/features/schedule/presentation/schedule_page.dart`
- `lib/features/settings/presentation/pages/settings_page.dart`
- `lib/features/home/presentation/pages/classic_today_page.dart`
- `lib/features/mentor/presentation/pages/mentor_page.dart`
- `lib/features/workout/presentation/pages/workout_home_page.dart`
- `lib/features/planner/providers/planner_providers.dart`
- `lib/features/workout/providers/workout_providers.dart`
- `test/features/mentor/mentor_flow_test.dart` — wspólny fixture rozmowy jawnie
  deklaruje brak lokalnego konta harmonogramu, zamiast otwierać platformową bazę.
  Nie zmieniono asercji rozmowy/przewijania.

Pozostałe modyfikacje domeny, kolekcji, backupu i testy task1 widoczne w `git
status` poprzedzały tę pracę i nie są zmianami task2.

## Trasy, widgety i API

- `/settings/activities`: dwie sekcje external/FitBirek, dodawanie, edycja,
  potwierdzane usuwanie, włączanie/wyłączanie. UUID reguły pozostaje kluczem
  edycji; replacement/tombstone wykonuje istniejący `ActivityRepository`.
- `/settings/activities/new?type=external|fitbirek` i
  `/settings/activities/:id/edit` są dziećmi istniejącej gałęzi settings.
  Nie dodano Navigatora ani drugiego shella.
- `ActivityEditorPage` przechwytuje epoch/konto, pojedynczy `ActivitySnapshot`
  **przed** odczytem prywatnych szablonów. Save nigdy nie pobiera nowego lease.
  Konflikt zachowuje treść; zmiana authority revision (również A→B→A) czyści
  kontrolery, lease, plany i pola oraz trwale blokuje formularz.
- Nazwa, wiele dni ISO, tekst HH:mm i picker, opcjonalne 1–1440 min,
  enabled, opcjonalny szablon FitBirek / jawny „Trening swobodny”, opt-in
  reminders domyślnie false i lead 0–1440. External nie ma pola szablonu.
  Informacja o osobnych uprawnieniach nie inicjuje żądań zgody.
- Legacy pozostaje widoczne jako „Bez godziny”; toggle jest wyłączony
  z wyjaśnieniem „najpierw edytuj”. Formularz nie dopisuje godziny legacy.
  Brakujący szablon jest jawnym stanem, nie cichym wyborem treningu swobodnego.
- `/schedule` nadal pokazuje tydzień, oba typy i czas. `TodaySchedule` używa
  tego samego `scheduleWeekProvider` i `ScheduleOccurrenceCard` w klasycznym
  Dziś oraz domyślnym Dziś Mentora. W Mentorze umieszczono go **wewnątrz
  istniejącego górnego scrolla**, bez zmiany Expanded/Flexible i scrolla rozmowy.
- Kalendarz pozostaje systemowo lokalny jak dotychczas (`CalendarDay.local`);
  reguły/godziny są opisane jako Europe/Warsaw. Brak nowych zależności/timezone
  konwersji oraz brak UTC+24h arytmetyki.
- Start ma potwierdzenie i nie zalicza terminu. W jednej transakcji SQLite
  ponownie odczytuje aktualny termin pod wybraną datą, porównuje jego ID,
  snapshot/nazwę, odrzuca przesunięty/usunięty/zaliczony, sprawdza writability
  profilu i aktywny trening. Szablon rozwiązuje istniejący PlannerWorkflow.
  Swobodny używa istniejącego ActiveWorkoutNotifier, nie własnego zapisu sesji.
- Addytywne opcjonalne API: `PlannerWorkflow.startSaved(..., isCurrent:)` i
  `ActiveWorkoutNotifier.startSession(..., isCurrent:)`. Guard mounted/konto/
  epoch dochodzi aż do zapisu sesji i odczytu po await, nie tylko do dialogu.
- Po starcie `.go('/workout/session')`, nie push istniejącego shella.
  Link zarządzania z root `/schedule` również używa `.go` do settings.
- External wykonuje potwierdzane `completeExternal`; FitBirek wybiera
  rzeczywistą zakończoną sesję z listy providerowej i używa istniejącego
  `complete`. Bez fikcyjnych logów, automatycznych wykonań i kopiowania serii.

## Dowody i ograniczenia

- Początkowy RED real-router UI: `/tmp/opencode/activity-ui-red.log`
  (brak wejścia do harmonogramu).
- Dalsze regresje CRUD/multi-day, małego ekranu i Dziś rozbudowano w trakcie
  implementacji; nie twierdzimy, że każdy dodatkowy przypadek miał osobny RED.
- Pośrednie błędy fixture'ów (lazy list, fokus/scroll, brak izolacji lokalnej
  bazy w testach rozmowy, podwójny dispose) naprawiono bez osłabiania asercji.
- `/tmp/opencode/activity-task2-ui8.log`: **4 PASS / 0 FAIL** real-router UI
  (normalny oraz 320 px / text200%, obie ścieżki Dziś). Obejmuje CRUD/cancel,
  stale edit z zachowaną treścią, A→B→A, wiele dni i 06:00/18:00, Basen
  niedziela12:30, brak auto records, ręczne external bez logów, start swobodny,
  usunięcie terminu podczas dialogu, aktywną sesję bez nadpisania, wykonanie
  rzeczywistą sesją <=1 terminu i usunięty szablon bez fallbacku.
  Następnie dodano jeszcze asercje udanej edycji, toggle i double-tap Save.
- Końcowy szeroki focused: **505 PASS / 0 FAIL**:
  `flutter test --no-pub --reporter expanded test/features/schedule
  test/features/mentor test/features/planner test/features/workout`.
  Log: `/tmp/opencode/activity-task2-verification.log`. Obejmuje całą suite
  przewijania Mentora i rzeczywiste routery startu/treningu. Analyze z tego
  przebiegu miał jedną uwagę o klamrach w nowym guardzie; poprawiona.
- Po ostatnich drobnych poprawkach czyszczenia pól i ograniczeniu obserwacji
  katalogu do terminów z szablonem ponowiono **7 PASS / 0 FAIL**:
  `activity_ui_test.dart`, `activity_today_test.dart`,
  `schedule_router_start_test.dart`, `schedule_page_test.dart`.
  Log: `/tmp/opencode/activity-task2-final-ui.log` (zawiera także wcześniejszą
  pojedynczą uwagę analyze przed poprawką klamer).
- **Końcowy `flutter analyze --no-pub`: No issues found**, exit0;
  `/tmp/opencode/activity-task2-analyze-final.log`. `git diff --check` i
  `dart tools/generate_app_version.dart --check`: sukces.
- Weryfikacja w przypiętym Dockerze
  `fit-web:release-1.13.0-26-verified`, Flutter3.35.4 / Dart3.9.2,
  `--rm --network none -v /opt/fit:/app -w /app`. Formatowano wyłącznie
  pliki Dart zmieniane w task2. Nie uruchamiano pełnego Flutter suite ani
  backend pytest (backend bez zmian).
- Bez zmian deklaracji Drift/Freezed/json_serializable: generator niepotrzebny.
  Generated, lock i Web SQLite niezmienione. Lock: drift2.28.2 / sqlite3 2.9.4.
  SHA256 wasm: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`,
  worker: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`.
- Migracja stałych reminder settings/native toggles, permissions i dostarczanie
  powiadomień pozostają task3. Nie wykonano browser acceptance ani deploy.

## Poprawka review P2 — nieaktualny dialog wykonania/przesunięcia

Zgłoszenie potwierdzono: dotychczasowe `ScheduleRepository._current` podążało
za najnowszym `movedDate`, zamiast odrzucić akcję potwierdzoną dla innego,
wcześniej wyświetlonego snapshotu. Zmiana dotyczy wspólnej warstwy repozytorium,
nie tylko konkretnego przycisku UI.

Pliki poprawki:

- `lib/features/schedule/domain/weekly_schedule.dart`: addytywne lokalne pole
  `ScheduleOccurrence.sourceRevision` i getter `mutationBaseline`. `between`
  przechwytuje niemutowalną kanoniczną kopię **pełnej** źródłowej reguły oraz
  poprzedniego override (włącznie z brakiem wpisu, timestamps, tombstone,
  nieznanymi polami). Baseline obejmuje także wszystkie pola wystąpienia:
  identyfikatory, nazwę, daty, target planu, godzinę, typ, duration, snapshot
  reguły i stan wykonania. Nie jest zapisywany na wire ani do bazy.
- `lib/features/schedule/data/schedule_repository.dart`: `_current` w istniejącej
  guarded write transaction szuka terminu pod **wyświetloną datą** i wymaga
  identycznego pełnego baseline. Wspólne `move`, `complete`, `completeExternal`
  odmawiają przy zmianie źródła/override, przesunięciu, zmianie nazwy/targetu,
  move-away-back, wcześniejszym wykonaniu lub zniknięciu wirtualnego terminu.
  Brak baseline również odmawia zapisu. Publiczne sygnatury tych metod bez zmian.
  Świeżo odczytane zapisane wyjątki/historia nadal pozostają dostępne po
  usunięciu źródłowej reguły; usunięta reguła nie odtwarza wirtualnych terminów.
- `lib/features/schedule/presentation/widgets/today_schedule.dart`: start używa
  tego samego pełnego porównania zamiast wcześniejszego częściowego. Dialogi
  wykonania i date picker nadal przekazują oryginalnie uchwycony occurrence,
  bez recapture tuż przed zapisem. Oba wejścia Dziś i tydzień dzielą te akcje.
- Nowy `test/features/schedule/schedule_stale_occurrence_test.dart`: 30
  rzeczywistych testów DB (external/FitBirek/legacy × move/move-back, rewizja,
  nazwa i target źródła/override, disabled/deleted). Weryfikują odrzucenie
  **obu** operacji move i complete, niezmieniony cały harmonogram oraz dokładne
  wiersze outboxa, a następnie udaną akcję ze świeżego snapshotu.
- `test/features/schedule/activity_today_test.dart`: real-router regresje obu
  wejść Dziś dla zmiany terminu podczas otwartego date pickera, dialogu external
  i potwierdzenia rzeczywistej sesji FitBirek. Move-away-back nie odnawia zgody;
  odrzucona akcja nie zmienia outboxa/wykonania, jawne ponowienie po odświeżeniu
  działa. Kontrola braku nowych sesji/serii pozostaje.

TDD i weryfikacja w tym samym przypiętym Dockerze:

- Repo RED: **12 FAIL / 6 PASS** przed implementacją,
  `/tmp/opencode/activity-stale-occurrence-red.log` — stare operacje przyjmowały
  nieaktualny termin; disabled/deleted już wcześniej poprawnie odmawiały.
- UI RED: **2 FAIL / 0 PASS**, `/tmp/opencode/activity-stale-dialog-red.log` —
  oba date pickery zapisywały mimo zmiany terminu w trakcie dialogu.
- Początkowy GREEN: **26 PASS**, `/tmp/opencode/activity-stale-occurrence-green.log`.
  Następnie rozszerzono macierz o jawne nazwy/targety i dodatkowe dialogi Fit.
- Końcowy `flutter test --no-pub --reporter expanded test/features/schedule`:
  **78 PASS / 0 FAIL**, następnie `flutter analyze --no-pub`: **No issues found**,
  exit0. Log: `/tmp/opencode/activity-stale-occurrence-final.log`.
- `git diff --check`: sukces. Bez generatora: modele są ręczne, bez zmian
  deklaracji Drift/Freezed/json_serializable. Schemat, generated, deps/lock,
  Web SQLite, backend i powiadomienia bez zmian. Bez commit/push/deploy.
