# Ilustracje ćwiczeń — projekt Partii 15

## Zakres i stan wejściowy

Zakres: `cw061–cw066`, zgodnie z `assets/data/exercises.json`.
Nie zmieniać nazw, ID, wskazówek ani danych katalogowych.
Stan wejściowy: 126 ilustracji, 78 wydanych i 48 lokalnych, niewydanych z Partii
07–14; 190 brakujących na 316 ćwiczeń. Po integracji całej Partii 15:
132 lokalne = 78 wydanych + 54 niewydane; 184 brakujące.
Produkcja pozostaje `1.9.0+22`. Użytkownik zatwierdził zakres, kadry
i interpretację cw064; wykonanie zapisano poniżej. Publikacja i operacje
Git wymagają osobnej prośby.

## Zatwierdzone kadry i warianty

| ID | Ćwiczenie | Kadry | Wariant i kolejność |
|---|---|---:|---|
| cw061 | Przenoszenie ramion łukiem nad głowę w leżeniu na brzuchu | 3 | Trzy poziome pasy: ręce przy biodrach → T → nad głową. |
| cw062 | Skłony tułowia z hantlem i cofnięciem bioder | 2 | Jeden hantel oburącz przed klatką: stój → zawias biodrowy. |
| cw063 | Rumuński martwy ciąg z hantlami | 2 | Dwa hantle: stój → zawias, ciężary przy goleniach. |
| cw064 | Wiosłowanie oburącz hantlem opartym jednym końcem w rogu | 2 | Jeden krótki hantel: ręce wydłużone → przyciągnięcie wolnego końca. |
| cw065 | Wyciskanie hantli nad głowę w siadzie | 2 | Siad na ławce: ciężary przy uszach → wyciskanie. |
| cw066 | Wyciskanie hantli nad głowę w staniu | 2 | Stój: ciężary przy uszach → wyciskanie bez pracy nóg. |

Rekomendacja: trzeci kadr `cw061` pokazuje łuk bez strzałek. Dwa kadry
pokazałyby tylko końce ruchu; trzy wąskie kolumny zmniejszałyby czytelność
kończyn. Pozostałe ćwiczenia mają dwie odrębne, wystarczające fazy.

`cw062`: katalog dopuszcza przednią i tylną pozycję hantla; wybrano
przednią. Obie dłonie podpierają górną głowicę jednego pionowego hantla,
dolna głowica pozostaje wolna. Nie zmieniać chwytu między fazami.

`cw064`: zachować dosłowny sprzęt katalogowy: jeden krótki hantel,
jedna głowica podparta przy styku podłogi i ścian, druga trzymana oburącz.
„Ciągnij do klatki” interpretować jako kierunek przyciągnięcia, nie wymóg
dotknięcia klatki. Podparta głowica jest stałym punktem obrotu; wolna
głowica porusza się po łuku o niezmiennym promieniu odpowiadającym długości
hantla. Nie wydłużać uchwytu i nie zastępować sprzętu sztangą landmine.
Oceniać geometrię obu faz przed płatną korektą; jeśli ruch wymaga odrywania
podpartego końca lub nie daje się czytelnie przedstawić, zatrzymać próby
i zgłosić konkretną niezgodność zamiast zmieniać ćwiczenie.

`cw065`: ławka z niemal pionowym oparciem, pośladki na siedzisku,
plecy przy oparciu i obie stopy na podłodze. Dwa osobne hantle,
nachwyt, przedramiona pod ciężarami, łokcie nieco przed płaszczyzną tułowia.
`cw066`: ten sam podstawowy chwyt; stopy na szerokość bioder, stabilna
miednica i kolana, bez przysiadu lub wybicia jak w push press.

## Kontrakt wizualny

- Wzorzec stylu: `assets/exercises/cw256.webp`; kremowe tło, komiksowy
  kontur, twarz bez rysów, ciemny strój. Bez napisów, numerów, strzałek,
  timerów, watermarków, duchów ruchu i zbędnego sprzętu.
- Jeden źródłowy PNG 1024×1024 i jeden końcowy WebP 512×512 na ćwiczenie.
- `cw061`: trzy poziome pasy pełnej szerokości, czytane od góry do dołu.
  Jedna stała boczno-tylna kamera 3/4, dostatecznie podwyższona, aby
  rozróżnić obie ręce, ale z czytelnym kontaktem tułowia i nóg z podłogą.
  Skala dobrana do najszerszego T; nie ucinać dłoni w środkowym kadrze.
- `cw062–cw066`: dwa kadry obok siebie, od lewej start do prawej aktywna
  faza. Stała kamera przednio-boczna lub boczna 3/4, skala, stopy,
  podparcia i sprzęt. Pokazać całe ciało i wszystkie istotne kontakty.
- Liczyć hantle i śledzić połączenie każdej dłoni z rzeczywistym chwytem.
  Naturalne częściowe zasłonięcie jest dopuszczalne, jeśli widać ciągłość
  sprzętu i odrębne kończyny. Samo nałożenie konturów w projekcji nie
  dowodzi fizycznego przenikania; odłączone lub niemożliwe chwyty odrzucić.
- Ocena w źródle i 512 px, w tym po końcowej konwersji do WebP.

## Sceny i kryteria odrzucenia

### cw061 — Reverse snow angel — 3 kadry

Leżenie przodem, brzuch, miednica i nogi na podłodze, szyja neutralna,
wzrok w podłogę. Obie ręce lekko nad podłożem we wszystkich fazach,
łokcie wydłużone, dłonie skierowane w dół:
1. Ramiona wzdłuż tułowia, dłonie obok bioder, bez opierania rąk o podłoże.
2. Ramiona szeroko na boki w T, obie dłonie czytelne, bez dodatkowych rąk.
3. Obie ręce przeniesione nad głowę, nadal lekko uniesione.

Odrzucić uniesienie nóg jak w Superman, przejście do klęku lub podporu,
zgięte łokcie zamiast szerokiego łuku, podparcie na dłoniach, zadzieranie
głowy, ucięte dłonie, zmianę kamery i strzałki zastępujące środkową fazę.

### cw062 — Dumbbell good morning — 2 kadry

Boczna 3/4 kamera pokazuje położenie bioder i ciężaru:
1. Stabilny stój, lekko ugięte kolana, jeden pionowy hantel oburącz przed
   klatką w wybranym chwycie pod górną głowicą.
2. Biodra cofnięte, tułów z neutralnymi plecami zbliżony do równoległości
   z podłogą, kolana nadal tylko lekko ugięte. Hantel pozostaje przy
   klatce i obraca się wraz z tułowiem; nie musi pozostawać pionowy w świecie.

Odrzucić squat, głębokie ugięcie kolan, okrągłe plecy, opuszczanie hantla
do goleni jak RDL, tylny chwyt za karkiem, dwa hantle i zmianę dłoni.

### cw063 — Dumbbell RDL — 2 kadry

Ta sama kamera i pozycja stóp:
1. Stój, po jednym hantlu w każdej dłoni, oba ciężary przed udami,
   ramiona wydłużone, kolana lekko ugięte.
2. Biodra cofnięte, proste plecy, dłonie i dwa hantle blisko nóg na
   wysokości goleni. Łokcie pozostają wydłużone, bez wiosłowania.

Odrzucić przysiad, round-back, ciężary daleko przed nogami, kontakt hantli
z podłogą jako konieczny cel, jeden wspólny ciężar, zgięcie łokci i
jednonóż jako progresję zamiast podstawowego wariantu.

### cw064 — Landmine-style row with dumbbell — 2 kadry

Przednio-boczna 3/4 kamera pokazuje narożnik, podpartą głowicę i obie dłonie:
1. Stabilny zawias biodrowy, neutralne plecy, lekko ugięte kolana.
   Jedna głowica krótkiego hantla oparta przy podłodze w rogu, wolna
   głowica trzymana oburącz, ramiona wydłużone.
2. Ten sam zawias i podparcie, wolna głowica przyciągnięta ku klatce
   w granicach promienia obrotu, łokcie ugięte i cofnięte, bez rotacji tułowia.

Odrzucić odrywającą się kotwę, przesunięcie narożnika, teleportację
ciężaru, zmienną długość uchwytu, sztangę zamiast hantla, jeden chwyt
zamiast obu, wyprost tułowia zastępujący wiosłowanie i przenikanie dłoni.

### cw065 — Seated dumbbell overhead press — 2 kadry

Stała przednio-boczna 3/4 kamera, ławka z niemal pionowym oparciem:
1. Stabilny siad, dwa hantle na wysokości uszu, chwyty nachwytem,
   nadgarstki neutralne, łokcie lekko przed tułowiem.
2. Oba ciężary wyciśnięte nad głowę, ramiona prawie całkowicie
   wyprostowane bez przeprostu łokci. Zachowane podparcie pleców,
   pośladków i obu stóp, brak dużego łuku lędźwiowego.

Odrzucić wyciskanie na skosie jak chest press, brak drugiego hantla,
oderwanie pośladków/stóp, szerokie łokcie za tułowiem, wymuszoną zmianę
chwytu i ucięte ciężary w górnym kadrze.

### cw066 — Standing dumbbell overhead press — 2 kadry

Stała przednio-boczna 3/4 kamera:
1. Stój na szerokość bioder, napięty tułów, dwa hantle przy uszach,
   neutralne nadgarstki, łokcie pod ciężarami i lekko z przodu.
2. Oba ciężary nad głową, wydłużone ramiona; głowa lekko w przód
   pod ciężarami, bez zadzierania brody. Stopy, kolana i biodra stabilne,
   brak wybicia nogami i odchylenia lędźwiowego.

Odrzucić push press, przysiad, wysunięcie bioder, duży łuk pleców,
jednorącz, Arnold press z rotacją dłoni i scalone lub ucięte hantle.

## Prompty do przygotowania przed wykonaniem

Każdy prompt składa się z bloku wspólnego i poniższej sceny. Referencja
stylu dla pierwszych prób: `/tmp/opencode/cw256-reference.png`.

### Blok wspólny

```text
Use supplied image only as STYLE reference. Square 1024x1024, cream background, clean dark comic outlines, faceless adult in dark neutral clothes. Entire body, both hands, both feet and essential equipment inside each frame with generous margins. SAME camera, adult scale, grounded support contacts and fixed equipment positions across phases; the moving weight and limbs may move as explicitly described. Coherent anatomy and actual grips, no fused limbs, disconnected hands, floating apparatus or physical collisions. Natural partial occlusion is allowed only when limb/equipment continuity is readable at 512x512. Neutral neck and controlled spine. No text, labels, numbers, arrows, timers, watermarks, ghosts or extra figures. No required muscle overlays.
```

### cw061

```text
REVERSE SNOW ANGEL. EXACTLY THREE FULL-WIDTH HORIZONTAL ROWS stacked TOP TO BOTTOM. Same moderately elevated rear-side three-quarter camera revealing BOTH arms, whole prone body and floor support. Scale for widest T pose. Abdomen, pelvis and BOTH legs remain on floor in ALL rows; neutral downward gaze. Both straight arms hover slightly above floor, palms down throughout. TOP arms alongside torso, hands near hips. MIDDLE arms spread laterally into a wide T, both hands visible. BOTTOM arms swept overhead, both hands visible. Only arms sweep, no lifted legs or whole-body flight, no bent-elbow row, hand support, clipped T hands or motion arrows.
```

### cw062

```text
DUMBBELL GOOD MORNING, EXACTLY TWO side-by-side panels LEFT TO RIGHT. Fixed side three-quarter view. ONE short dumbbell held in front of chest with BOTH hands securely cupping below its upper head, lower head free, not behind neck. LEFT upright stable stance, softly bent knees. RIGHT hips move BACK, torso inclines nearly horizontal with neutral straight back, knees stay only slightly bent, NOT a squat. Dumbbell stays close to chest and naturally tilts WITH torso while the same two-hand grip remains unchanged. Full feet and both heads visible. No lowering the weight toward shins as in RDL, second weight, round back or deep knee bend.
```

### cw063

```text
DUMBBELL ROMANIAN DEADLIFT, EXACTLY TWO side-by-side panels LEFT TO RIGHT. Fixed side three-quarter view. TWO distinct short dumbbells, one actual handle gripped per hand, arms straight. LEFT standing with weights in front of thighs and softly bent knees. RIGHT hips pushed BACK, neutral straight back, dumbbells descend CLOSE ALONG legs to SHIN HEIGHT, elbows remain straight. Feet and mild knee bend stable across phases, not a squat or row. Both distinct weights and grips readable despite natural overlap. No one shared weight, floor-touch requirement, large forward weight gap, bent-elbow pull, rounded back or single-leg variation.
```

### cw064

```text
TWO-HAND CORNER-PIVOT DUMBBELL ROW, EXACTLY TWO side-by-side panels LEFT TO RIGHT. Fixed front-side three-quarter view exposes floor/wall corner, both hands and ONE SHORT ordinary dumbbell with two heads and a short handle, NOT a barbell or long landmine rod. One head supported at the floor/wall corner remains the SAME fixed pivot in both panels. BOTH hands securely grasp the OTHER head, no hand on the pivot head. LEFT hip-hinged adult with neutral back and slightly bent knees, arms lengthened. RIGHT same hip hinge, pull the held head upward TOWARD chest by bending elbows back; motion follows a SMALL physically possible arc around the fixed head, with EXACTLY the same dumbbell length and pivot. Do NOT force chest contact by stretching the equipment or lifting the supported head. No torso twist, standing up, floating anchor, disconnected grip or extra weight.
```

### cw065

```text
SEATED DUMBBELL OVERHEAD PRESS, EXACTLY TWO side-by-side panels LEFT TO RIGHT, fixed front-side three-quarter camera. Sit on a bench with nearly upright backrest, buttocks on seat, back supported, BOTH feet flat on floor in both phases. TWO separate dumbbells, actual handles grasped with palms facing forward, neutral wrists. LEFT weights at EAR HEIGHT, elbows a little FORWARD of torso, forearms beneath weights. RIGHT press both weights overhead, arms nearly fully extended without hyperextending elbows. Same seated torso and supports, no lumbar arch, wide rear elbows, incline chest press, changed grip, fused weights, lost foot contact or cropped overhead dumbbells.
```

### cw066

```text
STANDING STRICT DUMBBELL OVERHEAD PRESS, EXACTLY TWO side-by-side panels LEFT TO RIGHT, fixed front-side three-quarter camera. TWO separate dumbbells with real handle grips, palms forward and neutral wrists. Stable hip-width stance, knees and hips unchanged in BOTH phases. LEFT weights at EAR HEIGHT, forearms under weights and elbows slightly forward. RIGHT press both weights straight overhead, arms lengthened, head slightly forward under weights with neutral neck. Brace trunk and keep pelvis neutral, no leg drive or squat, no push press, lumbar arch, hip thrust, Arnold grip rotation, single-arm version, fused or cropped weights.
```

## Przyszłe wykonanie i weryfikacja

Po zatwierdzeniu specyfikacji przygotować szczegółowy plan wykonania.
Zachować aktualny `main` w `/opt/fit`, bez worktree, oraz wszystkie
niewydane zmiany Partii 07–14. Przeczytać `docs/modules/training.md`.

1. Dopisać `cw061–cw066` do oczekiwanych ID testu po cw060, przed cw251;
   fallback przenieść na `cw067` (Arnold press). Potwierdzić czerwony
   kontrakt przed integracją rejestru i nowych assetów.
2. Zapisać sześć osobnych promptów poza repozytorium, przejrzeć zgodność
   z katalogiem, następnie klarowność i geometrię. W cw064 osobno sprawdzić
   stały pivot, długość hantla i możliwość obu chwytów w obu fazach.
3. Każde płatne żądanie osobno, świeży katalog `cwNNN-trial-NN`, wyłącznie
   `tools/benchmark_exercise_images.py --single-sunburst-medium`.
   Odczytać źródło i podgląd 512 px przed kolejnym żądaniem. Nie retryować
   automatycznie wyniku niepewnego. Nie drukować sekretów ani środowiska.
4. Korekta nazwanego defektu z ostatnim odrzuconym PNG jako jedyną
   referencją. Po dwóch nieskutecznych korektach tego samego problemu
   zatrzymać próby i ocenić zmianę kompozycji przed dalszym płatnym ruchem.
5. Po zaakceptowaniu wszystkich sześciu źródeł konwersja do WebP przez
   `-resize 512x512 -strip -quality 90`, odczyt końcowych plików i dopisanie
   tych samych ID do `illustratedExerciseIds`.
6. Pełny Docker target `verification`: kontrola wersji, analiza i testy;
   dokładnie 132 zgodne ID/pliki, dekodowanie 512×512 i fallback cw067.
   Kontrola formatowania zmienionych Dartów i `git diff --check`.
7. Aktualizacja statusu i zapis rzeczywistych źródeł, przeglądów, prób,
   liczby unikalnych zakończonych żądań i szacunków z ledgerów. Liczniki:
   132 / 78 / 54 / 184 / 316. Sekcja „Piętnasta partia”, układ 3/2/2/2/2/2.
   Produkcja i wersja bez zmian; publikacja wymaga osobnej prośby.

## Samokontrola projektu

- Sześć kolejnych ID, bez zmiany istniejącego katalogu i wcześniejszych assetów.
- Wszystkie warianty, chwyty, liczby ciężarów i kontakty wskazane jawnie.
- cw061 nie jest Supermanem: tylko ramiona pracują, nogi pozostają podparte.
- cw062 zachowuje ciężar przy klatce, cw063 opuszcza dwa ciężary przy goleniach.
- cw064 zachowuje rzeczywisty krótki sprzęt i jego promień, bez wymuszania
  niemożliwej wysokości; interpretacja kierunku przyciągnięcia jest jawna.
- cw065 i cw066 różnią się podporami, a cw066 nie pokazuje push press.
- Kadry i docelowe liczniki są spójne; stan wejściowy wynosił 126 ilustracji.

## Wykonanie — 2026-10-14

Pakiet lokalnie zintegrowany, niewydany. Zaakceptowane źródła:
trial-01 dla cw061, cw063, cw065; correction-01 dla cw062 i cw066;
correction-02 dla cw064. Prompty, PNG, podglądy i ledgery pozostają
w `/tmp/opencode/cwNNN-*`. Wszystkie końcowe pliki są WebP 512×512.
Kadry i warianty zachowano bez zmian względem zatwierdzonego projektu.

Cw062 poprawiono w zakresie głębokości zawiasu i podparcia dłoni pod
górną głowicą. Cw064 poprawiono w zakresie krótkiej długości sprzętu
oraz utrzymania podpartego końca; pozostawiono mały częściowy zakres,
bez wymuszania kontaktu z klatką. Cw066 poprawiono w zakresie stóp,
nadgarstków i położenia głowy. Źródła oraz podglądy przejrzano bezpośrednio
i niezależnie, z kolejnością zgodność → jakość.

10 udanych pojedynczych żądań, szacunek upper_bound_no_cache 0,227790 USD.
Docker `fit-web:batch-15-verified`: analiza bez uwag, 366 testów zaliczonych,
132 zgodne pliki/rejestr/oczekiwania, poprawny fallback cw067. Kontrola
formatowania nie wymagała zmian. Stan: 132 lokalne / 78 wydanych /
54 niewydane / 184 brakujące / 316 ćwiczeń; produkcja 1.9.0+22.
