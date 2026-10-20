"""Original Polish editorial descriptions, 2026-10-20. Not medical prescriptions.

Sources below were consulted during the catalog research in the conversation.
Dose is deliberately not individualized; partner tasks require explicit consent.
23 individual movements + 16 partner tasks. Eleven proposed variants are not IDs.
"""

SOURCES = {
    'nhs_strength': 'https://www.nhs.uk/live-well/exercise/strength-exercises/',
    'nhs_standing': 'https://www.uhsussex.nhs.uk/resources/standing-exercises',
    'aaos_hip': 'https://orthoinfo.aaos.org/en/recovery/hip-conditioning-program',
    'ace_curl': 'https://www.acefitness.org/resources/everyone/exercise-library/131/prone-lying-hamstrings-curl/',
    'band_extension': 'https://musclewiki.com/exercise/band-leg-extension',
    'band_pullthrough': 'https://musclewiki.com/exercise/band-pullthrough',
    'band_adduction': 'https://library.theprehabguys.com/vimeo-video/standing-hip-adduction-band',
    'slider_curl': 'https://www.muscleandfitness.com/exercise/workouts/leg-exercises/sliding-leg-curl',
    'hundred': 'https://pilatesology.com/pilatesology-encyclopedia-hundred/',
    'leg_circles': 'https://onlinepilatesclasses.com/pilates-exercises/mat-exercises/mat-single-leg-circles',
    'single_stretch': 'https://onlinepilatesclasses.com/pilates-exercises/mat-exercises/mat-single-leg-stretch',
    'double_stretch': 'https://onlinepilatesclasses.com/pilates-exercises/mat-exercises/mat-double-leg-stretch',
    'saw': 'https://onlinepilatesclasses.com/pilates-exercises/mat-exercises/mat-saw',
    'gmb_joints': 'https://gmb.io/joint-mobility',
    'adductor_rockback': 'https://theprehabguys.com/vimeo-video/quadruped-dynamic-long-adductor-stretch/',
    'otago': 'https://roh.nhs.uk/services-information/therapy/otago-strength-and-balance-exercises',
    'nhs_balance': 'https://www.nhs.uk/live-well/exercise/balance-exercises/',
    'aaos_feet': 'https://orthoinfo.aaos.org/recovery/foot-and-ankle-conditioning-program/',
    'short_foot': 'https://www.nhsinform.scot/illnesses-and-conditions/muscle-bone-and-joints/leg-and-foot-problems-and-conditions/exercises-for-foot-conditions',
    'ankle_band': 'https://www.leicspart.nhs.uk/wp-content/uploads/2022/07/474-ankle-exercises.pdf',
    'partner_body': 'https://www.healthline.com/health/fitness-exercise/partner-workouts',
    'partner_squat': 'https://www.mobilesport.ch/aktuell/kraeftigen-oberschenkel-vorne-ruecken-an-ruecken/',
    'reaction': 'https://www.nsca.com/education/articles/kinetic-select/5-reaction-drills-to-build-quickness/',
    'mirror': 'https://www.westernracquet.com/blog/fun-partner-workouts-to-try',
    'partner_ball': 'https://www.silversneakers.com/blog/partner-workout-total-body-strength-exercises-2',
    'lunge_pass': 'https://www.acefitness.org/resources/everyone/exercise-library/264/medicine-ball-lunge-to-chest-pass',
    'partner_ace': 'https://www.acefitness.org/resources/pros/expert-articles/6194/6-calorie-blasting-partner-exercises/',
    'seated_pass': 'https://www.goldsgym.com/blog/partner-workout',
}

# Conditions are explicit decisions about the BASE version, never name inference.
STAND = ['no_jumps', 'quiet', 'no_kneeling', 'no_hand_support', 'no_floor', 'small_space']
SUPPORT = ['no_jumps', 'quiet', 'no_kneeling', 'no_floor', 'small_space']
FLOOR = ['no_jumps', 'quiet', 'no_kneeling', 'no_hand_support', 'small_space']
QUAD = ['no_jumps', 'quiet', 'small_space']
STOP = 'Przerwij przy bólu, drętwieniu, zawrotach głowy lub nietypowej duszności; nie wstrzymuj oddechu'


def entry(pl, en, primary, secondary, equipment, source, cues, errors, regression,
          *, style='strength', kind='Siła', level='Początkujący', position='standing',
          conditions=None, unilateral=False, tracking='reps', progression=None):
    partner = 'Partner' in equipment.split(', ')
    return dict(pl=pl, en=en, primary=primary.split(), secondary=secondary.split(),
                equipment=equipment, source=source, cues=cues + '; ' + STOP + (
                    '; Ustalcie komendę STOP; kończcie zadanie razem bez nagłego puszczania oporu; '
                    'Dobierzcie trudność do słabszego partnera; po serii zamieńcie role A i B'
                    if partner else ''), errors=errors, regression=regression,
                progression=progression or 'Najpierw popraw kontrolę ruchu; dopiero potem dodaj 1-2 powtórzenia bez bólu',
                style=([style, 'partner'] if partner else [style]), kind=kind,
                level=level, pattern=en, prescription=(
                    '1 x 10-15 sek' if tracking == 'time' else '1 x 4-6 na stronę' if unilateral else '1 x 4-6'),
                tempo='Spokojnie i kontrolowanie, odpocznij po próbie',
                positions=[position], conditions=list(conditions if conditions is not None else STAND),
                unilateral=unilateral, tracking=tracking)


ADDITIONS = [
    entry('Wstawanie z krzesła', 'Sit to stand', 'quadriceps glutes', 'abs', 'Krzesło', 'nhs_strength',
          'Ustaw stabilne krzesło przy ścianie; Usiądź bliżej krawędzi, stopy płasko; Pochyl tułów z bioder i wstań; Powoli usiądź bez opadania',
          'Opadanie na siedzisko; Zapadanie kolan do środka', 'Wyższe siedzisko i pomoc dłoni', position='seated'),
    entry('Odwodzenie prostej nogi w staniu z podparciem', 'Supported standing hip abduction', 'glutes', 'abs', 'Krzesło', 'nhs_standing',
          'Zabezpiecz krzesło przy ścianie, chwyć oparcie; Stań prosto; Unieś nogę w bok bez obrotu miednicy; Spokojnie opuść i zmień stronę',
          'Przechylanie tułowia; Wymachiwanie nogą', 'Mniejszy zakres i obie dłonie na podporze', conditions=SUPPORT, unilateral=True),
    entry('Prostowanie biodra w staniu z podparciem', 'Supported standing hip extension', 'glutes', 'hamstrings abs', 'Krzesło', 'nhs_standing',
          'Zabezpiecz krzesło przed przesuwaniem; Przytrzymaj oparcie; Przesuń prostą nogę nieznacznie za siebie; Wróć bez przeprostu pleców',
          'Wyginanie lędźwi; Pochylanie tułowia', 'Krótszy ruch bez wysokiego unoszenia nogi', conditions=SUPPORT, unilateral=True),
    entry('Odwodzenie prostej nogi w leżeniu bokiem', 'Side lying straight leg abduction', 'glutes', 'abs', 'Masa własna', 'aaos_hip',
          'Połóż się na boku z podpartą głową; Ugnij dolną nogę; Unieś prostą górną nogę bez obracania bioder; Powoli opuść i zmień bok',
          'Obracanie palców ku sufitowi; Kołysanie tułowiem', 'Niższe uniesienie', position='floor', conditions=FLOOR, unilateral=True),
    entry('Przywodzenie dolnej nogi w leżeniu bokiem', 'Side lying lower leg adduction', 'adductors', 'abs', 'Masa własna', 'aaos_hip',
          'Połóż się na boku; Przełóż ugiętą górną nogę przed dolną, stopa oparta; Dolną nogę unieś nieznacznie; Opuść i zmień bok',
          'Przetaczanie na plecy; Szarpanie', 'Mały ruch bez bólu pachwiny', position='floor', conditions=FLOOR, unilateral=True),
    entry('Uginanie nogi z gumą w leżeniu na brzuchu', 'Prone band hamstring curl', 'hamstrings', '', 'Gumy oporowe', 'ace_curl',
          'Zamocuj gumę nisko od strony stóp i zabezpiecz mocowanie przy kostce; Połóż się na brzuchu; Zbliż piętę do pośladka zginając kolano; Powoli wyprostuj bez unoszenia uda',
          'Wyginanie pleców; Odrywanie uda; Niepewny zaczep', 'Słabsza guma i krótszy zakres', position='floor', conditions=FLOOR, unilateral=True),
    entry('Prostowanie kolana z gumą w siadzie', 'Seated band knee extension', 'quadriceps', '', 'Krzesło, Gumy oporowe', 'band_extension',
          'Usiądź na stabilnym krześle z podpartym udem; Zabezpiecz gumę przy kostce i nieruchomym zaczepie za sobą; Wyprostuj kolano w wygodnym zakresie; Powoli wróć',
          'Podrzucanie nogi; Odrywanie uda; Przesuwanie siedziska przez gumę', 'Ruch bez gumy', position='seated', unilateral=True),
    entry('Wyprost bioder z przeciąganiem gumy między nogami', 'Band pull through', 'glutes hamstrings', 'abs back', 'Gumy oporowe', 'band_pullthrough',
          'Zabezpiecz niski zaczep za plecami; Stań tyłem i chwyć gumę między nogami; Cofnij biodra przy miękkich kolanach; Wyprostuj biodra do pionu bez odchylenia w tył',
          'Przysiad zamiast ruchu bioder; Przeprost lędźwi', 'Słabsza guma lub cofanie bioder do ściany cw369'),
    entry('Przywodzenie nogi z gumą w staniu', 'Standing band hip adduction', 'adductors', 'glutes abs', 'Gumy oporowe, Krzesło', 'band_adduction',
          'Zabezpiecz krzesło i niski zaczep gumy; Stań bokiem, guma przy kostce bliższej zaczepowi; Przyciągnij tę nogę ku środkowi ciała; Powoli odprowadź bez obrotu tułowia',
          'Szarpanie nogą; Obracanie miednicy', 'Słabsza guma i mały zakres', conditions=SUPPORT, unilateral=True),
    entry('Uginanie nóg na ślizgaczach', 'Sliding leg curl', 'hamstrings glutes', 'abs', 'Ślizgacze', 'slider_curl',
          'Sprawdź zgodność ślizgaczy z podłogą i wolny tor ruchu; Połóż się na plecach, pięty na ślizgaczach; Unieś biodra; Powoli odsuń i przyciągnij pięty utrzymując kontrolę miednicy',
          'Gwałtowny poślizg; Wyginanie pleców; Kontynuowanie mimo skurczu', 'Krótki ruch obunóż, bez pełnego wyprostu', position='floor', conditions=FLOOR, level='Średni'),
    entry('Pilates — setka z rytmiczną pracą ramion', 'Pilates Hundred', 'abs', 'hip_flexors', 'Masa własna', 'hundred',
          'Połóż się na plecach z ugiętymi nogami; Unieś głowę i łopatki tylko przy swobodnej szyi; Wykonuj małe ruchy ramion przy bokach; Oddychaj rytmicznie i odpocznij przed utratą kontroli',
          'Napinanie szyi; Zatrzymywanie oddechu; Wyginanie pleców', 'Głowa i stopy na podłodze, krótsza seria', position='floor', conditions=FLOOR, style='pilates', kind='Wytrzymałość', tracking='time'),
    entry('Pilates — krążenia jedną nogą w leżeniu', 'Pilates single leg circles', 'hip_flexors', 'abs glutes', 'Masa własna', 'leg_circles',
          'Połóż się na plecach, ramiona przy bokach; Unieś jedną nogę; Zataczaj małe koła w obie strony bez ruchu miednicy; Opuść nogę i zmień stronę',
          'Kołysanie biodrami; Forsowanie pachwiny', 'Ugnij kolano drugiej nogi i zmniejsz koła', position='floor', conditions=FLOOR, style='pilates', unilateral=True),
    entry('Pilates — naprzemienne wydłużanie nóg', 'Pilates single leg stretch', 'abs', 'hip_flexors', 'Masa własna', 'single_stretch',
          'Połóż się na plecach i unieś głowę z łopatkami; Przybliż jedno ugięte kolano, drugą nogę wydłuż wysoko po skosie; Spokojnie zmieniaj nogi; Utrzymuj tułów bez kołysania i odpoczywaj z głową na macie',
          'Szarpanie kolanem; Ciągnięcie szyją; Noga zbyt nisko', 'Krótszy ruch, noga prostowana wyżej', position='floor', conditions=FLOOR, style='pilates', unilateral=True),
    entry('Pilates — wydłużanie obu nóg i ramion', 'Pilates double leg stretch', 'abs', 'hip_flexors', 'Masa własna', 'double_stretch',
          'Z leżenia przybliż ugięte nogi do tułowia, głowa i łopatki lekko uniesione; Wydłuż nogi wysoko po skosie i ramiona za głowę; Zatocz ramionami łuk i ugnij nogi; Zachowaj kontrolę pleców bez zatrzymywania oddechu',
          'Przeprost lędźwi; Napinanie szyi', 'Krótszy zasięg, nogi wyżej lub martwy robak cw179', position='floor', conditions=FLOOR, style='pilates', level='Średni'),
    entry('Pilates — piła w siadzie', 'Pilates Saw', 'abs', 'back hamstrings', 'Masa własna', 'saw',
          'Usiądź w niewielkim rozkroku, ramiona rozłożone; Obróć tułów i sięgnij do przeciwnej stopy; Wróć do pionu i zmień stronę; Nie przesuwaj bioder ani nie forsuj skłonu',
          'Ruch bioder; Szarpanie skłonu; Nadmierny skręt szyi', 'Ugięte kolana, wyższy siad i mniejszy skręt; przy zaleconym zakazie zgięcia lub rotacji wymaga indywidualnego doboru', position='floor', conditions=FLOOR, style='pilates', kind='Mobilność', unilateral=True),
    entry('Wysuwanie i cofanie łopatek w klęku podpartym', 'Quadruped scapular protraction retraction', 'serratus back', 'shoulders abs', 'Masa własna', 'gmb_joints',
          'Ustaw dłonie pod barkami, kolana pod biodrami; Utrzymuj proste łokcie; Pozwól klatce lekko opaść między ramionami; Odepchnij podłoże oddalając łopatki bez ruchu lędźwi',
          'Zginanie łokci jak w pompce; Zapadanie lędźwi', 'Mały ruch lub wykonanie przy ścianie', position='floor', conditions=QUAD, kind='Mobilność'),
    entry('Krążenia obręczy barkowej w klęku podpartym', 'Quadruped shoulder circles', 'serratus back', 'shoulders abs', 'Masa własna', 'gmb_joints',
          'Przyjmij klęk podparty z prostymi ramionami; Połącz małe unoszenie, cofanie, opuszczanie i wysuwanie obręczy barkowej; Wykonaj płynne koło; Zmień kierunek bez kołysania całym tułowiem',
          'Duży ruch tułowia; Praca mimo bólu nadgarstków', 'Osobne wysuwanie i cofanie łopatek cw385', position='floor', conditions=QUAD, kind='Mobilność'),
    entry('Cofanie bioder w klęku z nogą wyprostowaną w bok', 'Straight leg adductor rock back', 'adductors', 'hamstrings', 'Masa własna', 'adductor_rockback',
          'Przyjmij klęk podparty; Wyprostuj jedną nogę w bok; Cofnij biodra ku pięcie nogi podporowej bez zaokrąglania pleców; Wróć i zmień stronę bez dociskania pachwiny',
          'Zaokrąglanie pleców; Forsowanie zakresu', 'Mniejszy rozkrok i krótszy ruch', position='floor', conditions=QUAD, kind='Mobilność', unilateral=True),
    entry('Stanie tandemowe przy podporze', 'Supported tandem stand', 'calves glutes', 'abs feet', 'Krzesło', 'otago',
          'Zabezpiecz krzesło przy ścianie i miej oparcie w zasięgu dłoni; Ustaw piętę jednej stopy przed palcami drugiej; Patrz przed siebie i oddychaj; Zamień ustawienie stóp po spokojnym wyjściu z pozycji',
          'Zamykanie oczu; Brak zabezpieczenia przy chwiejności', 'Rozsuń stopy na boki i trzymaj podporę', conditions=SUPPORT, tracking='time', unilateral=True, kind='Izometria'),
    entry('Chód pięta–palce przy podporze', 'Heel to toe walk', 'calves glutes', 'abs feet', 'Masa własna', 'nhs_balance',
          'Wybierz wolny tor przy stabilnej ścianie; Idź powoli ustawiając piętę przed palcami drugiej stopy; Patrz przed siebie; Zatrzymaj się przed zawróceniem, w razie chwiejności przerwij',
          'Pośpiech; Patrzenie wyłącznie pod nogi', 'Szerszy tor, dotykanie ściany dłonią', conditions=['no_jumps', 'quiet', 'no_kneeling', 'no_floor'], kind='Rozgrzewka'),
    entry('Zgarnianie ręcznika palcami stopy', 'Toe towel curls', 'feet', '', 'Krzesło, Ręcznik', 'aaos_feet',
          'Usiądź ze stopą na małym ręczniku; Zginając palce przyciągnij materiał pod stopę; Rozluźnij stopę; Powtórz bez przesuwania całej nogi, potem zmień stopę',
          'Przesuwanie nogi; Mocniejsze zaciskanie przy skurczu', 'Cieńszy ręcznik i mniej materiału', position='seated', unilateral=True),
    entry('Krótka stopa — aktywacja łuku w siadzie', 'Seated short foot exercise', 'feet', '', 'Krzesło', 'short_foot',
          'Usiądź ze stopą płasko; Oprzyj piętę i przodostopie; Delikatnie skróć stopę zbliżając podstawę palucha ku pięcie bez podwijania palców; Rozluźnij po małym napięciu i zmień stopę',
          'Podwijanie palców; Rolowanie na zewnętrzną krawędź', 'Mniejsza siła i krótka pauza', position='seated', unilateral=True),
    entry('Ruch stopy na zewnątrz przeciw gumie', 'Banded ankle eversion', 'peroneals', 'feet', 'Krzesło, Gumy oporowe', 'ankle_band',
          'Usiądź z podpartą nogą; Zabezpiecz gumę na przodostopiu tak, by opór przeciwdziałał ruchowi na zewnątrz; Utrzymując kolano nieruchomo odchyl przodostopie na zewnątrz; Powoli wróć bez wymuszania zakresu',
          'Obracanie całej nogi w biodrze; Guma zsuwająca się ze stopy', 'Mały ruch bez gumy', position='seated', unilateral=True),
]

PARTNERS = [
    entry('Deska z dotknięciem dłoni — w parach', 'Partner plank hand tap', 'abs serratus', 'shoulders glutes', 'Partner', 'partner_body',
          'A: ustaw podpór naprzeciw partnera, dłonie pod barkami; B: ustaw taki sam podpór w odległości lekkiego kontaktu dłoni; Oboje naprzemiennie dotknijcie dłoni partnera i odłóżcie ją; Utrzymujcie nieruchome biodra, kontakt bez uderzania',
          'Obracanie bioder; Sięganie za daleko; Próby przewracania partnera', 'Podpór na kolanach; warianty po opanowaniu: pompka przed kontaktem lub gąsienica do podporu', position='floor', conditions=['no_jumps', 'quiet', 'no_kneeling', 'small_space'], tracking='time', kind='Izometria', level='Średni'),
    entry('Przysiad plecami do siebie — w parach', 'Back to back partner squat', 'quadriceps glutes', 'abs', 'Partner', 'partner_squat',
          'A: oprzyj plecy o partnera i ustal równy nacisk; B: przyjmij stabilne ustawienie stóp i potwierdź gotowość; Oboje na sygnał wykonajcie płytki przysiad; Wróćcie razem do stania, nie odchodźcie nagle',
          'Nierówne tempo; Zbyt duża różnica masy lub wzrostu; Nagłe odejście', 'Mały zakres; wariant: krótkie utrzymanie półprzysiadu; przy niedopasowaniu wykonujcie niezależne przysiady naprzeciw siebie'),
    entry('Lustro ruchowe — w parach', 'Partner movement mirror', 'quadriceps glutes', 'calves abs', 'Partner', 'mirror',
          'A: prowadź powolne kroki i płytkie przysiady bez pozycji walki; B: odwzorowuj ruch z zachowaniem odstępu; Pozostańcie w wyznaczonej wolnej strefie; Zmieńcie prowadzącego na ustalony sygnał',
          'Nagłe trudne ruchy; Cofanie poza wolną strefę', 'Tylko kroki boczne w marszu', conditions=['no_jumps', 'no_kneeling', 'no_hand_support', 'no_floor'], style='conditioning', kind='Rozgrzewka', tracking='time'),
    entry('Przemieszczanie na gest — w parach', 'Partner wave direction drill', 'quadriceps glutes', 'calves abs', 'Partner', 'reaction',
          'A: pokazuj wcześniej uzgodnione kierunki; B: odpowiadaj krótkimi krokami i wracaj do środka; Wyznaczcie strefę hamowania bez przeszkód; Zmieniajcie role, na początku bez szybkiego biegu tyłem',
          'Sygnały zbyt szybkie; Brak miejsca na hamowanie', 'Tylko lewo i prawo w marszu', conditions=['no_jumps', 'no_kneeling', 'no_hand_support', 'no_floor'], style='conditioning', kind='Rozgrzewka', tracking='time'),
    entry('Chwyt piłki przed drugim odbiciem — w parach', 'Partner ball drop catch', 'quadriceps glutes', 'calves forearms', 'Partner, Piłka', 'reaction',
          'A: upuszczaj małą odbijającą piłkę w wolnej strefie; B: reaguj i łap przed drugim odbiciem; Ustalcie dystans bez ryzyka zderzenia; Nie rzucaj się na podłogę, nieudaną próbę odpuść',
          'Wbieganie na partnera; Nurkowanie za piłką', 'Mniejsza odległość i zapowiedź upuszczenia', conditions=['no_jumps', 'no_kneeling', 'no_hand_support', 'no_floor'], style='conditioning', kind='Rozgrzewka'),
    entry('Krok boczny z chwytem piłki — w parach', 'Partner shuffle reaction catch', 'quadriceps glutes', 'calves forearms', 'Partner, Piłka', 'reaction',
          'A: łagodnie podaj miękką piłkę na lewo lub prawo B; B: przesuń się krokiem dostawnym, złap i odeślij; Utrzymujcie bezpieczny dystans i wolny tor; Po serii zamieńcie role',
          'Podania poza zasięg; Krzyżowanie nóg w pośpiechu', 'Zapowiedziana strona i krótki dystans', conditions=['no_jumps', 'no_kneeling', 'no_hand_support', 'no_floor'], style='conditioning', kind='Rozgrzewka'),
    entry('Podania na jednej nodze — w parach', 'Partner single leg ball toss', 'glutes calves', 'abs forearms feet', 'Partner, Piłka', 'partner_ball',
          'A: stań stabilnie na jednej nodze z lekką miękką piłką; B: przyjmij takie samo ustawienie i pokaż gotowe dłonie; Wymieniajcie łagodne podania w zasięg dłoni; Zmieńcie nogi, odstaw stopę przed utratą równowagi',
          'Ciężka piłka; Ratowanie równowagi za wszelką cenę', 'Palce drugiej stopy na podłodze', conditions=['no_jumps', 'no_kneeling', 'no_hand_support', 'no_floor', 'small_space'], tracking='time', unilateral=True),
    entry('Podania sprzed klatki — w parach', 'Partner chest pass', 'chest triceps', 'shoulders abs forearms', 'Partner, Piłka', 'partner_body',
          'A: trzymaj miękką lekką piłkę przy klatce; B: pokaż gotowe dłonie; A podaje oburącz, B amortyzuje chwyt uginając ramiona i odsyła; Nie rzucajcie w twarz, zaczynajcie od łagodnych podań',
          'Podanie bez gotowości odbierającego; Sztywne łokcie przy chwycie', 'Lżejsza piłka i krótszy dystans', conditions=['no_jumps', 'no_kneeling', 'no_hand_support', 'no_floor', 'small_space'], style='conditioning'),
    entry('Wykrok z podaniem piłki — w parach', 'Partner lunge chest pass', 'quadriceps glutes', 'chest triceps abs', 'Partner, Piłka', 'lunge_pass',
          'A: wykonaj kontrolowany wykrok i podaj lekką piłkę; B: odbierz stojąc stabilnie; Poczekajcie aż A wróci do pozycji; Teraz B wykonuje wykrok i podaje, zachowajcie odstęp bez wchodzenia na siebie',
          'Jednoczesne wchodzenie na siebie; Podanie przed stabilizacją', 'Sam krok lub płytki wykrok', conditions=['no_jumps', 'no_kneeling', 'no_hand_support', 'no_floor'], level='Średni', unilateral=True),
    entry('Krok dostawny z podaniami — w parach', 'Partner side shuffle ball toss', 'quadriceps glutes', 'calves chest forearms', 'Partner, Piłka', 'partner_ace',
          'A: rozpocznij spokojny krok dostawny z lekką piłką; B: przemieszczaj się równolegle naprzeciw; Wymieniajcie łagodne podania przed klatkę; Zwolnijcie przed wspólną zmianą kierunku',
          'Rzuty za plecy; Rozbieganie partnerów; Nagłe zmiany kierunku', 'Zatrzymujcie się na każde podanie', conditions=['no_jumps', 'no_kneeling', 'no_hand_support', 'no_floor'], style='conditioning', tracking='time'),
    entry('Przysiad z przekazaniem piłki — w parach', 'Partner squat ball handoff', 'quadriceps glutes', 'abs shoulders', 'Partner, Piłka', 'partner_ball',
          'A: trzymaj lekką piłkę przy klatce; B: stań naprzeciw w zasięgu przekazania; Oboje wykonajcie przysiad i wróćcie do stania; A przekazuje piłkę do dłoni B bez rzutu i puszcza po potwierdzeniu chwytu',
          'Puszczanie zbyt wcześnie; Piłka daleko od tułowia', 'Płytki przysiad lub wstawanie ze stabilnych krzeseł'),
    entry('Przekazywanie piłki w siadzie plecami do siebie — w parach', 'Seated back to back partner ball pass', 'abs', 'back shoulders', 'Partner, Piłka', 'seated_pass',
          'A: usiądź stabilnie z ugiętymi kolanami i piłką; B: usiądź plecami do A; Obróćcie tułowia i przekażcie piłkę z rąk do rąk, potem na drugą stronę; Zmieńcie kierunek, nie szarpcie, przy ograniczeniu skrętów wybierzcie zwykłe podania',
          'Forsowanie skrętu; Szarpanie piłki; Przesuwanie bioder', 'Lekka piłka i mały skręt; wariant stojący w półprzysiadzie tylko bez dyskomfortu', position='floor', conditions=FLOOR, kind='Mobilność'),
    entry('Wiosłowanie gumą z oporem partnera — w parach', 'Partner anchored band row', 'back', 'biceps forearms abs', 'Partner, Gumy oporowe', 'partner_body',
          'A: stań stabilnie i trzymaj pewnie środek gumy przed sobą; B: chwyć uchwyty, przyjmij stabilny wykrok i przyciągnij łokcie ku tyłowi; B powoli prostuje ramiona, A utrzymuje stały opór; Zmieniajcie role dopiero po rozluźnieniu gumy',
          'Odchylanie tułowia; Szarpanie; Nagłe puszczanie gumy', 'Słabsza guma; przy niepewnym chwycie użyj właściwego nieruchomego zaczepu'),
    entry('Wyciskanie gumy z partnerem za plecami — w parach', 'Partner anchored band chest press', 'chest triceps', 'shoulders abs', 'Partner, Gumy oporowe', 'partner_body',
          'A: stabilizuj gumę za plecami B, poza linią twarzy; B: trzymaj uchwyty z gumą poniżej pach i przyjmij wykrok; B wypycha uchwyty przed klatkę i powoli cofa; A nie zmienia nagle oporu, zmiana ról po rozluźnieniu',
          'Guma przy szyi; Wyginanie pleców; Utrata chwytu', 'Słabsza guma lub nieruchomy zaczep zamiast partnera'),
    entry('Ruch po przekątnej z gumą — w parach', 'Partner band woodchop', 'abs', 'shoulders glutes', 'Partner, Gumy oporowe', 'partner_body',
          'A: stabilizuj gumę z boku B poniżej barków; B: chwyć drugi koniec i prowadź ramiona po krótkiej przekątnej z kontrolowanym obrotem; Wróć spokojnie bez skręcania kolan; Zmieńcie stronę i role po rozluźnieniu, nie kierujcie gumy na twarz',
          'Szarpanie; Skręt kolan przy nieruchomych stopach; Kierowanie gumy w twarz', 'Słaba guma, mała przekątna poniżej barków', unilateral=True, level='Średni'),
    entry('Chód w półprzysiadzie ze wspólną piłką — w parach', 'Partner stability ball squat walk', 'quadriceps glutes', 'shoulders abs', 'Partner, Piłka gimnastyczna', 'partner_ace',
          'A: oprzyj jedną dłoń o dużą piłkę gimnastyczną na wysokości barku; B: stań naprzeciw i oprzyj dłoń z drugiej strony; Przy lekkim wspólnym nacisku przejdźcie do płytkiego półprzysiadu i kroków bocznych; Zmieńcie ręce i kierunek, nie opierajcie ciężaru ciała na piłce',
          'Siłowe przepychanie piłki; Oparcie całego ciężaru; Nierówne tempo', 'Wyższa pozycja i pozostanie w miejscu', conditions=['no_jumps', 'quiet', 'no_kneeling', 'no_floor'], tracking='time'),
]

ADDITIONS += PARTNERS
for number, movement in enumerate(ADDITIONS, 370):
    movement['number'] = number
EXPECTED_COUNT = 369 + len(ADDITIONS)


def source_records():
    return {f'cw{a["number"]}': dict(source='partner_expansion_' + a['source'], movement=a['en']) for a in ADDITIONS}
