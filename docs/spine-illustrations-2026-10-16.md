# Ilustracje Kręgosłup: cw364–cw369 — 2026-10-16

## Wynik lokalny

6 nowych zaakceptowanych ilustracji, łącznie 11 kadrów. Lokalny katalog:
**369 rekordów / 369 WebP / 369 ID rejestru**, w tym **363 wydane wcześniej,
6 lokalnych niewydanych, 0 brakujących**. Bez commita, zmiany wersji, pushu
i wdrożenia. Nie zmieniano danych ćwiczeń ani bazy użytkownika.

Przed generacją przeczytano `AGENTS.md`, `docs/modules/training.md`,
`tools/SPINE_EXPANSION.md` (w tym frame focus) i pełne rzeczywiste rekordy
`cw364–cw369` w `assets/data/exercises.json`. Merytoryczne źródła pochodzą
z tego przekazania i rejestru `tools/source_data/catalog_sources.json`;
w tym etapie nie wykonano ponownego researchu medycznego.

## Zaakceptowane pliki i przegląd

Źródła PNG mają 1024×1024, finały WebP 512×512. Każde źródło i jego
`review-512.webp` odczytano narzędziem Read przed kolejnym płatnym żądaniem.
Przegląd wizualny wykonał ten sam agent, który generował ilustracje;
nie był to niezależny przegląd ani ocena kliniczna.

| ID | Kadry | Zaakceptowany PNG 1024 | Finalny asset | Źródło ruchu / ocena w 512 |
|---|---:|---|---|---|
| cw364 | 2 | `/tmp/opencode/cw364-trial-01/cw364-gpt-image-2.5-sunburst-medium.png` | `assets/exercises/cw364.webp` | `cuh_back` §7, uzupełnienie `nhs_inform_back`: subtelna zmiana ustawienia miednicy, pośladki stale na podłożu, ugięte kolana i oparte stopy; brak mostu. |
| cw365 | 1 | `/tmp/opencode/cw365-correction-01/cw365-gpt-image-2.5-sunburst-medium.png` | `assets/exercises/cw365.webp` | `aaos_spine` §10, `cuh_back` §5: głowa i barki leżą, ręce przy ciele widoczne, obie stopy oparte; brak crunchu i ruchu kończyn. Obraz nie dowodzi normalnego oddechu ani siły napięcia — te wskazówki pozostają w tekście katalogu. |
| cw366 | 3 | `/tmp/opencode/cw366-correction-01/cw366-gpt-image-2.5-sunburst-medium.png` | `assets/exercises/cw366.webp` | `cuh_back` §3, `nhs_inform_back`: lewo–środek–prawo, stałe barki, kolana razem i ugięte, stopy przy podłożu/przetaczane na krawędzie, bez dociskania ręką. |
| cw367 | 2 | `/tmp/opencode/cw367-trial-01/cw367-gpt-image-2.5-sunburst-medium.png` | `assets/exercises/cw367.webp` | `leeds_open_book` §1: leżenie bokiem, otwarcie górnej ręki i klatki; kolana nadal razem podparte, dolna ręka z przodu, głowa na poduszce. Zgięcie nóg łagodniejsze niż 90° sugerowane w promptcie, ale zgodne z opisem ugiętych bioder/kolan; brak pociągania kolan. |
| cw368 | 1 | `/tmp/opencode/cw368-trial-01/cw368-gpt-image-2.5-sunburst-medium.png` | `assets/exercises/cw368.webp` | `nhs_inform_back`, kontekst `aaos_spine` §5: chwyt za tył uda (regresja opisana w rekordzie), druga noga wyraźnie ugięta ze stopą płasko na podłodze; głowa i barki leżą. |
| cw369 | 2 | `/tmp/opencode/cw369-trial-01/cw369-gpt-image-2.5-sunburst-medium.png` | `assets/exercises/cw369.webp` | `peakrx_hip_hinge`, Butt taps: stanie → biodra cofnięte do widocznego kontaktu ze ścianą, niewielkie ugięcie kolan, neutralny pochylony tułów; nie przysiad. |

Pełne postaci mieszczą się w kadrach, bez przycięcia dłoni/stóp/podpór;
nakładanie kończyn w profilu jest naturalną okluzją. Kremowe tło, ciemne
ubrania, postać bez rysów twarzy, komiksowy kontur. Brak tekstu, liczb,
strzałek, timerów, duchów ruchu i znaków wodnych. Referencja stylu:
`assets/exercises/cw256.webp`, PNG `/tmp/opencode/cw256-reference.png`.

### Odrzucone próby i korekty

- `cw365-trial-01`: dalsza ręka całkowicie ukryta; nie można ocenić jej
  ułożenia. Korekta 01 odsłoniła obie ręce przez bardziej podniesioną kamerę.
- `cw366-trial-01`: zmienna kamera/orientacja tułowia między pasami utrudniała
  ocenę stałych barków; zbyt ciasny margines nad głową. Korekta 01 ustaliła
  widok od stóp i stałą oś barków, zachowując całą postać wewnątrz obrazu.

Każda korekta używała ostatniego odrzuconego PNG jako **jedynej referencji**
i nowego katalogu wyjściowego. Pozostałe cztery ilustracje zaakceptowano
po pierwszej próbie. Nie było drugich korekt ani automatycznych retry.
Wszystkie katalogi, prompty i ledgery zachowano w `/tmp/opencode`.

## Generacja i koszt

Wywołania pojedyncze przez `/tmp/opencode/fit-generate-one.sh`, narzędzie
`tools/benchmark_exercise_images.py --single-sunburst-medium`:
`gpt-image-2.5-sunburst`, medium, 1024×1024 PNG, `n=1`.
Klucz ładowany z pliku środowiskowego; nie drukowano sekretów.

Sumowanie wyłącznie zdarzeń **success**, deduplikacja po `request_id`.
`response_received` opisuje te same żądania i nie jest liczony drugi raz.
Wszystkie kwoty są estymatą `upper_bound_no_cache`, nie fakturą.

| Próba | request_id (success) | USD | Ocena |
|---|---|---:|---|
| cw364-trial-01 | `req_6713791377fa4829a3564b623caef6d4` | 0.022792 | akceptacja |
| cw365-trial-01 | `req_4f722b23b40445229113d76bd1536bc5` | 0.022627 | odrzucona wizualnie |
| cw365-correction-01 | `req_162d2c3c38db4fd9a4cb239bd90ba489` | 0.022382 | akceptacja |
| cw366-trial-01 | `req_cfd0eceef8184b72b7d5b5419c59bad1` | 0.022822 | odrzucona wizualnie |
| cw366-correction-01 | `req_4025155c371b4234b49521697b7aa10c` | 0.022687 | akceptacja |
| cw367-trial-01 | `req_ac5621762cb0430c9e1653310c5809b0` | 0.022897 | akceptacja |
| cw368-trial-01 | `req_fe0b76d5e50b4efa85200c365568d9f8` | 0.022642 | akceptacja |
| cw369-trial-01 | `req_eb03ad38418642959d6e816c78cac178` | 0.022917 | akceptacja |

**8 unikalnych sukcesów API, 0 błędów HTTP/sieci, 0 nierozstrzygniętych
żądań. Łącznie 0.181766 USD**, w tym 0.045449 USD na dwie odrzucone próby.
Nie ma żądań z nieznanym kosztem; nie utożsamiamy nieznanego kosztu z zerem.

## Konwersja i dowód tożsamości podglądu

Każdy zaakceptowany PNG przekonwertowano:

```sh
convert SOURCE.png -resize 512x512 -strip -quality 90 assets/exercises/ID.webp
cmp ACCEPTED_DIRECTORY/review-512.webp assets/exercises/ID.webp
```

Wszystkie sześć `cmp` zakończyło się kodem 0. `identify` potwierdził WebP
512×512. SHA-256 finału i ocenionego podglądu są identyczne:

| ID | SHA-256 finalnego WebP i review-512.webp |
|---|---|
| cw364 | `16a6359d51863e3827c0484b99d19eb644e17a24a70a56369bd353301c458019` |
| cw365 | `7265cfb01b1117149ee8c324a31aeaa0c0b47b65a98dec2d4020f4f13b2a2429` |
| cw366 | `12538b6b9dd9e2ead97701bbef2940cdde1dd3fd695fe0ea98cccd19f2c6c35a` |
| cw367 | `ff4ab6c7e30dd48d60ca0c7232563f388139970c80a1f9027295e345282fc742` |
| cw368 | `b15ba548dca85433354a88a434e97d0c1034d3b8965718b0a166f34333625e30` |
| cw369 | `6644168f3bda8ff610c554e5d2d3b050231543c1c47bb1acd13ca74c35f31820` |

## Integracja i weryfikacja

- Dopisano sześć ID po cw363 w rejestrze i oczekiwanym zestawie testu.
  Nieznane ID testowe: cw370.
- Istniejący test integracji katalogu sprawdza 369 ćwiczeń, dynamiczną
  zgodność ID metadanych i dokładne 19 ID kolekcji spine (13 + 6 nowych).
- `exercises_repository_test.dart` już używa dynamicznych rozmiarów
  aktualnego katalogu; historyczne 316 to zamierzony prefiks migracji.
  Nie wymagał zmiany.
- Docker: `fit-web:release-1.13.0-26-verified`, aktualne `lib`, `test`,
  `assets`, pubspec i analysis_options z `/opt/fit:/source:ro` kopiowane do
  `/tmp/fit`; cache zależności z obrazu. Bez sieci, bez build_runner,
  bez kompilacji całego obrazu i bez backendu.
- `dart format --output=none --set-exit-if-changed` trzech zmienionych
  plików Dart: **0 zmian**.
- `flutter test --no-pub --reporter expanded test/features/exercises`:
  **81/81 passed**, w tym zgodność rejestru z katalogiem i plikami oraz
  dekodowanie wszystkich 369 ilustracji do 512×512. Log:
  `/root/.local/share/opencode/tool-output/tool_1468d72e0001LFDu2hImtoYl9M`.
  Testy widgetów wypisały ostrzeżenia debug Drift o wielokrotnym tworzeniu
  AppDatabase; nie było błędów testów.
- `expand_catalog.py --check`, `expand_spine_catalog.py --check`,
  `build_catalog_metadata.py --check`, `build_execution_conditions.py --check`,
  `update_exercise_names_pl.py --check`, `validate_catalog.py`: **OK**.
- Python unittest: `test_spine_expansion.py` **8/8**,
  `test_catalog_pipeline.py` **23/23**, `test_execution_conditions.py`
  **14/14**. Odtwarzalność, zachowanie historycznych danych, jawne warunki
  i członkostwo spine potwierdzone.
- `git diff --check`: **OK**.

Status: **lokalnie zintegrowane, niewydane**. Produkcyjna publikacja
pozostaje udokumentowana osobno dla dotychczasowych 363 ilustracji.
