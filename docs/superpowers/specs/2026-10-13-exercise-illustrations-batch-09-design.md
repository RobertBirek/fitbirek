# Ilustracje ćwiczeń — projekt Partii 09

## Cel i zakres

Przygotować sześć kolejnych ilustracji `cw025–cw030` zgodnych z katalogiem
`assets/data/exercises.json` (wiersze 823–1032), referencją stylu `cw256`
i istniejącym rejestrem ilustracji. Użytkownik zatwierdził kontynuację pracy;
wykonanie przebiega tym samym workflow subagentowym, bez powtarzanych pauz
zatwierdzających. Ten dokument i towarzyszący plan opisują przyszłe wykonanie.

Stan wejściowy: 316 ćwiczeń, 90 ilustracji lokalnych, 78 wydanych,
12 niewydanych z Partii 07 i 08, 226 brakujących. Stan po integracji Partii 09:
96 lokalnych = 78 wydanych + 18 niewydanych z Partii 07, 08 i 09;
220 ćwiczeń bez ilustracji. Zachować wszystkie lokalne zmiany Partii 07/08.
Produkcja pozostaje `1.9.0+22`; publikacja, wersjonowanie, commit i push
nie są automatycznymi etapami tego pakietu.

## Forma i wspólna jakość

- Jeden WebP 512×512 na ćwiczenie, generowany z PNG 1024×1024.
- `cw025–cw029`: dokładnie dwa kadry obok siebie, od lewej do prawej.
- `cw030`: dokładnie trzy pełnej szerokości poziome pasy ułożone pionowo,
  od góry do dołu. Nie trzy wąskie kolumny.
- Kremowe tło, ciemny komiksowy kontur, dorosła postać bez rysów twarzy,
  neutralny ciemny strój jak w `assets/exercises/cw256.webp`.
- Stała kamera, skala postaci i sprzęt w obrębie każdej ilustracji.
  Całe ciało i cały niezbędny sprzęt mieszczą się w każdym kadrze.
- Bez napisów, numerów, timerów, etykiet, strzałek, znaków wodnych,
  duchów ruchu i dodatkowych kończyn. Kolorowe nakładki mięśni nie są wymagane.
- Chwyty, palce, kontakty podporowe i fazy muszą być czytelne również przy
  512×512. Naturalne zasłanianie perspektywiczne jest dopuszczalne, jeżeli
  anatomia i przebieg kontaktów pozostają jednoznaczne.

## Sceny i kryteria akceptacji

### cw025 — Bench chest dip

Dwie stabilne płaskie ławki: obie dłonie na jednej ławce za biodrami,
wyprostowane nogi i pięty na drugiej przed postacią. Obie ławki widoczne
w całości; pośladki nie spoczywają na siedzisku. Lewy kadr: ramiona
wyprostowane, ciało zawieszone pomiędzy podporami, tułów bliski pionu;
dopuszczalne niewielkie odchylenie wynikające z geometrii podporu.
Prawy: łokcie ugięte około 90°, kontrolowane obniżenie z wyraźnym
pochyleniem tułowia w przód dla zaakcentowania klatki, bez unoszenia barków
i wymuszania głębokości poza wiarygodną geometrią stawu. Pochylenie jest
elementem zejścia, nie obowiązkowym ustawieniem obu faz. Te same kontakty
dłoni i pięt w obu fazach. Doprecyzowanie wynika z przeglądu geometrii
próby cw025-trial-02 i zachowuje wybrany wariant dwóch ławek.
Odrzucić stopy na podłodze (regresja), poręcze zamiast ławek i brak podporu.

Katalog dopuszcza krzesła lub ławkę i wskazuje drugie krzesło pod nogami.
Przyjęta ilustracja dwóch stabilnych ławek realizuje tę samą konfigurację
podporów. Wskazówka „głębokie zejście” nie wymaga skrajnego zakresu barku.

### cw026 — Pseudo planche push-up

Podpór na palcach stóp na podłodze, dłonie przy biodrach, palce skierowane
na zewnątrz (dopuszczony przez katalog wariant „na boki”). Barki wyraźnie
przed dłońmi, stałe pochylenie w przód, wypchnięta górna część pleców,
napięta linia ciała. Lewy kadr z prostymi ramionami, prawy z ugiętymi
łokciami i obniżoną klatką; pochylenie i podporowe palce stóp zachowane.
Odrzucić zwykłą pompkę z dłońmi pod barkami, pełną planche ze stopami
w powietrzu i wymuszone odwrócenie palców w tył.

### cw027 — Fingertip push-up

Klasyczna pompka, ale każda dłoń oparta na opuszkach wszystkich pięciu
szeroko rozstawionych palców; wnętrze dłoni uniesione nad podłogą.
Niska kamera od przodu ujawnia podporowe opuszki i osobny kciuk oraz cztery
pozostałe palce każdej dłoni. Po przeglądzie trial-03 dopuszczono bardziej
frontalne ujęcie zamiast front-side 3/4, bez zmiany podporu lub faz.
Lewy kadr: górny
podpór; prawy: klatka nisko, łokcie około 45°, stabilna linia ciała,
palce stóp na podłodze. Anatomia obu dłoni ma pięć palców; perspektywa
może częściowo zasłaniać palec, ale nie usprawiedliwia braków lub zrostów.
Odrzucić podpór na paznokciach, pięściach, płaskich dłoniach, mniejszej
liczbie palców i nienaturalne załamania palców.

### cw028 — Archer decline push-up

Palce obu stóp na niskiej stabilnej ławce około 30–50 cm, obie dłonie
na podłodze szerzej niż barki. Lewy kadr: symetryczny szeroki podpór
z prostymi ramionami. Prawy: ciężar na jednym ugiętym ramieniu roboczym,
drugie ramię proste w bok jako pomocnicze; biodra bez rotacji. Stała
tożsamość strony roboczej, kamera i ławka. Odrzucić oba łokcie ugięte
jak w `cw009`, stopy na podłodze jak w `cw004`, skręt miednicy lub
oderwaną dłoń pomocniczą.

### cw029 — Paused push-up

Lewy kadr: wysoki podpór; prawy: klatka utrzymana około 2 cm nad podłogą,
łokcie około 45°, napięte ciało, bez kontaktu klatki z podłogą i odbicia.
W obu kadrach dłonie i palce stóp na podłodze. Obraz statyczny nie koduje
trzech sekund; czas określa istniejący katalog (tempo `3-3-1-0`). Nie
dodawać timera, tekstu, powtórzonej dolnej fazy ani sztucznego wyróżnika
względem `cw001`. Akceptacja dotyczy prawidłowej geometrii zatrzymania.

### cw030 — Side-to-side plyo push-up

Dokładnie trzy poziome pasy pełnej szerokości, czytane od góry do dołu.
Stała lekko podwyższona kamera dokładnie z przodu (postać skierowana ku
widzowi w każdym pasie, stopy za tułowiem) i dyskretna prosta linia
łączenia podłogi w tym samym miejscu w każdym pasie pozwalają porównać
położenie. Góra: niska pompka w lewym położeniu. Środek: eksplozywne
przemieszczenie górnej części ciała w bok, obie dłonie wyraźnie nad
podłogą, palce stóp utrzymują kontakt jako punkt obrotu. Dół: lądowanie
w prawym położeniu na ugiętych łokciach, stabilny tułów i napięta linia
ciała. Kamera ani punkt odniesienia nie przesuwają się wraz z postacią.
Odrzucić ruch wyłącznie pionowy, klaśnięcie, dłonie stale na podłodze,
proste łokcie przy lądowaniu i trzy identyczne pozycje. Bez strzałek
i wielokrotnych sylwetek w jednej fazie.

Katalog nie określa kontaktu stóp w locie. Przyjęty wariant zachowuje
podporowe palce stóp i pokazuje boczny przeskok dłoni/górnej części ciała;
nie wymaga unoszenia całego ciała w powietrze.

### Doprecyzowanie ujęć po przeglądach cw027 i cw030

Po dwóch nieskutecznych korektach pierwotne podejście zatrzymano.
Kontynuacja wymaga materialnej zmiany ujęcia, nie kolejnego powtórzenia
tego samego promptu: bardziej frontalnej projekcji obu dłoni w `cw027`
oraz kamery dokładnie z przodu w `cw030`. W `cw030` nie narzucać sztucznych
identycznych współrzędnych każdego palca stopy; podparcie i pivot mają być
fizycznie spójne, a kierunek osi ciała nie może odwracać się między pasami.
Przewidziano po jednej dodatkowej próbie z ostatnim odrzuconym PNG jako
jedyną referencją. Jeżeli pierwotne defekty pozostaną, wstrzymać dalsze
generowanie tych ID i zgłosić blokadę. Próba cw030-correction-03 usunęła
zmianę orientacji i ujęcia, ale przegląd ujawnił nowy defekt geometrii nóg
w środkowym pasie. Dopuszczono jedną punktową korektę tylko tej fazy:
nogi za tułowiem, orientacja butów zgodna z pozostałymi pasami, bez zmiany
kamery, startu, lądowania ani bocznego przemieszczenia. Jeśli ta korekta
nie przejdzie przeglądu, zatrzymać generowanie cw030 i zgłosić blokadę.

## Generowanie, korekty i przeglądy

Pierwsze żądanie każdego ID: referencja `/tmp/opencode/cw256-reference.png`,
świeży katalog `/tmp/opencode/cwNNN-trial-01`, skrypt
`tools/benchmark_exercise_images.py` z `--single-sunburst-medium` (`n=1`).
Żądania wyłącznie sekwencyjne. Po każdym odczytać źródłowy PNG i podgląd
512×512 przed następnym płatnym wywołaniem. Dane uwierzytelniające ładować
z `/root/.config/fit/openai.env`, nigdy nie wypisywać kluczy.

Przed korektą nazwać konkretny widoczny defekt. Jedyną referencją korekty
jest ostatni odrzucony PNG; świeży kolejny katalog i prompt, poprawka tylko
nazwanego defektu, pozostałe zaakceptowane cechy zachowane. Jeżeli dwie
kolejne korekty nie usuną tego samego defektu, zatrzymać płatne próby i
zgłosić blokadę. Bez automatycznych retry po niepewnym wyniku API.

Niezależny przegląd zgodności sceny, następnie jakości, przed uznaniem
każdego źródła za zaakceptowane. Przy workflow subagentowym osobni
recenzenci; kontroler utrzymuje listę zaakceptowanych ścieżek i koszty
z ledgerów. Korekta w ustalonym zakresie nie wymaga kolejnej zgody;
zmiana wariantu sceny wymaga rozstrzygnięcia blokady.

## Integracja i weryfikacja

Najpierw rozszerzyć test oczekiwanych ID o `cw025–cw030` po `cw024`,
przed `cw251`; fallback przenieść z `cw025` na `cw031`. Dockerowy target
`verification`, tag `fit-web:batch-09-red`, ma wykazać brak nowych ID.
Po akceptacji wszystkich sześciu źródeł konwersja
`-resize 512x512 -strip -quality 90`, dopisanie tych samych ID do rejestru
i Docker `fit-web:batch-09-verified` (timeout co najmniej 1200 s).
Istniejące testy sprawdzają dokładny zbiór plików i dekodowanie 512×512;
liczbę kadrów, anatomię i fazy sprawdza przegląd wizualny.

Status końcowy ma zawierać sześć wierszy z liczbami kadrów `2/2/2/2/2/3`,
sekcję „Dziewiąta partia” i podział 96/78/18/220/316. Zachować historię
lokalnych Partii 07/08 i wcześniejszych wydań. Nie zmieniać katalogu,
modeli, zależności, wersji, konfiguracji wdrożenia ani produkcji.
