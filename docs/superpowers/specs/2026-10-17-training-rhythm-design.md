# Powtarzanie, rytm tygodnia, trendy i akceptacja PWA

## Zatwierdzony zakres

Użytkownik zatwierdził wszystkie propozycje oraz poniższe zasady zachowania.
Baseline: czysty `e0fe9a6`, produkcja 1.14.0+27. Ta praca nie obejmuje
automatycznej publikacji, nowej wersji ani kolejnego commit/push.
Flutter 3.35.4 / Dart 3.9.2 pozostają bez zmian.

Prace są podzielone na trzy niezależne moduły funkcjonalne i osobną akceptację
PWA. Nie tworzymy drugiego planera, mechanizmu PR ani silnika synchronizacji.

## A. Powtórz trening

- Z historii zakończonej sesji użytkownik wybiera oryginalny plan ze snapshotu
  albo faktyczne wykonanie. Legacy sesja bez planu nie udaje, że go posiada.
- Podgląd i potwierdzenie poprzedzają nową sesję z nowym UUID. Żadne stare UUID
  serii, zdarzenia wykonania, PR, checkpointy lub czasy pracy nie są kopiowane.
- Wykonanie obejmuje wszystkie rzeczywiście zapisane serie, także dodatkowe,
  z deterministyczną kolejnością i zachowaniem ćwiczenia, nullable strony,
  nullable wariantu oraz różnych wartości kolejnych serii.
- Wartości są celami/prefillem, nie wykonaniem. Historyczne RPE jest informacją,
  nie nowym pomiarem. Każda nowa seria wymaga jawnego zapisu.
- Brak ćwiczenia, usunięty wariant lub niespójny snapshot blokuje odpowiednią
  pozycję z wyjaśnieniem; nie następuje cicha zamiana na wariant bazowy.
- Aktywna sesja nie jest porzucana. Double tap, zmiana konta i zdalne usunięcie
  źródła nie mogą tworzyć dodatkowych sesji. Zachować transakcje i outbox.
- Powtórzenie i wznowienie to odrębne operacje. Powtórzenie interwałów nie
  odtwarza nieznanego historycznie protokołu i nie zalicza starego czasu pracy.

## B. Rytm tygodnia

- Istniejące zapisane plany są przypisywane do dni tygodnia. Harmonogram jest
  dostępny offline i synchronizowany między urządzeniami.
- Referencje planów i sesji używają stabilnych sync UUID, nigdy lokalnych int ID.
- Reguła cykliczna i wystąpienie konkretnego dnia mają różne tożsamości.
  Przesunięcie dotyczy jednego niewykonanego wystąpienia, nie przyszłych tygodni.
- Daty są dniami kalendarza, bez utożsamiania północy UTC z lokalnym dniem.
  Edycje i konflikty używają UTC. Tydzień zaczyna się w poniedziałek.
- Start, przekroczenie daty ani finish pustej sesji nie zaliczają wystąpienia.
  Zaliczenie jest jawne, powiązane z zakończoną nieusuniętą sesją mającą zapisane
  wykonanie. Nie tworzy dodatkowej sesji, serii ani PR.
- Niedostępny plan i usunięta powiązana sesja są widoczne jako niedostępność,
  nie zastąpienie ani utrwalone fałszywe zaliczenie. Zmiany reguły nie przepisują
  historii wykonanych wystąpień.
- Konflikty dwóch urządzeń są deterministyczne, z tombstone'ami i zachowaniem
  prób wysłanych payloadów. Nowe dane nie mogą blokować globalnego pull starych
  klientów: bez nowego SyncEntityType. Omission musi zachowywać nowe rozszerzenie,
  explicit null pozostaje świadomym wyczyszczeniem. Backup/restore zachowuje je.
- Ograniczona kolekcja reguł/wyjątków, bez nieskończonego zapisu wystąpień
  kalendarza i bez automatycznego prune tombstone'ów.

## C. Trendy postępu

- Czysty odczyt zakończonych nieusuniętych sesji; dokładny scope to
  exerciseId + nullable side + nullable variantUUID. NULL != both.
- Dwie porównywalne sesje dają porównanie; co najmniej trzy dają opis trendu.
  UI rozróżnia brak danych, za mało danych, nieporównywalność i brak metryki.
- Powtórzenia przy tym samym obciążeniu: nie łączyć różnych ciężarów w jeden
  arbitralny wynik. RPE jest osobną metryką, brak RPE nie oznacza zera;
  mniejszy RPE oznacza mniejszy wysiłek tylko przy porównywalnej pracy.
- Czas to wyłącznie faktycznie zapisane sekundy pracy, nie długość sesji.
  Rundy nie implikują identycznego protokołu, jeśli historia go nie przechowuje.
- Wyniki nie zmieniają PR, zaleceń progresji, historii ani celu następnej sesji.
  Nie sugerują diagnozy, leczenia ani pewności przy nieporównywalnych próbkach.

## D. PWA i urządzenie

- Automatyczna akceptacja w izolowanej przeglądarce z aktywnym service workerem,
  zachowanym profilem i rzeczywistym odcięciem całego originu, nie tylko /api.
- Sprawdzić root/deep link, fonty/ilustracje użyte i nieużyte przed offline,
  start/wznowienie po restarcie procesu, szkic i jawne serie oraz reconnect.
- Nie przedstawiać wpisu w manifeście SW jako dowodu precache. Obecny worker
  ma mały CORE i większość zasobów dogrzewa dopiero podczas użycia.
- Jeśli test wykryje błąd, najpierw dowód i diagnoza; istotna zmiana polityki
  pobierania całego katalogu wymaga osobnego przedstawienia kosztu i projektu.
- Fizyczny telefon, wygaszenie ekranu, usunięcie z ostatnich aplikacji i tryb
  oszczędzania energii wymagają udziału użytkownika. Bez urządzenia status
  pozostaje manual pending, bez obietnic pracy timera/sync w tle.

## Integracja i weryfikacja

- Jeden właściciel zmian Drift/profil/sync i generatora: harmonogram. Repeat
  integruje się z workoutem bez równoległych generatorów deklaracji.
- Repeat: workout i szczegóły historii. Trendy: osobne pliki progress i jego
  punkt wejścia. Harmonogram: nowy moduł i planner; routing integruje właściciel
  harmonogramu. Nie przerabiać całego wielkiego workout providera bez potrzeby.
- TDD focused, niezależny przegląd danych offline/CAS/kompatybilności, generator
  i check, format zmienionych plików, analiza oraz pełne testy Flutter/backend.
- Akceptacja browserowa ma odróżniać stub od real API, reload od restartu,
  obsługę cache od dostępu do działającego serwera oraz snapshot od zapisu.
- Bez zmian katalogu369, ilustracji, zależności/toolchainu i produkcyjnych danych.
