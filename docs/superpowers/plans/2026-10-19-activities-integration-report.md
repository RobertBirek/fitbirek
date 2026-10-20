# Harmonogram aktywności — wynik integracji

## Wdrożenie po integracji — 2026-10-20

**1.18.0+32 wdrożone**, po kanonicznym runtime build, rzeczywistej izolowanej
akceptacji Chromium (31PASS), świeżym backupie/restore i promocji API/sendera
przed webem. Publiczne443/443hashy PASS. Historyczne wyniki i bramki poniżej
opisują stan w chwili integracji, nie są przepisywane. Dokładne obrazy, źródło,
godziny, backup, ograniczenia sprzętu/push i rollback:
[raport wdrożenia](../../releases/2026-10-20-api-web-1.18.0-32.md).

## Zakres

Implementacja lokalna na `feat/recurring-activity-schedules`, baseline
`ea18195`. Bez commitów, push, deployu lub podnoszenia wersji aplikacji.
Produkcja nadal na poprzednim wydaniu1.17.0+31. Użytkownik zatwierdził CRUD
aktywności zewnętrznych i treningów FitBirek, dni/godzinę oraz rekomendacje.

Gotowe:

- Ustawienia → Harmonogram aktywności: dwie listy, dodawanie/edycja/usuwanie,
  wielokrotny wybór dni, godzina, opcjonalny czas trwania, włączanie/wyłączanie,
  FitBirek ze wskazanym szablonem lub swobodny.
- Wspólne terminy w klasycznym Dziś i Dziś z Mentorem, chronologicznie; tydzień
  pod istniejącym `/schedule`. Zapis terminu nie tworzy sesji, serii ani PR.
- Start z potwierdzeniem i blokadą aktywnej sesji; external zaliczane ręcznie,
  FitBirek przez rzeczywistą zakończoną sesję z serią. Błąd brakującego szablonu
  jawny, bez cichego zastąpienia. Historia zachowana po edycji/usunięciu reguły.
- Idempotentna migracja starych ustawień karate i treningu, bez nowej zgody,
  uprawnień i odtwarzania tombstone. Nieznany status PWA pozostawia migrację
  oczekującą zamiast zgadywać zgodę i wyłączać działające stare przypomnienia.
- Opcjonalne przypomnienia wg aktywności, stare wire category karate/training
  zachowane. Włączone tylko przy flagach wpisu i kategorii instalacji; nowe
  wpisy mają reminders=false. Mood/operations pozostają niezależne.
- Native finite horizon7dni/60alarmów harmonogramu i64wszystkich, jawnie
  opisany. PWA sender korzysta z aktualnie zsynchronizowanego profilu właściciela
  i ponawia walidację przed dostarczeniem; bez automatycznych wykonań i AI.
- Offline/sync/backup na istniejącym weeklySchedule, współistnienie starych
  i nowych rodzajów, nullable reference remap, odmowa stale form/epoch/deferred,
  attempted outbox zachowany bajtowo. Bez drugiej tabeli terminów.

## Weryfikacja niezależna końcowa

Flutter w przypiętym obrazie3.35.4/Dart3.9.2:

```sh
docker run --rm --network none -v /opt/fit:/app -w /app \
  fit-web:release-1.13.0-26-verified sh -c \
  'dart tools/generate_app_version.dart --check && flutter analyze --no-pub && flutter test --no-pub --reporter expanded'
```

Exit0: **1200 testów PASS**, analiza bez uwag, wygenerowana wersja zgodna.
Log `/tmp/opencode/recurring-activities-full-flutter.log`.

Backend (cwd backend): `.venv/bin/python -m pytest -q --tb=short`, exit0,
**510 passed in 662.00s**, PostgreSQL16 przez rzeczywisty Testcontainers.
Log `/tmp/opencode/recurring-activities-full-backend.log`.

Worker: `node --test tools/tests/push-worker.test.mjs backend/tests/push-activity-worker.test.mjs`,
exit0, **10 PASS**,0FAIL/skip. Log `/tmp/opencode/recurring-activities-worker.log`.

Review task1, task2, task3 i całej integracji: **SPEC PASS / QUALITY APPROVED**.
W review naprawiono dwa P2: stale occurrence po zdalnym przesunięciu (także
tam i z powrotem) oraz daty0001/9999 wywołujące overflow sendera. Regresje
i focused RED/GREEN opisane w raportach tasków.

## Ograniczenia i gotowość wydania

- Nie wykonano runtime web build ani rzeczywistej akceptacji Chromium/PWA
  tego nowego harmonogramu. UI routing/320px/tekst200% sprawdzono widgetowo.
- Nie wywoływano prawdziwego dostawcy push/AI ani urządzeń fizycznych. Mock
  pluginu, PostgreSQL i testy workera nie są dowodem dostarczenia przez system.
- Native wymaga uruchomienia aplikacji przynajmniej raz w tygodniu. Zdalna
  zmiana nie anuluje alarmu na zamkniętym/offline telefonie do pull/reconcile.
  Kolizje dynamicznych IDs i limity są błędami, nie cichym nadpisaniem/prune.
- Stare klienty zachowują nieznane rodzaje harmonogramu w kwarantannie;
  przed użyciem nowej funkcji na drugim urządzeniu zaktualizować klienta.
- Przed publikacją: osobne podbicie minor/build i generated wersji, kanoniczny
  runtime build oraz przeglądarka na izolowanym API, backup/restore, API/sender
  przed webem według DEPLOY.md. Bez zmian schematuDrift13/Alembic0010.

Wszystkie pozostałe niezmienne: zależności, locki, generated modele, Web SQLite,
ustawienia runtimeCompose/Caddy, sekrety i dane produkcyjne.
