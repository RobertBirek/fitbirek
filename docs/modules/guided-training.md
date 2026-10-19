# Prowadzenie, lokalne wznowienie i plan a wykonanie

## Zakres i źródła

Klient w katalogu głównym; Flutter 3.35.4 / Dart 3.9.2. Bez wydania, zmiany
zależności, backendu, Alembic, nowych `SyncEntityType`, wariantów ani preferencji
chmurowych. Drift 12 pozostaje zarezerwowany dla następnego etapu.

- `lib/features/workout/domain/workout_guidance.dart`: snapshot i kodek,
  append-only zdarzenia oraz walidacja lokalnego szkicu.
- `lib/features/workout/data/workout_repository.dart`: transakcje sesji,
  powiązań serii, zdarzeń i lokalnych szkiców.
- `lib/features/workout/providers/workout_providers.dart`: aktywna sesja,
  guardy konta/generacji/UUID, uporządkowane checkpointy i wznowienie.
- `lib/features/workout/domain/interval_timer.dart`: checkpoint silnika.
- `lib/features/workout/presentation/pages/`: prowadzenie, Home, timer i summary.
- `lib/features/planner/providers/planner_providers.dart`: opcjonalny snapshot
  startu. Jedyna integracyjna zmiana w `planner_page.dart` przekazuje `plan:`;
  wyjaśnienia generatora nie są częścią tego etapu.
- `lib/core/{database,sync/sync_store.dart,services/backup_service.dart}`:
  migracja, optional wire, izolacja błędów i remapowanie UUID w backupie.

## Dokładny kontrakt Drift 10 → 11

Addytywnie, bez backfillu:

1. `workout_sessions.guidance_json TEXT NULL` / `WorkoutSessionData.guidanceJson`.
2. Lokalna tabela `workout_drafts`, `@DataClassName('WorkoutDraftData')`:
   `account_id TEXT`, `session_sync_id TEXT`, `payload_json TEXT`, klucz złożony
   `(account_id, session_sync_id)`. Nie korzysta z lokalnego integer ID jako
   tożsamości i nie jest synchronizowana ani eksportowana w backupie.

Generator: `dart run build_runner build --delete-conflicting-outputs`.
Wygenerowany `lib/core/database/app_database.g.dart` jest częścią zmiany.
Testy historycznych baz tworzonych z bieżącej deklaracji usuwają teraz także
kolumnę i tabelę v11 przed ustawieniem historycznego `user_version`.

## Optional wire `workoutSession.payload.guidance`

Mapa JSON (nie string), bez zmiany czterech wymaganych pól legacy:

```json
{
  "schemaVersion": 1,
  "plan": {"schemaVersion": 1, "criteria": {}, "budgetSeconds": 300,
    "level": "Średni", "equipment": [], "warnings": [],
    "blocks": [{"exerciseId": "cw001", "section": "main",
      "prescription": {"tracking": "reps", "sets": 2, "reps": 10,
        "workSeconds": 30, "restSeconds": 30, "transitionSeconds": 15}}]},
  "events": [
    {"type": "performed", "slotIndex": 0, "setSyncId": "UUID-serii"},
    {"type": "replaced", "slotIndex": 0, "exerciseId": "cw002"},
    {"type": "skipped", "slotIndex": 0}
  ]
}
```

`plan` jest oryginalnym `StructuredPlan` v1 z unikalnymi ID wszystkich bloków.
Nie zmienia się po zamianie. `slotIndex` jest zero-based indeksem oryginalnego
bloku; `setSyncId` wskazuje rzeczywisty zapis. Nazwy, exerciseId i pomiary serii
nie kodują pozycji planu. Każdy set UUID może wystąpić w zdarzeniach tylko raz.
Pominięcie nie usuwa wcześniejszych wykonań, zamiana nie przepina dawnych serii.
`exerciseAt(slot)` odtwarza aktualne ćwiczenie z kolejnych zdarzeń zamiany.
Zdarzenia nie zawierają diagnoz ani automatycznej oceny wykonania.

`WorkoutGuidance.validateJson(Object?)` sprawdza serializowalność, wersję,
pełną strukturę planu, niepustą listę bloków, typy, granice slotów, rodzaje
zdarzeń i unikalność powiązań. Nieobsługiwane pola guided są odrzucane zamiast
po cichu tracone przy ponownym zapisie. `tryRead(String?)` izoluje błąd od
historii serii. Prawdziwe NULL nadal oznacza zwykłą sesję ręczną.

### Granice zaufania i uszkodzenia

- Nowy start/upsert lokalny i nowe live operacje `enqueueAll` wymagają poprawnej
  struktury. Import backupu waliduje ją w transakcji: błąd wycofuje import.
- Pull waliduje **przed** zapisem. Błędne samo rozszerzenie guided zachowuje
  jednak oryginalny JSON w `guidanceJson` jako kwarantannę tego jednego wiersza,
  zamiast blokować całą stronę/kursor i poprawną historię innych sesji. Nie
  uznaje go za poprawny model prowadzenia. Summary jawnie pokazuje błąd oraz
  zwykłe serie. Błędy wymaganej koperty sesji nadal przerywają stronę pull.
- Uszkodzonego guided nie można wznowić. Można jawnie zakończyć oczekującą
  sesję bez odtwarzania formularza/timera (`finishPendingSession`), korzystając
  z czteropolowego legacy payloadu. Raw uszkodzenie nie jest naprawiane.
- Nowe DELETE sesji zachowują `dataStart`, `dataKoniec`,
  `czasTrwaniaSekund`, `notatka`; nie dekodują ani nie wysyłają guidance.
  Istniejące attempted payloady nie są przepisywane.

## API transakcyjne i prowadzenie

- `startSession(guidance: WorkoutGuidance?)` zapisuje snapshot razem z sesją
  i outboxem. `PlannerWorkflow.start(exercises, plan:)` przekazuje go z podglądu.
- `logSet(..., guidanceSlot:, expectedSyncId:)` tworzy normalną rzeczywistą
  serię, jej outbox i zdarzenie `performed` z UUID serii oraz outbox sesji
  **w tej samej transakcji**. Zewnętrzna transakcja notifikatora obejmuje też
  dotychczasowy detektor PR i jego outbox. Numery serii pochodzą z aktualnych
  wierszy transakcji, także po zapisach zewnętrznych/pull.
- `guidanceEvent(...)` utrwala pominięcie/zamianę i session outbox atomowo.
  UI pobiera zamiennik z aktualnego `StructuredPlanGenerator.replace`,
  aktualnego katalogu i shared filter engine. Oryginalne prescriptions zostają.
- `moveGuided(slot)` sprawdza zakres i blokadę zapisu; zmiana bloku czyści
  lokalne pola (historyczne zachowanie; zastąpione zachowaniem szkiców w korekcie
  ciągłości z 2026-10-18 opisanej poniżej). Cele są tylko domyślnymi szkicami formularza. Ani start,
  nawigacja, zamiana, upływ czasu, ani restore nie logują serii.
- `logSet` blokuje równoczesny podwójny tap guided. Interwały zachowują własny
  jednokrotny `IntervalWriteOrigin`; nigdy nie jest serializowany.

## Lokalny szkic i recovery

Payload szkicu v1:

```text
schemaVersion: 1
currentSlot: int >= 0
selectedIds: List<String>
guidanceSignature: String?  # kanoniczny JSON aktualnego guidance
fields: {
  weight?: String, reps?: String, seconds?: String,
  side?: left|right|both, rpe?: int 1..10, timer?: checkpoint|null,
  ...opcjonalne przyszłe lokalne dane
}
```

`validateWorkoutDraft` waliduje znane pola, RPE/stronę i cały checkpoint;
przyszłe lokalne pola zachowuje bez mapowania na serie/PR.
`updateDraft(changes)` od razu przechwytuje odłączony snapshot JSON. Kolejka
`_draftWrites` serializuje zapisy w kolejności przechwycenia; nie ma opóźnionego
nadpisania nowszego formularza starszym. `flushDraft()` czeka na kolejkę i
zgłasza rzeczywisty błąd zapisu. Zapis bez przypisanego konta nie jest durable.

`pendingWorkoutDraftsProvider` łączy szkice z aktywną, nieusuniętą sesją UUID
oraz odblokowanym kontem w `sync_state`. Home oferuje **Kontynuuj** i jawny wybór
**Wznów / Start odcinka od nowa / Zakończ**. Wybór ponownie waliduje konto,
schemat, podpis guidance, stan sesji i binding. Stary szkic po zmianie guidance
na innym urządzeniu może być widoczny w ofercie, ale jest odrzucany przy próbie
wznowienia; można zakończyć sesję. Nie jest automatycznie dopasowywany.

`resumeSession(UUID, restartSegment:)` dołącza **istniejący** wiersz, pobiera
normalne serie i rekonstruuje wybór z UUID/ID guided oraz aktualnego katalogu.
Nie wywołuje createSession, PR ani logSet. Brak ćwiczenia w katalogu jest jawnie
pokazany w bieżącym bloku. Guardy obejmują generację notifikatora, przechwycony
authority epoch, konto, offlineAccess, UUID i integer row ID. Logout, zmiana
konta, tombstone, finish lub zmiana tożsamości wiersza odrzucają stare callbacki.
Obserwator sesji reaguje również na zmianę guidance z pull. Import backupu
czyści lokalne szkice w tej samej transakcji i tworzy nowe UUID sesji.

### Checkpoint interwałów

`IntervalTimer.checkpoint()` zwraca v1: `config` (preparation/work/rest/rounds),
`phase`, `round`, `paused`, `elapsedMicros`, `results` (round/seconds/shortened).
Pozostały czas wynika dokładnie z konfiguracji i elapsed. Nie ma znacznika
czasu służącego do doliczania downtime ani uprawnienia do zapisu.

`IntervalTimer.restore(json, clock:, restartSegment:)` waliduje checkpoint,
odtwarza ukończoną faktyczną pracę i pozostaje w pauzie. Opcja restart zeruje
tylko bieżący odcinek, zachowując ukończone rundy i konfigurację. Otwarcie
timera po wznowieniu tworzy **nowy** capture z aktualnie zweryfikowanej sesji.
Potwierdzenie rund zużywa lokalny checkpoint (ustawia `fields.timer = null`
i aktualizuje podpis guidance) w **tej samej transakcji** co serie, ich związki
ze slotem i outbox. Awaria po commit nie oferuje ponownie już zapisanych rund.

W trybie guided checkpoint powstaje przy zmianie fazy/pauzy, suspension oraz
zmianie wyświetlanej sekundy (maksymalnie około raz na sekundę). Lifecycle
wstrzymuje silnik; długa nieobserwowana przerwa tickera (>3 s zegara ściennego)
zamraża ostatnio zaobserwowaną pracę i wymaga **Wznów**. Nie nadrabia czasu ani
nie zapisuje wyników automatycznie. Krótkie niewidoczne ułamki sekundy mogą być
utracone po zabiciu procesu; priorytetem jest niedoliczanie fikcyjnej pracy.

Stare ręczne formularze/stoper i manualne interwały zachowują zachowanie.
Trwałe pola formularza i checkpoint interwałów są podłączone do **guided**;
nie podłączono trwałości pól manualnych kart ani działającego ręcznego stopera.

## Summary i backup

Summary pokazuje oryginalne cele, liczbę powiązanych faktycznych serii,
zdarzenia zmiany/pominięcia, brak potwierdzenia i liczbę **Dodatkowych**.
Wszystkie normalne serie (również Mentor/pull bez powiązania) nadal są na liście,
ze stroną, RPE i pomiarami. Czas estymowany planu jest oddzielony od czasu sesji
(z przerwami i downtime) oraz sumy potwierdzonych sekund pracy. Nie porównujemy
czasu ściennego do pracy jako równoważnych metryk; nie ma diagnoz ani ocen.
Opcjonalna krótka notatka trafia do istniejącego `notatka` przy zakończeniu.

Backup v2 dodaje opcjonalne `archiveSetSyncId` w archiwalnym rekordzie serii.
Import nadal nadaje nowe sync UUID, ale remapuje `events[].setSyncId` na nowe
serie w transakcji, więc porównanie nie gubi powiązań. To pole nie jest nowym
polem wire setLog ani deklaracją domenowego wariantu. Szkice pozostają lokalne.

## Ograniczenia weryfikacji

Brak testu prawdziwego restartu procesu PWA na telefonie, gwarancji flush przy
zabiciu przeglądarki, wybudzania w tle lub synchronizacji niezapisanych szkiców.
Szkic nie jest rozproszonym CRDT ani chmurowym recovery. Przy zmianach planu
z innego urządzenia bezpieczne odrzucenie szkicu jest zamierzone.
Warianty/cloud profile i diagnostyka kliniczna są poza zakresem.

## Weryfikacja 2026-10-16 (bieżące drzewo współdzielone)

Wykonane przez istniejący obraz narzędziowy, bez budowania Dockera:

```sh
docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  dart run build_runner build --delete-conflicting-outputs

docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter analyze --no-pub

docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter test --no-pub -r expanded \
  test/features/workout/guidance_test.dart \
  test/features/workout/guidance_persistence_test.dart \
  test/features/workout/guidance_migration_test.dart \
  test/features/workout/guided_resume_test.dart \
  test/features/workout/guided_widgets_test.dart \
  test/features/workout/interval_checkpoint_test.dart
```

- Generator zakończony poprawnie (115 s), analyze: **bez uwag**.
- Nowy focused zestaw: **19 passed**. Końcowy przebieg powyższych sześciu
  plików **razem z `test/features/workout/interval_save_test.dart`: 28 passed**,
  analyze ponowione po poprawce checkpointu: bez uwag. Obejmuje niezmienność celów, zdarzenia,
  slot/link/double tap, stronę, dodatkowe zewnętrzne serie i numerację, reload
  bez nowego insert/log/PR, account binding/lock, błędny guided i finish legacy,
  schema 10→11 i attempted bytes, optional wire, izolację wadliwego pull,
  rollback restore, czteropolowy DELETE, remap UUID backupu, formularz guided
  i summary oraz checkpoint/pauzę/restart odcinka bez downtime.
- Szerszy focused przebieg: **173 passed** przed dodaniem ostatnich czterech
  regresji (obejmuje całe `test/features/workout`, sync/deferred/persistence,
  backup/settings, planner workflow/persistence, historyczne migracje i PR-side).
- Pełny `flutter test --no-pub -r expanded` przed ostatnią poprawką atomowego
  zużycia checkpointu i jej nowym testem: **591 passed, 1 failed**,
  2:12. Jedyny błąd: `test/features/planner/structured_plan_test.dart:27`
  oczekuje nadal 363 ćwiczeń, aktualny współdzielony katalog ma 369. Testu
  katalogowego nie edytowano w tym zakresie. Pełny zestaw nie jest zielony.
  Log hosta: `/root/.local/share/opencode/tool-output/tool_146ae6d410019oVZwh2uMgte6N`.
- Format wykonany tylko w plikach tego etapu, `git diff --check` sprawdzany.
  Brak zmian wersji/locka. SHA-256 Web SQLite zgadzają się z udokumentowaną parą
  z `pubspec.lock`: Drift **2.28.2**, sqlite3 **2.9.4**:
  `web/sqlite3.wasm` = `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`,
  `web/drift_worker.dart.js` = `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`.
- Backend, pipeline danych i ilustracji nie były uruchamiane ani edytowane
  przez ten etap. Bez commit/push/version/deploy i bez full Docker build.

## Review 2 — strona checkpointu i ćwiczenia dodatkowe (2026-10-17)

Poniższa korekta dotyczy wyłącznie workout source/UI/testów i tego dokumentu.
Działa na bieżącym Drift **12**, bez zmian tabel, modeli generowanych ani
codegenu. Synchronizacja profilu/kolekcji, presety, backup i ich poprawki należą
do osobnego, równoległego zakresu. Istniejące guardy wariantów i PR pozostają
używane, nie są zastępowane.

### Checkpoint nie przechodzi na inną stronę ani wariant

Lokalny formularz z timerem dostaje `timerBinding`:

```text
{ sessionSyncId, exerciseId, slotIndex: int|null,
  extra: bool, side: left|right|both|null, variantId: String|null }
```

Nie jest to wire ani uprawnienie do zapisu. Konto jest nadal częścią klucza
wiersza `WorkoutDrafts`, a authority epoch/generacja są przechwytywane przez
nieprzenoszalny `IntervalWriteOrigin`. Starszy lokalny checkpoint bez bindingu
jest przypisywany do **dotychczasowych** zapisanych pól przed scaleniem edycji
strony/wariantu, nie do nowych wartości formularza.

- Zmiana strony przy niezapisanym timerze wymaga dialogu **Zachowaj / Odrzuć
  timer**. Anulowanie zachowuje poprzednią stronę i wyniki. Potwierdzenie
  usuwa timer przed zmianą strony; nie tworzy żadnych serii.
- `captureInterval` oraz `isIntervalCurrent`/transakcyjny save sprawdzają
  zgodność checkpointu z ćwiczeniem, sesją, slotem/trybem, stroną i wariantem.
  Zmiana samych pól przez ominięcie UI nie pozwala otworzyć starego lewego
  checkpointu jako prawego ani zapisać go takim capture.
- Dotychczasowa świadoma zmiana wariantu nadal potwierdza zastąpienie szkicu
  i usuwa niezapisany timer. W trybie dodatkowym usuwa timer poprzedniego
  dokładnego klucza **przed** przełączeniem wariantu.
- Stoper otwarty z trwałej karty również weryfikuje origin po powrocie, zanim
  przekaże wynik do istniejącej ścieżki zapisu serii.

### Jawna ścieżka dodatkowa, bez zmiany planu

`ActiveWorkoutState.isExtraExercise(id)` wymaga wybranego ćwiczenia spoza
oryginalnych bloków, ich bieżących zamienników oraz ID historycznych zamian.
Pozostałe zaplanowane bloki nie są wyświetlane jako dodatkowe.

UI zachowuje **Dodaj ćwiczenie z bazy**. W prowadzonej sesji takie ćwiczenia
mają osobną sekcję **Dodatkowe ćwiczenia**, normalne formularze i — przy
`tracking == rounds` — własny timer z jawnym zapisem wyników.

API notifikatora:

```dart
logSet(exercise: ..., extra: true, side: ..., variantId: ..., ...)
captureInterval(exercise: ..., extra: true, side: ..., variantId: ..., ...)
updateExerciseDraft(exerciseId, changes,
  extra: true, side: ..., variantId: ...)
```

Tryb domyślny nadal dopuszcza tylko bieżący blok guided. `extra: true` nie
autoryzuje innego slotu ani dowolnego niewybranego ćwiczenia. Capture dodatkowy
ma `guidanceSlot == null`, ale nadal wiąże dokładny UUID sesji, row ID,
account epoch/generację, ćwiczenie, stronę i wariant. Usunięcie ćwiczenia z
wyboru lub przejście go do planu unieważnia dodatkowy origin.

Zapis korzysta z dotychczasowej transakcji repo/outbox/PR i walidacji żywej
definicji wariantu. Nie dopisuje `performed`/powiązania slotu i nie zmienia
oryginalnego snapshotu ani bieżącego bloku. Summary oznacza niepowiązane serie
zarówno licznikiem **Dodatkowe**, jak i etykietą **Dodatkowe •** przy wierszu.

### Lokalne szkice dodatkowe

W istniejącym `fields` lokalnego szkicu v1, bez zmiany schematu:

```text
extraForms: {
  JSON(["extra", sessionSyncUUID, exerciseId, side, variantId]): formularz
}
extraSelections: {
  exerciseId: {side, variantId, variantLabel}
}
```

To klucze lokalnego formularza, nie modyfikacje `exerciseId`, nazwy lub
ciężaru serii. Konto i UUID sesji nadal ograniczają cały wiersz szkicu.
`ActiveWorkoutState.exerciseDraft(...)` odczytuje wyłącznie dokładny klucz;
wybór innej strony/wariantu nigdy nie podkłada wyników poprzedniego.
Walidacja obejmuje również zagnieżdżone formularze, selekcje i checkpointy.
`selectedIds` odtwarza dodane ćwiczenia po reloadzie bez nowej sesji i bez
automatycznego logowania. Zmiana bloku/pominięcie/zamiana czyści pola guided,
ale zachowuje osobny namespace dodatkowych formularzy.

Potwierdzenie dodatkowych rund zużywa **tylko ich dokładny checkpoint** w tej
samej transakcji co serie i outbox; nie usuwa timera bieżącego bloku ani
checkpointów innych ćwiczeń/stron/wariantów. Zakończenie sesji i logout nadal
unieważniają wszystkie stare zapisy/capture.

### Dowody TDD i ograniczenia

Nowe regresje w:

- `test/features/workout/guided_side_checkpoint_review_test.dart` — restart
  z lewym ukończonym, niezapisanym checkpointem, cancel/confirm zmiany strony,
  nowy timer bez dawnych wyników oraz odmowa capture/save po obejściu UI.
- `test/features/workout/guided_extras_review_test.dart` — brak sekcji/logowania
  przed poprawką, formularz dodatkowy i reload, timer dodatkowy z jawnym save,
  niezmienny plan/slot i brak linków, osobne klucze side/variant, walidacja
  szkicu, exact-side wariant i PR, logout podczas transakcji oraz finish.

RED odtworzył niewłaściwy prawy origin dla lewego checkpointu, brak dialogu,
brak sekcji dodatkowej, dopuszczenie dowolnego ćwiczenia przez capture,
akceptację uszkodzonego dodatkowego formularza oraz brak etykiety wiersza
summary. GREEN: **9 nowych regresji**, cały focused workout **127 passed**.
Końcowy `flutter analyze --no-pub`: **bez uwag** (ponowiony na bieżącym drzewie
współdzielonym po poprawieniu własnych lintów, bez edycji plików cloud agenta).

Polecenia (ten sam istniejący obraz Flutter 3.35.4 / Dart 3.9.2, bez builda):

```sh
docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter test --no-pub -r expanded \
  test/features/workout/guided_side_checkpoint_review_test.dart \
  test/features/workout/guided_extras_review_test.dart

docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter test --no-pub -r expanded test/features/workout

docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter analyze --no-pub
```

Format ograniczono do czterech plików workout source i dwóch nowych testów.
`pubspec.yaml`, lockfile oraz artefakty Web SQLite pozostają niezmienione;
kontrolne SHA-256 są takie jak w poprzednim raporcie. Bez codegenu i zmiany
schematu 12. Nie przypisujemy temu focused przebiegowi wyniku pełnej aplikacji
(609 było podanym baseline main przed niniejszą korektą).

Bez testów rzeczywistego procesu PWA/urządzenia, pełnego Docker build,
wydania i operacji produkcyjnych. Ręczne sesje poza guided zachowują stare
zachowanie. Testy workoutu używają bieżących wariantów, ale ta poprawka nie
zmienia protokołu profilu, presetów ani backupu.

## Review 3 — CAS szkicu, zużycie i przejścia formularza (2026-10-17)

### Trwała ochrona przed starszym pełnym snapshotem

W lokalnym `payload_json` szkicu v1 dodano opcjonalne metadane (bez kolumn,
migracji ani zmiany Drift **12**):

```text
draftRevision: int >= 0
checkpointEpochs: Map<checkpointKey, int >= 0>
checkpointVersions: Map<checkpointKey, int >= 0>
```

Brak metadanych w starszym szkicu oznacza zero/pustą mapę. Klucz dodatkowy
pozostaje `JSON(["extra", sessionUUID, exerciseId, side, variantId])`;
klucz główny ma postać
`JSON(["guided", sessionUUID, slotIndex, exerciseId, side, variantId])`.
Oba pozostają wewnątrz wiersza ograniczonego kontem i UUID sesji.

- `WorkoutRepository.readDraft(accountId, sessionSyncId)` zwraca walidowany
  lokalny payload. `saveDraft(...)` zwraca **zatwierdzony payload** z metadanymi;
  odbiorcy ignorujący wynik mogą nadal zwyczajnie `await` tej operacji.
- `saveDraft` porównuje oczekiwane `draftRevision` z aktualnym wierszem
  **wewnątrz transakcji SQLite**, zanim cokolwiek nadpisze. Dla zmienianych
  timerów porównuje także epoch i wersję danego checkpointu. Samo odświeżenie
  numeru rewizji przy starym tokenie checkpointu nie autoryzuje jego odtworzenia.
  Metadane z payloadu nie mogą obniżyć przechowywanych liczników.
- `checkpointEpochs` zwiększa się przy potwierdzonym zużyciu. `checkpointVersions`
  zwiększa się przy zmianie danego utrwalonego timera oraz przy zużyciu.
  Dzięki temu stary widok nie może ani ponownie zapisać zużytych rund, ani
  skasować nowszej niezapisanej pracy drugiego widoku.
- `consumeDraftCheckpoint(...)` sprawdza oczekiwany epoch i wersję, czyta
  **najnowszy** wiersz i czyści wyłącznie wskazany timer. Robi to w tej samej
  transakcji co rzeczywiste serie, powiązania slotów i outbox. Błąd tokenu
  wycofuje cały batch. Nie używa pełnego `clearedDraft` sprzed await jako
  zamiennika najnowszego wiersza.
- Nie zwiększamy globalnej generacji sesji. Inne checkpointy, ich capture,
  formularze i pola pozostają zachowane. Po reloadzie liczniki są odczytywane
  z JSON, nie odtwarzane z dawnego `IntervalWriteOrigin`.

### Kolejka edycji i konflikty

`WorkoutDraftPatch` przechwytuje różnice pól, a nie uprawnienie do bezwarunkowego
zapisu pełnej kopii formularza. Worker czyta najnowszą rewizję, stosuje tylko
uchwycone edycje i wywołuje CAS repozytorium. Po wyścigu rewizji ponawia taki
patch maksymalnie cztery razy. Zmiany różnych pól można scalić; równoczesna
zmiana tego samego pola jest jawnym `WorkoutDraftConflict`, bez zastąpienia
nowszych danych. Lista wyboru ćwiczeń jest aktualizowana przez dodania/usunięcia
ID, zamiast nadpisywania całej listy starszą kopią.

Starszy pełny writer zatrzymany **przed** transakcją nie może po zużyciu
przywrócić timera. Jego pierwotny CAS jest odrzucany. Jeśli to własny wcześniejszy
ticker timera już świadomie zapisanego przez ten sam notifier, ponowienie pomija
tylko jego wycofane pola `timer`/`timerBinding`, zachowując pozostałe edycje.
Obcy/stary widok nie uzyskuje tego wyjątku: przestarzały token jest odrzucany.
Wersje checkpointów są uznawane za własne dopiero z wyniku zatwierdzonego zapisu,
wyłącznie dla faktycznie zmienionych kluczy, a nie z dowolnego świeżego odczytu.

Własne dopisanie `performed` może bezpiecznie przepiąć podpis guidance dla
własnych oczekujących edycji; nie daje takiego zezwolenia dowolnej zmianie
guidance z pull. Nadal obowiązują guardy konta, UUID/row ID, epoch auth i finish.
`draftSaveError` jest widoczny na ActiveSession, a `flushDraft()` zgłasza konflikt.
Konflikt tego samego pola wymaga ponownego odczytu/wznowienia; nie wybieramy
automatycznie zwycięskiej wartości użytkownika.

### Strona i wariant: zapis źródła, odczyt celu

Karta EXTRA zapisuje bieżące kontrolery do starego dokładnego klucza **przed**
zmianą strony/wariantu. Następnie ładuje kontrolery, RPE i obciążenie z klucza
docelowego. Dopiero brak szkicu daje puste wartości/default wariantu. Listener
zapisu jest wyciszony podczas ładowania, więc stan pośredni kontrolerów nie
nadpisuje celu. Opcjonalne przyszłe pola i timer docelowego klucza są zachowane.

Dialog odrzucenia timera/dirty wariantu nadal działa: cancel nie zmienia
tożsamości ani timera; confirm usuwa timer źródłowy i dopiero przełącza klucz.
Przejścia bazowy ↔ wariant A ↔ wariant B nie przenoszą powtórzeń i ciężaru
poprzedniej karty do nowej. Istniejące cele/defaulty zwykłego bloku guided
i ręczne sesje pozostają bez zmiany zachowania. Żadne przejście nie loguje serii.

### Regresje i ograniczenia tej korekty

Nowe pliki testów:

- `draft_consumption_review_test.dart`: writer opóźniony poza SQL i odrzucony
  po zużyciu; rzeczywisty reload bez odtworzenia wyników; zachowanie głównego
  checkpointu oraz późnych edycji innego pola; dwa aktywne widoki; nowsza
  niezapisana praca; stary token mimo odświeżonego CAS; konflikt tego samego pola;
  własne oczekujące edycje po dopisaniu zdarzenia guided.
- `draft_form_transition_review_test.dart`: widżet PRAWA 9 → LEWA 7 → PRAWA 9
  i ponowne utworzenie kontenera/resume; niezależne szkice bazowy/A/B, defaulty
  wyłącznie dla nowego klucza, cancel zachowujący timer i brak automatycznych serii.

RED pokazał fizyczne ponowne utrwalenie starego timera, drugi zapis tego samego
checkpointu, nadpisanie nowszej pracy oraz widżet zwracający `7` zamiast `9`.
Przy odtworzeniu starej ścieżki wariantu nowy klucz dostawał stare `9` zamiast
pustych powtórzeń. Końcowe wyniki i polecenia poniżej.

To nadal recovery lokalne, nie synchronizacja szkiców między urządzeniami.
Przy konfliktach nie ma automatycznego scalania konkurujących wartości jednego
pola; użytkownik widzi błąd i powinien odczytać szkic ponownie. Nie ma gwarancji
flush przy zabiciu procesu. Wyzerowanie/przywracanie bazy poza obsługiwanym
workflow lub równoczesny zapis przez starszy kod omijający CAS nie są objęte
gwarancją. Poprawka nie odzyskuje wartości szkiców nadpisanych już przez dawny
błąd. Brak testu rzeczywistego procesu PWA/telefonu i pełnego zestawu aplikacji.
Nie zmieniano SyncStore, profilu, kolekcji chmurowych, backupu, wersji ani deployu.

Weryfikacja końcowa tej korekty:

```sh
docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter test --no-pub -r expanded \
  test/features/workout/draft_consumption_review_test.dart \
  test/features/workout/draft_form_transition_review_test.dart
# 9 passed

docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter test --no-pub -r expanded test/features/workout
# 136 passed

docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter analyze --no-pub
# No issues found
```

Format tylko pięciu zmienionych/nowych plików source workout i dwóch nowych
testów. Brak deklaracji Drift/Freezed/json_serializable — bez generatora,
bez migracji. Lockfile i para Web SQLite dla Drift 2.28.2 / sqlite3 2.9.4
niezmienione. Bez commit/push, zmiany wersji, wdrożenia i full Docker build.

## Review 4 — edycje RAM podczas zużywania innego checkpointu (2026-10-17)

Poprzedni wynik CAS w SQL nie wystarczał: `updateDraft` przyjmował edycje do
RAM, lecz pomijał kolejkę w trakcie batcha, a zakończenie EXTRA podkładało stare
całe `extraForms`/`extraSelections`. To mogło cofnąć B z 9 do 3 mimo poprawnego
zużycia A w bazie. Poniższa korekta usuwa oba źródła tego problemu.

### Aktualny kontrakt scalania

- Nie ma globalnego pomijania kolejki formularzy podczas zapisu rund. Poprawne
  edycje B, nowy checkpoint B, notatki/future fields i wybory ćwiczeń od razu
  tworzą zwykłe delty `WorkoutDraftPatch`. Worker może czekać na zwolnienie
  transakcji A, ale edycja nie jest przyjęta wyłącznie do RAM i zapomniana.
- Nie czyścimy A w RAM przed await. Sukces SQL scala się z **aktualnym** RAM
  przez czystą `mergeConsumedCheckpointFields(current, key:, extra:,
  expectedForm:)`. Funkcja usuwa tylko `timer`/`timerBinding` wskazanego A,
  i tylko gdy nadal odpowiadają staremu checkpointowi. Nie podmienia całych
  map, selekcji, metryk ani innych pól. Nowy token/binding A nie jest kasowany.
- Ze zwrotnego payloadu repo przyjmowane są monotonicznie wyłącznie epoch
  i wersja zużywanego klucza A. Nie cofamy tokenów B ani globalnej generacji
  sesji. Końcowe `updateDraft({})` kolejkuje pozostałą celowaną deltę zużycia.
- Rollback/odmowa również nie przywraca całego starego snapshotu RAM. A nie
  zostało przedwcześnie usunięte, a edycje innych pól pozostają w kolejce.
- Tymczasowa blokada batcha dotyczy serializacji jawnych zapisów rund, nie
  zapisu formularzy. Nowy capture **tego samego** A w trakcie consume jest
  odrzucany; B nadal może dostać capture i zapisywać checkpointy.

### Nonce callbacku i jawna odmowa

`isIntervalCheckpointCurrent(origin)` i
`updateIntervalCheckpoint(origin, checkpoint) → bool` są ścieżką callbacku
timera w UI. Origin już zarezerwowany przez save jest wycofanym nonce:
spóźniony ticker A dostaje `false`, bez zmiany RAM i bez ponownego zapisu.
Stare capture po commit nadal odrzucają również trwałe epochy/CAS z review 3.

Niskopoziomowe `updateDraft`/`updateExerciseDraft` nie przyjmują do RAM zmiany
timera aktualnie zużywanego A: taka próba zgłasza `WorkoutDraftConflict`
synchronicznie. Nie blokuje to metryk A ani żadnej przestrzeni B. UI korzysta
z metody z origin, więc zwykły spóźniony callback jest bezpieczną odmową, a nie
nieobsłużonym wyjątkiem. Ważne edycje przyjęte do RAM trafiają do kolejki;
ewentualny konflikt/storage error jest jawny przez `draftSaveError` i
`flushDraft()`, z dotychczasowym unieważnieniem przy finish/logout/zmianie konta.

### TDD

`test/features/workout/draft_inflight_merge_review_test.dart`:

1. Bariera **wewnątrz rzeczywistej transakcji repo**, po insercie serii A:
   B:3 → B:9, nowy timer B, notatka, future field, dodanie C i przełączenie
   selekcji A na prawą stronę. RED dawał po consume B:3 zamiast B:9.
   GREEN sprawdza RAM, wejście workerów B do kolejki jeszcze przed zwolnieniem
   bariery, flush i nowe wznowienie z SQLite. A jest zużyte tylko raz, główny
   checkpoint i cała późniejsza praca pozostają zachowane.
2. Ten sam scenariusz z rollbackiem A: edycje B i pozostałych pól nadal są
   trwałe, A pozostaje niezapisane, liczba rzeczywistych serii wynosi zero.
   Spóźniony callback A jest odrzucany, checkpoint B jest przyjmowany normalnie.
3. Czysty test scalania dla 100 różnych map danych: wszystkie niezwiązane
   namespace'y i selekcje są zachowane, argument nie jest mutowany, operacja
   jest idempotentna; nowszy nonce A pozostaje nietknięty. Obejmuje też główny
   checkpoint poza EXTRA.

Nie dodano kolumn, migracji ani nowych metadanych JSON: schemat nadal 12.
Repozytoryjny CAS i trwałe tokeny z review 3 pozostają bez osłabienia. Zakres
tej korekty to provider, czysta funkcja scalająca, callback UI, nowy test i ten
dokument — bez plików cloud, wydania i operacji produkcyjnych.

Weryfikacja końcowa review 4 (Flutter 3.35.4 / Dart 3.9.2, istniejący obraz
narzędziowy, bez budowania Dockera):

```sh
docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter test --no-pub -r expanded \
  test/features/workout/draft_inflight_merge_review_test.dart \
  test/features/workout/draft_consumption_review_test.dart \
  test/features/workout/draft_form_transition_review_test.dart
# 12 passed: 3 nowe + wszystkie 9 poprzednich regresji

docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter test --no-pub -r expanded test/features/workout
# 139 passed

docker run --rm -v /opt/fit:/app -w /app fit-web:release-1.13.0-26-verified \
  flutter analyze --no-pub
# No issues found
```

Format wyłącznie trzech zmienionych plików source i jednego nowego testu.
Bez zmiany deklaracji generatorów, schematu 12, zależności, wersji lub
artefaktów Web SQLite. Bez commit/push/deploy/full Docker build. Pełny zestaw
aplikacji i akceptacja release pozostają osobnym etapem main. Dotychczasowe
ograniczenia flush przy zabiciu procesu oraz jawnych konfliktów pól nadal
obowiązują; ta korekta nie wprowadza cichego pomijania ważnych edycji.

## Browser blocker — granica transakcji kolejki (2026-10-17)

Źródło problemu pustej tabeli draftów z prawdziwego kompilatu opisano jako
dopisek do `docs/guided-browser-acceptance-2026-10-17.md`; jego historyczny
werdykt RED i wszystkie dowody pozostają bez zmian.

`PlannerWorkflow.start` tworzył notifikator i rejestrował callbacki kolejki
oraz obserwatora sesji w strefie transakcji planera. Długowieczna praca
wykorzystywała potem zamknięty executor. Native zgłaszał błąd, a transport
RPC mógł pozostawić całą kolejkę pending za zakończonym identyfikatorem.
Kolejne zmiany RAM nie były dowodem durable zapisu. Fixture nie utraciło
guidance: porównanie read-only SQLite/requestów wykazało zgodność wartości
i kolejności kluczy, a profile extras NULL odpowiadają poprawnemu omission.

`_persistentDatabaseZone()` wybiera najbliższą strefę nadrzędną niezwiązaną
z transakcją **tej bazy**, zachowując kontekst UI/error/test. Kolejka i trzy
miejsca podpinania trwałego `watchSession` używają jej przy rejestracji pracy.
To jeden jawny, wersjonowany punkt zgodności z `resolvedEngine` Drifta 2.28.2
(getter oznaczony internal); zmiana wersji Drifta wymaga ponowienia testów
native/RPC. Nie zmieniono zależności ani artefaktów Web SQLite.

Queue dalej korzysta z normalnego repo, transakcji CAS, epoch/tokenów i guardów
konta/UUID. Nie wstawiamy wiersza naprawczego, nie modyfikujemy echo ani
SyncStore. Worker wykonuje się po zwolnieniu transakcji wywołującej; dlatego
`flushDraft()` należy wywoływać **po** `await PlannerWorkflow.start`, a nie
oczekiwać na niego wewnątrz parent transaction, która trzyma bazę.

Odmowy `WorkoutSessionUnavailable`/`WorkoutAccountUnavailable` są wyciszane
tylko dla rzeczywiście nieaktualnego żądania/konta/wiersza. Gdy ten sam request
nadal jest bieżący, a konto i sesja są aktywne, błąd pozostaje widoczny przez
istniejący `draftSaveError` w UI i wyjątek `flushDraft()`. Nie traktujemy pustej
tabeli jako sukcesu zapisu. Widoczny krok w RAM nie jest potwierdzeniem flush.

Nowy `guided_browser_draft_repro_test.dart` oraz
`fixtures/guided_browser_capture.json` odtwarzają przechwycony profil/guidance
przez realne AuthController, PlannerWorkflow, SyncService, parser i SQLite.
Kontrole obejmują zwykłą i odwróconą kolejność kluczy JSON, native oraz RPC,
ponowne otwarcie pliku bazy/providerów, pending UUID i odtworzenie kroku 4,
Lewa/7, bez nowej sesji/serii/operacji startu. Jest również rollback caller
transaction i odmowa zapisu do nadal aktywnego wiersza.

Nie jest to PASS nowego compiled browsera: do niego potrzeba nowego obrazu
od main i ponowienia zachowanego harnessu. Nie uruchamiano runtime builda ani
nie edytowano fontów, pubspec/theme/assets, profilu, cloud sync czy backendu.

Weryfikacja tej korekty: `flutter test --no-pub -r expanded
test/features/workout/guided_browser_draft_repro_test.dart` — **9 passed**;
całe `test/features/workout` — **148 passed**; `flutter analyze --no-pub` —
**bez uwag**. Wszystko przez istniejący obraz narzędziowy
`fit-web:release-1.13.0-26-verified`, z bieżącym `/opt/fit:/app`. Format tylko
providera i nowego testu. Bez migracji/codegenu, zmiany wersji, commit/push,
deployu i full Docker build. Nowy obraz do prawdziwego retestu przygotowuje main.

## Ciągłość aktywnej sesji — 2026-10-18

`ActiveWorkoutNotifier.startSession` nie zastępuje aktywnego stanu RAM.
Start nowego wiersza używa transakcyjnego warunku `requireNoActiveSession`:
istniejąca niezakończona, nieusunięta sesja powoduje `ActiveSessionExists`,
bez nowego UUID i outboxa. Dotyczy także sesji bez poprawnego szkicu — nie
wolno traktować braku możliwości recovery jako zgody na nową sesję.
Klasyczny dashboard pokazuje **Kontynuuj trening** dla sesji w RAM lub
persisted recovery i prowadzi do istniejącej trasy sesji. Po restarcie wybór
wznowienia nadal jest jawny; dashboard nie wybiera pierwszego kandydata.

`moveGuided` zachowuje formularze bloków w istniejącym lokalnym payloadzie v1:

```text
fields.guidedForms[JSON(["guided", sessionUUID, slot, exerciseId, side, variantId])]
fields.guidedSelections[JSON([slot, exerciseId])] = dokładny klucz formularza
```

Aktywny formularz nadal jest bezpośrednio w `fields`. Przy przejściu zapisujemy
źródło, a docelowy formularz usuwamy z mapy nieaktywnych i odtwarzamy jako
aktywny: checkpoint nie ma drugiej kopii, która mogłaby wrócić po zużyciu.
Ten sam slot jest no-op; przejście podczas transakcji zużycia jest odrzucane.
Walidacja obejmuje zagnieżdżone formularze, a CAS, epoch i wersje obejmują
także nieaktywne checkpointy. EXTRA pozostaje osobną przestrzenią.
Zmiana ćwiczenia nie podkłada formularza poprzedniej tożsamości. Nie zmieniono
dialogów świadomego odrzucenia timera przy zmianie strony/wariantu.

Regresje `training_continuity_test.dart` i `classic_today_continuity_test.dart`
obejmują ponowny start, persisted recovery, dashboard, A–B–A/restart, stronę
i wariant, zamianę ćwiczenia, pauzę po dobie nieobecności, brak automatycznego
logowania i brak odtworzenia zużytego checkpointu. RED: nowy UUID zamiast
dotychczasowego, brak odmowy startu, utracone pole `9`, brak przycisku kontynuacji.
GREEN: wszystkie sześć nowych testów, workout + test workflow planera
**190 passed**, pełny klient **846 passed**, analiza **No issues found**.

Polecenia przez udokumentowany istniejący obraz (bez sieci i budowania obrazu):

```sh
docker run --rm --network none -v /opt/fit:/app -w /app \
  fit-web:release-1.13.0-26-verified flutter test --no-pub -r expanded \
  test/features/workout test/features/planner/planner_workflow_test.dart
docker run --rm --network none -v /opt/fit:/app -w /app \
  fit-web:release-1.13.0-26-verified flutter analyze --no-pub
docker run --rm --network none -v /opt/fit:/app -w /app \
  fit-web:release-1.13.0-26-verified flutter test --no-pub -r expanded
```

Bez migracji i deklaracji generatorów; nie zmieniono wersji, zależności ani
artefaktów Web SQLite (hashe jak wyżej, Drift 2.28.2 / sqlite3 2.9.4).
Bez commit/deploy i testu rzeczywistego restartu procesu PWA. Nadal nie ma
gwarancji flush przy zabiciu procesu ani odzyskania szkiców wcześniej utraconych.

### Korekta P1 po review — tożsamość wewnątrz bloku

Pierwsza poprawka archiwizowała formularz tylko przy `moveGuided`. Zmiana
strony/wariantu w tym samym bloku nadal nadpisywała poprzednie pomiary.
`selectGuidedIdentity` używa teraz tej samej operacji zapisz źródło / odczytaj
cel co nawigacja bloków. UI zapisuje kontrolery przed zmianą tożsamości,
ładuje docelowe wartości przy wyciszonych listenerach i stosuje cele/defaulty
tylko dla brakujących pól nowego szkicu. Nie zmieniono ręcznych kart ani EXTRA.

Przejście z niezapisanym timerem wymaga dotychczasowego świadomego discard;
notifier odmawia przełączenia, jeśli timer nie został wyczyszczony. Anulowanie
dialogu nie zmienia formularza. Odrzucony timer jest usuwany przed archiwizacją,
a zużyty checkpoint nie wraca po przełączeniu strony i wznowieniu.

Rozszerzone rzeczywiste testy UI w `draft_form_transition_review_test.dart`
wykazały RED: nowy wariant dostał stare `9` zamiast celu `10`, a powrót na
poprzednią stronę zwracał `7` zamiast `9`. GREEN obejmuje także sekwencję
blok A/lewa/X=9 → B → A/prawa/Y=4 → B → A/lewa/X=9 i ponowne wznowienie.
`training_continuity_test.dart` sprawdza przejście stron po zużyciu checkpointu.
Focused `test/features/workout`: **189 passed**. Pełnej suite w tej korekcie
nie uruchamiano — pozostaje do wykonania po integracji.
