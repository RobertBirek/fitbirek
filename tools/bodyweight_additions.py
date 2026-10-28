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


# Editorial English companion, not runtime Exercise/wire fields. These original
# descriptions mirror the reviewed Polish instructions; source verification and
# the published XLSX/raw catalog remain unchanged.
STOP_EN = [
    'Breathe freely.',
    'End the set before you lose control of the movement.',
    'Stop if you feel pain, numbness or dizziness.',
]
CHAIR_EN = ('Choose a stable chair without wheels on a non-slip surface, '
            'with your feet resting flat on the floor.')
INSTRUCTIONS_EN = {
    'cw425': {
        'name': 'Wall push-up',
        'description': 'A standing push-up with both hands against a stable wall. Bend and straighten your arms while keeping your trunk and hips aligned, using only a comfortable range.',
        'cues': [
            'Face a stable wall from roughly an arm length away, standing on a non-slip floor.',
            'Place your palms at chest height with your fingers pointing upwards.',
            'Keep your trunk and hips in one line, with your feet staying on the floor.',
            'Slowly bend your elbows close to your sides and bring your chest towards the wall within a comfortable range.',
            'Press away smoothly to return to the starting position.',
            *STOP_EN,
        ],
        'errors': ['Letting your hands or feet slide.', 'Allowing your hips to sag.',
                   'Reaching forwards with only your head.', 'Pushing away with a sudden bounce.'],
        'tempo': 'About 2 seconds in each direction, without swinging or bouncing.',
        'prescription': '1-2 sets of 5-8 repetitions',
        'progression': 'First add smooth repetitions, then move your feet a little farther from the wall only while remaining stable.',
        'regression': 'Stand closer to the wall and reduce both the range and the number of repetitions.',
    },
    'cw426': {
        'name': 'Bodyweight squat',
        'description': 'An unloaded squat performed without hand support. Bend your hips and knees together, keep your whole feet planted and return to standing without forcing depth.',
        'cues': [
            'Stand steadily with your feet slightly wider than your hips and your toes turned slightly outwards.',
            'Reach your arms forwards without resting them on equipment.',
            'Move your hips back and slowly bend your hips and knees, keeping your knees aligned with the direction of your feet.',
            'Lower only as far as you can keep your whole feet down and your back position controlled.',
            'Press your feet into the floor and straighten your hips and knees without jerking.',
            *STOP_EN,
        ],
        'errors': ['Lifting your heels.', 'Letting your knees collapse inwards.',
                   'Forcing a deeper squat.', 'Allowing your trunk to drop without control.'],
        'tempo': 'About 2 seconds in each direction, without swinging or bouncing.',
        'prescription': '1-2 sets of 5-8 repetitions',
        'progression': 'Add repetitions or gradually use a larger controlled range without adding external weight.',
        'regression': 'Use a shallower squat and fewer repetitions; do not force your thighs to reach parallel.',
    },
    'cw427': {
        'name': 'Bodyweight reverse lunge',
        'description': 'An unloaded step backwards into a shallow lunge, followed by a controlled return to standing. The rear knee stays above the floor throughout; this is not a kneeling exercise.',
        'cues': [
            'Stand with your feet hip-width apart, space behind you and no weights in your hands.',
            'Step one foot back onto its forefoot, keeping some sideways distance between your feet.',
            'Slowly bend both legs while guiding the front knee in the direction of its toes.',
            'Keep the rear knee above the floor throughout the movement; do not kneel down.',
            'Press the whole front foot into the floor and return to standing without bouncing.',
            'Complete a short set on one side, then change legs.',
            *STOP_EN,
        ],
        'errors': ['Placing both feet on one narrow line.', 'Dropping the rear knee onto the floor.',
                   'Letting the front knee collapse inwards.', 'Swinging your trunk to return to standing.'],
        'tempo': 'About 2 seconds in each direction, without swinging or bouncing.',
        'prescription': '1-2 sets of 5-8 repetitions per side',
        'progression': 'Add controlled repetitions on each side or slightly increase the comfortable range.',
        'regression': 'Take a shorter step and bend less deeply. If you cannot balance without hand support, choose a different exercise.',
    },
    'cw428': {
        'name': 'March in place',
        'description': 'A gentle stationary march with alternating low foot lifts and relaxed arm movements. Time covers the whole alternating sequence, not a separate interval for each leg.',
        'cues': [
            'Stand on a level, non-slip surface with clear space around you.',
            'Alternate low foot lifts and set each foot down quietly beneath your hip.',
            'Keep your trunk upright, look ahead and breathe calmly.',
            'Let your slightly bent arms move freely in rhythm with your steps.',
            'Stay in the same place, without bouncing or forcing your knees high.',
            *STOP_EN,
        ],
        'errors': ['Bouncing between steps.', 'Stamping your feet loudly.',
                   'Leaning your trunk backwards.', 'Marching so fast that comfortable conversation becomes difficult.'],
        'tempo': 'A calm, even rhythm without bouncing.',
        'prescription': '1-2 sets of 20-30 seconds',
        'progression': 'Gradually lengthen a short marching interval at a pace that still allows comfortable conversation.',
        'regression': 'Lift your feet less, slow down and use a shorter interval with a rest break.',
    },
    'cw429': {
        'name': 'Seated march',
        'description': 'Alternate small bent-knee lifts while sitting upright on a stable chair and lightly holding its sides. Measure the total time spent alternating, rather than time per leg.',
        'cues': [
            CHAIR_EN,
            'Sit upright away from the backrest and lightly hold the sides of the seat for stability.',
            'Lift one foot a little with the knee bent, without leaning your trunk backwards.',
            'Set the foot down gently and repeat with the other leg.',
            'Continue alternating at a calm rhythm without tugging or rocking the chair.',
            *STOP_EN,
        ],
        'errors': ['Leaning backwards.', 'Forcing a high knee lift.',
                   'Stamping your feet.', 'Rocking the chair.'],
        'tempo': 'A calm, even rhythm without bouncing.',
        'prescription': '1-2 sets of 20-30 seconds',
        'progression': 'Lengthen the time spent alternating calmly without increasing your pace.',
        'regression': 'Lift each foot only slightly, shorten the interval and rest between attempts.',
    },
    'cw430': {
        'name': 'Seated knee extension',
        'description': 'An unloaded seated knee extension with the thigh supported by the chair. Straighten and bend one knee slowly within a comfortable range, without a band or ankle weight.',
        'cues': [
            CHAIR_EN,
            'Sit upright with your hands resting loosely on your thighs, not supporting your body weight.',
            'Keep your thigh on the seat and slowly straighten one knee, lifting the foot in front of you and gently drawing your toes towards your shin.',
            'Stop at a comfortable range without abruptly locking the knee.',
            'Slowly bend the knee and return your foot to the floor.',
            'After a short set, change legs; do not use a resistance band or ankle weight.',
            *STOP_EN,
        ],
        'errors': ['Kicking with momentum.', 'Leaning your trunk backwards.',
                   'Lifting your thigh off the seat.', 'Forcing the knee into hyperextension.'],
        'tempo': 'About 2 seconds in each direction, without swinging or bouncing.',
        'prescription': '1-2 sets of 5-8 repetitions per side',
        'progression': 'Add controlled repetitions or a brief calm pause near extension, without adding external resistance.',
        'regression': 'Use a smaller comfortable range and fewer repetitions on each side.',
    },
    'cw431': {
        'name': 'Bodyweight fire hydrant',
        'description': 'A small sideways lift of a bent leg from a hands-and-knees position, without a band. Move at the hip while keeping the pelvis still rather than lifting the knee as high as possible.',
        'cues': [
            'Place your hands under your shoulders and your knees under your hips on a level, comfortable surface, without a resistance band.',
            'Keep your back steady, lightly engage your abdomen and look down.',
            'Keep the knee bent at about a right angle and lift one leg sideways with a small movement at the hip.',
            'Do not rotate your pelvis or trunk and do not lift the knee beyond about 45 degrees; a smaller range is enough.',
            'Slowly return the knee beneath your hip and change sides after a short set.',
            'A mat may make the position more comfortable, but it is not required.',
            *STOP_EN,
        ],
        'errors': ['Rotating your pelvis.', 'Letting your lower back sag.',
                   'Straightening the knee instead of moving the hip sideways.', 'Forcing a higher leg lift.'],
        'tempo': 'About 2 seconds in each direction, without swinging or bouncing.',
        'prescription': '1-2 sets of 5-8 repetitions per side',
        'progression': 'Add smooth repetitions or a short pause while keeping the pelvis still.',
        'regression': 'Reduce the range and the number of repetitions. If kneeling or supporting yourself on your hands is uncomfortable, choose a different exercise.',
    },
}


def source_records():
    return {f'cw{a["number"]}': {'source': 'bodyweight_' + a['source'], 'movement': a['en']}
            for a in ADDITIONS}
