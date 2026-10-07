# Odtworzenie recovery i wdrożenie — plan implementacji

> **Dla agentów wykonawczych:** WYMAGANA PODUMIEJĘTNOŚĆ: użyj `superpowers:subagent-driven-development` albo `superpowers:executing-plans`. Kroki używają składni list zadań (`- [ ]`).

**Cel:** Ustanowić nową zweryfikowaną bazę recovery obrazów, wydać pełne bieżące drzewo jako 1.3.0+5 i wdrożyć je bez utraty możliwości backupu oraz izolowanego odtworzenia.

**Architektura:** Bieżące obrazy produkcyjne API i Web zostają najpierw zachowane pod unikatowymi tagami. Nowe obrazy API, migratora i Web są budowane jako kandydaci, następnie nowy migrator staje się świadomie nową bazą recovery dla backupu i restore drilla. Dopiero pomyślna walidacja pozwala promować kandydatów, commitować, wysłać `main` i odtworzyć usługi przez wszystkie trzy pliki Compose.

**Stos technologiczny:** Flutter 3.35.4/Dart 3.9.2 w Dockerze, Python 3.12, PostgreSQL 16, Docker Compose, Alembic, systemd.

---

## Struktura plików

- Modyfikacja `DEPLOY.md` i `docs/web-push-deployment-2026-09-11.md`: usunięcie zbędnego realnego adresu e-mail oraz dokumentacja nowej bazy recovery.
- Modyfikacja `pubspec.yaml`, `lib/app/app_version.g.dart`, `CHANGELOG.md`: wersja wydania 1.3.0+5.
- Modyfikacja roota crontab: usunięcie flagi `-a` z tygodniowego Docker prune, aby zachować tagowane obrazy recovery.
- Wszystkie bieżące zmiany źródłowe: jeden zatwierdzony release commit po walidacji.

### Zadanie 1: Oczyść metadane wydania i ustal wersję

**Pliki:**
- Modyfikacja: `DEPLOY.md:64`
- Modyfikacja: `docs/web-push-deployment-2026-09-11.md:56`
- Modyfikacja: `pubspec.yaml:5`
- Modyfikacja: `lib/app/app_version.g.dart`
- Modyfikacja: `CHANGELOG.md:9-15`

- [ ] **Krok 1: Zastąp realne adresy w dokumentacji neutralnym opisem.**

  W `DEPLOY.md` zastąp wpis z konkretnym adresem konta tekstem `Initial account: configured owner account.`. W raporcie Web Push zastąp konkretny kontakt `owner account (redacted)`. Nie zmieniaj przykładów `@example.com` ani marki aplikacji.

- [ ] **Krok 2: Ustaw wydanie minor.**

  Zmień `version:` w `pubspec.yaml` na:

  ```yaml
  version: 1.3.0+5
  ```

  Dodaj nad dotychczasowym `1.2.0+4` sekcję `## [1.3.0+5] — 2026-10-05` opisującą Apple Health, Push, Mentora, administracyjne odzyskanie hasła oraz nową walidowaną bazę recovery obrazów.

- [ ] **Krok 3: Wygeneruj stałą wersji zatwierdzonym Dartem w kontenerze Flutter.**

  Uruchom z `/opt/fit`:

  ```bash
  docker run --rm -v /opt/fit:/app -w /app ghcr.io/cirruslabs/flutter:3.35.4@sha256:4ce1a8455a84d39b51a6e013ad9825fab651f881d02d966928aa624695b61022 dart tools/generate_app_version.dart
  docker run --rm -v /opt/fit:/app -w /app ghcr.io/cirruslabs/flutter:3.35.4@sha256:4ce1a8455a84d39b51a6e013ad9825fab651f881d02d966928aa624695b61022 dart tools/generate_app_version.dart --check
  ```

  Oczekiwany wynik: `lib/app/app_version.g.dart` zawiera `1.3.0`, `5` i `1.3.0+5`, a kontrola kończy się kodem `0`.

### Zadanie 2: Usuń przyczynę utraty obrazów recovery

**Pliki:**
- Modyfikacja: root crontab

- [ ] **Krok 1: Zapisz obecny crontab jako rollback poza repozytorium.**

  Uruchom:

  ```bash
  install -d -m 0700 /root/fit-operations-backups
  crontab -l > /root/fit-operations-backups/crontab-before-fit-recovery-20261005
  chmod 0600 /root/fit-operations-backups/crontab-before-fit-recovery-20261005
  ```

- [ ] **Krok 2: Zastąp tylko flagę agresywnego prune.**

  W istniejącym wpisie `0 3 * * 0` zmień wyłącznie `/usr/bin/docker system prune -af --filter "until=168h"` na `/usr/bin/docker system prune -f --filter "until=168h"`. Komenda bez `-a` usuwa wyłącznie zasoby dangling i zachowuje tagowane obrazy production/rollback.

- [ ] **Krok 3: Zweryfikuj wpis bez uruchamiania prune.**

  Uruchom:

  ```bash
  crontab -l
  ```

  Oczekiwany wynik: dokładnie jeden wpis tygodniowego prune zawiera `docker system prune -f` i nie zawiera `-a`.

### Zadanie 3: Zweryfikuj pełne drzewo i zbuduj kandydatów

**Pliki:**
- Modyfikacja: brak

- [ ] **Krok 1: Uruchom weryfikację backendu.**

  Uruchom z `/opt/fit/backend`:

  ```bash
  .venv/bin/python -m pytest -q
  ```

  Oczekiwany wynik: pełny zestaw przechodzi.

- [ ] **Krok 2: Zbuduj webowy etap weryfikacji.**

  Uruchom z `/opt/fit`:

  ```bash
  docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:verified .
  ```

  Oczekiwany wynik: analiza i testy Flutter przechodzą; generator wersji nie zgłasza rozbieżności.

- [ ] **Krok 3: Zbuduj obrazy kandydackie pod unikatowym znacznikiem.**

  Uruchom z `/opt/fit`:

  ```bash
  stamp=$(date -u +%Y%m%dT%H%M%SZ)
  docker build --target runtime -f backend/Dockerfile -t "fit-api:candidate-$stamp" backend
  docker build --target migration -f backend/Dockerfile -t "fit-migration:candidate-$stamp" backend
  docker build --target runtime -f deploy/docker/web.Dockerfile -t "fit-web:candidate-$stamp" .
  docker image inspect "fit-api:candidate-$stamp" "fit-migration:candidate-$stamp" "fit-web:candidate-$stamp" --format '{{.Id}} {{join .RepoTags ","}}'
  ```

  Oczekiwany wynik: trzy kandydaty mają różne identyfikatory obrazu. Zapisz `stamp` i identyfikatory w dzienniku wdrożenia bez sekretów.

### Zadanie 4: Ustanów i sprawdź nową bazę recovery

**Pliki:**
- Modyfikacja: runtime tagi Docker

- [ ] **Krok 1: Zachowaj działające obrazy API i Web pod tagami rollback.**

  Użyj tego samego `stamp`:

  ```bash
  docker tag fit-api:production "fit-api:rollback-$stamp"
  docker tag fit-web:production "fit-web:rollback-$stamp"
  docker image inspect "fit-api:rollback-$stamp" "fit-web:rollback-$stamp" --format '{{.Id}} {{join .RepoTags ","}}'
  ```

  Oczekiwany wynik: oba tagi wskazują obrazy działające przed wdrożeniem.

- [ ] **Krok 2: Oznacz zweryfikowany migrator jako nową bazę recovery.**

  Uruchom:

  ```bash
  docker tag "fit-migration:candidate-$stamp" fit-migration:production
  docker image inspect fit-api:production fit-migration:production --format '{{.Id}} {{join .RepoTags ","}}'
  ```

  Oczekiwany wynik: `fit-migration:production` wskazuje nowy kandydat; nie twierdzić, że jest to usunięty historyczny obraz.

- [ ] **Krok 3: Zweryfikuj Compose, backup i odtworzenie izolowane.**

  Uruchom:

  ```bash
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
  systemctl start fit-backup.service
  systemctl is-active --quiet fit-backup.service || systemctl show -p Result -p ExecMainStatus fit-backup.service
  systemctl start fit-restore-verify.service
  systemctl is-active --quiet fit-restore-verify.service || systemctl show -p Result -p ExecMainStatus fit-restore-verify.service
  ```

  Oczekiwany wynik: obie jednostki kończą z `Result=success` i `ExecMainStatus=0`; najnowszy manifest backupu istnieje i zawiera dwa identyfikatory obrazów.

### Zadanie 5: Commit, push i promowanie produkcyjne

**Pliki:**
- Modyfikacja: wszystkie świadomie zatwierdzone pliki bieżącego release

- [ ] **Krok 1: Przejrzyj i wystage’uj pełny zatwierdzony release.**

  Uruchom z `/opt/fit`:

  ```bash
  git diff --check
  git add -A
  git diff --cached --check
  git diff --cached --name-only
  git diff --cached -- docs/superpowers/specs/ docs/superpowers/plans/
  ```

  Oczekiwany wynik: brak błędów białych znaków, brak sekretów, a staged zestaw odpowiada świadomie zatwierdzonemu pełnemu wydaniu. Nie dodawaj katalogów buildów, `.venv`, `/docker` ani plików z sekretami.

- [ ] **Krok 2: Utwórz commit i wypchnij `main`.**

  Uruchom:

  ```bash
  git commit -m "feat: release health, push and mentor"
  git push origin main
  ```

  Oczekiwany wynik: push kończy się sukcesem; zapisz SHA commitu w raporcie wdrożenia.

- [ ] **Krok 3: Promuj kandydatów bez ponownego builda.**

  Uruchom:

  ```bash
  docker tag "fit-api:candidate-$stamp" fit-api:production
  docker tag "fit-web:candidate-$stamp" fit-web:production
  flock -w 900 /run/lock/fit-backup-restore.lock docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml run --rm --no-deps -T migrate
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml up -d --no-deps --no-build --wait --wait-timeout 180 web api push-sender
  ```

  Oczekiwany wynik: migrator kończy się sukcesem, a trzy usługi są zdrowe. W razie niepowodzenia nie uruchamiaj downgrade migracji; zatrzymaj procedurę i użyj zachowanych tagów rollback wraz z ostatnim zweryfikowanym dumpem.

### Zadanie 6: Weryfikacja po wdrożeniu

**Pliki:**
- Modyfikacja: brak

- [ ] **Krok 1: Sprawdź usługę i publiczne ścieżki wyłącznie odczytowo.**

  Uruchom:

  ```bash
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml ps -a
  curl -fsS https://fit.birek.online/api/health
  curl -fsSI https://fit.birek.online/
  curl -fsSI https://fit.birek.online/sqlite3.wasm
  curl -fsSI https://fit.birek.online/drift_worker.dart.js
  ```

  Oczekiwany wynik: migrator ma kod `0`, API/Web/Push działają, health zwraca status sukcesu, a artefakty Web są dostępne.

- [ ] **Krok 2: Sprawdź czysty stan releasu.**

  Uruchom z `/opt/fit`:

  ```bash
  git status --short
  git log -1 --oneline
  ```

  Oczekiwany wynik: brak nieoczekiwanych zmian po releasie i najnowszy commit jest wydaniem 1.3.0+5.

## Przegląd planu

- Plan pokrywa usunięcie danych osobowych, ochronę przed ponownym usunięciem tagowanych obrazów, kandydatów, backup, restore drill, commit/push, migrację i kontrole publiczne.
- Nie rekonstruuje historycznego obrazu ani nie wypisuje rozwiniętej konfiguracji Compose lub sekretów.
- Wszystkie obrazy są tagowane kandydacko przed promocją; API i Web mają zachowane tagi rollback.
