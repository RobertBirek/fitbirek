# Rozszerzenie katalogu i filtrowanie — zatwierdzony projekt

Użytkownik zatwierdził: rozszerzenie tai chi na krześle, jogi, kalisteniki,
sandbag z uchwytami (posiadane20kg) i podwójne kółko Gymtek z matą.
Bez działu karate. Zachować cw001–cw316, historię i ulubione; nowe ID odcw317.
Źródłem ćwiczeń pozostaje XLSX→tools/xlsx_to_json.py→JSON, nigdy edycjaSQLite.

## Wyszukiwanie

Styl, sprzęt i mięśnie główne+wspierające; OR wewnątrz grupy, AND między
grupami. Dostępność opcji liczona z pozostałymi filtrami (bez własnej grupy),
query i ulubionymi. Ukrywać niedostępne niezaznaczone opcje; zaznaczone
pozostają usuwalne. Liczniki unikalnych ćwiczeń, nie liczby tagów.
Wyszukiwanie wielowyrazowe AND po nazwachPL/EN, aliasach, stylach, sprzęcie,
mięśniach, bez znaków diakrytycznych; taichi/tai chi wspólny alias.
Wyraźnie oddzielić mięśnie od Cardio/Mobilność, które nie są mięśniami.

## Klasyfikacja offline bez migracji danych ćwiczeń

Osobny wersjonowany asset assets/data/exercise_catalog_metadata.json:
schemaVersion=1; styles i muscles to listy {id,label,aliases}; exercises to
mapa ID→{styles,primaryMuscles,secondaryMuscles,aliases,tracking,unilateral}.
tracking: reps/time/rounds. Każde ćwiczenie ma wpis, mięśnie i style mogą się
nakładać. Dane klasyfikacji edytowane przez wersjonowany pipeline narzędzi,
nie zgadywane w runtime po nazwach. Modele prostego indeksu w oddzielnym
module domain, bez rozszerzania Freezed Exercise/Drift Exercises.

## Rejestrowanie

reps: powtórzenia i opcjonalny ciężar tylko dla obciążeń; time: sekundy;
rounds: runda zapisana jako czas pracy (sekundy), bez wymuszania kilogramów.
Jednostronne ćwiczenia umożliwiają jawny wybór lewa/prawa/obie; pole side
opcjonalne w wire, wartości left/right/both. Stare serie bez side zachowują
dotychczasowe znaczenie. Wymagane trwałe przechowanie, backup/restore i sync;
nie kodować strony w exerciseId, ciężarze, nazwie lub powtórzeniach.
Nie zmieniać niezmiennych payloadów prób synchronizacji.

## Granice

Planowane56 nowych pozycji:16sandbag,5kółko,16joga,15kalistenika,
4zweryfikowane niedublujące tai chi siedzące. Liczba może zostać zmniejszona
po kontroli duplikatów/źródeł; jakość ma pierwszeństwo nad liczbą.
Wszystkie nowe opisy zawierają źródło, technikę, błędy, progresję/regresję.
Nie zakładać taśm na stopy ani mechanizmu powrotnego kółka; standing rollout
tylko zaawansowana progresja. Nie przypisywać wszystkim ruchom sandbaga20kg.
Ilustracje sekwencyjnie według dotychczasowego kontraktu, osobne ledgery.
Bez nowych szablonów treningu/zamienników/statystyk tygodniowych w tym etapie.
Bez commita/pusha/wersji/wdrożenia bez odrębnej prośby.
