# Polskie nazwy ćwiczeń

Wersja mappingu: 1, 2026-10-10. Zakres: przegląd wszystkich 316 nazw,
278 zmian i 38 nazw zachowanych. Wersję mappingu utrzymujemy w historii Git;
sam JSON jest płaskim obiektem `ID → nazwa docelowa`, bez pól metadanych.

## Źródła i zasady

- [Pełny, jawny mapping 316 ID](../tools/source_data/exercise_names_pl.json)
  obejmuje również nazwy już poprawne po polsku.
- Źródłem danych pozostaje `tools/source_data/baza_cwiczen_316.xlsx`, arkusz
  `BAZA_GLOWNA`, kolumna `Nazwa_PL`. Eksport powstaje przez istniejący
  `tools/xlsx_to_json.py`.
- Nazwa opisuje ruch po polsku. Zamiast dosłownych, niezrozumiałych kalk
  stosujemy opis pozycji lub wykonania, np. „unoszenie bioder” zamiast
  dosłownego tłumaczenia „frog pump”.
- Zachowane zapożyczenia: **burpee, hip thrust, face pull**. Określenia
  wariantów są polskie, np. „Face pull z gumą”, „Burpee bez pompki i wyskoku”.
- Zachowane nazwy własne: **Tai Chi**, Meadows, Kelso, Arnold, Zottman,
  Tate, Pallof oraz inicjały JM. Nazwiska odmieniamy zgodnie z polską składnią.
- Zachowujemy sprzęt, chwyt, podparcie, pozycję, stronę ruchu i kontekst
  ćwiczenia. Doprecyzowania wynikają z istniejących wskazówek i sprzętu,
  a nie z założenia, że każdy angielski termin oznacza jeden standardowy wariant.
- `nazwaEn`, ID, opisy, źródła, partie, typy i pozostałe pola pozostają identyczne.
  Podobnych ćwiczeń nie scalamy; powtarzalność samej nazwy nie oznacza błędu.
- Dla cw261 obowiązuje dokładnie: **Rozciąganie mięśnia czworogłowego uda w staniu**.

## Rozstrzygnięte niejednoznaczności

| ID | Decyzja i podstawa |
| --- | --- |
| cw008, cw249 | Nazwy z odniesieniem do Spider-Mana zastąpiono opisami ruchu: kolano do łokcia w pompce oraz stopa na zewnątrz dłoni w podporze. |
| cw019, cw024 | „Pullover” rozdzielono na przenoszenie hantla za głowę na ławce oraz ściąganie gumy znad głowy do bioder. Wskazówki gumy dopuszczają stanie lub leżenie, więc nazwa nie narzuca jednej pozycji. |
| cw025 | Źródło łączy krzesła i ławkę. Zachowano oba warianty w nazwie oraz akcent na klatkę piersiową. |
| cw050, cw053 | Zachowano nazwiska Meadows i Kelso. Wariant Meadowsa nadal używa hantla, a Kelso opisuje ściąganie łopatek bez zginania łokci, nie unoszenie barków. |
| cw055/cw086, cw058/cw085 | Te same polskie nazwy odpowiadają temu samemu ruchowi w różnych kontekstach partii. Pozostają cztery osobne rekordy; trójki PL+partia+typ są różne. |
| cw059, cw060, cw185 | „Superman” i „arch body hold” opisano ruchem lub utrzymaniem pozycji na brzuchu. Nie scalono podobnych utrzymań cw060 i cw185. |
| cw064 | Imitacja wiosłowania końcem sztangi pozostaje wariantem z hantlem opartym jednym końcem w rogu, zgodnie ze wskazówkami. |
| cw091, cw092 | „Empty/full can” rozróżnia kierunek kciuków; obie nazwy zachowują unoszenie w skos w przód. |
| cw101 | „21s” oznacza metodę 21 powtórzeń (7+7+7), nie 21 sekund. |
| cw105 | Mimo dawnego „hantlami oburącz” wskazówki mówią o jednym hantlu trzymanym oburącz; tak brzmi nazwa docelowa. |
| cw113 | JM to inicjały w nazwie własnej ćwiczenia; tłumaczymy „press”, zachowujemy JM. |
| cw122, cw123 | „Plate pinch” to w tej bazie ściskanie końca hantla, nie talerza. „Wrist roller” to nawijanie linki z hantlem na drążek/rurkę. |
| cw130–cw134 | „Zakroki chodzące” poprawiono na wykroki chodzone: EN i wskazówki podają krok w przód. Osobno pozostają zakrok, wypad w bok, zakrok skrzyżny i wykrok z rotacją. |
| cw132, cw143 | Wypad w bok wykonuje się krokiem, przysiad kozacki przejściem w szerokim rozkroku. Nie scalono rekordów mimo „cossack squat” w EN cw132. |
| cw138, cw149 | Podparcie w cw138 może być gumą lub drążkiem. Cw149 dopuszcza jeden albo dwa hantle; nazwa określa kategorię sprzętu bez narzucania ich liczby. |
| cw140, cw153 | Opisowe nazwy odpowiadają odchyleniu na palcach z podparciem oraz opadowi z klęku z zablokowanymi stopami i pomocą rąk. |
| cw160, cw167 | Cw160 zachowuje gumę nad kolanami. Cw167 to wspięcia w opadzie tułowia; ławka służy w opisie do podparcia, a nie do obciążenia. |
| cw183–cw185 | Rozróżniono utrzymanie i kołysanie łódki na plecach oraz utrzymanie łódki na brzuchu. |
| cw186–cw189 | Pełne brzuszki odróżniono od spięć brzucha i odwrotnych spięć, zgodnie z zakresem ruchu. |
| cw197 | Wskazówki rzeczywiście dodają rotację do wyciskania Pallofa. Nazwa zachowuje ten wariant zamiast zmieniać go w klasyczne ćwiczenie antyrotacyjne. |
| cw203–cw205 | Opisano podpór z nogami w poziomie, unoszenie prostego ciała na barkach oraz przetaczanie hantli. W cw205 zachowano sześciokątny kształt hantli mimo nietypowego połączenia z toczeniem; nazwa nie koryguje instrukcji. |
| cw212, cw219 | Ruchy bez pompki i wyskoku są bardzo podobne, ale oba ID pozostają: wariant burpee i wyrzuty nóg do podporu. |
| cw235, cw236 | Zachowano protokół 12-3-30 oraz jednostkę 3 mile/h. Interwał 30/90 rozwinięto jako 30 sekund sprintu i 90 sekund truchtu. |
| cw239 | EN podaje 80% tętna maksymalnego, a wskazówki 85%. Neutralna nazwa „bieg tempowy” nie rozstrzyga tej rozbieżności i nie zmienia źródłowych pól. |
| cw260, cw262 | „Couch stretch” używa w tej bazie ławki. Rozciąganie tyłu uda w staniu ma nogę na podwyższeniu, czego nie pominięto w nazwie. |
| cw268, cw291 | Zachowano rozróżnienie ogólnego siadu oraz siadu na krześle. Analogicznie nazwano pozostałe warianty z krzesłem. |
| cw274 | Wbrew fragmentowi „push-up” wskazówki opisują utrzymanie/rozciąganie nadgarstków w klęku podpartym z palcami ku kolanom, bez wykonywania pompki. |
| cw278 | „Shoulder dislocates” to przenoszenie gumy nad głową za plecy; unikamy dosłownego „zwichnięcia barków”. |
| cw283, cw285 | „Cloud hands” i „wave hands like clouds” mają zbliżone opisy. Zachowano dwa ID i odpowiadające źródłu nazwy, bez dopisywania odmiennych technik. |
| cw284–cw289 | Tradycyjne nazwy ruchów Tai Chi przetłumaczono, zachowując Tai Chi i siedzący wariant na krześle. |
| cw302, cw314 | Podobne połączenia przysiadu i wyciskania zachowują osobne ID; cw302 podkreśla dynamiczne wybicie opisane we wskazówkach. |
| cw303–cw316 | Sekwencje nazwano po polsku, zachowując skład ruchów i sprzęt. Cw312 to konkretnie rumuński martwy ciąg z wiosłowaniem według wskazówek. |

## Pełna lista zmienionych nazw

Poniżej wszystkie 278 zmienionych ID i ich nazwy docelowe. Poprzednie wartości
są widoczne w różnicy `assets/data/exercises.json`; pełny mapping zawiera także
38 zaakceptowanych nazw bez zmian.

| ID | Nazwa docelowa |
| --- | --- |
| cw004 | Pompki łucznika |
| cw007 | Pompki hinduskie |
| cw008 | Pompki z przyciąganiem kolana do łokcia |
| cw010 | Głębokie pompki na hantlach |
| cw012 | Wyciskanie hantli na ławce płaskiej |
| cw013 | Wyciskanie hantli na ławce skośnej głową w górę |
| cw014 | Wyciskanie hantli w leżeniu na podłodze |
| cw016 | Rozpiętki z hantlami na ławce płaskiej |
| cw017 | Rozpiętki z hantlami na ławce skośnej głową w górę |
| cw018 | Rozpiętki z hantlami w leżeniu na podłodze |
| cw019 | Przenoszenie hantla za głowę w leżeniu na ławce |
| cw020 | Wyciskanie hantli w moście biodrowym |
| cw021 | Wyciskanie gumy przed klatkę piersiową w staniu |
| cw022 | Rozpiętki z gumą w staniu |
| cw024 | Ściąganie gumy znad głowy do bioder na prostych ramionach |
| cw025 | Pompki między krzesłami lub na ławce (na klatkę piersiową) |
| cw026 | Pompki z dłońmi przy biodrach i pochyleniem w przód |
| cw028 | Pompki łucznika z nogami na ławce |
| cw030 | Pompki eksplozywne z przeskokiem w bok |
| cw031 | Podciąganie szerokim nachwytem |
| cw033 | Podciąganie chwytem neutralnym |
| cw034 | Podciąganie wąskim chwytem |
| cw035 | Podciąganie chwytem mieszanym |
| cw037 | Podciąganie z prostymi nogami uniesionymi do poziomu |
| cw039 | Opuszczanie na jednej ręce z podciągnięcia |
| cw042 | Opuszczanie z podciągnięcia |
| cw045 | Podciąganie łopatkowe |
| cw048 | Wiosłowanie hantlami z klatką opartą na ławce skośnej |
| cw049 | Wiosłowanie hantlami w podporze przodem |
| cw050 | Wiosłowanie Meadowsa z hantlem |
| cw051 | Wiosłowanie hantlami podchwytem |
| cw052 | Naprzemienne wiosłowanie hantlami z podłogi w opadzie |
| cw053 | Ściąganie łopatek Kelso z hantlami na ławce skośnej |
| cw054 | Wzruszanie barkami z hantlami |
| cw055 | Rozciąganie gumy przed klatką piersiową |
| cw056 | Wiosłowanie gumą w siadzie |
| cw057 | Ściąganie gumy z góry do klatki piersiowej |
| cw058 | Face pull z gumą |
| cw059 | Unoszenie ramion i nóg w leżeniu na brzuchu |
| cw060 | Utrzymanie uniesionych ramion i nóg w leżeniu na brzuchu |
| cw061 | Przenoszenie ramion łukiem nad głowę w leżeniu na brzuchu |
| cw062 | Skłony tułowia z hantlem i cofnięciem bioder |
| cw063 | Rumuński martwy ciąg z hantlami |
| cw064 | Wiosłowanie oburącz hantlem opartym jednym końcem w rogu |
| cw065 | Wyciskanie hantli nad głowę w siadzie |
| cw066 | Wyciskanie hantli nad głowę w staniu |
| cw067 | Wyciskanie Arnolda z hantlami |
| cw068 | Wyciskanie hantli nad głowę chwytem neutralnym |
| cw069 | Wyciskanie hantli nad głowę z wybiciem z nóg |
| cw070 | Unoszenie hantli bokiem |
| cw071 | Unoszenie hantli bokiem w staniu na jednej nodze |
| cw072 | Unoszenie hantli bokiem z pauzą |
| cw073 | Unoszenie hantli w przód |
| cw074 | Naprzemienne unoszenie hantli w przód |
| cw075 | Odwrotne rozpiętki z hantlami w opadzie |
| cw076 | Odwrotne rozpiętki z hantlami na ławce skośnej |
| cw077 | Unoszenie hantli w kształt litery Y na ławce skośnej |
| cw078 | Pompki z biodrami uniesionymi wysoko |
| cw079 | Pompki z biodrami uniesionymi wysoko i nogami na ławce |
| cw080 | Stanie na rękach przy ścianie |
| cw081 | Pompki w staniu na rękach przy ścianie |
| cw082 | Wyciskanie gumy nad głowę |
| cw083 | Unoszenie ramienia bokiem z gumą |
| cw084 | Unoszenie ramion w przód z gumą |
| cw085 | Face pull z gumą |
| cw086 | Rozciąganie gumy przed klatką piersiową |
| cw087 | Rotacja zewnętrzna ramienia z gumą |
| cw088 | Rotacja wewnętrzna ramienia z gumą |
| cw089 | Wyciskanie kubańskie z hantlami |
| cw090 | Rotacja zewnętrzna ramienia z hantlem w leżeniu bokiem |
| cw091 | Unoszenie hantli w skos w przód z kciukami w dół |
| cw092 | Unoszenie hantli w skos w przód z kciukami w górę |
| cw093 | Uginanie przedramion z hantlami w staniu |
| cw094 | Uginanie młotkowe z hantlami |
| cw095 | Naprzemienne uginanie przedramion z hantlami |
| cw096 | Uginanie przedramion z hantlami na ławce skośnej |
| cw097 | Uginanie Zottmana z hantlami |
| cw098 | Uginanie przedramienia z hantlem w oparciu o udo |
| cw099 | Uginanie młotkowe z hantlem do przeciwnego barku |
| cw100 | Uginanie przedramion z hantlami nachwytem |
| cw101 | Uginanie przedramion z hantlami metodą 21 powtórzeń |
| cw102 | Podciąganie podchwytem z naciskiem na biceps |
| cw103 | Uginanie przedramion z gumą |
| cw104 | Uginanie przedramion z hantlami prowadzonymi wzdłuż tułowia |
| cw105 | Wyciskanie francuskie hantla oburącz nad głową |
| cw106 | Wyciskanie francuskie hantla jednorącz nad głową |
| cw107 | Wyciskanie francuskie hantli w leżeniu na ławce |
| cw108 | Wyciskanie hantli wąsko na ławce |
| cw109 | Prostowanie przedramienia z hantlem w opadzie |
| cw110 | Pompki diamentowe z naciskiem na triceps |
| cw111 | Pompki tyłem na ławce |
| cw112 | Pompki tyłem na ławce z hantlem na udach |
| cw113 | Wyciskanie JM z hantlami |
| cw114 | Prostowanie przedramion w dół z gumą |
| cw115 | Prostowanie przedramion nad głową z gumą |
| cw116 | Wyciskanie Tate'a z hantlami |
| cw117 | Uginanie nadgarstków z hantlami podchwytem |
| cw118 | Prostowanie nadgarstków z hantlami nachwytem |
| cw119 | Chód farmera z hantlami |
| cw120 | Zwis martwy na siłę chwytu |
| cw121 | Podciąganie na ręcznikach przewieszonych przez drążek |
| cw122 | Ściskanie końca hantla palcami |
| cw123 | Nawijanie linki z hantlem na drążek |
| cw124 | Uginanie nadgarstków z hantlami za plecami |
| cw125 | Przysiad z hantlem trzymanym oburącz przy klatce |
| cw128 | Przysiad bułgarski z hantlami |
| cw129 | Przysiad w wykroku z hantlami |
| cw130 | Wykroki chodzone z hantlami |
| cw131 | Zakroki z hantlami |
| cw132 | Wypady w bok z hantlami |
| cw133 | Zakroki skrzyżne z hantlami |
| cw134 | Wykroki chodzone z rotacją tułowia i hantlami |
| cw135 | Wchodzenie na ławkę z hantlami |
| cw136 | Wchodzenie na ławkę z uniesieniem kolana i hantlami |
| cw137 | Przysiad na jednej nodze z drugą wyprostowaną w przód |
| cw138 | Przysiad na jednej nodze z drugą wyprostowaną w przód z podparciem |
| cw139 | Przysiad łyżwiarski |
| cw140 | Przysiad na palcach z odchyleniem tułowia w tył i podparciem |
| cw141 | Siad przy ścianie |
| cw142 | Siad przy ścianie z hantlem |
| cw143 | Przysiad kozacki z hantlem |
| cw145 | Przysiad ze skokiem i obrotem o 180° |
| cw146 | Wyskoki na skrzynię lub ławkę |
| cw147 | Skok w dal z miejsca |
| cw148 | Rumuński martwy ciąg z hantlami (na nogi) |
| cw149 | Rumuński martwy ciąg z hantlami na jednej nodze |
| cw150 | Martwy ciąg z hantlami na prostych nogach |
| cw151 | Martwy ciąg z hantlem w szerokim rozkroku |
| cw152 | Skłony tułowia z gumą i cofnięciem bioder |
| cw153 | Opad tułowia w klęku z zablokowanymi stopami i pomocą rąk |
| cw154 | Most biodrowy |
| cw155 | Most biodrowy z hantlem |
| cw158 | Unoszenie bioder w leżeniu ze złączonymi podeszwami stóp |
| cw159 | Unoszenie ugiętej nogi w tył w klęku podpartym |
| cw160 | Odwodzenie ugiętej nogi w bok w klęku podpartym z gumą |
| cw161 | Rozwieranie kolan w leżeniu bokiem z gumą |
| cw162 | Chód w półprzysiadzie z gumą |
| cw163 | Wspięcia na palce w staniu |
| cw164 | Wspięcia na palce na jednej nodze z hantlem |
| cw165 | Wspięcia na palce na krawędzi ławki z hantlami |
| cw166 | Wspięcia na palce w siadzie z hantlami |
| cw167 | Wspięcia na palce w opadzie tułowia |
| cw168 | Unoszenie przodostopia w oparciu plecami o ścianę |
| cw169 | Deska na przedramionach |
| cw170 | Deska na prostych ramionach |
| cw171 | Deska bokiem |
| cw172 | Deska bokiem z opuszczaniem i unoszeniem bioder |
| cw173 | Deska bokiem z unoszeniem nogi |
| cw174 | Deska z dotykaniem przeciwnego barku |
| cw175 | Przejścia z deski na przedramionach do podporu na dłoniach |
| cw176 | Wiosłowanie hantlami w podporze przodem (stabilizacja tułowia) |
| cw177 | Deska z unoszeniem nogi |
| cw178 | Deska kopenhaska z nogą na ławce |
| cw179 | Martwy robak |
| cw180 | Martwy robak z hantlem |
| cw181 | Prostowanie przeciwnej ręki i nogi w klęku podpartym |
| cw182 | Prostowanie przeciwnej ręki i nogi z przyciąganiem łokcia do kolana w klęku podpartym |
| cw183 | Utrzymanie pozycji łódki w leżeniu na plecach |
| cw184 | Kołysanie w pozycji łódki na plecach |
| cw185 | Utrzymanie pozycji łódki w leżeniu na brzuchu |
| cw186 | Pełne brzuszki |
| cw187 | Pełne brzuszki z hantlem na klatce piersiowej |
| cw188 | Spięcia brzucha |
| cw189 | Odwrotne spięcia brzucha |
| cw190 | Scyzoryki |
| cw191 | Sięganie dłońmi do uniesionych stóp w leżeniu |
| cw192 | Spięcia brzucha ze skrętem i naprzemienną pracą nóg |
| cw193 | Skręty tułowia w siadzie bez obciążenia |
| cw194 | Skręty tułowia w siadzie z hantlem |
| cw195 | Rąbanie drewna z hantlem po przekątnej |
| cw196 | Wyciskanie Pallofa z gumą |
| cw197 | Wyciskanie Pallofa z gumą i rotacją tułowia |
| cw198 | Skłony boczne z hantlem w staniu |
| cw199 | Unoszenie kolan w zwisie na drążku |
| cw200 | Unoszenie prostych nóg w zwisie na drążku |
| cw201 | Przenoszenie uniesionych nóg na boki w zwisie na drążku |
| cw202 | Unoszenie stóp do drążka w zwisie |
| cw203 | Utrzymanie podporu z prostymi nogami uniesionymi do poziomu |
| cw204 | Unoszenie i opuszczanie prostego ciała w oparciu na barkach na ławce |
| cw205 | Przetaczanie hantli sześciokątnych w przód w klęku |
| cw206 | Chód farmera z hantlami (stabilizacja tułowia) |
| cw207 | Chód z hantlem w jednej ręce |
| cw208 | Bieg w podporze (na brzuch) |
| cw212 | Burpee bez pompki i wyskoku |
| cw213 | Pajacyki |
| cw214 | Wyskoki z przysiadu do pozycji gwiazdy |
| cw215 | Bieg w miejscu z wysokim unoszeniem kolan |
| cw216 | Bieg w miejscu z uderzaniem piętami o pośladki |
| cw217 | Bieg w podporze |
| cw218 | Bieg w podporze z kolanami do przeciwnych łokci |
| cw219 | Wyrzuty nóg w tył do podporu z przysiadu |
| cw220 | Skoki łyżwiarskie |
| cw221 | Wyskoki z przyciąganiem kolan do klatki piersiowej |
| cw222 | Skok w dal z miejsca z powrotem truchtem |
| cw223 | Chód niedźwiedzia |
| cw224 | Chód kraba |
| cw225 | Skakanka — podskoki obunóż |
| cw226 | Skakanka — krok bokserski |
| cw227 | Skakanka — wysokie unoszenie kolan |
| cw228 | Skakanka — podskoki na jednej nodze |
| cw229 | Skakanka — podskoki na boki |
| cw230 | Skakanka — podskoki w przód i w tył |
| cw231 | Skakanka — podwójny obrót linki w podskoku |
| cw232 | Skakanka — podskoki ze skrzyżowaniem ramion |
| cw233 | Skakanka — podwójny obrót linki ze skrzyżowaniem ramion |
| cw234 | Bieżnia — spokojny bieg w drugiej strefie tętna |
| cw235 | Bieżnia — marsz 12-3-30 (nachylenie 12%, 3 mile/h, 30 min) |
| cw236 | Bieżnia — interwały: 30 sekund sprintu i 90 sekund truchtu |
| cw237 | Bieżnia — sprinty pod górę (nachylenie 5–7%) |
| cw239 | Bieżnia — bieg tempowy |
| cw240 | Bieżnia — długi, spokojny bieg |
| cw243 | Wymachy nogi w przód i w tył |
| cw244 | Wymachy nogi na boki |
| cw246 | Wykroki chodzone z rotacją tułowia bez obciążenia |
| cw247 | Gąsienica |
| cw248 | Rozciąganie w wykroku z rotacją tułowia |
| cw249 | Przyciąganie stopy do zewnętrznej strony dłoni w podporze |
| cw250 | Koci grzbiet i wygięcie pleców w klęku podpartym |
| cw251 | Pozycja kobry |
| cw253 | Pies z głową w dół |
| cw254 | Pies z głową w górę |
| cw256 | Rozciąganie bioder w siadzie 90/90 |
| cw257 | Rozciąganie w pozycji motyla |
| cw258 | Rozciąganie w pozycji żaby |
| cw259 | Rozciąganie w przysiadzie kozackim |
| cw260 | Rozciąganie zginaczy biodra w klęku ze stopą na ławce |
| cw261 | Rozciąganie mięśnia czworogłowego uda w staniu |
| cw262 | Rozciąganie tylnej części uda w staniu z nogą na podwyższeniu |
| cw263 | Skłon w przód w siadzie prostym |
| cw264 | Rozciąganie łydki przy ścianie |
| cw265 | Rozciąganie klatki piersiowej w futrynie |
| cw266 | Przekładanie ręki pod tułowiem w klęku podpartym |
| cw267 | Wyprost odcinka piersiowego kręgosłupa na ławce |
| cw268 | Koci grzbiet i wygięcie pleców w siadzie |
| cw270 | Cofanie brody |
| cw273 | Rozciąganie nadgarstków ze złożonymi dłońmi |
| cw274 | Rozciąganie nadgarstków w klęku podpartym z palcami ku kolanom |
| cw276 | Zgięcie grzbietowe stawu skokowego z kolanem do ściany |
| cw277 | Utrzymanie głębokiego przysiadu |
| cw278 | Przenoszenie gumy nad głową za plecy na prostych ramionach |
| cw279 | Rozciąganie przedniej i tylnej części barków z gumą |
| cw280 | Rozciąganie mięśnia czworogłowego uda w staniu z rotacją tułowia |
| cw281 | Powitanie słońca A |
| cw282 | Tai Chi — otwarcie klatki piersiowej w siadzie na krześle |
| cw283 | Tai Chi — dłonie jak chmury w siadzie na krześle |
| cw284 | Tai Chi — chwytanie wróblego ogona w siadzie na krześle |
| cw285 | Tai Chi — falowanie dłońmi jak chmurami w siadzie na krześle |
| cw286 | Tai Chi — rozdzielanie grzywy dzikiego konia w siadzie na krześle |
| cw287 | Tai Chi — złoty kogut w siadzie na krześle |
| cw288 | Tai Chi — omiatanie kolana w siadzie na krześle |
| cw289 | Tai Chi — pojedynczy bicz w siadzie na krześle |
| cw290 | Skręt tułowia w siadzie na krześle |
| cw291 | Koci grzbiet i wygięcie pleców w siadzie na krześle |
| cw292 | Skłon w przód w siadzie na krześle |
| cw293 | Pozycja gołębia w siadzie na krześle |
| cw294 | Skłon boczny w siadzie na krześle |
| cw295 | Boczne rozciąganie szyi w siadzie na krześle |
| cw296 | Krążenia barków w siadzie na krześle |
| cw297 | Ramiona orła w siadzie na krześle |
| cw298 | Krążenia kostek w siadzie na krześle |
| cw299 | Krążenia bioder w siadzie na krześle |
| cw300 | Oddech kwadratowy 4–4–4–4 |
| cw301 | Oddech przeponowy |
| cw302 | Przysiad z dynamicznym wyciśnięciem hantli nad głowę |
| cw303 | Pompka, wiosłowanie w podporze i przysiad z wyciskaniem hantli |
| cw304 | Burpee z rwaniem dwóch hantli nad głowę |
| cw305 | Zarzut hantli z wyciskaniem nad głowę |
| cw306 | Rwanie hantla jednorącz |
| cw307 | Wymach hantlem oburącz |
| cw308 | Wstawanie tureckie z hantlem |
| cw309 | Przysiad, uginanie przedramion i wyciskanie hantli nad głowę |
| cw310 | Wiosłowanie hantlami w podporze z pompką |
| cw311 | Wykrok z uginaniem przedramion z hantlami |
| cw312 | Rumuński martwy ciąg z wiosłowaniem hantlami |
| cw313 | Chód niedźwiedzia z pompkami |
| cw314 | Przysiad z wyciskaniem hantli nad głowę |
| cw315 | Burpee z podciąganiem na drążku |
| cw316 | Chód farmera naprzemiennie z chodem z hantlem w jednej ręce |

### Nazwy zaakceptowane bez zmian (38)

cw001, cw002, cw003, cw005, cw006, cw009, cw011, cw015, cw023, cw027,
cw029, cw032, cw036, cw038, cw040, cw041, cw043, cw044, cw046, cw047,
cw126, cw127, cw144, cw156, cw157, cw209, cw210, cw211, cw238, cw241,
cw242, cw245, cw252, cw255, cw269, cw271, cw272, cw275.

## Wykonanie i kontrole

Użyto izolowanego środowiska `/tmp/opencode/exercise-names-venv` z openpyxl
3.1.5. Polecenia z katalogu głównego repozytorium:

```bash
/tmp/opencode/exercise-names-venv/bin/python tools/update_exercise_names_pl.py
/tmp/opencode/exercise-names-venv/bin/python tools/xlsx_to_json.py
/tmp/opencode/exercise-names-venv/bin/python tools/update_exercise_names_pl.py --check
```

Skrypt wymaga kompletnego mappingu, odrzuca powtórzone klucze i sprawdza
baseline XLSX względem obecnego JSON przed zapisem. Zapisuje najpierw plik
tymczasowy, ponownie sprawdza wartości, typy, style, komentarze i odnośniki
wszystkich komórek oraz wynik konwertera. Dopiero po kontroli zastępuje XLSX.
Ponowne wykonanie z aktualnym eksportem nie przepisuje pliku. `--check` nie
zapisuje danych. JSON zapisuje wyłącznie istniejący konwerter.

Wyniki:

- Przed zmianą: wynik konwertera identyczny z istniejącymi 316 rekordami JSON.
- Po zmianie: 278 różnic, każda wyłącznie w `nazwaPl`; wszystkie pozostałe
  pola, kolejność rekordów i zbiór 316 ID identyczne z baseline.
- XLSX: 278 zmienionych wartości komórek, wyłącznie `BAZA_GLOWNA!B`.
  Wartości pozostałych komórek, w tym pozostałych 11 arkuszy, identyczne.
  openpyxl ponownie serializuje kontener XLSX, więc plik binarny ma inny rozmiar.
- Mapping, źródłowy XLSX i eksport JSON zgodne dla wszystkich 316 nazw.
- Kolizje trójek `nazwaPl + partiaGlowna + typ`: **0 przed, 0 po**.
  Kolizje analogicznych trójek EN: **0**.
- Istniejący `test/features/exercises/exercises_repository_test.dart`:
  **11 testów zaliczonych**, w tym test unikalności trójek PL i EN.
  Host nie udostępnia `flutter` w PATH; test wykonano w jednorazowym kontenerze
  istniejącego obrazu `fit-web:verified` (Flutter 3.35.4, Dart 3.9.2),
  z bieżącym plikiem danych i bieżącym plikiem testu podmontowanymi tylko do
  odczytu. Pozostały kod klienta pochodził z obrazu weryfikacyjnego.
- `git diff --check`: bez błędów.
