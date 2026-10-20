# Rozszerzenie katalogu — wykonanie lokalne

Specyfikacja: zaakceptowane w rozmowie ćwiczenia indywidualne i ogólnorozwojowe w parach, bez kumite; ostatnia lista 30 + 20 opisów. Nie publikować bez osobnej zgody.

- [x] Test RED danych: nowe ID, role partnerów, jawne wymagania sprzętu, niezmieniony prefiks 369.
- [x] Dopisać 23 samodzielne ćwiczenia i 16 podstawowych zadań partnerskich przez XLSX → JSON; 11 wariantów udokumentować bez nowych ID.
- [x] Dodać style „W parach” i „Pilates”, sprzęt i aliasy; wykorzystać istniejące filtry bez migracji bazy.
- [x] Sprawdzić aktualizację starej bazy i brak partnera w generatorze solo; pełne testy/analyze i przegląd.

Decyzje: partner jest wymaganiem wykonania reprezentowanym w istniejącym słowniku sprzętu, aby oba generatory respektowały jego brak. Żadne oznaczenie medycznej zgodności nie jest wyprowadzane z wieku. Zachować istniejące 369 rekordów i metadane. Dawne źródła i instrukcje pozostają niezmienione.

Stan początkowy: czysta feat/frontend-usability. Narzędzia Flutter tylko w kontenerze 3.35.4; Python w izolowanym venv z requirements-catalog.lock. Brak osobnego szczegółowego planu z wcześniejszej rozmowy; ten zapis uszczegóławia zaakceptowane trzy kroki. Bez commit/push/deploy.

## Dowody wykonania

- RED: `python -m unittest tools.tests.test_partner_expansion`: 2 oczekiwane porażki (369 zamiast 408, brak nowych ID).
- GREEN: `python -m unittest tools.tests.test_partner_expansion tools.tests.test_spine_expansion tools.tests.test_execution_conditions tools.tests.test_catalog_pipeline`: 49 PASS. Obejmuje niezmieniony prefiks 369, wszystkie istniejące metadane, XLSX, idempotencję, stare historyczne hashe i walidację źródeł.
- Ruling: nowe style i mięsień są dodatkiem do słowników. Historyczne testy projektują dokładny stary zakres zamiast zastępować hashe; odtworzenie starego rozszerzenia nadal ma dawać 369 wpisów, nie 408.
- Ruling: nowe ćwiczenia nie mają zatwierdzonych ilustracji. Zachowano 369 dotychczasowych i jawnie sprawdzono fallback dla 39 nowych; nie generowano ani nie kopiowano niepasujących obrazów.
- Ruling: siedem indywidualnych wariantów jest dokumentacją powiązań, nie nowymi rekordami ani automatycznie synchronizowanymi wariantami użytkownika. Cztery warianty partnerskie zawarto w regresjach. Koszt: te siedem opisów nie ma osobnych kart w aplikacji.
- Izolacja: czyste drzewo przeniesiono na lokalną gałąź `feat/partner-exercise-catalog`; testy Fluttera na kopii źródła, nie w kontenerach produkcji.
- Niezależny przegląd `fit-reviewer`: brak Critical/Important, potwierdzony prefiks i blokada partnera w generatorach. Brak zgłoszonych minorów.
- Dodatkowy test importu 369 → 408 i filtrów: 25 PASS (`flutter test --no-pub --reporter expanded test/features/exercises/exercises_repository_test.dart test/features/exercises/catalog_asset_integration_test.dart`). Analiza najnowszej kopii: No issues found. Logi `import-latest.log`, `analyze-latest.log` w `/tmp/opencode/partner-catalog-verification/`.
- Pierwszy pełny Flutter suite: 1343 PASS, 1 FAIL (`catalog_prescription_test.dart`: historyczna asercja 369 zamiast aktualnych 408). To nie błąd produktu; zachowano wszystkie testy dawek i budżetów, zaktualizowano tylko oczekiwaną liczebność. Log `tests.log`.
- Końcowy przebieg po korekcie: focused `catalog_prescription_test.dart` PASS, format 6 plików / 0 zmian, analiza No issues found (85.6 s), pełny Flutter suite **1345 PASS, 0 FAIL** (6:48). Nowa kopia źródła, Flutter 3.35.4 / Dart 3.9.2; logi `*-final.log` w tym samym katalogu. Bez pomijania testów. Końcowy kontener zakończył się `FINAL_ALL_PASS`, exit 0.
- `dart tools/generate_app_version.dart --check`: exit 0; wersja bez zmian, brak wydania. Bez commit/push/deploy; zmiany pozostają na `feat/partner-exercise-catalog`.

## Późniejsza, osobno autoryzowana publikacja

Po powyższej lokalnej akceptacji użytkownik polecił commit, push do main i deploy.
Źródło wydania 1.19.0+34: `cc7582c`, fast-forward main i push bez force.
Kanoniczny build runtime: ponownie 1345 Flutter PASS, analyze/version check PASS.
22 Chromium checks oraz publiczne 443/443 hashy PASS. Tylko web, start
2026-10-20 19:32:52 UTC, weryfikacja 19:33:35 UTC. Powyższe wzmianki
„bez publikacji” są historycznym stanem wykonania lokalnego, nie bieżącym.
Szczegóły: `docs/releases/2026-10-20-web-1.19.0-34.md`.
