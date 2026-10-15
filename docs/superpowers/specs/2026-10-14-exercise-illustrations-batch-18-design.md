# Ilustracje ćwiczeń — projekt Partii 18

## Zakres i stan wejściowy

Partia obejmuje `cw079–cw084`, zgodnie z `assets/data/exercises.json`.
Stan wejściowy: 144 lokalne ilustracje = 78 wydanych + 66 niewydanych
z Partii 07–17; 172 brakujące na 316 ćwiczeń. Po integracji szóstki:
150 lokalnych = 78 wydanych + 72 niewydane; 166 brakujących.
Produkcja pozostaje `1.9.0+22`. Użytkownik zatwierdził zakres i warianty;
wykonanie zapisano poniżej. Zachować katalog, ID
i wcześniejsze pakiety; publikacja i operacje Git na osobną prośbę.

## Kadry i warianty

| ID | Ćwiczenie | Kadry | Wariant i kolejność |
|---|---|---:|---|
| cw079 | Pompki z biodrami uniesionymi wysoko i nogami na ławce | 2 | Stopy na poziomym siedzisku; ramiona wydłużone → głowa nisko. |
| cw080 | Stanie na rękach przy ścianie | 1 | Statyczne utrzymanie plecami do ściany, pięty w lekkim kontakcie. |
| cw081 | Pompki w staniu na rękach przy ścianie | 2 | Plecami do ściany; góra → kontrolowane opuszczenie. |
| cw082 | Wyciskanie gumy nad głowę | 2 | Guma pod obiema stopami; uchwyty przy barkach → nad głową. |
| cw083 | Unoszenie ramienia bokiem z gumą | 2 | Lewa stopa kotwiąca, prawa ręka robocza; dół → wysokość barku. |
| cw084 | Unoszenie ramion w przód z gumą | 2 | Guma pod obiema stopami; dwa uchwyty przy biodrach → przed barki. |

### Układ i jawne wybory

- `cw079`: dwa poziome pasy pełnej szerokości, góra→dół. Profil boczny
  z niewielkim naturalnym odsunięciem dalszych kończyn dla czytelności.
  Ławka pozioma, wysokość orientacyjnie kolan; obie stopy/przodostopia
  na siedzisku, nie kolana lub piszczele. Dłonie na podłodze, barki
  w górnej fazie blisko pionu nad dłońmi, biodra wysoko. Stałe kontakty
  dłoni i stóp; położenie bioder może naturalnie zmieniać się z ruchem.
- `cw080`: pojedynczy pełny kadr. Wejście do stania jest przygotowaniem,
  nie drugą fazą holda. Czas 20–45 sekund pozostaje w katalogu, bez timera.
- `cw080–cw081`: wybrano plecy do ściany, twarz w stronę pomieszczenia,
  lekkie podparcie piętami. Prosta linia ciała bez „banana”; ramiona
  aktywne. Dłonie około szerokości barków, orientacyjnie 15–25 cm od
  ściany, nie w jej styku z podłogą. W cw080 palce rozstawione i dłonie
  nieco skierowane na zewnątrz; w cw081 dłonie ustawione równolegle.
- `cw081`: dwa kadry obok siebie; ta sama ściana, podłoga, kamera i
  miejsca dłoni. Podczas opuszczania pięty mogą zsunąć się po ścianie;
  nie wymagać identycznej wysokości stóp, bo uniemożliwiłoby to ruch.
  Głowa tuż nad podłogą z niewielkim prześwitem, bez podpory głową.
- `cw082` i `cw084`: dwa kadry obok siebie, kamera przednio-boczna 3/4.
  Jedna otwarta guma z środkowym odcinkiem przyciśniętym obiema podeszwami,
  dwa robocze końce do dwóch oddzielnych uchwytów. W cw082 chwyt z dłońmi
  do przodu, w cw084 nachwyt z dłońmi w dół w górnym kadrze.
- `cw083`: dwa poziome pasy pełnej szerokości, stała kamera frontalna.
  Obie stopy na podłodze; tylko lewa przyciska jeden koniec gumy.
  Prawa ręka trzyma jedyny uchwyt i unosi się w bok. „Stoisz na gumie
  jedną nogą” nie oznacza balansowania jednonóż jak cw071.
  Wybrano stronę przeciwną: lewa stopa→prawa ręka. Druga ręka pusta,
  swobodnie przy tułowiu, bez podtrzymywania gumy.

Rekomendacja: jeden kadr cw080 wystarcza dla izometrii; dwa wprowadzałyby
fikcyjną fazę. Pozostałe mają dwie istotne pozycje. Szerokie pasy pike
i jednostronnego wznosu mieszczą podstawę podpór lub przebieg gumy;
pionowe postacie HSPU i bilateralnych ćwiczeń mieszczą się w kolumnach.

## Kontrakt wizualny

PNG 1024×1024 i końcowy WebP 512×512 na ID. Styl
`assets/exercises/cw256.webp`: kremowe tło, komiksowy kontur, ciemny strój,
twarz bez rysów. Bez tekstu, numerów, strzałek, timerów, watermarków,
duchów ruchu i zbędnego sprzętu. Nakładki mięśni nie są wymagane.

Całe ciało, dłonie, stopy i istotny sprzęt w każdym kadrze z marginesem.
Jedna kamera i skala dla danego ID, stała ściana/ławka/podłoga i rzeczywiste
podpory. Nie dopasowywać zoomu osobno do fazy. Naturalna okluzja możliwa,
jeśli czytelne są obie kończyny i połączenia sprzętu. Nie wymagać
pikselowo identycznych konturów obracających się części ciała.

Nie dodawać ławki do wall handstand/HSPU ani hantli do ćwiczeń z gumą.
W wznosach i wyciskaniu neutralne nadgarstki, rzeczywiste zamknięte chwyty.
Podparcie głową nie jest dozwoloną dodatkową podporą.

### Gumy — ciągłość i zakotwienie

- `cw082/cw084`: jedna guma, ciągły odcinek pod obiema stopami oraz dwa
  napięte odcinki do dłoni. Po jednym uchwycie w każdej dłoni, bez
  osobnych dwóch gum, zewnętrznej kotwy ściennej lub odłączonych końców.
- `cw083`: jedna otwarta guma, jeden koniec pod lewą podeszwą i jeden
  roboczy odcinek do prawego uchwytu. Bez drugiej napiętej gałęzi i uchwytu
  w lewej ręce. Dopuszczalny krótki niepracujący koniec przy stopie.
- Napięcie już w dolnej fazie; wydłużenie gumy naturalne, nie sztywny pręt.
  Stopy nie podnoszą się razem z gumą. Kotwy pod podeszwami zachowują miejsca.
- W cw083 ukośny odcinek przebiega PRZED nogami/tułowiem. Może nakładać
  się na sylwetkę w projekcji; nie traktować tego jako przenikania,
  jeśli trasa w pierwszym planie jest ciągła i przestrzennie logiczna.
- Gumy nie przebiegają przez twarz/szyję; oceniać logiczną trasę
  podeszwa→guma→uchwyt→właściwa dłoń w źródle, 512 px i finalnym WebP.

## Sceny i odrzucenia

### cw079 — Elevated pike — 2 poziome pasy

Góra: obie stopy/przodostopia na jednej stabilnej ławce, obie dłonie
płasko na podłodze, nogi wydłużone, biodra wysoko, ramiona wydłużone.
Dół: ugięte łokcie około 45° względem tułowia, głowa blisko podłogi
między dłońmi z prześwitem. Nadal wysokie biodra i te same kontakty
stóp na siedzisku oraz dłoni na podłodze.

Odrzucić płaską pompkę z nogami na ławce, stopy na podłodze jak cw078,
klęk na ławce, podparcie głową, zmianę wysokości lub pozycji ławki,
przesunięcie dłoni/stóp i zbyt krótki zakres opuszczenia.

### cw080 — Wall handstand hold — 1 kadr

Jedna wyprostowana odwrócona postać plecami do pionowej ściany;
pięty lekko dotykają ściany. Obie dłonie płasko na podłodze, palce
rozstawione, dłonie nieco na zewnątrz. Łokcie wydłużone, barki aktywne,
tułów i nogi w linii, wzrok skierowany między dłonie, głowa wolna nad
podłogą. Widoczny odstęp dłoni od ściany.

Odrzucić headstand/statyw, zapadnięte barki, ugięte kolana, duży łuk
pleców, dłonie w ścianie, niewidoczne kontakty pięt lub timer/wejście.

### cw081 — Wall HSPU — 2 kadry

Lewy: wyprostowane ramiona i ciało przy ścianie, pięty w kontakcie,
dłonie równolegle na podłodze, głowa wolna. Prawy: łokcie ugięte,
tułów obniżony, czubek głowy tuż nad podłogą bez obciążania głowy;
pięty odpowiednio niżej, zachowują kontakt ze ścianą.
Napięty tułów bez banana, nogi wydłużone, bez wybicia i podkurczania.

Odrzucić nieruchome stopy mimo opuszczenia reszty ciała, pike zamiast
handstand, stanie na głowie, kip, duży łuk, zmianę kierunku do ściany,
niepełny zakres lub przesunięcie rąk/ściany.

### cw082 — Band overhead press — 2 kadry

Lewy: stój na szerokość bioder na środkowym odcinku gumy, dwa uchwyty
przy barkach, dłonie do przodu, łokcie nieco z przodu. Prawy: obie
ręce wydłużone nad głową bez przeprostu, ta sama podstawa i napięty
tułów. Dwa odcinki gumy pozostają ciągłe do uchwytów, poza głową.

Odrzucić hantle, ścienną kotwę, luźną lub odłączoną gumę, odrywanie
stóp, wybicie nogami, nadmierny łuk pleców i pojedynczy uchwyt.

### cw083 — Unilateral band lateral raise — 2 poziome pasy

Góra: stój obunóż, lewa stopa przyciska gumę, prawa ręka z uchwytem
przy prawym biodrze, lewa ręka pusta i opuszczona. Dół: prawa ręka
uniesiona bokiem do barku, łokieć nieznacznie ugięty, nadgarstek neutralny.
Jedyny roboczy odcinek gumy biegnie ukośnie przed ciałem do lewej stopy.
Tułów i obie stopy stabilne, bez bocznego przechyłu i shrug.

Odrzucić wznos lewą ręką, prawą stopę jako kotwę, balans jednonóż,
drugą napiętą gałąź, drugą rękę roboczą, ścienną kotwę, front raise,
znikający przebieg przez pierwszy plan lub ucięty uchwyt.

### cw084 — Band front raise — 2 kadry

Lewy: jedna guma pod obiema podeszwami, dwa uchwyty przy biodrach,
nachwyt, ramiona opuszczone. Prawy: obie ręce równocześnie przed ciałem
na wysokości barków, dłonie w dół, lekkie zgięcie łokci i neutralne
nadgarstki. Stopy i tułów bez zmiany, gałęzie napięte i ciągłe.

Odrzucić unoszenie bokiem lub nad głowę, jednorącz, odrywanie stóp,
kołysanie, hantle, zewnętrzną kotwę i odłączone lub scalone uchwyty.

## Sześć promptów bazowych

Każdy prompt: blok wspólny + scena. Pierwsza referencja stylu
`/tmp/opencode/cw256-reference.png`, nie narzuca pozycji z referencji.

### Blok wspólny

```text
Use supplied image ONLY as STYLE reference. Square1024x1024, cream background, clean dark comic outlines, faceless adult in dark neutral clothes. Whole body, BOTH hands/feet and essential apparatus fit with generous margins. SAME camera/scale/floor and fixed supports across phases, moving joints may move naturally as specified. Coherent anatomy and real grip/contact continuity. Band-gripping wrists align with forearms; floor-support wrists have natural extension with palms flat, not sideways kinks. Neutral neck and controlled spine. Natural partial occlusion allowed only if limbs/equipment are readable at512px, no physical penetration or floating grips. No text, labels, numbers, arrows, timer, watermark, ghosts or extra figures. No required muscle overlays.
```

### cw079

```text
ELEVATED PIKE PUSH-UP, EXACTLY TWO FULL-WIDTH HORIZONTAL ROWS TOP TO BOTTOM, SAME SIDE PROFILE with slight natural depth offset to reveal both hands/feet. ONE stable horizontal bench around knee height. BOTH forefeet on BENCH SEAT, BOTH palms flat shoulder-width on FLOOR, long legs, HIGH HIP angle. TOP arms long, shoulders near vertical over palms. BOTTOM bend elbows about45degrees to torso, head BETWEEN hands close to floor with SMALL GAP, never head-supported. SAME bench/hand/foot contacts and spans; hips may move naturally while staying high. No flat decline push-up, knees/shins on bench, feet on floor, headstand, bench-height change, shifted supports or cropped body.
```

### cw080

```text
WALL HANDSTAND HOLD, EXACTLY ONE UNDIVIDED FULL-BODY POSE, no entry sequence or timer. BACK TO WALL, face toward room, heels lightly touch wall. BOTH palms flat on floor shoulder-width, around20cm AWAY from wall, fingers spread and hands slightly turned OUTWARD. Straight active arms/shoulders, braced torso and long legs in one line without banana arch. Gaze BETWEEN palms, head clearly FREE above floor. Side three-quarter camera reveals wall/floor and both heel/palm contacts. No headstand, shoulder collapse, bent knees, hidden hands, palms inside wall, extra pose or time graphic.
```

### cw081

```text
WALL HANDSTAND PUSH-UP, EXACTLY TWO SIDE-BY-SIDE PANELS LEFT TO RIGHT, SAME side three-quarter camera, wall/floor and palm positions. BACK TO WALL in BOTH panels, heels contacting wall, palms parallel shoulder-width on floor around20cm from wall. LEFT straight active arms, straight inverted body, head free. RIGHT bend elbows and lower torso until CROWN is JUST ABOVE floor with tiny gap, NOT head-supported; heels SLIDE DOWN wall accordingly, keep wall contact, do NOT freeze foot height. Long legs, braced spine, no banana/kip/knee tuck. No pike, headstand, partial descent, changed wall or shifted palms. All body/contacts visible.
```

### cw082

```text
STANDING BAND OVERHEAD PRESS, EXACTLY TWO SIDE-BY-SIDE PANELS LEFT TO RIGHT, fixed front-side three-quarter camera. ONE continuous flexible band with middle section PINNED UNDER BOTH FLAT SOLES, two taut branches each connected to ONE real handle gripped by its same-side hand. Hip-width stable feet. LEFT handles at SHOULDER height, palms forward, elbows slightly forward. RIGHT press both handles OVERHEAD with long arms, neutral wrists and braced torso. Branches run logically from feet to hands outside head/neck, band stretches naturally. No dumbbells, wall anchor, two separate bands, loose/disconnected branch, lifted feet, leg drive, back arch or cropped top handles.
```

### cw083

```text
UNILATERAL BAND LATERAL RAISE, EXACTLY TWO FULL-WIDTH HORIZONTAL ROWS TOP TO BOTTOM, SAME FRONTAL camera and TWO-FOOT grounded stance. ONE open band pinned by LEFT SOLE, ONE working branch to a handle in RIGHT HAND; LEFT hand empty/down. TOP right handle beside right hip, branch already lightly taut. BOTTOM raise RIGHT arm SIDEWAYS to shoulder height with soft elbow bend and neutral wrist, no shrug. Band travels DIAGONALLY IN FRONT OF legs/torso from LEFT foot to RIGHT grip; continuous foreground overlap is NOT physical penetration. SAME anchor foot/supports, no side switch, one-leg balance, second taut branch/working hand, wall anchor, front raise, body lean or cropped handle.
```

### cw084

```text
STANDING BILATERAL BAND FRONT RAISE, EXACTLY TWO SIDE-BY-SIDE PANELS LEFT TO RIGHT, fixed front-side three-quarter camera shows FORWARD motion. ONE continuous flexible band middle PINNED UNDER BOTH SOLES, TWO taut branches to separate real handle grips. LEFT handles at hips, pronated grip. RIGHT BOTH arms FORWARD to SHOULDER HEIGHT, palms DOWN, soft elbow bend and neutral wrists. SAME hip-width feet and braced torso, no rocking or leg drive. Branches traceable foot-to-handle, natural band stretch and projection. No dumbbells, lateral/overhead raise, one hand, external anchor, lifted feet, fused/disconnected handles or text.
```

## Przyszłe wykonanie i weryfikacja

Po zatwierdzeniu przygotować plan wykonania. Aktualny main w `/opt/fit`,
bez worktree; zachować niewydane Partie 07–17. Przeczytać working-set
`docs/modules/training.md` przed integracją.

1. Dopisać cw079–cw084 po cw078 przed cw251 do oczekiwań testu; fallback
   cw085 (kolejny face pull). Potwierdzić czerwony brak cw079 przed
   generacją i zmianą rejestru/assetów. Nie mapować fallbacku po samej nazwie.
2. Zapisać sześć osobnych promptów poza repozytorium. Przegląd zgodności,
   potem geometrii/klarowności. Porównać podstawowy/elevated pike, hold/HSPU,
   przesuwające się pięty vs stałe dłonie, kotwy pod stopami i stronę cw083.
3. Każde żądanie osobno w świeżym cwNNN-trial-NN przez
   `tools/benchmark_exercise_images.py --single-sunburst-medium`.
   Odczyt źródła/podglądu512 przed kolejnym żądaniem; bez sekretów w logach.
   Po błędzie lub niepewnym wyniku odczytać ledger, nie retryować automatycznie.
4. Korekta tylko nazwanego defektu, ostatni odrzucony PNG jako jedyna
   referencja. Po dwóch nieskutecznych korektach tego samego problemu
   zatrzymać próby i ocenić nową kompozycję przed dalszym płatnym działaniem.
5. Integracja po akceptacji całej szóstki: WebP przez
   `-resize 512x512 -strip -quality 90`, odczyt finalnych plików,
   te same ID do illustratedExerciseIds. Kadry2/1/2/2/2/2.
6. Pełny Docker target verification: wersja, analiza, testy; 150 zgodnych
   ID/plików, dekodowanie512×512 i fallbackcw085. Formatowanie zmienionych
   Dartów i git diff --check. Bez modeli, zależności i Web SQLite.
7. Status150/78/72/166/316, sześć wierszy, sekcja „Osiemnasta partia”.
   Zapis faktycznych źródeł, przeglądów, korekt i deduplikowanych sukcesów
   ledgerów. Błędy bez danych kosztowych wykazać osobno, nie jako bezpłatne.
   Produkcja nadal1.9.0+22, bez automatycznego commita/pusha/wdrożenia.

## Samokontrola projektu

- Sześć kolejnych ID, poprzednie assety i katalog bez zmian.
- Hold ma jeden kadr, czas pozostaje katalogowy; HSPU pokazuje ruch pięt po ścianie.
- Pike podpiera stopy na ławce, nie kolana; ręce na podłodze, głowa bez podparcia.
- Gumy zakotwione pod wskazanymi podeszwami, z odpowiednią liczbą gałęzi/uchwytów.
- Cw083 nie jest staniem jednonóż; wybrane lewa stopa/prawa ręka i logiczny pierwszy plan.
- Układy i docelowe liczniki spójne; stan wejściowy wynosił 144 ilustracje.

## Wykonanie — 2026-10-14

Sześć WebP 512×512 lokalnie zintegrowanych, niewydanych, kadry 2/1/2/2/2/2.
Źródła trial-01 dla cw079/cw082/cw084, correction-01 dla cw080/cw081.
W cw080 poprawiono odwróconą anatomię głowy; w cw081 stałość dłoni i
ramiona w opuszczeniu, zachowując niższe pięty. Cw083 używa pliku
`/tmp/opencode/cw083-trial-01/cw083-approved-flipped.png`, lokalnego odbicia
całego oryginalnego frontalnego PNG; bez nowego API lub zmiany techniki.
Oba warianty PNG i ledger zachowane. Sprawdzono prawą rękę/lewą stopę
oraz jedną ciągłą gałąź w pierwszym planie i podparcie obu stóp.

Niezależne przeglądy objęły prompty i cw079. Przy cw080 osiągnięto limit
subagentów; dalsza kontrola źródeł, podglądów, finalnych WebP i integracji
odbyła się bezpośrednio, bez dodatkowego niezależnego review.
8 udanych żądań, bez HTTP error, upper_bound_no_cache 0,182626 USD,
nie potwierdzone rozliczenie dostawcy; przegląd ośmiu ledgerów i request_id.

Weryfikacja Dockerowa po wznowieniu przerwanego builda: 366 testów
zaliczonych, analiza bez uwag, formatowanie 0 zmian. 150 zgodnych
plików/rejestru/oczekiwań, decode 512×512, fallback cw085.
Stan: 150 lokalnych / 78 wydanych / 72 niewydane / 166 brakujących /
316 ćwiczeń; produkcja 1.9.0+22, bez commita/pusha/wdrożenia.
