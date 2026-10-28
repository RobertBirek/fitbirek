"""Original conservative instructions; publisher text read on 2026-10-28.

Sources document movement only. Dosage, tempo and progressions are editorial,
not medical advice or promises. No publisher prose or illustrations copied.
"""
PREFIX_COUNT = 424
PREFIX_SHA256 = 'd734c9eb98c827f47d5755705fbd8819207fbe7431db65f26e61ec97c5e7c278'
EXPECTED_COUNT = 431
SOURCES = {
    'wall': 'https://www.nhs.uk/live-well/exercise/strength-and-flexibility-exercises/strength-exercises/',
    'squat': 'https://www.acefitness.org/resources/everyone/exercise-library/135/bodyweight-squat/',
    'lunge': 'https://www.acefitness.org/resources/everyone/exercise-library/319/reverse-lunge/',
    'march': 'https://www.nhs.uk/live-well/exercise/how-to-warm-up-before-exercising/',
    'seated_march': 'https://www.nhs.uk/live-well/exercise/strength-and-flexibility-exercises/sitting-exercises/',
    'knee': 'https://www.opalreturntowork.nhs.uk/exercises/seated-knee-extension/',
    'hydrant': 'https://sportsrehab.ucsf.edu/sites/g/files/tkssra10961/files/doc/Core_Strengthening_Basics_Protocol_Nov2025.pdf',
}
VERIFIED = {
    'wall': 'NHS Strength exercises, Wall press-up: stand at arm length, palms at chest level, bend arms beside torso with straight back, return slowly.',
    'squat': 'ACE Bodyweight Squat, steps 1–6: no equipment; hip/knee flexion, feet remain planted, knees follow toes, controlled ascent with hips and torso together.',
    'lunge': 'ACE Reverse Lunge: article demonstrates a BARBELL version; step backward, lower rear knee toward floor, press front foot to return. Not a source claiming equipment-free execution.',
    'march': 'NHS March on the spot: rhythmic steps with bent elbows and relaxed fists; publication also adds forward/backward travel. Knee lifts are a separate section.',
    'seated_march': 'NHS Sitting exercises, Hip marching: sturdy wheelless chair, upright torso away from backrest, hold sides, lift bent leg and lower with control, alternate legs.',
    'knee': 'OPAL Seated knee extension: sturdy chair, upright torso, feet initially supported, dorsiflex ankle, straighten knee using front thigh and return with control. Band/ankle weight only in the optional harder version; page has postoperative context.',
    'hydrant': 'UCSF Core Strengthening Basics Protocol, Fire Hydrant (Quadruped with Hip Abduction): hands and knees on flat surface, engage core, lift knee to side no farther than 45 degrees, pressure through stationary limbs, repeat both sides. No band in this exercise.',
}
ADAPTATIONS = {
    'wall': 'Smaller comfortable range and 1–2 short sets initially; wall is a required stable surface in instructions, not a new equipment category. Hands bear weight: no no_hand_support tag.',
    'squat': 'Self-selected shallow range before heels lift or control is lost; no mandatory parallel depth, chair or external load.',
    'lunge': 'Explicit unloaded editorial adaptation of the documented reverse-lunge movement. No barbell, rear knee stays ABOVE floor; no kneeling or travelling lunges. Smaller range, no hand support in the base version.',
    'march': 'Stationary, low-foot-lift, no bouncing or travelling; shorter starting intervals. Time covers alternating steps, not repetitions per side.',
    'seated_march': 'Retain light hand support on chair sides as published, so no no_hand_support tag. Time covers alternating lifts; lower than a forced high-knee march.',
    'knee': 'General unloaded movement description only, not postoperative rehabilitation guidance; no band or ankle weight. Hands rest on thighs without bearing weight. Shorter comfortable sets; no forced knee lock.',
    'hydrant': 'Small comfortable abduction, never force 45 degrees; bent knee, pelvis still, no resistance band. Flat comfortable floor required; mat optional, not equipment requirement. No no_floor/no_kneeling/no_hand_support tags.',
}
ALL = ['no_jumps', 'quiet', 'no_kneeling', 'no_hand_support', 'no_floor', 'small_space']
STOP = 'Oddychaj swobodnie; Zakończ serię przed utratą kontroli; Przerwij przy bólu, drętwieniu lub zawrotach głowy'
CHAIR = 'Wybierz stabilne krzesło bez kółek na nieśliskim podłożu, ze stopami opartymi płasko na podłodze; '


def entry(n, pl, en, primary, secondary, source, cues, errors, progression, regression,
          *, equipment='Masa własna', tracking='reps', unilateral=False,
          position='standing', conditions=None, style=None):
    return dict(number=n, pl=pl, en=en, primary=primary.split(), secondary=secondary.split(),
                equipment=equipment, source=source, cues=cues + '; ' + STOP, errors=errors,
                progression=progression, regression=regression,
                style=style or ['strength', 'calisthenics'],
                kind='Rozgrzewka' if tracking == 'time' else 'Siła', level='Początkujący',
                pattern='Marsz naprzemienny' if tracking == 'time' else 'Kontrolowany ruch',
                prescription=('1-2 x 20-30 sek' if tracking == 'time' else '1-2 x 5-8') +
                             (' na stronę' if unilateral else ''),
                tempo='Spokojny równy rytm, bez podskoków' if tracking == 'time' else
                      'Około 2 sek ruchu w każdą stronę, bez zamachu',
                tracking=tracking, unilateral=unilateral, positions=[position],
                conditions=list(ALL if conditions is None else conditions))


ADDITIONS = [
    entry(425, 'Pompki od ściany', 'Wall push-up', 'chest', 'triceps shoulders abs', 'wall',
          'Stań twarzą do stabilnej ściany mniej więcej na odległość ramion, na nieśliskiej podłodze; Oprzyj dłonie na wysokości klatki, palce skieruj w górę; Utrzymaj tułów i biodra w jednej linii, stopy pozostają na podłodze; Powoli zegnij łokcie blisko boków i przybliż klatkę do ściany w wygodnym zakresie; Odepchnij się płynnie do pozycji wyjściowej',
          'Ślizgające się dłonie lub stopy; Zapadanie bioder; Wysuwanie samej głowy; Gwałtowne odbicie',
          'Najpierw dodaj płynne powtórzenia, potem odsuń stopy nieznacznie dalej przy zachowanej stabilności',
          'Stań bliżej ściany i zmniejsz zakres oraz liczbę powtórzeń',
          conditions=[c for c in ALL if c != 'no_hand_support']),
    entry(426, 'Przysiad bez obciążenia', 'Bodyweight squat', 'quadriceps glutes', 'abs', 'squat',
          'Stań stabilnie ze stopami nieco szerzej niż biodra, palce lekko na zewnątrz; Ręce wysuń przed siebie bez opierania ich na sprzęcie; Cofnij biodra i powoli ugnij biodra oraz kolana, prowadząc kolana zgodnie z kierunkiem stóp; Zejdź tylko tak nisko, by całe stopy pozostały oparte, a plecy zachowały kontrolowaną pozycję; Naciśnij stopami podłoże i wyprostuj biodra oraz kolana bez szarpania',
          'Odrywanie pięt; Zapadanie kolan; Wymuszanie głębokości; Opadanie tułowia bez kontroli',
          'Dodaj powtórzenia lub stopniowo większy kontrolowany zakres bez obciążenia',
          'Płytszy przysiad i mniej powtórzeń, bez wymuszania zejścia do równoległości'),
    entry(427, 'Zakroki bez obciążenia', 'Bodyweight reverse lunge', 'quadriceps glutes', 'hamstrings abs', 'lunge',
          'Stań ze stopami na szerokość bioder i wolnym miejscem za sobą, bez ciężaru w dłoniach; Cofnij jedną stopę i oprzyj jej przodostopie, zachowując odstęp między stopami na boki; Powoli ugnij obie nogi, przednie kolano prowadź w kierunku palców; Tylne kolano pozostaje nad podłogą przez cały ruch, nie klękaj; Naciśnij całą przednią stopą podłoże i wróć do stania bez odbicia; Wykonaj krótką serię na jedną stronę, potem zmień nogę',
          'Stopy na jednej wąskiej linii; Opadanie kolana na podłogę; Zapadanie przedniego kolana; Zamach tułowiem',
          'Dodaj kontrolowane powtórzenia na stronę lub nieco zwiększ komfortowy zakres',
          'Krótszy krok i płytsze ugięcie; jeśli nie utrzymujesz równowagi bez podparcia, wybierz inne ćwiczenie', unilateral=True),
    entry(428, 'Marsz w miejscu', 'March in place', 'hip_flexors calves', 'quadriceps glutes abs', 'march',
          'Stań na równym nieśliskim podłożu z wolnym miejscem wokół; Naprzemiennie unoś stopę niewysoko i odkładaj ją cicho pod biodrem; Zachowaj wyprostowany tułów, wzrok przed sobą i spokojny oddech; Poruszaj swobodnie lekko ugiętymi ramionami w rytmie kroków; Pozostawaj w miejscu, bez podskoków i bez wymuszania wysokiego unoszenia kolan',
          'Podskakiwanie; Głośne tupanie; Odchylanie tułowia; Zbyt szybki rytm utrudniający swobodną rozmowę',
          'Wydłuż krótki odcinek marszu przy rytmie pozwalającym swobodnie rozmawiać',
          'Niższe unoszenie stóp, wolniejszy rytm i krótszy czas z przerwą', tracking='time', style=['conditioning']),
    entry(429, 'Marsz w siadzie', 'Seated march', 'hip_flexors', 'quadriceps abs', 'seated_march', CHAIR +
          'Usiądź prosto bez opierania pleców, chwyć lekko boki siedziska dla stabilności; Unieś jedną stopę niewysoko z ugiętym kolanem bez odchylania tułowia; Odstaw stopę łagodnie i powtórz drugą nogą; Kontynuuj naprzemiennie w spokojnym rytmie, bez szarpania krzesłem',
          'Odchylanie pleców; Wymuszanie wysokiego kolana; Tupanie; Kołysanie krzesłem',
          'Wydłuż czas spokojnej naprzemiennej pracy bez przyspieszania',
          'Unoś stopę minimalnie, skróć czas i odpocznij między próbami', equipment='Krzesło', tracking='time',
          position='seated', style=['conditioning'], conditions=[c for c in ALL if c != 'no_hand_support']),
    entry(430, 'Prostowanie kolana w siadzie bez gumy', 'Seated knee extension', 'quadriceps', '', 'knee', CHAIR +
          'Usiądź prosto, dłonie połóż swobodnie na udach bez podpierania ciężaru ciała; Trzymaj udo na siedzisku i powoli prostuj jedno kolano, unosząc stopę przed siebie, palce łagodnie przyciągnij ku goleni; Zatrzymaj ruch w wygodnym zakresie bez gwałtownego blokowania kolana; Powoli zegnij kolano i odstaw stopę; Po krótkiej serii zmień nogę, nie używaj gumy ani ciężarka',
          'Kopnięcie z zamachu; Odchylanie tułowia; Odrywanie uda; Wciskanie kolana na siłę w przeprost',
          'Dodaj kontrolowane powtórzenia lub krótką spokojną pauzę przy wyproście bez dodatkowego obciążenia',
          'Mniejszy wygodny zakres i mniej powtórzeń na stronę', equipment='Krzesło', unilateral=True, position='seated', style=['strength']),
    entry(431, 'Odwodzenie ugiętej nogi w bok w klęku podpartym bez gumy', 'Bodyweight fire hydrant', 'glutes', 'abs shoulders', 'hydrant',
          'Ustaw dłonie pod barkami i kolana pod biodrami na równym wygodnym podłożu, bez gumy; Utrzymaj plecy spokojnie, brzuch lekko napięty i wzrok w dół; Zachowując ugięcie kolana około kąta prostego, unieś jedną nogę w bok małym ruchem w biodrze; Nie obracaj miednicy ani tułowia i nie unoś kolana wyżej niż około 45 stopni, mniejszy zakres jest wystarczający; Powoli odstaw kolano pod biodro i po krótkiej serii zmień stronę; Mata może zwiększyć komfort, ale nie jest wymagana',
          'Obracanie miednicy; Zapadanie lędźwi; Prostowanie kolana zamiast odwodzenia biodra; Wymuszanie wysokości',
          'Dodaj płynne powtórzenia lub krótką pauzę przy zachowaniu nieruchomej miednicy',
          'Zmniejsz zakres i liczbę powtórzeń; jeśli podpór lub klęk jest niewygodny, wybierz inne ćwiczenie',
          unilateral=True, position='floor', conditions=['no_jumps', 'quiet', 'small_space']),
]


def source_records():
    return {f'cw{a["number"]}': {'source': 'bodyweight_' + a['source'], 'movement': a['en']}
            for a in ADDITIONS}
