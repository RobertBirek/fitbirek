# Ustawienia — wynik integracji

## Implementacja

Lokalny branch `feat/settings-ui`, baseline `a0ca0f8`, bez commit/push/deploy.
Główny ekran ograniczony do960px, na szerokim ekranie dwie kolumny, na wąskim
i przy dużym tekście jedna. Harmonogram ma jedyny pomarańczowy znacznik.
Zachowano lokalny Inter i jasny/ciemny motyw oraz istniejące ustawienia.

Powiadomienia, backup i Apple Zdrowie przeniesione do osobnych chronionych
podstron settings. Główny ekran nie zawiera rozbudowanych technicznych paneli
ani tokenów. Wylogowanie jest na końcu. Pełne ostrzeżenie importu i informacje
o konflikcie synchronizacji pozostają dostępne; gesture push zachowany.

Review ujawnił ryzyko udostępnienia opóźnionego eksportu po back/logout:
przed Share sprawdzane są źródłowe konto/epoch, operacja, trasa i trwały binding.
Import ma tę samą ochronę i dodatkową transakcję wycofującą anulowany restore.
Nie zmieniano serwisu backupu ani formatu danych.

Pierwsza rzeczywista akceptacja znalazła zgubiony deep link przy reload:
tymczasowy Navigator `MaterialApp.home` bramki DB konsumował początkowy URI.
Minimalna zmiana `home` na `builder` usuwa ten Navigator bez zmiany auth,
bramki bazy, Retry i logiki tras. Regresje obejmują prawdziwy platformowy URI,
asynchroniczny startup, defaultToday oraz login/onboarding/back.

## Weryfikacja

- Spec i quality review po obu poprawkach: **PASS / APPROVED**.
- Kanoniczny build web końcowego targetu runtime przez verification:
  **1254 Flutter PASS**,0skip, analyze bez uwag, versioncheck poprawny.
- Końcowy Chromium: **70 PASS / 0 FAIL**,76screenshotów;1280/768/375/320px,
  dark/light, powiadomienia/backup/health i ich back/deepreload, authredirect,
  anulowanie importu, widoczny fokus Tab. Żadnych mutacji domeny poza
  standardowym onboardingiem wyłącznie izolowanego konta testowego.
- Kontroler obejrzał finalne desktop1280dark i mobile375darktop/footer:
  panel ograniczony, spokojne grupy, poprawne zawijanie. Nie dodawano kolejnych
  dekoracji. Zaznaczenie części wierszy na screenach to hover myszy.
- `git diff --check` poprawny. Backend, deploy, dependencies, wersja i WebSQLite
  bez zmian, co potwierdzono osobnym `git diff --exit-code` dla tych ścieżek.

Immutable candidate (nie produkcyjny release):
`fit-web:settings-ui-20261020T072616Z`,
`sha256:f2d024e5e21da732d0f881a4d940a383d179056b002f357465c3c4239dd726d6`.

Dowody: `/tmp/opencode/settings-ui-20261020T072616Z/`, w tym final-counts,
checks, manifesty źródeł/pakietu i screenshoty. Pierwszy FAIL zachowany pod
`/tmp/opencode/settings-ui-20261020T064625Z/` i w browser-report.

## Ograniczenia

Nie wdrożono na https://fit.birek.online. Produkcyjne kontenery, obrazy i czasy
startu bez zmian. Nie logowano się na produkcji, nie generowano tokenów,
nie importowano danych ani nie wysyłano push/AI. Zasoby izolowane usunięto
po sprawdzeniu własnych labeli, obrazy i dowody zachowano.

200%tekst ma pokrycie widgetowe, nie browserzoom/urządzenie fizyczne. Chromium
resizedviewports nie zastępuje Safari ani fizycznego telefonu. Backend510PASS
to dziedziczony wynik niezmienionego1.18, nie nowy przebieg.

Przed osobno zleconym wdrożeniem: bump patch/build jako poprawka UI, generated
wersja, nowy kanoniczny build, procedura backup/restore i webrollout z DEPLOY.md.
Nie publikować kandydata z wersją1.18.0 jako nowego wydania bez bumpu.
