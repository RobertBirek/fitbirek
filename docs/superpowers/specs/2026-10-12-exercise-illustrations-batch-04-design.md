# Ilustracje ćwiczeń - partia 04

## Zakres

Partia domyka luki w obecnej serii mobilizacji: `cw268-cw272` oraz `cw275`.
Nie zmienia katalogu ćwiczeń, identyfikatorów, bazy danych, synchronizacji ani
układu UI. Po akceptacji wszystkich sześciu assetów następuje jedna integracja
i jedno wdrożenie web-only w wersji `1.8.0+21`.

## Kontrakt wizualny

- Jeden `assets/exercises/cwNNN.webp` na ćwiczenie, `512x512`, dwa kadry.
- `assets/exercises/cw256.webp` pozostaje wzorcem stylu: kremowe tło, ciemny
  neutralny strój, bez twarzy i wyraźny komiksowy kontur.
- Bez tekstu, numerów, etykiet, znaków wodnych i strzałek kierunkowych.
- Pomarańcz opisuje cel anatomiczny, a turkus widoczne wsparcie; nie oznaczamy
  stawów, ścięgien, nerwów ani kręgów jako mięśni.

## Sceny i bezpieczeństwo

| ID | Scena | Punkty kontroli |
|---|---|---|
| `cw268` | Siedzący cat-cow: otwarcie klatki, następnie zaokrąglenie całych pleców. | Ruch obejmuje kręgosłup piersiowy, a nie wyłącznie odcinek lędźwiowy. |
| `cw269` | Neutralna szyja, następnie mały kontrolowany łuk przód-bok. | Brak mocnego odchylenia głowy w tył, barki pozostają rozluźnione. |
| `cw270` | Profil: neutralna postawa, następnie poziome cofnięcie brody. | Głowa przesuwa się do tyłu bez skłonu i bez unoszenia brody. |
| `cw271` | Krążenie barków: faza do przodu, potem uniesienie i cofnięcie. | Wyprostowany tułów, duży lecz spokojny zakres. |
| `cw272` | Ręce przed tułowiem w dwóch odmiennych pozycjach krążenia nadgarstków. | Ruch pochodzi z nadgarstków, bez obciążenia i bez wymuszonego zakresu. |
| `cw275` | Stabilny siad z uniesioną stopą w dwóch przeciwnych pozycjach krążenia kostki. | Stopa jest wyraźnie uniesiona, a ruch izolowany do kostki. |

Każdy asset powstaje z osobnego promptu i jednego żądania Sunburst medium z
referencją `cw256`. Punktowa korekta używa odrzuconego draftu jako jedynej
referencji wyłącznie po nazwaniu błędu pozycji.

## Integracja i weryfikacja

1. Test rejestru najpierw otrzymuje sześć ID, a produkcyjny rejestr pozostaje
   niezmieniony do akceptacji assetów.
2. Zatwierdzone PNG są konwertowane do WebP `512x512`; test sprawdza rejestr,
   kompletność katalogu i dekodowanie każdego pliku.
3. Aktualizowane są rejestr, status, changelog, `pubspec.yaml` oraz wygenerowany
   `lib/app/app_version.g.dart`.
4. Weryfikacja obejmuje pełny Dockerowy target `verification`, runtime i
   publiczną kontrolę wersji, assetów oraz artefaktów Web SQLite.
5. Wdrożenie zachowuje rollback bieżącego obrazu i odtwarza wyłącznie `web`.

## Kryteria akceptacji

- `cw268-cw272` i `cw275` mają po jednym lokalnym WebP oraz wpisie w rejestrze.
- Każdy kadr komunikuje bezpieczny wariant ruchu opisany w tabeli.
- Nie ma brakujących ani osieroconych plików; każdy asset dekoduje się jako
  `512x512`.
- Publiczna wersja to `1.8.0+21`, a assety pozostają dostępne offline.
