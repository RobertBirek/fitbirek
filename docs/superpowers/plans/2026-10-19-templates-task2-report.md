# Zadanie 2 — wykonanie, postęp i usuwanie

## Zakres i stan drzewa

Implementacja w `/opt/fit`, na zastanym dirty tree. Przeczytano AGENTS,
specyfikację, plan, raport/interfejsy zadania 1 oraz working sets treningu,
prowadzenia, repeat, interwałów i recovery. Zachowano zmiany hotfixu 1.16.1
i zadania 1. Bez subagentów, commitów, wersjonowania, deployu, zapisów
produkcyjnych, zmian backendu, zależności i narzędzi Flutter/Dart.

Nie zmieniono tabel, migracji, modeli generowanych ani wire schemaVersion.
Nie było deklaracji Drift/Freezed/json_serializable wymagających generatora.
Zmiany kodeków domenowych są ręczne. Wersja pozostaje zastanym hotfixem,
a nie nowym wydaniem zadania 2.

## Usuwanie

`workout/data/session_actions_repository.dart`:

- `capture(id)` zwraca `SessionEdit`: pełny wiersz sesji, żywe serie,
  surowe lokalne szkice, trwały binding account/device/offlineAccess i epoch
  pasywnej authority. Capture wykonywany **przed** potwierdzeniem.
- `check(edit)` porównuje pełne wartości Drift, a nie tylko UUID/datę.
  Dopisanie/usunięcie/zmiana serii albo zmiana szkicu unieważnia dialog.
  Odmawia przy deferred i push hold/pull quarantine. Sprawdza również nowe
  niewidoczne jeszcze dzieci przez parent UUID w deferred/quarantine payloadzie
  i powiązane attempted operacje w outboxie. Nie wymaga inicjalizacji auth/HTTP.
- `delete(edit)` w jednej transakcji zapisuje tombstone sesji i **każdej żywej
  serii**, usuwa lokalne szkice i kolejkuje komplet DELETE. Nie usuwa fizycznie
  sesji/serii, nie nadaje nowych UUID i nie przepisuje attempted operacji.
  DELETE sesji ma legacy czteropolowy payload, nie dekoduje uszkodzonego guidance.
- Końcowy guard konta, epoch i device bindingu po SQL wycofuje również już
  wykonane modyfikacje oraz outbox. Powtórny/stary snapshot jest odrzucany.

`SessionDeleteButton` jest współdzielony przez aktywną sesję, historię,
podsumowanie i recovery. Potwierdzenie zawiera datę, liczbę żywych serii,
informację o szkicu/synchronizacji oraz wyraźne wyjaśnienie: źródłowy szablon
i oddzielnie zapisane PR pozostają. **Nie ma heurystyki kasowania PR po dacie**,
bo historyczny model nie ma session FK. Busy chroni podwójny callback; po
delete nawigacja wymaga nadal pierwotnego epoch. Reset RAM dotyczy wyłącznie
tego samego session UUID, nie innej równoległej aktywnej sesji.

Statystyki/trendy korzystają z istniejących filtrów tombstone; test realnej
historii trendów potwierdza zniknięcie wykonania po usunięciu.
`ScheduleRepository._actualSession` już wymaga żywego, zakończonego rodzica
i żywej serii. Zachowano ten kontrakt: referencja ukończenia staje się
`invalidated`, nie jest przepisywana poza guarded workflow profilu. Istniejąca
regresja harmonogramu po usunięciu sesji przechodzi.

## Zakończenie i pusta sesja

`WorkoutRepository.finishSession` wymaga co najmniej jednej żywej serii
**w tej samej transakcji**, co koniec sesji, notatka, usunięcie szkicu i outbox.
Wybranie ćwiczenia/targetu, skip ani upływ czasu nie wystarczają.
`EmptyWorkoutSession` nie tworzy zakończonego rekordu. Zasada obejmuje również
`finishPendingSession`, uszkodzone guidance i recovery bez szkicu.

`SessionFinishButton` wydziela dialog z dużej strony aktywnego treningu:

- Flush istniejącego szkicu, capture realnego wykonania, konto/epoch przed i po
  await, ponowne optimistic sprawdzenie przy zapisie.
- Pusta sesja: Wróć, kopia celów/wyboru do edytora szablonu i jawne
  **Odrzuć pusty trening**, korzystające z powyższego potwierdzenia usunięcia.
  Samo otwarcie edytora nie zapisuje szablonu, sesji ani serii.
- Guidance daje oryginalny snapshot celów. `empty_session_template.dart`
  proponuje jawnie opisane, edytowalne defaulty dla nowego wyboru. Repeat
  kopiuje tylko bezstratnie zgodne cele; różne dawki, strony, warianty,
  nieobsługiwany tracking i brak metadanych powodują odmowę kopii zamiast
  cichego pominięcia. Limit 90 min pozostaje. Odrzucenie pustego treningu
  pozostaje dostępne również przy odmowie konwersji.
- Dla niepustej sesji: realny postęp i liczba brakujących serii, zgoda na
  częściowy trening, ostrzeżenie o odrzuceniu niezapisanych formularzy i
  wyników timera oraz opcjonalna notatka. Podwójny finish nie tworzy kolejnego
  zapisu. Błąd walidacji nie pozostawia notifikatora w permanentnym closing.
- Recovery zachowuje dotychczasowy zapis czasu, nie dolicza czasu nieobecności.
  Potrafi skopiować również poprawny lokalny pusty wybór/repeat do szablonu.

Wykryta integracyjna poprawka zadania 1: `SaveAsTemplateButton` ma opcjonalny
`beforeNavigate`. Zamknięcie dialogu **przed** push do shell navigatora pozwala
faktycznie edytować kopię; bez tego modal pozostawał nad edytorem. Dotychczasowi
użytkownicy przycisku nie wymagają zmian. Test prawdziwego routera przechodzi.

## Postęp

`domain/workout_progress.dart` jest czysty i nie zapisuje danych:

- guidance: unikalne żywe UUID z `performed`, osobno na blok, z limitem
  prescription.sets każdego bloku; skip nie zwiększa wykonania;
- repeat: przecięcie unikalnych `repeatCompleted` z żywymi UUID, z limitem celu;
- dodatkowe wykonanie nie podbija innego celu; procent maksymalnie 100%;
- swobodny trening pokazuje liczbę serii, bez wymyślonego procentu.

Aktywna sesja używa rzeczywistego streamu serii przez provider Riverpoda;
podsumowanie i historia korzystają z tego samego modelu. Guidance ma trwały
snapshot i może pokazywać uczciwy częściowy procent po zakończeniu. Historyczny
repeat bez lokalnego szkicu **nie** udaje trwałego zapisu celu/procentu —
pokazuje serię/liczbę wykonania. Nie dodano pól chmurowych tylko dla procentu.

## Dodatkowe ćwiczenia i ciężar

- „Dodaj ćwiczenie z bazy” jest dostępne także w repeat, również po zalogowaniu
  wszystkich targetów. `plannedExerciseIds` obejmuje oryginalne ID repeat.
- Repeat renderuje osobną sekcję EXTRA z istniejącymi `_ExerciseLogCard`.
  EXTRA `logSet` nie waliduje/nie przesuwa repeatTarget i nie dopisuje
  `repeatCompleted`. Numerowanie nadal pochodzi z transakcyjnego odczytu SQL.
- Identyczne już wybrane ćwiczenie nie jest powielane; jest jawny komunikat
  zachowania celów i formularza. Nie ma przełączania na inną sesję.
- Formularze EXTRA, dokładny side/variant i checkpoint przechodzą przez
  istniejący trwały namespace, CAS, tokeny checkpointów i kolejkę szkiców.
- **Nowy test interwałów repeat wykrył rzeczywisty błąd integracji:** stary
  warunek `consumesDraft == guidance != null` zapisywał dodatkowe rundy, ale
  pozostawiał checkpoint repeat do ponownego zaoferowania. Warunek obejmuje
  teraz EXTRA także bez guidance; dokładny checkpoint jest atomowo zużywany
  wraz z seriami/outboxem. Binding timera EXTRA jest weryfikowany również
  bez guidance. Istniejące CAS/in-flight/rollback testy pozostają zielone.
- Opcjonalne kg z zadania 1 jest defaultem wyłącznie dla nowego pustego
  formularza; wpisany/saved ciężar oraz niepusty własny szkic mają pierwszeństwo.
  Kodek `WorkoutGuidance` dopuszcza teraz `weightKg` w allowliście prescription
  (wcześniej odrzucał poprawny nowy snapshot); walidacja finite/nonnegative
  nadal pochodzi ze StructuredPlan. UI test potwierdza 12 kg → własne 7 →
  restart/resume → 7, bez nadpisania przez cel.

## Testy i zachowanie istniejących fixture

Nowe pliki testów: `session_actions_test.dart`,
`session_execution_widgets_test.dart`, `workout_progress_test.dart`,
`empty_session_template_test.dart`.

Dowody obejmują prawdziwy Drift: delete+draft+outbox, attempted bytes,
pozostawienie PR, optimistic set/draft races, A–B–A i device binding,
auth rollback po SQL, deferred nowych dzieci, push hold/pull quarantine,
push ACK/pull tombstone, reopen pliku i late-child cascade DELETE, trendy,
puste finish/recovery bez fake completion. Prawdziwe UI/router: repeat →
katalog → nowy EXTRA → formularz → restart → zapis EXTRA i targetu bez
mieszania postępu; checkpoint EXTRA repeat → restart → jawny zapis rund bez
przesunięcia targetu; empty/back/template/discard; partial warning/notatka;
A–B–A podczas otwartego dialogu nie zapisuje starej notatki ani zakończenia.

Istniejące testy, których fixture kończyło pustą sesję jako setup, dostosowano
do nowego kontraktu — **nie osłabiono walidacji repozytorium**:

- workout/recovery/router mają rzeczywiście zapisaną serię, gdy badają
  poprawny finish. Asercje braku nowych zapisów porównują pełny baseline serii.
- protokołowe testy sync mają `test/helpers/recorded_workout_fixture.dart`:
  wcześniej przechowywana seria bez nowej operacji outboxa; dzięki temu
  asercje kolejności/liczby session envelopes i attempted bytes są niezmienione.
  Test Mentora zmienia tylko fixture i porównuje niezmieniony baseline,
  nie implementację Mentora.
- cleanup pustego fixture interwałów używa tombstone, nie fikcyjnego finish;
  finish wygrywający z wycofanym pierwszym batchem oczekuje jawnej odmowy
  pustej sesji. Negatywne asercje rollbacku pozostają.

RED w przebiegach rzeczywiście wykazał odrzucenie weightKg przez guidance,
edytor ukryty pod modalem i niezużyty repeat checkpoint. Poprawki potwierdzono
ponownym GREEN. Nie deklarujemy pełnego test-first dla całego zakresu:
część regresji dodano i uruchomiono już po pierwszej implementacji.

## Weryfikacja końcowa

Istniejący obraz `fit-web:release-1.13.0-26-verified`, Flutter 3.35.4/Dart 3.9.2,
`--network none`, roboczy klient `/opt/fit:/app`, bez budowania obrazu:

```sh
docker run --rm --network none -v /opt/fit:/app -w /app \
  fit-web:release-1.13.0-26-verified bash -lc '
    dart format lib/features/workout/providers/workout_providers.dart &&
    flutter analyze --no-pub &&
    flutter test --no-pub -r expanded \
      test/features/workout test/features/schedule \
      test/features/planner/manual_templates_test.dart \
      test/features/planner/session_template_test.dart \
      test/features/planner/templates_widgets_test.dart \
      test/features/planner/planner_workflow_test.dart \
      test/core/sync_service_test.dart test/core/sync_audit_test.dart \
      test/core/deferred_sync_test.dart test/core/sync_persistence_test.dart \
      test/features/mentor/mentor_actions_test.dart'
```

**348 passed**, pełne `flutter analyze --no-pub`: **No issues found**.
Log: `/tmp/opencode/task2-final-verified2.log`. Format wcześniej wykonano
wyłącznie dla plików zmienianych w zadaniu; końcowy `git diff --check` czysty.
Suite zawiera również istniejące regresje 320px/text200, continuity hotfixu,
guided extras i tokenów/CAS szkiców. Ostrzeżenia Drift multiple-database
pochodzą z testów tworzących kilka baz; nie było failed testów.

Lock i Web SQLite niezmienione, zgodna dotychczasowa para Drift **2.28.2** /
sqlite3 **2.9.4**:

- `web/sqlite3.wasm`: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- `web/drift_worker.dart.js`: `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

## Ograniczenia / integracja

Nie uruchamiano pełnej suite aplikacji ani backendu, compiled-browser/PWA,
telefonu, runtime builda czy deployu. Focused GREEN nie jest akceptacją wydania.
Pozostaje zwykła integracyjna pełna suite zadania 4. Nie ma gwarancji flush
przy zabiciu procesu i synchronizacji lokalnych, niezapisanych formularzy.
PR pozostają samodzielnymi rekordami. Repeat bez szkicu nie uzyskuje nowego
trwałego modelu celu. Nieobsługiwane/lossy kopie wyjaśniają odmowę zamiast
zmyślać wykonanie lub redukować historię. Zastane pliki release/wersji/deployu
i zadania 1 pozostają niezatwierdzonymi zmianami ich właściciela.

## Korekta po review P2 — opcjonalne kg także przy czasie i masie własnej

Zweryfikowano zgłoszenie: samo wczytanie `prescription.weightKg` do kontrolera
nie wystarczało. `_usesWeight` ukrywało pole dla time/rounds i ćwiczeń z masą
własną, `_logTimedSet` pomijało kg, a capture interwałów nie miało pola obciążenia.

Zakres tej korekty jest ograniczony do `active_session_page.dart`,
`workout_providers.dart`, nowego `template_weight_execution_test.dart` i raportu:

- Niepuste opcjonalne kg **w snapshocie celu szablonu** udostępnia widoczne,
  edytowalne pole ciężaru także dla time/rounds i bazowych bodyweight reps.
  Pole pozostaje dostępne po świadomym wyczyszczeniu wartości. Zwykły time
  bez target kg nie dostaje wymuszonego obciążenia ani nowego pola.
- Ręczny zapis sekund/rundy oraz stoper przekazują potwierdzone opcjonalne kg;
  pusty string oznacza `null`. Walidacja odrzuca wartości ujemne i niefinite.
- `captureInterval(weightKg:)` przechwytuje zwalidowany ciężar jako
  niemutowalną wartość `IntervalWriteOrigin`. Każda jawnie zapisana runda,
  jej outbox i wpis RAM dostają tę wartość. Sekundy nadal nie generują PR/1RM.
- Nie zmieniono defaultów szkiców: zapisany pusty string ma pierwszeństwo
  przed kg celu, także po odtworzeniu providerów/resume. Nie ma ponownego
  podłożenia 12 kg po świadomym wyczyszczeniu pola.

**RED przed zmianą produkcji:** nowy zestaw miał **7 failed, 1 passed**:
brak widocznego pola w sześciu wariantach, interwał zapisywał `null` zamiast
edytowanych 5 kg. Log: `/tmp/opencode/task2-weight-review-red.log`.
**GREEN:** wszystkie **8 nowych testów** przechodzą. Obejmują time
30 s / cel 12 kg, bodyweight reps i rounds: widoczne 12 kg → edycja na 7
albo wyczyszczenie → trwały szkic → nowe providery/resume → zapis dokładnych
kg/null i pomiaru. Interwały z celem rounds zapisują jawnie 10 s / 5 kg lub
null po wyczyszczeniu, bez PR. Istniejące testy zwykłych time/reps/rounds
bez celu kg nadal wymagają braku pola ciężaru i przechodzą.

Końcowe polecenie, ten sam istniejący obraz i `--network none`:

```sh
docker run --rm --network none -v /opt/fit:/app -w /app \
  fit-web:release-1.13.0-26-verified bash -lc '
    dart format test/features/workout/template_weight_execution_test.dart &&
    flutter analyze --no-pub &&
    flutter test --no-pub -r expanded test/features/workout \
      test/features/planner/templates_widgets_test.dart \
      test/features/planner/session_template_test.dart'
```

**252 passed**, analyze: **No issues found**, `git diff --check` czysty.
Log: `/tmp/opencode/task2-weight-review-focused2.log`. To nowy, węższy focused
przebieg po review, nie ponowienie wcześniejszych 348 ani pełnej suite.
Lock i oba SHA-256 Web SQLite pozostały identyczne z powyższymi. Bez zmiany
deklaracji generowanych, schematu, wersji, backendu, deployu i commitów.
