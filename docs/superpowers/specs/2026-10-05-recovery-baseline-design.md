# Odtworzenie bazy recovery obrazów

## Problem

Automatyczny `docker system prune -af` usunął obraz i tag
`fit-migration:production`. Nie istnieje zewnętrzny artefakt umożliwiający
odtworzenie historycznego obrazu, więc backup i drill odtworzeniowy nie mają
pełnego zestawu obrazów rollbackowych.

## Cel

Ustanowić nową, sprawdzoną bazę recovery z bieżącego zatwierdzonego kodu przed
wdrożeniem produkcyjnym.

## Zakres

1. Usunąć z commitowanej dokumentacji rzeczywiste identyfikatory osobowe, które
   nie są niezbędne do działania aplikacji.
2. Zbudować kandydatów API, migratora i Web pod nowymi, unikatowymi tagami;
   nie nadpisywać działających obrazów ani tagów produkcyjnych przed walidacją.
3. Potwierdzić zawartość kandydatów, ich testy i zgodność z trzema runtime
   plikami Compose.
4. Po powodzeniu walidacji ustanowić nowy obraz migratora jako
   `fit-migration:production`, wykonać backup i izolowany drill odtworzeniowy.
5. Dopiero po sukcesie backupu i drilla promować zatwierdzone obrazy, commitować,
   wypchnąć `main` i wdrożyć przez bazowy, Push i Mentor Compose.

## Ograniczenia bezpieczeństwa

- Historycznego obrazu nie wolno udawać ani rekonstruować z bieżącego źródła.
  Nowe obrazy są nową bazą recovery i muszą mieć zapisane identyfikatory.
- Nie uruchamiać `docker system prune -a`; przyszłe tagowane obrazy release i
  rollback muszą zostać zachowane.
- Nie wyświetlać rozwiniętej konfiguracji Compose ani sekretów.
- Wdrożenie następuje wyłącznie po sukcesie backupu, drilla i walidacji
  `config --quiet` dla trzech plików Compose.

## Weryfikacja

- Pełne testy backendu oraz webowy target Docker `verification` przechodzą.
- Backup kończy się sukcesem i manifest zawiera nowy zestaw obrazów.
- Izolowany restore drill kończy się sukcesem.
- Po wdrożeniu usługi są zdrowe, rewizja bazy jest oczekiwana, a publiczne
  kontrole health i statycznego Web przechodzą.
