# Ćwiczenia dla potwierdzonego sprzętu — lokalny odbiór

## Zakres i stan publikacji

Baza kodu: `954484a` (dokumentacja wdrożonego źródła `dd4f4b2`).
Nowy katalog rozwijany lokalnie w `feat/owner-equipment-catalog`, bez commit,
push i wdrożenia. Produkcja1.22.0+38 zawiera wcześniejsze przygotowanie treningu,
nie ten dodatek. Metadane wersji pozostają bez zmian do odrębnej decyzji wydania.

**424 ćwiczenia**: zachowany surowy prefiks412 i12 dodatków:

| ID | Ćwiczenie |
|---|---|
| cw413 | Wejście bokiem na step |
| cw414 | Kontrolowane zejście ze stepu |
| cw415 | Pompki z dłońmi na stepie |
| cw416 | Spięcia brzucha na ławce głową w dół |
| cw417 | Pełne brzuszki na ławce głową w dół |
| cw418 | Wyciskanie hantli na ławce głową w dół |
| cw419 | Stanie obunóż na poduszce równoważnej |
| cw420 | Stanie jednonóż na poduszce równoważnej |
| cw421 | Rolowanie łydki |
| cw422 | Rolowanie przedniej części uda |
| cw423 | Rolowanie pośladka |
| cw424 | Chód z sandbagiem objętym przed tułowiem |

Bez duplikowania: korekty `cw009`, `cw123`, `cw135`, `cw136`, `cw165`, `cw267`
są osobnym wersjonowanym manifestem, nie zmianą surowego prefiksu. Import
aktualizuje zatwierdzone pola tych ID z zachowaniem historii, ulubionych i pending.
Nowe ilustracje nie są gotowe; dotychczasowe412 plików zachowane, nowe12 korzysta
z jawnego fallbacku zamiast obrazu innego ruchu.

## Sprzęt i granice znaczenia

- Step regulowany podstawą, deklarowane150kg; wysokość niezmierzona.10–15cm
  oznacza orientacyjną niską adaptację, nie pomiar ani zgodę na skoki.
- Ławka do brzuszków nie jest aliasem płaskiej/dodatniej ani ławki do wyciskania.
  Wyciskanie ujemne wymaga osobnego jawnego wyboru ławki dopuszczonej do ciężaru;
  nośność konkretnej ławki właściciela pozostaje niezweryfikowana.
- Sandbag operacyjnie stale20kg, nie domyślny ciężar innych użytkowników.
  Historia innej masy nie uzasadnia progresji przy20kg; brak automatycznego +kg.
- Wrist roller: kg zawieszonego obciążenia, nie sztuki hantla ani uchwytu.
- Pasy za nogi nie są TRX/podporami ramion; bez automatycznych inwersji.
- Nowe kategorie wybiera się jawnie w edycji profilu. Nie zmieniano profilu
  produkcyjnego ani nie zaznaczano posiadania sprzętu w tle.

`equipmentSets` ma OR kompletnych zestawów AND. Katalog przeglądany filtrem OR
nie dowodzi sam w sobie wykonalności. Oba lokalne generatory i przygotowanie
używają wspólnego matchera; etykiety pokazują zgodny zestaw lub jawny fallback.

Mentor nie ma obecnie autorytatywnego sprzętu w walidacji. Nowe `cw418`
wyłączono z jego automatycznej puli i walidacji; pozostałych dawnych propozycji
nie przedstawiamy jako sprzętowo zweryfikowanych. Nie dodano ujawniania profilu
do AI, zgód, migracji, zmian wire ani nowych encji synchronizacji.

## Dotychczasowe dowody

- Python pipeline: **65 PASS**, reprodukowalność/replay/idempotencja i źródła.
- Faktyczny import/filtry/generatory/ilustracje: **77 PASS**.
- Task2:51 focused PASS, detailpage27 PASS; Task3:96 focused PASS.
- Test generatora pakietu offline: RED→GREEN korekt i metadanych w CORE;
  **32 testy Node worker/client PASS**. Obrazy nadal wymagają pełnego pakietu.
- Pierwszy pełny Flutter: **1554 PASS / 1 skipUTC**, analiza bez uwag; snapshot
  poprzedza ostatnie poprawki etykiet i testy szczegółów. Końcowy stabilny przebieg
  jest oddzielną bramką, nie przypisujemy mu wyniku tej wcześniejszej kopii.
- Końcowy przebieg po poprawce carry: **1561 PASS / 0 FAIL / 1 skipUTC**
  (`--concurrency=4`,7:28); pominięty test DST osobno w `TZ=Europe/Warsaw`:
  **1 PASS**. Pełna analiza: **No issues found**. Ścisły scoped format:
  **82 pliki / 0 zmian**, app-version check i fixture generatora offline PASS.
- Prywatny build `lib/main.dart` i generator pakietu: PASS. **489/489** lokalnych
  hashów i długości,48 164 121B; packageId
  `163a0317acdb050b67035f98f9a6e8b3451bce68ebe3f36ba8a0a771815a9777`.
  Sprawdzono zgodność trzech assetów z bieżącymi źródłami,424/6 wpisów,
  dokładny worker ze źródłowego szablonu i dwa wymagane assety w CORE.
- Task5:25 czystych testów backendowych PASS,4 integracyjne jawnie deselected;
  następnie pełny backend z PostgreSQL16/Testcontainers: **628 PASS / 0 FAIL /
  0 skip**,891s. JUnit zweryfikowany niezależnie. Po zmianie wyłącznie nagłówka
  sources_sha256 projekcji (wszystkie424 wpisy i kod identyczne) cały aktualny
  plik templates z bazą ponowiono: **29 PASS**, bez deselect/skip.

Nie zmieniano Flutter3.35.4/Dart3.9.2, lockfile, Drift14, artefaktów SQLite,
Alembic ani konfiguracji wdrożenia. Opcjonalny Wasm dry-run zachowuje wcześniejsze
ostrzeżenia `flutter_secure_storage_web`; wybrany build to JS + CanvasKit/Wasm.
Pozostaje wcześniejszy dług globalnego formatowania10 niezwiązanych plików.

## Poprawki po przeglądach

Każda miała RED→GREEN: importer nie wykonywał bezwzględnego no-op (SQLite
total_changes435→447), poprawiono efektywne nazwy i predykaty różnic; nagłówek,
agregat i picker pokazywały canonical sprzęt mimo zgodnego stepu — teraz używają
wspólnego dopasowania. Detailpage opisuje kompletne alternatywy bez używania
starych metadanych podczas loading/error. Źródła pompek ze stopami na podwyższeniu,
wspięć i zejścia ze stepu poprawiono na właściwe techniki, oddzielając adaptację.

Finalny review wykrył P2: aktywna karta czasowego cw424 pomijała przygotowane
20kg, jeśli prescription szablonu nie miało kg. Rzeczywisty zapis miał czas20
i kgNULL. Minimalna poprawka rozpoznaje jawny Sandbag jako obciążony również
przy czasie, bez zmiany tracking/prescription lub dodawania kg wszystkim
ćwiczeniom czasowym. **35 focused PASS** obejmuje przygotowanie→wznowienie→
aktywny formularz→zapis20s/kg20→historia, ręczne19,5kg, finitevalidation i
kontrolę bodyweight bez kg. Wcześniejszy build/smoke przygotowania nie dowodzi
tej ścieżki; prywatny pakiet489 opisany powyżej poprzedza ten ostatni fix JS.
Końcowy re-review poprawki carry: **P2 ADDRESSED, PASS**, brak nowych P0/P1/P2
w poprawce. **Post-fix compiled browser PASS**: real424/6import, Step-only,
wristroller2,5kg/start/recovery, sandbag15kg odrzucone/20kgstart, izolacja ławek,
fallback nowych obrazów i prawdziwy edytor profilu cancel/save/unknown.
Rzeczywisty cw424 bez kg w prescription przechodzi przygotowanie→recovery→
ActiveSessionPage→„Zapisz czas”→SQLite20s/kg20,1sesja/1draft/1seria/0PR.
21 screenshotów mobile/desktop/text200;0 błędów konsoli i0 żądań zewnętrznych.
Parent sprawdził hashy772 aktualnych wejść, w tym active_session_page, oraz
rzeczywisty readback20s/kg20. Raport i dowody:
`/tmp/opencode/equipment-catalog-20261022/browser/report.md`.
To izolowany rzeczywisty konsument UI/WebSQLite, nie pełne E2E Dziś/auth/sync.
SW był blokowany; compiled smoke nie dowodzi pełnego pakietu offline ani
upgrade412 (ten ma odrębne testy NativeDB). WakeLock przyznano rzeczywistym
uprawnieniem Chromium/CDP, nie atrapą API. Telefon/VoiceOver pozostaje do odbioru.
Osobny Alembic check wykrył zastany drift indeksu
`apple_health_tokens.token_hash`; modele i migracje nie mają lokalnych zmian.
Nie naprawiano go zmianą historycznych migracji ani operacją na produkcji.
Osobne migracyjne head/upgrade PASS0010; `alembic.command.check` FAIL na świeżej
izolowanej bazie. Model, migracja0008 i env są identyczne z954484a/dd4; sprawdzono
hashy i pusty diff. Łączny gate pytest+Alembic nie jest całkowicie zielony mimo
628 PASS: to jawny zastany dług schematu, nie regresja ani naprawa tego dodatku.

Dowody lokalne: `/tmp/opencode/equipment-catalog-20261022/` i
`.superpowers/sdd/2026-10-22-owner-equipment-catalog/`. Brak odbioru na fizycznym
telefonie/VoiceOver, testu własnych nośności sprzętu ani gwarancji flush po
nagłym zabiciu procesu.

## Status końcowy

Kod i dane lokalnego dodatku gotowe, bez publikacji. Nie dodano12 ilustracji,
nie zmieniano profilu produkcyjnego, nie dopuszczono automatycznej inwersji,
skoków ani niezweryfikowanego wyciskania ujemnego przez Mentora. Następnym
krokiem jest osobna decyzja o wydaniu oraz potraktowanie zastanego driftu
Alembica jako jawnej bramki/odrębnej poprawki, nie ukrytego zielonego wyniku.

## Zgoda na wydanie1.23.0+39 i poprawka schematu

Po powyższym odbiorze użytkownik zatwierdził naprawę zastanego driftu oraz commit,
push do main i wdrożenie API/web1.23.0+39. Wersję zmieniono wyłącznie w pubspec,
wygenerowano AppVersion; check i14 testów generatora PASS.

Rozbieżność naprawiono dopasowaniem metadata ORM do istniejącej0008:
`token_hash` zachowuje UNIQUE constraint i ma jawny osobny nonunique index.
Nie zmieniono historycznych migracji, nie dodano rewizji ani produkcyjnego DDL.
RED2FAIL/1PASS → GREEN3PASS na PostgreSQL16: Alembic check bez różnic,
odrzucenie duplikatów token_hash i dopuszczenie wielu NULL.
Readonly preflight potwierdził taki sam fizyczny schemat produkcyjny.
Nowy pełny backend+Alembic i obrazy wydania są osobnymi bramkami; powyższe
historyczne FAIL i628PASS nie są przemianowywane na wynik tej poprawki.
Dokładny raport wdrożenia po publikacji znajdzie się w `docs/releases/`.
