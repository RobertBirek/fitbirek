# FitBirek production operations

Production: **https://fit.birek.online**, deployed 2026-09-10.
Source: `/opt/fit`; runtime: `/docker/fit`; versioned templates: `deploy/`.
The authenticated Flutter PWA synchronizes through FastAPI/PostgreSQL and uses
Drift SQLite as its per-device offline store.

## Images, services and routing

- `deploy/docker/web.Dockerfile`: digest-pinned Flutter **3.35.4 / Dart 3.9.2**
  multistage build and Nginx runtime. CanvasKit is bundled locally. The
  `verification` target runs analysis and all Flutter tests; the release target
  depends on it, so failing checks prevent building a production image.
- `backend/Dockerfile`: serving `runtime` target and dedicated `migration`
  target with locked Alembic tooling, migrations and `backend/migrate.py`.
  Migration credentials are read internally, never passed in command arguments.
- `deploy/compose.yaml` is installed as `/docker/fit/compose.yaml`, mode `0600`.
  Three long-running services (`api`, `postgres`, `web`) and one successful
  one-shot `migrate` service. Migration completion gates API startup.
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

## First installation (already executed)

Run as root. Initialization refuses to replace existing secrets.

```bash
python3 /opt/fit/deploy/ops/initialize-runtime.py
docker network create --subnet 172.26.0.0/16 --gateway 172.26.0.1 fit_ingress
docker compose -f /docker/fit/compose.yaml config --quiet
docker compose -f /docker/fit/compose.yaml build
docker compose -f /docker/fit/compose.yaml up -d --wait
python3 /opt/fit/deploy/ops/create-account.py
```

Initial account: **robert@birek.online**. Password file:
`/docker/fit/secrets/initial-account.txt`, root `0600`, directory `0700`.
The file contains only the generated password. The wrapper feeds the existing
account CLI via stdin and suppresses terminal fallback output. There is no
public signup. Never print the password into logs or pass it in argv.

Database credentials are in root-readable `/docker/fit/.env` and
`/docker/fit/secrets/postgres-password.txt`, both `0600`. The account password
is never mounted in containers; PostgreSQL stores its Argon2 hash.

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
docker compose -f /docker/fit/compose.yaml config --quiet
docker compose -f /docker/fit/compose.yaml up -d --no-deps --no-build --force-recreate --wait --wait-timeout 180 api
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

Production was built from an approved working tree containing uncommitted
account/sync implementation. Do not reset or overwrite it; Git SHA alone does
not identify this release. Review the tree and retain previous images first.

```bash
# In /opt/fit:
docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:verified .
# In /opt/fit/backend:
.venv/bin/pytest -q
# Runtime commands work from either directory:
docker compose -f /docker/fit/compose.yaml build
systemctl start fit-backup.service
flock -w 900 /run/lock/fit-backup-restore.lock \
  docker compose -f /docker/fit/compose.yaml run --rm --no-deps migrate
docker compose -f /docker/fit/compose.yaml up -d --wait --wait-timeout 180
```

For template changes:
`install -m 0600 /opt/fit/deploy/compose.yaml /docker/fit/compose.yaml`.
Use `config --quiet`; resolved Compose output contains database credentials.
For rollback retain compatible previous API/web images and the pre-update dump.
Do not blindly downgrade Alembic or delete the persistent data directory.

## Backups and restoration

```bash
install -m 0644 /opt/fit/deploy/ops/systemd/fit-* /etc/systemd/system/
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
- Atomic timestamped bundles in `/docker/fit/data/backups` contain a custom,
  serializable-deferrable `database.dump` and `manifest.json` with SHA-256,
  Alembic revision, Git SHA, dirty-tree flag and API/migration image IDs.
  Latest 35 local bundles are retained.
- Existing `/opt/backup/restic-backup.sh` includes `/docker` and `/etc`, hence
  dumps, runtime secrets and units are covered. No shared Restic changes were
  needed. Logical dumps are the database recovery source; copies of live
  PostgreSQL files are not consistent backups.
- Restore checks checksum and revision, creates **fit_restore only**, restores,
  applies migrations, verifies one account and non-null sync IDs/positive
  versions, then drops the isolated database on success or failure. It refuses
  to replace an already-existing `fit_restore` database.
- Hardened systemd services report failures through systemd/journal and
  `fit-operations` error logs. No external email notification is configured.

Verify a selected recovered bundle:

```bash
bash /opt/fit/deploy/ops/restore-verify.sh /docker/fit/data/backups/TIMESTAMP
```

For disaster recovery, recover the runtime secrets, source/images and dump from
Restic, start PostgreSQL, and verify the recovered bundle in isolation before
cutover. Stop API and preserve the current production database before a manual
production restoration. The automated drill cannot overwrite production.

## Verification

```bash
docker compose -f /docker/fit/compose.yaml ps -a
curl -fsS https://fit.birek.online/api/health
curl -fsSI https://fit.birek.online/
curl -fsSI https://fit.birek.online/sqlite3.wasm
curl -fsSI https://fit.birek.online/drift_worker.dart.js
curl -fsSI https://fit.birek.online/flutter_service_worker.js
curl -fsSI https://fit.birek.online/today
python3 /opt/fit/deploy/ops/check-shared-sites.py after
```

Expected: three healthy services and migration exit 0; health `{"status":"ok"}`;
static/SPA paths 200; Wasm `application/wasm`; workers `Cache-Control: no-cache`;
valid public TLS chain. Browser verification includes login, offline mood
creation, reconnect, second-profile synchronization, logout and protected-route
redirection. The web Dio base is empty because paths begin with `/api/`;
using `/` produces a wrong protocol-relative `//api/...` URL.

Run `python3 /opt/fit/deploy/ops/browser-smoke.py` as root with Python Playwright
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
