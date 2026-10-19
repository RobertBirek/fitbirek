# Audyt FitBirek — trzeci pakiet: UI/UX i dostępność

Zmiany lokalne na `fix/training-continuity-ux`, zintegrowane z wcześniejszymi
pakietami treningu oraz integralności danych. To raport implementacji i testów,
nie wdrożenia produkcyjnego ani pełnej certyfikacji WCAG.

## Czytelność i układ

- Zachowano pomarańczowo-grafitową identyfikację i lokalny Inter. Tekst na
  pomarańczowym tle używa grafitowego `onAccent`: kontrast około 5,95:1,
  zamiast wcześniejszego białego tekstu o kontraście około 2,84:1.
- Główne przyciski mają elastyczne, wyśrodkowane etykiety, minimum 56 px
  wysokości i możliwość wzrostu przy powiększonym tekście. Stan ładowania
  zachowuje nazwę semantyczną i kontrastowy wskaźnik, bez aktywnej akcji.
- Nagłówek RPE zawija tekst. Timer przerwy ma przewijaną część środkową,
  ograniczoną szerokość przycisków i jawne kontrastowe pary kolorów dla presetów
  oraz przycisku „Własny”, również przy jasnym motywie aplikacji.
- Testy obejmują 320×640 i tekst 200%, rzeczywisty zapis serii, wybór RPE,
  preset oraz ±15 s, odliczanie i pominięcie przerwy. Nietrafione kliknięcia
  są błędami testu; SnackBar walidacji wygasa naturalnie przed kolejną akcją.

## Postępy i ręczne pomiary

- Pierwszy wynik testu sprawności jest od razu widoczny z wartością, jednostką
  i datą. Tekstowa historia uzupełnia wykres i ma strony po pięć wyników,
  aby nie wypychać pomiarów i rekordów za nieograniczoną listę.
- Selektory testów zawijają się; osie wykresu używają `onSurfaceVariant`.
  Testy kontrastu uwzględniają oba motywy i powierzchnie karty/scaffold.
- Ręczne pomiary mają edycję i usuwanie z potwierdzeniem. Zapis zachowuje UUID,
  datę i niewidoczne pola; puste opcjonalne obwody stają się jawnym `null`.
  Importy Health zachowują odrębną ścieżkę i nie dostają ręcznej edycji.
- Wiersz i outbox są zapisywane transakcyjnie. Edycję chronią snapshot wiersza,
  konto, dostęp offline, generacja powiązania i epoka autoryzacji.
- Odroczony snapshot zdalny, także równy lokalnemu `syncVersion`, oraz właściwy
  hold/kwarantanna blokują zmianę pomiaru przed odczytem i ponownie przy zapisie.
  Użytkownik nie może nadpisać niewidzianych danych ani wskrzesić zdalnego
  tombstone'a. Zwykłe oczekujące zmiany lokalne nie są blokowane automatycznie.

## Nawigacja i Mentor

- Zakładka Trening udostępnia drugorzędną akcję „Ułóż plan”, prowadzącą do
  rzeczywistej trasy planera i zachowującą aktywną sesję bez nowych zapisów.
- Własne wysłanie i wybór historii prowadzą do końca rozmowy. Nowa odpowiedź
  przewija automatycznie tylko przy końcu; podczas czytania starszych wpisów
  pojawia się „Nowa odpowiedź”.
- Warunkowe przewijanie ponownie sprawdza intencję użytkownika w odłożonym
  callbacku. Drag, kółko i zmiana offsetu nie powodują przeskoku na dół;
  zmiana konta, rozmowy lub opuszczenie ekranu nie odtwarza starego znacznika.
- Respektowane są ograniczenie animacji oraz krótkie komunikaty semantyczne.
  Zachowano ochronę tekstu przy odrzuconym podglądzie kontekstu i rejestr
  operacji Mentora o nierozstrzygniętym koszcie.

## Końcowa weryfikacja

Po wszystkich poprawkach na połączonym drzewie:

| Kontrola | Wynik |
| --- | --- |
| `dart tools/generate_app_version.dart --check` | PASS |
| Pełne `flutter analyze --no-pub` | Bez uwag |
| Pełne `flutter test --no-pub --reporter expanded` | **983 PASS** |
| Format 73 nowych/zmienionych plików Dart całej gałęzi | PASS |
| Przeglądy zgodności i jakości podpakietów | APPROVED |

Testy uruchomiono z bieżącymi źródłami w obrazie narzędziowym
`fit-web:release-1.13.0-26-verified`, Flutter 3.35.4 / Dart 3.9.2,
`--network none`, bez pobierania zależności. Pierwszy pełny przebieg wykrył
kliknięcie zasłonięte SnackBarem; poprawiono fixture, a dodatkowy test małego
ekranu wykrył i doprowadził do naprawy układu RPE oraz timera.

Backend nie zmienił się w tym pakiecie; jego pełny wynik **436 PASS** pochodzi
z poprzedniego pakietu. Nie zmieniono schematów, zależności ani artefaktów
Web SQLite. Nie wykonano commita, podniesienia wersji i wdrożenia.

Pozostaje akceptacja wizualna w rzeczywistym PWA i na urządzeniach oraz
odsłuch z VoiceOver/TalkBack. Testy widgetów sprawdzają semantykę i klawiaturę,
ale nie zastępują tych czynności. Pełny wykres nadal przetwarza całą historię;
ograniczenie liczby elementów dotyczy nowej listy tekstowej.

Kolejny zaplanowany pakiet dotyczy retencji cache, pomiarów wydajności PWA,
testowania finalnego artefaktu i procedur odzyskiwania.

## Późniejsza akceptacja rzeczywistego kandydata

Wykonano następnie buildy i akceptację Chromium z rzeczywistym API/PostgreSQL.
Wykryto i naprawiono propagację wylogowania do drugiej karty, jasną dolną
nawigację oraz utratę precyzji daty pomiaru przy edycji. Kandydat C:
**30 PASS / 0 FAIL / 5 NOTTESTED**, kanoniczny build **1053 testy Flutter PASS**,
końcowy backend **448 PASS**. Zakres, screenshoty, dokładne obrazy, wymaganie
API przed webem i pozostałe ograniczenia:
[raport kandydata C](acceptance/2026-10-19-candidate-c.md).
