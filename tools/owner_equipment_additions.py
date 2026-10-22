"""Reviewed owner-equipment supplement, 2026-10-22; original Polish instructions.

Research was supplied by the preceding data review. Sources support movements,
not equipment certification, clinical outcomes or an individual load target.
"""
PREFIX_COUNT = 412
PREFIX_SHA256 = 'f08515f6c776162eeb448dcdfcf56b10d37c504a52083e5a8117aecd5a7ce02d'
EXPECTED_COUNT = 424
SOURCES = {
    'step_up': 'https://www.acefitness.org/resources/everyone/exercise-library/28/step-up/',
    'step_variations': 'https://www.acefitness.org/resources/pros/expert-articles/6369/back-to-the-basics-how-to-create-innovative-fitness-programs/',
    'step_glutes': 'https://www.acefitness.org/resources/pros/expert-articles/5901/effective-exercises-to-target-the-glutes/',
    'step_pushup': 'https://www.acefitness.org/resources/pros/expert-articles/5808/strength-and-cardio-circuit-for-beginning-clients/',
    'feet_pushup': 'https://www.acefitness.org/resources/everyone/blog/5391/outdoor-functional-training-exercises/',
    'feet_pushup_low': 'https://www.acefitness.org/about-ace/press-room/in-the-news/8284/what-muscles-do-pushups-work-tips-how-to-do-them-correctly-healthnews/',
    'standing_calf': 'https://exrx.net/WeightExercises/Gastrocnemius/BWStandingCalfRaise',
    'decline_crunch': 'https://exrx.net/WeightExercises/RectusAbdominis/BWInclineCrunch',
    'decline_situp': 'https://exrx.net/WeightExercises/HipFlexors/WtDeclineSitup',
    'decline_press': 'https://exrx.net/WeightExercises/PectoralSternal/DBDeclineBenchPress',
    'balance': 'https://www.togu.de/en/blog/pelvic-floor-training-with-the-dynair-ballkissen',
    'roll_calf': 'https://contentcdn.eacefitness.com/certifiednews/images/article/pdfs/MyofascialRelease.pdf',
    'roll_quad': 'https://www.acefitness.org/about-ace/our-efforts/blog/7786/foam-rollers-should-you-use-them/',
    'roll_glute': 'https://www.acefitness.org/resources/pros/expert-articles/5895/recover-faster-and-more-effectively-with-these-foam-roller-moves/',
    'carry': 'https://ultimatesandbagtraining.com/best-secret-great-ultimate-sandbag-workouts/',
    'wrist': 'https://www.catalystathletics.com/exercise/788/Wrist-Roller-Flexion/',
    'thoracic': 'https://www.acefitness.org/resources/pros/expert-articles/7960/thoracic-mobility-exercises-to-address-shoulder-pain/',
}
VERIFIED = {
    'step_up': 'Forward step-up: whole foot on platform, controlled ascent/descent; existing cw135, not a new duplicate.',
    'step_variations': 'Step-up/lunge variations, including lateral movement context; not evidence for an isolated heel-tap with support-leg-only return or a calf raise.',
    'step_glutes': 'Eccentric Step Down With Body Weight Only: slowly lower left leg, tap heel, relax and transfer weight to floor, then step back onto bench to reset and repeat. Publication describes a 10–12 inches bench, not a measured owner step height. Also step-up/knee-lift context for cw135/cw136.',
    'step_pushup': 'Elevated-hand push-up on step in beginner circuit; incline push-up, not feet-elevated cw009.',
    'feet_pushup': 'Decline Push-ups: hands on ground, feet on bench; distinct from hands-elevated incline push-ups.',
    'feet_pushup_low': 'Decline push-up instructions explicitly allow a low support for the feet; not a mandatory 30–50 cm height.',
    'standing_calf': 'Bodyweight Standing Calf Raise: forefeet on raised step, heel lowering and raising, hand support for balance and optional dumbbell. Not a step-up or lunge.',
    'decline_crunch': 'Incline/decline abdominal crunch: secured legs, spinal flexion, distinct from full hip-flexion sit-up.',
    'decline_situp': 'Decline sit-up: secured legs, trunk and hip flexion; unloaded conservative adaptation, no mandatory plate.',
    'decline_press': 'Dumbbell decline bench press setup and controlled press; purpose-rated load-bearing bench required.',
    'balance': 'Two-leg and one-leg standing balance on Dynair cushion only; no pelvic-floor, treatment or clinical claims imported.',
    'roll_calf': 'ACE Myofascial Release handout, calf rolling instructions; slow calf contact, avoid joints and painful pressure.',
    'roll_quad': 'Foam-roller quadriceps technique; supported front-thigh rolling, no knee pressure or therapeutic promise.',
    'roll_glute': 'Glute foam-roller position and controlled rolling, gentle self-selected pressure; no recovery guarantee.',
    'carry': 'Bear-hug Ultimate Sandbag carry; bag held against torso and controlled walking. Bag configuration differs; no universal 20 kg target.',
    'wrist': 'Wrist Roller Flexion: suspended load wound up and lowered under control; complete up/down cycle, no dumbbell pair.',
    'thoracic': 'Thoracic extension over foam roller; support head, avoid substituting lumbar extension; alternate apparatus for cw267.',
}
EDITORIAL_ADAPTATIONS = {
    'step_glutes': 'Editorial adaptation for cw414: a stable low adjustable step replaces the published 10–12 inches bench; 10–15 cm is illustrative only, not measured owner height or a source-prescribed target. Preserve the controlled descent, floor weight transfer and separate step-up reset; do not turn it into a support-leg-only heel-tap return.',
    'feet_pushup': 'Editorial equipment options for cw009: stable Step or chair in place of the demonstrated bench; no fixed height prescription. These options are adaptations, not an exact list quoted from this article.',
    'feet_pushup_low': 'Low support is source-supported; exact owner step height is not measured. Stability and control determine a suitable low setting, not a universal centimetre target.',
    'standing_calf': 'Editorial equipment naming for cw165: Step or suitable stable legacy bench. Optional balance support and optional dumbbell are separate technique choices, not a requirement for a dumbbell pair or mandatory use of extra weight.',
}
ALL_CONDITIONS = ['no_jumps', 'quiet', 'no_kneeling', 'no_hand_support', 'no_floor', 'small_space']
STOP = 'Oddychaj swobodnie; Przerwij przy bólu, drętwieniu lub zawrotach głowy'
STEP = ('Sprawdź stabilność i blokadę podstawy stepu na nieśliskim podłożu; '
        'Wysokość stepu właściciela jest niezmierzona, deklarowane 150 kg nie jest zweryfikowaną nośnością; '
        'Wybierz niskie ustawienie pozwalające zachować kontrolę, bez narzucania wysokości; ')
BENCH = ('Sprawdź stabilność ławki do brzuszków, blokadę skosu i pewne zabezpieczenie nóg; '
         'Zacznij od łagodnego skosu głową w dół, bez dodatkowego ciężaru; ')


def entry(n, pl, en, primary, secondary, gear, source, cues, errors, progression, regression,
          *, tracking='reps', unilateral=False, position='standing', style='strength',
          kind='Siła', conditions=None):
    return dict(number=n, pl=pl, en=en, primary=primary.split(), secondary=secondary.split(),
                equipment=gear, source=source, cues=cues + '; ' + STOP, errors=errors,
                progression=progression, regression=regression, style=[style], kind=kind,
                level='Początkujący', pattern='Kontrolowany ruch',
                prescription=('2 x 15-30 sek' if tracking == 'time' else '2 x 6-10') +
                             (' na stronę' if unilateral else ''),
                tempo='Wolno i płynnie, bez odbicia', positions=[position],
                conditions=list(ALL_CONDITIONS if conditions is None else conditions),
                unilateral=unilateral, tracking=tracking)


ADDITIONS = [
    entry(413, 'Wejście bokiem na step', 'Lateral step-up', 'quadriceps glutes', 'abs calves',
          'Step', 'step_variations', STEP +
          'Stań bokiem przy stepie, bliższą stopę ustaw w całości na platformie; Kolano prowadź w kierunku palców; Unieś tułów pracą nogi na stepie, bez wybicia z podłogi; Dostaw drugą stopę i zejdź powoli w tej samej kolejności',
          'Kolano zapadające do środka; Odbijanie nogą z podłogi; Zeskakiwanie',
          'Najpierw dodaj kontrolowane powtórzenia z niezmienioną wysokością',
          'Niższe ustawienie i mniej powtórzeń, z odpoczynkiem przed utratą kontroli', unilateral=True),
    entry(414, 'Kontrolowane zejście ze stepu', 'Controlled step-down', 'quadriceps glutes', 'abs',
          'Step', 'step_glutes', STEP +
          'Stań stabilnie na stepie z całą stopą nogi podporowej na platformie; Powoli ugnij biodro i kolano nogi podporowej, opuszczając drugą piętę do lekkiego dotknięcia podłogi przed stepem; Zachowaj miednicę poziomo i kolano w linii stopy; Po dotknięciu piętą spokojnie przenieś ciężar na podłogę i zakończ zejście; Następnie wejdź ponownie na step, ustaw się stabilnie i rozpocznij kolejne kontrolowane zejście',
          'Spadanie na podłogę; Zapadanie kolana; Przechylanie miednicy; Gwałtowne odbicie zamiast spokojnego zejścia i ponownego ustawienia',
          'Wydłuż kontrolowaną fazę opuszczania lub dodaj powtórzenia, nie skoki',
          'Niższy step i krótszy kontrolowany zakres', unilateral=True),
    entry(415, 'Pompki z dłońmi na stepie', 'Hands-elevated step push-up', 'chest', 'triceps shoulders abs',
          'Step', 'step_pushup', STEP +
          'Oprzyj dłonie stabilnie na platformie stepu nieco szerzej niż barki, stopy na podłodze; Utrzymaj tułów i biodra w jednej linii; Ugnij łokcie ukośnie w tył i zbliż klatkę do stepu; Odepchnij się bez zapadania lędźwi',
          'Ślizgający się step; Zapadanie bioder; Łokcie szeroko na boki; Stopy zamiast dłoni na stepie',
          'Dodaj poprawne powtórzenia; później wybierz trudniejszą pompkę na podłodze jako osobny wariant',
          'Mniej powtórzeń; łatwiejszy wariant z dłońmi na wyższej, stabilnej podporze',
          position='floor', conditions=['no_jumps', 'quiet', 'no_kneeling', 'small_space']),
    entry(416, 'Spięcia brzucha na ławce głową w dół', 'Decline bench crunch', 'abs', '',
          'Ławka do brzuszków', 'decline_crunch', BENCH +
          'Połóż się z podpartymi plecami i lekko ugiętymi kolanami; Skrzyżuj ręce na klatce; Z wydechem unieś tylko głowę i łopatki, zbliżając żebra do miednicy; Powoli odłóż łopatki, nie przechodź do pełnego siadu',
          'Ciągnięcie głowy rękami; Zamach; Pełny siad zamiast spięcia; Wstrzymywanie oddechu',
          'Dodaj kontrolowane powtórzenia i krótką pauzę w spięciu, bez dokładania ciężaru',
          'Mniejszy skos lub krótszy zakres; jeśli pozycja głową w dół jest źle tolerowana, wybierz spięcia na podłodze',
          position='bench'),
    entry(417, 'Pełne brzuszki na ławce głową w dół', 'Decline bench sit-up', 'hip_flexors abs', '',
          'Ławka do brzuszków', 'decline_situp', BENCH +
          'Połóż plecy na ławce, ręce skrzyżuj na klatce; Najpierw zbliż żebra do miednicy, potem zegnij biodra i unieś tułów do siadu w wygodnym zakresie; Opuszczaj tułów powoli aż plecy znów będą podparte; Nie szarp nogami o blokadę',
          'Zamach ramion; Gwałtowne odchylanie głowy; Zrzucanie tułowia; Zbyt duży skos',
          'Zwiększ liczbę płynnych powtórzeń, nie obciążenie ani głębokość skosu za wszelką cenę',
          'Mniejszy skos i mniej powtórzeń; wybierz samo spięcie brzucha, jeśli pełny siad traci kontrolę', position='bench'),
    entry(418, 'Wyciskanie hantli na ławce głową w dół', 'Dumbbell decline bench press', 'chest', 'triceps shoulders',
          'Ławka ujemna do wyciskania, Hantle', 'decline_press',
          'Wymagana jest osobno potwierdzona ławka ujemna przeznaczona do wyciskania z obciążeniem; Ławka właściciela do brzuszków ma niezweryfikowaną nośność do hantli: sama deklaracja przydatności nie wystarcza, nie wykonuj na niej tego ruchu bez potwierdzenia producenta; Sprawdź limit łącznej masy ciała i hantli, stabilność, blokadę skosu oraz zabezpieczenie nóg; Ustal bezpieczne podanie i odebranie lekkich hantli, w razie potrzeby z asekuracją; Połóż się z podpartą głową, plecami i pośladkami; Prowadź hantle po bokach klatki, nadgarstki nad łokciami; Wyciskaj płynnie nad klatkę i opuszczaj bez odbicia',
          'Użycie niezweryfikowanej ławki do brzuszków; Brak bezpiecznego odłożenia; Zrzucanie hantli; Nadmierny skos; Wstrzymywanie oddechu',
          'Najpierw popraw kontrolę i powtórzenia; dopiero na zweryfikowanym sprzęcie rozważ najmniejszy przyrost obciążenia',
          'Lżejsze hantle i mniejszy zatwierdzony skos; bez właściwej ławki wybierz inne ćwiczenie', position='bench'),
    entry(419, 'Stanie obunóż na poduszce równoważnej', 'Double-leg balance cushion stand', 'feet calves', 'glutes abs',
          'Poduszka równoważna', 'balance',
          'Połóż poduszkę na nieśliskiej podłodze obok stabilnego podparcia awaryjnego; Wejdź ostrożnie i ustaw obie stopy na poduszce; Utrzymuj miękkie kolana, wzrok na nieruchomym punkcie i spokojny oddech; Zejdź przed utratą równowagi',
          'Zamykanie oczu na początku; Blokowanie kolan; Ustawienie przy przeszkodach; Kontynuowanie mimo utraty równowagi',
          'Stopniowo wydłuż spokojne stanie z otwartymi oczami',
          'Krótsze próby lub stanie na stabilnej podłodze', tracking='time', kind='Izometria'),
    entry(420, 'Stanie jednonóż na poduszce równoważnej', 'Single-leg balance cushion stand', 'feet calves', 'glutes abs',
          'Poduszka równoważna', 'balance',
          'Ustaw poduszkę na nieśliskiej podłodze blisko stabilnego podparcia awaryjnego; Ustaw stopę podporową na środku i lekko ugnij kolano; Ostrożnie unieś drugą stopę, utrzymuj miednicę poziomo i patrz przed siebie; Odstaw stopę natychmiast przy utracie kontroli',
          'Zapadanie kolana; Przechylanie miednicy; Zamykanie oczu; Ryzyko upadku przy zbyt długiej próbie',
          'Wydłuż krótkie stabilne próby z otwartymi oczami, bez dodawania ciężaru',
          'Stanie obunóż na poduszce lub jednonóż na stabilnej podłodze',
          tracking='time', unilateral=True, kind='Izometria'),
    entry(421, 'Rolowanie łydki', 'Calf foam rolling', 'calves', '', 'Roller', 'roll_calf',
          'Usiądź na podłodze, roller umieść pod miękką częścią łydki, drugą stopę i dłonie oprzyj dla kontroli nacisku; Powoli przesuwaj łydkę po rollerze na krótkim odcinku; Omijaj dół podkolanowy, kostki i ścięgno Achillesa; Nacisk ma być łagodny i tolerowany, nie walcz z bólem',
          'Nacisk na staw lub ścięgno; Szybkie ruchy; Silny ból; Wstrzymywanie oddechu',
          'Wydłuż łagodne rolowanie do komfortowego czasu, nie zwiększaj nacisku przez ból',
          'Więcej ciężaru na stopie i dłoniach, krótszy odcinek i czas', tracking='time', unilateral=True,
          position='floor', style='mobility_recovery', kind='Regeneracja',
          conditions=['no_jumps', 'quiet', 'no_kneeling', 'small_space']),
    entry(422, 'Rolowanie przedniej części uda', 'Quadriceps foam rolling', 'quadriceps', '', 'Roller', 'roll_quad',
          'Połóż przód uda na rollerze i podeprzyj tułów na przedramionach; Drugą nogą reguluj nacisk; Powoli przesuwaj miękką część uda po rollerze, bez dociskania pachwiny i rzepki; Utrzymuj spokojny oddech i łagodny nacisk',
          'Rolowanie po kolanie; Zbyt silny nacisk; Zapadanie lędźwi; Szybkie przejazdy',
          'Stopniowo wydłuż komfortowy czas, bez forsowania nacisku',
          'Odciąż nogę podporową, skróć zakres i czas', tracking='time', unilateral=True,
          position='floor', style='mobility_recovery', kind='Regeneracja',
          conditions=['no_jumps', 'quiet', 'small_space']),
    entry(423, 'Rolowanie pośladka', 'Glute foam rolling', 'glutes', '', 'Roller', 'roll_glute',
          'Usiądź na rollerze z dłońmi i stopami opartymi stabilnie; Lekko przenieś nacisk na jeden pośladek, drugą stopą reguluj obciążenie; Wykonuj małe powolne przesunięcia po miękkiej części pośladka; Omijaj kości i przerwij przy promieniowaniu lub drętwieniu',
          'Ucisk kości; Silny ból; Szybkie kołysanie; Ignorowanie drętwienia',
          'Wydłuż łagodne kontrolowane rolowanie, bez wymuszania większego nacisku',
          'Więcej podparcia na stopach i dłoniach oraz krótszy czas', tracking='time', unilateral=True,
          position='floor', style='mobility_recovery', kind='Regeneracja',
          conditions=['no_jumps', 'quiet', 'no_kneeling', 'small_space']),
    entry(424, 'Chód z sandbagiem objętym przed tułowiem', 'Bear-hug sandbag carry', 'abs back', 'glutes quadriceps forearms',
          'Sandbag', 'carry',
          'Sprawdź zamknięcia worka i wolną płaską trasę bez przeszkód; Dobierz masę pozwalającą bezpiecznie podnieść, objąć i odłożyć worek, bez szarpania; Obejmij worek przed tułowiem, blisko klatki, nie zaciskaj szyi; Idź małymi spokojnymi krokami z wyprostowanym tułowiem i swobodnym oddechem; Odłóż worek kontrolowanie pracą bioder i kolan; Worek właściciela pozostaje operacyjnie przy 20 kg, to nie uniwersalny cel: jeśli za ciężki, nie wykonuj ruchu',
          'Odchylanie tułowia w tył; Zasłonięta trasa; Wstrzymywanie oddechu; Zrzucanie worka; Schody lub step z workiem',
          'Najpierw wydłuż krótki odcinek lub czas przy tej samej komfortowej masie; nie dokładaj obciążenia',
          'Krótszy odcinek lub lżejszy worek, jeśli dostępny; gdy posiadany worek jest za ciężki, wybierz inny ruch',
          tracking='time', style='conditioning', kind='Wytrzymałość',
          conditions=['no_jumps', 'quiet', 'no_kneeling', 'no_hand_support', 'no_floor']),
]

EQUIPMENT_SETS = {
    'cw009': [['Masa własna', 'Step'], ['Masa własna', 'Krzesło'], ['Masa własna', 'Ławeczka']],
    **{eid: [['Masa własna', 'Step'], ['Hantle', 'Step'], ['Hantle', 'Ławeczka']]
       for eid in ('cw135', 'cw136', 'cw165')},
    'cw267': [['Ławeczka'], ['Roller']],
}


def correction_manifest():
    """Only reviewed catalog fields; no history, tracking or measurements."""
    fields = {
        'cw009': dict(nazwaPl='Pompki z podniesionymi nogami',
                      sprzet=['Masa własna', 'Ławeczka'],
                      kluczoweWskazowki=['Oprzyj stopy na stabilnym stepie, krześle lub ławce, dłonie na podłodze',
                                        'Wybierz niską wysokość pozwalającą utrzymać ciało w linii, bez narzucania centymetrów',
                                        'Napnij brzuch, uginaj łokcie ukośnie w tył i zbliż klatkę do podłogi',
                                        'Odepchnij się bez zapadania bioder, oddychaj swobodnie'],
                      czesteBledy=['Niestabilne podparcie stóp', 'Zapadanie bioder', 'Zbyt wysokie podparcie zmieniające ruch w pike'],
                      progresja='Najpierw dodaj kontrolowane powtórzenia przy tej samej wysokości',
                      regresja='Niższe stabilne podparcie stóp lub pompka na podłodze'),
        'cw123': dict(nazwaPl='Nawijanie i rozwijanie linki na wrist rollerze', sprzet=['Wrist roller'],
                      kluczoweWskazowki=['Sprawdź uchwyt, linkę i mocowanie zawieszonego talerza',
                                        'Trzymaj uchwyt oburącz stabilnie przed sobą, barki rozluźnione',
                                        'Nawijaj linkę naprzemienną pracą nadgarstków aż ciężar uniesie się bez kontaktu z uchwytem',
                                        'Rozwijaj linkę powoli pod kontrolą aż ciężar wróci w dół: góra–dół to pełny cykl',
                                        'Zapis kg oznacza wyłącznie zawieszony ciężar, nie masę uchwytu ani parę hantli',
                                        'Oddychaj swobodnie i przerwij przy bólu nadgarstków lub drętwieniu'],
                      czesteBledy=['Swobodne spadanie ciężaru', 'Szarpanie barkami', 'Zbyt duży ciężar', 'Liczenie masy uchwytu lub pary hantli'],
                      progresja='Najpierw dodaj kontrolowany pełny cykl; później najmniejszy przyrost zawieszonego ciężaru',
                      regresja='Lżejszy zawieszony ciężar i mniej pełnych cykli'),
        'cw135': dict(nazwaPl='Wchodzenie na podwyższenie',
                      kluczoweWskazowki=[STEP.rstrip('; '), 'Ustaw całą stopę na stepie i wejdź pracą nogi podporowej bez odbicia tylną nogą',
                                        'Prowadź kolano w kierunku palców i zejdź powoli',
                                        'Zacznij bez hantli; wariant obciążony wymaga hantli oraz stepu lub stabilnej ławki przeznaczonej do takiego użycia'],
                      czesteBledy=['Odbijanie tylną nogą', 'Kolano do środka', 'Zeskakiwanie', 'Zbyt wysokie lub niestabilne podwyższenie'],
                      progresja='Najpierw powtórzenia i kontrola; hantle dopiero przy stabilnym ruchu i odpowiednim sprzęcie',
                      regresja='Niższy step i masa własna'),
        'cw136': dict(nazwaPl='Wchodzenie na podwyższenie z uniesieniem kolana',
                      kluczoweWskazowki=[STEP.rstrip('; '), 'Cała stopa podporowa na stepie, wejdź bez odbicia z podłogi',
                                        'Po wejściu unieś wolne kolano do wygodnej wysokości, utrzymaj miednicę poziomo',
                                        'Opuść nogę i zejdź wolno bez podskoku',
                                        'Zacznij z masą własną; hantle wymagają stepu lub stabilnej ławki przeznaczonej do takiego użycia'],
                      czesteBledy=['Podskok zamiast kontroli', 'Zapadanie kolana', 'Brak pełnej stopy na podporze', 'Utrata równowagi'],
                      progresja='Dodaj krótką pauzę po uniesieniu kolana; ewentualne hantle dopiero po opanowaniu ruchu',
                      regresja='Niższy step, bez hantli lub bez uniesienia kolana'),
        'cw165': dict(nazwaPl='Wspięcia na palce na krawędzi podwyższenia',
                      kluczoweWskazowki=[STEP.rstrip('; '), 'Oprzyj przodostopie pewnie na krawędzi stepu, pięty poza podporą',
                                        'Powoli opuść pięty tylko do komfortowego zakresu i wznieś się na palce bez odbicia',
                                        'Zacznij bez obciążenia; hantle wymagają stabilnego stepu lub ławki przeznaczonej do takiego użycia',
                                        'Nie forsuj rozciągnięcia ani równowagi, oddychaj swobodnie'],
                      czesteBledy=['Odbijanie w dole', 'Wymuszanie głębokiego rozciągnięcia', 'Ślizgające się przodostopie', 'Zbyt duży ciężar'],
                      progresja='Najpierw kontrola i powtórzenia; hantle tylko przy zachowanej równowadze i właściwej podporze',
                      regresja='Mniejszy zakres i masa własna albo wspięcia z podłogi'),
        'cw267': dict(nazwaPl='Wyprost odcinka piersiowego na podporze',
                      kluczoweWskazowki=['Wariant z ławką: oprzyj górną część pleców poprzecznie na stabilnej niskiej ławce, stopy na podłodze',
                                        'Wariant z rollerem: połóż się na podłodze z rollerem poprzecznie pod górną częścią pleców, kolana ugięte',
                                        'Podeprzyj głowę dłońmi, łokcie kieruj lekko do przodu',
                                        'Wykonaj mały spokojny wyprost w odcinku piersiowym i wróć, nie wyginaj lędźwi',
                                        'Nie roluj szyi ani lędźwi i nie forsuj bólu, oddychaj swobodnie'],
                      czesteBledy=['Przeprost lędźwi', 'Ciągnięcie głowy', 'Duży zamach', 'Nacisk rollera na szyję lub lędźwie'],
                      progresja='Popraw kontrolę i dodaj spokojne powtórzenia, bez dodatkowego ciężaru',
                      regresja='Mniejszy bezbolesny zakres lub przerwij, jeśli nie możesz utrzymać kontroli'),
    }
    return dict(schemaVersion=1, corrections=[dict(exerciseId=eid, revision=1, fields=f)
                                             for eid, f in fields.items()])


def source_records():
    return {f'cw{a["number"]}': dict(source='owner_equipment_' + a['source'], movement=a['en'])
            for a in ADDITIONS}
