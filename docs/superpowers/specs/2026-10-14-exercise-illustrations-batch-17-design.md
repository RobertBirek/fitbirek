# Ilustracje ćwiczeń — projekt Partii 17

## Zakres i stan wejściowy

Partia obejmuje `cw073–cw078`, zgodnie z `assets/data/exercises.json`.
Stan wejściowy: 138 lokalnych ilustracji = 78 wydanych + 60 niewydanych
z Partii 07–16; 178 brakujących na 316 ćwiczeń. Po integracji szóstki:
144 lokalne = 78 wydanych + 66 niewydanych; 172 brakujące.
Produkcja pozostaje `1.9.0+22`. Użytkownik zatwierdził zakres i warianty;
zmianę kompozycji cw078 zapisano poniżej. Zachować wcześniejsze
pakiety, katalog i ID; operacje Git i publikacja wymagają osobnej prośby.

## Kadry i warianty

| ID | Ćwiczenie | Kadry | Wariant i kolejność |
|---|---|---:|---|
| cw073 | Unoszenie hantli w przód | 2 | Stój; obie ręce przy udach → obie do wysokości barków. |
| cw074 | Naprzemienne unoszenie hantli w przód | 3 | Prawa w górze → obie w połowie → lewa w górze. |
| cw075 | Odwrotne rozpiętki z hantlami w opadzie | 2 | Stały zawias około 45°; zwis → szeroki łuk w bok. |
| cw076 | Odwrotne rozpiętki z hantlami na ławce skośnej | 2 | Klatka na ławce około 35°; zwis → rozpiętka. |
| cw077 | Unoszenie hantli w kształt litery Y na ławce skośnej | 2 | Klatka na ławce około 35°; zwis → ramiona w Y, kciuki w górę. |
| cw078 | Pompki z biodrami uniesionymi wysoko | 2 | Pike na podłodze; ramiona wydłużone → głowa nisko, łokcie ugięte. |

### Układ i interpretacje

- `cw073`: dwa kadry obok siebie, od lewej do prawej; stała kamera
  przednio-boczna 3/4 ujawnia ruch przed ciałem, a nie w bok.
- `cw074`: trzy pionowe kolumny od lewej do prawej, ta sama kamera.
  Pokazać ciągłą zmianę stron: prawa opada, gdy lewa wznosi się.
  Środkowo obie ręce przed ciałem około 45° ponad pozycję zwisu.
  Nie zastępować sekwencji startem obu rąk na dole i dwoma niezależnymi
  powtórzeniami; katalog jawnie wskazuje jednoczesną zmianę kierunków.
- `cw073–cw074`: nachwyt. Przy udach grzbiety dłoni skierowane do przodu,
  po uniesieniu dłonie w dół. „Dłonie w dół” nie wymaga zginania nadgarstków
  w dolnej pozycji; orientacja wynika z pronowanego chwytu i unoszenia ramion.
- `cw075–cw078`: dwa poziome pasy pełnej szerokości, od góry do dołu.
  Dla rozpiętek i Y kamera boczno-tylna 3/4, ujawniająca oba ramiona,
  a przy ławce również kontakt klatki z krawędzią poduszki. Dla pike
  boczna 3/4, czytelny wysoki kąt bioder, dłonie, stopy i głowa.
- `cw075`: tułów około 45° do podłogi, nie pionowy i nie wymuszony poziom
  jak w good morning. Stałe niewielkie ugięcie kolan i łokci.
- `cw076–cw077`: wspólny wariant ławki około 35°, w zakresie 30–45°
  określonym dla cw076. Klatka i miednica podparte, obie stopy/przodostopia
  na podłodze. Głowa poza górną krawędzią poduszki, szyja neutralna.
  „Leżysz twarzą” oznacza leżenie przodem, nie dociskanie twarzy do ławki.
- `cw077`: ławka jest wymagana przez nazwę i wskazówki, mimo jej braku
  w polu sprzętu. Pokazać ją bez edycji katalogu. Y oceniać względem osi
  tułowia/głowy, nie wyłącznie pionu ekranu. Kciukowa strona dłoni ku
  górze; kciuk może pozostawać częścią zamkniętego chwytu.
- `cw078`: podstawowy pike, bez ławki, nogi wydłużone. Podparcie obu
  płaskich dłoni i obu przodostopi, pięty mogą być uniesione. Głowa
  zbliża się do podłogi między dłońmi, lecz nie staje się punktem podpory.
  Biodra pozostają wysoko; nie wymagać ich identycznej współrzędnej w fazach.

Rekomendowane trzy kadry cw074 uwidaczniają obie strony i przejście;
dwa pokazałyby tylko końce. Pełnoszerokie pasy rozpiętek/Y/pike ułatwiają
zmieszczenie rozstawu rąk, ławki lub podstawy V bez zmiany skali.

## Kontrakt wizualny

Jeden PNG 1024×1024 i końcowy WebP 512×512 na ID. Styl
`assets/exercises/cw256.webp`: kremowe tło, komiksowy kontur, ciemny strój,
twarz bez rysów. Bez tekstu, numerów, strzałek, timerów, watermarków,
duchów ruchu i zbędnego sprzętu. Nakładki mięśni nie są wymagane.

Wszystkie kadry danego ćwiczenia mają stałą kamerę, skalę i podłoże;
stopy i sprzęt podporowy zachowują położenie. Całe ciało, dłonie, stopy
oraz istotny sprzęt mieszczą się z marginesem, także w najszerszej fazie.
W pike dłonie również zachowują miejsca podparcia, ale inne części ciała
mogą przemieścić się naturalnie podczas zgięcia łokci.

`cw073–cw077`: dwa odrębne krótkie hantle, po jednym w każdej dłoni,
rzeczywiste uchwyty, neutralne nadgarstki. `cw078`: bez hantli.
Rozróżniać ciągłość chwytu i kierunek dłoni od samej osi ciężaru.
Naturalna okluzja dopuszczalna, jeśli obie kończyny i sprzęt pozostają
czytelne; nałożenie konturów w projekcji nie dowodzi przenikania.
Źródło, podgląd 512 px oraz finalne WebP wymagają odczytu.

## Sceny i odrzucenia

### cw073 — Dumbbell front raise — 2 kadry

1. Stabilny stój na szerokość bioder, dwa hantle przed udami, nachwyt,
   ramiona opuszczone, łokcie lekko ugięte.
2. Obie ręce równocześnie uniesione PRZED ciałem do wysokości barków,
   dłonie w dół, nadgarstki neutralne, ugięcie łokci niewielkie.

Odrzucić unoszenie bokiem, nad głowę, jednorącz, chwyt neutralny zamiast
nachwytu, kołysanie lub odchylenie tułowia, shrug i zablokowane łokcie.

### cw074 — Alternating front raise — 3 kolumny

1. Prawa ręka przed ciałem na wysokości barku, lewa blisko uda.
2. Obie ręce przed ciałem w połowie: prawa przechodzi w dół, lewa w górę,
   co wynika z kolejności kadrów; nie dodawać strzałek kierunkowych.
3. Lewa ręka na wysokości barku, prawa blisko uda.

Nachwyt, niewielkie ugięcie łokci; stały tułów, nogi i kamera. Odrzucić
obustronny wznos do barków w środku, pomylenie stron, zmianę kamery,
rotację tułowia, znikający opuszczony hantel i kołysanie.

### cw075 — Bent-over reverse flye — 2 poziome pasy

Góra: stały zawias około 45°, neutralne plecy, kolana lekko ugięte,
dwa hantle zwisają pod klatką, łokcie miękko ugięte.
Dół: ramiona szeroko w bok i nieco w tył, do płaszczyzny barków/tułowia,
łopatki zbliżone, nadal niewielkie zgięcie łokci. Tułów nie podnosi się.
Chwyt przy zwisie neutralny, ręce podążają naturalnie za łukiem ramion.

Odrzucić wiosłowanie z mocnym zgięciem łokci i hantlami przy biodrach,
wyprost tułowia, shrug, unoszenie w przód lub zbyt wysoko za plecy,
ugięcie nadgarstków, niewidoczny drugi chwyt i ucięte ciężary.

### cw076 — Chest-supported reverse flye — 2 poziome pasy

Góra: leżenie przodem na ławce około 35°, klatka i miednica w kontakcie
z poduszką, obie stopy/przodostopia na podłodze. Głowa wolna poza pad,
dwa hantle w zwisie, łokcie nieznacznie ugięte.
Dół: szeroki boczny łuk obu ramion, chwyt i zgięcie łokci naturalne,
klatka cały czas podparta, sprzęt i podpory bez zmian.

Odrzucić siedzenie lub leżenie na plecach, twarz wbita w poduszkę,
oderwanie klatki, zmianę nachylenia ławki, row, brak drugiego hantla,
kolizję dłoni/ciężarów z ławką i zbyt duże zgięcie łokci.

### cw077 — Y raise — 2 poziome pasy

Takie samo podparcie jak cw076. Góra: dwa hantle w zwisie pod barkami.
Dół: ramiona uniesione po skosie PRZED i NAD głowę, tworzą szerokie Y
względem osi tułowia, około 30–45° od osi głowy na każdą stronę,
łokcie wydłużone bez przeprostu, kciukowe strony dłoni ku górze.
Klatka podparta, barki bez wzruszenia, szyja neutralna.

Odrzucić boczne T jak cw076, wyciskanie z silnie zgiętymi łokciami,
wznos pionowo do sufitu zamiast Y względem tułowia, shrug, odrywanie
klatki, brak ławki, wymuszone otwarcie dłoni lub zmianę podporów.

### cw078 — Pike push-up — 2 poziome pasy

Góra: odwrócone V, biodra wysoko, nogi wydłużone, obie dłonie płasko
na podłodze około szerokości barków, oba przodostopia podparte;
ramiona wydłużone i szyja w osi tułowia.
Dół: łokcie ugięte około 45° względem tułowia, głowa obniżona między
dłońmi blisko podłoża z niewielkim prześwitem, biodra nadal wysoko.
Te same miejsca dłoni i stóp, bez podpory głową.

Odrzucić płaski plank lub zwykłą pompkę, klęk jako regresję, stopy na
ławce jako progresję cw079, stojenie na głowie, głowę podniesioną do
przodu, szerokie boczne łokcie i zmianę położenia rąk/stóp między fazami.

## Sześć promptów bazowych

Każdy prompt: blok wspólny + właściwa scena. Pierwsza referencja stylu
`/tmp/opencode/cw256-reference.png`; nie narzuca pozycji z referencji.

### Blok wspólny

```text
Use supplied image ONLY as style reference. Square 1024x1024, cream background, clean dark comic outlines, faceless adult in dark neutral clothes. Entire body, BOTH hands/feet and essential equipment inside every frame with generous margins. SAME camera, scale, floor and fixed supports across phases; moving limbs may move naturally as specified. Size for widest/highest pose. Coherent anatomy, actual grip/contact continuity, neutral wrists and neck, controlled spine. Natural partial occlusion only if limbs/equipment remain readable at512px; no fused weights, floating grips or physical collisions. No text, numbers, labels, arrows, timer, watermark, motion ghosts or extra figures. No required muscle overlays.
```

### cw073

```text
STANDING BILATERAL DUMBBELL FRONT RAISE, EXACTLY TWO SIDE-BY-SIDE PANELS LEFT TO RIGHT. Fixed front-side three-quarter camera makes FORWARD rather than lateral arm motion clear. TWO separate dumbbells with real handle grips, pronated grip: at thighs backs of hands face forward; at raised endpoint palms face DOWN, wrists stay straight. LEFT weights before thighs, softly bent elbows. RIGHT BOTH arms lifted in FRONT of body to SHOULDER HEIGHT, same mild elbow bend. Stable hip-width feet/torso, no swing, lean back, shrug, single-arm or overhead/lateral raise. No hand fusion or clipped weights.
```

### cw074

```text
ALTERNATING DUMBBELL FRONT RAISE, EXACTLY THREE VERTICAL COLUMNS LEFT TO RIGHT, SAME front-side camera/body/feet. TWO separate weights with pronated real handle grips and slightly bent elbows. LEFT anatomicalRIGHT arm FORWARD at shoulder height, LEFT arm down near thigh. CENTER BOTH arms FORWARD at midrange about45degrees above hanging position: right descending, left ascending as implied by frame sequence. RIGHT LEFT arm FORWARD at shoulder height, RIGHT arm down. BOTH weights visible throughout, no torso twist, simultaneous full-height bilateral raise, side switch error, camera change, swing, arrows or missing down-arm dumbbell.
```

### cw075

```text
BENT-OVER REVERSE DUMBBELL FLYE, EXACTLY TWO FULL-WIDTH HORIZONTAL ROWS TOP TO BOTTOM. SAME rear-side three-quarter camera reveals both arms and upper back, stable hip hinge with torso about45degrees to floor, neutral spine and mildly bent knees. TWO short weights, real grips, neutral wrists. TOP dumbbells hang UNDER CHEST, elbows slightly bent. BOTTOM sweep BOTH arms WIDE LATERALLY and slightly backward into shoulder/torso plane, keeping SAME SMALL elbow bend, controlled scapular retraction and SAME torso angle/feet. No row to hips, strong elbow curl, standing up, shrug, forward raise, overextension behind back or clipped full arm span.
```

### cw076

```text
CHEST-SUPPORTED REVERSE DUMBBELL FLYE, EXACTLY TWO FULL-WIDTH HORIZONTAL ROWS TOP TO BOTTOM. SAME rear-side three-quarter camera shows BOTH hands and side edge of bench contact. Adult PRONE on35degree incline bench, CHEST AND PELVIS touching pad, both feet/forefeet supported on floor, neutral neck with HEAD FREE beyond upper pad edge, not face pressed into cushion. TWO distinct dumbbells with actual handle grips. TOP hang below chest, mild elbow bend. BOTTOM open BOTH arms WIDE SIDEWAYS to shoulder/torso plane, same small elbow bend. Chest contact/bench angle/support feet stay fixed. No row, lifting chest, supine or seated pose, missing weight, bench collision, shrug or cropped hands.
```

### cw077

```text
PRONE INCLINE-BENCH DUMBBELL Y RAISE, EXACTLY TWO FULL-WIDTH HORIZONTAL ROWS TOP TO BOTTOM. SAME rear-side three-quarter camera makes BODY-RELATIVE Y clear. Adult prone on35degree bench, chest/pelvis supported, both feet/forefeet on floor, head free beyond upper pad edge and neutral neck. TWO short dumbbells with actual handle grips. TOP weights hanging under shoulders. BOTTOM raise BOTH long arms DIAGONALLY FORWARD AND OVERHEAD relative to torso, each30–45degrees outward from head/torso long axis, creating Y, NOT lateral T. Thumb sides face UP without opening grips, wrists straight. Same bench/supports, no shoulder shrug, elbow-bent press, vertical-to-ceiling arm substitute, chest lift, absent bench or clipped hands.
```

### cw078

```text
FLOOR PIKE PUSH-UP, EXACTLY TWO FULL-WIDTH HORIZONTAL ROWS TOP TO BOTTOM. SAME side three-quarter camera shows HIGH INVERTED-V hips, both palms/feet and head. NO dumbbells or bench. TOP long arms, both palms flat shoulder-width on floor, long legs with both forefeet supported, heels may lift, neutral neck. BOTTOM bend elbows about45degrees to torso, lower head BETWEEN HANDS close to floor but keep a SMALL GAP: head does NOT support body. Hips remain HIGH, not flat plank; same hand/foot support locations, natural hip movement allowed. No regular push-up, kneeling, feet elevation, headstand, forward-looking head, wide elbow flare or changed camera/scale.
```

## Przyszłe wykonanie i testy

Po zatwierdzeniu przygotować plan. Aktualny `main` w `/opt/fit`, bez
worktree; zachować poprzednie pakiety i przeczytać `docs/modules/training.md`.

1. Dopisać cw073–cw078 po cw072 przed cw251 do oczekiwań testu; fallback
   cw079 (elevated pike). Potwierdzić czerwony kontrakt brakującego cw073
   przed generacją, zmianą rejestru i integracją assetów.
2. Zapisać sześć osobnych promptów poza repozytorium, przejrzeć zgodność,
   następnie klarowność/geometrię. Porównać forward/lateral arc, zmianę
   stron cw074, flye/row oraz T/Y; osobno sprawdzić podpory ławki i pike.
3. Każde żądanie osobno w świeżym cwNNN-trial-NN przez
   `tools/benchmark_exercise_images.py --single-sunburst-medium`.
   Odczyt PNG i podglądu512 przed kolejnym żądaniem; bez drukowania sekretów.
   Po błędzie/niepewnym wyniku odczytać ledger, nie ponawiać automatycznie.
4. Korekta tylko nazwanego defektu, ostatni odrzucony PNG jako jedyna
   referencja. Po dwóch nieskutecznych korektach tego samego problemu
   zatrzymać próby i ocenić nową kompozycję przed dalszym płatnym działaniem.
5. Po akceptacji szóstki WebP przez `-resize 512x512 -strip -quality 90`,
   odczyt finalnych plików i dopisanie tych samych ID do illustratedExerciseIds.
6. Pełny Docker target verification: wersja, analiza, testy; 144 zgodne
   ID/pliki, decode512×512, fallbackcw079. Kontrola formatowania zmienionych
   Dartów i git diff --check. Bez zmiany modeli, zależności i Web SQLite.
7. Aktualizacja statusu:144/78/66/172/316, sześć wierszy, kadry2/3/2/2/2/2,
   sekcja „Siedemnasta partia”. Zapis faktycznych źródeł, przeglądów,
   korekt i deduplikowanych sukcesów ledgerów. Błędy bez danych kosztowych
   wykazać osobno, nie jako bezpłatne żądania. Produkcja nadal1.9.0+22.

## Samokontrola

- Sześć kolejnych ID; bazowy pike odróżniony od fallbackcw079.
- Pięć ćwiczeń z dwoma hantlami, pike bez ciężarów; ławka w cw076–cw077.
- Nachwyt front raise nie wymaga załamania nadgarstków przy udach.
- Cw074 uwzględnia jednoczesne przejście przeciwnych stron, nie reset obu rąk.
- Flye nie jest row; Y ma kierunek względem tułowia i kciuki ku górze.
- Kontakt klatki nie oznacza kontaktu twarzy; pike nie podpiera się głową.
- Kadry i docelowe liczniki spójne; stan wejściowy wynosił 138 ilustracji.

## Zatwierdzona zmiana kompozycji cw078

Po dwóch odrzuconych korektach poślizgu bliższej dłoni zatrzymano próby
starej kompozycji. Użytkownik zatwierdził nowy profil boczny zamiast 3/4,
bardziej kompaktowe odwrócone V oraz delikatne nieopisane szwy podłogi
pod kontaktami stóp i dłoni. Dwa poziome pasy, stała kamera/skala/podpory,
wydłużone nogi, wysokie biodra i prześwit pod głową pozostają wymagane.
W górze barki bliżej pionu nad dłońmi; w dole naturalny ruch tułowia/bioder
ma umożliwiać zgięcie łokci bez przesunięcia podpór. Szwy są elementem
podłogi, nie strzałkami, markerami lub etykietami.

## Wykonanie — 2026-10-14

Cała szóstka lokalnie zintegrowana i niewydana. Finalne WebP 512×512,
kadry 2/3/2/2/2/2. Źródła trial-01 dla cw073–cw076, correction-01 dla
cw077, new-01 dla cw078, wraz z promptami/podglądami/ledgerami w
`/tmp/opencode`. Odczyt bezpośredni i niezależne przeglądy zgodność→jakość.
Y poprawiono w zakresie czytelnego rozwidlenia i wspólnej skali obu scen.
Pike wykonano w zatwierdzonym nowym ujęciu po dwóch odrzuconych korektach
poślizgu dłoni; nowa kompozycja utrzymuje podpory i rozstaw dłonie–stopy.

10 udanych żądań, szacunek upper_bound_no_cache 0,228200 USD, bez błędów
HTTP; nie potwierdzone rozliczenie dostawcy. Docker batch-17-verified:
366 testów zaliczonych, analiza bez uwag, formatowanie 0 zmian.
Rejestr/oczekiwania/pliki: 144 ID, decode 512×512, fallback cw079.
Stan: 144 lokalne / 78 wydanych / 66 niewydanych / 172 brakujące /
316 ćwiczeń. Produkcja 1.9.0+22; bez commita, pusha i wdrożenia.
