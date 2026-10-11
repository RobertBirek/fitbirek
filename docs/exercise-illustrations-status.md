# Status ilustracji ćwiczeń

Stan na 2026-10-11, wersja webowa 1.4.9+16.

## Wydane ilustracje

| ID | Ćwiczenie | Kadry | Status |
|---|---|---:|---|
| cw256 | Rozciąganie bioder 90/90 | 2 | Wydane w 1.3.1+6; referencja stylu serii. |
| cw257 | Rozciąganie motylkowe | 1 | Wydane w 1.4.6+13. |
| cw261 | Rozciąganie mięśnia czworogłowego uda w staniu | 1 | Wydane w 1.4.4+11; pomarańcz oznacza czworogłowy. Nie oznaczono zasłoniętego stabilizatora biodra. |
| cw251 | Pozycja kobry | 2 | Wydane w 1.4.9+16. |
| cw252 | Pozycja dziecka | 2 | Wydane w 1.4.9+16. |
| cw253 | Pies z głową w dół | 2 | Wydane w 1.4.9+16. |
| cw262 | Rozciąganie tylnej części uda w staniu z nogą na podwyższeniu | 2 | Wydane w 1.4.9+16. |
| cw264 | Rozciąganie łydki przy ścianie | 2 | Wydane w 1.4.6+13. |
| cw265 | Rozciąganie klatki piersiowej w futrynie | 2 | Wydane w 1.4.3+10; pomarańcz oznacza prawy piersiowy większy. |
| cw278 | Przenoszenie gumy nad głową | 3 | Wydane w 1.4.7+14; świadoma zmiana kamery z front 3/4 na rear 3/4, z gumą za biodrami w ostatnim panelu. |

`assets/exercises/`, `illustratedExerciseIds` i testy ilustracji są wspólnym
rejestrem tych trzech zasobów. Każdy nowy plik WebP wymaga wpisu w rejestrze,
dekodowania 512×512 oraz kontroli braku osieroconych plików.

## Pierwsza partia

Zakres pierwszej partii obejmuje `cw251–cw267`, `cw273`, `cw274` i
`cw276–cw281`. Do przygotowania pozostaje 15 zasobów. `cw279` jest wstrzymane:
opis nie określa wysokości kotwy gumy ani ustawienia ramienia.

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
opisują historyczne próby. Ten plik określa stan wydanych zasobów.
