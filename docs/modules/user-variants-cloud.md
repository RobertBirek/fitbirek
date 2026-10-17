# Własne warianty i chmurowe definicje filtrów

## Zakres i kontrakt

Klient główny `/opt/fit`, Flutter 3.35.4 / Dart 3.9.2. Lokalny Drift **12**
(addytywna migracja 11→12), bez nowych zależności, typów encji synchronizacji,
kursora ani migracji PostgreSQL. Nie zmienia katalogu 369 ćwiczeń, ich ID,
klasyfikacji, ilustracji ani protokołu prowadzenia treningu.

`UserProfiles.filterPresetsJson` i `exerciseVariantsJson` to nullable JSON strings
w **surowym** wierszu Drift, nie pola publicznego Freezed `UserProfile`.
Formularze profilu nie mają ich wartości domyślnych: zwykły zapis zachowuje
kolumny, a outbox powstaje ze świeżego, całego wiersza w tej samej transakcji.
Zmiana preferencji aktualizuje tylko wskazaną kolekcję i `updatedAtUtc` — nie
zastępuje imienia, wzrostu ani innych pól formularza.

Wire: opcjonalne klucze istniejącego `profile.payload`:

```json
{
  "filterPresets": {"version": 1, "entries": []},
  "exerciseVariants": {"version": 1, "entries": []}
}
```

Każdy wpis ma `id` (globalnie stabilny UUID), `name` (1–80 znaków Unicode),
`createdAtUtc`, `updatedAtUtc` (ISO8601 UTC, końcówka Z), opcjonalny
`deletedAtUtc`. `updatedAtUtc >= createdAtUtc`, deletion nie później niż update.
Puste nullable kolumny oznaczają brak dotychczasowej kolekcji. Brak klucza w
incoming profilu zachowuje lokalne rozszerzenie; explicit null jest jawnym
zastąpieniem NULL, nie omission. Operacje UI usuwają **wpis**, tombstone'em,
nie przez zerowanie kolekcji. UUID nie jest nowym `cw...` ID.

Wpis filtra: `filters` to pełny istniejący kodek `FilterPreset.encodeFilters` /
`decodeFilters`: styles, muscles, conditions, positions, sprzet, typy, partie,
poziomy, tylkoUlubione, query, sortBy. Nie zawiera wyników wyszukiwania.
Nieznane ID kryteriów pozostają zachowane; brakujące opcjonalne kryteria mają
dotychczasowe domyślne wartości kodeka.

Wpis wariantu: `exerciseId`, `name`, opcjonalne `loadKg`, `tempo`,
`pauseSeconds`, `rangeOfMotion`, `cue`. Load: skończony, **>0, <=1000 kg**,
tworzony tylko dla bazowego ćwiczenia z Hantlami/Sandbagiem i tracking `reps`,
nie Izometrii. Sprawdzenie korzysta z istniejącego indeksu offline.
Pauza: całkowite 0–3600 s. Teksty parametrów: do 1000 znaków każdy.
Tempo, pauza, zakres i domyślny load są niezmienne pod danym UUID: dla innego
protokołu należy utworzyć nowy wariant (nowy UUID). Repozytorium udostępnia
rename/cue bez zmiany protokołu, UI szczegółów udostępnia dodawanie/usuwanie.

**Limity każdej kolekcji:** 500 wpisów **łącznie z tombstone'ami**, 262144
bajty UTF-8 JSON. Limity obowiązują też wynik merge i restore. Nie ma
automatycznego prune, GC ani cichego odrzucania wpisów. Przekroczenie limitu
blokuje zapis/merge z błędem, pozostawiając źródłowe dane i operację. Do
długofalowego GC potrzebna jest osobno uzgodniona polityka wszystkich urządzeń.

## Konto, migracja i odświeżanie

Produkcyjny `FilterPresetsRepository` korzysta z Drift; bez argumentu `cloud`
pozostaje istniejącym adapterem SharedPreferences dla fixture'ów i migracji.
API `load/save/delete`, semantyka nadpisania i duplikatu nazwy nie zmieniają się.
Sieć działa wyłącznie przez istniejący `SyncService`, nigdy przez loader filtrów.

Po dostępności aktywnego profilu importowany jest wyłącznie klucz bieżącego
konta `exercise_filter_presets.v1.<base64url(accountId)>`. Zachowane są UUID;
ID już znane lokalnie z chmury, także tombstone'y, nie są ponownie importowane.
Stary format nie ma wiarygodnej daty edycji. Automatycznie importowany wpis
nieznany lokalnie dostaje `createdAtUtc = updatedAtUtc =
1970-01-01T00:00:00.000Z`, **nie czas importu**. Dzięki temu zdalna definicja
lub tombstone jeszcze niepobrane przez urządzenie wygrywają późniejszy merge.
Import nie wykonuje dodatkowego HTTP. Jawny zapis użytkownika po imporcie
dostaje rzeczywisty UTC i konkuruje zwykłą polityką LWW; UUID pozostaje ten sam.
Znacznik `<klucz>.drift-imported` zapisuje się **po commit** Drift/outbox.
Źródłowych preferencji nie usuwa się. Utrata zapisu znacznika może powtórzyć
próbę, ale nie zduplikuje ID ani nie odrodzi usuniętego wpisu. Uszkodzony
dokument migracji daje błąd i pozostaje nienaruszony.

Zapisy przechwytują konto, pasywny `CachedAuthWriteAuthority.epoch` i guard UI;
transakcja sprawdza SQLite binding/offlineAccess oraz aktywny profil po awaitach.
Także A→B→A unieważnia przechwycenie. Brak bootstrapu auth/HTTP.
Subskrypcja surowego profilu odświeża UI po pull, konflikcie i restore.
Kontroler nie publikuje spóźnionych odczytów do nowego konta; podczas własnego
zapisu końcowy reload zastępuje wcześniejsze read'y, bez wyścigu pustej listy.

## Konflikty i niezmienność outboxa

`UserCollections.merge` wykonuje rzeczywiste per-ID LWW po `updatedAtUtc`.
Remis: tombstone wygrywa z live; następnie leksykograficzny canonical JSON
(rekurencyjnie sortowane klucze). Wynik ma posortowane UUID. Tombstone'y
pozostają. Merge jest deterministyczny i przemienny; nie jest konkatenacją list.

Po definitywnym odrzuceniu operacji przez CAS `SyncService` usuwa tylko tę
operację. Jeśli nie ma późniejszej dirty operacji, scala **bieżące kolumny
lokalnej bazy** z kolekcjami serwera i zapisuje lokalnie serwerowe pola skalarne
plus scalone rozszerzenia, po czym tworzy **nowy** upsert na remote version.
ACK tej operacji nie może zostawić starych lokalnych pól skalarnych.
Nie scala usuniętego profilu ani operacji delete; nie odradza profilu z tombstone'a.

Jeżeli są późniejsze dirty edycje, zachowana jest dotychczasowa polityka defer:
lokalne pola i attempted payloady nie są nadpisywane. Incoming profile snapshot
nie rebazuje wtedy unsent profilu „w ciemno”; ostatnia operacja również przechodzi
CAS, a finalny konflikt scala kompletny lokalny stan kolekcji. Dzięki temu
nie ginie nowy wpis z innego urządzenia ani późniejsza edycja lokalnej kolekcji.
Pola skalarne w odrzuconym finalnym konflikcie pozostają server-authoritative.

`row.syncVersion` nadal jest monotoniczną **wersją zaobserwowaną**, również
podczas defer. Nie oznacza, że pola lokalnego wiersza są snapshotem tej wersji.
Zwykły zapis profilu, zapis kolekcji i `enqueueAll` pytają w tej samej transakcji
`profileWriteBaseVersion`: przy istniejącym niezastosowanym deferred vN baza
nowej operacji jest ograniczona do `N-1` (lub niższej zgłoszonej wersji).
To konserwatywny, celowo stary token CAS — nie zmiana observed watermark ani
próba ominięcia CAS. Serwer znający co najmniej vN musi odrzucić stary snapshot,
co uruchamia pełny merge. Także ACK starszy od deferred nie rebazuje unsent
operacji do nowszej wersji jedynie zaobserwowanej w wierszu. ACK rzeczywiście
supersedujący deferred zachowuje istniejącą politykę reconcile. Rozwiązanie
korzysta z obecnej trwałej tabeli defer, bez nowej kolumny/metadanych/schematu.

Jawny restore skalarów zachowuje dotychczasowe `preserveLocal`, gdy wynik
kolekcji jest już identyczny ze zdalnym. Nawet wtedy świeża operacja restore
zawiera **scalone kolekcje**, nigdy stare listy z odrzuconego payloadu, i te
same wartości są lokalnie zapisywane w transakcji przed enqueue. Jeśli merge
wnosi lokalne rozszerzenia/clear, świeża operacja używa serwerowych skalarów.
Wtedy nie dziedziczy już `preserveLocal`: kolejny konflikt nie może ponownie
nadać starszym skalarom z restore pierwszeństwa nad nowszym stanem serwera.

Walidacja obejmuje nowe upserty, restore i incoming kolekcje. Uszkodzona
incoming kolekcja jest kwarantannowana jako jej oryginalny JSON: reader zgłasza
błąd, lecz druga kolekcja, zwykły profil i historia pozostają czytelne. Nie
zastępujemy uszkodzenia pustą listą. Nowy zapis całego profilu z uszkodzonym
rozszerzeniem zostaje zablokowany, a nie wysyła „naprawy” kasującej dane.
Nie modyfikujemy attempted payloadów, nawet podczas restore / duplicate ACK.

Backup schemaVersion pozostaje 2: eksport wiersza zawiera nullable rozszerzenia.
Restore waliduje je i scala per-ID z obecnymi definicjami (chroni tombstone'y).
Stary backup bez tych pól zachowuje obecne kolumny zamiast zastosować NULL jako
wartość domyślną. Intencjonalne explicit null to odrębny przypadek: obecny w
surowym archiwum klucz `filterPresetsJson: null` / `exerciseVariantsJson: null`
przekazuje do `enqueueAll` jawny zbiór clear intent. Pierwszy nowy upsert wysyła
odpowiedni **wire key z NULL**, a nie omission. To nie jest zmiana domyślnego
kodeka: NULL w zwykłym/starym lokalnym wierszu bez intencji nadal pomija klucz,
żeby klient przed pierwszym pull nie wyczyścił nieznanych zdalnych preferencji.

Przy kolejnym świeżym upsercie profilu outbox zachowuje jawny NULL z oczekującej
operacji, jeśli nowy payload omija ten klucz. Szuka ostatniej jawnej wartości
według SQLite `rowid` (kolejność enqueue, odporna na cofnięcie zegara). Nowa
nie-NULL wartość tego klucza jest jawnym zastąpieniem intencji clear; nie gubi
clear innej kolekcji. Dotyczy to również attempted poprzednika, ale wyłącznie
jako **odczytu** — poprzednia operacja nie jest przepisywana. Intencja trwa w
nowych payloadach przez coalescing, restart i CAS do rozstrzygnięcia ACK.
Finalny konflikt respektuje NULL dla lokalnie wyczyszczonej kolekcji zamiast
scalać w nią stare zdalne wpisy. Brak markerów w publicznym modelu profilu ani
nowych wire keys / entityType. Limity 500/256 KiB i zakaz prune bez zmian.

## Serie, PR, prowadzenie i UI

`SetsLog`, `PersonalRecords`: nullable `variantId` / `variantLabel`; wcześniejsze
wiersze migrują do NULL (bazowy). SetLog Freezed JSON oraz wire nowych
workoutSet/PR zawierają parę, gdy ID nie jest NULL. Label przy NULL ID nie ma
znaczenia; nieprawidłowa para z niepustym ID jest odrzucana. Label jest
snapshotem podczas zapisu, nie jest odczytywany z aktualnej nazwy definicji.
Usunięta/nieznana definicja nie blokuje czytania dawnej historii ani restore.

Nowa seria/PR z wariantem wymaga transakcyjnego dowodu, że UUID jest live w
profilu bieżącego konta i należy do danego ćwiczenia. Guard nie dotyczy importu
historii. Last set, getBest, historia PR, delty i progresja mają dokładny scope
**exerciseId + side + variantId**. NULL side to nie `both`; NULL variant to nie
żaden UUID. Progresja RPE porównuje rzeczywisty identyczny ciężar, nie load
domyślny definicji. Czas/rundy nie tworzą 1RM.

Szczegóły: „Moje warianty”, osobne pola parametrów, dodawanie/usuwanie.
Sesja: bazowy + własne live warianty. Zmiana wariantu wypełnia tylko szkic
domyślnego obciążenia; istniejący szkic wymaga potwierdzenia. Parametry są
pokazane osobno, nie kodowane w nazwie/powtórzeniach/ciężarze faktycznej serii.
Checkpoint guided zachowuje optional `variantId/variantLabel`; po usunięciu
definicji nie stosuje jej automatycznie ani nie przechodzi cicho na bazowy:
pokazuje niedostępność i wymaga wyboru. Dawna etykieta pozostaje w historii.
Interwały zapisują wyłącznie jawnie zatwierdzony batch z wariantem przechwyconym
w origin. Nadal bez autosave. Powiązania guided są po setSyncId+slot,
podsumowanie adnotuje wariant jako zmianę bazowego, nie dodatkową duplikację serii.

## Weryfikacja i granice publikacji

Testy: `user_collections_test`, `variants_schema_test`,
`profile_collections_sync_test`, `profile_cloud_review_test`, `own_variants_test`, `variant_widgets_test`,
dotychczasowe testy filtrów, PR, progresji, guided, sync/restore/migracji.
Generator uruchamiany na rzeczywistych źródłach w kopii `/tmp`, Docker Flutter
3.35.4 / Dart3.9.2, źródło zamontowane read-only. Bez inline ignorowania
duplikatów Freezed. Lockfile i artefakty Web SQLite nie zmieniają wersji.

**Wymagane późniejsze wydanie API+web:** backendowa ochrona optional omission
po hash/CAS musi zostać opublikowana przed uruchomieniem funkcji na produkcji.
Ten etap nie wdraża API, nie uruchamia pełnego Docker build ani nie zmienia
wersji aplikacji. Stare klienty ignorują optional profile keys, nie ma nowego
entityType mogącego zablokować ich globalny pull.

Ograniczenia: LWW używa zegarów urządzeń (nie zegara centralnego); przy pełnym
limicie brak automatycznego GC tombstone'ów; brak UI naprawy uszkodzonego raw
JSON (należy zachować eksport i rozwiązać przyczynę, nie resetować kolekcji).
UI oferuje nowe definicje zamiast edycji istniejącego protokołu. Zwykły ręczny
formularz sesji nadal ma dotychczasowy zakres lokalnej trwałości; trwałe
przywracanie wyboru wariantu dotyczy checkpointu prowadzonego treningu.

### Wynik lokalnej weryfikacji implementacji przed poprawkami review 3

- Docker potwierdził Flutter **3.35.4**, Dart **3.9.2**.
- `dart run build_runner build --delete-conflicting-outputs`: sukces;
  porównanie wszystkich wygenerowanych modeli nie wykazało zmian poza
  `app_database.g.dart`, `workout_session.g.dart`, `workout_session.freezed.dart`.
- `dart tools/generate_app_version.dart --check`: sukces, wersja bez zmian.
- `flutter analyze`: **No issues found**.
- Pełne `flutter test --reporter expanded`: **609 passed, 0 failed**.
- `git diff --check`: sukces.
- SHA256 lokalnych artefaktów porównano bajtowo z release'ami odpowiadającymi
  lockfile: sqlite3 **2.9.4**, Drift **2.28.2**. Oba zgodne; bez podmiany plików:
  - sqlite3.wasm: `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
  - drift_worker.dart.js (upstream `drift_worker.js`):
    `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`
- Nie wykonywano niezależnego review subagentem, ręcznego browser acceptance,
  pełnego Docker build ani testów/publikacji backendu w tym etapie.

### Review 3 — deferred base, jawny NULL restore, pierwszeństwo migracji

Test-first reprodukcja w `test/core/profile_cloud_review_test.dart` przed
poprawkami: **6 FAIL / 2 PASS**. Trzy błędy bazy CAS po defer (zwykły profil,
nowy preset, restore) miały `baseVersion = 2` mimo niezastosowanych pól v2;
dwa przypadki NULL restore nie miały wire key; automatyczny import odradzał
zdalnie usunięty UUID. Kontrole starego backupu bez pól i celowej edycji
użytkownika po imporcie przechodziły już przed poprawkami.

Po poprawkach dziesięć testów tego pliku obejmuje również starszy ACK wobec
nowszego observed watermark, utracony ACK po commit, reopen SQLite, późniejszą
edycję po defer oraz niezmienność attempted payloadu. Osobny RED pokazał też
195 zamiast nowszego serwerowego wzrostu 200 przy drugim konflikcie clear;
regresja przechodzi po skonsumowaniu `preserveLocal` przez pierwszy merge
wybierający serwerowe skalary. Szerszy focused zestaw
sync/defer/persistence/presetów/providerów/widgetów/backup: **75 PASS / 0 FAIL**.
`flutter analyze`: **No issues found**. `generate_app_version --check`: sukces.
Bez zmiany deklaracji Drift/Freezed/JSON, schemat nadal **12**, generator
w tym review nie był potrzebny. Nie zmieniano backendu, zależności, wersji,
artefaktów SQLite ani plików workout z równoległego zadania.

Pierwszy pełny przebieg wspólnego snapshotu: **626 PASS / 1 FAIL**.
Jedyny błąd był w równolegle dodanym
`test/features/workout/guided_extras_review_test.dart`, test „added non-plan
exercise is loggable, resumes and appears in summary as additional”, linia 466
(nie znaleziono tekstu `Dodatkowe • Dodatkowy…`). Zakres workout pozostawiono
drugiemu agentowi. **Ostatni pełny przebieg świeżej kopii wspólnych źródeł po
wszystkich poprawkach tego review: 628 PASS / 0 FAIL**, analyze nadal bez uwag;
wcześniejszy błąd workout również już przechodzi, bez edytowania jego plików
w zadaniu sync/cloud. Pełnego Docker build, backendu i pipeline nie uruchamiano
ponownie w tym review.
