# Ilustracje ćwiczeń — projekt Partii 26

## Zakres i stan wejściowy

Projekt zatwierdzony przez użytkownika 2026-10-15: `cw127–cw132`
z `assets/data/exercises.json`, w tym cw128 bez skoku i kadry 2/2/2/3/3/3.
Stan wejściowy: 192 lokalne ilustracje = 78 wydanych + 114 niewydanych
z Partii 07–25; 124 brakujące na 316 ćwiczeń. Po integracji szóstki:
198 lokalnych = 78 wydanych + 120 niewydanych; 118 brakujących.
Produkcja pozostaje `1.9.0+22`. Ten etap obejmuje projekt i prompty,
bez żądań API lub zmian assetów/rejestru/testów. Zachować katalog, ID i historię.

## Podejścia i rekomendacja

1. **Rekomendowane: sześć nowych źródeł, kadry 2/2/2/3/3/3.**
   Dwa końce ruchu wystarczają dla przysiadu front-rack i statycznych split
   squatów. Trzy sceny rozróżniają kroki: naprzemienne wykroki chodzone,
   krok w tył z powrotem i krok w bok przed zejściem.
2. Dwa kadry dla wszystkich: większa postać, ale końcowy wykrok nie pokazuje,
   czy stopa poszła w przód, w tył czy była nieruchoma. Grozi duplikowaniem
   static split squat w kilku ID.
3. Cztery lub więcej faz kroków: dokładniejsza sekwencja, lecz mniejsze
   sceny512px bez konieczności technicznej. Nie kodować każdego powtórzenia.

Brak reuse: goblet/side-held squat nie ma rack na barkach; istniejące złożone
ćwiczenia z wypadami nie odpowiadają tym pojedynczym wariantom.

## Kadry i jawne warianty

| ID | Ćwiczenie | Kadry | Wariant i kolejność |
|---|---|---:|---|
| cw127 | Przysiad przedni z hantlami | 2 | Dwa hantle w rack na barkach, łokcie do przodu i wysoko; stój → głęboki przysiad. |
| cw128 | Przysiad bułgarski z hantlami | 2 | Prawa stopa z przodu na podłodze, grzbiet lewej na ławce, dwa hantle przy bokach; wysoko → zejście. |
| cw129 | Przysiad w wykroku z hantlami | 2 | Prawa stopa z przodu, lewe przodostopie z tyłu na podłodze; stałe miejsca stóp, wysoko → tylne kolano blisko podłogi. |
| cw130 | Wykroki chodzone z hantlami | 3 | Prawa noga prowadzi w niskim wykroku → wznos/przejście lewej nogi w przód → lewa prowadzi w kolejnym niskim wykroku. |
| cw131 | Zakroki z hantlami | 3 | Stój → lewa noga cofa się do niskiego wykroku, prawa stopa pozostaje na miejscu → powrót do stania. |
| cw132 | Wypady w bok z hantlami | 3 | Stój → prawa stopa odstawiona szeroko w bok, ciało jeszcze wysoko → zejście na prawą nogę, lewa prosta. |

Cw127: dwa kadry obok siebie. Cw128–cw129: dwa poziome pasy pełnej
szerokości od góry do dołu. Cw130–cw132: trzy poziome pasy pełnej szerokości
od góry do dołu, aby pomieścić rozkrok i pokazać zmianę położenia stóp.

### Rozstrzygnięcia techniczne

- **Cw127:** dwa niezależne krótkie hantle neutralnie lub lekko skośnie,
  tylna głowica każdego oparta na odpowiednim przednim barku. Każda dłoń
  zamyka własną rękojeść; łokcie skierowane w przód, utrzymane wysoko,
  bez wymuszania sztangowego front-rack z przeprostowanymi nadgarstkami.
  Tułów możliwie pionowy, naturalne niewielkie pochylenie dopuszczalne.
  Głębokość około równoległości lub nieco niżej przy pełnych stopach.
- **Cw128:** niejasne „głęboki wyskok tylnym kolanem” interpretować jako
  kontrolowane ZEJŚCIE, zgodne z nazwą Bulgarian split squat i tempem3-1-1-0.
  Bez skoku lub oderwania przedniej stopy. Jawna interpretacja do zatwierdzenia,
  bez zmiany katalogu. Prawa noga robocza, lewy grzbiet stopy oparty na
  siedzisku jednej ławki; nie palce lewej stopy o podłogę. Przednia stopa
  w odpowiedniej odległości odpowiadającej cue60–80cm, bez miarki/liczb.
  Obie dłonie trzymają dwa kompaktowe hantle neutralnie przy bokach.
- **Cw129:** ta sama prawa noga z przodu, ale obie podpory na podłodze:
  pełna prawa stopa i lewe przodostopie z uniesioną piętą. Stopy nie robią
  kroku między fazami. Tylne kolano blisko podłogi, bez opierania na niej;
  przednia goleń zbliżona do pionowej i kolano w kierunku palców.
- **Cw130:** ruch postępuje w przód, bez resetu obu stóp do miejsca startu.
  Najpierw niski wykrok prawą, następnie wznos na prawej i przeniesienie
  lewej stopy, potem niski wykrok lewą dalej w przód. Ta sama kamera/skala,
  nieopisane delikatne szwy podłogi jako stałe odniesienie drogi.
  Stały kierunek ciała i rzeczywiste połączenia biodro–kolano–stopa;
  nie odbijać całej postaci w celu pozorowania zmiany nogi.
- **Cw131:** prawa stopa kotwicząca w tym samym miejscu w trzech scenach;
  tylko lewa cofa się i wraca. Środkowa pozycja niska, lewe przodostopie
  z tyłu, kolano blisko podłogi, prawa pięta podparta. Ostatni kadr powrotu
  nie jest kolejnym krokiem w przód. Mały szew podłogi przy prawej stopie
  ułatwia ocenę kierunku bez strzałek.
- **Cw132:** wybrano lateral lunge z krokiem w bok, nie statyczny cossack
  z przenoszeniem między nogami. Prawa noga robocza, lewa stopa nie zmienia
  miejsca. W drugim kadrze rozkrok jeszcze wysoko, w trzecim biodra w tył
  i w prawo, prawe kolano zgięte, lewa noga prosta. Obie pięty na podłodze;
  nie wymagać rotacji lewej stopy na piętę/palców w górę jak w niektórych
  wariantach cossack. Dwa hantle trzymane za rękojeści przy bokach, naturalnie
  obok roboczej nogi/przed miednicą według projekcji barków, nie w goblet.
  Ramiona długie, sprzęt nie dotyka podłogi lub kolan.

## Kontrakt wizualny

Styl cw256: kremowe tło, komiksowy kontur, ciemny strój, twarz bez rysów.
PNG1024×1024, finalny WebP512×512 przez `-resize 512x512 -strip -quality 90`.
Bez napisów, cyfr, strzałek, timerów, watermarków i duchów ruchu.
Nakładki mięśni nie są wymagane. Tempo, odległość60–80cm i liczba kroków
pozostają w katalogu, nie są mierzone statycznymi scenami.

Całe ciało, obie dłonie/stopy, hantle i ławka z marginesem w każdym kadrze.
Stała kamera i skala, bez zoomu osobno do fazy; podłoże/sprzęt nie zmienia
wysokości. Podpory nieruchome cw127–cw129, zamierzony ruch stóp cw130–cw132.
W nowych sekwencjach prosty nieopisany szew podłogi dopuszczalny.
Dwie niezależne rękojeści/dwa zamknięte chwyty i cztery głowice; chwyt
oceniać z dłoni/przedramion, nie samych osi ciężarów. Okluzja naturalna
przy czytelnej ciągłości512px, nie samotna głowica zamiast dalszego chwytu.

Naturalna pozycja kręgosłupa, kolana podążają za palcami, przednia/robocza
pięta podparta. Nie skracać ramion, nie wydłużać kończyn i nie zmieniać
rozmiaru hantli dla prześwitu w dolnej pozycji. Wybrać kompaktowy sprzęt.

## Sceny i kryteria odrzucenia

### cw127 — Front-rack dumbbell squat

Dwa kadry obok siebie, stały przednio-boczny widok3/4 ujawniający oba racki,
kolana i stopy. Lewy: stój, dwa hantle przy barkach, łokcie do przodu.
Prawy: głęboki przysiad, oba racki i wysokość łokci względem tułowia
zachowane, uda około poziomu lub nieco poniżej. Stopy na szerokość barków,
palce lekko na zewnątrz, pięty i przody stóp w tych samych miejscach.

Odrzucić jeden hantel w goblet, ciężary przy bokach lub nad głową,
opadające łokcie, dłonie bez rzeczywistego chwytu, sprzęt w szyi,
zmianę stóp, zaokrąglony grzbiet, uniesione pięty i zapadające kolana.

### cw128 — Bulgarian split squat

Dwa poziome pasy, widok boczny3/4 odsłaniający przednią prawą nogę i lewą
stopę na ławce za postacią. Góra: wysoka pozycja, przednie kolano miękkie,
tylne zgięte przez podniesioną stopę. Dół: ciało niżej, prawe biodro/kolano
zgięte, lewe kolano schodzi w stronę podłogi, lewy grzbiet stopy nadal
na siedzisku. Prawa stopa pełna na podłodze, te same punkty podpór.
Hantle poza nogami, proste ramiona, tułów kontrolowany.

Odrzucić skok, grzbiet stopy bez kontaktu z ławką, stopę na pionowym boku
ławki, tylną nogę na podłodze, zmianę nogi roboczej, przednią piętę w górze,
ciężar przenikający ławkę/nogę i zanik dalszej dłoni.

### cw129 — Static split squat

Dwa poziome pasy, ta sama kamera i skala, prawa stopa z przodu, lewe
przodostopie z tyłu na podłodze. Góra: biodra wysoko, kolana prawie
wyprostowane bez przeprostu. Dół: tylne kolano kilka centymetrów nad podłogą,
przednie zgięte około90°, tułów możliwie pionowy, hantle po bokach.
Stopy nie przesuwają się, ciężar rozłożony między obie podpory.

Odrzucić ławkę, krok lub zmianę rozstawu stóp, tylną piętę płasko na ziemi
przy niskiej fazie, kolano oparte na ziemi, niski półprzysiad bez zakresu,
gwałtowny skłon, valgus i ciężary dotykające podłogi.

### cw130 — Walking lunges

Trzy poziome pasy, kamera lekko przednio-boczna3/4, kierunek ruchu w prawo
obrazu, stały szew podłogi i szeroki kadr. Góra: niski wykrok, prawa stopa
prowadzi, lewe kolano blisko podłogi. Środek: wznos na prawej stopie,
lewa noga przechodzi do przodu, bez obu kolan na ziemi lub biegu.
Dół: lewa stopa staje dalej w przód, niski wykrok z prawym kolanem nisko.
Dwa hantle neutralnie przy bokach, barki nisko, ramiona długie.

Odrzucić tę samą prowadzącą nogę w obu niskich fazach, reset do startu,
odbicie postaci zmieniające kierunek kamery, brak postępu po podłodze,
skok, zwykły spacer bez zejścia, statyczny split squat lub brak ciężaru.

### cw131 — Reverse lunge

Trzy poziome pasy, stały widok boczny3/4 i szew przy prawej stopie.
Góra: stój z dwoma hantlami przy bokach. Środek: lewa noga cofnięta,
lewe kolano blisko podłogi, prawa stopa niezmiennie na szwie.
Dół: powrót lewej stopy obok prawej do pozycji startowej. Tułów i sprzęt
spójne, prawa noga zapewnia odepchnięcie przy powrocie.

Odrzucić krok prawą w przód, przesunięcie kotwiczącej stopy, statyczny
rozkrok w trzech kadrach, zmianę kierunku postaci, przeskok lub brak powrotu.

### cw132 — Lateral lunge

Trzy poziome pasy, stały widok frontalny z minimalnym3/4, obie nogi widoczne.
Góra: stój, dwa hantle przy bokach. Środek: prawa stopa szeroko w prawo
anatomicznie (w lewo obrazu), obie nogi jeszcze prawie proste, miednica wysoko.
Dół: prawa noga zgięta, lewa prosta, biodra cofnięte nad prawą nogę,
klatka nad kolanem roboczej nogi. Lewa stopa zachowuje miejsce we wszystkich
fazach, prawa w dolnej pozostaje na miejscu osiągniętym krokiem.

Odrzucić krok w przód/tył, zmianę nogi roboczej, ugięcie obu kolan
jak sumo squat, uniesioną prawą piętę, automatyczne palce lewej stopy w górę,
pozorny krok przez samą zmianę zoomu, ciężary na podłodze lub goblet.

## Sześć promptów bazowych

Każdy dokładny prompt zawiera wspólny blok i odpowiednią scenę.
Referencja stylu `/tmp/opencode/cw256-reference.png`, nie narzuca pozycji.

### Blok wspólny

```text
Use supplied image ONLY as STYLE reference. Square1024x1024,cream background,clean dark comic outlines,faceless adult in dark neutral clothes. Exact panels/layout as specified. Wholebody,BOTH hands/feet,TWO complete shortdumbbells and essential bench fit EVERY frame with margins. SAME camera/scale/floor/equipmentheight across phases,no per-phasezoom. Coherent anatomy,realclosedgrips,stablewrists,controlledspine,kneestracktoes. Each dumbbell ONE short handle,TWO heads,no sharedbar. Natural partialocclusion only with clear connected hands/forearms/equipment at512px. Longarms in sideheldvariants;do not shortenlimbs forclearance. No text,numbers,arrows,timers,watermarks,ghosts or extrafigures. No required muscleoverlays;reps/tempo/distances stay in catalog. Intendedsteps movefeet,static supports don'tmove.
```

### cw127

```text
FRONT-RACK TWO-DUMBBELL SQUAT, EXACTLY TWO SIDE-BY-SIDE panels LEFT TO RIGHT,same front-side3/4 view. TWO compactDBs,each own realclosedhandlegrip neutral/slightlyangled,rearhead rests on corresponding FRONT SHOULDER,ELBOWS FORWARD and HIGH throughout,not barbellwristcontortion. LEFT tallstand. RIGHT deepcontrolledsquat aboutparallel/slightlybelow,torsofairlyupright with naturalminimallean,heels/fullsoles grounded,SAME shoulderwidth/toesout stance,kneestracktoes. Rack/elbowheight relativetorso unchanged,weightsdon'tpierceneck. No goblet/singleweight/sideweights/overheadpress,elbowdrop,heelraise,valgus,roundedback or crop. Bothgrips/shouldercontacts visible.
```

### cw128

```text
RIGHT-LEG-FORWARD BULGARIAN SPLIT SQUAT WITH TWO SIDE-HELD DBs, EXACTLY TWO FULL-WIDTH HORIZONTAL BANDS TOP TO BOTTOM,same SIDE3/4 camera. RIGHT fullfoot onFLOOR infront,LEFT FOOT DORSUM rests atop ONE benchseat BEHIND body,not toesonfloor. Natural60-80cmfrontfootdistance,no measurementlabels. TOP highposition,softfrontknee,backkneebent due elevatedfoot. BOTTOM LOWER body by bendingRIGHT hip/knee,LEFTknee descends towardfloor,LEFTdorsum stays on SAME seatspot. Controlledtorso,bracedcore,frontheelgrounded,SAME footcontacts/benchheight. TWO compactDBs neutral atSIDES,longarms,clearancefromlegs/bench/floor. NO JUMP despite ambiguouscatalogword,not explosiveexercise. No sidechange,unsupportedrearfoot,footonverticalbenchside,frontheelraise,valgus,missingfargrip or crop.
```

### cw129

```text
STATIC SPLIT SQUAT WITH TWO SIDE-HELD DUMBBELLS, EXACTLY TWO FULL-WIDTH HORIZONTAL BANDS TOP TO BOTTOM,same side3/4 camera. RIGHT fullfoot FORWARD onfloor,LEFT FOREFOOT behind onfloor with heelUP,NO BENCH. SAME footpositions bothphases,staticbase. TOP hips high,kneesalmostextended. BOTTOM bendbothknees,LEFTrearknee closeabovefloor notresting,RIGHTfrontkneeabout90/shinnearvertical,kneestracktoes,torsofairlyupright. Weightsharedbetweenfrontsole/rearforefoot,frontheelgrounded. TWO DBs realNEUTRAL grips atSIDES,longarms,weightsclearfloor/legs. No stepping,changedstance,bench,sidechange,groundedrearknee,deepforwardfold,valgus or missingweight.
```

### cw130

```text
WALKING LUNGES WITH TWO SIDE-HELD DUMBBELLS, EXACTLY THREE FULL-WIDTH HORIZONTAL BANDS TOP TO BOTTOM. SAME front-side3/4 camera/scale,facing/TRAVELLING toward IMAGE RIGHT,wide framing and faint UNLABELLED fixedfloorseam. TOP LOW LUNGE with anatomicalRIGHTlegFORWARD,LEFTknee closefloor. MIDDLE rise over plantedRIGHTfrontfoot while LEFTleg SWINGS/PASSES FORWARD,walkingtransition notjump,bodyadvances. BOTTOM NEXT LOW LUNGE with LEFTfoot NOW FORWARD fartheralongfloor,RIGHTknee closefloor. Alternateleadlegs with realhip-knee-footconnections,NOT mirroredwholebody or duplicatepose. BOTH DBs neutral atSIDES,longarms,shoulderslow,torsofairlyupright,leadheelgrounded. No resettooriginalspot,static3poses,sameleadlegtwice,run,weightsmissing/floorcontact,labels/arrows/ghosts. Fullbody/equipment within eachband.
```

### cw131

```text
REVERSE LUNGE WITH TWO SIDE-HELD DUMBBELLS, EXACTLY THREE FULL-WIDTH HORIZONTAL BANDS TOP TO BOTTOM,same SIDE3/4 camera/scale/bodyorientation. Faint UNLABELLED FLOOR SEAM atRIGHTFOOT staysfixedall3. TOP standbothfeetbesideeachother,2DBneutral atSIDES. MIDDLE LEFTleg STEPS BACK behindbody to LOW LUNGE,leftforefootonfloor/heelup,LEFTknee closeabovefloor,RIGHT fullsole REMAINS atSEAM,no forwardstep. BOTTOM LEFTfoot RETURNS beside RIGHT intooriginalstand,notcontinuingforward. Torsofairlyupright/braced,frontheelgrounded,kneestracktoes,longarms/realgrips,weightsclearlegs/floor. Sameanatomy/supportscale,oneconsistentmotiondirection. No movingrightanchorfoot,forwardlunge,staticrozkrokallframes,jump,sidechange,arrows/text or ghosts.
```

### cw132

```text
RIGHT LATERAL LUNGE WITH TWO SIDE-HELD DUMBBELLS, EXACTLY THREE FULL-WIDTH HORIZONTAL BANDS TOP TO BOTTOM,same almostFRONTAL camera/scale/floor. TOP uprightstand,feetabout hipwidth,2DBneutral atSIDES. MIDDLE anatomicalRIGHTFOOT steps WIDE SIDEWAYS to viewerLEFT,bothlegs stillnearlystraight/hipsHIGH,LEFTfoot staysoriginalspot. BOTTOM flexRIGHTknee/hip,sithipsBACK and RIGHT overworkingleg,LEFTleg STRAIGHT,chestoverRIGHTknee,RIGHTknee trackstoes. LEFTfootunchangedthroughout,RIGHTfootstaysatwidecontactfrommiddle. BOTH HEELS/fullsoles grounded,no automaticlefttoe-uplift/cossackheelrotation. TWO separate compactDBs realgrips,longarms followshoulderprojection besideworkingleg/frontpelvis,notgoblet,weightsAIR clearfloor/knees. No sumosquatbothkneesbend,forward/backstep,sideflip,zoomfake,valgus,heelraise,text/arrows or ghosts. Entire widebody/bothfeet/weights fit eachband.
```

## Planowane wykonanie po zatwierdzeniu

1. Zatwierdzić warianty, liczbę kadrów i interpretację cw128 bez skoku.
   Zapisać plan. Bieżący main w /opt/fit, zachować niewydane Partie07–25.
   Przeczytać AGENTS.md i docs/modules/training.md.
2. Test expectedIllustrationIds: cw127–cw132 po cw126 przedcw251,
   fallbackcw133. Red brakującegocw127 przed integracją.
3. Sześć dokładnych promptów poza repozytorium. Kontrola zgodność→geometria:
   rack/łokcie,grzbietstopy naławce,stały rozkrok,postęp walkinglunges,
   kotwicząca prawa stopa w reverse,lewa w lateral.
4. Żądania pojedynczo tools/benchmark_exercise_images.py --single-sunburst-medium,
   świeży katalog na próbę,sekrety z /root/.config/fit/openai.env bez drukowania.
   Odczytać źródło i podgląd512px przed następnym żądaniem.
5. Korekty nazwanych defektów,ostatni odrzuconyPNG jako jedyna referencja.
   Po dwóch nieskutecznych korektach tej samej wady zakończyć kompozycję
   i ocenić nową, kontynuując do poprawnego wyniku według polecenia użytkownika.
   Po błędzie/niepewności odczytać ledger,bez automatycznego retry;zachować
   katalog i osobno wykazać nieznany koszt.
6. Po akceptacji szóstki konwersja WebP,odczyt finalnych plików,te sameID
   do illustratedExerciseIds. Kadry2/2/2/3/3/3,bez edycji katalogu/modeli/
   zależności/WebSQLite.
7. Pełny Docker verification:wersja/analiza/komplet testów,198zgodnychID/assetów,
   dekodowanie512×512,fallbackcw133. Formatowanie dwóch Dartów,git diff --check.
8. Status198/78/120/118/316,sześćwierszy,sekcja „Dwudziesta szósta partia”.
   Zapisać rzeczywiste źródła,korekty,przeglądy i koszty tylko success,
   deduplikacja request_id,response_received bez ponownego liczenia.
   upper_bound_no_cache to szacunek,nie rozliczenie dostawcy.
9. Przeglądy bezpośrednie po wcześniejszym limicie subagentów,nie deklarować
   niezależnego review. Commit,push,wersja i wdrożenie na osobną prośbę.

## Samokontrola projektu

- SześćkolejnychID,nazwy/technika z katalogu,bez reuse.
- Kadry2/2/2/3/3/3,jednoznaczne podpory i strony,zamierzone kroki.
- Cw128 niejasnywyskok rozstrzygnięty jawnie jakozejście/dozatwierdzenia.
- Static129 stopy nieruchome,walking130 przemieszcza się,reverse131 wraca.
- Lateral132 pokazuje krok w bok przed zejściem,nie staticcossack/sumosquat.
- Dwa hantle przez cały pakiet,tylko127 rack,reszta przybokach,długieramiona.
- Liczniki192/78/114/124/316→198/78/120/118/316,fallbackcw133 spójne.
- Etap projektu bez żądańAPI i integracji.

## Wykonanie — 2026-10-15

Zintegrowano sześć nowych WebP512×512, kadry2/2/2/3/3/3, przez
`-resize 512x512 -strip -quality 90`.

| ID | Zaakceptowane źródło | Przebieg |
|---|---|---|
| cw127 | /tmp/opencode/cw127-correction-02 | Usunięto niepotrzebną ławkę i podniesiono łokcie. |
| cw128 | /tmp/opencode/cw128-new-01 | Po dwóch nieskutecznych korektach chwytu nowe przednie3/4. |
| cw129 | /tmp/opencode/cw129-new-02 | Po dwóch korektach podpór i odrzuconym new-01 nowe ujęcie frontalne. |
| cw130 | /tmp/opencode/cw130-new-01 | Odrzucono pierwszą próbę z powtórzoną nogą/zmienną skalą; nowa kamera frontalna. |
| cw131 | /tmp/opencode/cw131-new-01 | Po dwóch korektach kotwiczącej stopy nowa kamera frontalna. |
| cw132 | /tmp/opencode/cw132-approved-aligned.png | Correction-02 z lokalnym przesunięciem górnej sceny o22px. |

Pierwszy prompt cw127 nieprecyzyjnie wymieniał ławkę w bloku wspólnym;
usunięto ją w korekcie i doprecyzowano brak ławki w pozostałych nieławowych
scenach przed ich żądaniami. Druga korekta poprawiła front-rack zamiast
podtrzymywania ciężarów z opuszczonymi łokciami. Cw128 zachowuje zatwierdzone
zejście zamiast skoku, obie dłonie trzymają oddzielne ciężary, lewy grzbiet
stopy pozostaje na siedzisku.

W cw129 dwie korekty starego ujęcia nie zapewniły stałej geometrii podpór;
new-01 nadal przesuwał stopę i zasłaniał dalszy chwyt. Frontalny new-02
pokazał te same punkty podparcia i oba ciężary. W cw130 od razu oceniono
globalny problem pierwszej kompozycji (powtórzenie nogi, skala i brak postępu),
zamiast wykonywać lokalne korekty nieodpowiedniej sceny. Nowa kamera
pokazuje prawą nogę prowadzącą, przejście lewej i następny lewy wykrok.
Cw131 w nowym frontalnym ujęciu cofa lewą stopę przy zachowaniu prawej
i wraca do stania; stare boczne źródło i korekty pozostawiono odrzucone.

W cw132 dwie korekty poprawiły dolny rozstaw, lecz pozostawiły małe
przesunięcie początkowej sceny. Wybrano nowe podejście lokalne zamiast
dalszego płatnego powtarzania: sztywna translacja górnego regionu o22px
w prawo, bez obrotu/skalowania/deformacji. Operacja na source1024px:

```bash
convert /tmp/opencode/cw132-correction-02/cw132-gpt-image-2.5-sunburst-medium.png \( /tmp/opencode/cw132-correction-02/cw132-gpt-image-2.5-sunburst-medium.png -crop 1002x358+0+0 +repage \) -geometry +22+0 -compose Over -composite /tmp/opencode/cw132-approved-aligned.png
```

Sprawdzono tożsamość pikseli RGB starego regionu0..1001,0..357 z nowym
22..1023,0..357 oraz całego regionu y>=358. Dolne sceny i linie podziału
identyczne, ciało/sprzęt w całości w kadrze, brak dodatkowego żądania API.
Odczytano wyrównany PNG i podgląd512px przed integracją.

Źródła i podglądy512px odczytywano przed następnymi żądaniami, wszystkie
finalne WebP po konwersji. Przeglądy bezpośrednie zgodność→jakość,
nie niezależne subagenty po wcześniejszym limicie. Prompty/PNG/podglądy/
ledgery zachowano poza repozytorium; katalogowe dane i wcześniejsze assety
pozostały zachowane.

Red:365testów zaliczonych, tylko brak cw127 w rejestrze, analiza0problemów.
Log `/root/.local/share/opencode/tool-output/tool_13f1772ab001kBCscDXganp2AF`.
Green:366testów zaliczonych, analiza0problemów, kontrola wersji poprawna,
formatowanie2Dartów bez zmian. Log:
`/root/.local/share/opencode/tool-output/tool_13f6c5c46001hwtZK26fVNBZVf`.
198zgodnych ID/assetów,512decode,fallbackcw133. Status198/78/120/118/316.
Pakiet lokalny/niewydany; produkcja1.9.0+22.

### Koszty — szacunki USD

Wszystkie21ledgerów odczytane; success z różnymi request_id, bez podwójnego
liczenia response_received. Bez błędów HTTP.

| Katalog w /tmp/opencode | upper_bound_no_cache USD |
|---|---:|
| cw127-trial-01 | 0.023292 |
| cw127-correction-01 | 0.022382 |
| cw127-correction-02 | 0.022492 |
| cw128-trial-01 | 0.023472 |
| cw128-correction-01 | 0.022377 |
| cw128-correction-02 | 0.022392 |
| cw128-new-01 | 0.023237 |
| cw129-trial-01 | 0.023402 |
| cw129-correction-01 | 0.022347 |
| cw129-correction-02 | 0.022417 |
| cw129-new-01 | 0.023027 |
| cw129-new-02 | 0.023017 |
| cw130-trial-01 | 0.023552 |
| cw130-new-01 | 0.023362 |
| cw131-trial-01 | 0.023512 |
| cw131-correction-01 | 0.022492 |
| cw131-correction-02 | 0.022322 |
| cw131-new-01 | 0.022977 |
| cw132-trial-01 | 0.023672 |
| cw132-correction-01 | 0.022622 |
| cw132-correction-02 | 0.022477 |
| Razem | 0.480842 |

21sukcesów=11źródeł/nowychkompozycji+10korekt. Kwota nie jest
potwierdzonym rozliczeniem dostawcy.
