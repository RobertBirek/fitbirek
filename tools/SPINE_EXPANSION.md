# Kręgosłup — druga ekspansja katalogu, 2026-10-16

## Wynik i kontrakt

**369 ćwiczeń; 6 nowych ID cw364–cw369.** Baza odniesienia:
`6f3eb79b692f6201d8bbf45b6952cd461aeccaaa` (363 ćwiczenia).
Wszystkie pola każdego z 363 starych ćwiczeń są identyczne z baseline.
Każda stara komórka wszystkich arkuszy XLSX zachowana: wartość, typ,
styl, komentarz, hiperłącze. Wszystkie stare wpisy mapy nazw i źródeł zachowane.

Jedyna zmiana starych metadanych to **dopisanie** `spine` do wybranych list
`styles`. Sześć dotychczasowych definicji stylów, ich kolejność i wszystkie
dotychczasowe style wpisów pozostają. Mięśnie, aliasy, tracking, unilateral,
conditions i positions starego prefiksu nie zmieniają się. Nadal schemaVersion=1.

```json
{"id":"spine","label":"Kręgosłup — ruch i stabilizacja","aliases":["kręgosłup","kregoslup","spine"]}
```

To kolekcja w **istniejącym** `styles`, nie mięsień ani nowa kategoria.
Nie dodano root `collections`, `ExerciseFilters.collections` ani żadnych
nowych kryteriów planów. Dynamiczne ID stylu nie wymaga zmiany parsera.
Słownik ma obecnie **7 stylów, 21 grup mięśni, 6 warunków, 5 pozycji**.
Żadnych zmian Fluttera, DB, backendu, ilustracji, wersji aplikacji ani wdrożenia.

## Research i pierwotne źródła

Przeczytano pełny tekst wskazanych stron/PDF 2026-10-16, nie tylko wyniki
wyszukiwarki. Wersjonowany w git rejestr `source_data/catalog_sources.json`
zawiera URL, wydawcę, dostępną wersję publikacji, przeczytane sekcje oraz
powiązanie każdego nowego ID z ruchem. Dodano 6 pozycji źródłowych: 5
wykorzystanych w nowych ćwiczeniach i 1 pomocniczą dla audytu odrzuconego ruchu.
Cały rejestr obejmuje 53 dopisane ćwiczenia cw317–cw369.

| Klucz rejestru | Pierwotne źródło i przeczytana sekcja |
|---|---|
| `aaos_spine` | [AAOS Spine Conditioning Program](https://orthoinfo.aaos.org/en/recovery/spine-conditioning-program/), zwłaszcza 5 Knee to Chest, 6 Bird Dog, 7 Plank, 8 Modified Side Plank, 9 Hip Bridge, 10 Abdominal Bracing; brak daty rewizji w pobranym tekście |
| `cuh_back` | [CUH Back mobility exercises](https://www.cuh.nhs.uk/patient-information/back-mobility-exercises/), 3 Knee rolls, 5 Core muscle contraction (normalny oddech), 6 Bridging, 7 Pelvic tilts; zatwierdzone 16.07.2024, wersja 4 |
| `nhs_inform_back` | [NHS inform Exercises for back pain](https://www.nhsinform.scot/illnesses-and-conditions/muscle-bone-and-joints/neck-and-back-problems-and-conditions/exercises-for-back-pain), pojedyncze kolano do klatki z drugą nogą ugiętą, pelvic tilts, knee rolls, stop i stopniowanie objętości; brak daty rewizji w pobranym pełnym tekście |
| `leeds_open_book` | [Leeds NHS LN005629 PDF](https://flipbooks.leedsth.nhs.uk/LN005629.pdf), 1 Open book; wydanie 1, Ver 1.0, 08/2024, przegląd 08/2027 |
| `peakrx_hip_hinge` | [PeakRx, Dr Brooke Miller, fizjoterapeutka](https://www.peakrxtherapy.com/blog/hip-hinging-101), What is a hip hinge, Common faults, Ways to Train / Butt taps; 10.02.2018 |
| `cuh_thoracic` | [CUH Thoracic spine exercises](https://www.cuh.nhs.uk/patient-information/thoracic-spine-exercises/), 2 wyprost na oparciu krzesła oraz 4–6 rotacje i cat-cow; 16.07.2024, wersja 4; źródło audytu, bez nowego ID |

Źródła medyczne opisują także konteksty kliniczne. Katalog wykorzystuje
wyłącznie udokumentowaną technikę ogólnego ruchu, **nie przypisuje użytkownikowi
diagnozy, programu rehabilitacyjnego ani obietnicy leczenia dyskopatii**.
Nie przeniesiono twierdzeń PeakRx o ochronie/leczeniu pleców ani instrukcji
AAOS pełnych kół szyi. Również starego cw269 nie dodano do kolekcji spine.

## Nowe ID: technika, dawka i przekazanie do ilustracji

Polskie instrukcje są autorskie. Pełne kroki, błędy, progresja, regresja,
tempo i URL są w `spine_additions.py`, workbooku i **wygenerowanym** JSON.
Poniższe dawki są zachowawczymi propozycjami startowymi kuratora, nie dawkami
indywidualnie zaleconymi przez AAOS/NHS. CUH pozostawia pola dawkowania puste;
NHS inform sugeruje początkowo 2–3 powtórzenia, Leeds 5 na stronę, AAOS
bracing 5 utrzymań po 15 sek. Nie przypisujemy źródłom naszych mniejszych dawek.

| ID / nazwa | Technika i rozróżnienie | Dawka / tracking / strona | Frame focus do przyszłego obrazu | Źródło |
|---|---|---|---|---|
| **cw364** Przetaczanie miednicy w leżeniu na plecach | Kolana ugięte, stopy oparte. Małe podwinięcie miednicy zmniejsza szczelinę pod lędźwiami, mały ruch przeciwny ją przywraca. Pośladki nie odrywają się. To nie most ani cat-cow. | 1 × 3–5 pełnych przetoczeń tam/powrót; ok. 2 sek w każdą stronę; `reps`, bilateral | Profil leżącej osoby, obie stopy i ugięte kolana widoczne; dłonie na miednicy, biodra na podłodze. Dwa małe ustawienia miednicy, nie wysoko uniesiony most. | CUH §7; uzupełnienie NHS inform |
| **cw365** Łagodne napięcie brzucha w leżeniu z normalnym oddechem | Nogi podparte stopami, ręce przy ciele. Lekkie napięcie dolnego brzucha, bez unoszenia głowy, barków i kończyn. Swobodny wdech/wydech, potem pełne rozluźnienie. To nie crunch, hollow hold, dead bug ani trening bezdechu. | 3 × 5 sek z odpoczynkiem pomiędzy napięciami; `time`, bilateral | Ujęcie 3/4 z boku, głowa i barki leżą, kolana zgięte, stopy na ziemi. Brak ruchu kończyn i zgięcia tułowia; nie rysować agresywnie wciągniętego brzucha ani parcia. Oddech wymaga podpisu/instrukcji, obraz sam go nie dowodzi. | AAOS §10; normalny oddech CUH §5 |
| **cw366** Kołysanie ugiętych kolan w leżeniu na plecach | Oba kolana razem idą w bok i wracają do środka. Barki pozostają na ziemi, stopy przetaczają się na krawędzie. Nie unosić nóg jak w windshield wipers. | 1 × 3 na stronę; bok → środek to 1 powtórzenie strony; `reps`, unilateral | Ujęcie skośne od stóp, widoczne oba barki na podłożu i złączone ugięte kolana nieznacznie obok osi ciała; brak dłoni dociskającej nogi. | CUH §3; uzupełnienie NHS inform |
| **cw367** Otwarta książka — obrót klatki w leżeniu bokiem | Biodra i kolana ugięte, kolana razem na podłodze. Górna ręka otwiera się łukiem razem z klatką i wraca na dolną dłoń. Nie wymaga dotknięcia podłogi z tyłu ani rotacji szyi do końca. | 1 × 3–5 na stronę, wolno; `reps`, unilateral | Ujęcie 3/4 z góry: dolna ręka przed klatką, górna otwarta za tułów, oba kolana nadal razem na ziemi. Nie przedstawiać podporu na dłoni ani przetoczenia na plecy. | Leeds §1 |
| **cw368** Przyciąganie jednego kolana do klatki w leżeniu | Jedno udo ku klatce, druga stopa na podłodze, drugie kolano ku sufitowi. Głowa i barki leżą. Delikatny chwyt, bez szarpania; regresja: chwyt za tył uda. Nie happy baby ani reverse crunch. | 1 × 3 na stronę, 2–3 sek łagodnej pauzy; `reps`, unilateral | Profil/3⁄4: jedna noga przyciągana, druga wyraźnie ugięta ze stopą opartą. Ręce nie ściskają mocno rzepki. Bez drugiej nogi wyprostowanej w powietrzu i bez unoszenia głowy. | NHS inform single knee hug; kontekst AAOS §5 |
| **cw369** Cofanie bioder do ściany bez obciążenia | Stanie tyłem kilka cm od ściany, miękkie kolana, ręce w zgięciach bioder. Cofnięcie bioder do lekkiego dotknięcia ściany, neutralny tułów, powrót przez biodra. Nauka zawiasu z celem dotykowym, bez ciężaru. | 1 × 5, ok. 3 sek cofania i spokojny powrót; `reps`, bilateral | Pełny profil z widoczną ścianą za pośladkami, stopy płasko na podłodze, małe ugięcie kolan, tułów pochylony z bioder. Dłonie na biodrach, żadnej sztangi, gumy, worka ani ręki podpierającej ścianę. | PeakRx / Butt taps |

**Bezpieczeństwo nowych wpisów:** brak pracy przez ból, wymuszonych przeprostów,
rotacji z ciężarem, pełnych kół szyi i zatrzymywania oddechu. Każdy wpis ma
jawną instrukcję przerwania przy bólu/nasileniu objawów/drętwieniu i konsultacji
dalszego ruchu. Po urazie, operacji lub przy rozpoznanym schorzeniu zakres
i dobór należy uzgodnić ze swoim specjalistą; kolekcja nie zastępuje konsultacji.
Progresje to mały przyrost swobodnych powtórzeń/czasu, a w cw369 odległości
od ściany; żadna nie dodaje ciężaru. Regresje zmniejszają zakres/czas/napięcie.

**Obrazów nie wygenerowano.** Tabela jest przekazaniem merytorycznym do osobnego
etapu: źródło 1024, podgląd przed następnym żądaniem, docelowy obraz 512 zgodnie
z zatwierdzonym projektem. Nie zmieniano istniejących opublikowanych obrazów.

## Audyt duplikatów całej bazy 363

Przejrzano nazwy EN/PL, wzorce i instrukcje istniejących wpisów. Walidator
automatycznie wykrywa identyczne nazwy EN nowych wpisów; poniżej osobny przegląd
semantyki (nie twierdzimy, że test automatycznie rozumie biomechanikę):

- cw364 vs cw154/cw155: ruch miednicy bez podnoszenia bioder; cw250/cw268/cw291
  to cat-cow w podporze/siadzie, a nie kontrola miednicy w leżeniu.
- cw365 vs cw179/cw180: brak ruchu rąk/nóg; vs cw183/cw188: brak uniesienia
  kończyn, głowy i barków. cw300 to oddech z pauzami, cw301 samo oddychanie;
  tutaj zadaniem jest lekkie izometryczne napięcie z ciągłym oddechem.
- cw366 vs cw193/cw194/cw201/cw348: kolana ugięte i nisko, tułów podparty
  podłogą, bez ciężaru, siadu lub zwisu; nie windshield wiper w zwisie.
- cw367 vs cw266: leżenie bokiem zamiast podporu/klęku i przeplatania ramienia;
  vs cw290/cw348: bez siadu, dźwigni łokciem i ręki podporowej.
- cw368 vs cw351: jedno kolano przyciągane, druga stopa podparta; bez odwodzenia
  obu bioder i chwytania stóp. vs cw189: nie unosić miednicy jak reverse crunch.
- cw369 vs cw062/cw063/cw148/cw150/cw152/cw317/cw321: nie dodano kolejnego
  obciążonego skłonu lub martwego ciągu. To ćwiczenie nauki cofania bioder,
  z dotykowym celem na ścianie, bez trzymania ciężaru i bez głębokiego skłonu.
- **Odrzucono wyprost piersiowy na oparciu krzesła:** CUH potwierdza ruch,
  ale cw267 już opisuje górne plecy podparte poprzecznie o ławkę i kontrolowany
  wyprost piersiowy. Sama zmiana powierzchni podparcia nie uzasadnia nowego ID.
- Nie dublowano deski, bird dog, mostu, cat-cow, pozycji dziecka ani wariantów
  neck rolls. Zachowano istniejące historyczne podobieństwa cw268/cw291,
  bez renumeracji, łączenia i zmiany starych treści.

## Członkostwo istniejących ćwiczeń

13 starych wpisów otrzymuje wyłącznie dodatkowy tag:

- **cw154** most biodrowy — stabilizacja i wyprost bioder (AAOS §9, CUH §6).
- **cw169** deska na przedramionach, **cw171** deska bokiem — stabilizacja
  tułowia (AAOS §7–8); stary opis pełnej deski zachowany, nie przepisano go
  na modyfikowaną deskę z AAOS i nie tworzono duplikatu.
- **cw179** dead bug, **cw181** bird dog — kontrola tułowia w ruchu kończyn;
  bird dog wprost AAOS §6, dead bug to przegląd istniejącej instrukcji katalogu,
  nie twierdzenie, że AAOS opisuje ten ruch.
- **cw250** cat-cow, **cw252** pozycja dziecka — kontrolowana mobilność w klęku
  (CUH back/thoracic; analogia pozycji cofnięcia bioder AAOS §2).
- **cw266** thread the needle, **cw267** wyprost piersiowy na ławce,
  **cw268** cat-cow w siadzie, **cw290** skręt w siadzie,
  **cw291** drugi historyczny cat-cow w siadzie, **cw294** skłon boczny
  w siadzie — przegląd istniejących instrukcji, odniesienie do płaszczyzn ruchu
  CUH thoracic §1–5. Nie przypisujemy CUH identycznej techniki każdego wariantu.

Kolekcja liczy **19 wpisów (13 starych + 6 nowych)**. Nie obejmuje automatycznie
całego brzucha, obciążonych rotacji, zaawansowanych rolloutów ani skrajnych
wygięć jogi. Tag to temat ruchowy, **nie medyczny certyfikat bezpieczeństwa**;
stare opisy i stare dawkowanie nie były zmieniane w tym zadaniu.

## Odtwarzanie i walidacja

Źródłem prawdy są `spine_additions.py` i źródłowy XLSX, nie eksport JSON.
`expand_spine_catalog.py` dopisuje 6 wierszy do `BAZA_GLOWNA`, mapę nazw,
6 jawnych wpisów do istniejącego pełnego `exercise_execution_conditions.json`
oraz wspólny rejestr źródeł. Drugi przebieg nie przepisuje nawet ZIP XLSX.
`expand_catalog.py --check` nadal sprawdza pierwszą ekspansję cw317–cw363,
ale jego wspólny ledger uwzględnia teraz także drugi przyrost.

Warunki nowych wpisów są statyczne: wszystkie `no_jumps`, `quiet`,
`no_kneeling`, `no_hand_support`, `small_space`; tylko cw369 dodatkowo
`no_floor` i pozycja `standing`, pozostałe `floor`. Spoczywająca ręka nie
jest obciążonym podporem. `unilateral` oznacza samodzielną stronę kierunku
pracy w cw366–cw368, nie sumę obu stron; ich przepis mówi jawnie „na stronę”.
Mięśnie w mobilności oznaczają główne grupy docelowe/kontrolujące ruch,
nie wynik pomiaru EMG. Nie dodano żadnego sprzętu.

```bash
ls /tmp/opencode
# Istniejący venv lub utworzenie Pythonem 3.12:
python3.12 -m venv /tmp/opencode/catalog-venv
/tmp/opencode/catalog-venv/bin/python -m pip install --require-hashes --only-binary=:all: -r tools/requirements-catalog.lock

/tmp/opencode/catalog-venv/bin/python tools/expand_spine_catalog.py
/tmp/opencode/catalog-venv/bin/python tools/xlsx_to_json.py
/tmp/opencode/catalog-venv/bin/python tools/build_catalog_metadata.py

/tmp/opencode/catalog-venv/bin/python tools/expand_catalog.py --check
/tmp/opencode/catalog-venv/bin/python tools/expand_spine_catalog.py --check
/tmp/opencode/catalog-venv/bin/python tools/build_catalog_metadata.py --check
/tmp/opencode/catalog-venv/bin/python tools/build_execution_conditions.py --check
/tmp/opencode/catalog-venv/bin/python tools/update_exercise_names_pl.py --check
/tmp/opencode/catalog-venv/bin/python tools/validate_catalog.py
/tmp/opencode/catalog-venv/bin/python -m unittest discover -s tools/tests -p test_catalog_pipeline.py -v
/tmp/opencode/catalog-venv/bin/python -m unittest discover -s tools/tests -p test_execution_conditions.py -v
/tmp/opencode/catalog-venv/bin/python -m unittest discover -s tools/tests -p test_spine_expansion.py -v
```

Konwerter nadal sprawdza **oryginalny** hash cw001–cw316, a dodatkowo hash
całego prefiksu cw001–cw363. Nie zastąpiono starego hasha nowym. Walidator
metadanych porównuje historyczny hash po odjęciu wyłącznie nowego tagu,
sprawdza dokładną definicję/członkostwo spine i komplet nowych metadanych.
Testy starego etapu sprawdzają oryginalne hashe baseline oraz zachowanie ich
projekcji po przyroście, zamiast wymagać identycznych bajtów powiększonego XLSX.
Nowy test odtwarza rozszerzenie od baseline w katalogu tymczasowym,
porównuje wynik i potwierdza bajtową idempotencję drugiego przebiegu.
Testy historycznych komórek używają lokalnego obiektu git `6f3eb79`.
Kontrole CLI nie potrzebują repozytorium git, sieci ani Dockera.

Testy są skupione na danych; nie uruchamiać Dart, backendu, Playwright ani
generatora obrazów. Pełny `discover test_*.py` w `tools/tests` obejmuje także
niezwiązane narzędzia push/Playwright i wymaga ich osobnego środowiska.
