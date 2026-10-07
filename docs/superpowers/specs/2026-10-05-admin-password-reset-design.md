# Administracyjne resetowanie hasła

## Cel

Umożliwić jedynemu właścicielowi instancji odzyskanie dostępu przez SSH bez dodawania publicznego mechanizmu odzyskiwania hasła.

## Zakres

Backend dostanie polecenie administracyjne `reset-password`, uruchamiane w środowisku serwera. Polecenie:

- interaktywnie pobiera adres e-mail istniejącego konta oraz nowe hasło i jego potwierdzenie;
- nie wyświetla wpisywanych haseł;
- odrzuca pustą wartość oraz różniące się hasła;
- odszukuje konto po istniejącej, znormalizowanej obsłudze e-maila;
- zapisuje hash nowego hasła przy użyciu aktualnego Argon2;
- atomowo unieważnia wszystkie sesje konta po udanej zmianie.

Nie będą dodawane endpointy HTTP, e-mail/SMTP, tokeny resetu, ekran aplikacji ani migracje bazy danych.

## Obsługa błędów

Polecenie kończy się czytelnym błędem, bez zmiany danych, gdy konto nie istnieje, hasło jest puste albo potwierdzenie nie jest identyczne. Hasło nie może trafić do wyjścia standardowego, logów ani argumentów procesu.

## Testy

Testy backendu potwierdzą, że udany reset aktualizuje hash hasła i unieważnia sesje, a błędne wejście nie modyfikuje konta. Zostaną uruchomione właściwe testy backendu.

## Poza zakresem

Nie zmieniamy niepowiązanych, lokalnych modyfikacji obecnych w katalogu roboczym.
