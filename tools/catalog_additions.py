"""Reviewed expansion input. XLSX remains the source consumed by the exporter.

Descriptions are original Polish instructions, not translations of source prose.
Each tuple specifies movement-specific cues, errors and scaling, not a generic
exercise template. Source keys resolve through the versioned review ledger.
"""

SOURCES = {
    'dvrt10': ('https://ultimatesandbagtraining.com/10-ultimate-sandbag-exercises-that-are-musts/',
               'DVRT: Shoulder Squat; Clean and Press; MAX Lunge; Bent Rows; Shoveling; Around the Worlds; Plank Lateral Drag; Hip Bridges; Arc Press'),
    'dvrttop': ('https://ultimatesandbagtraining.com/top-10-ultimate-sandbag-training-exercises/',
                'DVRT: Front Hold Squats; High Pull; Front Hold Good Mornings; Bent-Over Row; Clean and Press; Lateral Bag Drag'),
    'dvrtpress': ('https://ultimatesandbagtraining.com/9-ultimate-sandbag-exercises-that-make-functional-strength-better/',
                  'DVRT: overhead press, clean once then press, row and deadlift hinge variations'),
    'dvrtdeadlift': ('https://ultimatesandbagtraining.com/the-ultimate-sandbag-deadlift-challenge/',
                     'DVRT: foundational handle-grip sandbag deadlift'),
    'wheel': ('https://theworkoutdigest.com/ab-wheel-exercises/',
              'Kneeling rollouts; kneeling V rollouts; standing progression. Excluded single-arm: source requires a central handle.'),
    'wheelplank': ('https://barbend.com/ab-wheel-workouts/',
                   'Ab Wheel Plank; kneeling rollout. Excluded all foot-strapped movements.'),
    'monkey': ('https://gmb.io/monkey/', 'Basic Monkey setup and variations'),
    'frogger': ('https://gmb.io/frogger/', 'Basic Frogger; Floating Table Top preparation'),
    'shrimp': ('https://gmb.io/shrimp-squats/', 'Shrimp squat vs pistol: knee/ankle control, rear leg position'),
    'cartwheel': ('https://gmb.io/cartwheel/', 'Three cartwheel progressions, hand/foot order and safe low entry'),
    'bridge': ('https://gmb.io/three-point-bridge/', 'Three Point Bridge; Supine Tabletop preparation'),
    'crow': ('https://gmb.io/crow-pose/', 'Crow/frog stand: bent-arm hand balance, scaling and wrist safety'),
    'compression': ('https://gmb.io/l-sit/', 'Build the Compression Strength: seated single-leg raises, other thigh hugged'),
    'seated': ('https://www.taichiexercises.co.uk/wp-content/uploads/2020/05/Exercises-Seated.pdf',
               'Arm: Picking Cherries; Trunk: Rowing a Boat, Turtle Swims in the Ocean; Leg: Kick with Sole'),
}

# id, names, anatomy, equipment, style/tracking/side and all workbook instructions.
ADDITIONS = []


def add(pl, en, primary, secondary, equipment, style, tracking, unilateral,
        source, cues, errors, progression, regression, level='Średni', kind='Siła'):
    number = 317 + len(ADDITIONS)
    ADDITIONS.append(dict(
        number=number, pl=pl, en=en, primary=primary.split(), secondary=secondary.split(),
        equipment=equipment, style=style.split(), tracking=tracking, unilateral=unilateral,
        source=source, cues=cues, errors=errors, progression=progression,
        regression=regression, level=level, kind=kind,
    ))


def sand(pl, en, p, s, source, cues, errors, prog, reg, side=False, level='Średni', tracking='reps'):
    add(pl, en, p, s, 'Sandbag', 'strength', tracking, side, source,
        cues + '; Sprawdź uchwyty i zamknięcia wkładów, nie rzucaj workiem; Dobierz ciężar do techniki — posiadane 20 kg nie jest obciążeniem obowiązkowym',
        errors, prog, reg, level)


sand('Martwy ciąg z sandbagiem za uchwyty', 'Sandbag deadlift', 'glutes hamstrings', 'back abs forearms', 'dvrtdeadlift',
     'Ustaw worek blisko goleni i chwyć symetryczne uchwyty; Cofnij biodra, napnij brzuch i wstań, prowadząc worek blisko nóg; Odstaw go przez zgięcie bioder bez garbienia',
     'Szarpanie z podłogi; Zaokrąglanie lędźwi; Odchylanie się w końcowej pozycji',
     'Zwiększ ciężar dopiero po serii równych powtórzeń', 'Zmniejsz wypełnienie i ćwicz krótsze serie', level='Początkujący')
sand('Przysiad z sandbagiem trzymanym z przodu', 'Sandbag front hold squat', 'quadriceps glutes', 'abs back biceps', 'dvrttop',
     'Oprzyj worek poziomo przed klatką na przedramionach; Zejdź między biodra, utrzymując całe stopy na podłożu; Wstań bez wypychania żeber do przodu',
     'Zapadanie kolan do środka; Opadanie łokci i tułowia; Odrywanie pięt',
     'Wydłuż pauzę na dole bez utraty ustawienia', 'Płytszy przysiad z lżejszym workiem')
sand('Przysiad z sandbagiem objętym pionowo', 'Sandbag bear hug squat', 'quadriceps glutes', 'abs back adductors', 'dvrttop',
     'Obejmij pionowo ustawiony worek, przyciągając go do tułowia; Usiądź między biodra i prowadź kolana w kierunku palców; Utrzymuj spokojny wydech podczas wstawania',
     'Worek odsunięty od ciała; Garbienie górnych pleców; Wstrzymywanie oddechu przez całą serię',
     'Stopniowo pogłębiaj przysiad z zachowaniem stabilnych stóp', 'Lżejszy worek i mniejsza głębokość')
sand('Przysiad z sandbagiem na jednym barku', 'Sandbag shoulder squat', 'quadriceps glutes', 'abs back shoulders', 'dvrt10',
     'Ułóż worek na jednym barku i asekuruj dłońmi; Wykonaj przysiad z tułowiem pośrodku między stopami; Po serii bezpiecznie odłóż worek i zmień bark',
     'Przechylanie tułowia pod ciężarem; Zsuwanie worka na szyję; Skręt kolan',
     'Dodaj pauzę na dole przy równym rozłożeniu nacisku stóp', 'Mniejszy ciężar lub przysiad z workiem z przodu', side=True)
sand('Skłon biodrowy z sandbagiem przed klatką', 'Sandbag front loaded good morning', 'hamstrings glutes', 'back abs', 'dvrttop',
     'Trzymaj worek przy klatce na przedramionach; Z miękkimi kolanami cofnij biodra, wydłużając tył ud; Wróć przez wyprost bioder bez odchylania lędźwi',
     'Zamiana ruchu w przysiad; Zaokrąglanie grzbietu; Odsuwanie worka od klatki',
     'Wydłuż fazę opuszczania do trzech sekund', 'Lżejszy worek i krótszy skłon')
sand('Wiosłowanie sandbagiem w opadzie', 'Sandbag bent-over row', 'back', 'biceps shoulders abs hamstrings forearms', 'dvrt10',
     'Chwyć parę uchwytów i cofnij biodra do stabilnego opadu; Przyciągnij worek ku górnej części brzucha, nie unosząc tułowia; Opuść go powoli, zachowując długą szyję',
     'Podrzucanie ciężaru tułowiem; Unoszenie barków do uszu; Zgarbione lędźwie',
     'Dodaj sekundę zatrzymania przy brzuchu', 'Zmniejsz ciężar i skróć serię')
sand('Dynamiczne podciągnięcie sandbaga do klatki', 'Sandbag high pull', 'glutes hamstrings', 'back shoulders abs forearms', 'dvrttop',
     'Rozpocznij z workiem przed goleniami w zgięciu bioder; Wyprostuj biodra dynamicznie i poprowadź łokcie w górę, nie ciągnąc samymi rękami; Kontroluj powrót worka blisko ciała',
     'Szarpnięcie lędźwiami; Ruch ramion przed wyprostem bioder; Worek daleko od ciała',
     'Przejdź do zarzutu po opanowaniu powtarzalnego toru', 'Lżejszy worek i spokojny martwy ciąg')
sand('Zarzut sandbaga na przedramiona', 'Sandbag clean to fists', 'glutes hamstrings', 'back biceps abs shoulders', 'dvrttop',
     'Chwyć równoległe uchwyty i ustaw worek przy goleniach; Nadaj mu pęd biodrami i szybko podprowadź łokcie pod worek; Przyjmij ciężar na przedramionach bez uderzenia w klatkę',
     'Ciągnięcie wyłącznie bicepsem; Uderzanie workiem o nadgarstki; Przeprost pleców przy chwycie',
     'Po stabilnym przyjęciu dodaj osobne wyciskanie', 'Ćwicz high pull z mniejszym wypełnieniem')
sand('Wyciskanie sandbaga nad głowę', 'Sandbag overhead press', 'shoulders triceps', 'abs back glutes', 'dvrtpress',
     'Zarzuć lekki worek raz i ustabilizuj go przed klatką; Wyciśnij pionowo bez wybicia z nóg i bez wypychania żeber; Opuść do pozycji wyjściowej, nie odginając nadgarstków',
     'Przeprost lędźwi; Nierówny chwyt; Opuszczanie worka na głowę',
     'Wydłuż kontrolowane opuszczanie', 'Zmniejsz wypełnienie lub ogranicz zakres do bezbolesnego')
sand('Zarzut i wyciskanie sandbaga', 'Sandbag clean and press', 'glutes hamstrings shoulders triceps', 'abs back quadriceps', 'dvrt10',
     'W każdym powtórzeniu rozpocznij workiem przy goleniach; Zarzuć z bioder, ustabilizuj tułów i dopiero wtedy wyciśnij; Opuść do klatki, następnie bezpiecznie na podłoże',
     'Wyciskanie przed ustabilizowaniem zarzutu; Wyginanie pleców; Niekontrolowany upadek worka',
     'Łącz powtórzenia bez utraty jakości przyjęcia', 'Trenuj oddzielnie lżejszy zarzut i wyciskanie')
sand('Zakrok z przeniesieniem sandbaga przy przedniej nodze', 'Sandbag MAX lunge', 'quadriceps glutes', 'abs hamstrings back', 'dvrt10',
     'Trzymaj worek za uchwyty przed biodrami; Cofnij jedną nogę, prowadząc worek na zewnątrz kolana nogi przedniej; Wróć naciskiem przedniej stopy, kontrolując obrót tułowia',
     'Skręcanie obciążonego kolana; Zbyt obszerny zamach; Utrata równowagi przy powrocie',
     'Łącz kolejne powtórzenia płynnie, nie zwiększając zamachu', 'Zakrok bez rotacji z lżejszym workiem', side=True)
sand('Przenoszenie sandbaga ruchem szuflowania', 'Sandbag shoveling', 'glutes abs', 'hamstrings back shoulders forearms', 'dvrt10',
     'Trzymaj worek za uchwyty przed sobą i obróć stopy wraz z biodrami w bok; Cofnij biodro, prowadząc worek przy zewnętrznej stronie kolana; Wyprostuj biodro i przenieś ciężar ku drugiej stronie bez skręcania samych lędźwi',
     'Stopy przyklejone podczas obrotu; Skręt tylko w pasie; Utrata kontroli hamowania',
     'Zwiększ płynność przejścia między stronami', 'Lżejszy worek i mały, powolny łuk', side=True)
sand('Obwodzenie sandbaga wokół tułowia w klęku', 'Sandbag around the world', 'abs', 'shoulders back forearms', 'dvrt10',
     'Uklęknij wysoko, napinając lekko pośladki; Przeprowadź lekki worek wokół górnej części tułowia jak przy zakładaniu kurtki; Utrzymuj miednicę nad kolanami i wróć tą samą kontrolowaną drogą',
     'Siadanie na piętach; Przeprost lędźwi; Zbyt ciężki worek przy głowie',
     'Wydłuż czas płynnego ruchu bez zwiększania ciężaru', 'Mały łuk z bardzo lekkim workiem')
sand('Przeciąganie sandbaga pod tułowiem w desce', 'Sandbag plank lateral drag', 'abs', 'shoulders back glutes forearms', 'dvrttop',
     'Ustaw szeroko stopy w podporze, a lekki worek obok dłoni; Sięgnij przeciwną ręką po uchwyt i wolno przeciągnij worek pod klatką; Utrzymuj biodra równolegle do podłogi, potem zmień rękę',
     'Obracanie miednicy; Zadzieranie bioder; Szarpanie ciężaru',
     'Zwęż rozstaw stóp dopiero przy pełnej kontroli', 'Oprzyj kolana i mocno zmniejsz wypełnienie', side=True)
sand('Most biodrowy z napięciem sandbaga nad klatką', 'Sandbag tension hip bridge', 'glutes hamstrings', 'abs back shoulders', 'dvrt10',
     'Połóż się, ustaw stopy blisko pionu pod kolanami i chwyć zewnętrzne uchwyty lekkiego worka; Utrzymuj worek nad dolną klatką, delikatnie rozciągając uchwyty na boki; Unieś biodra naciskiem stóp, nie przenosząc worka na biodra',
     'Przeprost w lędźwiach; Luźny chwyt nad klatką; Rozjeżdżanie kolan',
     'Dodaj pauzę u góry przy stałym napięciu uchwytów', 'Lżejszy worek i niższe uniesienie bioder')
sand('Wyciskanie sandbaga łukiem w półklęku', 'Sandbag half-kneeling arc press', 'shoulders triceps', 'abs back glutes', 'dvrt10',
     'Przyjmij stabilny półklęk i ułóż lekki worek przy jednym barku; Oburącz wyciśnij go łukiem ponad głową i powoli opuść ku drugiemu barkowi; Oprzyj ciężar na nogach, nie pochylając tułowia na boki',
     'Zbyt niski łuk nad głową; Kołysanie miednicą; Za duży ciężar',
     'Wydłuż opuszczanie po drugiej stronie', 'Bardzo lekki worek i stabilny klęk obunóż', side=True)

add('Przetaczanie kółka w przód z kolan', 'Kneeling ab wheel rollout', 'abs', 'back shoulders glutes',
    'Kółko do brzucha', 'strength calisthenics', 'reps', False, 'wheel',
    'Oprzyj kolana na macie i chwyć oba uchwyty; Podwiń lekko miednicę i przetaczaj kółko po prostej tylko tak daleko, jak utrzymujesz napięty brzuch; Wróć bez siadania biodrami na pięty, kółko nie pomaga w powrocie',
    'Opadanie lędźwi; Wyjazd poza kontrolowany zakres; Szarpanie ramionami',
    'Najpierw wydłużaj zakres, rollout ze stania dopiero jako zaawansowany cel po pełnej kontroli z kolan',
    'Krótki zakres ograniczony ścianą, bez uderzania kółkiem', kind='Siła')
add('Przetaczanie kółka po skosie z kolan', 'Kneeling ab wheel V rollout', 'abs', 'back shoulders glutes',
    'Kółko do brzucha', 'strength calisthenics', 'reps', True, 'wheel',
    'Z klęku skieruj kółko lekko po skosie w lewo, trzymając oba uchwyty; Utrzymuj długi tułów bez zapadania lędźwi; Wróć do środka i wykonaj osobne powtórzenie w prawo, nie próbuj ostro skręcać podwójnej rolki pod obciążeniem',
    'Skręt samych lędźwi; Nagła zmiana kierunku w końcu ruchu; Zbyt daleki wyjazd',
    'Stopniowo wydłuż tor po skosie bez pogłębiania skrętu', 'Bardzo krótki skos lub rollout po prostej', level='Zaawansowany')
add('Deska z dłońmi na kółku', 'Ab wheel plank', 'abs', 'shoulders chest glutes',
    'Kółko do brzucha', 'strength calisthenics', 'time', False, 'wheelplank',
    'Chwyć oba uchwyty i ustaw barki nad osią kółka; Wyprostuj nogi do podporu na palcach, napnij brzuch i pośladki; Utrzymuj rolkę nieruchomo i oddychaj, nie odkładaj stóp na kółko',
    'Odjeżdżanie rolki; Zapadanie bioder; Wstrzymanie oddechu',
    'Wydłuż utrzymanie przy niezmienionym ustawieniu', 'Podeprzyj kolana na macie', kind='Izometria')


def yoga(pl, en, slug, p, s, cues, errors, prog, reg, side=True, level='Średni'):
    key = 'yj-' + slug
    SOURCES[key] = ('https://www.yogajournal.com/poses/' + slug + '/',
                    'Yoga Journal: ' + en + ' — setup, variations, beginner tips')
    add(pl, en, p, s, 'Masa własna', 'yoga mobility_recovery', 'time', side, key,
        cues + '; Oddychaj swobodnie, wyjdź z pozycji przy bólu lub zawrotach głowy',
        errors, prog, reg, level, 'Izometria')


yoga('Wojownik I', 'Warrior I — Virabhadrasana I', 'warrior-i-pose', 'quadriceps glutes', 'calves hip_flexors abs shoulders back',
     'Ustaw jedną nogę z przodu, a tylną stopę lekko skośnie; Zegnij przednie kolano w kierunku palców i unieś ramiona; Wydłuż tułów bez wymuszania ustawienia bioder',
     'Kolano zapadające do środka; Przeprost lędźwi; Zbyt wąskie ustawienie stóp', 'Wydłuż utrzymanie bez utraty oddechu', 'Skróć wykrok i trzymaj dłonie na biodrach')
yoga('Wojownik II', 'Warrior II — Virabhadrasana II', 'warrior-ii-pose', 'quadriceps glutes adductors', 'abs shoulders calves',
     'Stań w rozkroku i skieruj przednią stopę na zewnątrz; Ugnij jej kolano, utrzymując tułów pionowo; Wyciągnij ramiona w przeciwnych kierunkach i spójrz nad przednią dłonią',
     'Opieranie tułowia na przedniej nodze; Zapadanie kolana; Unoszenie barków', 'Nieco pogłębiaj ugięcie przy stabilnych stopach', 'Mniejsze ugięcie i dłonie na biodrach')
yoga('Wojownik III', 'Warrior III — Virabhadrasana III', 'warrior-iii-pose', 'glutes hamstrings quadriceps', 'abs back shoulders calves',
     'Przenieś ciężar na jedną stopę i pochyl długi tułów; Wyciągnij drugą nogę w tył, utrzymując oba biodra skierowane ku podłodze; Sięgnij ramionami przed siebie bez przeprostu kolana podporowego',
     'Otwieranie miednicy w bok; Zapadanie lędźwi; Blokowanie kolana', 'Wydłuż utrzymanie w poziomie', 'Oprzyj dłonie o ścianę i unieś nogę niżej')
yoga('Pozycja trójkąta', 'Extended Triangle — Utthita Trikonasana', 'extended-triangle-pose', 'hamstrings adductors', 'abs back shoulders quadriceps',
     'W szerokim rozkroku skieruj jedną stopę na zewnątrz; Wydłuż tułów nad tą nogą i oprzyj dłoń na goleni, nie na kolanie; Otwórz klatkę i unieś drugą rękę bez skręcania szyi na siłę',
     'Zapadanie dolnego boku tułowia; Nacisk na kolano; Dążenie dłonią do podłogi kosztem pleców', 'Zmniejsz podparcie dłonią przy zachowaniu długości boków', 'Dłoń wyżej na goleni i wzrok w dół')
yoga('Pozycja rozciągniętego kąta bocznego', 'Extended Side Angle — Utthita Parsvakonasana', 'extended-side-angle-pose', 'quadriceps glutes adductors', 'abs shoulders back',
     'Z szerokiego rozkroku zegnij przednie kolano i oprzyj przedramię na udzie; Wydłuż drugi bok od tylnej pięty do ręki sięgającej nad uchem; Otwórz klatkę bez naciskania całym ciężarem na udo',
     'Zapadanie kolana; Garbienie klatki; Zawieszanie ciężaru na przedramieniu', 'Sięgnij dolną dłonią niżej bez utraty osi kolana', 'Mniejsze ugięcie nogi i górna dłoń na biodrze')
yoga('Pozycja półksiężyca w staniu', 'Half Moon — Ardha Chandrasana', 'half-moon-pose', 'glutes quadriceps', 'hamstrings abs shoulders calves',
     'Z przeniesienia ciężaru na jedną nogę ustaw dłoń przed stopą; Unieś drugą nogę do tyłu i otwórz miednicę w bok; Wydłuż tułów i unieś wolną rękę, stabilizując kolano podporowe',
     'Blokowanie kolana; Opadanie tułowia; Wymuszanie spojrzenia w górę', 'Stopniowo odciążaj podpierającą dłoń', 'Oprzyj plecy i uniesioną piętę o ścianę')
yoga('Pozycja drzewa', 'Tree — Vrksasana', 'tree-pose', 'glutes quadriceps calves', 'abs adductors',
     'Stań na jednej nodze i przyłóż drugą stopę do łydki lub uda, omijając kolano; Utrzymaj miednicę przodem i spójrz na nieruchomy punkt; Złącz dłonie przed klatką bez wypychania biodra w bok',
     'Nacisk stopy na staw kolanowy; Skręt miednicy; Przeprost kolana podporowego', 'Unieś ramiona przy zachowaniu równowagi', 'Palce uniesionej nogi pozostaw na podłodze', level='Początkujący')
yoga('Pozycja orła w staniu', 'Eagle — Garudasana', 'eagle-pose', 'quadriceps glutes', 'shoulders back abs calves',
     'Lekko ugnij nogę podporową i skrzyżuj nad nią drugie udo; Skrzyżuj ramiona przed klatką i unieś łokcie w bezbolesnym zakresie; Utrzymuj tułów pionowo, nie wymuszając owinięcia stopy',
     'Skręcanie bolącego kolana; Zapadanie klatki; Wymuszanie splotu dłoni', 'Stopniowo odciąż stopę pomocniczą', 'Oprzyj palce wolnej nogi o podłoże i obejmij ramiona dłońmi')
yoga('Pozycja krzesła bez podparcia', 'Chair — Utkatasana', 'chair-pose', 'quadriceps glutes', 'abs shoulders back calves',
     'Stań ze stopami razem lub na szerokość bioder; Cofnij biodra i ugnij kolana jak do siedzenia, nie używając krzesła; Unieś ramiona tylko na tyle, by zachować spokojne ustawienie żeber',
     'Przeprost pleców przy unoszeniu rąk; Odrywanie pięt; Zapadanie kolan', 'Stopniowo wydłuż utrzymanie', 'Płytsze ugięcie z dłońmi na biodrach', side=False)
yoga('Pozycja wielbłąda', 'Camel — Ustrasana', 'camel-pose', 'back glutes', 'hip_flexors quadriceps chest shoulders abs',
     'Uklęknij z biodrami nad kolanami i podeprzyj dłońmi tył miednicy; Unieś mostek, a następnie delikatnie otwórz górę tułowia w tył; Do pięt sięgaj dopiero bez ucisku w lędźwiach i szyi',
     'Zapadanie lędźwi; Odrzucanie głowy; Cofanie bioder za kolana', 'Sięgaj do pięt dopiero po opanowaniu podpartej wersji', 'Dłonie pozostają na miednicy, minimalne odchylenie', side=False)
yoga('Pozycja łuku', 'Bow — Dhanurasana', 'bow-pose', 'back glutes hamstrings', 'quadriceps hip_flexors chest shoulders',
     'Leżąc na brzuchu, ugnij kolana i chwyć kostki obiema dłońmi; Naciśnij goleniami w tył, unosząc klatkę i ewentualnie uda; Zachowaj oddech i szyję jako przedłużenie pleców',
     'Rozjeżdżanie kolan; Ciągnięcie stóp samymi rękami; Bolesny ucisk lędźwi', 'Wydłuż łagodne utrzymanie, nie zwiększając wygięcia na siłę', 'Mniejsze uniesienie, a przy bólu pomiń pozycję', side=False)
yoga('Pozycja łodzi w siadzie', 'Boat — Paripurna Navasana', 'boat-pose', 'abs hip_flexors', 'quadriceps back',
     'Usiądź na guzach kulszowych i unieś mostek; Odchyl długi tułów, po czym unieś stopy bez opadania na kość krzyżową; Utrzymaj równowagę z rękami przed sobą i stopniowo prostuj kolana',
     'Zaokrąglanie lędźwi; Wysuwanie brody; Prostowanie nóg kosztem pleców', 'Stopniowo wyprostuj obie nogi', 'Ugnij kolana i przytrzymaj uda', side=False)
yoga('Skręt mędrca w siadzie na podłodze', 'Half Lord of the Fishes — Ardha Matsyendrasana', 'half-lord-of-the-fishes-pose', 'back abs', 'glutes shoulders',
     'Usiądź i przełóż stopę jednej nogi za przeciwne kolano; Wydłuż kręgosłup na wdechu i łagodnie obróć tułów ku uniesionemu kolanu; Dłoń za plecami tylko podpiera, nie wymusza skrętu',
     'Szarpanie łokciem o kolano; Zapadanie pleców; Skręt szyją zamiast tułowiem', 'Wydłuż utrzymanie przy równych guzach kulszowych', 'Pozostaw dolną nogę prostą i obejmij kolano zamiast zapierać łokieć')
yoga('Pozycja bramy w klęku', 'Gate — Parighasana', 'gate-pose', 'abs adductors', 'back shoulders hamstrings',
     'Z klęku wyprostuj jedną nogę w bok, pozostawiając drugie biodro nad kolanem; Oprzyj dłoń na wyprostowanej nodze i wydłuż przeciwną rękę nad głową; Wykonaj łagodny skłon boczny bez obracania klatki ku podłodze',
     'Zgniatanie dolnego boku; Opieranie dłoni na kolanie; Ból kolana klęczącego', 'Wydłuż sięganie ręką bez pogłębiania skłonu na siłę', 'Mniejszy skłon i dłoń wyżej na udzie')
yoga('Skłon w przód w szerokim rozkroku', 'Wide-Legged Forward Bend — Prasarita Padottanasana', 'wide-legged-forward-bend', 'hamstrings adductors', 'calves back abs',
     'Stań w stabilnym rozkroku i połóż dłonie na biodrach; Pochyl się z bioder, wydłużając plecy i podpierając dłonie na podłodze tylko jeśli sięgasz swobodnie; Wyjdź powoli, bez obciążania głowy',
     'Przeprost kolan; Dociskanie głowy do podłoża; Zbyt szybkie wstawanie', 'Stopniowo pogłębiaj skłon przy długich plecach', 'Ugnij kolana i zatrzymaj skłon wyżej z dłońmi na udach', side=False)
yoga('Pozycja szczęśliwego dziecka', 'Happy Baby — Ananda Balasana', 'happy-baby-pose', 'adductors glutes', 'hamstrings back',
     'Połóż się na plecach i przyciągnij kolana szerzej niż tułów; Chwyć zewnętrzne krawędzie stóp lub łydki, kierując podeszwy ku górze; Pozostaw głowę i kość krzyżową na podłożu, nie ciągnąc nóg na siłę',
     'Odrywanie głowy; Szarpanie stóp; Ból pachwin', 'Wydłuż spokojne utrzymanie bez mocniejszego ciągnięcia', 'Chwyć uda zamiast stóp', side=False, level='Początkujący')


def cal(pl, en, p, s, source, cues, errors, prog, reg, tracking='reps', side=False, kind='Siła'):
    add(pl, en, p, s, 'Masa własna', 'calisthenics', tracking, side, source,
        cues + '; Przy bólu nadgarstków lub innych stawów przerwij próbę',
        errors, prog, reg, 'Średni', kind)


cal('Przemieszczanie bokiem w przysiadzie na rękach', 'GMB Monkey', 'shoulders abs', 'glutes quadriceps adductors back', 'monkey',
    'Z przysiadu postaw obie dłonie z jednej strony stóp; Przenieś ciężar na ręce i przenieś stopy bokiem za dłońmi; Pozostań blisko podłoża i ćwicz oba kierunki osobno',
    'Wyrzucanie nóg daleko za siebie; Upadanie na dłonie; Zbyt głęboki bolesny przysiad', 'Wydłuż odcinek ruchu bocznego', 'Płytszy przysiad i małe przestawienie stóp', tracking='rounds', side=True)
cal('Przemieszczanie żabki z podparciem rąk', 'GMB Frogger', 'shoulders abs', 'glutes quadriceps back calves', 'frogger',
    'Z przysiadu sięgnij dłońmi przed siebie; Przenieś ciężar na ręce i unieś biodra, po czym dostaw stopy ku dłoniom; Wyląduj miękko w przysiadzie, nie wykonując wyskoku pionowego',
    'Odbijanie wyłącznie z nóg; Twarde lądowanie; Przeciążenie nadgarstków', 'Wydłuż płynny odcinek przy zachowaniu miękkich lądowań', 'Mały ruch z płytszego przysiadu', tracking='rounds')
cal('Przysiad krewetki z chwytem tylnej stopy', 'Shrimp squat', 'quadriceps glutes', 'abs calves', 'shrimp',
    'Stań na jednej nodze i chwyć stopę drugiej za sobą; Uginaj nogę podporową, prowadząc tylne kolano ku podłodze; Wstań naciskiem całej przedniej stopy bez puszczania tylnej stopy',
    'Opadanie na tylne kolano; Zapadanie kolana podporowego; Odrywanie pięty', 'Stopniowo obniżaj tylne kolano przy zachowaniu kontroli', 'Płytsze zejście i lekki kontakt wolnej dłoni ze ścianą', side=True)
cal('Przerzut bokiem na obie ręce', 'Cartwheel', 'shoulders triceps', 'abs glutes adductors forearms', 'cartwheel',
    'Zapewnij wolny, nieślizgający odcinek podłoża i rozpocznij z wykroku; Postaw kolejno dłoń po stronie nogi prowadzącej i drugą dłoń, przenosząc nogi bokiem; Wyląduj kolejno stopami, zaczynając od niskiej wersji bez pionu',
    'Rzut ciała bez kontroli; Krzyżowanie nóg przy lądowaniu; Próba w ciasnym otoczeniu', 'Stopniowo prostuj nogi i zbliżaj tor do jednej linii', 'Niskie przejście po łuku, bez unoszenia bioder nad głowę', side=True)
cal('Most trójpunktowy z sięganiem', 'Three-point bridge', 'glutes back shoulders', 'abs hamstrings chest', 'bridge',
    'Z wygodnego przysiadu oprzyj jedną dłoń za biodrem; Naciśnij piętami i unieś biodra, stabilizując bark ręki podporowej; Sięgnij drugą ręką w tył z łagodnym otwarciem klatki, potem wróć',
    'Zapadanie barku podporowego; Skręt wyłącznie w lędźwiach; Ruch przez ból', 'Wydłuż sięganie przy stabilnej dłoni', 'Podpór na dwóch dłoniach i niższe biodra', side=True)
cal('Podpór żaby na ugiętych ramionach', 'Crow / frog stand', 'shoulders abs', 'triceps forearms', 'crow',
    'Z przysiadu oprzyj dłonie na szerokość barków i ugnij łokcie; Oprzyj kolana na górze ramion, powoli przenosząc ciężar na dłonie; Unieś stopy tylko przy kontroli, patrząc nieco przed dłonie i zostawiając bezpieczne miejsce przed głową',
    'Wskakiwanie na dłonie; Wstrzymanie oddechu; Zapadanie nadgarstków', 'Wydłuż krótkie udane utrzymania', 'Palce stóp pozostają na podłodze, bez obciążania głowy', tracking='time', kind='Izometria')
cal('Unoszenie prostej nogi w siadzie z kompresją', 'Seated single-leg compression raise', 'hip_flexors abs', 'quadriceps', 'compression',
    'Usiądź z jedną nogą prostą, a drugie udo przyciągnij rękami do tułowia; Bez odchylania pleców unieś piętę prostej nogi kilka centymetrów; Opuść kontrolowanie i wykonaj osobną serię na drugą stronę',
    'Odchylanie tułowia; Odbijanie pięty; Zginanie unoszonego kolana', 'Wydłuż zatrzymanie nogi nad podłogą', 'Mniejsza wysokość unoszenia i krótsza seria', side=True)
cal('Utrzymanie podporu tyłem z ugiętymi nogami', 'Supine tabletop hold', 'glutes shoulders hamstrings', 'abs triceps back', 'bridge',
    'Usiądź z ugiętymi nogami i oprzyj dłonie za biodrami; Naciśnij stopami oraz dłońmi i unieś biodra do wygodnej wysokości; Utrzymuj otwartą klatkę bez marszu, z szyją w przedłużeniu tułowia',
    'Zapadanie barków; Odrzucanie głowy; Zbyt duży przeprost lędźwi', 'Wydłuż stabilne utrzymanie', 'Niższe biodra i krótsze utrzymanie', tracking='time', kind='Izometria')


def tai(pl, en, p, s, cues, errors, prog, reg, side=False):
    add('Tai chi — ' + pl + ' w siadzie', en + ' (seated)', p, s, 'Krzesło',
        'tai_chi mobility_recovery', 'reps', side, 'seated',
        'Usiądź na stabilnym krześle bez kółek, stopy oprzyj na podłodze; ' + cues +
        '; Oddychaj naturalnie i wykonuj ruch powoli, bez bólu ani naprężania',
        errors, prog, reg, 'Początkujący', 'Regeneracja')


tai('zbieranie wiśni', 'Picking Cherries', 'shoulders', 'back abs',
    'Sięgaj jedną dłonią po wyobrażoną wiśnię nad głową, potem przed sobą i w bok; Wracaj dłonią bez szarpania i zmieniaj rękę, nie odrywając pośladków od siedziska',
    'Unoszenie barku do ucha; Przechylanie się poza stabilną podstawę',
    'Płynnie łącz kierunki sięgania w bezbolesnym zakresie', 'Sięgaj niżej i bliżej tułowia', side=True)
tai('wiosłowanie łodzią', 'Rowing a Boat', 'back abs', 'shoulders',
    'Łagodnie przenoś tułów w przód i w tył z bioder; Dodaj oburącz krążenie ramion jak przy prowadzeniu wioseł po bokach łodzi, utrzymując stopy nieruchomo',
    'Gwałtowne bujanie; Zaokrąglanie samych lędźwi; Utrata kontaktu stóp z podłożem',
    'Łącz ruch ramion i tułowia coraz płynniej', 'Małe wychylenia z dłońmi bliżej ud')
tai('żółw pływający w oceanie', 'Turtle Swims in the Ocean', 'shoulders back', 'abs chest',
    'Przy łagodnym pochyleniu wykonaj ramionami ruch podobny do pływania żabką; Przy powrocie prowadź ramiona szerokim łukiem jak w stylu motylkowym, bez odrzucania pleców; Zmień kierunek krążenia w kolejnej krótkiej serii',
    'Forsowanie barków za plecy; Szarpanie tułowiem; Zatrzymywanie oddechu',
    'Łącz oba kierunki przy jednakowo spokojnym tempie', 'Małe łuki ramion bez wychylania tułowia')
tai('otwieranie drzwi podeszwą', 'Kick with Sole', 'quadriceps', 'hip_flexors abs tibialis_anterior',
    'Powoli wyprostuj jedną nogę przed sobą; Skieruj podeszwę w przód jak przy łagodnym otwieraniu drzwi piętą, nie kopiąc gwałtownie; Cofnij stopę na podłogę i zmień nogę',
    'Gwałtowny wyprost kolana; Odchylanie pleców; Unoszenie całego uda wysoko',
    'Wydłuż spokojny wyprost bez blokowania kolana', 'Prostuj kolano tylko częściowo, pięta blisko podłogi', side=True)
