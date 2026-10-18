# Offline Readiness Implementation Plan

> **For agentic workers:** Use subagent-driven-development, TDD and independent review. No commit/push/deploy in this task.

**Goal:** Naprawić wznowienie po reloadzie i oferować sprawdzony, jawnie pobrany
pakiet offline zamiast niezweryfikowanej obietnicy dostępności PWA.

**Architecture:** Niezależny ekran recovery korzysta z obecnego workflow.
Build generuje manifest zasobów i worker, a mały JS bridge oraz warunkowy
adapter Flutter oddzielają cache zasobów od lokalnych danych użytkownika.

**Tech Stack:** Pinned Flutter/Dart, service worker/CacheStorage/WebCrypto,
istniejący Riverpod, Docker i Python Playwright. Bez nowych zależności.

Projekt: `../specs/2026-10-17-offline-readiness-design.md`.

## Status — 2026-10-18

Implementacja A–C i lokalna integracja są zakończone. **PASS dotyczy wykonanych
scenariuszy, nie całej akceptacji urządzeń i rollout.** Wyniki, identyfikacja
finalnego obrazu i granice: [raport końcowy](../../offline-readiness-results-2026-10-18.md).
Źródłem najnowszego browser E2E jest sekcja **LATEST — 2026-10-18 UTC** w
[raporcie browser](../../offline-readiness-browser-acceptance-2026-10-17.md#latest--2026-10-18-utc-final-image-sc-font-i-worker-pin--green).
Starsze FAIL pozostają historią wcześniejszych obrazów.

`fit-web:offline-final`: **813 Flutter PASS**, analyze **0**, compiled build PASS;
pakiet **443 pliki / 46 808 551 bajtów (~44.64 MiB)**. Backend **378 PASS** i
zgodność **17/17 generated** to wcześniejsze wyniki niezmienionego zakresu,
nie nowe uruchomienia. Kod pozostaje niecommitowany, bez bumpa; produkcja
**1.14.0+27** bez zmian. Multi-user nadal odłożone.

## A. Recovery — właściciel workout

**Files:** `lib/features/workout/presentation/pages/active_session_page.dart`,
nowy widget recovery i read-only provider; testy workout/routera.

- [x] RED: istniejąca sesja+szkic po świeżym providerze na aktywnej trasie
  ma wezwanie do wznowienia, bez nowej sesji, serii, PR i czasu pracy.
- [x] Pokazać loading/retry/legacy/brak sesji/konflikt wielu sesji i użyć
  jawnego `resumeSession` z guardami konta oraz wersji odczytu.
- [x] GREEN: router reload, repeat targets/cursor, side/variant, timer pause,
  konto A→B→A i source deletion. Nie zmieniać warstwy cache ani ustawień.

## B. Manifest, worker i bridge — właściciel web/ops

**Files:** `web/` worker template i offline client; build-time tool w `tools/`;
`deploy/docker/web.Dockerfile` tylko krok generacji; testy generatora i JS.

- [x] RED generatora i workera: core root/index, HTML navigation fallback,
  missing asset/API bez HTML i brak obcych URL.
- [x] Po finalnym buildzie wyliczyć deterministyczny manifest SHA/size, content
  packageId; zintegrować custom worker pod dotychczasowym URL rejestracji.
- [x] Implementować protokół status/prepare/cancel, verified cache/progress,
  bounded requests, współdzielenie pracy, retry i błędy quota/integrity/network.
- [x] GREEN: kompletność zależna od aktualnych bajtów cache, nie trwałej flagi,
  aktualizacja manifestu i brak kasowania danych użytkownika/push cache.
- [x] Dokładnie opisać zakres precache i rozmiar pełnego pakietu.

## C. UI offline — właściciel settings

**Files:** `lib/features/offline/{domain,data,providers,presentation}/`,
ustawienia jako punkt wejścia; testy `test/features/offline/`.

- [x] RED fake bridge: unsupported/notReady/downloading/ready/error/cancel,
  format rozmiaru, jawna zgoda, retry i timeout.
- [x] Warunkowy web adapter do `window.fitOffline` bez nowych zależności;
  polling ograniczony lifecycle, bez nakładających się odczytów.
- [x] UI pokazuje stan i prawdziwy rozmiar pakietu przed prepare, progress,
  kontrolę cache i osobny stan oczekujących danych synchronizacji.
- [x] GREEN: brak automatycznego downloadu, stan nie przenosi danych konta,
  status zasobów nigdy nie udaje pełnej synchronizacji lub gwarancji iOS storage.

## D. Integracja i niezależna akceptacja

- [x] Format zmienionych Dart, analyze i pełny Flutter; zachować generated Drift13.
- [x] Build runtime z generacją manifestu i sprawdzeniem jego bajtów.
- [x] Review recovery oraz worker/cache/auth/API/route scope i bridge/UI — focused
  review **CLEAR po poprawkach**, w zakresie opisanym w raporcie końcowym.
- [x] Real browser UI prepare→ready→origin stopped→root/deep links/nieodwiedzone
  obrazy/fonty→restart→resume→jawny zapis→reconnect real API bez duplikatów.
- [x] Cancel/retry, eviction i network error bez false ready na compiled final;
  corruption/quota/protocol oraz content package/wiele kart w testach
  jednostkowych/fixture. Node **32/32**, worker browser **3/3**, updates **7/7**,
  cold **2/2**, Nginx **1/1** PASS. To różne poziomy dowodów, nie pełna macierz
  awarii w finalnym E2E.
- [x] Raport i instrukcja iPhone/Android z jawnym manual pending, bez promocji
  produkcyjnej; [checklista urządzeń](../../pwa-offline-acceptance-2026-10-17.md#ręczna-lista-ios--android--nadal-untested).
- [ ] **NOT TESTED — rollout:** migracja między dwiema różnymi pełnymi
  skompilowanymi wersjami aplikacji. Legacy/custom A→B fixture z rzeczywistym
  loaderem nie zalicza tej bramki.
- [ ] **MANUAL PENDING / UNTESTED — fizyczny iPhone/Android:** instalacja,
  cold/warm start, lock/usypianie, OS kill, storage eviction, timer i foreground
  reconnect. Restart Chromium nie zalicza telefonu ani działania w tle.

Recovery repeat cursora/timera i guardy konta mają testy native/widget;
nie ponawiano ich pełnej macierzy w finalnym compiled E2E. Ograniczenia
Blob/nested/empty-clientId, opcjonalnych backendów i Unicode pozostają jawne
w raporcie końcowym. Niniejsza aktualizacja jedynie konsoliduje istniejące dowody.
