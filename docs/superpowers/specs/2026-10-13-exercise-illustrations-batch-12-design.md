# Ilustracje ćwiczeń — projekt Partii 12

## Zakres i stan wejściowy

Partia obejmuje `cw043–cw048`: zwis martwy, aktywny zwis, podciąganie
łopatkowe oraz trzy warianty wiosłowania hantlami. Źródłem nazw i techniki
jest `assets/data/exercises.json`; nie zmieniać rekordów ani identyfikatorów.

Stan wejściowy: 108 lokalnych ilustracji = 78 wydanych + 30 niewydanych
z Partii 07–11; 208 ćwiczeń bez ilustracji spośród 316. Po integracji
Partii 12: 114 lokalnych = 78 wydanych + 36 niewydanych; 202 brakujące.
Produkcja pozostaje `1.9.0+22`. Dokumenty przygotowawcze nie uruchamiają
płatnych generacji, zmiany wersji, wdrożenia, commita ani pushu.

## Proponowana liczba kadrów i warianty

- `cw043` i `cw044`: po jednym kadrze. Są to statyczne utrzymania pozycji;
  nie dodawać fikcyjnej drugiej fazy ani timera.
- `cw045–cw048`: po dwa kadry obok siebie, czytane od lewej do prawej.
- `cw043–cw045`: nachwyt na szerokość barków, stały widok tylny 3/4
  ujawniający barki i górną część pleców. Dla `cw043` chwyt podaje katalog;
  dla `cw044/045` jest to przyjęty wariant ilustracyjny.
- `cw046`: pracuje anatomiczna prawa ręka z jednym hantlem; lewa dłoń
  i lewe kolano na ławce, prawa stopa na podłodze. Ta sama strona w obu fazach.
- `cw047/048`: dwa osobne hantle, neutralne chwyty, po jednym na dłoń.
- Czasy utrzymania zwisów opisuje katalog, nie obraz. Statyczne zdjęcie
  nie musi wizualnie odróżniać `cw044` od aktywnej fazy `cw045`.

## Kontrakt wspólny

- Jeden lokalny WebP `512×512` na ID, ze źródłowego PNG `1024×1024`.
- Styl `assets/exercises/cw256.webp`: kremowe tło, ciemny neutralny strój,
  twarz bez rysów, komiksowy kontur. Bez tekstu, numerów, timerów,
  etykiet, strzałek, watermarków i dodatkowych sylwetek. Nakładki mięśni
  nie są wymagane; nie oznaczać stawów lub zasłoniętych mięśni.
- Całe ciało, dłonie, stopy i niezbędny sprzęt mieszczą się w każdym kadrze.
  Przy dwóch fazach stała kamera, skala postaci, sprzęt i punkty podparcia.
- Drążek poziomy, zamocowany do stabilnej konstrukcji. W `cw043–cw045`
  obie stopy nad podłogą, bez asysty, stopnia lub obciążenia; łokcie proste.
- Ławki stabilne, bez przenikania przez ciało. Każda dłoń rzeczywiście
  obejmuje uchwyt swojego hantla. `cw046` ma jeden hantel, `cw047/048` dwa.
- Neutralna szyja i kontrolowane plecy; nie przedstawiać kopnięcia,
  huśtania, kołysania ani zmiany fazy przez przesunięcie kamery.
- Sprawdzać źródło oraz podgląd `512×512`; naturalne zasłonięcie dopuszczalne
  tylko wtedy, gdy anatomia, chwyt i istotne kontakty pozostają czytelne.

## Sceny i kryteria odrzucenia

### cw043 — Zwis martwy — 1 kadr

Pełna sylwetka w tylnym 3/4: nachwyt na szerokość barków, ramiona
wyprostowane, swobodny zwis. Naturalnie uniesione barki przy ramionach
nad głową; łopatki nie są aktywnie ściągane w dół i do tyłu. Tułów
kontrolowany bez bujania, nogi razem lub lekko skrzyżowane, stopy w powietrzu.

Odrzucić ugięte łokcie, aktywną depresję barków jak w `cw044`, stopy
dotykające podłogi jako regresję, dodatkowy kadr i timer.

### cw044 — Aktywny zwis — 1 kadr

Ten sam typ kamery i sprzętu: nachwyt na szerokość barków, łokcie
wyprostowane. Barki i łopatki aktywnie w dół i do tyłu, klatka lekko
otwarta, szyja ma większy odstęp od barków niż w martwym zwisie.
Tułów kontrolowany, stopy nad podłogą. Ciało uniesione jedynie niewielkim
ruchem łopatek, daleko od pozycji brodą nad drążkiem.

Odrzucić wzruszenie barków do uszu, ugięcie łokci, zwykłe podciągnięcie,
wymuszone duże wygięcie pleców, dwie fikcyjne fazy lub timer.

### cw045 — Podciąganie łopatkowe — 2 kadry

Stała kamera tylna 3/4 i nieruchomy drążek:
1. Rozluźniony zwis, ramiona proste, naturalnie uniesione barki.
2. Łopatki w dół i do tyłu, barki oddalone od uszu, klatka lekko otwarta,
   tułów nieznacznie wyżej. Łokcie nadal proste; chwyt i położenie drążka
   takie same. Ruch ma naturalnie mały zakres, nie wysokość podciągnięcia.

Odrzucić zginanie łokci, duże wzniesienie brody do drążka, dwie identyczne
pozycje barków, bujanie oraz ruch sprzętu zamiast postaci. Czas trzymania
nie odróżnia ilustracji; porównywać fazy z `cw043` i `cw044`.

### cw046 — Wiosłowanie hantlem jednorącz — 2 kadry

Stała kamera boczna 3/4 od strony prawej ręki roboczej:
1. Lewa dłoń i lewe kolano podparte na płaskiej ławce, prawa stopa na
   podłodze. Plecy płaskie, tułów blisko poziomu, neutralna szyja.
   Jeden hantel w prawej dłoni, ramię wydłużone pod barkiem, bez kontaktu
   ciężaru z podłogą lub ławką.
2. Prawy łokieć ciągnięty w tył przy tułowiu, hantel przy biodrze,
   kontrolowane ściągnięcie łopatki. Te same podpory i ustawienie tułowia.

Odrzucić dwa hantle, podpieranie się ręką roboczą, zmienioną stronę,
obrót lub podniesienie tułowia, shrug i uginanie bicepsa bez cofnięcia łokcia.

### cw047 — Wiosłowanie hantlami w opadzie — 2 kadry

Stała kamera boczna 3/4 pokazująca oba hantle, neutralne chwyty i plecy:
1. Stopy na szerokość bioder lub barków, całe podeszwy na podłodze,
   lekko ugięte kolana, zawias biodrowy, tułów około 45° względem podłogi.
   Dwa hantle pod barkami, ramiona wydłużone, plecy kontrolowane.
2. Hantle przyciągnięte ku biodrom, łokcie w górę i tył, około 45° od
   tułowia. Tułów zachowuje ten sam kąt i podparcie stóp.

Odrzucić zaokrąglone plecy, wyprost do stania przy podciągnięciu, ławkę
jako asystę, jeden wspólny hantel, kontakt ciężarów z podłogą i curl do barków.

### cw048 — Wiosłowanie hantlami z klatką opartą na ławce skośnej — 2 kadry

Stała kamera boczna 3/4 pokazująca podparcie klatki i oba hantle:
1. Leżenie przodem z klatką na oparciu ławki pod kątem 30–45°,
   twarz nad górnym końcem oparcia, neutralna szyja i wzrok w dół.
   Stopy stabilnie na podłodze; ramiona wolno zwisają z dwoma hantlami
   po zewnętrznych stronach ławki, bez kolizji z jej konstrukcją.
2. Łokcie w górę i tył, hantle w stronę bioder, łopatki kontrolowanie
   zbliżone. Klatka nadal oparta, ławka i podparcia niezmienne.

Odrzucić leżenie tyłem jak przy wyciskaniu, skośną ławkę zmieniającą kąt,
odrywanie klatki, unoszenie szyi, ciężary przenikające przez ławkę,
kołysanie i wzruszenie barkami.

## Generacja i przeglądy

Pierwsza próba każdego ID: `/tmp/opencode/cw256-reference.png`, świeży
katalog `/tmp/opencode/cwNNN-trial-NN`, jeden obraz przez
`tools/benchmark_exercise_images.py --single-sunburst-medium`.
Odczyt źródła i podglądu `512×512` przed następnym płatnym żądaniem.
Korekta tylko nazwanego defektu, z ostatnim odrzuconym PNG jako jedyną
referencją i świeżym katalogiem. Po dwóch nieskutecznych korektach tego
samego problemu zatrzymać płatne próby i ocenić nowe ujęcie. Bez
automatycznych retry po niepewnym wyniku API.

Porównać barki `cw043/cw044` oraz obie fazy `cw045`; nie wymagać
sztucznych symboli rozróżniających statyczne utrzymanie i ruch.
Porównać podpory i liczbę hantli `cw046/cw047/cw048`. Nie akceptować
samych zmienionych dłoni przy niezmienionych łokciach jako pełnego wiosła.
Przegląd zgodności poprzedza kontrolę jakości i anatomii. Jeśli subagenci
są niedostępni, zapisać bezpośrednią kontrolę zamiast deklarować niezależny review.

## Integracja i ukończenie

Test oczekiwanych ID otrzymuje `cw043–cw048` po `cw042`, przed `cw251`;
fallback braku ilustracji przenieść z `cw043` na `cw049`. Czerwony kontrakt
ma wskazywać brak `cw043`. Po akceptacji wszystkich sześciu źródeł:
konwersja `-resize 512x512 -strip -quality 90`, te same wpisy w rejestrze,
Dockerowy target `verification` z analizą i pełnymi testami. Rejestr,
oczekiwania i katalog zawierają 114 ID, każdy obraz dekoduje się jako `512×512`.

Dokument statusu: sześć wierszy, kadry `1/1/2/2/2/2`, sekcja „Dwunasta partia”,
114 lokalnych / 78 wydanych / 36 niewydanych z Partii 07–12 / 202 brakujące
na 316 ćwiczeń. Zachować wszystkie istniejące pakiety i dowody wydań.
Praca na aktualnym `main`, bez worktree, wersja produkcyjna `1.9.0+22`.
Generacja i publikacja wymagają osobnej decyzji; żadnych automatycznych operacji Git.

## Zapis wykonania

Użytkownik zatwierdził zakres oraz po jednym kadrze dla statycznych zwisów.
Pakiet wykonano bezpośrednio w sesji, z odczytem źródeł i podglądów
przed kolejnym pojedynczym żądaniem. Jedyna korekta dotyczyła zbyt
subtelnej aktywnej fazy `cw045`; pozostałe źródła zaakceptowano z pierwszych
prób. Końcowe źródła, koszty i wynik zielonego Dockerowego targetu
`verification` zapisano w dokumencie statusowym. Nie deklarować dodatkowych
niezależnych przeglądów subagentowych; nie zmieniono wersji ani produkcji.
