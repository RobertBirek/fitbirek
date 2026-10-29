# Serie i indywidualne cele — Flutter Task3

Kontrakt storage: [training-sets-programs-data.md](training-sets-programs-data.md).
Klient główny; programy A/B opisano w sekcji Task4 poniżej. Bez migracji
i deklaracji generatorów, zależności, wydania lub wdrożenia w zmianach UI.

## Edytor i start

- Nowe ręczne szablony tworzą schema2. Zapisane schema1 i v1 seeds pozostają
  schema1 do jawnego „Ustaw osobne cele serii”. Ta akcja odmawia rounds oraz
  ponad100 serii, zamiast zmieniać ich znaczenie.
- `PerSetDoseEditor`/`SetTargetForm` opakowują `SetPrescription` kontrolerami.
  Rola, strona, reps/czas, kg, estymowana praca i przerwa są osobnymi polami.
  Dodanie nadaje UUID celu; reorder zachowuje UUID. Cancel nie zapisuje.
  Granice, budżet i optimistic/account lease pozostają obowiązujące.
- `validatePerSetCatalog` sprawdza istnienie ćwiczenia, aktualny tracking i
  dokładną semantykę stron: jednostronne wymagają left/right/both, pozostałe NULL.
  Workflow ponawia walidację przy zapisie i starcie. Start v2 wymaga także
  zgodnej uporządkowanej listy ćwiczeń. Headless start nie rejestruje nowego
  długowiecznego strumienia katalogu w strefie krótkiej transakcji.
- Scalar edycja przerwy i generacyjna zamiana v2 pozostają jawną odmową;
  podgląd pokazuje pełną listę. Przygotowanie v2 jest read-only: pokazuje
  wszystkie cele, nie emituje `PreparedTarget`, nie pobiera historycznej sugestii
  do nadpisania całej rampy i nie oferuje zamiany przed startem. Domenowy i
  workflow guard odmawiają wspólnego ciężaru/reps dla takiego bloku.

## Prowadzenie i lokalne recovery

- `ActiveWorkoutState.currentTarget/currentTargetConsumed` identyfikują cel
  wyłącznie po targetId i zdarzeniach, nie po liczbie logów.
  `selectGuidedTarget(id)` zmienia wybrany cel, zachowując jego niezależny szkic.
  Wykonany/pominięty cel pozostaje widoczny i wybrany do jawnego wyboru kolejnego.
- `logSet(guidanceTargetId:)` może przechwycić expected ID starego widoku.
  Karta przekazuje tożsamość wyświetlonego formularza (UUID sesji, slot i targetId),
  nie pobiera nowego celu z RAM przy obsłudze starego callbacku. Callback starego
  formularza nie może zapisać rozgrzewki jako nowego roboczego celu ani nadpisać
  jego pól przed przebudową UI.
  V2 bierze rolę z celu, wymaga jego strony i wybranej tożsamości wariantu;
  rzeczywiste odstępstwa kg/reps/sekund pozostają odstępstwami, nie są poprawiane.
  Repo zapisuje performed+serię+outbox, a zewnętrzna transakcja także PR i
  aktualny podpis durable szkicu. Odmowa foreign/stale target wycofuje całość.
- `guidedEvent()` v2 pomija wybrany target, nie cały blok i nie wykonuje go.
  Repo `transitionGuidance(targetId:)` utrwala zdarzenie, szkic i tokeny CAS razem.
- Lokalny payload nadal ma schemaVersion1. Wyłącznie v2 dodaje `fields.targetId`,
  `guidedTargets[slot]` i `guidedSelections[JSON([slot,exercise,targetId])]`.
  Dokładny klucz formularza/checkpointu v2 to
  `JSON(['guided',sessionUUID,slot,exercise,side,variantId,targetId])`.
  Sześciopolowe guidedv1 i pięciopolowe EXTRA nie są przepisywane.
- `IntervalWriteOrigin.targetId` i `timerBinding.targetId` wiążą v2 timer z
  celem. Jeden target dopuszcza jedną rundę. Obcy wariant, cel, stary token,
  nonce po consume albo multiround checkpoint nie otrzymują nowego uprawnienia.
  EXTRA zachowuje wielorundowy timer i nie dopisuje performed.
- Consume v2 porównuje dokładny klucz z aktualnie wybranym trwałym formularzem:
  stary widok A nie może wyczyścić nowszego timera B. Niezwiązane EXTRA, CAS
  revision/epoch/version, kolejka patchy i persistentDatabaseZone pozostają.
  Flush nadal musi być poza transakcją nadrzędną. Fresh provider może od razu
  zapisać/pominąć właściwy cel lub potwierdzić odzyskany timer, bez edycji pól.
  `saveIntervalRounds` v2 sam czeka na własne queued patche wyboru/checkpointu
  **przed** otwarciem transakcji. Po barierze ponawia guard origin i bierze wersję
  checkpointu z własnych zatwierdzonych zapisów; nie przyjmuje tokenu obcego widoku.
- Obserwowana zgodna zamiana inicjalizuje dokładny target nowej tożsamości,
  zamiast zostawiać szkic bez targetId. Odroczony performed-row ręcznego zapisu
  nie jest odtwarzany podczas późniejszego consume innego celu.

## Role i historia

Nowy manual/EXTRA ma jawny wybór Robocza/Rozgrzewkowa, default Robocza.
Origin interwałów zachowuje rolę. Powtórzenie wykonania zachowuje nullable rolę
źródła: legacyNULL nie staje się working. Warmup pod v1 pozostaje dodatkowy.
Powtórzenie oryginalnego snapshotu v2 inicjalizuje pierwszy dokładny target
w początkowym trwałym szkicu i ponawia walidację katalogu/metryki/stron przed startem.
Warmup nie uruchamia detektora PR. Baseline PR czyta effective-working historię
przed insertem kandydata i zachowuje dawne PR bez przeliczeń/usuwania.

Aktywny ekran i summary pokazują etykiety ról oraz konkretne cele, skippedTarget
i nieważny link po usunięciu dowodu. Historia nadal zawiera wszystkie serie;
NULL nie dostaje etykiety udającej dawną rolę. Agregacje evidence pozostają
filtrowane zgodnie z Task2. Czas sesji i estymacja nadal nie udają czasu pracy.

Nie jest to gwarancja flush po zabiciu procesu, chmurowy sync szkiców ani odbiór
fizycznego telefonu/PWA. Pełna suita i runtime acceptance należą do Task5.

## Programy A/B — Task4

- Wejścia z Moich szablonów i Rytmu tygodnia prowadzą do chronionego `/programs`.
  Tworzenie wybiera dwa różne dostępne zapisane szablony, nazwę, dni i lokalną
  datę. Starszy dostępny plan bez struktury pozostaje legacy, nie staje się v2.
  Brak planu/ćwiczenia, nieobsługiwany JSON, deferred lub quarantine blokuje start
  bez generatora zastępczego. Katalog i metadane v2 są walidowane ponownie.
- `TrainingProgramSchedule(TrainingPrograms).between(first,last)` rozwija do366
  dni **włącznie**. Ordinal liczy zaplanowane dni od effectiveFromDate, a nie
  wykonane sesje: pon/śr/pt ABA → BAB. Arytmetyka używa CalendarDay/UTC jako
  kalkulatora gregoriańskiego, nie24h od lokalnej północy. UUIDv5 programu
  i pierwotnej daty, plan A/B i snapshot pozostają po przesunięciu.
- `TrainingProgramsRepository` zapisuje wyłącznie istniejącą kolekcję profilu.
  `open` jest read-only lease konta/epoch/binding/profilu i pełnej rewizji
  programu; create dodatkowo przechwytuje baseline szablonów. `rename/end`
  nie zmieniają core; end ustawia raz wyłączną granicę nie wcześniejszą niż dziś.
  Zaległe daty wcześniejsze niż cutoff pozostają. Strukturalną zmianę wykonuje
  się przez zakończenie i nowy program z nowym UUID. Wyjątek korzysta wyłącznie
  z własnego snapshotu i nazwy, także po rename/end.
- Stream tygodnia obserwuje profil, konto, plany, sesje, serie i deferred,
  bez auth HTTP i bez zapisów podczas wejścia. Czytelny profil w hold pokazuje
  definicje, ale blokuje zmiany. Nieczytelny raw nie staje się pustą kolekcją.
- `WorkoutPreparationWorkflow.open(programOccurrence:...)` dodaje kontrolę
  programu do istniejącego read-only przygotowania i startu przez
  `PlannerWorkflow.startPrepared`. A→B→A, move-away-back, zmiana nazwy/granicy,
  edycja szablonu i hold unieważniają stare potwierdzenie. Aktywny snapshot v2
  jest niezależny od późniejszej edycji szablonu.
- `SessionCompletionProof` jest wspólnym namespace weekly/program. Jawne complete
  wymaga wybranej zakończonej live sesji i co najmniej jednej live serii
  effective-working (working lub historyczny NULL). Sam start/finish/upływ daty,
  empty/warmup-only nie zaliczają. Częściowy trening tylko przez jawny wybór
  i potwierdzenie użytkownika. Zapis odmawia ponownego użycia sesji w obu repo;
  offline merge zachowuje oba powiązania jako conflict. Usunięty dowód daje
  invalidated bez zmiany rotacji. Nie powstają kopie sesji/serii/PR.
- Ręczne operacje są serializowane w SQLite z optimistic/account guards;
  deferred profilu oraz generyczne `_syncPushHold`/`_syncPullQuarantine` profilu
  blokują zapisy i start bez naruszania raw lub attempted bytes. UI używa tych
  samych kontroli, blokuje doubletap i ma układ przewijalny320px/text200%.

Task4 nie zmienia storage/backup/sync serializerów z Task2, backendu, schematu,
lock/deps/Web SQLite, katalogu ani wersji. Nie dodaje przypomnień programowych.
Raport i dokładne komendy/wyniki: lokalny
`.superpowers/sdd/2026-10-28-training-sets-programs/task-4-report.md`.
Pełny Flutter i runtime/browser oraz niezależny odbiór pozostają w Task5.
