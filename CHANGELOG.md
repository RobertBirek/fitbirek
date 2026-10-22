# Changelog

Wszystkie znaczące zmiany w projekcie FitBirek są dokumentowane w tym pliku.

Format oparty na [Keep a Changelog](https://keepachangelog.com/), wersjonowanie projektu jest wewnętrzne (brak publicznego API/semver — aplikacja mobilna).

---

## [1.23.0+39] — 2026-10-22

### Added
- 12 ćwiczeń ze stepem, ławką ujemną, poduszką równoważną, rollerem
  i sandbagiem; katalog liczy 424 pozycje. Nowe ilustracje pozostają do przygotowania.
- Alternatywne kompletne zestawy sprzętu, odrębne typy ławek oraz jawna edycja
  wyposażenia profilu z zachowaniem starszych, nieznanych wartości.

### Fixed
- Wersjonowane korekty sześciu wpisów bez zmiany ID, historii i ulubionych;
  wrist roller nie wymaga pary hantli, a step nie oznacza ławki płaskiej.
- Przygotowanie stałego worka20kg oraz zachowanie masy przy zapisie ćwiczenia
  czasowego i wznowieniu sesji. Ręczny rzeczywisty wynik nie jest nadpisywany.
- Deklaracja indeksu tokenu Apple Health zgodna z istniejącym schematem Alembica,
  bez zmiany historycznych migracji lub danych.

### Deployment Notes
- API/Mentor i web: aktualna projekcja katalogu oraz blokada automatycznego
  wyciskania ujemnego bez weryfikacji ławki; bez nowych danych profilu dla AI.
- Bez nowych migracji, zależności i zmian Web SQLite. Korekty oraz metadane
  sprzętu należą do podstawowego pakietu offline; profil nie zmienia się w tle.

## [1.22.0+38] — 2026-10-22

### Added
- Przygotowanie treningu z panelu Dziś przed utworzeniem sesji: sprzęt,
  ustawienie, ostatni ciężar oraz ręczne cele bez wymyślania pierwszych wyników.
- Konfiguracje talerzy ze wspólnego zapasu dla pary hantli i gryfu EZ,
  jawne kg na sztukę/łącznie oraz propozycje progresji przyjmowane ręcznie.
- Zamiana ćwiczenia tylko na trening lub także w szablonie; anulowanie niczego
  nie zapisuje, a cele zachowują się w lokalnym szkicu po wznowieniu.

### Deployment Notes
- Wydanie wyłącznie web. Bez zmian API, migracji, zależności i artefaktów
  Web SQLite; konfiguracja potwierdzonego sprzętu prywatnej instalacji.

## [1.21.0+37] — 2026-10-21

### Added
- Własne testy dla dowolnego ćwiczenia: karta z ilustracją, warunki próby,
  jednostka, kierunek poprawy, wersje zasad oraz rzeczywista data i godzina.
- Wejścia z bazy i karty ćwiczenia, historia porównywalnych wyników bez
  arbitralnej punktacji; wyniki testów oddzielone od treningów, serii i PR.
- Nowe sekcje Postępów: Ciało, Testy, Trening; surowe jednostki dawnych testów.
- Lokalny krój Barlow Condensed do kart wyników, z dołączoną licencją OFL.

### Data And Deployment Notes
- Drift13→14: dwie nullable kolumny bez przeliczenia starych wyników; backup
  format3 zachowuje protokoły/snapshoty, nadal czytane są stare formaty1/2.
- API z ochroną omission nowych rozszerzeń musi poprzedzać web. Bez nowych
  encji sync, migracji PostgreSQL, zmian zależności i artefaktów Web SQLite.
- Kandydat lokalny; bez publikacji i danych testowych na kontach produkcyjnych.

## [1.20.0+36] — 2026-10-21

### Added
- Trzy ćwiczenia z gryfem łamanym EZ: uginanie podchwytem, uginanie nachwytem
  i prostowanie przedramion w leżeniu na ławce.
- Spokojna jazda na rowerze stacjonarnym jako osobna pozycja cardio.
- Opcje sprzętu „Gryf łamany EZ” i „Rower stacjonarny”, metadane i ilustracje
  czterech nowych pozycji. Dotychczasowe 408 ćwiczeń pozostaje bez zmian.

### Deployment Notes
- Wydanie wyłącznie web, bez migracji, zmian API i zależności.
  Osobiste szablony oraz harmonogram nie są automatycznie instalowane u innych
  użytkowników; ich zapis następuje osobno, po publikacji wymaganego katalogu.

## [1.19.1+35] — 2026-10-20

### Fixed
- Uzupełniono ilustracje 39 nowych ćwiczeń `cw370–cw408`, w tym 16 zadań
  partnerskich. Wszystkie 408 ćwiczeń ma teraz dedykowaną ilustrację.
- Testy sprawdzają kompletność katalogu, rejestru, manifestu i plików oraz
  dekodowanie każdej ilustracji w rozmiarze 512×512.

### Deployment Notes
- Wydanie wyłącznie web, bez zmian API, schematów danych i zależności.
  Nowe obrazy są częścią aktualizowanego pakietu offline.

## [1.19.0+34] — 2026-10-20

### Added
- Katalog 408 ćwiczeń: 23 indywidualne i 16 ogólnorozwojowych zadań w parach,
  źródła, role partnerów, błędy, regresje i wskazówki bezpieczeństwa offline.
- Filtry „W parach” i „Pilates”; jawne wymaganie partnera chroni generatory
  treningów solo. Zachowano wszystkie 369 wcześniejszych rekordów i ich ID.

### Deployment Notes
- Wydanie wyłącznie web, bez migracji i zmian API; nowe ćwiczenia mają opisy,
  ale nie mają jeszcze zatwierdzonych ilustracji.

## [1.18.1+33] — 2026-10-20

### Fixed
- Czytelniejsze Ustawienia z osobnymi ekranami powiadomień, kopii zapasowej
  i Apple Zdrowie; bez zmiany uprawnień ani automatycznych operacji.
- Walidacja profilu zachowuje ułamki i obsługuje przecinek dziesiętny;
  zmiana typu testu czyści niepasujący szkic wyniku.
- Responsywne formularze, szablony i podsumowania, cele dotykowe co najmniej
  48 px, czytelny fallback Mentora oraz wykresy z rzeczywistymi odstępami dat.

### Deployment Notes
- Wydanie wyłącznie web; API pozostaje 1.18.0, bez zmian schematów i zależności.

## [1.18.0+32] — 2026-10-20

### Added
- Harmonogram aktywności zewnętrznych i treningów FitBirek: edycja dni, godziny,
  opcjonalnego szablonu i przypomnień, wspólne terminy w Dziś i tygodniu.
- Migracja dawnych ustawień karate/treningu bez nowych zgód; przypomnienia
  zależne od zgód instalacji. Zapis harmonogramu nie tworzy wykonanego treningu.

## [1.17.0+31] — 2026-10-19

### Added
- Własne szablony treningów: kolejność ćwiczeń, cele powtórzeń/czasu i opcjonalny
  ciężar, edycja oraz kopia sesji do nowego lub istniejącego szablonu.
- Postęp wykonania, dodatkowe ćwiczenia w powtarzanym treningu i potwierdzane
  usuwanie sesji z seriami. Pusty trening można zapisać jako szablon lub odrzucić,
  lecz nie oznaczyć jako wykonany bez zapisanej serii.
- Mentor może proponować strukturalny szablon do ręcznego podglądu i zapisu;
  wejście z listy jedynie wypełnia szkic, bez automatycznego płatnego wysłania.

### Deployment Notes
- API przed webem; bez zmian Drift13, Alembic0010, zależności i Web SQLite.
- Rzeczywisty płatny dostawca Mentora oraz fizyczne telefony wymagają odrębnej
  akceptacji; testy kontrolowanego dostawcy nie potwierdzają tych integracji.

---

## [1.16.1+30] — 2026-10-19

### Fixed
- Start treningu z kartoteki ćwiczenia obsługuje niedokończoną sesję zamiast
  kończyć się nieobsłużonym błędem. Wybrane ćwiczenie przechodzi do jawnego
  odzyskiwania; dodanie po wznowieniu wymaga potwierdzonej akcji użytkownika.
- Zakładka Trening pokazuje również niezakończone sesje bez szkicu. Można je
  świadomie zakończyć z zachowaniem zapisanych serii, bez doliczania nieobecności.
  Inne niedokończone sesje pozostają widoczne także podczas aktywnego treningu.
- Wspólna akcja rozpoczęcia/dodania ma blokadę podwójnego kliknięcia, obsługę
  ładowania i błędów oraz ochronę przed spóźnioną zmianą konta. Ćwiczenie bazowe
  nie wymaga tworzenia własnego wariantu.

---

## [1.16.0+29] — 2026-10-19

### Added
- Edycja i usuwanie ręcznych pomiarów z potwierdzeniem oraz atomowym zapisem
  do kolejki synchronizacji. Zachowane UUID, data i pola niewidoczne w formularzu;
  niezastosowane zmiany zdalne blokują nadpisanie. Importy Apple Health nadal
  mają odrębną ścieżkę obsługi.
- Tekstowa historia wyników sprawności, stronicowana po pięć wpisów, z widoczną
  wartością, jednostką i datą już po pierwszym wyniku. Bezpośredni skrót
  „Ułóż plan” w zakładce Trening.
- Trwała kwarantanna nieodtwarzalnych rekordów synchronizacji i blokady operacji
  o nieznanym wyniku, bez utraty oryginalnych żądań i z postępem niezależnych encji.

### Fixed
- Rozpoczęcie treningu nie zastępuje aktywnej sesji. Szkice bloków zachowują
  wartości osobno dla ćwiczenia, strony i wariantu; zużyte checkpointy nie wracają
  po nawigacji. Sesję bez szkicu można jawnie zakończyć bez dopisywania pracy.
- Formularze pomiarów i testów przyjmują przecinek i kropkę, wyświetlają błędy
  przy polach, zachowują tekst po błędzie zapisu i blokują podwójne wysłanie.
- Podsumowanie odróżnia błąd odczytu od ładowania i pozwala ponowić odczyt.
  Usuwanie planów wymaga potwierdzenia; akcje planera chronione przed duplikacją.
- Poprawiono kontrast przycisków, aktywnych chipów, wiadomości użytkownika,
  etykiet wykresów, timera i jasnej dolnej nawigacji. Etykiety przycisków,
  nagłówek RPE i kontrolki przerwy dostosowują się do dużego tekstu.
- Mentor przewija do nowych wiadomości bez przerywania czytania wcześniejszej
  historii. Podgląd kontekstu wiąże zgodę z dokładną treścią notatki lub pomiaru;
  zmiana źródła wymaga ponownego wyboru przed wywołaniem dostawcy.
- Wylogowanie offline blokuje prywatne ekrany pozostałych otwartych kart bez
  reloadu i unieważnia opóźnione wyniki autoryzacji oraz synchronizacji.
- Eksport backupu odczytuje wszystkie kolekcje z jednego spójnego snapshotu.
- API zachowuje pominięte `structure` planu i `side` serii/PR; niezgodna lista
  ćwiczeń powoduje konflikt zamiast cichego usunięcia struktury. Pominięte
  `measurement.data` przy korekcie zachowuje dokładną datę żywego rekordu serwera,
  również milisekundy; konflikt z tombstone'em nie wywołuje pętli ponowień.

### Deployment Notes
- **API przed webem:** nowy klient korzysta z zachowania pominiętej daty pomiaru.
  Nie cofać API do poprzedniej wersji przy aktywnych nowych klientach, również
  uruchomionych z cache. Stare podglądy kontekstu Mentora wymagają odświeżenia.
- Bez zmiany schematów Drift (13) i Alembic (0010), zależności, wersji Fluttera
  ani artefaktów Web SQLite. Przy aktualizacji nie usuwać lokalnych danych.

### Known Issues
- Fizyczny iPhone/Android, VoiceOver/TalkBack oraz rzeczywisty płatny dostawca
  Mentora nadal wymagają osobnej akceptacji. Testy Chromium nie gwarantują
  trwałości storage ani pracy w tle na urządzeniach mobilnych.
- Kwarantanna i blokady zachowują dowody; nieznany wynik push wymaga jawnego,
  autorytatywnego rozstrzygnięcia. Zwykły backup nie jest kopią outboxa i kwarantanny.
- Poprawka daty pomiaru nie odzyskuje precyzji utraconej historycznie w SQLite
  lub backupie. Przy 320 px dolna etykieta „Ustawienia” może być skrócona.
- Pozostaje znane ostrzeżenie Fluttera 3.35.4 dotyczące pokrycia U+FE0F (VS16).

---

## [1.15.0+28] — 2026-10-18

### Added
- Powtarzanie zakończonego treningu z oryginalnego planu (snapshotu) albo
  potwierdzonego wykonania wszystkich serii. Potwierdzenie tworzy nowy UUID;
  nie kopiuje logów ani PR. RPE nowej serii jest puste, a poprzednie RPE służy
  tylko jako odniesienie. Cele i kursor wykonania pozostają lokalnym szkicem.
- Rytm tygodnia dla zapisanych planów: ręczne przesuwanie pojedynczych terminów
  i jawne zaliczanie przez wskazanie zakończonej sesji z rzeczywistą serią.
  Opcjonalna kolekcja `weeklySchedule` synchronizuje się w istniejącym profilu;
  sam start treningu ani upływ terminu nie oznaczają zaliczenia.
- Trendy treningowe tylko do odczytu, w dokładnym zakresie ćwiczenie + nullable
  strona + nullable UUID wariantu. Porównania respektują układ serii i obciążenia;
  brakujące RPE oraz nieporównywalne protokoły są wyjaśniane, nie uzupełniane.
  Bez zmian PR, progresji i celów kolejnego treningu.
- Ekran trybu offline z jawną zgodą na pełny pakiet statyk, rzeczywistym rozmiarem,
  postępem, anulowaniem i ponowieniem. Gotowość wynika z kontroli długości i SHA-256
  faktycznych odpowiedzi cache, nie z trwałej flagi. Zweryfikowany build wydania
  zawiera 443 pliki / 46 814 736 bajtów (około 44,65 MiB); identyfikator pakietu
  jest wyliczany z finalnej treści podczas każdego buildu.
- Core umożliwiający cold start i deep link offline po instalacji podczas wizyty
  online; pełne ilustracje i fallbacki wymagają osobnego przygotowania pakietu.
- Jawny panel odzyskania aktywnej sesji po reloadzie bezpośredniego URL:
  wznowienie zachowuje UUID i szkic, bez automatycznych serii, PR ani startu timera.
- Lokalny mirror 22 fontów zastępczych Roboto/Noto, w tym shard Noto Sans SC
  wymagany dla symbolu ostrzeżenia. Zweryfikowana próbka offline działa bez
  zewnętrznych żądań fontów i bez lokalnych 404/retry po przygotowaniu pakietu.

### Changed
- Drift 13: addytywna migracja 12→13 dodaje wyłącznie nullable
  `user_profiles.weekly_schedule_json`, bez backfillu i nowych encji synchronizacji.

### Fixed
- Nieczytelne lub przyszłe kolekcje profilu trafiają do kwarantanny z trwałym
  wstrzymaniem operacji tego profilu. Zachowano niezmienione attempted payloady
  i lokalne dane; niezależne encje nadal push/pull, a status pozostaje konfliktowy
  do jawnego recovery, zamiast blokowania globalnego pull.
- Start planu z harmonogramu przechodzi do istniejącego ekranu aktywnej sesji
  bez duplikowania nawigatora. Bezpośredni reload sesji nie wymaga obejścia przez Home.
- Pakiet offline zachowuje przypięcie wersji dokumentów i workerów SQLite/Drift;
  brak zaufanej tożsamości jest odrzucany zamiast podania kodu innego wydania.

### Known Issues
- Pozostaje niewyciszone ostrzeżenie silnika Flutter 3.35.4 dotyczące nominalnego
  pokrycia U+FE0F (VS16). Mirror nie gwarantuje obsługi dowolnego Unicode.
- Fizyczny iPhone/Android: MANUAL PENDING / UNTESTED. Brak gwarancji trwałości
  storage, pracy timera/JS, pobierania lub synchronizacji w tle po uśpieniu systemu.
- Nowy klient bezpiecznie odmawia pracy na starym schemacie; samo zamknięcie
  starej karty i Retry nie gwarantuje migracji. Aktualizacja może wymagać zamknięcia
  **wszystkich** kart i okien FitBirek, **także zablokowanego**, pełnego zamknięcia
  PWA i ponownego otwarcia. Retry jest tylko opcjonalnym sprawdzeniem.
  Nie usuwać danych aplikacji. Rzeczywisty retest dwóch pełnych buildów potwierdził
  migrację po pełnym wyjściu z przeglądarki i ponownym otwarciu tego samego profilu,
  z zachowaniem niepustego outboxa przed ACK. Nie potwierdza to migracji przy
  otwartych starych kartach ani zachowania fizycznego iPhone'a.
- Prywatne konta wielu użytkowników pozostają DEFERRED — to plan na przyszłość,
  nie funkcja tego wydania. Aplikacja nadal jest osobista, dla właściciela.

---

## [1.14.0+27] — 2026-10-17

### Added
- Prowadzony trening z trwałym checkpointem i wznowieniem po ponownym otwarciu
  aplikacji; zapis faktycznych serii nadal wymaga jawnego zatwierdzenia.
- Podsumowanie planu względem wykonania, powody doboru ćwiczeń oraz cele
  z katalogowych zaleceń z widocznym źródłem, bez dopisywania wykonanych serii.
- Własne warianty ćwiczeń ze stabilnym UUID; historia, PR i progresja rozdzielone
  według ćwiczenia, strony i wariantu. Definicje wariantów i zestawy filtrów
  działają offline i synchronizują się w profilu po zalogowaniu.
- Katalog 369 ćwiczeń, w tym 19 pozycji dla kręgosłupa, oraz sześć nowych
  ilustracji `cw364`–`cw369`.
- Lokalne fonty Inter oraz mirror fontów zastępczych Roboto/Noto: bez zewnętrznych
  żądań fontów w zweryfikowanym scenariuszu przeglądarkowym.

### Fixed
- Poprawiono opis zapisanych filtrów: zestawy nie są już wyłącznie lokalne.

### Known Issues
- Flutter 3.35.4 nadal zgłasza ostrzeżenie pokrycia U+FE0F (VS16), mimo poprawnego
  renderowania zweryfikowanej próbki emoji. Lokalny mirror nie obejmuje całego
  Unicode; nie wyciszono diagnostyki ani nie zmieniono silnika.

---

## [1.13.0+26] — 2026-10-16

### Added
- Rekordy osobiste i porównania serii osobno dla lewej/prawej/obu stron oraz
  historii bez oznaczenia; lokalne migracje Drift 8→9→10 bez backfillu.
- Nazwane zestawy filtrów przypisane do konta na urządzeniu oraz interwały
  z jawnym, atomowym zapisem faktycznych sekund pracy.
- Generator strukturalnych planów z aktywnych filtrów, budżetem czasu,
  sekcjami i wymianą bloków; cele w podglądzie bez automatycznego zapisu serii.
- Sześć warunków wykonania i pięć pozycji dla wszystkich 363 ćwiczeń.
- Propozycje powtórzeń przy stałym ciężarze na podstawie dwóch zakończonych
  sesji, strony i RPE; bez automatycznego zwiększania ciężaru.

### Fixed
- Zabezpieczono operacje asynchroniczne przy wylogowaniu, izolację historii
  uszkodzonych planów i zgodność usuwania planów ze starszymi klientami.

---

## [1.12.0+25] — 2026-10-16

### Added
- Rozszerzono katalog do 363 ćwiczeń z kompletem ilustracji: 47 nowych pozycji
  z sandbagiem, kółkiem do brzucha, jogą, kalisteniką i tai chi siedzącym.
- Dodano wyszukiwanie PL/EN i filtry stylów, sprzętu oraz mięśni głównych
  i wspierających, z licznikami i klasyfikacją dostępną offline.
- Dodano rejestrowanie czasu pracy i stron Lewa/Prawa/Obie, z zachowaniem
  strony w lokalnej bazie Drift 8, backupie i synchronizacji. Automatyczne PR
  dla jawnych stron pozostają wyłączone do osobnego rozszerzenia modelu.

---

## [1.11.0+24] — 2026-10-16

### Added
- Dodano 112 ilustracji szczegółów ćwiczeń `cw139`–`cw250` z Partii 28–46:
  ćwiczenia nóg i pośladków, stabilizację tułowia, brzuch, kondycję,
  skakankę, bieżnię oraz rozgrzewkę i mobilność. Wszystkie 316 ćwiczeń
  w katalogu ma teraz ilustracje.

---

## [1.10.0+23] — 2026-10-15

### Added
- Dodano 126 ilustracji szczegółów ćwiczeń `cw013`–`cw138` z Partii 07–27:
  wyciskania, wiosłowania, ćwiczenia barków, ramion i chwytu, przysiady,
  wykroki oraz wejścia na ławkę. Katalog zawiera teraz 204 ilustracje.

---

## [1.9.0+22] — 2026-10-12

### Added
- Dodano dwanaście ilustracji szczegółów ćwiczeń `cw001`–`cw012` z Partii 05
  i 06. `cw007` i `cw011` mają po trzy kadry; pozostałe po dwa.

---

## [1.8.0+21] — 2026-10-12

### Added
- Dodano sześć ilustracji szczegółów ćwiczeń `cw268`–`cw272` oraz `cw275`,
  po dwa kadry każda.

---

## [1.7.0+20] — 2026-10-12

### Added
- Dodano ilustracje szczegółów ćwiczeń `cw314`–`cw316`.

---

## [1.6.0+19] — 2026-10-11

### Added
- Dodano ilustracje szczegółów ćwiczeń `cw282`–`cw313`.

---

## [1.5.1+18] — 2026-10-11

### Fixed
- Poprawiono ilustrację `cw267`: dłonie są splecione za głową podczas wyprostu
  odcinka piersiowego na ławce.

---

## [1.5.0+17] — 2026-10-11

### Added
- Dodano ilustracje szczegółów ćwiczeń `cw254`, `cw255`, `cw258`–`cw260`,
  `cw263`, `cw266`, `cw267`, `cw273`, `cw274`, `cw276`, `cw277` oraz
  `cw279`–`cw281`.

---

## [1.4.6+13] — 2026-10-10

### Added
- Dodano ilustracje do szczegółów ćwiczeń `cw257` (rozciąganie motylkowe) i
  `cw264` (rozciąganie łydki przy ścianie).

---

## [1.4.5+12] — 2026-10-10

### Changed
- Spolonizowano pole `nazwaPl` całego katalogu ćwiczeń; identyfikatory `cw...`
  oraz nazwy angielskie nie uległy zmianie.
- Wyszukiwanie po nazwach angielskich pozostaje dostępne, także dla istniejących
  instalacji aktualizujących katalog lokalnie.

---

## [1.4.4+11] — 2026-10-10

### Fixed
- Uzupełniono szczegóły ćwiczenia `cw261` o poprawioną ilustrację.

---

## [1.4.3+10] — 2026-10-09

### Fixed
- Uzupełniono brakującą ilustrację w szczegółach ćwiczenia `cw265`.

---

## [1.4.2+9] — 2026-10-09

### Added
- Mentor: mikrofon obsługuje pełny turn głosowy - automatycznie transkrybuje,
  wysyła pytanie i odtwarza odpowiedź.

### Fixed
- Mentor: zablokowane autoplay pozostawia przygotowaną odpowiedź do ręcznego
  odtworzenia bez drugiego żądania ElevenLabs.

---

## [1.4.1+8] — 2026-10-09

### Fixed
- Mentor: przycisk wyboru kontekstu jest aktywny tylko dla niepustej wiadomości.
- Mentor: lista głosów ElevenLabs akceptuje prawidłowe odpowiedzi dostawcy do 128 KiB.

---

## [1.4.0+7] — 2026-10-08

### Added
- Mentor: wybierany dla każdej wiadomości kontekst z osobnymi zgodami na
  trening, profil, masę, notatkę treningową i dane Apple Health oraz podglądem
  wyboru przed wysłaniem do OpenAI.
- Mentor: persona i profile modelu oraz ograniczenie historii treningów do
  24 sesji z ostatnich 12 tygodni.

---

## [1.3.1+6] — 2026-10-07

### Added
- Komiksowa ilustracja 90/90 hip stretch z oznaczeniem głównych i wspierających
  partii mięśni w szczegółach ćwiczenia.

---

## [1.3.0+5] — 2026-10-05

### Added
- Health: import Apple Zdrowie przez świadomie uruchamiany Skrót iOS, odwoływalny
  token importu oraz synchronizowane offline próbki masy i kroków.
- Push: uwierzytelniony rejestr instalacji, niezależny sender i monitoring
  Web Push z opt-in w ustawieniach oraz workerem `/push/`.
- Mentor: rozmowy i zatwierdzane propozycje treningów, szyfrowane lokalnie
  poświadczenia dostawców oraz niezależny overlay klucza głównego dla API.
- Administracyjne resetowanie hasła z interaktywnym potwierdzeniem oraz procedury
  odzyskiwania konta i danych po awarii.
- Ustanowiono zweryfikowaną bazę recovery obrazów dla przyszłych operacji;
  nie została jeszcze użyta w produkcyjnej operacji.

---

## [1.2.0+4] — 2026-09-14 (wdrożone 2026-09-15)

### Added
- Rozmowa z mentorem jako główny ekran Dziś: krótkie podpowiedzi czasu i energii,
  historia rozmów, usuwanie i edytowalna pamięć zatwierdzana przez użytkownika.
- OpenAI Responses ze ścisłym schematem propozycji oraz ElevenLabs STT/TTS:
  krótkie nagranie, edycja transkrypcji przed wysłaniem i osobny gest odtwarzania.
- Jednorazowe formularze kluczy w Ustawieniach, szyfrowanie Fernet po stronie
  serwera, odrębne zgody, jawne testy połączenia i lokalne limity użycia.
- Potwierdzane, edytowalne propozycje treningu/serii z trwałą deduplikacją
  istniejącego repozytorium i outbox; klasyczny trening dostępny offline.
- Opcjonalny, wyłącznie dla API overlay mentora z niezależnym kluczem głównym;
  dokumentacja bram prywatności/dostawców/sprzętu, retencji i rotacji.
- Chronione pełne DR PostgreSQL zachowuje szyfrogramy `mentor_credentials`
  (zamiast wcześniejszego wykluczenia). Odtworzenie wymaga oryginalnego klucza
  głównego z osobnego escrow i powiązania konta/dostawcy. Szyfrowany Restic bez
  zmian; lokalne bundle root `0700`, pliki `0600`. Eksport Flutter nadal nie
  zawiera kluczy ani szyfrogramów mentora i nie jest pełnym DR serwera.

---

## [1.1.0+3] — 2026-09-11

### Added
- Integracja Apple Zdrowie przez ręcznie uruchamiany Skrót iOS: wybrane próbki masy w kg oraz dzienny wynik kroków ręcznie potwierdzony z aplikacji Zdrowie (bez sumowania źródeł iPhone/Apple Watch).
- Odwoływalny, przeznaczony wyłącznie do importu token, jednorazowe ujawnienie po zgodzie na przesyłanie danych zdrowotnych na VPS, rotacja i status w Ustawieniach.
- Osobne próbki zdrowotne synchronizowane do pamięci offline, masa w Postępach i podsumowanie na Dziś; import nie zastępuje pomiarów ręcznych.
- Instrukcja ręcznego utworzenia Skrótu i kontrakt JSON. Test rzeczywistego iPhone pozostaje bramką akceptacji; brak bezpośredniego HealthKit w PWA.
- Pełna instrukcja „Jak połączyć Apple Zdrowie” w Ustawieniach: osobna przewijalna strona dostępna offline, konfiguracja Skrótu krok po kroku, kopiowanie JSON z placeholderami bez tokenu, rozwiązywanie błędów i zasady prywatności (w tym samym niewdrożonym wydaniu 1.1.0+3).

### Fixed
- Zgodność synchronizacji ze starszymi PWA: próbki zdrowotne są zwracane wyłącznie klientom deklarującym ich obsługę; nowy klient jednorazowo odtwarza pominiętą historię bez naruszania outbox.
- Niezależny pełny kursor synchronizacji w Drift v7 zapobiega pomijaniu próbek przez równolegle działającą starszą kartę PWA współdzielącą lokalną bazę.
- Blokada importu, rotacji i odwołania tokenu jest zgodna z blokadami kontroli kluczy obcych PostgreSQL podczas równoległego zapisu synchronizacji.

---

## [1.0.1+2] — 2026-09-11

### Fixed
- Wersja aplikacji i numer buildu pochodzą wyłącznie z `pubspec.yaml`; ustawienia i eksport backupu pokazują ten sam pełny numer. Wersja schematu backupu pozostaje bez zmian.
- Generator stałych Dart i kontrola `--check` wykrywają nieaktualne metadane przed budowaniem obrazu web; dodano testy zgodności wersji.

---

## [0.8.1] — Prawdziwy release keystore + drobne porządki

### Added
- `android/release-key.jks` + `android/key.properties` — wygenerowany prawdziwy keystore do podpisywania release buildów (alias `release`, ważny do 2054). Oba pliki poza kontrolą wersji (`android/.gitignore` już zawierał odpowiednie wzorce `key.properties` / `**/*.jks` — zweryfikowane, sekrety nigdy nie trafiły do repo).
- `android/app/build.gradle.kts` — dodano blok `signingConfigs { create("release") {...} }` wczytujący dane z `key.properties`; `buildTypes.release.signingConfig` przełączony z `debug` na `release` (z automatycznym fallbackiem na `debug`, gdy `key.properties` nie istnieje — np. świeży checkout repo bez wygenerowanego keystore).

### Fixed
- `lib/core/models/exercise.dart` — usunięto nieaktualny komentarz/TODO z ery "starter pack 38 ćwiczeń" i odniesienie do nieistniejącego skryptu `build_exercises.dart`; zaktualizowano na opis zgodny ze stanem faktycznym (realna baza 316, `tools/xlsx_to_json.py`).

### Verified
- `flutter build apk --release` — sukces (143.7s), APK 62.8MB (debug: ~191MB — R8/minifikacja działa poprawnie).
- `apksigner verify --print-certs` — potwierdzony podpis prawdziwym certyfikatem release (SHA-256 `72:12:8A:...:88:CF:49`), nie debug-keyem.
- `aapt dump badging` na release APK — `package: com.fitbirek.training`, `application-label: 'FitBirek Training'` — konsystencja zachowana.
- `flutter analyze` — brak problemów.

---

## [0.8.0] — Realna baza ćwiczeń (316 pozycji, autor: Robert Birek) zastępuje bazę syntetyczną

### Added
- `tools/xlsx_to_json.py` — konwerter Excel → JSON. Czyta zakładkę `BAZA_GLOWNA` (openpyxl, `data_only=True`) z `tools/source_data/baza_cwiczen_316.xlsx`, waliduje fail-fast (nagłówek, enumy `Typ`/`Poziom`, unikalność i format id `cwNNN`, dokładnie 316 pozycji), normalizuje pole `Sprzet` (aliasy, rozbijanie "X lub Y" / "X/Y" / "X opcjonalnie", fallback `["Masa własna"]`), rozdziela pola z separatorami (przecinek dla `Partie_wspierajace`, średnik dla `Kluczowe_wskazowki`/`Czeste_bledy`), zapisuje `assets/data/exercises.json`.
- `assets/data/exercises.json` — całkowicie zastąpiony: 316 PRAWDZIWYCH, ręcznie kuratorowanych ćwiczeń autorstwa Roberta Birka (2026-08-08), z realnymi źródłami wiedzy (Athlean-X, Muscle & Strength, Healthline, Harvard Health, GMB Fitness, Calisthenics Family, ChairTaiChi.org, Peloton, Cleveland Clinic, AAOS OrthoInfo, Barbend) — zastępuje syntetyczną bazę z 0.7.0.
- `lib/core/utils/partia_kategoria.dart` — funkcja czysta `mapToKategoria(partiaGlowna, {wzorzecRuchu})`, redukująca ~163 granularne wartości `Partia_glowna` z realnej bazy do 10 prostych kategorii UI (Klatka, Plecy, Barki, Biceps, Triceps, Pośladki, Nogi, Brzuch, Cardio, Mobilność), bez zmiany schematu Drift/Freezed. 100% pokrycie zweryfikowane wobec wszystkich rzeczywistych wartości z bazy.
- `test/unit/partia_kategoria_test.dart` — ~14 testów jednostkowych dla `mapToKategoria()` (kategorie podstawowe, precedencja przy wieloznacznych wartościach, branch `Full body` warunkowany `wzorzecRuchu`, fallback dla wartości resztkowych, case-insensitivity).
- Sprzęt: dodano `Krzesło` i `Ręcznik` do `AppConstants.dostepnySprzetOpcje` (realna baza wykorzystuje ćwiczenia z krzesłem — np. Chair Tai Chi — i ręcznikiem, nieobecne w bazie syntetycznej).
- `Typ` ćwiczenia: `AppConstants.typyOpcje` rozszerzone z 4 do 10 wartości (`Hipertrofia`, `Siła`, `Wytrzymałość`, `Cardio`, `Rozgrzewka`, `Regeneracja`, `Explosive`, `Rozciąganie`, `Izometria`, `Mobilność`), zgodnie z rzeczywistą taksonomią użytą w Excelu.

### Fixed
- **Krytyczne**: `active_session_page.dart` — stała `_typyIzometryczne` używała nieaktualnej wartości `'Izometryczne'`, niezgodnej z realną wartością `'Izometria'` z Excela. Bez tej naprawy stoper czasu dla 14 ćwiczeń izometrycznych (plank, wall sit itd.) w ogóle by się nie uruchamiał.
- `lib/features/exercises/providers/exercises_providers.dart` (`filteredExercisesProvider`) i `lib/features/planner/domain/plan_generator.dart` (grupowanie kandydatów) — filtrowanie/grupowanie po partii ciała przełączone z surowego `partiaGlowna` na `mapToKategoria(ex.partiaGlowna, wzorzecRuchu: ex.wzorzecRuchu)`, żeby UI (10 kategorii) poprawnie dopasowywało 163 granularne wartości z realnej bazy.
- `lib/features/onboarding/presentation/pages/onboarding_equipment_page.dart` — dodano ikony dla nowego sprzętu (`Krzesło` → `Icons.chair`, `Ręcznik` → `Icons.dry_cleaning`).
- `test/features/exercises/exercises_repository_test.dart` — enumy walidacyjne (`validTyp`, `validSprzet`) rozszerzone zgodnie z realną taksonomią; dodano test pokrycia `mapToKategoria()`; test unikalności nazw ćwiczeń zmieniony z prostego `nazwaPl` na klucz złożony `nazwaPl+partiaGlowna+typ` — realna baza zawiera zamierzone, legalne duplikaty nazw różniące się partią/typem (np. `Band pull-apart`, `Seated cat-cow` jako osobne warianty).

### Deprecated
- `scripts/generate_exercises.py` — generator bazy SYNTETYCZNEJ z 0.7.0, oznaczony jako deprecated. Zachowany wyłącznie jako historyczny wzorzec kodu (funkcja `add_family()`); NIE uruchamiać — nadpisałby realne dane. Aktualne źródło danych to `tools/xlsx_to_json.py`.

### Verified
- `flutter analyze` — brak problemów.
- `dart format .` — bez zmian formatowania poza konwersją.
- `flutter test` — **122 testy, wszystkie przechodzą** (`+122: All tests passed!`).
- `flutter build apk --debug` — sukces; `aapt dump badging` potwierdza `package: com.fitbirek.training`, `application-label: 'FitBirek Training'`.
- `flutter build web --release` — sukces (ostrzeżenia WASM dotyczące `flutter_secure_storage_web`/`dart:js` są nieszkodliwe dla standardowego JS builda).

---

## [0.7.0] — Rozszerzenie bazy ćwiczeń 38 → 316 + import przyrostowy

### Added
- `assets/data/exercises.json` rozszerzony z 38 do 316 ćwiczeń (`cw001`-`cw316`), zgodnych ze schematem Freezed (`Exercise`, 16 pól) i pełną walidacją: unikalne id/nazwyPl/nazwyEn, zgodne enumy (`poziom`, `typ`), sprzęt zawsze podzbiór `AppConstants.dostepnySprzetOpcje`. Rozkład per `partiaGlowna`: Nogi 55, Brzuch 45, Cardio 35, Klatka 32, Pośladki 30, Plecy 27, Barki 25, Mobilność 25, Biceps 21, Triceps 21.
- `scripts/generate_exercises.py` — generator Python używany do wytworzenia i scalenia nowych 278 pozycji (funkcja `add_family()` grupująca warianty ćwiczeń o wspólnym wzorcu ruchu/wskazówkach/błędach, funkcja `merge_and_write()` do przypisania sekwencyjnych ID i zapisu finalnego JSON). Pozostaje w repo jako wzorzec do kolejnych rozszerzeń bazy.
- Sprzęt "Bieżnia" (zdefiniowany w `AppConstants.dostepnySprzetOpcje`, ale dotąd nieużywany przez żadne ćwiczenie) doczekał się realnych pozycji: marsz z inklinacją, interwały HIIT na bieżni.

### Fixed
- **Krytyczne**: `ExercisesRepository.importFromAssetsIfEmpty()` (blokował import na urządzeniach z niepustą tabelą — nowe ćwiczenia nigdy nie trafiłyby do istniejących instalacji) zastąpiony przez `syncFromAssets()` — import przyrostowy, wstawiający tylko ćwiczenia o `id` jeszcze nieobecnym w bazie lokalnej. Nie nadpisuje/nie usuwa istniejących wierszy, więc `ulubione` ustawione przez użytkownika jest zachowane. Dodano `ExercisesDao.getAllIds()` do wsparcia tej logiki. Zaktualizowano call site w `lib/main.dart`.

### Docs
- `CONTRIBUTING.md` — poprawiono niezgodność nazwy pola (`sprzetWymagany` → `sprzet`, zgodnie z rzeczywistym modelem), usunięto nieaktualną wzmiankę o `applicationId` (naprawione w 0.6.1), dodano wskazówki o imporcie przyrostowym i generatorze `scripts/generate_exercises.py`.
- `README.md` — zaktualizowano opis bazy ćwiczeń (316 zamiast "38, docelowo 316"), usunięto zrealizowaną pozycję z tabeli "Znane ograniczenia".

---

## [0.6.1] — Drobiazgi: ujednolicenie applicationId + prawdziwy gong

### Fixed
- Ujednolicono Android `applicationId`/`namespace`: `com.fitbirek.fitbirek_training` → `com.fitbirek.training` (zgodnie z docelową nazwą pakietu projektu). Zaktualizowano `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml` (`android:label` → "FitBirek Training"), przeniesiono `MainActivity.kt` do nowej struktury katalogów `android/app/src/main/kotlin/com/fitbirek/training/`, usunięto starą strukturę. Zweryfikowano `flutter build apk --debug` (SUCCESS) + `aapt dump badging` potwierdzający poprawny package name w gotowym APK.

### Added
- Dodano rzeczywisty plik `assets/sounds/gong.mp3` (wygenerowany efekt dźwiękowy — pojedyncze uderzenie gongu, ~2s). `GongService` nadal zachowuje fallback na `SystemSoundType.alert` na wypadek problemów z odtwarzaniem audio na urządzeniu, ale nie jest już to jedyna dostępna ścieżka dźwiękowa.

### Docs
- Zaktualizowano README.md — usunięto z tabeli "Znane ograniczenia" pozycje `gong.mp3` i `applicationId` (zrealizowane), pozostawiono VPS deployment i rozszerzenie bazy ćwiczeń jako wciąż otwarte.

---

## [0.6.0] — Wykresy postępów (fl_chart) + testy per-feature

### Added
- `lib/core/widgets/weight_line_chart.dart` — wykres liniowy wagi w czasie (fl_chart), sortowanie chronologiczne wewnątrz widgetu, tooltip z datą i wagą, gradient pod linią, placeholder gdy < 2 pomiary
- `lib/core/widgets/test_score_chart.dart` — wykres liniowy score (0-100) testów sprawnościowych w czasie, z `ChoiceChip` do przełączania typu testu; buduje listę dostępnych typów dynamicznie na podstawie zapisanych wyników (nie zakłada z góry, które testy user wykonywał)
- Integracja obu wykresów w `progress_page.dart` — sekcje "Waga w czasie" i "Progres testów sprawnościowych" wstawione przed listami PR/pomiarów; podłączenie dotychczas nieużywanego `allTestResultsProvider`

### Tests (73 nowe testy, +73 → 168 łącznie w projekcie)
- `test/features/progress/test_score_calculator_test.dart` — 18 testów: wszystkie 11 typów testów sprawnościowych, progi low/high, clamping, zaokrąglanie
- `test/features/progress/formatters_test.dart` — 17 testów: date/dateTime/time/dayMonth/weekday/duration/weight/deltaPercent
- `test/features/progress/pr_detector_test.dart` — 10 testów dedykowanych (rozszerzenie poza 2 testy smoke w `widget_test.dart`): epley1Rm, isNewRecord, przypadki brzegowe (0/ujemne wartości)
- `test/features/planner/plan_generator_test.dart` — 11 testów: filtrowanie sprzętu/poziomu, skalowanie liczby ćwiczeń czasem, priorytety wg celu, przypadki brzegowe
- `test/features/progress/measurements_repository_test.dart` — 7 testów na `AppDatabase.forTesting(NativeDatabase.memory())`
- `test/features/progress/tests_repository_test.dart` — 6 testów (w tym auto-przeliczanie score przy zapisie)
- `test/features/progress/prs_repository_test.dart` — 6 testów (w tym auto-przeliczanie 1RM wg Epley przy zapisie)

### Fixed
- `MeasurementsDao`/`TestsDao`/`PrsDao`/`MoodDao.watchAll()` (i pochodne `getLatest`/`getHistoryFor*`) — sortowanie było oparte wyłącznie na `data` (kolumna `DateTimeColumn` w SQLite ma rozdzielczość sekundową), co dawało niezdeterminowaną kolejność przy kilku insertach w tej samej sekundzie. Dodano `id` jako drugorzędne kryterium sortowania (`OrderingTerm.desc(t.id)`) — wykryte przez nowe testy repozytoriów, naprawione w kodzie produkcyjnym (nie tylko w teście)

---

## [0.5.0] — Notyfikacje lokalne

### Added
- `lib/core/services/notification_scheduler.dart` — czysta logika obliczania terminów (`nextWeekdayTime()`, `nextDailyTime()`), bez zależności od pluginu/platform channels — testowalna w izolacji na `DateTime`
- `lib/core/services/notification_service.dart` — `NotificationService` na `flutter_local_notifications` + `timezone` (strefa zahardkodowana na `Europe/Warsaw` — aplikacja jednoosobowa, PL):
  - `setKarateReminder()` — cotygodniowe przypomnienie wt+czw 19:30 (30 min przed treningiem 20:00), powtarzane automatycznie (`DateTimeComponents.dayOfWeekAndTime`)
  - `setWorkoutReminder()` — codzienne przypomnienie o treningu domowym (domyślnie 18:00)
  - `setMoodCheckReminder()` — codzienny prompt dziennika samopoczucia (domyślnie 20:30)
  - `requestPermission()` — żądanie zgody na notyfikacje (Android 13+)
  - Guard `kIsWeb` przy inicjalizacji strefy czasowej — plugin sam jest no-op na Web, ale `timezone.initializeTimeZones()` nie jest potrzebne na tej platformie
- `notificationServiceProvider` w `core/providers/notification_provider.dart`
- Rozszerzenie `AppSettings`/`SettingsNotifier` o `notifKarate`/`notifWorkout`/`notifMood` (persystencja w `SharedPreferences`, re-aplikowanie harmonogramu przy starcie aplikacji)
- UI w `settings_page.dart` — 3 nowe `SwitchListTile` w sekcji "Powiadomienia", żądanie uprawnienia przy włączeniu
- `AndroidManifest.xml` — `RECEIVE_BOOT_COMPLETED` + `SCHEDULE_EXACT_ALARM` permissions, `ScheduledNotificationReceiver` + `ScheduledNotificationBootReceiver` (przetrwanie zaplanowanych notyfikacji po restarcie urządzenia)
- `timezone: ^0.10.1` jako bezpośrednia zależność w `pubspec.yaml` (była tranzytywna przez `flutter_local_notifications`, `flutter analyze` wymagał jawnej deklaracji)

### Tests
- `test/features/settings/notification_scheduler_test.dart` — 8 testów jednostkowych na czystej logice `NotificationScheduler` (bez platform channels): wybór najbliższego dnia tygodnia/godziny, przeskok o tydzień/dzień gdy godzina minęła, równość traktowana jako "minęło", granica miesiąca

### Fixed
- `test/widget_test.dart` — poprawiono błędną oczekiwaną wartość w teście `BmrCalculator` (1707.5 → 1835.0; sam wzór Mifflin-St Jeor w `BmrCalculator` był poprawny, błąd był wyłącznie w asercji testu — wykryty przy pełnym przebiegu `flutter test` w tej sesji, niezwiązany z notyfikacjami)

### Verified
- `flutter analyze` → **No issues found!**
- `dart format .` → sformatowane
- `flutter test` (pełny projekt) → **20/20 passed**
- `flutter build apk --debug` → **SUCCESS** (181MB)
- `flutter build web --release` → **SUCCESS** (potwierdzone, że guard `kIsWeb` nie łamie platformy web mimo że `flutter_local_notifications`/`timezone` nie deklarują wsparcia Web w swoich `pubspec.yaml`)

---

## [0.4.0] — Backup/restore JSON (Premium)

### Added
- `lib/core/services/backup_service.dart` — `BackupService.exportToBytes()` / `importFromBytes()` / `suggestedFileName()`:
  - Format JSON z `schemaVersion` (obecnie `1`), `appVersion`, `exportedAt`, 9 sekcji danych (wszystkie tabele Drift)
  - Eksport wykorzystuje generowane przez Drift `toJson()` na klasach danych — brak ręcznego mapowania kolumn
  - Import w `db.transaction()`: czyszczenie 9 tabel w kolejności odwrotnej do FK, re-insert z zachowaniem oryginalnych ID (`insertOnConflictUpdate`) — zachowuje relacje (np. `SetsLog.sesjaId → WorkoutSessions.id`)
  - Walidacja `schemaVersion` — odrzuca import z nieznanej/przyszłej wersji formatu, bez modyfikacji bazy
  - Błąd w trakcie importu → rollback transakcji, baza pozostaje niezmieniona
- `backupServiceProvider` w `core/providers/database_provider.dart`
- UI w `settings_page.dart` (przepisane na `ConsumerStatefulWidget`):
  - Eksport → `share_plus` (`XFile.fromData`), działa identycznie na Web i Android (bez `dart:io`)
  - Import → `file_picker` (`withData: true`, operuje na `Uint8List` w pamięci), dialog ostrzegawczy przed nieodwracalnym zastąpieniem danych, loading overlay podczas operacji

### Tests
- `test/features/settings/backup_service_test.dart` — 6 testów jednostkowych na `AppDatabase.forTesting(NativeDatabase.memory())`:
  - Eksport pustej bazy generuje poprawną strukturę JSON
  - Round-trip profilu użytkownika
  - Round-trip sesji + serii z zachowaniem relacji FK
  - Odrzucenie nieznanego `schemaVersion`
  - Odrzucenie nieprawidłowego JSON bez crasha
  - Rollback transakcji przy błędzie w trakcie importu (baza niezmieniona)

### Verified
- `flutter analyze` → **No issues found!**
- `dart format .` → bez zmian po formatowaniu (clean)
- `flutter build apk --debug` → **SUCCESS** (181MB, wzrost z 156MB — natywne zależności `file_picker`/`share_plus`)
- `flutter test test/features/settings/backup_service_test.dart` → **6/6 passed**

---

## [0.3.0] — Naprawa kompilacji web + dokumentacja + ikona

### Added
- Struktura Drift multi-platform (`core/database/connection/`): `native_connection.dart`, `web_connection.dart`, `unsupported_connection.dart`, `connection.dart` z conditional exports (`dart.library.ffi` / `dart.library.js_interop`)
- Pliki binarne `web/sqlite3.wasm` (v2.9.4) i `web/drift_worker.dart.js` (v2.28.2), zgodne z wersjami w `pubspec.lock`
- Ikona aplikacji (custom, motyw pięść+hantla, paleta #1A1D23/#FF6B35), zintegrowana we wszystkich rozdzielczościach Android (mdpi–xxxhdpi, launcher + round + adaptive foreground)
- README.md, ARCHITECTURE.md, CHANGELOG.md, CONTRIBUTING.md

### Fixed
- `flutter build web --release` — wcześniej fail (`Only JS interop members may be 'external'` z `sqlite3_flutter_libs` przez `dart:ffi` niekompatybilne z dart2js/wasm). Naprawione przez migrację do `WasmDatabase` na platformie web.
- Lint `dangling_library_doc_comments` w `connection.dart` — zamiana doc-comments (`///`) na zwykłe komentarze (`//`) + dodanie deklaracji `library;`

### Verified
- `flutter analyze` → **No issues found!**
- `flutter build web --release` → **✓ Built build/web** (60.7s), potwierdzono runtime przez log serwera: sekwencja żądań `main.dart.js → drift_worker.dart.js → sqlite3.wasm → assets/data/exercises.json` dowodzi, że baza Wasm inicjalizuje się i seed danych ćwiczeń wczytuje poprawnie w przeglądarce.

---

## [0.2.0] — Timer przerw + stoper izometryczny (MVP core loop)

### Added
- `core/widgets/rest_timer_screen.dart` — pełnoekranowy timer przerw (`showRestTimer()`):
  - Presety 60/90/120/180s + custom duration dialog
  - Pulsowanie wizualne (`flutter_animate`) przy ≤5s pozostałych
  - Haptic feedback + gong audio na zakończenie
  - Przyciski „Pomiń przerwę” / +/-15s
- `core/widgets/isometric_stopwatch.dart` — stoper izometryczny (`showIsometricStopwatch()`):
  - Non-dismissible bottom sheet (blokada przypadkowego zamknięcia w trakcie pomiaru)
  - Liczenie w górę, Start/Pauza/Wznów/Zakończ
- `core/services/gong_service.dart` — `GongService.playGong()` z fallbackiem na `SystemSound.play(SystemSoundType.alert)` gdy plik audio niedostępny
- Integracja timera i stopera w `active_session_page.dart`:
  - Auto-trigger timera przerw po każdej zalogowanej serii
  - Warunkowe UI (`_isIsometric`) — ćwiczenia izometryczne dostają stoper, siłowe dostają pola waga/powtórzenia

### Changed
- `_ExerciseLogCard` w `active_session_page.dart` zrefaktoryzowany — rozdzielenie logiki `_logStrengthSet()` vs `_startIsometricStopwatch()`, wspólny `_afterLogSet()` (obsługa PR + auto-timer)

### Feature: Planner (nowy, kompletny)
- `features/planner/domain/plan_generator.dart` — `PlanGenerator.generate()`: algorytm doboru ćwiczeń wg celu, poziomu, sprzętu i czasu sesji (mapa priorytetów partii ciała per cel treningowy)
- `features/planner/data/planner_repository.dart` — `SavedPlan` model + `PlannerRepository` (save/watch/delete)
- `features/planner/providers/planner_providers.dart`
- `features/planner/presentation/pages/planner_page.dart` — formularz generatora (poziom, czas trwania), wynik, historia zapisanych planów

### Fixed
- `use_build_context_synchronously` lint w `planner_page.dart` — `ScaffoldMessenger.of(context)` zapisywany do zmiennej przed `await`

---

## [0.1.0] — Naprawa kompilacji od 113 błędów do zera

### Fixed — Root cause: kolizja nazw Drift ↔ Freezed
- Dodano `@DataClassName('XxxData')` do 9 tabel Drift w 7 plikach (`exercises_table.dart`, `user_profile_table.dart`, `workout_tables.dart` ×2, `mood_table.dart`, `measurements_table.dart`, `tests_table.dart`, `prs_table.dart`, `plans_table.dart`) — eliminacja kolizji identyfikatorów między auto-generowanymi klasami wierszy Drift i modelami domenowymi Freezed o tych samych nazwach
- Regeneracja kodu: `dart run build_runner build --delete-conflicting-outputs` (104 outputs)

### Fixed — Błędy kompilacji i lint
- `app.dart` — brakujący import `flutter_localizations`, poprawiona lista `localizationsDelegates`
- `router.dart` — usunięcie unused import
- `workout_home_page.dart` — usunięcie leftover `typedef _Unused = ExercisesListPage;` (hack blokujący kompilację)
- `calculator_page.dart` — brakujący import `core/models/user_profile.dart` (błąd `undefined_getter 'label'`)
- Usunięcie 9 nieużywanych importów tabel Drift w plikach repozytoriów (`exercises_repository.dart`, `mood_repository.dart`, `onboarding_flow_page.dart`, `user_profile_provider.dart`, `measurements_repository.dart`, `prs_repository.dart`, `tests_repository.dart`, `workout_repository.dart`)

### Fixed — Testy
- `test/widget_test.dart` — całkowicie przepisany (wcześniej referencjonował nieistniejącą klasę `MyApp`), 5 nowych testów: `PrimaryButton` tap, `EmptyState` CTA, `ProviderScope` mount, `BmrCalculator.calculateFull`, `PrDetector.isNewRecord`
- Poprawiono błędną nazwę pola w teście: `kalorieDocelowe` → `celKalorii`

### Fixed — Android build
- `android/app/build.gradle.kts` — włączenie core library desugaring (`isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`), wymagane przez `flutter_local_notifications`

### Verified
- `flutter analyze` → **No issues found!** (z 113 błędów startowych)
- `flutter build apk --debug` → **SUCCESS** (~156MB, 141.6s)

---

## [0.0.1] — Stan wyjściowy

Projekt otrzymany z pełnym briefem technicznym: Flutter 3.35.4/Dart 3.9.2, Clean Architecture feature-first, Riverpod 2.6.1, GoRouter 14.8.1, Freezed+json_serializable, Drift, Material 3 dark theme. Struktura projektu, tabele Drift i większość features już istniały, ale projekt się nie kompilował (113 błędów `flutter analyze`, brak feature `planner` mimo referencji w routerze).
