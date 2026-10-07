# Apple Zdrowie — zamknięcie poprawek review

> Raport kandydata review2. Kolejne review wykazało pozostały problem
> współdzielenia `sync_state.cursor` przez starą i nową kartę. Aktualny kontrakt
> zastępuje znacznik replay niezależnym `full_cursor` w schemacie v7;
> poniższe wyniki nie obejmują tej dodatkowej poprawki.
> Aktualne dowody i obrazy: [niezależny pełny kursor v7](apple-health-shared-cursor-fix.md).

**2026-09-11: oba P1 i luka testowa P2 poprawione.** Wersja nadal
**1.1.0+3**, niewdrożona. Ten raport zastępuje wyniki pierwszego kandydata
opisane w `apple-health-implementation.md`. Nie wykonano deploymentu,
commitów, odczytu sekretów ani operacji na produkcyjnych danych zdrowotnych.
Nie uruchamiano reviewera; prace wykonali koordynator i dwie sesje fixerów.

## P1 — deadlock blokady użytkownika z FK synchronizacji

W czterech miejscach w `backend/app/health/service.py` i `router.py`
zmieniono mutex właściciela na `with_for_update(key_share=True)` przy
domyślnym `read=False`. Zweryfikowany SQL dialektu PostgreSQL:

```sql
SELECT users.id
FROM users FOR NO KEY UPDATE
```

Nie zmieniano blokad rekordów ani wspólnej blokady publikowania sync.
`FOR NO KEY UPDATE` serializuje operacje zdrowotne, ale jest zgodne z
`FOR KEY SHARE` kontroli FK `sync_operations.user_id`.

**Deterministyczny dowód na PostgreSQL 16:**
`test_forced_sync_fk_flush_does_not_deadlock_import` wymusza kolejność:
sync ma rekord → import ma użytkownika i żąda rekordu → sync wykonuje flush
z FK. Przed poprawką: **1 failed**, wyniki `['PushResponse', 'DBAPIError']`.
Po poprawce obie transakcje kończą się poprawnie: delete jest zaakceptowany,
import respektuje tombstone. Nie jest to test polegający tylko na równoczesnym
uruchomieniu dwóch zadań.

Trzy warianty `test_health_owner_mutex_serializes_but_allows_fk_key_share`
sprawdzają realne uzyskanie `FOR KEY SHARE` przy zajętym mutexie oraz czekanie
import/rotate/revoke widoczne w `pg_stat_activity`. Zachowano testy ponownej
kontroli tokenu po rotacji i revoke. Zestaw blokad: **5 passed**.

Szczegóły: [raport backendu](apple-health-backend-review-fixes.md).

## P1 — stare PWA i odtworzenie pominiętej historii

- Bez `include_health` lub z `false` pull nie zwraca `healthSample`.
- Nowy `HttpSyncApi` wysyła `include_health=true`.
- Filtr SQL działa **przed LIMIT 500**. Serwer ustala najpierw granicę
  zatwierdzonego strumienia użytkownika, potem pobiera dane tylko do niej.
  Pełna strona zwraca kursor ostatniej widocznej zmiany, niepełna/pusta —
  ustaloną granicę. Kursor nie cofa się i nie pomija publikacji pomiędzy
  oboma SELECT-ami.
- Drift **v6** dodaje `SyncState.healthReplayEnabled`, domyślnie false.
  Przy pierwszym bind poprawnego konta jeden transakcyjny zapis ustawia
  `cursor=0` i znacznik true. Nie modyfikuje lokalnych danych, deferred
  records ani attempted outbox. Następne uruchomienie kontynuuje zapisany
  kursor, również po awarii bezpośrednio po resecie.
- Nie dodano ignorowania nieznanych typów bez odtworzenia historii.

Test API używa **501 ukrytych healthSample, 501 zwykłych zmian i końcowego
healthSample**. Weryfikuje strony starego klienta, ich kursory oraz pełną
historię nowego klienta od zera. Osobne testy obejmują wyłącznie ukryte dane,
kursor wejściowy powyżej granicy i wymuszony commit zwykłej zmiany pomiędzy
odczytem granicy a SELECT-em strony — w obu trybach negocjacji.

Przed poprawką zestaw negocjacji: **4 failed**. Po poprawkach wspólny zestaw
sync + health: **68 passed**.

## P2 — rzeczywista baza v4, migracja i restore

`test/fixtures/schema_v4.sql` zawiera niezależny pełny historyczny schemat,
przepisany z commita `5e2a28d`, nie z aktualnej deklaracji Drift.
`test/features/health/health_replay_migration_test.dart` tworzy plik SQLite
i przed otwarciem przez AppDatabase zapisuje:

- pomiar ręczny z opcjonalnymi polami i metadanymi sync;
- sesję treningową oraz serię wskazującą ją przez FK;
- konto, urządzenie i kursor **77**;
- attempted outbox, włącznie z dosłownym JSON zawierającym odstępy;
- deferred record.

Porównuje **wszystkie kolumny** zasianych wierszy przed i po migracji,
sprawdza FK, odrzucenie innego konta, reset **77→0**, zamknięcie/otwarcie
SQLite przed pull, pobranie pominiętej próbki oraz kolejny restart z kursorem
**99** bez resetu. Warianty obejmują **v4→v6 i v5→v6**.

Następnie wykonuje eksport i restore: sprawdza nową tożsamość ręcznych
rekordów zgodną z dotychczasową semantyką backupu, relację sesja–serie,
tombstone starego rodzica, zachowanie próbek zdrowotnych oraz identyczność
wszystkich pól wcześniejszych attempted operations. Usunięto poprzedni
test migracji oparty tylko na `sync_state`.

Szczegóły: [raport Fluttera](apple-health-flutter-review-fixes.md).

## Końcowa weryfikacja po poprawkach

| Kontrola | Wynik |
| --- | --- |
| Pełny backend, Python 3.12 + Testcontainers PostgreSQL 16 | **191 passed**, 283.69 s |
| Generator Drift i kontrola wersji | OK, v6 / 1.1.0+3 |
| Pełny `flutter analyze` | **No issues found** |
| Pełny `flutter test` | **278 passed** |
| Etap Docker `verification` nowego web builda | **No issues found; 278 passed** |
| Finalny web build `--target runtime` | OK, Nginx |
| Build API runtime i migracji | OK |
| Smoke obrazu API bez bazy/sieci | OpenAPI: `include_health` boolean, default false |
| Obraz migracyjny `alembic heads` bez bazy | **0008 (head)** |
| Smoke Nginx bez sieci i publikowania portów | poprawna konfiguracja, `/healthz`, `/today`, `/version.json`, artefakty SQLite |
| Serwowane metadane wersji | **1.1.0 / build 3** |
| Walidacja JSON z dokumentacji | **2 poprawne przykłady** |
| `git diff --check` | OK |

Flutter **3.35.4**, Dart **3.9.2**. Wszystkie hashe plików lock są identyczne
z pierwszym kandydatem; nie dodano zależności. Istniejące ostrzeżenia
opcjonalnego pełnego Dart-Wasm oraz podwójnej deklaracji MIME wasm w Nginx
pozostały bez zmian i nie zablokowały wybranego buildu JS ani smoke.

### Nowe obrazy-kandydaty — niewdrożone

| Obraz | ID |
| --- | --- |
| `fit-api:apple-health-1.1.0-review2` | `sha256:9d1d76debb4ea722997a3cc5427fc5f05b855a460c53351f55f3a58be6b00124` |
| `fit-migration:apple-health-1.1.0-review2` | `sha256:f2d79181cc5408607f4bfb78db8333e3b7216b629757c299ad4ccf8835bf8eff` |
| `fit-web:apple-health-1.1.0-review2` | `sha256:98af658a8248e1c2508fa9fad16f4b98c4a8f2177222bc539214ee026f9e582b` |

## Pozostałe ograniczenia

- Pierwsze włączenie capability odtwarza cały strumień raz, stronami po 500,
  co zwiększa koszt pierwszej synchronizacji przy dużej historii.
- Zgodność starego klienta sprawdzono na API bez flagi, a migrację/replay na
  natywnym SQLite. Nie wykonywano ręcznego testu aktualizacji PWA w Safari ani
  jednocześnie otwartych starych i nowych kart współdzielących tę samą bazę.
- Rzeczywisty iPhone/Skrót/HealthKit nadal wymaga bramki sprzętowej.
  Kroki pozostają ręcznie potwierdzanym totalem ze Zdrowia. Nie udajemy
  automatycznej deduplikacji Apple Watch/iPhone ani dostępu do UUID próbki.
- Polityka restore importów pozostaje opisana w instrukcji: plik archiwizuje
  dane, lecz nie odtwarza serwerowych importów; te wracają przez sync konta.
