# Apple Health — poprawki backendu po review

## Zakres

Poprawiono wyłącznie backend oraz niniejszy raport (jawny wyjątek). Kontrakt
przeczytano przed implementacją i pozostawiono bez zmian. Nie zmieniano wersji
1.1.0+3, zależności, Fluttera ani plików wdrożenia. Bez commitów, reviewerów,
subagentów, sekretów i dostępu do produkcyjnej bazy. Testy korzystały z
izolowanego PostgreSQL 16 uruchomionego przez Testcontainers.

## P1: cykl blokad import / sync delete / FK

Wszystkie cztery blokady właściciela zdrowia — rotacja, revoke, process_import
i rezerwacja limitu w routerze — używają teraz
`with_for_update(key_share=True)` przy domyślnym `read=False`.
Kompilacja dialektu PostgreSQL daje dokładnie **FOR NO KEY UPDATE**.
Pozostałe blokady rekordów i porządek publikowania nie zostały zmienione.

Ta blokada nadal serializuje operacje health na tym samym koncie, ale nie
blokuje `FOR KEY SHARE` używanego przez FK sync_operations.user_id.

### Dowód RED/GREEN

`test_forced_sync_fk_flush_does_not_deadlock_import` wykorzystuje zdarzenia
i hooki wokół rzeczywistych advisory locks, bez losowego równoległego startu:

1. sync uzyskuje advisory lock rekordu i czeka;
2. import uzyskuje blokadę użytkownika, po czym dochodzi do żądania tego rekordu;
3. zdarzenie pozwala sync kontynuować aż do flush operacji i sprawdzenia FK;
4. oba zadania mają ograniczony czas, test sprawdza wyniki obu transakcji.

Przed poprawką: **1 failed in 14.90s**, wyniki transakcji
`['PushResponse', 'DBAPIError']`. Test wykazał awarię w wymuszonej kolejności.
Po poprawce test przechodzi: delete zaakceptowany, import rozpoznaje tombstone.

Trzy warianty `test_health_owner_mutex_serializes_but_allows_fk_key_share`
(rotate/revoke/import) dodatkowo sprawdzają kompilację SQL, uzyskują realne
`FOR KEY SHARE` obok aktywnego mutexu właściciela i potwierdzają w
`pg_stat_activity`, że kolejny writer czeka na `FOR NO KEY UPDATE`. Dopiero
zwolnienie mutexu pozwala mu zakończyć się kodem 200. Zachowano testy stale
principal po rotacji/revoke.

Skupiony wynik blokad i stale principal: **5 passed, 36 deselected in 20.25s**.

## P1: negocjacja pull starszych PWA

`GET /api/sync/pull` ma parametr `include_health: bool = False`.
Bez flagi healthSample jest filtrowany w SQL **przed LIMIT 500**.
`include_health=true` udostępnia pełną historię.

Oba tryby używają identycznego algorytmu kursora:

1. Pierwszy SELECT odczytuje maksymalny zatwierdzony cursor użytkownika.
   Watermark to maksimum tego wyniku oraz kursora wejściowego.
2. Drugi SELECT ogranicza zmiany do `input < cursor <= watermark`, nakłada
   opcjonalny filtr healthSample i limit 500.
3. Strona pełna zwraca cursor ostatniej widocznej zmiany; niepełna, również
   pusta, zwraca watermark. Cursor nigdy nie cofa się.

Regresje sprawdzają ponad 500 ukrytych zmian przed zwykłymi danymi, pełną
paginację widocznych danych, przesunięcie pustej strony, historię opt-in od
zera oraz zapis zatwierdzony dokładnie pomiędzy odczytem watermark i drugim
SELECT-em. Ten zapis nie trafia do pierwszej odpowiedzi i jest odebrany w
następnym pull, w obu trybach. Testy health jawnie wysyłają flagę opt-in.

RED przed implementacją: **4 failed, 23 deselected in 19.40s** — brak
filtrowania, brak przesunięcia pustej strony i nieobsługiwany parametr
include_health w serwisie. Po implementacji zestaw sync + health:
**68 passed in 122.03s**.

## Ostateczna weryfikacja

- `.venv/bin/python -m pytest -q`, timeout 600000:
  **191 passed in 283.69s (0:04:43)**.
- `backend/.venv/bin/python tools/verify_apple_health_example.py`:
  **Validated 2 documented JSON examples; no network or database access.**
- `git diff --check`: OK.

Import/tokeny/dane zachowują dotychczasowe zachowanie poza poprawką mutexu.
Nie wykonano buildów ani wdrożenia. Replay marker Fluttera i buildy kandydatów
pozostają w zakresie koordynatora.
