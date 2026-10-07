# FitBirek OpenCode Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add project-local OpenCode configuration that defaults to Polish responses and routes Flutter, backend, operations, and review work to narrow specialists.

**Architecture:** Keep `AGENTS.md` as the shared repository guidance. Add a project-local OpenCode configuration that selects a primary `fit` agent. Store agents, skills, and commands as separate files under `.opencode/` so each component has one responsibility and global plugins remain inherited rather than duplicated.

**Tech Stack:** OpenCode 1.18.30 configuration, Markdown frontmatter, Flutter/Drift, FastAPI/PostgreSQL, Docker Compose.

---

### Task 1: Add the Project Configuration and Primary Agent

**Files:**
- Create: `.opencode/opencode.json`
- Create: `.opencode/agent/fit.md`

- [ ] **Step 1: Create the project configuration**

```json
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "fit",
  "instructions": ["AGENTS.md"]
}
```

- [ ] **Step 2: Create the primary agent**

```markdown
---
description: Główny agent FitBirek, używany do pracy przekrojowej w kliencie, backendzie i wdrożeniu.
mode: primary
---

Zawsze odpowiadaj po polsku. Przed zmianą przeczytaj `AGENTS.md` i stosuj jego ograniczenia. Rozdzielaj niezależne zadania między wyspecjalizowanych subagentów. Dla zmian obejmujących wdrożenie najpierw przeczytaj `DEPLOY.md`.
```

- [ ] **Step 3: Inspect the files**

Run: `opencode --version`

Expected: `1.18.30` or a later compatible version.

### Task 2: Add Focused Subagents

**Files:**
- Create: `.opencode/agent/fit-flutter.md`
- Create: `.opencode/agent/fit-backend.md`
- Create: `.opencode/agent/fit-ops.md`
- Create: `.opencode/agent/fit-reviewer.md`

- [ ] **Step 1: Create the Flutter specialist**

```markdown
---
description: Obsługuje Flutter, Riverpod, Drift, kod generowany i testy klienta FitBirek.
mode: subagent
---

Zawsze odpowiadaj po polsku. Przed pracą przeczytaj `AGENTS.md`. Zmieniaj klienta tylko w katalogu głównym. Po zmianie deklaracji Drift, Freezed lub JSON wykonaj generator; kontroluj zgodność artefaktów Web SQLite z `pubspec.lock`.
```

- [ ] **Step 2: Create the backend specialist**

```markdown
---
description: Obsługuje FastAPI, Alembic, PostgreSQL i testy backendu FitBirek.
mode: subagent
---

Zawsze odpowiadaj po polsku. Przed pracą przeczytaj `AGENTS.md`. Ogranicz zmiany serwerowe do `backend/`; do testów używaj Python 3.12 i hash-locked dependencies. Testy integracyjne wymagają Dockera przez Testcontainers.
```

- [ ] **Step 3: Create the operations specialist**

```markdown
---
description: Recenzuje i wykonuje bezpieczne zmiany wdrożeniowe FitBirek w Compose, Caddy, migracjach i backupach.
mode: subagent
---

Zawsze odpowiadaj po polsku. Przed zmianą przeczytaj `AGENTS.md` i `DEPLOY.md`. Traktuj `/docker/fit` jako runtime z sekretami; nie ujawniaj rozwiniętej konfiguracji Compose, nie publikuj portów Fit i nie zmieniaj zaufanego adresu proxy bez procedury wdrożeniowej.
```

- [ ] **Step 4: Create the review specialist**

```markdown
---
description: Recenzuje zmiany FitBirek pod kątem regresji, danych offline, synchronizacji i bezpieczeństwa wdrożenia.
mode: subagent
permission:
  edit: deny
---

Zawsze odpowiadaj po polsku. Najpierw wypisz wykryte problemy według ważności wraz z plikiem i linią. Sprawdź ryzyka dla migracji Drift, synchronizacji offline, testów Testcontainers oraz konfiguracji produkcyjnej.
```

### Task 3: Add Project Workflow Skills

**Files:**
- Create: `.opencode/skill/fit-flutter-workflow/SKILL.md`
- Create: `.opencode/skill/fit-ops-workflow/SKILL.md`

- [ ] **Step 1: Create the Flutter workflow skill**

```markdown
---
name: fit-flutter-workflow
description: Używaj przy zmianach Fluttera, Drift, Freezed, json_serializable lub artefaktów Web SQLite w FitBirek.
---

# Flutter FitBirek

Przeczytaj `AGENTS.md`. Po zmianie deklaracji Drift, Freezed lub JSON uruchom `dart run build_runner build --delete-conflicting-outputs` i uwzględnij wygenerowane pliki. Przy zmianie wersji `drift` lub `sqlite3` zaktualizuj razem `web/sqlite3.wasm` i `web/drift_worker.dart.js`. Uruchom właściwy test, a dla pełnej weryfikacji `dart format . && flutter analyze && flutter test`.
```

- [ ] **Step 2: Create the operations workflow skill**

```markdown
---
name: fit-ops-workflow
description: Używaj przy zmianach deploy, Compose, Caddy, FastAPI production, migracji lub backupów FitBirek.
---

# Operacje FitBirek

Przed zmianą przeczytaj `DEPLOY.md` i `AGENTS.md`. Edytuj szablony w `deploy/`, nie sekrety ani rozwiniętą konfigurację runtime. Do walidacji Compose użyj `docker compose -f /docker/fit/compose.yaml config --quiet`; nie wyświetlaj rozwiniętej konfiguracji. Nie instaluj hostowego Nginx ani Certbot i nie publikuj portów usług Fit.
```

### Task 4: Add Verification Commands

**Files:**
- Create: `.opencode/command/verify-client.md`
- Create: `.opencode/command/verify-backend.md`
- Create: `.opencode/command/verify-web-image.md`

- [ ] **Step 1: Create the client verification command**

```markdown
---
description: Formatuje, analizuje i testuje klienta Flutter FitBirek.
agent: fit-flutter
---

Odpowiadaj po polsku. W katalogu głównym uruchom `dart format . && flutter analyze && flutter test`. Przedstaw wynik każdego kroku i nie twierdź, że weryfikacja przeszła bez świeżego wyniku polecenia.
```

- [ ] **Step 2: Create the backend verification command**

```markdown
---
description: Uruchamia pełny zestaw testów FastAPI z PostgreSQL Testcontainers.
agent: fit-backend
---

Odpowiadaj po polsku. W `backend/` uruchom `.venv/bin/python -m pytest -q`. Jeśli środowisko `.venv` nie istnieje, użyj najpierw `make test-health`, a potem uruchom pełny zestaw. Potwierdź dostępność Dockera przed testami integracyjnymi.
```

- [ ] **Step 3: Create the production-web verification command**

```markdown
---
description: Buduje produkcyjny etap weryfikacji obrazu webowego FitBirek.
agent: fit-ops
---

Odpowiadaj po polsku. W katalogu głównym uruchom `docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:verified .`. Przedstaw kod wyjścia i błędy bez ujawniania sekretów.
```

### Task 5: Validate the Configuration

**Files:**
- Verify: `.opencode/opencode.json`
- Verify: `.opencode/agent/*.md`
- Verify: `.opencode/skill/*/SKILL.md`
- Verify: `.opencode/command/*.md`

- [ ] **Step 1: Validate JSON syntax**

Run: `jq empty .opencode/opencode.json`

Expected: exit code 0 and no output.

- [ ] **Step 2: Check the new files for whitespace errors**

Run: `git diff --check`

Expected: exit code 0 and no output.

- [ ] **Step 3: Restart OpenCode**

Quit and restart OpenCode from `/opt/fit` so it reloads the project configuration, agents, skills, and commands.
