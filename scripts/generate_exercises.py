#!/usr/bin/env python3
"""
Generator rozszerzenia bazy ćwiczeń FitBirek: 38 -> 316.

Ćwiczenia grupowane są w "rodziny" (np. warianty pompek, warianty
podciągania) - każda rodzina ma współdzielone kluczowe wskazówki i częste
błędy (bo dotyczą tego samego wzorca ruchu), plus każdy wariant ma własną,
dodatkową wskazówkę/błąd specyficzny dla tego wariantu.

Uruchomienie:
    python3 scripts/generate_exercises.py

Efekt: assets/data/exercises.json zawiera 316 ćwiczeń (38 oryginalnych +
278 nowych), id ciągle numerowane cw001..cw316, bez duplikatów nazw/id.
"""

import json
import os

ZRODLO_NOWE = "Starter pack FitBirek — rozszerzenie 316"

# Lista wszystkich nowych ćwiczeń (wypełniana przez add_family per kategoria)
NEW_EXERCISES = []


def add_family(
    partia_glowna,
    partie_wspierajace,
    sprzet,
    typ,
    wzorzec,
    wskazowki_bazowe,
    bledy_bazowe,
    variants,
):
    """
    variants: lista tupli
      (nazwaPl, nazwaEn, poziom, seriexPowtorzenia, tempo,
       progresja, regresja, extra_wskazowka, extra_blad)
    Opcjonalnie 10-ty element: override sprzet (lista) dla danego wariantu.
    """
    for v in variants:
        nazwa_pl, nazwa_en, poziom, serie, tempo, prog, regres, extra_w, extra_b = v[:9]
        sprzet_final = v[9] if len(v) > 9 else sprzet
        wskazowki = list(wskazowki_bazowe) + ([extra_w] if extra_w else [])
        bledy = list(bledy_bazowe) + ([extra_b] if extra_b else [])
        NEW_EXERCISES.append(
            {
                "nazwaPl": nazwa_pl,
                "nazwaEn": nazwa_en,
                "partiaGlowna": partia_glowna,
                "partieWspierajace": partie_wspierajace,
                "sprzet": sprzet_final,
                "typ": typ,
                "poziom": poziom,
                "wzorzecRuchu": wzorzec,
                "seriexPowtorzenia": serie,
                "tempo": tempo,
                "kluczoweWskazowki": wskazowki,
                "czesteBledy": bledy,
                "progresja": prog,
                "regresja": regres,
                "zrodlo": ZRODLO_NOWE,
                "ulubione": False,
            }
        )


# ======================================================================
# KLATKA (docelowo +28)
# ======================================================================

add_family(
    "Klatka", ["Triceps", "Barki", "Brzuch"], ["Masa własna"], "Siłowe",
    "Poziome wypychanie",
    [
        "Ciało w jednej linii od głowy do stóp przez cały ruch",
        "Napięty brzuch i pośladki, bez zapadania lędźwi",
        "Pełny zakres ruchu — klatka blisko podłoża na dole",
    ],
    [
        "Opadanie bioder (brak napięcia core)",
        "Niepełny zakres ruchu",
    ],
    [
        ("Pompki szerokie", "Wide-grip push-up", "Średni", "4 x 10-12", "2-0-1-0",
         "Pompki diamentowe", "Pompki na kolanach (chwyt szeroki)",
         "Dłonie szerzej niż barki — większe zaangażowanie klatki, mniejsze triceps",
         "Zbyt szerokie rozstawienie obciąża stawy barkowe — nie przesadzaj"),
        ("Pompki hindu", "Hindu push-up (dive bomber)", "Zaawansowany", "3 x 8-10", "3-0-1-1",
         "Pompki hindu z podskokiem", "Pompki klasyczne",
         "Ruch po łuku — od pozycji psa z opuszczoną głową do wyprostu w górę jak kobra",
         "Zbyt szybkie tempo bez kontroli w dolnej fazie"),
        ("Pompki archer", "Archer push-up", "Zaawansowany", "3 x 6-8/stronę", "2-1-1-0",
         "Pompki na jednej ręce (asysta)", "Pompki szerokie",
         "Jedna ręka pod barkiem, druga wyprostowana na boku — przesuwaj ciężar na ramię robocze",
         "Skręcanie tułowia zamiast czystego przesunięcia ciężaru"),
        ("Pompki plyometryczne (clap)", "Clap push-up", "Zaawansowany", "3 x 5-6", "wybuchowo",
         "Clap push-up z podwójnym klaśnięciem", "Pompki klasyczne",
         "Wybuchowe odbicie od podłoża — ląduj miękko z ugiętymi łokciami",
         "Lądowanie na wyprostowanych, zablokowanych łokciach (ryzyko urazu)"),
        ("Pompki na kolanach", "Knee push-up", "Początkujący", "3 x 12-15", "2-0-1-0",
         "Pompki klasyczne (na stopach)", "Pompki przy ścianie",
         "Kolana pod biodrami, ciało w linii od kolan do głowy",
         "Wypychanie bioder do góry, żeby 'oszukać' pełny zakres"),
        ("Pompki przy ścianie", "Wall push-up", "Początkujący", "3 x 15-20", "2-0-1-0",
         "Pompki na kolanach", "—",
         "Dobry punkt startowy przy ograniczonej sile górnej części ciała",
         "Zbyt małe odchylenie od ściany (za mały zakres ruchu)"),
        ("Pompki ze stopami na podwyższeniu", "Decline push-up", "Zaawansowany", "4 x 10-12", "2-0-1-0",
         "Pompki plyometryczne ze stopami na podwyższeniu", "Pompki klasyczne",
         "Im wyżej stopy, tym większe obciążenie górnej części klatki i barków",
         "Zbyt duże wygięcie w lędźwiach przy wysokim podwyższeniu"),
    ],
)

add_family(
    "Klatka", ["Triceps", "Barki"], ["Hantle", "Ławeczka"], "Siłowe",
    "Poziome wypychanie (skos)",
    [
        "Łopatki ściągnięte i przyklejone do ławki przez cały ruch",
        "Stopy płasko na podłodze, napięte pośladki i core",
        "Kontrolowane opuszczanie hantli do wysokości klatki",
    ],
    [
        "Odrywanie bioder od ławki (mostek)",
        "Zbyt szybkie, niekontrolowane opuszczanie ciężaru",
    ],
    [
        ("Wyciskanie hantli skos dodatni", "Incline dumbbell press", "Średni", "4 x 8-10", "2-1-1-0",
         "Wyciskanie hantli skos dodatni z pauzą 2s", "Wyciskanie hantli leżąc (płasko)",
         "Ławka pod kątem 30-45° — większe zaangażowanie górnej klatki",
         "Zbyt duży kąt ławki (>45°) przesuwa pracę na barki"),
        ("Wyciskanie hantli skos ujemny", "Decline dumbbell press", "Zaawansowany", "3 x 10-12", "2-0-1-0",
         "Wyciskanie hantli skos ujemny z pauzą 2s", "Wyciskanie hantli leżąc (płasko)",
         "Mocowanie stóp na ławce decline lub asysta partnera",
         "Zbyt szybkie tempo przy nietypowej pozycji ciała"),
        ("Floor press hantlami", "Dumbbell floor press", "Początkujący", "3 x 10-12", "2-0-1-1",
         "Wyciskanie hantli leżąc na ławeczce", "Wyciskanie jednego hantla na leżąco",
         "Łokcie dotykają podłogi na dole — naturalny stopper chroniący staw barkowy",
         "Zbyt szeroki rozstaw łokci przy dotyku podłogi", ["Hantle"]),
        ("Wyciskanie jednego hantla (single-arm)", "Single-arm dumbbell floor press", "Średni", "3 x 8-10/stronę", "2-1-1-0",
         "Wyciskanie jednego hantla z uniesioną wolną nogą", "Floor press hantlami (dwie ręce)",
         "Napięty core stabilizuje tułów przeciw rotacji przy pracy jedną ręką",
         "Rotacja tułowia w stronę pracującej ręki", ["Hantle"]),
        ("Wyciskanie hantli chwyt neutralny", "Neutral-grip dumbbell press", "Średni", "4 x 10-12", "2-0-1-0",
         "Neutralny chwyt skos dodatni", "Wyciskanie hantli chwyt neutralny (mniejszy ciężar)",
         "Dłonie zwrócone do siebie przez cały ruch — łagodniejsze dla barków",
         "Zbyt lekki ciężar niewykorzystujący pełnego zakresu siły"),
        ("Pullover hantlem", "Dumbbell pullover", "Zaawansowany", "3 x 12-15", "3-0-2-0",
         "Pullover hantlem z większym zakresem", "Pullover hantlem z mniejszym ciężarem",
         "Ruch tylko w stawie barkowym — łokcie lekko ugięte, stałe",
         "Zgięcie łokci jak przy wyciskaniu triceps (zmiana wzorca ruchu)"),
        ("Wyciskanie hantli z pauzą", "Paused dumbbell bench press", "Zaawansowany", "4 x 6-8", "3-2-1-0",
         "Wyciskanie hantli z podwójną pauzą (2s+2s)", "Wyciskanie hantli leżąc bez pauzy",
         "2-sekundowa pauza na dole eliminuje odbicie i buduje siłę startową",
         "Odbijanie ciężaru od klatki w dolnej pozycji"),
    ],
)

add_family(
    "Klatka", ["Barki", "Triceps"], ["Hantle", "Ławeczka"], "Siłowe",
    "Izolacja - przywodzenie ramion (klatka)",
    [
        "Lekkie ugięcie łokci przez cały ruch — nie prostuj ich do końca",
        "Ruch jak 'obejmowanie drzewa' — prowadź hantle łukiem, nie liniowo",
    ],
    [
        "Prostowanie łokci na dole (przenosi obciążenie na staw)",
        "Zbyt duży ciężar ograniczający zakres ruchu",
    ],
    [
        ("Rozpiętki hantlami płasko", "Flat dumbbell fly", "Średni", "3 x 12-15", "3-0-2-0",
         "Rozpiętki skos dodatni z większym ciężarem", "Rozpiętki hantlami z mniejszym ciężarem",
         "Płaska ławka — równomierne zaangażowanie całej klatki",
         "Zbyt niskie opuszczanie obciążające przednią część barku"),
        ("Rozpiętki hantlami skos ujemny", "Decline dumbbell fly", "Zaawansowany", "3 x 10-12", "3-0-2-0",
         "Rozpiętki skos ujemny z pauzą na dole", "Rozpiętki hantlami płasko",
         "Kąt ujemny kładzie nacisk na dolną część klatki",
         "Utrata kontroli tułowia przy nietypowym kącie ławki"),
        ("Krzyżowanie gumy oporowej", "Standing band chest fly (crossover)", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Krzyżowanie gumy jednostronnie z większym oporem", "Krzyżowanie gumy z lżejszym oporem",
         "Guma mocowana za plecami na wysokości barków — krzyżuj ręce przed sobą",
         "Zbyt duże pochylenie tułowia do przodu zamiast pracy ramion", ["Gumy oporowe"]),
        ("Wyciskanie gumą oporową w staniu", "Standing resistance band chest press", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Wyciskanie gumą jednostronnie (unilateralnie)", "Wyciskanie gumą siedząc (mniejszy zakres)",
         "Guma mocowana za plecami na wysokości klatki, krok w przód dla napięcia",
         "Odchylanie tułowia do tyłu podczas wypychania", ["Gumy oporowe"]),
        ("Dipy klatkowe na ławeczkach", "Chest dips (torso leaning forward)", "Zaawansowany", "3 x 8-10", "2-1-1-0",
         "Dipy z dociążeniem (plecak/talerz)", "Dipy z asystą nóg opartych na podłodze",
         "Pochylenie tułowia do przodu przenosi akcent z tricepsa na klatkę",
         "Zbyt wyprostowana pozycja tułowia (przenosi pracę na triceps)"),
    ],
)

add_family(
    "Klatka", ["Barki", "Brzuch"], ["Masa własna"], "Izometryczne",
    "Izometria - napięcie klatki",
    [
        "Maksymalne napięcie mięśni klatki przez pełny czas utrzymania",
        "Spokojny, równomierny oddech mimo napięcia izometrycznego",
    ],
    [
        "Wstrzymywanie oddechu podczas napięcia",
        "Zbyt krótki czas utrzymania bez progresji",
    ],
    [
        ("Izometryczny ścisk dłoni przed klatką", "Standing isometric chest squeeze", "Początkujący", "3 x 20-30s", "izometria",
         "Ścisk z gumą oporową dla większego napięcia", "Krótsze utrzymanie 10-15s",
         "Złóż dłonie przed klatką i naciskaj jedną na drugą przez cały czas",
         "Napięcie tylko w rękach bez zaangażowania klatki"),
        ("Podpór z uciskiem hantli między dłońmi", "Isometric dumbbell squeeze plank", "Średni", "3 x 20-30s", "izometria",
         "Wersja z podniesioną jedną nogą dla dodatkowej stabilizacji", "Wersja na kolanach",
         "Trzymaj mały hantel/piłkę między dłońmi w podporze, zaciskaj przez cały czas",
         "Opadanie bioder podczas koncentracji na ucisku rąk", ["Masa własna", "Hantle"]),
    ],
)

add_family(
    "Klatka", ["Triceps", "Barki", "Brzuch"], ["Masa własna"], "Siłowe",
    "Poziome wypychanie (stabilizacja)",
    [
        "Ciało w jednej linii od głowy do stóp przez cały ruch",
        "Napięty core minimalizuje niepotrzebną rotację",
    ],
    [
        "Opadanie bioder podczas dodatkowego ruchu ręką/nogą",
        "Zbyt szybkie tempo bez kontroli",
    ],
    [
        ("Pompki T", "T push-up", "Zaawansowany", "3 x 8-10/stronę", "2-0-1-1",
         "Pompki T z hantlem w ręce", "Pompki klasyczne bez rotacji",
         "Po wypchnięciu obróć tułów i wyciągnij rękę ku sufitowi, tworząc literę T",
         "Zbyt szybka rotacja destabilizująca miednicę"),
        ("Pompki Spiderman", "Spiderman push-up", "Zaawansowany", "3 x 8-10/stronę", "2-0-1-0",
         "Spiderman push-up z podskokiem kolana do łokcia", "Pompki klasyczne",
         "Podczas opuszczania przyciągaj kolano do łokcia po tej samej stronie",
         "Opadanie bioder podczas przyciągania kolana"),
        ("Pompki Superman", "Superman push-up", "Zaawansowany", "3 x 5-8", "wybuchowo",
         "Pompki plyometryczne z pełnym oderwaniem od podłogi", "Pompki plyometryczne (clap push-up)",
         "Wybuchowe wypchnięcie z oderwaniem rąk i nóg jednocześnie od podłoża",
         "Lądowanie z zablokowanymi stawami łokciowymi i kolanowymi"),
        ("Pompki staggered", "Staggered push-up", "Średni", "3 x 10-12/stronę", "2-0-1-0",
         "Staggered push-up ze zwiększoną różnicą wysunięcia", "Pompki klasyczne (dłonie równo)",
         "Jedna dłoń wysunięta bardziej do przodu — zmienia rozkład obciążenia między stronami",
         "Symetryczne obciążenie mimo asymetrycznej pozycji rąk (brak efektu)"),
        ("Pompki z obciążeniem", "Weighted push-up", "Zaawansowany", "4 x 8-10", "2-0-1-0",
         "Weighted push-up z większym obciążeniem stopniowo", "Pompki klasyczne bez obciążenia",
         "Dodatkowe obciążenie na plecach — utrzymuj identyczną technikę jak bez ciężaru",
         "Pogorszenie techniki (opadanie bioder) pod wpływem dodatkowego ciężaru"),
        ("Pompki na jednej nodze", "Single-leg push-up", "Średni", "3 x 10-12", "2-0-1-0",
         "Single-leg push-up z nogą uniesioną wyżej", "Pompki klasyczne (obie nogi na podłodze)",
         "Jedna noga uniesiona kilka centymetrów nad podłogę — wymaga dodatkowej stabilizacji core",
         "Rotacja bioder w stronę uniesionej nogi"),
        ("Pompki na jednej ręce (asysta)", "Wall-assisted one-arm push-up", "Zaawansowany", "3 x 5-6/stronę", "2-0-1-0",
         "Pompki na jednej ręce bez asysty", "Pompki archer",
         "Stopy szerzej rozstawione i przeciwna ręka lekko odciąża o ścianę/oparcie",
         "Skręcanie bioder zamiast utrzymania stabilnej podstawy"),
    ],
)

# ======================================================================
# PLECY (docelowo +28)
# ======================================================================

add_family(
    "Plecy", ["Biceps", "Przedramiona"], ["Drążek"], "Siłowe",
    "Wertykalne przyciąganie",
    [
        "Zacznij ruch od ściągnięcia łopatek, potem ugięcie ramion",
        "Pełny zakres — od pełnego wyprostu ramion do brody nad drążkiem",
        "Napięty core, minimalizuj kołysanie ciała",
    ],
    [
        "Podciąganie tylko przedramionami, bez pracy łopatek",
        "Nadmierne kołysanie całym ciałem",
        "Niepełny zakres (brak pełnego wyprostu na dole)",
    ],
    [
        ("Podciąganie chwytem mieszanym", "Mixed-grip pull-up", "Zaawansowany", "4 x 5-8", "2-0-1-1",
         "Podciąganie jednostronne (archer pull-up)", "Podciąganie nachwytem z gumą asekuracyjną",
         "Jedna dłoń nachwytem, druga podchwytem — zmieniaj stronę między seriami"
         , "Faworyzowanie tylko jednej strony ciała"),
        ("Podciąganie nachwytem szerokim", "Wide-grip pull-up", "Zaawansowany", "4 x 5-8", "2-0-1-0",
         "Podciąganie nachwytem szerokim z obciążeniem", "Podciąganie nachwytem chwytem standardowym",
         "Szeroki chwyt akcentuje najszerszy grzbietu, ogranicza zasięg ruchu",
         "Zbyt szeroki chwyt ograniczający kontrolę i zakres"),
        ("Podciąganie z gumą asekuracyjną", "Band-assisted pull-up", "Początkujący", "4 x 6-10", "2-0-1-0",
         "Podciąganie nachwytem bez asysty", "Martwe zwisy na drążku",
         "Guma zapięta na drążku i kolanie/stopie redukuje obciążenie w najsłabszej fazie",
         "Zbyt mocna guma eliminująca cały wysiłek", ["Drążek", "Gumy oporowe"]),
        ("Negatywne podciąganie", "Negative pull-up (eccentric)", "Średni", "4 x 5-6", "5-0-0-0",
         "Podciąganie nachwytem pełne", "Martwe zwisy na drążku",
         "Wyskocz do góry, następnie opuszczaj się maksymalnie wolno (4-5s)",
         "Zbyt szybkie opuszczanie tracące cel treningu ekscentrycznego"),
        ("Podciąganie archer", "Archer pull-up", "Zaawansowany", "3 x 4-6/stronę", "2-0-1-0",
         "Podciąganie na jednej ręce (asysta)", "Podciąganie nachwytem szerokim",
         "Jedna ręka ciągnie, druga wyprostowana wzdłuż drążka jako punkt równowagi",
         "Zbyt duże obciążenie ramienia asekurującego"),
        ("Martwe zwisy na drążku", "Dead hang", "Początkujący", "3 x 20-40s", "izometria",
         "Martwe zwisy z jedną ręką", "Zwisy z podparciem stóp na krześle",
         "Aktywne zwisy — lekko ściągnij łopatki, nie wisz całkowicie pasywnie",
         "Całkowicie pasywny zwis w barkach (ryzyko przeciążenia stawu)", ["Drążek"]),
        ("Wiosłowanie na drążku pod kątem", "Australian pull-up (body row)", "Początkujący", "4 x 10-12", "2-0-1-0",
         "Wiosłowanie na drążku ze stopami wyżej", "Wiosłowanie na drążku pod większym kątem (bliżej pionu)",
         "Ciało pod kątem, drążek ustawiony niżej — łagodniejsza alternatywa dla pełnego podciągania",
         "Zbyt niski kąt ciała utrudniający wykonanie z dobrą techniką"),
    ],
)

add_family(
    "Plecy", ["Biceps", "Barki"], ["Hantle", "Ławeczka"], "Siłowe",
    "Horyzontalne przyciąganie",
    [
        "Łopatka 'chowana w kieszeni' na szczycie ruchu",
        "Tułów stabilny, minimalna rotacja",
        "Prowadź łokieć blisko ciała",
    ],
    [
        "Rotacja tułowia dla 'oszukania' ciężaru",
        "Zbyt duży zamach bez kontroli ekscentrycznej",
    ],
    [
        ("Wiosłowanie hantlem jednorącz w podparciu", "Single-arm dumbbell row (bench supported)", "Średni", "4 x 10-12/stronę", "2-1-1-0",
         "Wiosłowanie hantlami dwuręcz w opadzie", "Wiosłowanie hantlem lekkim ciężarem",
         "Kolano i dłoń podparte na ławce dla stabilizacji tułowia",
         "Opieranie się na ramieniu podpierającym zamiast na core"),
        ("Wiosłowanie hantlami w opadzie tułowia", "Bent-over dumbbell row", "Zaawansowany", "4 x 8-10", "2-0-1-0",
         "Wiosłowanie hantlami w opadzie z pauzą na szczycie", "Wiosłowanie hantlem jednorącz w podparciu",
         "Tułów pod kątem ~45°, biodra odsunięte do tyłu (hip hinge)",
         "Okrąglenie odcinka lędźwiowego pod obciążeniem"),
        ("Wiosłowanie hantlem chwytem młotkowym", "Neutral-grip dumbbell row", "Średni", "4 x 10-12", "2-0-1-0",
         "Wiosłowanie hantlami w opadzie", "Wiosłowanie hantlem jednorącz w podparciu",
         "Neutralny chwyt bardziej angażuje środkową część grzbietu",
         "Zbyt szybkie tempo w fazie opuszczania ciężaru"),
        ("Renegade row (wiosłowanie w podporze)", "Renegade row", "Zaawansowany", "3 x 8-10/stronę", "2-0-1-0",
         "Renegade row z pompką między powtórzeniami", "Wiosłowanie hantlem jednorącz w podparciu na ławce",
         "Szeroki rozstaw stóp dla stabilności, minimalizuj rotację bioder",
         "Nadmierna rotacja bioder podczas ciągnięcia hantla"),
        ("Wiosłowanie gumą oporową w siadzie", "Seated resistance band row", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Wiosłowanie gumą jednostronnie", "Wiosłowanie gumą z mniejszym oporem",
         "Guma owinięta wokół stóp, siad z wyprostowanymi nogami, ciągnij do brzucha",
         "Garbienie się (okrąglenie pleców) w trakcie ciągnięcia", ["Gumy oporowe"]),
        ("Pull-apart gumą przed sobą", "Band pull-apart", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Pull-apart gumą jednorącz naprzemiennie", "Pull-apart z mniejszym oporem gumy",
         "Ramiona wyprostowane przed sobą, rozciągaj gumę na boki ściągając łopatki",
         "Uginanie łokci zamiast pracy w stawach barkowych", ["Gumy oporowe"]),
    ],
)

add_family(
    "Plecy", ["Pośladki", "Brzuch"], ["Masa własna"], "Siłowe",
    "Wyprost tułowia",
    [
        "Wyprost przez całą długość kręgosłupa, nie tylko odcinek lędźwiowy",
        "Napięte pośladki wspomagają wyprost bioder",
    ],
    [
        "Przeprost w górnej fazie (hiperekstensja szyi/lędźwi)",
        "Zbyt szybkie tempo bez kontroli",
    ],
    [
        ("Superman naprzemienny", "Alternating Superman", "Średni", "3 x 10-12/stronę", "2-1-1-0",
         "Superman naprzemienny z hantlami w rękach", "Superman statyczny (bez ruchu)",
         "Unoś przeciwną rękę i nogę naprzemiennie, zamiast wszystkich czterech kończyn naraz",
         "Zbyt duża amplituda skręcająca miednicę", ["Masa własna", "Hantle"]),
        ("Good morning z gumą oporową", "Resistance band good morning", "Średni", "3 x 12-15", "3-0-1-0",
         "Good morning z hantlami", "Good morning z samą masą ciała",
         "Zawias w biodrach (hip hinge), kolana lekko ugięte, grzbiet neutralny",
         "Zginanie w odcinku lędźwiowym zamiast w biodrach", ["Gumy oporowe"]),
        ("Bird dog", "Bird dog", "Początkujący", "3 x 10-12/stronę", "2-1-1-0",
         "Bird dog z gumą oporową między ręką i nogą", "Bird dog bez wysuwania kończyn (tylko unoszenie)",
         "Przeciwna ręka i noga wysuwane równocześnie, miednica nieruchoma",
         "Kołysanie bioder w trakcie wysuwania kończyn"),
        ("Hiperekstensje na podłodze", "Floor back extension", "Początkujący", "3 x 12-15", "2-1-1-0",
         "Superman klasyczny", "Hiperekstensje z mniejszym zakresem",
         "Unoś tułów tylko do naturalnego wyprostu kręgosłupa, bez przeprostu",
         "Nadmierne odchylenie głowy do tyłu"),
    ],
)

add_family(
    "Plecy", ["Biceps", "Barki", "Brzuch"], ["Drążek"], "Siłowe",
    "Wertykalne przyciąganie (stabilizacja)",
    [
        "Kontrola łopatek na całej długości ruchu",
        "Napięty core ograniczający zbędny ruch tułowia",
    ],
    [
        "Brak aktywacji łopatek przed zgięciem ramion",
        "Nadmierne kołysanie ciała",
    ],
    [
        ("Scapular pull-up", "Scapular pull-up", "Początkujący", "3 x 10-12", "2-1-1-0",
         "Podciąganie z gumą asekuracyjną", "Scapular pull-up z podparciem stóp",
         "Bez zginania ramion — tylko 'ściąganie' i 'rozciąganie' łopatek w zwisie",
         "Zginanie ramion (przechodzenie w pełne podciąganie)"),
        ("L-sit pull-up", "L-sit pull-up", "Zaawansowany", "3 x 4-6", "2-0-1-0",
         "L-sit pull-up z dociążeniem", "Podciąganie nachwytem bez pozycji L",
         "Nogi wyprostowane pod kątem 90° do tułowia przez cały ruch — dodatkowo obciąża core",
         "Opadanie nóg poniżej kąta 90° w trakcie ruchu"),
        ("Single-arm dead hang", "Single-arm dead hang", "Zaawansowany", "3 x 10-15s/stronę", "izometria",
         "Single-arm dead hang z dociążeniem", "Martwe zwisy dwiema rękami",
         "Druga ręka lekko dotyka drążka dla bezpieczeństwa, ale nie odciąża",
         "Odciąganie ciężaru na drugą, 'asekurującą' rękę"),
    ],
)

add_family(
    "Plecy", ["Barki", "Przedramiona"], ["Gumy oporowe"], "Siłowe",
    "Horyzontalne przyciąganie (guma)",
    [
        "Łokcie wysoko podczas ciągnięcia dla akcentu na górną część grzbietu",
        "Kontrolowany powrót — nie pozwól gumie 'szarpnąć' ramion do przodu",
    ],
    [
        "Ciągnięcie tylko ramionami bez pracy łopatek",
        "Zbyt szybki, niekontrolowany powrót gumy",
    ],
    [
        ("Face pull na gumie w klęku", "Kneeling band face pull", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Face pull gumą w staniu", "Face pull gumą z mniejszym oporem",
         "Ciągnij gumę do wysokości czoła, łokcie wysoko, kciuki do tyłu na końcu ruchu",
         "Ciągnięcie gumy do brody zamiast do czoła (zmiana wzorca)"),
        ("Standing wide band row", "Standing wide-grip band row", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Standing band row jednorącz", "Standing band row z mniejszym oporem",
         "Szeroki chwyt gumy, ciągnij do klatki z łokciami wysoko dla akcentu na środek grzbietu",
         "Opuszczanie łokci podczas ciągnięcia (zmiana akcentu na dolne plecy)"),
    ],
)

add_family(
    "Plecy", ["Barki", "Przedramiona"], ["Hantle"], "Siłowe",
    "Izolacja - unoszenie barków (trapez)",
    [
        "Unoś barki prosto w górę do uszu, bez rotacji ramion",
        "Kontrolowane opuszczanie — nie 'upuszczaj' ciężaru",
    ],
    [
        "Rotacja barków w trakcie ruchu (zamiast czystej elewacji)",
        "Zbyt szybkie tempo bez pauzy na szczycie",
    ],
    [
        ("Shrugi z hantlami", "Dumbbell shrug", "Początkujący", "4 x 12-15", "2-1-1-0",
         "Shrugi z większym ciężarem i pauzą", "Shrugi bez obciążenia (masa własna ramion)",
         "Krótka pauza na szczycie ruchu maksymalizuje napięcie górnej części trapezu",
         "Zbyt duży ciężar wymuszający pomoc nóg/tułowia (szarpanie)"),
    ],
)

# ======================================================================
# BARKI (docelowo +26)
# ======================================================================

add_family(
    "Barki", ["Triceps", "Plecy"], ["Hantle"], "Siłowe",
    "Wertykalne wypychanie",
    [
        "Nadgarstki w linii z łokciami, ciężar prowadzony po łuku nad głową",
        "Napięty core zapobiega nadmiernemu wyginaniu lędźwi",
    ],
    [
        "Nadmierne wyginanie odcinka lędźwiowego (mostkowanie)",
        "Zbyt szybkie 'wystrzeliwanie' ciężaru bez kontroli",
    ],
    [
        ("Wyciskanie hantli nad głowę siedząc", "Seated dumbbell shoulder press", "Średni", "4 x 8-10", "2-0-1-0",
         "Wyciskanie hantli nad głowę stojąc", "Wyciskanie hantli siedząc z mniejszym ciężarem",
         "Oparcie ławki stabilizuje tułów, pozwala skupić się na pracy barków",
         "Odrywanie pleców od oparcia w trakcie wyciskania", ["Hantle", "Ławeczka"]),
        ("Wyciskanie hantli nad głowę stojąc", "Standing dumbbell shoulder press", "Zaawansowany", "4 x 6-8", "2-0-1-0",
         "Wyciskanie jednego hantla nad głowę stojąc", "Wyciskanie hantli nad głowę siedząc",
         "Wymaga większej stabilizacji core niż wersja siedząca",
         "Nadmierne wyginanie lędźwi dla 'pomocy' w wyciskaniu"),
        ("Arnold press", "Arnold press", "Zaawansowany", "3 x 8-10", "2-1-1-0",
         "Arnold press z pauzą na szczycie", "Wyciskanie hantli nad głowę siedząc",
         "Rotacja dłoni z chwytu neutralnego na dole do nachwytu na górze",
         "Zbyt szybka rotacja bez kontroli w środkowej fazie ruchu"),
        ("Wyciskanie jednego hantla nad głowę", "Single-arm dumbbell press", "Zaawansowany", "3 x 8-10/stronę", "2-0-1-0",
         "Wyciskanie jednego hantla w staniu", "Wyciskanie hantli nad głowę siedząc (dwie ręce)",
         "Wolna ręka może się lekko oprzeć na biodrze dla stabilizacji",
         "Boczne przechylanie tułowia w stronę pracującego ramienia"),
        ("Pike push-up ze stopami na podwyższeniu", "Elevated pike push-up", "Zaawansowany", "3 x 8-10", "2-0-1-0",
         "Handstand push-up z asystą ściany", "Pike push-up (stopy na podłodze)",
         "Stopy na krześle/ławce zwiększają kąt i obciążenie barków",
         "Zbyt małe zgięcie w biodrach (zbliżanie do klasycznej pompki)", ["Masa własna"]),
        ("Handstand push-up z asystą ściany", "Wall-assisted handstand push-up", "Zaawansowany", "3 x 5-8", "3-0-1-0",
         "Handstand push-up wolnostojący", "Pike push-up ze stopami na podwyższeniu",
         "Głowa kontrolowanie zbliża się do podłogi, łokcie w kierunku ~45°",
         "Zbyt szybkie opuszczanie głowy bez kontroli (ryzyko urazu)", ["Masa własna"]),
    ],
)

add_family(
    "Barki", ["Plecy"], ["Hantle"], "Siłowe",
    "Izolacja - odwodzenie ramion",
    [
        "Lekkie ugięcie łokci, prowadź ciężar do wysokości barków, nie wyżej",
        "Kontrolowane tempo — bez używania rozmachu tułowia",
    ],
    [
        "Unoszenie ramion powyżej wysokości barków (przeciąża staw)",
        "Używanie zamachu tułowia do 'wyrzucenia' ciężaru",
    ],
    [
        ("Wznosy bokiem siedząc", "Seated lateral raise", "Średni", "4 x 12-15", "2-0-2-0",
         "Wznosy bokiem stojąc z większym ciężarem", "Wznosy bokiem z mniejszym ciężarem",
         "Pozycja siedząca eliminuje pomoc nóg i tułowia",
         "Nachylanie tułowia do przodu podczas unoszenia ramion", ["Hantle", "Ławeczka"]),
        ("Wznosy bokiem na leżąco (skos)", "Incline lateral raise", "Zaawansowany", "3 x 12-15", "2-0-2-0",
         "Wznosy bokiem na leżąco z pauzą na szczycie", "Wznosy bokiem stojąc",
         "Leżenie na boku na ławce skos — pełna izolacja środkowej głowy naramiennego",
         "Zbyt duży ciężar skracający zakres ruchu", ["Hantle", "Ławeczka"]),
        ("Wznosy bokiem gumą oporową", "Band lateral raise", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Wznosy bokiem gumą z większym oporem", "Wznosy bokiem gumą z mniejszym oporem",
         "Stań na środku gumy, unoś ręce na boki do wysokości barków",
         "Zbyt szybkie tempo tracące napięcie mięśniowe", ["Gumy oporowe"]),
        ("Wznosy przodem", "Front raise", "Początkujący", "3 x 12-15", "2-0-2-0",
         "Wznosy przodem naprzemiennie", "Wznosy przodem z mniejszym ciężarem",
         "Unoszenie hantli przed sobą do wysokości oczu, kontrolowany powrót",
         "Kołysanie tułowia do tyłu dla ułatwienia unoszenia"),
        ("Wznosy w opadzie (reverse fly) w staniu", "Standing bent-over reverse fly", "Średni", "3 x 12-15", "2-0-2-0",
         "Reverse fly na ławce (skos ujemny)", "Reverse fly z mniejszym ciężarem",
         "Tułów w opadzie ~45°, unoszenie ramion na boki z akcentem na łopatki",
         "Prostowanie tułowia w trakcie unoszenia ramion"),
        ("6-way shoulder raise", "6-way shoulder raise", "Zaawansowany", "3 x 8/kierunek", "2-0-2-0",
         "6-way shoulder raise z większym ciężarem", "Wznosy bokiem + wznosy przodem osobno",
         "Sekwencja: przód, bok, tył w jednej serii bez odkładania hantli",
         "Zbyt duży ciężar psujący technikę w ostatnich powtórzeniach kombinacji"),
    ],
)

add_family(
    "Barki", ["Plecy", "Przedramiona"], ["Gumy oporowe"], "Mobilność",
    "Mobilizacja stawu barkowego",
    [
        "Ruch płynny, bez szarpania — pełen zakres bez bólu",
        "Napięty core stabilizuje tułów podczas pracy ramion",
    ],
    [
        "Kompensacja ruchu przez wyginanie tułowia",
        "Zbyt szybkie tempo utrudniające kontrolę zakresu",
    ],
    [
        ("Pull-apart nad głową", "Overhead band pull-apart", "Początkujący", "3 x 12-15", "2-0-2-0",
         "Pull-apart nad głową z większym oporem", "Pull-apart przed sobą (łatwiejszy wariant)",
         "Ramiona wyprostowane nad głową, rozciągaj gumę na boki",
         "Opuszczanie ramion poniżej linii głowy w trakcie ruchu"),
        ("Rotacje zewnętrzne barku z gumą", "Band external rotation", "Początkujący", "3 x 12-15/stronę", "2-0-2-0",
         "Rotacje zewnętrzne z większym oporem gumy", "Rotacje zewnętrzne bez gumy (masa ręki)",
         "Łokieć przy tułowiu, ruch tylko w stawie barkowym (rotacja przedramienia)",
         "Odsuwanie łokcia od tułowia (zmiana wzorca ruchu)"),
        ("Krążenia ramion z gumą (pass-through)", "Band shoulder pass-through", "Początkujący", "3 x 10-12", "wolno",
         "Pass-through z węższym chwytem (większy zakres)", "Pass-through z szerszym chwytem (mniejszy zakres)",
         "Przenoszenie napiętej gumy od bioder nad głowę i za plecy w kółko",
         "Zbyt wąski chwyt utrudniający pełny, bezbolesny zakres"),
    ],
)

# ======================================================================
# BICEPS (docelowo +22)
# ======================================================================

add_family(
    "Biceps", ["Przedramiona"], ["Hantle"], "Siłowe",
    "Izolacja - zgięcie łokcia",
    [
        "Łokcie przyklejone do tułowia przez cały ruch",
        "Pełen zakres — od pełnego wyprostu do pełnego zgięcia",
        "Kontrolowana faza opuszczania (ekscentryczna)",
    ],
    [
        "Poruszanie łokciami do przodu/na boki (odciążanie bicepsa)",
        "Używanie zamachu tułowia do 'wystrzelenia' ciężaru",
    ],
    [
        ("Uginanie hantli naprzemiennie", "Alternating dumbbell curl", "Początkujący", "4 x 10-12/stronę", "2-0-1-0",
         "Uginanie hantli jednocześnie oburącz z większym ciężarem", "Uginanie hantli z mniejszym ciężarem",
         "Naprzemienna praca pozwala skupić się na technice każdej strony",
         "Kołysanie tułowia w rytm uginania"),
        ("Uginanie kaznodziejskie hantlem", "Preacher curl (bench-supported)", "Zaawansowany", "3 x 10-12", "3-0-1-0",
         "Uginanie kaznodziejskie z większym ciężarem", "Uginanie hantli w staniu",
         "Tricep/tył ramienia oparty na ławce skos — eliminuje pomoc barku",
         "Odrywanie ramienia od podparcia w górnej fazie ruchu", ["Hantle", "Ławeczka"]),
        ("Uginanie hantli chwytem odwrotnym", "Reverse-grip dumbbell curl", "Średni", "3 x 12-15", "2-0-1-0",
         "Uginanie odwrotne z większym ciężarem", "Uginanie odwrotne z mniejszym ciężarem",
         "Nachwyt (dłonie skierowane do podłogi) akcentuje przedramiona i ramienno-promieniowy",
         "Zginanie nadgarstka podczas ruchu (powinien być stabilny)"),
        ("21s uginanie hantli", "21s bicep curl", "Zaawansowany", "3 x 21 (7+7+7)", "zmienne",
         "21s z większym ciężarem", "Klasyczne uginanie hantli (bez podziału)",
         "7 powtórzeń dolna połowa + 7 górna połowa + 7 pełny zakres, bez odpoczynku",
         "Skracanie liczby powtórzeń w każdej fazie (utrata efektu metabolicznego)"),
        ("Uginanie hantli ze wspornikiem o ścianę", "Wall-supported dumbbell curl", "Początkujący", "3 x 12-15", "2-0-1-0",
         "Uginanie hantli bez wsparcia (klasyczne)", "Uginanie hantli ze wspornikiem, mniejszy ciężar",
         "Tył ramienia oparty o ścianę eliminuje możliwość oszukiwania zamachem",
         "Odrywanie ramienia od ściany w trakcie ruchu"),
    ],
)

add_family(
    "Biceps", ["Przedramiona", "Barki"], ["Hantle"], "Siłowe",
    "Izolacja - zgięcie łokcia (chwyt neutralny)",
    [
        "Łokcie stabilne przy tułowiu, chwyt neutralny przez cały ruch",
        "Kontrola w obu fazach ruchu — koncentryczna i ekscentryczna",
    ],
    [
        "Rotacja nadgarstka podczas ruchu (zmiana z młotkowego na klasyczny)",
        "Zbyt duży ciężar wymuszający pomoc barku",
    ],
    [
        ("Hammer curl naprzemienny", "Alternating hammer curl", "Początkujący", "4 x 10-12/stronę", "2-0-1-0",
         "Hammer curl oburącz z większym ciężarem", "Hammer curl z mniejszym ciężarem",
         "Chwyt młotkowy dodatkowo angażuje ramienno-promieniowy i przedramiona",
         "Unoszenie barku w trakcie ruchu (kompensacja)"),
        ("Cross-body hammer curl", "Cross-body hammer curl", "Średni", "3 x 10-12/stronę", "2-0-1-0",
         "Cross-body hammer curl z większym ciężarem", "Hammer curl naprzemienny (bez krzyżowania)",
         "Ciężar prowadzony w kierunku przeciwnego barku, nie prosto do góry",
         "Prowadzenie ciężaru po linii prostej zamiast po przekątnej"),
        ("Zottman curl pełny zakres", "Full-range Zottman curl", "Zaawansowany", "3 x 10-12", "2-1-2-0",
         "Zottman curl z większym ciężarem", "Uginanie hantli klasyczne (bez rotacji)",
         "Rotacja na szczycie: uginanie nachwytem, opuszczanie podchwytem",
         "Zbyt szybka rotacja bez pauzy na szczycie ruchu"),
    ],
)

add_family(
    "Biceps", ["Przedramiona", "Plecy"], ["Drążek"], "Siłowe",
    "Wertykalne przyciąganie (podchwyt)",
    [
        "Podchwyt (dłonie do siebie) mocniej angażuje biceps niż nachwyt",
        "Pełen zakres ruchu, kontrolowane tempo",
    ],
    [
        "Niepełny zakres (brak pełnego wyprostu ramion na dole)",
        "Nadmierne kołysanie ciała",
    ],
    [
        ("Chin-up wąski chwyt", "Close-grip chin-up", "Zaawansowany", "4 x 5-8", "2-0-1-0",
         "Chin-up z dociążeniem", "Chin-up z gumą asekuracyjną",
         "Dłonie blisko siebie maksymalizują zaangażowanie bicepsa",
         "Zbyt szeroki chwyt (przechodzi w wzorzec pleców, nie bicepsa)"),
        ("Negatywne chin-up", "Negative chin-up", "Średni", "4 x 5-6", "5-0-0-0",
         "Chin-up pełny", "Martwe zwisy podchwytem",
         "Wyskocz do góry, opuszczaj się maksymalnie wolno kontrolując tempo",
         "Zbyt szybkie, niekontrolowane opadanie"),
        ("Chin-up z gumą asekuracyjną", "Band-assisted chin-up", "Początkujący", "4 x 6-10", "2-0-1-0",
         "Chin-up wąski chwyt bez asysty", "Zwisy podchwytem z podparciem stóp",
         "Guma redukuje obciążenie w najsłabszej, dolnej fazie ruchu",
         "Zbyt mocna guma odbierająca cały wysiłek treningowy", ["Drążek", "Gumy oporowe"]),
    ],
)

add_family(
    "Biceps", ["Przedramiona"], ["Gumy oporowe"], "Siłowe",
    "Izolacja - zgięcie łokcia (guma)",
    [
        "Stabilne łokcie, napięcie gumy utrzymywane przez cały zakres",
        "Kontrolowany powrót — nie pozwól gumie 'wyrwać' ramienia",
    ],
    [
        "Zbyt szybki, niekontrolowany powrót do pozycji startowej",
        "Poruszanie łokciami do przodu podczas uginania",
    ],
    [
        ("Uginanie gumy oporowej stojąc", "Standing band bicep curl", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Uginanie gumy z większym oporem", "Uginanie gumy z mniejszym oporem",
         "Stań na środku gumy, łokcie przy tułowiu przez cały ruch",
         "Kołysanie tułowia dla pomocy w uginaniu"),
        ("Uginanie gumy naprzemiennie", "Alternating band curl", "Początkujący", "3 x 12-15/stronę", "2-0-2-0",
         "Uginanie gumy oburącz jednocześnie", "Uginanie gumy jednorącz z przerwą między stronami",
         "Naprzemienna praca pozwala skupić uwagę na technice każdej ręki",
         "Nierówne napięcie gumy między powtórzeniami"),
    ],
)

# ======================================================================
# TRICEPS (docelowo +22)
# ======================================================================

add_family(
    "Triceps", ["Barki"], ["Hantle", "Ławeczka"], "Siłowe",
    "Izolacja - wyprost łokcia",
    [
        "Łokcie stabilne, blisko głowy, ruch tylko w stawie łokciowym",
        "Kontrolowane opuszczanie ciężaru za głowę",
    ],
    [
        "Rozjeżdżanie się łokci na boki podczas ruchu",
        "Zbyt duży ciężar ograniczający pełny zakres",
    ],
    [
        ("Wyprost hantla nad głową siedząc", "Seated overhead dumbbell extension", "Średni", "3 x 10-12", "2-0-1-0",
         "Wyprost hantla nad głową stojąc", "Wyprost hantla z mniejszym ciężarem",
         "Oparcie ławki stabilizuje tułów podczas pracy tricepsa",
         "Nadmierne wyginanie lędźwi podczas wyprostu", ["Hantle", "Ławeczka"]),
        ("Wyprost jednorącz za głową", "Single-arm overhead extension", "Zaawansowany", "3 x 10-12/stronę", "2-0-1-0",
         "Wyprost jednorącz z większym ciężarem", "Wyprost hantla nad głową siedząc (dwie ręce)",
         "Wolna ręka stabilizuje łokieć ramienia roboczego z boku",
         "Odsuwanie łokcia od głowy w trakcie ruchu"),
        ("Skull crusher na leżąco (klasyczny)", "Lying tricep extension", "Zaawansowany", "3 x 10-12", "2-0-1-0",
         "Skull crusher z większym ciężarem", "Skull crusher z mniejszym ciężarem",
         "Łokcie skierowane do sufitu, opuszczaj ciężar w kierunku czoła",
         "Zbyt duży zakres ruchu w barkach (łokcie 'ucieka' do tyłu)", ["Hantle", "Ławeczka"]),
        ("Kickback jednorącz w opadzie", "Bent-over dumbbell kickback", "Początkujący", "3 x 12-15/stronę", "2-0-2-0",
         "Kickback z większym ciężarem", "Kickback z mniejszym ciężarem",
         "Ramię równoległe do podłogi, ruch tylko w przedramieniu",
         "Opuszczanie ramienia poniżej linii tułowia podczas ruchu", ["Hantle", "Ławeczka"]),
    ],
)

add_family(
    "Triceps", ["Barki", "Klatka"], ["Masa własna"], "Siłowe",
    "Poziome wypychanie (chwyt wąski)",
    [
        "Łokcie blisko tułowia przez cały ruch (nie rozjeżdżają się na boki)",
        "Ciało w jednej linii, napięty core",
    ],
    [
        "Rozjeżdżanie łokci na boki (przenosi pracę na klatkę/barki)",
        "Niepełny zakres ruchu",
    ],
    [
        ("Pompki diamentowe klasyczne", "Diamond push-up", "Zaawansowany", "4 x 8-10", "2-0-1-0",
         "Pompki diamentowe z podwyższonymi stopami", "Pompki diamentowe na kolanach",
         "Dłonie złożone w 'diament' pod klatką, łokcie przy tułowiu",
         "Zbyt duże rozjeżdżanie łokci na boki"),
        ("Pompki diamentowe na kolanach", "Kneeling diamond push-up", "Początkujący", "3 x 10-12", "2-0-1-0",
         "Pompki diamentowe klasyczne (na stopach)", "Pompki wąskie przy ścianie",
         "Kolana pod biodrami, ciało w linii od kolan do głowy",
         "Wypychanie bioder do góry dla ułatwienia ruchu"),
        ("Bench dips z nogami wyprostowanymi", "Straight-leg bench dips", "Zaawansowany", "3 x 10-12", "2-0-1-0",
         "Bench dips z obciążeniem na kolanach", "Bench dips z ugiętymi kolanami (łatwiejszy)",
         "Wyprostowane nogi znacznie zwiększają obciążenie tricepsa",
         "Zbyt niskie opuszczanie bioder przeciążające stawy barkowe", ["Ławeczka"]),
        ("Bench dips z ugiętymi kolanami", "Bent-knee bench dips", "Początkujący", "3 x 12-15", "2-0-1-0",
         "Bench dips z nogami wyprostowanymi", "Bench dips z mniejszym zakresem ruchu",
         "Dobry punkt startowy do budowania siły tricepsa przy dipach",
         "Zbyt szerokie rozstawienie dłoni na ławce", ["Ławeczka"]),
    ],
)

add_family(
    "Triceps", ["Barki"], ["Gumy oporowe"], "Siłowe",
    "Izolacja - wyprost łokcia (guma)",
    [
        "Łokieć stabilny, blisko tułowia, ruch tylko w przedramieniu",
        "Kontrolowany powrót gumy do pozycji startowej",
    ],
    [
        "Poruszanie łokciem podczas wyprostu (odciążanie tricepsa)",
        "Zbyt szybki, niekontrolowany powrót",
    ],
    [
        ("Wyprost tricepsa gumą nad głową", "Overhead band tricep extension", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Wyprost gumą z większym oporem", "Wyprost gumą z mniejszym oporem",
         "Guma mocowana wysoko (np. drążek), łokcie przy głowie",
         "Rozjeżdżanie łokci na boki podczas wyprostu", ["Gumy oporowe", "Drążek"]),
        ("Pushdown gumą oporową", "Band tricep pushdown", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Pushdown gumą jednorącz", "Pushdown gumą z mniejszym oporem",
         "Guma mocowana wysoko, łokcie przy tułowiu, wyprost przedramion do dołu",
         "Odsuwanie łokci od tułowia podczas ruchu", ["Gumy oporowe", "Drążek"]),
    ],
)

# ======================================================================
# BARKI — dopełnienie (+8)
# ======================================================================

add_family(
    "Barki", ["Triceps", "Plecy"], ["Masa własna"], "Siłowe",
    "Wertykalne wypychanie (masa własna)",
    [
        "Biodra wysoko, ciało w odwróconej literze V",
        "Głowa kontrolowanie zbliża się do podłogi między dłońmi",
    ],
    [
        "Zbyt niskie biodra (zmiana wzorca ruchu w pompkę klasyczną)",
        "Rozjeżdżanie łokci zamiast prowadzenia ich do tyłu",
    ],
    [
        ("Pike push-up klasyczny", "Pike push-up", "Średni", "3 x 8-12", "2-0-1-0",
         "Pike push-up ze stopami na podwyższeniu", "Pike push-up z węższą podstawą (mniejszy zakres)",
         "Ustawienie w odwróconej literze V, ręce i stopy szeroko dla stabilności",
         "Zbyt szeroki rozstaw dłoni ograniczający zakres ruchu"),
        ("Krążenia ramion z hantlami", "Dumbbell shoulder circles", "Początkujący", "3 x 10/kierunek", "wolno",
         "Krążenia z większym ciężarem", "Krążenia bez obciążenia",
         "Płynne, kontrolowane kółka w obu kierunkach, ramiona lekko uniesione",
         "Zbyt szybkie tempo tracące kontrolę nad ciężarem"),
    ],
)

add_family(
    "Barki", ["Plecy", "Przedramiona"], ["Hantle"], "Siłowe",
    "Izolacja - odwodzenie ramion w opadzie",
    [
        "Tułów w opadzie ~45°, grzbiet neutralny przez cały ruch",
        "Unoszenie ramion na boki z akcentem na łopatki, nie na barki",
    ],
    [
        "Prostowanie tułowia w trakcie unoszenia (utrata kąta opadu)",
        "Używanie zamachu tułowia zamiast czystej pracy ramion",
    ],
    [
        ("Reverse fly na ławce skos ujemny", "Incline reverse fly", "Zaawansowany", "3 x 12-15", "2-0-2-0",
         "Reverse fly na ławce z większym ciężarem", "Reverse fly w staniu (bez ławki)",
         "Klatka oparta o ławkę pod kątem — eliminuje kompensację dolnych pleców",
         "Odrywanie klatki od ławki w trakcie unoszenia ramion", ["Hantle", "Ławeczka"]),
        ("Y-raise na ławce skos", "Incline Y-raise", "Średni", "3 x 12-15", "2-0-2-0",
         "Y-raise z większym ciężarem", "Y-raise bez obciążenia",
         "Ramiona unoszone po skosie w kształcie litery Y, kciuki do góry",
         "Unoszenie ramion prosto na boki zamiast po skosie 'Y'", ["Hantle", "Ławeczka"]),
    ],
)

add_family(
    "Barki", ["Klatka", "Triceps"], ["Masa własna"], "Izometryczne",
    "Izometria - stabilizacja barku",
    [
        "Stabilna pozycja tułowia, napięte barki przez cały czas utrzymania",
        "Spokojny oddech mimo statycznego napięcia",
    ],
    [
        "Opadanie bioder podczas utrzymania pozycji",
        "Wstrzymywanie oddechu",
    ],
    [
        ("Plank z dotykiem barku", "Plank shoulder tap", "Średni", "3 x 10-12/stronę", "izometria",
         "Plank shoulder tap z uniesioną nogą", "Plank klasyczny (bez dotyku barku)",
         "Dotykaj przeciwnego barku ręką, minimalizując rotację bioder",
         "Rotacja bioder w stronę podnoszonej ręki"),
        ("Podpór na przedramionach z unoszeniem ramienia", "Forearm plank arm raise", "Średni", "3 x 8-10/stronę", "izometria",
         "Wersja z jednoczesnym unoszeniem ramienia i nogi", "Podpór na przedramionach klasyczny",
         "Unoszenie jednego ramienia przed siebie z zachowaniem stabilnej miednicy",
         "Opadanie bioder w stronę unoszonego ramienia"),
    ],
)

# ======================================================================
# BICEPS — dopełnienie (+8)
# ======================================================================

add_family(
    "Biceps", ["Przedramiona"], ["Drążek"], "Izometryczne",
    "Izometria - zgięcie łokcia (zwis)",
    [
        "Stabilne ramiona, napięcie bicepsa przez cały czas utrzymania",
        "Spokojny, kontrolowany oddech mimo statycznego wysiłku",
    ],
    [
        "Zbyt krótkie utrzymanie bez progresji czasu",
        "Całkowicie rozluźnione ramiona (utrata napięcia izometrycznego)",
    ],
    [
        ("Chin-up hold (utrzymanie na szczycie)", "Chin-up top hold", "Zaawansowany", "3 x 10-15s", "izometria",
         "Chin-up hold z dociążeniem", "Chin-up hold z asystą gumy",
         "Broda nad drążkiem, łopatki ściągnięte, utrzymuj bez opadania",
         "Opadanie w trakcie utrzymania (utrata pozycji szczytowej)", ["Drążek"]),
        ("Zwis podchwytem ze zgięciem 90°", "90-degree chin-up hold", "Średni", "3 x 10-20s", "izometria",
         "Zwis 90° z dociążeniem", "Martwe zwisy podchwytem (pełny wyprost)",
         "Ramiona zgięte pod kątem 90°, łokcie blisko tułowia",
         "Zbyt duże zgięcie łokci (bliżej pełnego chin-up) niezgodne z celem 90°", ["Drążek"]),
    ],
)

add_family(
    "Biceps", ["Przedramiona", "Barki"], ["Hantle", "Ławeczka"], "Siłowe",
    "Izolacja - zgięcie łokcia w opadzie",
    [
        "Ramię wyprostowane za linią tułowia na starcie ruchu",
        "Kontrola ekscentryczna — nie pozwól ciężarowi 'spadać'",
    ],
    [
        "Zbyt małe rozciągnięcie na dole (ramię przed tułowiem)",
        "Kołysanie tułowia dla pomocy w uginaniu",
    ],
    [
        ("Incline dumbbell curl", "Incline dumbbell curl", "Zaawansowany", "3 x 10-12", "2-0-1-0",
         "Incline curl z większym ciężarem", "Uginanie hantli w staniu",
         "Leżenie na ławce skos ujemny — maksymalne rozciągnięcie bicepsa na starcie",
         "Odrywanie ramion od ławki w trakcie uginania", ["Hantle", "Ławeczka"]),
        ("Spider curl", "Spider curl", "Zaawansowany", "3 x 10-12", "2-0-1-0",
         "Spider curl z większym ciężarem", "Uginanie kaznodziejskie hantlem",
         "Klatka oparta o ławkę skos dodatni w pozycji leżącej na brzuchu",
         "Odrywanie klatki od ławki podczas uginania", ["Hantle", "Ławeczka"]),
    ],
)

# ======================================================================
# TRICEPS — dopełnienie (+9)
# ======================================================================

add_family(
    "Triceps", ["Barki", "Klatka"], ["Masa własna"], "Siłowe",
    "Izometria - wyprost łokcia (podpór)",
    [
        "Napięty tricep przez cały czas utrzymania pozycji",
        "Stabilna pozycja tułowia, bez opadania bioder",
    ],
    [
        "Opadanie bioder podczas utrzymania",
        "Zbyt krótki czas bez progresji",
    ],
    [
        ("Podpór tyłem (reverse plank)", "Reverse plank", "Średni", "3 x 20-30s", "izometria",
         "Reverse plank z uniesioną nogą", "Reverse plank z ugiętymi kolanami (łatwiejszy)",
         "Dłonie pod barkami, ciało w linii od głowy do stóp, tricep w napięciu",
         "Zapadanie bioder w dół podczas utrzymania"),
        ("Podpór na dłoniach z wyprostem", "Tricep plank hold", "Początkujący", "3 x 20-30s", "izometria",
         "Wersja z unoszeniem jednej ręki na przemian", "Podpór na przedramionach (łatwiejszy)",
         "Ramiona wyprostowane pod barkami, łokcie 'zablokowane' ale nie przeprostowane",
         "Przeprost w stawach łokciowych (nadmierne blokowanie)"),
    ],
)

add_family(
    "Triceps", ["Barki"], ["Hantle"], "Siłowe",
    "Izolacja - wyprost łokcia w opadzie",
    [
        "Ramię równoległe do podłogi przez cały ruch, tylko przedramię się porusza",
        "Łokieć nieruchomy, blisko tułowia",
    ],
    [
        "Opuszczanie ramienia poniżej linii tułowia",
        "Poruszanie łokciem w trakcie wyprostu (odciążanie tricepsa)",
    ],
    [
        ("Kickback oburącz w opadzie", "Two-arm bent-over kickback", "Średni", "3 x 12-15", "2-0-2-0",
         "Kickback oburącz z większym ciężarem", "Kickback jednorącz z podparciem",
         "Tułów w opadzie ~45°, oba ramiona równolegle do podłogi",
         "Zbyt duże wyprostowanie tułowia (utrata kąta opadu)"),
        ("Overhead extension oburącz", "Two-arm overhead extension", "Średni", "3 x 10-12", "2-0-1-0",
         "Overhead extension z większym ciężarem", "Overhead extension jednorącz",
         "Jeden hantel trzymany oburącz nad głową, łokcie blisko uszu",
         "Rozjeżdżanie łokci na boki podczas opuszczania ciężaru", ["Hantle"]),
        ("JM press (hybrydowy wyprost)", "JM press", "Zaawansowany", "3 x 8-10", "2-0-1-0",
         "JM press z większym ciężarem", "Skull crusher klasyczny",
         "Hybryda między wyciskaniem wąskim a skull crusherem — łokcie schodzą do przodu i dół",
         "Zbyt duży zakres ruchu w barkach zamiast w łokciach", ["Hantle", "Ławeczka"]),
        ("Diamond push-up z podwyższonymi stopami", "Elevated diamond push-up", "Zaawansowany", "3 x 8-10", "2-0-1-0",
         "Diamond push-up z dociążeniem", "Pompki diamentowe klasyczne (stopy na podłodze)",
         "Podwyższone stopy zwiększają obciążenie tricepsa i górnej klatki",
         "Zbyt duże ugięcie w lędźwiach przy podwyższonych stopach"),
        ("Tricep dips na krześle", "Chair tricep dips", "Początkujący", "3 x 10-15", "2-0-1-0",
         "Tricep dips z nogami wyprostowanymi", "Tricep dips z bliżej ugiętymi kolanami",
         "Dłonie na krawędzi krzesła/ławki, biodra blisko mebla podczas ruchu",
         "Zbyt duże odsunięcie bioder od krzesła (przeciążenie barków)"),
    ],
)

# ======================================================================
# NOGI (docelowo +51)
# ======================================================================

add_family(
    "Nogi", ["Pośladki", "Brzuch"], ["Hantle"], "Siłowe",
    "Zgięcie kolan i bioder (przysiad)",
    [
        "Kolana w linii ze stopami, nie zapadają się do środka",
        "Ciężar na piętach/środku stopy, tułów w naturalnej pozycji",
        "Pełen zakres — biodra na wysokości kolan lub niżej",
    ],
    [
        "Zapadanie kolan do środka (koślawość)",
        "Odrywanie pięt od podłogi",
        "Niepełny zakres ruchu",
    ],
    [
        ("Goblet squat z pauzą", "Paused goblet squat", "Średni", "4 x 10-12", "2-2-1-0",
         "Goblet squat z większym ciężarem i pauzą", "Goblet squat bez pauzy",
         "2-sekundowa pauza w dolnej pozycji eliminuje odbicie",
         "Odbijanie się od dołu zamiast kontrolowanego wstawania"),
        ("Przysiad sumo z hantlem", "Sumo squat (dumbbell)", "Średni", "4 x 12-15", "2-0-1-0",
         "Sumo squat z większym ciężarem", "Sumo squat bez obciążenia",
         "Szeroki rozstaw stóp, palce skierowane na zewnątrz — akcent na przywodziciele i pośladki",
         "Zbyt wąski rozstaw stóp (zmiana wzorca na klasyczny przysiad)"),
        ("Przysiad Zercher", "Zercher squat", "Zaawansowany", "3 x 8-10", "2-0-1-0",
         "Zercher squat z większym ciężarem", "Goblet squat (łatwiejszy uchwyt)",
         "Hantel/ciężar trzymany w zgięciu łokci przed klatką",
         "Garbienie się pod wpływem ciężaru trzymanego z przodu"),
        ("Przysiad z hantlami po bokach", "Dumbbell suitcase squat", "Początkujący", "4 x 12-15", "2-0-1-0",
         "Suitcase squat z większym ciężarem", "Przysiad bez obciążenia (masa ciała)",
         "Hantle trzymane po bokach ciała — naturalna pozycja, łatwa progresja ciężaru",
         "Przechylanie tułowia w bok pod wpływem ciężaru"),
        ("Przysiad z podskokiem", "Jump squat", "Zaawansowany", "4 x 10-12", "wybuchowo",
         "Jump squat z obciążeniem (lekkie hantle)", "Przysiad klasyczny bez podskoku",
         "Wybuchowe odbicie z dołu, miękkie lądowanie z ugięciem kolan",
         "Sztywne lądowanie na wyprostowanych kolanach"),
        ("Przysiad izometryczny z pulsowaniem", "Pulse squat", "Średni", "3 x 15-20", "1-0-1-0",
         "Pulse squat z obciążeniem", "Pulse squat w niepełnym zakresie (górna połowa)",
         "Małe, kontrolowane pulsowanie w dolnej pozycji przysiadu",
         "Zbyt duża amplituda pulsowania (zmiana w pełny przysiad)"),
        ("Sissy squat", "Sissy squat", "Zaawansowany", "3 x 8-10", "3-0-1-0",
         "Sissy squat z dociążeniem", "Sissy squat z asystą (trzymanie się czegoś)",
         "Kolana wysuwają się mocno do przodu, tułów odchylony do tyłu, pięty w górze",
         "Zbyt duże obciążenie odcinka lędźwiowego przy odchylaniu tułowia"),
        ("Przysiad box squat", "Box squat", "Początkujący", "4 x 10-12", "2-1-1-0",
         "Box squat z hantlami", "Box squat bez obciążenia",
         "Delikatny dotyk krzesła/ławki na dole jako punkt odniesienia głębokości",
         "Siadanie z pełnym ciężarem na krześle (utrata napięcia mięśniowego)", ["Masa własna", "Ławeczka"]),
    ],
)

add_family(
    "Nogi", ["Pośladki", "Brzuch"], ["Hantle", "Ławeczka"], "Siłowe",
    "Jednonóż zgięcie kolana i biodra",
    [
        "Kolano przedniej nogi nie wykracza znacznie poza linię palców stopy",
        "Tułów lekko pochylony do przodu, napięty core",
    ],
    [
        "Zbyt krótki krok (przeciążenie kolana)",
        "Utrata równowagi z powodu zbyt szybkiego tempa",
    ],
    [
        ("Bulgarian split squat z pauzą", "Paused Bulgarian split squat", "Zaawansowany", "3 x 8-10/stronę", "2-2-1-0",
         "Bulgarian split squat z większym ciężarem", "Split squat bez podniesionej nogi z tyłu",
         "2-sekundowa pauza na dole maksymalizuje napięcie mięśniowe",
         "Odbijanie się od dołu bez pauzy"),
        ("Split squat (przysiad rozkroczny)", "Split squat", "Początkujący", "4 x 10-12/stronę", "2-0-1-0",
         "Bulgarian split squat (tylna noga podniesiona)", "Split squat bez obciążenia",
         "Statyczna pozycja rozkroczna, tylko ruch w górę i dół",
         "Zbyt krótki rozkrok utrudniający równowagę"),
        ("Wykroki w miejscu", "Stationary lunge", "Początkujący", "4 x 10-12/stronę", "2-0-1-0",
         "Wykroki chodzone", "Wykroki w miejscu bez obciążenia",
         "Kolano tylnej nogi kontrolowanie opada blisko podłogi",
         "Odrywanie pięty przedniej nogi od podłogi"),
        ("Wykroki chodzone", "Walking lunge", "Średni", "3 x 12-14/stronę", "2-0-1-0",
         "Wykroki chodzone z większym ciężarem", "Wykroki w miejscu",
         "Płynne przejście krok po kroku, tułów wyprostowany",
         "Zbyt duże pochylenie tułowia do przodu podczas kroku"),
        ("Wykroki w bok (lateral lunge)", "Lateral lunge", "Średni", "3 x 10-12/stronę", "2-0-1-0",
         "Lateral lunge z hantlami", "Lateral lunge bez obciążenia",
         "Biodra odsunięte do tyłu w kierunku kroku bocznego, druga noga wyprostowana",
         "Zginanie kolana nieruchomej nogi (powinno być prawie wyprostowane)"),
        ("Wykroki skośne (curtsy lunge)", "Curtsy lunge", "Zaawansowany", "3 x 10-12/stronę", "2-0-1-0",
         "Curtsy lunge z obciążeniem", "Wykroki w miejscu (klasyczne)",
         "Noga zakrocz za i za linię ciała, kolano skierowane lekko na zewnątrz",
         "Utrata równowagi z powodu zbyt dużego skrzyżowania nóg"),
        ("Step-up na ławeczkę", "Step-up", "Początkujący", "4 x 10-12/stronę", "2-0-1-0",
         "Step-up z hantlami", "Step-up na niższe podwyższenie",
         "Cała stopa na podwyższeniu, wstawaj kontrolując siłą przedniej nogi",
         "Odpychanie się tylną nogą (przenosi pracę z przedniej nogi)", ["Masa własna", "Ławeczka", "Hantle"]),
        ("Step-up z podniesieniem kolana", "Step-up with knee drive", "Zaawansowany", "3 x 10-12/stronę", "2-0-1-1",
         "Step-up z podskokiem na szczycie", "Step-up klasyczny (bez podniesienia kolana)",
         "Na szczycie dynamicznie unieś kolano tylnej nogi do wysokości bioder",
         "Utrata równowagi przy dynamicznym unoszeniu kolana", ["Masa własna", "Ławeczka"]),
        ("Skater lunge (boczne wypady dynamiczne)", "Skater lunge", "Zaawansowany", "3 x 10-12/stronę", "wybuchowo",
         "Skater lunge z większym zakresem (dalszy skok)", "Wykroki w bok (statyczne)",
         "Dynamiczny skok w bok z lądowaniem na jednej nodze, druga z tyłu",
         "Sztywne lądowanie bez amortyzacji kolanem"),
    ],
)

add_family(
    "Nogi", ["Pośladki", "Plecy"], ["Hantle"], "Siłowe",
    "Zawias biodrowy (hip hinge)",
    [
        "Ruch inicjowany z bioder, nie z kolan czy dolnych pleców",
        "Grzbiet neutralny przez cały zakres ruchu",
        "Hantle/ciężar blisko nóg przez cały ruch",
    ],
    [
        "Okrąglenie odcinka lędźwiowego pod obciążeniem",
        "Inicjowanie ruchu zgięciem kolan zamiast biodrami",
    ],
    [
        ("RDL jednonóż", "Single-leg RDL (dumbbell)", "Zaawansowany", "3 x 8-10/stronę", "3-0-1-0",
         "Single-leg RDL z większym ciężarem", "RDL dwunóż (klasyczny)",
         "Noga zapasowa wyprostowana do tyłu, tworzy linię z tułowiem",
         "Rotacja bioder w trakcie unoszenia nogi do tyłu"),
        ("Martwy ciąg sumo z hantlami", "Sumo deadlift (dumbbell)", "Średni", "4 x 8-10", "2-0-1-0",
         "Sumo deadlift z większym ciężarem", "RDL klasyczny (węższy rozstaw)",
         "Szeroki rozstaw stóp, palce na zewnątrz, hantle między nogami",
         "Zaokrąglanie grzbietu podczas podnoszenia ciężaru z podłogi"),
        ("Good morning z hantlem na plecach", "Dumbbell good morning", "Zaawansowany", "3 x 10-12", "3-0-1-0",
         "Good morning z większym ciężarem", "Good morning z gumą oporową",
         "Kolana lekko ugięte, zawias tylko w biodrach, grzbiet neutralny",
         "Zginanie w odcinku lędźwiowym zamiast w stawach biodrowych"),
        ("Kettlebell swing (imitacja hantlem)", "Dumbbell swing", "Średni", "4 x 15-20", "wybuchowo",
         "Swing z większym ciężarem", "RDL klasyczny (bez dynamiki)",
         "Wybuchowe wyprostowanie bioder napędza ruch ciężaru do przodu, nie ramiona",
         "Podnoszenie ciężaru ramionami zamiast wyprostem bioder"),
    ],
)

add_family(
    "Nogi", ["Pośladki", "Łydki"], ["Masa własna"], "Izometryczne",
    "Izometria - przysiad statyczny",
    [
        "Kolana w linii ze stopami przez cały czas utrzymania",
        "Napięte mięśnie ud, spokojny oddech mimo napięcia",
    ],
    [
        "Zapadanie kolan do środka podczas utrzymania",
        "Zbyt wysoka pozycja (niewystarczające zgięcie kolan)",
    ],
    [
        ("Wall sit z piłką między kolanami", "Wall sit with ball squeeze", "Średni", "3 x 30-45s", "izometria",
         "Wall sit z dociążeniem na kolanach", "Wall sit klasyczny (bez ścisku)",
         "Dodatkowy ścisk piłki/poduszki między kolanami aktywuje przywodziciele",
         "Rozluźnianie ścisku kolan w trakcie utrzymania"),
        ("Wall sit na jednej nodze", "Single-leg wall sit", "Zaawansowany", "3 x 15-20s/stronę", "izometria",
         "Single-leg wall sit z dociążeniem", "Wall sit klasyczny (obie nogi)",
         "Jedna noga uniesiona przed siebie, druga utrzymuje kąt 90° w kolanie",
         "Opadanie bioder podczas balansowania na jednej nodze"),
        ("Przysiad statyczny w rozkroku (sumo hold)", "Sumo squat hold", "Początkujący", "3 x 30-40s", "izometria",
         "Sumo squat hold z hantlem", "Sumo squat hold z mniejszym zgięciem kolan",
         "Szeroki rozstaw, biodra na wysokości kolan, napięte przywodziciele",
         "Zbyt wysoka pozycja niewykorzystująca pełnego napięcia mięśniowego"),
    ],
)

add_family(
    "Nogi", ["Łydki"], ["Masa własna"], "Siłowe",
    "Izolacja - wspięcia na palce",
    [
        "Pełen zakres — od pełnego rozciągnięcia do maksymalnego wspięcia",
        "Krótka pauza na szczycie ruchu",
    ],
    [
        "Niepełny zakres ruchu (skrócone wspięcie)",
        "Zbyt szybkie, sprężynujące tempo bez kontroli",
    ],
    [
        ("Wspięcia na palce (calf raise)", "Standing calf raise", "Początkujący", "4 x 15-20", "1-1-1-0",
         "Wspięcia na jednej nodze", "Wspięcia z podparciem o ścianę",
         "Stanie na krawędzi stopnia dla większego zakresu ruchu",
         "Opieranie się całym ciężarem na piętach na starcie ruchu"),
        ("Wspięcia na palce na jednej nodze", "Single-leg calf raise", "Zaawansowany", "3 x 12-15/stronę", "1-1-1-0",
         "Wspięcia jednonóż z hantlem w ręce", "Wspięcia dwunóż (klasyczne)",
         "Druga noga lekko ugięta z tyłu, cały ciężar na nodze roboczej",
         "Przenoszenie części ciężaru na nogę 'odpoczywającą'"),
        ("Wspięcia na palce w przysiadzie (sumo)", "Sumo calf raise", "Średni", "3 x 15-20", "1-1-1-0",
         "Sumo calf raise z hantlem", "Wspięcia klasyczne (stopy równolegle)",
         "Szeroki rozstaw stóp, palce na zewnątrz — inny akcent na łydki",
         "Zbyt wąski rozstaw zmieniający cel ćwiczenia"),
    ],
)

add_family(
    "Nogi", ["Pośladki", "Brzuch"], ["Masa własna"], "Cardio",
    "Cykliczny - skoki (nogi)",
    [
        "Miękkie lądowanie z ugięciem kolan, amortyzacja przez całą stopę",
        "Stabilny tułów, napięty core podczas dynamicznych ruchów",
    ],
    [
        "Sztywne lądowanie na wyprostowanych kolanach",
        "Zbyt duże tempo powodujące utratę techniki",
    ],
    [
        ("Box jump (skoki na podwyższenie)", "Box jump", "Zaawansowany", "4 x 8-10", "wybuchowo",
         "Box jump na wyższe podwyższenie", "Jump squat (bez podwyższenia)",
         "Ląduj na całej stopie na podwyższeniu, schodź kontrolowanie (nie skacz w dół)",
         "Skakanie w dół z podwyższenia (duże obciążenie stawów)"),
        ("Broad jump (skok w dal)", "Broad jump", "Zaawansowany", "4 x 6-8", "wybuchowo",
         "Broad jump z większym zakresem", "Jump squat w miejscu",
         "Wymach ramion do przodu wspomaga długość skoku, miękkie lądowanie",
         "Lądowanie na wyprostowanych, sztywnych nogach"),
        ("Skip A (bieg technika kolan)", "A-skip drill", "Średni", "3 x 20-30m", "dynamiczne",
         "Skip A z większym tempem", "Marsz z wysokim unoszeniem kolan",
         "Wysokie unoszenie kolan w rytmicznym, kontrolowanym truchcie",
         "Zbyt niskie unoszenie kolan (utrata celu ćwiczenia)"),
    ],
)

# ======================================================================
# POŚLADKI (docelowo +27)
# ======================================================================

add_family(
    "Pośladki", ["Nogi", "Brzuch"], ["Masa własna"], "Siłowe",
    "Zgięcie i wyprost bioder",
    [
        "Pełny wyprost bioder na szczycie ruchu, napięte pośladki",
        "Brak przeprostu w odcinku lędźwiowym na górze",
    ],
    [
        "Przeprost lędźwi zamiast wyprostu w biodrach",
        "Niepełny zakres ruchu (brak pełnego wyprostu)",
    ],
    [
        ("Glute bridge jednonóż", "Single-leg glute bridge", "Średni", "3 x 10-12/stronę", "2-1-1-0",
         "Single-leg glute bridge z hantlem na biodrach", "Glute bridge dwunóż (klasyczny)",
         "Druga noga wyprostowana i uniesiona, biodra pozostają na równej wysokości",
         "Przekrzywianie bioder w stronę uniesionej nogi"),
        ("Glute bridge z pulsowaniem", "Glute bridge pulse", "Początkujący", "3 x 15-20", "1-0-1-0",
         "Glute bridge pulse z hantlem na biodrach", "Glute bridge statyczny (bez pulsowania)",
         "Małe, kontrolowane pulsowanie w górnej pozycji mostka",
         "Zbyt duża amplituda pulsowania (zmiana w pełny mostek)"),
        ("Hip thrust jednonóż na ławeczce", "Single-leg hip thrust", "Zaawansowany", "3 x 8-10/stronę", "2-1-1-0",
         "Single-leg hip thrust z hantlem", "Hip thrust dwunóż na ławeczce",
         "Górna część łopatek oparta o ławkę, jedna stopa na podłodze",
         "Rotacja bioder podczas pracy jedną nogą", ["Ławeczka"]),
        ("Frog pump (mostek żabka)", "Frog pump", "Początkujący", "3 x 15-20", "1-1-1-0",
         "Frog pump z hantlem na biodrach", "Frog pump bez obciążenia",
         "Podeszwy stóp złączone, kolana rozłożone na boki — akcent na dolne pośladki",
         "Zbyt małe rozłożenie kolan (mniejszy zakres ruchu)"),
        ("Marsz w mostku (glute bridge march)", "Glute bridge march", "Średni", "3 x 10-12/stronę", "2-1-1-0",
         "Glute bridge march z hantlem na biodrach", "Glute bridge march bez obciążenia",
         "Utrzymuj biodra wysoko i stabilnie, unosząc kolana na przemian",
         "Opadanie bioder przy unoszeniu kolana"),
        ("Kickback pośladkowy w podporze", "Glute kickback (quadruped)", "Początkujący", "3 x 12-15/stronę", "2-0-2-0",
         "Kickback z gumą oporową na kostce", "Kickback bez obciążenia (mniejszy zakres)",
         "Wyprost nogi do tyłu i góry, kolano zgięte pod 90° na starcie",
         "Wyginanie odcinka lędźwiowego dla większego zakresu ruchu", ["Masa własna", "Gumy oporowe"]),
        ("Fire hydrant (otwieranie bioder w podporze)", "Fire hydrant", "Początkujący", "3 x 12-15/stronę", "2-0-2-0",
         "Fire hydrant z gumą oporową nad kolanami", "Fire hydrant bez obciążenia",
         "Kolano unoszone na bok z zachowaniem kąta 90°, stabilna miednica",
         "Rotacja tułowia w stronę unoszonej nogi", ["Masa własna", "Gumy oporowe"]),
        ("Donkey kick (osioł)", "Donkey kick", "Początkujący", "3 x 12-15/stronę", "2-0-2-0",
         "Donkey kick z gumą oporową", "Donkey kick bez obciążenia",
         "Kopnięcie stopą w górę z zachowaniem kąta 90° w kolanie",
         "Wyprostowywanie nogi zamiast utrzymania kąta 90°", ["Masa własna", "Gumy oporowe"]),
    ],
)

add_family(
    "Pośladki", ["Nogi"], ["Gumy oporowe"], "Siłowe",
    "Izolacja - odwodzenie bioder (guma)",
    [
        "Guma nad kolanami lub na kostkach, napięcie przez cały ruch",
        "Stabilna miednica, minimalna rotacja tułowia",
    ],
    [
        "Rotacja tułowia dla 'pomocy' w odwodzeniu",
        "Zbyt szybkie, niekontrolowane ruchy tracące napięcie gumy",
    ],
    [
        ("Monster walk (chód z gumą)", "Monster walk", "Średni", "3 x 10-12 kroków/stronę", "kontrolowane",
         "Monster walk z mocniejszą gumą", "Monster walk z lżejszą gumą",
         "Krok na boki i do przodu w half-squat, guma na kostkach lub nad kolanami",
         "Wyprostowywanie się między krokami (utrata napięcia)"),
        ("Odwodzenie bioder w leżeniu bokiem", "Side-lying hip abduction", "Początkujący", "3 x 15-20/stronę", "2-0-2-0",
         "Odwodzenie bokiem z gumą oporową", "Odwodzenie bokiem bez obciążenia",
         "Leżenie na boku, unoszenie górnej nogi prosto w górę",
         "Rotacja nogi do przodu podczas unoszenia (zmiana wzorca ruchu)"),
        ("Clamshell (otwieranie muszli)", "Clamshell", "Początkujący", "3 x 15-20/stronę", "2-0-2-0",
         "Clamshell z gumą oporową nad kolanami", "Clamshell bez obciążenia",
         "Stopy złączone, otwieranie kolan jak muszla, biodra nieruchome",
         "Rotacja bioder do tyłu podczas otwierania kolana"),
        ("Odwodzenie bioder stojąc z gumą", "Standing band hip abduction", "Początkujący", "3 x 15-20/stronę", "2-0-2-0",
         "Odwodzenie stojąc z mocniejszą gumą", "Odwodzenie stojąc bez obciążenia",
         "Guma na kostkach, odwodzenie nogi na bok przy stabilnym tułowiu",
         "Przechylanie tułowia w stronę przeciwną do ruchu nogi"),
    ],
)

add_family(
    "Pośladki", ["Nogi", "Brzuch"], ["Masa własna"], "Siłowe",
    "Jednonóż zawias biodrowy (pośladki)",
    [
        "Stabilna miednica, minimalna rotacja podczas pracy jedną nogą",
        "Kontrolowane tempo w obu fazach ruchu",
    ],
    [
        "Utrata równowagi z powodu zbyt szybkiego tempa",
        "Rotacja bioder podczas jednostronnej pracy",
    ],
    [
        ("B-stand RDL (pół-jednonóż)", "B-stand single-leg RDL", "Średni", "3 x 10-12/stronę", "3-0-1-0",
         "B-stand RDL z hantlami", "RDL dwunóż (klasyczny)",
         "Tylna stopa lekko przesunięta do tyłu na palcach dla wsparcia równowagi",
         "Zbyt duże obciążenie tylnej stopy (powinna tylko wspierać balans)"),
        ("Skater deadlift (jednonóż dynamiczny)", "Skater deadlift", "Zaawansowany", "3 x 8-10/stronę", "2-0-1-0",
         "Skater deadlift z hantlami", "B-stand RDL (łatwiejszy wariant)",
         "Dynamiczne przejście z zawiasu do wyprostu, jak w ruchu łyżwiarza",
         "Utrata kontroli grzbietu podczas dynamicznego przejścia"),
    ],
)

add_family(
    "Pośladki", ["Nogi"], ["Masa własna"], "Cardio",
    "Cykliczny - skoki z odwodzeniem (pośladki)",
    [
        "Kontrolowane lądowanie, napięte pośladki w fazie odwodzenia",
        "Stabilny tułów przez cały dynamiczny ruch",
    ],
    [
        "Zbyt szybkie tempo tracące kontrolę lądowania",
        "Brak pełnego zakresu odwodzenia nóg",
    ],
    [
        ("Skip skoki boczne (lateral hops)", "Lateral hop", "Średni", "3 x 10-12/stronę", "dynamiczne",
         "Lateral hop z większym zakresem", "Step touch (bez skoku)",
         "Skok na boki na jednej nodze z miękkim lądowaniem",
         "Sztywne lądowanie bez amortyzacji kolanem"),
    ],
)

# ======================================================================
# BRZUCH (docelowo +41)
# ======================================================================

add_family(
    "Brzuch", ["Plecy"], ["Masa własna"], "Izometryczne",
    "Izometria - stabilizacja tułowia",
    [
        "Ciało w jednej linii od głowy do stóp, bez opadania/wypychania bioder",
        "Napięty core przez cały czas utrzymania, spokojny oddech",
    ],
    [
        "Opadanie bioder (utrata napięcia core)",
        "Wypychanie bioder zbyt wysoko (zmniejsza obciążenie brzucha)",
    ],
    [
        ("Plank z unoszeniem nogi", "Plank leg lift", "Średni", "3 x 10-12/stronę", "izometria",
         "Plank z unoszeniem nogi i ręki naprzemiennie", "Plank klasyczny (bez unoszenia)",
         "Unoszenie jednej nogi kilka centymetrów, biodra nieruchome",
         "Rotacja bioder podczas unoszenia nogi"),
        ("Side plank (podpór bokiem)", "Side plank", "Średni", "3 x 20-30s/stronę", "izometria",
         "Side plank z uniesioną górną nogą", "Side plank z ugiętymi kolanami (łatwiejszy)",
         "Ciało w jednej linii z boku, biodra uniesione, nie opadają",
         "Opadanie bioder w dół podczas utrzymania"),
        ("Side plank z rotacją (thread the needle)", "Side plank with rotation", "Zaawansowany", "3 x 8-10/stronę", "2-1-1-0",
         "Side plank z rotacją i dociążeniem", "Side plank statyczny (bez rotacji)",
         "Górna ręka przesuwa się pod tułowiem i z powrotem w górę, obracając klatkę",
         "Opadanie bioder podczas rotacji ramienia"),
        ("Plank z przesuwaniem rąk (plank walk-out)", "Plank walk-out", "Średni", "3 x 8-10", "kontrolowane",
         "Plank walk-out z pompką na końcu", "Plank walk-out z mniejszym zakresem",
         "Chodzenie dłońmi do przodu i z powrotem, biodra stabilne",
         "Zapadanie bioder podczas maksymalnego wysunięcia rąk"),
        ("RKC plank (maksymalne napięcie)", "RKC plank", "Zaawansowany", "3 x 15-20s", "izometria",
         "RKC plank z dłuższym utrzymaniem", "Plank klasyczny (mniejsze napięcie)",
         "Maksymalne napięcie całego ciała — pośladki, quady, core spięte jak przy PR",
         "Rozluźnianie napięcia w trakcie krótkiego utrzymania"),
        ("Plank z dotykiem stopy (spiderman plank)", "Spiderman plank", "Średni", "3 x 10-12/stronę", "izometria",
         "Spiderman plank z pompką między dotykami", "Plank klasyczny (bez dotyku stopy)",
         "Kolano przyciągane do łokcia po tej samej stronie, biodra stabilne",
         "Opadanie bioder podczas przyciągania kolana"),
        ("Plank na przedramionach z piłką", "Stability ball plank", "Zaawansowany", "3 x 20-30s", "izometria",
         "Plank na piłce z unoszeniem ręki", "Plank na przedramionach na podłodze",
         "Niestabilna powierzchnia (piłka) wymaga dodatkowej aktywacji core",
         "Zbyt duże napięcie w barkach zamiast w core"),
        ("Bear plank (podpór na dłoniach i palcach stóp, kolana nad podłogą)", "Bear plank", "Średni", "3 x 20-30s", "izometria",
         "Bear plank z unoszeniem ręki/nogi", "Plank klasyczny na przedramionach",
         "Kolana kilka centymetrów nad podłogą, biodra na wysokości pleców",
         "Zbyt wysokie biodra (zmiana w pozycję psa)"),
    ],
)

add_family(
    "Brzuch", ["Nogi"], ["Drążek"], "Siłowe",
    "Zgięcie bioder w zwisie",
    [
        "Minimalne kołysanie ciała, ruch kontrolowany z brzucha",
        "Pełny zakres — od wyprostu do maksymalnego zgięcia bioder/kolan",
    ],
    [
        "Kołysanie ciałem dla 'wystrzelenia' nóg (kipping)",
        "Zbyt szybkie tempo bez kontroli ekscentrycznej",
    ],
    [
        ("Podnoszenie kolan w zwisie", "Hanging knee raise", "Średni", "3 x 12-15", "2-0-1-0",
         "Hanging leg raise (wyprostowane nogi)", "Podnoszenie kolan z podparciem",
         "Kolana przyciągane do klatki, minimalne kołysanie",
         "Kołysanie ciałem zamiast izolowanej pracy brzucha"),
        ("Podnoszenie nóg L-sit w zwisie", "Hanging L-sit raise", "Zaawansowany", "3 x 6-8", "2-1-1-0",
         "Hanging L-sit raise z utrzymaniem na szczycie", "Hanging leg raise (bez pauzy)",
         "Nogi wyprostowane unoszone do kąta 90°, pauza na szczycie",
         "Uginanie kolan dla ułatwienia dotarcia do góry"),
        ("Toes to bar (nogi do drążka)", "Toes to bar", "Zaawansowany", "3 x 6-10", "2-0-1-0",
         "Toes to bar z większym zakresem kontroli", "Hanging leg raise (mniejszy zakres)",
         "Nogi wyprostowane dotykają drążka, kontrolowany powrót",
         "Nadmierne kołysanie ciała (kipping) dla ułatwienia ruchu"),
        ("Windshield wipers (wycieraczki)", "Hanging windshield wipers", "Zaawansowany", "3 x 6-8/stronę", "3-0-2-0",
         "Windshield wipers z wyprostowanymi nogami", "Windshield wipers z ugiętymi kolanami",
         "Nogi uniesione, przenoszone na boki jak wycieraczka, ramiona stabilne",
         "Zbyt duża amplituda ruchu tracąca kontrolę core"),
    ],
)

add_family(
    "Brzuch", ["Nogi"], ["Masa własna"], "Siłowe",
    "Izometria - zgięcie tułowia",
    [
        "Napięty brzuch przez cały ruch, dolne plecy przyciśnięte do podłogi",
        "Kontrolowane tempo, bez szarpania",
    ],
    [
        "Odrywanie dolnych pleców od podłogi (kompensacja lędźwiami)",
        "Szarpanie/zamach zamiast kontrolowanego napięcia brzucha",
    ],
    [
        ("Hollow hold z rozciągnięciem", "Hollow hold (full extension)", "Zaawansowany", "3 x 20-30s", "izometria",
         "Hollow hold z pulsowaniem", "Hollow hold z ugiętymi kolanami (łatwiejszy)",
         "Ramiona i nogi wyprostowane, dolne plecy przyklejone do podłogi",
         "Odrywanie dolnych pleców od podłogi"),
        ("Hollow rock (kołyska)", "Hollow rock", "Zaawansowany", "3 x 10-15", "kontrolowane",
         "Hollow rock z większą amplitudą", "Hollow hold statyczny (bez kołysania)",
         "Delikatne kołysanie w pozycji hollow, zachowując napięty core",
         "Utrata pozycji hollow (odrywanie pleców) podczas kołysania"),
        ("Dead bug", "Dead bug", "Początkujący", "3 x 10-12/stronę", "2-1-1-0",
         "Dead bug z gumą oporową między ręką i nogą", "Dead bug z mniejszym zakresem",
         "Przeciwna ręka i noga wysuwane równocześnie, dolne plecy przyklejone",
         "Odrywanie dolnych pleców od podłogi podczas wysuwania kończyn"),
        ("V-up (składanie scyzoryk)", "V-up", "Zaawansowany", "3 x 10-12", "2-0-1-0",
         "V-up z dociążeniem", "Tuck-up (ugiete kolana, łatwiejszy)",
         "Jednoczesne unoszenie tułowia i wyprostowanych nóg, tworząc literę V",
         "Uginanie kolan zamiast utrzymania wyprostowanych nóg"),
        ("Tuck-up (składanie z ugiętymi kolanami)", "Tuck-up", "Początkujący", "3 x 12-15", "2-0-1-0",
         "V-up (wyprostowane nogi)", "Crunch klasyczny (mniejszy zakres)",
         "Kolana przyciągane do klatki jednocześnie z unoszeniem tułowia",
         "Szarpanie szyją/głową zamiast pracy brzucha"),
        ("Reverse crunch", "Reverse crunch", "Początkujący", "3 x 15-20", "2-0-1-0",
         "Reverse crunch z gumą na kostkach", "Reverse crunch z mniejszym zakresem",
         "Biodra unoszone od podłogi przez skrócenie dolnej części brzucha",
         "Używanie zamachu nóg zamiast kontrolowanego skrócenia brzucha"),
        ("Flutter kicks (nożyce)", "Flutter kicks", "Początkujący", "3 x 20-30s", "dynamiczne",
         "Flutter kicks z wyższym uniesieniem tułowia", "Flutter kicks z ugiętymi kolanami",
         "Dolne plecy przyciśnięte do podłogi, małe, szybkie ruchy nóg",
         "Odrywanie dolnych pleców od podłogi"),
        ("Scissor kicks (nożyce krzyżowe)", "Scissor kicks", "Początkujący", "3 x 20-30s", "dynamiczne",
         "Scissor kicks z większą amplitudą", "Scissor kicks z ugiętymi kolanami",
         "Nogi krzyżują się nad sobą w powietrzu, dolne plecy stabilne",
         "Zbyt wysokie unoszenie nóg (zmniejsza napięcie brzucha)"),
    ],
)

add_family(
    "Brzuch", ["Plecy"], ["Masa własna"], "Siłowe",
    "Rotacja tułowia",
    [
        "Rotacja z bioder i tułowia, nie tylko z ramion",
        "Kontrolowane tempo w obu kierunkach ruchu",
    ],
    [
        "Rotacja tylko ramionami bez zaangażowania core",
        "Zbyt szybkie, niekontrolowane szarpanie",
    ],
    [
        ("Russian twist z piłką/hantlem", "Weighted Russian twist", "Średni", "3 x 12-15/stronę", "2-0-1-0",
         "Russian twist z większym ciężarem", "Russian twist bez obciążenia",
         "Stopy uniesione dla większej trudności, rotacja tułowia z ciężarem",
         "Zbyt szybkie tempo bez kontroli rotacji", ["Hantle"]),
        ("Woodchopper z gumą oporową", "Standing band woodchopper", "Średni", "3 x 12-15/stronę", "2-0-2-0",
         "Woodchopper z większym oporem gumy", "Woodchopper z mniejszym oporem",
         "Ruch po przekątnej od wysoka do niska, rotacja z bioder",
         "Zginanie tylko w ramionach bez rotacji tułowia", ["Gumy oporowe"]),
        ("Bicycle crunch", "Bicycle crunch", "Początkujący", "3 x 15-20/stronę", "2-0-1-0",
         "Bicycle crunch z wolniejszym, kontrolowanym tempem", "Bicycle crunch z mniejszym zakresem",
         "Łokieć w kierunku przeciwnego kolana, dolne plecy przy podłodze",
         "Szarpanie szyją podczas skrętu"),
        ("Standing oblique crunch", "Standing oblique crunch", "Początkujący", "3 x 15-20/stronę", "2-0-1-0",
         "Standing oblique crunch z hantlem", "Standing oblique crunch bez obciążenia",
         "Kolano unoszone w bok jednocześnie ze zgięciem tułowia w tę samą stronę",
         "Zbyt duże pochylenie tułowia do przodu (zmiana wzorca)"),
        ("Side bend z hantlem", "Dumbbell side bend", "Początkujący", "3 x 15-20/stronę", "2-0-1-0",
         "Side bend z większym ciężarem", "Side bend bez obciążenia",
         "Zginanie tylko w bok, tułów nieruchomy w innych płaszczyznach",
         "Rotacja tułowia do przodu/tyłu podczas zginania w bok", ["Hantle"]),
    ],
)

add_family(
    "Brzuch", ["Nogi", "Barki"], ["Masa własna"], "Siłowe",
    "Złożony - całe ciało (core)",
    [
        "Napięty core przez cały złożony ruch, stabilna miednica",
        "Kontrolowane tempo, priorytet techniki nad szybkością",
    ],
    [
        "Opadanie bioder podczas złożonego, dynamicznego ruchu",
        "Utrata napięcia core dla zwiększenia tempa",
    ],
    [
        ("Bear crawl (chód niedźwiedzia)", "Bear crawl", "Średni", "3 x 10-12m", "kontrolowane",
         "Bear crawl do tyłu", "Bear crawl w miejscu (bez przemieszczania)",
         "Kolana blisko podłogi, przemieszczanie przeciwstawną ręką i nogą",
         "Zbyt wysokie biodra (utrata napięcia core)"),
        ("Crab walk (chód kraba)", "Crab walk", "Początkujący", "3 x 10-12m", "kontrolowane",
         "Crab walk z podniesioną nogą między krokami", "Crab walk w miejscu",
         "Biodra uniesione, dłonie i stopy na podłodze, przemieszczanie się do przodu/tyłu",
         "Opadanie bioder w trakcie przemieszczania"),
        ("Inchworm (gąsienica)", "Inchworm", "Początkujący", "3 x 8-10", "kontrolowane",
         "Inchworm z pompką na końcu", "Inchworm bez pompki",
         "Chodzenie dłońmi do przodu do podporu, następnie przyciąganie stóp",
         "Uginanie kolan podczas chodzenia dłońmi do przodu"),
    ],
)

# ======================================================================
# CARDIO (docelowo +31)
# ======================================================================

add_family(
    "Cardio", ["Nogi", "Brzuch"], ["Masa własna"], "Cardio",
    "Cykliczny - bieg w podporze",
    [
        "Napięty core, biodra stabilne podczas dynamicznego ruchu nóg",
        "Krótki, szybki kontakt stóp z podłogą",
    ],
    [
        "Opadanie/wypychanie bioder podczas dynamicznego ruchu",
        "Zbyt duże obciążenie ramion (garbienie się)",
    ],
    [
        ("Mountain climbers na wolno", "Slow mountain climbers", "Początkujący", "3 x 30-40s", "kontrolowane",
         "Mountain climbers klasyczne (szybkie)", "Mountain climbers z podparciem na ławce",
         "Pełne przyciąganie kolana do klatki w kontrolowanym tempie",
         "Niepełny zakres ruchu kolana", ["Masa własna"]),
        ("Mountain climbers skośne (cross-body)", "Cross-body mountain climbers", "Średni", "3 x 30-40s", "dynamiczne",
         "Cross-body mountain climbers z większym tempem", "Mountain climbers klasyczne",
         "Kolano przyciągane do przeciwnego łokcia, rotacja z bioder",
         "Rotacja tylko ramionami bez pracy bioder"),
        ("High knees w podporze (plank high knees)", "Plank high knee run", "Zaawansowany", "3 x 30s", "dynamiczne",
         "Plank high knee run z większym tempem", "Mountain climbers na wolno",
         "Bardzo szybkie, drobne kroki w podporze, biodra stabilne",
         "Zbyt duże skoki bioder w górę i dół"),
    ],
)

add_family(
    "Cardio", ["Nogi", "Pośladki"], ["Masa własna"], "Cardio",
    "Cykliczny - skoki (cardio)",
    [
        "Miękkie lądowanie z ugięciem kolan",
        "Stabilny rytm oddechu zsynchronizowany z ruchem",
    ],
    [
        "Sztywne lądowanie bez amortyzacji",
        "Wstrzymywanie oddechu podczas wysiłku",
    ],
    [
        ("Jumping jacks z krzyżowaniem rąk", "Cross jumping jacks", "Początkujący", "3 x 30-40s", "dynamiczne",
         "Jumping jacks z większym tempem", "Jumping jacks klasyczne",
         "Ramiona krzyżują się przed sobą zamiast łączyć nad głową",
         "Brak synchronizacji rąk i nóg"),
        ("Star jumps (skoki gwiazda)", "Star jump", "Średni", "3 x 15-20", "wybuchowo",
         "Star jump z większą wysokością", "Jumping jacks klasyczne",
         "Wybuchowy skok z pełnym rozłożeniem rąk i nóg w powietrzu",
         "Zbyt niska wysokość skoku (utrata efektu treningowego)"),
        ("Squat jacks (przysiad z jumping jack)", "Squat jack", "Średni", "3 x 15-20", "dynamiczne",
         "Squat jack z większym tempem", "Jumping jacks klasyczne (bez przysiadu)",
         "Połączenie przysiadu sumo z ruchem ramion jumping jack",
         "Zbyt wysoka pozycja bioder (utrata elementu przysiadu)"),
        ("High knees (bieg z wysokim unoszeniem kolan)", "High knees", "Początkujący", "3 x 30-40s", "dynamiczne",
         "High knees z większym tempem", "March in place (marsz w miejscu)",
         "Kolana unoszone do wysokości pasa, ramiona pracują naprzemiennie",
         "Zbyt niskie unoszenie kolan"),
        ("Butt kicks (bieg z piętami do pośladków)", "Butt kicks", "Początkujący", "3 x 30-40s", "dynamiczne",
         "Butt kicks z większym tempem", "March in place",
         "Pięty dotykają pośladków w szybkim, drobnym truchcie",
         "Zbyt duże pochylenie tułowia do przodu"),
        ("Tuck jumps (skoki z przyciąganiem kolan)", "Tuck jump", "Zaawansowany", "3 x 8-10", "wybuchowo",
         "Tuck jump z większą wysokością", "Jump squat (bez przyciągania kolan)",
         "Kolana przyciągane do klatki w najwyższym punkcie skoku",
         "Lądowanie na sztywnych nogach bez amortyzacji"),
    ],
)

add_family(
    "Cardio", ["Nogi", "Brzuch"], ["Masa własna"], "Cardio",
    "Złożony - całe ciało (cardio)",
    [
        "Płynne przejścia między fazami ruchu, kontrolowane tempo",
        "Napięty core stabilizuje tułów w dynamicznym ćwiczeniu",
    ],
    [
        "Utrata techniki (np. zaokrąglanie grzbietu) pod presją tempa",
        "Zbyt szybkie tempo utrudniające pełny zakres ruchu",
    ],
    [
        ("Burpee bez pompki", "Burpee (no push-up)", "Początkujący", "4 x 8-10", "dynamiczne",
         "Burpee klasyczny z pompką", "Half burpee (bez wyskoku)",
         "Łatwiejsza wersja dla początkujących — bez fazy pompki",
         "Zbyt szybkie, niekontrolowane przejście do podporu"),
        ("Burpee z podciąganiem", "Burpee pull-up", "Zaawansowany", "3 x 5-8", "dynamiczne",
         "Burpee pull-up z większym tempem", "Burpee klasyczny (bez podciągania)",
         "Po wyskoku dodatkowe podciągnięcie na drążku nad głową",
         "Utrata techniki podciągania z powodu zmęczenia po burpee", ["Masa własna", "Drążek"]),
        ("Half burpee (bez wyskoku)", "Half burpee", "Początkujący", "4 x 10-12", "kontrolowane",
         "Burpee bez pompki", "Squat thrust (tylko wejście do podporu)",
         "Bez końcowego wyskoku — dobra baza do nauki pełnego burpee",
         "Zbyt szybkie tempo tracące kontrolę przejść"),
        ("Squat thrust", "Squat thrust", "Początkujący", "3 x 10-12", "kontrolowane",
         "Half burpee (z wyskokiem)", "Squat thrust w wolniejszym tempie",
         "Przysiad, wejście do podporu, powrót do przysiadu — bez pompki i wyskoku",
         "Zaokrąglanie grzbietu podczas wejścia do podporu"),
        ("Devil press (imitacja hantlami)", "Devil press", "Zaawansowany", "3 x 8-10", "dynamiczne",
         "Devil press z większym ciężarem", "Burpee klasyczny (bez hantli)",
         "Burpee z hantlami zakończone wyciśnięciem obu hantli nad głowę",
         "Zaokrąglanie grzbietu podczas podnoszenia hantli z podłogi", ["Hantle"]),
    ],
)

add_family(
    "Cardio", ["Nogi", "Brzuch"], ["Skakanka"], "Cardio",
    "Cykliczny - skoki ze skakanką",
    [
        "Skoki niskie i szybkie, lądowanie na śródstopiu",
        "Nadgarstki wykonują ruch obrotowy, nie całe ramiona",
    ],
    [
        "Zbyt wysokie skoki (męczące i niepotrzebne)",
        "Poruszanie całymi ramionami zamiast nadgarstkami",
    ],
    [
        ("Skakanka - bieg w miejscu", "Jump rope running", "Średni", "3 x 45-60s", "dynamiczne",
         "Skakanka bieg z większym tempem", "Skakanka basic (obunóż)",
         "Naprzemienne unoszenie kolan jak podczas biegu, rytm skakanki",
         "Zbyt wysokie unoszenie kolan zaburzające rytm skakanki"),
        ("Skakanka - krok bokiem", "Jump rope side-to-side", "Średni", "3 x 45-60s", "dynamiczne",
         "Skakanka krok bokiem z większym zakresem", "Skakanka basic",
         "Skoki na boki zamiast w miejscu, zachowując rytm skakanki",
         "Zbyt duży zakres bocznego ruchu zaburzający rytm"),
        ("Skakanka - podwójne obroty (double under)", "Double under", "Zaawansowany", "3 x 20-30", "wybuchowo",
         "Double under w seriach bez przerw", "Skakanka basic",
         "Wyższy, mocniejszy skok pozwalający na dwa obroty skakanki w powietrzu",
         "Zbyt niski skok niewystarczający na drugi obrót"),
        ("Skakanka - krzyżowanie rąk", "Crossover jump rope", "Zaawansowany", "3 x 20-30", "dynamiczne",
         "Crossover jump rope w seriach ciągłych", "Skakanka basic",
         "Krzyżowanie przedramion przed sobą podczas skoku",
         "Zbyt wczesne/zbyt późne krzyżowanie zaburzające rytm"),
    ],
)

add_family(
    "Cardio", ["Nogi"], ["Masa własna"], "Cardio",
    "Cykliczny - step (cardio)",
    [
        "Stabilny rytm, kontrolowane stąpanie na podwyższeniu",
        "Napięty core podczas dynamicznych zmian kierunku",
    ],
    [
        "Zbyt szybkie tempo prowadzące do potknięć",
        "Niepełne stawianie stopy na podwyższeniu",
    ],
    [
        ("Step-up cardio (szybkie tempo)", "Fast step-up", "Średni", "3 x 40-50s", "dynamiczne",
         "Step-up cardio z hantlami", "Step-up w wolnym tempie",
         "Szybka wymiana nóg na niskim podwyższeniu, stabilny rytm",
         "Niepełne stawianie stopy (tylko palce dotykają podwyższenia)", ["Masa własna", "Ławeczka"]),
        ("Lateral shuffle (bieg bokiem)", "Lateral shuffle", "Początkujący", "3 x 30-40s", "dynamiczne",
         "Lateral shuffle z większym tempem", "March in place",
         "Niska pozycja, szybkie kroki boczne bez skrzyżowania stóp",
         "Skrzyżowanie stóp podczas bocznego biegu"),
    ],
)

# ======================================================================
# MOBILNOŚĆ (docelowo +22)
# ======================================================================

add_family(
    "Mobilność", ["Plecy", "Brzuch"], ["Masa własna"], "Mobilność",
    "Segmentowa mobilizacja kręgosłupa",
    [
        "Ruch płynny, segment po segmencie kręgosłupa",
        "Synchronizacja ruchu z oddechem — wdech/wydech na przemian",
    ],
    [
        "Zbyt szybkie tempo tracące kontrolę segmentową",
        "Ruch tylko w odcinku lędźwiowym (brak mobilizacji całego kręgosłupa)",
    ],
    [
        ("Cat-cow z pauzą", "Cat-cow with pause", "Początkujący", "3 x 8-10", "wolno",
         "Cat-cow z większym zakresem", "Cat-cow bez pauzy",
         "Krótka pauza w każdej krańcowej pozycji dla lepszej mobilizacji",
         "Zbyt szybkie przechodzenie między pozycjami"),
        ("Thread the needle (nawlekanie igły)", "Thread the needle", "Początkujący", "3 x 6-8/stronę", "wolno",
         "Thread the needle z większą rotacją", "Thread the needle z mniejszym zakresem",
         "Rotacja klatki z ręką przesuwaną pod tułowiem, biodra stabilne",
         "Zbyt duża rotacja bioder (powinny być nieruchome)"),
        ("World's greatest stretch", "World's greatest stretch", "Średni", "3 x 5-6/stronę", "wolno",
         "World's greatest stretch z rotacją górnej części ciała", "Wersja bez rotacji górnej części",
         "Kompleksowy stretch łączący wykrok, rotację tułowia i ramienia",
         "Zbyt szybkie przechodzenie przez fazy ruchu"),
        ("Spine wave (fala kręgosłupa)", "Standing spine wave", "Początkujący", "3 x 8-10", "wolno",
         "Spine wave z większą amplitudą", "Cat-cow (na czworaka)",
         "W staniu, fala ruchu przez kręgosłup od góry do dołu",
         "Ruch tylko w jednym odcinku kręgosłupa"),
    ],
)

add_family(
    "Mobilność", ["Nogi", "Pośladki"], ["Masa własna"], "Mobilność",
    "Mobilizacja rotacji bioder",
    [
        "Ruch w pełnym, bezbolesnym zakresie stawu biodrowego",
        "Stabilna miednica podczas mobilizacji",
    ],
    [
        "Kompensacja ruchu przez wyginanie odcinka lędźwiowego",
        "Zbyt szybkie, dynamiczne ruchy bez kontroli",
    ],
    [
        ("90/90 hip switch (dynamiczny)", "90/90 hip switch", "Średni", "3 x 8-10/stronę", "kontrolowane",
         "90/90 hip switch z większym tempem", "90/90 hip stretch (statyczny)",
         "Płynne przechodzenie między dwiema pozycjami 90/90 na przemian",
         "Odrywanie bioder od podłogi podczas przejścia"),
        ("Leżący skręt bioder (lying hip rotation)", "Lying hip rotation stretch", "Początkujący", "3 x 8-10/stronę", "wolno",
         "Lying hip rotation z większym zakresem", "Lying hip rotation z mniejszym zakresem",
         "Kolana zgięte, opadanie na boki z zachowaniem kontaktu barków z podłogą",
         "Odrywanie barków od podłogi podczas skrętu"),
        ("Krążenia bioder w staniu (hip circles)", "Standing hip circles", "Początkujący", "3 x 8-10/kierunek", "wolno",
         "Hip circles z większym zakresem", "Hip circles z mniejszym zakresem",
         "Krążenie kolanem w powietrzu, stabilna druga noga",
         "Utrata równowagi z powodu zbyt szybkiego tempa"),
        ("Cossack squat (mobilizacja przywodzicieli)", "Cossack squat", "Zaawansowany", "3 x 6-8/stronę", "wolno",
         "Cossack squat z hantlem dla balastu", "Cossack squat z mniejszym zakresem",
         "Szeroki rozkrok, przenoszenie ciężaru na jedną nogę w głęboki przysiad boczny",
         "Odrywanie pięty nogi obciążonej od podłogi"),
    ],
)

add_family(
    "Mobilność", ["Nogi", "Pośladki"], ["Masa własna"], "Mobilność",
    "Rozciąganie statyczne - rotatory bioder",
    [
        "Rozciąganie do lekkiego dyskomfortu, nigdy do bólu",
        "Spokojny, głęboki oddech podczas utrzymania pozycji",
    ],
    [
        "Rozciąganie do bólu (ryzyko urazu)",
        "Wstrzymywanie oddechu podczas utrzymania pozycji",
    ],
    [
        ("Pigeon pose zaawansowany (z pochyleniem)", "Advanced pigeon pose", "Średni", "3 x 30-45s/stronę", "statyczne",
         "Pigeon pose z pochyleniem do przodu", "Pigeon pose klasyczny",
         "Pochylenie tułowia do przodu nad przednią nogą zwiększa rozciąganie",
         "Zbyt duże obciążenie kolana przedniej nogi"),
        ("Figure-4 stretch (leżący)", "Lying figure-4 stretch", "Początkujący", "3 x 30-45s/stronę", "statyczne",
         "Figure-4 stretch z większym zakresem (przyciąganie nogi)", "Figure-4 stretch bez przyciągania",
         "Kostka na kolanie przeciwnej nogi, delikatne przyciąganie za udo",
         "Zbyt mocne, szarpane przyciąganie nogi"),
        ("Frog stretch (żabka)", "Frog stretch", "Średni", "3 x 30-45s", "statyczne",
         "Frog stretch z większym rozstawem kolan", "Frog stretch z mniejszym rozstawem",
         "Kolana rozstawione szeroko, biodra opadają do tyłu delikatnie",
         "Zbyt szybkie, dynamiczne wchodzenie w pozycję"),
        ("Butterfly stretch (motylek)", "Butterfly stretch", "Początkujący", "3 x 30-45s", "statyczne",
         "Butterfly stretch z pochyleniem tułowia do przodu", "Butterfly stretch bez pochylenia",
         "Podeszwy stóp złączone, kolana opadają na boki, grzbiet neutralny",
         "Garbienie się podczas pochylania tułowia do przodu"),
    ],
)

add_family(
    "Mobilność", ["Barki", "Plecy"], ["Masa własna"], "Mobilność",
    "Mobilizacja klatki i barków",
    [
        "Ruch płynny w pełnym, bezbolesnym zakresie stawu barkowego/klatki",
        "Kontrolowane tempo, brak szarpania",
    ],
    [
        "Kompensacja ruchu przez wyginanie odcinka lędźwiowego",
        "Zbyt szybkie, dynamiczne ruchy bez kontroli zakresu",
    ],
    [
        ("Rozciąganie klatki w progu drzwi (doorway stretch)", "Doorway chest stretch", "Początkujący", "3 x 30-45s/stronę", "statyczne",
         "Doorway stretch z różnymi wysokościami ramienia", "Doorway stretch z mniejszym zakresem",
         "Przedramię na framudze, delikatny krok w przód rozciąga klatkę",
         "Zbyt mocne, szarpane wejście w rozciąganie"),
        ("Thoracic rotation na czworaka", "Quadruped thoracic rotation", "Początkujący", "3 x 8-10/stronę", "wolno",
         "Thoracic rotation z większym zakresem", "Thread the needle (mniejszy zakres)",
         "Rotacja klatki z ręką sięgającą ku sufitowi, biodra stabilne",
         "Rotacja z bioder zamiast z odcinka piersiowego kręgosłupa"),
    ],
)

# ======================================================================
# DOPEŁNIENIE DO CELU 278 (Nogi +21, Pośladki +12, Brzuch +13,
# Cardio +11 [w tym 'Bieżnia' — decyzja: dodać realne ćwiczenia na
# bieżni, żeby sprzęt zdefiniowany w AppConstants faktycznie był
# wykorzystywany], Mobilność +8)
# ======================================================================

# --- NOGI +21 -----------------------------------------------------------

add_family(
    "Nogi", ["Pośladki", "Brzuch"], ["Masa własna"], "Siłowe",
    "Przysiad (podstawowy wzorzec) — warianty",
    [
        "Kolana śledzą kierunek palców stóp, nie zapadają do środka",
        "Grzbiet neutralny, spojrzenie skierowane do przodu",
    ],
    [
        "Zapadanie kolan do środka podczas wstawania",
        "Odrywanie pięt od podłogi w dolnej fazie",
    ],
    [
        ("Goblet squat (przysiad z hantlem)", "Goblet squat", "Początkujący", "4 x 10-12", "2-0-1-0",
         "Goblet squat z większym ciężarem", "Przysiad bez obciążenia",
         "Hantel trzymany blisko klatki, łokcie mijają kolana w dolnej fazie",
         "Odsuwanie hantla od tułowia (utrata równowagi)", ["Hantle"]),
        ("Sumo squat (przysiad w szerokim rozkroku)", "Sumo squat", "Początkujący", "4 x 10-12", "2-0-1-0",
         "Sumo squat z hantlem", "Przysiad klasyczny (węższy rozstaw)",
         "Szeroki rozstaw stóp, palce skierowane na zewnątrz",
         "Zbyt wąski rozstaw kolan w dolnej fazie"),
        ("Squat pulse (przysiad z pulsowaniem)", "Squat pulse", "Średni", "3 x 15-20", "1-0-1-0",
         "Squat pulse z większym zakresem", "Przysiad statyczny (bez pulsowania)",
         "Małe, kontrolowane pulsowanie w dolnej pozycji przysiadu",
         "Zbyt duża amplituda pulsowania (zmiana w pełny przysiad)"),
        ("Pistol squat — asekuracja (progresja)", "Assisted pistol squat", "Zaawansowany", "3 x 5-6/stronę", "3-0-1-0",
         "Pistol squat pełny (bez asekuracji)", "Przysiad jednonóż na podwyższeniu (box pistol)",
         "Trzymanie się poręczy/framugi dla równowagi, druga noga wyprostowana do przodu",
         "Opadanie na piętę bez kontroli w dolnej fazie"),
        ("Box squat na wysokim podwyższeniu (przysiad płytszy)", "High box squat", "Średni", "4 x 8-10", "3-1-1-0",
         "High box squat z większym ciężarem", "Przysiad klasyczny (bez podwyższenia)",
         "Lekki dotyk wyższego pudła/krzesła pośladkami, bez siadania z pełnym ciężarem",
         "Pełne oparcie ciężaru na podwyższeniu (utrata napięcia)", ["Masa własna", "Ławeczka"]),
        ("Przysiad wąski (narrow stance squat)", "Narrow stance squat", "Początkujący", "3 x 12-15", "2-0-1-0",
         "Przysiad wąski z hantlem", "Sumo squat (szerszy rozstaw)",
         "Stopy blisko siebie — większy akcent na przednią część uda",
         "Odrywanie pięt od podłogi z powodu ograniczonej mobilności"),
        ("Przysiad z pauzą (paused squat)", "Paused squat", "Zaawansowany", "4 x 6-8", "2-3-1-0",
         "Paused squat z większym ciężarem", "Przysiad klasyczny (bez pauzy)",
         "2-3 sekundowa pauza w dolnej pozycji bez odbijania się",
         "Odbijanie się od dołu dla ułatwienia wstania"),
    ],
)

add_family(
    "Nogi", ["Pośladki"], ["Gumy oporowe"], "Siłowe",
    "Przysiad z gumą oporową",
    [
        "Napięcie gumy utrzymywane przez cały zakres ruchu",
        "Kolana pracują na zewnątrz przeciw oporowi gumy",
    ],
    [
        "Utrata napięcia gumy w górnej fazie ruchu",
        "Zapadanie kolan do środka mimo oporu gumy",
    ],
    [
        ("Przysiad z gumą nad kolanami (band squat)", "Band squat", "Średni", "3 x 12-15", "2-0-1-0",
         "Band squat z mocniejszą gumą", "Przysiad bez gumy",
         "Guma nad kolanami wymusza dodatkową pracę odwodzicieli",
         "Pozwolenie gumie ściągać kolana do środka"),
        ("Przysiad z odwiedzeniem i gumą (squat + abduction)", "Squat with band abduction", "Zaawansowany", "3 x 10-12", "2-1-1-0",
         "Squat + abduction z mocniejszą gumą", "Band squat (bez dodatkowego odwiedzenia)",
         "Na szczycie ruchu dodatkowe odwiedzenie jednej nogi na bok",
         "Utrata równowagi podczas dodatkowego odwiedzenia nogi"),
        ("Szeroki przysiad z gumą (broad band squat)", "Broad band squat", "Średni", "3 x 12-15", "2-0-1-0",
         "Broad band squat z mocniejszą gumą", "Band squat (węższy rozstaw)",
         "Szeroki rozstaw stóp maksymalizuje napięcie gumy na całym zakresie",
         "Zbyt szybkie tempo tracące kontrolowane napięcie gumy"),
    ],
)

add_family(
    "Nogi", ["Pośladki", "Plecy"], ["Masa własna"], "Siłowe",
    "Zginanie kolana — łańcuch tylny (hamstring)",
    [
        "Kontrolowany, powolny ruch — nie szarpany",
        "Napięty core stabilizuje miednicę podczas ruchu",
    ],
    [
        "Zbyt szybkie tempo tracące kontrolę ekscentryczną",
        "Opadanie bioder/miednicy w trakcie ruchu",
    ],
    [
        ("Nordic curl — asekuracja partnera/pasa", "Assisted Nordic curl", "Zaawansowany", "3 x 5-6", "5-0-1-0",
         "Nordic curl pełny (bez asekuracji)", "Leżące zginanie kolana z piętami (heel slides)",
         "Powolne opadanie do przodu z maksymalną kontrolą hamstringów",
         "Zbyt szybkie 'spadanie' bez kontroli ekscentrycznej"),
        ("Nordic curl — negatyw kontrolowany", "Nordic curl negative", "Zaawansowany", "3 x 4-6", "6-0-0-0",
         "Nordic curl pełny (z powrotem do góry)", "Assisted Nordic curl (z asekuracją)",
         "Tylko faza opadania, powrót do pozycji startowej rękami",
         "Zbyt szybka faza opadania (utrata napięcia treningowego)"),
        ("Leżące zginanie kolana z piętami (heel slides)", "Heel slides hamstring curl", "Początkujący", "3 x 12-15", "2-0-2-0",
         "Heel slides z gumą oporową", "Glute bridge march (łatwiejszy)",
         "Pięty ślizgają się po podłodze przyciągając ciało w mostku",
         "Opadanie bioder podczas ślizgu pięt"),
        ("Mostek na jednej pięcie (single-heel bridge curl)", "Single-heel bridge curl", "Średni", "3 x 10-12/stronę", "2-1-1-0",
         "Single-heel bridge curl z hantlem na biodrach", "Heel slides hamstring curl (dwunóż)",
         "Jedna pięta na podłodze, druga noga wyprostowana w powietrzu",
         "Rotacja bioder podczas pracy jedną nogą"),
    ],
)

add_family(
    "Nogi", ["Łydki", "Pośladki"], ["Masa własna"], "Cardio",
    "Skoki jednonóż i plyometria (nogi)",
    [
        "Miękkie, kontrolowane lądowanie z ugięciem kolana",
        "Stabilna miednica podczas jednostronnej pracy dynamicznej",
    ],
    [
        "Sztywne lądowanie bez amortyzacji stawu kolanowego",
        "Utrata równowagi po lądowaniu na jednej nodze",
    ],
    [
        ("Single-leg box step-down", "Single-leg box step-down", "Średni", "3 x 8-10/stronę", "3-0-1-0",
         "Step-down z większego podwyższenia", "Step-up klasyczny (dwunóż)",
         "Kontrolowane schodzenie z podwyższenia na jednej nodze",
         "Zbyt szybkie 'spadanie' z podwyższenia bez kontroli"),
        ("Lateral bound (skoki boczne jednonóż)", "Lateral bound", "Zaawansowany", "3 x 8-10/stronę", "wybuchowo",
         "Lateral bound z większym zakresem", "Skater lunge (bez skoku)",
         "Wybuchowy skok w bok z lądowaniem na przeciwnej nodze, stabilizacja 2s",
         "Brak stabilizacji po lądowaniu przed kolejnym odbiciem"),
        ("Depth jump (skok w głąb z podwyższenia)", "Depth jump", "Zaawansowany", "3 x 6-8", "wybuchowo",
         "Depth jump z wyższego podwyższenia", "Box jump (bez zeskoku)",
         "Zeskok z niskiego podwyższenia i natychmiastowy wyskok wzwyż",
         "Zbyt długa pauza między zeskokiem i wyskokiem (utrata reaktywności)", ["Masa własna", "Ławeczka"]),
    ],
)

add_family(
    "Nogi", ["Pośladki"], ["Ławeczka", "Masa własna"], "Siłowe",
    "Wykroki i przysiady dzielone — dopełnienie",
    [
        "Stabilna miednica, kontrolowane tempo w obu fazach ruchu",
        "Kolano przedniej nogi śledzi linię stopy",
    ],
    [
        "Utrata równowagi z powodu zbyt szybkiego tempa",
        "Zbyt krótki krok/rozkrok utrudniający kontrolę",
    ],
    [
        ("Wykrok izometryczny (isometric lunge hold)", "Isometric lunge hold", "Średni", "3 x 20-30s/stronę", "izometria",
         "Isometric lunge hold z hantlami", "Split squat (dynamiczny)",
         "Statyczne utrzymanie dolnej pozycji wykroku bez ruchu",
         "Przenoszenie ciężaru na przednią stopę (utrata balansu)"),
        ("Wykrok w tył z podniesieniem kolana (reverse lunge to knee drive)", "Reverse lunge to knee drive", "Zaawansowany", "3 x 8-10/stronę", "2-0-1-1",
         "Reverse lunge to knee drive z hantlami", "Wykroki w miejscu (bez podniesienia kolana)",
         "Po wykroku w tył dynamiczne podniesienie kolana do wysokości bioder",
         "Utrata równowagi podczas dynamicznego podniesienia kolana"),
        ("Curtsy lunge z pulsowaniem", "Curtsy lunge pulse", "Zaawansowany", "3 x 10-12/stronę", "1-0-1-0",
         "Curtsy lunge pulse z hantlami", "Curtsy lunge (bez pulsowania)",
         "Małe pulsowanie w dolnej pozycji skrętnego wykroku",
         "Utrata skrętnego ustawienia nóg podczas pulsowania"),
        ("Przysiad dzielony na podwyższeniu z pulsowaniem", "Elevated split squat pulse", "Zaawansowany", "3 x 10-12/stronę", "1-0-1-0",
         "Elevated split squat pulse z hantlami", "Split squat (bez podwyższenia tylnej nogi)",
         "Tylna stopa podniesiona na ławce, pulsowanie w dolnej pozycji",
         "Zbyt duże obciążenie przedniego kolana zamiast pośladków"),
    ],
)

# --- POŚLADKI +12 --------------------------------------------------------

add_family(
    "Pośladki", ["Nogi"], ["Ławeczka", "Masa własna"], "Siłowe",
    "Mostek/hip thrust — dopełnienie",
    [
        "Pełny wyprost bioder na szczycie, napięte pośladki, bez przeprostu lędźwi",
        "Kontrolowane tempo w obu fazach ruchu",
    ],
    [
        "Przeprost odcinka lędźwiowego zamiast wyprostu w biodrach",
        "Zbyt szybkie, niekontrolowane tempo",
    ],
    [
        ("Glute bridge ze stopami na ławce (elevated)", "Elevated glute bridge", "Średni", "3 x 12-15", "2-1-1-0",
         "Elevated glute bridge jednonóż", "Glute bridge klasyczny (stopy na podłodze)",
         "Stopy na ławce zwiększają zakres ruchu i napięcie pośladków",
         "Niepełny wyprost bioder na szczycie ruchu"),
        ("Hip thrust z pauzą na szczycie", "Paused hip thrust", "Zaawansowany", "4 x 8-10", "2-2-1-0",
         "Paused hip thrust z większym ciężarem", "Hip thrust klasyczny (bez pauzy)",
         "2-sekundowa pauza w pełnym wyproście maksymalizuje napięcie",
         "Skracanie pauzy pod wpływem zmęczenia", ["Masa własna", "Ławeczka", "Hantle"]),
        ("B-stand hip thrust (asymetryczny)", "B-stand hip thrust", "Zaawansowany", "3 x 8-10/stronę", "2-1-1-0",
         "B-stand hip thrust z hantlem na biodrach", "Hip thrust dwunóż (klasyczny)",
         "Większość ciężaru na jednej nodze, druga tylko wspiera balans",
         "Równomierne rozłożenie ciężaru na obie nogi (utrata efektu)", ["Masa własna", "Ławeczka"]),
    ],
)

add_family(
    "Pośladki", ["Nogi"], ["Gumy oporowe"], "Siłowe",
    "Odwodzenie i rotacja z gumą — dopełnienie",
    [
        "Napięcie gumy przez cały zakres ruchu, stabilna miednica",
        "Ruch izolowany w stawie biodrowym, minimalna kompensacja tułowiem",
    ],
    [
        "Rotacja/przechylanie tułowia dla 'pomocy' w ruchu",
        "Utrata napięcia gumy w skrajnych pozycjach ruchu",
    ],
    [
        ("Odwodzenie bioder siedząc z gumą (seated band abduction)", "Seated band hip abduction", "Początkujący", "3 x 15-20", "2-0-2-0",
         "Seated band abduction z mocniejszą gumą", "Standing band hip abduction (stojąc)",
         "Siedząc na krześle, kolana rozpychają gumę na boki",
         "Odrywanie stóp od podłogi podczas rozpychania kolan"),
        ("Kickback stojąc z gumą (standing band kickback)", "Standing band kickback", "Średni", "3 x 12-15/stronę", "2-0-2-0",
         "Standing band kickback z mocniejszą gumą", "Glute kickback w podporze (bez gumy)",
         "Guma zaczepiona niska, wyprost nogi do tyłu przeciw oporowi",
         "Wyginanie odcinka lędźwiowego dla większego zakresu"),
        ("Przyciąganie gumy przez biodra (band pull-through)", "Band pull-through", "Średni", "3 x 12-15", "2-0-1-0",
         "Band pull-through z mocniejszą gumą", "Kettlebell swing (imitacja hantlem)",
         "Zawias biodrowy tyłem do zaczepu gumy, wyprost bioder ciągnąc gumę",
         "Inicjowanie ruchu rękami zamiast wyprostem bioder"),
    ],
)

add_family(
    "Pośladki", ["Nogi", "Brzuch"], ["Masa własna"], "Izometryczne",
    "Izometria pośladków — dopełnienie",
    [
        "Maksymalne, świadome napięcie pośladków przez cały czas utrzymania",
        "Spokojny oddech mimo napięcia mięśniowego",
    ],
    [
        "Rozluźnianie napięcia pośladków w trakcie utrzymania",
        "Kompensacja napięcia w dolnym odcinku pleców",
    ],
    [
        ("Mostek — izometria na szczycie (glute bridge hold)", "Glute bridge hold", "Początkujący", "3 x 30-45s", "izometria",
         "Glute bridge hold z hantlem na biodrach", "Glute bridge dynamiczny",
         "Pełny wyprost bioder utrzymywany bez ruchu, maksymalne napięcie",
         "Opadanie bioder w trakcie długiego utrzymania"),
        ("Izometria jednonóż w mostku (single-leg glute bridge hold)", "Single-leg glute bridge hold", "Zaawansowany", "3 x 15-20s/stronę", "izometria",
         "Single-leg glute bridge hold z dociążeniem", "Glute bridge hold (dwunóż)",
         "Druga noga wyprostowana w powietrzu, biodra równo na obu stronach",
         "Przekrzywianie bioder w stronę uniesionej nogi"),
        ("Izometryczny ścisk pośladków przy ścianie", "Wall isometric glute squeeze", "Początkujący", "3 x 30-40s", "izometria",
         "Wall isometric squeeze z pulsowaniem", "Glute bridge hold (na podłodze)",
         "Oparcie o ścianę, maksymalny ścisk pośladków bez ruchu bioder",
         "Zbyt niska intensywność napięcia (brak realnego wysiłku)"),
    ],
)

add_family(
    "Pośladki", ["Nogi", "Brzuch"], ["Masa własna"], "Cardio",
    "Cardio pośladki — dopełnienie",
    [
        "Kontrolowane lądowanie, napięte pośladki w fazie wyprostu/odwiedzenia",
        "Stabilny tułów przez cały dynamiczny ruch",
    ],
    [
        "Zbyt szybkie tempo tracące kontrolę techniki",
        "Sztywne lądowanie bez amortyzacji",
    ],
    [
        ("Skok skrętny curtsy (curtsy lunge jump)", "Curtsy lunge jump", "Zaawansowany", "3 x 8-10/stronę", "wybuchowo",
         "Curtsy lunge jump z większym zakresem", "Curtsy lunge (bez skoku)",
         "Dynamiczne odbicie ze skrętnego wykroku z miękkim lądowaniem",
         "Utrata skrętnego ustawienia nóg podczas lądowania"),
        ("Pop squat (skoki sumo)", "Pop squat", "Średni", "3 x 15-20", "dynamiczne",
         "Pop squat z większym tempem", "Squat jack (bez pełnego przysiadu)",
         "Skok z wąskiej stójki do szerokiego przysiadu sumo i z powrotem",
         "Niepełne zejście do przysiadu sumo"),
        ("Odbicie boczne z napięciem pośladków (lateral bound to squeeze)", "Lateral bound to glute squeeze", "Zaawansowany", "3 x 8-10/stronę", "wybuchowo",
         "Lateral bound to glute squeeze z większym zakresem", "Lateral bound (bez dodatkowego ścisku)",
         "Po lądowaniu dodatkowy świadomy ścisk pośladka nogi podporowej",
         "Brak stabilizacji po lądowaniu przed kolejnym odbiciem"),
    ],
)

# --- BRZUCH +13 -----------------------------------------------------------

add_family(
    "Brzuch", ["Nogi"], ["Masa własna"], "Siłowe",
    "Crunch — dodatkowe warianty",
    [
        "Napięty brzuch przez cały ruch, dolne plecy przyciśnięte do podłogi",
        "Ruch inicjowany skróceniem mięśni brzucha, nie szarpaniem szyi",
    ],
    [
        "Szarpanie szyją/głową zamiast pracy brzucha",
        "Odrywanie dolnych pleców od podłogi",
    ],
    [
        ("Crunch klasyczny", "Basic crunch", "Początkujący", "3 x 15-20", "2-0-1-0",
         "Long-arm crunch (większy zakres)", "Crunch z podparciem stóp",
         "Ręce skrzyżowane na klatce lub za głową, unoszenie górnej części tułowia",
         "Ciągnięcie głowy rękami do przodu"),
        ("Long-arm crunch (ramiona wyprostowane nad głową)", "Long-arm crunch", "Średni", "3 x 12-15", "2-0-1-0",
         "Long-arm crunch z hantlem w rękach", "Crunch klasyczny (ręce na klatce)",
         "Wyprostowane ramiona nad głową wydłużają ramię siły, zwiększając trudność",
         "Uginanie ramion podczas unoszenia tułowia"),
        ("Reverse crunch z piłką między kolanami", "Reverse crunch with ball squeeze", "Średni", "3 x 12-15", "2-0-1-0",
         "Reverse crunch z gumą na kostkach", "Reverse crunch klasyczny",
         "Ścisk piłki między kolanami dodaje aktywację przywodzicieli i core",
         "Rozluźnianie ścisku piłki podczas ruchu"),
        ("Cross-body crunch (skrzyżowany)", "Cross-body crunch", "Początkujący", "3 x 15-20/stronę", "2-0-1-0",
         "Cross-body crunch z wolniejszym tempem", "Crunch klasyczny (bez skrętu)",
         "Łokieć w kierunku przeciwnego kolana z rotacją tułowia",
         "Szarpanie łokciem bez faktycznej rotacji tułowia"),
    ],
)

add_family(
    "Brzuch", ["Plecy"], ["Masa własna"], "Izometryczne",
    "Izometria brzucha — dodatkowe warianty",
    [
        "Napięty core przez cały czas utrzymania pozycji",
        "Spokojny, kontrolowany oddech mimo napięcia mięśniowego",
    ],
    [
        "Wstrzymywanie oddechu podczas utrzymania pozycji",
        "Kompensacja napięcia w dolnym odcinku pleców/szyi",
    ],
    [
        ("Superman hold (izometria wyprostu)", "Superman hold", "Początkujący", "3 x 20-30s", "izometria",
         "Superman hold z pulsowaniem", "Superman raise dynamiczny",
         "Ręce i nogi uniesione jednocześnie, napięte plecy i pośladki",
         "Zbyt wysokie uniesienie głowy (przeprost szyi)"),
        ("Boat pose (V-sit hold)", "Boat pose hold", "Zaawansowany", "3 x 20-30s", "izometria",
         "Boat pose z wyprostowanymi nogami", "Boat pose z ugiętymi kolanami (łatwiejszy)",
         "Balans na kościach siedzeniowych, tułów i nogi tworzą literę V",
         "Zaokrąglanie odcinka lędźwiowego podczas balansu"),
        ("Hollow hold na ławeczce (z podparciem)", "Hollow hold on bench", "Średni", "3 x 20-30s", "izometria",
         "Hollow hold na ławeczce z wyprostowanymi kończynami", "Hollow hold na podłodze (łatwiejszy)",
         "Dolne plecy przyklejone do ławki, napięty core przez cały czas",
         "Odrywanie dolnych pleców od ławki"),
    ],
)

add_family(
    "Brzuch", ["Barki", "Nogi"], ["Masa własna"], "Siłowe",
    "Złożone core — dodatkowe warianty",
    [
        "Stabilna miednica podczas dynamicznego, złożonego ruchu",
        "Napięty core przez cały zakres, priorytet techniki nad tempem",
    ],
    [
        "Opadanie/wypychanie bioder podczas dynamicznego ruchu",
        "Utrata napięcia core dla zwiększenia tempa",
    ],
    [
        ("Plank jack (podpór z rozstawem nóg)", "Plank jack", "Średni", "3 x 30-40s", "dynamiczne",
         "Plank jack z większym tempem", "Plank klasyczny (bez ruchu nóg)",
         "Nogi rozstawiane i łączone w skoku, biodra stabilne w podporze",
         "Wypychanie bioder w górę podczas rozstawiania nóg"),
        ("Renegade row (imitacja bez hantli — podpór dynamiczny)", "Bodyweight renegade plank row", "Zaawansowany", "3 x 8-10/stronę", "2-0-2-0",
         "Renegade row z hantlami", "Plank klasyczny (bez unoszenia ręki)",
         "Uniesienie jednej ręki w podporze z zachowaniem stabilnej miednicy",
         "Rotacja bioder podczas unoszenia ręki"),
        ("Superman raise dynamiczny", "Dynamic superman raise", "Początkujący", "3 x 12-15", "2-1-1-0",
         "Superman hold (izometria)", "Superman raise z mniejszym zakresem",
         "Dynamiczne unoszenie i opuszczanie ramion/nóg z leżenia na brzuchu",
         "Zbyt szybkie tempo bez kontroli w górnej fazie"),
    ],
)

add_family(
    "Brzuch", ["Nogi"], ["Drążek", "Gumy oporowe"], "Siłowe",
    "Zwis i guma — dopełnienie",
    [
        "Minimalne kołysanie ciała, ruch kontrolowany z brzucha",
        "Pełny, kontrolowany zakres ruchu w obu fazach",
    ],
    [
        "Kołysanie ciałem dla 'wystrzelenia' ruchu (kipping)",
        "Zbyt szybkie tempo bez kontroli ekscentrycznej",
    ],
    [
        ("Hanging knee raise z gumą oporową", "Banded hanging knee raise", "Zaawansowany", "3 x 10-12", "2-0-1-0",
         "Banded hanging knee raise z większym oporem", "Podnoszenie kolan w zwisie (bez gumy)",
         "Guma zaczepiona nad drążkiem dodaje opór podczas przyciągania kolan",
         "Kołysanie ciałem zamiast izolowanej pracy brzucha", ["Drążek", "Gumy oporowe"]),
        ("Plank walk-out do przyciągnięcia kolana (imitacja koła ab)", "Plank walkout to knee tuck", "Średni", "3 x 8-10", "kontrolowane",
         "Plank walkout to knee tuck z pompką", "Plank walk-out klasyczny",
         "Po wysunięciu dłoni do przodu, przyciągnięcie kolana do klatki w podporze",
         "Zapadanie bioder podczas maksymalnego wysunięcia rąk", ["Masa własna"]),
        ("Standing band crunch (crunch z gumą stojąc)", "Standing band crunch", "Średni", "3 x 15-20", "2-0-2-0",
         "Standing band crunch z mocniejszą gumą", "Crunch klasyczny (leżąc)",
         "Guma zaczepiona wysoko, zgięcie tułowia w dół przeciw oporowi",
         "Zginanie tylko w ramionach bez skrócenia mięśni brzucha", ["Gumy oporowe"]),
    ],
)

# --- CARDIO +11 -----------------------------------------------------------

add_family(
    "Cardio", ["Nogi", "Brzuch"], ["Masa własna"], "Cardio",
    "Cykliczny i złożony — dopełnienie",
    [
        "Płynne przejścia między fazami ruchu, stabilny core",
        "Miękkie, kontrolowane lądowanie z ugięciem kolan",
    ],
    [
        "Utrata techniki pod presją tempa",
        "Sztywne lądowanie bez amortyzacji",
    ],
    [
        ("Plank to downward dog (podpór do psa z głową w dół)", "Plank to downward dog", "Średni", "3 x 30-40s", "dynamiczne",
         "Plank to downward dog z większym tempem", "Plank klasyczny (bez przejścia)",
         "Płynne przejście bioder w górę do pozycji psa i z powrotem do podporu",
         "Uginanie kolan podczas przejścia do psa z głową w dół"),
        ("Speed skaters (dynamiczne łyżwiarskie odbicia)", "Speed skaters", "Zaawansowany", "3 x 30-40s", "dynamiczne",
         "Speed skaters z większym zakresem", "Skater lunge (wolniejsze tempo)",
         "Szybkie, boczne odbicia z ręką sięgającą do podłogi",
         "Sztywne lądowanie bez amortyzacji kolanem"),
        ("Frog jumps (skoki żabki)", "Frog jumps", "Średni", "3 x 10-12", "wybuchowo",
         "Frog jumps z większym zakresem skoku", "Squat jump (bez pochylenia)",
         "Z głębokiego przysiadu wybuchowy skok do przodu z miękkim lądowaniem",
         "Lądowanie na wyprostowanych, sztywnych nogach"),
    ],
)

add_family(
    "Cardio", ["Nogi", "Barki"], ["Skakanka"], "Cardio",
    "Skakanka — dopełnienie",
    [
        "Skoki niskie i szybkie, lądowanie na śródstopiu",
        "Nadgarstki wykonują ruch obrotowy, nie całe ramiona",
    ],
    [
        "Zbyt wysokie skoki (męczące i niepotrzebne)",
        "Poruszanie całymi ramionami zamiast nadgarstkami",
    ],
    [
        ("Skakanka - boxer skip (krok boksera)", "Boxer skip jump rope", "Średni", "3 x 45-60s", "dynamiczne",
         "Boxer skip z większym tempem", "Skakanka basic (obunóż)",
         "Delikatne przenoszenie wagi z nogi na nogę w rytmie skakanki",
         "Zbyt duże, kołyszące przenoszenie ciężaru ciała"),
        ("Skakanka - wysokie kolana (high knees jump rope)", "High knee jump rope", "Zaawansowany", "3 x 30-40s", "dynamiczne",
         "High knee jump rope z większym tempem", "Skakanka - bieg w miejscu",
         "Wysokie unoszenie kolan zsynchronizowane z rytmem skakanki",
         "Utrata rytmu skakanki przy zbyt wysokim unoszeniu kolan"),
    ],
)

add_family(
    "Cardio", ["Nogi"], ["Bieżnia"], "Cardio",
    "Cykliczny - bieżnia",
    [
        "Naturalna, wyprostowana postawa — bez trzymania się poręczy",
        "Stabilny, kontrolowany rytm oddechu dopasowany do intensywności",
    ],
    [
        "Trzymanie się poręczy podczas marszu/biegu (zniekształca postawę)",
        "Zbyt duże nachylenie tułowia do przodu przy wyższym tempie",
    ],
    [
        ("Marsz z inklinacją (incline walk)", "Incline treadmill walk", "Początkujący", "20-30 min", "stałe tempo",
         "Interwały sprint/trucht na bieżni (większa intensywność)", "Marsz na bieżni bez inklinacji",
         "Zwiększone nachylenie bieżni podnosi intensywność bez obciążania stawów",
         "Chwytanie poręczy dla wsparcia (zmniejsza efekt treningowy)"),
        ("Interwały sprint/trucht na bieżni (HIIT treadmill)", "HIIT treadmill intervals", "Zaawansowany", "8-10 x 30s/90s", "interwałowe",
         "HIIT treadmill z krótszymi przerwami", "Marsz z inklinacją (niższa intensywność)",
         "Krótkie odcinki sprintu przeplatane truchtem/marszem dla regeneracji",
         "Zbyt gwałtowne zwiększanie prędkości bez rozgrzewki"),
    ],
)

add_family(
    "Cardio", ["Nogi", "Brzuch"], ["Masa własna"], "Cardio",
    "Złożone — dopełnienie",
    [
        "Napięty core stabilizuje tułów w dynamicznym, złożonym ruchu",
        "Kontrolowane przejścia między fazami ćwiczenia",
    ],
    [
        "Zaokrąglanie grzbietu podczas dynamicznych przejść",
        "Zbyt szybkie tempo utrudniające pełny zakres ruchu",
    ],
    [
        ("Plank jack + burpee (hybryda)", "Plank jack burpee hybrid", "Zaawansowany", "3 x 8-10", "dynamiczne",
         "Plank jack burpee hybrid z pompką", "Burpee klasyczny (bez plank jack)",
         "Dodanie plank jacka w fazie podporu przed powrotem do przysiadu",
         "Wypychanie bioder w górę podczas plank jacka"),
        ("Bear crawl do sprawl (bear crawl to sprawl)", "Bear crawl to sprawl", "Zaawansowany", "3 x 8-10", "dynamiczne",
         "Bear crawl to sprawl z większym tempem", "Bear crawl klasyczny (bez sprawla)",
         "Z pozycji niedźwiedzia dynamiczne opadnięcie do podporu (sprawl) i powrót",
         "Zbyt wysokie biodra podczas przejścia (utrata napięcia core)"),
    ],
)

add_family(
    "Cardio", ["Nogi"], ["Ławeczka", "Masa własna"], "Cardio",
    "Step i przejścia boczne — dopełnienie",
    [
        "Cała stopa stawiana na podwyższeniu, stabilny rytm ruchu",
        "Napięty core podczas dynamicznych zmian kierunku",
    ],
    [
        "Niepełne stawianie stopy na podwyższeniu",
        "Zbyt szybkie tempo prowadzące do potknięć",
    ],
    [
        ("Lateral step-over (przekroczenie boczne podwyższenia)", "Lateral step-over", "Średni", "3 x 30-40s", "dynamiczne",
         "Lateral step-over z większym tempem", "Step-up cardio (bez przekraczania)",
         "Przekraczanie niskiego podwyższenia na boki w rytmicznym tempie",
         "Potykanie się o podwyższenie z powodu niepełnego uniesienia stopy"),
        ("Box step tap (dotyk podwyższenia)", "Box step tap", "Początkujący", "3 x 40-50s", "dynamiczne",
         "Box step tap z większym tempem", "Lateral shuffle (bez podwyższenia)",
         "Szybki, alternujący dotyk stopą niskiego podwyższenia",
         "Zbyt mocne uderzanie stopą (brak kontroli lądowania)"),
    ],
)

# --- MOBILNOŚĆ +8 ----------------------------------------------------------

add_family(
    "Mobilność", ["Nogi"], ["Masa własna"], "Mobilność",
    "Mobilizacja kostki i łydek",
    [
        "Ruch w pełnym, bezbolesnym zakresie stawu skokowego",
        "Kontrolowane tempo, brak szarpania",
    ],
    [
        "Zbyt szybkie, niekontrolowane ruchy stawu",
        "Kompensacja ruchu kolanem/biodrem zamiast stawem skokowym",
    ],
    [
        ("Krążenia stawu skokowego (ankle circles)", "Ankle circles", "Początkujący", "3 x 8-10/kierunek/stronę", "wolno",
         "Ankle circles z większym zakresem", "Ankle circles z mniejszym zakresem",
         "Pełne krążenie stopą w obu kierunkach, staw kolanowy nieruchomy",
         "Poruszanie całą nogą zamiast izolowanego ruchu w stawie skokowym"),
        ("Rozciąganie łydki przy ścianie (wall calf stretch)", "Wall calf stretch", "Początkujący", "3 x 30-45s/stronę", "statyczne",
         "Wall calf stretch z większym pochyleniem", "Wall calf stretch z mniejszym zakresem",
         "Tylna noga wyprostowana, pięta na podłodze, pochylenie do ściany",
         "Odrywanie pięty tylnej stopy od podłogi"),
    ],
)

add_family(
    "Mobilność", ["Barki"], ["Masa własna"], "Mobilność",
    "Mobilizacja obręczy barkowej",
    [
        "Ruch płynny w pełnym, bezbolesnym zakresie stawu barkowego",
        "Stabilny tułów, ruch izolowany w barkach",
    ],
    [
        "Kompensacja ruchu wyginaniem odcinka lędźwiowego",
        "Zbyt szybkie, dynamiczne ruchy bez kontroli zakresu",
    ],
    [
        ("Krążenia ramion (arm circles)", "Arm circles", "Początkujący", "3 x 10-12/kierunek", "wolno",
         "Arm circles z większym zakresem/tempem", "Arm circles z mniejszym zakresem",
         "Pełne krążenie wyprostowanymi ramionami w obu kierunkach",
         "Zgięcie ramion podczas krążenia (zmniejsza zakres mobilizacji)"),
        ("Ślizgi po ścianie (wall slides)", "Wall slides", "Średni", "3 x 10-12", "wolno",
         "Wall slides z większym zakresem", "Arm circles (mniej wymagające)",
         "Przedramiona i barki w kontakcie ze ścianą podczas ślizgu w górę/dół",
         "Odrywanie dolnych pleców od ściany podczas ślizgu w górę"),
        ("Ściąganie łopatek (band pull-apart imitacja)", "Scapular pull-apart", "Początkujący", "3 x 15-20", "2-1-1-0",
         "Scapular pull-apart z gumą oporową", "Scapular pull-apart z mniejszym zakresem",
         "Ramiona wyprostowane przed sobą, ściąganie łopatek do siebie",
         "Unoszenie barków do uszu zamiast ściągania łopatek", ["Gumy oporowe"]),
    ],
)

add_family(
    "Mobilność", ["Plecy", "Nogi"], ["Masa własna"], "Mobilność",
    "Rozciąganie łańcucha tylnego i przedniego",
    [
        "Rozciąganie do lekkiego dyskomfortu, nigdy do bólu",
        "Spokojny, głęboki oddech podczas utrzymania pozycji",
    ],
    [
        "Rozciąganie do bólu (ryzyko urazu)",
        "Zaokrąglanie grzbietu zamiast neutralnej pozycji",
    ],
    [
        ("Rozciąganie dwugłowego uda w staniu (standing hamstring stretch)", "Standing hamstring stretch", "Początkujący", "3 x 30-45s/stronę", "statyczne",
         "Standing hamstring stretch z większym pochyleniem", "Standing hamstring stretch z ugiętym kolanem",
         "Noga wyprostowana na podwyższeniu, pochylenie tułowia z neutralnym grzbietem",
         "Zaokrąglanie grzbietu podczas pochylania się"),
        ("Rozciąganie czworogłowego w staniu (standing quad stretch)", "Standing quad stretch", "Początkujący", "3 x 30-45s/stronę", "statyczne",
         "Standing quad stretch z przyciągnięciem pięty do pośladka", "Standing quad stretch z podparciem o ścianę",
         "Przyciąganie stopy do pośladka z zachowaniem stabilnej miednicy",
         "Przechylanie tułowia do przodu zamiast utrzymania wyprostu"),
        ("Pies z głową w dół (downward dog)", "Downward dog", "Początkujący", "3 x 30-45s", "statyczne",
         "Downward dog z naprzemiennym uginaniem kolan (pompowanie łydek)", "Downward dog z ugiętymi kolanami",
         "Ręce i stopy na podłodze, biodra uniesione wysoko, grzbiet wydłużony",
         "Zaokrąglanie grzbietu zamiast wydłużenia kręgosłupa"),
    ],
)

def merge_and_write(existing_path="assets/data/exercises.json"):
    """
    Wczytuje istniejące ćwiczenia, dopisuje NEW_EXERCISES z sekwencyjnymi
    ID kontynuującymi numeracją (cw039..), waliduje unikalność id/nazw
    i zapisuje finalny plik z powrotem do assets/data/exercises.json.
    """
    with open(existing_path, "r", encoding="utf-8") as f:
        existing = json.load(f)

    existing_ids = {x["id"] for x in existing}
    existing_pl = {x["nazwaPl"] for x in existing}
    existing_en = {x["nazwaEn"] for x in existing}

    next_num = len(existing) + 1
    merged = list(existing)

    for item in NEW_EXERCISES:
        if item["nazwaPl"] in existing_pl:
            raise ValueError(f"Duplikat nazwaPl względem istniejących: {item['nazwaPl']}")
        if item["nazwaEn"] in existing_en:
            raise ValueError(f"Duplikat nazwaEn względem istniejących: {item['nazwaEn']}")
        existing_pl.add(item["nazwaPl"])
        existing_en.add(item["nazwaEn"])

        new_id = f"cw{next_num:03d}"
        if new_id in existing_ids:
            raise ValueError(f"Kolizja id: {new_id}")
        existing_ids.add(new_id)
        next_num += 1

        row = dict(item)
        row["id"] = new_id
        # Zachowanie kolejności pól zgodnej z konwencją istniejącego JSON (id pierwsze)
        ordered = {"id": row["id"]}
        for k in [
            "nazwaPl", "nazwaEn", "partiaGlowna", "partieWspierajace", "sprzet",
            "typ", "poziom", "wzorzecRuchu", "seriexPowtorzenia", "tempo",
            "kluczoweWskazowki", "czesteBledy", "progresja", "regresja",
            "zrodlo", "ulubione",
        ]:
            ordered[k] = row[k]
        merged.append(ordered)

    # Walidacja końcowa: unikalność ID na całym zbiorze
    all_ids = [x["id"] for x in merged]
    if len(all_ids) != len(set(all_ids)):
        raise ValueError("Wykryto zduplikowane ID w finalnym zbiorze!")

    with open(existing_path, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)
        f.write("\n")

    return len(merged)


if __name__ == "__main__":
    print(f"Wygenerowano nowych ćwiczeń: {len(NEW_EXERCISES)}")
    total = merge_and_write()
    print(f"Zapisano finalny plik assets/data/exercises.json z {total} ćwiczeniami (cw001-cw{total:03d}).")
