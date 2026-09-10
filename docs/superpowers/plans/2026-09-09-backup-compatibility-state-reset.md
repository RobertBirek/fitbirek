# Backup Compatibility and State Reset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore v1 favorite flags and clear sync state/outbox on successful backup import while preserving transactional rollback.

**Architecture:** Keep all restore changes in `BackupService.importFromBytes`'s existing database transaction. Test externally observable database state through the real in-memory Drift database.

**Tech Stack:** Flutter 3.35.4, Drift, flutter_test.

---

### Task 1: Define Failing Backup Regressions

**Files:**
- Modify: `test/features/settings/backup_service_test.dart`

- [ ] **Step 1: Add a schema-v1 legacy favorite test**

Create a schema-v1 payload containing an exercise with `ulubione: true`, import it, and assert `ExerciseFavorites` contains one active row for that exercise.

- [ ] **Step 2: Seed sync state and outbox in successful restore tests**

Leave nonempty `SyncState` and `SyncOutbox` in place before import, then assert both are empty after a successful v1 or v2 restore.

- [ ] **Step 3: Preserve state during a failed restore**

Seed sync state and outbox before corrupt import data, then assert both remain after `ImportResult.success` is false.

- [ ] **Step 4: Run the focused test to verify failure**

Run: `docker run --rm -v "/opt/fit:/work" -w /work ghcr.io/cirruslabs/flutter:3.35.4 sh -c 'flutter pub get && flutter test test/features/settings/backup_service_test.dart'`

Expected: FAIL because legacy `ulubione` is not restored and successful imports do not clear local sync state/outbox.

### Task 2: Restore Legacy Favorites and Reset Sync State

**Files:**
- Modify: `lib/core/services/backup_service.dart`

- [ ] **Step 1: Clear local sync tables in the restore transaction**

Delete `db.syncOutbox` and `db.syncState` alongside the existing table cleanup before inserts begin.

- [ ] **Step 2: Restore v1 legacy favorite flags**

When `schemaVersion == 1`, derive active favorites from `data['exercises']` entries whose `ulubione` is `true`, and insert fresh `ExerciseFavorites` rows after exercises restore.

- [ ] **Step 3: Run the focused test to verify success**

Run: `docker run --rm -v "/opt/fit:/work" -w /work ghcr.io/cirruslabs/flutter:3.35.4 sh -c 'flutter pub get && dart format lib/core/services/backup_service.dart test/features/settings/backup_service_test.dart && flutter test test/features/settings/backup_service_test.dart'`

Expected: PASS.

### Task 3: Verify the Complete Suite

**Files:**
- Verify: `lib/core/services/backup_service.dart`
- Verify: `test/features/settings/backup_service_test.dart`

- [ ] **Step 1: Confirm no generated source is required**

The change uses existing Drift tables and does not alter a table definition, so do not regenerate Drift sources.

- [ ] **Step 2: Run all Flutter tests**

Run: `docker run --rm -v "/opt/fit:/work" -w /work ghcr.io/cirruslabs/flutter:3.35.4 sh -c 'flutter pub get && flutter test'`

Expected: PASS.

- [ ] **Step 3: Check the patch**

Run: `git diff --check`

Expected: no output.
