# Prywatne konta dla znajomych — plan na przyszłość

## Decyzja użytkownika — 2026-10-17

**Odłożone. Na razie jedynym użytkownikiem pozostaje właściciel aplikacji.**
Użytkownik zaakceptował poniższy kierunek jako plan na przyszłość, ale nie zleca
teraz jego implementacji, tworzenia kolejnych kont ani wdrażania zaproszeń.
Powrót do tego zakresu wymaga osobnej decyzji. Nie zmieniamy obecnego logowania,
izolacji danych ani zabezpieczeń tylko dlatego, że aplikacja pozostaje osobista.

## Uzgodniony model przyszły

- Zamknięty dostęp dla znajomych; bez publicznej rejestracji.
- Administrator tworzy jednorazowe zaproszenie przypisane do adresu e-mail,
  z terminem ważności. Link przekazuje ręcznie; pierwsza wersja nie wymaga
  automatycznej wysyłki e-maili.
- Zaproszona osoba samodzielnie ustala hasło. Administrator nie tworzy go
  za użytkownika i nie poznaje jego wartości.
- Każda osoba ma niezależne, prywatne treningi, historię, dane zdrowotne,
  zapisane plany, warianty, filtry, eksporty i ustawienia.
- Wspólny jest katalog ćwiczeń i ilustracji. Nie ma modelu trener–podopieczni,
  podglądu cudzych postępów, feedu ani domyślnego udostępniania danych.
- Panel administracyjny zarządza zaproszeniami i blokowaniem dostępu, nie
  udostępnia przeglądania prywatnych danych treningowych.
- Operator serwera nadal ma techniczny dostęp do bazy i backupów. Nie jest
  to szyfrowanie end-to-end ani obietnica braku dostępu operatora do danych.
- Jedno konto przypisane do jednego profilu przeglądarki/PWA na urządzeniu;
  bez szybkiego przełączania kont ze szkicami offline. Jedno konto może działać
  na kilku urządzeniach. Szczegóły bezpiecznej zmiany przypisania wymagają
  projektu przed implementacją.
- Wspólna aplikacja PWA dla iPhone'a i Androida, z osobną akceptacją obu
  platform. Obecnie właściciel korzysta z iPhone'a. Aplikacje sklepowe nie są
  częścią tej decyzji.

## Bramki przed ewentualnym uruchomieniem

- Zweryfikować istniejące mechanizmy kont; nie traktować przypisania rekordów
  do użytkownika jako dowodu pełnej gotowości produktu multi-user.
- Przetestować dwa rzeczywiste konta: odmowę dostępu do cudzych danych przez
  API, izolację lokalnej bazy/cache i zachowanie przy wylogowaniu oraz offline.
- Sprawdzić przypisanie synchronizacji, eksportów, powiadomień i ustawień
  integracji do właściwej osoby oraz brak ujawnienia danych poprzedniego konta.
- Zaprojektować bezpieczny cykl zaproszenia, odzyskiwanie dostępu i skutki
  blokady dla sesji oraz danych lokalnych. Blokada na serwerze nie daje gwarancji
  natychmiastowego odebrania dostępu urządzeniu pozostającemu offline.
- Domknąć i sprawdzić zachowanie offline PWA na obu platformach; nie obiecywać
  działania synchronizacji ani timera w uśpionej aplikacji.

Ten dokument jest zapisem kierunku i odroczenia, nie harmonogramem realizacji
ani pełną specyfikacją bezpieczeństwa przyszłej funkcji.
