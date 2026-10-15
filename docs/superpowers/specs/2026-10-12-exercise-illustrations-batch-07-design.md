# Ilustracje ćwiczeń — partia 07

## Cel i zakres zatwierdzony

Sześć kolejnych ćwiczeń katalogu: `cw013–cw018`, obejmujących wyciskania
i rozpiętki z hantlami. Każde ćwiczenie otrzyma dokładnie dwa kadry.
Użytkownik zatwierdził wariant `cw015` w staniu, z wyciskaniem dociśniętych
do siebie hantli w przód i lekko w górę.

Źródłem nazw i wskazówek technicznych jest `assets/data/exercises.json`.
Nie zmieniać rekordów katalogu ani istniejących identyfikatorów.

Punkt wyjścia: 78 wydanych ilustracji i 238 ćwiczeń bez ilustracji spośród
316 rekordów. Po lokalnej integracji Partii 07: 84 ilustracje, w tym
78 wydanych i 6 niewydanych, oraz 232 ćwiczenia bez ilustracji.
Aktualna produkcja to `1.9.0+22`.

Zakres obejmuje przygotowanie, generację, przeglądy i lokalną integrację.
Wersja następnego wydania, wdrożenie, commit i push wymagają osobnej prośby
użytkownika; poprzednia prośba o wydanie Partii 04–06 została już wykonana.

## Kontrakt wizualny

- Jeden lokalny `assets/exercises/cwNNN.webp` na ćwiczenie, `512×512`.
- Dokładnie dwa oddzielone kadry obok siebie, czytane od lewej do prawej.
- Wzorzec stylu: `assets/exercises/cw256.webp`; kremowe tło, ciemny neutralny
  strój, twarz bez rysów i wyraźny komiksowy kontur.
- Ta sama postać, kamera, sprzęt i podparcia w obu kadrach ćwiczenia.
- Całe ciało i sprzęt mieszczą się w kadrze; obie dłonie, oba hantle,
  nadgarstki, łokcie, stopy i istotne kontakty z podłożem są czytelne.
- W każdym kadrze dokładnie dwa osobne hantle i jeden chwyt na każdy hantel.
  Kontakt ciężarów w `cw015` nie może sugerować jednego wspólnego przyrządu.
- Bez tekstu, numerów, etykiet, strzałek i znaków wodnych.
- Pierwsze prompty nie wymagają kolorowych oznaczeń mięśni. Jeśli pojawią
  się takie oznaczenia, pomarańcz opisuje cel, turkus widoczne wsparcie;
  nie oznaczać stawów, ścięgien ani zasłoniętych mięśni.
- Kontrolować zarówno źródło `1024×1024`, jak i podgląd `512×512`.
  Poprawność chwytów, kąt ławki i różnica między fazami muszą być czytelne
  bez powiększania podglądu.

## Sceny i kryteria odrzucenia

### cw013 — Wyciskanie hantli na ławce skośnej głową w górę

Stała, lekko podwyższona kamera boczna 3/4, pokazująca oba hantle i kąt ławki:
1. Oparcie ławki uniesione około 30–45°, obie stopy na podłodze; głowa,
   górna część pleców i pośladki podparte. Hantle po bokach górnej klatki,
   łokcie około 45° od tułowia, nadgarstki nad łokciami.
2. Hantle wyciśnięte ponad górną klatkę; ramiona wyprostowane bez
   przesadnego przeprostu, hantle rozdzielone, podparcia niezmienione.

Odrzucić ławkę płaską lub ustawioną ponad 60°, odrywanie pleców,
załamane nadgarstki, hantle przy twarzy i ruch przypominający wyciskanie
nad głowę w siadzie. Kąt ma być czytelny wizualnie, nie wymaga podpisu.

### cw014 — Wyciskanie hantli w leżeniu na podłodze

Stała, lekko podwyższona kamera boczna 3/4, ujawniająca oba ramiona:
1. Leżenie tyłem na podłodze, kolana ugięte, obie stopy płasko podparte.
   Głowa, plecy i pośladki na podłożu. Łokcie i tylne części ramion
   delikatnie dotykają podłogi; łokcie ugięte około 90°, odsunięte od
   tułowia około 45°, nadgarstki nad łokciami, hantle po bokach klatki.
2. Hantle wyciśnięte nad klatkę, ramiona wyprostowane, ciężary rozdzielone;
   te same kontakty ciała i stóp z podłogą.

Odrzucić ławkę, dolną fazę zawieszoną bez kontaktu ramion z podłożem,
przenikanie łokci w podłogę, unoszenie bioder i hantle nad twarzą.
Ilustracja pokazuje kontrolowany kontakt, nie odbicie łokci od podłoża.

### cw015 — Wyciskanie ściskające hantlami — wariant w staniu

Stała kamera przednio-boczna 3/4, wyraźnie pokazująca dwa chwyty:
1. Stabilny wyprostowany stój, stopy około szerokości bioder, kolana
   nieznacznie rozluźnione. Dwa hantle ustawione obok siebie i dociśnięte
   do siebie przed klatką; po jednej dłoni na każdym uchwycie, łokcie ugięte.
2. Hantle wyciśnięte w przód i lekko w górę, około wysokości górnej klatki,
   łokcie niemal wyprostowane, ciężary nadal dociśnięte do siebie.

Tułów pozostaje nieruchomy i wyprostowany; nie ilustrować ruchu nad głowę.
Kamera musi ujawniać dwa osobne uchwyty i osobne głowice hantli pomimo
kontaktu ciężarów. Odrzucić rozdzielenie hantli w drugiej fazie, połączenie
ich w jedną sztangę, wspólny chwyt na jednym hantlu, przechylenie tułowia
w tył i wariant w leżeniu zamiast zatwierdzonego stania.

### cw016 — Rozpiętki z hantlami na ławce płaskiej

Stała podwyższona kamera przednio-boczna 3/4, pokazująca rozstaw ramion:
1. Leżenie na płaskiej ławce, obie stopy na podłodze, głowa, górna część
   pleców i pośladki podparte. Ramiona otwarte na boki do poziomu klatki,
   łokcie lekko ugięte, chwyty neutralne, dłonie zwrócone ku sobie.
2. Hantle zbliżone nad klatką ruchem łukowym, lecz niezderzające się;
   zachowane lekkie ugięcie łokci i te same podparcia ciała.

Odrzucić zmianę ugięcia łokci jak w wyciskaniu, całkowicie proste łokcie
w dolnej fazie, zejście ramion wyraźnie poniżej klatki, zapadnięte barki
i ławkę skośną. Różnica względem `cw012` musi być widoczna bez podpisu.

### cw017 — Rozpiętki z hantlami na ławce skośnej głową w górę

Stała podwyższona kamera przednio-boczna 3/4, pokazująca oba ramiona i ławkę:
1. Oparcie ławki około 30°, głowa, górna część pleców i pośladki podparte,
   stopy na podłodze. Ramiona otwarte na boki do poziomu klatki, łokcie
   lekko ugięte, neutralne chwyty.
2. Hantle zbliżone nad górną klatką, z niezmienionym lekkim ugięciem łokci
   i bez zderzenia ciężarów; ciało nadal oparte na ławce.

Odrzucić ławkę płaską lub zbyt strome oparcie, prostowanie łokci,
przesadnie głęboką dolną fazę i tor przypominający wyciskanie.
Różnica względem `cw013` i `cw016` musi być czytelna w `512×512`.

### cw018 — Rozpiętki z hantlami w leżeniu na podłodze

Stała podwyższona kamera przednio-boczna 3/4, ujawniająca obie ręce:
1. Leżenie tyłem na podłodze, kolana ugięte, stopy płasko podparte,
   głowa, plecy i pośladki na podłożu. Ramiona szeroko otwarte na boki,
   łokcie lekko ugięte i delikatnie dotykające podłogi jako ogranicznika.
2. Hantle zbliżone nad klatką ruchem łukowym, lekkie ugięcie łokci nadal
   takie samo; ciężary nie zderzają się, podparcia ciała niezmienione.

Odrzucić ławkę, brak dolnego kontaktu łokci z podłogą, uderzanie lub
przenikanie w podłoże, zmianę kąta łokci jak w wyciskaniu i uniesione
biodra. W dolnej fazie szerszy rozstaw ramion oraz niewielkie ugięcie
łokci muszą odróżniać obraz od `cw014`.

## Przebieg generacji i przeglądów

1. Przygotować sześć osobnych promptów zawierających wspólny styl,
   układ dwóch kadrów, kamerę, fazy oraz kryteria odrzucenia.
2. Generować w kolejności `cw013–cw018` przez
   `tools/benchmark_exercise_images.py`, pojedynczym żądaniem
   `--single-sunburst-medium` na próbę. Pierwsza próba każdego ćwiczenia
   używa `/tmp/opencode/cw256-reference.png`, odpowiadającego wzorcowi WebP.
3. Każda próba trafia do świeżego katalogu `/tmp/opencode/cwNNN-trial-NN`.
   Prompty, PNG, podglądy i ledgery pozostają poza repozytorium.
4. Odczytać źródło i podgląd `512×512` przed następnym płatnym żądaniem.
   Po uzyskaniu wyników porównać pary `cw013/cw017`, `cw014/cw018` oraz
   `cw016/cw017`, kontrolując tor ruchu, pracę łokci i kąt ławki.
5. Korekta usuwa tylko nazwany defekt, z odrzuconym PNG jako jedyną
   referencją i świeżym katalogiem; zachowuje zaakceptowane części sceny.
6. Jeśli kolejne korekty nie usuwają tego samego problemu, zatrzymać
   płatne próby i ponownie uzgodnić sposób przedstawienia ruchu.
7. Przegląd zgodności ze sceną poprzedza przegląd jakości anatomii
   i czytelności. Oceniać kontakty w przestrzeni z uwzględnieniem
   perspektywy, nie według jednej poziomej linii projekcji obrazu.
   Nie akceptować rzeczywistego przenikania sprzętu lub brakujących chwytów.

## Integracja i weryfikacja

- W `test/features/exercises/exercise_illustrations_test.dart` dodać
  `cw013–cw018` do `expectedIllustrationIds` po `cw012`, przed `cw251`.
- Istniejący test braku ilustracji przenieść z `cw013` na nadal
  niezilustrowane `cw019`. Potwierdzić celowo czerwony kontrakt rejestru
  z brakiem `cw013`, przy poprawnym fallbacku `cw019`.
- Produkcyjny rejestr i assety rozszerzyć dopiero po akceptacji wszystkich
  sześciu scen; nie integrować obrazów po pojedynczych generacjach.
- Finalne PNG konwertować przez `convert` z opcjami
  `-resize 512x512 -strip -quality 90` do sześciu WebP `cw013–cw018`.
- W `lib/features/exercises/presentation/exercise_illustrations.dart`
  zarejestrować nowe ID po `cw012`, zachowując wcześniejsze 78 wpisów
  i niezmienioną funkcję mapowania. Deklaracja katalogu assetów już istnieje.
- Uruchomić Dockerowy target `verification` z
  `deploy/docker/web.Dockerfile`: kontrola wygenerowanej wersji, analiza
  Fluttera i pełne testy. Rejestr, oczekiwania testu i katalog WebP mają
  obejmować te same 84 ID, każdy asset dekodować się jako `512×512`.
- Liczbę dwóch wizualnych kadrów, fazy i różnice między ćwiczeniami
  potwierdzają przeglądy obrazów; test dekodowania nie ocenia techniki ruchu.
- W `docs/exercise-illustrations-status.md` dodać sześć wierszy po dwa
  kadry, sekcję „Siódma partia” i stan 84 lokalnych ilustracji,
  78 wydanych, 6 niewydanych, 232 brakujących z katalogu 316.
  Nowe pozycje oznaczać jako lokalnie zintegrowane, niewydane.

## Warunki ukończenia pakietu

- Sześć finalnych WebP ma po dwa czytelne kadry i przeszło oba przeglądy.
- Wyciskania i rozpiętki są wizualnie rozróżnialne; `cw015` pokazuje
  zatwierdzony wariant w staniu z kontaktem dwóch odrębnych hantli.
- Rejestr, oczekiwania testu i assety obejmują te same 84 ID; fallback `cw019`
  działa, analiza i testy Dockerowe są zielone.
- Dokumentacja rozróżnia sześć niewydanych ilustracji Partii 07 od
  78 ilustracji produkcyjnych `1.9.0+22`.
- Praca pozostaje na aktualnym `main`, zgodnie z dotychczasowym wyborem;
  żadna publikacja ani operacja Git nie wynika automatycznie z przygotowania.
