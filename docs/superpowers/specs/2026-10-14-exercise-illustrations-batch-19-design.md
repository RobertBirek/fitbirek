# Ilustracje ćwiczeń — projekt Partii 19

## Zakres i stan wejściowy

Zakres: `cw085–cw090` z `assets/data/exercises.json`. Stan wejściowy:
150 lokalnych ilustracji = 78 wydanych + 72 niewydane z Partii 07–18;
166 brakujących na 316 ćwiczeń. Po integracji szóstki: 156 lokalnych
= 78 wydanych + 78 niewydanych; 160 brakujących.
Produkcja pozostaje `1.9.0+22`. Użytkownik zatwierdził zakres, warianty
i reuse cw055 jako cw086. Zachować katalog, ID i wcześniejsze
pakiety; publikacja i operacje Git wymagają osobnej prośby.

## Kadry, warianty i ponowne wykorzystanie

| ID | Ćwiczenie | Kadry | Wariant |
|---|---|---:|---|
| cw085 | Face pull z gumą | 2 | Stój, kotwa przed ciałem na wysokości oczu, dwa rozdzielone chwyty. |
| cw086 | Rozciąganie gumy przed klatką piersiową | 2 | Ponowne wykorzystanie cw055: bez zewnętrznej kotwy, proste ramiona. |
| cw087 | Rotacja zewnętrzna ramienia z gumą | 2 | Prawa ręka; kotwa po lewej stronie postaci, ręcznik przy łokciu. |
| cw088 | Rotacja wewnętrzna ramienia z gumą | 2 | Prawa ręka; kotwa po prawej stronie postaci, ruch do brzucha. |
| cw089 | Wyciskanie kubańskie z hantlami | 4 | Zwis → wysoki łokieć → rotacja w górę → wyciskanie. |
| cw090 | Rotacja zewnętrzna ramienia z hantlem w leżeniu bokiem | 2 | Leżenie na lewym boku, prawa górna ręka robocza. |

### Reuse i liczba generacji

- Odczytano `assets/exercises/cw055.webp`: technika i kadry odpowiadają
  cw086. Brak napisów/oznaczeń czasu lub nakładek mięśni wymagających
  zmiany przy innym opisie partii i tempie. Proponowane skopiowanie pod
  `assets/exercises/cw086.webp`, bez płatnego żądania. Oryginał zachować.
  Nazwa, tempo i ID obu ćwiczeń pozostają odrębne w katalogu.
- Odczytano `assets/exercises/cw058.webp`: podobny face pull, ale kotwa
  jest pokazana ponad głową. Nie kopiować go bezkrytycznie do cw085,
  którego katalog wymaga poziomu oczu. Dla cw085 nowe ujęcie.
- Pakiet zawiera sześć ID, lecz domyślnie tylko pięć nowych generacji.
  Zasoby mają własne ścieżki ID; nie zmieniać mappera na dopasowanie po nazwie.

### Układ i wybory

- `cw085`, `cw087`, `cw088`: dwa kadry obok siebie, lewo→prawo.
  Stała przednio-boczna 3/4 kamera ujawnia kotwę, chwyty i ruch przedramienia.
- `cw086`: istniejące dwa kadry obok siebie, kamera cw055 bez zmian.
- `cw089`: siatka 2×2, kolejność górny lewy → górny prawy → dolny lewy
  → dolny prawy, bez numerów/strzałek. Cztery kadry pozwalają pokazać
  także początkowy zwis; trzy pomijałyby jedną z części złożonego ruchu.
- `cw090`: dwa poziome pasy pełnej szerokości, góra→dół. Stała kamera
  przednio-boczna 3/4 z widoczną górną ręką, podparciem boku i łokciem.
- `cw085`: stały stój obunóż. Jedna guma środkiem zaczepiona o widoczny
  przedni wspornik na wysokości OCZU, dwie napięte gałęzie do dłoni.
  Końce rozdzielone po bokach górnej twarzy, łokcie szeroko, nieco wyżej
  niż nadgarstki zgodnie z katalogiem. Nie podnosić kotwy ponad głowę
  jedynie dla łatwiejszego rozrysowania gumy.
- `cw087`: prawa ręka robocza; kotwa po LEWEJ stronie postaci na
  wysokości łokcia. Łokieć przy prawym boku, zgięty 90°, niewielki
  zwinięty ręcznik między łokciem a tułowiem, jak we wskazówkach.
  Przedramię przemieszcza się od przodu brzucha na zewnątrz.
- `cw088`: ta sama prawa ręka, kotwa po PRAWEJ stronie postaci na
  wysokości łokcia. Początek przedramienia skierowany na zewnątrz,
  koniec ku brzuchowi. Łokieć przy boku, zgięty 90°, bez ręcznika
  niewymaganego w tym opisie. Nie zamieniać kotew między ćwiczeniami.
- `cw087–cw088`: stój obunóż, jedna robocza gałąź do jednego uchwytu;
  lewa ręka pusta i opuszczona. Ruch z rotacji ramienia, nie wyprostu
  łokcia, zginania nadgarstka lub obracania tułowia.
- `cw089`: stój, dwa niewielkie odrębne hantle. Rotacja przy wysokich
  łokciach jest ruchem ramienia/przedramienia, nie załamywaniem nadgarstków.
- `cw090`: lewy bok na podłodze, nogi ułożone jedna na drugiej, kolana
  mogą być lekko ugięte. Dolna lewa ręka bez ciężaru podpiera głowę;
  szyja neutralna. Jeden hantel w prawej dłoni, prawy łokieć przy
  tułowiu zgięty 90°, w tym samym miejscu w obu fazach.

## Kontrakt wizualny

Nowe źródła PNG 1024×1024; finalne zasoby WebP 512×512 na każde ID.
Wzorzec `assets/exercises/cw256.webp`: kremowe tło, komiksowy kontur,
ciemny strój i twarz bez rysów. Bez tekstu, numerów, strzałek, timerów,
watermarków, duchów ruchu i zbędnego sprzętu. Nakładki mięśni nie są wymagane.

Całe ciało, dłonie, stopy i istotny sprzęt mieszczą się z marginesem,
również w najszerszej/najwyższej fazie. Ta sama kamera i skala dla danego
ID, stałe podłoże, stopy i kotwy. W rotacjach szczególnie śledzić
niezmienne podparcie łokcia oraz kąta jego zgięcia; nie wymagać
pikselowo identycznych konturów obracających się przedramion lub ciężarów.

Gumy ciągłe i napięte, z rzeczywistymi zamkniętymi chwytami i neutralnymi
nadgarstkami. Ukośny/horyzontalny odcinek może przebiegać w PIERWSZYM
planie przed tułowiem. Samo nakładanie na sylwetkę, również w face pull,
nie dowodzi przenikania. Trasa musi być przestrzennie wyjaśniona i czytelna:
kotwa → roboczy odcinek → uchwyt → właściwa dłoń, bez wchodzenia w ciało
lub niewytłumaczonego znikania. Nie scalać gumy z konturem twarzy/szyi.

W hantlach odrębne głowice i rękojeści, po jednym rzeczywistym chwycie
na ciężar. Kciuki nie muszą być oderwane od zamkniętego chwytu.
Odczytać źródła, podglądy 512 px i finalne WebP; reuse cw086 również
podlega kontroli treści, wymiarów i identyczności kopii.

## Sceny i odrzucenia

### cw085 — Face pull — 2 kadry

Lewy: ramiona wydłużone ku przedniej kotwie na poziomie oczu, dwa chwyty,
stabilny tułów. Prawy: dłonie rozdzielone po bokach górnych policzków,
łokcie ugięte i szeroko nieco ponad nadgarstkami, rotacja zewnętrzna,
łopatki zbliżone, szyja i tułów bez zmiany.
Odrzucić kotwę ponad głową, chwyt złączony, ciągnięcie do brody/brzucha,
shrug, brak zgięcia łokci, przerwane gałęzie lub faktyczne przenikanie.

### cw086 — Pull-apart — 2 kadry, reuse cw055

Lewy: proste ramiona przed klatką, dłonie trzymają jedną lekko napiętą
gumę na szerokość barków. Prawy: ramiona szeroko na boki na poziomie
klatki, łokcie nadal proste, guma między dłońmi przed tułowiem.
Bez kotwy zewnętrznej. Odrzucić zgięcie łokci, shrug, ucięte dłonie,
zmianę czasu poprzez napisy. Potwierdzić istniejący cw055 spełnia te kryteria.

### cw087 — External rotation — 2 kadry

Lewy: prawa górna część ramienia przy boku, łokieć 90° z ręcznikiem,
przedramię przed brzuchem ku lewej kotwie, guma napięta.
Prawy: przedramię obrócone na zewnątrz w prawo, łokieć nadal przy
boku i 90°, ten sam ręcznik, kotwa, stój i pusty lewy chwyt.
Odrzucić lewą rękę roboczą, kotwę po prawej, unoszenie całego ramienia,
wyprost/uginanie łokcia jak curl, obrót tułowia lub brak ręcznika.

### cw088 — Internal rotation — 2 kadry

Lewy: prawy łokieć przy tułowiu 90°, przedramię skierowane na zewnątrz
w stronę prawej kotwy. Prawy: przedramię obrócone ku brzuchowi przeciw
napięciu gumy, bez zmiany łokcia, podpór i tułowia.
Odrzucić kotwę po lewej, lewą rękę, ruch jak cw087, skręt ciała,
unoszenie łokcia, wyprost łokcia, przerwę między uchwytem i dłonią.

### cw089 — Cuban press — 4 kadry w siatce 2×2

1. Dwa hantle przy udach, ramiona opuszczone, nachwyt, stabilny stój.
2. Upright row: łokcie wysoko na poziomie barków, przedramiona/hantle
   poniżej łokci, bez wzruszenia barków.
3. Rotacja w górę: łokcie nadal wysoko i około 90°, przedramiona pionowo
   do góry, hantle nad łokciami w okolicy uszu, dłonie do przodu.
4. Obustronne wyciskanie nad głowę, ramiona wydłużone bez przeprostu.
Powrót w odwrotnej kolejności pozostaje w opisie katalogowym.
Odrzucić zwykły overhead/Arnold press bez faz 2–3, obrót samych ciężarów,
skręcone nadgarstki, brak hantla, zmianę kamery, kip lub ucięte głowice.

### cw090 — Side-lying external rotation — 2 poziome pasy

Góra: lewy bok podparty na podłodze, głowa na dolnym ramieniu, jeden
hantel w górnej prawej dłoni. Prawy łokieć przy prawym boku 90°,
przedramię w początkowej pozycji przy brzuchu.
Dół: prawe przedramię obrócone ku górze z hantlem, łokieć i górna część
ramienia nadal przy boku, bez obracania tułowia lub unoszenia barku.
Odrzucić leżenie na plecach/brzuchu, lewą rękę roboczą, dwa hantle,
odrywanie łokcia, biceps curl/row zamiast rotacji, zmianę boku lub podpór.

## Prompty i kontrakt reuse

Nowe prompty: wspólny blok + odpowiednia scena, pierwsza referencja
stylu `/tmp/opencode/cw256-reference.png`. Cw086 domyślnie bez wywołania API.

### Blok wspólny

```text
Use supplied image ONLY as STYLE reference. Square1024x1024, cream background, clean dark comic outlines, faceless adult in dark neutral clothes. Whole body, BOTH hands/feet and essential equipment inside every frame with generous margins. SAME camera/scale/floor/fixed supports across phases. Coherent anatomy, real connected grips, neutral wrists/neck and controlled spine. Natural partial occlusion/foreground overlap allowed only when route and limb/equipment continuity remain clear at512px; no physical penetration or floating grips. No text, labels, numbers, arrows, timer, watermark, ghosts or extra figures. No required muscle overlays.
```

### cw085

```text
STANDING BAND FACE PULL, EXACTLY TWO SIDE-BY-SIDE PANELS LEFT TO RIGHT, SAME front-side three-quarter view. ONE band midpoint attached to visible fixed support IN FRONT at EYE HEIGHT, NOT above head; two taut branches to two real hand grips. LEFT arms extended toward anchor. RIGHT separate grips beside upper cheeks, elbows BENT/WIDE and slightly HIGHER than wrists, external shoulder rotation, controlled scapular retraction. Same grounded stance/torso/neck. Trace both branches logically in front of adult; explained foreground overlap alone is not penetration, never merge rubber with face/neck contour. No chin/abdomen pull, joined grips, shrug, overhead anchor, disconnected branches or labels.
```

### cw086 — kontrakt kopii, nie płatny prompt

```text
Reuse assets/exercises/cw055.webp unchanged as assets/exercises/cw086.webp after content review. Require TWO panels, unanchored band at chest height, both elbows straight, forward arms→wide pull-apart, full body/hands, no text/timer. Preserve original file and verify identical bytes,512x512 WebP. Catalog ID/name/tempo remain distinct; do not map by exercise name or regenerate by default.
```

### cw087

```text
RIGHT-ARM BAND EXTERNAL ROTATION, EXACTLY TWO SIDE-BY-SIDE PANELS LEFT TO RIGHT, fixed front-side three-quarter camera. ONE taut band from visible fixed anchor on anatomicalLEFT side of adult at ELBOW HEIGHT to real handle in RIGHT HAND. Both feet grounded, LEFT hand empty/down. RIGHT upper arm and elbow pinned gently at side with SMALL ROLLED TOWEL BETWEEN ELBOW AND TORSO, elbow angle stays90degrees. LEFT panel forearm across front of abdomen toward left anchor. RIGHT panel forearm rotates OUTWARD to anatomicalRIGHT, around same upper-arm axis, NOT elbow extension/curl. Same towel/elbow/torso/feet/anchor, wrist straight. Continuous band in front of body, no physical penetration, torso rotation, shoulder lift, opposite arm/anchor or lost towel.
```

### cw088

```text
RIGHT-ARM BAND INTERNAL ROTATION, EXACTLY TWO SIDE-BY-SIDE PANELS LEFT TO RIGHT, fixed front-side three-quarter camera. ONE taut band from visible fixed anchor on anatomicalRIGHT side of adult at ELBOW HEIGHT to real handle in RIGHT HAND, other hand empty/down, both feet grounded. RIGHT elbow at side stays90degrees. LEFT panel forearm outward toward right anchor. RIGHT panel rotate forearm INWARD across front toward ABDOMEN against band tension, not outward. Same elbow/upper arm/torso/feet/anchor, neutral wrist, logical continuous foreground band route. No elbow lifting/extension/curl, torso twist, opposite hand/anchor, shoulder shrug or disconnected grip. No towel required.
```

### cw089

```text
STANDING DUMBBELL CUBAN PRESS, EXACTLY FOUR panels in2x2 GRID, read TOP-LEFT→TOP-RIGHT→BOTTOM-LEFT→BOTTOM-RIGHT without labels/arrows. SAME front-side three-quarter camera, adult scale, hip-width feet and braced body throughout. TWO separate modest dumbbells, one real handle grip per hand. TOP-LEFT weights at thighs, arms down, pronated grip. TOP-RIGHT upright-row endpoint: elbows at shoulder height, forearms/weights BELOW elbows, no shrug. BOTTOM-LEFT rotate BOTH forearms UP about upper-arm axes: elbows remain shoulder-level and bent90degrees, forearms VERTICAL UP, weights over elbows near ears, palms forward, wrists straight. BOTTOM-RIGHT press both overhead with long arms/no hyperextension. No wrist twisting, weight-only rotation, skipped row/rotation stage, Arnold sequence, leg drive, back arch, merged or cropped weights.
```

### cw090

```text
SIDE-LYING RIGHT-ARM DUMBBELL EXTERNAL ROTATION, EXACTLY TWO FULL-WIDTH HORIZONTAL ROWS TOP TO BOTTOM, SAME front-side three-quarter camera. Adult on LEFT SIDE on floor, legs stacked/knees mildly bent, empty lowerLEFT arm supports head with neutral neck. ONE short dumbbell in upperRIGHT hand, real handle grip/neutral wrist. RIGHT upper arm at torso and elbow bent90degrees in BOTH rows. TOP forearm near abdomen. BOTTOM rotate forearm and dumbbell UP toward ceiling about same upper-arm axis while elbow stays at right side, no elbow lift or body roll. All supports stable, no supine/prone pose, opposite arm, second dumbbell, bicepscurl/row, shoulder shrug, clipped weight or floating grip.
```

## Przyszłe wykonanie i weryfikacja

Po zatwierdzeniu przygotować plan. Aktualny main w `/opt/fit`, bez
worktree; zachować niewydane Partie 07–18 i przeczytać `docs/modules/training.md`.

1. Dopisać cw085–cw090 po cw084 przed cw251 do oczekiwań testu; fallback
   cw091. Potwierdzić czerwony brak cw085 przed zmianą rejestru i assetów.
2. Przejrzeć pięć promptów oraz kontrakt kopii cw086: zgodność, następnie
   geometria/klarowność, w tym strona i kierunek oporu,90°łokcie, ręcznik,
   kolejność Cuban press i górna ręka przy leżeniu bokiem.
3. Pięć nowych żądań osobno w świeżych cwNNN-trial-NN przez
   `tools/benchmark_exercise_images.py --single-sunburst-medium`.
   Odczyt PNG/podglądu512 przed następnym żądaniem, bez sekretów w logach.
   Po błędzie/niepewności odczytać ledger, bez automatycznego retry.
4. Korekta tylko nazwanego defektu, ostatni odrzucony PNG jako jedyna
   referencja. Po dwóch nieskutecznych korektach tego samego problemu
   zatrzymać próby i ocenić nową kompozycję przed dalszym płatnym działaniem.
5. Po akceptacji pięciu źródeł i ponownym odczycie cw055: nowe WebP przez
   `-resize 512x512 -strip -quality 90`, lokalna kopia cw055→cw086,
   sprawdzenie identyczności kopii, odczyt wszystkich sześciu finalnych
   assetów i dopisanie tych samych ID do illustratedExerciseIds.
6. Pełny Docker target verification: wersja/analiza/testy,156zgodnych ID/
   plików, dekodowanie512×512, fallbackcw091; formatowanie Dartów i
   git diff --check. Bez zmiany katalogu/modeli/zależności/Web SQLite.
7. Status156/78/78/160/316, kadry2/2/2/2/4/2, sekcja „Dziewiętnasta partia”.
   Odnotować reuse cw086 i zero żądań dla niego, rzeczywiste źródła,
   przeglądy, korekty i deduplikowane sukcesy ledgerów, błędy z nieznanym kosztem
   osobno. Po limicie subagentów kontrola bezpośrednia, bez udawania
   niezależnego review. Produkcja nadal1.9.0+22, Git/publikacja tylko osobno.

## Samokontrola projektu

- Sześć kolejnych ID, pięć nowych źródeł i jedna jawna kopia wcześniej zatwierdzonej grafiki.
- Cw085 uwzględnia wymagany poziom oczu; cw086 nie wymaga nowej generacji dla tempa.
- Cw087/cw088: ta sama ręka, przeciwne kierunki ruchu i odpowiednie strony kotew.
- Łokieć90° i stały tułów odróżniają rotację od curl/row; ręcznik jawnie w cw087.
- Cuban press cztery uporządkowane etapy; side-lying lewy bok/prawa ręka i jeden hantel.
- Kadry i docelowe liczniki spójne; stan wejściowy wynosił 150 ilustracji.

## Wykonanie — 2026-10-14

Sześć WebP 512×512 lokalnie zintegrowanych i niewydanych; kadry 2/2/2/2/4/2.
Cw086 jest identyczną kopią cw055, cmp potwierdza bajty, zero API.
Nowe źródła: correction-02 cw085, correction-01 cw087/cw088/cw089,
trial-01 cw090; pliki wraz z promptami, podglądami i ledgerami w /tmp/opencode.
Naprawiono łokcie face pull, strony kotew i ciągłość forearm/grip w
rotacjach oraz fazę obrotu przedramion Cuban press przy wysokich łokciach.
Warianty i układy zachowano, bez zmiany katalogu lub starszych ilustracji.

Bezpośredni odczyt źródeł/podglądów/finalnych WebP, zgodność potem jakość;
bez niezależnych subagentów ze względu na wcześniej osiągnięty limit.
10 unikalnych udanych żądań, bez HTTP error, upper_bound_no_cache
0,226785 USD; odczyt success ledgerów z różnymi request_id, nie faktura dostawcy.
Docker batch-19-verified: 366 testów zaliczonych, analiza bez uwag,
formatowanie 0 zmian; 156 zgodnych plików/rejestru/oczekiwań, fallback cw091.
Stan 156 lokalnych / 78 wydanych / 78 niewydanych / 160 brakujących /
316 ćwiczeń; produkcja 1.9.0+22, bez commita/pusha/wdrożenia.
