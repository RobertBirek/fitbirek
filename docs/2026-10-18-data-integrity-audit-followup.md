# Audyt FitBirek — drugi pakiet: integralność danych

## Zrealizowany zakres

- **Sync klienta:** trwałe zachowanie wadliwych rekordów pull, rozpoznawanie
  bezpiecznego zastąpienia starszej historii oraz postęp niezależnych danych.
  Nieznany wynik push i niepoprawny autorytet CAS wstrzymują daną encję oraz
  jej zależności, bez przepisywania oryginalnej próby. Błędy SQLite nadal
  wycofują transakcję. Szczegóły i ograniczenia:
  [audyt klienta sync](2026-10-18-client-sync-audit.md).
- **Wylogowanie:** trwała generacja powiązania oraz kontrole przed batchami
  i zastosowaniem odpowiedzi odrzucają nieaktualny przebieg także przy dwóch
  instancjach i zmianie A–B–A. Wysłanego żądania nie można cofnąć na serwerze.
- **Backup:** wszystkie 11 kolekcji eksportu jest materializowanych w jednej
  transakcji odczytu. Filtrowanie i kodowanie JSON odbywają się poza transakcją.
  Dwa testy z niezależnym writerem w SQLite WAL potwierdzają spójność snapshotu.
- **Zgodność API:** pominięte `workoutPlan.structure` i `side` serii/PR są
  zachowywane, jawne `null` je usuwa. Zmiana ćwiczeń bez odpowiedniej struktury
  powoduje konflikt; hash idempotencji dotyczy oryginalnego żądania.
  Kontrakt: [SYNC_EXTENSIONS.md](../backend/SYNC_EXTENSIONS.md).
- **Mentor:** selektor wiąże zatwierdzoną projekcję notatki lub masy (także
  Apple Health). Zmienione źródło jest odrzucane przed rezerwacją kosztu
  i wywołaniem dostawcy. Flutter zachowuje tekst i wymaga świeżego podglądu,
  ponownego wyboru i potwierdzenia. Nieznany wynik wcześniejszej płatnej operacji
  nie jest uznawany za bezpieczny do usunięcia po późniejszym odrzuceniu.
  Kontrakt: [MENTOR_CONTEXT_SELECTORS.md](../backend/MENTOR_CONTEXT_SELECTORS.md).

## Końcowa weryfikacja

Stan po zintegrowaniu pierwszego i drugiego pakietu:

| Kontrola | Wynik |
| --- | --- |
| Pełne `flutter analyze --no-pub` | Bez uwag |
| Pełne `flutter test --no-pub --reporter expanded` | 907 PASS |
| Pełne `.venv/bin/python -m pytest -q` w `backend/` | 436 PASS |
| `dart tools/generate_app_version.dart --check` | PASS |
| Format wszystkich 52 nowych/zmienionych plików Dart | PASS |
| Przeglądy zgodności, jakości i adaptacji testów | APPROVED |

Flutter: 3.35.4 / Dart 3.9.2 w istniejącym obrazie narzędziowym
`fit-web:release-1.13.0-26-verified`, źródła bieżącej gałęzi zamontowane do
`/app`, `--network none`, `--no-pub`. Backend: Python 3.12, istniejący venv
z hash-locked zależnościami, izolowany PostgreSQL przez Testcontainers.

Wstępny pełny przebieg klienta wykazał osiem nieaktualnych testów. Poprawiono
rozróżnienie awarii transportu od trwałego konfliktu, typy map fixture'ów
oraz oczekiwania kwarantanny. Nie usunięto kontroli rollbacku: osobny test
wstrzykuje rzeczywisty błąd SQLite i sprawdza cofnięcie danych oraz kursora.
Po tych poprawkach ponownie uruchomiono cały zestaw z powyższym wynikiem.

## Stan wydania i dalsza akceptacja

Zmiany są lokalne na `fix/training-continuity-ux`; nie wykonano commita,
podniesienia wersji ani wdrożenia. Nie ma zmian schematu Drift/Alembic,
zależności ani artefaktów Web SQLite.

Pozostaje akceptacja rzeczywistego PWA z wieloma kartami/OPFS oraz urządzeń
mobilnych. Przy przyszłym wydaniu należy uwzględnić aktualizację wszystkich
klientów, odrzucenie starych selektorów Mentora i udokumentowaną kolejność
wdrożenia API/klienta. Testy nie obejmowały płatnych wywołań rzeczywistego AI.

W chwili zakończenia drugiego pakietu kolejnymi pracami były dostępność/ergonomia
UI oraz cache, wydajność PWA i procedury operacyjne. Pakiet UI wykonano następnie
na tej samej gałęzi; zakres i aktualne wyniki klienta opisuje
[raport UI/UX](2026-10-18-ui-accessibility-audit-followup.md).
Pakiet PWA i operacyjny pozostaje do wykonania.
