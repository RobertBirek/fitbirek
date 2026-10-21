# Custom Fitness Tests Implementation Plan

> **For agentic workers:** use subagent-driven-development, osobne własności
> backend / Flutter dane / prezentacja. Nie publikować ani nie zmieniać produkcji.

**Goal:** Własne testy dowolnych ćwiczeń, karta i data/godzina, porównywalna historia.
**Architecture:** Profile-owned fitnessProtocols, immutable snapshots w fitnessTest,
Drift14, istniejący outbox i CAS, osobna prezentacja custom/legacy.
**Tech Stack:** Flutter3.35.4 /Dart3.9.2, Drift, Riverpod, FastAPI/JSONB.
**Spec:** `docs/superpowers/specs/2026-10-21-custom-fitness-tests.md`.

## Global Constraints

- Zachować wszystkie stare wyniki, score, daty, treningi/PR/pomiary i katalog412.
- Nie tworzyć nowych encji sync ani definicji udających wyniki0.
- Chronić offline/account epochs, attempted requests, CAS, restore i raw collections.
- Brak Git commit/push/deploy i zapisów produkcyjnych do osobnej zgody.
- Role zapisu i protokół określa spec, nie wizualny formularz.

## Review Focus

1. UTC wykonania vs techniczna data i ręczne historyczne próby.
2. Niezmienność wersji/gałęzie offline i snapshot po usunięciu definicji/wariantu.
3. Stary payload bez rozszerzeń, korupcja/future version i częściowy pull.
4. Restore stare1/2/nowe3 bez utraty snapshotów i identyfikatorów rewizji.
5. Deep link, 320px/tekst200%, obraz offline fallback i A→B→A podczas formularza.

## Zadania

- [x] 1. Backend: TDD walidatory kontraktu, omission po CAS, immutable transitions,
  tombstone unreadable, wspólne fixture i focused/full pytest. Pliki app/sync,
  backend testy i SYNC_EXTENSIONS; bez Alembic zmiany.
- [x] 2. Flutter dane: najpierw opisać publiczny interfejs dla UI, następnie TDD
  domain/model, Drift14/regeneracja, repo/guard/provider, profile merge/quarantine,
  sync/migracja/backup3/restore. Tylko dane/core i ich testy, bez prezentacji/routera.
- [x] 3. UI: TDD karty/protokół/formularze/daty/historia, 3 sekcje Postępów,
  raw legacy chart, wejście katalog/karta/deep link i lokalny font. Własność
  presentation/router/pubspec fonts; interfejsy danych z zadania2.
- [x] 4. Niezależne scoped reviews i poprawki; pełna analiza/testy obu stron,
  runtime candidate i izolowane scenariusze przeglądarkowe bez produkcji.
- [x] 5. Raport gotowości i ograniczeń, propozycja osobno autoryzowanego rollout
  API→web, migracja lokalna13→14 i weryfikacja fizycznego telefonu później.

## Decyzje wykonawcze

- Praca w dotychczasowym /opt/fit: czysty HEAD06d3c95, pliki rozdzielone pomiędzy
  agentów. Brak automatycznych commitów na main; finalny diff podlega review.
- Wyniki standardowych testów pozostają legacy; nie mapować ich wstecz na
  dopiero stworzone, ścisłe protokoły i nie przeliczać historycznych score.

## Kontrola interfejsów i własności

| Zadania | Wspólny interfejs | Rozstrzygnięcie |
|---|---|---|
| Backend ↔ dane Flutter | tests/fixtures/fitness_protocol_v1.json i spec v1 | Stałe nazwy pól; brak/null nullable równoważne, bez mutacji attempted requestów. |
| Dane Flutter ↔ UI | /tmp/opencode/custom-fitness-20261021/flutter-public-api.md | Zamrożone modele, providery, workflow i lease; UI nie pisze bezpośrednio do DAO. |
| Dane Flutter ↔ UI | katalogi tests/progress | Domenowe/repo/sync testy osobno od widget/router/chart testów. |
| UI ↔ główny agent | pubspec.yaml | UI zmienia wyłącznie fonty; wersja dopiero po zakończeniu tego zadania. |
| Dane ↔ backend | liczby wyniku | Powtórzenia to integralne num:18 i18.0 równoważne, stara kolumna jest REAL; bool i ułamkowe powtórzenia odrzucane. |
| Wszystkie | produkcja i Git | Wyłącznie lokalna implementacja; bez deployu, push i zapisów konta. |

Środowisko przeglądarki i izolowany przepis HTTPS/API/PG gotowe w prywatnym
browser/README.md. Rekonesans/about:blank nie jest testem aplikacji. Właściwa
akceptacja wymaga zamrożonych kandydatów i nowych testowych danych, bez produkcji.

## Wykryte problemy weryfikacji

- Backend FULL na początkowo zamrożonym kodzie:617 PASS/1 FAIL. Istniejący
  test odtwarzalności Mentora wykazał stary wygenerowany katalog369 przy
  źródle412. Ruling: odtworzyć wyłącznie publiczny artefakt istniejącym
  backend/tools/generate_mentor_catalog.py i sprawdzić --check/testy Mentora.
  Bez zmian logiki Mentora, zgód, sekretów lub wywołań dostawcy. Koszt decyzji:
  jeden wygenerowany JSON oraz ponowna weryfikacja backendu; nie maskować FAIL
  obniżeniem oczekiwań testu.

## Kandydat i niezależna weryfikacja

- Lokalna wersja funkcji:1.21.0+37; wygenerowany app_version sprawdzony przez
  generate_app_version.dart --check. Licencja OFL fontu dołączona do assetów.
- Wspólne41 przypadków granicznych protokołu (m.in. Unicode80/81, brak/null,
  kg0, metryki, bool, daty30lutego/rok0/sekunda60) przechodzi osobno przez
  backendowy walidator i parser Dart:41/41 po obu stronach. Dane prywatne
  nieużywane, raw fixture pozostaje bez mutacji. To test kontraktu, nie E2E.
- Niezależne recenzje backendu oraz UI uruchomione na scoped diffach; recenzja
  danych wymaga końca prac nad migracją/sync/restore. Pełny build i rzeczywista
  akceptacja przeglądarkowa dopiero na ustabilizowanym źródle.

### Wyniki po integracji części

- Dane: raport końcowy agenta411 PASS w szerokiej serii,22 nowe testy danych;
  nazwy/sygnatury API bez zmian. Niezależna recenzja danych uruchomiona.
- Backend: niezależna recenzja bez potwierdzonych usterek;23 dodatkowe przypadki
  smoke. Ponowny FULL po odtworzeniu katalogu Mentora pozostaje osobnym gate.
- UI: recenzja wykryła3P2: mylący wybór historycznego wariantu o tym samym id,
  brak jawnej metryki przed pierwszym wynikiem, całkowitoliczbowe etykiety osi
  dla ułamkowych wartości. Przekazano do weryfikacji i poprawek z regresjami TDD.
- Niezależny parent check:32/32 testów offline worker/client PASS. Lock, oba
  artefakty Web SQLite, źródłowy katalog412 i wszystkie412 ilustracji są
  identyczne z HEAD; nie zmieniano zależności ani istniejących ilustracji.
- Lokalne obrazy API/migration zbudowane;49 plików manifestu nie zmieniło się
  przez build. Nie są wdrożone. Web/runtime/E2E jeszcze niepotwierdzone.
- Recenzja danych potwierdziłaP2 testem: równoległy lokalny zapis podczas
  oczekującego push/CAS traktował nieopublikowane rewizje jak usunięte przez
  serwer i trwale wstrzymywał profil. Zlecono root-cause fix z zachowaniem
  attempted/digest, zbieżności gałęzi i wykrywania rzeczywistych kolizji UUID.
  Ten FAIL nie jest maskowany wcześniejszymi411 PASS. Pełny build zaczeka na
  poprawkę i ponowną szeroką weryfikację danych oraz3 poprawek UI.

### Zamrożenie po poprawkach

- Backend FULL618/618 PASS po odtworzeniu publicznego artefaktu Mentora; log
  i hashe źródeł w raporcie backendu. Obrazy API/migrator zgodne z manifestem.
- UI po3P2:122 PASS +1 DST skip w UTC, osobny test Europe/Warsaw1/1 PASS.
  Regresje obejmują historyczny/bieżący wariant, metrykę przed wynikiem i osie
  ułamkowe/ujemne/duże z tekstem200%. Brak obietnicy wizualnego E2E.
- Dane poP2:27 focused i421 szerokich PASS, w tym zbieżność obu baz po
  interleaved CAS, ochrona prawdziwej kolizji UUID i prune. Reviewer ponownie
  sprawdza swój pierwotny reproducer; niezależne zamknięcie jeszcze oczekiwane.
- Parent:57 zmienionych Dart files format check PASS (0 zmian), diff check
  i version --check PASS. Pełny web/runtime build ze stage verification
  uruchomiony na zamrożonym manifeście źródeł. Nadal bez publikacji.

### Pełny Docker gate — zapis prób

- Pierwsza próba została anulowana limitem narzędzia120s w build_runner, nie
  otrzymała wyniku testów. Ponowiona bez limitu.
- Kolejna: analiza czysta,1372 PASS/38 FAIL. Wszystkie38 błędów miały wspólną
  przyczynę PathNotFound dla nowego tests/fixtures/fitness_protocol_v1.json;
  allowlista .dockerignore obejmowała test/, lecz nie wspólny tests/fixtures.
- Naprawa: dopuszczenie wyłącznie tego konkretnego publicznego fixture w
  kontekście Docker (bez całego tests/, runnerów, prywatnych danych). To
  root-cause correction konfiguracji buildu, bez osłabiania testów aplikacji.
  Manifest źródeł odświeżony, pełny Docker gate ponowiony. FAIL zachowany
  w web-build-retry.log, kolejna próba w web-build-fixture.log.
- Niezależny reviewer zamknąłP2 CAS:14 PASS, w tym niezmieniony reproducer,
  zbieżność czterech rewizji i nadal aktywne hold dla prawdziwych kolizji/prune.

### Pełny kandydat po naprawie kontekstu

- Docker runtime exit0. Flutter analyze:No issues found; pełny suite1426 PASS,
  1 DST skip w UTC (oddzielny Warsaw test PASS). Build web release i generator
  offline exit0. Istniejące ostrzeżenia dry-run Wasm zależności secure_storage
  nie dotyczą wybranego buildu JavaScript/CanvasKit.
- Parent potwierdził wszystkie1224 pliki zamrożonego manifestu bez zmian podczas
  buildu. Web image sha256:bb9999ed71809e2934ee47ca388d2cf064406c4350421ca6fb62c368669c8be6.
- Wyeksportowany lokalny pakiet1.21.0+37:488/488 hashów i długości PASS,
  48 071 679B; lokalny font i OFL obecne. PackageId
  0fd011a2ea79315ca65aef2f6eba17040ba6113ff9186add7ca5cb29d45092a9.
- Izolowane E2E uruchomione na osobnych PG/API/HTTPS i syntetycznym koncie,
  z użyciem niezmiennych IDs kandydatów. Nie jest to wdrożenie produkcyjne.
  Migracja, custom flow, text200 i backup mają odrębne gate i dowody; wynik
  rzeczywistej przeglądarki jeszcze oczekiwany.

### Rzeczywista przeglądarka — pierwszy kandydat

- Izolowane E2E potwierdziło13→14 z zachowaniem dwóch pełnych pending wierszy
  przed ACK, własny test i wcześniejszą datę, zapis/reload offline, rewizję,
  archiwizację, niezależny drugi kontekst i rzeczywisty backup3 export/import.
  Koniec:pending0, katalog412, zero sesji/serii/PR. Dane tylko syntetyczne.
-61 screenshotów i14 prywatnych trace; parent odczytał listę390, formularze,
  historię320 oraz desktop1280. Ilustracja, jednostka, data, archiwizacja i
  historia czytelne;320 korzysta z pionowego scrolla. Dowody i E2E report
  pozostają prywatnie w /tmp/opencode/custom-fitness-20261021/browser/.
- Browser text200 NIE POTWIERDZONE: CDP przyjęło scale2, lecz zmierzona wysokość
  tekstu nie wzrosła. Nie utożsamiać z rzeczywistą akceptacją skalowania.
  Zlecono diagnozę przyczyny/metody, bez zmiany zachowania aplikacji w teście.
- Parent zauważył na rzeczywistym formularzu komunikat Historia niedostępna
  mimo poprawnego odczytu danych. Przyczyna: hardcoded results:null w karcie
  formularza. Zlecono wąską poprawkę rzeczywistego stanu historii z regresją;
  po niej wymagany ponowny web build i UI smoke na nowym ID. Wyników pierwszego
  kandydata nie przepisywać automatycznie na nowy pakiet.

### Ostatnia poprawka i skuteczny text200

- Formularz wyniku poprawiony: subskrypcja rzeczywistej historii wyłącznie w
  karcie, osobne stany loading/error/empty/data, niezmienny szkic/data/lease.
  Scoped128 PASS +1 wcześniejszy DST skip. Ponowny pełny build uruchomiony;
  różnica od pierwszego manifestu obejmuje wyłącznie presentation i testy.
- Zdiagnozowano nieskuteczność CDP: Flutter3.35.4 czyta computed font-size(html)
  /16. Nowy testowy profil z rzeczywistą preferencją default_font_size32 daje
  skalę2 przy320×844, DPR1 i zoom1, bez podmiany CSS/MediaQuery aplikacji.
- Parent odczytał rzeczywiste screenshoty text200: historia i pełny przycisk
  zapisu osiągalne pionowym scrollem, tekst zawija się i jest powiększony.
  AppBar i niektóre etykiety mają wielokropki; nie deklarujemy pełnego audytu
  WCAG lub VoiceOver. To dowód ograniczonego scenariusza320/text200, nie test
  fizycznego iPhone'a ani całego flow przy wszystkich ustawieniach urządzenia.

## Zakończenie lokalnej implementacji

- Finalny Docker gate1432 PASS/1 UTC DST skip, analiza i release build PASS;
  backend618 PASS. Końcowy pakiet488/488 hashów/długości PASS,48 072 362B,
  image b79bd4eb31dc74cc11c2982f8d8bff850075567d4b238f590db52f2bfc7f5b3e.
- Końcowy re-smoke na dokładnym nowym main hash230e8205e40810846dcc32f14d28cf33f7255fe96700cb6e687621809aae3646
  PASS. W otwartym formularzu rzeczywisty pull wyniku17 z drugiego kontekstu
  nie utracił szkicu23 i wybranej daty. Archiwalny13 zachował wcześniejszą datę.
- Ograniczony rzeczywisty text200 na nowym pakiecie PASS,23 screenshoty; parent
  odczytał formularz ze szkicem i pełny przycisk zapisu przy320/text200.
  Końcowo pending0, katalog412, bez sesji/serii/PR; eksport3 sprawdzony.
- Własny etykietowany stos PG/API/HTTPS usunięty targeted cleanup po normalnym
  zamknięciu browserów i odczycie dowodów. Prywatne dowody/profile i obrazy
  zachowane. Żadnego Git commit/push, deployu lub zapisu produkcyjnego.
- Raport gotowości i warunki osobnego rollout:
  docs/releases/2026-10-21-custom-fitness-1.21.0-37-candidate.md.
  Fizyczny iPhone/VoiceOver nadal do odbioru; nie deklarujemy pełnego WCAG.

## Osobna zgoda na publikację

Po końcowym podsumowaniu użytkownik odpowiedział tak na pytanie o commit/push
i wdrożenie API→web. Wykonanie rozpoczyna się od weryfikacji manifestów, czystego
commitu źródeł i push; następnie świeży backup ze starymi IDs, izolowany restore
nowym migratorem, serializowany migrate oraz API/sender przed webem. Dane domenowe,
hasło, powiadomienia, Caddy, sieci i PostgreSQL runtime bez zmian. Powyższe zapisy
braku zgody/publikacji dokumentują poprzedni etap, nie nową autoryzację.
