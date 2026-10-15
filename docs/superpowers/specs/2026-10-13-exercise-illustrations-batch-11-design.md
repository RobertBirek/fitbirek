# Ilustracje ćwiczeń — projekt Partii 11

## Zakres i stan wejściowy

Partia obejmuje `cw037–cw042`: L-sit, łucznika, opuszczanie jednorącz,
chest-to-bar, podciąganie eksplozywne i opuszczanie oburącz. Źródłem nazw
i wskazówek jest `assets/data/exercises.json`; nie zmieniać danych ani ID.

Stan wejściowy: 102 ilustracje lokalne = 78 wydanych + 24 niewydane z
Partii 07–10; 214 brakujących na 316 ćwiczeń. Po integracji Partii 11:
108 lokalnych = 78 wydanych + 30 niewydanych; 208 brakujących.
Produkcja pozostaje `1.9.0+22`. Ten projekt nie uruchamia płatnych żądań,
publikacji, zmiany wersji, commita ani pushu.

## Proponowane warianty

- Nachwyt na szerokość barków dla `cw037`, `cw040`, `cw041` i `cw042`;
  szeroki nachwyt dla `cw038`. Katalog nie określa orientacji wszystkich
  tych chwytów — są to spójne decyzje ilustracyjne, nie zmiany rekordów.
- `cw039`: pracuje anatomiczna prawa ręka nachwytem, lewa jest wyraźnie
  puszczona i widoczna obok ciała, bez podtrzymywania nadgarstka. Sekwencja
  zaczyna się już po wejściu na górę i puszczeniu drugiej ręki. Wejście
  dwurącz lub wskok pozostaje w instrukcji katalogowej.
- `cw041`: wysoka pozycja z drążkiem przy dolnej części mostka, wyżej
  niż w `cw040`, ale bez przejścia do podporu nad drążkiem. Eksplozywnego
  tempa nie kodować strzałkami lub duchami ruchu.
- Czasy opuszczania (`cw039`: 5–10 s; `cw042`: 5–8 s) pozostają w katalogu.
  Kadry wyjaśniają kierunek i zakres, nie mierzą czasu.

## Kontrakt wizualny i sprzęt

- Jeden WebP `512×512` na ID, generowany z PNG `1024×1024`.
- `cw037`, `cw038`, `cw040`, `cw041`: dokładnie dwa kadry obok siebie,
  dolna pozycja → górna pozycja, od lewej do prawej.
- `cw039` i `cw042`: dokładnie trzy **pionowe kolumny** obok siebie,
  górna pozycja → środek opuszczania → dolna pozycja, od lewej do prawej.
  Nie trzy poziome pasy: pionowa sylwetka wymaga wysokości kadru.
- Styl `cw256`: kremowe tło, ciemny neutralny strój, twarz bez rysów,
  komiksowy kontur. Bez tekstu, numerów, timerów, etykiet, strzałek,
  znaków wodnych i dodatkowych sylwetek. Nakładki mięśni nie są wymagane.
- Stała kamera, skala postaci, wysokość drążka i jego mocowania we
  wszystkich kadrach jednego obrazu. Ruch wykonuje postać, nie sprzęt.
- Drążek poziomy, fizycznie zamocowany do stabilnej prostej konstrukcji.
  Dłonie rzeczywiście obejmują drążek; bez zrostów i brakujących kończyn.
- Całe ciało, dłonie, stopy i niezbędne mocowania mieszczą się w każdym
  kadrze. Stopy pozostają nad podłogą; bez stopnia, gumy lub podparcia.
- Neutralna szyja, bez wyciągania brody samym odchyleniem głowy. W dolnym
  zwisie naturalne ustawienie barków przy uniesionych ramionach; nie
  wymuszać maksymalnej depresji łopatek i rozluźnionego zwisu jednocześnie.
- Oceniać źródło i podgląd `512×512`. Naturalne zasłonięcie jest
  dopuszczalne, jeśli nie ukrywa istoty chwytu, podparcia lub fazy.

## Sceny i odrzucenia

### cw037 — Podciąganie z prostymi nogami uniesionymi do poziomu — 2 kadry

Stała kamera boczna 3/4, pokazująca prostą linię obu nóg i kontakt dłoni:
1. Pełny zwis na prostych ramionach, nogi wyprostowane razem w przód,
   około poziomu bioder, równolegle do podłogi; sylwetka L.
2. Podciągnięcie z brodą nad drążkiem, ugięte łokcie. Nogi nadal proste
   i poziome względem podłogi; unoszą się wraz z biodrami, nie opadają.

Odrzucić ugięte kolana, jedną nogę opuszczoną, zmianę L na zwykłe
podciąganie, bujanie, skrót zakresu i ucięte stopy.

### cw038 — Podciąganie łucznika — 2 kadry

Stała przednio-boczna 3/4, pokazująca oba ramiona i szeroki drążek:
1. Symetryczny pełny zwis z prostymi ramionami, szeroki nachwyt.
2. Przesunięcie ciała do anatomicznej prawej ręki roboczej: prawy łokieć
   ugięty, broda przy tej stronie drążka, lewa ręka pomocnicza prosta
   w bok i nadal w kontakcie z drążkiem. Dopuszczalny ślizg dłoni zgodny
   z katalogiem; strona robocza i kamera pozostają niezmienne.

Odrzucić oba łokcie ugięte jak w zwykłym podciąganiu, odłączoną dłoń
pomocniczą, zamianę stron, skręt tułowia lub bujanie.

### cw039 — Opuszczanie na jednej ręce z podciągnięcia — 3 kadry

Stała przednio-boczna 3/4, prawy chwyt i wolna lewa dłoń widoczne:
1. Broda ponad drążkiem, prawy łokieć mocno ugięty; lewa ręka już puszczona.
2. Kontrolowane obniżenie ciała, prawy łokieć częściowo prostowany;
   lewa dłoń nadal bez kontaktu z drążkiem lub prawym nadgarstkiem.
3. Dolna pozycja z prawym ramieniem wydłużonym do niemal pełnego zwisu,
   bez gwałtownego przeprostu; stopy w powietrzu, bark i tułów kontrolowane.

We wszystkich fazach dokładnie jedna dłoń podporowa. Odrzucić lewy
chwyt na drążku, asystę drugą ręką, pozycję wznoszenia zamiast opuszczania,
trzy identyczne kąty łokcia, brak wolnej ręki i silny obrót tułowia.

### cw040 — Podciąganie do klatki — 2 kadry

Stała kamera boczna 3/4, pozwalająca ocenić kontakt drążka z klatką:
1. Pełny zwis na prostych ramionach, nachwyt na szerokość barków.
2. Górna część klatki dotyka drążka przy górnym mostku; tułów
   kontrolowanie odchylony w łuk, łokcie w dół i do tyłu, szyja neutralna.

Odrzucić zatrzymanie tylko brodą nad drążkiem, kontakt drążka z szyją
lub twarzą, przenikanie przez klatkę, kip i przesadne wygięcie lędźwi.

### cw041 — Podciąganie eksplozywne — 2 kadry

Stała kamera boczna 3/4, ujawniająca wysokość ciała względem drążka:
1. Pełny zwis, prosty lub lekko hollow tułów, stopy w powietrzu.
2. Wysokie podciągnięcie: drążek przy dolnej części mostka, łokcie
   nadal ugięte, dłonie zachowują nachwyt. Bez przetoczenia nad drążkiem
   i wyprostu ramion do podporu jak przy ukończonym muscle-up.

Odrzucić zwykłe podciągnięcie do brody, identyczną wysokość jak `cw040`,
podpór muscle-up, puszczenie drążka, kip i kopnięcie nogami. Statyczny
obraz pokazuje wysokość celu; eksplozywne tempo opisuje katalog.

### cw042 — Opuszczanie z podciągnięcia — 3 kadry

Stała przednio-boczna 3/4, obie dłonie nachwytem na szerokość barków:
1. Broda nad drążkiem, ugięte łokcie; wejście wskokiem lub ze stopnia
   nie jest osobnym kadrem ani dodatkowym sprzętem tej ilustracji.
2. Środek kontrolowanego opuszczania, łokcie bardziej otwarte, ciało niżej.
3. Końcowy pełny zwis na prostych ramionach, stopy nadal nad podłogą.

Odrzucić odwróconą kolejność (zwis → góra), jedną puszczoną rękę,
trzy identyczne fazy, brak pełnego końcowego zwisu i timer.

## Generacja, kontrola i integracja

Każde pierwsze żądanie korzysta z `/tmp/opencode/cw256-reference.png`
przez `tools/benchmark_exercise_images.py --single-sunburst-medium`.
Świeży katalog `/tmp/opencode/cwNNN-trial-NN`, dokładnie jeden obraz.
Odczyt źródła i podglądu `512×512` przed kolejnym płatnym żądaniem.
Korekta tylko nazwanego defektu, z ostatnim odrzuconym PNG jako jedyną
referencją. Po dwóch nieskutecznych korektach tego samego problemu
zatrzymać kolejne płatne próby i ocenić nowe ujęcie. Nie retry automatycznie
po niepewnym wyniku API. Prompty, PNG, podglądy i ledgery poza repozytorium.

Porównać `cw037/cw032` pod kątem utrzymania L, `cw038/cw031` pod kątem
asymetrii ramion, `cw039/cw042` pod kątem liczby podporowych dłoni oraz
`cw040/cw041` pod kątem wysokości klatki względem drążka. Czas i prędkość
nie są cechami mierzalnymi ze statycznego obrazu.

Najpierw test oczekiwanych ID `cw037–cw042` po `cw036`, przed `cw251`;
fallback przenieść z `cw037` na `cw043`. Potwierdzić czerwony kontrakt
z brakiem `cw037`. Dopiero po akceptacji całej szóstki konwersja
`-resize 512x512 -strip -quality 90`, te same ID w rejestrze i zielona
weryfikacja Dockerowa: analiza, pełne testy, 108 plików zgodnych z rejestrem
i oczekiwaniami, każdy dekodowany jako `512×512`, fallback `cw043` poprawny.

Dokumentacja statusu: sześć wierszy, kadry `2/2/3/2/2/3`, sekcja
„Jedenasta partia”, stan 108 lokalnych / 78 wydanych / 30 niewydanych
z Partii 07–11 / 208 brakujących / 316 rekordów. Zachować wszystkie
wcześniejsze niecommitowane pakiety, wersję `1.9.0+22` i dowody wydań.
Praca na aktualnym `main`, bez worktree; publikacja i operacje Git osobno.

## Zapis wykonania

Użytkownik zatwierdził zakres oraz trzy pionowe kolumny opuszczania.
Wykonanie odbyło się bezpośrednio w sesji po osiągnięciu limitu subagentów;
nie przedstawiać kontroli źródeł i finalnych WebP jako niezależnego
przeglądu subagentowego. Zachowano pojedyncze żądania i odczyt każdego
wyniku przed kolejną generacją.

W `cw041` próby wspólnego wyrównania sprzętu nie rozwiązały różnicy
wysokości. Po ponownej ocenie zastosowano jedną ograniczoną korektę
wyłącznie lewego zwisu do poprawnej wysokości prawego drążka. Ta próba
naprawiła aparat, ale obniżyła względną wysokość górnej pozycji ciała;
jedna korekta tylko tej pozycji, z nieruchomym drążkiem, domknęła scenę.
Końcowe źródła, koszty i wynik zielonej weryfikacji zapisano w dokumencie
statusowym. Nie zmieniono katalogu, wariantów ćwiczeń ani produkcji.
