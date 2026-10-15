# Ilustracje ćwiczeń — projekt Partii 23

## Zakres i stan wejściowy

Projekt zatwierdzony przez użytkownika 2026-10-15: `cw109–cw114`
z `assets/data/exercises.json`, łącznie z reuse cw002→cw110.
Stan wejściowy: 174 lokalne ilustracje = 78 wydanych + 96 niewydanych
z Partii 07–22; 142 brakujące na 316 ćwiczeń. Po integracji szóstki:
180 lokalnych = 78 wydanych + 102 niewydane; 136 brakujących.
Produkcja pozostaje `1.9.0+22`. Ten etap obejmuje projekt, bez nowych
żądań API lub integracji. Zachować wszystkie wcześniejsze pakiety i katalog.

## Podejścia i rekomendacja

1. **Rekomendowane: pięć nowych źródeł + identyczna kopia cw002 dla cw110.**
   Sprawdzono `cw002.webp` oraz oba opisy katalogowe. Oba ćwiczenia mają
   romb pod klatką, łokcie blisko ciała, pełne zejście do dłoni, prostą
   sylwetkę, serie 3–4×8–15 i tempo 2-1-1-0. Nowe ID cw110 zachowuje
   własny wpis; reuse dotyczy wyłącznie bajtów grafiki, jak cw055→cw086.
2. Sześć nowych źródeł: osobna grafika cw110 mimo tej samej techniki,
   dodatkowy koszt i ryzyko niespójności bez potrzeby technicznej.
3. Trzy fazy JM press: dokładniejszy tor, lecz mniejsze sceny przy 512 px.
   Dwa końce ruchu z widoczną zmianą pozycji łokci wystarczają do odróżnienia
   hybrydy od skull crusher i zwykłego wyciskania; tor objaśnia katalog.

Nie kopiować `cw025.webp` do dips: zawiera drugą ławkę pod piętami i inny
kontekst ruchu. Cw111/cw112 pokażą jedną ławkę i pięty na podłodze.

## Kadry i jawne warianty

| ID | Ćwiczenie | Kadry | Wariant i kolejność |
|---|---|---:|---|
| cw109 | Prostowanie przedramienia z hantlem w opadzie | 2 | Prawa ręka, jeden hantel neutralnie, stój w zawiasie około 45°; łokieć zgięty → wyprost w tył. |
| cw110 | Pompki diamentowe z naciskiem na triceps | 2 | Identyczna bajtowo kopia cw002; wysoka pozycja → klatka przy rombie dłoni. |
| cw111 | Pompki tyłem na ławce | 2 | Jedna ławka, proste nogi i pięty na podłodze; wysoko → łokcie około 90°. |
| cw112 | Pompki tyłem na ławce z hantlem na udach | 2 | Jedna ławka, proste nogi i pięty na podłodze, jeden hantel na udach; wysoko → łokcie około 90°. |
| cw113 | Wyciskanie JM z hantlami | 2 | Ławka płaska, dwa hantle neutralnie bez wymogu styku; wyprost nad klatką → ciężary blisko brody, łokcie obniżone. |
| cw114 | Prostowanie przedramion w dół z gumą | 2 | Stój, jedna wysoka kotwa przed ciałem i dwie gałęzie do uchwytów; łokcie zgięte → wyprost przy udach. |

Cw109 i cw114: dwa kadry obok siebie. Cw110 zachowuje istniejący układ
cw002 obok siebie bez przerabiania obrazu. Cw111–cw113: dwa poziome pasy
pełnej szerokości od góry do dołu, aby pomieścić wydłużoną sylwetkę.

### Interpretacje techniki

- **Cw109:** zawias tułowia około 45° i poziome górne ramię to dwa różne
  wymagania. Nie utożsamiać osi ramienia z ukośną osią tułowia; ramię
  robocze jest uniesione nieco za tułów i równoległe do podłogi. Porusza
  się przedramię wokół stałego łokcia. Lewa pusta dłoń może podpierać lewe
  udo w obu fazach; bez dodawania ławki do pola sprzętu.
- **Cw111:** katalog dopuszcza nogi proste lub ugięte. Wybrano proste,
  aby cw112 różniło się obciążeniem, nie dodatkową zmianą wariantu.
  Dłonie na przedniej krawędzi siedziska za biodrami, palce skierowane
  ku ciału/stopom. Biodra blisko krawędzi, bez dalekiego wysuwania w przód.
- **Cw112:** jeden kompaktowy hantel poprzecznie w poprzek obu górnych ud,
  blisko zgięcia bioder, podparty przez uda w obu fazach. Obie dłonie
  pozostają podporami na ławce; nie dorysowywać trzeciej ręki do ciężaru.
  Położenie ciężaru oceniać względem ud, nie stałych pikseli pomieszczenia.
- **Cw113:** „łokcie 45°” interpretować jako umiarkowane ustawienie górnych
  ramion względem tułowia widziane z góry, nie zgięcie łokcia do 45°.
  Dolna faza: hantle przy brodzie/górze klatki z prześwitem od twarzy,
  łokcie zginają się i obniżają w stronę tułowia. Powrót od brody w górę
  i nieco ku stopom kończy się nad klatką. „W kierunku bioder” oznacza
  kierunek tej składowej toru, nie cel w miednicy. Nie wykonywać wyciskania
  do bioder ani pullovera; jawna interpretacja grafiki bez edycji katalogu.
- **Cw114:** wysoka kotwa przed i powyżej postaci; dwie napięte gałęzie
  jednej gumy do dwóch uchwytów. Wybrano neutralne chwyty i prosty stój
  z lekkim pochyleniem całego tułowia. Nie kotwić gumy pod stopami.

## Kontrakt wizualny

Styl cw256: kremowe tło, ciemny strój, komiksowy kontur, twarz bez rysów.
Nowe PNG 1024×1024; finalny WebP 512×512 przez
`-resize 512x512 -strip -quality 90`. Reuse cw110 kopiować bez konwersji.
Nakładki mięśni nie są wymagane. Bez napisów, cyfr, strzałek, timerów,
watermarków i duchów ruchu. Pauza cw109 i tempo pozostają w katalogu.

W nowych źródłach jedna kamera/skala/podłoże i te same podpory między fazami;
bez osobnego zoomu. Całe ciało, dłonie, stopy, sprzęt i kotwa w kadrze
z marginesem. Dłonie rzeczywiście obejmują uchwyty albo stanowią podpory.
Naturalne wyprostowanie nadgarstków przy płaskich dłoniach dips jest poprawne;
nie wymuszać na nich neutralnego nadgarstka jak przy hantlach.
Każdy hantel ma krótką rękojeść i dwie głowice. Oceniać orientację dłoni
i ciągłość przedramion, nie same osie sprzętu. Naturalna okluzja możliwa
przy czytelnym połączeniu kończyn i sprzętu w 512 px.

## Sceny i kryteria odrzucenia

### cw109 — Kickback

Stały widok od prawego boku 3/4. Obie stopy podparte, kolana lekko ugięte,
zawias około 45°, plecy kontrolowane. Prawa ręka z jednym hantlem neutralnie,
górne ramię blisko boku i poziomo, łokieć za linią barku. Lewa dłoń na lewym
udzie. Lewy kadr: prawe przedramię zwisa od łokcia, kąt około 90°.
Prawy: wyprost przedramienia w tył do linii górnego ramienia, bez przeprostu.

Odrzucić wiosłowanie całym ramieniem, zamach barkiem, opadający łokieć,
górne ramię zgodne z 45° tułowia zamiast poziomego, drugi ciężar,
zmianę strony lub podpór. Bez timera pauzy.

### cw110 — Diamond push-up, reuse

Kopiować cw002.webp identycznie do cw110.webp po zatwierdzeniu.
Zachować całe istniejące dwa kadry, bez dodawania mięśniowych oznaczeń,
tekstu lub nowej kompresji. Potwierdzić identyczność `cmp`, zgodność
z katalogiem i dekodowanie. Zero nowych żądań API dla tego ID.

### cw111 — Bench dips

Widok boczny 3/4, dwa poziome pasy. Jedna ławka za plecami, obie dłonie
na przedniej krawędzi siedziska, palce ku stopom, proste nogi i pięty
na podłodze. Góra: łokcie niemal wyprostowane, pośladki poza siedziskiem
blisko krawędzi. Dół: biodra niżej, łokcie około 90°, barki nisko,
tułów blisko ławki; nie siadać na podłodze. Miejsca dłoni i pięt stałe.

Odrzucić drugą ławkę, stopy na podwyższeniu, zmianę na ugięte kolana,
unoszenie barków do uszu, palce odwrócone od ciała, ruch bioder daleko
przed ławkę i utratę podpór.

### cw112 — Weighted bench dips

Ta sama technika co cw111, lecz nowe źródło z jednym hantlem podpartym
poprzecznie na górnych udach. Ciężar krótki, stabilny i nie przenika ud.
Utrzymać położenie względem ud mimo ich niewielkiej zmiany kąta.
Obie dłonie na ławce, pięty podparte na podłodze, nogi proste.

Odrzucić ciężar trzymany ręką kosztem podpory, trzecie ramię, hantel
na brzuchu/kolanach, spadający lub wiszący ciężar, sztangę, zmianę na
drugi podest i zbyt głęboki zjazd poniżej kąta około 90°.

### cw113 — JM press

Dwa poziome pasy, stała kamera boczna 3/4 lekko od strony stóp,
pokazująca oba chwyty i obniżanie łokci. Ławka pozioma, głowa/grzbiet/
pośladki podparte, obie stopy na podłodze. Dwa odrębne hantle neutralnie,
naturalny mały odstęp, bez narzuconego kontaktu jak cw108.
Góra: niemal wyprostowane ramiona, hantle nad klatką. Dół: oba łokcie
zgięte i obniżone ku tułowiowi, hantle blisko brody, górne ramiona
umiarkowanie około 45° od tułowia; brak skrajnego rozstawu na boki.

Odrzucić pionowe nieruchome górne ramiona skull crusher, zwykły press
z ciężarami nisko przy środkowej klatce, szeroki rozstaw łokci 90°,
przenikanie brody/szyi, wyciskanie do miednicy, wspólną rękojeść
i znikającą dalszą dłoń. Neutralny chwyt oceniać z dłoni/przedramion.

### cw114 — Band pushdown

Stój na szerokość bioder, lekki stały skłon, obie stopy na podłodze.
Wysoki widoczny uchwyt ścienny przed postacią, jedna guma zamocowana
środkiem, dwie napięte gałęzie do dwóch końcowych uchwytów. Łokcie przy
bokach, górne ramiona nieruchome, neutralne dłonie i stabilne nadgarstki.
Lewy: łokcie około 90°, uchwyty przed górą brzucha. Prawy: wyprost
w dół, dłonie przy udach, gałęzie dłuższe. Sprzęt przed ciałem, nie przez nie.

Odrzucić kotwę za głową lub pod stopami, luźne/zerwane gumy, kabel
z wyciągiem zamiast gumy, ruch barków jak straight-arm pulldown,
odchodzące łokcie, kołysanie, zmianę pozycji kotwy lub podpieranie
uchwytów na udach zamiast rzeczywistego chwytu.

## Pięć promptów bazowych

Dokładny prompt to blok wspólny + scena. Referencja stylu nowych źródeł:
`/tmp/opencode/cw256-reference.png`. Dla cw110 nie przygotowywać żądania.

### Blok wspólny

```text
Use supplied image ONLY as STYLE reference. Square1024x1024, cream background, clean dark comic outlines, faceless adult in dark neutral clothes. EXACTLY TWO panels as specified. Entire body,BOTH hands/feet,essential equipment and anchor fit EACH panel with margins. SAME camera/scale/floor/fixed supports in both phases. Coherent anatomy, connected real grips or flat support palms as appropriate, controlled spine. Each short dumbbell has ONE handle,TWO heads. Read grip from hands/forearms,not equipment axes alone. Natural partial occlusion only with clear limb/equipment continuity at512px. No floating hands,merged weights,physical intersections,extrafigures,text,numbers,arrows,timers,watermarks or motion ghosts. No required muscle overlays. Tempo,rep counts and pauses remain in catalog.
```

### cw109

```text
RIGHT-ARM DUMBBELL TRICEPS KICKBACK, TWO SIDE-BY-SIDE panels LEFT TO RIGHT, same RIGHT-SIDE three-quarter camera. Grounded feet,soft knees,stable hip hinge torso about45degrees,LEFT EMPTY hand braces LEFTthigh. ONE shortDB in RIGHT realNEUTRAL handlegrip. RIGHT upperarm close to side but HORIZONTAL parallel FLOOR,elbow behind shoulder,not merely aligned with slantedtorso. LEFTpanel forearm hangs down from fixedelbow,bendabout90degrees. RIGHTpanel extend ONLY forearm BACK to nearstraight inlinewith horizontalupperarm,neutralwrist,nohyperextension. Same elbow/shoulder/torso/feet/supports. No row,shoulderswing,droppingelbow,secondweight,sidechange or pauseclock.
```

### cw111

```text
STRAIGHT-LEG BENCH DIPS, TWO FULL-WIDTH HORIZONTAL BANDS STACKED TOP TO BOTTOM, same SIDE three-quarter camera. ONE horizontalbench BEHIND body. BOTH palms support FRONT EDGE of seat behind hips,fingers point TOWARD BODY/FEET,natural extendedwrists. Legs STRAIGHT,HEELS grounded on FLOOR inboth;no secondbench. TOP elbows nearlystraight,buttocks OFFseat close toedge,shoulders low. BOTTOM lowerhips by bendingelbows toabout90degrees,body stays close tobench,shoulders NOT shrugged,hips abovefloor. SAME hand/heelcontactlocations and benchheight/scale. No forwardhipdrift,bentknees,feetraised,missingfarhand,reversefingerorientation,unsupportedbody or crop.
```

### cw112

```text
WEIGHTED STRAIGHT-LEG BENCH DIPS, TWO FULL-WIDTH HORIZONTAL BANDS STACKED TOP TO BOTTOM, same SIDE three-quarter camera. ONE horizontalbench behindbody,BOTH palms onfrontseatedge behindhips,fingers towardfeet. Legs STRAIGHT,HEELS grounded onFLOOR,both hands remain supports. ONE COMPACT short dumbbell RESTS CROSSWISE ACROSS BOTH PROXIMAL UPPER THIGHS nearhipcrease,ownhandle/twoheads,actualthighcontact,not abdomen/knees. TOP elbows nearlystraight,hips close tobench offseat. BOTTOM lowerhips/elbowsabout90degrees,shoulderslow,weight stays supported atSAME thighlocation relativebody,not fixedroompixels. Same hand/heelcontacts/camera/scale. No handholdingweight,thirdarm,floating/fallingDB,legpenetration,barbell,secondbench,bentknees or too-deepdip.
```

### cw113

```text
TWO-DUMBBELL JM PRESS, TWO FULL-WIDTH HORIZONTAL BANDS STACKED TOP TO BOTTOM, SAME side three-quarter camera slightlyfromfootend revealing BOTH hands and elbow lowering. Horizontalbench supports head/back/buttocks,BOTH feetgrounded. TWO DISTINCT short dumbbells,ownhandles/twoheads,actual NEUTRAL grips palms towardEACHOTHER,small naturalgap,NO requiredweightcontact. TOP nearstraightarms,weights ABOVE CHEST. BOTTOM bendBOTHelbows and LOWER elbows towardtorso while weights approach CHIN/UPPERCHEST with face/neckclearance,upperarms moderatelyabout45degreesfromtorso inoverheadprojection,not flared90. Hybrid skullcrusher+closepress,NOT fixedverticalupperarm skullcrusher. Returnpath is UP and slightlyFOOTWARD fromchin to ABOVE CHEST,never to pelvis. Samebody/supports/scale. No ordinarylowmidchestpress,wideelbows,facecollision,pullover,sharedhandle,farhandmissing or crop.
```

### cw114

```text
BILATERAL BAND TRICEPS PUSHDOWN, TWO SIDE-BY-SIDE panels LEFT TO RIGHT, SAME front-side three-quarter camera. Stablehipwidthstance,slightfixedtorsolean,bothfeetgrounded. Visible HIGH WALL ANCHOR inFRONT/ABOVE person,ONE resistanceband secured atmiddle,TWO taut branches down to TWO realendhandles in hands,NEUTRALgrips. LEFT elbowsbentabout90degrees,handlesinfrontupperabdomen,upperarms/elbowsatsides. RIGHT extend ONLY forearms DOWN,handsbythighs,brancheslengthened/taut,sameupperarms/elbows. Tracecontinuousband fromanchor tobothgrips OUTSIDE body,no head/neckintersection. Sameanchorheight/stance/camera/scale. No footanchor,behindheadanchor,cablemachine,slack/brokenband,shoulderpulldown,elbowdrift,rocking or handlesrestingonlegs.
```

## Planowane wykonanie po zatwierdzeniu

1. Zapisać zatwierdzenie wariantów i reuse; przygotować plan wykonania.
   Bieżący main w `/opt/fit`, zachować niewydane Partie 07–22.
   Przeczytać `AGENTS.md` i `docs/modules/training.md`.
2. Rozszerzyć expectedIllustrationIds o cw109–cw114 po cw108 przed cw251,
   fallback cw115. Potwierdzić red brakującego cw109 przed integracją.
3. Zapisać pięć osobnych promptów poza repozytorium. Kontrola zgodności,
   potem geometrii: poziome ramię kickback, dłonie/pięty dips, ciężar na
   udach bez trzeciej ręki, hybryda JM press, gałęzie i kotwa pushdown.
4. Generacje pojedynczo przez `tools/benchmark_exercise_images.py
   --single-sunburst-medium`, świeży katalog każdej próby. Sekrety ładować
   z `/root/.config/fit/openai.env`, bez drukowania. Odczytać źródłowy PNG
   i podgląd 512 px przed kolejnym żądaniem.
5. Korekty tylko nazwanych defektów, ostatni odrzucony PNG jako jedyna
   referencja. Po dwóch nieskutecznych korektach zatrzymać tę kompozycję
   i ocenić nowe ujęcie, zamiast powtarzać ten sam prompt. Użytkownik przy
   Partii 22 polecił kontynuować do poprawnego wyniku; nie oznacza to
   automatycznego retry po niepewnym wyniku API. Po błędzie odczytać ledger,
   zachować katalog i osobno wykazać nieznany koszt.
6. Po akceptacji źródeł konwersja pięciu WebP, cw110 jako identyczna kopia
   cw002 z potwierdzeniem cmp. Odczytać wszystkie finalne pliki.
   Dopisać cw109–cw114 do illustratedExerciseIds.
7. Pełny Docker verification: kontrola wersji, analiza, komplet testów,
   180 zgodnych ID/assetów, dekodowanie 512×512, fallback cw115.
   Kontrola formatowania dwóch Dartów i git diff --check.
8. Status 180/78/102/136/316, sześć wierszy i sekcja „Dwudziesta trzecia
   partia”. Zachować historię, katalog, modele, zależności i Web SQLite.
   Zapisać rzeczywiste źródła, korekty, reuse bez API i przeglądy bezpośrednie
   (po wcześniejszym limicie subagentów nie udawać niezależnego review).
9. Koszty tylko z success, deduplikacja request_id, response_received bez
   ponownego liczenia; upper_bound_no_cache jako szacunek, nie rozliczenie.
   Commit, push, zmiana wersji i wdrożenie na osobną prośbę.

## Samokontrola projektu

- Sześć kolejnych ID i poprawne nazwy katalogowe, pięć nowych źródeł + reuse.
- Kadry 2/2/2/2/2/2, bez kodowania czasu lub dodatkowych fikcyjnych faz.
- Cw109 poziome górne ramię mimo ukośnego tułowia; nie konflikt w promptach.
- Cw110 reuse uzasadniony techniką i tempem, bez zmiany katalogowych ID.
- Dips jedna ławka i proste nogi; weighted jeden ciężar podparty udami.
- JM press jawnie odróżniony od cw107/cw108; wskazówki45°/biodra wyjaśnione.
- Pushdown wysoka kotwa przed ciałem, realne dwa chwyty i gałęzie gumy.
- Liczniki wejściowe174/78/96/142/316 i docelowe180/78/102/136/316 spójne.
- Na etapie projektu bez płatnych żądań i bez zmian assetów/rejestru/testu.

## Wykonanie — 2026-10-15

Zintegrowano sześć WebP 512×512 i wpisy rejestru/testu, kadry2/2/2/2/2/2.

| ID | Zaakceptowane źródło | Przebieg |
|---|---|---|
| cw109 | /tmp/opencode/cw109-correction-01 | Jedna korekta opadającego łokcia i kierunku wyprostu. |
| cw110 | assets/exercises/cw002.webp | Kopia bez konwersji, cmp potwierdził identyczność. |
| cw111 | /tmp/opencode/cw111-new-01 | Dwie odrzucone korekty bocznego ujęcia, nowe przednie3/4. |
| cw112 | /tmp/opencode/cw112-trial-01 | Przed żądaniem przyjęto przednią kamerę3/4, aby odsłonić dłonie. |
| cw113 | /tmp/opencode/cw113-new-correction-02 | Po dwóch nieudanych korektach nowa kamera, potem dwie korekty sprzętu/chwytów. |
| cw114 | /tmp/opencode/cw114-trial-01 | Pierwsze źródło zaakceptowane. |

Nowe pliki konwertowano przez resize512/strip/quality90. Dokładne prompty,
oryginalne i korygowane PNG, podglądy i ledgery zachowano poza repozytorium.
Źródła i podglądy odczytywano przed następnym żądaniem, finalne WebP po
konwersji. Przeglądy bezpośrednie zgodność→jakość, nie niezależne subagenty.

W cw111 pierwsza korekta umieściła dłoń na udzie, druga nie pokazała jej
poprawnego podparcia w obu fazach; zatrzymano stare ujęcie. Nowy widok
pokazuje obie podpory na krawędzi. W cw113 początkowe próby łączyły
ciężary we wspólną rękojeść lub ukrywały dalszy chwyt. Po zmianie kamery
ostatnia korekta ustawiła dwa osobne hantle po skosie wzdłuż osi tułowia
i rzeczywiste neutralne dłonie. Nie narzucano kontaktu ciężarów jak cw108.
Zastosowano zatwierdzoną interpretację JM press i pozostawiono katalog bez zmian.

Red: analiza0problemów, 365testów zaliczonych, tylko brak cw109 w rejestrze.
Log `/root/.local/share/opencode/tool-output/tool_13e5a4a8c001Afa6rZBFeNTPF7`.
Green: 366testów zaliczonych, analiza0problemów, kontrola wersji poprawna,
formatowanie2Dartów bez zmian. Log:
`/root/.local/share/opencode/tool-output/tool_13e71e0d60019bPctAEs4CySLa`.
180 zgodnych ID/assetów, fallbackcw115, wszystkie dekodowane512×512.
Status180/78/102/136/316. Pakiet lokalny/niewydany, produkcja1.9.0+22.

### Rozliczenie żądań — szacunki USD

Odczytano wszystkie14ledgerów, success z różnymi request_id, bez ponownego
liczenia response_received. Bez błędów HTTP, zerożądań dla cw110.

| Katalog w /tmp/opencode | upper_bound_no_cache USD |
|---|---:|
| cw109-trial-01 | 0.023122 |
| cw109-correction-01 | 0.022487 |
| cw111-trial-01 | 0.023102 |
| cw111-correction-01 | 0.022407 |
| cw111-correction-02 | 0.022482 |
| cw111-new-01 | 0.023002 |
| cw112-trial-01 | 0.023502 |
| cw113-trial-01 | 0.023347 |
| cw113-correction-01 | 0.022572 |
| cw113-correction-02 | 0.022747 |
| cw113-new-01 | 0.023322 |
| cw113-new-correction-01 | 0.022762 |
| cw113-new-correction-02 | 0.022907 |
| cw114-trial-01 | 0.023282 |
| Razem | 0.321043 |

14sukcesów = 7źródeł/nowychkompozycji + 7korekt. Kwota nie jest
potwierdzonym rozliczeniem dostawcy.
