# FitBirek: konta, synchronizacja i wdrozenie produkcyjne

## Cel

Udostepnic FitBirek pod `https://fit.birek.online` jako prywatna aplikacje dla jednego konta. Aplikacja ma dzialac offline na wielu urzadzeniach i synchronizowac zmiany po odzyskaniu polaczenia.

## Zakres

- Jedno konto tworzone administracyjnie podczas pierwszego wdrozenia.
- Logowanie e-mail i haslo; bez publicznej rejestracji.
- Backend FastAPI i PostgreSQL jako zrodlo prawdy.
- Lokalna baza Drift pozostaje magazynem offline i cachem.
- Automatyczna, idempotentna synchronizacja danych treningowych.
- Konflikty rozwiazywane zasada last-write-wins wedlug kolejnosci zaakceptowanej przez serwer.
- Produkcyjny Docker Compose podzielony na `/opt/fit` (kod) i `/docker/fit` (infrastruktura oraz dane).

Poza zakresem sa wielokonta, publiczna rejestracja, reset hasla przez e-mail, federacja tozsamosci i migracja danych z obecnej lokalnej bazy. Nowa wersja zaczyna z pustymi danymi.

## Architektura

### Aplikacja Flutter

Flutter otrzyma ekran logowania oraz warstwe klienta API. Drift nadal obsluguje operacje podczas braku sieci. Rekordy synchronizowane z serwerem musza miec stabilny UUID, numer wersji, czas modyfikacji, znacznik usuniecia oraz informacje potrzebne do lokalnej kolejki mutacji.

Zmiana lokalna jest zapisywana w Drift i dodawana do kolejki. Synchronizacja jest uruchamiana przy starcie aplikacji, po zalogowaniu i po odzyskaniu sieci:

1. Klient wysyla oczekujace mutacje z unikalnymi identyfikatorami operacji.
2. Serwer przyjmuje je transakcyjnie i odpowiada potwierdzeniem lub stanem nowszego rekordu.
3. Klient pobiera zmiany po kursora synchronizacji i aktualizuje Drift w jednej transakcji.
4. Klient zapisuje nowy kursor dopiero po poprawnym zastosowaniu calej odpowiedzi.

Ponowne wyslanie tej samej operacji nie moze tworzyc duplikatow. Usuniecia sa propagowane jako tombstones. Konflikt na tym samym rekordzie rozstrzyga najnowsza zmiana zaakceptowana przez serwer.

### Backend

Backend FastAPI udostepnia:

- `POST /api/auth/login`, `POST /api/auth/logout` i endpoint stanu sesji;
- chronione endpointy synchronizacji push/pull;
- endpoint healthcheck;
- jednorazowe polecenie administracyjne do utworzenia poczatkowego konta.

Hasla sa przechowywane w postaci hashy Argon2id. Sesja PWA korzysta z cookies `HttpOnly`, `Secure` i `SameSite`; wszystkie mutujace wywolania sa chronione tokenem CSRF. Logowanie ma rate limiting. Backend akceptuje i zwraca tylko dane nalezace do uwierzytelnionego konta.

PostgreSQL przechowuje konta, dane domenowe, wersje rekordow i dziennik zmian potrzebny do synchronizacji. Wszystkie czasy zapisu dla rozstrzygania konfliktow sa nadawane przez serwer.

### Infrastruktura

`/docker/fit/compose.yaml` uruchamia uslugi `api`, `postgres` i `web`.

- `fit_internal` jest prywatna siecia dla API i PostgreSQL.
- `fit_ingress` laczy `api` oraz `web` z Caddy; Caddy zostanie dolaczony do tej zewnetrznej sieci.
- Zadna nowa usluga nie publikuje portu na hoście.
- Dane Postgresa i dumpy sa przechowywane w `/docker/fit/data`.
- Sekrety znajduja sie w `/docker/fit/.env`, poza repozytorium.

Obraz `web` buduje Flutter Web w wieloetapowym obrazie z przypietymi Flutter 3.35.4 i Dart 3.9.2. Koncowy Nginx serwuje artefakty `build/web`, ma MIME `application/wasm` dla `.wasm`, fallback SPA oraz naglowki zapobiegajace cacheowaniu service workera.

Caddy obsluguje `fit.birek.online`: `/api/*` przekazuje do backendu, a pozostale sciezki do Nginx. Wykorzystuje istniejace naglowki bezpieczenstwa i automatyczne certyfikaty Let's Encrypt.

## Bledy i bezpieczenstwo

Blad sieci nie blokuje lokalnego treningu: mutacja pozostaje w kolejce i bedzie ponowiona. Odpowiedz 401 czysci sesje i prowadzi do logowania. Niepoprawny payload synchronizacji nie zmienia lokalnej bazy czesciowo. Bledy API sa logowane bez sekretow ani danych hasel.

Sekrety nie trafiaja do repozytorium ani obrazu klienta. PostgreSQL nie jest dostepny z Internetu. Caddy waliduje konfiguracje przed reloadem.

## Wdrazanie i utrzymanie

Kod jest rozwijany lokalnie w `/opt/fit` i recznie pushowany do GitHub. Aktualizacja produkcji przebiega przez testy, budowe obrazow, migracje Alembic, `docker compose up -d`, healthcheck API, sprawdzenie HTTPS oraz test logowania i synchronizacji PWA.

Codzienny `pg_dump` zapisuje kopie do `/docker/fit/data/backups` przed istniejacym backupem Restic obejmujacym `/docker`. Miesieczny restore drill odtwarza dump do tymczasowej bazy i raportuje wynik.

## Weryfikacja

- Backend: testy hashy, sesji, CSRF, rate limitingu, izolacji konta, push/pull, idempotencji, tombstones i konfliktow.
- Flutter: testy kolejki offline, kursora, zmian zdalnych, konfliktow i obslugi sesji.
- Kontenery: build obrazow, healthcheck i brak opublikowanych portow.
- Reverse proxy: `caddy validate`, pobranie certyfikatu oraz odpowiedzi HTTPS dla PWA i API.
- Przegladarka: logowanie, praca offline, pozniejsza synchronizacja oraz zaladowanie `sqlite3.wasm` bez bledow MIME.
