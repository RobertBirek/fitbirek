# Recurring activities Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Zastąpić stałe karate i trening dwoma listami CRUD aktywności z dniami,
godzinami i opcjonalnym szablonem, wspólnym Dziś i niezależną zgodą reminders.
**Architecture:** Rozszerzenie istniejącego weeklySchedule o nowe rodzaje wpisów,
bez drugiej tabeli terminów. Guardowane transakcje UserCollections/outbox;
zgodność starszych reguł i legacy reminderów przez deterministyczne migracje.
**Tech Stack:** Flutter3.35.4/Dart3.9.2, Riverpod, Drift13, FastAPI/PostgreSQL.
**Spec:** `docs/superpowers/specs/2026-10-19-recurring-activities-design.md`.

## Global Constraints

- Zachować Flutter3.35.4/Dart3.9.2, Drift13/Alembic0010, deps/lock/WebSQLite.
- Bez commit/push/deploy w tym zadaniu; to wymaga osobnej dyspozycji.
- Nie czyścić danych ani ignorować nieznanego JSON, chronić attempted i hold.
- Nowe wpisy nie włączają automatycznie przypomnień/uprawnień.

## Review Focus

1. Edycja dni/godziny lub wyłączenie nie usuwa potwierdzonej historii.
2. Tombstone legacy na urządzeniu A nie wraca po starcie urządzenia B.
3. A-B-A lub zdalna zmiana w otwartym formularzu blokuje stary zapis.
4. Warsaw DST i przesunięcie terminu nie dają podwójnego push/zaliczenia.
5. Nieczytelny profil blokuje CRUD, ale nie kasuje planów i niezależnych danych.

## Task 1: Domena i trwały CRUD harmonogramu

**Files:** `lib/features/schedule/domain/{weekly_schedule,activity_schedule}.dart`,
`lib/features/schedule/data/{schedule_repository,activity_repository}.dart`,
`lib/features/schedule/providers/schedule_providers.dart`,
`lib/core/services/backup_service.dart`, `test/features/schedule/`.
**Interfaces:** Udostępnić typowane ActivityRule/ActivityDraft, snapshot lease,
create/update/delete/setEnabled, manual external completion; zachować stare API
addRule/move/complete. ScheduleOccurrence otrzymuje nullable planSyncId, time,
activityType, optional duration i external completion. Nowe UI korzysta z tego
samego scheduleWeekProvider, bez drugiej listy zapisanej w bazie.

- [ ] Testy RED poprawnych/niepoprawnych nowych rodzajów, weekdays1..7 HH:mm,
  duration/reminder limits, legacy1, stable order i finite expansion przez DST.
- [ ] Implementować kodek i rozszerzyć wystąpienia bez zmiany starych UUID.
- [ ] Testy RED transactionalCRUD+optimistic baseline+auth/deferred/held+history
  preservation+manualexternalno logs, backupnullable plan/session remap.
- [ ] Implementować guarded repo i provider z zachowaniem istniejących testów.
- [ ] Focused: `flutter test test/features/schedule test/features/settings/backup_snapshot_test.dart`
  w przypiętym obrazie, analyze; raport interfejsów i review.

## Task 2: Lista CRUD, edytor i Dziś

**Files:** `lib/features/schedule/presentation/{activity_list_page,activity_editor_page,schedule_page}.dart`,
`lib/features/schedule/presentation/widgets/today_schedule.dart`, router,
settings_page, workout_home_page, classic_today_page, mentor_page.
**Interfaces:** konsumuje ActivityRule/Draft/lease/repo i wspólny provider z task1.
Nowa trasa `/settings/activities` dla list, `/settings/activities/new` i edit
po sync UUID. `/schedule` pozostaje tygodniem, oba typy w jednym modelu.

- [ ] Testy RED realrouter settings->lists->create/edit/cancel/delete, multi-day
 6:00+18:00, swimmingSunday12:30, no session aftersave, 320px/text200%.
- [ ] Zbudować listy i formularz, czytelne loading/error/empty/staleaccount,
  zachowanie formularza przy konflikcie i brak defaultu szablonu bez wyboru.
- [ ] Zaktualizować tydzień o typ/godzinę i akcje właściwe dla rodzaju;
  legacy widoczne, konwersja do edytowalnej reguły bez zmiany historii.
- [ ] Testy RED Dziś obu wejść, ordered, starttemplate/free explicit nooverwrite,
  manualexternalno logs, Fitcompletion<=1real session, deletedtemplate honest.
- [ ] Implementować wspólny TodaySchedule z tą samą logiką start i completion.
- [ ] Focused UI/schedule/router tests + analyze i review.

## Task 3: Migracja i przypomnienia

**Files:** `lib/features/schedule/{data,providers}/` migration/reminder adapters,
`settings_provider.dart`, `notification_service.dart`, `push_settings_tile.dart`,
`backend/app/push/{queue,activity_schedule}.py`, `web/push/push-worker.js`,
backend/tests/test_push*.py oraz client native/reminder tests.
**Interfaces:** Dane activityRule i snapshot w weeklySchedule z task1;
native migration łączy pref keys notif_karate/notif_workout z regułami
deterministycznymi per profileSyncId. PWA category wire karate/training zachowane.

- [ ] RED deterministic legacy karate wt/czw20:00 reminder30, daily18:00,
  restart/twodevices/tombstone/no permission requests, unknownpush no inferredconsent.
- [ ] Guardowana migracja i adapter settings; usunąć hardcoded controllisty.
- [ ] RED native perrule reminder optin/reschedule/cancel/logout w mocks;
  mood untouched, nowe defaultoff i stable collisionfree IDs.
- [ ] Adapter native schedule. Nie przekraczać limitów platformy bez jawnego błędu.
- [ ] RED backend schedule syncedprofile belongs subuser, no legacyduplicates,
  disabled/tombstone/completed/moved/DST/stalequeuedrevalidate/dedup/TTL/invalidJSON.
- [ ] Backend dynamic enqueue+sendvalidation i worker dynamic boundedplain title/body
  (local sameorigin URL only), bez zmian transport SSRF/VAPID/consents/schema.
- [ ] Focused backend pytest+client push/native tests, analyze i review.

## Task 4: Integracja i końcowa weryfikacja

- [ ] Zestaw dwóch realnych baz: offline CRUD ->restart->sync->seconddevice,
  legacytombstone+attempted immutable, backuprestore newrefs; wszystkie rodzaje.
- [ ] Pełne Flutter analyze/test, version--check i catalog--check, pełne backend
  pytest oraz diff--check. Nie zmieniać wersji przed osobnym wydaniem.
- [ ] Końcowy review i raport z ograniczeniami fizycznych powiadomień/PWA.
- [ ] Zaktualizować docs/modules/weekly-schedule.md i wire spec rozszerzeń.

## Stan wykonania

Baseline czysty main ea18195, pełne1130Flutter/467backendPASS z poprzedniego
zadania. Praca na nowym branch feat/recurring-activity-schedules w /opt/fit.
Nie tworzono worktree bez osobnej zgody. Użytkownik przyjął rekomendacje
i polecił działać; nie powtarzamy pytań o znane dni/godziny/szablony.
Zadania sekwencyjne (współdzielone modele/provider/UI); review po każdym.
