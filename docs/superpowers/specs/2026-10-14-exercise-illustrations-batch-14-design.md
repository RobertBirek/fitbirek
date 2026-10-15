# Ilustracje ćwiczeń — projekt Partii 14

## Zakres i stan wejściowy

Partia obejmuje `cw055–cw060`: pull-apart, wiosłowanie gumą w siadzie,
ściąganie gumy do klatki, face pull, Superman i Superman hold. Źródłem
nazw i techniki jest `assets/data/exercises.json`; nie zmieniać danych ani ID.

Stan wejściowy: 120 lokalnych ilustracji = 78 wydanych + 42 niewydane
z Partii 07–13; 196 brakujących na 316 ćwiczeń. Po integracji Partii 14:
126 lokalnych = 78 wydanych + 48 niewydanych; 190 brakujących.
Produkcja pozostaje `1.9.0+22`. Przygotowanie dokumentów nie uruchamia
płatnej generacji, zmiany wersji, wdrożenia, commita ani pushu.

## Kadry i przyjęte warianty

- `cw055–cw059`: po dwa kadry obok siebie, od lewej pozycja startowa,
  po prawej przyciągnięcie, rozciągnięcie lub uniesienie.
- `cw060`: jeden niepodzielony kadr utrzymania uniesionych kończyn.
  Nie dodawać timera lub drugiej fikcyjnej fazy izometrii.
- `cw056`: siad na podłodze, nogi przed sobą z dopuszczalnym lekkim
  ugięciem kolan; zewnętrzna kotwa przed ciałem na wysokości odpowiadającej
  brzuchowi siedzącej postaci. Nie zaczepiać gumy o stopy w tym wariancie.
- `cw057`: klęk obunóż, wyprostowany tułów, wysoka kotwa przed postacią.
  Katalog dopuszcza klęk lub siad; wybrano klęk.
- `cw058`: stabilny stój wykroczny, kotwa przed postacią na wysokości głowy.
- `cw059/cw060`: obie ręce wyprostowane nad głową i obie nogi razem;
  łagodne, kontrolowane uniesienie, brzuch i miednica pozostają podparte.
- Czas utrzymania i pauz określa katalog. Statyczny hold może odpowiadać
  uniesionej fazie Supermana; nie wymaga sztucznego wizualnego wyróżnika.

## Kontrakt wizualny i gumy

Jeden WebP `512×512` na ID, ze źródłowego PNG `1024×1024`. Styl `cw256`:
kremowe tło, ciemny neutralny strój, twarz bez rysów, komiksowy kontur.
Bez tekstu, numerów, etykiet, strzałek, timerów, watermarków i duchów
ruchu; nakładki mięśni nie są wymagane. Całe ciało, dłonie, stopy i
niezbędny sprzęt mieszczą się w każdym kadrze. Przy dwóch fazach stała
kamera, skala postaci, kotwy i podparcia.

- `cw055` ma jedną gumę między dłońmi, bez kotwy zewnętrznej.
- `cw056–cw058` mają widoczną, stabilną kotwę na prostym wsporniku przed
  postacią. Pokazać dwa robocze odcinki, po jednym do każdej dłoni,
  oraz spójne połączenie uchwytów lub końców gumy z chwytami.
- Kotwy zachowują położenie między fazami: niska przednia w `cw056`,
  wysoka przednia w `cw057`, na wysokości głowy w `cw058`.
- Gumy naprężone, elastyczne, ciągłe, bez odłączonych końców i dodatkowych
  gałęzi. Nie przenikają przez głowę, szyję ani ciało. Naturalna okluzja
  wymaga widocznych odcinków wyjaśniających przebieg. Samo nałożenie linii
  gumy na sylwetkę w projekcji nie dowodzi fizycznego przenikania.
- Odczytać źródło i podgląd `512×512`; prześledzić każdą trasę kotwa → guma
  → właściwa dłoń. W pull-apart odczytać ciągłą trasę między dwiema dłońmi.

## Sceny i kryteria odrzucenia

### cw055 — Rozciąganie gumy przed klatką piersiową — 2 kadry

Stała kamera przednio-boczna 3/4, z odpowiednią skalą dla pełnego rozstawu:
1. Wyprostowany stój, stopy stabilne, ramiona wyprostowane przed klatką,
   dłonie około szerokości barków trzymają tę samą gumę, już lekko napiętą.
2. Ramiona rozłożone szeroko na boki na wysokości klatki, łokcie nadal
   proste; guma rozciągnięta między dłońmi przed ciałem, łopatki ściągnięte.

Odrzucić kotwę zewnętrzną, zgięte łokcie, brak ciągłości gumy, ucięte
dłonie, uniesienie ramion nad głowę, zmianę ustawienia stóp i shrug.

### cw056 — Wiosłowanie gumą w siadzie — 2 kadry

Stała kamera boczna 3/4 pokazująca kotwę, oba chwyty i nogi:
1. Siad na podłodze, pośladki i pięty podparte, proste plecy, nogi
   przed ciałem, kolana mogą być lekko ugięte. Guma od niskiej przedniej
   kotwy do dwóch dłoni na wydłużonych ramionach, przebieg ponad nogami.
2. Obie dłonie przyciągnięte do brzucha, łokcie blisko tułowia i cofnięte,
   łopatki kontrolowanie zbliżone. Tułów bez odchylenia w tył lub przód,
   te same podparcia, kotwa i nogi.

Odrzucić gumę zaczepioną o stopy, tylną kotwę, zaokrąglone plecy,
przenikanie gumy przez nogi, podciągnięcie do twarzy i kołysanie tułowiem.

### cw057 — Ściąganie gumy z góry do klatki piersiowej — 2 kadry

Stała kamera przednio-boczna 3/4, postać zwrócona ku wysokiej przedniej kotwie:
1. Klęk obunóż, tułów wyprostowany, ramiona uniesione i wydłużone ku
   wysokiej kotwie, obie dłonie na niezależnych końcach lub uchwytach.
2. Końce przyciągnięte ku górnej klatce, łokcie wyraźnie ugięte,
   prowadzone w dół przy tułowiu. Szyja neutralna, barki kontrolowane,
   kolana i tułów zachowują położenie.

Odrzucić kotwę za ciałem, ciągnięcie za kark, prostoramienny pullover
zamiast zgięcia łokci, kip, kołysanie i zmianę klęku na stój.

### cw058 — Face pull z gumą — 2 kadry

Stała kamera przednio-boczna 3/4 ujawniająca dwa końce i kotwę na wysokości głowy:
1. Stabilny stój wykroczny, wyprostowany tułów, ręce wydłużone przed sobą
   ku przedniej kotwie, guma napięta do dwóch chwytów.
2. Dłonie rozdzielone po bokach twarzy, około górnych policzków lub skroni;
   łokcie ugięte i szeroko, nieco wyżej niż nadgarstki zgodnie z katalogiem,
   rotacja zewnętrzna barków. Tułów i szyja stabilne, guma poza głową.

Odrzucić dłonie przy brodzie lub brzuchu, dwa końce złączone przed twarzą,
niemożliwy przebieg gumy, wyprostowane łokcie jak w pull-apart, shrug
i przechylenie głowy zastępujące ruch ramion.

### cw059 — Unoszenie ramion i nóg w leżeniu na brzuchu — 2 kadry

Stała niska kamera boczna 3/4 pokazująca oba zestawy kończyn:
1. Leżenie przodem na podłodze, ramiona wyprostowane nad głową, nogi
   wydłużone, szyja neutralna i wzrok skierowany w podłogę.
2. Jednocześnie obie ręce i obie nogi łagodnie uniesione nad podłożem,
   kolana nadal wydłużone; brzuch i miednica pozostają podparte,
   niewielkie kontrolowane wyprostowanie pleców, bez skrajnego łuku.

Odrzucić unoszenie tylko jednej pary przeciwległych kończyn jako regresję,
całe ciało w locie, ugięte kolana, zadzieranie głowy i nadmierny przeprost.

### cw060 — Utrzymanie uniesionych ramion i nóg w leżeniu na brzuchu — 1 kadr

Ten sam typ bocznego 3/4 ujęcia: obie ręce nad głową i obie nogi
utrzymane w niewielkim uniesieniu, brzuch i miednica na podłodze,
kontrolowany łagodny wyprost, szyja neutralna, wzrok w dół.

Odrzucić timer, fikcyjną drugą fazę, przeciwległe kończyny zamiast obu
par, ciało bez kontaktu z podłogą, uniesioną brodę i skrajny łuk pleców.

## Generacja, przeglądy i integracja

Sześć osobnych promptów z kompozycją, wariantem, kamerą, fazami i sprzętem.
Pierwsza referencja `/tmp/opencode/cw256-reference.png`; świeży katalog
`/tmp/opencode/cwNNN-trial-NN`, jedno żądanie `--single-sunburst-medium`
przez `tools/benchmark_exercise_images.py`. Odczyt źródła i podglądu przed
kolejnym płatnym żądaniem. Korekta tylko nazwanego defektu z ostatnim
odrzuconym PNG jako jedyną referencją. Po dwóch nieskutecznych korektach
tego samego problemu zatrzymać płatne próby i ocenić nowe ujęcie; bez
automatycznego retry po niepewnym wyniku API. Artefakty prób poza repozytorium.

Porównać wyprostowane łokcie pull-apart z ugiętymi łokciami face pull,
kotwy i końcowe chwyty row/pulldown/face pull oraz uniesioną fazę Superman
z jego statycznym utrzymaniem. Nie oceniać czasu ze statycznego obrazu.
Jeśli subagenci są niedostępni, odnotować kontrolę bezpośrednią.

Test oczekiwanych ID dostaje cw055–cw060 po cw054, przed cw251; fallback
przenieść z cw055 na cw061. Wykazać czerwony kontrakt z brakiem cw055.
Dopiero po akceptacji całego pakietu konwersja `-resize 512x512 -strip
-quality 90`, dopisanie tych samych ID do rejestru i zielony Dockerowy
target `verification`: kontrola wersji, analiza, pełne testy, 126 zgodnych
plików/rejestru/oczekiwań, dekodowanie `512×512`, poprawny fallback cw061.

Dokumentacja: sześć wierszy, kadry `2/2/2/2/2/1`, sekcja „Czternasta partia”,
126 lokalnych / 78 wydanych / 48 niewydanych z Partii 07–14 / 190 brakujących
na 316 ćwiczeń. Zachować wszystkie wcześniejsze pakiety, dowody wydań,
aktualny `main` bez worktree oraz wersję produkcyjną `1.9.0+22`.
Publikacja i operacje Git wymagają osobnej prośby użytkownika.

## Zatwierdzona zmiana kompozycji

Po dwóch odrzuconych korektach `cw057–cw059` użytkownik zatwierdził nowe
kompozycje. Dla `cw057–cw058` obowiązuje stała kamera frontalna w obu
panelach zamiast 3/4, z przednią kotwą i czytelnymi gałęziami poza głową.
`cw059` zachowuje dwie fazy, lecz ma dwa poziome pasy pełnej szerokości,
od góry do dołu, zamiast wąskich kolumn. Pozostałe kryteria techniki,
podparcia, sprzętu i końcowego rozmiaru pozostają obowiązujące.
