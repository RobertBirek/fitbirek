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

- Drift schema **8**, migracja addytywna z wcześniejszych wersji:
  `sets_log.side TEXT NULL CHECK (side IS NULL OR side IN ('left','right','both'))`.
- Stare serie pozostają `NULL`. Nie ma backfillu ani zmiany identyfikatorów.
- Domenowy model serii nazywa się w tym projekcie `SetLog` (encja sync:
  `workoutSet`); jego opcjonalne pole `side` przenoszone jest przez SQLite,
  JSON, backup/restore oraz outbox/pull.
- Wire dodaje wyłącznie opcjonalne `side: "left" | "right" | "both"`.
  Nowe operacje pomijają pole dla starych/niesklasyfikowanych serii.
  Istniejących, już próbowanych payloadów nie przepisujemy.
- Backend używa `dict[str, JsonValue]` wewnątrz envelope i JSONB w storage.
  `extra="forbid"` dotyczy envelope, nie pól payloadu. Nie jest potrzebna
  migracja Alembic ani zmiana schematów backendu. Test backendowy sprawdza
  cztery przypadki (brak strony/left/right/both), push/pull i duplicate retry.
- Backup zachowuje obecną wersję formatu: pole jest opcjonalne i obsługiwane
  przez wygenerowane serializery; test sprawdza także ponowne zakolejkowanie.

## Ograniczenia

Rekordy osobiste nie mają wymiaru strony w swojej tabeli. Konserwatywnie nie
obliczamy PR dla **żadnej jawnej strony**, również `both`; informacja widoczna
jest przy selektorze. Nie porównujemy lewej/prawej ani z historycznymi seriami
bez strony. Ostatnia seria dobierana jest dokładnie po stronie, a brak strony
porównywany tylko z brakiem strony. Podsumowanie pokazuje stronę i sekundy.

Pełna obsługa PR per strona wymaga osobnej zmiany modelu i migracji rekordów.
Nie dodajemy utrwalania ustawień przerw ani nowej encji rund: zapisujemy ich
rzeczywisty wynik w sekundach. Nie zmieniamy kontraktu propozycji Mentora.
