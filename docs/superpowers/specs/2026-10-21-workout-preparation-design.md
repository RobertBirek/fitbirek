# Dziś — przygotowanie treningu przed startem

## Uzgodniony cel

Z panelu Dziś użytkownik chce przygotować sprzęt, ustawić ławkę, ustalić ciężar
i ewentualnie zamienić ćwiczenie PRZED utworzeniem sesji. Modal nie jest kolejnym
ekranem aktywnego treningu. Użytkownik powierzył dobór układu wykonawcy i nie chce
makiety. Poprzednie wydanie1.21.0+37 jest już wdrożone; ta funkcja to nowy zakres.
Nie ma osobnej zgody na commit/push lub publikację tego zakresu.

Uzgodnienia:
- Punktem wyjścia jest ostatni rzeczywiście zapisany ciężar, nie rekord osobisty.
- Możliwa propozycja progresji na podstawie historii, zawsze przyjmowana jawnie.
- Ciężar można zmienić ręcznie przed startem, także bez przyjmowania sugestii.
- Po zamianie pytanie: Tylko ten trening / Ten trening i szablon.
- Sprzęt i talerze potwierdzone przez właściciela po odczycie14 zdjęć JPG.

## Sprzęt — potwierdzone dane

| Element | Dane |
|---|---|
| Gryf łamany |7kg |
| Uchwyty hantli |2 małe po2,25kg,2 duże po2,5kg; liczba widoczna na zdjęciu |
| Hantle stałe |para1,5kg i para2kg; NIE5kg (korekta właściciela) |
| Talerze5kg |4 czarne |
| Talerze2,5kg |4 czarne +4 chromowane |
| Talerze1,25kg |8 czarnych +2 chromowane |
| Talerze1kg |4 chromowane |
| Talerze0,5kg |4 chromowane |

Razem30 talerzy/58,5kg. Wszystkie talerze pasują do wszystkich uchwytów i gryfu.
Widoczne:drążek z pasami do unoszenia nóg, ławka skośna z wałkami, step, sandbag,
trzy gumy, skakanka, kółko do brzucha, poduszka równoważna, maty, roller oraz
prosty uchwyt do wyciągu. Sam uchwyt NIE dowodzi posiadania całego wyciągu.
Zdjęcia nie potwierdzają masy sandbaga, liczbowego oporu gum, kątów/udźwigu ławki,
maksymalnego obciążenia ani długości roboczej uchwytów; nie wymyślać tych danych.
Nie usuwać z istniejącego profilu sprzętu niewidocznego na tych zdjęciach.

Zdjęcia pozostają prywatnie /tmp/opencode/fit-equipment-photos; nie dodawać ich
do repo, publicznych assetów, backendu ani dokumentacji publicznej.

## Proponowany UX — decyzje wykonawcy

Duży modal/bottom sheet Przygotuj trening; na telefonie niemal pełny ekran,
na desktopie ograniczona szerokość. Istniejąca grafitowo-pomarańczowa stylistyka,
lokalne fonty/ilustracje, bez nowych zależności. Pionowy scroll, bez poziomego.

1. Nazwa, kolejność bloków, liczba ćwiczeń i szacowany czas (nie czas wykonania).
2. Przygotuj na początek: sprzęt pierwszego ćwiczenia, ciężar i konfiguracja.
   Dalej zbiorcza lista sprzętu oraz wymagane zmiany ustawień pomiędzy blokami.
3. Karty ćwiczeń: ilustracja, nazwa, serie/powtórzenia lub sekundy/rundy, przerwy,
   ostatni ciężar z datą i źródłem, wybrany cel oraz przycisk Zmień ćwiczenie.
4. Ustawienia ławki wyłącznie ze zweryfikowanego opisu/warunków ćwiczenia.
   Jeśli brak kąta, pokazać opis i konieczność sprawdzenia ustawienia; bez
   automatycznego dopisywania30/45 stopni lub zakładania ławki uniwersalnej.
5. Ciężar: ręczne pole oraz konfiguracja gryf/uchwyt + talerze na stronę.
   Hantle docelowo kg/szt., gryf całkowite kg. Nigdy nie mylić masy dwóch hantli
   z masą jednej. Puste pole nie oznacza0kg i nie kopiuje kg poprzedniego ruchu.
6. Sugestia progresji z krótkim powodem i dowodami z historii, osobny Przyjmij.
   Renderowanie/odświeżenie sugestii nie nadpisuje ręcznego szkicu.
7. Anuluj oraz końcowy Rozpocznij trening, z blokadą double tap i stanem zapisu.
   Zamknięcie przed startem nie zapisuje planu, sesji, szkicu, serii, PR ani outboxa.

Aktywny/persisted trening nadal prowadzi przez Kontynuuj; modal nie tworzy sesji
zastępczej. Zdarzenia zewnętrzne (np.karate) nie otrzymują fałszywej listy ćwiczeń.
Trening swobodny bez planu pokazuje ten fakt; nie generować planu automatycznie.

## Historia i progresja — bez automatycznych zaleceń medycznych

Historia:ostatnia seria ostatniego zakończonego, żywego treningu dokładnego
exerciseId/side/variantId; NULL/both/left/right rozdzielone. Nie używać PR,
wyników testów sprawnościowych, aktywnych lub usuniętych sesji/serii. Przy wielu
ciężarach w sesji nie wybierać maksymalnego ani wygodniejszego wyniku.

Dotychczasowy proposeFixedLoad i jego zachowanie w aktywnym treningu bez zmian.
Nowy helper przygotowania może używać jego konserwatywnej progresji powtórzeń.
Proponowana polityka nowej sugestii kg (decyzja wykonawcy do zatwierdzenia):
- Tylko reps, porównywalna jednostka i tożsamość, dwie ostatnie różne zakończone
  sesje na tym samym ciężarze, wszystkie wymagane serie na górnej granicy zakresu
  oraz każde RPE1..7. Brak RPE/serii, różne kg, czas/rundy → bez sugestii kg.
- Najmniejszy wykonalny wzrost ze sprzętu, nie większy niż10% bieżącej masy.
  To ostrożny limit funkcji, nie norma zdrowotna. Większa zmiana tylko ręczna.
- Cel powtórzeń po przyjęciu większego ciężaru wraca do dolnej granicy zakresu.
  Przyjęcie zmienia tylko przygotowywany trening, nie historię lub szablon.
- Sugestia nie może sama się zatwierdzić ani wymagać zwiększenia ciężaru.

**Wyjaśnienie właściciela:** nie wykonał jeszcze żadnych ćwiczeń. Pierwszy trening
jest podstawowym scenariuszem, nie błędem/brakiem danych do naprawy. Nie udawać
ostatnich wyników i nie wyliczać startowych kg z masy ciała, sprzętu lub PR.
Bez historii:jawny cel Z szablonu, jeśli istnieje, albo ręczne puste pole.
Progresja pojawi się dopiero po rzeczywiście zapisanych porównywalnych sesjach.
Od teraz UI jednoznacznie opisuje hantle jako kg/szt. z uchwytem i talerzami,
a gryf jako całość z masą7kg. Nie usuwać potencjalnych danych testowych lub
starszych rekordów na podstawie tej wypowiedzi; nie przepisywać żadnej historii.

## Konfiguracje talerzy

Czysty solver w całkowitych gramach; symetrycznie na obu stronach. Dla pary
hantli identyczna masa i wspólny zapas:4 takie same strony, nie dwa niezależne
obliczenia mogące zużyć te same talerze. Bez talerzy → masa uchwytu/gryfu.
Preferować mniej elementów i deterministyczny wybór; różne uchwyty są osobnymi
konfiguracjami. Przykład:mały uchwyt2,25 +2×2,5 =7,25kg/szt.

Pokazać brak dokładnej konfiguracji i alternatywy, bez cichego zaokrąglenia
wartości wpisanej przez użytkownika. Nie gwarantować fizycznego zmieszczenia
talerzy bez danych o długości uchwytu; jawnie Sprawdź miejsce i zaciski.
Konfiguracje różnych bloków są kolejne, nie obietnicą jednoczesnego złożenia
wszystkich hantli i gryfu. Oznaczyć potrzebę przełożenia talerzy.

## Zamiana i zapis

Zamienniki:aktualny katalog i shared filter engine, wymagany dostępny sprzęt,
ten sam tracking/sekcja oraz zgodny wzorzec ruchu lub główna grupa mięśniowa;
bez duplikatu ćwiczenia w planie i bez automatycznego luzowania filtrów.
Zamiennik dostaje własną historię/ciężar, nie kg usuniętego ćwiczenia. Przy braku
danych jawne puste pole. Lista sprzętu i ustawienia przeliczane po zmianie.

Dialog po wyborze:Tylko ten trening / Ten trening i szablon / Anuluj.
Decyzja pozostaje szkicem aż do Rozpocznij. Komunikat:Zmiana szablonu zostanie
zapisana przy rozpoczęciu treningu. Możliwy mix różnych decyzji dla bloków:
szablon otrzymuje TYLKO wyraźnie oznaczone zamiany, nie inne lokalne zmiany.
Ręczne kg i sugestie progresji domyślnie wyłącznie na tę sesję.

Start:ponowna weryfikacja konta/epoch, terminu, oryginalnego szablonu, katalogu
i braku aktywnej sesji. Konflikt w tle nie jest ignorowany i nie nadpisuje
nowego szablonu. Zapis zmiany szablonu i start dokładnie jednej sesji atomowo,
z zachowaniem dotychczasowego repo/outbox i bez zaliczenia terminu z samego startu.
Porażka transakcji nie może pozostawić aktywnej sesji RAM bez wiersza SQLite.

## Granice techniczne

Flutter3.35.4/Dart3.9.2. Reuse StructuredPlan v1/PlanPrescription.weightKg,
TemplateLease, PlannerRepository.updateTemplate, PlannerWorkflow oraz istniejący
notyfikator/recovery. Nie dodawać encji sync, migracji, backendu lub zależności,
jeżeli istniejący snapshot planu i lokalny draft wystarczają. Nie poszerzać wire
bez osobnego projektu kompatybilności. Brak PR/serii przy podglądzie lub starcie.

Pierwsza wersja prywatnej aplikacji korzysta z jawnej, testowalnej konfiguracji
potwierdzonego sprzętu właściciela; bez nowego magazynu/CRUD, zdjęć runtime,
automatycznych edycji profilu i zmian przypomnień. Nie wynajdywać masy sandbaga.
Ewentualna publikacja1.22.0+38 wymaga osobnego potwierdzenia po wykonaniu/testach.

## Rozstrzygnięcia po builder check (wybory wykonawcy)

- Zamiana zachowuje serie/powtórzenia, przerwy i sekcję slotu przy zgodnym
  tracking; nie generuje nowej dawki. Usuwa ciężar dawnego ćwiczenia. Obie
  wynikowe struktury muszą mieć unikalne exerciseId. Kandydat powodujący duplikat
  w sesji LUB docelowym szablonie jest niedostępny; zmiana scope waliduje całość.
- Pierwsza wersja nie dodaje edytora stron/wariantów w modal. Historia dotyczy
  bazowego wariantu i tej samej domyślnej strony co guided (unilateral both).
  Inne tożsamości nie dziedziczą przygotowanych kg. Cele przygotowania są seedami
  dokładnych kluczy istniejącego lokalnego draftu, nie globalną zmianą kg dla
  wszystkich wariantów. Jawna masa oryginalnego planu pozostaje osobno opisana
  jako Z szablonu, nie jako historia innej strony.
- Legacy plan bez structure zachowuje unguided start. Modal pokazuje listę i
  sprzęt oraz wyjaśnia brak celów; nie dopisuje fikcyjnych prescriptions. Edycja
  celów i zamian szablonu dotyczy struktury v1. Uszkodzona/future structure jest
  błędem, NIE legacy fallbackiem.
- Potwierdzony sprzęt to jawna konfiguracja obecnej prywatnej instalacji
  właściciela, bez nowej kolekcji i bez automatycznej edycji profilu. Zachować
  jednocześnie restrykcje profilu i plan.criteria. Testy podmieniają konfigurację;
  przyszłe prywatne konta znajomych poza zakresem.
- Przy hantlach wybór uchwytu/stałych oraz1 szt. albo para, domyślnie jawna para.
  Solver i sugestia używają tej samej quantity. Samo przełączenie uchwytu nie
  jest progresją; kg proponowane przy tym samym typie uchwytu.
- Brak historii + jawne weightKg oryginalnego bloku → cel Z szablonu, bez
  etykiety Ostatnio i bez progresji. Brak obu → puste pole. Zamiennik nie
  dziedziczy starej masy również ze źródłowego szablonu.
- Seedy ciężaru/powtórzeń zapisywane wraz z pierwszym lokalnym draftem dopiero
  przy udanym starcie. Nie ma obietnicy cloud sync niezapisanych pól; błąd flush
  jest jawny. Nie pozostawiać aktywnego RAM bez zatwierdzonej sesji SQLite.
