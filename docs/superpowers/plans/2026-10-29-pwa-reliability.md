# Niezawodność PWA i timera — plan implementacji

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Każdy deliverable ma osobny cykl test/review; wykonanie kolejno po poleceniu użytkownika, bez kolejnych rund pytań.

**Goal:** Zweryfikować mobilne PWA, poprawić instrukcję aktualizacji, utrwalić dual-UID gate i obsłużyć legalne długie cele.
**Architecture:** Istniejący OfflineController/bridge, nowy operacyjny checker rzeczywistych obrazów, jawny nieserializowany kontekst timera celu v2. Bez drugiego updatera i migracji.
**Tech Stack:** Flutter3.35.4/Dart3.9.2, Python stdlib/Docker, Node/Playwright z istniejących cache.
**Spec:** `docs/superpowers/specs/2026-10-29-pwa-reliability-design.md`.

## Global Constraints
- Flutter3.35.4/Dart3.9.2, dotychczasowe zależności, lock i Web SQLite bez zmian.
- Bez migracji, backfillu, zmian wire/backendu domenowego lub starego JSON planów/guidance/szkiców. Katalog431 i431 ilustracji pozostają nietknięte.
- Bez czyszczenia IndexedDB, cache, outboxa, deferred lub szkiców; bez logoutu, automatycznego odświeżania aplikacji i automatycznej zgody na pełny pakiet.
- Bez zmian ComposeUSER, sekretów, proxy, portów, sieci i produkcyjnych danych.
- Brak automatycznej publikacji tego zadania. Produkcja pozostaje1.25.1+43; przyszłe wydanie/versionbump/push/merge/deploy wymaga osobnej decyzji.
- Implementerzy nie uruchamiają własnych subagentów. Raport w planworkspace, nie force-add .superpowers; commity tylko własnego kodu/testów/docs.

## Review Focus
1. reloadRequired bywa nieznaną tożsamością karty/instalowaniem, nie potwierdzoną „nową wersją gotową”.
2. Pozornie terminalny błąd z packageId/rozmiarem nie daje zgody prepare i nie może maskować pending/conflict/unknown account.
3. APIuser czyta0700, sender65532 nie; test musi wykonać kernelową kontrolę na immutable obrazie i wykryć I/O przy importach.
4. Podsunięte targetId/rounds1 w EXTRA nie uprawnia do5400; recovery archiwalnego właściwego celu nie może utracić4000s.
5. Emulator/touch, fake session i abortowane API nie są fizycznym telefonem ani dowodem ponownej synchronizacji.

### Task 1: Odbiór mobilnego compiled PWA
**Files:** artefakty/harness wyłącznie `/tmp/opencode/pwa-reliability-mobile/`, potem publiczny `docs/reports/2026-10-29-pwa-mobile-acceptance.md`.
**Interfaces:** rzeczywisty release073e11d, `fitOffline.status/prepare({packageId})`; UI tworzy dane, storage tylko read-only po zamknięciu.
- [ ] Uruchom nowy profil390×844 touch, compiled onboarding/ćwiczenia/cele/role, zwykłe pełne zamknięcie i resume→immediate log.
- [ ] Jawne przygotowanie pakietu i offline cold-load/history/illustration; pending/outbox/szkic zachowane bez seedowania.
- [ ] Jeśli dostępne, sprawdź old1.25.0→new1.25.1 w tym samym profilu z pending/szkicem. Nie oznaczaj auth-sync ACK, jeśli API abortowane.
- [ ] Zapisz konkretne assertions/screenshots/logi/ograniczenia, realne błędy oddziel od błędów harnessu; gate przed Task2.

### Task 2: Dedykowana informacja reloadRequired
**Files:** modify `lib/features/offline/domain/offline_snapshot.dart`, `providers/offline_controller.dart`, `presentation/offline_page.dart`; tests `test/features/offline/{offline_test,offline_page_test,offline_sync_test}.dart` lub wąski nowy plik; guide `docs/modules/offline-ui.md`.
**Interfaces:** getter `OfflineSnapshot.requiresReload`, phaseerror/reloadRequired; `OfflineController.prepare(consent)` ma odmówić przed wywołaniem bridge. Bez zmian JS/publicprotocol/shell/lifecycle.
- [ ] RED parser: oba warianty terminalnego reloadRequired (bez totals i z totalsB); checking/downloading/notReady z kodem odrzucane.
- [ ] RED controller: po reloadRequired zero prepare/cancel/automatycznych retry/poll; manualrefresh=status-only. Właściwy nowy status+zgoda odblokowują normalny prepare.
- [ ] RED UI: tytuł „Aktualizacja aplikacji — wymagane odświeżenie”, kontrolowany opis możliwej aktualizacji/nieznanej wersji; brak „Ponów pobieranie”, ready lub surowego message.
- [ ] RED realSQLite: aktywny szkic+attemptedoutbox przed/po panelu i refresh byte-for-byte takie same; pending3/conflict1 widoczne, unavailable/otheraccount nie ujawnia cudzych agregatów ani nie udaje0.
- [ ] GREEN minimalnie bez globalnego bannera, fetchversionpollera, reloadbutton lub nowego właściciela lifecycle. Sprawdź320px/text200%.
- [ ] Run `flutter test --no-pub test/features/offline` + właściwe recovery/persistence regresje, analyze, changedformat; Node istniejących worker/client; commit+API/testreport i niezależny review.

### Task 3: Rzeczywista dual-UID bramka kandydatów
**Files:** create `deploy/ops/check-backend-images.py`, `tools/tests/test_backend_images.py`; modify `DEPLOY.md` sekcjaUpdates, opcjonalny krótki working set.
**Interfaces:** CLI wymagane `--runtime-image REF --migration-image REF`; resolveREFjednorazowo→imageID; cztery próby API/MIG×app100:101/sender65532:65532.
- [ ] RED testCLI fakeDocker: pinnedIDs zamiastmutabletags, cztery próby, jedna awaria/timeout/brak obrazu daje nonzero; cleanup wyłącznie własnej nazwy.
- [ ] RED rzeczywiste permissions fixture: owner100:101/push0700, appPASS senderFAIL;0755obaPASS; plik0600/nested bezsearch/missing sentinel/importsideeffect fail.
- [ ] GREEN checker stdlib: exactUID/readtraverseallfiles/importallappmodules, sentinele app.main/app.push.worker/app.push.transport/catalogJSON; migrationtoolingread/compilebezexecenv.py.
- [ ] Kontenery read-only/networknone/nocaps/nosecrets/nomount/noports/nopull, syntetyczna konfiguracja, brak workerloop/DB/API/push/I/O; timeoutcleanup/report bez rawtrace/env.
- [ ] Run stdlib unittest i realny checker na istniejących immutable API31c9…/MIG9092… w izolacji. Negatywny test na kontrolowanym złym obrazie musi odrzucić0700 dla65532 bez niejawnego skippa. Nie promować tagów.
- [ ] Dodaj obowiązkową komendę doDEPLOY build→verify→promote, immutableIDs/rebuildinvalidates; guard nie zastępuje backup/restore/heartbeat. Commit+report+niezależny review.

### Task 4: Pojedynczy guided target do5400 sekund
**Files:** modify `lib/features/workout/domain/interval_timer.dart`, `presentation/pages/interval_timer_screen.dart`, `domain/workout_guidance.dart`, `providers/workout_providers.dart`; jeśli potrzebne pass-through `active_session_page.dart`; targeted tests interval/per_set/recovery/guidance/draft.
**Interfaces:** jawny nieserializowany kontekst konfiguracji i `restore`, z domyślnym legacy/manual3600. Dokładną nazwę parametrów/stałych zapisać w raporcie. Rozszerzenie tylko przy zgodnym targetv2, 1runda.
- [ ] RED engine/restore: target3601/4000/5400PASS,5401FAIL; manualEXTRA/v13601FAIL nawetrounds1; targetmultiroundFAIL. Przygotowanie0–60/przerwa0–600 bez zmian.
- [ ] RED widget: target4000 startuje bez edycji,5400max/5401error; manual3600max; seconds≠workSeconds mierzyseconds, koniec nie zapisuje sam.
- [ ] RED persistence/provider: active+archived targetcheckpoint4000 A→B→A, flush/reopenfreshprovider/resume→immediatesave;1set/1performed/outboxatomic, duplicate/stale/foreigntarget/variant/account odmawia bez usuwania obcego szkicu.
- [ ] RED namespace: extraForms z podsuniętym targetId/1round nie uzyskuje5400. LegacyJSON/signature/checkpoint1 unchanged.
- [ ] GREEN wspólne granice engine/UI/provider, kontekst we wszystkich restore (screen,draftvalidator,recoveryrestart,updatecheckpoint), bezserializacji kontekstu/migracji/przycinania istniejących celów. Odstępstwo4100przytarget4000 dopuszczalne do5400.
- [ ] Focused workout/planner/corecovery, analyze/changedformat; commit+report; niezależny review.

### Task 5: Integracja i końcowy odbiór
**Files:** current guides `offline-ui.md`, `workout-intervals.md`, `training-sets-programs-ui.md`, publiczny `docs/reports/2026-10-29-pwa-reliability.md`; tylko potrzebne wąskie poprawki z regresjami.
- [ ] Finalny pełny Flutter/analyze, Node worker/client, tools Python z właściwym Playwrightdriver, imagecheckertesty. Backendpełny tylko jeśli zmieniono jego źródła; nie deklarować historycznychPASSjakoświeżych.
- [ ] JS compileprobe i standardowy releaseWeb+offlinegenerator z obecnej wersji bezoverride, porównajlockedSQLite/generated/catalog431/431imageprefix; prywatny artifact nie wydanie.
- [ ] Compiled nowego OfflinePage/statusflow i target4000 w lokalnejprzeglądarce; brak productionmutation/realcredentials. Wyniki mobile baselineTask1 i newbuild oznaczyć odrębnie.
- [ ] Wholebranchreview, jedna finalfixwave jeśli wymagana, scopedre-review; raportzliczbami/ograniczeniami/decyzjami, branch zachowany bezmerge/push/deploy.
