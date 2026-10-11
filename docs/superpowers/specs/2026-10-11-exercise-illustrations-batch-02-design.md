# Ilustracje ćwiczeń - partia 02

## Zakres

Partia obejmuje 32 nieilustrowane ćwiczenia `cw282-cw313`, bez zmian danych
katalogu, identyfikatorów, schematu bazy, synchronizacji ani układu UI.

- `cw282-cw301`: regeneracja i Tai Chi wykonywane w siadzie na krześle.
- `cw302-cw313`: ćwiczenia siłowe i dynamiczne z hantlami lub masą własnego
  ciała.

Po zaakceptowaniu wszystkich assetów następuje jedna integracja i jedno
wdrożenie web-only.

## Kontrakt Wizualny

- Jeden `assets/exercises/cwNNN.webp` na ćwiczenie, `512x512`, od jednego do
  czterech kadrów.
- `assets/exercises/cw256.webp` pozostaje wzorcem stylu: kremowe tło, ciemny
  neutralny strój i wyraźny komiksowy kontur.
- Grafiki nie zawierają tekstu, numerów, etykiet, znaków wodnych ani ozdobnych
  linii kierunkowych. Wyjątkiem jest `cw299`: małe zakrzywione strzałki
  wyłącznie przy miednicy oznaczają kierunek krążenia.
- Pomarańcz oznacza główny cel anatomiczny, turkus istotne widoczne mięśnie
  wspierające. W pozycjach biernych turkus jest opcjonalny.
- Nie oznaczamy stawów, ścięgien, nerwów ani kręgów jako mięśni.

## Metoda Generacji

Proste pozycje powstają z jednoznacznego promptu i referencji stylu `cw256`.
Dla ruchów złożonych `cw303-cw308`, `cw310` i `cw313` pierwszy odrzucony
wariant może stać się jedyną referencją punktowej korekty pozycji. Prompt
zachowuje zatwierdzone elementy, nazywa widoczny błąd i określa jego zamianę;
finalna grafika nadal jest oceniana względem kontraktu serii.

Każde ćwiczenie ma własny prompt i pojedyncze generowanie Sunburst medium.
Odrzucone próby nie trafiają do katalogu assetów. Po pięciu odrzuconych próbach
stosowany jest przeprojektowany prompt, a nie automatyczne powtarzanie tego
samego żądania.

## Grupy Scen

| ID | Scena i liczba kadrów | Punkty kontroli |
|---|---|---|
| cw282 | Otwarcie klatki w siadzie, 2 | Pionowy siad, luźne barki, otwarcie i powrót ramion. |
| cw283 | Dłonie jak chmury, 3 | Naprzemienne dłonie przed tułowiem, lekka rotacja, wzrok za dłonią. |
| cw284 | Chwytanie wróblego ogona, 4 | Czytelne fazy ward off, roll back, press i push. |
| cw285 | Falowanie dłońmi jak chmurami, 3 | Odmienny od cw283 układ dłoni oraz płynna rotacja. |
| cw286 | Rozdzielanie grzywy konia, 3 | Jedna dłoń w górę i bok, druga w dół; zmiana stron. |
| cw287 | Złoty kogut, 2 | Uniesione kolano, przeciwna ręka wysoko, pionowy tułów. |
| cw288 | Omiatanie kolana, 3 | Dłoń przy udzie i przeciwna dłoń wypychająca na wysokości klatki. |
| cw289 | Pojedynczy bicz, 2 | Dłoń w bok, druga w charakterystycznym układzie dłoni, kontrolowana rotacja. |
| cw290 | Skręt tułowia w siadzie, 2 | Wydłużenie kręgosłupa i chwyt oparcia bez forsowania. |
| cw291 | Cat-cow w siadzie, 2 | Wyraźnie różne fazy wyprostu i zaokrąglenia całych pleców. |
| cw292 | Skłon w przód w siadzie, 2 | Stopy na podłodze, skłon z bioder i rozluźniona szyja. |
| cw293 | Gołąb w siadzie, 2 | Figura 4 bez dociskania kolana, długie plecy w skłonie. |
| cw294 | Skłon boczny w siadzie, 2 | Ręka nad głową, bez skrętu tułowia. |
| cw295 | Boczne rozciąganie szyi, 2 | Bark nisko; dłoń tylko lekko asystuje przy skroni. |
| cw296 | Krążenia barków, 2 | Duże, spokojne koła w przód i w tył. |
| cw297 | Ramiona orła, 2 | Skrzyżowane ramiona, dłonie lub grzbiety dłoni razem, łokcie na wysokości barków. |
| cw298 | Krążenia kostek, 2 | Uniesiona stopa i czytelne koło w obu kierunkach. |
| cw299 | Krążenia bioder, 2 | Stabilny siad na brzegu krzesła, ruch inicjowany miednicą; mała zakrzywiona strzałka przy miednicy wskazuje kierunek. |
| cw300 | Oddech kwadratowy, 1 | Spokojny pionowy siad z dłońmi na udach; bez wizualizacji czasu i zatrzymania oddechu. |
| cw301 | Oddech przeponowy, 1 | Siad; jedna dłoń na klatce, druga na brzuchu. |
| cw302 | Przysiad z wyciskaniem hantli, 3 | Rack, przysiad, stabilny lockout nad głową. |
| cw303 | Pompka, wiosłowanie, thruster, 4 | Szerokie stopy, plank bez rotacji, ruchy stron i końcowy przysiad z wyciskaniem. |
| cw304 | Burpee z rwaniem dwóch hantli, 4 | Kontrolowana pozycja dolna, bezpieczne przejście i lockout. |
| cw305 | Zarzut hantli z wyciskaniem, 3 | Napęd biodrami, rack, wyciskanie; bez ciągnięcia rękami. |
| cw306 | Rwanie hantla jednorącz, 3 | Hantel między stopami, hip hinge, stabilna ręka nad głową. |
| cw307 | Wymach hantlem oburącz, 2 | Hinge zamiast przysiadu; neutralny kręgosłup i ciężar do wysokości barków. |
| cw308 | Wstawanie tureckie z hantlem, 4 | Hantel nad barkiem i wzrok na ciężarze w każdej pokazanej fazie. |
| cw309 | Przysiad, curl, wyciskanie, 3 | Rozdzielone fazy, stabilne kolana i kontrolowany powrót. |
| cw310 | Wiosłowanie w podporze z pompką, 3 | Plank na hantlach, szerokie stopy i biodra bez rotacji. |
| cw311 | Wykrok z curlem, 2 | Kolano zgodne z kierunkiem stopy, strony naprzemiennie. |
| cw312 | RDL z wiosłowaniem, 3 | Hinge, neutralny kręgosłup, wiosłowanie ku biodrom. |
| cw313 | Chód niedźwiedzia z pompkami, 4 | Niski crawl, napięty brzuch, pompka bez zapadania bioder. |

## Integracja I Weryfikacja

1. Po akceptacji grafika jest konwertowana do WebP `512x512` i sprawdzana pod
   kątem dekodowania.
2. Jednocześnie aktualizowane są `illustratedExerciseIds`, kontrakt testowy i
   `docs/exercise-illustrations-status.md`.
3. Wersja jest zwiększana zgodnie z `AGENTS.md`, a
   `lib/app/app_version.g.dart` generowany z `pubspec.yaml`.
4. Weryfikacja obejmuje testy ilustracji i pełny Dockerowy target
   `verification`.
5. Po zachowaniu rollbacku wdrażany jest wyłącznie nowy obraz `web`; API,
   PostgreSQL i `push-sender` pozostają bez zmian.

## Kryteria Akceptacji

- Wszystkie 32 ID mają jeden lokalny WebP i jednoznaczny wpis w rejestrze.
- Każdy kadr komunikuje właściwy ruch bez mylenia wariantu, strony lub fazy.
- Ruchy złożone zachowują kluczowe warunki bezpieczeństwa opisane w tabeli.
- Żaden asset nie wymaga żądania do API podczas używania aplikacji offline.
