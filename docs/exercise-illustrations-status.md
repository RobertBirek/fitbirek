# Status ilustracji ćwiczeń

## Integracja lokalna — 2026-10-29 (431 ilustracji, niewydane)

Katalog i rejestr obejmują **431 ID (`cw001–cw431`)**. cw425–cw431 mają
własne ścieżki WebP; publiczny `awaitingIllustrationExerciseIds` jest pusty.
Nie zmieniono renderera ani zachowania bezpiecznego braku obrazu dla
nieznanych ID (w tym cw432). Nie zmieniano wcześniejszych424 assetów.

TDD RED przed zmianą rejestru potwierdził brak nowych plików i wpisów
w manifeście oraz błąd ładowania cw425.webp przez rzeczywisty codec Fluttera.
Test wymaga dokładnie431 ID katalogu/rejestru/plików/manifestu i dekodowania
każdego obrazu jako512×512; testy szczegółów wymagają własnego obrazu każdego
nowego ruchu i braku tekstu oczekiwania. Końcowe focused testy: **25 PASS**,
w tym dekodowanie wszystkich431 WebP512 i siedem kart szczegółów bez pending.
Niezależny przegląd wizualny: **7 PASS /0 FAIL**, bez wymaganych korekt.
Wcześniejsze424 obrazy porównane bajtowo z bazą f0c849c: bez zmian.
[Źródła, próby i koszt](bodyweight-illustrations-2026-10-29-results.md).
Pełna analiza czysta; build web i generator offline PASS. Prywatny pakiet:
**508 plików /48 608 913B**, wszystkie hashe/długości i431 obrazy zgodne.
PackageId `b0d92848cb7b5017dc6412eabb7b73087a68447471e64cecfb1c032775ad3e1c`.
Ilustracje poza CORE, zgoda na pełny pakiet bez zmian. Pierwszy izolowany
przebieg miał starsze testy z obrazu narzędziowego; ponowiono z aktualnym
katalogiem testów bez zmiany kodu. Pełnego suite Flutter/backend nie ponawiano.
To stan niewydany, nie deklaracja publikacji.

## Historyczne wydanie — 2026-10-22 (424 ilustracje, wydano1.23.1+40)

Katalog obejmuje **424 ćwiczenia i 424 ilustracje (`cw001–cw424`), bez
oczekujących ID**. Nowe **12 (`cw413–cw424`)** opublikowano, a wszystkie
wcześniejsze **412 ilustracji** pozostają identyczne bajtowo z wydanym źródłem.
Niezależny przegląd wizualny zaakceptował komplet; dla cw421 przyjęto próbę03
z jawnym ograniczeniem zasłoniętej perspektywą dalszej dłoni, bez nowej generacji.
[Metoda, źródła i koszty](owner-equipment-illustrations-2026-10-22-results.md).

Potwierdzono TDD RED przed rozszerzeniem rejestru: brak `cw413` w rejestrze,
plikach i manifeście oraz błąd ładowania `cw413.webp` podczas dekodowania.
Test wymaga dokładnych zbiorów ID/pliki/manifest i rzeczywistego dekodowania
każdej z 424 ilustracji jako **512×512**. Końcowy focused odbiór ilustracji
i rzeczywistej integracji katalogu: **21 PASS**. Potwierdzono dokładne zbiory
rejestru/plików/manifestu oraz dekodowanie wszystkich obrazów.
Pełna analiza czysta; prywatny build web i generator pakietu offline PASS.
Pakiet: **501 plików /48 364 768B**, packageId
`dd7567f560fde5c5d00410fc29bdd3434a6243462901f3949a065e5889c21273`.
Sprawdzono501/501 hashów i długości oraz zgodność wszystkich424 obrazów ze
źródłami. Ilustracje pozostają poza CORE, z dotychczasową zgodą na pełny pakiet.
Znane ostrzeżenia opcjonalnego Wasm dry-run nie blokują wybranego JS/CanvasKit.

**1.23.1+40 wdrożono2026-10-22 13:03:57UTC**, source `d409438`; końcowy
audyt13:04:48UTC. Finalny pakiet501/48 364 768B, packageId
`86ceee4e7e599febce4a907cb530285d304ad6e662c40d625bc68498b905b7de`.
Publiczne501/501 hashów i wszystkie424 ilustracje PASS; Dockerverification
1561PASS/1UTCskip, izolowanyWarsaw1PASS, analiza czysta. Backup i restore PASS,
bez zmian API/danych/schematu. Powyższy prywatny packageId opisuje wcześniejszy
odbiór, nie finalny pakiet wydania. Telefon/VoiceOver/PWA do odbioru.
[Wdrożenie i rollback](releases/2026-10-22-illustrations-1.23.1-40.md).
Poniższy stan412 jest historyczny.

## Historyczne wydanie — 2026-10-21 (1.20.0+36)

**412 ćwiczeń i 412 ilustracji = 412 wydanych + 0 niewydanych,
0 brakujących**. Nowe `cw409–cw411` to gryf łamany EZ, `cw412` to rowerek
stacjonarny. Wszystkie wcześniejsze 408 rekordów/metadanych i obrazów zachowano.
[Źródła ilustracji i koszt](ez-illustrations-2026-10-21-results.md).

Kanoniczny kandydat runtime: **1348 Flutter tests PASS**, analiza bez problemów,
kontrola wersji i kompilacja PASS. Pakiet offline: **486 plików / 47 823 677 B**.
Niezależny przegląd katalogu i czterech obrazów: brak HIGH/MEDIUM. Commit
`8f4ff6a` wypchnięty do main; produkcyjna 1.20.0+36 zweryfikowana publicznie:
486/486 hashy i długości zgodnych. [Wdrożenie](releases/2026-10-21-web-1.20.0-36.md).

## Poprzednie wydanie — 2026-10-20 (1.19.1+35)

Katalog obejmuje **408 ćwiczeń**. Wydanie web **1.19.0+34** zachowuje
**369 wydanych ilustracji (`cw001–cw369`)**; nowe `cw370–cw408` (39 ćwiczeń)
wydano wtedy jako wpisy tekstowe z placeholderem, bez ilustracji:
[dowody wydania](releases/2026-10-20-web-1.19.0-34.md).

Rejestr, pliki i testy obejmują **408 ilustracji = 408 wydanych +
0 lokalnych niewydanych, 0 brakujących**. Wygenerowano i obejrzano wszystkie
nowe `cw370–cw408`; wcześniejsze 369 plików pozostało identycznych bajtowo.
[Sceny, źródła, korekty i koszty](exercise-illustrations-2026-10-20-results.md).

Testy wymagają dokładnej zgodności ID katalogu, rejestru, plików WebP i manifestu
assetów oraz dekodowania każdego z 408 oczekiwanych obrazów jako 512×512.
Potwierdzono etap TDD RED przed zmianą rejestru (brak `cw370`) i końcowy GREEN:
Docker verification zaliczył **1346 testów**, analizę bez problemów i kontrolę
wersji. Niezależny przegląd obrazów i integracji: bez problemów HIGH/MEDIUM.
Wydano web **1.19.1+35**: publiczne **482/482 SHA-256 i długości**, w tym
408 ilustracji, zgodne z kandydatem. Backup i izolowany restore PASS;
API, PostgreSQL i Caddy bez zmian. [Raport wdrożenia](releases/2026-10-20-web-1.19.1-35.md).

## Historia wydanych ilustracji

Stan historyczny na 2026-10-17, produkcyjna wersja webowa 1.14.0+27.
Wszystkie369 ilustracji sprawdzono publicznie (HTTP, MIME i SHA-256),
w tym sześć nowych; poprzednie363 zachowano bez zmian.
[Aktualne dowody](releases/2026-10-17-api-web-1.14.0-27.md).

Ówczesny katalog lokalny obejmował **369 ćwiczeń i 369 ilustracji**:
**369 publicznie wydanych, 0 lokalnych niewydanych, 0 brakujących**.
Nowe `cw364–cw369` wydano w1.14.0+27;
[przegląd, źródła i koszt](spine-illustrations-2026-10-16.md).
Poprzednie47 (`cw317–cw363`) wydano w1.12.0+25.
Wszystkie363 WebP zweryfikowano publicznie (HTTP/type/cache/SHA-256):
[wydanie1.12.0+25](releases/2026-10-16-web-1.12.0-25.md).
Źródła rozszerzenia i funkcje: [raport](catalog-expansion-2026-10-16.md).
Partie 28–46 (`cw139–cw250`, 112 ilustracji) wydano w `1.11.0+24`.
Wszystkie 316 obrazów zweryfikowano publicznie; dowody:
[wydanie 1.11.0+24](releases/2026-10-16-web-1.11.0-24.md).
Zakończono autonomiczne domknięcie cw157–cw250;
szczegóły: [rejestr wykonania](superpowers/specs/2026-10-15-exercise-illustrations-completion-results.md).

Partie 07–27 (`cw013–cw138`) wydano wspólnie w wersji webowej `1.10.0+23`.
Wszystkie 126 nowych ilustracji oraz 78 wcześniejszych zweryfikowano publicznie.
Dowody: [wydanie 1.10.0+23](releases/2026-10-15-web-1.10.0-23.md).

Wydanie `1.9.0+22` obejmuje obie Partie 05 i 06 (`cw001–cw012`)
oraz zachowuje wszystkie 66 wcześniej wydanych ilustracji, w tym sześć z Partii 04.

## Ilustracje — rejestr i historyczny status integracji

**Aktualny status cw364–cw369: wydane w 1.14.0+27.**
**Aktualny status cw317–cw363: wydane w 1.12.0+25.**
Poniższe opisy lokalnej integracji rozszerzenia zachowują historię przed wydaniem.
**Aktualny status cw013–cw138: wydane w 1.10.0+23.**
**Aktualny status cw139–cw250: wydane w 1.11.0+24.** Zachowane poniżej
oznaczenia „lokalnie zintegrowane; niewydane” oraz opisy Partii 07–46
dokumentują stan w chwili ukończenia poszczególnych pakietów. Wydania
opisane powyżej zastępują te historyczne oznaczenia publikacji; warianty,
liczby kadrów i historia generacji pozostają aktualne.

| ID | Ćwiczenie | Kadry | Status |
|---|---|---:|---|
| cw364 | Przetaczanie miednicy w leżeniu na plecach | 2 | Wydane w 1.14.0+27. Biodra pozostają na podłożu. |
| cw365 | Łagodne napięcie brzucha w leżeniu z normalnym oddechem | 1 | Wydane w 1.14.0+27. Oddech pozostaje instrukcją tekstową. |
| cw366 | Kołysanie ugiętych kolan w leżeniu na plecach | 3 | Wydane w 1.14.0+27. Stałe barki, stopy przy podłożu. |
| cw367 | Otwarta książka — obrót klatki w leżeniu bokiem | 2 | Wydane w 1.14.0+27. Kolana razem na podłożu. |
| cw368 | Przyciąganie jednego kolana do klatki w leżeniu | 1 | Wydane w 1.14.0+27. Druga noga ugięta, stopa oparta. |
| cw369 | Cofanie bioder do ściany bez obciążenia | 2 | Wydane w 1.14.0+27. Zawias biodrowy, kontakt ze ścianą. |
| cw001 | Pompki klasyczne | 2 | Wydane w 1.9.0+22. |
| cw002 | Pompki wąskie (diamentowe) | 2 | Wydane w 1.9.0+22. |
| cw003 | Pompki szerokie | 2 | Wydane w 1.9.0+22. |
| cw004 | Pompki łucznika | 2 | Wydane w 1.9.0+22. |
| cw005 | Pompki na jednej ręce | 2 | Wydane w 1.9.0+22. |
| cw006 | Pompki plyometryczne z klaśnięciem | 2 | Wydane w 1.9.0+22. |
| cw007 | Pompki hinduskie | 3 | Wydane w 1.9.0+22. |
| cw008 | Pompki z przyciąganiem kolana do łokcia | 2 | Wydane w 1.9.0+22. |
| cw009 | Pompki z podniesionymi nogami | 2 | Wydane w 1.9.0+22. |
| cw010 | Głębokie pompki na hantlach | 2 | Wydane w 1.9.0+22. |
| cw011 | Pompki z rotacją | 3 | Wydane w 1.9.0+22. |
| cw012 | Wyciskanie hantli na ławce płaskiej | 2 | Wydane w 1.9.0+22. |
| cw013 | Wyciskanie hantli na ławce skośnej głową w górę | 2 | Lokalnie zintegrowane; niewydane. |
| cw014 | Wyciskanie hantli w leżeniu na podłodze | 2 | Lokalnie zintegrowane; niewydane. |
| cw015 | Wyciskanie ściskające hantlami | 2 | Lokalnie zintegrowane; niewydane; wariant w staniu. |
| cw016 | Rozpiętki z hantlami na ławce płaskiej | 2 | Lokalnie zintegrowane; niewydane. |
| cw017 | Rozpiętki z hantlami na ławce skośnej głową w górę | 2 | Lokalnie zintegrowane; niewydane. |
| cw018 | Rozpiętki z hantlami w leżeniu na podłodze | 2 | Lokalnie zintegrowane; niewydane. |
| cw019 | Przenoszenie hantla za głowę w leżeniu na ławce | 2 | Lokalnie zintegrowane; niewydane; leżenie wzdłuż ławki. |
| cw020 | Wyciskanie hantli w moście biodrowym | 2 | Lokalnie zintegrowane; niewydane. |
| cw021 | Wyciskanie gumy przed klatkę piersiową w staniu | 2 | Lokalnie zintegrowane; niewydane. |
| cw022 | Rozpiętki z gumą w staniu | 2 | Lokalnie zintegrowane; niewydane. |
| cw023 | Pompka z gumą na plecach | 2 | Lokalnie zintegrowane; niewydane. |
| cw024 | Ściąganie gumy znad głowy do bioder na prostych ramionach | 2 | Lokalnie zintegrowane; niewydane; wariant w staniu. |
| cw025 | Pompki między krzesłami lub na ławce (na klatkę piersiową) | 2 | Lokalnie zintegrowane; niewydane; dłonie i pięty na dwóch ławkach. |
| cw026 | Pompki z dłońmi przy biodrach i pochyleniem w przód | 2 | Lokalnie zintegrowane; niewydane; palce skierowane na zewnątrz. |
| cw027 | Pompki na palcach | 2 | Lokalnie zintegrowane; niewydane; widok frontalny, podparcie na opuszkach pięciu palców każdej dłoni. |
| cw028 | Pompki łucznika z nogami na ławce | 2 | Lokalnie zintegrowane; niewydane. |
| cw029 | Pompki z pauzą | 2 | Lokalnie zintegrowane; niewydane; czas pauzy pozostaje w opisie katalogowym. |
| cw030 | Pompki eksplozywne z przeskokiem w bok | 3 | Lokalnie zintegrowane; niewydane; trzy poziome pasy pełnej szerokości, ułożone pionowo od góry do dołu, widok frontalny i stały szew podłogi: nisko po lewej → środek z dłońmi w powietrzu → lądowanie po prawej na ugiętych ramionach. |
| cw031 | Podciąganie szerokim nachwytem | 2 | Lokalnie zintegrowane; niewydane. |
| cw032 | Podciąganie podchwytem | 2 | Lokalnie zintegrowane; niewydane. |
| cw033 | Podciąganie chwytem neutralnym | 2 | Lokalnie zintegrowane; niewydane; dwa równoległe uchwyty. |
| cw034 | Podciąganie wąskim chwytem | 2 | Lokalnie zintegrowane; niewydane; wariant nachwytem. |
| cw035 | Podciąganie chwytem mieszanym | 2 | Lokalnie zintegrowane; niewydane; prawa dłoń nachwytem, lewa podchwytem. |
| cw036 | Podciąganie z pauzą na górze | 2 | Lokalnie zintegrowane; niewydane; nachwyt na szerokość barków, czas pauzy w katalogu. |
| cw037 | Podciąganie z prostymi nogami uniesionymi do poziomu | 2 | Lokalnie zintegrowane; niewydane; L utrzymane w obu fazach. |
| cw038 | Podciąganie łucznika | 2 | Lokalnie zintegrowane; niewydane; prawa ręka robocza, lewa pomocnicza prosta. |
| cw039 | Opuszczanie na jednej ręce z podciągnięcia | 3 | Lokalnie zintegrowane; niewydane; trzy pionowe kolumny, prawa ręka podporowa. |
| cw040 | Podciąganie do klatki | 2 | Lokalnie zintegrowane; niewydane; drążek przy górnym mostku. |
| cw041 | Podciąganie eksplozywne | 2 | Lokalnie zintegrowane; niewydane; wysokie podciągnięcie, bez podporu muscle-up. |
| cw042 | Opuszczanie z podciągnięcia | 3 | Lokalnie zintegrowane; niewydane; trzy pionowe kolumny opuszczania oburącz. |
| cw043 | Zwis martwy | 1 | Lokalnie zintegrowane; niewydane; rozluźniony zwis. |
| cw044 | Aktywny zwis | 1 | Lokalnie zintegrowane; niewydane; aktywne barki, proste łokcie. |
| cw045 | Podciąganie łopatkowe | 2 | Lokalnie zintegrowane; niewydane; proste łokcie w obu fazach. |
| cw046 | Wiosłowanie hantlem jednorącz | 2 | Lokalnie zintegrowane; niewydane; prawa ręka robocza, lewa dłoń i kolano na ławce. |
| cw047 | Wiosłowanie hantlami w opadzie | 2 | Lokalnie zintegrowane; niewydane; stały zawias biodrowy. |
| cw048 | Wiosłowanie hantlami z klatką opartą na ławce skośnej | 2 | Lokalnie zintegrowane; niewydane; klatka podparta w obu fazach. |
| cw049 | Wiosłowanie hantlami w podporze przodem | 2 | Lokalnie zintegrowane; niewydane; prawa ręka robocza. |
| cw050 | Wiosłowanie Meadowsa z hantlem | 2 | Lokalnie zintegrowane; niewydane; chwyt za uchwyt nachwytem, ustawienie pionowe traktowane jako przygotowanie. |
| cw051 | Wiosłowanie hantlami podchwytem | 2 | Lokalnie zintegrowane; niewydane; dwa podchwyty, stały zawias biodrowy. |
| cw052 | Naprzemienne wiosłowanie hantlami z podłogi w opadzie | 3 | Lokalnie zintegrowane; niewydane; trzy pionowe kolumny: start, prawa, lewa. |
| cw053 | Ściąganie łopatek Kelso z hantlami na ławce skośnej | 2 | Lokalnie zintegrowane; niewydane; retrakcja bez zgięcia łokci. |
| cw054 | Wzruszanie barkami z hantlami | 2 | Lokalnie zintegrowane; niewydane; proste łokcie, pionowe uniesienie barków. |
| cw055 | Rozciąganie gumy przed klatką piersiową | 2 | Lokalnie zintegrowane; niewydane; bez zewnętrznej kotwy. |
| cw056 | Wiosłowanie gumą w siadzie | 2 | Lokalnie zintegrowane; niewydane; siad na podłodze, niska kotwa przed ciałem. |
| cw057 | Ściąganie gumy z góry do klatki piersiowej | 2 | Lokalnie zintegrowane; niewydane; klęk obunóż, stały widok frontalny. |
| cw058 | Face pull z gumą | 2 | Lokalnie zintegrowane; niewydane; widok frontalny, końce rozdzielone przy twarzy. |
| cw059 | Unoszenie ramion i nóg w leżeniu na brzuchu | 2 | Lokalnie zintegrowane; niewydane; dwa poziome pasy od góry do dołu, podparta miednica. |
| cw060 | Utrzymanie uniesionych ramion i nóg w leżeniu na brzuchu | 1 | Lokalnie zintegrowane; niewydane; czas utrzymania w katalogu. |
| cw061 | Przenoszenie ramion łukiem nad głowę w leżeniu na brzuchu | 3 | Lokalnie zintegrowane; niewydane; trzy poziome pasy, nogi podparte. |
| cw062 | Skłony tułowia z hantlem i cofnięciem bioder | 2 | Lokalnie zintegrowane; niewydane; jeden hantel oburącz przed klatką. |
| cw063 | Rumuński martwy ciąg z hantlami | 2 | Lokalnie zintegrowane; niewydane; dwa hantle blisko goleni. |
| cw064 | Wiosłowanie oburącz hantlem opartym jednym końcem w rogu | 2 | Lokalnie zintegrowane; niewydane; krótki hantel, podparty koniec i częściowy zakres. |
| cw065 | Wyciskanie hantli nad głowę w siadzie | 2 | Lokalnie zintegrowane; niewydane; plecy i stopy podparte. |
| cw066 | Wyciskanie hantli nad głowę w staniu | 2 | Lokalnie zintegrowane; niewydane; strict press bez wybicia nogami. |
| cw067 | Wyciskanie Arnolda z hantlami | 3 | Lokalnie zintegrowane; niewydane; stój, trzy kolumny rotacji chwytu. |
| cw068 | Wyciskanie hantli nad głowę chwytem neutralnym | 2 | Lokalnie zintegrowane; niewydane; dłonie do siebie cały czas. |
| cw069 | Wyciskanie hantli nad głowę z wybiciem z nóg | 3 | Lokalnie zintegrowane; niewydane; stój, płytki dip, wyciskanie. |
| cw070 | Unoszenie hantli bokiem | 2 | Lokalnie zintegrowane; niewydane; dwa poziome pasy. |
| cw071 | Unoszenie hantli bokiem w staniu na jednej nodze | 2 | Lokalnie zintegrowane; niewydane; prawa noga podporowa, dwa poziome pasy. |
| cw072 | Unoszenie hantli bokiem z pauzą | 2 | Lokalnie zintegrowane; niewydane; dwa poziome pasy, czas pauzy w katalogu. |
| cw073 | Unoszenie hantli w przód | 2 | Lokalnie zintegrowane; niewydane; równoczesny wznos obu rąk, nachwyt. |
| cw074 | Naprzemienne unoszenie hantli w przód | 3 | Lokalnie zintegrowane; niewydane; prawa, obie w połowie, lewa. |
| cw075 | Odwrotne rozpiętki z hantlami w opadzie | 2 | Lokalnie zintegrowane; niewydane; stały zawias około 45°, dwa poziome pasy. |
| cw076 | Odwrotne rozpiętki z hantlami na ławce skośnej | 2 | Lokalnie zintegrowane; niewydane; klatka podparta, dwa poziome pasy. |
| cw077 | Unoszenie hantli w kształt litery Y na ławce skośnej | 2 | Lokalnie zintegrowane; niewydane; Y względem tułowia, kciuki w górę. |
| cw078 | Pompki z biodrami uniesionymi wysoko | 2 | Lokalnie zintegrowane; niewydane; pike na podłodze, profil boczny i stałe podpory. |
| cw079 | Pompki z biodrami uniesionymi wysoko i nogami na ławce | 2 | Lokalnie zintegrowane; niewydane; stopy na ławce, dłonie na podłodze. |
| cw080 | Stanie na rękach przy ścianie | 1 | Lokalnie zintegrowane; niewydane; plecami do ściany, czas w katalogu. |
| cw081 | Pompki w staniu na rękach przy ścianie | 2 | Lokalnie zintegrowane; niewydane; plecami do ściany, pięty przesuwają się pionowo. |
| cw082 | Wyciskanie gumy nad głowę | 2 | Lokalnie zintegrowane; niewydane; jedna guma pod obiema stopami. |
| cw083 | Unoszenie ramienia bokiem z gumą | 2 | Lokalnie zintegrowane; niewydane; lewa stopa kotwiąca, prawa ręka robocza. |
| cw084 | Unoszenie ramion w przód z gumą | 2 | Lokalnie zintegrowane; niewydane; dwie gałęzie jednej gumy pod obiema stopami. |
| cw085 | Face pull z gumą | 2 | Lokalnie zintegrowane; niewydane; przednia kotwa na poziomie oczu. |
| cw086 | Rozciąganie gumy przed klatką piersiową | 2 | Lokalnie zintegrowane; niewydane; kopia grafiki cw055, bez nowej generacji. |
| cw087 | Rotacja zewnętrzna ramienia z gumą | 2 | Lokalnie zintegrowane; niewydane; prawa ręka, lewa kotwa, ręcznik przy łokciu. |
| cw088 | Rotacja wewnętrzna ramienia z gumą | 2 | Lokalnie zintegrowane; niewydane; prawa ręka, prawa kotwa. |
| cw089 | Wyciskanie kubańskie z hantlami | 4 | Lokalnie zintegrowane; niewydane; cztery fazy w siatce 2×2. |
| cw090 | Rotacja zewnętrzna ramienia z hantlem w leżeniu bokiem | 2 | Lokalnie zintegrowane; niewydane; lewy bok, prawa ręka robocza. |
| cw091 | Unoszenie hantli w skos w przód z kciukami w dół | 2 | Lokalnie zintegrowane; niewydane; scaption, kciukowe strony w dół. |
| cw092 | Unoszenie hantli w skos w przód z kciukami w górę | 2 | Lokalnie zintegrowane; niewydane; scaption, kciukowe strony w górę. |
| cw093 | Uginanie przedramion z hantlami w staniu | 2 | Lokalnie zintegrowane; niewydane; oburącz z supinacją. |
| cw094 | Uginanie młotkowe z hantlami | 2 | Lokalnie zintegrowane; niewydane; chwyt neutralny przez cały ruch. |
| cw095 | Naprzemienne uginanie przedramion z hantlami | 3 | Lokalnie zintegrowane; niewydane; prawa, obie w połowie, lewa. |
| cw096 | Uginanie przedramion z hantlami na ławce skośnej | 2 | Lokalnie zintegrowane; niewydane; oparcie około 55°, ramiona w zwisie. |
| cw097 | Uginanie Zottmana z hantlami | 4 | Lokalnie zintegrowane; niewydane; podchwyt w górę, nachwyt w dół, siatka 2×2. |
| cw098 | Uginanie przedramienia z hantlem w oparciu o udo | 2 | Lokalnie zintegrowane; niewydane; prawa ręka i podparcie o prawe udo. |
| cw099 | Uginanie młotkowe z hantlem do przeciwnego barku | 2 | Lokalnie zintegrowane; niewydane; jeden hantel, prawa ręka ku lewemu barkowi. |
| cw100 | Uginanie przedramion z hantlami nachwytem | 2 | Lokalnie zintegrowane; niewydane; nachwyt przez obie fazy. |
| cw101 | Uginanie przedramion z hantlami metodą 21 powtórzeń | 3 | Lokalnie zintegrowane; niewydane; punkty dół/połowa/góra, 7+7+7 w katalogu. |
| cw102 | Podciąganie podchwytem z naciskiem na biceps | 2 | Lokalnie zintegrowane; niewydane; podchwyt, pełny zwis i górna klatka blisko drążka. |
| cw103 | Uginanie przedramion z gumą | 2 | Lokalnie zintegrowane; niewydane; jedna guma pod obiema stopami, podchwyt. |
| cw104 | Uginanie przedramion z hantlami prowadzonymi wzdłuż tułowia | 2 | Lokalnie zintegrowane; niewydane; łokcie cofane w tył, krótki górny zakres. |
| cw105 | Wyciskanie francuskie hantla oburącz nad głową | 2 | Lokalnie zintegrowane; niewydane; stój, jeden pionowy hantel podparty oburącz pod górną głowicą. |
| cw106 | Wyciskanie francuskie hantla jednorącz nad głową | 2 | Lokalnie zintegrowane; niewydane; stój, prawa ręka robocza, lewa stabilizuje ramię. |
| cw107 | Wyciskanie francuskie hantli w leżeniu na ławce | 2 | Lokalnie zintegrowane; niewydane; hantle obok czoła, dwa poziome pasy. |
| cw108 | Wyciskanie hantli wąsko na ławce | 2 | Lokalnie zintegrowane; niewydane; stykające się hantle neutralnie, kamera od strony stóp 3/4. |
| cw109 | Prostowanie przedramienia z hantlem w opadzie | 2 | Lokalnie zintegrowane; niewydane; prawa ręka, poziome górne ramię i stały łokieć. |
| cw110 | Pompki diamentowe z naciskiem na triceps | 2 | Lokalnie zintegrowane; niewydane; identyczna kopia cw002, bez nowej generacji. |
| cw111 | Pompki tyłem na ławce | 2 | Lokalnie zintegrowane; niewydane; jedna ławka, nogi proste, pięty na podłodze, ujęcie przednie 3/4. |
| cw112 | Pompki tyłem na ławce z hantlem na udach | 2 | Lokalnie zintegrowane; niewydane; jeden hantel podparty na górnych udach, ujęcie przednie 3/4. |
| cw113 | Wyciskanie JM z hantlami | 2 | Lokalnie zintegrowane; niewydane; dwa hantle neutralnie, do brody z obniżeniem łokci. |
| cw114 | Prostowanie przedramion w dół z gumą | 2 | Lokalnie zintegrowane; niewydane; wysoka kotwa przed ciałem, dwie napięte gałęzie i uchwyty. |
| cw115 | Prostowanie przedramion nad głową z gumą | 2 | Lokalnie zintegrowane; niewydane; niska zewnętrzna kotwa za ciałem, dwa uchwyty. |
| cw116 | Wyciskanie Tate'a z hantlami | 2 | Lokalnie zintegrowane; niewydane; nachwyt, łokcie na zewnątrz względem hantli, dwa poziome pasy. |
| cw117 | Uginanie nadgarstków z hantlami podchwytem | 2 | Lokalnie zintegrowane; niewydane; przedramiona na udach, ruch nadgarstków, podchwyt. |
| cw118 | Prostowanie nadgarstków z hantlami nachwytem | 2 | Lokalnie zintegrowane; niewydane; przedramiona na udach, wyprost nadgarstków, nachwyt. |
| cw119 | Chód farmera z hantlami | 2 | Lokalnie zintegrowane; niewydane; dwa ciężary, lewa/prawa noga prowadząca, kamera frontalna. |
| cw120 | Zwis martwy na siłę chwytu | 1 | Lokalnie zintegrowane; niewydane; identyczna kopia cw043, bez nowej generacji. |
| cw121 | Podciąganie na ręcznikach przewieszonych przez drążek | 2 | Lokalnie zintegrowane; niewydane; dwa ręczniki, neutralne chwyty i broda przy wysokości dłoni. |
| cw122 | Ściskanie końca hantla palcami | 1 | Lokalnie zintegrowane; niewydane; prawa dłoń szczypcowo na bokach górnej głowicy. |
| cw123 | Nawijanie linki z hantlem na drążek | 3 | Lokalnie zintegrowane; niewydane; trzy kolumny, stała rurka i przyrost zwojów. |
| cw124 | Uginanie nadgarstków z hantlami za plecami | 2 | Lokalnie zintegrowane; niewydane; dwa hantle, dłonie ku tyłowi, ruch nadgarstków. |
| cw125 | Przysiad z hantlem trzymanym oburącz przy klatce | 2 | Lokalnie zintegrowane; niewydane; jeden pionowy hantel oburącz, uda około poziomu. |
| cw126 | Przysiad z hantlami po bokach | 2 | Lokalnie zintegrowane; niewydane; dwa hantle przy bokach, długie ramiona i prześwit nad podłogą. |
| cw127 | Przysiad przedni z hantlami | 2 | Lokalnie zintegrowane; niewydane; dwa hantle w rack na barkach, łokcie do przodu i wysoko. |
| cw128 | Przysiad bułgarski z hantlami | 2 | Lokalnie zintegrowane; niewydane; prawa noga z przodu, lewy grzbiet stopy na ławce, bez skoku. |
| cw129 | Przysiad w wykroku z hantlami | 2 | Lokalnie zintegrowane; niewydane; prawa noga z przodu, stałe podpory na podłodze, ujęcie frontalne. |
| cw130 | Wykroki chodzone z hantlami | 3 | Lokalnie zintegrowane; niewydane; prawy wykrok → przejście lewej nogi → lewy wykrok, ujęcie frontalne. |
| cw131 | Zakroki z hantlami | 3 | Lokalnie zintegrowane; niewydane; lewa noga cofa się i wraca, prawa stopa kotwicząca, ujęcie frontalne. |
| cw132 | Wypady w bok z hantlami | 3 | Lokalnie zintegrowane; niewydane; krok prawą w bok → zejście na prawą nogę, lewa stopa pozostaje na miejscu. |
| cw133 | Zakroki skrzyżne z hantlami | 3 | Lokalnie zintegrowane; niewydane; lewa noga za prawą, prawa stopa kotwicząca. |
| cw134 | Wykroki chodzone z rotacją tułowia i hantlami | 4 | Lokalnie zintegrowane; niewydane; siatka 2×2, dwa hantle przed klatką, skręt ku nodze prowadzącej. |
| cw135 | Wchodzenie na ławkę z hantlami | 2 | Lokalnie zintegrowane; niewydane; pełna stopa na siedzisku, w finale obie stopy na ławce. |
| cw136 | Wchodzenie na ławkę z uniesieniem kolana i hantlami | 3 | Lokalnie zintegrowane; niewydane; trzy pionowe kolumny, prawa noga podporowa, lewe kolano drive. |
| cw137 | Przysiad na jednej nodze z drugą wyprostowaną w przód | 2 | Lokalnie zintegrowane; niewydane; prawa noga podporowa, lewa prosta i wolna, ramiona w przód. |
| cw138 | Przysiad na jednej nodze z drugą wyprostowaną w przód z podparciem | 2 | Lokalnie zintegrowane; niewydane; prawy pistol z asystą gumy z wysoką kotwą przed ciałem. |
| cw139 | Przysiad łyżwiarski | 2 | Lokalnie zintegrowane; niewydane; prawa noga podporowa, lewa zgięta z tyłu i wolna. |
| cw140 | Przysiad na palcach z odchyleniem tułowia w tył i podparciem | 2 | Lokalnie zintegrowane; niewydane; oba przodostopia na podłodze, pięty w górze, asysta dłonią na słupku. |
| cw141 | Siad przy ścianie | 1 | Lokalnie zintegrowane; niewydane; plecy podparte, kolana około 90°, ręce bez kontaktu z udami. |
| cw142 | Siad przy ścianie z hantlem | 1 | Lokalnie zintegrowane; niewydane; jeden pionowy hantel oburącz przy klatce. |
| cw143 | Przysiad kozacki z hantlem | 3 | Lokalnie zintegrowane; niewydane; stały szeroki rozstaw, prawa → środek → lewa, jeden hantel goblet. |
| cw144 | Przysiad ze skokiem | 3 | Lokalnie zintegrowane; niewydane; trzy pionowe kolumny, przysiad → lot → ugięte lądowanie. |
| cw145 | Przysiad ze skokiem i obrotem o 180° | 3 | Lokalnie zintegrowane; niewydane; trzy kolumny, zmiana kierunku w locie i ugięte lądowanie. |
| cw146 | Wyskoki na skrzynię lub ławkę | 4 | Lokalnie zintegrowane; niewydane; siatka 2×2, przysiad → lot → ugięte lądowanie na ławce → wyprost. |
| cw147 | Skok w dal z miejsca | 3 | Lokalnie zintegrowane; niewydane; trzy poziome pasy, postęp względem stałych szwów podłogi. |
| cw148 | Rumuński martwy ciąg z hantlami (na nogi) | 2 | Lokalnie zintegrowane; niewydane; identyczna kopia cw063, bez nowej generacji. |
| cw149 | Rumuński martwy ciąg z hantlami na jednej nodze | 2 | Lokalnie zintegrowane; niewydane; prawa noga podporowa, lewa wolna w tył, dwa hantle. |
| cw150 | Martwy ciąg z hantlami na prostych nogach | 2 | Lokalnie zintegrowane; niewydane; głęboki hinge, prawie proste niezablokowane kolana, hantle blisko kostek/podłoża. |
| cw151 | Martwy ciąg z hantlem w szerokim rozkroku | 2 | Lokalnie zintegrowane; niewydane; jeden pionowy hantel oburącz za górną głowicę, długie ramiona. |
| cw152 | Skłony tułowia z gumą i cofnięciem bioder | 2 | Lokalnie zintegrowane; niewydane; zamknięta guma pod obiema stopami i na górnych plecach u nasady karku. |
| cw153 | Opad tułowia w klęku z zablokowanymi stopami i pomocą rąk | 3 | Lokalnie zintegrowane; niewydane; kostki pod niską poprzeczką ławki, opad z kolan i końcowa pomoc dłoni. |
| cw154 | Most biodrowy | 2 | Lokalnie zintegrowane; niewydane; głowa, barki i stopy podparte na podłodze. |
| cw155 | Most biodrowy z hantlem | 2 | Lokalnie zintegrowane; niewydane; jeden hantel na biodrach stabilizowany obiema dłońmi. |
| cw156 | Hip thrust z hantlem | 2 | Lokalnie zintegrowane; niewydane; górne plecy na ławce, hantel na biodrach, kontrolowana głowa i szyja. |
| cw157 | Hip thrust jednonóż | 2 | Lokalnie zintegrowane; niewydane; prawa podpora, lewa noga w powietrzu. |
| cw158 | Unoszenie bioder w leżeniu ze złączonymi podeszwami stóp | 2 | Lokalnie zintegrowane; niewydane; frog pump. |
| cw159 | Unoszenie ugiętej nogi w tył w klęku podpartym | 2 | Lokalnie zintegrowane; niewydane. |
| cw160 | Odwodzenie ugiętej nogi w bok w klęku podpartym z gumą | 2 | Lokalnie zintegrowane; niewydane; guma nad kolanami. |
| cw161 | Rozwieranie kolan w leżeniu bokiem z gumą | 2 | Lokalnie zintegrowane; niewydane; stopy razem. |
| cw162 | Chód w półprzysiadzie z gumą | 3 | Lokalnie zintegrowane; niewydane; cykl kroku w bok. |
| cw163 | Wspięcia na palce w staniu | 2 | Lokalnie zintegrowane; niewydane. |
| cw164 | Wspięcia na palce na jednej nodze z hantlem | 2 | Lokalnie zintegrowane; niewydane; podpora i hantel po prawej. |
| cw165 | Wspięcia na palce na krawędzi ławki z hantlami | 2 | Lokalnie zintegrowane; niewydane; pięty poza krawędzią. |
| cw166 | Wspięcia na palce w siadzie z hantlami | 2 | Lokalnie zintegrowane; niewydane. |
| cw167 | Wspięcia na palce w opadzie tułowia | 2 | Lokalnie zintegrowane; niewydane; dłonie na ławce. |
| cw168 | Unoszenie przodostopia w oparciu plecami o ścianę | 2 | Lokalnie zintegrowane; niewydane; pięty na podłodze. |
| cw169 | Deska na przedramionach | 1 | Lokalnie zintegrowane; niewydane. |
| cw170 | Deska na prostych ramionach | 1 | Lokalnie zintegrowane; niewydane. |
| cw171 | Deska bokiem | 1 | Lokalnie zintegrowane; niewydane. |
| cw172 | Deska bokiem z opuszczaniem i unoszeniem bioder | 2 | Lokalnie zintegrowane; niewydane. |
| cw173 | Deska bokiem z unoszeniem nogi | 2 | Lokalnie zintegrowane; niewydane. |
| cw174 | Deska z dotykaniem przeciwnego barku | 2 | Lokalnie zintegrowane; niewydane. |
| cw175 | Przejścia z deski na przedramionach do podporu na dłoniach | 3 | Lokalnie zintegrowane; niewydane. |
| cw176 | Wiosłowanie hantlami w podporze przodem (stabilizacja tułowia) | 2 | Lokalnie zintegrowane; niewydane. |
| cw177 | Deska z unoszeniem nogi | 2 | Lokalnie zintegrowane; niewydane. |
| cw178 | Deska kopenhaska z nogą na ławce | 1 | Lokalnie zintegrowane; niewydane; podparcie przy kolanie. |
| cw179 | Martwy robak | 2 | Lokalnie zintegrowane; niewydane. |
| cw180 | Martwy robak z hantlem | 2 | Lokalnie zintegrowane; niewydane. |
| cw181 | Prostowanie przeciwnej ręki i nogi w klęku podpartym | 2 | Lokalnie zintegrowane; niewydane. |
| cw182 | Prostowanie przeciwnej ręki i nogi z przyciąganiem łokcia do kolana w klęku podpartym | 1 | Lokalnie zintegrowane; niewydane. |
| cw183 | Utrzymanie pozycji łódki w leżeniu na plecach | 1 | Lokalnie zintegrowane; niewydane. |
| cw184 | Kołysanie w pozycji łódki na plecach | 2 | Lokalnie zintegrowane; niewydane. |
| cw185 | Utrzymanie pozycji łódki w leżeniu na brzuchu | 1 | Lokalnie zintegrowane; niewydane. |
| cw186 | Pełne brzuszki | 2 | Lokalnie zintegrowane; niewydane. |
| cw187 | Pełne brzuszki z hantlem na klatce piersiowej | 2 | Lokalnie zintegrowane; niewydane. |
| cw188 | Spięcia brzucha | 2 | Lokalnie zintegrowane; niewydane. |
| cw189 | Odwrotne spięcia brzucha | 2 | Lokalnie zintegrowane; niewydane. |
| cw190 | Scyzoryki | 2 | Lokalnie zintegrowane; niewydane. |
| cw191 | Sięganie dłońmi do uniesionych stóp w leżeniu | 2 | Lokalnie zintegrowane; niewydane. |
| cw192 | Spięcia brzucha ze skrętem i naprzemienną pracą nóg | 1 | Lokalnie zintegrowane; niewydane. |
| cw193 | Skręty tułowia w siadzie bez obciążenia | 3 | Lokalnie zintegrowane; niewydane. |
| cw194 | Skręty tułowia w siadzie z hantlem | 2 | Lokalnie zintegrowane; niewydane. |
| cw195 | Rąbanie drewna z hantlem po przekątnej | 2 | Lokalnie zintegrowane; niewydane. |
| cw196 | Wyciskanie Pallofa z gumą | 2 | Lokalnie zintegrowane; niewydane. |
| cw197 | Wyciskanie Pallofa z gumą i rotacją tułowia | 2 | Lokalnie zintegrowane; niewydane. |
| cw198 | Skłony boczne z hantlem w staniu | 2 | Lokalnie zintegrowane; niewydane. |
| cw199 | Unoszenie kolan w zwisie na drążku | 2 | Lokalnie zintegrowane; niewydane. |
| cw200 | Unoszenie prostych nóg w zwisie na drążku | 2 | Lokalnie zintegrowane; niewydane. |
| cw201 | Przenoszenie uniesionych nóg na boki w zwisie na drążku | 3 | Lokalnie zintegrowane; niewydane. |
| cw202 | Unoszenie stóp do drążka w zwisie | 2 | Lokalnie zintegrowane; niewydane. |
| cw203 | Utrzymanie podporu z prostymi nogami uniesionymi do poziomu | 1 | Lokalnie zintegrowane; niewydane; niskie poręcze. |
| cw204 | Unoszenie i opuszczanie prostego ciała w oparciu na barkach na ławce | 2 | Lokalnie zintegrowane; niewydane. |
| cw205 | Przetaczanie hantli sześciokątnych w przód w klęku | 2 | Lokalnie zintegrowane; niewydane. |
| cw206 | Chód farmera z hantlami (stabilizacja tułowia) | 2 | Lokalnie zintegrowane; niewydane; reuse cw119. |
| cw207 | Chód z hantlem w jednej ręce | 1 | Lokalnie zintegrowane; niewydane. |
| cw208 | Bieg w podporze (na brzuch) | 2 | Lokalnie zintegrowane; niewydane. |
| cw209 | Burpee klasyczny | 4 | Lokalnie zintegrowane; niewydane. |
| cw210 | Burpee z pompką | 4 | Lokalnie zintegrowane; niewydane. |
| cw211 | Burpee z podskokiem | 4 | Lokalnie zintegrowane; niewydane; reuse cw209. |
| cw212 | Burpee bez pompki i wyskoku | 4 | Lokalnie zintegrowane; niewydane. |
| cw213 | Pajacyki | 2 | Lokalnie zintegrowane; niewydane. |
| cw214 | Wyskoki z przysiadu do pozycji gwiazdy | 3 | Lokalnie zintegrowane; niewydane. |
| cw215 | Bieg w miejscu z wysokim unoszeniem kolan | 1 | Lokalnie zintegrowane; niewydane. |
| cw216 | Bieg w miejscu z uderzaniem piętami o pośladki | 1 | Lokalnie zintegrowane; niewydane. |
| cw217 | Bieg w podporze | 2 | Lokalnie zintegrowane; niewydane; reuse cw208. |
| cw218 | Bieg w podporze z kolanami do przeciwnych łokci | 2 | Lokalnie zintegrowane; niewydane. |
| cw219 | Wyrzuty nóg w tył do podporu z przysiadu | 4 | Lokalnie zintegrowane; niewydane; reuse cw212. |
| cw220 | Skoki łyżwiarskie | 3 | Lokalnie zintegrowane; niewydane. |
| cw221 | Wyskoki z przyciąganiem kolan do klatki piersiowej | 3 | Lokalnie zintegrowane; niewydane. |
| cw222 | Skok w dal z miejsca z powrotem truchtem | 4 | Lokalnie zintegrowane; niewydane. |
| cw223 | Chód niedźwiedzia | 1 | Lokalnie zintegrowane; niewydane. |
| cw224 | Chód kraba | 1 | Lokalnie zintegrowane; niewydane. |
| cw225 | Skakanka — podskoki obunóż | 2 | Lokalnie zintegrowane; niewydane. |
| cw226 | Skakanka — krok bokserski | 1 | Lokalnie zintegrowane; niewydane. |
| cw227 | Skakanka — wysokie unoszenie kolan | 1 | Lokalnie zintegrowane; niewydane. |
| cw228 | Skakanka — podskoki na jednej nodze | 1 | Lokalnie zintegrowane; niewydane. |
| cw229 | Skakanka — podskoki na boki | 2 | Lokalnie zintegrowane; niewydane. |
| cw230 | Skakanka — podskoki w przód i w tył | 2 | Lokalnie zintegrowane; niewydane. |
| cw231 | Skakanka — podwójny obrót linki w podskoku | 1 | Lokalnie zintegrowane; niewydane; liczba obrotów w opisie. |
| cw232 | Skakanka — podskoki ze skrzyżowaniem ramion | 1 | Lokalnie zintegrowane; niewydane. |
| cw233 | Skakanka — podwójny obrót linki ze skrzyżowaniem ramion | 1 | Lokalnie zintegrowane; niewydane; liczba obrotów w opisie. |
| cw234 | Bieżnia — spokojny bieg w drugiej strefie tętna | 1 | Lokalnie zintegrowane; niewydane. |
| cw235 | Bieżnia — marsz 12-3-30 (nachylenie 12%, 3 mile/h, 30 min) | 1 | Lokalnie zintegrowane; niewydane. |
| cw236 | Bieżnia — interwały: 30 sekund sprintu i 90 sekund truchtu | 2 | Lokalnie zintegrowane; niewydane. |
| cw237 | Bieżnia — sprinty pod górę (nachylenie 5–7%) | 1 | Lokalnie zintegrowane; niewydane. |
| cw238 | Bieżnia — piramida tempa | 2 | Lokalnie zintegrowane; niewydane; reuse cw236. |
| cw239 | Bieżnia — bieg tempowy | 1 | Lokalnie zintegrowane; niewydane; reuse cw234. |
| cw240 | Bieżnia — długi, spokojny bieg | 1 | Lokalnie zintegrowane; niewydane; reuse cw234. |
| cw241 | Bieżnia — spacer regeneracyjny | 1 | Lokalnie zintegrowane; niewydane. |
| cw242 | Krążenia ramion | 3 | Lokalnie zintegrowane; niewydane. |
| cw243 | Wymachy nogi w przód i w tył | 2 | Lokalnie zintegrowane; niewydane. |
| cw244 | Wymachy nogi na boki | 2 | Lokalnie zintegrowane; niewydane. |
| cw245 | Krążenia bioder | 3 | Lokalnie zintegrowane; niewydane. |
| cw246 | Wykroki chodzone z rotacją tułowia bez obciążenia | 1 | Lokalnie zintegrowane; niewydane. |
| cw247 | Gąsienica | 3 | Lokalnie zintegrowane; niewydane. |
| cw248 | Rozciąganie w wykroku z rotacją tułowia | 1 | Lokalnie zintegrowane; niewydane. |
| cw249 | Przyciąganie stopy do zewnętrznej strony dłoni w podporze | 2 | Lokalnie zintegrowane; niewydane. |
| cw250 | Koci grzbiet i wygięcie pleców w klęku podpartym | 2 | Lokalnie zintegrowane; niewydane. |
| cw251 | Pozycja kobry | 2 | Wydane w 1.4.9+16. |
| cw252 | Pozycja dziecka | 2 | Wydane w 1.4.9+16. |
| cw253 | Pies z głową w dół | 2 | Wydane w 1.4.9+16. |
| cw254 | Pies z głową w górę | 2 | Wydane w 1.5.1+18. |
| cw255 | Pozycja gołębia | 2 | Wydane w 1.5.1+18. |
| cw256 | Rozciąganie bioder 90/90 | 2 | Wydane w 1.3.1+6; referencja stylu serii. |
| cw257 | Rozciąganie motylkowe | 1 | Wydane w 1.4.6+13. |
| cw258 | Rozciąganie w pozycji żaby | 2 | Wydane w 1.5.1+18. |
| cw259 | Rozciąganie w przysiadzie kozackim | 3 | Wydane w 1.5.1+18. |
| cw260 | Rozciąganie zginaczy biodra w klęku ze stopą na ławce | 2 | Wydane w 1.5.1+18. |
| cw261 | Rozciąganie mięśnia czworogłowego uda w staniu | 1 | Wydane w 1.4.4+11; pomarańcz oznacza czworogłowy. Nie oznaczono zasłoniętego stabilizatora biodra. |
| cw262 | Rozciąganie tylnej części uda w staniu z nogą na podwyższeniu | 2 | Wydane w 1.4.9+16. |
| cw263 | Skłon w przód w siadzie prostym | 2 | Wydane w 1.5.1+18. |
| cw264 | Rozciąganie łydki przy ścianie | 2 | Wydane w 1.4.6+13. |
| cw265 | Rozciąganie klatki piersiowej w futrynie | 2 | Wydane w 1.4.3+10; pomarańcz oznacza prawy piersiowy większy. |
| cw266 | Przekładanie ręki pod tułowiem w klęku podpartym | 3 | Wydane w 1.5.1+18. |
| cw267 | Wyprost odcinka piersiowego kręgosłupa na ławce | 3 | Wydane w 1.5.1+18; dłonie splecione za głową. |
| cw268 | Koci grzbiet i wygięcie pleców w siadzie | 2 | Wydane w 1.8.0+21. |
| cw269 | Krążenia szyi | 2 | Wydane w 1.8.0+21. |
| cw270 | Cofanie brody | 2 | Wydane w 1.8.0+21. |
| cw271 | Krążenia barków | 2 | Wydane w 1.8.0+21. |
| cw272 | Krążenia nadgarstków | 2 | Wydane w 1.8.0+21. |
| cw273 | Rozciąganie nadgarstków ze złożonymi dłońmi | 2 | Wydane w 1.5.1+18. |
| cw274 | Rozciąganie nadgarstków w klęku podpartym z palcami ku kolanom | 2 | Wydane w 1.5.1+18. |
| cw275 | Krążenia kostek | 2 | Wydane w 1.8.0+21. |
| cw276 | Zgięcie grzbietowe stawu skokowego z kolanem do ściany | 2 | Wydane w 1.5.1+18. |
| cw277 | Utrzymanie głębokiego przysiadu | 2 | Wydane w 1.5.1+18. |
| cw278 | Przenoszenie gumy nad głową | 3 | Wydane w 1.4.7+14; świadoma zmiana kamery z front 3/4 na rear 3/4, z gumą za biodrami w ostatnim panelu. |
| cw279 | Rozciąganie przedniej i tylnej części barków z gumą | 2 | Wydane w 1.5.1+18; kotwa jest na wysokości barku przed lub za ciałem. |
| cw280 | Rozciąganie mięśnia czworogłowego uda w staniu z rotacją tułowia | 2 | Wydane w 1.5.1+18. |
| cw281 | Powitanie słońca A | 4 | Wydane w 1.5.1+18. |
| cw282 | Tai Chi — otwarcie klatki piersiowej w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw283 | Tai Chi — dłonie jak chmury w siadzie na krześle | 3 | Wydane w 1.6.0+19. |
| cw284 | Tai Chi — chwytanie wróblego ogona w siadzie na krześle | 4 | Wydane w 1.6.0+19. |
| cw285 | Tai Chi — falowanie dłońmi jak chmurami w siadzie na krześle | 3 | Wydane w 1.6.0+19. |
| cw286 | Tai Chi — rozdzielanie grzywy dzikiego konia w siadzie na krześle | 3 | Wydane w 1.6.0+19. |
| cw287 | Tai Chi — złoty kogut w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw288 | Tai Chi — omiatanie kolana w siadzie na krześle | 3 | Wydane w 1.6.0+19. |
| cw289 | Tai Chi — pojedynczy bicz w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw290 | Skręt tułowia w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw291 | Koci grzbiet i wygięcie pleców w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw292 | Skłon w przód w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw293 | Pozycja gołębia w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw294 | Skłon boczny w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw295 | Boczne rozciąganie szyi w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw296 | Krążenia barków w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw297 | Ramiona orła w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw298 | Krążenia kostek w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw299 | Krążenia bioder w siadzie na krześle | 2 | Wydane w 1.6.0+19. |
| cw300 | Oddech kwadratowy 4–4–4–4 | 1 | Wydane w 1.6.0+19. |
| cw301 | Oddech przeponowy | 1 | Wydane w 1.6.0+19. |
| cw302 | Przysiad z dynamicznym wyciśnięciem hantli nad głowę | 3 | Wydane w 1.6.0+19. |
| cw303 | Pompka, wiosłowanie w podporze i przysiad z wyciskaniem hantli | 4 | Wydane w 1.6.0+19. |
| cw304 | Burpee z rwaniem dwóch hantli nad głowę | 4 | Wydane w 1.6.0+19. |
| cw305 | Zarzut hantli z wyciskaniem nad głowę | 3 | Wydane w 1.6.0+19. |
| cw306 | Rwanie hantla jednorącz | 3 | Wydane w 1.6.0+19. |
| cw307 | Wymach hantlem oburącz | 2 | Wydane w 1.6.0+19. |
| cw308 | Wstawanie tureckie z hantlem | 4 | Wydane w 1.6.0+19. |
| cw309 | Przysiad, uginanie przedramion i wyciskanie hantli nad głowę | 3 | Wydane w 1.6.0+19. |
| cw310 | Wiosłowanie hantlami w podporze z pompką | 3 | Wydane w 1.6.0+19. |
| cw311 | Wykrok z uginaniem przedramion z hantlami | 2 | Wydane w 1.6.0+19. |
| cw312 | Rumuński martwy ciąg z wiosłowaniem hantlami | 3 | Wydane w 1.6.0+19. |
| cw313 | Chód niedźwiedzia z pompkami | 4 | Wydane w 1.6.0+19. |
| cw314 | Przysiad z wyciskaniem hantli nad głowę | 3 | Wydane w 1.7.0+20. |
| cw315 | Burpee z podciąganiem na drążku | 4 | Wydane w 1.7.0+20. |
| cw316 | Chód farmera naprzemiennie z chodem z hantlem w jednej ręce | 3 | Wydane w 1.7.0+20. |
| cw317 | Martwy ciąg z sandbagiem za uchwyty | 2 | Lokalnie zintegrowane; niewydane. |
| cw318 | Przysiad z sandbagiem trzymanym z przodu | 2 | Lokalnie zintegrowane; niewydane. |
| cw319 | Przysiad z sandbagiem objętym pionowo | 2 | Lokalnie zintegrowane; niewydane. |
| cw320 | Przysiad z sandbagiem na jednym barku | 2 | Lokalnie zintegrowane; niewydane. |
| cw321 | Skłon biodrowy z sandbagiem przed klatką | 2 | Lokalnie zintegrowane; niewydane. |
| cw322 | Wiosłowanie sandbagiem w opadzie | 2 | Lokalnie zintegrowane; niewydane. |
| cw323 | Dynamiczne podciągnięcie sandbaga do klatki | 3 | Lokalnie zintegrowane; niewydane. |
| cw324 | Zarzut sandbaga na przedramiona | 3 | Lokalnie zintegrowane; niewydane. |
| cw325 | Wyciskanie sandbaga nad głowę | 2 | Lokalnie zintegrowane; niewydane. |
| cw326 | Zarzut i wyciskanie sandbaga | 3 | Lokalnie zintegrowane; niewydane. |
| cw327 | Zakrok z przeniesieniem sandbaga przy przedniej nodze | 1 | Lokalnie zintegrowane; niewydane. |
| cw328 | Przenoszenie sandbaga ruchem szuflowania | 2 | Lokalnie zintegrowane; niewydane. |
| cw329 | Obwodzenie sandbaga wokół tułowia w klęku | 3 | Lokalnie zintegrowane; niewydane. |
| cw330 | Przeciąganie sandbaga pod tułowiem w desce | 1 | Lokalnie zintegrowane; niewydane. |
| cw331 | Most biodrowy z napięciem sandbaga nad klatką | 2 | Lokalnie zintegrowane; niewydane. |
| cw332 | Wyciskanie sandbaga łukiem w półklęku | 3 | Lokalnie zintegrowane; niewydane. |
| cw333 | Przetaczanie kółka w przód z kolan | 2 | Lokalnie zintegrowane; niewydane. |
| cw334 | Przetaczanie kółka po skosie z kolan | 2 | Lokalnie zintegrowane; niewydane. |
| cw335 | Deska z dłońmi na kółku | 1 | Lokalnie zintegrowane; niewydane. |
| cw336 | Wojownik I | 1 | Lokalnie zintegrowane; niewydane. |
| cw337 | Wojownik II | 1 | Lokalnie zintegrowane; niewydane. |
| cw338 | Wojownik III | 1 | Lokalnie zintegrowane; niewydane. |
| cw339 | Pozycja trójkąta | 1 | Lokalnie zintegrowane; niewydane. |
| cw340 | Pozycja rozciągniętego kąta bocznego | 1 | Lokalnie zintegrowane; niewydane. |
| cw341 | Pozycja półksiężyca w staniu | 1 | Lokalnie zintegrowane; niewydane. |
| cw342 | Pozycja drzewa | 1 | Lokalnie zintegrowane; niewydane. |
| cw343 | Pozycja orła w staniu | 1 | Lokalnie zintegrowane; niewydane. |
| cw344 | Pozycja krzesła bez podparcia | 1 | Lokalnie zintegrowane; niewydane. |
| cw345 | Pozycja wielbłąda | 1 | Lokalnie zintegrowane; niewydane. |
| cw346 | Pozycja łuku | 1 | Lokalnie zintegrowane; niewydane. |
| cw347 | Pozycja łodzi w siadzie | 1 | Lokalnie zintegrowane; niewydane. |
| cw348 | Skręt mędrca w siadzie na podłodze | 1 | Lokalnie zintegrowane; niewydane. |
| cw349 | Pozycja bramy w klęku | 1 | Lokalnie zintegrowane; niewydane. |
| cw350 | Skłon w przód w szerokim rozkroku | 1 | Lokalnie zintegrowane; niewydane. |
| cw351 | Pozycja szczęśliwego dziecka | 1 | Lokalnie zintegrowane; niewydane. |
| cw352 | Przemieszczanie bokiem w przysiadzie na rękach | 3 | Lokalnie zintegrowane; niewydane. |
| cw353 | Przemieszczanie żabki z podparciem rąk | 3 | Lokalnie zintegrowane; niewydane. |
| cw354 | Przysiad krewetki z chwytem tylnej stopy | 2 | Lokalnie zintegrowane; niewydane. |
| cw355 | Przerzut bokiem na obie ręce | 1 | Lokalnie zintegrowane; niewydane. |
| cw356 | Most trójpunktowy z sięganiem | 1 | Lokalnie zintegrowane; niewydane. |
| cw357 | Podpór żaby na ugiętych ramionach | 1 | Lokalnie zintegrowane; niewydane. |
| cw358 | Unoszenie prostej nogi w siadzie z kompresją | 2 | Lokalnie zintegrowane; niewydane. |
| cw359 | Utrzymanie podporu tyłem z ugiętymi nogami | 1 | Lokalnie zintegrowane; niewydane. |
| cw360 | Tai chi — zbieranie wiśni w siadzie | 2 | Lokalnie zintegrowane; niewydane. |
| cw361 | Tai chi — wiosłowanie łodzią w siadzie | 2 | Lokalnie zintegrowane; niewydane. |
| cw362 | Tai chi — żółw pływający w oceanie w siadzie | 3 | Lokalnie zintegrowane; niewydane. |
| cw363 | Tai chi — otwieranie drzwi podeszwą w siadzie | 2 | Lokalnie zintegrowane; niewydane. |

`assets/exercises/`, `illustratedExerciseIds` i testy ilustracji są wspólnym
rejestrem tych trzech zasobów. Każdy nowy plik WebP wymaga wpisu w rejestrze,
dekodowania 512×512 oraz kontroli braku osieroconych plików.

## Pierwsza partia

Zakres pierwszej partii obejmuje `cw251–cw267`, `cw273`, `cw274` i
`cw276–cw281`. Wszystkie 25 zasobów są wydane. Dodatkowe `cw279` używa kotwy
gumy na wysokości barku i obejmuje wariant przednią oraz tylną stronę barku.

## Druga partia

Zakres drugiej partii obejmuje `cw282–cw313`. Wszystkie 32 zasoby są wydane w
wersji 1.6.0+19.

## Trzecia partia

Zakres trzeciej partii obejmuje `cw314–cw316`. Wszystkie trzy zasoby są wydane
w wersji 1.7.0+20.

## Czwarta partia

Zakres czwartej partii obejmuje `cw268–cw272` oraz `cw275`. Wszystkie sześć
zatwierdzonych zasobów WebP 512×512 ma po dwa kadry i jest wydanych w wersji
1.8.0+21. Wdrożono wyłącznie web; publiczną wersję, nagłówki i zgodność bajtów
wszystkich sześciu ilustracji z lokalnymi assetami zweryfikowano
2026-10-12 o 17:45:16 UTC. API, PostgreSQL i push-sender zachowały identyfikatory
kontenerów oraz czasy uruchomienia.

Rollback: `fit-web:rollback-1.7.0-20-20261012T174440Z`, obraz
`sha256:d97bfc12b01a1068e67a422ba3d132321a421333eb23af0ef5a752c1ee21c3d6`.

## Piąta partia

Zakres piątej partii obejmuje `cw001–cw006`. Wszystkie sześć zatwierdzonych
WebP 512×512 ma po dwa kadry i jest wydanych w `1.9.0+22`. Weryfikacja
Dockerowa obejmuje analizę i pełny zestaw testów.

## Szósta partia

Zakres szóstej partii obejmuje `cw007–cw012`. Wszystkie sześć zatwierdzonych
WebP 512×512 jest wydanych w `1.9.0+22`. `cw007` i `cw011` mają po trzy kadry
w poziomych pasach ułożonych pionowo, od góry do dołu; pozostałe ilustracje
mają po dwa kadry. Weryfikacja
Dockerowa obejmuje analizę i pełny zestaw testów: 366 testów przeszło,
analiza wykazała 0 problemów.

## Wspólne wydanie Partii 05 i 06 — 1.9.0+22

Wdrożono wyłącznie web z commitu `c1453441a0b8b98800fb3ea5363a52549964ed2d`.
Kontener web uruchomiono 2026-10-12 o 20:25:14 UTC; weryfikację zakończono
o 20:25:48 UTC. Obraz runtime:
`sha256:bf346275aaa74a2fad4f55a5f4b776298b73d616649ea8891ae29d0e9dc5e62e`.

Przed zmianą tagu produkcyjnego wykonano `fit-backup.service`:
`Result=success`, `ExecMainStatus=0`. Backup `20261012T202511791611Z`,
SHA-256 dumpa:
`82217dc0c969f860b4d23b9b9b3474f2461f11b13f3284a47ed940fdded52424`.

Rollback: `fit-web:rollback-1.8.0-21-20261012T202511Z`, obraz
`sha256:6dc5ac2d652c96ba61f436b9bc32ba03bbc7fbce66ddba5d663eeff96fa415e7`.

Compose zweryfikowano przez `config --quiet` z nakładkami push i mentor.
Publiczne `version.json` potwierdza `1.9.0`, build `22`, a `/api/health`
zwraca `{"status":"ok"}`. Manifest obejmuje wszystkie 78 ilustracji;
każda zwraca HTTP 200 i `image/webp`, z SHA-256 zgodnym z lokalnym assetem.
Kontrola obejmuje również wszystkie 18 assetów Partii 04–06.
`sqlite3.wasm` i `drift_worker.dart.js` są niepuste, zgodne bajtowo z lokalnymi
plikami, zwracają HTTP 200, właściwy Content-Type oraz `Cache-Control: no-cache`.
Kontener web jest zdrowy. API, PostgreSQL i push-sender zachowały identyczne
identyfikatory kontenerów, obrazy i czasy uruchomienia; nie wykonywano migracji.

## Siódma partia

Zakres siódmej partii obejmuje `cw013–cw018`. Wszystkie sześć zatwierdzonych
WebP 512×512 ma po dwa kadry i jest lokalnie zintegrowanych. `cw015` pokazuje
zatwierdzony wariant w staniu z dwoma odrębnymi hantlami, które pozostają
dociśnięte do siebie w obu kadrach; każdy ma osobny uchwyt.
Weryfikacja Dockerowa obejmuje analizę i pełny zestaw testów: 366 testów
przeszło, analiza wykazała 0 problemów. Pakiet nie jest jeszcze wydany;
wersja produkcyjna pozostaje `1.9.0+22`.

## Ósma partia

Zakres ósmej partii obejmuje `cw019–cw024`. Wszystkie sześć zatwierdzonych
WebP 512×512 ma po dwa kadry i jest lokalnie zintegrowanych. `cw019` pokazuje
zatwierdzony wariant leżenia wzdłuż ławki z jednym hantlem; `cw024` pokazuje
zatwierdzony wariant w staniu z wysoką kotwą gumy za ciałem.
Zmiany kamery w `cw022` i `cw024` zostały zatwierdzone. Przebieg gum i chwyty
sprawdzono w docelowej rozdzielczości 512×512.
Weryfikacja Dockerowa obejmuje analizę i pełny zestaw testów: 366 testów
przeszło, analiza wykazała 0 problemów. Pakiet nie jest jeszcze wydany;
wersja produkcyjna pozostaje `1.9.0+22`.

## Dziewiąta partia

Zakres dziewiątej partii obejmuje `cw025–cw030`: sześć zatwierdzonych
zasobów WebP 512×512, lokalnie zintegrowanych i niewydanych. Układ kadrów
wynosi odpowiednio 2/2/2/2/2/3.

`cw025` pokazuje podparcie dłońmi na jednej ławce i piętami na drugiej;
w górnym kadrze tułów pozostaje blisko pozycji neutralnej, a w dolnym
pochyla się w przód. W `cw026` palce dłoni kierują się na zewnątrz.
`cw027` pokazuje widok frontalny i podparcie na opuszkach pięciu palców
każdej dłoni. `cw028` pokazuje pompki łucznika z nogami na ławce.
W `cw029` istniejące tempo i pauza 3 sekundy pozostają w opisie katalogowym;
statyczna ilustracja nie koduje czasu.

`cw030` ma trzy poziome pasy pełnej szerokości, ułożone pionowo od góry
do dołu. Widok frontalny, orientacja ciała i szew podłogi pozostają spójne
między kadrami: niska pozycja po lewej, środek z dłońmi w powietrzu,
lądowanie po prawej na ugiętych ramionach. Częściowe zasłonięcie nóg jest
naturalne; nie obowiązuje wymóg identycznych współrzędnych punktu obrotu.

Weryfikacja Dockerowa obejmuje analizę i pełny zestaw testów: 366 testów
przeszło, analiza wykazała 0 problemów. Pakiet nie jest jeszcze wydany;
wersja produkcyjna pozostaje `1.9.0+22`.

## Dziesiąta partia

Zakres dziesiątej partii obejmuje `cw031–cw036`. Wszystkie sześć zasobów
WebP 512×512 ma po dwa kadry: pełny zwis i górną pozycję. Są lokalnie
zintegrowane i niewydane. Sprawdzono orientację i rozstaw obu chwytów,
mocowanie sprzętu oraz pozycję brody względem drążka w docelowym rozmiarze.
`cw033` używa dwóch równoległych uchwytów; `cw034` wąskiego nachwytu,
`cw035` stałego zestawu prawa dłoń nachwytem/lewa podchwytem, a `cw036`
nachwytu na szerokość barków. Czas pauzy opisuje katalog, nie timer w obrazie.

Po osiągnięciu limitu subagentów generację i kontrolę obrazów dokończono
bezpośrednio w sesji. Odczytano źródła i podglądy 512×512 przed kolejnymi
żądaniami; końcowe źródła to trial-02 dla `cw031–cw034` i `cw036` oraz
trial-01 dla `cw035`. Wykonano 11 pojedynczych żądań, w tym 5 korekt
zgodności wysokości sprzętu lub pełnej pozycji górnej. Suma szacunków
`upper_bound_no_cache` z zakończonych żądań wynosi 0,251707 USD;
nie jest to potwierdzone rozliczenie dostawcy.

Pełna weryfikacja Dockerowa `fit-web:batch-10-verified` zakończyła się
powodzeniem: 366 testów zaliczonych, 0 problemów analizy. Rejestr,
oczekiwania testu i pliki obejmują 102 ID; fallback wskazuje `cw037`.
Wersja produkcyjna pozostaje `1.9.0+22`.

## Jedenasta partia

Zakres jedenastej partii obejmuje `cw037–cw042`. Wszystkie sześć zasobów
WebP 512×512 jest lokalnie zintegrowanych i niewydanych. Układ kadrów:
2/2/3/2/2/3. `cw039` i `cw042` pokazują opuszczanie w trzech pionowych
kolumnach od lewej do prawej: pozycja górna, środek zjazdu, pozycja dolna.
Czasy opuszczania pozostają w opisie katalogowym, bez timera w obrazie.

Sprawdzono utrzymanie L w `cw037`, prostą rękę pomocniczą łucznika,
jedną podporową dłoń `cw039`, kontakt górnej klatki z drążkiem `cw040`
oraz wyższą pozycję ciała w `cw041`, z ugiętymi ramionami i bez przejścia
do podporu muscle-up. Kontrolowano niezmienną wysokość sprzętu w kadrach.
Generację i przegląd źródeł, podglądów 512×512 oraz finalnych WebP wykonano
bezpośrednio w sesji, bez dodatkowych niezależnych przeglądów subagentów.

Zaakceptowane źródła: trial-02 dla `cw037` i `cw039`, trial-03 dla `cw038`
i `cw040`, trial-05 dla `cw041`, trial-01 dla `cw042`. W `cw041` po
nieskutecznym wspólnym wyrównywaniu sprzętu zastosowano ograniczoną zmianę
podejścia: wyrównanie wyłącznie zwisu po lewej, a następnie punktową naprawę
utraconej wysokości górnego kadru. Wykonano 16 pojedynczych żądań, w tym
10 korekt. Suma szacunków `upper_bound_no_cache` wynosi 0,362007 USD;
nie jest to potwierdzone rozliczenie dostawcy.

Pełna weryfikacja Dockerowa `fit-web:batch-11-verified` zakończyła się
powodzeniem: 366 testów zaliczonych, 0 problemów analizy. Rejestr,
oczekiwania testu i pliki obejmują 108 ID; fallback wskazuje `cw043`.
Wersja produkcyjna pozostaje `1.9.0+22`.

## Dwunasta partia

Zakres dwunastej partii obejmuje `cw043–cw048`. Wszystkie sześć zasobów
WebP 512×512 jest lokalnie zintegrowanych i niewydanych. Układ kadrów:
1/1/2/2/2/2. Statyczne zwisy mają po jednym kadrze; czas utrzymania
pozostaje w katalogu, bez timera lub fikcyjnej dodatkowej fazy.

Kontrolowano naturalne ustawienie barków w zwisie martwym, aktywne
ściągnięcie łopatek oraz nieugięte łokcie w podciąganiu łopatkowym.
W wiosłowaniach sprawdzono liczbę hantli, chwyty, kierunek łokci i stałe
podparcia: lewą dłoń i kolano na ławce w `cw046`, zawias biodrowy w `cw047`
oraz kontakt klatki z oparciem ławki skośnej w `cw048`.

Generację i przegląd źródeł, podglądów 512×512 oraz końcowych WebP
wykonano bezpośrednio w sesji. Źródła: trial-01 dla `cw043`, `cw044`
i `cw046–cw048`; trial-02 dla `cw045`, po korekcie czytelności aktywnej
fazy barków. Wykonano 7 pojedynczych żądań. Suma szacunków
`upper_bound_no_cache` wynosi 0,159204 USD, nie jest to potwierdzone
rozliczenie dostawcy.

Pełna weryfikacja Dockerowa `fit-web:batch-12-verified` zakończyła się
powodzeniem: 366 testów zaliczonych, 0 problemów analizy. Rejestr,
oczekiwania testu i pliki obejmują 114 ID; fallback wskazuje `cw049`.
Wersja produkcyjna pozostaje `1.9.0+22`.

## Trzynasta partia

Zakres trzynastej partii obejmuje `cw049–cw054`. Wszystkie sześć zasobów
WebP 512×512 jest lokalnie zintegrowanych i niewydanych. Układ kadrów:
2/2/2/3/2/2. `cw052` ma trzy pionowe kolumny od lewej do prawej:
oba ciężary na podłodze, wiosłowanie prawą ręką, wiosłowanie lewą ręką.

Użytkownik powierzył asystentowi decyzję o chwycie w niejednoznacznym
`cw050`. Przyjęto chwyt za uchwyt hantla nachwytem; ustawienie pionowe
potraktowano jako przygotowanie przed zilustrowanym ruchem. Jest to jawna
interpretacja potrzeb ilustracji, bez zmiany danych katalogu. Sprawdzono
podpory planku, podchwyty `cw051`, stałą pozycję bioder oraz rozróżnienie
retrakcja Kelso / elewacja barków, z prostymi łokciami w obu ćwiczeniach.

Wykonanie i kontrola źródeł, podglądów 512×512 oraz finalnych WebP odbyły
się bezpośrednio w sesji. Źródła: trial-01 dla `cw049–cw052` i `cw054`,
trial-02 dla `cw053`, po korekcie widoczności drugiego ciężaru i czytelności
aktywnej fazy łopatek. Wykonano 7 pojedynczych żądań. Suma szacunków
`upper_bound_no_cache` wynosi 0,160074 USD; nie jest to potwierdzone
rozliczenie dostawcy.

Pełna weryfikacja Dockerowa `fit-web:batch-13-verified` zakończyła się
powodzeniem: 366 testów zaliczonych, 0 problemów analizy. Rejestr,
oczekiwania testu i pliki obejmują 120 ID; fallback wskazuje `cw055`.
Wersja produkcyjna pozostaje `1.9.0+22`.

## Czternasta partia

Zakres czternastej partii obejmuje `cw055–cw060`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Układ kadrów: 2/2/2/2/2/1.
W `cw056` przyjęto siad na podłodze z niską zewnętrzną kotwą przed ciałem.
`cw057` pokazuje klęk obunóż, `cw058` stabilny stój wykroczny. Sprawdzono
ciągłość gum od kotew do obu chwytów oraz przebieg poza głową i szyją.

Po dwóch odrzuconych korektach każdego z `cw057–cw059` zatrzymano płatne
próby i uzyskano zgodę użytkownika na nowe kompozycje. `cw057–cw058` mają
stałą kamerę frontalną w obu panelach; `cw059` dwa poziome pasy pełnej
szerokości, czytane od góry do dołu. Nowe ujęcia poprawiły czytelność gum,
obu par kończyn i kontaktu brzucha oraz miednicy z podłożem. `cw060` ma
pojedynczy kadr utrzymania, bez timera. Kontrole zgodności i jakości
wykonywano bezpośrednio oraz przy wsparciu niezależnego subagenta.

Zaakceptowane źródła: trial-01 dla `cw055`, `cw056`, `cw060`; new-01 dla
`cw057`, `cw059`; new-02 dla `cw058`, po korekcie wysokości łokci.
Wykonano 16 pojedynczych żądań. Suma szacunków `upper_bound_no_cache`
wynosi 0,362602 USD; nie jest to potwierdzone rozliczenie dostawcy.

Pełna weryfikacja Dockerowa `fit-web:batch-14-verified` zakończyła się
powodzeniem: 366 testów zaliczonych, 0 problemów analizy. Rejestr,
oczekiwania testu i pliki obejmują 126 ID; fallback wskazuje `cw061`.
Wersja produkcyjna pozostaje `1.9.0+22`; Partie 07–14 obejmują 48
niewydanych ilustracji.

## Piętnasta partia

Zakres piętnastej partii obejmuje `cw061–cw066`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Układ kadrów: 3/2/2/2/2/2.
`cw061` ma trzy poziome pasy pełnej szerokości, czytane od góry do dołu:
ramiona przy biodrach, T, nad głową; nogi i tułów pozostają podparte.
W `cw062` przyjęto wariant z jednym hantlem oburącz przed klatką;
odróżniono go od RDL z dwoma ciężarami przy goleniach. W wyciskaniach
kontrolowano dwa chwyty, ustawienie nadgarstków, podpory siadu i stabilny
stój bez wybicia nogami.

Użytkownik zatwierdził interpretację `cw064`: przyciągnięcie wolnego końca
krótkiego hantla w kierunku klatki, bez wymogu jej dotknięcia. Pokazano
mały częściowy zakres z jednym końcem podpartym w rogu, zamiast wydłużać
sprzęt do sztangi. Dwie korekty usunęły nadmierne wydłużenie uchwytu oraz
przesunięcie podparcia; końcową projekcję i czytelność oceniono w źródle
i w 512 px. Nie zmieniano danych katalogowych.

Źródła: trial-01 dla `cw061`, `cw063`, `cw065`; correction-01 dla `cw062`
i `cw066`; correction-02 dla `cw064`. Pozostałe korekty dotyczyły skłonu
i podparcia dłoni w good morning oraz ustawienia stóp, nadgarstków i głowy
w strict press. Źródła i podglądy odczytywano przed kolejnymi żądaniami,
a przeglądy zgodności i jakości wspierał niezależny subagent.
Wykonano 10 pojedynczych żądań; suma szacunków `upper_bound_no_cache`
wynosi 0,227790 USD, nie jest to potwierdzone rozliczenie dostawcy.

Pełna weryfikacja Dockerowa `fit-web:batch-15-verified` zakończyła się
powodzeniem: 366 testów zaliczonych, 0 problemów analizy. Formatowanie
dwóch zmienionych Dartów nie wymagało zmian. Rejestr, oczekiwania testu
i pliki obejmują 132 ID; fallback wskazuje `cw067`. Wersja produkcyjna
pozostaje `1.9.0+22`; Partie 07–15 obejmują 54 niewydane ilustracje.

## Szesnasta partia

Zakres szesnastej partii obejmuje `cw067–cw072`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Układ kadrów: 3/2/3/2/2/2.
`cw067` i `cw069` mają po trzy pionowe kolumny od lewej do prawej;
`cw068` dwa kadry obok siebie, a wznosy bokiem `cw070–cw072` dwa poziome
pasy pełnej szerokości od góry do dołu.

Użytkownik zatwierdził interpretację początku Arnold press: dłonie ku
własnej twarzy, następnie częściowa rotacja i dłonie do przodu nad głową.
Przy chwycie neutralnym dłonie pozostają skierowane ku sobie nawzajem.
W push press sprawdzono rzeczywisty płytki dip i wyprost nóg bez drugiego
ugięcia jak w jerk. W `cw071` prawa stopa jest jedyną podporą w obu fazach;
lewa jest czytelnie uniesiona. Pauza `cw072` pozostaje wyłącznie w katalogu.

Źródła: correction-01 dla `cw067–cw068`, trial-01 dla `cw069–cw072`.
Korekta Arnold press rozdzieliła hantle na początku i uwidoczniła
pośrednią rotację dłoni. Korekta `cw068` zastąpiła błędny chwyt do przodu
neutralnym, ocenianym z dłoni i przedramion, nie samych osi hantli.
Źródła i podglądy 512 px odczytywano przed kolejnymi żądaniami; zgodność
i jakość oceniano bezpośrednio oraz przy wsparciu niezależnego subagenta.

Pierwsze żądanie `cw068` zwróciło błąd HTTP bez PNG, danych użycia,
identyfikatora odpowiedzi ani kosztu. Nie ponowiono go automatycznie.
Użytkownik wyraźnie zatwierdził nowe pojedyncze żądanie w świeżym katalogu
trial-02, z którego wykonano następnie korektę chwytu. Zachowano ledger
błędu. Łącznie 9 prób: 8 udanych i 1 błąd HTTP. Suma szacunków
`upper_bound_no_cache` dla udanych żądań wynosi 0,182506 USD; koszt
nieudanego żądania jest nieznany, a kwota nie jest rozliczeniem dostawcy.

Pełna weryfikacja Dockerowa `fit-web:batch-16-verified` zakończyła się
powodzeniem: 366 testów zaliczonych, 0 problemów analizy. Formatowanie
dwóch zmienionych Dartów nie wymagało zmian. Rejestr, oczekiwania testu
i pliki obejmują 138 ID; fallback wskazuje `cw073`. Produkcja pozostaje
`1.9.0+22`; Partie 07–16 obejmują 60 niewydanych ilustracji.

## Siedemnasta partia

Zakres siedemnastej partii obejmuje `cw073–cw078`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Układ kadrów: 2/3/2/2/2/2.
`cw073` ma dwa kadry obok siebie, `cw074` trzy pionowe kolumny, a
`cw075–cw078` dwa poziome pasy pełnej szerokości.

Naprzemienność `cw074` pokazuje ciągłe przejście: prawa w górze, obie
w połowie ruchu, lewa w górze, bez resetu obu rąk na dole. Sprawdzono
nachwyt i kierunek unoszenia w przód. Rozpiętki odróżniono od wiosłowania;
na ławce około 35° kontrolowano podparcie klatki i miednicy oraz wolną
głowę. Y-raise pokazuje kierunek względem osi tułowia i kciuki ku górze;
ławka wynika z nazwy/wskazówek, bez edycji pola sprzętu katalogowego.

Korekta `cw077` uwidoczniła rozwidlenie Y i jednakowo zmniejszyła obie
sceny, aby zmieścić ramiona. Po dwóch odrzuconych korektach `cw078`
zatrzymano stare ujęcie i uzyskano wyraźną zgodę użytkownika na nową
kompozycję: profil boczny, kompaktowe wysokie V i delikatne nieopisane
szwy podłogi. W nowej wersji utrzymano podparcie obu dłoni i przodostopi,
rozstaw podpór oraz prześwit pod głową, bez podpierania się głową.

Źródła: trial-01 dla `cw073–cw076`, correction-01 dla `cw077`, new-01
dla `cw078`. Źródła i podglądy odczytywano przed kolejnymi żądaniami;
przeglądy zgodności, a następnie jakości wspierał niezależny subagent.
Wykonano 10 pojedynczych udanych żądań, bez błędów HTTP. Suma szacunków
`upper_bound_no_cache` wynosi 0,228200 USD, nie rozliczenie dostawcy.

Pełna weryfikacja Dockerowa `fit-web:batch-17-verified` zakończyła się
powodzeniem: 366 testów zaliczonych, 0 problemów analizy. Formatowanie
dwóch zmienionych Dartów nie wymagało zmian. Rejestr, oczekiwania testu
i pliki obejmują 144 ID; fallback wskazuje `cw079`. Produkcja pozostaje
`1.9.0+22`; Partie 07–17 obejmują 66 niewydanych ilustracji.

## Osiemnasta partia

Zakres osiemnastej partii obejmuje `cw079–cw084`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Kadry: 2/1/2/2/2/2.
Elevated pike i wznos jednostronny mają po dwa poziome pasy, handstand
pojedynczy kadr utrzymania, pozostałe po dwa kadry obok siebie.
Stanie i HSPU pokazują plecy do ściany, kontakt pięt oraz wolną głowę.
W HSPU pięty zsuwają się podczas opuszczania; miejsca dłoni są zachowane.
Czas holda pozostaje w katalogu, bez timera lub fikcyjnej fazy wejścia.

Sprawdzono stopy na siedzisku w elevated pike, naturalne wyprostowanie
nadgarstków przy płaskich dłoniach i rozróżnienie chwytów gumy od podpór
podłogowych. W `cw082` i `cw084` jedna guma jest przyciśnięta obiema
podeszwami, z dwiema gałęziami do uchwytów. W `cw083` lewa stopa kotwi
jedyny roboczy odcinek, prawa ręka unosi uchwyt, a obie stopy są podparte.
Ukośny przebieg przed sylwetką oceniano przestrzennie, nie jako przenikanie.

Zaakceptowane źródła: trial-01 dla `cw079`, `cw082`, `cw084`;
correction-01 dla `cw080–cw081`. Korekta holda poprawiła orientację
głowy względem odwróconej szyi; korekta HSPU przywróciła stałe miejsca
dłoni i dopasowała ugięte ramiona. `cw083` pochodzi z trial-01 po lokalnym
poziomym odbiciu całego frontalnego obrazu (`cw083-approved-flipped.png`),
które przywróciło zatwierdzone strony bez kolejnego płatnego żądania.
Oryginalny PNG i ledger zachowano.

Prompty i `cw079` przeszły niezależne przeglądy. Po osiągnięciu limitu
subagentów przy próbie przeglądu `cw080` pozostałe źródła, podglądy 512 px,
finalne WebP oraz integrację sprawdzono bezpośrednio w sesji. Nie wykonano
dodatkowych niezależnych przeglądów po tym limicie. Odczytano wszystkie
osiem ledgerów; uwzględniono wyłącznie sukcesy z różnymi request_id.
8 udanych pojedynczych żądań, bez błędów HTTP; suma szacunków
`upper_bound_no_cache` 0,182626 USD, nie rozliczenie dostawcy.

Pierwszy build weryfikacyjny został przerwany przed testami i wznowiony.
Pełna weryfikacja `fit-web:batch-18-verified` zakończyła się powodzeniem:
366 testów zaliczonych, 0 problemów analizy, formatowanie dwóch Dartów
bez zmian. Rejestr, oczekiwania testu i pliki obejmują 150 ID, fallback
`cw085`. Produkcja pozostaje `1.9.0+22`; Partie 07–18 zawierają 72
niewydane ilustracje.

## Dziewiętnasta partia

Zakres dziewiętnastej partii obejmuje `cw085–cw090`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Kadry: 2/2/2/2/4/2.
`cw085–cw088` mają dwa kadry obok siebie, `cw089` siatkę 2×2 czytaną
górny lewy→górny prawy→dolny lewy→dolny prawy, `cw090` dwa poziome pasy.

Face pull pokazuje kotwę na poziomie oczu i rozdzielone chwyty z łokciami
wyżej od nadgarstków. W rotacjach z gumą prawa ręka jest robocza:
kotwa po lewej stronie postaci w external rotation, po prawej w internal
rotation. Sprawdzono ręcznik cw087, położenie łokci przy tułowiu i ruch
przedramienia zamiast curl/row. Cuban press: zwis, upright row, rotacja
w górę przy łokciach na poziomie barków, wyciskanie. Side-lying pokazuje
lewy bok, jeden hantel w górnej prawej ręce i stabilne podpory.

Użytkownik zatwierdził reuse cw055 dla cw086. Skopiowano istniejący
WebP bez zmian, identyczność bajtów potwierdzono przez cmp. Oryginał,
katalogowe ID i tempo zachowano; zero żądań API dla cw086.
Pozostałe zaakceptowane źródła: correction-02 dla cw085, correction-01
dla cw087–cw089, trial-01 dla cw090. Dwie korekty face pull poprawiły
wysokość łokci. Rotacje poprawiono w zakresie stron kotew i połączenia
przedramienia/chwytu, Cuban press w zakresie trzeciej fazy przed wyciskaniem.

Generacje, kontrolę źródeł i podglądów oraz końcowych WebP wykonano
bezpośrednio w sesji, bez niezależnych subagentów po wcześniej osiągniętym
limicie. Przeglądy prowadzono w kolejności zgodność→jakość. Odczytano
rekordy success dziesięciu ledgerów z różnymi request_id, bez ponownego
liczenia response_received. 10 udanych pojedynczych żądań, bez błędów HTTP;
upper_bound_no_cache 0,226785 USD, nie potwierdzone rozliczenie dostawcy.

Pełna weryfikacja `fit-web:batch-19-verified` zakończyła się powodzeniem:
366 testów zaliczonych, 0 problemów analizy, formatowanie dwóch Dartów
bez zmian. Pliki, rejestr i oczekiwania testu obejmują 156 ID, fallback
cw091. Produkcja nadal `1.9.0+22`; Partie 07–19 obejmują 78 niewydanych
ilustracji. Dane katalogowe i wcześniejsze pakiety pozostają zachowane.

## Dwudziesta partia

Zakres dwudziestej partii obejmuje `cw091–cw096`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Kadry: 2/2/2/2/3/2.
Scaption cw091–cw092 ma dwa poziome pasy, cw093–cw094 i cw096 dwa kadry
obok siebie, a cw095 trzy pionowe kolumny od lewej do prawej.

Sprawdzono tor około 30° przed płaszczyzną boczną i przeciwne kierunki
kciukowych stron chwytów w fazie uniesienia, bez załamywania nadgarstków.
W cw093 odróżniono supinację od neutralnego chwytu hammer cw094.
Naprzemienność cw095 pokazuje prawa w górze→obie w połowie→lewa w górze,
bez resetu obu rąk na dole. W incline curl kontrolowano oparcie około
55°, podparcie pleców/pośladków/stóp oraz swobodny zwis obu ciężarów
i stabilność łokci względem tułowia.

Źródła: trial-01 dla cw091/cw093/cw094, correction-01 dla cw092,
correction-02 dla cw096. W cw092 poprawiono zamknięcie chwytów,
czytelność obu głowic i poziom końcowy. Dwie korekty cw096 odsłoniły
dalszą rękę z rzeczywistym chwytem zamiast pojedynczej głowicy zza uda.
Cw095 wykorzystuje `cw095-approved-reordered.png`, lokalne przestawienie
kolumn z trial-01 w odwrotnej kolejności. Nie odbijano ani nie deformowano
postaci; zmiana przywróciła zatwierdzony początek prawą ręką. Oryginał
i ledger zachowane, bez dodatkowego płatnego żądania.

Źródła, podglądy i finalne WebP sprawdzono bezpośrednio w sesji w kolejności
zgodność→jakość, bez niezależnych subagentów po wcześniej osiągniętym
limicie. Odczytano rekordy success dziewięciu ledgerów, każdy request_id
odrębny. 9 udanych pojedynczych żądań, bez błędów HTTP; szacunek
upper_bound_no_cache 0,205028 USD, nie potwierdzone rozliczenie dostawcy.

Pełna weryfikacja `fit-web:batch-20-verified`: 366 testów zaliczonych,
0 problemów analizy, formatowanie dwóch zmienionych Dartów bez zmian.
Rejestr, oczekiwania testu i pliki obejmują 162 ID, fallback cw097.
Produkcja nadal `1.9.0+22`; Partie 07–20 zawierają 84 niewydane ilustracje.
Katalog, wcześniejsze pakiety i dowody wydań pozostają zachowane.

## Dwudziesta pierwsza partia

Zakres dwudziestej pierwszej partii obejmuje `cw097–cw102`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Kadry: 4/2/2/2/3/2. Zottman ma
siatkę 2×2: dół podchwytem → góra podchwytem → góra nachwytem → dół nachwytem.
`cw101` ma trzy pionowe kolumny dół/połowa/góra; pozostałe dwa kadry obok siebie.

Użytkownik zatwierdził interpretację niejednoznacznego opisu `cw098`:
jeden hantel w prawej dłoni, ten sam prawy łokieć podparty o wewnętrzną
powierzchnię prawego uda. Katalog pozostał bez zmian. W `cw099` chwyt
neutralny prowadzi ciężar ku lewemu barkowi, bez wymuszania kontaktu.
Sprawdzono pronację dłoni w reverse curl oraz rzeczywistą zmianę chwytów
Zottmana, nie same osie hantli. Trzy punkty `cw101` ilustrują zakresy,
nie dowodzą wykonania 21 powtórzeń; metoda 7+7+7 pozostaje w katalogu.
`cw102` pokazuje podchwyt na szerokość barków, pełny zwis i górną klatkę
blisko stałego drążka, ze stopami w powietrzu.

Wszystkie zaakceptowane źródła to trial-01. Przed generacją `cw102`
doprecyzowano margines nad drążkiem. Źródła, podglądy 512 px i finalne WebP
sprawdzono bezpośrednio w sesji w kolejności zgodność→jakość, bez niezależnego
przeglądu subagentów po osiągniętym limicie. Sześć pojedynczych udanych żądań,
bez korekt i błędów HTTP. Rekordy success sześciu ledgerów mają odrębne
request_id; response_received nie liczono ponownie. Suma szacunków
`upper_bound_no_cache` wynosi 0,138377 USD, nie jest rozliczeniem dostawcy.

Pełna weryfikacja `fit-web:batch-21-verified`: 366 testów zaliczonych,
0 problemów analizy, formatowanie dwóch zmienionych Dartów bez zmian.
Log: `/root/.local/share/opencode/tool-output/tool_13befbeff001TlBy4AREJ9szGN`.
Rejestr, oczekiwania testu i pliki obejmują 168 ID, fallback `cw103`.
Partie 07–21 zawierają 90 niewydanych ilustracji; 148 ćwiczeń nadal bez grafiki.
Produkcja pozostaje `1.9.0+22`.

## Dwudziesta druga partia

Zakres dwudziestej drugiej partii obejmuje `cw103–cw108`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512, po dwa kadry. `cw103–cw106` mają
kadry obok siebie, `cw107–cw108` dwa poziome pasy czytane od góry do dołu.
Sprawdzono ciągłość jednej gumy pod obiema stopami i podchwyt band curl,
cofnięcie łokci i krótki zakres drag curl, różne chwyty wyprostów nad głową,
podparcie głowy/ciała/stóp na ławce i zgięcie łokci skull crusher.

Overhead extension pokazuje zatwierdzony stój; `cw105` jeden pionowy ciężar
podparty obiema dłońmi pod górną głowicą, `cw106` prawą dłoń na rękojeści
i lewą stabilizującą ramię. Skull crusher wykorzystuje katalogową opcję
do czoła, z prześwitem między hantlami a głową, bez ruchu jak w wyciskaniu.

Źródła zaakceptowane: trial-01 dla `cw103`, `cw104`, `cw106`, `cw107`;
correction-02 dla `cw105`; new-correction-02 dla `cw108`. Dwie korekty
`cw105` poprawiły margines nad ciężarem i widoczność drugiej dłoni.
W `cw108` po dwóch odrzuconych korektach starego ujęcia zatrzymano próby
i uzyskano zgodę użytkownika na nową kamerę od strony stóp pod kątem 3/4.
Nowe ujęcie wymagało dwóch korekt chwytów oraz rozdzielenia równoległych
hantli. Druga przywróciła neutralne dłonie i kontakt boków osobnych głowic,
zamiast wspólnej poprzecznej rękojeści. Użytkownik zatwierdził kontynuację
do poprawnego wyniku. Naturalną okluzję oceniono z ciągłości dłoni i sprzętu.

Źródła i podglądy 512 px odczytywano przed kolejnymi żądaniami; finalne
WebP sprawdzono po konwersji. Kontrola zgodność→jakość była bezpośrednia,
bez niezależnych subagentów po wcześniej osiągniętym limicie. Odczytano
13 rekordów success z różnymi request_id, bez podwójnego liczenia
response_received; bez błędów HTTP. Suma szacunków `upper_bound_no_cache`
wynosi 0,298231 USD, nie jest to potwierdzone rozliczenie dostawcy.

Pełna weryfikacja `fit-web:batch-22-verified`: 366 testów zaliczonych,
0 problemów analizy, formatowanie dwóch zmienionych Dartów bez zmian.
Log: `/root/.local/share/opencode/tool-output/tool_13e3c08d9001Xf7fAflomR2lO1`.
Rejestr, oczekiwania testu i pliki obejmują 174 ID, fallback `cw109`.
Partie 07–22 zawierają 96 niewydanych ilustracji; 142 ćwiczenia bez grafiki.
Produkcja pozostaje `1.9.0+22`.

## Dwudziesta trzecia partia

Zakres dwudziestej trzeciej partii obejmuje `cw109–cw114`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512, po dwa kadry. `cw109`, `cw110`
i `cw114` mają kadry obok siebie; `cw111–cw113` dwa poziome pasy.

Kickback pokazuje prawą rękę i poziome górne ramię przy ukośnym tułowiu;
korekta przywróciła wysokość łokcia i wyprost w tył zamiast ruchu barkiem.
Użytkownik zatwierdził reuse `cw002` dla `cw110`: identyczność bajtów
potwierdzono przez cmp, bez nowego żądania API. Technika i tempo katalogowe
są zgodne; oba ID i opisy zachowano.

W bench dips po dwóch nieskutecznych korektach dalszej dłoni zakończono
pracę nad bocznym ujęciem. Nowe przednie ujęcie od strony stóp pod kątem
3/4 odsłoniło obie dłonie na krawędzi jednej ławki. Przed pierwszą generacją
weighted dips zastosowano ten sam kierunek kamery: jeden hantel spoczywa
na górnej części ud, obie dłonie pozostają podporami, nogi wyprostowane,
pięty na podłodze. Nie dodano drugiej ławki.

JM press pokazuje neutralne chwyty, dwa osobne hantle oraz zgięcie
i obniżenie łokci przy opuszczaniu ku brodzie. „45°” odnosi się do
umiarkowanego ustawienia ramion względem tułowia, a „w kierunku bioder”
do składowej powrotu od brody w górę i ku stopom, kończącego się nad klatką,
nie do wyciskania nad miednicę. Jawna interpretacja bez zmiany katalogu.
Po dwóch odrzuconych korektach sprzętu zmieniono kamerę na bardziej
podwyższone ujęcie od strony stóp; dwie dalsze korekty rozdzieliły ciężary
i ustawiły rzeczywiste chwyty neutralne. Pushdown pokazuje stałą wysoką
kotwę przed ciałem, dwie gałęzie gumy i wyprost przy nieruchomych ramionach.

Zaakceptowane źródła: correction-01 dla `cw109`, new-01 dla `cw111`,
trial-01 dla `cw112` i `cw114`, new-correction-02 dla `cw113`, cw002.webp
dla `cw110`. Wszystkie źródła i podglądy 512 px odczytywano przed kolejnymi
żądaniami; końcowe WebP sprawdzono po konwersji. Kontrole zgodność→jakość
były bezpośrednie, bez niezależnych subagentów po wcześniejszym limicie.
Użytkownik wcześniej polecił kontynuować do poprawnego wyniku; przy zmianie
kompozycji zaprzestawano korekt starego ujęcia.

Odczytano 14 rekordów success z różnymi request_id, bez ponownego liczenia
response_received. 7 źródeł/nowych kompozycji i 7 korekt, bez błędów HTTP.
Suma szacunków `upper_bound_no_cache` wynosi 0,321043 USD, nie jest to
potwierdzone rozliczenie dostawcy. Dla `cw110` zero żądań API.

Pełna weryfikacja `fit-web:batch-23-verified`: 366 testów zaliczonych,
0 problemów analizy, formatowanie dwóch zmienionych Dartów bez zmian.
Log: `/root/.local/share/opencode/tool-output/tool_13e71e0d60019bPctAEs4CySLa`.
Rejestr, oczekiwania testu i pliki obejmują 180 ID, fallback `cw115`.
Partie 07–23 zawierają 102 niewydane ilustracje; 136 ćwiczeń bez grafiki.
Produkcja pozostaje `1.9.0+22`.

## Dwudziesta czwarta partia

Zakres dwudziestej czwartej partii obejmuje `cw115–cw120`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Kadry: 2/2/2/2/2/1; Tate press
ma dwa poziome pasy, pozostałe nowe grafiki dwa kadry obok siebie.
Zwis zachowuje jeden kadr. Cw120 to zatwierdzona identyczna kopia cw043,
cmp potwierdził zgodność bajtów; zero nowych żądań API dla tego ID.

Band overhead extension pokazuje dwie napięte gałęzie od niskiej kotwy
za plecami do dwóch uchwytów, wyprost łokci przy ramionach obok głowy.
Tate press realizuje zatwierdzoną interpretację niejasnej wskazówki:
łokcie rozchodzą się na zewnątrz względem hantli, ciężary schodzą ku klatce.
Chwyt jest pronowany, bez łamania nadgarstków w celu dosłownego skierowania
dłoni ku podłodze. Nie zmieniano tekstu katalogowego.

W wrist curl zmienia się kąt dłoni względem podpartego przedramienia;
zwykła zasada neutralnego nadgarstka tutaj nie obowiązuje. Cw117 zachowuje
podchwyt, cw118 nachwyt, łokcie i przedramiona na udach, nadgarstki poza
kolanami. W cw117 dwie korekty pierwszego ujęcia nie usunęły unoszenia
przedramion; nowe bardziej boczne ujęcie ze skłonem poprawiło podparcie,
a jedna korekta przywróciła podchwyt w dolnej fazie. Przed pierwszą generacją
cw118 zastosowano tę samą zasadę wyraźnego podparcia.

W farmer walk pierwsze ujęcie i dwie korekty powtarzały tę samą prowadzącą
nogę; zatrzymano tę kompozycję. Nowa stała kamera frontalna pokazuje lewą
nogę prowadzącą w pierwszym i prawą w drugim kadrze, z dwoma ciężarami
przy bokach przez cały czas. Czas/dystans pozostają w katalogu; dwa kroki
nie dowodzą przejścia całej serii.

Zaakceptowane źródła: trial-01 dla cw115/cw116/cw118,
new-correction-01 dla cw117, new-01 dla cw119, cw043.webp dla cw120.
Źródła i podglądy 512 px odczytywano przed kolejnymi żądaniami; wszystkie
finalne WebP sprawdzono po konwersji. Kontrole zgodność→jakość wykonano
bezpośrednio, bez niezależnych subagentów po wcześniejszym limicie.

Odczytano 12 rekordów success z odrębnymi request_id, response_received
bez ponownego liczenia. 7 źródeł/nowych kompozycji i 5 korekt, bez błędów HTTP.
Suma szacunków upper_bound_no_cache wynosi 0,276504 USD, nie jest to
potwierdzone rozliczenie dostawcy.

Pełna weryfikacja `fit-web:batch-24-verified`: 366 testów zaliczonych,
0 problemów analizy, formatowanie dwóch zmienionych Dartów bez zmian.
Log: `/root/.local/share/opencode/tool-output/tool_13eaf3d36001pdW40eXnQwoKfF`.
Rejestr, oczekiwania testu i pliki obejmują 186 ID, fallback cw121.
Partie 07–24 obejmują 108 niewydanych ilustracji; 130 ćwiczeń bez grafiki.
Produkcja pozostaje `1.9.0+22`.

## Dwudziesta piąta partia

Zakres dwudziestej piątej partii obejmuje `cw121–cw126`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Kadry: 2/1/3/2/2/2. Pinch hold
ma jeden kadr, wrist roller trzy pionowe kolumny; pozostałe dwa kadry obok siebie.
Wszystkie sześć grafik pochodzi z nowych źródeł, bez reuse.

Towel pull-up pokazuje dwa ręczniki przewieszone przez stały drążek,
każda dłoń obejmuje oba końce swojego ręcznika chwytem neutralnym.
Użytkownik zatwierdził górny punkt jako brodę przy wysokości dłoni,
bez wymuszania dosięgnięcia wyższego drążka. Dwie korekty podniosły
górną pozycję ciała przy zachowaniu chwytów i długości tkaniny.
Cw122 realizuje polski opis: szczypiec prawej dłoni na bokach górnej
głowicy pionowego hantla, nie talerz i nie chwyt za rękojeść.

W wrist rollerze rurka i sznurek wynikają z nazwy/wskazówek, bez zmiany
pola sprzętu. Jedna linka łączy środek rurki z rękojeścią jednego hantla.
Trzy pozycje pokazują skracanie wolnego odcinka i przyrost zwojów przy
stałej wysokości rurki; korekta zwiększyła ilość nawiniętej linki w ostatniej
kolumnie. Kontrolowane rozwijanie i liczba rolek pozostają w katalogu.
Cw124 pokazuje dłonie ku tyłowi i celowe zgięcie nadgarstków, z nieruchomymi
ramionami; jedna korekta poprawiła czytelność ruchu dłoni.

Goblet squat utrzymuje jeden pionowy hantel oburącz przy klatce i pełne
podparcie stóp. Side-held squat ma dwa oddzielne hantle poza kolanami,
długie ramiona i prześwit nad podłożem w dolnej fazie, bez zamiany na deadlift.
Kontrolowano głębokość, kierunek kolan i naturalne pochylenie tułowia.

Zaakceptowane źródła: correction-02 dla cw121, trial-01 dla cw122/cw125/cw126,
correction-01 dla cw123/cw124. Źródła i podglądy 512 px odczytywano przed
kolejnymi żądaniami; finalne WebP sprawdzono po konwersji. Kontrole
zgodność→jakość były bezpośrednie, bez niezależnych subagentów po wcześniejszym
limicie. Katalogowe ID, dane i wcześniejsze pakiety zachowano.

Odczytano 10 rekordów success z różnymi request_id, bez podwójnego liczenia
response_received: 6 źródeł i 4 korekty, bez błędów HTTP. Suma szacunków
upper_bound_no_cache wynosi 0,229705 USD, nie jest to potwierdzone rozliczenie
dostawcy.

Pełna weryfikacja `fit-web:batch-25-verified`: 366 testów zaliczonych,
0 problemów analizy, formatowanie dwóch zmienionych Dartów bez zmian.
Log: `/root/.local/share/opencode/tool-output/tool_13ef76ca0001BlTc05Y6JIjYgv`.
Rejestr, oczekiwania testu i pliki obejmują 192 ID, fallback cw127.
Partie 07–25 obejmują 114 niewydanych ilustracji; 124 ćwiczenia bez grafiki.
Produkcja pozostaje `1.9.0+22`.

## Dwudziesta szósta partia

Zakres dwudziestej szóstej partii obejmuje `cw127–cw132`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Kadry: 2/2/2/3/3/3. Front-rack squat
ma dwa kadry obok siebie; pozostałe grafiki poziome pasy od góry do dołu.
Wszystkie sześć pochodzi z nowych źródeł, bez reuse.

Front-rack squat wymagał usunięcia zbędnej ławki z pierwszej próby oraz
podniesienia łokci do przodu przy zachowaniu dwóch ciężarów na barkach.
W kolejnych promptach bez ławki doprecyzowano brak dodatkowego sprzętu.
Przysiad bułgarski realizuje zatwierdzoną interpretację niejasnego „wyskoku”
jako kontrolowanego zejścia, bez skoku: prawa stopa na podłodze i lewy
grzbiet stopy na siedzisku. Po dwóch korektach nieczytelnego dalszego chwytu
zakończono boczną kompozycję; nowe przednie 3/4 odsłoniło obie dłonie.

Static split squat ma nieruchome podpory bez ławki. Dwie korekty i pierwsza
nowa kompozycja nie zapewniły dostatecznej zgodności ustawienia stóp/dalszego
chwytu; zaakceptowano drugie nowe ujęcie frontalne z odniesieniami podłogi.
Walking lunges po pierwszej próbie z powtórzoną nogą i zmienną skalą przeszły
na frontalną kompozycję: prawa noga prowadzi, lewa przechodzi w przód,
następnie lewa prowadzi w kolejnym niskim wykroku. Ciało przemieszcza się
względem podłogi, bez odbijania całej postaci.

W reverse lunge dwie korekty bocznej kompozycji nie usunęły przesunięcia
przedniej stopy; nowe ujęcie frontalne pokazuje lewą nogę cofającą się
i wracającą przy prawej stopie pozostającej na miejscu. Lateral lunge
pokazuje krok prawą w bok, następnie zejście na prawą nogę przy lewej prostej,
obu piętach na podłodze i dwóch hantlach przy bokach.

Po dwóch korektach cw132 pozostało niewielkie przesunięcie pierwszej sceny.
Wykonano lokalną sztywną translację całego górnego regionu o 22 px w prawo:
`/tmp/opencode/cw132-approved-aligned.png`. Nie odbijano ani nie deformowano
kończyn, nie zmieniano zoomu. Piksele obu dolnych scen i linii podziału
pozostały identyczne; tożsamość przesuniętego regionu potwierdzono na RGB.
Nie wykonano dodatkowego żądania API dla tej operacji.

Zaakceptowane źródła: correction-02 dla cw127, new-01 dla cw128,
new-02 dla cw129, new-01 dla cw130/cw131 oraz correction-02 z lokalnym
wyrównaniem dla cw132. Źródła i podglądy 512 px odczytywano przed kolejnymi
żądaniami, finalne WebP po konwersji. Kontrole zgodność→jakość były
bezpośrednie, bez niezależnych subagentów po wcześniejszym limicie.
Katalog, ID i wcześniejsze pakiety zachowano.

Odczytano 21 rekordów success z odrębnymi request_id, bez ponownego liczenia
response_received: 11 źródeł/nowych kompozycji i 10 korekt, bez błędów HTTP.
Suma szacunków upper_bound_no_cache wynosi 0,480842 USD, nie jest to
potwierdzone rozliczenie dostawcy.

Pełna weryfikacja `fit-web:batch-26-verified`: 366 testów zaliczonych,
0 problemów analizy, formatowanie dwóch zmienionych Dartów bez zmian.
Log: `/root/.local/share/opencode/tool-output/tool_13f6c5c46001hwtZK26fVNBZVf`.
Rejestr, oczekiwania testu i pliki obejmują 198 ID, fallback cw133.
Partie 07–26 obejmują 120 niewydanych ilustracji; 118 ćwiczeń bez grafiki.
Produkcja pozostaje `1.9.0+22`.

## Dwudziesta siódma partia

Zakres dwudziestej siódmej partii obejmuje `cw133–cw138`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Kadry: 3/4/2/3/2/2. Cw133 ma
trzy poziome pasy, cw134 siatkę 2×2, cw135/cw137/cw138 po dwa poziome pasy.
Cw136 w końcowym wykonaniu ma trzy pionowe kolumny zamiast planowanych
poziomych pasów: nowa kompozycja zapewniła pionowe miejsce na uniesienie
ciała i prawidłową nogę podporową, bez skracania kończyn.

W curtsy lunge lewa noga cofa się po skosie za prawą, następnie ciało
schodzi przy prawej stopie pozostającej na miejscu. Pierwszą scenę wyrównano
lokalnie o 65 px w prawo jako całość: `/tmp/opencode/cw133-approved-aligned.png`.
Nie obracano, nie skalowano ani nie deformowano postaci. Piksele dolnych
scen i linii podziału pozostały identyczne; przesunięcie potwierdzono na RGB.
Zero dodatkowych żądań API dla tej operacji.

W cw134 pierwsza kompozycja powtarzała nogę prowadzącą; nowa frontalna
siatka pokazuje niski prawy wykrok bez skrętu, skręt klatki ku prawej,
przejście lewej nogi i następny niski lewy wykrok ze skrętem ku lewej.
Oba hantle pozostają przed klatką, skręca się tułów, nie tylko głowa/ręce.
W zwykłym step-up nowa kompozycja poprawiła proporcje postaci, a korekta
ujednoliciła ławkę. Finał pokazuje obie stopy na siedzisku, bez knee drive.

W cw136 kolejne odrzucone ujęcia myliły podparcie na ławce z podłogą,
nie prostowały nogi podporowej lub zmieniały jej tożsamość. Zakończono
te kompozycje. Frontalne trzy kolumny pokazują prawą pełną stopę na ławce
przez całą sekwencję: start, wyprost z lewą nogą wolną nisko, lewe kolano
wysoko. Ostatnia korekta przywróciła ten sam rozmiar ławki w trzeciej fazie.

Pistol cw137 pokazuje prawą piętę i przodostopie na podłodze, lewą nogę
prostą z prześwitem i ramiona w przód. Assisted pistol cw138 realizuje
zatwierdzony wariant z gumą: stała wysoka kotwa przed postacią, dwie napięte
gałęzie i rzeczywiste chwyty. Korekta wyprostowała nogę podporową w wysokiej
fazie, z zachowaniem głębokiej dolnej pozycji i wolnej lewej stopy.

Zaakceptowane źródła: trial-01 z lokalnym wyrównaniem dla cw133,
new-01 dla cw134, new-correction-01 dla cw135, new-correction-02 dla cw136,
trial-01 dla cw137 i correction-01 dla cw138. Źródła i podglądy 512 px
odczytywano przed kolejnymi żądaniami; finalne WebP po konwersji.
Kontrole zgodność→jakość były bezpośrednie, bez niezależnych subagentów
po wcześniejszym limicie. Katalog i wcześniejsze pakiety zachowano.

Odczytano 15 rekordów success z różnymi request_id, bez podwójnego liczenia
response_received: 11 źródeł/nowych kompozycji i 4 korekty, bez błędów HTTP.
Suma szacunków upper_bound_no_cache wynosi 0,348425 USD, nie jest to
potwierdzone rozliczenie dostawcy.

Pełna weryfikacja `fit-web:batch-27-verified`: 366 testów zaliczonych,
0 problemów analizy, formatowanie dwóch zmienionych Dartów bez zmian.
Log: `/root/.local/share/opencode/tool-output/tool_13fdee8cf001Q6giiBpQ5Nxs6j`.
Rejestr, oczekiwania testu i pliki obejmują 204 ID, fallback cw139.
Partie 07–27 obejmują 126 niewydanych ilustracji; 112 ćwiczeń bez grafiki.
Produkcja pozostaje `1.9.0+22`.

## Dwudziesta ósma partia

Zakres dwudziestej ósmej partii obejmuje `cw139–cw144`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Kadry: 2/2/1/1/3/3. Skater i sissy
mają po dwa poziome pasy, oba wall sits pojedyncze kadry utrzymania,
cossack trzy poziome pasy, jump squat trzy pionowe kolumny. Wszystkie źródła nowe.

Skater pokazuje prawą pełną stopę jako jedyną podporę i lewą nogę zgiętą
z tyłu, bez podparcia stopą lub kolanem. Korekta pogłębiła dolną pozycję.
W sissy squat użytkownik zatwierdził interpretację niejasnego „jednego palca”:
oba przodostopia podparte, pięty uniesione, prawa dłoń na stałym słupku.
Celowe odchylenie w tył z wydłużoną linią kolana–biodra–głowa nie jest
błędem postawy tego ćwiczenia. Pierwsza próba miała kadry obok siebie;
korekta przywróciła poziome pasy i spójny chwyt na słupku.

Oba wall sits mają plecy/miednicę podparte o ścianę, uda około poziomu,
kolana nad kostkami i pełne stopy na podłodze. Cw141 ma ramiona skrzyżowane
przed klatką bez nacisku na uda, cw142 jeden hantel oburącz przy klatce,
zgodnie z wybranym wariantem katalogowym. Bez fikcyjnej fazy ruchu/timera.

Cossack pokazuje stały szeroki rozstaw pięt i przejście prawa–środek–lewa
z jednym hantlem goblet. Palce wolnej prostej nogi mogą unosić się przy
podpartej pięcie; pełna stopa nogi roboczej pozostaje podparta. W jump squat
środkowa scena ma obie stopy w powietrzu, cień i widoczny prześwit przy
stałej podłodze; finał to lądowanie na ugiętych biodrach/kolanach.
Statyczna grafika nie mierzy siły lądowania, czasu utrzymania lub tempa.

Zaakceptowane źródła: correction-01 dla cw139/cw140, trial-01 dla cw141–cw144.
Źródła i podglądy 512 px odczytywano przed kolejnymi żądaniami; finalne
WebP po konwersji. Kontrole zgodność→jakość były bezpośrednie, bez niezależnych
subagentów po wcześniejszym limicie. Katalog i wszystkie wydane assety zachowano.

Odczytano 8 rekordów success z odrębnymi request_id, bez ponownego liczenia
response_received: 6 źródeł i 2 korekty, bez błędów HTTP. Suma szacunków
upper_bound_no_cache wynosi 0,185311 USD, nie jest rozliczeniem dostawcy.

Pełna weryfikacja `fit-web:batch-28-verified`: 366 testów zaliczonych,
0 problemów analizy, formatowanie dwóch zmienionych Dartów bez zmian.
Log: `/root/.local/share/opencode/tool-output/tool_1403c7499001LSNHSVAKUtKzGj`.
Rejestr, oczekiwania testu i pliki obejmują 210 ID, fallback cw145.
204 ilustracje pozostają wydane w 1.10.0+23 lub wcześniej; sześć Partii 28
pozostaje lokalnych niewydanych. 106 ćwiczeń bez grafiki. Produkcja 1.10.0+23.

## Dwudziesta dziewiąta partia

Zakres dwudziestej dziewiątej partii obejmuje `cw145–cw150`: sześć lokalnie
zintegrowanych, niewydanych WebP 512×512. Kadry: 3/4/3/2/2/2. Cw145 ma
trzy pionowe kolumny, cw146 siatkę 2×2, cw147 trzy poziome pasy, cw149 dwa
poziome pasy, cw148/cw150 dwa kadry obok siebie.

Skok180° pokazuje przygotowanie ku prawej, lot przodem do kamery i ugięte
lądowanie ku lewej; zmienia się orientacja ciała, nie kamera. Box jump ma
cztery fazy z końcowym wyprostem na ławce. Pierwsze ujęcie i korekta zmieniały
położenie/perspektywę podestu; nowe boczne ujęcie uprościło jego geometrię.
Wyrównano je lokalnie w `/tmp/opencode/cw146-approved-aligned.png`: wszystkie
cztery pełne sceny skalowane jednakowo do 85%, następnie przesunięte w siatce.
Nie deformowano ciała/sprzętu ani nie skalowano osobno faz. Tożsamość RGB
czterech regionów z jednakowo przeskalowanymi wycinkami źródła potwierdzono.
Operacja bez dodatkowego żądania API; obie pełne stopy na siedzisku w fazach3/4.

Broad jump pokazuje postęp w przód względem podłogi: przygotowanie po lewej,
lot w środku, ugięte lądowanie po prawej. Czas/siła/dystans nie są mierzone
przez statyczną ilustrację. Cw148 to zatwierdzona identyczna kopia cw063;
ponownie odczytano grafikę i technikę, cmp potwierdził identyczność bajtów,
zero nowych żądań dla tego ID. Katalogowe ID/nazwy/teksty zachowano.

Single-leg RDL ma prawą stopę jako jedyną podporę i dwa ciężary wzdłuż nogi,
lewą nogę w tył jako przeciwwagę i kontrolowaną miednicę. W stiff-leg deadlift
dwie korekty pogłębiły zawias biodrowy przy zachowaniu prawie prostych,
niezablokowanych kolan i neutralnego grzbietu; ciężary blisko kostek/podłoża,
bez wymuszania kontaktu z ziemią przez squat lub wydłużanie ramion.

Zaakceptowane źródła: trial-01 dla cw145/cw147/cw149, new-01 z lokalnym
wyrównaniem dla cw146, cw063.webp dla cw148, correction-02 dla cw150.
Źródła/podglądy512px odczytywano przed kolejnymi żądaniami; lokalny wynik
cw146 i finalne6WebP również odczytano. Przeglądy zgodność→jakość bezpośrednie,
bez niezależnych subagentów po wcześniejszym limicie. Partię28 zachowano.

Odczytano 9 rekordów success z różnymi request_id, bez ponownego liczenia
response_received: 6 źródeł/nowych kompozycji i 3 korekty, bez błędów HTTP.
Suma szacunków upper_bound_no_cache wynosi 0,209028 USD, nie jest rozliczeniem
dostawcy. Reusecw148 nie wymagał żądania API.

Pełna weryfikacja `fit-web:batch-29-verified`: 366 testów zaliczonych,
0 problemów analizy, formatowanie dwóch zmienionych Dartów bez zmian.
Log: `/root/.local/share/opencode/tool-output/tool_14077ebf1001w93VqBt67qAkA8`.
Rejestr, oczekiwania testu i pliki obejmują 216 ID, fallback cw151.
204 ilustracje wydane; 12 z Partii 28–29 lokalnych niewydanych; 100 ćwiczeń
bez grafiki. Produkcja pozostaje 1.10.0+23.

## Trzydziesta partia

Zakres `cw151–cw156`: sześć nowych ilustracji, kadry 2/2/3/2/2/2.
Cw151 ma kadry obok siebie, pozostałe poziome pasy. Sumo pokazuje niski
chwyt górnej głowicy jednego hantla i długie ramiona. W cw152 zamknięta
guma biegnie pod obiema stopami i na górnych plecach u nasady karku,
zgodnie z zatwierdzoną interpretacją katalogowego „za karkiem”.

Nordic pokazuje klęk, opad z kolan i kontakt dłoni z podłożem; correction-01
poprawiła faktyczną blokadę obu kostek pod niską poprzeczką i wysoki klęk.
Mosty cw154/cw155 mają głowę i barki na podłodze; cw155 jeden hantel
na biodrach. Cw156 odróżnia kontakt górnych pleców z ławką; correction-01
poprawiła ustawienie głowy/szyi przy zachowaniu hantla i podpór.

Zaakceptowane źródła: trial-01 dla cw151/cw152/cw154/cw155 oraz
correction-01 dla cw153/cw156, w odpowiednich katalogach `/tmp/opencode`.
Źródła i podglądy 512px odczytano przed kolejnymi żądaniami; odczytano
również sześć finalnych WebP 512×512. Przeglądy zgodność→jakość były
bezpośrednie, bez niezależnego review po wcześniejszym limicie subagentów.

Osiem sukcesów z unikalnymi request_id: sześć prób bazowych i dwie korekty,
bez błędów HTTP. Suma `upper_bound_no_cache`: **0,180536 USD** — szacunek,
nie rozliczenie dostawcy. Nie doliczano ponownie `response_received`.
Szczegóły kosztów i źródeł w specyfikacji Partii 30.

Pełna weryfikacja `fit-web:batch-30-verified`: 366 testów zaliczonych,
0 problemów analizy, kontrola wersji poprawna; formatowanie dwóch Dartów
bez zmian. Log: `/root/.local/share/opencode/tool-output/tool_140af9415001mYSMk7BeqJFhUg`.
Rejestr, test, pliki i tabela obejmują 222 ID, fallback cw157.
Stan: 222 lokalne / 204 wydane / 18 niewydanych z Partii 28–30 /
94 brakujące / 316 ćwiczeń. Produkcja pozostaje 1.10.0+23.

## Domknięcie katalogu — Partie 31–46

Na podstawie zgody użytkownika uzupełniono autonomicznie wszystkie pozostałe
94 pozycje `cw157–cw250`. Stan końcowy: **316 lokalnych / 204 wydane /
112 niewydanych / 0 brakujących / 316 ćwiczeń**. Zapisano dokładne prompty,
źródła, korekty i ledgery; sceny sprawdzano bezpośrednio w źródle1024 i przy512px.
Szczegóły scen, adaptacji i reuse w
[rejestrze wykonania](superpowers/specs/2026-10-15-exercise-illustrations-completion-results.md).

87 pozycji ma nowe źródła, 7 wykorzystuje zgodne wcześniejsze obrazy:
cw206←cw119, cw211←cw209, cw217←cw208, cw219←cw212,
cw238←cw236 i cw239/cw240←cw234. Parametry tempa, tętna, czasu lub liczby
obrotów linki pozostają w opisach; nie dodawano fikcyjnych timerów i napisów.
W cw215/cw216 pozostawiono jeden pełny kadr przez lokalne kadrowanie i
rozszerzenie tła; w cw220 lokalne odbicie ostatniej frontalnej fazy pokazuje
przeciwną podporę. Bez deformacji anatomii. Bezpośrednie kontrole nie stanowią
niezależnego review.

Odczyt115 ledgerów: 115 sukcesów z unikalnymi request_id, bez błędów HTTP
i nierozstrzygniętych żądań. Łączny szacunek `upper_bound_no_cache`:
**2,549335 USD**, nie rozliczenie dostawcy. Response_received nie liczono drugi raz.

Weryfikacja `fit-web:illustrations-complete`: **366 testów zaliczonych**,
analiza bez problemów, kontrola wersji poprawna. Test rejestru dodatkowo
porównuje wszystkie ID bezpośrednio z katalogiem; wszystkie316 obrazów
dekodowane512×512. Fallback testowany na nieznanym cw317.
Po korekcie samego formatowania testu check dwóch Dartów:0zmian.
Log pełnej weryfikacji:
`/root/.local/share/opencode/tool-output/tool_141d83e80001biO0U9xvWXpFpL`.
Produkcja pozostaje1.10.0+23; gotowy komplet lokalny oczekuje osobnego wydania.

## Rozszerzenie katalogu — cw317–cw363

47 nowych źródeł:16sandbag,3kółko,16joga,8kalistenika,4tai chi siedzące.
Nie zmieniano dotychczasowych316 ćwiczeń i ich ilustracji. Wszystkie nowe
obrazy512×512 odczytano jako źródło1024 i podgląd512 przed następnym żądaniem;
finalneWebP quality90/strip są identyczne z odczytanymi podglądami.
Przegląd obrazów bezpośredni; niezależny review dotyczył kodu, nie grafiki.

Źródła w /tmp/opencode/cwNNN-trial-01 poza:
cw320/cw349/cw355/cw357/cw361=correction-01; cw327=new-01.
Korekty: pojedynczy bark320; worek poza przednim kolanem327 (dwie korekty
odrzucone, nowe pełne ujęcie po ocenie kompozycji); klęk zamiast siadu349;
pełna sylwetka w jednym kadrze355; zgięte łokcie357; pełna dłoń361.
Prompty dokładne w /tmp/opencode/cwNNN-PRÓBA-prompt.txt, PNG i ledger.jsonl
w odpowiadających katalogach.55 sukcesów/unikalnychrequest_id:47 prób
bazowych,7korekt,1nowa kompozycja, bez błędów lub niepewności.
Suma upper_bound_no_cache: **1,219730 USD**, szacunek nie rozliczenie;
liczono tylko success, bez ponownego liczenia response_received.
Produkcja pozostaje1.11.0+24 z316 ilustracjami, lokalnie363/316/47/0/363.

## Obowiązujące zasady

- Jeden WebP 512×512 na ćwiczenie, od jednego do czterech kadrów zależnie od
  ruchu.
- Kremowe tło, komiksowy kontur i strój referencyjny z cw256.
- Pomarańcz wskazuje obszar docelowy; turkus oznacza istotny, widoczny mięsień
  wspierający lub stabilizujący.
- W biernym rozciąganiu można pominąć turkus. Nie oznaczamy stawów, ścięgien,
  nerwów ani zasłoniętych mięśni.
- Najpierw zatwierdzamy scenę i prompt, potem wykonujemy jedno generowanie
  Sunburst medium. Korektę lokalną stosujemy po zidentyfikowaniu konkretnego
  błędu. Nie powtarzamy automatycznie płatnego żądania.

Dokumenty `cw261-benchmark-prompt`, `cw265-image-prompt` i raport benchmarku
opisują historyczne próby. Ten plik określa stan wydanych i lokalnie
zintegrowanych zasobów.
