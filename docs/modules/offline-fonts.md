# Fonty offline — Inter

**Aktualizacja po offline E2E:** źródłowy mirror uzupełniono do **22 WOFF2**
o wymagany przez silnik shard `Noto Sans SC 69` (plik `.87`, v37, 5256 bajtów).
Powodem wyboru jest **U+26A0 `⚠`**, potwierdzony instrumentacją runtime oraz
pełnym lookupem/cmap, a nie pusty lookup FE0F. Nowy pakiet wymaga przebudowy
i ponownej akceptacji maina. Poniższy PASS 21 fontów dotyczy historycznej
próbki z polskim prefiksem; nie obejmuje nowego residual 404 w offline E2E.

**Bieżący stan — 2026-10-17:** lokalne Inter i mirror **21 prawdziwych WOFF2**
Roboto/Noto mają **funkcjonalną akceptację fontów PASS** w opisanym real-browser
scenariuszu: zero zewnętrznych prób fontów, zero HTML/parse errors, poprawne
SHA/rozmiary 21/21 plików oraz brak widocznych brakujących glifów w namalowanej
próbce `Zażółć gęślą jaźń ▾ 💪 ⚠️ 👩‍💻 💪🏽`. Nie jest to pełne pokrycie Unicode.
**Ścisłe zero missing-glyph warnings nadal FAIL**: pozostał **1 potwierdzony
warning silnika Flutter 3.35.4 dla U+FE0F (VS16)**, opisany poniżej. Historyczne
„do decyzji”/„nie wdrożono”, wcześniejsze failures i etap 20 plików zachowano.

## Najnowsza diagnoza warningu VS16 i dowody

W odseparowanym przebiegu diagnostycznym rzeczywisty argument gałęzi warningu
wynosił dokładnie `missingCodePoints: [65039]`, czyli tylko **U+FE0F**. Wejście
zawierało już kompletną powyższą próbkę; w tablicy braków nie było samotnego
surogatu ani U+200D/ZWJ. Nie przypisujemy tego warningu przejściowo urwanej
sekwencji ani brakującemu widocznemu znakowi.

Pełne dekodowanie mapy Flutter 3.35.4 (724 fonty, 6892 komponenty, 29518
zakresów do U+10FFFF) daje dla U+FE0F pusty zbiór nominalnych kandydatów.
Audyt rzeczywistych `cmap` 21 WOFF2 i Inter nie znalazł samodzielnego glifu
VS16, ale **Noto Color Emoji 2, cmap format 14**, obsługuje sekwencję
**U+26A0 U+FE0F** jako default UVS (użycie glifu bazowego). VS16 jest selektorem
prezentacji, nie osobnym malowanym znakiem. Nominalna kontrola `getGlyphIDs`
i lookup silnika nie modelują tej sekwencji: to potwierdzony false positive
diagnostyki pokrycia silnika. Dodanie spekulacyjnego fontu z pozostałej mapy
nie zmieni pustego lookupu FE0F; diagnoza nie daje gwarancji pełnego Unicode.

Dowody diagnozy w **`/tmp/opencode/font-warning-research/`**:
`DIAGNOSIS.md`, `conclusion.json`, `codepoint-map-cmap-audit.json` oraz
`guided/console-1792225155490307210.json` i PNG/traffic w `guided/`.
Tymczasowa instrumentacja JS dotyczyła tylko odpowiedzi w routingu osobnego
browsera diagnostycznego: dodano logger przed oryginalną gałęzią, zachowując
warunki, tekst i **1 oryginalny warning**. Nie zmieniono source app ani
produkcji. Ten przebieg nie zastępuje nieinstrumentowanej akceptacji.

Najnowszy raport: **`docs/guided-browser-acceptance-2026-10-17-fonts.md`**,
sekcja „Retest 21 plików”; artefakty akceptacji:
**`/tmp/opencode/guided-acceptance-fonts-complete-20261017T081018Z/`**
(`verification.json`, naturalne odpowiedzi, direct audit i painted PNG).
Runtime `fit-web:guided-local-fonts-complete` ma pełny Docker manifest/index
**`sha256:e25b29c3ab64c48e74fbf8cf68e21aeaa6e45dc280dcddf80698e2d3dd86c007`**.
Przekazany wynik main: **pełna suita Flutter 682 passed, analyze 0 issues**;
przekazany wynik review: **bez HIGH/MEDIUM**. Nie są to nowe uruchomienia
ani review wykonane podczas tej aktualizacji dokumentacji.

Użytkownik **nie zatwierdził engine upgrade**: pozostają Flutter 3.35.4 / Dart
3.9.2. Ewentualna poprawka semantyki coverage w silniku wymaga osobnej jawnej
decyzji; nie wyciszać warningu, usuwać VS16, dodawać sztucznego glifu ani
wyłączać fallbacku. Ścisłe zero-warning pozostaje **FAIL**. Browser acceptance
dotyczy lokalnego HTTP i fixture API, nie pełnej offline PWA, telefonu ani
integracji z rzeczywistym backend API/CAS.

## Working set i przyczyna

`lib/app/theme.dart`, `pubspec.yaml`, `assets/fonts/`,
`test/app/offline_fonts_test.dart`, `test/app/web_font_fallbacks_test.dart`,
`web/flutter_bootstrap.js`, `web/font-fallbacks/`.
Bez zmian guided, bazy, zależności i wersji.

Raport `docs/guided-browser-acceptance-2026-10-17.md` wykazał brak malowanego
tekstu przy działającej semantyce i zablokowanym `fonts.gstatic.com`.
Motyw wywoływał `GoogleFonts.interTextTheme` i `GoogleFonts.inter`, a klient
nie zawierał TTF. Teraz oba motywy używają lokalnej rodziny `Inter` z manifestu
Fluttera; nie rejestrują runtime loaderów Google Fonts. Zależność pozostaje
w pubspec/lock zgodnie z zakresem zadania. Nie zmieniono układu ani rozmiarów.

## Pochodzenie, integralność i licencja

- Samodzielne źródło provenance: **`assets/fonts/PROVENANCE.txt`** — rodzina,
  wersja 4.1, oficjalny upstream, przypięty release/URL archiwum, SHA-256
  archiwum, data pobrania i dokładne ścieżki kopiowanych bez modyfikacji plików.
  Test czyta ten plik, nie dokumentację modułu.
- Sumy SHA-256 każdego fontu i licencji: `assets/fonts/SHA256SUMS`.
  Weryfikacja z katalogu głównego: `sha256sum -c assets/fonts/SHA256SUMS`.
- Licencja: **SIL Open Font License 1.1**, Copyright (c) 2016 The Inter Project
  Authors. Pełna, niezmieniona licencja jest dołączona jako asset
  `assets/fonts/LICENSE.txt`. Przy dystrybucji fontów zachować ten plik.

Odtworzenie: pobrać archiwum wskazane w `PROVENANCE.txt`, sprawdzić SHA-256
**przed** rozpakowaniem,
wybrać wskazane sześć plików i porównać `SHA256SUMS`. Nie pobierać fontów
z przypadkowych mirrorów ani nie aktualizować automatycznie do „latest”.

## Zakres znaków i wag

Statyczne TrueType, nie WOFF2 ani zmienne fonty: zgodne z Flutter 3.35.4
na Web i platformach natywnych. Deklaracje wag: 400 Regular, 500 Medium,
600 SemiBold, 700 Bold, 800 ExtraBold. W800 jest używane m.in. w stopwatch,
rest timer, onboarding i stronie głównej. Skan `lib/**/*.dart` nie wykazał
żądań kursywy ani innych wag. Nie potrzeba syntetycznego pogrubienia.

Testy czytają rzeczywisty `FontManifest.json`, bajty z `rootBundle`, nagłówek
SFNT, brak osi `fvar`, `OS/2.usWeightClass` oraz mapy `cmap` dla
`ĄĆĘŁŃÓŚŹŻąćęłńóśźż` we wszystkich pięciu plikach. Test widgetowy uruchamia
oba motywy z wyłączonym runtime fetching Google Fonts i polskim tekstem.
To nie jest dowód rasteryzacji Web: widget tester używa środowiska testowego.

## Weryfikacja i przekazanie do browser retry

```sh
flutter test --no-pub test/app/offline_fonts_test.dart
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib/app/theme.dart test/app/offline_fonts_test.dart
sha256sum -c assets/fonts/SHA256SUMS
```

Agent główny musi **przebudować nowy obraz** przed browser retry. Stary obraz
z raportu nie zawiera tych assetów. Nie wykonywano tutaj pełnego Docker builda
ani wdrożenia. Nie zmieniano Drift/sqlite3/lockfile ani ich artefaktów Web.

Akceptacja na nowym runtime:

1. Nowy, pusty profil Chromium, bez cache i service workera z poprzedniej wersji.
   Runtime serwowany lokalnie w `--network none`; browser współdzieli jego
   namespace sieciowy. Zezwolić tylko na lokalny origin, blokować i logować
   cały ruch zewnętrzny. To cold visit bez internetu, nie bez lokalnego serwera.
2. Zapisać ID nowego obrazu i SHA `main.dart.js`. Sprawdzić nowy
   `/assets/FontManifest.json` i HTTP 200 dla pięciu
   `/assets/assets/fonts/Inter-*.ttf`; porównać SHA z repozytorium.
3. Przejść onboarding i podstawowe widoki, oba motywy oraz tekst z polskimi
   znakami i w800. Zapisać screenshoty i **obejrzeć namalowane litery**;
   poprawna semantyka/locatory same nie zaliczają tego przypadku.
4. Konsola i log requestów: brak żądań Google Fonts i błędów ładowania Inter;
   sprawdzić także ewentualne fallbacki Roboto/Noto. Polski tekst pokrywa Inter,
   ale glify spoza dostarczonego repertuaru (np. emoji/inne alfabety) mogą nadal
   powodować fallback silnika. Nie zaliczać pełnego „zero external requests”,
   jeśli faktyczny log zawiera taki ruch. Nie dosyłać fontów z harnessu.
5. Reload oraz ponowny cold context bez internetu: tekst nadal widoczny.
   Pełny tryb offline PWA po odcięciu również lokalnego serwera to osobny test
   cache/service workera, nie dowód z samego bundlowania fontów.

Drugi blocker guided/resume pozostaje poza tym working setem.

## Kontrakt kontekstu Docker

`.dockerignore` wyklucza domyślnie wszystko (`**`) i dopuszcza m.in.
`assets/**`, `lib/**` oraz `test/**`, ale nie `docs/**`. Dockerfile Web wykonuje
`COPY . .` przed etapem verification, więc testy nie mogą wymagać dokumentacji.
Poprzedni odczyt tego dokumentu w teście powodował `PathNotFoundException`.

`PROVENANCE.txt` i `SHA256SUMS` są wejściami weryfikacji źródeł w `assets/fonts/`,
dostępnymi również w ograniczonym kontekście Docker. Nie wymagają dodawania
dokumentacji do obrazu ani deklaracji jako assety runtime w pubspec. Test nadal
sprawdza licencję z bundla, URL i SHA archiwum, obecność sum dla wszystkich
pięciu fontów, a dodatkowo rodzinę oraz wersję z pliku provenance.

Kontrola poprawki: na izolowanej kopii źródeł **bez `docs/`**, bez generatora
i bez sieci, odtworzono wcześniejsze 7 PASS / 1 FAIL (`PathNotFoundException`).
Po poprawce ten sam focused zestaw: **8/8 PASS**; analiza samego testu:
`No issues found!`; format: 0 zmian; SHA fontów i licencji: 6/6 OK.
Nie uruchamiano pełnego builda ani pełnej suity i nie modyfikowano konfiguracji
Docker. Kontrola w osobnej kopii nie zapisuje cache ani artefaktów generatora
w głównym workspace.

## Wynik kontroli źródeł — 2026-10-17

- TDD RED: przed poprawką wszystkie 7 początkowych przypadków regresji nie
  przeszło (brak manifestu/assetów Inter i rodzina `Inter_regular`).
- GREEN: 8/8 focused testów po dodaniu kontroli licencji i provenance.
- `flutter analyze --no-pub`: `No issues found!`.
- Format wyłącznie dwóch własnych plików Dart: 0 zmian w końcowej kontroli.
- `sha256sum -c assets/fonts/SHA256SUMS`: 6/6 OK.
- Testy i analiza w istniejącym lokalnym `fit-web:flutter-builder`, z
  `--network none`; zależności rozwiązywane offline z `--enforce-lockfile`.
  Nie zbudowano nowego obrazu. `pubspec.lock` pozostał bez zmian.
- Web SQLite: lock Drift 2.28.2 / sqlite3 2.9.4, SHA zgodne z wcześniejszym
  raportem: wasm `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`,
  worker `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`.
- **Akceptacja wizualna nowego Web runtime oczekuje na rebuild i browser retry.**
  Nie przypisujemy testom widgetowym dowodu usunięcia pustego tekstu na Web.

## Diagnoza fallbacków silnika po świeżym browser retest

Aktualny raport: `docs/guided-browser-acceptance-2026-10-17-fixed.md`.
Inter i namalowany polski tekst mają PASS. Pozostałe żądania nie pochodzą
z `google_fonts`, lecz z silnika. `actual-verification.json` w
`/tmp/opencode/guided-acceptance-fixed-20261017T061511Z/` zawiera trzy unikalne
zewnętrzne URL: guided 4/155/84 prób, timer 5/384/313 prób odpowiednio
Roboto / Noto Sans Symbols / Noto Sans Symbols 2 3. „2 3” oznacza shard 3
rodziny Symbols 2, nie oddzielną rodzinę „Noto Sans Symbols 3”.

### Źródła Flutter 3.35.4 i mechanizm

Poniższe ścieżki względem
https://github.com/flutter/flutter/tree/3.35.4/ :

- `engine/src/flutter/lib/web_ui/lib/src/engine/canvaskit/fonts.dart`:
  `SkiaFontCollection.loadAssetFonts` pobiera Roboto, jeżeli manifest nie
  zawiera rodziny o dokładnej nazwie `Roboto`. To wymóg domyślnego fallbacku
  CanvasKit, niezależny od rodziny głównego motywu. Analogiczny warunek jest
  w `engine/src/flutter/lib/web_ui/lib/src/engine/skwasm/skwasm_impl/font_collection.dart`.
- `engine/src/flutter/lib/web_ui/lib/src/engine/font_fallbacks.dart`:
  `ensureFontsSupportText` wykrywa brakujące glify, kolejka pobiera wybrane
  Noto pod `${configuration.fontFallbackBaseUrl}${font.url}`. Nieudane pobranie
  usuwa wpis pending, ale nie oznacza go jako downloaded: następne układy
  tekstu mogą ponawiać żądanie. To wyjaśnia retry i timeout `networkidle`.
- `engine/src/flutter/lib/web_ui/lib/src/engine/configuration.dart`:
  **wspierane** `fontFallbackBaseUrl` domyślnie wskazuje
  `https://fonts.gstatic.com/s/`; konfiguruje zarówno Roboto, jak i Noto.
  Nie jest to `canvasKitBaseUrl`, a lokalny CanvasKit nie lokalizuje fontów.
- `engine/src/flutter/lib/web_ui/flutter_js/src/loader.js`: `load({config})`
  przekazuje konfigurację dalej do inicjalizacji silnika.
  `packages/flutter_tools/lib/src/web/bootstrap.dart` generuje domyślny
  bootstrap z `{{flutter_js}}`, `{{flutter_build_config}}` i jednym wywołaniem
  `_flutter.loader.load(...)`. Root `web/` obecnie nie ma własnego bootstrapu.
- `engine/src/flutter/lib/web_ui/lib/ui_web/src/ui_web/testing.dart`:
  `disableFontFallbacks` to pole **TestEnvironment**, ustawialne jedynie
  w debug; `setUp` poza debug rzuca `UnsupportedError`. Nie jest obsługiwanym
  polem produkcyjnego `JsFlutterConfiguration`. Nie należy dodawać fikcyjnego
  przełącznika do bootstrapu ani używać go jako zamiennika brakujących glifów.

### Zweryfikowane bajty i glify — tylko artefakty diagnostyczne w temp

Pobrano oryginalne trzy WOFF2 z oficjalnego Google Fonts CDN do
`/tmp/opencode/engine-font-diagnosis-fp4wd7k9/`, bez zmiany assetów aplikacji.
`diagnosis.json` zawiera SHA, rozmiary i repertuar próbki odczytany `fc-scan`.
To nie jest jeszcze pakiet redystrybucyjny z dołączonymi licencjami.

Wszystkie poniższe ścieżki względem `https://fonts.gstatic.com/s/`:

| Ścieżka | Bajty | SHA-256 |
| --- | ---: | --- |
| `roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2` | 63464 | `35b02ca266b79eb4996590f15817425a1ce9ebf48f84471843233ff614656bf2` |
| `notosanssymbols/v43/rP2up3q65FkAtHfwd-eIS2brbDN6gxP34F9jRRCe4W3gfQ8gb_VFRkzrbQ.woff2` | 69116 | `08202e258ea583254c036cff46a7077bb5af4f82c41a6c0a6775f6e44d99f1aa` |
| `notosanssymbols2/v24/I_uyMoGduATTei9eI8daxVHDyfisHr71-vrgfE71.woff2` | 382716 | `c90fbe98152bbb119a7e521a048c6aa6fc367879d6e3dae6db5a17582de25ead` |

Inter nie zawiera U+25BE `▾`; żądany shard Symbols 2 3 zawiera ten znak.
To znak tekstowy w etykiecie wariantu, nie ikona MaterialIcons. Inter zawiera
`→`, `✓`, `⚠`, polskie znaki i `×`, ale nie zawiera `💪` (U+1F4AA) ani
samodzielnego selektora U+FE0F. Żaden z trzech powyższych plików nie zawiera
`💪`. Sam brak glifu dla selektora nie dowodzi błędu sekwencji emoji;
sekwencje wymagają dodatkowego testu renderowania/shapingu.

### Opcje do decyzji przed implementacją

1. **Minimalny mirror obserwowanego scenariusza**: trzy pliki (515296 bajtów),
   ich odpowiednie licencje/provenance oraz własny `web/flutter_bootstrap.js`
   z `config.fontFallbackBaseUrl` wskazującym lokalny katalog, np.
   `new URL('font-fallbacks/', document.baseURI).href`.
   Zachować wersjonowane podkatalogi i nazwy plików silnika, końcowy slash,
   pojedynczy loader i dotychczasowe ustawienia service workera. Bez zmian
   `index.html`, kodu feature'ów, motywu ani toolchainu. Nie podstawiać pod
   nazwami shardów innych fontów. WOFF2 dotyczy tutaj wyłącznie Web fallbacku
   silnika; natywna rodzina Inter nadal pochodzi z lokalnych TTF.
   To pokrywa żądania z dowodów guided/timer, **nie gwarantuje wszystkich emoji
   ani dowolnego tekstu użytkownika**. Brakujące shardy na lokalnym origin
   nadal dałyby 404/retry: samego braku zewnętrznego hosta nie zaliczamy jako
   pełnej poprawki.
2. **Mirror plus pełne emoji i symbole dla szerszego UI**: zachować ten sam
   mechanizm, dodać wymagane shardy Symbols 2 i Noto Color Emoji, licencje,
   SHA/provenance i sprawdzić m.in. `▾`, `💪`, `⚠️`, warianty/ZWJ i znaki
   w nazwach użytkownika. W silniku 3.35.4 są 12 shardów Noto Color Emoji
   i 6 Symbols 2. Dokładny rozmiar tego wariantu wymaga pomiaru; nie pobierano
   ani nie dodawano ich automatycznie. Dalsze alfabety to osobna decyzja.
3. **Pełny mirror repertuaru silnika**: tabela `font_fallback_data.dart`
   zawiera 724 unikalne WOFF2, dodatkowo osobny Roboto. To znacznie większy
   zakres dystrybucji/utrzymania, nie minimalny bugfix. Bez decyzji nie wdrażać.

Na tym etapie **nie zmieniono bootstrapu, fontów ani kodu aplikacji**; duże
rozszerzenie repertuaru pozostaje do uzgodnienia. Nie usuwano tekstów/emoji,
nie wyciszano błędów i nie zmieniano kryteriów akceptacji.

Focused kontrola bieżącej bazy na izolowanej kopii bez `docs/` i sieci:
**8/8 PASS**, analiza testu `No issues found!`, format 0 zmian.
Nie jest to dowód usunięcia fallback-fetch: produkcyjna poprawka tego mechanizmu
nie została jeszcze wdrożona. Nie wykonywano pełnego builda ani generatora.

## Wdrożony lokalny mirror symboli i emoji — 2026-10-17

Po zatwierdzeniu rozszerzenia dodano własny `web/flutter_bootstrap.js`.
`fontFallbackBaseUrl` rozwiązuje się przez
`new URL('font-fallbacks/', document.baseURI).href`: respektuje także aplikację
hostowaną w podkatalogu. Zachowano tokeny Flutter loadera/build config,
pojedyncze wywołanie loadera oraz ustawienia wersjonowania service workera.
Nie wyłączono fallbacków i nie przechwycono/wyciszono błędów silnika.
`index.html`, motyw i polskie Inter pozostały bez zmian w tej iteracji.

### Dokładny zakres, licencje i rozmiar

`web/font-fallbacks/manifest.json` zawiera 20 wpisów z nazwą rodziny silnika,
ścieżką, rozmiarem, SHA-256 i licencją. `PROVENANCE.txt` zawiera źródła
i przypięte commity. Oryginalne bajty pobrano z oficjalnego
`https://fonts.gstatic.com/s/` bez modyfikacji; ścieżki Noto dopasowano do
`font_fallback_data.dart` Flutter 3.35.4, commit
`d693b4b9dbac2acd4477aea4555ca6dcbea44ba2`. Roboto odpowiada ścieżce
`canvaskit/fonts.dart` tej samej wersji. Nie używano aktualnego CSS API ani
podmienionych pełnych fontów pod nazwami shardów.

| Repertuar | Pliki | Bajty fontów |
| --- | ---: | ---: |
| Roboto v32 | 1 | 63464 |
| Noto Sans Symbols v43 | 1 | 69116 |
| Noto Sans Symbols 2 v24 — wszystkie shardy silnika | 6 | 430608 |
| Noto Color Emoji v32 — wszystkie shardy silnika | 12 | 2014496 |
| **Razem** | **20** | **2577684 (około 2,46 MiB)** |

Cały katalog `web/font-fallbacks/` (fonty + manifest, licencje, provenance
i sumy) ma **2606321 bajtów** zawartości plików; bootstrap dodatkowo **414
bajtów**. To rozmiar surowych dodanych plików, nie pomiar transferu/cache.

Roboto ma w pobranym foncie informację o **Apache License 2.0** i copyright
Google 2011; pełny tekst oraz notice są w `Apache-2.0-Roboto.txt`.
Symbole i emoji są na **SIL OFL 1.1**; pełne warunki i notices Noto/Google
są w `OFL-Noto.txt`. Nie zmieniono fontów ani ich nazw wewnętrznych.
Te pliki wraz z provenance są częścią `web/`, zatem trafiają do wydania bez
zmian pubspec, Dockerfile i `.dockerignore`.

`SHA256SUMS` obejmuje 20 fontów, obie licencje, manifest i provenance:

```sh
sha256sum -c web/font-fallbacks/SHA256SUMS
flutter test --no-pub test/app/offline_fonts_test.dart test/app/web_font_fallbacks_test.dart
```

### Testy i niezależny audyt bajtów

- TDD RED: 8 dotychczasowych testów PASS / 2 nowe FAIL na brakującym bootstrapie
  i manifeście. Po wdrożeniu i dodaniu kontroli audytu: **11/11 PASS**.
- Izolowana kopia bez `docs/`, sieci i generatora; pełne `flutter analyze
  --no-pub`: **No issues found!**. Formatowano wyłącznie własne testy.
- Nowe testy nie czytają dokumentacji, nie wymagają usług sieciowych ani nowych
  zależności. Kontrolują bootstrap, komplet 20 fontów, brak duplikatów, rozmiary,
  nagłówki WOFF2, pliki licencji i rzeczywiste SHA przez systemowy `sha256sum`
  (wymaganie środowiska Linux/Docker, nie nowa zależność aplikacji).
- Dodatkowy audyt w tymczasowym venv fontTools 4.67.0/Brotli 1.2.0 zweryfikował
  rzeczywiste `cmap`, zgodność wszystkich 19 mapowań Noto z silnikiem oraz
  obecność COLR/CPAL we wszystkich 12 shardach emoji. Próbka obejmuje
  `▾ → ✓ ⚠ 💪 🏋 🧘 🔥 😀`. Metadane audytu są zapisane w manifeście i związane
  SHA z bajtami; test Flutter nie udaje samodzielnej dekompresji WOFF2.
- Skrypty audytu/pobrania i kontroli wykonania JS są zachowane w
  `/tmp/opencode/{download-fit-fallbacks.py,audit-fit-fallbacks.py,check-font-bootstrap.js}`.
  Kontrola wykonania JS z podstawionymi tokenami: **2/2 PASS** (root URL
  i zagnieżdżony base URL), jeden loader i zachowana wersja SW. To kontrola
  konfiguracji, nie rzeczywistego rasteryzatora ani service workera.
- SHA Inter/licencji pozostają zgodne. Bez nowych modeli, generatorów,
  zależności, wersji, zmian deployu lub feature code.

### Ograniczenia i następny browser retry maina

To **ograniczony repertuar**, nie pełny mirror 724 fontów Noto. Inne alfabety
i znaki spoza tego zakresu, zwłaszcza dowolny Unicode użytkownika, mogą wymagać
nieobecnych lokalnych ścieżek i powodować 404/retry. Nie ignorujemy ich ani
nie uznajemy samego braku zewnętrznej domeny za pełną akceptację.
„Pełne emoji” oznacza wszystkie 12 shardów **tej wersji silnika**, nie obietnicę
wszystkich znaków z przyszłych wersji Unicode. `cmap` i COLR/CPAL nie dowodzą
poprawnego shapingu selektorów, odcieni skóry i sekwencji ZWJ.

Main musi przebudować nowy obraz (nie wykonywano tutaj runtime builda),
a następnie w świeżym profilu bez internetu sprawdzić:

1. Lokalny Roboto HTTP 200 przy starcie oraz lokalne Noto przy potrzebnych
   glifach, zero prób fontów zewnętrznych i zero lokalnych font 404/retry.
2. Namalowane polskie Inter, `Bazowy ▾`, `💪`, `⚠️`, emoji z modyfikatorami
   i ZWJ; screenshoty oraz wygląd glifów, nie tylko semantykę.
3. Ścieżki guided/resume/timer bez usuwania tekstu; `networkidle` po zakończeniu
   legalnych requestów nie powinno być podtrzymywane retry fontów.
4. Świeżość obrazu i bootstrapu, SHA fontów względem manifestu; bez dosyłania
   fontów z harnessu. Osobno akceptacja PWA/SW i pełnego odcięcia serwera.

## Noto Sans v37 — uzupełnienie po rzeczywistym wpisywaniu notatki

Raport `docs/guided-browser-acceptance-2026-10-17-fonts.md` potwierdził zero
zewnętrznych fontów i namalowane `▾ 💪 ⚠️ 👩‍💻 💪🏽`, ale podczas rzeczywistego
wpisywania notatki silnik zażądał dodatkowego `Noto Sans`. Brakujący plik
zwracał HTTP 200 z HTML identycznym z `index.html` (1474 bajty i ten sam SHA),
co dowodzi niedomkniętego mirroru, nie błędu samego fontu. Status HTTP nie
potwierdza poprawnego fontu; SPA fallback maskował brak assetu. Nie zmieniano
Nginx/deployu ani kryteriów akceptacji.

Dodano **tylko** oryginalny plik wskazany przez mapę silnika Flutter 3.35.4:

```text
https://fonts.gstatic.com/s/notosans/v37/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjcz6L1SoM-jCpoiyD9A99Y41P6zHtY.woff2
199616 bajtów
SHA-256: 62a7417925f89dc84917c38d96b7b2e68092106dc3832c7a48129030322e73d8
```

Licencja: **SIL OFL 1.1**, Copyright 2022 The Noto Project Authors
(`https://github.com/notofonts/latin-greek-cyrillic`), potwierdzona w tabeli
nazw pobranego fontu i przypiętym upstream OFL. Notice dodano do `OFL-Noto.txt`,
źródło do `PROVENANCE.txt`, wpis do manifestu i SHA256SUMS. Oryginalny WOFF2
został zdekodowany przez TTFont, zbadano `cmap`, długość i SHA. Pozostałych
20 fontów, Inter i konfiguracji bootstrapu nie zmieniano.

### Dlaczego żądanie Noto Sans może pojawić się przy emoji

Sprawdzono `FontFallbackManager.ensureFontsSupportText` oraz
`findFontsForMissingCodePoints` w przypiętym `font_fallbacks.dart`:

1. Silnik zbiera nie-ASCII kodpunkty tekstu do `codePoints` i sprawdza glify.
2. Gdy `missingCodePoints.isNotEmpty`, do kolejki przekazuje
   **`addMissingCodePoints(codePoints)`**, nie samą podlistę braków.
3. Dobór fontów przez zachłanny set-cover może zatem objąć również polskie
   litery już pokryte Inter, gdy ten sam tekst zawiera jeszcze niepokryte
   symbole/emoji. Request Noto Sans nie dowodzi braku polskich glifów Inter.

Audyt rzeczywistego Noto Sans potwierdził polskie litery z próbki i U+200D
ZERO WIDTH JOINER; nie zawiera on samych emoji z tej notatki ani osobnego
U+FE0F. U+200D występuje także m.in. w shardach emoji 8/9. To wyjaśnia, dlaczego
dobór dla mieszanego tekstu lub pośredniego stanu edycji może potrzebować
zwykłego Noto Sans. **Nie ustalono pojedynczego wyzwalającego kodpunktu ani
dokładnej ramki pośredniej**: log browsera zapisuje URL/odpowiedzi, a nie
argumenty silnika w każdej ramce. Nie przypisujemy żądania bez dowodu wyłącznie
ZWJ, selektorowi, odcieniowi skóry ani uszkodzonej parze surogatów. Nie jest to
powód do modyfikowania wejścia użytkownika lub wyłączania fallbacku.

### Regresja i dalsza akceptacja

Testy wymagają 21 fontów oraz dokładnej ścieżki Noto Sans. Dla wszystkich
plików sprawdzają sygnaturę `wOF2`, minimum 48 bajtów nagłówka, zgodność
długości z nagłówkiem i niezerową liczbę tabel, następnie rozmiar i SHA.
Osobny test odrzuca HTML imitujący odpowiedź SPA 200 oraz ucięte `wOF2`.
To uzupełnia audyt rzeczywistej dekompresji; żaden test nie traktuje samego
HTTP 200 jako zaliczenia fontu.

Fontów jest teraz **21**, łącznie **2777300 bajtów** (przyrost samych fontów:
199616 bajtów, około 195 KiB). Repertuar nadal nie obejmuje całego Unicode.
Main musi przebudować runtime i powtórzyć prawdziwe wpisywanie tej samej próbki
od pustej notatki, nie tylko wkleić końcowy tekst. Naturalny request Noto Sans
ma zwrócić poprawny WOFF2 z powyższym SHA, bez parse warnings, HTML i ukrywania
błędów; ponownie sprawdzić także pozostałe fonty oraz zero external requests.

Weryfikacja tej poprawki: TDD RED **11 PASS / 2 FAIL** (20 zamiast 21 wpisów
i brak Noto Sans); po dodaniu pliku **13/13 focused PASS**. Izolowana kopia
bez `docs/`, sieci i generatora; pełne `flutter analyze --no-pub`:
**No issues found!**; format dwóch własnych testów: **0 zmian**.
SHA mirroru: **25/25 OK**, Inter/licencja: **6/6 OK**. Niezależny audyt
fontTools potwierdził prawidłowy WOFF2, nazwę/licencję, `cmap` oraz ścieżkę
Noto Sans w przypiętej tabeli Fluttera. Bez runtime builda i bez zmian
bootstrapu, kodu aplikacji, wersji, zależności lub wdrożenia.

## SC 69 / plik shard 87 — diagnoza offline E2E i minimalne uzupełnienie

Raport `docs/offline-readiness-browser-acceptance-2026-10-17.md` wykazał
powtarzane 404 dla `notosanssc/v37/...87.woff2`. „69” to nazwa podzbioru
w silniku, nie wersja; rzeczywisty katalog upstream to **v37**. Nie pomylono
tego żądania ze znanym warningiem FE0F. Dane readiness 442/46801539 i core
PASS pozostają dowodami poprzedniego obrazu, nie nowego pakietu fontów.

### Bezpośredni dowód doboru fontów

W odseparowanym kontenerze `fit-web:offline-local-fixed` (`--network none`, bez
host ports) uruchomiono rzeczywisty browser z osobnym pustym profilem i lokalną
fixture API. Oryginalny JS SHA:
`2de34fa3e8c5fcf69dbd40698ee5f4dcaadb4d767284fd962b798844361addcb`.
Wyłącznie w odpowiedzi JS w tymczasowym harnessie dodano logi do istniejącego
sprawdzenia braków i doboru fontów; bez zmiany danych, warunków i fontów.
To diagnoza silnika tego samego obrazu, **nie** ponowna akceptacja real API/SW
lub pełnego pakietu. Nie instrumentowano repozytoryjnego silnika/aplikacji.

Dla notatki **bez polskiego prefiksu** `💪 ⚠️ 👩‍💻 💪🏽` zarejestrowano batch:

```text
[128170,9888,65039,128105,8205,128187,127997]
 U+1F4AA U+26A0 U+FE0F U+1F469 U+200D U+1F4BB U+1F3FD
selected: Noto Color Emoji 8 → Noto Sans SC 69 → Noto Color Emoji 9
unknown: [65039] = [U+FE0F]
```

W sprawdzeniu bazowych fontów Inter pokrywał U+26A0 — nie był to brak widocznego
glifu `⚠`. Silnik przekazuje jednak cały batch, jeżeli brakuje choć części
znaków. Emoji 8 pokrywa kobietę/ZWJ/laptop/odcień skóry; dla pozostającego
U+26A0 zachłanny algorytm rozstrzyga remis przez preferencję **Noto Sans SC**.
Pełna mapa 724 fontów dla U+26A0 ma sześciu kandydatów: Emoji 2, Symbols 2 3,
HK 79, JP 60, SC 69 i TC 72. Gdy nie trzeba pobrać Symbols 2 3 dla `▾` lub
szerszego mieszanego tekstu, SC może wygrać remis mimo lokalnego Symbols.
Nazwa CJK nie oznacza więc obecności chińskich znaków w notatce.

Ponowne obliczenie pełnego lookupu i algorytmu dla powyższej tablicy dało
identyczne trzy rodziny. **To rzeczywisty, mapowalny wybór fontu dla symbolu
U+26A0**, a nie spekulatywne pobranie dla samodzielnego VS16/ZWJ. Brak tego
pliku w mirrorze powodował realne 404/retry. Dodanie oryginalnego sharda
obsługuje ten jawny wybór silnika bez patchowania algorytmu lub tekstu.

### Oryginalny asset i licencja

```text
https://fonts.gstatic.com/s/notosanssc/v37/k3kCo84MPvpLmixcA63oeAL7Iqp5IZJF9bmaG9_FnYkldv7JjxkkgFsFSSOPMOkySAZ73y9ViAt3acb8NexQ2w.87.woff2
5256 bajtów
SHA-256: e4b7e47d39dc977a198121b39c448c698a5ccb33f14a48d945e25d122f6904e8
```

Pobrano przez HTTPS z oficjalnego CDN, bez konwersji lub podmiany fontu.
Dekompresja TTFont potwierdziła `cmap` U+26A0 → `uni26A0` i U+2713; brak
nominalnego FE0F, ZWJ i emoji z notatki. Licencja **SIL OFL 1.1**, copyright
Adobe 2014–2021, Reserved Font Name **Source**, zgodne z tabelą nazw fontu
i przypiętym OFL Google Fonts `ofl/notosanssc/OFL.txt`. Notice dodano do
`OFL-Noto.txt`, pełne źródła do provenance, rozmiar/SHA do manifestu i sum.
Pozostałych 21 fontów nie zmieniano; brak rozszerzenia na pełne CJK/724 fonty.

Mirror: **22 fonty / 2782556 bajtów**; cały katalog wraz z licencjami,
manifestem, provenance i sumami: **2814162 bajty**. Przyrost binariów to tylko
**5256 bajtów**. Repertuar nadal jest ograniczony, a warning nominalnego
pokrycia U+FE0F jest osobnym problemem silnika — ta zmiana go nie wycisza.

### Regresja, dowody i przekazanie

- TDD RED: 12 PASS / 2 FAIL przed dodaniem (brak pliku i 21 zamiast 22 wpisów).
- GREEN: **14/14 focused PASS**, format dwóch własnych testów: 0 zmian.
- Pełne `flutter analyze --no-pub` w izolowanej kopii: **No issues found!**
  Pierwsza próba analizy przekroczyła limit 120 s; jawny rerun tej samej kopii
  z limitem 240 s zakończył się poprawnie w 76,7 s.
- SHA mirroru **26/26 OK**, Inter/licencja **6/6 OK**. Audyt wszystkich 22
  WOFF2: SHA/rozmiary, oryginalne ścieżki engine, próbka `cmap`, COLR/CPAL emoji.
- Test wymaga dokładnej rodziny/ścieżki SC 69, 5256 bajtów, prawdziwego nagłówka
  WOFF2, ustalonego SHA, audytowanego U+26A0 i właściwego notice Adobe.
- Dowody: `/tmp/opencode/font-sc-research/`, `conclusion.json`, `sc69-audit.json`,
  `guided/console-1792268792143150203.json`, traffic i screenshoty. Skrypt
  `/tmp/opencode/prepare-sc-research.py` dokumentuje tymczasową instrumentację.
  Własny kontener diagnostyczny usunięto; dowody historyczne pozostawiono.

Nie uruchamiano runtime builda, generatorów ani manifestu post-build. Main musi
włączyć nowy plik do wyliczanego pakietu offline, przebudować nowy obraz i
ponowić **cold/offline odczyt notatki bez polskiego prefiksu**. Oczekiwać
rzeczywistego WOFF2/SHA dla sharda SC i braku 404/retry, nie samego HTTP 200.
Nie zmieniano workerów, deployu, aplikacji, zależności, wersji ani toolchainu.
