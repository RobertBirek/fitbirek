# Ilustracje ćwiczeń — projekt Partii 27

## Zakres i stan wejściowy

Projekt zatwierdzony przez użytkownika 2026-10-15: `cw133–cw138`
z `assets/data/exercises.json`, kadry3/4/2/3/2/2, w tym asysta gumą cw138.
Stan wejściowy: 198 lokalnych ilustracji = 78 wydanych + 120 niewydanych
z Partii 07–26; 118 brakujących na 316 ćwiczeń. Po integracji szóstki:
204 lokalne = 78 wydanych + 126 niewydanych; 112 brakujących.
Produkcja pozostaje `1.9.0+22`. Etap projektu bez płatnych żądań oraz bez
zmian assetów/rejestru/testów. Zachować katalog, ID i wszystkie wcześniejsze pakiety.

## Podejścia i rekomendacja

1. **Rekomendowane: sześć nowych źródeł, kadry 3/4/2/3/2/2.**
   Curtsy pokazuje kierunek kroku przed zejściem. Cztery sceny rotacyjnych
   wykroków odróżniają skręt od przejścia do następnej nogi. Zwykły step-up
   ma dwa końce ruchu, knee drive dodatkową fazę uniesienia kolana.
   Pistol i assisted pistol po dwa końce ruchu z tą samą nogą podporową.
2. Dwa kadry dla każdego ID: większa sylwetka, lecz utrata kierunku kroku,
   rozróżnienia rotacji i części wejście→knee drive. Szczególnie cw134
   może wtedy przypominać dwa niepowiązane wykroki.
3. Cztery–pięć scen również dla wejść/pistoli: nadmiar sylwetek i mniejsza
   czytelność chwytów przy512px. Nie dodawać osobnego holda z timerem.

Brak reuse. Wcześniejsze split squaty/wykroki nie pokazują skrzyżowania
nogi, rotacji tułowia, wejścia na podest ani pozycji pistol. Nie kopiować
cw128: grzbiet tylnej stopy na ławce nie jest pełną stopą roboczą step-up.

## Kadry i warianty

| ID | Ćwiczenie | Kadry | Wariant i kolejność |
|---|---|---:|---|
| cw133 | Zakroki skrzyżne z hantlami | 3 | Stój → lewa stopa w tył i za prawą, wysoko → zejście; prawa stopa kotwicząca. |
| cw134 | Wykroki chodzone z rotacją tułowia i hantlami | 4 | Niski wykrok prawą bez skrętu → skręt ku prawej → wznos/przejście lewej bez skrętu → niski wykrok lewą ze skrętem ku lewej. |
| cw135 | Wchodzenie na ławkę z hantlami | 2 | Pełna prawa stopa na ławce, lewa na podłodze → stój obiema stopami na siedzisku. |
| cw136 | Wchodzenie na ławkę z uniesieniem kolana i hantlami | 3 | Prawa stopa na ławce → wyprost na prawej, lewa noga wolna nisko → lewe kolano wysoko. |
| cw137 | Przysiad na jednej nodze z drugą wyprostowaną w przód | 2 | Prawa noga podporowa, lewa prosta w przód i wolna; wysoka pozycja → głęboki pistol, ramiona w przód. |
| cw138 | Przysiad na jednej nodze z drugą wyprostowaną w przód z podparciem | 2 | Jak cw137, lecz obie dłonie trzymają uchwyty gumy z wysoką kotwą przed ciałem. |

Cw133: trzy poziome pasy od góry do dołu. Cw134: siatka2×2,
czytana górny lewy→górny prawy→dolny lewy→dolny prawy. Cw135: dwa poziome
pasy; cw136: trzy poziome pasy. Cw137–cw138: po dwa poziome pasy,
aby pomieścić wyprostowaną nogę i ramiona bez zmniejszania osobno dolnej fazy.

### Jawne interpretacje

- **Cw133:** lewa noga cofa się po skosie za prawą; prawa pełna stopa
  pozostaje nieruchoma. Kierunek skrzyżowania widoczny z przodu3/4:
  lewa stopa kończy za prawą i nieco po jej prawej stronie anatomicznie,
  a nie w zwykłym rozkroku w tył. Tylne kolano schodzi w dół, nie dotyka
  podłogi. Prawa pięta podparta, prawe kolano śledzi własne palce;
  nie imitować dygnięcia zapadnięciem przedniego kolana do środka.
  Dwa hantle neutralnie przy bokach, ramiona długie.
- **Cw134:** dwa odrębne małe hantle, po jednym w każdej dłoni, trzymane
  PRZED klatką na ugiętych łokciach. Nie zmieniać liczby ciężarów na
  pojedynczy goblet/medball. Naturalny mały odstęp między ciężarami,
  stabilne nadgarstki; ręce i hantle podążają za skrętem klatki.
  Rzeczywista rotacja obręczy barkowej/tułowia ku nodze prowadzącej,
  nie sam obrót głowy lub przerzucenie ciężarów przy nieruchomej klatce.
  W dwóch pierwszych kadrach podpory wykroku prawego nie zmieniają miejsc.
  Trzecia faza pokazuje wyprost i przeniesienie lewej nogi z rozkręceniem
  tułowia, czwarta kolejny lewy wykrok dalej w przód ze skrętem ku lewej.
  Stopy i kolana nie obracają się razem z barkami; miednica kontrolowana,
  rotacja umiarkowana, bez wymuszania dużego skrętu lędźwiowego.
- **Cw135:** jedna stabilna ławka/podest o siedzisku wystarczającym dla obu
  stóp, wysokość w dolnej pozycji daje zgięcie prawego kolana około90°.
  Pełna prawa stopa spoczywa na siedzisku od pierwszej fazy do końca.
  Lewa w górnej fazie dochodzi na siedzisko obok prawej, bez knee drive.
  Pokazujemy końce wejścia; obraz nie dowodzi braku odbicia lub rozkładu sił.
  Kontrolowane zejście opisuje katalog, bez dodatkowej fikcyjnej pauzy.
- **Cw136:** ta sama prawa noga robocza i pełna stopa na ławce. W fazie2
  prawa noga prawie wyprostowana, lewa już wolna od podłogi i nisko,
  nie staje na ławce. Faza3: uniesione LEWE kolano, uda lewej nogi około
  poziomu, prawe kolano bez przeprostu, ciało w równowadze. Bez zamiany
  nóg lub chwilowego przeniesienia podpory na lewą. Pauza1sek w katalogu,
  nie w timerze. Dwa hantle przy bokach w całej sekwencji.
- **Cw137:** prawa noga podporowa z piętą i przodem stopy na ziemi,
  lewa noga prosta w przód, palce/stopa nie podpierają się w żadnej fazie.
  Wysoka pozycja: lewa noga uniesiona tylko na tyle, aby stopa była wolna;
  nie wymagać jej poziomego utrzymania przy wyprostowanej podporowej.
  Głęboki dół: biodra nisko blisko prawej pięty, lewa noga wyprostowana
  w przód z prześwitem nad ziemią, obie ręce w przód. Naturalny skłon
  tułowia i wysunięcie podporowego kolana są potrzebne dla równowagi;
  nie wymuszać pionowego tułowia/pionowej goleni kosztem oderwania pięty.
  Brak ławki, ciężarów, gumy lub podpory dłonią o nogę/podłoże.
- **Cw138:** wybrano GUMĘ spośród dopuszczonych gumy/drążka. Jedna widoczna
  wysoka zewnętrzna kotwa przed ciałem, jedna guma zamocowana środkiem
  i dwie napięte gałęzie do uchwytów w dłoniach. Uchwyty przed klatką,
  mogą obniżać się wraz z ciałem, ale nie ślizgają się po materiale.
  Guma wydłuża się w dolnej pozycji; ta sama kotwa i fizyczna ciągłość
  obu gałęzi. Pomaga równowadze, nie zastępuje podparcia prawej stopy;
  bez odchylenia w tył i wiszenia całym ciężarem na rękach.
  Prawa noga podporowa, lewa prosta i wolna, jak cw137.

## Kontrakt wizualny

Styl cw256: kremowe tło, komiksowy kontur, ciemny strój, twarz bez rysów.
Źródłowy PNG1024×1024, finalny WebP512×512 przez
`-resize 512x512 -strip -quality 90`. Bez napisów, cyfr, strzałek,
timerów, watermarków i duchów ruchu. Nakładki mięśni nie są wymagane.

Całe ciało, obie dłonie/stopy i istotny sprzęt z marginesem w każdym kadrze.
Ta sama kamera/skala/podłoże w ramach ID. Nie zmniejszać osobno kadrów
z długą wyprostowaną nogą lub stojącą postacią na ławce. Zostawić zapas
miejsca nad postacią w wysokim step-up. Sprzęt i podparcia nie zmieniają
wysokości między fazami. Zamierzony krok może zmieniać pozycję stóp;
stopa kotwicząca nie przesuwa się. Delikatne nieopisane szwy podłogi
dopuszczalne jako odniesienie, bez strzałek lub markerów z numerami.

Każdy hantel ma własną krótką rękojeść i dwie głowice; dwie rzeczywiste
dłonie obejmują dwa uchwyty. Chwyt oceniać z dłoni/przedramion, nie osi
ciężarów. Tylko cw135/cw136 mają ławkę, tylko cw138 gumę, cw137 bez sprzętu.
Okluzja naturalna dopuszczalna przy czytelnej ciągłości512px, nie samotny
talerz zamiast dalszej dłoni. Bez skracania ramion dla prześwitu sprzętu.

## Sceny i kryteria odrzucenia

### cw133 — Curtsy lunge

Trzy poziome pasy, stały przedni3/4 widok odsłaniający skrzyżowanie nóg.
Góra: stój z dwoma hantlami przy bokach. Środek: prawa stopa nadal
w miejscu, lewa cofa się i przechodzi za prawą po skosie, biodra wysoko.
Dół: zejście na prawej, lewe kolano nisko z boku/za podporową nogą,
lewe przodostopie na podłodze, prawa pięta podparta.

Odrzucić zwykły reverse lunge bez skrzyżowania, krok przed prawą nogę,
zmianę nogi roboczej, przesunięcie prawej stopy, valgus prawego kolana,
skręt podporowej stopy, kolano na podłożu, brak ciężaru lub upadek tułowia.

### cw134 — Walking lunge with twist

Cztery kadry2×2, stała kamera przednia z lekkim3/4 i pełne sceny.
1: niski prawy wykrok, klatka i hantle na wprost.
2: te same stopy/niski wykrok, barki/klatka/dłonie skręcone ku prawej nodze.
3: wyjście w górę, klatka wraca na wprost, lewa noga przechodzi w przód.
4: następny niski lewy wykrok dalej w przód, skręt klatki ku lewej nodze.
Górna pozycja3 nie może mieć mniejszej skali. Dwie niezależne sztangielki
przed klatką w czterech scenach, nie przy bokach lub nad głową.

Odrzucić sam obrót głowy, skręt ku tylnej nodze, ruch tylko rąk,
obracanie kolan/stóp razem z barkami, brak postępu, tę samą nogę w obu
wykrokach, odbicie całej postaci lub utratę jednego hantla.

### cw135 — Step-up

Dwa poziome pasy, stała przednio-boczna kamera pokazująca oba chwyty,
całą prawą stopę na ławce i lewą nogę. Góra: prawa stopa na siedzisku,
prawe kolano około90°, lewa stopa na podłodze za/obok ławki.
Dół: biodra uniesione, prawa noga wyprostowana, lewa stopa dostawiona
na siedzisko. Ławka w tym samym miejscu, dwie stopy mieszczą się na niej.
Dwa hantle neutralnie przy bokach, ramiona długie i wolne od ławki.

Odrzucić podparcie tylko palcami/połową prawej stopy, zmianę wysokości
ławki, nogę wolną w górze jak knee drive, odbicie z obiema stopami w powietrzu,
zamianę nóg, chwyt bez połączenia z przedramieniem i uciętą głowę.

### cw136 — Step-up with knee drive

Trzy poziome pasy, ta sama kamera/ławka i zapas miejsca nad głową.
Góra: pełna prawa stopa na siedzisku, lewa na podłodze.
Środek: wyprost na prawej, lewa stopa wolna nisko, bez kontaktu z siedziskiem.
Dół: lewe kolano uniesione do około wysokości biodra, prawa pełna stopa
nadal jedyną podporą na ławce. Ciało nad podporą, dwa hantle przy bokach.

Odrzucić prawą stopę przesuniętą/na krawędzi, lewe podparcie w fazie2/3,
kolano drive z prawej nogi, skok zamiast wejścia, pochylenie w bok,
zmianę skali/ławki, brak ciężaru lub timer pauzy.

### cw137 — Pistol squat

Dwa poziome pasy, widok boczny3/4 od prawej strony pozwalający ocenić
piętę podporową i prześwit lewej stopy. Góra: wysoka pozycja na prawej,
lewa noga prosta przed ciałem i wolna, ramiona wyprostowane w przód.
Dół: głęboki przysiad na prawej, biodra nisko przy pięcie, lewa noga nadal
prosta przed ciałem, nie dotyka podłoża. Prawa pełna stopa w tym samym miejscu.

Odrzucić dwunożny przysiad, skater squat z lewą nogą w tył/ugiętą,
oparcie lewej pięty lub dłoni na podłodze, oderwaną prawą piętę,
ławkę/ciężar/gumę, skrócone kończyny i sztucznie pionowy tułów bez równowagi.

### cw138 — Band-assisted pistol squat

Dwa poziome pasy, stały boczny3/4 widok pokazujący gumę przed postacią
i prawą stopę podporową. Góra: wysoka pozycja z prostą wolną lewą nogą,
obie dłonie na dwóch uchwytach, guma już lekko napięta od wysokiej kotwy.
Dół: głęboki prawy pistol, lewa prosta nad podłożem, gałęzie wydłużone
i napięte, prawy pełny kontakt stopy zachowany. Uchwyty mogą podążać za
wysokością klatki, kotwa stała. Naturalny skłon w przód zamiast wiszenia w tył.

Odrzucić gumę pod stopą/na biodrach zamiast w dłoniach, brak mocowania,
luźne gałęzie, przechodzenie przez szyję/ciało, skrócenie gumy podczas
schodzenia, podparcie wolną nogą, oderwaną piętę, box pistol lub chwyt drążka
zamiast wybranego wariantu z gumą.

## Sześć promptów bazowych

Dokładny prompt to blok wspólny plus odpowiednia scena. Pierwsza referencja
stylu `/tmp/opencode/cw256-reference.png`. Prompty, źródła, podglądy i ledgery
pozostają poza repozytorium w /tmp/opencode.

### Blok wspólny

```text
Use supplied image ONLY as STYLE reference. Square1024x1024, cream background, clean dark comic outlines, faceless adult in dark neutral clothes. Exact panels/layout as specified. Entire body, BOTH hands/feet and ONLY scene-required equipment fit EVERY panel with margins. SAME camera/scale/floor/fixed equipment across phases, no per-phase zoom. Coherent anatomy, real connected closed grips, stable loaded wrists, controlled spine. Each dumbbell has ONE short handle and TWO heads; count two only in dumbbell scenes133-136, no dumbbells137-138. Bench ONLY135-136, resistanceband ONLY138. Natural partial occlusion only with clear limb/equipment continuity at512px. No text,numbers,arrows,timers,watermarks,ghosts or extrafigures. No required muscle overlays. Rep counts, tempo and pauses remain in catalog; static images do not prove force distribution or elapsed time.
```

### cw133

```text
RIGHT-SUPPORT CURTSY LUNGE with TWO SIDE-HELD dumbbells, EXACTLY THREE FULL-WIDTH HORIZONTAL BANDS TOP TO BOTTOM, fixed FRONT3/4 view revealing legcrossing. TOP uprightstand,feet hipwidth,DBs neutral atSIDES,longarms. MIDDLE RIGHT fullsole stays at original flooranchor; LEFT foot steps BACK and DIAGONALLY BEHIND RIGHT to anatomicalRIGHT side of it,hips stillHIGH. BOTTOM bendRIGHTsupportleg,lowerLEFTrearknee down/sideways nearfloor withoutcontact,LEFTforefoot behindcrossed,RIGHT heel/fullsolegrounded. SAME rightfoot all3,LEFTcrossed contact same middle/bottom,frontknee tracks OWN toes not valgus. Controlledpelvis/trunk,realhip-knee-foot connections,weightsAIR clearlegs. No ordinaryreversewithoutcross,stepinfront,sidechange,frontfootpivot,groundedknee,bodymirror,bench or labels/arrows.
```

### cw134

```text
WALKING LUNGE WITH TORSO TWIST, EXACTLY FOUR panels in2x2 GRID read TOPLEFT→TOPRIGHT→BOTTOMLEFT→BOTTOMRIGHT. SAME front/slight3/4 camera/physical scale/floor, wholebody and TWO SMALL dumbbells visible EACH scene. TWO separate real closed handlegrips,weights held BEFORE CHEST with bentelbows/smallgap,not sideheld/goblet/medball. TOPLEFT LOW RIGHT-LEG-FORWARD lunge,torso/weights faceforward. TOPRIGHT SAME LOW stance/footcontacts but ROTATE RIBCAGE/SHOULDERS/hands/weights toward FRONT RIGHT LEG,not merely head/arms;pelviscontrolled,knees/feetdoNOTpivot. BOTTOMLEFT rise overRIGHTfoot,LEFTlegpassesFORWARD,torsoUNTWISTS toneutral,not resetback,NO shrinkmiddlepose. BOTTOMRIGHT NEXT LOW LEFT-LEG-FORWARD lunge FARTHER along path,torso/shoulders/weights rotate toward FRONT LEFT LEG. Alternatelegconnections,forwardprogression relative faintUNLABELLEDfloorseam,samecamera not mirroredfigure. Bothweights remain infrontofchest followingtrunk,moderaterotation/neutralwrists,nobacktwistcollapse. No rearleg-directedtwist,headonlyturn,sameleadlegtwice,missingweight,text/arrows/ghosts.
```

### cw135

```text
RIGHT-LEG DUMBBELL STEP-UP, EXACTLY TWO FULL-WIDTH HORIZONTAL BANDS TOP TO BOTTOM, SAME front-side3/4 view revealing BOTH grips/wholeRIGHTsole and platform. ONE stablebench with seat wideenough forBOTH feet,topheight gives RIGHT knee about90 instart. TOP RIGHT FULL FOOT atopseat,LEFT foot onFLOOR,bracedtorso,TWO compactDBs NEUTRAL atSIDES,longarms. BOTTOM rise byRIGHTleg to tallstand atopbench,LEFT foot JOINS besideRIGHT onseat,no kneelift. RIGHTsole remains SAME seatspot,benchheight/location/camera/scale unchanged. Naturalcontrolledspine,kneestracktoes,weightsAIR clearbench/body. Leave generousheadroom for standingabovebench,don't shrinkupperpose. No toes-onlyrightcontact,changingbenchheight,jump/bothfeetairborne,kneedrive,sidechange,missingfargrip,labels/arrows/text. Illustration shows endpoints,not measured legforce.
```

### cw136

```text
RIGHT-LEG STEP-UP WITH LEFT KNEE DRIVE and TWO SIDE-HELD dumbbells, EXACTLY THREE FULL-WIDTH HORIZONTAL BANDS TOP TO BOTTOM, SAME front-side3/4 camera/scale/stablebench. TOP RIGHT fullsole atopbench,RIGHTkneebentabout90,LEFT foot onfloor. MIDDLE extendRIGHTleg to tall SINGLE-LEG support on SAME seatspot,LEFTfoot now FREE LOW belowhip,NEVER joinsseat. BOTTOM drive LEFT KNEE UP to aboutHIPHEIGHT/leftthigharoundhorizontal while RIGHTfullsole still ONLY support atopbench,rightknee nohyperextension. Samebodyorientation/benchheight/footanchor,twoDBneutralgrips atSIDES,longarms/lowshoulders,weights clearbody/bench. Trunkbalancedoverrightsupport,not jump. Fullbody/freefoot/weights inside EACH band with generousTOPmargin,NO pose-specificzoom. No sidechange,RIGHTkneedrive,LEFTfootseatcontact inmiddle/bottom,toes-onlysupport,leanfall,missinggrip,timer/text/arrows.
```

### cw137

```text
BODYWEIGHT PISTOL SQUAT on RIGHT supportleg, EXACTLY TWO FULL-WIDTH HORIZONTAL BANDS TOP TO BOTTOM, same RIGHT-SIDE3/4 view exposing heel and freefootgap. NO equipment. TOP tallRIGHTsinglelegstand,LEFTleg STRAIGHT extendedFORWARD with footAIR (neednot horizontalhigh),BOTH armsstraightFORWARD forbalance. BOTTOM slowlydeepRIGHTsinglelegsquat,hips low nearRIGHTheel,LEFTleg remainsSTRAIGHT FORWARD with clearairgapabovefloor,BOTH armsforward. RIGHT HEEL and FOREFOOT stay on SAME floorcontact inboth. Naturalforwardtorsolean/ankledorsiflexion/frontkneeovertoes allowed forbalance,not artificialuprighttrunk/verticalshin. Coherent fullleglength,wholebody/BOTH handsfeet fit samecamera/scale/margins. No leftheeltoe support,handonground/leg,skatersquatbentfreeleg,heelraise,bench/box/weight/band,valgus,fallingback,text/arrows/ghosts.
```

### cw138

```text
BAND-ASSISTED RIGHT-LEG PISTOL SQUAT, EXACTLY TWO FULL-WIDTH HORIZONTAL BANDS TOP TO BOTTOM, same SIDE3/4 camera showing RIGHTsupportsole/freeLEFTleg and visible HIGH EXTERNAL ANCHOR IN FRONT ofperson. ONE resistanceband secured atmiddle tofixedanchor,TWO tautbranches to TWO realhandles in BOTH hands beforechest. TOP highRIGHTsinglelegstand,LEFTlegSTRAIGHTFORWARD/footAIR,bandalreadymildlytaut. BOTTOM deepRIGHTpistol,hipsnearheel,LEFTlegstillSTRAIGHTFORWARD/clearfloor,bothhandlesfollowchestdown naturally,bandbranchesLONGER/TAUT,sameanchor. RIGHTfullsole/heel onSAME floorcontact inboth. NaturalFORWARD torsoinclination forbalance,modesthandassistance,NOT leanback/hangbodyfromband. Bothhands/grips/branches continuous OUTSIDE head/neck/body. No bandunderfoot/onhips,slack/brokenstrand,anchorchange,freefootfloorcontact,heelraise,box/bench,weights,polegrip insteadband,text/arrows/timer. Wholebody/equipment includinganchor inside margins,samecamera/scale.
```

## Planowane wykonanie po zatwierdzeniu

1. Zatwierdzić warianty i kadry, w tym dwa hantle przed klatką cw134,
   zwykły step-up z dostawieniem lewej stopy cw135 i gumę w cw138.
   Zapisać plan, bieżący main /opt/fit, zachować niewydane Partie07–26.
   Przeczytać AGENTS.md i docs/modules/training.md.
2. Test expectedIllustrationIds rozszerzyć o cw133–cw138 po cw132 przedcw251;
   fallbackcw139. Red brakującegocw133 przed integracją assetów/rejestru.
3. Sześć osobnych dokładnych promptów poza repozytorium. Kontrola
   zgodności→geometrii: skrzyżowany krok, rzeczywisty skręt tułowia,
   pełne stopy na ławce/stała wysokość, właściwe kolano drive,
   prawa pięta/luźna lewa noga w pistol i ciągłość gumy.
4. Żądania pojedynczo przez tools/benchmark_exercise_images.py
   --single-sunburst-medium, świeży katalog na próbę, sekrety ładowane
   z /root/.config/fit/openai.env bez drukowania. Odczytać źródłowyPNG
   i podgląd512px przed następnym żądaniem.
5. Korekty tylko nazwanych defektów, ostatni odrzuconyPNG jako jedyna
   referencja. Po dwóch nieskutecznych korektach tej samej wady zakończyć
   kompozycję i ocenić nowe ujęcie, kontynuując do poprawnego wyniku
   według polecenia użytkownika. Bez automatycznego retry po błędzie lub
   niepewności: odczytać ledger, zachować katalog, nieznany koszt osobno.
6. Po akceptacji szóstki konwersja WebP i odczyt finalnych plików,
   te sameID do illustratedExerciseIds. Kadry3/4/2/3/2/2, bez edycji
   katalogu, modeli, zależności i artefaktów WebSQLite.
7. Pełny Docker verification: wersja/analiza/komplet testów,204zgodneID/assety,
   dekodowanie512×512,fallbackcw139. Formatowanie dwóch Dartów i git diff --check.
8. Status204/78/126/112/316,sześćwierszy,sekcja „Dwudziesta siódma partia”.
   Zapisać rzeczywiste źródła/przeglądy/korekty i koszty tylko success,
   deduplikacja request_id,response_received bez ponownego liczenia.
   upper_bound_no_cache jest szacunkiem, nie rozliczeniem dostawcy.
9. Przeglądy bezpośrednie po wcześniejszym limicie subagentów; nie deklarować
   niezależnego review. Commit,push,wersja i wdrożenie na osobną prośbę.

## Samokontrola projektu

- Sześć kolejnychID, nazwy/technika katalogowa, bez reuse.
- Kadry3/4/2/3/2/2, grid2×2 tylko cw134, reszta poziome pasy.
- Cw133 odróżnione od reverse przez widoczne skrzyżowanie, nie valgus.
- Cw134 dwa ciężary z przodu, skręt ku przedniej nodze, rzeczywista klatka
  obraca się, przejście pokazuje postęp i zmianę prowadzącej nogi.
- Cw135 dwie stopy w finale na ławce, cw136 tylko prawa i lewe kolano drive.
- Cw137 bez sprzętu, cw138 z gumą, wolna prosta noga nigdy nie podpiera.
- Podparcie prawej pięty, naturalny skłon w pistol, bez fałszywego pomiaru sił/czasu.
- Liczniki198/78/120/118/316→204/78/126/112/316,fallbackcw139 spójne.
- Etap projektu bez żądańAPI i integracji.

## Wykonanie — 2026-10-15

Zintegrowano sześć WebP512×512 przez resize512/strip/quality90,
kadry3/4/2/3/2/2. **Końcowy układ cw136 zmieniono na trzy pionowe kolumny**
czytane od lewej do prawej, aby zmieścić rzeczywistą zmianę wysokości ciała
bez skracania kończyn. Pozostałe układy zgodne z projektem.

| ID | Zaakceptowane źródło | Przebieg |
|---|---|---|
| cw133 | /tmp/opencode/cw133-approved-aligned.png | Trial-01, lokalna sztywna translacja początkowej sceny o65px. |
| cw134 | /tmp/opencode/cw134-new-01 | Po odrzuconej pierwszej kompozycji nowe ujęcie frontalne. |
| cw135 | /tmp/opencode/cw135-new-correction-01 | Nowe ujęcie z poprawą proporcji i korektą ławki. |
| cw136 | /tmp/opencode/cw136-new-correction-02 | Nowe frontalne trzy kolumny, korekta ławki po wcześniejszych odrzuconych kompozycjach. |
| cw137 | /tmp/opencode/cw137-trial-01 | Pierwsza próba zaakceptowana. |
| cw138 | /tmp/opencode/cw138-correction-01 | Korekta wysokiej pozycji prawej nogi podporowej. |

Cw133 zachowuje prawą kotwiczącą stopę i skrzyżowany lewy krok;
wyrównano cały początkowy region, nie poszczególne kończyny:

```bash
convert /tmp/opencode/cw133-trial-01/cw133-gpt-image-2.5-sunburst-medium.png \( /tmp/opencode/cw133-trial-01/cw133-gpt-image-2.5-sunburst-medium.png -crop 959x365+0+0 +repage \) -geometry +65+0 -compose Over -composite /tmp/opencode/cw133-approved-aligned.png
```

Potwierdzono tożsamość RGB starego regionu0..958,0..364 z nowym65..1023,0..364
oraz całego y>=365; dolne sceny/linie podziału identyczne, zeroAPI dla operacji.
Odczytano wyrównany PNG i podgląd512px. Cw134 w nowej frontalnej kompozycji
realizuje zmianę prowadzącej nogi i skręt klatki we właściwą stronę, przy
dwóch ciężarach przed klatką. Pierwsza próba była odrzucona globalnie,
bez niepotrzebnego punktowego poprawiania niewłaściwej sekwencji.

Cw135 trial-01 skracał nogi w finale i zmieniał perspektywę/ławki;
new-01 poprawił proporcje, korekta ujednoliciła ławkę. Cw136 trial-01
przenosił podporę na podłogę i ukrywał dalszy ciężar; new-01 nie prostował
nogi podporowej. New-02 w trzech kolumnach dał miejsce na uniesienie ciała,
ale mylił nogę startową i ukrywał chwyt; jego korekta new-correction-01
nie rozwiązała problemu, więc zakończono tę kompozycję. New-03 przy dokładnie
frontalnej kamerze pokazał prawą nogę podporową we wszystkich fazach i lewe
kolano drive, a new-correction-02 skorygował zbyt szeroką ostatnią ławkę.
Nazwy katalogów korekt zachowano; new-correction-02 używa wyłącznie PNGnew-03
jako referencji, nie new-correction-01 z poprzedniej kompozycji.

Cw137 bez sprzętu: prawa stopa pełna, lewa noga wolna/prosta, naturalny
skłon i głęboki dół. Cw138 z gumą: poprawiono ćwierćprzysiad w górnym
kadrze do wysokiej pozycji z prawie prostą podporową nogą; oba uchwyty,
kotwa i ciągłość gumy zachowane, dolna faza z lewą stopą w powietrzu.

Odczytano każdy źródłowy PNG i podgląd512px przed następnym żądaniem,
wszystkie finalne WebP po konwersji. Przeglądy bezpośrednie zgodność→jakość,
nie niezależne subagenty po wcześniejszym limicie. Wszystkie dokładne
prompty/PNG/podglądy/ledgery zachowano poza repozytorium w /tmp/opencode.

Red:365testów zaliczonych, tylko brak cw133 w rejestrze. Log:
`/root/.local/share/opencode/tool-output/tool_13fb48c75001EhS67gmmzCLC6H`.
Green:366testów zaliczonych, analiza0problemów, kontrola wersji poprawna,
formatowanie2Dartów bez zmian. Log:
`/root/.local/share/opencode/tool-output/tool_13fdee8cf001Q6giiBpQ5Nxs6j`.
204zgodneID/assety,512decode,fallbackcw139. Status204/78/126/112/316.
Pakiet lokalny/niewydany, produkcja1.9.0+22; wcześniejsze dane zachowane.

### Koszty — szacunki USD

Odczytano15ledgerów, success z odrębnymi request_id, bez ponownego
liczenia response_received; bez błędów HTTP.

| Katalog w /tmp/opencode | upper_bound_no_cache USD |
|---|---:|
| cw133-trial-01 | 0.023407 |
| cw134-trial-01 | 0.023842 |
| cw134-new-01 | 0.023547 |
| cw135-trial-01 | 0.023437 |
| cw135-new-01 | 0.023127 |
| cw135-new-correction-01 | 0.022407 |
| cw136-trial-01 | 0.023507 |
| cw136-new-01 | 0.023342 |
| cw136-new-02 | 0.023402 |
| cw136-new-correction-01 | 0.022717 |
| cw136-new-03 | 0.023437 |
| cw136-new-correction-02 | 0.022437 |
| cw137-trial-01 | 0.023522 |
| cw138-trial-01 | 0.023657 |
| cw138-correction-01 | 0.022637 |
| Razem | 0.348425 |

15sukcesów=11źródeł/nowychkompozycji+4korekty. Kwota nie jest
potwierdzonym rozliczeniem dostawcy.
