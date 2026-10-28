# Serie i indywidualne cele — Flutter Task3

Kontrakt storage: [training-sets-programs-data.md](training-sets-programs-data.md).
Klient główny; bez programu A/B (repo/UI to Task4), migracji i deklaracji
generatorów, zależności, wydania lub wdrożenia.

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
