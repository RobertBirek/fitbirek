"""Original Polish EZ / easy cycling descriptions, reviewed 2026-10-21.

Sources validate technique, not individualized dosage or medical suitability.
"""
PREFIX_COUNT = 408
PREFIX_SHA256 = '98fea910a93c5f85796533c217d11ce437492307c9c9aea315b4f14804438ed9'
EXPECTED_COUNT = 412
SOURCES = {
    'ez_curl': 'https://www.muscleandstrength.com/exercises/ez-bar-curl.html',
    'ez_reverse_curl': 'https://www.muscleandstrength.com/exercises/ez-bar-reverse-grip-barbell-curl.html',
    'ez_extension': 'https://www.endomondo.com/exercise/ez-bar-lying-triceps-extension',
    'stationary_bike': 'https://www.arthritis.org/health-wellness/healthy-living/physical-activity/other-activities/benefits-of-stationary-biking',
    'talk_test': 'https://www.nhs.uk/live-well/exercise/exercise-guidelines/physical-activity-guidelines-for-adults-aged-19-to-64/',
}
VERIFIED = {
    'ez_curl': '2026-10-21 Exa publisher extraction: EZ Bar Curl Instructions 1–5 and Tips; underhand shoulder-width grip, fixed elbows, no swing, slow lowering. Original Polish adaptation.',
    'ez_reverse_curl': '2026-10-21 Exa publisher extraction: Reverse Grip Barbell Curl (EZ Bar) Instructions 1–4 and Tips; pronated grip, fixed upper arms, slow controlled movement. Forearms / brachialis with biceps support.',
    'ez_extension': '2026-10-21 full page read via Exa: How To Do 1–5, Tips From Expert, Equipment, People With Elbow Pain. Flat bench, angled grip, fixed upper arms, controlled lowering beyond forehead, breathing. No analgesic promise or copied dosage.',
    'stationary_bike': '2026-10-21 Exa publisher extraction: Check your form, Start small, Know when to back off; seat/reach, slight knee bend, easy low resistance and gradual duration, stop sharp pain. Not an individual arthritis prescription.',
    'talk_test': '2026-10-21 NHS page read: What counts as moderate aerobic activity; conversation possible, unlike vigorous exercise. Easy conversational pace here is an editorial lower-intensity choice, not an age or heart-rate prescription.',
}
CONDITIONS = ['no_jumps', 'quiet', 'no_kneeling', 'no_hand_support', 'no_floor', 'small_space']
SAFETY = ('Oddychaj swobodnie: wydech przy unoszeniu, wdech przy opuszczaniu; '
          'Przerwij przy bólu łokci, nadgarstków lub barków, drętwieniu albo zawrotach głowy; '
          'Zapisuj łączną masę gryfu i talerzy w kg, nie ciężar na rękę; '
          'Zabezpiecz talerze zaciskami, dobierz lekki ciężar do kontroli ruchu i zostaw około 3 powtórzeń w zapasie')


def entry(number, pl, en, primary, secondary, source, cues, errors, *, bench=False):
    return dict(number=number, pl=pl, en=en, primary=primary.split(), secondary=secondary.split(),
                equipment='Gryf łamany EZ' + (', Ławeczka' if bench else ''), source=source,
                cues=cues + '; ' + SAFETY, errors=errors,
                progression='Najpierw osiągnij 15 kontrolowanych powtórzeń bez bólu i z zapasem; potem dodaj najmniejszy dostępny ciężar i wróć do 10 powtórzeń',
                regression='Lżejszy gryf lub mniej talerzy i krótszy bezbolesny zakres; jeśli sam gryf jest za ciężki, wybierz lżejszy wariant z innym sprzętem',
                style=['strength'], kind='Siła', level='Początkujący',
                pattern='Prostowanie łokci' if bench else 'Zginanie łokci',
                prescription='2 x 10-15', tempo='Unoszenie 1-2 s, opuszczanie 2-3 s bez szarpania',
                positions=['bench' if bench else 'standing'], conditions=list(CONDITIONS),
                unilateral=False, tracking='reps')


ADDITIONS = [
    entry(409, 'Uginanie ramion z gryfem łamanym EZ stojąc', 'Standing EZ bar curl',
          'biceps', 'brachialis forearms', 'ez_curl',
          'Stań stabilnie, stopy na szerokość bioder, kolana miękkie; Chwyć ukośne odcinki gryfu symetrycznie podchwytem, dłonie ku górze, nadgarstki w linii przedramion; Utrzymuj łokcie blisko boków i tułów nieruchomo; Ugnij łokcie unosząc gryf bez wysuwania ramion; Opuść powoli do wygodnego wyprostu bez blokowania łokci',
          'Bujanie tułowiem i odchylanie pleców; Wysuwanie łokci; Załamywanie nadgarstków; Zrzucanie ciężaru'),
    entry(410, 'Uginanie ramion z gryfem łamanym EZ nachwytem stojąc', 'Standing reverse grip EZ bar curl',
          'forearms brachialis', 'biceps', 'ez_reverse_curl',
          'Stań stabilnie, stopy na szerokość bioder, tułów wyprostowany; Chwyć ukośne odcinki gryfu symetrycznie nachwytem, dłonie ku dołowi; Utrzymaj nadgarstki w linii przedramion i łokcie przy bokach; Ugnij łokcie bez wymachu i podnoszenia barków; Opuść gryf powoli, nie pozwalaj nadgarstkom opaść',
          'Podchwyt zamiast nachwytu; Kołysanie tułowiem; Opadanie nadgarstków; Ciężar wymuszający skrócenie ruchu'),
    entry(411, 'Prostowanie ramion z gryfem łamanym EZ w leżeniu na ławce płaskiej', 'Lying EZ bar triceps extension on flat bench',
          'triceps', '', 'ez_extension',
          'Zablokuj stabilną ławkę w ustawieniu płaskim i oprzyj stopy na podłodze; Chwyć wewnętrzne ukośne odcinki gryfu symetrycznie nachwytem z kciukiem wokół gryfu; Połóż się z podpartą głową, plecami i pośladkami, ustaw gryf nad górą klatki; Utrzymuj ramiona niemal nieruchomo i łokcie skierowane w górę bez rozpychania; Zginając łokcie opuść gryf kontrolowanie za linię czoła, bez kontaktu z głową; Wyprostuj łokcie bez gwałtownego blokowania, nie zmieniaj ruchu w wyciskanie; Użyj ciężaru, który samodzielnie bezpiecznie ustawisz i odłożysz, w razie trudności poproś o pomoc przy podaniu i odebraniu',
          'Opuszczanie gryfu na twarz; Rozchodzenie łokci; Ruch barkami zamiast łokci; Wyginanie pleców; Zbyt ciężki gryf bez bezpiecznego odłożenia', bench=True),
    dict(number=412, pl='Spokojna jazda na rowerze stacjonarnym', en='Easy stationary cycling',
         primary=['quadriceps', 'glutes'], secondary=['hamstrings', 'calves'],
         equipment='Rower stacjonarny', source='stationary_bike',
         cues='Sprawdź stabilność roweru i blokadę regulacji; Ustaw siodełko tak, aby kolano pozostało lekko ugięte przy najdalszym położeniu pedału, biodra nie kołysały się; Ustaw kierownicę w wygodnym zasięgu, rozluźnij barki i lekko oprzyj dłonie; Zacznij od kilku minut bardzo lekkiego pedałowania z małym oporem; Pedałuj płynnie w siadzie, kolana prowadź zgodnie z kierunkiem stóp; Dobierz tempo i opór tak, by swobodnie rozmawiać pełnymi zdaniami, bez zadyszki; Oddychaj swobodnie, zakończ kilkoma minutami coraz lżejszej jazdy i zatrzymaj pedały przed zejściem; Przerwij przy bólu kolan, bólu w klatce, zawrotach głowy lub nietypowej duszności',
         errors='Zbyt niskie siodełko; Blokowanie kolan lub kołysanie bioder; Wysoki opór i zadyszka zamiast spokojnej jazdy; Wstrzymywanie oddechu; Zsiadanie przy obracających się pedałach',
         progression='Najpierw stopniowo wydłużaj komfortową jazdę o kilka minut; dopiero później nieznacznie zwiększ opór, nadal zachowując swobodną rozmowę',
         regression='Krótsza jazda, mniejszy opór i spokojniejsze tempo; zrób przerwę przed pogorszeniem techniki',
         style=['conditioning'], kind='Cardio', level='Początkujący', pattern='Pedałowanie',
         prescription='1 x 10-20 min łącznie z łagodnym początkiem i zakończeniem',
         tempo='Płynnie, spokojne tempo rozmowy, bez sprintów', positions=['seated'],
         conditions=list(CONDITIONS), unilateral=False, tracking='time'),
]


def source_records():
    return {f'cw{a["number"]}': dict(source='ez_expansion_' + a['source'], movement=a['en']) for a in ADDITIONS}
