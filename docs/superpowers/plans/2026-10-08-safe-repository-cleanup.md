# Safe Repository Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce routine agent context and remove only Flutter code whose lack of runtime use is verified.

**Architecture:** Runtime contracts, Drift, synchronization, migrations and deployment remain frozen. This plan adds a concise module index and removes isolated source files or declarations that have no imports or consumers; no feature behavior or public API changes.

**Tech Stack:** Flutter/Dart, Docker Flutter verification, repository documentation.

---

### Task 1: Module working-set index

**Files:**
- Create: `docs/modules/README.md`
- Create: `docs/modules/{mentor,training,tracking,sync}.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Write a documentation review checklist.**

The index must identify the entrypoint, frozen paths, generated paths to skip by default, and exact working sets for Mentor, training, tracking and sync. It must state that `docs/superpowers/` is historical planning material, not runtime instructions.

- [ ] **Step 2: Add concise module maps.**

Each module file lists: responsibility, allowed dependencies, key entrypoints, tests, and paths that an agent normally need not read. Keep global release, artifact and production constraints in root `AGENTS.md`; add only a link to `docs/modules/README.md`.

- [ ] **Step 3: Review links and scope.**

Run: `git diff --check && git diff -- docs/modules AGENTS.md`

Expected: documentation only; no changes to deployment, source or generated files.

### Task 2: Remove isolated Flutter utilities

**Files:**
- Delete: `lib/core/widgets/stat_card.dart`
- Delete: `lib/core/sync/sync_dao.dart`
- Modify: `lib/features/home/presentation/pages/main_shell.dart`
- Test: existing Docker Web verification suite

- [ ] **Step 1: Add or update a compile-level regression check.**

No behavioral test is necessary because the symbols have no consumers. Before deletion, verify all references are limited to their declarations:

```bash
git grep -nE 'StatCard|stat_card.dart|core/sync/sync_dao.dart|TabColors' -- ':!lib/core/widgets/stat_card.dart' ':!lib/core/sync/sync_dao.dart' ':!lib/features/home/presentation/pages/main_shell.dart'
```

Expected: no output.

- [ ] **Step 2: Delete only the verified dead declarations.**

Remove both files. Remove only the `TabColors` declaration from `main_shell.dart`; retain the shell, tabs, routes and colors used by its widgets.

- [ ] **Step 3: Verify Flutter compilation and behavior.**

Run:

```bash
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:safe-cleanup .
```

Expected: version check, analyzer and full Flutter suite exit `0`.

### Task 3: Remove unused model declarations without touching Drift

**Files:**
- Modify: `lib/core/models/fitness_test.dart`
- Delete only after reference checks: unused Freezed source models and their generated files for `PersonalRecord`, `Measurement`, `MoodEntry`
- Test: model, progress, mood and database tests through Docker verification

- [ ] **Step 1: Verify each model has no consumer.**

For each type, run `git grep -n '<TypeName>' -- ':!<source>' ':!<generated-files>'`. Stop this task if an import, runtime type use, serializer registration or test consumer appears.

- [ ] **Step 2: Remove one model family at a time.**

Delete its source and generated artifacts, run `dart run build_runner build --delete-conflicting-outputs` in the pinned Docker build, and inspect the generated diff. Do not change Drift tables or `*Data` classes.

- [ ] **Step 3: Remove only `FitnessTestResult`.**

Retain `TypTestu`, its file and all Drift `FitnessTestResultData` code. Re-run code generation.

- [ ] **Step 4: Run full Web verification.**

Run the Task 2 Docker command. Expected: success with no unrelated generated changes.

### Task 4: Close the safe-cleanup release

**Files:**
- Modify: `CHANGELOG.md` only if user-visible behavior or release policy requires it

- [ ] **Step 1: Inspect all changed paths.**

Run:

```bash
git status --short
git diff --check
git diff --stat
```

- [ ] **Step 2: Verify no frozen area changed.**

Confirm no modifications under `backend/`, `deploy/`, `web/`, `assets/`, `lib/core/database/`, `lib/core/sync/`, migrations or package lockfiles.

- [ ] **Step 3: Commit only after explicit user request.**

Use a focused commit message such as `refactor: remove unused Flutter utilities`.
