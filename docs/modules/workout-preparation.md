# Przygotowanie treningu

Aktualizacja schema2/programy A/B: [training-sets-programs-ui.md](training-sets-programs-ui.md).
Przygotowanie per-set jest informacyjne: pokazuje wszystkie dawki i role,
nie stosuje jednego historycznego kg/reps do całej rampy i nie oferuje zamiany
przed startem. Program korzysta z istniejącego startPrepared, z dodatkowym
lease rewizji programu/terminu; zmiana planu, przesunięcia, nazwy lub granicy
unieważnia stare potwierdzenie. Start nie zalicza terminu.

## Working set

- `lib/features/workout/preparation/domain/`: potwierdzony zapas sprzętu,
  symetryczne konfiguracje w gramach, sugestie, snapshot i niemutowalny szkic.
- `lib/features/workout/preparation/providers/preparation_providers.dart`:
  lokalny odczyt, guardy konta/epoki, katalogu, profilu, szablonu i terminu.
- `lib/features/workout/preparation/presentation/`: modal i karty przygotowania.
- `lib/features/workout/data/workout_repository.dart`: `getPreparationHistory`.
- `lib/features/planner/providers/planner_providers.dart`: `startPrepared`.
- Wejścia: `today_schedule.dart` (wspólne dla obu hostów Dziś) oraz
  `classic_today_page.dart` (trening swobodny).
- Testy: `test/features/workout/preparation/`, `schedule_router_start_test.dart`,
  `classic_today_continuity_test.dart` i istniejące testy planera/recovery.

Kontekst: [guided-training.md](guided-training.md),
[weekly-schedule.md](weekly-schedule.md),
[fixed-load-progression.md](fixed-load-progression.md).

## Kontrakt

Otwarcie i anulowanie modala nie zapisują sesji, planu, szkicu, serii, PR ani
outboxa. Szkic przygotowania istnieje wyłącznie w pamięci. Start ponownie sprawdza
binding konta i oryginalny szablon/termin; zmiana szablonu oraz utworzenie sesji
korzystają z transakcji istniejącego planera. Nie zaliczają terminu treningu.
Celowanie do lokalnego szkicu jest ograniczone dokładnym slotem, ćwiczeniem,
stroną i wariantem; nie zmienia globalnej masy prescription ani dawnych wyników.
Flush lokalnej kolejki następuje poza zewnętrzną transakcją. Błąd flush wymaga
ponownego odczytu istniejącej sesji, a nie uruchomienia następnej.

Zamiana zachowuje dawkę slotu i usuwa ciężar poprzedniego ćwiczenia. Zakresy
„tylko trening” i „trening i szablon” są składane osobno. Obie wynikowe listy
muszą mieć unikalne ID. Katalog, profilowy sprzęt, tracking i kryteria planu nie
są automatycznie luzowane. Legacy bez struktury ma informacyjny podgląd i start
bez prowadzenia; uszkodzona struktura nie jest traktowana jako legacy.

Brak historii jest zwykłym pierwszym treningiem: cel z szablonu albo puste pole.
Historia pochodzi z ostatniej rzeczywistej serii zakończonej, nieusuniętej sesji,
z dokładnym exerciseId/side/variantId. Nie używa PR ani testów sprawnościowych.
Nowa progresja nie zmienia `proposeFixedLoad`. Sugestia kg wymaga dwóch pełnych
sesji na jednym ciężarze, górnej granicy zakresu, wszystkich RPE ≤7 oraz
najmniejszego wykonalnego wzrostu ≤10%; wymaga jawnego przyjęcia.

## Jednostki i ograniczenia

Hantle: kg na sztukę łącznie z uchwytem i talerzami; gryf EZ: całość łącznie
z 7 kg gryfu. Zapas właściciela jest jawną konfiguracją tej prywatnej instalacji,
nie rozpoznawaniem sprzętu innych kont. Solver uwzględnia wspólne talerze dla
pary hantli, ale nie gwarantuje miejsca na uchwycie, udźwigu ławki ani zacisków.
Zestawy kolejnych ćwiczeń mogą wymagać przełożenia talerzy. Brak dokładnej masy
nie powoduje zaokrąglenia wejścia. Zdjęcia sprzętu nie są assetami aplikacji.

Bez nowej migracji, encji sync i zależności. Szkice są lokalne, bez gwarancji
zapisu po nagłym zabiciu procesu; strony/warianty zmienia się w aktywnym treningu,
nie w modalu. Rzeczywisty telefon i VoiceOver wymagają odrębnego odbioru.
