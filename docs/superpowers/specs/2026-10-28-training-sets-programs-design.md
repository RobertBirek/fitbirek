# Etap 3 — rodzaje serii, indywidualne cele i programy A/B

## Intencja i zakres
Użytkownik polecił wykonać etap3 po odbiorze etapu2 bez następnej rundy pytań.
Rozbudowujemy istniejącego Fluttera, Drift i sync, nie budujemy drugiej ścieżki
treningu. Etap obejmuje rzeczywistą rolę serii, osobne cele kolejnych serii,
prowadzenie według tych celów i programy dwóch planów A/B. Bez publikacji
na produkcję, nowych zależności, płatnego AI i kopiowania poradnika.

Decyzje wykonawcze niżej są wyborami implementacyjnymi, nie dodatkowymi
preferencjami przypisanymi użytkownikowi. Wymagane są testy i niezależny review.

## 1. Rola rzeczywistej serii
Wire `workoutSet.payload.setRole` jest opcjonalne: NULL albo dokładnie
`working`/`warmup`. Lokalny `SetsLog` i domenowy `SetLog` otrzymują nullable
pole. Brak/NULL zachowuje dotychczasową semantykę dla obliczeń, ale nie jest
backfillowany ani automatycznie dopisywany do starych outgoing payloadów.
Nowy formularz świadomie zapisuje rolę; stare dane i rekordy pozostają bez zmian.

Nowe jawne warmup:
- są widoczne w historii/podsumowaniu z etykietą;
- nie tworzą PR, nie stanowią dowodu progresji stałego ciężaru ani zwiększenia kg;
- nie zwiększają roboczej objętości/trendu, także w kontekście Mentora;
- nie powodują, że plan/sesja/termin zostaje automatycznie zaliczony.

Nie próbujemy odgadywać roli starych rekordów PR, usuwać ich lub przeliczać
historii. LegacyNULL uwzględniamy tak jak przed zmianą; dokumentacja jasno
odróżnia zgodność historyczną od dowodu, że dawna seria była robocza.
Powtarzanie faktycznego wykonania zachowuje role. Nowe interwały i dodatkowe
serie również muszą przejść przez świadomy wybór/default roboczy formularza.

Backend zachowuje rolę przy omission żywego snapshotu; explicitNULL jest
jawnym resetem do legacy. DELETE/revival nie dziedziczy roli tombstone'a.
Walidacja odrzuca inne wartości422 przed zapisami, bez wstawiania defaultu
do żądania lub zmiany jego hasha/idempotencji. Nie dodajemy kolumn PostgreSQL
ani migracji Alembic. API musi być opublikowane przed klientem przy przyszłym
wydaniu; teraz implementujemy i testujemy, nie wdrażamy.

## 2. Wersjonowane cele serii
Nowe plany z indywidualnymi seriami używają jawnego `StructuredPlan` schema2.
Jedna uporządkowana lista `SetPrescription` jest źródłem prawdy:
- stabilne `targetId` (nie numer logu), unikalne w bloku;
- rola `warmup` lub `working`;
- dodatnie reps dla trackingu reps albo dodatni czas dla time;
- opcjonalny skończony nieujemny weightKg;
- opcjonalna strona null/left/right/both;
- dodatni szacowany czas pracy i nieujemna przerwa po serii.

Tracking i czas przejścia pozostają cechą bloku. Ostatnia przerwa nie jest
doliczana drugi raz do przejścia. Liczba serii i sumy czasu są wyliczane
z listy, a nie utrzymywane jako konkurencyjne edytowalne wartości.
W tej wersji indywidualne cele obsługują reps/time (nie wielorundowy protokół
interwałowy). Nie konwertować rounds stratnie do time; schema1 rounds
pozostaje obsługiwane dotychczasową ścieżką. Maksymalnie100 celów na blok,
targetId niepuste do80znaków i unikalne w bloku; wszystkie granice liczb
sprawdzane przed mnożeniem/sumowaniem, nie tylko po wyliczeniu budżetu.
Nadal obowiązuje limit estymacji/budżetu5400s, brak duplikatu exerciseId
w blokach i ścisła zgodność kolejności cwiczeniaIds z blokami.

Odczyt i ponowna serializacja schema1 zachowują jego reprezentację i podpis
guidance. Legacy nie jest w tle przepisywane do schema2. Adapter może
udostępnić jednorodne cele v1 w pamięci, bez zmiany przechowywanego JSON.
Wersja3/przyszłe lub uszkodzone dane są izolowane jako niedostępne/raw,
nie konwertowane do legacy i nie pomijane w backupie. Backend zachowuje opaque
structure/guidance tak jak dotąd. Stare klienty mogą pokazać schema2 jako
niedostępne — nigdy nie obiecujemy, że obsługują nowe funkcje.

Edytor szablonu pozwala dodawać, usuwać i przesuwać wiersze serii, wybierać rolę,
reps/czas/kg/przerwę oraz przejrzeć pełną estymację. Przesunięcie zachowuje
targetId. Cancel nie zapisuje, optimistic/account guard pozostaje.
Kopia z historii może zachować różne dawki i role, gdy tracking jest spójny;
nadal odmawia konwersji stratnej stron/wariantów/mieszanych jednostek.

Generator nadal może tworzyć schema1 dla jednorodnych planów. Edycja przerwy
i zamiana schema2 nie mogą spłaszczyć listy; brak bezpiecznej konwersji oznacza
odmowę z wyjaśnieniem. Przygotowanie per-set planu pokazuje jego cele, ale
w tym etapie nie stosuje historycznej sugestii kg/powtórzeń do całej listy.
Nie nadpisuje rampy rozgrzewkowej jednym obciążeniem.

## 3. Prowadzenie i recovery per cel
Guidance schema2 wiąże `performed(slotIndex,targetId,setSyncId)` z konkretnym
celem. `skippedTarget(slotIndex,targetId)` oznacza jawne pominięcie, nie wykonanie.
Snapshot planu pozostaje niezmienny, zdarzenia append-only; schema1 zachowuje
dotychczasowy format i działanie. Identyfikator celu nie pochodzi z numerSerii,
liczby wszystkich logów ani kolejności katalogu.

Zapis rzeczywistej serii, linku celu, outboxa i ewentualnego PR jest atomowy.
Stary widok/doubletap nie może wykonać jednego celu dwa razy. Dodatkowy log
nie zużywa celu. Pominięte i nieważne po usunięciu logu cele pozostają widoczne
w podsumowaniu; nie są automatycznie ponownie otwierane lub wykonywane.

UI pokazuje wybrany cel i jego rolę, pozwala wskazać inny cel/pominąć go,
zachowuje odstępstwa rzeczywistego wykonania zamiast je poprawiać. Zapis
warmup jako dodatkowej serii pod v1 nie ma zużywać domyślnego celu working.
W v2 rola wynika z wybranego celu; dodatkowe serie mają osobny wybór roli.
Guidedv2 timer może obejmować tylko jeden wybrany target i jedną rundę.
Wielorundowy timer pozostaje dostępny jako EXTRA, bez zużywania kolejnych
celów. Checkpointówv1 nie konwertujemy automatycznie do v2.

Szkic/checkpoint i origin timera muszą obejmować targetId w v2; legacy klucze
pozostają bez zmian. Target/side/variant nie przenosi wyników obcego timera.
Zachować CAS, revision/epoch/version, nonce, flush poza transakcją oraz
persistentDatabaseZone. Po fresh-provider restart cel i jego indywidualne
kg/reps/czas/rola są odtworzone; natychmiastowa kolejna akcja działa bez
pomocniczej edycji formularza. Obcy szkic/EXTRA nie jest tracony.

Ćwiczenia jednostronne zachowują oddzielne fakty stron. Nowy cel jednostronny
ma jawną stronę left/right/both; domyślny w edytorze jest both (reps na stronę,
czas pracy uwzględnia obie). Dla oddzielnego logowania stron użytkownik tworzy
osobne cele left i right. Cel both zużywa wyłącznie log jawnie potwierdzony
jako both, nigdy sam left/right. Dla niejednostronnych strona celu/logu jest
null. Legacy nie jest przez ten adapter przepisywane.
Aktywna zamiana nadal nie przenosi indywidualnego ciężaru na inny ruch:
jakikolwiek dodatni kg w celach blokuje taką zamianę. Celów nie zmieniamy.

## 4. Programy A/B — kalendarz i jawne wykonanie
Decyzja wykonawcza: deterministyczna rotacja według kolejnych ZAPLANOWANYCH
terminów, nie wspólny mutowalny nextIndex ani modulo liczby sesji. Dla pn/śr/pt
otrzymujemy A–B–A, w kolejnym tygodniu B–A–B. Brak wykonania nie zalicza dnia;
poprzedni termin pozostaje do wykonania/przesunięcia. Nie implementujemy
w tym etapie alternatywnego kursora zależnego od wykonanych treningów.

Nowa opcjonalna kolekcja profilu `trainingPrograms`, version1, z dotychczasową
kopertą UUID/name/createdAtUtc/updatedAtUtc/deletedAtUtc, per-ID LWW,
limitami500wrazztombstone/262144B i quarantine/hold/explicitNULL.
Nie dodajemy nieznanych rodzajów do weeklySchedulev1.

Wpis `kind:program` zawiera dokładnie dwa różne UUID istniejących planów
`planSyncIds` w kolejności A/B, unikalne `weekdays`1..7 oraz `effectiveFromDate`.
Te trzy parametry są niezmienne pod danym ID. W tej minimalnej wersji UI
nie edytuje strukturalnie istniejącego programu: pozwala zmienić nazwę,
zakończyć go i utworzyć nowy program z nowym ID. Zakończenie ustawia raz
`endBeforeDate` (wyłączna granica, nie wcześniejsza niż dzisiejszy dzień).
Stara definicja pozostaje źródłem terminów wcześniejszych niż ta granica,
więc zakończenie/nowy program nie usuwa zaległych A/B. Granica nie może być
cofnięta/wyczyszczona przez omission, merge ani restore; dwie różne jawne
granice oznaczają konflikt, nie cichą zmianę historii. Tombstone nie uprawnia
do usunięcia dawnej definicji lub wyjątków.
Wyliczenie ordinalu używa lokalnych dni kalendarza, nie dodawania24h do
lokalnej północy. Termin ma UUIDv5(programId,originalDate); przeniesienie
nie zmienia jego tożsamości ani wybranego planu.

Wpis `kind:programOverride` ma programId/originalDate/movedDate,
state planned|completed, sessionSyncId wyłącznie dla completed i snapshot
definicji programu. Snapshot pozwala wyświetlić historię po edycji/usunięciu
programu. Nowy program dotyczy własnego zakresu dat i ma własny ordinal,
nie przepisuje snapshotów istniejących wyjątków i rozpoczętej sesji.
Wyjątki korzystają wyłącznie ze swojego snapshotu definicji i nazwy.

Programy A/B są tworzone świadomie z dwóch zapisanych szablonów. UI zawiera
nazwę, wybór A/B, dni tygodnia, datę początku, podgląd tygodnia, start,
przesunięcie i jawne powiązanie zakończonej sesji. Używa istniejącego workflow
startu i zabezpieczeń konta, bez drugiego serializera sesji.
Sam start, upływ terminu, pusta sesja, warmup-only i samo finish nie zaliczają
terminu. Użytkownik potwierdza ukończenie i wybiera zakończoną nieusuniętą
sesję z co najmniej jedną live serią effective-working. Częściowe wykonanie
może zostać powiązane tylko przez tę jawną decyzję, nie przez automat.

Jedna sesja nie zalicza po cichu dwóch terminów (także między programem
i weeklySchedule). Zapis lokalny odmawia; po offline merge oba powiązania
mają jawny konflikt. Usunięty dowód oznacza nieważność, nie przewijanie
historii. Brak planu/ćwiczenia lub nieobsługiwany plan oznacza niedostępność,
bez generatora zastępczego. Powiadomienia programów nie są częścią etapu.

## 5. Storage, sync i backup
Nowa addytywna migracja Drift14→15: nullable setRole serii i nullable
trainingProgramsJson profilu. Nie edytować dawnych migracji ani uzupełniać
historycznych ról. Regenerować i commitować pliki Drift/Freezed/JSON.
Backend generyczny JSONB nie wymaga Alembic; dodać ochronę omission nowego
klucza profilu i roli serii. Serwer nie nadaje domyślnych wartości przed
idempotencyhash. Mentor agreguje wyłącznie effective-working.

Nowe eksporty backup4, stare formaty1–3 nadal importowalne. Backup4 zachowuje
role, programy i powiązania; poprzedni klient ma go odrzucić, nie odtworzyć
stratnie. Import remapuje UUID planów/sesji/serii i referencje programów oraz
guidance, zachowując wewnętrzne targetId. Brak mapowanej referencji jest
jawną niedostępnością/błędem, nie wymyśloną sesją lub zerowym ID.
Nie niszczyć nowszych kolekcji profilu, tombstone'ów i attempted payloadów.
Ponieważ restore nadaje planom nowe UUID, importowane programy i wyjątki
stają się kopiami z nowymi UUID programu oraz przeliczonymi UUIDv5 wyjątków.
Referencje planów i sesji oraz snapshoty korzystają z tych samych map restore;
nie zmieniać niezmiennych parametrów istniejącego programu pod starym ID.
Zachować role, tombstone i zamknięte granice kopii. Brak mapy referencji lub
przekroczenie łącznego limitu kolekcji odmawia całego importu transakcyjnie,
bez pomijania programu i bez modyfikacji oryginalnego pliku backupu.

Stary klient nie rozumie warmup ani schema2 i może inaczej liczyć PR — sama
ochrona omission nie daje semantycznej zgodności. Przed przyszłą publikacją
potrzebny plan aktualizacji klientów oraz API-first; nie resetować ich danych.

## 6. Odbiór
- warmup z większym wynikiem od working nie tworzy PR i nie blokuje progresji;
  historia nadal pokazuje oba; legacyNULL pozostaje bez zapisu/backfillu;
- migracja14→15, serializers/pull/outbox/restore i omission/NULL/revival
  zachowują rolę i program; invalidrole422 bez zapisów;
- v1 roundtrip i podpisy bez zmian, v2 per-set roundtrip i future quarantine;
- różne kg/reps/czasy/role po save/start/restart; dodatkowa seria i doubletap
  nie zużywają obcego celu; target/side/variant/timer izolowane;
- bezpieczne przygotowanie, zamiana i copy/repeat nie spłaszczają per-set;
- pn/śr/pt ABA/BAB, granica roku/DST, przesunięcie bez zmiany tożsamości,
  zakończenie/nowy program bez zmiany zaległych terminów i zapisanej historii,
  jawne completed/conflict/invalid;
- backup4 roundtrip z remapem i import starszych formatów; brak utraty pending;
- focused i pełne Flutter/backend, analiza, codegen i diffcheck oraz review.
