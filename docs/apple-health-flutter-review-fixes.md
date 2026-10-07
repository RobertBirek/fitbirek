# Apple Zdrowie — poprawki klienta po review

> Raport historycznej poprawki v6. Współdzielony kursor wymagał następnie
> zastąpienia niezależnym pełnym kursorem — [aktualny raport v7](apple-health-shared-cursor-fix.md).

Data: 2026-09-11. Wersja aplikacji pozostaje **1.1.0+3**.

## Negocjacja i jednorazowe odtworzenie historii

- `HttpSyncApi.pull` wysyła dokładnie
  `/api/sync/pull?cursor=X&include_health=true`.
- Drift v6 dodaje trwałą kolumnę `SyncState.healthReplayEnabled`, domyślnie
  false. Migracja z v4 dodaje również tabelę HealthSamples; z v5 tylko marker.
- `bindAccount` najpierw sprawdza dotychczasowe przypisanie konta. W jednej
  transakcji, przed operacjami sieciowymi, ustawia `cursor=0` i marker true,
  ale tylko kiedy marker był false. Nie zmienia danych domenowych, deferred
  records ani żadnego pola outbox.
- Nowa baza tworzy binding z kursorem 0 i markerem true. Kolejne uruchomienia
  zachowują osiągnięty kursor. Awaria po zatwierdzeniu resetu nie gubi replay:
  kolejny proces nadal rozpoczyna pobieranie od zapisanego kursora 0.
- Nie wprowadzono ignorowania nieznanych typów ani zmian obsługi konfliktów
  usuwania healthSample. Poprawka backendowego deadlocku jest poza tym zakresem.

## Test historycznej migracji i restore

Dodano niezależny plik `test/fixtures/schema_v4.sql`, przepisany z historycznych
deklaracji tabel w commicie `5e2a28d` (odczyt przez git show). Zawiera cały
schemat v4, a nie schemat bieżącej aplikacji z usuniętą tabelą zdrowia.
Plik jest częścią zmian do późniejszego zatwierdzenia przez koordynatora;
w tej sesji nie wykonywano commita.

`health_replay_migration_test.dart` tworzy rzeczywisty plik SQLite przed
otwarciem go przez AppDatabase. Zapisuje pomiar ręczny, sesję, serię z FK,
binding z dodatnim kursorem, attempted outbox oraz deferred record.
Porównuje wszystkie kolumny zasianych rekordów przed/po migracji do v6,
w tym surowy payload JSON z odstępami, operationId, baseVersion, attempted,
deleted, preserveLocal, createdAt i metadane synchronizacji danych domenowych.

Warianty v4 i v5 sprawdzają:

- odrzucenie zmiany konta bez zmiany kursora;
- atomowy reset 77→0 i zachowanie outbox/deferred;
- zamknięcie i ponowne otwarcie SQLite po resecie, przed pull;
- pobranie historycznego healthSample z kursora 0 mimo starego kursora 77;
- kolejne ponowne otwarcie i pull z kursora 99, bez ponownego resetu;
- backup/restore po migracji: ręczne rekordy otrzymują nowe UUID, stare
  rekordy dostają operacje delete, a seria wskazuje nowego rodzica;
- zachowanie lokalnych health rows/tombstone'ów i ich attempted deletes;
- identyczność każdego pola wcześniejszych attempted operations;
- zachowanie accountId/deviceId/kursora po restore.

Osobny test sprawdza nowy binding i brak powtórnego resetu. Test HTTP adaptera
sprawdza pełną ścieżkę opt-in i metodę GET.

Usunięto poprzedni, zbyt słaby test migracji oparty tylko na tabeli sync_state.
W istniejących testach v2/v3 poprawiono wyłącznie warunki początkowe: te wersje
nie miały HealthSamples ani healthReplayEnabled. Wszystkie wcześniejsze
asercje pozostawiono bez osłabiania.

## Weryfikacja końcowa

W istniejącym obrazie SDK `fit-web:verified` (Flutter 3.35.4 / Dart 3.9.2),
z `/opt/fit:/app`, uruchomiono:

```text
dart format [zmienione pliki]
dart run build_runner build --delete-conflicting-outputs
dart tools/generate_app_version.dart --check
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

Wyniki końcowego przebiegu:

- build_runner: sukces; wygenerowany `app_database.g.dart` uwzględnia marker.
- kontrola wersji: sukces, bez zmiany pubspec i zależności.
- analiza: **No issues found!**
- pełne testy: **278 — All tests passed!**
- `git diff --check`: sukces.

Bez zmian UI, produkcji, sekretów, wdrożenia, commitów i delegacji.
Koordynator może zbudować finalnych kandydatów po zakończeniu poprawki backendu.
