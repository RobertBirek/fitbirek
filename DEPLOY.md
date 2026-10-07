# FitBirek production operations

Production: **https://fit.birek.online**, base deployed 2026-09-10;
Web Push deployed **2026-09-11 10:00:59 UTC** (12:00:59 Europe/Warsaw).
Source: `/opt/fit`; runtime: `/docker/fit`; versioned templates: `deploy/`.
Mentor **1.2.0+4 deployed 2026-09-15 07:37:51 Europe/Warsaw (05:37:51 UTC)**,
Alembic **0009**. This deploy enables configuration and local encryption only:
no provider credentials, both consent defaults false, no provider calls.
Hardware/provider acceptance and independent off-host master-key escrow remain
pending. See [deployment evidence](docs/mentor-deployment-2026-09-15.md).
All current runtime Compose commands must include **base + push + mentor**;
two-file commands in historical sections describe earlier deployments only.
Apple Zdrowie **1.1.0+3 deployed**, verified on the host at
**2026-09-13 10:36:20 Europe/Warsaw (08:36:20 UTC)**; Alembic **0008**,
final Nginx runtime includes the offline guide and human-readable build label.
Real iPhone/Shortcut acceptance remains **pending**; no production health token
or import was created during deployment. Evidence and rollback:
[deployment report](docs/apple-health-deployment-2026-09-13.md).
The authenticated Flutter PWA synchronizes through FastAPI/PostgreSQL and uses
Drift SQLite as its per-device offline store.

## Images, services and routing

- `deploy/docker/web.Dockerfile`: digest-pinned Flutter **3.35.4 / Dart 3.9.2**
  multistage build and Nginx runtime. CanvasKit is bundled locally. The
  `verification` target runs analysis and all Flutter tests; the release target
  depends on it, so failing checks prevent building a production image.
  **Serving images must use the final `runtime` target (Nginx), not `release`
  (Flutter builder).**
- `backend/Dockerfile`: serving `runtime` target and dedicated `migration`
  target with locked Alembic tooling, migrations and `backend/migrate.py`.
  Migration credentials are read internally, never passed in command arguments.
- `deploy/compose.yaml` is installed as `/docker/fit/compose.yaml`, mode `0600`.
  The installed `/docker/fit/compose.push.yaml` adds `push-sender` to `api`,
  `postgres`, `web`. The installed `/docker/fit/compose.mentor.yaml` adds the
  API-only master-key mount. Use all three files in subsequent runtime commands.
  Migration completion gates API startup; explicit `run --rm --no-deps -T migrate`
  is serialized with backup/restore before targeted updates.
- PostgreSQL data: `/docker/fit/data/postgres`. PostgreSQL joins private
  `fit_internal` only. API joins both networks, web joins external `fit_ingress`.
  Caddy reaches aliases `fit-api` and `fit-web`. No Fit host ports are published.
- Existing `/docker/caddy` owns TCP/UDP 80 and 443 and renews TLS automatically.
  `deploy/caddy-fit.caddy` documents its installed Fit host block. `/api` prefix
  is preserved. Nginx's container config `deploy/docker/web-nginx.conf` provides
  SPA fallback, `application/wasm`, and `no-cache` for workers/bootstrap/assets.

The old `deploy/fitbirek-deploy-vps.sh` is retired: it exits 2 before any old
implementation. The old host Nginx config is reference-only. Do not install
host Nginx or Certbot for this stack.

## First installation (historical, already executed without push)

Run as root. Initialization refuses to replace existing secrets.

```bash
python3 /opt/fit/deploy/ops/initialize-runtime.py
docker network create --subnet 172.26.0.0/16 --gateway 172.26.0.1 fit_ingress
docker compose -f /docker/fit/compose.yaml config --quiet
docker compose -f /docker/fit/compose.yaml build
docker compose -f /docker/fit/compose.yaml up -d --wait
python3 /opt/fit/deploy/ops/create-account.py
```

Initial account: configured owner account.
Password file:
`/docker/fit/secrets/initial-account.txt`, root `0600`, directory `0700`.
The file contains only the generated password. The wrapper feeds the existing
account CLI via stdin and suppresses terminal fallback output. There is no
public signup. Never print the password into logs or pass it in argv.

Database credentials are in root-readable `/docker/fit/.env` and
`/docker/fit/secrets/postgres-password.txt`, both `0600`. The account password
is never mounted in containers; PostgreSQL stores its Argon2 hash.

### Owner password recovery

The owner with SSH access runs this command interactively:

```bash
docker compose \
  -f /docker/fit/compose.yaml \
  -f /docker/fit/compose.push.yaml \
  -f /docker/fit/compose.mentor.yaml \
  exec api python -m app.cli.reset_password
```

The CLI asks for the account email, the new password, and its confirmation.
Do not add `-T`: the CLI requires a TTY and rejects non-interactive input. The
password never appears in argv or logs. A successful reset invalidates active
sessions and removes their push subscriptions, so every signed-in device must
log in again.

Install the Fit Caddy host block and persist external `fit_ingress` in Caddy's
Compose file. Attach the running container and reload without recreation:

```bash
python3 /opt/fit/deploy/ops/check-shared-sites.py before
docker network connect --ip 172.26.0.4 fit_ingress caddy  # first time only; already attached
docker compose -f /docker/caddy/compose.yaml config --quiet
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
python3 /opt/fit/deploy/ops/check-shared-sites.py after
```

Existing maintenance/denied hosts have baseline 503/403 responses; compare
against `/docker/fit/shared-sites-before.json` rather than assuming all return 200.

### Forwarded client IP trust

The inspected external `fit_ingress` network uses subnet **172.26.0.0/16**,
gateway **172.26.0.1**. Caddy's existing address **172.26.0.4** is pinned in
`/docker/caddy/compose.yaml` (keep its other network memberships):

```yaml
services:
  caddy:
    networks:
      proxy:
      finanse_ingress:
      fit_ingress:
        ipv4_address: 172.26.0.4
networks:
  fit_ingress:
    external: true
```

The API-only `environment` in both Fit Compose files sets
`FORWARDED_ALLOW_IPS: "172.26.0.4"`. Uvicorn already enables proxy headers;
its loopback-only default otherwise collapses login buckets onto Caddy's IP.
Trust only this exact peer, never `*` or the whole bridge subnet. Caddy's
default handling discards client-supplied forwarding headers at public ingress.

Do not recreate an existing network to apply this fix. On disaster recovery,
check for subnet conflicts and attach Caddy at `.4` before starting Fit services.
If addressing changes, update the Caddy pin and both API templates together.
The Compose pin records the already-running address and needs no Caddy restart
or reload. Apply only the API environment change:

```bash
docker compose -f /docker/caddy/compose.yaml config --quiet
docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml up -d --no-deps --no-build --force-recreate --wait --wait-timeout 180 api
# From /opt/fit: use the deployed Uvicorn version and actual container env.
docker exec -i fit-api-1 python - < deploy/ops/check-proxy-trust.py
python3 deploy/ops/check-proxy-public.py
python3 deploy/ops/check-shared-sites.py after
```

The public check logs in, reads protected session/sync endpoints, checks cookie,
Origin and CSRF protections, and logs out. It also exhausts a unique nonexistent
email bucket while varying spoofed XFF, then verifies one non-proxy, non-spoofed
database bucket. That bucket expires through normal limiter cleanup; it does
not exhaust the owner account or write domain records. Secrets remain in memory.

## Updates

### Application version and native builds

Edit only `version: x.y.z+N` in `pubspec.yaml` for each release, increasing N.
Use patch for fixes, minor for features, major for breaking changes; update the
changelog narrowly. Generate and commit `lib/app/app_version.g.dart`:

```bash
dart tools/generate_app_version.dart
dart tools/generate_app_version.dart --check
flutter analyze
flutter test
# Native (Flutter 3.35.4 / Dart 3.9.2, Android SDK and signing configured):
dart tools/generate_app_version.dart --check && flutter build apk --release
dart tools/generate_app_version.dart --check && flutter build appbundle --release
# iOS, on macOS with Xcode and signing configured:
dart tools/generate_app_version.dart --check && flutter build ipa --release
```

Do not override the version with `--build-name`, `--build-number` or version
`--dart-define` flags: generated UI values must match package metadata. Docker
checks the committed generated file before regeneration, analysis and web build.
The web artifact `version.json` must match `AppVersion.name` and `buildNumber`.

Production was built from an approved working tree containing uncommitted
account/sync implementation. Do not reset or overwrite it; Git SHA alone does
not identify this release. Review the tree and retain previous images first.

```bash
# In /opt/fit:
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:verified .
# In /opt/fit/backend:
.venv/bin/pytest -q
# Before rebuilding/promoting production tags: retain the currently running
# API/web/migration images under unique rollback tags and record their IDs.
# Backup must still see the OLD production API/migration tags in its manifest.
systemctl start fit-backup.service
# Confirm Result=success, ExecMainStatus=0, dump SHA-256 and old image IDs.
# Build candidates under unique tags; web MUST use --target runtime.
# Verify candidate contents; promote migration only after the backup, then
# run the isolated restore drill with the new migrator before production.
# Promote approved API/web only after successful migration below.
flock -w 900 /run/lock/fit-backup-restore.lock \
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml run --rm --no-deps -T migrate
# Confirm database revision, then promote the approved API/web candidate tags.
docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml up -d --no-deps --no-build --wait --wait-timeout 180 web api push-sender
```

For template changes:

```bash
install -m 0600 /opt/fit/deploy/compose.yaml /docker/fit/compose.yaml
install -m 0600 /opt/fit/deploy/compose.push.yaml /docker/fit/compose.push.yaml
install -m 0600 /opt/fit/deploy/compose.mentor.yaml /docker/fit/compose.mentor.yaml
docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
```

Resolved Compose output contains database credentials.
For rollback retain compatible previous API/web images and the pre-update dump.
Do not blindly downgrade Alembic or delete the persistent data directory.

## Backups and restoration

```bash
# Install only the units involved in the change; do not use a wildcard.
install -m 0644 /opt/fit/deploy/ops/systemd/fit-backup.service /opt/fit/deploy/ops/systemd/fit-backup.timer /opt/fit/deploy/ops/systemd/fit-restore-verify.service /opt/fit/deploy/ops/systemd/fit-restore-verify.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now fit-backup.timer fit-restore-verify.timer
systemctl start fit-backup.service
systemctl start fit-restore-verify.service
systemctl list-timers 'fit-*'
journalctl -u fit-backup.service -u fit-restore-verify.service
```

- Daily dump: **01:30 Europe/Warsaw**, before existing Restic 02:00 plus jitter.
- Monthly drill: **first Sunday at 04:30 Europe/Warsaw**.
- Both serialize with `/run/lock/fit-backup-restore.lock` (900-second wait).
- `database-backup.py` automatically includes each installed Push and Mentor
  overlay for every Compose call (including the isolated migration); base-only
  installations remain supported. The Mentor overlay mounts its key only into
  `api`, never `migrate`. It never runs `up` or disables/recreates the sender.
- Atomic timestamped bundles in `/docker/fit/data/backups` contain a custom,
  serializable-deferrable `database.dump` and `manifest.json` with SHA-256,
  Alembic revision, Git SHA, dirty-tree flag and API/migration image IDs.
  Latest 35 local bundles are retained. This protected full DR dump includes
  encrypted `mentor_credentials` rows. Local bundles are sensitive: root-owned
  `0700` directories and `0600` files (script umask `0077`). Restoring usable
  provider credentials requires the original separately escrowed master key and
  preserved account/provider binding. Flutter app export is a different boundary:
  it contains neither mentor keys nor credential ciphertexts.
- Existing encrypted Restic via `/opt/backup/restic-backup.sh` includes `/docker` and `/etc`, hence
  dumps, runtime secrets and units are covered. No shared Restic changes were
  needed. Logical dumps are the database recovery source; copies of live
  PostgreSQL files are not consistent backups.
- Restore checks checksum and revision, creates **fit_restore only**, restores,
  applies migrations, verifies one account and non-null sync IDs/positive
  versions, then drops the isolated database on success or failure. It refuses
  to replace an already-existing `fit_restore` database.
- Hardened systemd services report failures through systemd/journal and
  `fit-operations` error logs. No external email notification is configured.

### Optional mentor overlay

Storing valuable Mentor provider credentials requires an independently escrowed Fernet master key
and the optional API-only `deploy/compose.mentor.yaml` overlay. Its example
host file path, `/var/lib/fit-mentor-secrets/master.key`, is deliberately
outside `/docker` and `/etc`, so existing Restic coverage does not copy it.
Determine the API image's numeric UID:GID first with an isolated `docker run
--rm --network none fit-api:production id`; do not use root-only source-file
permissions because the API is non-root. The key is never generated in runtime
or stored in the repository, `.env`, or database dump. Read
[docs/mentor.md](docs/mentor.md). Installing the schema, web/API and master-key
overlay is authorized with no provider keys and both consents false. Storage
readiness proves local encryption only, not external AI readiness. Complete
provider, privacy, retention, rotation and hardware gates before actual provider
use. Independently encrypted off-host escrow and verified key recovery are
required before storing valuable provider credentials; local key creation does
not complete escrow. Record it as pending, without changing shared Restic.

Verify a selected recovered bundle:

```bash
bash /opt/fit/deploy/ops/restore-verify.sh /docker/fit/data/backups/TIMESTAMP
```

For disaster recovery, recover the runtime secrets, source/images and dump from
Restic, start PostgreSQL, and verify the recovered bundle in isolation before
cutover. Stop API and preserve the current production database before a manual
production restoration. The automated drill cannot overwrite production.

## Verification

### Web Push implementation status

Web Push is **deployed and enabled since 2026-09-11**. It includes
the authenticated installation registry, independent sender/scheduler, Flutter
opt-in settings, `/push/` worker and operations alert/recovery monitoring.
No VAPID secret is needed to start the existing API; only the optional sender
mounts the private key. Migrations through `0007` must precede this API version.
See [docs/web-push.md](docs/web-push.md) for the API contract, VAPID file permissions,
optional `compose.push.yaml` overlay, tests, hardware acceptance gate and limits.
The overlay is installed: include **all three** Compose files in future commands.
The push deployment originally had Alembic `0007`, a fresh sender heartbeat, protected status `ready`,
and enabled `fit-push-monitor.timer`. Actual iPhone delivery remains a manual gate.
Evidence, image IDs, checksums and rollback: [deployment report](docs/web-push-deployment-2026-09-11.md).

### Existing production checks

```bash
docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml ps -a
curl -fsS https://fit.birek.online/api/health
curl -fsSI https://fit.birek.online/
curl -fsSI https://fit.birek.online/sqlite3.wasm
curl -fsSI https://fit.birek.online/drift_worker.dart.js
curl -fsSI https://fit.birek.online/flutter_service_worker.js
curl -fsSI https://fit.birek.online/today
python3 /opt/fit/deploy/ops/check-shared-sites.py after
```

Expected: three healthy services, running sender with fresh DB heartbeat and
explicit migration exit 0 / DB revision `0009`; health `{"status":"ok"}`;
static/SPA paths 200; Wasm `application/wasm`; workers `Cache-Control: no-cache`;
valid public TLS chain. Browser verification includes login, offline mood
creation, reconnect, second-profile synchronization, logout and protected-route
redirection. The web Dio base is empty because paths begin with `/api/`;
using `/` produces a wrong protocol-relative `//api/...` URL.

Do not run domain-writing browser-smoke as part of the 1.1.0+3 production
acceptance. This release used anonymous HTTP/static checks and read-only DB
integrity checks, without login, token generation or health imports. The real
iPhone acceptance is a separate manual gate.

For a separately authorized domain-writing test, run
`python3 /opt/fit/deploy/ops/browser-smoke.py` as root with Python Playwright
and Chromium installed. It checks login in two independent browser contexts,
creates one offline mood, verifies sync/reload/logout, and tombstones its test
records. It requires no existing mood entry today. On a new account it temporarily
uses onboarding defaults and removes that test profile afterward. Failed smoke
runs require checking and cleaning their specific test records before retrying.

Remote snapshot writes use typed Drift companions with explicit nulls so that
replaying a deletion followed by revival clears the old deletion marker. The
regression test is in `test/core/sync_service_test.dart`.

The release uses JavaScript plus CanvasKit/SQLite Wasm. Flutter's optional
full-Dart-Wasm dry run reports flutter_secure_storage_web incompatibilities;
these do not prevent the selected JavaScript production build.
