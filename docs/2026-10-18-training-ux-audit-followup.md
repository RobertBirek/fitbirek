# Audyt FitBirek — pierwszy pakiet poprawek

## Zakres

Pierwszy pakiet zatwierdzonego planu obejmuje ciągłość treningu, szkice
prowadzonych bloków, formularze liczbowe oraz bezpieczne zakończenie operacji UI.
Zmiany są przygotowane na gałęzi `fix/training-continuity-ux`; ten dokument
nie stanowi potwierdzenia wydania ani wdrożenia produkcyjnego.

## Zrealizowane zachowania

- Start nie zastępuje istniejącej sesji. Dashboard rozróżnia rozpoczęcie,
  kontynuację i oczekiwanie na odczyt recovery.
- Szkice guided zachowują osobne wartości dla sesji, bloku, ćwiczenia, strony
  i wariantu, także przy zmianie tożsamości w obrębie jednego bloku.
- Przejście między blokami i recovery nie zaliczają nieobecności jako pracy.
  Zużyty checkpoint nie wraca po zmianie tożsamości ani po wznowieniu.
- Niezakończoną sesję bez szkicu można jawnie zakończyć bez wznawiania.
  Operacja zachowuje zapisany czas i serie, wymaga aktualnej authority konta
  i zapisuje sesję oraz outbox transakcyjnie.
- Pomiary i testy przyjmują przecinek lub kropkę, walidują wartości skończone
  i reguły metryk. Błędne pola opcjonalne nie są cicho pomijane. Zapis ma
  blokadę ponownego wysłania, a błąd zachowuje wpisany tekst do ponowienia.
- Podsumowanie odróżnia ładowanie, błąd odczytu, brak/usunięcie sesji i dane.
  Oferuje retry oraz przejście do rzeczywistej historii treningów.
- Usunięcie planu wymaga potwierdzenia z nazwą. Anulowanie nie zmienia
  rekordu ani outboxa. Zapis, start i usunięcie planu blokują podwójne akcje.

## Weryfikacja

Użyto istniejącego obrazu narzędziowego `fit-web:release-1.13.0-26-verified`
z Flutter 3.35.4 / Dart 3.9.2, z bieżącym źródłem zamontowanym w `/app`
i wyłączoną siecią. Nazwa obrazu nie jest wersją przygotowanych zmian.

```sh
docker run --rm --network none -v /opt/fit:/app -w /app \
  fit-web:release-1.13.0-26-verified sh -c \
  'dart tools/generate_app_version.dart --check && flutter analyze --no-pub && flutter test --no-pub --reporter expanded'
```

- Kontrola wersji: PASS.
- Pełna analiza Fluttera: `No issues found`.
- Pełny zestaw Fluttera: **869 testów PASS**.
- Format 25 nowych/zmienionych plików Dart: PASS.
- `git diff --check`: PASS.
- Przeglądy zgodności i jakości, w tym końcowy przegląd integracyjny: APPROVED.

Pełna kontrola formatu `lib test` wskazuje ponadto 20 wcześniejszych plików
poza zakresem pakietu. Kontrola używała `--output=none`; tych plików nie
przeformatowano. Nie ma zmian deklaracji Drift/Freezed/JSON wymagających
regeneracji, zmian zależności ani artefaktów Web SQLite.

Nie wykonano nowej akceptacji w przeglądarce/PWA ani na fizycznym telefonie.
Testy providerów i widgetów nie zastępują testu nagłego zamknięcia procesu;
ostatnia edycja przed flush nadal nie ma gwarancji trwałości.

## Kolejne pakiety zatwierdzonego kierunku

1. Synchronizacja i prywatność: odtwarzalność historii z błędnym wpisem,
   izolacja nierozstrzygalnych operacji, logout wielu kart, snapshot eksportu,
   zgodność starszych payloadów i wersja podglądu kontekstu Mentora.
2. Dostępność i UX: kontrast, zawijanie etykiet przycisków, edycja pomiarów,
   tekstowa historia testów, przewijanie Mentora i odnajdywalność planowania.
3. PWA i utrzymanie: retencja cache z ochroną aktywnych klientów, pomiary
   startupu, testy finalnego artefaktu, odtwarzanie poza hostem i aktualizacje.

W chwili zakończenia pierwszego pakietu powyższe prace były planem.
Pakiet synchronizacji i prywatności został następnie wykonany na tej samej
gałęzi; aktualny zakres i wyniki opisuje
[raport drugiego pakietu](2026-10-18-data-integrity-audit-followup.md).
Pakiet dostępności/UI również został następnie wykonany; jego zakres opisuje
[raport UI/UX](2026-10-18-ui-accessibility-audit-followup.md).
Pakiet PWA pozostaje do wykonania.
