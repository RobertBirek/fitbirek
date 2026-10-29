# Mobilny compiled PWA — odbiór 2026-10-29

**Task 1: PASS_WITH_LIMITS.** Końcowa kontrola dowodów: **20 grup asercji PASS,
0 FAIL produktu**. Gate przed Task 2 spełniony w opisanym zakresie emulacji;
nie jest to akceptacja fizycznego telefonu ani rzeczywistej synchronizacji.

## Artefakt i izolacja

- Testowano istniejący compiled release **1.25.1+43**, źródło
  `073e11d06272b067f50380abea9f3417fe6dc659`, bez ponownego buildu.
  Workspace `834cab0` dodaje wyłącznie dokumentację względem tego źródła;
  nie przedstawiamy go jako nowego skompilowanego produktu.
- `main.dart.js` SHA-256:
  `4284d50f7adac013ab5a0619545dc5f7b12d5ce9a11bd3fe9261072230552047`.
  Package ID:
  `17a29ec70950aafa5646d55dd03acd265903f30eca1a55790ff7527476948214`.
- Chromium **148.0.7778.96**, headless, **390×844**, touch1, DPR3,
  locale PL / Europe/Warsaw; dwa odrębne prywatne profile odbiorowe.
  HTTP wyłącznie na loopback testowym. To emulacja viewportu/touch, nie Android/iOS.
- Jedyny udawany sukces HTTP: syntetyczny `GET /api/auth/session`.
  Wszystkie pozostałe API abortowane; obce originy blokowane. Zarejestrowano
  **202 przechwycenia API**, **0 API dochodzących do serwera testowego**,
  **0 żądań obcych originów**, **0 pageerror** we wszystkich przebiegach.
- Dane domenowe tworzono wyłącznie przez UI. SQLite sprawdzano na kopiach
  read-only po zamknięciu aplikacji; bez SQL/IndexedDB seedowania, kasowania
  danych, logoutu, prawdziwych credentials, produkcyjnych zapisów lub push.

## Wyniki

| Zakres | Wynik i konkretna asercja |
| --- | --- |
| Nowy profil | PASS: trzy ekrany onboardingu, siedem krytycznych stron, katalog431; viewport390 i brak poziomego overflow dokumentu/renderowanego widoku. |
| Cele i role | PASS: dwa ręczne szablony oraz program A/B przez UI; rozgrzewka20kg×5, cel roboczy10kg×8, niezależny szkic10kg×9. |
| Pełne zamknięcie / recovery | PASS: wybrany cel i szkic przetrwały normalne zamknięcie całej przeglądarki. Po reopen→resume zapis bez edycji/focus pól i bez ponownego wyboru celu: robocza10kg×9. Scroll touch do przycisku nie jest zmianą formularza. |
| Historia | PASS: jedna zakończona sesja, dokładnie dwie serie i dwa zdarzenia performed o właściwych targetId/rolach; rozgrzewka20×5 i robocza10×9, bez duplikatu. |
| Zgoda i zasoby | PASS: `notReady` przed jawną zgodą związaną z packageId przez publiczny bridge; potem508/508 plików,48 608 913/48 608 913 bajtów. Wszystkie508 lokalnych hashy/długości zgodne, CORE31. |
| Cold offline | PASS: po pełnym zamknięciu i uruchomieniu bez sieci czytelne programy, historia, podsumowanie i ilustracje. Każda z431 ilustracji faktycznie zdekodowana512×512; dwa profile dają862 udane dekodowania. |
| Pending offline | PASS: dziewięć operacji outbox po zakończeniu sesji, identycznych bajtowo przed/po odczytach offline; zachowane sesja, serie, katalog i profil. Brak ACK nie jest błędem tego fixture. |
| Aktualizacja istniejącego profilu | PASS: rzeczywisty1.25.0+42 (501 plików /48 501 382 bajty,424 obrazki, katalog431) →1.25.1+43, Drift15→15. Stary profil miał siedem pending, aktywny szkic i jedną rozgrzewkę. |
| Lifecycle aktualizacji | PASS: pierwsze otwarcie online wykonało stary main i otrzymało `reloadRequired` nowego workera. Po kolejnym pełnym zamknięciu/reopen ten sam profil wykonał potwierdzony hash nowego main, stan `notReady`; bez wymuszonego claim/skipWaiting i bez czyszczenia storage. |
| Zachowanie danych przy aktualizacji | PASS: siedem pending, payload szkicu, sesja, seria, dwa szablony, katalog431 i profil identyczne bajtowo przed/po aktualizacji oraz przygotowaniu nowego pakietu po nowej zgodzie. Potem cold offline→resume→natychmiastowy zapis właściwej roboczej10×9; końcowe dziewięć pending pozostało niezmienione. |

## Przerwania harnessu, nieukryte ograniczenia

Łącznie **34 wywołania przeglądarkowego harnessu:26 udanych i8 przerwanych
podczas dopracowania automatyzacji**; to nie34 niezależne testy produktu.
Ślady błędów zachowano. Siedem dotyczyło semantyki Fluttera/selektorów:
transparentny overflow body zamiast rzeczywistego dokumentu, inna etykieta
potwierdzenia startu, puste unfocused input-surrogates, semantyka poza viewportem,
brak touch-scroll do przycisku, tekst programu w aria-group i tekst historii
zamiast group. Jednorazowe touch0 w harnessie nie odtworzyło się w prostym
fixture; nie ustalono jego przyczyny i nie nazywamy tego naprawą produktu.
Końcowe siedem krytycznych screenshotów viewportowych potwierdza touch1.
Nie potwierdzono realnego błędu mobilnego flow wymagającego poprawki produktu.

**Niewykonane:** fizyczny Android/iPhone, instalacja/standalone PWA, VoiceOver,
WebKit (brak w istniejącym cache; niczego nie pobierano), realny login,
authenticated reconnect/ACK i pełny sync/conflict matrix, pełna macierz
timer/stron/cross-sync, crash/kill/OS suspend/background i eviction storage.
**Abortowane API ≠ udany reconnect. Zachowane pending ≠ serwerowy ACK.**
Normalne zamknięcie z utrwalonym szkicem nie gwarantuje flush przy zabiciu procesu.

## Dowody i zakres zmian

Pełne logi, screenshoty, pośrednie FAIL harnessu, kopie storage oraz enumeracja
20 końcowych asercji: `/tmp/opencode/pwa-reliability-mobile/`;
podsumowania `report.md`, `result.json`, kontrola `verification.log`.
Harness: `mobile_harness.py`; read-only weryfikacja: `verify_results.py`.
Jedyna zmiana repo w Task1 to ten dokument; bez zmian produktu, commitu,
push/merge, buildu lub produkcji. Wynik nie zalicza przyszłego UI z Task2.
