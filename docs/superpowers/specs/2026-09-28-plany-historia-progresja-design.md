# FitBirek: trening z planu, historia ćwiczenia i progresja

Data: 2026-09-28. Projekt opisany w rozmowie został zaakceptowany przez użytkownika.
Dokument oczekuje na przegląd użytkownika przed przygotowaniem planu implementacji.

## Cel i kolejność

Domknąć ścieżkę: zapisany plan → wykonany trening → ocena wyników → cel na
kolejny trening. Realizacja w trzech osobno weryfikowanych etapach:

1. Uruchamianie treningu z zapisanego planu.
2. Historia i porównanie wykonań konkretnego ćwiczenia.
3. Opcjonalne, jawne reguły progresji dla ćwiczeń z ciężarem i powtórzeniami.

Rozszerzamy obecne moduły zamiast przebudowywać całą aplikację lub uzależniać
podstawowe czynności od Mentora. Duża przebudowa zwiększa ryzyko regresji,
a realizacja wyłącznie przez AI ogranicza przewidywalność i pracę offline.

## Kontekst i ograniczenia

- Flutter/Riverpod, lokalna baza Drift i istniejąca synchronizacja FastAPI.
- Planer zapisuje plany; aktywny trening obsługuje ćwiczenia, serie i rekordy.
- Historia sesji i lista rekordów nie zastępują historii wszystkich wykonań ćwiczenia.
- Punkty integracji: `lib/features/planner/presentation/pages/planner_page.dart`,
  `lib/features/workout/providers/workout_providers.dart`,
  `lib/features/workout/data/workout_repository.dart`,
  `lib/features/workout/presentation/pages/active_session_page.dart`,
  `lib/features/progress/presentation/pages/progress_page.dart`.
- Zachowujemy Flutter 3.35.4, Dart 3.9.2, istniejące ID ćwiczeń i obsługę Mentora.
- Nie cofamy ani nie porządkujemy niezwiązanych zmian już obecnych w repozytorium.
- Wdrożenie produkcyjne, przebudowa generatora i automatyczny trener AI są poza zakresem.
- Nie zmieniamy aplikacji podczas zatwierdzania tej specyfikacji.

## Etap 1: rozpoczęcie treningu z planu

### Zachowanie użytkowe

Zapisany plan otrzymuje przycisk „Rozpocznij trening”. Ćwiczenia zostają wczytane
w kolejności planu, a użytkownik przechodzi do istniejącego ekranu aktywnej sesji.
Można dodawać lub pomijać ćwiczenia bez edytowania planu źródłowego.

Jeżeli trening już trwa, aplikacja proponuje powrót do niego; nie nadpisuje go
i nie rozpoczyna drugiego. Przycisk jest blokowany na czas uruchamiania,
a warstwa operacji chroni także przed równoległym wywołaniem.

Brakujące ćwiczenia są wskazywane przed rozpoczęciem. Użytkownik może anulować
albo potwierdzić rozpoczęcie z pozostałymi ćwiczeniami. Gdy nie pozostaje żadne
ćwiczenie, rozpoczęcie jest zablokowane. Powtórzone ID są redukowane do pierwszego
wystąpienia, zgodnie z modelem unikalnych ćwiczeń aktywnej sesji.

Lista rozróżnia „brak zapisanych serii” i „zapisano serie”. Jedna seria nie oznacza
ukończenia ćwiczenia. W tym etapie nie wprowadzamy obowiązkowych celów serii.

### Granice odpowiedzialności

Operacja rozpoczęcia przyjmuje identyfikator planu, odczytuje go i rozwiązuje ID
ćwiczeń z lokalnego katalogu. Walidacja poprzedza utworzenie sesji. Kontroler
treningu odpowiada za pojedynczą aktywną sesję; ekran za potwierdzenia i nawigację.
Stan sesji nie może być częściowo przełączony po błędzie zapisu lub zmianie konta.
Nie zapisujemy sztucznych serii tylko po to, aby przypisać ćwiczenia do sesji.

## Etap 2: historia ćwiczenia

### Dostęp i dane

Historia jest dostępna ze szczegółów ćwiczenia i z aktywnego treningu.
Repozytorium odczytuje lokalne serie danego ID ćwiczenia, grupując je według
zakończonych, nieusuniętych sesji należących do bieżącego kontekstu danych.
Nie uwzględnia sesji aktywnych ani usuniętych serii. Kolejność wyznacza czas
zakończenia sesji; przy równych czasach stosowany jest stabilny identyfikator.

Widok pokazuje datę oraz zapisane ciężary, powtórzenia, czasy i RPE.
Brak wartości oznacza brak danych, nigdy automatycznie zero.

### Porównanie i trend

- Porównujemy dwa ostatnie zakończone wykonania tego ćwiczenia.
- Suma powtórzeń jest porównywana przy jednakowym ciężarze wszystkich
  porównywanych serii oraz tej samej liczbie serii; inaczej pokazujemy wartości
  obok siebie bez oceny, że wynik jest lepszy.
- Dla serii z dodatnim ciężarem i powtórzeniami można pokazać sumę kg × powtórzenia,
  opisaną jako objętość zarejestrowanych serii, nie uniwersalną miarę postępu.
- Trend ciężaru przedstawia najwyższy zapisany ciężar w sesji wraz z kontekstem
  powtórzeń. Trend izometrii przedstawia najdłuższą serię w sekundach.
- Nie łączymy kilogramów i sekund w jeden wynik. Dane niepasujące do metryki
  pozostają w liście serii, ale nie są przeliczane na wykresie.
- Brak historii, jedno wykonanie i brak wartości dla wykresu mają jawne stany puste.

Odczyt danych, obliczanie podsumowań i prezentacja są oddzielone. Obliczenia
działają bez sieci, nie modyfikują zapisanych wyników ani rekordów osobistych.

## Etap 3: jawne sugestie progresji

### Ustawienia

Reguła jest opcjonalna i przypisana do ćwiczenia w konkretnym planie. Zawiera:

- dodatnią docelową liczbę serii;
- dodatnią dolną i górną granicę powtórzeń, dolna nie większa od górnej;
- dodatni krok ciężaru i maksymalny dostępny ciężar;
- maksymalne RPE zgodne z zakresem RPE obsługiwanym przez aplikację.

Reguła dotyczy wyłącznie ćwiczeń z dodatnim ciężarem i powtórzeniami.
Izometria i ćwiczenia bez obciążenia korzystają z historii, ale nie otrzymują
automatycznych sugestii progresji. Ustawienia nie są automatycznie włączane
w starszych planach.

### Algorytm pierwszej wersji

Silnik jest deterministyczną funkcją reguły i ostatniego zakończonego wykonania
ćwiczenia. Nie potrzebuje Mentora ani zewnętrznego API. Historia źródłowa dotyczy
tego samego ćwiczenia, również jeśli wykonano je poza tym planem; reguła pozostaje
specyficzna dla planu, a sugestia pokazuje datę źródłowego treningu.

Zwiększenie jest proponowane wyłącznie, gdy:

1. Liczba zapisanych serii jest dokładnie równa docelowej liczbie serii. Nadmiar
   serii oznacza niejednoznaczne dane, nie jest automatycznie pomijany.
2. Każda seria ma ten sam dodatni ciężar i co najmniej górny próg powtórzeń.
3. Każda seria zawiera RPE nieprzekraczające ustawionego maksimum.
4. Ciężar zwiększony o skonfigurowany krok nie przekracza limitu sprzętu.

Wynik zawiera proponowany ciężar, zakres powtórzeń, liczbę serii i uzasadnienie.
Przykład: „Wykonano 3 × 12 przy 10 kg, RPE nie przekroczyło 8.
Propozycja: 11 kg, cel 3 × 8–12”.

Jeżeli kompletne wyniki nie osiągają progu, sugestia wskazuje utrzymanie ciężaru.
Jeżeli osiągnięto limit sprzętu, nie proponuje ciężaru spoza limitu. Przy brakach
RPE, różnym ciężarze, braku historii lub niezgodnej liczbie serii wyjaśnia brak
podstaw do zwiększenia, bez udawania pewnej rekomendacji. Nie proponuje
automatycznej redukcji obciążenia ani zmiany ćwiczenia.

### Akceptacja i trwałość

Użytkownik może zaakceptować lub zignorować sugestię. Akceptacja zapisuje cel
dla ćwiczenia w danym planie i może podpowiedzieć parametry przy zapisie kolejnych
serii, ale nie zapisuje wykonania. Zignorowanie niczego nie zmienia.

Przed akceptacją sprawdzana jest aktualność danych źródłowych i reguły. Jeżeli
zmieniły się wskutek edycji lub synchronizacji, sugestia jest przeliczana i wymaga
ponownej akceptacji. Wielokrotna akceptacja tej samej sugestii zapisuje ten sam
cel, a nie nalicza kolejnych kroków ciężaru.

## Dane, synchronizacja i zgodność

- Uruchamianie, historia, reguły i akceptacja celu działają offline.
- Reguły i zaakceptowane cele są częścią danych planu; podlegają istniejącemu
  modelowi własności, synchronizacji, usuwania i rozwiązywania konfliktów.
- Serie pozostają źródłem historii; podsumowania i sugestie są wyliczane,
  nie tworzą dodatkowych synchronizowanych kopii wyników.
- Starsze rekordy i kopie zapasowe bez nowych pól oznaczają brak reguł i celów.
- Eksport i import zachowują nowe ustawienia. Błędne dane są odrzucane przez
  walidację bez częściowego odtworzenia bazy.
- Plan implementacji musi ustalić dokładny kontrakt nowych pól po przeglądzie
  obecnego formatu planów, synchronizacji i backupu. To detal implementacyjny,
  nie zgoda na lokalne pola pomijane przez synchronizację.
- Rozszerzenie kontraktu musi chronić nowe dane przed cichą utratą przez starszy
  klient. W razie potrzeby należy jawnie odrzucić niezgodny zapis zamiast zerować pola.
- Zmiany Drift wymagają migracji oraz regeneracji plików generowanych.
- Usunięcie sesji, planu lub zmiana konta podczas operacji nie może odtworzyć
  usuniętych danych ani zapisać celu w innym kontekście użytkownika.

## Weryfikacja i kryteria odbioru

### Etap 1

- Test kolejności, pustego planu, brakujących i zduplikowanych ID.
- Test aktywnej sesji, podwójnego kliknięcia i błędu zapisu.
- Test anulowania potwierdzenia oraz braku modyfikacji planu źródłowego.
- Test regresji istniejących operacji Mentora i usuwania sesji.

### Etap 2

- Test grupowania, kolejności, wykluczania usuniętych i niezakończonych sesji.
- Test brakujących wartości, jednego wykonania, różnej liczby serii i ciężarów.
- Test odrębnych metryk dla ciężaru/powtórzeń i izometrii.
- Test wejścia z obu ekranów i aktualizacji po zmianie danych.

### Etap 3

- Test wszystkich warunków zwiększenia oraz każdego powodu braku sugestii.
- Test granic RPE, ciężarów ułamkowych, maksimum sprzętu i walidacji reguły.
- Test nieaktualnej i wielokrotnie akceptowanej sugestii.
- Test, że akceptacja nie tworzy serii, a zignorowanie nie zmienia celu.
- Test oddzielnych reguł tego samego ćwiczenia w różnych planach.

### Przekrojowo

- Test migracji starych planów, offline, synchronizacji i round-trip backupu.
- Test ochrony nowych ustawień przed utratą przy starszym formacie zapisu.
- Analiza Flutter i właściwe testy klienta; testy backendu, jeśli zmienia się kontrakt.
- Regeneracja i kontrola wersji zgodnie z AGENTS.md na etapie przygotowania wydania.
- Brak zmian wdrożeniowych i operacji na produkcyjnej bazie w ramach tego zadania.

## Kolejny krok

Po akceptacji zapisanego dokumentu powstanie plan implementacji z zadaniami
i testami dla kolejnych etapów. Niezależne zadania klienta, kontraktu backendu
i przeglądu bezpieczeństwa danych należy rozdzielić między wyspecjalizowanych
subagentów, bez równoległej edycji tych samych plików.
