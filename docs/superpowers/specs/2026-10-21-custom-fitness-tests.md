# Własne testy sprawnościowe i ekran Postępy

## Zgoda i cel

Użytkownik zatwierdził wykonanie: własny test dla dowolnego ćwiczenia, karta
z ilustracją i opisem zasad, rzeczywista data/godzina próby, historia i porównanie
wyłącznie tej samej wersji zasad. Wyniki pozostają oddzielne od treningów i PR.
Nie zapisujemy sesji, serii ani rekordów przy tworzeniu testu lub wyniku.
Publikacja/commit/push/deploy nie są częścią bieżącej zgody wykonawczej.

## UX i wygląd

- Postępy: sekcje **Ciało / Testy / Trening**; zachować pomiary ręczne/Apple
  Zdrowie, źródła, usuwanie importów, kroki, PR i istniejące trendy.
- Testy: własne aktywne i archiwalne definicje, ilustracja, nazwa, ostatni wynik
  z jednostką/datą i poprzedni porównywalny wynik. Starsze 11 typów dostępne
  osobno jako dotychczasowe testy; danych i punktacji nie przepisywać.
- Główna prezentacja wyników w powtórzeniach/sekundach/metrach; punkty legacy
  co najwyżej opisany pomocniczy indeks, nie norma kliniczna lub ocena zdrowia.
- Baza ćwiczeń: akcja w menu wiersza; karta ćwiczenia: przycisk
  **Test sprawnościowy**. Otwiera wybór/utworzenie testu dla wybranego ćwiczenia,
  nigdy automatyczny start treningu lub zapis. Zachować ulubione i nawigację.
- Definicja: nazwa, ćwiczenie z katalogu, metryka, kierunek poprawy, opcjonalnie
  kg i sposób podania, strona, istniejący wariant, limit sekund, opis zasad.
  Każde ćwiczenie może mieć dowolną metrykę testu niezależnie od tracking workoutu.
- Karta protokołu: lokalna ilustracja lub jawny placeholder, snapshot nazwy,
  co mierzymy, warunki, instrukcje, ostatni wynik; osobno przejście do pełnej
  karty ćwiczenia. Nie podmieniać brakującego obrazu na inne ćwiczenie.
- Próba: wpis wyniku i data+godzina wykonania, domyślnie teraz, edytowalne
  dla wcześniejszej próby; jawny **Zapisz wynik**. Możliwy pomocniczy stoper
  tylko bez autosave/obietnic działania w tle; ręczny wynik zawsze dostępny.
- Zmiana definicji tworzy nowy UUID rewizji w rodzinie; wcześniejsze zasady
  i wyniki zachowane. Archiwizacja nie usuwa historii. Współbieżne rewizje
  pozostają osobnymi gałęziami, nie udajemy jednej sekwencji numerów.
- Daty są momentami UTC w zapisie i lokalnymi datami/godzinami w UI;
  `data` oznacza wykonanie, `updatedAtUtc` techniczny zapis. Nie zastępować
  daty wykonania czasem synchronizacji. Formularz nie przyjmuje przyszłej próby.
- Responsywność 320px–desktop, tekst200%, kontrolki min48px, focus/VoiceOver,
  powrót z deep linku, offline, loading/error/empty i blokada podczas zapisu.

### Tokeny

Grafit #1A1D23, powierzchnia #23262E, jasny #F4F6F8, pomocniczy #A7B0BE,
akcent #FF6B35, pozytywny #4CAF50. Korzystać z ThemeData w obu trybach;
pomarańczowy oznacza akcję, kolor nie jest jedynym nośnikiem znaczenia.
Inter dla opisów/kontrolek; lokalny Barlow Condensed SemiBold oszczędnie dla
wyniku i nagłówka testu, z licencją i provenance, bez fontów runtime z CDN.
Element charakterystyczny: ilustracja oraz **poprzednio → teraz** z jednostką
i warunkami porównania, nie wielka arbitralna ocena0–100. Ograniczona animacja.

## Kontrakt v1 — stały dla obu klientów i backendu

Lean: definicje jako nowa kolekcja `profile.fitnessProtocols`, wyniki jako
opcjonalne rozszerzenie istniejącej encji `fitnessTest`. Nie dodawać typów encji.

### `fitnessProtocols`

Koperta `{version:1, entries:[...]}`; <=500 wpisów z tombstone'ami,
<=262144 bajtów UTF-8. Wpis rewizji ma dokładnie znane pola:

| Pole | Kontrakt |
|---|---|
| id, familyId | UUID; id identyfikuje niezmienną rewizję |
| supersedesId | nullable UUID, różny od id; rodzic może być niedostępny |
| name | niepusty, <=80 znaków Unicode |
| exerciseId / exerciseName | niepuste <=64 /200 znaków; nazwa jest snapshotem |
| metric | reps / time / distance, jednostki kanoniczne powtórzenia /s /m |
| direction | higher / lower |
| loadKg | nullable skończone 0..1000; null nie oznacza0 |
| loadBasis | nullable total / perImplement; obecne wtedy i tylko gdy kg obecne |
| side | nullable left / right / both; null nie jest both |
| variantSnapshot | nullable pełny snapshot v1 wpisu exerciseVariants |
| timeLimitSeconds | nullable int1..86400 |
| instructions | string <=4000 znaków Unicode, może być pusty |
| createdAtUtc, updatedAtUtc | UTC ISO8601 z Z, updated>=created |
| deletedAtUtc | opcjonalny/null lub UTC Z, nie późniejszy niż updated |

Snapshot wariantu zachowuje id/name/exerciseId/createdAtUtc/updatedAtUtc,
opcjonalne deletedAtUtc/tempo/pauseSeconds/loadKg/rangeOfMotion/cue, według
dotychczasowych ograniczeń; exerciseId zgodny z protokołem. Nie zależy od
bieżącego istnienia wariantu. Obciążenie konkretnego testu jest w loadKg/loadBasis;
domyślna dawka wariantu go nie nadpisuje. Snapshot rewizji maks32768B UTF-8.
Nieznane pola/wersje zasad odrzucać zachowując raw, nie ignorować ograniczeń.

Nullable pola semantyczne mogą być pominięte na wejściu i oznaczają wtedy null;
wyjściowy klient emituje je jawnie. Porównanie zasad normalizuje brak/null,
ale nigdy nie modyfikuje attempted requestu lub jego digestu. Nowe daty są
ścisłym gregoriańskim ISO UTC-Z z opcjonalnym ułamkiem1..6cyfr i rokiem1..9999;
odrzucać normalizację nieistniejących dat (np.30lutego) i sekund60. Nie zmieniać
historycznej tolerancji parserów legacy poza własnymi nowymi polami.

Wszystkie pola poza updatedAtUtc/deletedAtUtc są niezmienne dla tego samego id.
Zmiana także nazwy tworzy nową rewizję. Archiwizacja zmienia tylko metadane
tombstone. Przy merge ten sam id z inną treścią zasad to jawny konflikt,
bez arbitralnego LWW. Nie usuwać dawnych wpisów kolekcji przez prune/NULL.

### Wynik

```text
entityType: fitnessTest
payload: {
 typ: customFitnessTestV1,
 data: rzeczywisty moment UTC ISO8601,
 wynik: surowa wartość,
 score: 0,
 customProtocol: {version:1, protocolId:UUID, familyId:UUID, snapshot:pełny wpis}
}
```

`score:0` jest wyłącznie paddingiem zgodności starego wire, nie punktacją
własnego testu; nigdy nie wyświetlać go jako oceny. Brak sztucznych rekordów
wyników służących do przechowywania definicji. Reps: całkowita wartość num0..1e9
(JSON18 i18.0 są równoważne, bo stara kolumna wynik jest REAL); czas/dystans:
skończone num0..1e9, bez bool/NaN/Infinity. ProtocolId/familyId muszą zgadzać się
ze snapshotem. Historyczny odczyt nie wymaga definicji ani ćwiczenia w katalogu.
Porównanie wymaga id rewizji i identycznego kanonicznego snapshotu zasad;
rozbieżność tych samych id jest pokazywana jako nieporównywalność, nie trend.

## Persistencja, offline, backup i rollout

- Drift13→14: nullable `UserProfiles.fitnessProtocolsJson` i nullable
  `FitnessTestResults.customProtocolJson`; bez backfillu i zmiany legacy wyników.
- Backend JSONB bez migracji SQL: omission preservation fitnessProtocols
  w profile i customProtocol w fitnessTest, po CAS i bez mutacji attempted/digest.
- Walidacja po rekonstrukcji pominiętych rozszerzeń. Istniejącego custom wyniku
  nie wolno zmienić w legacy ani zmienić snapshotu; korekta wartości/daty może
  zachować protokół. Tombstone pozwala usunąć nieczytelny historyczny rekord.
- Profile: walidować nową kolekcję i niezmienność istniejących id; bez usuwania
  wcześniejszych entries. Inne kolekcje zachować dotychczasową semantykę.
- Zachować raw/deferred/quarantine, per-ID merge, immutable attempted outbox,
  pełny CAS profilu i brak blokowania niezależnego globalnego pull przez kolekcję.
- Guardy: pasywny auth/account epoch, binding/offlineAccess/profil przed i po
  await, transakcja row+outbox. A→B→A unieważnia formularz, nie zapisuje na B.
- Backup format3, czytać stare1/2; pełne snapshoty i stabilne UUID rewizji/rodzin
  przez restore. Stary klient musi odrzucić nowy backup zamiast zgubić semantykę.
  Nie deklarować bezstratnego eksportu/restore własnych testów przez stare klienty.
- API rozszerzenie musi być wdrożone PRZED webem. Przed użyciem testów użytkownik
  aktualizuje klienty. Shared Drift schema gate pozostaje fail-closed; nie czyścić
  IndexedDB, outboxa, nie zmieniać nazwy bazy ani nie wymuszać zamknięcia workerów.
- Flutter3.35.4 /Dart3.9.2, lock/SQLite/worker bez zmian. Po deklaracjach regenerate
  build_runner; nie edytować ręcznie g.dart. Żadnych operacji produkcyjnych teraz.
