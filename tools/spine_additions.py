"""Reviewed second expansion, 2026-10-16. No runtime name-based classification.

Sources establish technique, not individualized medical suitability or dosage.
All Polish instructions and conservative starting doses are editorial choices.
"""
import copy
import hashlib
import json
from typing import Any

PREFIX_COUNT = 363
PREFIX_SHA256 = '8f5e78e88c53bad83f0fbb27cf6bc6beebcd47903da7b00c0fc485af7311b547'
METADATA_SHA256 = 'f544158ebd46bdd3e7df76ebea47b4b867520524b2147a5478275e43b633bcfd'
SPINE_STYLE = ('spine', 'Kręgosłup — ruch i stabilizacja', ['kręgosłup', 'kregoslup', 'spine'])

# Small, explicit selection: stability and spinal mobility, not all core work.
# AAOS: bridge, plank, bird dog; CUH/NHS: cat-cow, supported movement.
EXISTING_SPINE = {154, 169, 171, 179, 181, 250, 252, 266, 267, 268, 290, 291, 294}

SOURCES = {
    'aaos_spine': {
        'url': 'https://orthoinfo.aaos.org/en/recovery/spine-conditioning-program/',
        'verifiedSections': '5 Knee to Chest; 6 Bird Dog; 7 Plank; 8 Modified Side Plank; 9 Hip Bridge; 10 Abdominal Bracing. Read full text 2026-10-16; AAOS does not explicitly mention breathing in bracing, supplemented by CUH section 5. Do not adopt head rolls or forced end-range instructions.',
        'publisher': 'AAOS OrthoInfo', 'publicationVersion': 'Live page, no revision date displayed; reviewed Daniel K. Park / Thomas Ward Throckmorton',
    },
    'cuh_back': {
        'url': 'https://www.cuh.nhs.uk/patient-information/back-mobility-exercises/',
        'verifiedSections': '3 Knee rolls: bent knees together, upper trunk still; 5 Core muscle contraction: breathe normally, no arching; 7 Pelvic tilts: backward/forward pelvic rotation in supine. Also 6 Bridging. Read full text 2026-10-16.',
        'publisher': 'Cambridge University Hospitals NHS, Addenbrooke’s physiotherapy team',
        'publicationVersion': 'Approved 16 Jul 2024, version 4',
    },
    'nhs_inform_back': {
        'url': 'https://www.nhsinform.scot/illnesses-and-conditions/muscle-bone-and-joints/neck-and-back-problems-and-conditions/exercises-for-back-pain',
        'verifiedSections': 'Single knee hug: supine, other knee towards ceiling, hold a few seconds then release. Pelvic tilts and knee rolls; gradual starting volume 2–3 repetitions; stop for worsening symptoms or new pain. Read full text 2026-10-16.',
        'publisher': 'NHS inform / NHS 24', 'publicationVersion': 'Live page, no revision date in retrieved full text',
    },
    'leeds_open_book': {
        'url': 'https://flipbooks.leedsth.nhs.uk/LN005629.pdf',
        'verifiedSections': '1 Open book: side lying, arms together in front, top arm opens in arc, eyes follow, knees together on floor, slow return; 5 each side. Clinical leaflet context is not a diagnosis or an indication assigned to catalog users. Floor contact of opening hand is NOT required in our adaptation. Read full PDF 2026-10-16.',
        'publisher': 'Leeds Teaching Hospitals NHS Trust, Emma MacInnes',
        'publicationVersion': 'LN005629, first edition Ver 1.0, publication 08/2024, review 08/2027',
    },
    'peakrx_hip_hinge': {
        'url': 'https://www.peakrxtherapy.com/blog/hip-hinging-101',
        'verifiedSections': 'What is a hip hinge; Common faults; Ways to Train / Butt taps: a few inches from wall, soft knees, hips back to tap wall, hands in hip crease, progress by stepping slightly forward. Read full text 2026-10-16; do not reproduce protection or pain-treatment claims.',
        'publisher': 'Dr. Brooke Miller, physical therapist, PeakRx PT & Wellness',
        'publicationVersion': '10 Feb 2018, live article',
    },
    'cuh_thoracic': {
        'url': 'https://www.cuh.nhs.uk/patient-information/thoracic-spine-exercises/',
        'verifiedSections': '2 Seated extension above chair back; 4 Seated rotation; 5 Quadruped rotation; 6 Cat-cow. Read full text 2026-10-16. Chair extension excluded as too close to existing cw267 supported thoracic extension.',
        'publisher': 'Cambridge University Hospitals NHS, Addenbrooke’s physiotherapy team',
        'publicationVersion': '16 Jul 2024, version 4',
    },
}

STOP = 'Przerwij przy bólu, nasileniu objawów lub drętwieniu i skonsultuj dalszy ruch ze specjalistą'
FLOOR_CONDITIONS = ['no_jumps', 'quiet', 'no_kneeling', 'no_hand_support', 'small_space']


def movement(number, pl, en, primary, secondary, kind, pattern, prescription,
             tempo, cues, errors, progression, regression, source, tracking='reps',
             unilateral=False, standing=False) -> dict[str, Any]:
    return dict(number=number, pl=pl, en=en, primary=primary, secondary=secondary,
                kind=kind, pattern=pattern, prescription=prescription, tempo=tempo,
                cues=cues + '; ' + STOP, errors=errors, progression=progression,
                regression=regression, source=source, tracking=tracking,
                unilateral=unilateral, style=['mobility_recovery', 'spine'],
                equipment='Masa własna', level='Początkujący',
                conditions=(['no_jumps', 'quiet', 'no_kneeling', 'no_hand_support',
                             'no_floor', 'small_space'] if standing else list(FLOOR_CONDITIONS)),
                positions=['standing'] if standing else ['floor'])


ADDITIONS = [
    movement(364, 'Przetaczanie miednicy w leżeniu na plecach', 'Supine pelvic tilt',
             ['abs'], ['back'], 'Mobilność', 'Kontrola pochylenia miednicy',
             '1 x 3-5', 'Wolno, około 2 sek w każdą stronę',
             'Połóż się na plecach, ugnij kolana i oprzyj stopy o podłogę; '
             'Rozluźnij barki i połóż dłonie na miednicy; '
             'Łagodnie podwiń miednicę, zmniejszając szczelinę pod lędźwiami; '
             'Następnie pochyl miednicę w przeciwną stronę, tworząc tylko niewielką szczelinę; '
             'Pośladki pozostają na podłożu, oddychaj swobodnie; Pełne przetoczenie tam i z powrotem to jedno powtórzenie',
             'Unoszenie bioder jak w moście; Wypychanie brzucha i duży przeprost lędźwi; Zatrzymywanie oddechu',
             'Dodaj 1-2 powtórzenia, jeśli ruch pozostaje swobodny, bez zwiększania wygięcia',
             'Wykonuj bardzo mały ruch miednicy i wracaj do wygodnej pozycji', 'cuh_back'),
    movement(365, 'Łagodne napięcie brzucha w leżeniu z normalnym oddechem', 'Supine abdominal bracing',
             ['abs'], [], 'Izometria', 'Stabilizacja tułowia bez ruchu kończyn',
             '3 x 5 sek', 'Spokojny oddech przez całe utrzymanie, odpoczynek po każdym napięciu',
             'Połóż się na plecach z ugiętymi kolanami, stopami na podłodze i rękami przy tułowiu; '
             'Łagodnie napnij dolną część brzucha, jak przy odsuwaniu go od paska spodni; '
             'Nie unoś głowy ani barków, nie poruszaj nogami i nie wyginaj lędźwi; '
             'Utrzymuj lekkie napięcie przez 5 sek, swobodnie wdychając i wydychając powietrze; '
             'Rozluźnij brzuch całkowicie i odpocznij przed kolejnym napięciem',
             'Wstrzymywanie oddechu lub parcie; Maksymalne wciąganie brzucha; Unoszenie tułowia jak przy spięciu brzucha',
             'Wydłuż lekkie napięcie do 8-10 sek tylko przy swobodnym oddychaniu',
             'Skróć napięcie do 2-3 sek lub zmniejsz jego siłę', 'aaos_spine', tracking='time'),
    movement(366, 'Kołysanie ugiętych kolan w leżeniu na plecach', 'Supine bent-knee rolls',
             ['back'], ['abs', 'glutes'], 'Mobilność', 'Łagodna rotacja tułowia w leżeniu',
             '1 x 3 na stronę', 'Powolne opuszczenie i powrót, krótka pauza bez dociskania',
             'Połóż się na plecach z kolanami ugiętymi i złączonymi, stopy na podłodze; '
             'Oprzyj ramiona wygodnie obok tułowia, barki pozostają na podłożu; '
             'Przechyl oba kolana razem w wybraną stronę tylko w komfortowym zakresie; '
             'Pozwól stopom lekko przetoczyć się na krawędzie, bez unoszenia nóg w powietrze; '
             'Powoli wróć do środka, oddychając normalnie; Wyjście w bok i powrót to jedno powtórzenie na tę stronę',
             'Odrywanie barków; Dociskanie kolan do podłogi ręką; Szybkie przerzucanie nóg',
             'Dodaj 1-2 spokojne powtórzenia na stronę bez pogłębiania skrętu na siłę',
             'Zmniejsz wychylenie kolan i wracaj do środka bez pauzy', 'cuh_back', unilateral=True),
    movement(367, 'Otwarta książka — obrót klatki w leżeniu bokiem', 'Side-lying open book',
             ['back'], ['chest', 'abs', 'shoulders'], 'Mobilność', 'Rotacja piersiowa w leżeniu bokiem',
             '1 x 3-5 na stronę', 'Wolne otwarcie ramienia i kontrolowany powrót',
             'Połóż się na boku z biodrami i kolanami ugiętymi, kolana razem na podłodze; '
             'Wyciągnij obie ręce przed klatkę, dłoń na dłoni, głowę ułóż wygodnie; '
             'Zatocz górnym ramieniem łuk w górę i za siebie, obracając klatkę piersiową; '
             'Wzrok może podążać za dłonią, ale nie wymuszaj skrętu szyi; '
             'Kolana pozostają razem na podłożu, nie próbuj koniecznie dotknąć tylną dłonią podłogi; '
             'Wróć dłonią na dłoń i oddychaj swobodnie, następnie zmień bok',
             'Odrywanie górnego kolana i przetaczanie całego ciała; Dociskanie ramienia do podłogi; Wymuszanie zakresu barku lub szyi',
             'Zwiększ do 5 swobodnych powtórzeń na stronę, bez ciężaru i dociskania',
             'Otwórz ramię tylko częściowo i pozostaw wzrok przed sobą', 'leeds_open_book', unilateral=True),
    movement(368, 'Przyciąganie jednego kolana do klatki w leżeniu', 'Supine single knee to chest',
             ['back', 'quadratus_lumborum'], ['glutes'], 'Mobilność', 'Zgięcie biodra z łagodnym rozciąganiem pleców',
             '1 x 3 na stronę', 'Powolne przyciągnięcie, 2-3 sek pauzy i spokojne odłożenie',
             'Połóż się na plecach, ugnij oba kolana i oprzyj stopy na podłodze; '
             'Unieś jedno kolano ku klatce i obejmij nogę dłońmi, bez mocnego nacisku na kolano; '
             'Druga stopa zostaje na podłodze, jej kolano skierowane ku sufitowi; '
             'Przybliż udo tylko do łagodnego uczucia rozciągania, głowa i barki zostają na podłożu; '
             'Oddychaj normalnie przez krótką pauzę, powoli odstaw stopę; Przyciągnięcie i powrót to jedno powtórzenie na stronę',
             'Mocne szarpanie nogi; Unoszenie głowy do kolana; Prostowanie drugiej nogi mimo dyskomfortu lędźwi',
             'Dodaj 1-2 powtórzenia na stronę bez silniejszego ciągnięcia',
             'Obejmij udo od tyłu i przyciągnij je mniej, druga stopa nadal na podłodze', 'nhs_inform_back', unilateral=True),
    movement(369, 'Cofanie bioder do ściany bez obciążenia', 'Bodyweight wall hip hinge',
             ['glutes', 'hamstrings'], ['back', 'abs'], 'Rozgrzewka', 'Zawias biodrowy z kontrolą tułowia',
             '1 x 5', 'Około 3 sek cofania bioder, lekki dotyk ściany i spokojny powrót',
             'Stań tyłem kilka centymetrów od stabilnej ściany, stopy na szerokość bioder; '
             'Lekko ugnij kolana, połóż dłonie w zgięciach bioder; '
             'Cofaj biodra do lekkiego dotknięcia ściany pośladkami, pochylając tułów z bioder; '
             'Zachowaj wygodne ustawienie kręgosłupa i szyi, stopy cały czas na podłodze; '
             'Nie siadaj w przysiad ani nie zaokrąglaj pleców, wróć do stania przez wyprost bioder; '
             'Oddychaj swobodnie, bez dodawania ciężaru i bez wypychania lędźwi w przód',
             'Zaokrąglanie pleców zamiast ruchu bioder; Głęboki przysiad; Uderzanie pośladkami o ścianę lub odchylanie tułowia po powrocie',
             'Odsuń stopy o 2-3 cm od ściany tylko przy zachowaniu kontroli, nadal bez obciążenia',
             'Stań bliżej ściany i skróć cofnięcie bioder', 'peakrx_hip_hinge', standing=True),
]
EXPECTED_COUNT = PREFIX_COUNT + len(ADDITIONS)


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def validate_preservation(data, meta):
    if digest(data[:PREFIX_COUNT]) != PREFIX_SHA256:
        raise ValueError('Chronione rekordy cw001–cw363 zostały zmienione')
    old = copy.deepcopy(meta)
    old['styles'] = [r for r in old['styles'] if r['id'] not in {'spine', 'partner', 'pilates'}]
    old['muscles'] = [r for r in old['muscles'] if r['id'] != 'peroneals']
    old['exercises'] = {eid: row for eid, row in old['exercises'].items()
                        if int(eid[2:]) <= PREFIX_COUNT}
    for row in old['exercises'].values():
        row['styles'] = [s for s in row['styles'] if s != 'spine']
    if digest(old) != METADATA_SHA256:
        raise ValueError('Metadata cw001–cw363 changed beyond additive spine styles')
    i, label, aliases = SPINE_STYLE
    if [r for r in meta['styles'] if r['id'] == i] != [dict(id=i, label=label, aliases=aliases)]:
        raise ValueError('Spine style definition differs')
    expected_members = {f'cw{n:03d}' for n in EXISTING_SPINE} | set(source_exercises())
    if {eid for eid, row in meta['exercises'].items() if 'spine' in row['styles']} != expected_members:
        raise ValueError('Reviewed spine membership differs')
    for a in ADDITIONS:
        eid = f'cw{a["number"]}'
        expected = dict(styles=a['style'], primaryMuscles=a['primary'],
                        secondaryMuscles=a['secondary'], aliases=[a['en']],
                        tracking=a['tracking'], unilateral=a['unilateral'],
                        conditions=a['conditions'], positions=a['positions'])
        if meta['exercises'].get(eid) != expected:
            raise ValueError(f'{eid}: reviewed spine metadata differs')


def source_exercises():
    return {f'cw{a["number"]}': dict(source=a['source'], movement=a['en']) for a in ADDITIONS}
