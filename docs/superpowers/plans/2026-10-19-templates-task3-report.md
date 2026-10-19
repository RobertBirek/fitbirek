# Zadanie 3 — strukturalne propozycje szablonów Mentora

## Zakres i ochrona istniejących zmian

Praca w `/opt/fit`, bez subagentów, commitów, deployu, podnoszenia wersji,
instalowania SDK lub nowych zależności. Zachowano zastany dirty tree hotfixu,
zadania 1 i zadania 2. Zmiany serwerowe wyłącznie w `backend/`. Bez migracji,
nowych tabel, nowego typu synchronizacji i bez zmiany StructuredPlan schema1.

Przeczytano AGENTS, working set Mentor, `docs/mentor.md`, zatwierdzoną
specyfikację, plan i raport interfejsu zadania 1. Wspólne pliki edytora,
listy i routera rozszerzono, nie zastąpiono ich wcześniejszych implementacji.

## Backend i granica danych

- `backend/app/mentor/templates.py`: nowy rodzaj **create_template** we wspólnym
  kontrakcie `proposal`. Pola: name, minutes oraz uporządkowane exercises,
  z exercise_id, sets, reps ALBO seconds, rest_seconds i nullable weight_kg.
  Brak URL, komend, dowolnych metadanych ćwiczeń lub operacji zapisu.
- Ścisła walidacja po odczycie JSON dostawcy, ponawiana w service: dokładne
  klucze i typy (bool nie jest int), nazwa 1–120, 5–90 minut, 1–10 różnych
  ćwiczeń. Serie 1–5400, reps 1–1800, sekundy 1–5400, przerwa 0–5400;
  kg finite 0–1000 lub null. Operandy sprawdzane przed arytmetyką; suma pracy,
  przerw między seriami i 15 s przejścia na ćwiczenie mieści się w budżecie.
  Reps zgodne z metadata, 3 s/powtórzenie oraz obie strony dla unilateral;
  seconds oznaczają łączną pracę obu stron. Nie przycinamy błędnej propozycji.
- `backend/app/mentor/exercise_catalog.json`: wygenerowany publiczny bundle
  wszystkich aktualnych 369 ID, nazw, typu, mięśnia, sprzętu i tracking/unilateral.
  Zawiera SHA-256 obu źródeł. `backend/tools/generate_mentor_catalog.py`
  odtwarza go deterministycznie z assets; `--check` wykrywa rozjazd.
  Brak runtime fetchu lub zależności od hostowego katalogu Fluttera. Istniejące
  `COPY app ./app` w backend/Dockerfile obejmuje JSON, więc Dockerfile nie wymaga
  zmiany. Po aktualizacji źródłowych assets należy uruchomić generator i check.
- Do dostawcy trafia **maks. 10** publicznych kandydatów, nie cały katalog.
  Intent rozciągania filtruje typ; pozostałe słowa rankują nazwę/typ/mięsień/
  sprzęt, a remisy preferują różne partie. Projekcja developer zawiera tylko
  id/name/tracking/unilateral. Tekst użytkownika jedynie wybiera publiczną pulę,
  nie jest interpolowany do zaufanej projekcji. Nie sięgamy po zdrowie,
  poświadczenia, rekordy profilu ani dowolny przesłany przez klienta kontekst.
- `backend/app/mentor/vendor.py`: rozszerzony JSON Schema i instrukcja modelu,
  bez nowego providercall, endpointu, retry lub zwiększenia limitów modeli.
  Rozszerzony kontrakt jest opt-in: „szablon” albo treningowa intencja z jawnymi
  minutami (również „Poranne rozciąganie ogólne15min”). Zwykła rozmowa i zwykły
  „Ułóż spokojny plan” zachowują dotychczasowy schema/instrukcje i pełny budżet
  kontekstu. Niezamówiona propozycja szablonu jest odrzucana.
  `service.py` dodaje publiczną pulę przed istniejącym input-token preflight;
  waliduje wynik również względem **dokładnej puli tej wiadomości**, nie tylko
  globalnego katalogu. Stare trzy rodzaje propozycji pozostają obsługiwane.
  Dodatkowo sprawdzane są poświadczenia w serializacji propozycji.
- Całość nadal przechodzi istniejące zgody, szyfrowany klucz, limit, trwałą
  rezerwację request_id PRZED HTTP, complete/failed, auth/session/settings epoch
  i odpowiedź replay. Nie zapisuje WorkoutPlans, sesji, serii ani SyncRecord.
  Błędna odpowiedź dostawcy daje kontrolowany błąd Mentora, bez propozycji
  i bez zwrotu rezerwacji; ponowienie request_id nie kontaktuje się z dostawcą.

## Flutter i świadome potwierdzenie

- `mentor/data/mentor_template.dart`: typowany, odłączony intent z ograniczeniami
  rozmiaru, typów i liczb przed mnożeniem. Buduje StructuredPlan dopiero po
  rozwiązaniu wszystkich ID w aktualnym lokalnym katalogu i metadata. Nie ufa
  zdalnemu tracking, nazwom ćwiczeń lub arbitralnym właściwościom planu.
- `mentor_models.dart`: createTemplate i `isSafeToConfirm` dla walidowanego
  intentu; bez zmiany dotychczasowych trzech przypadków.
- `mentor_actions.dart`: osobna **niezapisująca** prepareTemplate. Sprawdza
  konto, trwały binding/offlineAccess, auth generation i aktywną sesję przed
  i po await; czeka na lokalne metadata. Pobiera lease zadania 1 i oddaje
  TemplateEditorSeed z odłączonym planem/nazwą/lease. Próba przekazania nowego
  rodzaju do dotychczasowej metody confirm nie wywołuje zapisów.
- `mentor_page.dart`: przycisk propozycji otwiera realny edytor, bez drugiego
  płatnego wywołania lub automatycznego zapisu/startu. Callback jest związany
  z kontem/generation widoku; przed nawigacją ponownie sprawdza sesję.
  Istniejący rejestr operacji i odzyskiwanie nieznanego wyniku nie są obchodzone.
- `template_editor_page.dart`: seed może przenosić już przechwycony lease,
  walidowany PRZED wyświetleniem prywatnego planu. Zmiana konta podczas edycji
  takiej propozycji Mentora czyści pola i usuwa możliwość zapisu. Sam zapis nadal wymaga osobnego
  potwierdzenia i guarded transakcji zadania 1. Nie aktualizuje źródła propozycji.
- `templates_page.dart` i `app/router.dart`: jawne wejście **„Utwórz szablon
  z Mentorem”** kieruje do istniejącego `/today`, z początkowym szkicem
  „Ułóż szablon: Poranne rozciąganie ogólne 15 min”. Nigdy nie wysyła automatycznie.
  Opisuje limit/koszt i brak zapisu; przy braku konfiguracji oferuje
  **„Ułóż szablon samodzielnie”**, prowadzące do ręcznego edytora.

## Testy, regresje i narzędzia

Nowe testy: `backend/tests/test_mentor_templates.py` oraz
`test/features/mentor/mentor_templates_test.dart`. Istniejący fake ActionsFake
w `mentor_flow_test.dart` otrzymał nową niepiszącą metodę. Istniejące testy
backendu pozostawiono ostatecznie bez zmian, w tym prywatności zwykłej rozmowy
i maksymalnego zatwierdzonego kontekstu.

Backend: Python **3.12.3**, istniejąca `.venv` z hash-locked dependencies
(ponowne `pip install --no-index --no-build-isolation --require-hashes -r
requirements-dev.lock`: wszystkie zależności już obecne; `pip check`: OK),
PostgreSQL przez prawdziwy Docker/Testcontainers. Nowe testy HTTP przechodzą
przez POST FastAPI, prawdziwy parser/protokół vendor z httpx.MockTransport,
trwały ledger i bazę; nie zastępują service.openai_reply. Sprawdzają rezerwację
w momencie HTTP, pojedynczy call/replay, brak domenowych zapisów, malformed,
nieznane ID, rozmiar, finite/bool/overflow, rozjazd katalogu, zachowaną rezerwację
nieudanego wywołania oraz brak ponownego HTTP dla failed request_id.

Flutter: wyłącznie istniejący przypięty obraz
`fit-web:release-1.13.0-26-verified`, `--network none`, bez pub/instalacji.
Nowe testy używają rzeczywistego createRouter, prawdziwego edytora i Drift/outbox:
propozycja → podgląd bez zapisów → edycja → jedno potwierdzenie/jeden plan i
jeden outbox, bez sesji/serii; cancel; zmiana konta w edytorze; zmiana konta
podczas ładowania metadata; nieznane ID; wejście z listy i brak automatycznego
send oraz ręczny fallback. Istniejące testy ledger/unknown outcome, dawnych
propozycji, kontekstu, prywatności, scroll i 320px pozostają w focused zestawie.

RED: początkowy backend zestaw 12 nowych testów nie przeszedł przed
implementacją brakującego modułu. Pierwszy Flutter przebieg wykazał konieczność
czekania na metadata przed konwersją (naprawione) oraz jawnego metadata fixture
widgetów. Szerszy backend przebieg wykrył niepożądane dołączanie publicznego
katalogu do zwykłej rozmowy oraz regresję budżetu dla maksymalnego kontekstu.
Naprawiono to kontraktem opt-in, nie podnoszeniem limitów ani ograniczeniem
zatwierdzonych danych. Tymczasowa adaptacja asercji testu prywatności została
wycofana; oryginalne testy pozostają bez zmian. Początkowy limit 120 s dla
szerszego backend zestawu był za krótki;
ponowiono z limitem 360 s. Wczesne analyze wykryło braces/fake interface;
usunięto przyczyny przed końcową weryfikacją.

Faktycznie potwierdzone końcowe przebiegi klienta:

```sh
docker run --rm --network none -v /opt/fit:/app -w /app \
  fit-web:release-1.13.0-26-verified sh -c \
  'flutter test --no-pub --reporter expanded test/features/mentor \
    test/features/planner/templates_widgets_test.dart test/app/router_test.dart && \
    flutter analyze --no-pub'
```

**101 passed; No issues found.** Po ostatnim drobnym uzupełnieniu ponownego
prefill przy powrocie na zakładkę: nowy plik testów Mentora ponownie
**7 passed**, następnie ponownie **No issues found**. Nie sumować tych liczb
jako różnych testów. Potwierdzono `flutter --version`: Flutter3.35.4/Dart3.9.2.

Backend po naprawie opt-in: nowy plik **19** przypadków i regresja maksymalnego
kontekstu, razem **20 passed**. Końcowy szerszy focused zestaw backendu:
**140 passed in 156.42s**, bez błędów, na ostatecznym kodzie.

```sh
cd backend
.venv/bin/python -m pytest -q tests/test_mentor_templates.py \
  tests/test_mentor_vendor.py tests/test_mentor.py \
  tests/test_mentor_context.py tests/test_mentor_operations.py
.venv/bin/python tools/generate_mentor_catalog.py --check
```

Format ograniczony do własnych/współdzielonych plików przyrostu. Bez zmian
Drift/Freezed/json_serializable; generator kodu nie był wymagany. `git diff
--check` i deterministyczny catalog `--check`: OK.

## Ograniczenia i handoff

- Nie wykonano full Flutter/backend suite — zadanie 4 ma przeprowadzić pełną
  integrację. Nie wykonywano rzeczywistego płatnego providercall, release build,
  PWA ani testu przeglądarkowego. Brak zmiany wersji i wdrożenia.
- Pula 10 jest deterministycznym, ograniczonym doborem publicznych ćwiczeń,
  nie kompletną wyszukiwarką semantyczną ani diagnozą/rekomendacją medyczną.
  Provider ma poprosić o doprecyzowanie przy braku pasujących ćwiczeń. Nie
  twierdzimy, że każda intencja pokryje wszystkie 369 ćwiczeń w jednym call.
- Zachowano istniejący konserwatywny input preflight. Wyłącznie w trybie szablonu
  schema i krótki katalog zużywają część tego samego budżetu; zbyt rozbudowany tekst/kontekst może być
  bezpiecznie odrzucony przed rezerwacją. Nie podniesiono budżetów, aby ukryć to
  ograniczenie. Niepełna odpowiedź modelu (np. output-token cap) jest odrzucana,
  nie powoduje automatycznego płatnego dogenerowania.
- Żadne nowe dane Mentora nie trafiły do Drift/SharedPreferences/eksportu;
  dopiero ręcznie zatwierdzony w edytorze zwykły WorkoutPlan trafia do obecnego
  magazynu i outbox. Historia rozmowy/propozycji pozostaje pod dotychczasową
  polityką prywatności/retencji Mentora.
