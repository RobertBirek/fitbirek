# Bezpieczne zamienniki, przerwy i estymacja czasu

## Working set

- `lib/features/planner/domain/exercise_training_policy.dart`: współdzielona,
  częściowa klasyfikacja funkcji ruchu, zgodności i domyślnych przerw.
- `structured_plan.dart`: generator, `replacementCandidates`, `replace`,
  niemutujące `withRest` i `proposeBlocks`.
- `plan_explanation.dart`, `planner_page.dart`, `widgets/plan_edit_dialog.dart`:
  uzasadnienia i świadoma akceptacja zmian podglądu.
- `lib/features/workout/preparation/domain/workout_preparation.dart`: ta sama
  zgodność zamienników, zachowanie dawki slotu i usunięcie poprzedniego ciężaru.
- `workout/presentation/pages/active_session_page.dart`,
  `widgets/active_replacement_dialog.dart`, `providers/workout_providers.dart`,
  `data/workout_repository.dart`: aktywna zamiana i atomowy stan recovery.

Czytaj też `training.md`, `structured-planner.md`, `plan-explanations.md`,
`workout-preparation.md` i `guided-training.md`. Poniższy kontrakt zastępuje
historyczny wymóg identycznego czasu zamiany i stałych przerw 30 s.

## Zgodność ruchowa

`ExerciseTrainingPolicy.compatible` wymaga rozpoznanej identycznej rodziny,
sekcji, trackingu i jednostronności oraz niepustych, równych zbiorów
`primaryMuscles`. Mięśnie wspierające, ten sam pierwszy człon nazwy wzorca
lub wspólna szeroka partia nie wystarczają. Charakter regeneracji/jogi jest
sprawdzany zarówno z typu, jak i stylów metadanych.

Mapa jest jawna i częściowa: rozróżnia push/pull poziomy i pionowy,
squat/hinge/lunge, wybrane izolacje, stabilizacje i wąskie funkcje ruchowe.
Nieznane lub ogólne wzorce (`Push`, `Pull`, `Ruch złożony`, `Flow`,
`Kontrolowany ruch`, `Triceps`) nie są dowodem zgodności. Nie używać cwID
ani dopasowania pierwszego słowa do zgadywania funkcji.

Planner i przygotowanie nadal wymagają zgodności z bieżącą filtrowaną pulą,
poziomem i całymi alternatywnymi zestawami sprzętu (OR zestawów, AND wewnątrz).
Wykluczają zajęte ID. Brak weryfikowalnego zamiennika oznacza odmowę, a nie
rozszerzenie puli. Wybór jest deterministyczny.

## Domyślne przerwy

Jeden resolver obsługuje zarówno dawkę rozpoznaną z katalogu, jak i fallback.
Kolejność reguł:

1. Sekcja pomocnicza lub typ regeneracja/mobilność/joga: 0 s.
2. Wytrzymałość i izometria: 30 s.
3. Explosive: 120 s.
4. Jednoznaczna izolacja: 60 s.
5. Rozpoznana rodzina wielostawowa: Siła 120 s, Hipertrofia 90 s.
6. Brak rozstrzygnięcia: 30 s z jawnym ostrzeżeniem fallbacku.

Są to edytowalne ustawienia generatora, nie indywidualne zalecenie medyczne.
Nie przeliczać dawnych snapshotów przy odczycie.

## Zmiany podglądu

`replace` odczytuje dawkę nowego ćwiczenia i usuwa nieprzenośny ciężar.
Pozostałe bloki są zachowane. `withRest` zmienia wyłącznie `restSeconds`
wybranego bloku (nowe wartości 0–600 s), zachowując m.in. `weightKg`.
Usuwa tylko ostrzeżenie domyślnej przerwy edytowanego bloku. Dawne większe
przerwy zachowują dotychczasowy kontrakt odczytu wire.

Nie wymagamy identycznego czasu zamiennika. Nadal obowiązuje:

`sets * workSeconds + (sets - 1) * restSeconds + transitionSeconds`.

Estymacja powtórzeń nadal wynosi 3 s; ćwiczenia jednostronne uwzględniają obie
strony. Nie jest to pomiar czasu ani interpretacja pola tempo. Przy jednej
serii zmiana przerwy nie zmienia estymacji bloku.

Domyślnie propozycja przekraczająca budżet jest odrzucana. Opcjonalne
`allowBudgetIncrease` dopuszcza poprawny snapshot z budżetem zaokrąglonym
w górę do minuty (co najmniej stary budżet, nie więcej niż 5400 s).
Dialog pokazuje pełny czas i budżet przed/po; zwiększenie wymaga osobnego
checkboxa, resetowanego po zmianie wartości. Ponad 90 min oznacza odmowę.
Nie skracamy innych przerw/serii ani nie usuwamy ćwiczeń po cichu.

Akceptacja zmienia tylko lokalny podgląd, po ponownym sprawdzeniu konta,
planu, katalogu, metadanych/silnika i profilu. Anulowanie nie zapisuje niczego.
Save/start nadal mają osobne potwierdzenia i walidację.

## Aktywna sesja i recovery

Aktywna zamiana korzysta z `replacementCandidates` i wyłącznie nowego ID,
nie z nowej dawki `replace`. Weryfikuje aktualne źródła i sprzęt profilu;
brak załadowanych danych nie uprawnia do użycia szerszego fallbacku.
Oryginalny snapshot celów, zapisane serie i ich UUID pozostają niezmienione.
Nie edytujemy przerw aktywnej sesji w tym etapie.

Dodatni `weightKg` oryginalnego celu blokuje aktywną zamianę: użytkownik
powinien zmienić ćwiczenie przed startem albo dodać osobne. Nie przenosimy
indywidualnego ciężaru na inny ruch. Dialog wymaga jawnego odrzucenia
bieżącego formularza, strony, wariantu i niezapisanych wyników timera.
Inne szkice pozostają. Anulowanie niczego nie czyści.

`guidedEvent` blokuje przejście podczas consume/busy, sprawdza źródłowy stan
i lease UI, a kolejkę szkiców opróżnia przed transakcją SQLite.
`WorkoutRepository.transitionGuidance` sprawdza oczekiwaną sygnaturę guidance,
rewizję szkicu i slot; w jednej transakcji zapisuje zdarzenie/outbox, nową
sygnaturę szkicu, celowane wyczyszczenie formularza oraz rewizję i tokeny
bieżącego checkpointu. Zachowuje niezwiązane formularze i tokeny.
Utrata guarda wycofuje całą operację. Obserwator rozróżnia własny zapis
i odroczone zmiany innego writera; RAM przyjmuje zatwierdzony payload.

Brak nowych pól zdarzenia `replaced`, nowego wire, migracji, zależności ani
zmian katalogu. Recovery pozostaje lokalne; test odtworzenia providerów
i SQLite nie oznacza gwarancji flush po zabiciu procesu przeglądarki.

## Testy

- Domain: `training_policy_test.dart`, `preview_edit_test.dart`,
  `catalog_prescription_test.dart`, `structured_plan_test.dart`.
- Planner UI: `preview_edit_widgets_test.dart`, `plan_explanation_test.dart`,
  `plan_explanation_widgets_test.dart`.
- Workout: `active_replacement_safety_test.dart`,
  `active_replacement_widgets_test.dart`, istniejące continuity/recovery
  oraz `test/features/workout/preparation/`.

Sprawdzać zwłaszcza: rzeczywiste niejednoznaczne rekordy katalogu, secondary
zamiast primary, typy/styl regeneracyjny, jednostronność, komplet sprzętu,
różne dawki/czasy, jedną serię, 90 min, cancel, nieaktualne dialogi,
atomową sygnaturę po ponownym otwarciu bazy i brak przeniesienia timera/kg.

## Weryfikacja implementacji

Kod `360fa58` na gałęzi `feat/planner-safe-replacements`, Flutter 3.35.4 /
Dart 3.9.2, przeszedł niezależny review wraz z poprawkami stale baseline
i akcji bezpośrednio po recovery. Końcowe wyniki na aktualnym źródle:

- Planner/workout: 568 testów zaliczonych.
- Pełne `flutter test --no-pub --reporter expanded`: 1667 zaliczonych,
  1 istniejący test pominięty; bez błędów (7 min 2 s).
- `flutter analyze --no-pub`: bez uwag; kontrola wersji aplikacji poprawna.
- Format 23 zmienionych plików Dart: bez zmian; `git diff --check` poprawny.
- `flutter build web --release --no-pub --no-web-resources-cdn`: poprawny
  standardowy build Web. Dry run Wasm nadal ostrzega o istniejących
  zależnościach `flutter_secure_storage_web`/`js`; nie jest to build Wasm.

Testy używały istniejącego obrazu
`fit-web:verification-1.23.1-40-illustrations-candidate`, z read-only mountem
aktualnego worktree skopiowanym do roboczego `/app`. Web budowano osobno,
pobierając brakujący SDK Web dokładnie tej samej przypiętej wersji Fluttera.
Nie testowano działania w prawdziwej przeglądarce/PWA ani zabicia procesu telefonu.
Bez publikacji, wdrożenia, zmiany wersji, zależności i artefaktów Web SQLite.
