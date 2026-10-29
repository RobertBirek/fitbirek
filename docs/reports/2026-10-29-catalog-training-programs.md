# Odbiór etapów 2 i 3 — katalog i programy treningowe

Data: 2026-10-29. Gałąź: `feat/catalog-and-training-programs`.
Baza: `c9d25873fc792c2c70f66d020450ea406cf10f54`.
Końcowe źródło produktu: `993accdfb1e7160322d070885d13fef5e91e0513`.
Status: implementacja i niezależny odbiór zakończone, bez merge/push/deploy.
Niniejszy raport nie oznacza nowego wydania ani aktualizacji produkcji.

## Zakres

- Etap 2: siedem samodzielnych ćwiczeń `cw425–cw431`, katalog431;
  poprzednie424 rekordy, korekty i424 ilustracje zachowane. Autorskie instrukcje
  PL, nazwy PL/EN i pełny redakcyjny sidecar EN; siedem jawnych pending ilustracji.
  Pipeline XLSX jest reprodukowalny, import przyrostowy i idempotentny.
- Etap 3: role serii rozgrzewkowa/robocza, cele poszczególnych serii, edytor,
  prowadzenie i recovery według stabilnych identyfikatorów celów.
  Jawne rozgrzewki nie tworzą nowych PR i nie stanowią dowodu progresji/trendu.
  Dawne NULL i rekordy nie są przeliczane ani przepisywane.
- Programy A/B z własnych zapisanych szablonów, deterministyczne ABA/BAB według
  kolejnych zaplanowanych dat. Przesunięcia zachowują tożsamość terminu;
  zaliczenie wymaga osobnej decyzji i zakończonej sesji z żywą serią roboczą.
  Wspólny dowód z harmonogramem tygodniowym wykrywa podwójne powiązanie.
- Addytywny Drift14→15, backendowa ochrona omission, backup4 z importem1–3,
  remapowaniem UUID i zachowaniem archiwalnych referencji/tombstone'ów.
  Bez Alembic, zmian zależności, toolchainu lub Web SQLite.

Przewodniki: [katalog](../modules/bodyweight-catalog.md),
[dane](../modules/training-sets-programs-data.md),
[prowadzenie](../modules/training-sets-programs-ui.md),
[backup](../modules/backup.md). Szczegóły programów w aktualnym working set
harmonogramu i przewodnikach danych/UI.

## Końcowe dowody

| Kontrola | Wynik i zakres |
|---|---|
| Pełny Flutter po ostatniej poprawce produktu | **1812 PASS / 0 FAIL / 1 warunkowy skip UTC**, bez wykluczeń |
| Europe/Warsaw po poprawce | **33 PASS / 0 SKIP**, w tym DST i nowe regresje backupu |
| Flutter analyze | **No issues found** |
| Codegen | **17/17** commitowanych artefaktów identycznych; późniejsze zmiany nie zmieniały deklaracji |
| Pełny backend, Python3.12 / PostgreSQL16 Testcontainers | **694 PASS**; stabilny kod backendu, bez wykluczeń |
| DR/privacy po finalnej zmianie eksportera | **5 PASS**, hash eksportera zgodny z finalnym buildem |
| Python tools | **102 PASS**, bez retry w tym przebiegu |
| Node worker/client | **41 PASS** |
| Browser/Nginx fixtures | **13 PASS** w udokumentowanych zgodnych środowiskach |
| Finalny release Web, generator offline | **PASS** dla `993accd`, Flutter3.35.4/Dart3.9.2 |
| Finalny Nginx HTTP | **501/501** hashy i długości zgodnych |
| Diff / wersja / chronione artefakty | PASS; wersja i zależności bez zmian |

Nie sumujemy tych różnych zestawów w rzekomą jedną suitę Fluttera.
Pełny backend uruchomiono podczas pracy nad eksporterem; po ustabilizowaniu
eksportera ponowiono całą suitę DR. Nie twierdzimy, że źródła Fluttera były
niezmienne przez cały wcześniejszy backend run.

### Artefakt Web — wyłącznie testowy

- source: `993accdfb1e7160322d070885d13fef5e91e0513`;
- `main.dart.js` SHA256:
  `0f6b9255b935a4454c9eb0187670ccf21a80e0a2fc8ef0a7d4f15195c99eacd2`;
- packageId:
  `f8d578ed0c92ce9c9f756c025b93dab34af4fc38646e8fbcc8655700e53c3404`;
- **501 plików, CORE31, 48 501 383 B**;
- metadata pozostaje **1.24.0+41**: nie wykonano bumpu ani promocji wydania.

Build: `flutter build web --release --no-web-resources-cdn --no-pub`, następnie
`dart tools/generate_offline_package.dart`. Użyto istniejących przypiętych
zależności; uzupełnienie brakującego cache Web SDK dotyczyło tego samego engine,
nie aktualizacji narzędzi. Nie deklarujemy pełnego Dockerfile builda z pustym
cache i odciętą siecią.

## Niezależny review i naprawione regresje

Etap 2 i zadania etapu 3 przeszły osobne przeglądy spec/quality.
Whole-branch review wykrył brak usuniętej serii `performed` w backupie zwykłej
sesji guided. Naprawa ma sześć nowych regresji v1/v2 oraz wielokrotny roundtrip;
strict importer nadal odrzuca rzeczywiście brakujące lub obce referencje.
Usunięta seria nie zostaje ożywiona, a nieważny dowód celu pozostaje nieważny.
Scoped final review `ecf96e1..993accd`: **P1 ADDRESSED, spec PASS,
quality APPROVE, brak nowych Critical/Important**.

Wcześniejsze poprawki z regresjami obejmują domknięcie referencji zachowanych
programów, zgodność legacy repeat JSON, tożsamość starego callbacku formularza
oraz kolejność własnej kolejki szkicu przed transakcją timera. Nie osłabiano
CAS/nonce/guardów obcego checkpointu ani asercji danych w starych testach.

## Rzeczywisty browser — zakres dowodów

Na artefakcie `ecf96e1` wykonano pełny lokalny compiled UI flow: onboarding,
dwa szablony v2, role/dawki, utworzenie programu, ABA→BAB, przygotowanie/start,
normalne zamknięcia i wznowienie z indywidualnym szkicem, warmup bez PR,
working z PR, historia/podsumowanie i jawne zaliczenie terminu. Odczyt kopii
prawdziwej SQLite był read-only; nie seedowano zapisów domenowych SQL-em.

Na **finalnym `993accd`** wykonano osobno fresh compiled smoke: onboarding,
cw425 z fallbackiem, jawne przygotowanie całego pakietu, pełne zamknięcie,
offline cold-load i kolejny offline reload. Trzy faktyczne odpowiedzi JS miały
nowy hash powyżej; **0 pageerror**, Drift15/integrityOK/katalog431. Izolowany
Nginx bez publikowanych portów zweryfikował wszystkie501 plików przez HTTP.

Autoryzacja była syntetycznym lokalnym fixture sesji; pozostałe API i obce
originy blokowano. Nie jest to produkcyjny auth/sync acceptance.
Długiego wcześniejszego flow nie przypisujemy automatycznie finalnemu buildowi.
Opcjonalny compiled backup roundtrip z usuniętą pojedynczą serią nie został
wykonany: UI nie udostępnia tej operacji na wykonanej serii. Pokrywają go
rzeczywiste testy repo/eksportu/importu, nie deklaracja browser PASS.

## Decyzje wykonawcze i ich konsekwencje

Poniższa lista zachowuje wszystkie decyzje zapisane jako `Ruling:` w ledgerach;
kolejność odpowiada ich podjęciu, nie późniejszemu układowi plików.

1. „Wykonaj od razu” oznacza realizację bez kolejnych pytań technicznych.
   Koszt błędu interpretacji: decyzje mogą wymagać korekty.
2. Nowe siedem ćwiczeń ma jawny fallback, bez cudzych lub płatnie generowanych
   ilustracji. Koszt: siedem grafik czeka na osobne przygotowanie.
3. Praca w osobnym worktree bez automatycznego wdrożenia.
   Koszt: publikacja wymaga osobnej decyzji.
4. LegacyNULL zachowuje dotychczasową semantykę bez backfillu i przeliczania PR.
   Koszt: dawne PR mogą obejmować nieoznaczoną dawną rozgrzewkę.
5. Cele/guidance używają schema2, targetId, stron i reps/time, maks100/blok.
   Koszt: starsze klienty nie obsłużą tych planów.
6. A/B rotuje według zaplanowanych dat; ukończenie jest zawsze jawne.
   Koszt: niewykonane A nie zmienia następnego zaplanowanego B.
7. Core programu jest niezmienny; zakończenie ma jednorazowy cutoff.
   Koszt: zmiana konfiguracji wymaga nowego programu.
8. Backup4 tworzy kopie programów/wyjątków z nowymi UUID podczas restore.
   Koszt: starsze klienty nie zaimportują nowego formatu.
9. API-first dotyczy przyszłej osobno zatwierdzonej publikacji; bez deploy,
   merge/push i versionbump teraz. Koszt: funkcje nie są jeszcze na produkcji.
10. Pełne EN jest redakcyjnym sidecarem, nie nowym językiem interfejsu.
    Koszt: aplikacja nadal wyświetla instrukcje PL.
11. Stary test custom fitness oczekuje teraz backup4 zamiast3, z zachowaniem
    UUID/snapshot/atomic assertions. Ryzyko: nie wolno maskować innych błędów;
    pełny przebieg po korekcie zaliczono bez wykluczeń.
12. Task4 IMPLEMENTED/ACCEPTANCE BLOCKED potraktowano jako ukończoną implementację
    z concernem do review, nie pełne green. Koszt: wymagało późniejszej pełnej
    suity bez wykluczeń; została zaliczona.
13. Analogicznie poprawiono oczekiwaną wersję backupu w activity cloud3→4,
    zachowując attempted/tombstone/history assertions. Ryzyko maskowania innych
    błędów ograniczono zachowaniem asercji i pełnym zielonym przebiegiem.

## Pozostawione ograniczenia

- Timer zachowuje limit3600s; model celu może dopuścić dłuższy czas w budżecie5400s.
  Taki cel można zapisać ręcznie, bez przycinania. To jawny minor, nie pełna
  obsługa całego zakresu timerem.
- Dziewięć istniejących odchyleń formatowania poza zmianą pozostawiono bez zmian;
  format zmienionych plików i diffcheck przechodzą. Brak repo-wide formatPASS.
- Historyczny test browser push raz zwrócił `body=None`; późniejsze100/100,
  a następnie102/102 zaliczono. Przyczyna nieznana, nie zgłaszamy naprawienia flake.
- Runtime fixture początkowo wymagał zgodnego systemowego drivera i package
  config dla worker probe; nie wyłączano asercji service workera.
- Brak fizycznego iPhone/Android/VoiceOver, produkcyjnego auth roundtrip,
  aktualizacji istniejącej pełnej PWA oraz gwarancji flush po crashkill.
- Stare klienty nie rozumieją warmup/schema2/programów/backup4; ochrona omission
  nie zapewnia zgodności semantycznej. Przyszłe wydanie wymaga API-first,
  planu aktualizacji klientów, bumpu wersji i zwykłych bramek wdrożeniowych.

## Lokalne logi odbioru

Logi i artefakty testowe znajdują się w `/tmp/opencode/`, nie na produkcji:

- `final-fix-backup-full-flutter.log`, `final-fix-backup-warsaw.log`,
  `final-fix-backup-analyze.log`;
- `task-5-backend-fix-full.log`, `task-5-backend-fix-final-checks.log`;
- `task5-python-tools.log`, `task5-node-worker.log`;
- `task5-993accd-web-build.log`, `task5-993accd-nginx-runtime.log`,
  `task5-993accd-compiled-smoke.log`, `task5-993accd-artifact-assertions.log`.

Szczegółowe raporty wykonania/review pozostają w planowych workspace'ach
`.superpowers/sdd/2026-10-28-{catalog-basics,training-sets-programs}/` na czas
pozostawienia gałęzi do dalszej decyzji. Część wcześniejszych raportów jest
również w historii Git. Nie usunięto worktree ani nie scalono gałęzi.
