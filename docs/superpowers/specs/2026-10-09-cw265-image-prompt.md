# cw265 — scenariusz i prompt przed kolejnym generowaniem

Status: dokument historyczny. Końcowa ilustracja cw265 została wydana w 1.4.3+10;
jej stan i kryteria kolejnych zasobów opisuje `docs/exercise-illustrations-status.md`.
Referencja stylu: `assets/exercises/cw256.webp`; nie kopiujemy pozy ćwiczenia.

## Decyzje kompozycyjne

- Jeden kwadratowy obraz, dwa kadry obok siebie, wynik 512×512 WebP.
- Ta sama postać, kamera i skala. Pełna sylwetka z marginesem pod stopami.
- Kamera na wysokości mostka, lekko od anatomicznie lewej strony postaci,
  przez otwór drzwiowy. Widoczny przód prawej części klatki i powierzchnia podpory.
- Podpora to szeroka wewnętrzna powierzchnia głębokiego ościeża, nie cienka
  krawędź listwy. Powierzchnia biegnie w głąb przejścia i jest skierowana do otworu.
- Prawe przedramię i dłoń podparte w obu kadrach; łokieć w przybliżeniu na
  wysokości barku, zgięty około 90°. Kontakt pokazany wspólną granicą i cieniem
  styku, a nie oczekiwaniem widoczności zasłoniętej skóry.
- Drugi kadr: małe przeniesienie ciężaru na przednią nogę. Nieruchome podparcie
  ogranicza tor barku; nie żądamy jednocześnie dużej translacji, identycznych
  kątów i identycznego położenia wszystkich części ciała.
- Pomarańczowy prawy piersiowy większy: czytelny wachlarz od mostka/obojczyka
  ku ramieniu. Bez dekoracyjnego turkusu w biernym podpartym rozciąganiu.

## Prompt do pojedynczej próby

```text
Create ONE square comic exercise illustration with TWO side-by-side panels
separated by a thin vertical line. Use the attached cw256 image only as the
reference for the character, cream background, charcoal outlines, flat shading,
dark athletic shirt and muted shorts. Show the entire person including both
feet with a small clear margin in each panel. No text or labels.

Exercise: right-sided doorway pectoral stretch. The support is a deep rectangular
door jamb beside the man's RIGHT arm. Its broad INNER face extends into the
doorway and faces the open passage. Show this supporting surface as a visible
plane, not a narrow decorative edge.

Use the same level camera at sternum height, slightly to the man's LEFT of a
frontal view, looking through the open passage. Keep his front chest and the
supporting jamb surface visible. His right arm appears on the viewer's left.

LEFT PANEL — SETUP: relaxed staggered stance, upright torso. Right upper arm
extends sideways, elbow approximately at shoulder height and bent about 90
degrees. The right forearm is vertical. The forearm from elbow to wrist and the
palm rest against the same broad inner jamb surface. Make the contact clear
with an uninterrupted contact boundary and a subtle contact shadow. Left arm
hangs relaxed.

RIGHT PANEL — GENTLE STRETCH: same camera, same jamb and same forearm contact
location. Transfer a little weight onto the front foot, advancing the chest
slightly through the doorway. Allow the shoulder to follow a small natural arc
around the supported elbow while maintaining natural arm length and comfortable
joint angles. Keep torso and pelvis aligned, shoulder relaxed, and back neutral.
A small arrow beside the waist shows the forward body shift; the raised arm
does not move up between panels.

In both panels, overlay the RIGHT pectoralis major through the shirt in
translucent orange: a bounded anatomical fan extending from the right side of
the sternum and medial clavicle toward the upper arm beside the armpit, with
three fine fiber lines converging laterally. Keep it on the right chest, not
across the midline or on the abdomen. No other muscle color is needed for this
supported passive stretch. Preserve the reference's simple comic character
instead of a photorealistic anatomical rendering.
```

## Kontrola przed wysłaniem

- Jednoznaczne rozróżnienie strony anatomicznej i strony obrazu.
- Opisana płaszczyzna kontaktu i położenie kamery, nie tylko słowo „futryna”.
- Oddzielone elementy nieruchome od zmiany pomiędzy kadrami.
- Bez żądania sztywnego kąta przy dowolnym przemieszczeniu barku.
- Bez konfliktu pomiędzy „zachowaj wszystkie piksele” a zmianą geometrii.
- Jedna próbka, brak automatycznych ponowień; nie uruchamiać całej partii.

## Kryteria odrzucenia wyniku

1. Oparcie wyłącznie dłoni, widoczna szczelina pomiędzy podporą a przedramieniem.
2. Zmiana strony ciała, dodatkowa kończyna lub nienaturalnie wydłużone ramię.
3. Podnoszenie ręki zamiast pokazania przeniesienia ciężaru tułowia.
4. Rozmyta plama zamiast obszaru mięśnia piersiowego albo kolor poza nim.
5. Ucięte stopy, nieczytelność po zmniejszeniu do 512×512 lub odejście od stylu.

Przegląd promptu nie gwarantuje poprawnego obrazu. Po jednej próbie ocenić
wynik względem tych kryteriów; nie ponawiać płatnego żądania bez rozpoznania
konkretnej przyczyny błędu i zaplanowanej zmiany.
