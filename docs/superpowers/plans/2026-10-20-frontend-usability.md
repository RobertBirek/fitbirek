# Frontend usability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Naprawić audytowane błędy i uprościć codzienne zadania bez zmiany danych.
**Architecture:** Zachować istniejące repozytoria i snapshoty; małe współdzielone
prymitywy responsywnego layoutu, lokalne refaktory konkretnych stron.
**Tech Stack:** Flutter3.35.4/Dart3.9.2/Riverpod/Drift13, obecne fonty i wykresy.
**Spec:** `docs/superpowers/specs/2026-10-20-frontend-usability-design.md`.

## Global Constraints

- Zachować całe przygotowane UI Ustawień i jego poprawki bezpieczeństwa.
- Bez backendu, schematu, dependencies, wersji wydania i deploymentu.
- Bez commit/push; bez rzeczywistych wywołań AI/push i danych produkcyjnych.
- Prawdziwe stany/ostrzeżenia/zgody/lease i attempted outbox bez osłabiania.

## Review Focus

1. Account/epoch A-B-A podczas formularza lub STT nie ujawnia ani nie zapisuje szkicu.
2. Rozwinięcie/zwinięcie parametrów nie kasuje niewysłanych celów/wariantu/kg.
3. Responsywny układ nie łamie scroll-to-latest ani keyboard composer.
4. Uproszczone trendy nie łączą różnych konfiguracji/stron i nie ukrywają wyłączeń.
5. Oś czasu przy powtarzających się datach i zerowym zakresie nie daje NaN/overflow.

## Task 1: Poprawność formularzy i kalkulator

**Files:** numeric_input.dart lub mały profile_input.dart, onboarding_profile_page,
edit_profile_page, user_profile_provider(repo opcjonalny guard z kompatybilnością),
run_test_page, calculator_page oraz testy onboarding/settings/progress.
**Interfaces:** Wspólna walidacja wiekuint i dodatnichfinite liczb, formatter
bez roundowania; guarded saveProfile z obowiązującym bindem w ścieżce edycji.

- [ ] RED47.5/47,5wiek,NaN/exponent,94.5->cel-only,94,5waga,wzrostdecimal,
  błędnepole bez Save/fallback, busy/doubletap/errorstays, A-B-Aqueuedwrite.
- [ ] GREENparser/form/repo, zachować onboarding nowego profilu i inne callsites.
- [ ] REDzmianatestu czyściszkic, ten samtyp zachowuje; GREENbez zmianywynikówDB.
- [ ] REDcalculator320/200%overflow->GREENelastycznelabelvalue,max640.
- [ ] Focusedtesty/analyze/report; spec+qualityreview.

## Task 2: Głos i układ Mentora

**Files:** mentor_page.dart, mentor_settings_page.dart(copy zgodne), małe widgety
Mentora, test/features/mentor/. Czytać docs/modules/mentor.md przed kodem.
**Interfaces:** transcribed draft zostaje w existing_input do jawnego_send;
bez nowego endpointu/providerrequestów i bez rozszerzania prywatnego kontekstu.

- [ ] REDmockSTT tekst doedytora, chatPOST0przedSend,1poSend poprawionego tekstu,
  cancel/errors/unknownoutcome retry/accountswitch/draft noleak.
- [ ] GREENstop autosend zachowując ledger i consentguards.
- [ ] REDunconfiguredToday widoczny powód/ustawienia/jedenofflineCTA, brakStop,
  configuredchatreading/newreply w320/200%+keyboard; GREENnaturalnyflow.
- [ ] FocusedMentor/schedule/routertests+analyze/report; review.

## Task 3: Formy, szablony, trening i Postępy

**Files:** core/widgets mały contentlayout, template_editor/templates/planner,
activitylist/editor, measurementsform, exercisecatalog/detail, active_session
variantcontrol, summary, progress/trends, weight_line_chart/test_score_chart.
**Interfaces:** layoutprymitywy bez domeny/state; istniejąceprescriptioncontrollers,
lease/Save/logSet i validacje pozostają; rozsądne zgrupowanie plików zamiast
wymiany architektury. Testy pod właściwym modułem.

- [ ] REDszablon2+ćwiczenia visibleSave/zwijaniepreservessketch/invalidautoexpand,
  keyboardtext2/desktopmeasure; GREENfooter/zwijanie/2panel/wąsko1.
- [ ] RED miara pozostałych formularzy, favoritea11ylabel i varianttarget48;
  GREENprymityw i konkretne komponenty, limityilustracji.
- [ ] Reprodukcje REDkatalog ostrzeżenia/keyboard +summarydługi/text2;
  GREENjeden naturalnyscroll tamgdziepotwierdzone, zachowaćostrzeżenia.
- [ ] REDTrendy wynikpierwszy/wyłączenia nadal dostępne/noNULLcwmain;
  GREENcopygrupymethodology bez zmiany obliczeń.
- [ ] RED chart dates1/2/20,Xreflecttime,duplicate/same-day/singlepoint,
  GREENdataXfinite i accessiblelist.
- [ ] RED errorcases trzechstron retry/back nofakedata;
  GREENloading/error UI. Focusedtesty/analyze/report;review.

## Task 4: Integracja i ponowny browser

- [ ] FullFlutteranalyze/test/versioncheck, diffcheck; backendniezmienionyniepowtarzać.
- [ ] Wholefeature spec/qualityreview, poprawki wszystkich ważnych regresji.
- [ ] Immutablewebbuildfulverification, izolowanyAPI/Postgres/Chromium z fikcyjnym
  kontem. Before/afteraudit:1254baseline + nowetestcounts faktyczne, nie hardcode.
- [ ] Profilfractional/comma/save, agevalidation, kalkulator320/largewidget,
  Mentor unavailable, szablon3goals/Save, wariant/favorite, summarylong/trends,
  desktopmobilelightdark. Nie udawać browserTextScaler200CSSzoomem.
- [ ] Końcowy raport poprawione/pozostające z linkami do zrzutów. Bez deploy/push.

## Stan i sekwencja

BaselineGit a0ca0f8 z niezatwierdzonym, zaakceptowanym panelemUstawień1254PASS;
nowybranchfeat/frontend-usability obejmuje te zmiany bez utraty danych.
Auditreportreadonlysourcebefore1341files. Zadania1-3sekwencyjne ze względu
na testyintegracyjne/layoutprymitywy. Użytkownik zatwierdził działanie bez
dalszych pytań o rekomendacje. Rekomendowane delegowanie z osobnym review.
