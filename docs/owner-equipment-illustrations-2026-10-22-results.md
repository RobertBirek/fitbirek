# Ilustracje sprzętu właściciela — komplet obrazów, 2026-10-22

**Zaakceptowano wizualnie i zapisano 12/12 nowych ilustracji**: `cw413.webp`–
`cw424.webp` w `assets/exercises/`. Początkowo wykonawca przyjął 11/12 i wstrzymał
cw421/03 z powodu niewidocznej dalszej dłoni. Niezależny przegląd `R/review.md`
oraz decyzja sesji nadrzędnej przyjęły /03: kontakt jest na miękkiej łydce,
z dala od Achillesa i kolana, a dalsza dłoń jest naturalnie zasłonięta, co nie
stanowi dowodu brakującej kończyny. **Nie potwierdzono wizualnie obu dłoni.**
Sesja nadrzędna skopiowała istniejący podgląd /03 jako `cw421.webp`; zmiana
decyzji nie wymagała nowego żądania API ani nowych kosztów.

Wszystkie wcześniejsze **412/412 assetów są identyczne bajtowo** według SHA-256
sprzed i po pracy. Łącznie obecnie **424 pliki WebP ćwiczeń**. Wynik **PASS**
dotyczy pokrycia ilustracjami i ich pochodzenia, nie publikacji katalogu,
testów Fluttera, wdrożenia ani certyfikacji sprzętu.

## Oddzielny odbiór integracji przez sesję nadrzędną

Po domknięciu obrazów: **21 focused testów Flutter PASS**, w tym ścisłe zbiory
424 ID/plików/manifestu i rzeczywiste dekodowanie wszystkich424 WebP512 oraz
6 testów integracji katalogu. Niezależny code-review integracji bez P0/P1/P2.
Pełna analiza: **No issues found**. Prywatny build web i generator offline PASS:
**501 plików /48 364 768B**, packageId
`dd7567f560fde5c5d00410fc29bdd3434a6243462901f3949a065e5889c21273`.
Parent sprawdził501/501 hashów i długości,424 obrazy zgodne bajtowo ze źródłami
i zachowanie pełnopakietowej zgody na ilustracje (nie są w CORE). Wcześniejsze
412 WebP porównano również bezpośrednio z HEAD. Nie uruchamiano nowego pełnego
Flutter suite dla tej delty samych obrazów/rejestru; nie raportujemy go jako PASS.
Znane ostrzeżenia opcjonalnego Wasm dry-run nie blokują builda JS/CanvasKit.
To lokalny niewydany kandydat bez zmiany wersji; produkcja1.23.0+39 bez zmian.

Po powyższym odbiorze użytkownik zatwierdził commit, push do main i publikację.
Przygotowano wersję **1.23.1+40**, wyłącznie web; metadata wersji generowana
z pubspec. Powyższy prywatny build501 opisuje odbiór sprzed podniesienia wersji,
nie finalny obraz wydania. Nowa pełna verification i audyt kandydata muszą
przejść przed przełączeniem produkcji. API i dane pozostają bez zmian.

Publikację zakończono: **1.23.1+40**, source `d409438`, web2026-10-22
13:03:57UTC, finalny audyt13:04:48UTC. Dockerverification1561PASS/1UTCskip,
Warsaw1PASS, analiza czysta;501/501 publicznych hashów i424 obrazów PASS.
Backup i isolatedrestore PASS, bez restartu API/sendera/PG/Caddy i bez DDL.
[Finalny raport wydania](releases/2026-10-22-illustrations-1.23.1-40.md).

## Metoda i dowody

Dowody poza repo: `/tmp/opencode/owner-equipment-illustrations-20261022/` (**R**).
Przeczytano `AGENTS.md`, oba working-set guides treningu i sprzętu właściciela,
rzeczywiste instrukcje cw413–424 w katalogu, `tools/owner_equipment_additions.py`
oraz poprzedni raport EZ i prompt cw409. Źródła i adaptacje opisuje
`R/storyboards.md`; nie przeprowadzano nowej weryfikacji publikacji w sieci.

`R/style.png` to lokalna konwersja `assets/exercises/cw256.webp`. Styl: kremowe
tło, mocne czarne kontury, ciemna odzież, twarz bez rysów. Pominięto pomarańczowe
efekty wzorca; szczególnie rolowanie nie sugeruje aktywacji mięśni, leczenia
lub gwarantowanej regeneracji. Bez napisów, liczb, strzałek i logo.

Początkowy brak klucza w środowisku okazał się nieaktualnym blokerem: po korekcie
użytkownika użyto zatwierdzonego historycznego źródła klucza wyłącznie w pamięci
i środowisku potomnego procesu. Bez ujawniania wartości, kopiowania klucza,
argumentów CLI zawierających sekret lub odczytu konfiguracji produkcji.

Każde żądanie: istniejący `tools/benchmark_exercise_images.py` z obowiązkowym
`--single-sunburst-medium`, jedno `gpt-image-2.5-sunburst`, `medium`, PNG1024,
n=1, świeży katalog próby. Bez `high`, `flare`, innego dostawcy, równoległych
płatnych wywołań lub automatycznych retry. Wykorzystano limit 18 żądań:
12 pierwszych prób i 6 ręcznych korekt po ocenie wizualnej. Generacja zatrzymana.

Każdy źródłowy PNG1024 i jego WebP512 odczytano indywidualnie przed następnym
żądaniem. Konwersja: `convert SOURCE -resize 512x512 -strip -quality 90 preview.webp`.
Tylko zaakceptowane podglądy skopiowano jako nowe assety: pierwsze 11 przez
wykonawcę, cw421/03 przez sesję nadrzędną po niezależnym przeglądzie. Każdy z 12
finalnych assetów odczytano ponownie indywidualnie. `identify` zdekodował wszystkie
18 źródeł jako PNG1024 i 18 podglądów oraz 12 finalnych assetów jako WebP512.
Końcowa kontrola potwierdziła zgodność cw421.webp bajt w bajt z podglądem /03
oraz niezmienione SHA-256 wszystkich 412 wcześniejszych obrazów.

Pliki dowodowe: `R/before.json`, `R/verification.json`, `R/provenance.json`,
`R/review-table.md`. Każdy katalog `R/cwNNN/trial-TT/` zawiera źródło
`cwNNN-gpt-image-2.5-sunburst-medium.png`, `preview.webp`, dokładny `prompt.txt`
użyty w próbie i oryginalny `ledger.jsonl`. Hashe promptów sprawdzono z ledgerem.

## Ocena wybranych źródeł

| ID | TT | Ocena techniki i czytelności 512 | Request ID | USD |
|---|---|---|---|---:|
| cw413 | 01 | boczne wejście, stopa w całości, potem obie na stepie; nie wejście przodem | req_8d26a2e7fce84166a1f3f0b01b808fbf | 0.023302 |
| cw414 | 01 | 4 kadry: góra → pięta → obie stopy/ciężar na podłodze → osobne wejście-reset | req_6889175a8165441fbc4cd75b045289d5 | 0.023612 |
| cw415 | 01 | dłonie na stepie, stopy na podłodze, spójna linia ciała | req_a931b01866b44daf901c591a72401d37 | 0.023367 |
| cw416 | 02 | małe spięcie głowy/łopatek, lędźwie i miednica podparte, wydłużony pad | req_5cf4f584f67445d1851fb20811219ed1 | 0.023617 |
| cw417 | 01 | pełny siad przez zgięcie bioder, wyraźnie większy zakres niż cw416 | req_814d4a812c034c19bdb96040a9cd9298 | 0.023487 |
| cw418 | 01 | osobna solidna ławka do wyciskania, podparte głowa/plecy/miednica, blokada nóg, dwa hantle | req_98ad5b74ba18455f88bb4d7298a43fb8 | 0.023717 |
| cw419 | 01 | wejście i stanie obunóż na niskim dysku, stabilne krzesło; lekki kontakt dłoni pozostaje | req_29261a88e9084ecebafd5a2aa14f9d45 | 0.023452 |
| cw420 | 02 | ta sama prawa noga podporowa w obu kadrach, lewa stopa uniesiona, krzesło obok | req_056d0e9e037f4910b02141c97bcc80db | 0.024057 |
| cw421 | 03 | przyjęte po niezależnym review i decyzji parenta; miękka łydka z dala od Achillesa/kolana, dalsza dłoń zasłonięta | req_035d360b1c174ae1979ceff367f88599 | 0.024062 |
| cw422 | 02 | jeden roller pod środkiem prostego uda, z dala od rzepki/pachwiny; podpór na przedramionach | req_2ca65179dd8349efab6f4f48325f2be1 | 0.024177 |
| cw423 | 02 | obie dłonie i stopy na podłodze, delikatny jednostronny nacisk pośladka; bez figure-four | req_5432d35773194efda88dc5db7b3f5697 | 0.024162 |
| cw424 | 01 | objęty worek, rozpoznawalna pozycja chodu po płaskim, bez stepu/etykiety masy; naprzemienność nie jest bezsporna | req_4191968f93b64b9fa2679faff7cfb81b | 0.023532 |

## Odrzucenia i historia decyzji o łydce

- cw416/01: głowa poza końcem pada mimo poprawnego krótkiego zakresu spięcia.
- cw420/01: zmiana nogi podporowej i położenia dysku między kadrami.
- cw421/01: dalsza ręka/dłoń całkowicie zasłonięta.
- cw421/02: obie dłonie widoczne, ale kontakt zbyt nisko na łydce, aby pewnie
  ocenić odsunięcie od Achillesa w 512 px; do niezależnej decyzji, nie zaakceptowano.
- cw421/03: początkowo wstrzymane mimo lepszego kontaktu z miękką łydką
  i wyraźnej przerwy przy kostce, ponieważ dalsza dłoń ponownie ukryta.
  **Następnie zaakceptowane** przez niezależny review i sesję nadrzędną:
  zasłonięcie jest geometrycznie wiarygodne, nie świadczy o brakującej ręce.
  Dokładne miejsce oparcia dalszej dłoni pozostaje niewidoczne; instrukcja
  tekstowa nadal wymaga podparcia obiema dłońmi. To zmiana decyzji oceniających,
  nie nowa generacja ani usunięcie pierwotnego zastrzeżenia.
- cw422/01: cylinder jak mankiet wokół zgiętego kolana i dodatkowy odłączony roller.
- cw423/01: dalsza dłoń niewidoczna, brak możliwości sprawdzenia obu podpór.

Początkowo: 11 zaakceptowanych i 7 odrzuconych/wstrzymanych źródeł.
Ostatecznie: **12 zaakceptowanych, 6 odrzuconych/wstrzymanych źródeł**,
w tym odrzucone cw421/01 i /02. Limit 18 żądań nie został przekroczony;
po przeglądzie nie wykonywano żadnego nowego wywołania API.

## Koszt i ograniczenia

**18 rzeczywistych żądań, 18 `success`, 18 unikalnych request ID, 0 błędów API,
0 `uncertain`, 0 nieznanych kosztów.** Suma kosztów końcowych zdarzeń `success`,
deduplikowanych po request ID: **0.425721 USD (`upper_bound_no_cache`)**.
To górne oszacowanie tokenowe, nie faktura; obejmuje również odrzucone próby.

Kadry nie dowodzą tempa, oddychania ani stanu otwartych oczu w faceless stylu.
Instrukcje tekstowe pozostają konieczne. Lekki kontakt dłoni z krzesłem przy
cw419 jest widoczny, nie udawano stania bez podparcia. Ławka na cw418 nie
certyfikuje sprzętu właściciela: jego ławka do brzuszków nadal nie jest
zweryfikowana do wyciskania z hantlami. Worek na cw424 nie wyznacza uniwersalnej
masy startowej i nie ma oznaczenia 20 kg. Kadry cw424 pokazują podobne momenty
kroku: nie dowodzą bezspornie naprzemienności nóg ani pełnego cyklu chodu.
Na cw421 dalsza dłoń jest zasłonięta; ilustracja nie potwierdza wizualnie
wszystkich podpór i wymaga towarzyszącej instrukcji tekstowej.

Zakres wykonawcy zmienił 11 nowych assetów i niniejszy raport w repo; dwunasty
asset (cw421) zainstalowała sesja nadrzędna. Domknięcie raportu/provenance nie
zmieniało assetów, katalogu, rejestru, wersji, kodu ani testów. Integracja i
testy Fluttera należą do sesji nadrzędnej; raport nie przypisuje im wyniku.
Nie wykonywano commita, pusha, wdrożenia ani zapisu danych produkcji.
Brak pracy generującej w tle. Komplet obrazów nie oznacza publikacji.
