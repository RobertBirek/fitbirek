# Niezawodność PWA i timerów — 2026-10-29

Gałąź `feat/pwa-reliability-and-timers`, baza `d567c2f`.
**Ten etap zakończono lokalnie, bez merge/push/wydania/wdrożenia.** Produkcja
wtedy pozostawała1.25.1+43; wersja, katalog431, ilustracje431, Drift15, backup4, Alembic0010,
lockfile i para Web SQLite nie zostały zmienione. Nie generowano ilustracji.
Po osobnej zgodzie użytkownika scalono i opublikowano poprawki jako
[Web1.25.2+44](../releases/2026-10-29-pwa-reliability-1.25.2-44.md).
Poniższe liczby opisują etap funkcjonalny, nie zastępują dowodów tego wydania.

## Zakres

1. [Mobilny odbiór bazowego kompilatu](2026-10-29-pwa-mobile-acceptance.md):
   20 grup asercji, recovery, aktualizacja1.25.0→1.25.1 z zachowanym pending
   i szkicem,431 ilustracji odkodowanych offline w dwóch profilach.
   To emulacja viewport/touch, nie fizyczny telefon ani VoiceOver.
2. `OfflinePage` pokazuje dedykowaną informację dla terminalnego
   `error/reloadRequired`, także gdy worker zwraca rozmiar innego pakietu.
   Nie obiecuje zawsze gotowej nowej wersji. Brak autoreloadu, ponownego
   pobierania, czyszczenia storage albo automatycznej zmiany szkicu/pending.
   Kontroler niezależnie blokuje prepare; ręczne sprawdzenie jest status-only.
3. `deploy/ops/check-backend-images.py` sprawdza **immutable imageID** dwóch
   obrazów jako API100:101 i sender65532:65532: cztery osobne próby, odczyt
   plików/katalogów, kompilacja i import wszystkich modułów app oraz tooling
   migratora bez uruchamiania migracji/lifespan/workerloop. Bez sieci, sekretów,
   mounts, pull, portów i zapisu rootfs; cleanup tylko własnych kontenerów.
   `DEPLOY.md` wymaga4/4PASS i promocji wyłącznie zgłoszonych IDs; rebuild
   unieważnia wynik. Nie zastępuje to backup/restore i heartbeat sendera.
4. Dokładny czasowy target guidancev2 ma zakres1–5400s i jedną rundę.
   Manual/EXTRA/v1 nadal1–3600s. Jawny kontekst `guidedTarget` nie jest
   serializowany i nie powstaje z dowolnego targetId w JSON. Walidacja obejmuje
   guidance/metrykę/slot/binding/stronę/wariant oraz właściwy namespace.
   Aktywny formularz wymaga bieżącego ćwiczenia, archiwum zachowuje legalną
   historyczną tożsamość. Recovery/restartSegment nie przycina4000 do3600.
   Timer bierze `seconds`, nie estymowane `workSeconds`;4100 przy celu4000
   jest legalnym odstępstwem. Zapis wymaga jawnego potwierdzenia i zachowuje
   dotychczasowe CAS/epoch/version/nonce, atomowość serii/performed/outbox.

Commity implementacji: `4282952`, `9b64892`, `fa0fcb8`; spec/plan `834cab0`,
raport mobilny `296887f`.

## Testy i recenzja

- Task2 RED37PASS/16FAIL →53offlinePASS; dodatkowe32 regresje timera/recovery
  i analiza bez uwag. Realny SQLite sprawdza identyczny szkic i attempted
  outbox przed/po panelu oraz ręcznym statusie dla trzech stanów konta.
- Task4 RED2PASS/5FAIL (UI long/checkpoint), potem10 nowych regresji.
  Focused workout+plannerworkflow: **403PASS**.
- Pierwszy pełny Flutter:1839PASS/1skip/**1FAIL** — callback multiround
  zwracał wyjątek zamiast false. Zachowano istniejący test i poprawiono
  kontrakt callbacku. Ten przebieg pozostaje RED, nie jest końcowym wynikiem.
- Niezależna recenzja `fit-reviewer` obejmowała cały diff względem bazy oraz
  Task4. Dwa Important, zero Critical: archiwalny4000 po zamianie ćwiczenia
  oraz połknięty wyjątek odmowy I/O przy imporcie. Oba odtworzonoRED→GREEN:
  pełny provider/repo/SQLite dla zamiany oraz rzeczywisty proces z UID dla
  połkniętej próby socket. Archiwum nie dostaje uprawnienia aktywnego formularza;
  checker zapamiętuje naruszenie także po przechwyceniu wyjątku przez moduł.
  Brak odłożonych Minor. Wcześniejszy limit subagentów nie uniemożliwił tej
  końcowej świeżej recenzji; nie przedstawiamy self-review jako niezależnego.

### Końcowe wyniki

| Kontrola | Wynik |
|---|---|
| Pełny `flutter analyze --no-pub` | **No issues found** |
| Pełny `flutter test --no-pub --reporter expanded` | **1841 PASS**, 1 UTC/DST SKIP, 0 FAIL |
| `TZ=Europe/Warsaw` fitness_protocol_widgets_test | **18 PASS**, obejmuje pominiętą próbę DST |
| Sonda adaptera `dart compile js` | PASS, rzeczywisty conditional import web |
| Node worker/client/push/voice | **51/51 PASS** |
| Python `tools/tests` | **110 PASS + 1 SKIP**, osobno wcześniej pominięty notification test pod Xvfb **1 PASS** |
| Python browser offline/Nginx/update/workery | **10 PASS + 3 PASS** w dwóch przebiegach |
| Jednostkowe/UID fixture checkera obrazów | **9/9 PASS** |
| Rzeczywiste obrazy runtime31c9… / migration9092… | **4/4 PASS**, 43 moduły app w każdej próbie |
| Historyczny wadliwy runtimec6b6… | oczekiwany exit1: API100 PASS, sender65532 FAIL; migrator2 PASS |
| Release Web + generator offline, sprawdzenie wersji | PASS, prywatny kompilat ze źródła `fa0fcb8`, bez override wersji |
| Wszystkie pliki nowego pakietu | **508/508** zgodnych hashów i długości, 48 611 881 bajtów, CORE31 |
| Katalog/obrazy/prefix/SQLite | **431/431**, `assets/assets/exercises/`, obrazy poza CORE; SQLite i katalog identyczne ze źródłem |
| Format zmienionego Dart / `git diff --check` | PASS |

**Jawne niezależne ograniczenie formatowania:** pełny dry-run
`dart format --output=none --set-exit-if-changed .` zwrócił exit1:501 plików,
9 wymagałoby zmiany. Wszystkie9 są niezmienione względem `d567c2f`:
notification_service, training_trend, training_trend_providers,
database_bootstrap_test, mentor_api_test, mentor_privacy_boundary_test,
training_trend_provider_test, training_trend_repository_test i training_trend_test.
Nie formatowano plików spoza zakresu. To nie jest globalny PASS formatowania.

Pierwszy release build zatrzymał się na niedostępnej sieci `pub.dev` podczas
pobierania advisories. Ponowiono wyłącznie build z `--no-pub`, na tych samych
zainstalowanych zależnościach/locku, bez instalacji lub upgrade. Zwykły
release JS+CanvasKit zakończył się powodzeniem; opcjonalny Wasm dry-run nadal
ostrzega o istniejącym flutter_secure_storage_web, nie jest to build Dart-Wasm.
Pierwszy Python browser-suite miał błąd setupu trzech workerów: brak
hostowego package_config. Dokończono je w niezmienionej kopii `git archive`
z configiem odczytanym z istniejącego kontenera;163/163 cache paths obecne,
1589 plików kopii niezmienionych. Nie przemianowano błędnych przebiegów na PASS.

Główne logi `/tmp/opencode/`: `pwa-final-verified-build.log`,
`pwa-final-build-offline.log`, `pwa-final-js-format.log`,
`pwa-final-format-all.log`, `pwa-final-tools-report.md` i wskazane w nim logi.

### Odbiór nowego kompilatu — oddzielny od Task1

Artefakt `/tmp/opencode/pwa-final-browser/web`, packageId
`05e791bfe7666f88f4d2081b75733a6a5545c6db33b75905b9239a2e94cd8fba`, main JS
SHA256 `a28fa553c7900e0cccf3c227871681df16170a0ea5426ea22125afa1d4a4fa2f`.
Prywatny loopback390×844/touch, osobny profil i syntetyczna odpowiedź sesji;
zewnętrzna sieć i wszystkie API writes abortowane, bez produkcyjnych credentials.

- UI utworzyło szablon z jednym celem Deski:seconds4000, estimate36. Timer
  pokazał domyślne4000 i faktycznie rozpoczął rundę1/1 bez edycji pracy.
- Pauza i pełne zamknięcie Chromium, ponowne otwarcie tego samego profilu,
  jawne Wznów trening i otwarcie timera: odzyskana runda pozostaje w pauzie.
- Nowy skompilowany OfflinePage sprawdzono z **kontrolowaną odpowiedzią
  bridge** reloadRequired, nie z udawanym rzeczywistym wdrożeniem A→B.
  Panel poprawny, surowy message i retry niewidoczne, trzy pending widoczne.
  „Sprawdź ponownie” zwiększyło tylko status o1; prepare0/cancel0.
- Read-only kopia SQLite **po zamknięciu aplikacji**, bez seedowania/SQL edits:
  integrity ok,431 ćwiczeń,1 sesja,0 serii/PR/performed,3 pending i lokalny
  checkpoint work4000/rounds1/paused. Target nadal4000, estymacja36.

Dowody: `/tmp/opencode/pwa-final-browser/` — `timer-running.png`,
`timer-recovered.png`, `reload-required.png`, `artifact-and-storage-proof.json`,
`snapshot-final/`, `result.json`, `recover-result.json`; harness
`/tmp/opencode/pwa-final-browser.py`. Wczesne aborty harnessu (etykieta dialogu,
etykiety pól, materializacja wartości po focusie, złożona semantyczna etykieta
settings, zamrożony obiekt bridge, odczyt version.json przez worker) zachowano
w osobnych logach i plikach `result-*-abort.json`; nie są PASS produktu.
Nie edytowano kodu produktu w odpowiedzi na te błędy selektorów/fixture.

## Decyzje i granice

- „Działaj dalej po kolei” potraktowano jako realizację czterech uzgodnionych
  usprawnień bez kolejnej rundy pytań; błędne założenie wymagałoby korekty zakresu.
- Implementacja1→2→3→4, niezależne analizy read-only równolegle; kosztem jest
  zależność wstępnego projektu od odbioru bazowego kompilatu.
- Odbiór mobilny emulowany i bez rzeczywistego auth-sync/ACK; fizyczny telefon,
  VoiceOver i synchronizacja z produkcyjnym kontem pozostają osobnym odbiorem.
- Bez nowej publikacji: wcześniejsze wdrożenie nie jest bezterminową zgodą.
  Koszt: produkcja nie otrzymuje tych poprawek przed osobną decyzją.
- Informacja aktualizacji w istniejącym Trybie offline, nie globalny watcher;
  koszt: nie jest widoczna na każdym ekranie. `reloadRequired` może oznaczać
  niepotwierdzoną tożsamość karty, nie zawsze gotową nowszą wersję. Użytkownik
  kończy pracę i odświeża świadomie; brak jednoklikowego wymuszonego reloadu.
- Bramka UID jako prepromotionCLI zamiast DockerfileRUN; koszt: operator musi
  ją jawnie wykonać i promować dokładne IDs. Nie zmieniono produkcyjnego USER.
- 5400 tylko dla dokładnego v2target; koszt: każda ścieżka restore/walidacji
  i writer musi przekazać sprawdzony kontekst. Manual/EXTRA/v1 nie zmieniają limitu.
- Po wcześniejszym limicie wykonanie przejęto inline z istniejącego pełnego
  Task2, bez ponownej implementacji; koszt to słabszy self-review tam, gdzie
  świeży agent był niedostępny. Końcowy niezależny review ostatecznie wykonano.
- Build `--no-pub` po błędzie sieci korzysta z tego samego locka/cache;
  koszt: prywatny odbiór nie sprawdza dostępności rejestru pakietów.
- Pozostawiono9 odziedziczonych rozbieżności globalnego formatowania poza
  zakresem; koszt: pełny format-check pozostaje czerwony, choć zmienione pliki
  są sformatowane. Wymagałoby to osobnego porządkowania, nie zmiany funkcjonalnej.

Nie ma gwarancji flush po zabiciu procesu ani chmurowej synchronizacji szkiców.
Abortowane żądania API i zachowane pending nie dowodzą synchronizacji/ACK.
Backend domenowy bez zmian — nie powtarzano jego pełnego Testcontainers suite.
Nie wykonywano produkcyjnego loginu, zapisów domenowych, push/AI ani migracji.
