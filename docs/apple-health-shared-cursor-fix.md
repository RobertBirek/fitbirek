# Apple Zdrowie — niezależny kursor pełnego strumienia (v7)

Data: 2026-09-11. Wersja aplikacji bez zmian: **1.1.0+3**.

## Odtworzenie błędu: rzeczywisty RED

Przed zmianą implementacji dodano test
`legacy filtered response after new bind must not skip health history`
w `test/features/health/health_shared_cursor_test.dart`.

Test używa dwóch rzeczywistych połączeń do tego samego pliku SQLite:

1. Nowy SyncService wykonuje `bindAccount` na pierwszym połączeniu.
2. Drugie połączenie, emulujące stary klient, wykonuje wyłącznie znany mu SQL:
   `UPDATE sync_state SET cursor = 1 WHERE id = 1`.
3. Nowy klient synchronizuje się z API, które zwraca historyczny healthSample
   tylko dla kursora 0.

Uruchomienie na dotychczasowym kodzie v6:

```text
flutter test --no-pub test/features/health/health_shared_cursor_test.dart --reporter expanded
Expected: [0]
Actual:   [1]
new full stream must start at zero despite the legacy writer
00:01 +0 -1: Some tests failed.
```

Był to błąd zachowania istniejącego API, nie błąd kompilacji brakującego gettera.
Znacznik replay nie chronił współdzielonego kursora przed zapisem starej karty.

## Naprawa

- Drift **v7** dodaje `SyncState.fullCursor` / `full_cursor`, INTEGER NOT NULL
  DEFAULT 0. Migracje z v4/v5/v6 nie kopiują starego kursora do nowej kolumny.
- `SyncService` pobiera strony, waliduje postęp i zapisuje wynik wyłącznie
  względem `fullCursor`. Dane strony i pełny kursor zapisują się w tej samej
  transakcji.
- `HttpSyncApi` nadal jawnie wysyła `include_health=true`.
- Usunięto z `bindAccount` reset starego kursora oraz decyzje oparte na
  `healthReplayEnabled`. Nowy binding korzysta z domyślnych zer obu kursorów.
- Historyczny marker pozostaje w schemacie ze swoją dotychczasową wartością;
  nowy kod nie zmienia go i nie używa go do decyzji o replay.
- Migracja sprzed v4 nie zeruje już starego `cursor`: nowy `full_cursor=0`
  naturalnie odtwarza również historycznie pominięte deferred payloads.
- Nie zmieniono backendu, obsługi konfliktów, auth ani polityki restore.

Audyt kodu źródłowego poza plikami generowanymi potwierdził: jedyne operacyjne
odczyty/walidacje/zapis kursora pull są w SyncService i używają fullCursor.
Auth zmienia wyłącznie swoje pola bindingu, backup/restore nie zapisuje żadnego
z kursorów. Stare pole pozostało jedynie deklaracją, a marker deklaracją oraz
elementem historycznej migracji v6.

## GREEN i zakres testów

Ten sam test RED przeszedł po naprawie. Łącznie osiem focused testów migracji
i współdzielenia kursora przeszło w jednym przebiegu.

Nowe deterministyczne testy obejmują:

- Dwa połączenia SQLite i pełny pull wstrzymany przez Completer: stary klient
  zapisuje cursor=999 podczas oczekiwania; nowy zatwierdza fullCursor=1, nie
  zmieniając starego kursora.
- Spóźniony stary zapis cursor=0 po pełnym commicie nie cofa fullCursor.
  Kolejny healthSample jest pobierany z pełnego kursora 1, nie pomijany.
- Ponowne otwarcie nowego połączenia przy starym cursor=1001 kontynuuje
  fullCursor=2. Nie trzeba zamykać starego połączenia/karty.
- Błędna strona zawierająca poprawną, a następnie uszkodzoną próbkę wycofuje
  zapis próbki i pełnego kursora. Niezależny stary commit cursor=501 pozostaje.
  Ponowienie nadal pobiera pełną stronę od 0.
- Replay starszego pomiaru nie nadpisuje nowszych ręcznych danych. Attempted
  outbox pozostaje identyczny, nowszy deferred tombstone nie jest zastępowany
  starszym snapshotem, a lokalnie usunięta próbka nie wraca do widoku.

Testy historycznej migracji nadal budują prawdziwy plik SQLite na niezależnym
`test/fixtures/schema_v4.sql` wyprowadzonym z commita `5e2a28d`. Rozszerzono je
na **v4, v5 i v6**. Wariant v6 ma marker true oraz stary cursor=999; warianty
v4/v5 mają cursor=77. Warianty v5/v6 mają także istniejący health row i tombstone.

Każdy wariant porównuje wszystkie stare kolumny zasianych danych przed/po v7:
pomiar, sesję, serię/FK, binding, attempted outbox i deferred, a dla v5/v6 także
health rows. Wyłączone z porównania są wyłącznie kolumny nowo dodane migracją.
Marker v6 jest porównywany jako stare pole, nie pomijany. Sprawdzono fullCursor=0
niezależnie od kursora/markera, replay po restarcie oraz kontynuację od 99.

Backup/restore po migracji zachowuje niezależnie stary cursor=77/999 i
fullCursor=99, account/device, health rows/tombstones oraz każde pole attempted
operations. Zachowano testy dotychczasowej semantyki ręcznych danych: świeże
UUID, usunięcia starych rekordów i prawidłowe przypisanie serii do nowej sesji.

Istniejące asercje dotyczące postępu nowego sync przełączono na fullCursor.
Jawne asercje starego kursora pozostały; dodano m.in. zachowanie legacy=20
w migracji v3. Przy odtwarzaniu warunków początkowych v2/v3 usuwana jest również
kolumna full_cursor, której te historyczne schematy nie zawierały.

## Weryfikacja końcowa

SDK uruchamiany w istniejącym Dockerze `fit-web:verified`, Flutter 3.35.4 /
Dart 3.9.2, bez upgrade i bez zmian zależności.

```text
dart run build_runner build --delete-conflicting-outputs  → sukces
dart format [zmienione pliki]                            → sukces
dart tools/generate_app_version.dart --check              → sukces
flutter analyze --no-pub                                 → No issues found!
flutter test --no-pub --reporter expanded                 → 283 All tests passed!
git diff --check                                         → sukces
```

Wygenerowany app_database.g.dart zawiera fullCursor. Pełna analiza/testy
uruchomione z limitem 600000 ms zakończyły się sukcesem.

W sesji implementującej klienta nie budowano obrazów ani nie uruchamiano
reviewerów. Weryfikację backendu i buildy ukończył następnie koordynator,
zgodnie z wynikami poniżej. Bez wdrożenia, commitów, odczytu sekretów ani
operacji na produkcyjnych danych zdrowotnych.

## Końcowa weryfikacja koordynatora — kandydat review3

Poprzednie poprawki PostgreSQL (`FOR NO KEY UPDATE`) oraz filtrowania legacy
pull nie zostały zmienione. Ponownie wykonano pełną serię backendu na
izolowanym PostgreSQL 16 przez Testcontainers.

| Kontrola | Wynik |
| --- | --- |
| Pełny backend, Python 3.12 | **191 passed in 289.98s** |
| Pełny Flutter | **283 passed** |
| Pełny `flutter analyze` | **No issues found** |
| Generator Drift i `generate_app_version.dart --check` | OK, schema v7 / 1.1.0+3 |
| Docker web `verification` po tej poprawce | analiza OK, **283 passed** |
| Finalny build web `--target runtime` | OK, Nginx |
| Build API runtime i migracji | OK |
| Smoke API bez sieci/bazy | OpenAPI: `include_health` boolean, default false |
| Smoke obrazu migracyjnego bez bazy | **0008 (head)** |
| Smoke Nginx bez sieci i publikowania portów | konfiguracja OK; `/healthz`, `/today`, `/version.json`, artefakty SQLite |
| Serwowana wersja | **1.1.0 / build 3** |
| Walidator przykładów dokumentacji | **2 poprawne przykłady JSON** |
| `git diff --check` | OK |

Flutter 3.35.4 / Dart 3.9.2 oraz wszystkie pliki lock pozostały niezmienione.
Nie wdrażano żadnego kandydata v5/v6/v7. Wersja aplikacji pozostaje tą samą
niewydaną wersją 1.1.0+3; v7 jest numerem lokalnego schematu Drift.

### Obrazy niewdrożone

| Obraz | ID |
| --- | --- |
| `fit-api:apple-health-1.1.0-review3` | `sha256:b3c78ec3767818b883598d664614b3a4e7a608901c827b339a5e6c6c7984e01a` |
| `fit-migration:apple-health-1.1.0-review3` | `sha256:e9d124c8437627c6d00a8c6211bb664c113c971782b5aa18d9ed347040b0c16c` |
| `fit-web:apple-health-1.1.0-review3` | `sha256:19a395cdbbbe92ac58ea9c73954fdc99fe49ff6be141d6350b33264a1a5802b9` |

### Granice weryfikacji i pozostałe ograniczenia

- Dowód izolacji kursora korzysta z dwóch otwartych połączeń SQLite oraz SQL
  starego DAO, także podczas wstrzymanego pull i po jego zatwierdzeniu.
  Nie opiera się na zamykaniu starych kart. Nie wykonywano ręcznego testu dwóch
  historycznych wersji PWA w Safari ani rzeczywistego Skrótu na iPhone.
- Pierwszy pull nowego pełnego strumienia odtwarza całą historię stronami po
  500; zwykłe rekordy mogą zostać odczytane ponownie. Testy sprawdzają ochronę
  nowszych danych, attempted outbox i nowszego deferred tombstone przy replay.
- Outbox i deferred records pozostają wspólne i są zachowywane; poprawka
  rozdziela kursory pull, nie tworzy odrębnego magazynu mutacji dla każdej
  wersji klienta.
- Kroki pozostają ręcznie potwierdzanym totalem ze Zdrowia. Polityka restore
  importów pozostaje serwerowa: backup archiwizuje próbki, a przywracanie ich
  na nowym urządzeniu odbywa się przez synchronizację konta.
