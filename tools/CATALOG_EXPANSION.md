# Katalog ćwiczeń — rozszerzenie 2026-10-16

> Poniżej opis historycznej pierwszej ekspansji do 363 wpisów. Druga ekspansja
> dodaje cw364–cw369 i siódmy styl `spine`, zachowując cały prefiks i stare
> style: aktualny wynik **369 ćwiczeń** opisano w [SPINE_EXPANSION.md](SPINE_EXPANSION.md).

> Addytywny etap 5 rozszerza poniższy historyczny kontrakt sidecara (nadal
> schemaVersion=1) o rejestry i listy `conditions`/`positions` dla wszystkich
> 363 ID. Aktualne definicje, źródło decyzji i polecenia:
> [EXECUTION_CONDITIONS.md](EXECUTION_CONDITIONS.md). Dotychczasowe pola
> i wszystkie treści ćwiczeń pozostają bez zmian.

## Wynik i granice

**47 nowych ćwiczeń, cw317–cw363; łącznie 363.** Podział przyrostu:
16 sandbag, 3 kółko, 16 joga, 8 kalistenika, 4 tai chi siedzące.
Bez karate, obrazów, migracji, zmian UI, backendu, wersji aplikacji i wdrożenia.
Wszystkie pola cw001–cw316 pozostają identyczne. Konwerter sprawdza SHA-256
kanonicznego JSON tego prefiksu, nie tylko istnienie jego identyfikatorów.

Plan realizacji: testy kontraktów → audyt istniejących ruchów i źródeł →
dopisanie do `BAZA_GLOWNA` → eksport XLSX→JSON → jawna klasyfikacja →
kontrola integralności i odtwarzalności. Zmiany nazw/treści starego prefiksu
wymagałyby osobnej świadomej decyzji i aktualizacji kontraktu, nie obchodzenia
walidacji. `update_exercise_names_pl.py` wymaga teraz dokładnego pokrycia
rzeczywistych ID workbooka, zamiast stałej liczby 316.

## Pliki i źródła prawdy

- `source_data/baza_cwiczen_316.xlsx`: nazwa historyczna; **363** wiersze danych
  w `BAZA_GLOWNA`. Pozostałe arkusze to historyczne podziały, nie rozszerzany
  indeks. Narzędzie dopisujące weryfikuje zachowanie wszystkich istniejących
  komórek wszystkich arkuszy (wartość, typ, styl, komentarz, hiperłącze).
- `source_data/exercise_names_pl.json`: jawna mapa nazw wszystkich 363 ID.
- `catalog_additions.py`: kuratorowany, odtwarzalny wkład tej konkretnej
  ekspansji: nazwy, polskie instrukcje, błędy, progresje, regresje, źródła.
  `expand_catalog.py` odmawia nadpisania różniącego się istniejącego wiersza.
  Późniejsze korekty dodatków należy uzgodnić w workbooku i tym wkładzie,
  a nie modyfikować wyeksportowanego JSON.
- `xlsx_to_json.py`: jedyna droga eksportu `assets/data/exercises.json`.
- `build_catalog_metadata.py`: ręcznie przejrzana tabela anatomii **dla każdego
  starego ID**, jawne zestawy ID stylów/trybów/stron oraz klasyfikacja dodatków.
  Generuje jawny `assets/data/exercise_catalog_metadata.json`.
- `source_data/catalog_sources.json`: wersjonowany rejestr URL, sprawdzonych
  sekcji, powiązania każdego nowego ID z ruchem i decyzji o pominięciach.
- `validate_catalog.py`, `tests/test_catalog_pipeline.py`: walidacja offline.
  Nie twierdzą, że automatycznie rozpoznają semantyczne dublety lub prawidłową
  biomechanikę. Te wymagają przeglądu. Testy nie pobierają stron w sieci;
  URL/treść wydawców sprawdzono podczas kuracji 2026-10-16.

## Nowe ćwiczenia

| ID | Ruch | Źródło / sekcja |
|---|---|---|
| cw317 | Martwy ciąg z sandbagiem za uchwyty | DVRT deadlift |
| cw318 | Przysiad z sandbagiem trzymanym z przodu | DVRT Top 10: Front Hold Squats |
| cw319 | Przysiad z sandbagiem objętym pionowo | DVRT Top 10: Bear Hug Squat |
| cw320 | Przysiad z sandbagiem na jednym barku | DVRT 10 Musts: Shoulder Squat |
| cw321 | Skłon biodrowy z sandbagiem przed klatką | DVRT Top 10: Front Hold Good Mornings |
| cw322 | Wiosłowanie sandbagiem w opadzie | DVRT 10 Musts: Bent Rows |
| cw323 | Dynamiczne podciągnięcie sandbaga do klatki | DVRT Top 10: High Pull |
| cw324 | Zarzut sandbaga na przedramiona | DVRT Top 10: Clean |
| cw325 | Wyciskanie sandbaga nad głowę | DVRT 9: Overhead Press |
| cw326 | Zarzut i wyciskanie sandbaga | DVRT 10 Musts: Clean and Press |
| cw327 | Zakrok z przeniesieniem sandbaga przy przedniej nodze | DVRT 10 Musts: MAX Lunge |
| cw328 | Przenoszenie sandbaga ruchem szuflowania | DVRT 10 Musts: Shoveling |
| cw329 | Obwodzenie sandbaga wokół tułowia w klęku | DVRT 10 Musts: Around the Worlds |
| cw330 | Przeciąganie sandbaga pod tułowiem w desce | DVRT Top 10: Lateral Bag Drag |
| cw331 | Most biodrowy z napięciem sandbaga nad klatką | DVRT 10 Musts: Hip Bridges |
| cw332 | Wyciskanie sandbaga łukiem w półklęku | DVRT 10 Musts: Arc Press |
| cw333 | Przetaczanie kółka w przód z kolan | Workout Digest: Kneeling Rollouts |
| cw334 | Przetaczanie kółka po skosie z kolan | Workout Digest: V Rollouts |
| cw335 | Deska z dłońmi na kółku | BarBend: Ab Wheel Plank |
| cw336 | Wojownik I | Yoga Journal: Warrior I |
| cw337 | Wojownik II | Yoga Journal: Warrior II |
| cw338 | Wojownik III | Yoga Journal: Warrior III |
| cw339 | Pozycja trójkąta | Yoga Journal: Extended Triangle |
| cw340 | Pozycja rozciągniętego kąta bocznego | Yoga Journal: Extended Side Angle |
| cw341 | Pozycja półksiężyca w staniu | Yoga Journal: Half Moon |
| cw342 | Pozycja drzewa | Yoga Journal: Tree |
| cw343 | Pozycja orła w staniu | Yoga Journal: Eagle |
| cw344 | Pozycja krzesła bez podparcia | Yoga Journal: Chair |
| cw345 | Pozycja wielbłąda | Yoga Journal: Camel |
| cw346 | Pozycja łuku | Yoga Journal: Bow |
| cw347 | Pozycja łodzi w siadzie | Yoga Journal: Boat |
| cw348 | Skręt mędrca w siadzie na podłodze | Yoga Journal: Half Lord of the Fishes |
| cw349 | Pozycja bramy w klęku | Yoga Journal: Gate |
| cw350 | Skłon w przód w szerokim rozkroku | Yoga Journal: Wide-Legged Forward Bend |
| cw351 | Pozycja szczęśliwego dziecka | Yoga Journal: Happy Baby |
| cw352 | Przemieszczanie bokiem w przysiadzie na rękach | GMB: Monkey |
| cw353 | Przemieszczanie żabki z podparciem rąk | GMB: Frogger |
| cw354 | Przysiad krewetki z chwytem tylnej stopy | GMB: Shrimp Squat |
| cw355 | Przerzut bokiem na obie ręce | GMB: Cartwheel |
| cw356 | Most trójpunktowy z sięganiem | GMB: Three Point Bridge |
| cw357 | Podpór żaby na ugiętych ramionach | GMB: Crow/Frog Stand |
| cw358 | Unoszenie prostej nogi w siadzie z kompresją | GMB: L-Sit, seated leg raises |
| cw359 | Utrzymanie podporu tyłem z ugiętymi nogami | GMB: Supine Tabletop |
| cw360 | Tai chi — zbieranie wiśni w siadzie | Exercises Seated PDF: Picking Cherries |
| cw361 | Tai chi — wiosłowanie łodzią w siadzie | PDF: Rowing a Boat |
| cw362 | Tai chi — żółw pływający w oceanie w siadzie | PDF: Turtle Swims in the Ocean |
| cw363 | Tai chi — otwieranie drzwi podeszwą w siadzie | PDF: Kick with Sole |

Pełne URL znajdują się w `zrodlo` każdego rekordu i rejestrze źródeł.
Główne publikacje:

- [DVRT Top 10](https://ultimatesandbagtraining.com/top-10-ultimate-sandbag-training-exercises/)
- [DVRT 10 Musts](https://ultimatesandbagtraining.com/10-ultimate-sandbag-exercises-that-are-musts/)
- [DVRT 9 Functional Strength](https://ultimatesandbagtraining.com/9-ultimate-sandbag-exercises-that-make-functional-strength-better/)
- [DVRT deadlift](https://ultimatesandbagtraining.com/the-ultimate-sandbag-deadlift-challenge/)
- [Workout Digest](https://theworkoutdigest.com/ab-wheel-exercises/),
  [BarBend](https://barbend.com/ab-wheel-workouts/)
- [Yoga Journal biblioteka](https://www.yogajournal.com/poses/), indywidualny URL każdej pozycji w rejestrze
- [GMB Monkey](https://gmb.io/monkey/), [Frogger](https://gmb.io/frogger/),
  [Shrimp](https://gmb.io/shrimp-squats/), [Cartwheel](https://gmb.io/cartwheel/),
  [Three Point Bridge](https://gmb.io/three-point-bridge/),
  [Crow](https://gmb.io/crow-pose/), [L-Sit](https://gmb.io/l-sit/)
- [Tai Chi Exercises — ćwiczenia siedzące, PDF](https://www.taichiexercises.co.uk/wp-content/uploads/2020/05/Exercises-Seated.pdf)
- [VA](https://news.va.gov/107780/live-whole-health-134-seated-tai-chi-moves/)
  to **kontekst** dostępności praktyki siedzącej; artykuł nie opisuje tekstowo
  czterech wybranych ruchów. Nie przypisujemy mu ich instrukcji ani nie
  deklarujemy obejrzenia filmu jako dowodu.

## Ograniczenia sprzętowe i kontrola dubletów

Bushido: potwierdzono 7 uchwytów i 3 wkłady. 20 kg to informacja użytkownika,
nie domyślna recepta; szczególnie łuki nad głową i drag wymagają lżejszego
worka. Adaptujemy ruchy DVRT do worka z uchwytami, nie twierdzimy, że oba modele
mają identyczny rozmiar i chwyt. Bez rzutów.

Gymtek: potwierdzono podwójną rolkę, boczne uchwyty i matę pod kolana; brak
udokumentowanych pasków na stopy i mechanizmu powrotnego. Nie dodano knee
tucks/pike/bridge ze stopami na osi, ani wariantów jednorącz wymagających
centralnego uchwytu. Krótki rollout/przy ścianie to regresja cw333, stojący
to wyłącznie zaawansowana progresja; nie sztuczne dodatkowe ID. V rollout ma
mały, ustalony na początku skos, bez ostrego skręcania rolki pod obciążeniem.

Pominięto ponowny most biodrowy (cw154), locust/arch hold (cw185), bear crawl
(cw223), crab walk (cw224), L-sit (cw203), dead bug (cw179), inchworm (cw247).
Nie zgadywano instrukcji nowych zwierzęcych wzorców GMB z samych nazw.
Osiem nowych pozycji kalisteniki ma dostępne, konkretne instrukcje.

Świadomie odróżnione pary: cw354 trzyma tylną stopę (inaczej niż swobodna
tylna noga w cw139); cw359 to nieruchomy podpór, nie chód cw224; cw347 to
utrzymanie równowagi na guzach kulszowych, nie leżenie cw183 ani dynamiczny
scyzoryk cw190. cw331 utrzymuje napięcie worka **nad klatką**, a nie ciężar na
biodrach jak cw155. Przysiady sandbag różnią położenie i sposób podparcia
ładunku (poziomo przed klatką / pionowo objęty / asymetrycznie na barku).
Zarzut, strict press i pełny clean-and-press mają różny zakres jednego
powtórzenia. Nie dodano ich wariantów różniących się tylko tempem.

Cztery ruchy siedzące z PDF nie są ponownym otwarciem klatki ani dłońmi jak
chmury. Zachowano historyczne cw283/cw285 mimo podobieństwa. Ruchy PDF są
ćwiczeniami praktyki Tai chi / przygotowawczymi, nie deklaracją tradycyjnej
formy Yang ani leczenia. Opisy nie powtarzają obietnic medycznych wydawców.

## Sidecar — kontrakt i decyzje kuratorskie

Dokładny format (bez dodatkowych pól):

```json
{
  "schemaVersion": 1,
  "styles": [{"id": "yoga", "label": "Joga", "aliases": ["yoga"]}],
  "muscles": [{"id": "abs", "label": "Brzuch", "aliases": ["core"]}],
  "exercises": {
    "cw333": {
      "styles": ["strength", "calisthenics"],
      "primaryMuscles": ["abs"],
      "secondaryMuscles": ["back", "shoulders", "glutes"],
      "aliases": ["Kneeling ab wheel rollout", "ab wheel", "ab roller"],
      "tracking": "reps",
      "unilateral": false
    }
  }
}
```

To przykład struktury, nie kompletny rejestr. Asset ma **6 stylów, 21 grup
mięśniowych i 363 wpisy**. Stabilne ID stylów: `yoga`, `tai_chi`,
`calisthenics`, `strength`, `conditioning`, `mobility_recovery`.
Etykiety: Joga, Tai chi, Kalistenika, Trening siłowy, Trening kondycyjny,
Mobilność i regeneracja. `cw357` należy równocześnie do kalisteniki i jogi,
ale jest pojedynczym ćwiczeniem (podział 16+3+16+8+4 liczy grupę dodania,
nie liczbę wszystkich nakładających się tagów).

Anatomia: `back` obejmuje najszerszy, trapezy, romboidy i prostowniki;
`abs` mięśnie proste/poprzeczny/skośne. Osobno ramienny, stożek rotatorów,
zębaty przedni, zginacze bioder, przód goleni, szyja, przepona, mięśnie stóp,
QL. Nigdy Cardio/Mobilność/Koordynacja jako mięsień.

Główne i wspierające pochodzą z obu surowych kolumn, po scaleniu synonimów
bez dublowania tej samej grupy w obu rolach. Niejednoznaczne ogólniki
rozstrzygnięto na podstawie instrukcji ruchu, jawnie per ID, np.:

- cw032: biceps **i** plecy główne, nie tylko kategoria „plecy”;
- cw063/cw148: tył uda i pośladki główne, grzbiet wspierający;
- cw099: ramienny główny, biceps wspierający;
- cw168: piszczelowy przedni, nie łydki;
- cw234–241: rzeczywiste grupy nóg zamiast surowego „Cardio”;
- cw269–270: mięśnie szyi zamiast kategorii „mobilność”;
- cw300–301: przepona, nie „nerw błędny” jako mięsień;
- cw243–249, cw277, cw299: biodra/stawy rozłożone na pracujące lub
  rozciągane grupy według opisu, nie automatycznie wszystkie mięśnie nóg.

W rozciąganiu `primaryMuscles` oznacza główną grupę docelową, nie twierdzenie,
że mięsień wytwarza największą siłę. Wspierające to istotne grupy pomocnicze
lub dodatkowo rozciągane. Klasyfikacja nie jest pomiarem EMG ani poradą
rehabilitacyjną. Wynik jest wersjonowany i dostępny offline; klient nie musi
rozpoznawać fragmentów nazw ani partii w runtime.

- `tracking: reps`: liczba pełnych powtórzeń; dla unilateral jedno
  powtórzenie dotyczy wybranej strony, nie sumy lewa+prawa.
- `tracking: time`: sekundy utrzymania lub pracy ciągłej. Stare ćwiczenia
  przepisywane w metrach (np. crab walk) otrzymują czas pracy, nie fikcyjne
  powtórzenia; przepisów w historycznym JSON nie zmieniono.
- `tracking: rounds`: jedna zapisana seria to jedna runda z czasem pracy
  w sekundach (np. locomotion, interwały, flow, oddech kwadratowy), nie
  wymuszenie obciążenia i nie liczba oddechów zakodowana jako powtórzenia.
- `unilateral: true`: ćwiczenie ma sensowny samodzielny wariant lewa/prawa
  lub kierunek pracy asymetrycznej (np. bark pod sandbagiem, podpierająca
  ręka, noga podporowa, bok rollout). Nie oznacza obowiązkowego side w
  starej historii. Kierunek krążenia nie jest stroną ciała: neck rolls,
  chin tuck i oburęczne rozciąganie nadgarstków mają `false`.

## Odtworzenie i sprawdzenie

Bez instalacji globalnych; Python **3.12**, zależności wraz z przechodnią
przypięte wersjami i hashami. Testy używają standardowego `unittest`.

```bash
ls /tmp/opencode
python3.12 -m venv /tmp/opencode/catalog-venv
/tmp/opencode/catalog-venv/bin/python -m pip install --require-hashes --only-binary=:all: -r tools/requirements-catalog.lock

# Tylko przy odtwarzaniu rozszerzenia workbooka (idempotentne, nie nadpisuje różnic):
/tmp/opencode/catalog-venv/bin/python tools/expand_catalog.py

# Normalny eksport źródłowego workbooka, bez ręcznej edycji JSON:
PATH="/tmp/opencode/catalog-venv/bin:$PATH" python3 tools/xlsx_to_json.py
/tmp/opencode/catalog-venv/bin/python tools/build_catalog_metadata.py

/tmp/opencode/catalog-venv/bin/python tools/expand_catalog.py --check
/tmp/opencode/catalog-venv/bin/python tools/build_catalog_metadata.py --check
/tmp/opencode/catalog-venv/bin/python tools/update_exercise_names_pl.py --check
/tmp/opencode/catalog-venv/bin/python tools/validate_catalog.py
/tmp/opencode/catalog-venv/bin/python -m unittest discover -s tools/tests -p test_catalog_pipeline.py -v
```

Walidacja obejmuje niezmienność 316 rekordów, ciągłość/unikalność ID,
kompletność pól i zakaz formuł w imporcie, oba nowe typy sprzętu, zgodność
mapy nazw i workbooka z eksportem, dokładne klucze schematu, pokrycie ID,
referencje do słowników, brak nakładania ról mięśni, typ boolean, poprawny
tracking, przypisanie źródeł, przypadki niejednoznaczne i odtwarzalność
sidecara. Kontrola nazw wykrywa tylko identyczne nazwy nowych ruchów;
semantyczną kontrolę dubletów opisano wyżej. Nie wymaga Dockera ani
instalowania zależności backendu; nie uruchamia testów integracyjnych.
