# Rejestrowanie serii z metadanych katalogu

UI aktywnej sesji odczytuje `exerciseCatalogMetadataProvider` i
`ExerciseCatalogMetadata.entryFor(id)`. Brak wpisu, ładowanie i błąd metadanych
nie blokują treningu: typ `Izometria`/`time` używa sekund, pozostałe powtórzeń.
Metadane `time` i `rounds` nie pokazują kilogramów; runda to osobna seria z
czasem pracy w `czasSekund`, nie liczba wpisana w `powtorzenia`.
Można wpisać sekundy lub użyć stopera. Timer przerwy pozostaje konfigurowalny.
Dla masy własnej pole ciężaru jest ukryte; Hantle/Sandbag dopuszczają opcjonalne
kilogramy, także gdy lista sprzętu zawiera masę własną.

## Trwałość i wire

- Drift schema **9**, migracje addytywne z wcześniejszych wersji:
  `sets_log.side TEXT NULL CHECK (side IS NULL OR side IN ('left','right','both'))`.
- Migracja **8→9** dodaje takie samo nullable `side` do `personal_records`.
  Nie zmienia wartości, ID ani metadanych synchronizacji istniejących PR.
- Stare serie pozostają `NULL`. Nie ma backfillu ani zmiany identyfikatorów.
- Domenowy model serii nazywa się w tym projekcie `SetLog` (encja sync:
  `workoutSet`); opcjonalne `side` serii i rekordów `personalRecord`
  przenoszone jest przez SQLite, wygenerowany JSON, backup/restore i outbox/pull.
  Model PR w tym projekcie to wygenerowany przez Drift `PersonalRecordData`;
  nie tworzymy drugiego, zbędnego modelu domenowego.
- Wire dodaje wyłącznie opcjonalne `side: "left" | "right" | "both"`.
  Nowe operacje pomijają pole dla starych/niesklasyfikowanych serii.
  Istniejących, już próbowanych payloadów nie przepisujemy.
- Backend używa `dict[str, JsonValue]` wewnątrz envelope i JSONB w storage.
  `extra="forbid"` dotyczy envelope, nie pól payloadu. Nie jest potrzebna
  migracja Alembic ani zmiana schematów backendu. Test backendowy sprawdza
  cztery przypadki (brak strony/left/right/both) dla obu encji,
  push/pull i duplicate retry.
- Backup zachowuje obecną wersję formatu: pole jest opcjonalne i obsługiwane
  przez wygenerowane serializery; test sprawdza także ponowne zakolejkowanie.

## PR i bezpośrednie porównania

PR best/history i ostatnia seria mają zakres **exerciseId + dokładne side**:
`NULL`, `both`, `left`, `right` są czterema różnymi zakresami. Stary caller bez
argumentu strony nadal odczytuje/zapisuje PR bez oznaczenia. Nie ma backfillu
`NULL` na `both` ani przeliczania historii. UI pokazuje najlepszy PR oraz
rozwijaną historię osobno dla każdego zakresu, także **Bez oznaczenia**.

Epley i komunikat o nowym PR działają dla dodatnich kg + powtórzeń, również
z jawną stroną. Czas i powtórzenia bez ciężaru nie otrzymują pozornego 1RM.
Po zapisaniu serii UI pokazuje neutralne delty kg/powtórzeń/sekund względem
poprzedniej serii tej samej strony (tylko wspólne metryki, bez diagnoz
asymetrii). Odczyt poprzedniej serii następuje przed zapisem; remisy timestampów
rozstrzyga ID. Zmiana strony nie pokazuje delty innej strony.
Podsumowanie nadal pokazuje stronę i sekundy.

Seria, PR i outbox zapisują się w jednej transakcji; utrata aktywnej sesji,
anulowanie podczas odczytu PR lub zablokowane konto nie pozostawia częściowego
zapisu. Watch usunięcia sesji przez restore/pull pozostaje aktywny.
Guard ręcznego log-set sprawdza również pasywny cache stanu i epoki auth.
`authStateProvider` publikuje przejścia synchronicznie (także `loading` na starcie
logoutu), więc unieważnia zapis nawet gdy trwały lock `offlineAccess=false`
czeka w kolejce za transakcją. Powrót na to samo konto nie przywraca starej
epoki. Odczyt cache nie uruchamia auth bootstrap ani HTTP; zanim auth zostanie
zainicjalizowane, samodzielny zapis offline nadal używa trwałego bindingu.

## Ograniczenia

Delty są informacją o właśnie zapisanej serii w aktywnej sesji, nie utrwalaną
encją ani automatyczną rekomendacją progresji. Brak wspólnej metryki oznacza
brak delty, nie zero. Nie przypisujemy starym wynikom strony automatycznie.
Nie dodajemy utrwalania ustawień przerw ani nowej encji rund: zapisujemy ich
rzeczywisty wynik w sekundach. Nie zmieniamy kontraktu propozycji Mentora.
Mentor log-set nadal zapisuje bez strony; jego API nie otrzymało pola `side`.
