# Ilustracje ćwiczeń — projekt Partii 22

## Zakres i stan wejściowy

Projekt zatwierdzony przez użytkownika 2026-10-15: `cw103–cw108`
z `assets/data/exercises.json`.
Stan wejściowy: 168 lokalnych ilustracji = 78 wydanych + 90 niewydanych
z Partii 07–21; 148 brakujących na 316 ćwiczeń. Po integracji szóstki:
174 lokalne = 78 wydanych + 96 niewydanych; 142 brakujące.
Produkcja `1.9.0+22`. Na etapie przygotowania zapisujemy projekt i prompty;
generacja oraz integracja następują po zatwierdzeniu.

## Podejścia i rekomendacja

1. **Rekomendowane: sześć nowych źródeł, po dwa kadry.** Każde ćwiczenie ma
   dwa czytelne końce ruchu. Osobne źródła pozwalają pokazać cofnięcie łokci
   drag curl, rzeczywiste chwyty wyprostów oraz kontakt hantli close-grip press.
2. Trzy kadry z pozycją pośrednią: więcej informacji o torze, lecz mniejsza
   sylwetka przy 512 px i brak istotnej dodatkowej fazy w tych ćwiczeniach.
3. Adaptacja wcześniejszych curl/press: możliwa stylistycznie, ale wymagałaby
   zmiany sprzętu, chwytów lub toru. Nie planować kopii zwykłego curl dla
   drag curl ani szerokiego wyciskania dla close-grip press.

## Kadry i jawne warianty

| ID | Ćwiczenie | Kadry | Wariant i kolejność |
|---|---|---:|---|
| cw103 | Uginanie przedramion z gumą | 2 | Stój na jednej gumie obiema stopami, dwa uchwyty podchwytem; dół → ugięcie. |
| cw104 | Uginanie przedramion z hantlami prowadzonymi wzdłuż tułowia | 2 | Stój, dwa hantle podchwytem; dół → krótki drag curl z łokciami cofniętymi. |
| cw105 | Wyciskanie francuskie hantla oburącz nad głową | 2 | Stój, jeden pionowy hantel oburącz pod górną głowicą; wyprost nad głową → zgięcie za głowę. |
| cw106 | Wyciskanie francuskie hantla jednorącz nad głową | 2 | Stój, prawa dłoń na rękojeści, lewa lekko stabilizuje prawe ramię przy łokciu; wyprost → zgięcie za głowę. |
| cw107 | Wyciskanie francuskie hantli w leżeniu na ławce | 2 | Ławka płaska, dwa hantle neutralnie; nad klatką → obok czoła przy stałych pionowych ramionach. |
| cw108 | Wyciskanie hantli wąsko na ławce | 2 | Ławka płaska, dwa stykające się hantle neutralnie; nisko nad klatką → wyciśnięcie pionowo. |

`cw103–cw106`: dwa kadry obok siebie, czytane od lewej do prawej.
`cw107–cw108`: dwa poziome pasy pełnej szerokości, czytane od góry do dołu,
aby zachować czytelność leżącej sylwetki i obu chwytów przy 512 px.

Wariant stojący `cw105–cw106` wybrano, ponieważ katalog nie wymaga siadu.
`cw106` wykorzystuje dopuszczoną stabilizację drugą ręką, ale tylko prawa
dłoń trzyma ciężar. W `cw107` wybrano katalogową opcję „do czoła”, z ciężarami
obok skroni i prześwitem od głowy. Opcja daleko za głowę mogłaby wymuszać
zmianę kąta ramion w barkach, sprzeczną z pokazanym pionowym ustawieniem.
Nie edytować katalogu ani ID w celu dopasowania ilustracji.

## Kontrakt wizualny

- Referencja stylu `assets/exercises/cw256.webp`, PNG źródłowy 1024×1024,
  finalny WebP 512×512 przez `-resize 512x512 -strip -quality 90`.
- Kremowe tło, ciemny strój, komiksowy kontur, twarz bez rysów.
  Nakładki mięśni nie są wymagane.
- Bez napisów, cyfr, strzałek, timerów, watermarków i duchów ruchu.
  Tempo, pauzy i liczba powtórzeń pozostają w katalogu.
- Stała kamera, skala, podłoże i sprzęt w ramach ID. Nie zmieniać zoomu
  między fazami. Całe ciało, stopy, dłonie i sprzęt z marginesem.
- Rzeczywiste chwyty z czytelną ciągłością dłoni/przedramion; stabilne
  nadgarstki. Osi hantla nie traktować jako dowodu orientacji dłoni.
- W leżeniu głowa, grzbiet i pośladki na ławce; obie stopy na podłodze.
  Naturalna okluzja dopuszczalna, lecz dalsza ręka nie może zostać zastąpiona
  samotną głowicą ciężaru. Każdy hantel ma krótką rękojeść i dwie głowice.

## Sceny i kryteria odrzucenia

### cw103 — Band curl

Jedna ciągła guma przyciśnięta obiema podeszwami; dwie boczne gałęzie
do uchwytów w dłoniach. Stój na szerokość bioder, podchwyt w obu fazach.
Lewy kadr: ramiona niemal proste, uchwyty przy udach, guma już lekko napięta.
Prawy: zgięte łokcie przy bokach, uchwyty ku barkom, dłuższe napięte gałęzie.
Tułów i stopy nieruchome.

Odrzucić zewnętrzną kotwę, gumę wychodzącą z wnętrza nóg/stóp, zerwane
połączenia, luźne wiszące gałęzie, hantle zamiast uchwytów, kołysanie,
uniesienie łokci i zmianę chwytu. „Neutralne nadgarstki” oznaczają brak
załamania, nie obowiązek chwytu młotkowego.

### cw104 — Drag curl

Stały widok boczny 3/4 ujawniający cofanie łokci. Dwa hantle podchwytem,
dół przy udach → ciężary blisko przedniej powierzchni tułowia, do dolnych
żeber/górnej talii. Łokcie przemieszczają się w tył, górne ramiona za linię
tułowia; przedramiona w górnej fazie wznoszą się ku przodowi od cofniętych
łokci. Krótszy zakres niż klasyczny curl; nie wymuszać dojścia do barków.

Odrzucić klasyczny łuk daleko przed ciałem, nieruchome lub wysunięte
w przód łokcie, wiosłowanie neutralnym chwytem, wzruszanie barkami,
odchylanie tułowia i pełny curl do barków. Cofanie łokci jest tu zamierzone.

### cw105 — Two-hand overhead extension

Stabilny stój, jeden krótki hantel pionowo. Obie dłonie rzeczywiście
podpierają spód górnej głowicy, palce obejmują jej nasadę; nie dwa osobne
hantle i nie dwie dłonie wciskane w zbyt krótką rękojeść. Ramiona obok
głowy, łokcie skierowane w górę, naturalny wąski rozstaw.
Lewy: niemal pełny wyprost nad głową bez przeprostu. Prawy: ugięcie łokci,
ten sam ciężar opuszczony za głowę z prześwitem od czaszki/szyi.

Wybrać kamerę boczną 3/4 pokazującą połączenie obu dłoni z ciężarem także
w dolnej fazie. Odrzucić zasłonięty nieczytelny chwyt, drugą sztangielkę,
przenoszenie całych ramion jak pullover, rozjechane łokcie, łuk lędźwiowy,
dotknięcie ciężarem głowy lub szyi i ucięty górny ciężar.

### cw106 — One-arm overhead extension

Prawa ręka robocza, jeden hantel trzymany za rękojeść. Prawa górna część
ramienia obok głowy, łokieć w górę; lewa dłoń lekko stabilizuje ramię
tuż powyżej łokcia i nie obejmuje ciężaru. Lewy: wyprost prawego łokcia
bez przeprostu. Prawy: zgięcie, przedramię i hantel za głową bez kolizji.
Stała kamera od prawego boku 3/4 z czytelną prawą dłonią w obu fazach.

Odrzucić zmianę strony, drugą dłoń na hantlu, dwa ciężary, znikający chwyt,
opuszczanie całego ramienia, ucieczkę łokcia na bok, skręt tułowia
i zmieniony kontakt dłoni stabilizującej bez potrzeby.

### cw107 — Lying dumbbell extension

Dwa poziome pasy, ta sama kamera boczna 3/4 i pozioma ławka.
Góra: dwa odrębne hantle nad klatką, ramiona pionowo, chwyt neutralny
(dłonie wzajemnie do siebie), łokcie niemal wyprostowane.
Dół: łokcie zgięte, górne ramiona pozostają pionowe; ciężary po bokach
czoła/skroni, bez kontaktu z twarzą. Obie dłonie trzymają rękojeści,
dalszy hantel i chwyt widoczne przez naturalną perspektywę.

Odrzucić bench press z opuszczonymi łokciami, pullover z ruchem barków,
łokcie szeroko na boki, przenikające głowę ciężary, niepodpartą głowę,
ucięte stopy i jeden ciężar zamiast dwóch.

### cw108 — Close-grip dumbbell press

Dwa poziome pasy i stała kamera boczna 3/4. Dwa hantle neutralnym chwytem
równolegle i bezpośrednio obok siebie; wewnętrzne boki ich głowic stykają
się w obu fazach, ale każdy zachowuje własny uchwyt i dwie głowice.
Góra: dolna faza tuż nad środkiem klatki, łokcie blisko tułowia,
przedramiona zbliżone do pionu w projekcji przestrzennej.
Dół: wyciśnięcie pionowo nad klatkę, niemal wyprostowane łokcie,
zachowany kontakt hantli. Plecy, głowa, pośladki i stopy nadal podparte.

Odrzucić szczelinę między hantlami, zlanie ich w jeden przedmiot,
dłonie na tej samej rękojeści, szerokie łokcie, rozpiętkę, skull crusher,
wyciskanie nad twarz, zmianę ławki lub odbijanie ciężaru od klatki.

## Sześć promptów bazowych

Każdy dokładny prompt ma zawierać blok wspólny oraz odpowiednią scenę.
Pierwsza referencja stylu: `/tmp/opencode/cw256-reference.png`.

### Blok wspólny

```text
Use supplied image ONLY as STYLE reference. Square 1024x1024, cream background, clean dark comic outlines, faceless adult in dark neutral clothes. EXACTLY TWO panels as specified. Entire body, BOTH hands/feet and essential equipment fit EACH panel with generous margins, including overhead weights. SAME camera, scale, floor and fixed equipment across phases. Coherent anatomy, connected real grips, stable wrists and controlled spine. Read grip from palm/fingers/thumbs/forearm, not merely dumbbell axes. Each short dumbbell has ONE handle and TWO heads. Natural partial occlusion only with clear limb/equipment continuity at 512px; no floating hands, merged weights or physical intersections. No text, numbers, labels, arrows, timer, watermark, ghosts or extra figures. No required muscle overlays. Rep counts, tempo and pauses remain in catalog, not in image.
```

### cw103

```text
STANDING BILATERAL BAND CURL, TWO SIDE-BY-SIDE panels LEFT TO RIGHT, same front-side three-quarter view. ONE continuous resistance tube with TWO real end handles, middle section securely trapped under BOTH grounded soles at hip width, TWO visible side branches to hands. BOTH hands SUPINATED throughout, wrists straight. LEFT arms long by thighs, band already mildly taut. RIGHT flex BOTH elbows, handles toward shoulders, upper arms/elbows stay by sides, branches lengthened and taut. Same feet/torso, no rocking. Trace coherent band from each handle to the respective sole, no external anchor, broken strands, rope emerging inside feet, slack hanging sections, dumbbells, elbow raise or hammer-grip substitution.
```

### cw104

```text
STANDING BILATERAL DUMBBELL DRAG CURL, TWO SIDE-BY-SIDE panels LEFT TO RIGHT, same SIDE three-quarter camera clearly exposing elbows moving BACK. TWO short dumbbells with real SUPINATED grips throughout. LEFT long arms, weights by front thighs. RIGHT drag weights CLOSE UP FRONT OF TORSO to upper waist/lower ribs, elbows travel BEHIND torso, upper arms angle backward, forearms rise forward from retracted elbows. Deliberately SHORT top range, NOT curl to shoulders. Stable stance/torso/wrists. No classic forward curl arc, fixed or forward elbows, neutral-grip row, shrug, torso lean or missing far hand/weight.
```

### cw105

```text
STANDING TWO-HAND OVERHEAD SINGLE DUMBBELL TRICEPS EXTENSION, TWO SIDE-BY-SIDE panels LEFT TO RIGHT, SAME side three-quarter view exposing hands and weight behind head. ONE short VERTICAL dumbbell, BOTH palms actually support UNDERSIDE of SAME UPPER HEAD, fingers securely around its neck, NOT two hands crammed into short handle. Upper arms remain beside head, elbows point UP with natural narrow spacing. LEFT elbows nearly extended overhead, no hyperextension. RIGHT bend ONLY elbows, lower SAME vertical weight BEHIND head with clear skull/neck gap, same upper-arm positions. Same grounded feet, ribs/pelvis stacked. Both hands/connection readable in each phase. No second weight, invisible disconnected grip, shoulder pullover, flared elbows, lumbar arch, head contact or overhead crop.
```

### cw106

```text
STANDING RIGHT-ARM OVERHEAD DUMBBELL TRICEPS EXTENSION, TWO SIDE-BY-SIDE panels LEFT TO RIGHT, SAME RIGHT-SIDE three-quarter view exposing working grip behind head. ONE short dumbbell held by HANDLE in RIGHT hand. RIGHT upper arm stays beside head, elbow points UP. EMPTY LEFT hand lightly braces RIGHT upper arm JUST ABOVE elbow in BOTH phases, never holds weight. LEFT panel right elbow nearly extended overhead. RIGHT panel bend RIGHT elbow to lower forearm/weight BEHIND head, visible real right grip and head clearance. Same upper arm/support contact/torso/feet, no rotation or back arch. No side swap, two-handed weight grip, second dumbbell, disappearing hand, shoulder lowering, lateral elbow flare or crop.
```

### cw107

```text
LYING TWO-DUMBBELL SKULL CRUSHER, TWO FULL-WIDTH HORIZONTAL BANDS STACKED TOP TO BOTTOM, same SIDE three-quarter view and horizontal bench. Head, back, buttocks supported, BOTH feet planted. TWO separate short dumbbells with NEUTRAL real handle grips, palms face EACH OTHER. TOP arms vertical above chest, elbows nearly extended. BOTTOM bend ONLY elbows, upper arms remain VERTICAL with same elbow locations, weights beside forehead/temples with air gap, not touching face. Both forearms and real far-hand grip/weight readable by natural perspective. Same bench/body/feet/scale. No bench press, shoulder pullover, elbow flare, head penetration, unsupported head, single weight or cropped feet/equipment.
```

### cw108

```text
CLOSE-GRIP TWO-DUMBBELL BENCH PRESS, TWO FULL-WIDTH HORIZONTAL BANDS STACKED TOP TO BOTTOM, same SIDE three-quarter view, horizontal bench. Head, back, buttocks supported, BOTH feet grounded. TWO DISTINCT parallel short dumbbells held with NEUTRAL real grips, palms toward each other. INNER SIDES of dumbbell HEADS TOUCH throughout BOTH phases; each weight keeps OWN handle and TWO heads, no merged single object. TOP low phase just above mid chest, elbows TUCKED close to torso, forearms near vertical in space. BOTTOM press vertically above SAME chest, elbows nearly extended, weights STILL TOUCHING. Both real hand connections visible, same supports/scale/bench. No gap between weights, shared handle, wide elbows, fly, skull crusher, press over face, chest bounce or crop.
```

## Planowane wykonanie po akceptacji

1. Przygotować plan wykonania, zachowując bieżący main w `/opt/fit` i wszystkie
   niewydane Partie 07–21. Przeczytać `docs/modules/training.md`.
2. Do expectedIllustrationIds dopisać `cw103–cw108` po `cw102` przed `cw251`;
   fallback przestawić na `cw109`. Potwierdzić red brakującego `cw103`.
3. Dokładne prompty zapisać osobno poza repozytorium. Sprawdzić zgodność,
   następnie klarowność/geometrię: gałęzie gumy, cofnięcie łokci drag curl,
   oba typy overhead grip, pionowe ramiona skull crusher, kontakt hantli press.
4. Pojedyncze żądania wyłącznie przez
   `tools/benchmark_exercise_images.py --single-sunburst-medium`, świeży
   katalog na próbę. Sekrety z `/root/.config/fit/openai.env` bez drukowania.
   Odczytać PNG źródłowy i podgląd 512 px przed następnym płatnym żądaniem.
5. Korekta wyłącznie nazwanego defektu, ostatni odrzucony PNG jako jedyna
   referencja. Po dwóch nieskutecznych korektach tego samego defektu zatrzymać
   próby i uzgodnić nową kompozycję. Bez automatycznego retry po błędzie;
   zachować ledger, nieznany koszt wykazać osobno.
6. Po akceptacji całej szóstki konwersja WebP, odczyt finalnych plików,
   integracja tych samych ID do illustratedExerciseIds. Bez zmiany katalogu,
   modeli, zależności lub artefaktów Web SQLite.
7. Pełny Docker target verification: kontrola wersji, analiza i testy,
   174 zgodne ID/assety, dekodowanie wszystkich 512×512, fallback `cw109`.
   Kontrola formatowania dwóch Dartów i `git diff --check`.
8. Status 174/78/96/142/316, sześć wierszy i sekcja „Dwudziesta druga partia”.
   Zapisać zaakceptowane źródła, rzeczywiste przeglądy i koszty tylko z success,
   deduplikowane po request_id, bez ponownego liczenia response_received.
   `upper_bound_no_cache` jest szacunkiem, nie rozliczeniem dostawcy.
9. Po osiągniętym limicie subagentów kontrola bezpośrednia; nie deklarować
   niezależnego review. Wersja, commit, push i wdrożenie na osobną prośbę.

## Samokontrola projektu

- Sześć kolejnych ID od cw103, zgodnych z nazwami i wskazówkami katalogu.
- Kadry 2/2/2/2/2/2; poziome pasy wyłącznie dla dwóch ćwiczeń w leżeniu.
- Jawne warianty: supinacja cw103, stojące overhead, prawa ręka cw106,
  opcja do czoła cw107, kontakt głowic cw108.
- Drag curl celowo dopuszcza cofnięcie łokci; wspólny blok nie zabrania go.
- Cw105 dwie dłonie pod głowicą, cw106 jedna dłoń na rękojeści; nie mieszać.
- Stan wejściowy 168/78/90/148/316 i docelowy 174/78/96/142/316 spójne.
- Na tym etapie brak nowych żądań API lub integracji assetów.

## Wykonanie — punkt kontrolny 2026-10-15

Po zatwierdzeniu przygotowano plan i rozszerzono test o cw103–cw108,
fallback cw109. Red potwierdzony: brak cw103 w rejestrze, 365 innych testów
zaliczonych i 0 problemów analizy. Log:
`/root/.local/share/opencode/tool-output/tool_13e11ac970010GDQVEtWsZV5fu`.

Źródła zaakceptowane po bezpośrednim odczycie PNG i podglądu 512 px:
trial-01 dla cw103, cw104, cw106, cw107; correction-02 dla cw105.
W cw105 poprawiono margines nad ciężarem i czytelność drugiej dłoni
podpierającej spód górnej głowicy. Przeglądy zgodność→jakość bez niezależnych
subagentów po wcześniej osiągniętym limicie.

**Cw108 pozostaje niezaakceptowane.** Pierwsza próba zasłania dalszy chwyt,
pierwsza korekta pokazuje sprzęt podobny do połączonych końcami hantli,
druga nadal nie daje jednoznacznego chwytu neutralnego i równoległego
kontaktu dwóch osobnych ciężarów. Po dwóch nieskutecznych korektach
zatrzymano płatne próby. Propozycja do zatwierdzenia: nowe źródło z kamerą
od strony stóp pod kątem 3/4, ujawniające dwa uchwyty i stykające się
wewnętrzne boki głowic. Zachować dwa poziome pasy i pozostałą technikę.

Integracja całej szóstki i green oczekują na akceptację nowej kompozycji
cw108 i poprawny obraz. Bieżący status assetów nadal 168/78/90/148/316.
Dokładne prompty, PNG, podglądy i ledgery zachowano w `/tmp/opencode`.
Odczytano 10 rekordów success z różnymi request_id, bez podwójnego liczenia
response_received. Suma szacunków upper_bound_no_cache: 0,228920 USD,
bez błędów HTTP; nie jest to rozliczenie dostawcy. Szczegóły kosztów w planie.

### Zatwierdzona nowa kompozycja cw108

Użytkownik zatwierdził pojedynczą nową generację z kamerą od strony stóp
pod kątem 3/4. Dwa poziome pasy i pozostała technika bez zmian. Nowe źródło
używa wyłącznie referencji stylu cw256, nie odrzuconych ujęć cw108.
Dokładny prompt: `/tmp/opencode/cw108-new-01-prompt.txt`, wyjście w świeżym
`/tmp/opencode/cw108-new-01`. Przed żądaniem sprawdzono wymagania kontaktu
dwóch osobnych ciężarów, neutralnych chwytów i stałych podpór.

Wykonano zatwierdzone pojedyncze żądanie. New-01 poprawia widoczność czterech
głowic, ale nadal zasłania dalszy chwyt w dolnej fazie i nie pokazuje
jednoznacznie dłoni skierowanych ku sobie. Źródło i podgląd 512 px odczytano;
obraz odrzucony. Dalsze żądania wstrzymano. Proponowana jedna korekta
new-01: odsłonięcie obu chwytów neutralnych na osobnych równoległych
rękojeściach, bez zmiany kamery, kontaktu głowic i podpór.
Nowy koszt 0,023407 USD; narastająco 11 sukcesów, 0,252327 USD
upper_bound_no_cache, bez błędów HTTP. Kwoty nie są rozliczeniem dostawcy.

Użytkownik zatwierdził jedną korektę nowego ujęcia. Wykonano ją w
`/tmp/opencode/cw108-new-correction-01`, z new-01 jako jedyną referencją.
Odczyt źródła i 512 px: obie dłonie widoczne, lecz w wyproście sprzęt
przypomina wspólną poprzeczną rękojeść/połączone głowice, zamiast dwóch
osobnych równoległych hantli neutralnie. Obraz odrzucony; pierwsza
nieskuteczna korekta nowej kompozycji. Nie wykonano kolejnych żądań.
Koszt korekty 0,022822 USD; narastająco 12 sukcesów, 0,275149 USD
upper_bound_no_cache, bez błędów HTTP. Integracja i green nadal oczekują.

## Zakończenie wykonania — 2026-10-15

Użytkownik zatwierdził drugą korektę nowego ujęcia i dalszą pracę do
poprawnego wyniku. Wystarczyła druga korekta: `cw108-new-correction-02`.
Prompt `/tmp/opencode/cw108-new-correction-02-prompt.txt` rozdzielił sprzęt
na dwie równoległe osie rękojeści, z głowicami od strony stóp i głowy,
chwytami neutralnymi i kontaktem boków głowic. Referencją był wyłącznie
ostatni odrzucony PNG new-correction-01. Źródło, podgląd 512 px i finalny
WebP sprawdzono bezpośrednio; wynik zaakceptowany. Nie były potrzebne
dalsze nowe kompozycje ani żądania po tej korekcie.

Zintegrowano sześć WebP 512×512 przez `-resize 512x512 -strip -quality 90`:

| ID | Zaakceptowany katalog źródłowy w /tmp/opencode | Kadry |
|---|---|---:|
| cw103 | cw103-trial-01 | 2 |
| cw104 | cw104-trial-01 | 2 |
| cw105 | cw105-correction-02 | 2 |
| cw106 | cw106-trial-01 | 2 |
| cw107 | cw107-trial-01 | 2 |
| cw108 | cw108-new-correction-02 | 2 |

Dodano cw103–cw108 do rejestru; test oczekuje tych samych ID i fallbacku cw109.
Pełny Docker verification: 366 testów zaliczonych, 0 problemów analizy,
kontrola wersji poprawna, formatowanie dwóch Dartów bez zmian. Log:
`/root/.local/share/opencode/tool-output/tool_13e3c08d9001Xf7fAflomR2lO1`.
Status 174/78/96/142/316; wcześniejsze pakiety i katalog zachowano.

Ostatni request_id `req_a5e29ebc12f84bcea9a1c471a37b6a1f`, szacunek
0,023082 USD. Odczytano wszystkie 13 ledgerów; sukcesy mają odrębne
request_id, response_received nie liczono ponownie. Łącznie 13 udanych
żądań (7 źródeł/nowych kompozycji i 6 korekt), bez błędów HTTP;
`upper_bound_no_cache` 0,298231 USD, nie rozliczenie dostawcy.
Pakiet lokalny, niewydany; produkcja pozostaje `1.9.0+22`.
