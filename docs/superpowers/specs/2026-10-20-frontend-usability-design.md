# Frontend — naprawy audytu i czytelność codziennych zadań

## Zgoda i punkt wyjścia

Po audycie użytkownik polecił „ok, działaj”. Przyjęty zakres: najpierw błędy
formularzy i świadome wysyłanie, następnie Dziś/Mentor, szablony i wskazane
problemy ergonomii. Nie jest to nowa marka ani redesign wszystkich ekranów
w identyczne karty. Źródła audytu: /tmp/opencode/frontend-audit-20261020-summary.md,
static.md i browser-report.md;95zrzutów,30ekranów,3widgetowe reprodukcje błędów.
Zachować cały niezatwierdzony panel Ustawień i jego poprawki bezpieczeństwa.

## Cel i ograniczenia

- Brak niespodziewanego wysłania/płatnej operacji i cichej zmiany danych.
- Najważniejsza informacja/akcja widoczna, jedna naturalna oś przewijania.
- Lokalny Inter, istniejący grafit/pomarańcz/jasny motyw. Dark#1A1D23/#23262E,
  border#3B414C, tekst#F5F6F8/#B8C0CC, akcent#FF6B35. Bez nowych fontów,
  dependencies, animowanych hero, globalnej zmiany tematu lub schematu danych.
- Miara zależna od zadania: formularze max640px, listy/pulpity960px,
  dwupanelowy edytor szablonów na szerokości>=1000px jeśli tekst<=125%;
  wąsko/200% pojedyncza kolumna. Padding16mobile/24desktop, odstępy16/24,
  minimalne cele48px, focus klawiatury, nie ucinać opisów i ostrzeżeń.
- Bez zmian backendu, Drift13/Alembic0010, Flutter3.35.4/Dart3.9.2 i locków.
- Bez commit/push/deploy lub wersjonowania wydania bez osobnego polecenia.

## 1. Formularze i poprawność

Wiek jest dodatnią liczbą całkowitą;47.5/47,5,Infinity/NaN/eksponenty są
odrzucane komunikatem pola bez wyjątku. Wzrost/waga dodatnie finite przez wspólny
parseDecimal, kropka i przecinek akceptowane. Bez arbitralnych nowych progów
medycznych. UI istniejącego profilu zachowuje dokładny ułamek, również gdy
użytkownik zmienia wyłącznie cel. Błędnego pola nie zastępujemy starą wartością.
Zapis ma busy/failure/cancel i guard konta/epoch/binding przed i po await oraz
w transakcji; A-B-A nie może zapisać danych pod nowym kontem. Uzupełnienie
onboardingu nadal działa przed istnieniem profilu. Pola i repo współdzielą
walidację; brak zmiany znaczenia outbox/hold/attempted.

Po zmianie rodzaju testu fitness wspólny szkic wyniku jest czyszczony z krótkim
wyjaśnieniem; nie przenosić60s do60powtórzeń. Powtórne kliknięcie tego samego
typu nie kasuje szkicu. Błąd zapisu zachowuje aktualny szkic.
Kalkulator: etykieta i wynik mogą przejść do dwóch wierszy;320px/200% bez
overflow, liczby i jednostki nadal czytelne, wzory/kalorie bez zmian.

## 2. Mentor i Dziś

Nagranie po transkrypcji trafia do szkicu; NIE wywołuje automatycznie chat/_send.
Użytkownik widzi „Sprawdź transkrypcję i wybierz Wyślij”, może poprawić/anulować.
Ręczne Wyślij zachowuje dotychczasowe zgody/ledger/limit/kontekst; STT nadal jest
świadomie rozpoczętą operacją po kliknięciu mikrofonu. Brak dodatkowej płatnej
próby po utracie wyniku. Wylogowanie/zmiana konta usuwa prywatny szkic.

Na Dziś/Mentor najpierw rzeczywisty stan dostępności. Gdy AI niedostępne:
krótki widoczny powód i Ustawienia Mentora oraz jeden Klasyczny trening/offline;
nie pokazywać martwego czatu/sugestii ani bezczynnego Stop. Harmonogram nadal
łatwo dostępny. Gdy AI działa: rozmowa dostaje przestrzeń, plan dnia i sugestie
mogą być zwijane i nie tworzą stałego małego scrollportu z pustym obszarem.
Composer przy keyboard/320px ma użyteczne pole, kontekst i mikrofon nie mogą
wyprzeć tekstu. Stop tylko podczas nagrania/odtwarzania/operacji, którą faktycznie
przerywa. Zachować scroll-to-latest, drag reading i new-reply przycisk.

## 3. Edytory i odczyt treningu

Szablon: nazwa/lista ćwiczeń stanowią główny przepływ. Parametry na ćwiczenie
zwijane, summary np.3×10,30s przerwy; po Dodaj nowy element otwarty. Błędy
otwierają właściwą sekcję. Po dodaniu drugiego ćwiczenia zapis nadal dostępny
w stałej stopce nad globalną nawigacją (także z keyboard/text200%).
Desktop: wybrana lista po lewej, wyszukiwarka/dodawanie po prawej, oba w960px
lub jawnie ograniczonej mierze; mały ekran jeden przewijalny formularz.
Zachować ograniczenia modelu, kolejność, kg/time/reps i snapshot/leasekonto;
nie nadpisywać szkicu po rebuild. Potwierdzenie Save i cele≠wykonanie bez zmian.

Pozostałe listy/formularze otrzymują miarę odpowiednią do zadania, nie wymuszone
dwie kolumny: profil, kalkulator, pomiary, aktywności, plan, szablony, Mentor
settings, ćwiczenia/postępy. Ilustracja ćwiczenia ograniczona np.max360px;
instrukcje i Start nie odsuwane ogromnym kwadratem. Gwiazdka ma nazwę/stany
Dodaj/Usuń z ulubionych, przycisk wariantu min48px ze stanemsemantycznym.

Ryzyka katalogu i podsumowania najpierw reprodukujemy widgetem320/200% z
krótkim viewportem/keyboard/mnogimi seriami. Jeśli potwierdzone: katalog ma
przewijalny nagłówek z wynikami, a summary jedną oś przewijania i wtórne akcje
grupowane. Nie usuwać ostrzeżeń kryteriów ani częściowego wykonania.

## 4. Postępy i błędy

Trendy: najpierw „Za mało danych”/wynik i konkretny powód. Filtry mają nazwy
użytkowe, bez cw001/NULL/kontraktu w głównym UI. Brak strony zapisu to „Strona
nieokreślona”, nie zgadywać obie ani scalać różnych konfiguracji. Metodologia
i wyłączenia rozwijane niżej, zawsze dostępne. Bez zmian algorytmów progresji.
Wykresy wagi/testów opisane jako czas mają X z daty/instant (sortowanie i
bezpieczny zakres); odstęp1dnia i18dni nie wygląda jednakowo. Ten sam dzień
ma jawne rozróżnienie lub równe X; brak fałszywej skali, dostępna lista odczytu.

Szablony, szczegół ćwiczenia i konfiguracja Mentora mają przy błędzie opis
i Retry/Back z dostępnym AppBar; nie wyświetlać surowego wyjątku jako jedynej
instrukcji. Nie zamieniać loading/niezgodnej struktury w pustą listę/generator.

## Akceptacja

Każdy potwierdzony błąd ma najpierw RED, potem GREEN z rzeczywistą stroną/repo.
320/375/768/1280,lightdark,text200%, keyboardfocus/scroll/cancel/accountswitch.
Pełne Flutter analyze/test/versioncheck. Niezależny review i finalny immutable
build z izolowanym Chromium: profil z ułamkiem i przecinkiem, zły wiek,
Mentor bez konfiguracji i stub STT w testach (bez płatnego providera), edytor
szablonu z kilkoma ćwiczeniami, kalkulator, katalog, summary, trendy i errorcase.
Zdjęcia przed/po, bez prawdziwych danych produkcyjnych/AI/push.
