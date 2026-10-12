# Ilustracje ćwiczeń — partia 05

## Cel i zakres zatwierdzony

Sześć wariantów pompek z początku katalogu: `cw001–cw006`. Seria
`cw251–cw316` ma już komplet ilustracji. Punktem wyjścia jest 66 zilustrowanych
ćwiczeń i 250 brakujących spośród 316 rekordów. Po integracji Partii 05 będzie
72 zilustrowanych ćwiczeń i 244 brakujące.

Źródłem nazw i techniki jest `assets/data/exercises.json`. Ilustracje nie
wymagają zmian rekordów katalogu ani istniejących identyfikatorów.
Niniejsza specyfikacja dotyczy przygotowania, generacji i integracji pakietu.
Wersja kolejnego wydania oraz wdrożenie wymagają osobnego uzgodnienia;
aktualna produkcja to `1.8.0+21`.

## Kontrakt wizualny

- Jeden lokalny `assets/exercises/cwNNN.webp` na ćwiczenie, `512×512`.
- Dokładnie dwa oddzielone kadry, czytane od lewej do prawej.
- Wzorzec stylu: `assets/exercises/cw256.webp`; kremowe tło, ciemny neutralny
  strój, twarz bez rysów, wyraźne komiksowe kontury.
- Ta sama postać, orientacja ciała i kamera w obu kadrach danego ćwiczenia.
- Całe ciało, dłonie i stopy mieszczą się w każdym kadrze; podłoże i punkty
  podparcia są czytelne. Kamera dobrana osobno dla każdego wariantu.
- Bez tekstu, numerów, etykiet, znaków wodnych i strzałek. Czytelność ruchu
  wynika z pozycji ciała, nie z oznaczeń kierunkowych.
- Pierwsze prompty nie wymagają kolorowych oznaczeń mięśni. Jeżeli pojawią się
  takie oznaczenia, obowiązuje konwencja serii: pomarańcz dla celu, turkus dla
  widocznego wsparcia; stawy, ścięgna i zasłonięte mięśnie nie są oznaczane.
- Oceniać zarówno PNG `1024×1024`, jak i podgląd `512×512`. Drobna różnica
  widoczna tylko po powiększeniu nie wystarcza do rozróżnienia wariantów.

## Sceny i kryteria odrzucenia

| ID i nazwa katalogowa | Kadr 1 | Kadr 2 | Kamera i kontrola |
|---|---|---|---|
| `cw001` — Pompki klasyczne | Podpór na wyprostowanych ramionach, dłonie około szerokości barków. | Klatka blisko podłoża, łokcie około 45° od tułowia. | Lekko podwyższony widok boczny 3/4; widoczne obie dłonie. Odrzucić opadanie bioder, łokcie rozstawione pod 90° i opuszczenie samej głowy zamiast klatki. |
| `cw002` — Pompki wąskie (diamentowe) | Podpór z dłońmi tworzącymi romb pod klatką. | Niska pozycja z klatką tuż nad dłońmi i łokciami blisko tułowia. | Przednio-boczny widok 3/4 od strony głowy, nieco z góry, ujawniający złączone kciuki i palce wskazujące. Odrzucić szeroki rozstaw dłoni, zasłonięty chwyt, zapadnięte biodra i łokcie na boki. |
| `cw003` — Pompki szerokie | Podpór, dłonie około 1,5 szerokości barków. | Kontrolowane opuszczenie klatki między dłońmi. | Lekko podwyższony przednio-boczny widok 3/4, ujawniający rozstaw obu dłoni. Odrzucić skrajnie szeroki rozstaw, zapadnięte barki i pozycję nierozróżnialną od `cw001`. |
| `cw004` — Pompki łucznika | Szeroki, symetryczny podpór z wyprostowanymi ramionami. | Ciężar przeniesiony na jedną stronę: roboczy łokieć ugięty, przeciwne ramię wyprostowane w bok z dłonią na podłożu. | Podwyższony przedni widok 3/4, pokazujący oba ramiona. Odrzucić ugięcie obu ramion jak w szerokiej pompce, oderwaną dłoń pomocniczą i załamanie lub skręt bioder. |
| `cw005` — Pompki na jednej ręce | Podpór jednorącz, nogi szeroko, wolna ręka za plecami. | Roboczy łokieć ugięty, klatka i biodra opuszczone razem. | Boczny widok 3/4 od strony wolnej ręki, ujawniający podporową dłoń i rozstaw stóp. Odrzucić podporową drugą rękę, pozorną trzecią kończynę, skręt bioder i nierówny zjazd tułowia. |
| `cw006` — Pompki plyometryczne z klaśnięciem | Dolna pozycja przed wybiciem: dłonie na podłożu, łokcie ugięte. | Faza lotu górnej części ciała: obie dłonie oderwane od podłoża i złączone w klaśnięciu przed klatką; palce stóp nadal oparte o podłoże. | Boczny widok 3/4, pokazujący kontakt stóp i odstęp dłoni od podłoża. Odrzucić dłonie nadal podpierające ciało podczas klaśnięcia, dodatkowe ręce i załamany tułów. Drugi kadr przedstawia lot, nie lądowanie; nie zastępuje instrukcji miękkiego lądowania z katalogu. |

We wszystkich wariantach tułów pozostaje stabilny, a głowa jest przedłużeniem
kręgosłupa. Ustawienie dłoni, łokci i podpór musi pozwalać rozpoznać konkretny
wariant bez podpisu. W `cw004` i `cw005` oba kadry pokazują tę samą stronę
roboczą; nie zamieniać strony między fazami.

## Przebieg generacji

1. Przygotować sześć osobnych promptów obejmujących kontrakt wizualny, dokładną
   scenę, kamerę i kryteria odrzucenia z tabeli.
2. Generować w kolejności `cw001` do `cw006`, po jednym żądaniu
   `--single-sunburst-medium` przez `tools/benchmark_exercise_images.py`.
   Referencją pierwszej próby jest `/tmp/opencode/cw256-reference.png`,
   odpowiadające `assets/exercises/cw256.webp`.
3. Każda próba używa świeżego katalogu `/tmp/opencode/cwNNN-trial-NN`.
   Prompt, PNG, podgląd i ledger pozostają poza repozytorium.
4. Odczytać i ocenić wynik przed następnym płatnym żądaniem. Nie generować
   całej partii automatycznie bez przeglądu kolejnych wyników.
5. Korekta dotyczy wyłącznie nazwanego defektu, używa odrzuconego PNG jako
   jedynej referencji i świeżego katalogu. Zachowuje poprawne części sceny.
6. Jeśli kolejne korekty nie usuwają tego samego problemu, zatrzymać płatne
   próby i ponownie uzgodnić sposób przedstawienia ruchu.

## Integracja i testy

- Najpierw rozszerzyć `expectedIllustrationIds` w
  `test/features/exercises/exercise_illustrations_test.dart` o `cw001–cw006`
  przed `cw251` i potwierdzić oczekiwaną porażkę kontraktu rejestru.
- Test braku ilustracji obecnie używa `cw001`; przenieść ten przypadek na
  nadal niezilustrowane `cw007`, aby zachować kontrolę fallbacku.
- Produkcyjny rejestr i assety rozszerzyć dopiero po akceptacji wszystkich
  sześciu scen. Nie integrować kolejnych ćwiczeń po pojedynczej generacji.
- Finalne PNG konwertować przez `convert` z opcjami
  `-resize 512x512 -strip -quality 90` do sześciu docelowych WebP.
- W `lib/features/exercises/presentation/exercise_illustrations.dart` dodać
  `cw001–cw006` przed `cw251`, bez zmiany funkcji wyboru assetu.
- Istniejąca deklaracja `assets/exercises/` obejmuje nowe lokalne pliki.
  Obrazy korzystają z istniejącego mechanizmu ładowania offline.
- Uruchomić Dockerowy target `verification` z
  `deploy/docker/web.Dockerfile`: kontrola wygenerowanej wersji, analiza
  Fluttera i pełne testy, w tym równość rejestru, brak osieroconych plików
  oraz dekodowanie obrazów jako `512×512`.
- W `docs/exercise-illustrations-status.md` dodać sześć wierszy, sekcję
  „Piąta partia” i liczby 72/244/316. Do wdrożenia nowe wiersze oznaczać
  jako lokalnie zintegrowane, niewydane; dotychczasowe 66 pozostaje wydane.

## Warunki ukończenia pakietu

- Sześć ilustracji przeszło przegląd scen oraz jakości w docelowym rozmiarze.
- W repozytorium znajduje się dokładnie sześć nowych WebP, po jednym na ID,
  i zgodne wpisy w rejestrze oraz oczekiwaniach testu.
- Analiza i testy targetu `verification` są zielone.
- Dokumentacja odróżnia przygotowany pakiet od faktycznie wydanej wersji.
- Praca pozostaje w aktualnym `main`, zgodnie z dotychczasowym wyborem.
  Commit i push wymagają wyraźnej prośby użytkownika; istniejące,
  niecommitowane zmiany Partii 04 należy zachować.
