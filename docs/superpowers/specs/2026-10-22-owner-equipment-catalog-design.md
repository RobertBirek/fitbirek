# Katalog ćwiczeń dla potwierdzonego sprzętu właściciela

## Zgoda i granice

Użytkownik zatwierdził wykonanie po omówieniu sprzętu, stepu, wariantów pompek
i ławki ujemnej. Implementacja lokalna; nowy katalog NIE jest częścią wydania
1.22.0+38. Jego commit/push/deploy wymaga osobnej decyzji. Bez zapisów do profilu
produkcyjnego, zmian narzędzi Flutter3.35.4/Dart3.9.2, migracji i nowych encji sync.

Potwierdzenia: małe uchwyty2,25kg, duże2,5kg, EZ7kg; pary hantli1,5/2kg,
30 talerzy/58,5kg bez zmian. Sandbag regulowany, ale operacyjnie stale20kg.
Step regulowany podstawą, deklarowane150kg; wysokość nieznana. Niskie10–15cm
to orientacyjny opis, nie pomiar. Ławka do brzuszków ze skosem ujemnym i blokadą
nóg; właściciel deklaruje przydatność pod hantle, nośność niezweryfikowana.
Uchwyt+linka+talerz to wrist roller, nie wyciąg. Pasy są na nogi do zwisu
odwróconego, NIE TRX ani pasy do podpierania ramion.

## Dane i nowe wpisy

Chroniony surowy prefiks412 zachowany bez zmian i bez zmiany istniejących ID.
Nowe12 ID cw413–cw424:
1. Wejście bokiem na step.
2. Kontrolowane zejście ze stepu.
3. Pompki z dłońmi na stepie.
4. Spięcia brzucha na ławce głową w dół.
5. Pełne brzuszki na ławce głową w dół.
6. Wyciskanie hantli na ławce głową w dół.
7. Stanie obunóż na poduszce równoważnej.
8. Stanie jednonóż na poduszce równoważnej.
9. Rolowanie łydki.
10. Rolowanie przedniej części uda.
11. Rolowanie pośladka.
12. Chód z sandbagiem objętym przed tułowiem.

Nie dublować forward step-up, knee-drive, calf raise, wrist rollera, pompek
z podniesionymi stopami i wyprostu piersiowego. Wersjonowane jawne korekty
cw009/cw123/cw135/cw136/cw165/cw267 zachowują ID, historię, ulubione i outbox.
Korekta cw123 usuwa wymaganie hantli/pary i opisuje pełny cykl góra–dół,
kg oznacza wyłącznie zawieszony ciężar, nie masę uchwytu. cw009 dopuszcza step
lub stabilne krzesło zamiast ławki i nie wymusza wysokości30–50cm.

Nowe kategorie: Step, Ławka do brzuszków, Ławka ujemna do wyciskania,
Wrist roller, Poduszka równoważna, Roller, Mata, Pasy do zwisu za nogi.
Ogólne legacy Ławeczka pozostaje dla zgodności, nie jest aliasem nowych ławek.
Mata nie staje się obowiązkowa dla istniejących ćwiczeń podłogowych. Brak
nowych ćwiczeń na pasach/inwersji. Brak skoków na step, auto sandbag20 na stepie,
twierdzeń o leczeniu i domniemanej certyfikacji sprzętu. Wyciskanie ujemne
wymaga odrębnej jawnej kategorii ławki do obciążenia oraz widocznego zastrzeżenia.

## Architektura — decyzje wykonawcy

- Nowy moduł rozszerzenia XLSX zgodny z istniejącym pipeline. JSON eksportować
  przez tools/xlsx_to_json.py. Generowane katalog/metadata/warunki/źródła muszą
  być reprodukowalne; prefiks412 chroniony hashem, dodatek idempotentny.
- assets/data/exercise_catalog_corrections.json, schemaVersion1, zawiera listę
  corrections: {exerciseId, revision:1, fields:{...}}. Dozwolone fields tylko
  nazwaPl, sprzet, kluczoweWskazowki, czesteBledy, progresja, regresja.
  Dotyczy wyłącznie6 jawnych ID; brak usuwania, reidentyfikacji, zmiany pomiarów.
  Importer aktualizuje wyłącznie te zatwierdzone pola katalogowe i zachowuje
  ulubione, historię i metadane lokalne. Żadnego replace całych wierszy.
- Metadata v1 otrzymuje opcjonalne equipmentSets: List<List<String>> we wpisie.
  To OR kompletnych zestawów, każdy wewnętrznie AND; brak pola oznacza obecne
  ścisłe wymagania ex.sprzet. Puste/błędne grupy odrzucane, nigdy free pass.
- Wspólny ExerciseFilterEngine.equipmentOptions(Exercise),
  supportsEquipment(Exercise, Iterable<String>),
  matchingEquipment(Exercise, Iterable<String>) używane przez oba generatory
  i przygotowanie. Ostatni zwraca pierwszy zgodny kompletny zestaw lub null.
  Masa własna nie wymaga zakupu. Filtr przeglądania zachowuje własne OR,
  ale query/fasety widzą także sprzęt alternatywny.
- Profil dostaje jawny edytor listy sprzętu z zachowaniem nieznanych starszych
  wartości; nie zaznaczać niczego automatycznie. Decline nie odblokowuje flat
  ani incline. Wymagania obciążenia są oddzielne od samej nazwy ławki.
- Przygotowanie pokazuje zgodny zestaw, nie parę hantli dla wrist rollera.
  Sandbag20kg jest potwierdzonym zasobem właściciela, nie fikcyjnym Ostatnio;
  nie sugerować progresji kg ponad20 ani przenosić historii innej masy.
- Wymagane assety korekt i metadanych należą do core cache. Alternatywy sprzętu
  i przygotowanie nie mogą zależeć od zgody na pełny pakiet ilustracji; poza
  tymi dwoma konkretnymi ścieżkami nie rozszerzać cache na wszystkie dane.
- Nowe wpisy korzystają z uczciwego istniejącego fallbacku ilustracji; bez
  przypisywania obrazu innego ruchu, pobierania prywatnych zdjęć lub udawania
  zatwierdzonych nowych ilustracji. Dotychczasowe412 obrazów bez zmian.
- Istniejący Mentor nie ma autorytatywnego sprzętu w interfejsie walidacji.
  W tym zakresie nie rozszerzać ujawniania profilu do AI. Nowe cw418 wymagające
  weryfikacji ławki wyłączyć z automatycznej puli/walidacji Mentora. Katalog
  i jawny wybór lokalny pozostają dostępne z warunkami sprzętu i ostrzeżeniem.
  Pełne sprzętowe dopasowanie Mentora pozostaje osobnym zakresem, nie dowodzi go
  zgodność lokalnych generatorów ani obecność equipmentSets w projekcji.

## Źródła i weryfikacja

ACE: Step-up / library28; articles6369,5901,5808,7786,5895,7960.
ExRx: BWInclineCrunch, WtDeclineSitup, DBDeclineBenchPress.
TOGU: pelvic-floor-training-with-the-dynair-ballkissen (wyłącznie ruchy,
bez twierdzeń terapeutycznych). UltimateSandbag: best-secret-great-ultimate-
sandbag-workouts. Wrist roller: Catalyst exercise788 i Rogue/wrist-roller.
Dokładne URL i przypisanie przechowuje source ledger dodatku.

TDD danych, korekt i matcherów; upgrade istniejącej bazy z412 bez utraty
ulubionych/historii/pending, brak duplikacjiID, izolacja ławek, OR zestawów
bez zluzowania innych wymagań, wristroller bez solvera hantli i sandbag20 bez
kg progresji. Pełna analiza/testy i końcowy niezależny review. Baseline clean
dd4:1494PASS gate produkcyjnego obrazu; świeże focused72PASS.
