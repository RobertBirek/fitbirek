# FitBirek Flutter Authentication and Offline Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Flutter client authenticate the single account, retain offline writes locally, and converge with the FitBirek sync API after reconnecting.

**Architecture:** A new local database name starts the approved clean-slate release without attempting to mutate existing browser data. Drift remains the offline store; it gains UUID-bearing user records, an outbox, and a pull cursor, while a sync service uses same-origin `/api` requests and applies server changes atomically.

**Tech Stack:** Flutter 3.35.4, Dart 3.9.2, Drift, Riverpod, Dio, GoRouter, flutter_test.

---

## File Structure

- Create: `lib/features/auth/{data,providers,presentation/pages}/` - session state and login UI.
- Create: `lib/core/api/api_client.dart` - cookie-capable same-origin Dio client and CSRF header injection.
- Create: `lib/core/sync/{sync_models,sync_dao,sync_service}.dart` - typed envelopes, persistent queue, push/pull orchestration.
- Create: `lib/core/database/tables/sync_tables.dart` - account binding, cursor, outbox, and exercise favorites.
- Modify: `lib/core/database/app_database.dart` and table/DAO files - UUIDs, timestamps, soft delete, and generated schema.
- Modify: `lib/app/router.dart`, `lib/main.dart` - auth-aware bootstrap and redirects.
- Modify: feature repositories - enqueue mutation in the same Drift transaction as local writes.
- Create: `test/features/auth/*`, `test/core/sync/*`, `test/app/router_test.dart`, and migration/repository tests.

### Task 1: Establish a clean sync-capable local database

**Files:**
- Modify: `lib/core/database/connection/native_connection.dart`
- Modify: `lib/core/database/connection/web_connection.dart`
- Create: `lib/core/database/tables/sync_tables.dart`
- Modify: `lib/core/database/app_database.dart`
- Test: `test/core/database/database_bootstrap_test.dart`

- [ ] **Step 1: Write the failing database-name and state test**

```dart
test('opens the v2 database with an empty sync state', () async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  expect(await db.syncDao.readState(), isNull);
  await db.close();
});
```

- [ ] **Step 2: Run it to verify failure**

Run: `cd /opt/fit && flutter test test/core/database/database_bootstrap_test.dart`

Expected: FAIL because `SyncDao` is unavailable.

- [ ] **Step 3: Add tables and register them**

Open `fitbirek_v2.sqlite` on native and `fitbirek_v2` on web. Do not reuse the v1 names because the approved product decision is to start with no prior local data. Add `SyncState` with a singleton primary key, `accountId`, `deviceId`, and `cursor`; add `SyncOutbox` with UUID `operationId`, entity type/id, base version, JSON payload, deleted flag, and created time; add `ExerciseFavorites` keyed by exercise ID. Register `SyncState`, `SyncOutbox`, and `ExerciseFavorites` plus `SyncDao` in `@DriftDatabase`, set schema version to 2, and regenerate sources with build_runner.

- [ ] **Step 4: Run the database test**

Run: `cd /opt/fit && dart run build_runner build --delete-conflicting-outputs && flutter test test/core/database/database_bootstrap_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/database test/core/database
git commit -m "feat: add local sync state"
```

### Task 2: Add stable identities and local mutation queueing

**Files:**
- Modify: `lib/core/database/tables/{user_profile_table,workout_tables,mood_table,measurements_table,tests_table,prs_table,plans_table}.dart`
- Modify: `lib/core/database/daos/*.dart`
- Create: `lib/core/sync/sync_models.dart`
- Create: `lib/core/sync/sync_dao.dart`
- Test: `test/core/sync/sync_dao_test.dart`

- [ ] **Step 1: Write failing atomic-write tests**

```dart
test('a local mood entry has a UUID and one outbox operation', () async {
  await repository.addMood(mood: Mood.dobry, note: 'ok');
  expect((await db.moodDao.getAll()).single.syncId, isNotEmpty);
  expect(await db.syncDao.pendingOperations(), hasLength(1));
});
```

- [ ] **Step 2: Run it to verify failure**

Run: `cd /opt/fit && flutter test test/core/sync/sync_dao_test.dart`

Expected: FAIL because sync IDs and queueing do not exist.

- [ ] **Step 3: Add explicit sync metadata**

Every user-owned row receives `syncId` (UUID), `syncVersion` (default 0), `updatedAtUtc`, and nullable `deletedAtUtc`. Keep existing integer IDs and foreign keys for UI compatibility. Convert `PlansDao.deletePlan` to set a tombstone. Keep exercises as immutable seed data and move favorite mutation from `Exercises.ulubione` to `ExerciseFavorites`. In each repository transaction, use `Uuid().v4()` at creation and call `SyncDao.enqueueUpsert` or `enqueueDelete` with the serialized domain payload.

- [ ] **Step 4: Run focused tests**

Run: `cd /opt/fit && flutter test test/core/sync/sync_dao_test.dart test/features/exercises/exercises_repository_test.dart test/features/progress/measurements_repository_test.dart`

Expected: PASS, including a seed refresh that preserves favorites.

- [ ] **Step 5: Commit**

```bash
git add lib/core/database lib/core/sync lib/features test
git commit -m "feat: queue offline FitBirek changes"
```

### Task 3: Add same-origin session client and authentication state

**Files:**
- Create: `lib/core/api/api_client.dart`
- Create: `lib/features/auth/data/auth_repository.dart`
- Create: `lib/features/auth/providers/auth_providers.dart`
- Create: `lib/features/auth/presentation/pages/login_page.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/main.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Test: `test/features/auth/auth_repository_test.dart`
- Test: `test/app/router_test.dart`

- [ ] **Step 1: Write failing auth and redirect tests**

```dart
test('signed out users are redirected to login', () async {
  final router = createRouter(authState: const AuthState.signedOut());
  expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
});

test('login sends credentials and restores the session', () async {
  await repository.login('me@example.com', 'password');
  expect(container.read(authStateProvider), const AuthState.signedIn());
});
```

- [ ] **Step 2: Run tests to verify failure**

Run: `cd /opt/fit && flutter test test/features/auth/auth_repository_test.dart test/app/router_test.dart`

Expected: FAIL because the auth feature does not exist.

- [ ] **Step 3: Implement session-aware UI**

Use `Dio` with `baseUrl: '/'` and `withCredentials: true`; make the API client first fetch `/api/auth/session`, cache the readable CSRF cookie value, and add it as `X-CSRF-Token` to mutating `/api` requests. Define `AuthState.loading`, `signedOut`, and `signedIn(accountId)`. The login page contains an email field, password field, submit button, busy state, and an error message without exposing authentication details. Add `/login` outside `StatefulShellRoute`; redirect loading state to a bootstrap view, signed-out users to `/login`, signed-in users without an onboarding profile to `/onboarding`, and all other signed-in users to `/today`. Add Android `INTERNET` permission.

- [ ] **Step 4: Run auth tests**

Run: `cd /opt/fit && flutter test test/features/auth test/app/router_test.dart`

Expected: PASS for invalid login, restored session, logout, deep links, and auth-driven redirects.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth lib/core/api lib/app lib/main.dart android test
git commit -m "feat: add FitBirek login flow"
```

### Task 4: Implement push/pull, conflict handling, and reconnect behavior

**Files:**
- Create: `lib/core/sync/sync_service.dart`
- Modify: `lib/core/providers/database_provider.dart`
- Modify: `lib/main.dart`
- Test: `test/core/sync/sync_service_test.dart`

- [ ] **Step 1: Write failing synchronization tests**

```dart
test('sync retries queued writes and advances cursor only after apply', () async {
  fakeApi.failPush = true;
  await service.synchronize();
  expect(await db.syncDao.pendingOperations(), hasLength(1));
  fakeApi.failPush = false;
  await service.synchronize();
  expect(await db.syncDao.pendingOperations(), isEmpty);
  expect((await db.syncDao.readState())!.cursor, 7);
});

test('server conflict replaces the stale local record', () async {
  await service.synchronize();
  expect((await db.moodDao.getAll()).single.note, 'server value');
});
```

- [ ] **Step 2: Run tests to verify failure**

Run: `cd /opt/fit && flutter test test/core/sync/sync_service_test.dart`

Expected: FAIL because `SyncService` does not exist.

- [ ] **Step 3: Implement the deterministic sync loop**

`SyncService.synchronize()` must return early when signed out or already running. It sends outbox batches of 100, acknowledges accepted and duplicate operations, applies conflict records from the response, then pulls pages of 500 changes until no page is full. Apply each page and persist the returned cursor in one Drift transaction. Remote deletes set tombstones locally. A 401 calls `AuthRepository.logoutLocal`; transport failures preserve the queue and expose a retryable status. Start a non-blocking sync after bootstrap, login, and connectivity recovery; never prevent local repository writes while offline.

- [ ] **Step 4: Run sync and regression tests**

Run: `cd /opt/fit && flutter test test/core/sync test/features/workout test/features/mood test/features/planner`

Expected: PASS for idempotency, partial failure, tombstones, last-write-wins conflict application, and offline writes.

- [ ] **Step 5: Commit**

```bash
git add lib/core/sync lib/core/providers lib/main.dart test
git commit -m "feat: synchronize FitBirek offline data"
```

### Task 5: Make backup/restore safe for a synchronized account

**Files:**
- Modify: `lib/core/services/backup_service.dart`
- Modify: `lib/features/settings/presentation/pages/settings_page.dart`
- Modify: `test/features/settings/backup_service_test.dart`

- [ ] **Step 1: Write failing backup boundary tests**

```dart
test('backup excludes account session and sync queue', () async {
  final exported = await service.exportBackup();
  expect(exported, isNot(contains('operationId')));
  expect(exported, isNot(contains('fit_session')));
});
```

- [ ] **Step 2: Run the test to verify failure**

Run: `cd /opt/fit && flutter test test/features/settings/backup_service_test.dart`

Expected: FAIL because the backup schema lacks the new policy.

- [ ] **Step 3: Update backup semantics**

Bump the exported backup schema to 2. Export domain rows and favorites, but exclude account binding, device ID, cursor, outbox, cookies, and auth state. After a successful restore, clear sync state and queue, retain the authenticated account, and show a confirmation that the next synchronization reconciles restored records with the server. Preserve the existing all-or-nothing Drift transaction.

- [ ] **Step 4: Run backup tests**

Run: `cd /opt/fit && flutter test test/features/settings/backup_service_test.dart`

Expected: PASS for round-trip, rollback, exclusions, and reset of sync state.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services lib/features/settings test/features/settings
git commit -m "feat: make backups sync-aware"
```
