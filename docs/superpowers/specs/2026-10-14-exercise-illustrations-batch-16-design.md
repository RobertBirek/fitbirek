# Ilustracje ćwiczeń — projekt Partii 16

## Zakres i stan wejściowy

Partia obejmuje `cw067–cw072`, zgodnie z `assets/data/exercises.json`.
Stan wejściowy: 132 lokalne ilustracje = 78 wydanych + 54 niewydane
z Partii 07–15; 184 brakujące na 316 ćwiczeń. Po integracji całej szóstki:
138 lokalnych = 78 wydanych + 60 niewydanych; 178 brakujących.
Produkcja pozostaje `1.9.0+22`. Użytkownik zatwierdził zakres i interpretację
chwytu cw067. Wykonanie zapisano poniżej; publikacja i operacje Git
wymagają osobnej prośby.
Zachować wcześniejsze niewydane pakiety i katalog bez zmian ID lub techniki.

## Kadry i wybrane warianty

| ID | Ćwiczenie | Kadry | Wariant i kolejność |
|---|---|---:|---|
| cw067 | Wyciskanie Arnolda z hantlami | 3 | Stój; przed klatką → rotacja przy barkach → nad głową. |
| cw068 | Wyciskanie hantli nad głowę chwytem neutralnym | 2 | Stój; przy uszach → nad głową, dłonie do siebie cały czas. |
| cw069 | Wyciskanie hantli nad głowę z wybiciem z nóg | 3 | Stój z ciężarami przy uszach → płytki dip → wyprost nóg i wyciskanie. |
| cw070 | Unoszenie hantli bokiem | 2 | Stój obunóż; ciężary przy udach → wysokość barków. |
| cw071 | Unoszenie hantli bokiem w staniu na jednej nodze | 2 | Prawa noga podporowa w obu fazach; dół → wysokość barków. |
| cw072 | Unoszenie hantli bokiem z pauzą | 2 | Stój obunóż; dół → góra, czas pauzy w katalogu. |

### Jawne interpretacje

- `cw067`: katalogowe „dłonie do siebie” przy początku przed klatką
  interpretować jako dłonie zwrócone ku WŁASNEJ twarzy/tułowiowi, zgodnie
  z nazwą Arnold press, a nie obustronny chwyt neutralny. Początek:
  supinacja, łokcie przed tułowiem; środek: częściowe otwarcie i obrót
  przedramion; koniec: dłonie do przodu, od twarzy. To interpretacja
  ilustracji, bez edycji katalogu. „Rotacja nadgarstków” oznacza zmianę
  orientacji chwytu przez ruch barków/przedramion, nie załamywanie stawu.
- `cw067–cw068`: wybrano stój, zgodny ze sprzętem katalogowym bez ławki.
- `cw069`: trzy kadry pokazują dip i wyprost nóg; prędkość oraz siła
  wybicia nie są mierzone na statycznym obrazie. Ostatni kadr pokazuje
  zakończenie po wyproście nóg, bez drugiego dipu jak w jerk.
- `cw071`: prawa noga podporowa; lewa lekko zgięta, stopa uniesiona nad
  podłogą i widoczna w obu fazach. Miednica stabilna, bez podpory meblem.
- `cw072`: pełny ruch z pauzą, nie osobne ćwiczenie czysto izometryczne.
  Dwa kadry, bez timera i sztucznego wyróżnika względem `cw070`.
  Pauza 2 sekundy pozostaje wyłącznie w katalogu.

### Dobór układu

Rekomendacja: trzy pionowe kolumny `cw067` i `cw069`, czytane od lewej
do prawej. Utrzymują czytelną sylwetkę w staniu i pokazują rotację/dip.
Dwa kadry pomijałyby odpowiednio zmianę chwytu lub pracę nóg.
`cw068`: dwa kadry obok siebie. `cw070–cw072`: dwa poziome pasy pełnej
szerokości, od góry do dołu, aby pełny rozstaw ramion mieścił się bez
ucięcia dłoni i zmiany skali. Wąskie kolumny wymuszałyby mniejszą postać.

## Kontrakt wizualny

Źródłowy PNG 1024×1024 i końcowy WebP 512×512 na każde ID. Wzorzec
`assets/exercises/cw256.webp`: kremowe tło, komiksowy kontur, ciemny strój,
twarz bez rysów. Bez tekstu, numerów, strzałek, timerów, watermarków,
duchów ruchu i zbędnego sprzętu. Nakładki mięśni nie są wymagane.

Każdy kadr mieści całe ciało, dłonie, stopy i oba hantle. Jedna stała
kamera przednio-boczna 3/4, skala i płaszczyzna podłogi dla danego ID.
Skalować do najszerszej/najwyższej fazy przed generacją, nie osobno do
każdej pozy. Dip zmienia wysokość ciała, nie kamerę lub poziom podłoża.

We wszystkich ćwiczeniach dwa osobne krótkie hantle, każdy z dwiema
głowicami i rzeczywistym uchwytem obejmowanym przez jedną dłoń. Neutralne
nadgarstki, spójna anatomia palców i kciuków. Ocenić orientację dłoni
na podstawie chwytu i przedramienia, nie samej osi ciężaru. Naturalne
częściowe zasłonięcie dopuszczalne przy czytelnej ciągłości, bez
przenikania, scalania dwóch ciężarów lub odłączonych dłoni.

## Sceny i odrzucenia

### cw067 — Arnold press — 3 kolumny

1. Stój na szerokość bioder, dwa hantle przed górną klatką, dłonie
   ku własnej twarzy, łokcie ugięte i z przodu, sprzęt nie styka się.
2. Hantle uniesione do okolic barków/uszu, częściowa rotacja na zewnątrz,
   łokcie otwarte umiarkowanie, dłonie w przejściu ku chwytowi do przodu.
3. Dwa hantle nad głową, dłonie do przodu, ramiona wydłużone bez
   przeprostu łokci. Stopy, kolana i miednica stabilne we wszystkich fazach.

Odrzucić chwyt neutralny we wszystkich fazach, brak rotacji, obrót
wyłącznie głowic bez zmiany dłoni, skręcone/załamane nadgarstki, zmianę
kamery, łuk lędźwiowy, wybicie nogami, scalone i ucięte ciężary.

### cw068 — Neutral grip DB press — 2 kadry

1. Stabilny stój na szerokość bioder, dwa hantle przy uszach; dłonie
   skierowane ku SOBIE NAWZAJEM, łokcie nieco przed tułowiem.
2. Ciężary nad głową, ramiona niemal wyprostowane bez przeprostu;
   dłonie nadal ku sobie, bez rotacji jak w Arnold press.

Odrzucić nachwyt z dłońmi do przodu, obrót chwytu, rozsuwanie ciężarów
na szerokie boki, zbyt duży łuk pleców, dip, scalone hantle i brak chwytu.

### cw069 — Dumbbell push press — 3 kolumny

1. Stabilny stój, dwa hantle przy uszach, dłonie do przodu, ciężary nad
   przedramionami; tułów wyprostowany, stopy na szerokość bioder.
2. Krótkie płytkie ugięcie kolan i bioder, pionowy tułów, hantle nadal
   przy uszach. Obie stopy pozostają podparte, bez głębokiego przysiadu.
3. Kolana i biodra wyprostowane, ciężary wyciśnięte nad głowę, tułów
   stabilny. Ta sama pozycja stóp, bez lotu i ponownego ugięcia pod ciężarem.

Odrzucić squat press, brak dipu, samo strict press, odchylenie tułowia,
zmianę skali/podłogi imitującą dip, jerk z drugim ugięciem i zbędny wyskok.

### cw070 — Dumbbell lateral raise — 2 poziome pasy

Góra: stabilny stój obunóż, małe stałe pochylenie w przód, hantle obok
ud, łokcie lekko ugięte. Dół: ramiona uniesione bokiem do wysokości
barków, zachowane małe zgięcie łokci, nadgarstki neutralne i dłonie
skierowane w dół; bez wymuszonego obrotu „wylewania dzbanka”.
Stopy i tułów bez ruchu; barki nie wznoszą się do uszu.

Odrzucić front raise, hantle nad głową, shrug, proste zablokowane łokcie,
kołysanie, ucięte ciężary i nadmierne pochylenie lub duży skręt chwytu.

### cw071 — Single-leg lateral raise — 2 poziome pasy

Ten sam ruch ramion jak `cw070`, z prawą stopą jako jedyną podporą
w obu pasach. Lewa noga lekko zgięta, lewa stopa widocznie w powietrzu,
nie dotyka podłoża ani mebla. Góra: ciężary przy udach; dół: ciężary
na wysokości barków. Stabilna miednica, brak bocznego przechyłu.

Odrzucić zamianę nogi podporowej między fazami, dwie stopy na ziemi,
ukrytą podporę, podskok, unoszenie wyprostowanej nogi do wysokiego L,
rotację bioder, przechylenie tułowia, brak jednego hantla lub chwytu.

### cw072 — Paused lateral raise — 2 poziome pasy

Góra: hantle przy udach; dół: ramiona na wysokości barków, lekkie zgięcie
łokci i neutralne nadgarstki, stabilny stój obunóż. Kontrolowane
utrzymanie górnej pozycji bez kołysania, bez wizualnej miary czasu.
Może być podobne do `cw070`; nie dodawać innej techniki dla wyróżnienia.

Odrzucić timer/licznik/napis „2 sek”, fikcyjny trzeci powtórzony kadr,
jednonóż, shrug, front raise, zablokowane łokcie, zmienną kamerę.

## Sześć promptów bazowych

Każdy prompt: poniższy blok wspólny + odpowiednia scena. Pierwsza
referencja `/tmp/opencode/cw256-reference.png`, użyta wyłącznie jako styl.

### Blok wspólny

```text
Use supplied image ONLY as style reference. Square 1024x1024, cream background, clean dark comic outlines, faceless adult in dark neutral clothes. Entire body, BOTH hands/feet and TWO separate short dumbbells fit each frame with generous margins. SAME fixed front-side three-quarter camera, adult scale, floor plane and support-foot locations across phases. Size adult for the widest/highest pose. Each hand grips a real dumbbell handle, connected fingers/thumbs, neutral wrist, coherent anatomy, no fused weights or floating grips. Natural partial occlusion only if limb/equipment continuity remains readable at 512x512. Neutral neck and controlled spine. No text, labels, numbers, arrows, timer, watermark, ghosts or extra figures. No required muscle overlays.
```

### cw067

```text
STANDING ARNOLD PRESS, EXACTLY THREE VERTICAL COLUMNS LEFT TO RIGHT. Stable hip-width feet, knees and pelvis in ALL columns, no leg drive. LEFT: two separate dumbbells in front of upper chest, palms face OWN FACE/TORSO, elbows bent and forward. CENTER: weights rising near shoulders/ears, forearms rotate outward partway, elbows moderately open, intermediate grip orientation. RIGHT: two weights overhead, palms face FORWARD AWAY FROM FACE, arms long without elbow hyperextension. Show actual gradual palm/forearm rotation, NOT twisting wrists or rotating weight heads alone. No neutral grip unchanged throughout, lumbar arch, clipped overhead weights or merged hands.
```

### cw068

```text
STANDING NEUTRAL-GRIP DUMBBELL PRESS, EXACTLY TWO SIDE-BY-SIDE PANELS LEFT TO RIGHT. Stable hip-width feet/knees/pelvis, no dip. LEFT two distinct dumbbells at ear height, palms FACE EACH OTHER, elbows a little forward, wrists neutral. RIGHT press overhead, arms nearly straight, palms STILL FACE EACH OTHER, NO grip rotation. Expose real handle grips and distinguish this from palms-forward strict press and Arnold press. No weights spread far sideways, back arch, elbow hyperextension, merged dumbbells or clipped hands.
```

### cw069

```text
DUMBBELL PUSH PRESS, EXACTLY THREE VERTICAL COLUMNS LEFT TO RIGHT, SAME camera and ground level. LEFT upright hip-width stance, two dumbbells at ears with palms forward. CENTER a SHORT SHALLOW DIP by bending knees/hips slightly, torso stays vertical, both feet supported, weights STILL AT EARS. RIGHT knees/hips straighten and weights finish OVERHEAD, neutral braced torso, long arms. SAME foot positions throughout, no jumping or second dip under weights. Show leg-assisted sequence, not a squat or strict arm-only press. No deep squat, jerk catch, rocking torso, scale/floor shifts, extra weights or clipped overhead hands.
```

### cw070

```text
STANDING DUMBBELL LATERAL RAISE, EXACTLY TWO FULL-WIDTH HORIZONTAL ROWS TOP TO BOTTOM. Same small forward torso inclination, hip-width grounded stance, head neutral in both rows. TOP two dumbbells beside thighs, elbows softly bent. BOTTOM raise BOTH arms LATERALLY to SHOULDER HEIGHT, elbows STILL SOFTLY BENT, wrists neutral, palms down without exaggerated pouring/internal twist. Shoulders stay away from ears; keep both weights/hands inside margins at full span. No front raise, overhead arms, shrug, locked elbows, body swing, grip loss or changed stance.
```

### cw071

```text
SINGLE-LEG DUMBBELL LATERAL RAISE, EXACTLY TWO FULL-WIDTH HORIZONTAL ROWS TOP TO BOTTOM. RIGHT foot is the ONLY floor support in BOTH rows, left knee mildly bent and LEFT FOOT VISIBLY LIFTED with clear gap above floor. Same support side, stable level pelvis and torso, no furniture/support. TOP two weights beside thighs. BOTTOM both arms rise laterally to shoulder height, elbows softly bent, wrists neutral and palms down. Entire raised foot and both weights/hands readable. No side switch, two grounded feet, hop, high straight leg lift, hip twist, body lean or cropped dumbbell.
```

### cw072

```text
PAUSED DUMBBELL LATERAL RAISE, EXACTLY TWO FULL-WIDTH HORIZONTAL ROWS TOP TO BOTTOM. Stable hip-width TWO-FOOT stance, same small torso inclination and camera. TOP two weights beside thighs, elbows softly bent. BOTTOM both arms at shoulder height with slight elbow bend, neutral wrists and palms down, controlled held endpoint, no shrug or sway. Hold duration is NOT visually measured: no timer, number, text or repeated third frame. Pose may resemble normal lateral raise; do not invent different technique to distinguish it. No single-leg stance, front raise, overhead arms, locked elbows, extra figures or clipped full arm span.
```

## Przyszłe wykonanie i testy

Po zatwierdzeniu przygotować plan wykonania. Aktualny `main` w `/opt/fit`,
bez worktree; zachować wszystkie wcześniejsze niewydane zmiany.
Przeczytać `docs/modules/training.md` przed pracą nad integracją.

1. Dopisać cw067–cw072 po cw066 i przed cw251 do oczekiwań testu;
   fallback cw073 (front raise). Potwierdzić czerwony kontrakt brakującego
   cw067 przed generacją i zmianą rejestru.
2. Zapisać sześć osobnych promptów poza repozytorium. Przejrzeć zgodność,
   następnie klarowność i geometrię. Porównać dłonie cw067/cw068, dip
   cw069 ze strict press cw066 i podporę cw071 ze stojem obunóż.
3. Każde żądanie osobno w świeżym `cwNNN-trial-NN`, przez
   `tools/benchmark_exercise_images.py --single-sunburst-medium`.
   Odczyt źródła i podglądu 512 px przed następnym płatnym żądaniem.
   Bez automatycznych retry po niepewnym wyniku i bez drukowania sekretów.
4. Korekta wyłącznie nazwanego defektu, ostatni odrzucony PNG jako jedyna
   referencja. Po dwóch nieskutecznych korektach tego samego problemu
   zatrzymać próby i ocenić nowe ujęcie przed dalszym płatnym działaniem.
5. Integracja dopiero po akceptacji całej szóstki. WebP przez
   `-resize 512x512 -strip -quality 90`, odczyt finalnych plików,
   dopisanie tych samych ID do `illustratedExerciseIds`.
6. Pełny Docker target `verification`: kontrola wersji, analiza i testy,
   dokładnie 138 zgodnych ID/plików, dekodowanie 512×512, fallback cw073.
   Kontrola formatowania zmienionych Dartów i `git diff --check`.
7. Status: 138 / 78 / 60 / 178 / 316, sześć wierszy, układ 3/2/3/2/2/2,
   sekcja „Szesnasta partia”. Zapis rzeczywistych źródeł, przeglądów,
   korekt, unikalnych zakończonych żądań i szacunków ledgerów. Produkcja
   nadal 1.9.0+22; publikacja i operacje Git tylko na osobną prośbę.

## Samokontrola

- Sześć kolejnych ID; obecne assety i katalog bez zmian.
- Rozróżnione orientacje dłoni Arnold/neutral i jawna interpretacja cw067.
- Rotacja nie wymaga zginania nadgarstków; trzy fazy dipu nie wymagają lotu.
- Najszersze fazy wznosów mają pełną szerokość, jedna noga cw071 jawnie wybrana.
- Pauza cw072 jest katalogowa; dwa kadry nie udają pomiaru czasu.
- Kadry i liczniki spójne; stan wejściowy wynosił 132 ilustracje.

## Wykonanie — 2026-10-14

Cała szóstka lokalnie zintegrowana i niewydana; wszystkie assety WebP 512×512.
Kadry i warianty zachowano: 3/2/3/2/2/2, trzy pionowe kolumny cw067/cw069,
dwa kadry obok siebie cw068 i dwa poziome pasy cw070–cw072.
Źródła correction-01 dla cw067–cw068, trial-01 dla cw069–cw072, w katalogach
`/tmp/opencode`. Sprawdzono orientację dłoni, podparcia, dip i brak timerów.

Pierwsza próba cw068 zakończyła się HTTP error bez obrazu i danych kosztu.
Po odczycie ledgeru i bez automatycznego retry uzyskano wyraźną zgodę
użytkownika na nowe żądanie trial-02. Potem korekta naprawiła neutralny
chwyt; cw067 poprawiono w zakresie odstępu ciężarów i fazy pośredniej.
Bezpośredni odczyt źródeł/podglądów i niezależne przeglądy zgodność→jakość.
9 prób: 8 udanych, 1 HTTP error z nieznanym kosztem. Znana suma szacunków
upper_bound_no_cache udanych żądań 0,182506 USD, nie rozliczenie dostawcy.

Docker fit-web:batch-16-verified: 366 testów zaliczonych, analiza bez uwag,
138 zgodnych plików/rejestru/oczekiwań, fallback cw073; formatowanie 0 zmian.
Stan: 138 lokalnych / 78 wydanych / 60 niewydanych / 178 brakujących / 316 ćwiczeń.
Produkcja 1.9.0+22, bez commita/pusha/wdrożenia.
