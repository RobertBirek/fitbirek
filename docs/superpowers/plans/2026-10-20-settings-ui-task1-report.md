# Task 1 — ustawienia FitBirek

## Zakres

Implementacja w głównym katalogu `/opt/fit`, gałąź `feat/settings-ui`, baza
`a0ca0f8`. Bez commit/push/deploy, zmian wersji, zależności, schematu i backendu.
Wczytano brief, specyfikację, AGENTS.md, working set synchronizacji oraz
`frontend-design` i `fit-flutter-workflow`.

Lokalny Inter, grafitowe karty, pomarańczowy znacznik harmonogramu. Treść do
960 px; padding 16/24, odstępy 24, karty 16. Dwie kolumny przy dostępnych
760 px, jedna przy dużym tekście. Bez zmiany globalnego motywu.

## Pliki implementacji

- `lib/app/router.dart` — trzy nested trasy wewnątrz dotychczasowego shella.
- `lib/features/settings/presentation/pages/settings_page.dart` — panel,
  istniejące linki i API preferencji, neutralny link do powiadomień, osobny logout.
- `lib/features/settings/presentation/widgets/settings_section.dart` — wspólna
  szerokość, przewijanie, karty i linki; lokalne cele IconButton minimum 48 px.
- `lib/features/settings/presentation/pages/settings_notifications_page.dart`
  — dotychczasowy Web Push/native opt-in i rzeczywisty stan przypomnień.
- `lib/features/settings/presentation/pages/settings_backup_page.dart` —
  przeniesione handlery, picker z `withData: true`, share, busy/error/cancel;
  ostrzeżenie importu z wyjątkiem Apple Zdrowie zachowane, dialog przewijalny.
- `lib/features/settings/presentation/pages/settings_health_page.dart` —
  istniejący HealthIntegrationTile poza ekranem głównym.
- `lib/core/sync/sync_status_tile.dart` — opcjonalne `showLogout = true`;
  stan, pending i pełny komunikat kwarantanny bez zmian. Ikony wyrównane do
  góry, aby retry nie znikał poniżej ekranu przy długim konflikcie i tekście 200%.
- `lib/core/push/push_settings_tile.dart` — tylko rozwijana instrukcja;
  automatycznie rozwinięta przy needsInstall. Transport i synchroniczny gesture
  enable bez zmian.

## Pliki testów

- `test/features/settings/settings_layout_test.dart` — produkcyjny router,
  podstrony/back/shell, stare linki, logout, auth bootstrap/login/deeplink;
  320/375/768/1280 px × tekst 100/200% × dark/light, wszystkie podstrony,
  szerokość, układ, cele co najmniej 48 px, przejście klawiaturą, brak wyjątków;
  ostrzeżenie i anulowanie importu.
- `test/features/settings/settings_safety_test.dart` — cancel/picker error/
  brak bajtów/niepoprawny JSON, busy i eksport error, brak mutacji danych,
  czytelny konflikt, push przy 320 px/200%, brak auto-enable i synchroniczny klik.

## Weryfikacja

Wszystkie polecenia Flutter/Dart w obrazie
`fit-web:release-1.13.0-26-verified`, z `--rm --network none -v /opt/fit:/app -w /app`.
Użyto `--no-pub`, ponieważ zależności są już dostępne w obrazie, a sieć jest
celowo odcięta. Formatowano wyłącznie własne pliki.

- RED: `/tmp/opencode/settings-ui/red.log` — testy nowego panelu i tras
  wykazały brak wymaganych sekcji/tras przed implementacją (3 pass/20 fail;
  początkowa fixture wymagała również mocka natywnych powiadomień).
- GREEN pierwszego zestawu: `/tmp/opencode/settings-ui/green.log` — 24 pass.
- Dodatkowy RED dostępności: `/tmp/opencode/settings-ui/safety.log` —
  20 pass/17 fail: domyślna ikona 40 px oraz retry pośrodku długiej karty
  konfliktu. Poprawiono lokalnie minimum 48 px oraz wyrównanie ikon do góry.
- Końcowe nowe testy UI/safety: `/tmp/opencode/settings-ui/final-ui-safety.log`
  — **39 pass**, bez błędów i ostrzeżeń trafienia poza ekranem. Obejmuje też
  minimalny rozmiar przycisku push przy tekście 100%, nie tylko 200%.
- Focused settings/auth/schedule/mentor/version/sync/push/router:
  `/tmp/opencode/settings-ui/final-focused.log` — **335 pass** (przed dodaniem
  dwóch dodatkowych wariantów normalnego tekstu push, osobno potwierdzonych
  w powyższym zestawie 39 testów).
- Końcowe pełne sprawdzenie: `/tmp/opencode/settings-ui/verified-full.log`:
  - `flutter analyze --no-pub` — **No issues found**, 48,4 s;
  - `dart tools/generate_app_version.dart --check` — exit 0 (następne polecenie
    uruchomione przez `&&`);
  - `flutter test --no-pub --reporter expanded` — **1239 pass**, 5 min 12 s,
    exit 0. Obejmuje cały aktualny zestaw oraz nowe 39 testów.

Wczesne uruchomienia `full.log`, `focused.log` i `final-full.log` są logami
pośrednimi, nie dowodem końcowym: zawierają testy pisane w trakcie pracy,
pomyłkę ścieżki `test/app/app_version_test.dart` (poprawnie
`test/app_version_test.dart`) oraz trzy poprawione uwagi lintera w nowych
testach. Nie osłabiano istniejących testów ani asercji. Żaden istniejący test
integracyjny nie wymagał zmiany oczekiwań tras.

Porównanie handlerów backupu z bazą: identyczne z wyjątkiem dodania
`scrollable: true` do dialogu ostrzeżenia. Generator niepotrzebny: brak zmian
Drift/Freezed/JSON. `pubspec.lock`, `web/sqlite3.wasm` i
`web/drift_worker.dart.js` identyczne z bazą (Drift 2.28.2, sqlite3 2.9.4).
Dowód: `/tmp/opencode/settings-ui/preservation.log`. `git diff --check` czysty
(`/tmp/opencode/settings-ui/diff-check.log`).
Kontrola formatowania dziesięciu własnych plików:
`/tmp/opencode/settings-ui/format-check.log` (0 zmian; późniejsze dodatkowe
warianty testu push również sformatowano).

## Pozostałe bramki

Kontroler wykonuje niezależny review oraz prawdziwy izolowany Chromium:
desktop/mobile, screenshoty, jasny/ciemny motyw i duży tekst, fokus klawiatury,
bezpieczne scenariusze push i backupu. Nie wykonano logowania ani zapisów
na produkcji. Te bramki nie są deklarowane jako zakończone przez implementera.

## Poprawka review P1 — źródło prywatnych bajtów backupu

Po review uzupełniono bezpieczeństwo nowej nawigacji. Wcześniejsze stwierdzenie
o identyczności handlerów opisuje stan sprzed tej poprawki; obecnie zawierają
poniższe jawne guardy, bez zmian `BackupService` ani polityki danych.

### Zmienione pliki w tej iteracji

- `lib/features/settings/presentation/pages/settings_backup_page.dart`:
  przechwycenie konta i epoch `CachedAuthWriteAuthority` oraz identyfikatora
  operacji przed pierwszym await; unieważnianie na zmianie autorytetu i dispose.
  Sprawdzana jest też aktualność trasy, ponieważ route po back może nadal być
  mounted podczas animacji. Odczyt trwałego powiązania weryfikuje accountId,
  offlineAccess i deviceId (generację unieważniania), zarówno przed eksportem,
  jak i bezpośrednio przed Share. Spóźnione sukcesy/błędy nie wyświetlają
  komunikatów poprzedniego konta. Guard nie inicjuje auth/HTTP.
- Import przechwytuje to samo źródło przed warningiem, sprawdza je po warningu
  i pickerze (także dla anulowania), a istniejący atomowy restore wykonuje
  wewnątrz dodatkowej transakcji sprawdzającej źródło przed i po serwisie.
  Cofnięcie podczas restore wycofuje jego mutacje. Ostrzeżenie, wyjątek Apple,
  picker bytes i semantyka serwisu są zachowane.
- `test/features/settings/settings_backup_authority_test.dart` — 9 nowych
  przypadków produkcyjnego routera: delayed export → back → footer logout,
  A-B-A przy nadal mounted stronie i tym samym końcowym deviceId, pozytywny
  Share dokładnie raz z tymi samymi bajtami, trwała blokada, back przed dispose,
  spóźniony picker po back/logout i A-B-A oraz prawdziwy restore: rollback po
  back / commit dla aktualnego konta. Share ma mock na granicy pluginu, bez
  zapisywania prywatnych bajtów do plików tymczasowych.
- `test/features/settings/settings_layout_test.dart` oraz
  `test/features/settings/settings_safety_test.dart` — wyłącznie przygotowanie
  fixture z produkcyjnym providerem auth i jego rzeczywistym pasywnym epoch;
  dotychczasowe asercje pozostają. Fake sync w testach celowo dopuszcza
  adwersarialne A-B-A, którego produkcyjny serwis nie dopuszcza w tej samej bazie;
  polityki produkcyjnej nie zmieniano.

### RED / GREEN i logi P1

- `/tmp/opencode/settings-ui/p1-red.log`: **2 pass / 2 fail**, oba eksporty
  rzeczywiście docierały do mocka Share po back/logout lub A-B-A.
- `/tmp/opencode/settings-ui/p1-back-transition-red.log`: **1 fail** — wykrył
  dodatkowo mounted route podczas animacji cofania, naprawiony kontrolą trasy.
- `/tmp/opencode/settings-ui/p1-final-ui.log`: **48 pass** (39 wcześniejszych
  i 9 nowych testów), bez osłabiania asercji.
- `/tmp/opencode/settings-ui/p1-final-focused.log`: **145 pass** — ustawienia,
  auth, router, restore/sync regresje i status synchronizacji.
- `/tmp/opencode/settings-ui/p1-final-full.log`: końcowy pełny
  `flutter analyze --no-pub` — **No issues found** (97,2 s),
  `dart tools/generate_app_version.dart --check` — **exit 0**,
  `flutter test --no-pub --reporter expanded` — **1248 pass**, 7 min 43 s,
  exit 0. Polecenia wykonano w tym samym izolowanym obrazie, jak poprzednio.
- `/tmp/opencode/settings-ui/p1-format-check.log`: cztery zmienione pliki
  Dart, **0 zmian**. `/tmp/opencode/settings-ui/p1-diff-check.log`: czysty
  `git diff --check`. `BackupService`, pubspec/lock, Web SQLite i backend
  pozostają bez zmian.

Ta iteracja nie zmienia pozostałych funkcji, backendu, schematu, zależności,
wersji ani Web SQLite. Nadal bez commit/push/deploy. Pozostałe bramki Chromium
i niezależny review pozostają po stronie kontrolera.

## Poprawka blokera Chromium — utrata deep linku podczas startu

Przeczytano raport Task 2 oraz rzeczywiste
`/tmp/opencode/settings-ui-20261020T064625Z/evidence-browser/deep-reproduction.json`:
wejściowe `/#/settings/notifications`, po reload `/#/today`. Zastosowano
systematyczne debugowanie: prześledzono main → DatabaseBootstrap →
ActivityReminderBootstrap → _ReadyApp → routerProvider/createRouter, a także
implementacje Flutter 3.35.4 i przypiętego GoRouter 14.8.1.

### Przyczyna, potwierdzona przed poprawką

To **nie** imperatywny `context.push`, opóźnienie auth do „naprawienia” timerem
ani wymuszanie `/bootstrap` przez GoRouter. GoRouter domyślnie honoruje
niepustą trasę platformy nawet przy `initialLocation: '/bootstrap'`.

Podczas asynchronicznego otwierania lokalnej bazy `DatabaseBootstrap` tworzył
`MaterialApp(home: Scaffold(...))`, czyli **tymczasowy Navigator przed właściwym
routerem**. Jego `selectSingleEntryHistory` i `routeInformationUpdated` trafiały
do `flutter/navigation`. Flutter Web EnginePlatformDispatcher po każdej takiej
wiadomości resetuje `defaultRouteName` do `/`. Navigator bramki, nieznający
podstron, raportował dodatkowo zastępczą trasę `/`.

Gdy baza była gotowa, GoRouter czytał już `/`, wybierał domyślny `/bootstrap`,
a `_PendingProtectedLocation` nigdy nie otrzymywał pierwotnego URI. Poprawny
fallback po auth/onboardingu prowadził więc do `/today`. Istniejące testy
`createRouter(initialLocation: target)` pomijały wcześniejszą bramkę i reset
silnika, dlatego nie wykrywały tego błędu.

Dowód implementacji granicy silnika i GoRouter:
`/tmp/opencode/settings-ui/deep-link-engine-boundary.log`.
RED odtwarzał przed powstaniem routera dokładnie:
`external=/settings/notifications; platform=/; navigation=[selectSingleEntryHistory,
routeInformationUpdated: {uri: /, ...}]`, potem końcowe `/today`.

### Minimalna poprawka i dokładny zakres tej iteracji

- `lib/app/database_bootstrap.dart`: `builder` zamiast `home` w tymczasowym
  MaterialApp. Widok oczekiwania/błędu nadal ma MaterialApp, motyw, Scaffold,
  istniejące komunikaty i Retry, ale **nie tworzy Navigatora i nie konsumuje
  adresu startowego**. Bez opóźnień, dodatkowego routera, ręcznego parsowania URL
  ani zmiany kolejności bezpieczeństwa otwierania bazy.
- `test/app/startup_deep_link_test.dart`: 6 regresji całego `FitBirekApp`,
  produkcyjnego GoRouter/routerProvider i providera auth z opóźnioną sesją,
  bramką DB oraz osobno asynchronicznym profilem. Zewnętrzny URI jest podawany
  przez platform dispatcher, nie `initialLocation` ani push. VM boundary mock
  naśladuje udokumentowany reset Flutter Web przy wiadomościach nawigacji.
  Sprawdza brak takich wiadomości przed bazą, trzy podstrony i back,
  dynamiczne `/workout/summary/7` z parametrem i back, domyślne Today dla `/`,
  signed-out login → ładowanie profilu → onboarding → pierwotny URI wraz
  z query i fragmentem. Pełna aplikacja używa polskiego przycisku Wstecz.
- Niniejszy raport. Nie zmieniano w tej iteracji `router.dart`, `main.dart`,
  polityki login/signed-out/onboarding, kształtu tras, domyślnego Today,
  opcji GoRouter dotyczących push ani wcześniejszych testów.

### Dowody i bramki

- `/tmp/opencode/settings-ui/deep-link-red.log`: **1 pass / 5 fail** przed
  zmianą — trzy podstrony, dynamiczna trasa i login wracały do `/today`;
  przypadek root → Today już przechodził.
- `/tmp/opencode/settings-ui/deep-link-green.log`: **16 pass** — 6 nowych
  regresji wraz z istniejącymi testami routera i bezpieczeństwa bramki DB.
  Trace po poprawce: `platform=/settings/notifications; navigation=[]` przed
  routerem; analogicznie backup, health i dynamiczna trasa treningu.
- `/tmp/opencode/settings-ui/deep-link-final-full.log`: pełny
  `flutter analyze --no-pub` — **No issues found** (69,4 s),
  `dart tools/generate_app_version.dart --check` — **exit 0**,
  `flutter test --no-pub --reporter expanded` — **1254 pass**, 5 min 36 s,
  exit 0. Ten sam izolowany obraz i `--network none` jak poprzednio.
- `/tmp/opencode/settings-ui/deep-link-format-check.log`: **2 pliki / 0 zmian**.
  `/tmp/opencode/settings-ui/deep-link-diff-check.log`: czysty `git diff --check`.

**Wymagany nowy kandydat przeglądarkowy ze zmienionego źródła.** Stary obraz
`fit-web:settings-ui-20261020T064625Z` nie zawiera tej poprawki; jego FAIL nadal
pozostaje prawdziwy. Testy widgetowe nie są deklaracją akceptacji Chromium.
Kontroler musi ponowić bezpośrednie `goto` i pełne reload dla trzech podstron
(zwłaszcza notifications dwukrotnie), back i auth/deep link oraz pozostałe
przerwane bramki z raportu Task 2. Bez deployu, zmian wersji, backendu,
zależności, schematu, artefaktów Web SQLite, subagentów, commit i push.
