# Ilustracje ćwiczeń — partia 06

## Cel i zakres zatwierdzony

Sześć kolejnych ćwiczeń katalogu: `cw007–cw012`. Partia obejmuje pięć
wariantów pompek oraz wyciskanie hantli na ławce płaskiej. Źródłem nazw
i techniki jest `assets/data/exercises.json`.

Punkt wyjścia: 72 lokalne ilustracje, w tym 66 wydanych i 6 niewydanych
z Partii 05, oraz 244 ćwiczenia bez ilustracji. Po integracji Partii 06:
78 lokalnych ilustracji, w tym 66 wydanych i 12 niewydanych, oraz 238 ćwiczeń
bez ilustracji; katalog nadal liczy 316 ćwiczeń.

Zakres obejmuje przygotowanie, generację, przeglądy i lokalną integrację.
Wersja kolejnego wydania oraz wdrożenie wymagają osobnego uzgodnienia.
Aktualna produkcja pozostaje `1.8.0+21`. Należy zachować istniejące zmiany
Partii 04 i 05 oraz nie zmieniać rekordów katalogu ani identyfikatorów.

## Kontrakt wizualny

- Jeden `assets/exercises/cwNNN.webp` na ćwiczenie, finalnie `512×512`.
- `cw007` i `cw011`: dokładnie trzy oddzielone kadry w poziomych pasach,
  czytane od góry do dołu. Taki układ pozostawia szerokość na całe ciało.
- `cw008`, `cw009`, `cw010`, `cw012`: dokładnie dwa kadry obok siebie,
  czytane od lewej do prawej.
- Wzorzec stylu: `assets/exercises/cw256.webp`; kremowe tło, ciemny neutralny
  strój, twarz bez rysów i wyraźny komiksowy kontur.
- Stała postać, kamera, sprzęt i strona robocza w obrębie jednego assetu.
  Obrót ciała w `cw011` jest elementem ćwiczenia, nie zmianą kamery.
- Całe ciało oraz sprzęt mieszczą się w każdym kadrze; dłonie, stopy,
  kontakty z podłożem i podparcie na ławce muszą być czytelne.
- Bez tekstu, numerów, podpisów, strzałek i znaków wodnych. Ruch komunikują
  pozycje ciała, nie oznaczenia kierunkowe.
- Pierwsze prompty nie wymagają kolorowych oznaczeń mięśni. Jeśli pojawią
  się takie oznaczenia, pomarańcz opisuje cel, a turkus widoczne wsparcie;
  nie oznaczać stawów, ścięgien ani zasłoniętych mięśni.
- Każdy wynik oceniać w źródłowym `1024×1024` i w podglądzie `512×512`.
  Wszystkie fazy, chwyty i podpory muszą być rozpoznawalne w podglądzie.

## Sceny i kryteria odrzucenia

### cw007 — Pompki hinduskie — 3 kadry

Kamera boczna 3/4, ta sama we wszystkich fazach:
1. Dłonie i stopy na podłożu, biodra wysoko, sylwetka odwróconej litery V.
2. Łokcie ugięte, głowa i klatka przechodzą nisko do przodu pomiędzy dłońmi;
   widoczny etap nurkowania, odmienny od obu pozycji końcowych.
3. Ramiona wyprostowane, klatka otwarta i uniesiona, biodra obniżone, dłonie
   nadal podparte; pozycja końcowa typu upward dog z podpartymi stopami.

Odrzucić brak fazy przejściowej, wymuszone odchylenie głowy, zapadnięcie
odcinka lędźwiowego oraz niemożliwe kontakty dłoni lub stóp z podłożem.
Nie ilustrować powrotu divebomber: katalog wymienia go jako progresję.

### cw008 — Pompki z przyciąganiem kolana do łokcia — 2 kadry

Lekko podwyższona kamera boczna 3/4 od strony pracującej nogi:
1. Wysoki podpór, obie dłonie i palce obu stóp na podłożu.
2. Niska faza pompki, bliższe kolano przyciągnięte na zewnątrz do łokcia
   tej samej strony; pracująca stopa oderwana od podłoża, przeciwna podparta.

Tułów stabilny, biodra równoległe do podłogi. Asset pokazuje jedno
powtórzenie po jednej stronie; nie zamieniać stron między kadrami.
Odrzucić kolano do przeciwnego łokcia, skręt lub unoszenie bioder i ruch
przypominający mountain climber bez opuszczenia klatki.

### cw009 — Pompki z podniesionymi nogami — 2 kadry

Kamera boczna 3/4 pokazująca dłonie i całą niską, stabilną ławkę:
1. Wysoki podpór, obie stopy na ławce o wysokości odpowiadającej 30–50 cm,
   dłonie na podłożu.
2. Ugięte łokcie, klatka opuszczona między dłońmi, stopy nadal na ławce.

Ciało zachowuje linię od głowy do pięt, bez zgięcia w biodrach.
Odrzucić wysokie ustawienie nóg przypominające pike push-up, opadnięte
biodra, opuszczenie samej głowy i ławkę bez wiarygodnego podparcia stóp.

### cw010 — Głębokie pompki na hantlach — 2 kadry

Kamera boczna 3/4 pokazująca oba chwyty oraz wysokość dłoni nad podłożem:
1. Wysoki podpór, dłonie chwytają uchwyty dwóch hantli heksagonalnych,
   których płaskie głowice stabilnie leżą na podłodze; stopy podparte.
2. Klatka obniżona poniżej poziomu dłoni, lecz bez przenikania w podłoże,
   łokcie około 45° od tułowia; identyczne ustawienie hantli.

Odrzucić okrągłe lub toczące się hantle, dłonie oparte na głowicach zamiast
uchwytów, brak zwiększonego zakresu oraz przesadną głębokość z zapadnięciem
barków. Wysokość hantli nie może być sztucznie zwiększana dla efektu.

### cw011 — Pompki z rotacją — 3 kadry

Stała kamera przednio-boczna 3/4 od strony otwierającej się klatki:
1. Dolna faza pompki, obie dłonie i stopy podparte.
2. Wysoki podpór po wyciśnięciu, obie ręce wyprostowane.
3. Obrót tułowia do podporu bokiem: jedna dłoń pod barkiem, drugie ramię
   wyprostowane pionowo w górę; klatka i miednica obracają się razem,
   głowa zwrócona ku uniesionej dłoni, stopy obracają się na krawędzie.

Stopy mogą pozostać lekko rozstawione dla stabilności; nie wymagać
nakładania jednej na drugą. Biodra pozostają uniesione, ramiona układają
się w linię tworzącą z tułowiem literę T.
Odrzucić obniżone biodra, ugięte górne ramię, dodatkową podporową rękę,
sam obrót ramienia bez tułowia i zmianę kamery między fazami.

### cw012 — Wyciskanie hantli na ławce płaskiej — 2 kadry

Lekko podwyższona kamera boczna 3/4 pokazująca oba hantle, łokcie i ławkę:
1. Leżenie na płaskiej ławce, stopy na podłodze, hantle przy klatce,
   nadgarstki nad łokciami, łokcie około 45° od tułowia.
2. Hantle wyciśnięte nad klatkę, ramiona wyprostowane bez nadmiernego
   przeprostu; hantle pozostają rozdzielone, bez zderzenia na górze.

Głowa, górna część pleców i pośladki pozostają podparte; dopuszczalna
niewielka naturalna krzywizna pleców. Odrzucić skośną ławkę, uniesione stopy
lub pośladki, załamane nadgarstki, nierówne wyciskanie i hantle nad twarzą.

## Przebieg generacji i przeglądów

1. Przygotować osobny prompt dla każdego ID z jego układem kadrów, kamerą,
   dokładnymi fazami oraz kryteriami odrzucenia.
2. Generować kolejno `cw007–cw012` przez `tools/benchmark_exercise_images.py`,
   pojedynczym żądaniem `--single-sunburst-medium` na próbę. Pierwsza próba
   używa `/tmp/opencode/cw256-reference.png`, odpowiadającego wzorcowi WebP.
3. Każda próba trafia do świeżego katalogu `/tmp/opencode/cwNNN-trial-NN`.
   Prompt, PNG, podgląd i ledger pozostają poza repozytorium.
4. Odczytać wynik oraz podgląd `512×512` przed następnym płatnym żądaniem.
   W trzech kadrach skontrolować także czytelność środkowej fazy.
5. Korekta usuwa tylko nazwany defekt, używa odrzuconego PNG jako jedynej
   referencji i świeżego katalogu. Zachowuje poprawne elementy sceny.
6. Jeśli kolejne korekty nie usuwają tego samego problemu, zatrzymać płatne
   próby i uzgodnić ponownie sposób przedstawienia ruchu.
7. Przegląd zgodności ze sceną poprzedza przegląd jakości, anatomii
   i czytelności w docelowym rozmiarze. Rozwiązać uwagi przed integracją.

## Integracja i weryfikacja

- W `test/features/exercises/exercise_illustrations_test.dart` dodać
  `cw007–cw012` po `cw006`, przed `cw251`, do `expectedIllustrationIds`.
- Przenieść istniejący przypadek braku ilustracji z `cw007` na nadal
  niezilustrowane `cw013`. Potwierdzić celowo czerwony kontrakt rejestru,
  wskazujący brak `cw007`, przy poprawnym fallbacku dla `cw013`.
- Produkcyjny rejestr i assety rozszerzyć dopiero po akceptacji wszystkich
  sześciu scen; nie integrować plików po pojedynczych generacjach.
- Zaakceptowane PNG konwertować przez `convert` z opcjami
  `-resize 512x512 -strip -quality 90` do `assets/exercises/cw007.webp`
  przez `cw012.webp`.
- W `lib/features/exercises/presentation/exercise_illustrations.dart`
  zarejestrować `cw007–cw012` po `cw006`, zachowując wszystkie wcześniejsze ID
  i istniejącą funkcję wyboru assetu. Deklaracja katalogu assetów już istnieje.
- Uruchomić Dockerowy target `verification` z
  `deploy/docker/web.Dockerfile`: kontrola wygenerowanej wersji, analiza
  Fluttera i pełne testy. Wymagana zgodność rejestru i plików oraz dekodowanie
  wszystkich 78 lokalnych ilustracji jako `512×512`.
- Testy automatyczne nie liczą wizualnych kadrów; liczbę 3/2 i poprawność
  ruchów potwierdzają przeglądy finalnych obrazów.
- W `docs/exercise-illustrations-status.md` dodać sześć wierszy z liczbami
  kadrów 3/2/2/2/3/2, sekcję „Szósta partia” i stan 78 lokalnych,
  66 wydanych, 12 niewydanych, 238 brakujących z katalogu 316.
  Nowe wiersze oznaczać jako lokalnie zintegrowane, niewydane.

## Warunki ukończenia pakietu

- Sześć finalnych WebP ma właściwą liczbę kadrów i przeszło oba przeglądy.
- Rejestr, oczekiwania testu i katalog assetów obejmują te same 78 ID.
- Analiza i testy Dockerowego targetu `verification` są zielone.
- Dokumentacja jednoznacznie odróżnia 12 niewydanych lokalnych ilustracji
  Partii 05 i 06 od 66 ilustracji aktualnej produkcji.
- Praca pozostaje w aktualnym `main`, zgodnie z dotychczasowym wyborem.
  Wdrożenie, commit i push wymagają wyraźnej prośby użytkownika.
