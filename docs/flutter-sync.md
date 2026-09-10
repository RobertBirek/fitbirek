# Flutter sync implementation

The implementation follows `backend/app/sync/{schemas,service,router}.py`.
The older plan snippets are not the wire contract.

## Persistence and identity

- Database schema 4 upgrades the existing `fitbirek_v2` database in place.
- `SyncState` retains account binding, device ID, cursor and offline-access lock.
  A different account cannot use the bound database.
- Nine typed entity kinds use UUID identities. Session/set links use
  `sessionSyncId` on the wire and resolve to device-local integer keys on pull.
- New profiles and favorites use account-derived UUIDv5 identities, avoiding
  independent singleton records on different devices.
- Unsent mutations coalesce. Once attempted, a request is immutable and durable.
  Later local edits occupy a separate outbox entry. Acknowledgements remove only
  the acknowledged operation and rebase unsent edits without replacing their data.
- `SyncDeferredRecords` retains the latest complete server snapshot for each
  dirty entity. Snapshot persistence, validation and cursor advancement share a
  transaction. Final acknowledgements reconcile snapshots atomically: an older
  accepted duplicate does not discard newer server state, while newer accepted
  local edits supersede older snapshots. Later queued edits remain protected.
- Upgrades from schema 2/3 reset the pull cursor to replay history, recovering
  payloads the previous implementation could discard. Equal-version clean
  records can apply during replay; lower versions still cannot overwrite them.

## Orchestration and conflict policy

- Auth bootstrap seeds exercises before starting synchronization.
- Startup, committed local changes, manual retry and a 15-second connectivity
  probe trigger one non-overlapping service pass. Network failure retains the queue.
- Production passes check the remote session account before sending user data.
- Push sends at most 100 operations and at most one operation per entity per batch.
- A rejected batch only acknowledges the IDs returned in `accepted`; all
  unreported operations remain queued. Normal version conflicts accept server
  state, preserving and rebasing later local edits.
- `indeterminateOperation` and `operationReuse` retain the exact request and show
  a verification-required status. They are never automatically assigned new IDs
  or treated as acknowledgements. Administrator investigation is required if
  the backend continues returning these markers.
- Pull pages contain at most 500 changes. Parents apply before children. Entity
  application and cursor advancement share a transaction; malformed data or a
  missing FK rolls back the page. Older versions do not overwrite newer data.

## Active workout lifecycle

- `finishSession` and `logSet` check for a missing/tombstoned parent inside their
  write transaction and reject without changing either domain data or outbox.
- The active-workout notifier observes its current session. Restore, pulled
  deletion, or remote completion clears the active in-memory state. A rejected
  write also clears it if the watch notification has not arrived yet.
- Asynchronous completions are bound to the session generation so an old finish
  cannot clear a replacement workout. Set/PR writes share a transaction.
- A deferred remote session tombstone blocks local writes immediately. Pending
  finishes are not rebased into implicit undeletes; definitive deletion wins.
  A confirmed newer accepted live operation can reconcile a provisional older
  tombstone without overwriting later queued payload edits.

## Authentication and backup

- First login requires the network. A previously authenticated, unlocked account
  may reopen offline when the session request fails without an HTTP response.
- A genuine 401 locks offline access and returns to login. Explicit logout
  persists the lock before waiting for in-flight sync, and retains account-owned
  data and pending operations.
  A stale server cookie cannot undo the explicit local logout on restart.
- Backup import retains binding/cursor and attempted operations. Replacement
  deletes and restored upserts are queued transactionally; singleton identities
  and known versions are retained. Restored sessions/sets get new UUIDs with
  remapped links. Old sessions remain as hidden tombstones with their original
  local IDs, so not-yet-pulled remote children still resolve their parent UUID.
  Since the backend has no cascade, late live children of tombstoned sessions
  are hidden and explicitly queued for deletion in the pull transaction.
  Explicit restore intent may rebase after a definitive version
  rejection, using a fresh operation ID. Indeterminate outcomes still block.
- Backup export excludes tombstones. Sync metadata and authentication state are
  not portable backup data.

## Native cookie persistence

- Only the native conditional cookie-store implementation uses
  `flutter_secure_storage`. It persists `fit_session` and `fit_csrf` together
  with absolute expiry timestamps, and awaits hydration before API requests.
- `Max-Age` takes precedence over `Expires`. Login now includes the actual
  database session expiry in both cookies. Legacy responses without expiry
  have a finite 24-hour native retention limit; reopening never extends it.
- Expired, deleted, corrupt or rejected (401) credentials are removed. Network
  failures retain unexpired credentials for authenticated reconnect.
- Explicit logout clears secure persistence before waiting for the HTTP
  response. Only the logout request retains a transient credential snapshot for
  server revocation. Response generations prevent late requests from restoring
  credentials after logout. Requests to other origins do not carry these tokens.
- The web implementation uses browser-managed cookies and never reads or writes
  the HttpOnly session token through Dart or secure storage. The readable CSRF
  cookie is used only for the CSRF request header.

## Verification

Run inside `ghcr.io/cirruslabs/flutter:3.35.4`:

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test --no-pub --reporter expanded
flutter analyze --no-pub
flutter build web --release --no-pub
```

Focused coverage is in `test/core/sync_service_test.dart`,
`test/core/sync_persistence_test.dart`, `test/core/sync_status_tile_test.dart`,
`test/features/auth/offline_auth_test.dart` and the existing backup/auth/router
tests. Restore/FK and secure-cookie regressions are in
`test/core/restore_sync_regression_test.dart` and
`test/features/auth/native_cookie_store_test.dart`. The small backend expiry
contract change is covered by `backend/tests/test_identity.py`.
Active-session and deferred-acknowledgement regressions are in
`test/features/workout/deleted_session_test.dart` and
`test/core/deferred_sync_test.dart`, including SQLite restart and v3 migration.
Release-device/browser testing against a running deployment is a separate
verification step; compiling the web bundle does not establish live sync health.
