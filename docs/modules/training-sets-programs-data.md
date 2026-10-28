# Serie i programy — kontrakt danych etapu3

## Storage i role

Drift14→15 dodaje wyłącznie nullable `SetsLog.setRole` (CHECK NULL/working/warmup)
i `UserProfiles.trainingProgramsJson`. Bez backfillu. `SetLog.setRole` pozostaje
String?, JSON i nowe outgoing legacy nie dopisują NULL ani working.
`WorkoutRepository.logSet(setRole: ...)` waliduje i zachowuje jawny wybór.
`SetRole.isEffectiveWorking(null)` oznacza zgodność historyczną, nie dowód roli.

Historia i backup pokazują/eksportują wszystkie serie. Wyłącznie odczyty dowodów
last/progression/preparation/trend używają `effectiveWorkingSets` (working lub
NULL). `getAllSetsForExercise(..., effectiveWorkingOnly: true)` jest adapterem
dla detektora PR; bez flagi pozostaje pełną historią. UI/provider musi odrzucić
tworzenie nowych PR dla warmup. Dawnych rekordów osobistych nie przeliczamy.

Pull workoutSet: omission żywego snapshotu zachowuje rolę, explicitNULL resetuje,
revival tombstone'a nie dziedziczy. Attempted requesty są wyłącznie odczytywane.

## Lista celów v2

`SetPrescription({required targetId, required setRole, side, reps, seconds,
weightKg, required workSeconds, required restSeconds})`,
`fromJson(map, tracking: ...)`, `validate(tracking)` i `toJson()`.
`seconds` to cel faktycznego czasu; `workSeconds` to jawna estymacja, także stron.
Tracking bloku reps/time; rounds pozostaje schema1. ID1–80 znaków, max100 celów,
unikalne ID w bloku. Granice operandów przed sumą; budżet nadal max5400s.
Przerwa ostatniego celu nie jest doliczana do przejścia.

`PlanPrescription.perSet(tracking:, setTargets:, transitionSeconds:)` ma
immutable ordered `setTargets` jako jedyną dawkę. `sets` jest wyliczane;
scalar reps/weightKg zwracają NULL, workSeconds/restSeconds rzucają StateError,
aby stary adapter nie spłaszczył rampy. `isPerSet` rozróżnia ścieżki.
`StructuredPlan(schemaVersion: 2, ...)` wymaga takich dawek wszystkich bloków.
Legacy API/default wersji1, JSON i podpis guidance pozostają niezmienione.
Generator nadal tworzy v1. Scalar `withRest` i generacyjne `replace` v2 zwracają
null (jawna odmowa); edytor musi zmieniać konkretne cele, nie średnią listy.
Także kodek/`WorkoutGuidance.replace` odmawiają aktywnej zamiany v2, jeśli
jakikolwiek cel ma dodatni ciężar; nie wystarcza ukryć przycisk UI.

`WorkoutGuidance.schemaVersion` odpowiada planowi. `link(slot,setSyncId,
targetId:...)` i `skipTarget(slot,targetId)` wymagają istniejącego celu v2,
zużywanego najwyżej raz. Skip nie jest dowodem wykonania. Legacy skip/link
zachowują dotychczasowy format. `WorkoutRepository.logSet(guidanceSlot:,
guidanceTargetId:, setRole:, side:)` sprawdza dokładną rolę/stronę celu i zapisuje
set/link/outbox atomowo; doubletap wycofuje całą drugą transakcję. Warmup pod v1
jest dodatkowy i nie dostaje linku working. `guidanceEvent(targetId:)` obsługuje
jawny skip; recovery transition/form/timer pozostaje do podłączenia przez UI.

Repeat rzeczywistego wykonania zachowuje nullable role. Kopia jednorodnych
legacyNULL pozostaje v1. Różne dawki lub jawne role dają v2 bez uśredniania,
wyłącznie gdy wszystkie serie mają jawną rolę. Jeśli v2 wymagałoby odgadnięcia
historycznego NULL, kopia odmawia i prosi o ręczne cele zamiast nadać working.
Kopia odmawia stron/wariantów/mieszanych jednostek i niejednoznacznych
jednostronnych danych. Ostrzeżenie mówi o niezmierzonych przerwach (0s).

## Kolekcja programów

`trainingPrograms: {version:1, entries:[...]}` używa wspólnej koperty UUID/name/
createdAtUtc/updatedAtUtc/deletedAtUtc i limitów500 wraz z tombstone/262144B.
`TrainingPrograms.validateEntry`, `fromJson/toJson/entries`, `snapshot(program)`,
`occurrenceId(programId,CalendarDay)`, `requireCompatible/requirePreserved`.

Program: `kind:program`, `planSyncIds:[A,B]`, `weekdays:[1..7]`,
`effectiveFromDate`, opcjonalnie raz ustawiony `endBeforeDate` (exclusive).
Override: `kind:programOverride`, `programId`, `originalDate`, `movedDate`,
`state:planned|completed`, sessionSyncId tylko dla completed, `programSnapshot`.
Snapshot zawiera `name/planSyncIds/weekdays/effectiveFromDate/[endBeforeDate]`,
bez koperty ID/timestamps. UUID wyjątku = UUIDv5(programId,originalDate).

Core programu jest niezmienny; weekdays porównujemy jako zbiór, plany w kolejności
A/B. Merge sprawdza oba revisions przed LWW, także tombstone i przegrywający
revision. Omission zachowuje cutoff, dwie różne granice/explicitNULL granicy są
konfliktem. Wyjątek ma niezmienne programId/originalDate/snapshot. Nie wolno
prune definicji ani wyjątków przez generyczne update. NULL pustej kolekcji jest
obsługiwane; NULL nie może wymazać istniejącej historii programu/granicy.

Wszystkie kolekcje mają wspólną ścieżkę walidacji/merge/CAS/hold, bez fallbacku
do exerciseVariants. Błędna/nowsza kolekcja zostaje raw; nowe zapisy odmawiają,
CAS zachowuje attempted i remote raw w trwałym profile hold. Programowe repo
ma jeszcze sprawdzić dostępność dwóch planów, dzisiejszą granicę zakończenia,
kalendarz i jawny dowód ukończonej sesji — kodek nie wykonuje zapytań katalogu.

## Backup4 i raw quarantine

Nowy eksport4; import1–3 pozostaje. Restore tworzy nowe UUID plan/session/set,
mapuje guidance.setSyncId, zachowuje targetId. Programy z archiwum są kopiami
z nowymi UUID i przeliczonymi UUIDv5 wyjątków. Plany, sesje i snapshoty korzystają
z tych samych map. Dawne lokalne programy pozostają bez zmiany immutable core.
Role, tombstone, cutoff są zachowane. Brak mapy lub limit całego merge odmawia
całego importu transakcyjnie. Oryginalnych bajtów pliku nie zmieniamy.
UUID mapy respektują wielkość liter UUID, a link serii musi należeć do tej samej
sesji. Legacy archiwum bez całego profilu nie usuwa istniejących kolekcji:
zachowuje wtedy ich dotychczasową kopertę profilu.

Ochrona raw nie oznacza konwersji przyszłego schematu. Nieczytelny lokalny
plan/guidance/kolekcja odmawia destrukcyjnego restore; eksport nadal zachowuje
raw. Incoming nieobsługiwany plan używa dotychczasowego `SyncQuarantine` w
syncDeferredRecords (z hold dla zapisu), guidance ma kwarantannę w wierszu.

Eksport4 zawiera również `data.syncRecovery:{deferredRecords,outbox}` z pełnymi
raw strings i attempted payloadJson. Import zachowuje tę sekcję jako **bierne
dowody**, w `_backupRecoveryArchive` istniejącej tabeli deferred, z nowym UUID.
Nie są to przenośne uprawnienia do retry starego konta ani normalne operacje;
istniejący deferred/outbox nie jest resetowany. Reeksport obejmuje też te
archiwa. Rozstrzygnięcie nieznanych outcomes nadal wymaga jawnego recovery.

Bez UI/providera prowadzenia lub repo/UI programów, bez zmiany zależności,
katalogu, artefaktów Web SQLite, wersji, backendu i wdrożenia. API-first oraz
plan aktualizacji starych klientów są konieczne przed przyszłą publikacją.

## Weryfikacja Task2

Flutter3.35.4/Dart3.9.2, bieżące źródła RO→robocze `/app` w istniejącym
`fit-catalog-program-tests`. CodegenPASS, trzy własne generatedDart w repo.
Focused data/core/sync/workout/planner/backup/progression/trends/migration:
**842PASS**, analiza **No issues found**, versioncheck/diffcheck/formatPASS.
Osobny kontraktowy zestaw:36PASS (34nowe +2dotychczasowe template). Pełna
suity klienta i prawdziwy runtime/browser pozostają do integracji Task5;
niezależny review wykonuje sesja nadrzędna, nie implementer Task2.
