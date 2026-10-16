# Warunki wykonania — etap 5, przegląd 2026-10-16

## Kontrakt dla klienta

Addytywne rozszerzenie **schemaVersion: 1**, bez zmiany ID, ćwiczeń ani
dotychczasowych stylów, mięśni, aliasów, tracking/unilateral. Root sidecara
otrzymuje dwa rejestry `{id,label,aliases:[]}`, każdy z 363 wpisów ćwiczeń
dwie listy identyfikatorów `conditions` i `positions`.

| conditions.id | Dokładna etykieta |
|---|---|
| no_jumps | Bez skoków |
| quiet | Cichy trening |
| no_kneeling | Bez klęku |
| no_hand_support | Bez podporu na dłoniach |
| no_floor | Bez schodzenia na podłogę |
| small_space | Mało miejsca |

| positions.id | Dokładna etykieta |
|---|---|
| standing | Stojąco |
| seated | Siedząco |
| floor | Na podłodze |
| hanging | W zwisie |
| bench | Na ławce |

Przykład **fragmentu** nowego kontraktu:

```json
{
  "schemaVersion": 1,
  "conditions": [{"id": "no_jumps", "label": "Bez skoków", "aliases": []}],
  "positions": [{"id": "floor", "label": "Na podłodze", "aliases": []}],
  "exercises": {
    "cw333": {
      "conditions": ["no_jumps", "quiet", "small_space"],
      "positions": ["floor"]
    }
  }
}
```

To nie jest kompletny sidecar: pozostałe dotychczasowe root/pola ćwiczeń
pozostają zachowane. W rzeczywistym pliku są dokładnie wszystkie 6 warunków,
5 pozycji i wpisy cw001–cw363. `aliases` nowych rejestrów na razie są puste.

Obecność warunku oznacza pozytywnie sklasyfikowaną możliwość wykonania
**kanonicznego opisu**, nie możliwość uzyskaną przez dowolną regresję.
Brak warunku nie oznacza diagnozy ani zakazu ćwiczenia — obejmuje też
przypadki niejednoznaczne rozstrzygnięte zachowawczo. Warunki wybrane przez
użytkownika należy łączyć **AND**. Pozycje są niewyłączne; np. łódź cw347
ma `seated + floor`, wyciskanie siedząc cw065 `seated + bench`, a burpee
cw209 `standing + floor`. Pozycja nie jest dodatkowym stylem treningu.

## Dokładne interpretacje

### no_jumps

Bez skoków, odbić z fazą lotu i powtarzalnych wzorców lot–lądowanie.
Wykluczamy także podskoki w podporach, wyrzuty/przyciągnięcia obunóż w
burpee/squat thrust, szybkie hopowe zmiany nóg, bieg, monkey/frogger oraz
przerzut bokiem. „Burpee bez wyskoku” cw212/cw219 nie otrzymuje tagu:
pozostaje obunóż wyrzut nóg i lądowanie w podporze/przysiadzie.

Unoszenie jednej nogi, wymachy, wspięcie na palce bez odbicia, leg raise
w zwisie i kompresja w siadzie **nie** stają się skokiem. Sam dynamiczny
wyprost bioder bez opisanego wybicia/lądowania też nim nie jest (np.
zarzut sandbaga). Bieżnia: marsze cw235/cw241 otrzymują `no_jumps`, biegi
nie. Dla cw039/cw042, wejścia do stania na rękach oraz flow cw281
zachowawczo pominięto tag z uwagi na dopuszczone/nieokreślone wejścia i
przejścia z odbiciem. Nie uzasadniamy tagu wersją z krokiem z regresji.

### quiet

**Relatywnie niskoimpaktowe, wykonywane płynnie i kontrolowanie. Nie jest
to gwarancja ciszy ani określonego poziomu hałasu.** Podłoże, obuwie,
sprzęt, masa i sposób odstawiania ciężaru mają znaczenie. To objaśnienie
należy zachować przy prezentacji flagi; sama nazwa „Cichy trening” nie
powinna sugerować bezgłośności.

Nie przyznajemy go bieżni (także marszowi), skakance, burpee/half burpee,
plyometrii i lądowaniom monkey/frogger/cartwheel. Ostrożnie pomijamy też
dynamiczne zarzuty/rwania/wymachy oraz cykliczny kontakt metalowego ciężaru
z podłożem (cw052/cw194). Sandbag: spokojny martwy ciąg, przysiad,
wiosłowanie/strict press, łuki w klęku i most mogą mieć tag **wyłącznie
przy płynnym kontrolowanym wykonaniu, odpowiednio lekkim wypełnieniu i
spokojnym odłożeniu**. Drag cw330 go nie ma: tarcie worka o podłoże może
być słyszalne. Nie nadpisujemy recepty ciężaru ani treści ćwiczenia.

### no_kneeling

Kanoniczna praca bez kontaktu/oparcia kolan o powierzchnię. Dotyczy także
półklęku i kolana podpierającego się **na ławce** (cw046), nie tylko klęku
obunóż na podłodze. Kolano zbliżające się do podłoża, lecz jawnie pozostające
nad nim, jak w zwykłym zakroku/split squat/skater squat, nie jest klękiem.

Kółko cw333/cw334, Nordic cw153, bird dog, rozciągania w klęku, half-kneeling
arc press cw332 nie mają tagu. Pełny plank cw335 go ma — regresja na kolanach
nie zmienia klasyfikacji pełnej pozycji. Kolana oparte **na ramionach**
w crow cw357 nie dotykają podłoża, dlatego tag jest obecny.

Przy możliwym kontakcie kolan w leżeniu przodem/bokiem, siadzie 90/90,
motylu czy skręcie z podwiniętą nogą zachowawczo nie przyznajemy tagu,
zamiast obiecywać brak kontaktu dla każdego zakresu. Dotyczy to m.in.
cw059–061/cw090/cw161/cw185/cw251–252/cw254–258/cw268/cw346/cw348.
Pełny shrimp cw354 dochodzi tylnym kolanem ku podłożu — zachowawczo bez
tagu; płytsza regresja nie jest podstawą przyznania go.

### no_hand_support

Bez przenoszenia ciężaru ciała na dłonie/palce lub trzymane uchwyty użyte
jako podparcie. Pompki, archer/T-push-up, handstand, plank na hantlach,
rollout/kółko, crow oraz podparcie ręką na ławce nie otrzymują tagu.
Zachowawczo wykluczamy również podtrzymywanie masy ciała w zwisie oraz
kotwienie ciężaru ciała chwytem ławki w dragon flag. Nie mylić tego
z chwytem hantla/worka jako **zewnętrznego obciążenia**: sam chwyt nie
wyklucza warunku (np. cw047/cw093/cw317).

Podpór na **przedramionach**, bez przenoszenia ciężaru na dłonie, nie
wyklucza flagi: cw169, cw171–173, cw178, frog stretch cw258. Zmienny
high/forearm plank cw177 jej nie dostaje, bo opis dopuszcza obciążenie dłoni.
Trzymanie ściany/drążka/gumy dla balansu lub oparcie dłoni o goleń jest
ocenione zachowawczo (m.in. cw138/cw140/cw164/cw243–244/cw264/cw339/cw341).
Lekkie trzymanie własnej stopy w drzewie/rozciąganiu lub happy baby nie
jest samo w sobie podparciem ciężaru ciała na dłoniach.

### no_floor

Bez przyjmowania pozycji siedzącej/leżącej/klęcznej/podporu na poziomie
podłogi ani przechodzenia do takiej pozycji w sekwencji. Zwykły kontakt
stóp z podłogą się nie liczy. Skłon wykonywany nadal stojąc, nawet jeśli
dłoń sięga podłogi (cw341/cw350), nie oznacza automatycznie „schodzenia
na podłogę”; może jednak nie spełniać osobnego `no_hand_support`.

Leżenie **na ławce** (cw012–013/cw016–019/cw107–108/cw204) spełnia
`no_floor`: ławka jest innym, podwyższonym podparciem, nie podłogą.
Hip thrust i extension z górą pleców na ławce oraz niską pozycją bioder
cw156–157/cw267 zachowawczo mają `floor + bench`, bez `no_floor`.
Pompki z nogami na ławce nadal mają `floor + bench` i nie spełniają warunku.
Siedzące tai chi na krześle ma wyłącznie `seated` oraz `no_floor`.

### small_space

**Bez przemieszczania poza własne stanowisko; sprzęt musi się zmieścić.**
Stanowisko obejmuje pełny zakres kończyn, matę/ławkę/kółko, zaczepy gum
oraz potrzebny prześwit i wysokość. Tag nie gwarantuje zmieszczenia się
w konkretnym pokoju ani nie oznacza „bez sprzętu”.

Wykluczamy chody farmera/suitcase, wykroki chodzone, monster walk,
locomotion/crawle/monkey/frogger, gąsienicę, przerzut bokiem, skoki w dal,
skoki boczne i skakankę (obwiednia liny). Box jump cw146 oraz burpee pod
drążkiem cw315 także zachowawczo bez flagi ze względu na strefę wejścia,
lądowania i przejść. Pojedynczy zakrok lub wykrok z powrotem na to samo
stanowisko nie jest wykrokiem chodzonym. Bieżnia może mieć `small_space`,
bo pozostaje na stanowisku, **o ile fizycznie mieści się sam sprzęt**;
nie otrzymuje z tego powodu `quiet`.

## Pozycje i niejednoznaczne stare opisy

- `standing`: praca na stopach, w tym przysiad/wykrok/skłon stojąc;
- `seated`: podparcie/ustawienie w siadzie, na krześle, ławce lub podłodze;
- `floor`: praca przy podłodze, w leżeniu, klęku, siadzie lub niskim podporze;
- `hanging`: zwis/podciąganie, nie zwykły chwyt drążka do balansu;
- `bench`: rzeczywiście używane podparcie na ławce, również stóp/kolana,
  a nie samo wystąpienie ławki na liście sprzętu.

Nie dodajemy pozycji tylko dlatego, że istnieje w progresji/regresji.
Gdy sam opis dopuszcza kilka równoprawnych wykonań, pozycje są sumą
tych wykonań, a warunki „bez” zachowawcze: cw024 „leżysz lub stoisz” ma
`standing + floor`, cw057 „klęk lub siad” ma `seated + floor`, bez
`no_kneeling`, cw275 „siedzisz lub stoisz” ma `standing + seated`.
cw301 „leżysz lub siedzisz” ma `seated + floor`, bez `no_floor`, mimo
krzesła w surowym sprzęcie. Sprzętu ani starego opisu nie poprawiamy.

Konwencje dla opisów nieprecyzyjnych, jawne w wejściu per ID:

- cw015: squeeze press traktowany zachowawczo jako wykonanie poziome na
  podłodze przy braku zadeklarowanej ławki; nie obiecujemy `no_floor`;
- cw056: siad na podłodze, cw268: siad na podłodze bez jawnego krzesła;
- cw067/cw068/cw105/cw106 oraz mobilizacja cw269–273/cw278–279:
  pionowa/stojąca wersja przy braku wskazanego siedziska;
- cw117/cw118/cw166: siedzisko podwyższone, bez narzucania konkretnej ławki,
  dlatego samo `seated`; cw065/cw096/cw098 jawnie wykorzystują ławkę;
- cw128: klasyczny kontrolowany split squat z tylną stopą na ławce;
  niefortunne stare słowo „wyskok” nie jest instrukcją dodania odbicia do
  tego ruchu; cw302 ma natomiast niejednoznaczne dynamiczne wybicie i
  zachowawczo nie ma `no_jumps`;
- cw203: podpór L-sit opisany na podłodze lub uchwycie, **nie zwis**;
  `seated + floor`, bez `no_hand_support` i bez `no_floor`;
- cw354: pełny shrimp ku kolanu przy podłożu, `standing + floor`;
  nie jest to płytszy skater squat cw139, którego kolano jawnie pozostaje
  nad podłogą.

To redakcyjna klasyfikacja wykonania, **nie rehabilitacja, diagnoza,
zalecenie przy bólu ani zapewnienie bezpieczeństwa dla stanu zdrowia**.
Filtry dotyczą wyłącznie opisanych cech ruchu i warunków otoczenia.

## Źródło i odtwarzanie

`tools/source_data/exercise_execution_conditions.json` jest jawnym,
wersjonowanym wejściem: pełne listy decyzji dla każdego z 363 ID.
Przegląd oparto na nazwach **i pełnych kluczowych wskazówkach** bieżących
rekordów, a nie regułach wyszukiwania słów w runtime. Przypadki wymagające
konwencji zapisano powyżej. Brak automatycznego dopowiadania warunków
z nazwy, mięśni, stylu, sprzętu czy trudności.

`build_execution_conditions.py` sprawdza dokładne rejestry, etykiety,
pokrycie ID, klucze, typy, referencje i brak sprzeczności `floor/no_floor`.
`build_catalog_metadata.py` kopiuje te decyzje do sidecara; nie zmienia
starej części metadanych. Przyszłe ćwiczenie bez ręcznie dodanego wpisu
powoduje błąd pokrycia zamiast otrzymać domyślne lub odgadnięte warunki.

Python 3.12, istniejący venv i hash-locked dependencies, bez nowych pakietów:

```bash
/tmp/opencode/catalog-venv/bin/python tools/build_catalog_metadata.py
/tmp/opencode/catalog-venv/bin/python tools/build_catalog_metadata.py --check
/tmp/opencode/catalog-venv/bin/python tools/build_execution_conditions.py --check
/tmp/opencode/catalog-venv/bin/python tools/validate_catalog.py
/tmp/opencode/catalog-venv/bin/python tools/expand_catalog.py --check
/tmp/opencode/catalog-venv/bin/python tools/update_exercise_names_pl.py --check
/tmp/opencode/catalog-venv/bin/python -m unittest discover -s tools/tests -p test_catalog_pipeline.py -v
/tmp/opencode/catalog-venv/bin/python -m unittest discover -s tools/tests -p test_execution_conditions.py -v
```

**Nie uruchamiać konwertera zapisującego ćwiczenia ani narzędzia zapisującego
workbook w tym etapie.** `--check` jedynie weryfikuje zgodność danych.
Testy pinują hash wszystkich 363 ćwiczeń, XLSX, mapy nazw i rejestru źródeł
oraz starej projekcji metadanych. Dotychczasowe 23 testy nadal sprawdzają
oryginalny hash prefiksu 316 i zawartość wszystkich 47 dodatków.
