# Domknięcie ilustracji — rejestr wykonania

Zgoda użytkownika: wszystkie brakujące cw157–cw250, samodzielny dobór scen
i korekt. Realizacja lokalna; bez wydania. Bezpośredni przegląd źródła1024
i podglądu512 przed następnym żądaniem, nie niezależne review.
Źródła i ledgery w `/tmp/opencode/cwNNN-PRÓBA/`; dokładne prompty obok,
w `/tmp/opencode/cwNNN-PRÓBA-prompt.txt`. Źródła PNG mają nazwę
`cwNNN-gpt-image-2.5-sunburst-medium.png`.
Finalne WebP: 512×512, strip, quality90.

| Zakres | Zaakceptowane źródła | Kadry | Uwagi |
|---|---|---|---|
| cw157–cw162 | trial-01 dla wszystkich | 2/2/2/2/2/3 | Hip thrust prawa podpora/lewa noga w powietrzu; frog pump podeszwami razem; donkey kick; fire hydrant; clamshell; jeden cykl kroku bocznego z gumą nad kolanami. |
| cw163–cw168 | correction-01 cw165, pozostałe trial-01 | 2/2/2/2/2/2 | Wspięcia obunóż/jednonóż/z krawędzi/w siadzie/w opadzie; tibialis z piętami na podłodze. Korekta cw165 odsłoniła pięty poza krawędzią ławki. |

## Sceny, zaakceptowane źródła i adaptacje

cw229–cw250: trial-01 poza cw229/cw230/cw246=correction-01 oraz reuse:
cw238←cw236, cw239/cw240←cw234. Ruch/sprzęt bieżni zgodny, zmiany tempa,
czasu, tętna i piramida pozostają w opisach, nie na fikcyjnym wyświetlaczu.
Kadry:229:2,230:2,231:1,232:1,233:1,234:1,235:1,236:2,237:1,
238:2,239:1,240:1,241:1,242:3,243:2,244:2,245:3,246:1,247:3,
248:1,249:2,250:2.
Skakanka jeden ciągły sznur bez duchów ruchu; dwukrotny obrót231/233
opisuje katalog, ilustracje pokazują wyższy skok. Korekty229/230 dodały
punkt odniesienia podłogi dla przesunięć. W cw246 jedna faza wykroku ze
skrętem zamiast dwóch zwykłych wykroków. Cat/cow, wykrok z rotacją i
spiderman bez modyfikacji danych katalogowych. Finalne WebP zgodne bajtowo
z odczytanymi podglądami512. Zakończono wszystkie94 brakujące pozycje.

cw205–cw228: trial-01 poza cw207/cw208/cw212/cw218/cw221=correction-01,
cw224=correction-02 i poniższymi adaptacjami. Kadry:
205:2,206:2,207:1,208:2,209:4,210:4,211:4,212:4,213:2,214:3,
215:1,216:1,217:2,218:2,219:4,220:3,221:3,222:4,223:1,224:1,
225:2,226:1,227:1,228:1.

Reuse bez API: cw206←cw119 (ten sam chód farmera), cw211←cw209 (ta sama
sekwencja z wyskokiem, nacisk na wysokość pozostaje w opisie),
cw217←cw208 (ten sam mountain climber), cw219←cw212 (ten sam squat thrust).
Burpee209/210 wybrane cztery pionowe kolumny zamiast zamierzonych pasów;
cw212 korekta do kolumn usunęła miniaturową postać w ostatniej fazie.
Korekty: cw207 jedna scena zamiast duplikatu; cw208 baza→przyciągnięcie kolana;
cw218 kolano prowadzone pod tułowiem do przeciwnego łokcia;
cw221 odsłonięcie całych dłoni; cw224 chwyt/palce oraz diagonalna praca kończyn.

Lokalne adaptacje bez API/anatomicznego retuszu:
- cw215/cw216: powtórzona faza zastąpiona jednym pełnym kadrem. Źródło
  `/tmp/opencode/cwNNN-approved-single.png`, komenda:
  `convert SOURCE -crop 500x1024+0+0 +repage -virtual-pixel edge -define distort:viewport=1024x1024-262+0 -distort SRT 0 +repage DEST`.
  Cały wycinek w skali100%, rozszerzono wyłącznie kremowe tło, bez deformacji.
- cw220: ostatni frontalny kadr odbity w poziomie dla przeciwnej nogi podporowej:
  `convert SOURCE \( +clone -crop 324x1024+700+0 +repage -flop \) -geometry +700+0 -composite /tmp/opencode/cw220-approved-alternating.png`.
  Stała frontalna kamera i podłoga; bez sprzętu lub tekstu do odwrócenia.

Odczytano lokalne wyniki512; finalne WebP zgodne z nimi bajtowo.

cw193–cw204: trial-01 poza cw194/cw196/cw204=correction-01.
Kadry3/2/2/2/2/2/2/2/3/2/1/2. Russian twist z hantlem: jeden skręt i powrót
do środka zamiast powtórzonej fazy. Pallof: obie dłonie na jednym uchwycie.
Dragon flag poprawiony z błędnego podporu tyłem na rzeczywistą podporę
górnych pleców z chwytem ławki za głową i uniesioną linią tułów–nogi.
L-sit na niskich poręczach; interpretacja dopuszczonego podporu na drążkach.
Finalne WebP bajtowo zgodne z odczytanymi podglądami.

cw181–cw192: zaakceptowane trial-01 poza cw181=correction-01,
cw182=new-02, cw192=correction-02. Kadry2/1/1/2/1/2/2/2/2/2/2/1.
Bird dog wymagał doprecyzowania przeciwstawnych kończyn. Cw182: trial-01,
correction-01 oraz new-01 i jego correction-01 odrzucone za zmianę podpór;
nowa pojedyncza scena frontalna pokazuje przeciwny łokieć/kolano bez zmiany
podpory. Bicycle: korekta do jednej fazy i odsłonięcie obciętego łokcia.
Naprzemienność pozostaje w opisie. Finalne WebP identyczne z odczytanymi
podglądami (cmp). Bez dodatkowych żądań w tle.

cw169–cw180: zaakceptowane trial-01 poza cw174=new-01, cw178=correction-01,
cw179=correction-02, cw180=correction-01. Kadry1/1/1/2/2/2/3/2/2/1/2/2.
Po dwóch nieskutecznych korektach naprzemiennych shoulder taps nowa kompozycja
cw174 pokazuje bazę i jeden poprawny dotyk; naprzemienność pozostaje w opisie.
Korekta Copenhagen przesunęła podporę z piszczeli pod wewnętrzną część uda
przy kolanie (wariant krótkiej dźwigni). Korekty deadbug odsłoniły ramię
po przeciwnej stronie do prostowanej nogi. Finalne cw169–cw180 są bajtowo
identyczne z odczytanymi podglądami WebP (cmp).

## Kontrola kosztów i weryfikacja

Odczytano115 ledgerów; wszystkie zakończone success,115 unikalnych request_id,
bez błędów HTTP/niepewności/nieznanych kosztów. Suma wyłącznie success,
response_received pominięte przy agregacji. 87 bazowych generacji, 3 nowe
kompozycje i25 korekt; 7 reuse bez API. Kwoty upper_bound_no_cache to
szacunki bez cache, nie rozliczenie dostawcy.

| Partia | Zakres | Żądania success | USD |
|---|---|---:|---:|
|31|cw157–cw162|6|0.134102|
|32|cw163–cw168|7|0.155409|
|33|cw169–cw174|9|0.199383|
|34|cw175–cw180|10|0.222105|
|35|cw181–cw186|11|0.244142|
|36|cw187–cw192|8|0.176916|
|37|cw193–cw198|8|0.177276|
|38|cw199–cw204|7|0.155104|
|39|cw205–cw210|7|0.154859|
|40|cw211–cw216|6|0.132457|
|41|cw217–cw222|6|0.132602|
|42|cw223–cw228|8|0.177121|
|43|cw229–cw234|8|0.177301|
|44|cw235–cw240|3|0.066516|
|45|cw241–cw246|7|0.155134|
|46|cw247–cw250|4|0.088908|
|**Suma**|**94 pozycje**|**115**|**2.549335**|

Pełna weryfikacja Docker `fit-web:illustrations-complete`: wersja poprawna,
analiza0,366testów zaliczonych (w tym dekodowanie316 obrazów512×512).
Log `/root/.local/share/opencode/tool-output/tool_141d83e80001biO0U9xvWXpFpL`.
Test dodatkowo porównuje rejestr z rzeczywistymi ID katalogu, fallbackcw317.
Po poprawieniu wyłącznie formatowania castu w teście: format2plików0zmian.
Dodatkowy focused test na finalnie sformatowanym pliku:14/14 zaliczonych.
Końcowy audyt:316 zgodnych ID katalog/rejestr/test/assety/tabela,94 nowe
nazwy tabeli zgodne z katalogiem;204 wydane WebP bajtowo bez zmian względemHEAD.
94 dodane pliki mają512×512 iłącznie1305120 bajtów. Siedem reuse potwierdzone
bajtowo. Katalog, wersja, zależności iWebSQLite bez zmian; git diff --check czysty.
Publiczne version.json potwierdza1.10.0/build23, APIhealthstatusok.
Produkcja pozostaje1.10.0+23 /204 wydane, komplet316 lokalny /112 niewydanych.
