# Zapisane filtry ćwiczeń — lokalna architektura

## Warstwy i API

- `features/exercises/domain/filter_preset.dart`: `FilterPreset(id, name, filters)`,
  walidacja nazwy i ręczny kodek całego `ExerciseFilters`. Kopia kryteriów ma
  niemodyfikowalne zbiory; nie zawiera wyników ani identyfikatorów ćwiczeń.
- `data/filter_presets_repository.dart`: `load(account)`,
  `save(account, name, filters, overwriteId: ...)`, `delete(account, id)`.
  Kolizja nazwy po trim/lowercase zgłasza `DuplicatePresetName(existing)`;
  nadpisanie wymaga ID wskazanego istniejącego zestawu. Nazwa: 1–80 znaków Unicode.
- `providers/filter_presets_providers.dart`: `filterPresetsAccountProvider`
  obserwuje wyłącznie lokalny `syncState` (`accountId`, `offlineAccess`). Nie
  tworzy auth/session/API providera, również przy przywracaniu offline.
  `filterPresetsRepositoryProvider` dostarcza jedno repozytorium/kolejkę zapisów;
  `filterPresetsProvider` udostępnia `AsyncValue<List<FilterPreset>>` i kontroler
  z `save`, `delete`, `apply(id)` (zwraca kryteria).

## Trwałość i izolacja kont

Istniejące `shared_preferences` 2.5.3. Klucz logiczny:
`exercise_filter_presets.v1.<base64url(utf8(stable opaque accountId))>`.
Kodowanie ID nie jest szyfrowaniem; nie używamy e-maila. Plugin zarządza swoim
prefiksem platformowym. Przykładowa wartość:

```json
{
  "version": 1,
  "presets": [{
    "id": "uuid-v4",
    "name": "Dom",
    "filters": {
      "styles": [], "muscles": [], "conditions": [], "positions": [],
      "sprzet": [], "typy": [],
      "partie": [], "poziomy": [], "tylkoUlubione": false,
      "query": "", "sortBy": "alfabetycznie"
    }
  }]
}
```

Uszkodzony dokument lub nieobsługiwana wersja daje pustą listę bez kasowania
storage. Uszkodzony wpis pomijany jest osobno. Brakujące opcjonalne kryteria
mają wartości domyślne, nieznane klucze są ignorowane, nieznane sortowanie
wraca do alfabetycznego. Nieznane wartości zbiorów zachowujemy (np. nowe tagi).
Etap 5 dodaje `conditions` (AND) i `positions` (OR) w tym samym kodeku
`encodeFilters/decodeFilters`, z pustymi zbiorami przy braku kluczy.
Semantyka i brak weryfikacji: `docs/modules/exercise-execution-filters.md`.

Każda operacja przechwytuje konto i jego klucz, sprawdza ważność kontrolera
przed/po oczekiwaniu na storage. Zmiana konta, blokada offline lub brak bindingu
tworzy nowy kontroler i unieważnia poprzedni, także dla A→B→A. Spóźniony odczyt
nie publikuje stanu. Zapisy/usunięcia czekające przed wywołaniem storage są
anulowane. Już przekazanego platformie zapisu nie można cofnąć; pozostaje on
wyłącznie pod przechwyconym kluczem starego konta i nie publikuje stanu nowego.
Nigdy nie wywołujemy globalnego `clear` ani nie usuwamy danych innych kont.
Kolejka serializuje modyfikacje w obrębie repozytorium; to nie jest mechanizm
synchronizacji równoległych kart przeglądarki.

## UI i granice

Przycisk „Zapisane filtry” w Bazie: zapisz aktualne/wczytaj/usuń, jawne
potwierdzenie nadpisania. Bez aktywnego bindingu przycisk jest wyłączony.
Otwarty dialog i potwierdzenie nadpisania ukrywają nazwy po zmianie konta.
Apply przypisuje cały obiekt do istniejącego `exerciseFiltersProvider`;
istniejący listener aktualizuje kontroler query, a chipy/fasety/wyniki obserwują
ten sam stan i bieżący katalog. Reset kryteriów nie usuwa presetów.

Bez zmian schematu Drift, modeli generowanych, backendu, sync encji, metadanych,
zależności, wersji i artefaktów Web SQLite. Generator nie jest potrzebny.
Focused testy: `test/features/exercises/filter_presets_{repository,provider,widgets}_test.dart`.
