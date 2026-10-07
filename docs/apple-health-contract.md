# Apple Zdrowie — kontrakt v1 (implementacja 1.1.0)

Uzgodniony kontrakt prac backend/Flutter. Import uruchamiany ręcznie przez Skrót
iOS, tylko odczyt wybranych danych. Kroki to **ręcznie potwierdzony dzienny wynik
z aplikacji Zdrowie**, nigdy suma próbek iPhone/Watch. Masa: wybrane próbki w kg.

## HTTP

- `GET /api/integrations/apple-health`: session; zwraca
  `{enabled: bool, createdAt: ISO|null, lastImportAt: ISO|null}`.
- `POST /api/integrations/apple-health/token`: session+CSRF,
  `{consent: true}`; atomowa rotacja; odpowiedź status jak wyżej + `token`
  ujawniany tylko raz. Cache-Control no-store. Hash tokenu wyłącznie na serwerze.
- `DELETE /api/integrations/apple-health/token`: session+CSRF; wyłącza import,
  zachowuje dane; zwraca status jak GET.
- `POST /api/integrations/apple-health/import`: wyłącznie Authorization Bearer,
  bez cookies, JSON poniżej; odpowiedź `{imported: int, duplicates: int,
  ignoredDeleted: int, lastImportAt: ISO}`. Brak danych/tokenów w logach/błędach.

```json
{
  "version": 1,
  "weights": [
    {"measuredAt": "2026-09-10T08:00:00+02:00", "value": 80.5,
     "unit": "kg", "source": "Apple Health"}
  ],
  "steps": [
    {"day": "2026-09-10", "value": 7500,
     "method": "manual_verified_total"}
  ]
}
```

Limity: 64 KiB strumieniowo, 100 elementów łącznie, 30 importów/min/token,
przedział dat od 2000-01-01 do teraz (+5 minut dla masy), dzień Europe/Warsaw,
masa 1–500 kg, kroki całkowite 0–100000. Tylko ścisłe, skończone liczby i pola.
Wymagany offset daty masy. Źródło 1–100 znaków. Pusty batch odrzucany.

## Tożsamość i synchronizacja

Nowy typ sync `healthSample`, lokalna osobna tabela source-tagged. Payload:
`{kind: "weight"|"steps", day: "YYYY-MM-DD", measuredAt: ISO|null,
value: number, source: string, method: "health_sample"|"manual_verified_total",
importedAt: ISO}`. Daty w JSON tak jak istniejący sync (ISO).
`measuredAt` jest wymaganym znacznikiem czasu dla masy, `null` dla dziennego
wyniku kroków (nie wymyślamy godziny pomiaru dla całego dnia).
Masa ma deterministyczną UUID per użytkownik + kanoniczny czas UTC + źródło +
wartość kg; nie zakładamy dostępności UUID HealthKit w Skrótach. Zmiana czasu,
źródła lub wartości tworzy nową próbkę, starą należy usunąć osobno.
Kroki mają jedną UUID per użytkownik/dzień: nowsze ręczne wysłanie zastępuje
cały total (również mniejszy); identyczny replay nie tworzy zmiany.
W batch tylko jeden wynik kroków na dzień. Replay starszego totalu po korekcie
jest ignorowany (trwały digest przyjętych wersji). Tombstone nie jest odradzany
przez import. Sync użytkownika może tylko usuwać healthSample, nie tworzyć ani
modyfikować/odradzać. Import publikuje atomowo przez istniejącą blokadę
publikowania sync i blokady rekordów; revoke/import serializowane.
Mutex właściciela w operacjach zdrowotnych używa PostgreSQL `FOR NO KEY UPDATE`:
serializuje import/rotację/revoke, ale dopuszcza `FOR KEY SHARE` używany przez
kontrolę FK `sync_operations.user_id`. Nie wolno zastąpić go `FOR UPDATE`,
które tworzy cykl z blokadą rekordu utrzymywaną przez równoległy sync push.

Masa włączona do historii/wykresu jako osobna próbka z widocznym źródłem,
nigdy zastąpienie ręcznego Measurement. Kroki widoczne osobno na Dziś wraz
z dniem/metodą. Brak danych to brak danych, nie zero; pokazujemy świeżość.
Token nie trafia do Drift, outbox, preferencji ani eksportu; UI jednorazowego
ujawnienia wymaga jawnej zgody na wysłanie danych zdrowotnych na VPS.

## Negocjacja pull i zgodność starszych PWA

`GET /api/sync/pull` domyślnie **nie zwraca `healthSample`**. Klient obsługujący
ten typ wysyła `include_health=true` wraz z kursorem. Filtr serwerowy działa
przed limitem 500 widocznych zmian. Serwer najpierw ustala high-water mark
zatwierdzonego strumienia danego użytkownika, a następnie pobiera zmiany do
tej granicy. Pełna strona zwraca kursor ostatniej widocznej zmiany; niepełna
(także pusta) przesuwa kursor do tej granicy, nigdy wstecz. Publikacje po
ustaleniu granicy czekają na następny pull i nie są pomijane.

Schemat lokalny **v7** dodaje niezależny `SyncState.fullCursor`
(`full_cursor`, domyślnie 0). Nowy klient czyta i zapisuje wyłącznie ten kursor
dla strumienia z `include_health=true`. Stare `cursor` pozostaje własnością
starszych klientów: ich zapis, również spóźniona odpowiedź trwającego pull,
nie może przesunąć ani cofnąć `full_cursor`.

Migracja z v4/v5/v6 inicjalizuje nową kolumnę od 0 niezależnie od starego
kursora i znacznika v6 `healthReplayEnabled`. Znacznik zachowano jedynie dla
zgodności starego schematu; nowy klient nie używa go do decyzji o replay.
Pierwszy pełny pull odtwarza pominiętą historię oraz zwykłe rekordy, które
mogły już być odczytane przez starszą kartę. Obsługa wersji i deferred records
zapewnia idempotencję. Zapis próbek i `full_cursor` następuje w jednej
transakcji. Restart kontynuuje pełny kursor, a backup/restore nie narusza
żadnego z kursorów, danych zdrowotnych ani attempted outbox. Nie trzeba
zamykać starych kart w celu ochrony pełnego kursora.

## Bramka urządzenia

Brak bezpośredniego HealthKit z PWA. Instrukcja ręcznego Skrótu, bez fikcyjnego
pliku .shortcut lub linku iCloud. Rzeczywisty odczyt masy i przesyłanie przez
iPhone wymagają testu urządzenia; nie są potwierdzone testami serwera.
