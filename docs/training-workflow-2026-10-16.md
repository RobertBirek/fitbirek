# Usprawnienia prowadzenia treningu — 2026-10-16

**Wydane jako1.13.0+26**, web-only2026-10-16 o19:56:57 UTC;
kontrola publiczna zakończona19:57:35 UTC. Pełne dowody:
[raport wydania](releases/2026-10-16-web-1.13.0-26.md).

## Zakres wykonany po wydaniu katalogu1.12.0+25

1. **PR per strona i porównania:** rozdzielone exerciseID+NULL/both/left/right,
   stare dane bez backfillu. Historia i najlepszePR prezentują zakres strony.
   Epley pozostaje metryką dodatnich kg+powtórzeń, nie sekund/masy własnej.
   Porównania ostatniejserii pokazują rzeczywiste deltykg/reps/sekundy.
2. **Zapisane filtry:** nazwanekryteria, nie kopie ćwiczeń; SharedPreferences
   na urządzeniu, osobnodlakonta, wersjonowanyJSON. Wczytanie obejmuje query,
   sortowanie, style, mięśnie, sprzęt, warunki i pozycje. Brak nowej encji sync;
   zestawy nie synchronizują się pomiędzy urządzeniami.
3. **Interwały:** przygotowanie/praca/przerwa/rundy, pauza/wznowienie/skip,
   anulowanie i zakończenie. Wyniki to faktyczne sekundypracy, nie odpoczynek.
   Zapis tylko po potwierdzeniu, atomowo paczka serii+outbox, bez doubletap.
   Sygnały systemowe opcjonalne; przeglądarka może je ograniczać w tle.
4. **Generator zfiltrów:** przycisk w Bazie prowadzi do /settings/planner.
   Aktualne kryteria i pełny posiadanysprzęt ograniczają pulę. Sekcje
   rozgrzewka/main/schłodzenie, estymowanyczas pracy/przerw/przejść<=budget.
   Brakującesekcje to ostrzeżenia, nie ćwiczenia dobrane spoza filtrów.
   Wymiana pojedynczegobloku nie zmienia innych. Zapisuje się struktura
   i cele; uruchomienie korzysta z istniejącej sesji. Cele widoczne są
   w podglądzie, nie są automatycznymi wpisami historii lub serii.
5. **Warunki wykonania:** sześć jawnych oznaczeńAND i pięć pozycjiOR,
   pokrycie wszystkich363ćwiczeń. Brak danychniepotwierdza warunku i nie
   powoduje cichego poszerzenia wyników/generatora. Quiet to niskiimpakt,
   nie gwarancja akustyki; smallspace wymaga miejsca na sprzęt i zakresruchu.
   Nie są to zalecenia medyczne.
6. **Stały ciężar:** propozycja na podstawie dwóch różnych zakończonych
   sesji, identycznego obciążenia/strony i poprawnegoRPE. +1powtórzenie
   tylko do jawnejgórnejgranicyprzydwócheasyRPE,8utrzymanie,>=9ostrożniejszy
   cel. Brakwiarygodnychdanych=bez wymyślonegocelu, nigdy automatycznie
   więcejkilogramów. Sandbag20kg tylkogdy takzapisano. Przyjęcie zmienia
   tylko szkicpowtórzeń zpotwierdzeniemzastąpienia; brak zapisu/PR/outbox.
   Czas i rundy pozostają przy utrzymaniu, bo brak porównywalnegoprotokołu.

## Trwałość i bezpieczeństwo

- AddytywneDrift8→9:personal_records.side nullable;9→10:
  workout_plans.structure_json nullable. LegacyNULL odrębneodObie.
- Nowe pola PRside i planstructure zachowane w backup/restore/sync JSONB;
  nie zmieniano schematu backendu i nie wymagano Alembic.
- Walidacja strukturyplanu przed utrwaleniem; złypull wycofuje wiersze
  i kursor. Istniejącyuszkodzonyplan nie ukrywa całejhistorii; raw dane
  zachowane, start/podgląd zablokowane, usuwanie nadal dostępne.
- DELETEplanów zachowuje cztery pola legacy dla starszych klientów,
  nie dekodując structureJson. Nie przepisuje się attemptedpayloads.
- Sygnał epoki autoryzacji unieważnia asynczapis przy rozpoczęciulogout,
  niezależnieod kolejkiSQLite. Zapisypaczek/PR/serii nie trafiają do nowej
  lub podmienionejsesji. Guardy są także ponawiane po dialogach przyjęciacelu.
- Odczyty cache nie uruchamiają auth ani płatnych/HTTP providerów.

## Review i testy

Oddzielne zadania specjalistyczne obejmowały domeny. Niezależne review
wykryły i zamknęły trzyMEDIUM: wylogowanie podczas zapisu, zatrucie historii
wadliwą strukturą i kompatybilnośćDELETEstarychklientów. Fixy mają testy
odtwarzające problem; rechecki nie wykazały pozostałych HIGH/MEDIUM
w sprawdzonych zakresach. Finalne wyniki release zawiera raport wydania.

Pipeline danych zachowuje wszystkie363treścićwiczeń, ID i ilustracje,
dotychczasowe style/mięśnie/tracking; dodano odtwarzalną klasyfikację
warunków. Nie zmieniano zależności, Flutter/Dart ani WebSQLite.

Szczegółowe kontrakty i ograniczenia:
- [PR i serie](modules/workout-catalog-tracking.md)
- [Zestawy filtrów](modules/exercise-filter-presets.md)
- [Interwały](modules/workout-intervals.md)
- [Generator](modules/structured-planner.md)
- [Warunki](modules/exercise-execution-filters.md)
- [Progresja](modules/fixed-load-progression.md)
- [Źródła warunków](../tools/EXECUTION_CONDITIONS.md)

## Końcowa weryfikacja wydaniowa

Wersja1.13.0+26: świeży finalny Docker runtime zależny od verification,
**560 testów Flutter, analiza0 problemów,344 backend i37 Python passed**.
Format67 nowych/zmienionych Dartów:0 zmian;17 śledzonych plików generowanych
zgodnych ze świeżym build_runner. Zachowano katalog, wszystkie363 obrazy,
zależności i WebSQLite. Pełne dowody oraz stan publikacji:
[wydanie1.13.0+26](releases/2026-10-16-web-1.13.0-26.md).
