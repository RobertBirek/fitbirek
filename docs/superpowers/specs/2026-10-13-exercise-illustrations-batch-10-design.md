# Ilustracje ćwiczeń — projekt Partii 10

## Zakres i stan wejściowy

Partia obejmuje `cw031–cw036`: sześć wariantów podciągania, każdy z dwoma
kadrami. Źródłem nazw i wskazówek jest `assets/data/exercises.json`.
Nie zmieniać rekordów katalogu ani identyfikatorów.

Stan wejściowy: 96 ilustracji lokalnych, w tym 78 wydanych i 18 niewydanych
z Partii 07–09, oraz 220 ćwiczeń bez ilustracji na 316 rekordów. Po
integracji Partii 10: 102 lokalne = 78 wydanych + 24 niewydane, 214 brakujących.
Produkcja pozostaje `1.9.0+22`. Przygotowanie tego projektu nie uruchamia
płatnej generacji, zmian wersji, wdrożenia, commita ani pushu.

## Warianty przyjęte w projekcie

- `cw034`: wąski **nachwyt** na prostym drążku. Katalog określa szerokość,
  ale nie orientację dłoni; nachwyt jest decyzją ilustracyjną, nie nową
  informacją dopisaną do danych.
- `cw036`: **nachwyt na szerokość barków**. Katalog opisuje pauzę na górze,
  ale nie podaje chwytu; przyjęto podstawowy wariant podciągania.
- `cw035`: prawa anatomiczna dłoń nachwytem, lewa podchwytem. Nie zamieniać
  chwytów między fazami. Zalecenie zmiany chwytów co serię pozostaje w katalogu.
- W `cw036` czas trzech sekund opisuje katalog; obraz statyczny pokazuje
  górną pozycję zatrzymania, bez timera i sztucznego wyróżnika.

## Forma i kontrakt sprzętu

- Jeden WebP `512×512` na ID, generowany z PNG `1024×1024`.
- Dokładnie dwa oddzielone kadry obok siebie: lewy — dolny zwis,
  prawy — górna pozycja. Stała kamera, skala postaci, sprzęt i wysokość drążka.
- Styl `assets/exercises/cw256.webp`: kremowe tło, ciemny neutralny strój,
  faceless dorosła postać, komiksowy kontur. Bez tekstu, numerów, strzałek,
  timerów, znaków wodnych i duchów ruchu. Oznaczenia mięśni nie są wymagane.
- Całe ciało, obie dłonie i wszystkie istotne mocowania mieszczą się
  w kadrze. Obie stopy są nad podłogą w obu fazach; bez dodatkowego stopnia,
  asysty, gumy, obciążenia lub podporu nóg.
- Drążek jest poziomy i stabilnie zamocowany do prostej konstrukcji;
  nie pływa przy dłoniach i nie zmienia położenia wraz z postacią.
- W `cw033` dwa osobne równoległe uchwyty skierowane przód–tył są połączone
  ze wspólną konstrukcją. Każda dłoń obejmuje własny uchwyt, dłonie zwrócone
  do siebie; nie wymuszać neutralnego chwytu na jednym prostym drążku.
- Dłonie rzeczywiście obejmują drążek lub uchwyty; palce i kciuki są
  anatomicznie spójne. Naturalna okluzja nie może ukrywać istoty chwytu.
- Głowa nie przenika przez drążek. Broda w górnej fazie przechodzi nad jego
  poziom bez zastępowania ruchu odchyleniem szyi. Przy neutralnych uchwytach
  osiąga poziom powyżej chwytów, bez kolizji ze wspólną konstrukcją.
- Dopuszczalne lekkie ugięcie kolan, takie samo w obu fazach, dla czytelnej
  pełnej sylwetki. Nie przedstawiać kipu, kopnięcia, bujania ani skrętu bioder.

## Sceny i kryteria odrzucenia

| ID i ćwiczenie | Lewy kadr | Prawy kadr | Kamera i kontrola |
|---|---|---|---|
| `cw031` — Podciąganie szerokim nachwytem | Pełny zwis na prostych ramionach, nachwyt wyraźnie szerszy od barków. | Ugięte łokcie, broda nad drążkiem, tułów stabilny. | Stała przednio-boczna 3/4 ujawniająca chwyt; odrzucić podchwyt, szerokość barków, niepełny zwis, bujanie i kolizję głowy z drążkiem. |
| `cw032` — Podciąganie podchwytem | Pełny zwis, dłonie na szerokość barków, podchwyt. | Broda nad drążkiem, klatka zbliżona do niego, łokcie skierowane w dół. | Przednio-boczna 3/4; odrzucić nachwyt lub dłonie bez rzeczywistego kontaktu, ruch szyją zamiast podciągnięcia, unoszenie nóg w kipie. |
| `cw033` — Podciąganie chwytem neutralnym | Zwis na dwóch równoległych uchwytach, dłonie ku sobie. | Łokcie w dół i do tyłu, klatka przy uchwytach, broda powyżej poziomu chwytów. | Przednio-boczna 3/4 pokazująca kierunek i mocowanie obu uchwytów; odrzucić pojedynczy prosty drążek bez uchwytów, uchwyty pływające lub zmieniony chwyt. |
| `cw034` — Podciąganie wąskim chwytem | Pełny zwis, nachwyt wyraźnie węższy niż barki, dłonie rozdzielone. | Broda nad drążkiem, klatka zbliżona, łokcie w dół. | Przednio-boczna 3/4; odrzucić chwyt na szerokość barków, złączenie dłoni w jeden nielogiczny chwyt i zmianę na podchwyt. |
| `cw035` — Podciąganie chwytem mieszanym | Pełny zwis, prawa dłoń nachwytem, lewa podchwytem, około szerokości barków. | Te same chwyty i strony, broda nad drążkiem, stabilny tułów. | Przednio-boczna 3/4 ujawniająca obie dłonie; odrzucić dwa identyczne chwyty, zamianę stron między fazami, skręt tułowia i zrost dłoni z drążkiem. |
| `cw036` — Podciąganie z pauzą na górze | Pełny zwis, nachwyt na szerokość barków. | Stabilna górna pozycja zatrzymania, broda nad drążkiem, łokcie ugięte, aktywne łopatki. | Przednio-boczna 3/4; odrzucić nieosiągniętą górną pozycję, bujanie, wyciągnięcie brody samą szyją, timer lub fikcyjne wizualne kodowanie trzech sekund. |

W dolnej pozycji dopuszczalne jest naturalne ustawienie barków przy
uniesionych ramionach. Nie wymagać maksymalnej depresji łopatek jednocześnie
z rozluźnionym martwym zwisem. Górna faza nie może przedstawiać barków
wzruszonych do uszu zamiast kontrolowanego podciągnięcia.

## Generacja i przeglądy

1. Przygotować sześć osobnych promptów z fazami, chwytem, kamerą, sprzętem
   i kryteriami odrzucenia. Pierwsza próba każdego ID używa wyłącznie
   `/tmp/opencode/cw256-reference.png` jako referencji stylu.
2. Jedno żądanie `--single-sunburst-medium` przez
   `tools/benchmark_exercise_images.py`, w świeżym katalogu
   `/tmp/opencode/cwNNN-trial-NN`. Bez automatycznych płatnych retry.
3. Odczytać źródło i podgląd `512×512` przed kolejnym płatnym żądaniem.
   Sprawdzić obie dłonie, rozstaw i ciągłe mocowanie sprzętu w obu fazach.
4. Porównać `cw031/cw032/cw034`: szeroki nachwyt, podchwyt na szerokość
   barków i wąski nachwyt mają być rozpoznawalne bez podpisu. W `cw035`
   widoczna jest rzeczywista asymetria chwytów, nie tylko różnica ramion.
5. Korekta dotyczy tylko nazwanego defektu, z ostatnim odrzuconym PNG
   jako jedyną referencją i świeżym katalogiem. Po dwóch nieskutecznych
   korektach tego samego problemu zatrzymać płatne próby i ocenić nowe ujęcie.
6. Przegląd zgodności poprzedza niezależny przegląd jakości, anatomii
   i czytelności w `512×512`. Same nadgarstki obrócone bez spójnych palców
   nie wystarczają do uznania prawidłowego chwytu.

## Integracja i weryfikacja

- Najpierw dodać `cw031–cw036` po `cw030`, przed `cw251`, do
  `expectedIllustrationIds` w `test/features/exercises/exercise_illustrations_test.dart`.
- Test braku ilustracji przenieść z `cw031` na `cw037`. Wykazać czerwony
  kontrakt rejestru z brakiem `cw031`, przy poprawnym fallbacku `cw037`.
- Po zaakceptowaniu całej szóstki konwertować źródła przez `convert`
  z opcjami `-resize 512x512 -strip -quality 90` do WebP.
- Zarejestrować te same ID w
  `lib/features/exercises/presentation/exercise_illustrations.dart`,
  zachowując wcześniejsze 96 oraz funkcję mapowania i deklarację assetów.
- Dockerowy target `verification` z `deploy/docker/web.Dockerfile`
  sprawdza wygenerowaną wersję, analizę i pełne testy. Rejestr, oczekiwania
  testu i pliki obejmują te same 102 ID, każdy obraz dekoduje się jako `512×512`.
- Dwa kadry, chwyty i pozycję względem drążka sprawdzać wizualnie;
  test dekodowania nie ocenia techniki ruchu ani czasu pauzy.
- `docs/exercise-illustrations-status.md`: sześć nowych wierszy po dwa
  kadry, sekcja „Dziesiąta partia”; stan 102 lokalne, 78 wydanych,
  24 niewydane z Partii 07–10, 214 brakujących na 316 ćwiczeń.
- Zachować wszystkie niecommitowane zmiany Partii 07–09 i dowody
  wcześniejszych wydań. Praca na aktualnym `main`, bez worktree.

## Warunki ukończenia

### Zapis wykonania

Użytkownik zatwierdził warianty `cw034/cw036` oraz wykonanie pakietu.
Etap czerwonego kontraktu i prompty przeszły przeglądy subagentów.
Limit ich użycia przerwał pracę przed pierwszą generacją; na prośbę
„dokończ” generację, kontrolę obrazów i końcową integrację wykonano
bezpośrednio w sesji. Nie przedstawiać tej kontroli jako dodatkowego
niezależnego przeglądu subagentowego. Pełna weryfikacja Dockerowa została
wykonana po integracji, a dokument statusu zawiera wynik i końcowe źródła.

Sześć WebP ma po dwa czytelne kadry, spójne chwyty i mocowania, a każdy
obraz przeszedł oba przeglądy. Rejestr, assety i test są zgodne, fallback
`cw037` działa, analiza i pełne testy Dockerowe są zielone. Dokumentacja
odróżnia przygotowany pakiet od wydanej produkcji `1.9.0+22`.
