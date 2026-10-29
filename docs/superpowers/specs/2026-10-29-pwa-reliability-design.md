# Niezawodność PWA, obrazu sendera i timera

## Intencja i autoryzacja

Użytkownik nie zgłasza bieżących problemów i polecił „działaj dalej po kolei”
po czterech propozycjach: odbiór mobilny/PWA, czytelny komunikat aktualizacji,
automatyczny test uprawnień sendera oraz spójny zakres timera i celu.
To dopracowanie istniejących mechanizmów, nie nowy system aktualizacji.
Wykonujemy kolejno1→2→3→4; niezależne analizy read-only mogą iść równolegle.
Praca w izolowanym worktree, branch `feat/pwa-reliability-and-timers`, baza
`d567c2f9342ef8b66606e7101d4d8f9d07a081ea`.

## Ograniczenia wspólne

- Flutter3.35.4/Dart3.9.2, dotychczasowe zależności, lock i Web SQLite bez zmian.
- Bez migracji, backfillu, zmian wire/backendu domenowego lub starego JSON
  planów/guidance/szkiców. Katalog431 i431 ilustracji pozostają nietknięte.
- Bez czyszczenia IndexedDB, cache, outboxa, deferred lub szkiców; bez logoutu,
  automatycznego odświeżania aplikacji i automatycznej zgody na pełny pakiet.
- Bez zmian ComposeUSER, sekretów, proxy, portów, sieci i produkcyjnych danych.
- Brak automatycznej publikacji tego zadania. Produkcja pozostaje1.25.1+43;
  przyszłe wydanie/versionbump/push/merge/deploy wymaga osobnej decyzji.

## 1. Odbiór mobilny/PWA

Nowy prywatny profil przeglądarki i rzeczywisty compiled artefakt073e11d.
Emulacja mobilnego viewportu/touch, co najmniej390×844, nie fizyczny telefon.
Synthetic session fixture wyłącznie lokalnie; pozostałe API/obce originy
blokowane, bez produkcyjnego logowania i danych. Tworzenie danych wyłącznie
przez UI, odczyt kopii storage read-only; bez seedowania SQL/IndexedDB.

Sprawdzić onboarding, karty ćwiczeń, role i cele serii, zwykłe zamknięcie
całego browsercontext/procesu i wznowienie szkicu, natychmiastowy zapis
odtworzonego celu, historię, przygotowanie pełnego pakietu po jawnej zgodzie,
offline cold-load i zachowanie pending/outboxa. Jeśli dostępne dwa zgodne
artefakty, sprawdzić przejście1.25.0→1.25.1 z istniejącymi pending/szkicem
bez czyszczenia profilu. Nazwać dokładnie wykonane scenariusze i ograniczenia.

Nie zaliczać tego jako Android/iPhone/VoiceOver lub produkcyjnego auth-sync
acceptance. Abortowane API nie jest dowodem ponownej synchronizacji/ACK;
brak pełnego lokalnego API/PG fixture oznacza jawnie niezweryfikowany reconnect.
Realny błąd → osobna reprodukcja/regresja, nie maskowanie harnessu jako produktu.

## 2. Czytelna informacja o aktualizacji

Wykorzystać istniejący bridge offline i mechanizm `reloadRequired`; nie tworzyć
równoległego sprawdzania wersji z losowym HTTP ani nowego service workera.
Nowy komunikat musi jasno odróżniać dostępność aktualizacji od gotowości
pełnego pakietu i od stanu synchronizacji danych. Nie wyświetlać surowych
wiadomości bridge/URL/wyjątków. Bez zmiany protokołu1 i przypinania dokumentu
do shell/package, skipWaiting lub clients.claim.

Wybór wykonawczy: pierwszy zakres to dedykowany panel istniejącego ekranu
„Tryb offline”, nie globalny banner. Nie dokładamy status/hashowania na
każdym uruchomieniu shell i nie zmieniamy właściciela lifecycle. Getter
`OfflineSnapshot.requiresReload`, ścisłe wymaganie error dla reloadRequired,
guard kontrolera oraz canPrepare w UI odmawiają prepare również przy
niepustym packageId/rozmiarze innego pakietu. „Sprawdź ponownie” to wyłącznie
pasywny status, nie reload. Gotowość pakietu nie oznacza zgodnego dokumentu.
Istniejący packageChanged zachowuje odrębny kontrakt świeżej zgody.

Tytuł panelu: „Aktualizacja aplikacji — wymagane odświeżenie”. Opis wyjaśnia,
że może trwać aktualizacja lub nie udało się potwierdzić wersji tej karty;
nie twierdzi bezwarunkowo „nowa wersja gotowa”. Tekst kontrolowany PL,
bez renderowania message bridge. Pending/conflicts i unavailable konta
pozostają odrębnymi informacjami; unavailable nie jest równoznaczne z zerem.

Użytkownik dostaje pasywną informację i instrukcję normalnego zapisania pracy,
zamknięcia wszystkich kart/PWA i otwarcia tego samego profilu online; brak
zalecenia kasowania danych. Gdy istnieje aktywny szkic/timer, nie wolno go
odrzucić ani obiecywać, że background/crash flush jest gwarantowany.
Brak bridge, błąd sieci, unknown protocol lub offline nie może sam w sobie
udawać potwierdzonej nowej wersji. Prepare/cancel pozostają chronione
istniejącym package identity i nową zgodą dla zmienionego rozmiaru.

Testy obejmują reloadRequired, zwykłe notReady/error, aktywny szkic, pending
i konflikty, wznowienie/lifecycle oraz wąski viewport z większym tekstem.
Weryfikacja JS conditional import i prawdziwego compiled Web jest wymagana;
same widgety/fake bridge nie dowodzą działania workera.
Widok/refresh aktualizacji nie może zmienić wierszy realnej SQLite dla
aktywnego szkicu/outboxa; testuje to regresja byte-for-byte, nie sam mock
summary. Globalny banner/eventowy updater pozostaje poza tym zakresem.

## 3. Trwała bramka uprawnień obrazu sendera

Dotychczasowy incydent: API działało jako appUID100, lecz senderUID65532 nie
mógł czytać katalogu `/app/app/push`0700. Test ma wykrywać rzeczywiste
uprawnienia i importowalność kodu w kandydacie, nie tylko zgodność źródeł
lub obecność stringa w Dockerfile. Nie zmieniać użytkownika produkcyjnego.

Wybrać najmniejszy wersjonowany guard wykonywany na rzeczywistym finalnym
obrazie API, obejmując oba istniejące UID/API i sender65532:65532. Musi
sprawdzić przejście katalogów, odczyt wszystkich plików aplikacji oraz
import/kompilację workera; nie uruchamiać jego pętli, połączeń DB, push ani
providerów. Izolacja bez sieci, mountów sekretów i produkcyjnych zmiennych.
Niezgodny obraz daje niezerowy exit, zanim można go promować.

Wybór wykonawczy: `deploy/ops/check-backend-images.py --runtime-image REF
--migration-image REF`, obie opcje wymagane, bez defaultproduction.
Każdy REF rozwiązywany jednorazowo do immutable imageID; potem tylko to ID.
Oba obrazy × APIapp100:101 i sender65532:65532 = cztery obowiązkowe próby.
Potwierdzić rzeczywiste UID/GID oraz domyślnego użytkownika API, nie tylko
samą deklarację maski pliku. Namespace package `app` nie wymaga __init__.py.
Sprawdzać każdy katalog/pliki z wyjątkiem cache, symlinki/specjalne pliki
odrzucać; nie połykać błędów os.walk/scandir. Sentinele: app.main,
app.push.worker, app.push.transport i mentor/exercise_catalog.json.
Zaimportować wszystkie odczytane moduły app bez wykonywania __main__/lifespan.
Dla migratora odczytać/kompilować także migrate.py i migrations, bez importu
wykonującego env.py lub uruchamiania migracji.

Izolowane jednorazowe kontenery: --pull=never, --network none, --read-only,
--cap-drop ALL, no-new-privileges, bez mount/ports/env-file; Python -B ze
skryptem na stdin. Wyłącznie syntetyczny URL konfiguracji, PUSH_ENABLED=false,
bez prawdziwych sekretów. Próba połączenia lub startu workerloop daje błąd.
Timeout kończy kontrolę i sprząta tylko własny unikalnie nazwany kontener.
Wyjście bez tracebacków/env, jedynie bezpieczny etap/ścieżka/klasa błędu.
Nie budować nowej równoległej infrastruktury ani zmieniać Dockerfile.

Regresja obejmuje kontrolowany obraz z katalogiem0700: APIuser może go czytać,
sender nie; guard ma odmówić. Poprawny obraz przechodzi dla obu. Wynik obejmuje
immutable imageID i rzeczywisty UID, nie mutable tag jako jedyny dowód.
Dokumentacja DEPLOY musi wskazać guard w kolejności build→verify→promote.
Promować wyłącznie imageID z wyniku4/4 PASS; zmiana ID wymaga ponownej bramki.
Bez zmian kodu domenowego FastAPI, zależności, Alembic lub Compose.

## 4. Spójność timera i legalnego celu

Zapisany cel v2 o czasie4000s jest legalny w budżecie5400s, lecz dotychczasowy
timer odmawia powyżej3600s. Nie zmieniamy ani nie przycinamy już zapisanych
celów, pomiarów, JSON lub historii.

Wybór wykonawczy: timer pojedynczego, dokładnie wskazanego celu schema2
obsługuje jego legalny zakres do5400s, nadal dokładnie jedną rundę. Ręczny
wielorundowy interwał/EXTRA i legacy zachowują istniejące limity oraz znaczenie;
nie dodajemy targetowych rounds, automatycznego zużywania następnych celów
lub zmiany roli. Zakres musi być spójny w formularzu, silniku, checkpointach,
recovery i walidacji zapisu. Caller nie może przez sam parametr ominąć
autoryzacji dokładnej sesji/slot/target/side/variant.

Testy granic3600/3601/4000/5400/5401, monotoniczny upływ, pauza/resume/tło,
checkpoint→freshprovider→natychmiastowy save, jednokrotny origin i atomowy
set/link/outbox. Obcy cel/strona/wariant i wielorundowy checkpoint nadal
odmawiają bez utraty szkicu. Stare3600s checkpointy i JSON pozostają czytelne.
Kontekst rozszerzenia jest jawny i nieserializowany; nie wnioskować go z
samego rounds==1 lub podsuniętego targetId w extraForms. Wspólne granice
silnika/UI/providerów: manual/EXTRA/v1 1–3600s, rzeczywisty celguidedv2
1–5400s i jedna runda; przygotowanie0–60s/przerwa0–600s bez zmian.
Timer mierzy target.seconds, nie estimated workSeconds; nie mnoży sam przez
liczbę stron. Rzeczywiste odstępstwo4100s przy celu4000s jest dopuszczalne,
do absolutnej granicy5400s. Wszystkie restorecallsite muszą otrzymać poprawny
kontekst: ekran, walidator aktywnego/archiwalnego formularza, recoveryrestart
i aktualizacja checkpointu. Nie dodawać pól do serializacji checkpointu1.

## Odbiór

Każda zmiana zachowania TDD RED→GREEN i niezależny spec/quality review.
Pełny Flutter/analyze, Node worker/client, właściwe testy operacyjnej bramki,
JS compile/compiled Web/offline po końcowych zmianach. Codegen tylko jeśli
zmienią się wymagające tego deklaracje (nie planujemy takich zmian).
Nie zmieniać istniejących testów, aby ukryć problemy. Historyczne baseline
odchylenia formatowania odnotować, nie formatować masowo obcego zakresu.
Raport końcowy oddziela emulator, fake fixture, compiled browser, backend
i fizyczne urządzenie. Bez automatycznej promocji na produkcję.
