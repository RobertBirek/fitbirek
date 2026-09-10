# Production deployment evidence — 2026-09-10

## Release

- URL: https://fit.birek.online
- Flutter 3.35.4, Dart 3.9.2; digest-pinned builder and runtime images.
- Production web build runs `build_runner`, analysis and tests before release:
  **No issues found; 214 tests passed**.
- Backend: `/opt/fit/backend/.venv/bin/pytest -q`: **67 passed**.
- Alembic: **0005**; packaged migration service exited **0**.
- Three serving containers healthy; all `HostConfig.PortBindings` empty.
- PostgreSQL network `fit_internal` has `Internal=true`; ingress aliases are
  `fit-api` and `fit-web`; Caddy is attached to `fit_ingress`.

Image IDs at verification:

```text
fit-web:production       sha256:964f9d8d36d9f35cc306d3f13852190865b83763b55d157b92e3ce0889a5f485
fit-api:production       sha256:4a5bb8e997a12c8ee6815a826f2945c69c56684f582e5c58bd5c35501983332a
fit-migration:production sha256:898cdcb878d53ce5aae79629b43ec42e0c3c100853cb3c617eb131d45ec12ba2
```

## HTTPS and shared proxy

- Let's Encrypt YE1; CN fit.birek.online, valid Sep 10–Dec 9 2026.
- API health returns `{"status":"ok"}` over verified HTTPS.
- Wasm: `application/wasm`; Drift worker: `application/javascript`; both 200
  with `Cache-Control: no-cache`. SPA `/today` returns HTML.
- Caddy validation and reload passed, without recreation. Container ID:
  `5e79ffaa540bd8d47fe483ebb34c54cab3083d4ae74abddfc2f75d34753f1d95`;
  original start time remains `2026-08-21T10:23:31.162230163Z`.
- All **27** other configured host status codes match the pre-deployment
  baseline in `/docker/fit/shared-sites-before.json`, including pre-existing
  maintenance, denied and API-root responses.

## Browser and fixes

`python3 deploy/ops/browser-smoke.py` passed in headless Chromium:

1. Protected route redirects to login; login posts to same-origin API, 204.
2. Mood entry saved with browser offline.
3. Reconnect synchronizes exactly one new mood record.
4. Second independent browser receives that entry and retains it after reload.
5. Logout and protected route return to login.
6. Test profile/mood records tombstoned; final live domain record count **0**.

Browser checks uncovered and fixed two pre-existing client defects:

- Web Dio base `/` produced protocol-relative `//api/...`; changed to empty.
- Remote snapshots omitted null fields on upsert, retaining deletion markers
  after revival. Typed companions now preserve explicit nulls. A fresh-device
  replay regression failed before the fix and passes afterward.

## Backup evidence

- `fit-backup.service` and `fit-restore-verify.service`: Result=success,
  ExecMainStatus=0. Both timers enabled.
- Next daily run: Sep 11 2026, 01:30 Europe/Warsaw (before Restic).
- Next monthly run: Oct 4 2026, 04:30 Europe/Warsaw.
- Final tested bundle:
  `/docker/fit/data/backups/20260910T091745471318Z`.
- Restore output: **users=1, sync_records=8, invalid=0**. These domain records
  are smoke-test tombstones. The isolated database was removed; DB count 0.
- Refusal checks passed for production database name and corrupted dump hash.
- Initial offsite Restic snapshot **740efead** saved Fit runtime configuration,
  secrets, dump bundles and deployment templates. Existing daily Restic already
  includes `/docker` and `/etc`.

## Account and limitations

Account: robert@birek.online. Password file only:
`/docker/fit/secrets/initial-account.txt` (root:root 0600; directory 0700).
Compose and DB credential files also verified root:root 0600.

The JavaScript release is supported; full-Dart-Wasm dry run reports existing
flutter_secure_storage_web incompatibilities. Nginx configuration validation
passes with a harmless duplicate `application/wasm` mapping warning. Failure
notifications are local systemd/journal alerts, not external email alerts.

No commits or pushes were made. Existing uncommitted account/sync work remains
in the source tree; the Git SHA alone does not reproduce the deployed release.

## API-only rate-limit hotfix — 09:35 UTC

Fixed the deployed login ordering defect: admission now occurs before any
password verification, using the existing PostgreSQL upsert/row lock. The lock
remains held through verification and failure commit or successful reset, so
competing workers cannot race admission against reset. The per-client-IP,
normalized-email limit is five attempts in a rolling 15-minute window. An
already exhausted bucket returns 429 even for the correct password, without
hash verification, session creation or cookies. A permitted successful login
resets the bucket. Blocked requests do not extend the window.

Existing bounded `SKIP LOCKED` cleanup, startup/recurring durable cleanup and
trusted-origin/CSRF checks are retained. No schema or migration changes.

### TDD evidence

- Before implementation, focused regressions: **5 failed, 1 passed**. Failures
  showed correct password after exhaustion returning 204, incorrect password
  still invoking verification despite 429, early successful bypass of rolling
  expiry, **12 hash checks for 12 concurrent requests**, and competing checks
  entering while a successful fifth attempt was paused.
- After implementation, identity/limiter suite: **30 passed**.
- Final full backend command, from `/opt/fit/backend`: `.venv/bin/pytest -q`:
  **72 passed in 113.54s**. Uses isolated Testcontainers PostgreSQL.
- Coverage includes exact rolling-expiry boundary, no window extension from
  blocked requests, correct/incorrect exhausted passwords with no verification
  or cookies, absence of a created session, permitted-success reset, and twelve
  concurrent requests performing exactly five password checks.
- Successful fifth-attempt race test waits until PostgreSQL reports six
  competing requests waiting on locks, then releases verification and verifies
  the reset admits five failures and blocks the sixth.
- Existing durable cleanup, lock-time database clock and trusted-origin tests
  also pass. `git diff --check` passes.

### Build and cutover

Executed after full tests and `docker compose ... config --quiet`:

```bash
docker image tag sha256:4a5bb8e997a12c8ee6815a826f2945c69c56684f582e5c58bd5c35501983332a fit-api:pre-rate-limit-20260910
docker compose -f /docker/fit/compose.yaml build api
docker compose -f /docker/fit/compose.yaml up -d --no-deps --no-build --wait --wait-timeout 180 api
```

- Build and healthy-wait succeeded. New `fit-api:production` image ID:
  `sha256:e44f6ce13e145fdceffd803b9a4fed10fcb828440ad496144141da9a7bbc3657`.
- New API container:
  `db819a012c32f0506b9f938ff39e083daf820c07c15e9c8729d36aed6a89425a`,
  started `2026-09-10T09:35:10.444963778Z`.
- Prior API image retained as `fit-api:pre-rate-limit-20260910` for rollback.
- Pre/post inspection confirmed these container IDs **and start times unchanged**:

| Service | Container ID | Start time (UTC) |
|---|---|---|
| PostgreSQL | `c02c441441f45eef405258491f6a2e324db8d8e23d1347e012b3e9df2eb7566b` | `2026-09-10T08:28:22.786136842Z` |
| Migration | `b08d7c89ed1e86053dad8f5a3d0bad119382a4df41993de177c564e092c40a5c` | `2026-09-10T08:28:29.084225617Z` |
| Web | `61ba4bef6cd56484994f75086dcc2d678bf22b26131733c32ec2e761394fe875` | `2026-09-10T09:10:23.091643614Z` |
| Caddy | `5e79ffaa540bd8d47fe483ebb34c54cab3083d4ae74abddfc2f75d34753f1d95` | `2026-08-21T10:23:31.162230163Z` |

Compose reports API/PostgreSQL/web healthy and migration still exited 0.
Read-only SQL verification returns Alembic revision **0005**. Migration was
neither rebuilt nor rerun; no Compose, database configuration, web or proxy
changes were made.

### Deployed HTTPS auth smoke

- Verified TLS, `GET /api/health`: **200**, `{"status":"ok"}`.
- Unauthenticated session **401**; owner login **204**, two Secure/SameSite=strict
  cookies with HttpOnly on session; authenticated session **200**.
- Logout with untrusted Origin and matching CSRF: **403**. Trusted logout:
  **204**; subsequent session **401**.
- Twelve concurrent public login requests for a unique nonexistent test email:
  **five 401, seven 429**; next request **429**; no Set-Cookie on any response.
  The test bucket is left to existing durable expiry/cleanup. Owner account was
  not exhausted. Correct-password exhaustion/no-verification is covered by the
  isolated PostgreSQL regression tests above.
- Credentials read internally from the existing root-only password file;
  passwords and cookie/token values were not printed or passed in argv.

Changed source files: `backend/app/identity/router.py`,
`backend/app/security/rate_limit.py`, `backend/tests/test_identity.py`, and this
verification document. No commit, push or OpenCode configuration changes.

## Exact proxy trust hotfix — 09:49 UTC

### Root cause and configuration

- Inspected `fit_ingress`: subnet `172.26.0.0/16`, gateway `172.26.0.1`;
  Caddy `.4`, API `.3`, web `.2` before cutover.
- Running Uvicorn had proxy headers enabled but `FORWARDED_ALLOW_IPS` unset,
  effective trust `127.0.0.1`. Thus `request.client.host` remained Caddy's IP.
- Added API-only `FORWARDED_ALLOW_IPS: "172.26.0.4"` in both
  `/opt/fit/deploy/compose.yaml` and `/docker/fit/compose.yaml`.
- Pinned Caddy's existing `.4` with `ipv4_address` in its Compose network
  membership; retained `proxy` and `finanse_ingress`. External network unchanged.
- Both Compose validations and Caddy config validation passed. Caddy needed no
  reload/restart/recreation. No image build or database migration was needed.

### Tests and runtime evidence

- `docker exec -i fit-api-1 python - < deploy/ops/check-proxy-trust.py`:
  **4 failed before, 4 passed after**. Uses deployed Uvicorn and container env.
  Tests exact trust, distinct IPv4/IPv6 clients via trusted Caddy, ignored XFF
  and forwarded protocol from untrusted bridge/gateway/loopback/public peers,
  and rejection of spoofed leftmost addresses in a forwarding chain.
- Recreated only API with `up -d --no-deps --no-build --force-recreate --wait
  --wait-timeout 180 api`; healthy. New container:
  `2a124030241e091478a428482f700e3ddaf159cc139d29e99fa9558833589c78`,
  started `2026-09-10T09:49:54.907492517Z`.
- Resolved Fit Compose environment, API runtime environment, Caddy Compose pin
  and live Caddy ingress IP all verified equal to **172.26.0.4**.
- Caddy/web/PostgreSQL/migration IDs and start times match the prior table
  exactly. API/web/PostgreSQL healthy; migration remains exited 0.
- `python3 deploy/ops/check-proxy-public.py` passed over verified public HTTPS:
  health 200; unauthenticated session and sync pull 401; owner login 204;
  authenticated session and sync pull 200; Secure/SameSite=strict cookies and
  HttpOnly session; untrusted Origin and missing CSRF each 403; valid logout
  204 followed by session and sync pull 401.
- Six public login attempts for one unique nonexistent email, each with a
  different spoofed XFF: **five 401, then 429**, no cookies. Read-only SQL proved
  exactly one bucket, five failures, IP neither Caddy nor any spoofed address.
  Test bucket left to normal expiry/cleanup; owner bucket was not exhausted.
- All **27 shared hosts** matched the existing baseline both before and after
  cutover, including existing 403/404/503 and redirect responses.

Operational checks added under `deploy/ops/`; deployment/recovery guidance
updated in `DEPLOY.md` and `/docker/caddy/README.md`. No secrets printed,
domain data writes, commits or OpenCode changes.
