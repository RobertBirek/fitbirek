# Ilustracje cw370–cw408 — wynik 2026-10-20

Dodano 39 nowych plików `assets/exercises/cw370.webp`–`cw408.webp`.
Bez reuse, zmian wcześniejszych 369 assetów, katalogu, wersji ani wdrożenia.
Integrację rejestru/testów i pełną weryfikację aplikacji zakończono lokalnie;
wyniki końcowe znajdują się poniżej.

## Metoda i dowody

Źródła, dokładne prompty, poprawki i ledgery pozostają poza repozytorium:
`/tmp/opencode/illustrations-20261020-sunburst-39` (dalej **R**).
Referencja `R/style.png` została skonwertowana z istniejącego `cw256.webp`.
Każde żądanie: `tools/benchmark_exercise_images.py --single-sunburst-medium`,
OpenAI Sunburst medium, jedno PNG 1024×1024, świeży katalog `trial-NN`.
Wyłącznie pojedyncze żądania, bez równoległej generacji i automatycznych retry.
Poprawki używały wyłącznie ostatniego odrzuconego PNG; po dwóch nieskutecznych
próbach kompozycji zmieniono scenę (`cw388`, `cw392`, `cw402`, `cw406`).

Dla każdego żądania odczytano indywidualnie źródłowe PNG i WebP512 przed
następnym żądaniem. Każdy zaakceptowany finalny WebP odczytano ponownie po
umieszczeniu w `assets/exercises/`. Nie stosowano zbiorczego autozatwierdzania.
Konwersja: `convert SOURCE -resize 512x512 -strip -quality 90 PREVIEW.webp`,
następnie kopia zaakceptowanych bajtów do docelowego assetu.
`identify` zdekodował wszystkie 39 plików jako WEBP 512×512.
`git diff --name-only HEAD -- assets/exercises/` nie wykazał zmian śledzonych
wcześniejszych assetów (nowe pliki pozostają nieśledzone do commita).
Końcowe porównanie bajtów każdego `cw001–cw369` z `git show HEAD:PATH`
potwierdziło 369/369 identycznych plików. Wszystkie 39 zaakceptowanych PNG
zdekodowano jako 1024×1024; końcowe WebP są identyczne bajtowo z odczytanymi
podglądami.

Styl: kremowe tło, czarne komiksowe kontury, twarze bez rysów, ciemna odzież,
bez napisów, strzałek i duchów. Zadania partnerskie mają dwie osoby w każdym
kadrze, konsekwentne role i sprzęt. Obrazy pokazują wybrane fazy, nie kodują
tempa, oddechu, czasu, zmiany stron ani wszystkich instrukcji bezpieczeństwa.
W `cw386` różnice obręczy są subtelne; kierunek pełnego krążenia pozostaje
w tekście. `cw389` pokazuje także fazę przenoszenia/lądowania stopy, nie tylko
ustalone pozycje tandemowe. `cw392` świadomie używa zbliżenia lewej stopy.
`cw402` wymagało oddalonego ujęcia z góry dla czytelnego równoległego ruchu.
`cw406` używa tylnego ujęcia dla czytelności gumy poniżej pach.

## Rejestr zaakceptowanych obrazów

Dla wiersza `cwNNN`, źródło to
`R/cwNNN/trial-TT/cwNNN-gpt-image-2.5-sunburst-medium.png`, ledger to
`R/cwNNN/trial-TT/ledger.jsonl`; oryginalny prompt: `R/cwNNN-prompt.txt`,
poprawki: `R/cwNNN-correction-TT.txt`. Koszt w tabeli sumuje **wszystkie**
próby danego ID, także odrzucone wizualnie, nie tylko zaakceptowane źródło.

| ID | Kadry | Scena | TT | Request ID zaakceptowanego źródła | Suma USD |
|---|---:|---|---|---|---:|
| cw370 | 2 | Siad na stabilnym krześle przy ścianie → stanie | 01 | req_9ba63aa330e048d6be03337a6397938a | 0.022412 |
| cw371 | 2 | Podparcie o krzesło, prosta noga w bok | 01 | req_425ce60b08674cdc8fee8a37dea4989b | 0.022402 |
| cw372 | 2 | Podparcie o krzesło, mały wyprost biodra w tył | 01 | req_924b76c15fe4407bb638d11d5e205aa8 | 0.022382 |
| cw373 | 2 | Leżenie bokiem, dolne kolano ugięte, górna noga unoszona | 01 | req_806dc3752f6f4fafb8e0d21e4f179bd8 | 0.022417 |
| cw374 | 2 | Górna stopa przed ciałem, unoszenie dolnej prostej nogi | 01 | req_a90de5a1254c4af4804233d738cc33c4 | 0.022472 |
| cw375 | 2 | Leżenie przodem, uginanie kolana, guma do niskiej kotwy za stopami | 01 | req_0058c5292f0a4c5abc18d9ec5ea36a86 | 0.022522 |
| cw376 | 2 | Udo na krześle, wyprost kolana przeciw gumie zakotwionej z tyłu | 01 | req_15d9202080b746b99840b0b845181b1b | 0.022497 |
| cw377 | 2 | Zawias → pion, guma między nogami do kotwy z tyłu | 01 | req_563cc87fcfc34d69a63505306d84d21d | 0.022512 |
| cw378 | 2 | Noga bliższa kotwie przyciągana do środka, podparcie o krzesło | 01 | req_7fc71adc8d3e4a3bb04ad8c1ca5fa18a | 0.022487 |
| cw379 | 2 | Most z piętami na dwóch ślizgaczach, odsunięcie pięt | 01 | req_81c39cb60ef241b69aeadbb0f68504f1 | 0.022477 |
| cw380 | 2 | Setka: ugięte nogi, stopy podparte, małe ruchy ramion | 01 | req_1951fc07d42b41adad57e03db3ab9ab3 | 0.022502 |
| cw381 | 3 | Leżenie, małe fazy koła uniesioną nogą | 01 | req_3c5920d078344dd69a6df6bd304d0b4c | 0.022492 |
| cw382 | 2 | Zamiana ugiętej nogi i wysoko wydłużonej przeciwnej | 02 | req_e8f0f014aa1641aa8f0b9cfa1dc310e7 | 0.044499 |
| cw383 | 3 | Przybliżenie kolan → wysokie wydłużenie → powrót ramion | 01 | req_13d8a94eb5bf40d78e7e24ebe00d546e | 0.022532 |
| cw384 | 3 | Siad rozkroczny → przeciwna dłoń do stopy → pion | 02 | req_e7239d99fe334f9d9612a2e8bdcacad6 | 0.044479 |
| cw385 | 2 | Łopatki w klęku podpartym, proste łokcie | 02 | req_6c99a7a05f6945eea6b7262692fa2299 | 0.044579 |
| cw386 | 3 | Małe fazy obręczy barkowej w klęku, stałe podpory | 01 | req_786cf454932742c0861eed018f4ec17d | 0.022552 |
| cw387 | 2 | Jedna noga w bok, biodra cofane ku pięcie podporowej | 01 | req_c0199d988b0040e68e09fd899181df44 | 0.022512 |
| cw388 | 1 | Tandem pięta przed palcami, dłoń na krześle | 03 | req_7a73d8b7762a42cba0f5fbfc953cae19 | 0.066526 |
| cw389 | 3 | Tandem, przeniesienie stopy i kolejny krok przy ścianie | 02 | req_d09c0c86446a44439b1ed9ec5fa4030a | 0.044634 |
| cw390 | 2 | Zbliżenie bosej stopy, palce marszczą ręcznik | 01 | req_7dfe562b47374fbdb39b2588925705a3 | 0.022522 |
| cw391 | 2 | Zbliżenie łuku: rozluźnienie → krótka stopa bez zawijania palców | 01 | req_4410347b06b04caeb1e94ae4d265b8a9 | 0.022542 |
| cw392 | 2 | Podparta lewa pięta, ewersja przeciw przyśrodkowej kotwie | 03 | req_1a621e014b6947a196e87173dd4b1d77 | 0.066986 |
| cw393 | 2 | Dwie deski naprzeciw, lekkie zetknięcie dłoni | 01 | req_ed6981a9ec2d4aa89caf06f8666e2e21 | 0.022702 |
| cw394 | 2 | Plecy w kontakcie, stanie → ograniczony przysiad | 02 | req_d6e953b9a38b4eb4b88dc657e501a5c7 | 0.044584 |
| cw395 | 3 | Lustro: gotowość, krok, przysiad; otwarte rozluźnione dłonie | 02 | req_aa8d45da86444199b6b0397ff58ce053 | 0.044624 |
| cw396 | 3 | Gest prowadzącego, krok B, powrót B do środka | 02 | req_96ece61e06884359908f87700f60964c | 0.044544 |
| cw397 | 3 | Upuszczenie piłki, kontakt z podłożem, chwyt po odbiciu | 02 | req_a94b44d0653f44ecb4a3718382bf5d55 | 0.044529 |
| cw398 | 3 | A podaje, B robi krok boczny i chwyta piłkę | 01 | req_16470534ecdb475db01d4b58dc3d03b0 | 0.022772 |
| cw399 | 2 | Oboje na jednej nodze, łagodne podanie i chwyt | 01 | req_931ce294debc458e92debd39f17e7a30 | 0.022742 |
| cw400 | 2 | Piłka przy klatce A → chwyt przy klatce B | 01 | req_dc9ad57573564c2589ff4a8aae612637 | 0.022687 |
| cw401 | 3 | Wykrok A, powrót i chwyt B, wykrok B z podaniem | 01 | req_27e0667da533447bb94d7291455566e8 | 0.022782 |
| cw402 | 3 | Oboje przemieszczają się równolegle z podaniem, widok z góry | 03 | req_37ca4fbb08394440a79876a97d9c6d68 | 0.067236 |
| cw403 | 3 | Wspólny przysiad, stanie, bezpośrednie przekazanie piłki | 01 | req_6d32ac5f1e294fa8981c6a2b95e69d71 | 0.022707 |
| cw404 | 3 | Siad plecami do siebie, przekazanie z boku, piłka u B | 01 | req_4f8b31a659044cfba96638d2242de80d | 0.022782 |
| cw405 | 2 | A trzyma środek gumy, B w wykroku wiosłuje dwoma uchwytami | 01 | req_7d5edf10982d44c3b18d7282fe84f81a | 0.022762 |
| cw406 | 2 | A z tyłu stabilizuje gumę, B wyciska, ujęcie tylne | 04 | req_8ab4c1c41ab2455bb2b934105e9f9c7e | 0.088913 |
| cw407 | 2 | A kotwi z boku, B prowadzi dłonie krótko po skosie ku biodru | 01 | req_d3edc9b5bfc94c54a1fe18e256345e01 | 0.022797 |
| cw408 | 3 | Jedna dłoń każdej osoby na dużej piłce, półprzysiad i krok | 01 | req_d84ef31f6a404ac7a5df7b4c1a03f973 | 0.022867 |

## Odrzucone próby i korekty

Każdy poniższy numer próby ma własny ledger ze statusem API `success`,
request ID, licznikami tokenów i szacunkiem kosztu. Odrzucenie jest oceną
wizualną, nie błędem API. Źródeł nie usuwano.

- `cw382/01`: obie fazy bez zamiany nóg; poprawiono przypisanie nóg w drugim kadrze.
- `cw384/01`: sięganie ręką do stopy tej samej strony; poprawiono przeciwną rękę.
- `cw385/01`: nadmierna praca kręgosłupa/szyi; ograniczono do łopatek.
- `cw388/01–02`: krzyżowanie/zasłonięcie stóp zamiast tandemu; nowa kompozycja
  z wyraźnie widocznymi dwiema stopami ustawionymi wzdłuż jednej linii.
- `cw389/01`: zwykły za długi krok; korekta tandemu i fazy przenoszenia.
- `cw392/01–02`: kotwa po niewłaściwej stronie dla ewersji; nowe zbliżenie
  lewej stopy i kotwa przyśrodkowa.
- `cw394/01`: zbyt głęboki przysiad; zmniejszono głębokość.
- `cw395/01`: zamknięte uniesione dłonie/pozycja walki; rozluźniono dłonie i ruch.
- `cw396/01`: garda odbierającego; zastąpiono otwartymi rozluźnionymi dłońmi.
- `cw397/01`: dwa znaki odbicia obok piłki; usunięto znaki ruchu.
- `cw402/01–02`: zbieganie się osób zamiast równoległego przesuwania;
  nowa kompozycja na dwóch torach w głąb kadru, wspólne przesunięcie boczne.
- `cw406/01–02`: nieczytelny zbyt wysoki przebieg gumy; zmiana na tylne ujęcie.
  `cw406/03`: ucięta stopa kotwiącego; oddalono kadr w próbie04.

## Koszt i granice weryfikacji

56 żądań, 56 `success`, 56 unikalnych request ID; 39 zaakceptowanych źródeł,
17 odrzuconych wizualnie. Brak błędów API, brak kosztów nieznanych.
Suma ostatnich zdarzeń `success` deduplikowanych po request ID:
**1.255967 USD (`upper_bound_no_cache`)**. To szacunek górny na podstawie
tokenów, nie potwierdzone rozliczenie dostawcy. Wszystkie żądania zakończono;
nie zadeklarowano dalszej pracy w tle.

Sprawdzono dekodowanie 39 końcowych WebP512 i niezmienność śledzonych starszych
assetów. Zadanie generowania nie uruchamiało testów ani wdrożenia.

## Końcowa integracja i weryfikacja

- Dokładna zgodność katalog/rejestr/pliki: **408/408/408**, wszystkie WebP 512×512.
- Katalog, wersja, lockfile, artefakty Web SQLite i wcześniejsze 369 ilustracji
  pozostały bez zmian. Dowody: `/tmp/opencode/illustrations-20261020-verification`.
- TDD RED przed rozszerzeniem rejestru: brak `cw370`, log
  `/tmp/opencode/exercise-illustrations-registry-red.log`.
- `docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:illustrations-408-verified .`:
  **1346 testów PASS**, analiza bez problemów, kontrola wersji i generowanie kodu
  zakończone poprawnie. Log: `docker-verification.log` w katalogu dowodów.
- Niezależny przegląd: wszystkie 39 grafik na pięciu planszach i 13 krytycznych
  indywidualnie, porównane z instrukcjami; brak HIGH/MEDIUM. Rejestr i testy
  również bez HIGH/MEDIUM. Ograniczenia statycznego obrazu opisane powyżej
  pozostają aktualne; `cw397` wymaga tekstu dla dynamiki odbicia.
- Bilans: **408 lokalnych / 369 wydanych / 39 niewydanych / 0 brakujących**.
  Bez commita, pusha, zmiany wersji i wdrożenia.
