# Frontend usability — zadanie 3

## Stan i zakres

Implementacja **6/6 grup briefu**, bez commitu, push, deployu, subagentów,
backendu, schematu, zależności ani wersji. Praca w `/opt/fit`, na
`feat/frontend-usability`. Na początku sprawdzono dirty tree; zastano częściowy
edytor szablonu oraz testy szablonu/wykresów z poprzedniego podejścia. Dokończono
je, nie powtarzając zadań 1/2 i nie nadpisując zaakceptowanych Ustawień.

Przeczytano brief, spec, ledger, working-sety i raporty audytu
`/tmp/opencode/frontend-audit-20261020-{summary,static,browser-report}.md`.
Obejrzano wcześniejsze PNG edytora desktop i mobilnych Trendów w
`frontend-audit-20261020T081928Z/evidence-browser/`. To dowody **przed**, nie
przeglądarkowa akceptacja aktualnego drzewa.

## Dostarczone zmiany

1. **Szablon:** zwijane parametry z aktualizowanym podsumowaniem, kontrolery
   zachowane przy zwijaniu/kolejności/resize; nowe ćwiczenie rozwinięte. Zapis
   otwiera błędne sekcje przed walidacją, bez dodatkowej przerwy async przed
   ustawieniem busy. Stopka z przyciskiem ≥48 px pozostaje nad klawiaturą i
   globalnymi zakładkami. Dwie kolumny przy szerokości ≥1000 i tekście ≤125%,
   jawna miara 1100 px; inaczej jeden scroll i miara 640 px. Zachowane lease,
   potwierdzenie, limity, prescriptions, kolejność i rozróżnienie cel/wykonanie.
2. **Miara i kontrolki:** wspólny czysto prezentacyjny `ContentLayout`:
   formularze 640, listy 960; główne formularze mają padding 16/24 px.
   Objęto pomiary, aktywności (lista/edytor), planer, szablony, konfigurację
   Mentora, szczegół ćwiczenia, Postępy i Trendy. Nie przepisywano profilu,
   kalkulatora ani strony rozmowy Mentora z zadań 1/2. Ilustracja ma limit
   360×360. Ulubione mają nazwy Dodaj/Usuń, stan `isSelected` i cel 48 px.
   Wariant jest standardowym przyciskiem ≥48 z nazwą/staniem semantycznym;
   istniejące guardy konta, dialog zastąpienia szkicu i blokady timera zostały.
3. **Potwierdzone ryzyka:** katalog przy 320×568, tekście 200% i klawiaturze
   odtworzył overflow 1160 px; po zmianie nagłówek/ostrzeżenia/wyniki mają
   jeden pionowy `CustomScrollView` ze sliverami, chipy zawijają się. Zachowano
   pełne komunikaty o nieweryfikowanych kryteriach i retry klasyfikacji.
   Podsumowanie z 30 seriami, 320×420 i 200% potwierdziło dwa pionowe scrolle;
   teraz jeden przepływ, akcje wtórne w „Akcje treningu”, bez utraty planu,
   notatki, ostrzeżeń, częściowego wykonania i potwierdzeń usuwania.
4. **Trendy:** wynik/za mało danych i rzeczywisty powód przed filtrami;
   użytkowe nazwy ćwiczeń, „Strona nieokreślona”, wariant wykonania.
   Historyczne identyfikatory, metodologia i wszystkie wyłączenia dostępne
   w rozwijanej sekcji. Rozróżnienie NULL/both i poszczególnych UUID pozostaje;
   nie zmieniano silnika, progów ani matematyki agregacji.
5. **Wykresy:** wspólna oś czasu z rzeczywistych instantów, sortowanie,
   skończony niezerowy zakres, te same chwile na tym samym X. Testy 1/2/20
   października sprawdzają proporcję odstępów 1:18, wewnątrz dnia 8/9/11 —
   1:2. Tooltip korzysta z indeksu punktu, nie X jako indeksu tablicy.
   Dostępne historie mają datę i godzinę; pojedynczy wynik nie udaje trendu.
   Zachowano paginację historii testów; historia wagi pokazuje pięć ostatnich
   i rozwijane starsze pomiary. Odcinki proste nie sugerują interpolowanego tempa.
6. **Odzyskiwanie:** szablony, szczegół/brak ćwiczenia i ustawienia Mentora
   mają AppBar, czytelny opis, „Spróbuj ponownie” i lokalny powrót. Retry
   unieważnia właściwy provider; bez surowego wyjątku jako jedynej instrukcji,
   sztucznej pustej listy lub zastępczych danych.

## Testy i dowody

Narzędzia wyłącznie z przypiętego obrazu
`fit-web:release-1.13.0-26-verified`, ID
`sha256:d5b72407766d36b9896eb38a6c94103879c1c29887ccef0ad4e13143ca2ba274`.
Flutter **3.35.4 / Dart 3.9.2**. `/opt/fit` montowany read-only jako `/source`;
testowana aktualna kopia `/tmp/fit`, nie źródła wbudowane w obraz.
`flutter pub get --offline --enforce-lockfile`; brak dostępu do sieci.

- RED szablonu z poprzedniego podejścia: `/tmp/opencode/task3-template-red.log`
  (niewidoczny zapis, brak dwóch kolumn i zwijania).
- Nowe/replayed RED: `task3-resume-layout-red.log` (katalog, summary, szczegół),
  `task3-resume-trend-recovery-red.log`, `task3-resume-variant-red.log`,
  `task3-resume-width-red.log`, `task3-resume-gutters-red.log`,
  `task3-resume-chart-red.log` (9 FAIL / 1 PASS na oryginalnych wykresach).
  Wszystkie nazwy logów w `/tmp/opencode/`.
- Poprawiono błąd samego testu stopki: nie odejmujemy jednocześnie wysokości
  nawigacji i klawiatury, gdy Scaffold zostawia nawigację pod klawiaturą.
  Asercje sprawdzają osobno faktyczną górę zakładek i górę klawiatury.
  Fixture naprawdę zawiera dwa ćwiczenia, dodatkowy test sprawdza trzecie.
- Zaktualizowano interakcje testów szablonu o jawne otwarcie nowej grupy akcji,
  oraz oczekiwane etykiety historii testów o godziny. Pierwszy pełny przebieg
  miał 1326 PASS / 2 FAIL wyłącznie na starych dokładnych tekstach historii;
  nie pominięto tych regresji.
- **26 nowych przypadków testowych** względem 1304 z ledgera zadania 2;
  rozszerzone dotychczasowe testy wariantów, trendów i dostępności.
- Finalny focused: **508 PASS / 0 FAIL**, `task3-resume-final-focused.log`.
  Polecenie: `flutter test --no-pub --reporter expanded` dla
  `test/core/{chart_time_axis,content_layout,recovery_pages,training_accessibility}_test.dart`,
  katalogów `test/features/{exercises,planner,progress,schedule}`, oraz
  `test/features/workout/{variant_widgets,session_summary_states}_test.dart`.
- Finalny pełny `flutter test --no-pub --reporter expanded`:
  **1330 PASS / 0 FAIL**, `task3-resume-final-full.log`.
- `flutter analyze --no-pub`: **No issues found**;
  `dart tools/generate_app_version.dart --check`: **PASS**;
  format plików zadania i `git diff --check`: **PASS**.
  Log: `task3-resume-final-analyze.log`.

W szerszych testach pozostają diagnostyczne ostrzeżenia debug Drift o wielu
instancjach testowych baz; nie wyciszano ich ani nie zmieniano schematu.
Nie zmieniono deklaracji Drift/Freezed/JSON — generator niewymagany.
Lock, wersja i artefakty SQLite bez zmian. Zgodne z lockiem Drift **2.28.2** /
sqlite3 **2.9.4**, SHA-256:

- wasm `922a76b182b6af69b030c8e2fdd3283ecc8e827248b20e4b1f3f3db170b52117`
- worker `6372cb95370e8698afbc594011c2d91cf6d8afea8c9122c25da60013c4eac610`

## Czego ten etap nie dowodzi

**Pozostaje zadanie 4:** niezależny review, finalny immutable build i nowa
izolowana akceptacja Chromium ze zdjęciami po zmianie (w tym pełna macierz
320/375/768/1280, oba motywy, keyboard/focus i 200% wszystkich zmienionych
stron). W tym zadaniu nie uruchamiano przeglądarki, builda web, fizycznego
screenreadera/telefonu ani płatnego AI/push. Widgetowe pomiary i pełny zestaw
testów nie są równoważne takiej akceptacji. Nie uruchamiano backend tests.
Nie ma pozostawionego polecenia testowego w tle.

## Korekta po Chromium P2 — rzeczywisty cel zapisu 40 → ≥48 px

Przeczytano raport `2026-10-20-frontend-browser-report.md`, PNG
`13-template-footer-mobile-inspect.png` oraz `template-footer-dom.json` i
`footer-hit-above.json` z `/tmp/opencode/frontend-usability-20261020T111440Z/evidence-browser/`.
Chromium wykazał rzeczywisty cel 40 px przy 1280/375/320, nie tylko mniejsze
tło. Wcześniejsza deklaracja ≥48 w tym raporcie **nie była poprawna dla
desktopowego/webowego density**; poprzedni widget test nie odtwarzał tej
konfiguracji platformy.

Przyczyna: Flutter 3.35.4 domyślnie stosuje na Linuxie
`VisualDensity.compact`; `ButtonStyleButton` przepuszcza `minimumSize` przez
`effectiveConstraints`, co zmniejsza 48 do 40 px. Poprawka produktu to
**jedna lokalna właściwość** `visualDensity: VisualDensity.standard` w stylu
stopkowego `FilledButton`. Nie zwiększano pustego paddingu rodzica, nie
zmieniano globalnego motywu, innych kontrolek ani domeny/guardów zapisu.

Dodano **6 regresji**: prawdziwy `FitBirekTheme.dark`, platforma Linux,
szerokości 1280/375/320 × tekst 100/200%; przy 200% również klawiatura 180 px.
Sprawdzane są rzeczywiste rozmiary `FilledButton`, malowanego `Material`,
interaktywnego `InkWell` i bounds semantycznego przycisku, oraz hit-test
RenderBox na wysokości 1 i 47 px od górnej krawędzi. Stopka nadal nad
klawiaturą i zakładkami. Zmiana dotyczy tylko edytora, jego testu i tego aneksu.

- RED przed poprawką: **7 PASS / 4 FAIL**, wszystkie cztery oczekują ≥48,
  otrzymując 40 px; pozostałe dwa nowe warianty już rosły przez zawinięty
  tekst. `/tmp/opencode/frontend-footer-p2-red.log`.
- GREEN: **11 PASS / 0 FAIL**, w tym wszystkie 6 nowych regresji.
  Rzeczywiste wysokości przycisku/powierzchni/hitboxu/semantyki są zgodne:
  **48 px** dla wszystkich trzech szerokości przy 100% i desktopu przy 200%;
  **80 px** przy 375/320 i 200% z klawiaturą.
- Pełny Flutter: **1336 PASS / 0 FAIL**;
  `/tmp/opencode/frontend-footer-p2-full.log`.
- Analyze: **No issues found**; version check **exit 0**; format i
  `git diff --check` poprawne. Pomiary i weryfikacja:
  `/tmp/opencode/frontend-footer-p2-verification.log`.

Użyto tego samego przypiętego obrazu narzędziowego Flutter 3.35.4 / Dart 3.9.2,
źródła read-only i testowana aktualna kopia. Bez subagentów, commitów,
deployu, zmiany wersji, zależności, schematu ani innych UI.
**Nie wykonano nowego buildu ani Chromium po poprawce** — ponowna akceptacja
przeglądarkowa wymaga nowego immutable kandydata; stary NEEDS_FIX pozostaje
uczciwym wynikiem poprzedniego obrazu.

## Korekta po kolejnym Chromium P2 — wariant i kontrola wszystkich jawnych 48 px

Przeczytano aneks raportu przeglądarkowego z wynikiem **54 PASS / 1 FAIL**, PNG
`43-variant-target-mobile.png` i odpowiadające boxes w
`/tmp/opencode/frontend-usability-20261020T120901Z/evidence-browser/`.
Rzeczywisty wariant miał 40 px przy 1280/375/320, mimo deklarowanego minimum.
Przyczyną jest ponownie kompaktowe desktopowe density, nie guard wyboru.

Zmiany produktu ograniczono do lokalnego `VisualDensity.standard`:

- `OutlinedButton` wyboru wariantu w aktywnej sesji;
- `TextButton.icon` „Parametry ćwiczenia” — proaktywna regresja wykazała ten
  sam defekt 40 px również tutaj.

Nie zmieniano globalnego motywu, rodziców/paddingu dla pozornego hitboxu,
domeny, guardów konta/wariantu/timera, dialogów ani zapisu serii. Gwiazdka,
Save i ikony kolejności/usuwania/dodawania nie wymagały kolejnej poprawki.

Regresje używają rzeczywistego motywu FitBirek na platformie Linux
(adaptacyjne **compact**), a nie domyślnego testowego density Androida:

- wariant: 1280/375/320 × 100/200%, przy 200% również inset klawiatury;
  pomiary w istniejącym teście prawdziwego repo/aktywnych wariantów, potem
  pełne dotychczasowe sprawdzenie Zachowaj/Zastąp, wznowienia usuniętego
  wariantu i blokady logowania;
- Save i **wszystkie pozostałe kontrolki szablonu z jawnym minimum 48**:
  parametry, aktywne strzałki kolejności, usuń i dodaj — ta sama macierz;
- gwiazdka: sześć nowych przypadków, trzy szerokości × oba stany;
  stan dodania przy 100%, stan usunięcia przy 200% i inset klawiatury.

Wspólny helper testowy mierzy `Material`, rzeczywisty `InkResponse`/`InkWell`,
kontrolkę i bounds semantyki; sprawdza trafienie w interaktywny RenderBox na
wysokości **1 i 47 px**. Nie zalicza samego zewnętrznego paddingu.
Zmiana rozmiaru w teście przewija rzeczywisty lazy viewport do kontrolki,
zamiast zakładać, że widget poza viewportem już istnieje.

**Wyniki:**

- poprawny RED: **17 PASS / 5 FAIL**, wszystkie FAIL to 40 zamiast ≥48
  (wariant oraz parametry); gwiazdka i Save przechodzą;
  `/tmp/opencode/frontend-variant-p2-red-final.log`;
- GREEN focused: **22 PASS / 0 FAIL**;
  `/tmp/opencode/frontend-variant-p2-verification.log`;
- wariant: powierzchnia i hitbox **48 px** przy 100% i desktopowym 200%,
  **80 px** przy mobilnym 200%; gwiazdka i ikony szablonu **48×48**;
  parametry **≥48 px**, rosną naturalnie z tekstem;
- pełny Flutter: **1342 PASS / 0 FAIL**, czyli sześć nowych przypadków ponad
  poprzednie 1336; `/tmp/opencode/frontend-variant-p2-full.log`;
- analyze **No issues found**, version check **exit 0**, format i
  `git diff --check` poprawne. Przypięty Flutter **3.35.4 / Dart 3.9.2**,
  ten sam obraz narzędziowy, źródło read-only i aktualna kopia do testowania.

Wstępny osobny fixture testowy aktywnej sesji miał timeouty przy obsłudze bazy;
został usunięty, nie uznano ich za błędy produktu ani dowód naprawy. Pomiary
wariantu przeniesiono do istniejącego stabilnego testu z prawdziwym katalogiem
i repozytorium. Zachowano diagnostyczne logi prób harnessu, a podane powyżej
liczniki dotyczą finalnych przebiegów, bez pozostawionego procesu testowego.

Bez subagentów, commitów, deployu, wersji, zależności, schematu i backendu.
Bez nowego web buildu/Chromium w tej korekcie — końcowa brama wymaga kolejnego
immutable kandydata i przeglądarkowego rechecku; poprzedni obraz pozostaje
oznaczony NEEDS_FIX.
