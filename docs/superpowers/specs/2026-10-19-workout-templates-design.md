# Szablony i wykonania treningów

## Zatwierdzony kierunek

Użytkownik tworzy własne nazwane szablony bez wykonywania serii. Szablon jest
oddzielony od sesji i historii. Wybór szablonu tworzy nową sesję ze snapshotem
celów. Można dopisywać ćwiczenia, również podczas powtarzania wykonania.
Mentor proponuje szablon do edycji i świadomego zatwierdzenia, nigdy nie zapisuje
wykonanych serii na podstawie samej propozycji.

## Model i decyzje implementacyjne

- Wykorzystać istniejące WorkoutPlans/workoutPlan i StructuredPlan schema1.
  Dotychczasowe plany są szablonami; bez kopiowania i drugiej tabeli szablonów.
- Jeden zestaw celów na ćwiczenie: liczba serii, powtórzenia albo sekundy,
  przerwa; opcjonalny ciężar. Ćwiczenie najwyżej raz w szablonie. Kolejność
  edytowalna. Nazwa i co najmniej jedno ćwiczenie wymagane do zapisu szablonu.
- Cele nie są wykonaniem. Start ma nowy UUID, zero zalogowanych serii i PR.
  Edycja/usunięcie szablonu nie zmienia historycznych snapshotów sesji.
- Zachować dotychczasowy kontrakt struktury, bez podnoszenia schemaVersion.
  Ewentualny opcjonalny ciężar wymaga walidacji finite >=0 i zachowania w
  serializerach oraz testów starszej struktury bez pola. Budżet 5–90 minut
  istniejącego modelu pozostaje jawnym ograniczeniem; czas jest estymowany.
- Edytor potrafi utworzyć nowy szablon, zmienić istniejący i utworzyć kopię
  z sesji (snapshot celów lub potwierdzone wykonanie). Aktualizacja istniejącego
  jest osobną potwierdzoną akcją; porównanie bazowego rekordu zapobiega
  nadpisaniu zmian innej karty/urządzenia, także deferred/quarantine.

## Interfejs

W Treningu dostępne „Szablony” i „Historia”; istniejąca historia może pozostać
na ekranie głównym z wyraźnym wejściem „Moje szablony”. Nowy szablon nie tworzy
sesji. Edytor pokazuje katalog, wyszukiwanie, dodawanie/usuwanie/przesuwanie
pozycji i formularze celów. Zapis i Start są rozdzielone.

## Postęp i zakończenie

- Procent tylko przy wiarygodnym celu: wykonane serie / zaplanowane serie,
  maksymalnie 100%. Dodatkowe serie nie zaliczają celu innego ćwiczenia/bloku.
- Dla guidance liczyć potwierdzone, nieusunięte set UUID przypisane zdarzeniami
  performed do właściwego bloku, z limitem celu bloku. Skip nie jest wykonaniem.
- Dla repeat liczyć potwierdzone UUID z repeatCompleted, nie wszystkie logi.
  Dla treningu swobodnego pokazać liczbę serii, bez wymyślonego procentu.
- Pusta sesja: „Wróć”, „Zapisz jako szablon” (gdy są wybrane ćwiczenia),
  „Odrzuć pusty trening”. Pustej sesji nie oznaczać jako wykonanej.
  W repozytorium zwykłe finish wymaga żywej serii, również recovery.
- Częściowy plan można świadomie zakończyć z ostrzeżeniem o brakujących seriach.
  Ostrzec przed odrzuceniem szkiców/checkpointu. Walidacja i zapis w transakcji.

## Usuwanie wykonania

Potwierdzenie z datą i liczbą serii. Tombstone sesji oraz wszystkich jej żywych
serii, usunięcie lokalnego szkicu i outbox są atomowe. Nie usuwać fizycznie
historii ani zmieniać UUID/attempted payloadów. Plan źródłowy pozostaje.
Nie usuwać PR przez heurystykę daty: historyczny model nie ma klucza sesji.
UI wyjaśnia, że oddzielnie zapisane rekordy osobiste pozostają. Liczniki,
trendy i harmonogram nie mogą liczyć usuniętej sesji jako wykonanej.

## Dodatkowe ćwiczenia i Mentor

„Dodaj ćwiczenie” działa we wszystkich trybach. W repeat osobny formularz
dodatkowych ćwiczeń nie przesuwa repeatCompleted; szkic zachowany po restarcie.
Również po ukończeniu wszystkich celów można dopisać wykonanie.

Mentor ma jawne generowanie propozycji szablonu (nazwa i intencja, np. poranne
rozciąganie 15 min). Propozycja jest strukturalna i ograniczona do prawdziwych
ID aktualnego katalogu; wynik nie tworzy automatycznie szablonu/sesji/logów.
Zachować zgody, ograniczenia dostawcy i ledger idempotencji/kosztów. W razie
braku konfiguracji pokazać wyjaśnienie i możliwość samodzielnego ułożenia.

## Bezpieczeństwo i akceptacja

Flutter3.35.4/Dart3.9.2, bez upgrade/zależności. Guard konta, epoch i trwałego
bindingu przed/po await i w transakcji; nie przywracać tombstone ani nadpisywać
niezastosowanego deferred. Loading/error/cancel nie tworzą rekordów. Testy
offline/reopen/sync/backup, small320px text200%, rzeczywisty routing.
W tej implementacji nie wykonujemy produkcyjnych zapisów ani wdrożenia bez
oddzielnego potwierdzenia. Istniejący niezatwierdzony diff hotfixu1.16.1 zachować.
