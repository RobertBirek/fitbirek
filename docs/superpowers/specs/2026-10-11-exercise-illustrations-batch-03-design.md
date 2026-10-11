# Ilustracje ćwiczeń - partia 03

## Zakres

Partia obejmuje ostatnie trzy nieilustrowane ćwiczenia katalogu: `cw314-cw316`.
Nie zmienia danych katalogu, identyfikatorów, schematu bazy, synchronizacji ani
układu UI. Po akceptacji wszystkich trzech assetów następuje jedna integracja i
jedno wdrożenie web-only w wersji `1.7.0+20`.

## Kontrakt wizualny

- Jeden `assets/exercises/cwNNN.webp` na ćwiczenie, `512x512`, od trzech do
  czterech kadrów.
- `assets/exercises/cw256.webp` pozostaje wzorcem stylu: kremowe tło, ciemny
  neutralny strój, faceless adult i wyraźny komiksowy kontur.
- Grafiki nie zawierają tekstu, numerów, etykiet, znaków wodnych, strzałek ani
  ozdobnych linii kierunkowych.
- Pomarańcz oznacza główny cel anatomiczny, a turkus widoczne mięśnie
  wspierające; nie oznaczamy stawów, ścięgien, nerwów ani kręgów jako mięśni.

## Sceny i bezpieczeństwo

| ID | Scena i liczba kadrów | Punkty kontroli |
|---|---|---|
| `cw314` | 3: hantle w racku, głęboki przysiad, pionowy lockout | Hantle nad barkami, kolana zgodne ze stopami, neutralny kręgosłup, bez przeprostu lędźwi w lockoucie. |
| `cw315` | 4: start pod drążkiem, burpee/plank, zwis po wyskoku, podciągnięcie | Stabilny plank i pełne burpee, wyraźny drążek, broda nad drążkiem, bez kippingu. |
| `cw316` | 3: farmer carry, suitcase carry z obciążeniem po lewej, suitcase carry z obciążeniem po prawej | Wyprostowany tułów, obciążenie po stronie opisanej przez kadr, brak pochylenia ku hantlowi i stabilny krok. |

Każda scena powstaje z osobnego promptu i pojedynczego żądania Sunburst medium
z referencją `cw256`. Po odrzuceniu poprawka używa odrzuconego draftu jako
jedynej referencji wyłącznie dla nazwanego błędu pozycji, przy zachowaniu
zaakceptowanego stylu i faz ruchu.

## Integracja i weryfikacja

1. Test rejestru najpierw otrzymuje `cw314-cw316`, a produkcyjny rejestr
   pozostaje niezmieniony do akceptacji assetów.
2. Zaakceptowane PNG są konwertowane do WebP `512x512`; test sprawdza rejestr,
   obecność plików i dekodowanie każdego assetu.
3. Wspólnie aktualizowane są `illustratedExerciseIds`, status ilustracji,
   changelog, `pubspec.yaml` oraz wygenerowany `lib/app/app_version.g.dart`.
4. Weryfikacja obejmuje pełny Dockerowy target `verification`, inspekcję
   runtime i publiczną kontrolę wersji, assetów oraz artefaktów Web SQLite.
5. Wdrożenie zachowuje rollback aktualnego `web` i odtwarza tylko usługę
   `web`; API, PostgreSQL i `push-sender` pozostają nietknięte.

## Kryteria akceptacji

- `cw314`, `cw315` i `cw316` mają po jednym lokalnym WebP oraz wpisie w
  rejestrze.
- Każdy kadr komunikuje prawidłowy ruch i spełnia przypisane warunki techniki.
- Nie występują brakujące lub osierocone pliki, a każdy asset dekoduje się jako
  `512x512`.
- Publiczna wersja to `1.7.0+20`, a nowe assety są dostępne bez żądań do API,
  także podczas działania offline.
