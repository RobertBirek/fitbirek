# Settings UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Krótsze i responsywne ustawienia z wyróżnionym harmonogramem.
**Architecture:** Obecne kontrolki i usługi pozostają; wydzielić małe komponenty
layoutu i strony notifications/backup/health w settingsbranch obecnego routera.
**Tech Stack:** Flutter3.35.4/Dart3.9.2, Riverpod, GoRouter, lokalny Inter.
**Spec:** `docs/superpowers/specs/2026-10-20-settings-ui-design.md`.

## Global Constraints

- Bez backendu, schematu, dependencies, wersji i deploymentu.
- Nie zmieniać zgód, sekretów, attempted payloadów ani polityki danych.
- Zachować gesture-required push enable i istniejące zabezpieczenia usług.

## Review Focus

1. Przeniesienie PushSettingsTile nie może zerwać browserpermissiongesture.
2. Health token nie pojawia się na głównym ekranie ani po back/accountchange.
3. Konflikt sync i błędy nie mogą zniknąć pod pozornym stanem „gotowa”.
4. Import nadal ostrzega o zastąpieniu i pozostawia Appleimports bez zmian.
5. Layout320/text200 nie ucina statusów, dropdownów ani dotykowych celów.

## Task 1: Panel i podstrony

**Files:** settings_page.dart, nowe settings_notifications_page.dart,
settings_backup_page.dart, settings_health_page.dart, widgets/settings_section.dart,
lib/app/router.dart, core/sync/sync_status_tile.dart (opcjonalny parametr do
ukrycia logout domyślnie zachowujący kompatybilność), core/push/push_settings_tile.dart
(zwijana instrukcja tylko, bez zmiany transportu), test/features/settings/.
**Interfaces:** istniejące SettingsPage/AppInfoTile zachowane. Trasy
/settings/notifications, /settings/backup, /settings/health pod obecnym shellem.
SettingsSection/SettingsPageLayout wspólna szerokość960+padding, bez globalnego
themeoverride. W razie braku providera summary pozostaje neutralnym linkiem.

- [ ] Testy RED produkcyjnyrouter: od settings do każdej nowej podstrony/back,
  elementy treningu, harmonogram, krótszy main, logout/footer, auth/deeplink.
- [ ] Testy RED mobile320/text200 oraz desktop1280/lightdark, brak wyjątków,
  boundedwidth960, właściwy układ kolumn i kompaktowe kontrolki.
- [ ] Minimalnie przenieść backuphandlers oraz health/push komponenty, dodać
  panel i sekcje według spec; sync tile pozwala wyłączyć wbudowany logout.
- [ ] Focused stare testy settings/auth/schedule/mentor/version/sync/push
  i nowe UI; poprawić wyłącznie oczekiwane zmiany tras w testach integracyjnych.
- [ ] Pełne Flutter analyze/test/versioncheck; raport plików i wyników.
- [ ] Spec/quality review implementacji i poprawki regresji.

## Task 2: Rzeczywista przeglądarka

- [ ] Build web runtime na osobnym immutabletag z pełną verification.
- [ ] Izolowany API/PostgreSQL i Chromium bez produkcyjnych danych; screenshoty
  settingsdesktop/mobilelightdark + detailnotifications/backup/health.
- [ ] Sprawdzenie podstron/back, focus i kompaktowości/overflow z czytelnym
  raportem ograniczeń. Bez eksportu prywatnych produkcyjnych danych/rotacji.
- [ ] Samokrytyka screenshotów: usuwać zbędne ozdobniki, zachować harmonogram
  jako jedyny wyróżniony element. Kod zmieniać wyłącznie z testem i review.
- [ ] Raport końcowy; pozostawić branch bez commit/push/deploy.

## Stan

Baseline a0ca0f8, źródło produkcyjnego1.18.0 z czystego branch feature parent.
Praca na nowym feat/settings-ui w /opt/fit bez usuwania starszego branch.
Użytkownik przyjął rekomendacje i zatwierdził powyższy kierunek w rozmowie.
