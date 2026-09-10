# FitBirek Production Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy the authenticated, synchronized FitBirek PWA under `https://fit.birek.online` without exposing application or database ports.

**Architecture:** A three-service Compose stack separates PostgreSQL, FastAPI, and static Flutter Web. Caddy is the only Internet-facing process, routes `/api/*` to FastAPI and all other paths to Nginx, and manages TLS; backup and restore drills use database dumps rather than raw live volume copies.

**Tech Stack:** Docker Compose, Caddy 2, Nginx Alpine, PostgreSQL 16, systemd, Restic, Flutter 3.35.4.

---

## File Structure

- Create: `deploy/docker/web.Dockerfile` - pinned Flutter build and Nginx runtime.
- Create: `deploy/docker/web-nginx.conf` - SPA, Wasm MIME, and cache policy.
- Create: `.dockerignore` - prevent development artifacts and secrets entering images.
- Create: `/docker/fit/compose.yaml` - production services, volumes, and networks.
- Create: `ops/{backup.sh,restore-verify.sh,systemd/*}` - dumps and restore drill units.
- Modify: `/docker/caddy/{compose.yaml,Caddyfile}` - isolated Fit ingress and host route.
- Modify: `DEPLOY.md`, `README.md`, `ARCHITECTURE.md` - replace unsafe direct-Nginx instructions.

### Task 1: Build and test the static Flutter Web image

**Files:**
- Create: `deploy/docker/web.Dockerfile`
- Create: `deploy/docker/web-nginx.conf`
- Create: `.dockerignore`
- Test: manual container headers check

- [ ] **Step 1: Create the failing build verification**

Run: `docker build -f deploy/docker/web.Dockerfile -t fit-web:test .`

Expected: FAIL because the Dockerfile does not exist.

- [ ] **Step 2: Implement the multi-stage image**

Use a builder pinned to Flutter `3.35.4`, run exactly `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, and `flutter build web --release`. Copy only `build/web` into a pinned Nginx Alpine runtime. Configure Nginx with `types { application/wasm wasm; }`, `try_files $uri $uri/ /index.html`, and `Cache-Control: no-cache` for `index.html`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `sqlite3.wasm`, and `drift_worker.dart.js`.

- [ ] **Step 3: Verify the image and required artifacts**

Run: `docker build -f deploy/docker/web.Dockerfile -t fit-web:test . && docker run --rm -d --name fit-web-check -p 127.0.0.1:18080:80 fit-web:test`

Expected: image builds and container starts.

Run: `curl -fsSI http://127.0.0.1:18080/sqlite3.wasm && curl -fsSI http://127.0.0.1:18080/drift_worker.dart.js`

Expected: `Content-Type: application/wasm` for Wasm and `Cache-Control: no-cache` for both files.

- [ ] **Step 4: Clean up the test container**

Run: `docker rm -f fit-web-check`

Expected: container removed.

- [ ] **Step 5: Commit**

```bash
git add deploy/docker .dockerignore
git commit -m "feat: containerize FitBirek web client"
```

### Task 2: Define the isolated production Compose stack

**Files:**
- Create: `/docker/fit/compose.yaml`
- Create: `/docker/fit/.env.example`
- Test: Compose validation

- [ ] **Step 1: Create the failing Compose validation**

Run: `docker compose -f /docker/fit/compose.yaml config`

Expected: FAIL because the stack does not exist.

- [ ] **Step 2: Add the three-service stack**

Define `postgres`, `api`, and `web`. PostgreSQL uses `/docker/fit/data/postgres` and only `fit_internal`. API uses `fit_internal` and external `fit_ingress`, has `expose: ["8000"]`, and has no `ports`. Web uses `fit_ingress`, has `expose: ["80"]`, and has no `ports`. Declare `fit_internal` as `internal: true`; declare `fit_ingress` as `external: true`. Set network aliases `fit-api` and `fit-web`. Keep actual secrets solely in `/docker/fit/.env` with mode 0600; commit only `.env.example`.

- [ ] **Step 3: Validate the manifest**

Run: `docker compose -f /docker/fit/compose.yaml config > /dev/null`

Expected: exit code 0 with no resolved secret values printed.

- [ ] **Step 4: Commit the source-controlled deployment definition**

```bash
git add /docker/fit/compose.yaml /docker/fit/.env.example
git commit -m "ops: add FitBirek production stack"
```

### Task 3: Route the domain through Caddy safely

**Files:**
- Modify: `/docker/caddy/compose.yaml`
- Modify: `/docker/caddy/Caddyfile`
- Test: Caddy validation and HTTPS checks

- [ ] **Step 1: Create the network and validate current Caddy first**

Run: `docker network create fit_ingress && docker compose -f /docker/caddy/compose.yaml exec caddy caddy validate --config /etc/caddy/Caddyfile`

Expected: network is created and current Caddy config validates before edits.

- [ ] **Step 2: Add the Fit ingress network and route**

Add `fit_ingress` as an external network to Caddy's Compose file. Add this exact Caddy block:

```caddy
fit.birek.online {
	import security_headers

	handle /api/* {
		reverse_proxy fit-api:8000
	}

	handle {
		reverse_proxy fit-web:80
	}
}
```

Do not use `handle_path`, because it would remove `/api` from FastAPI routes. Do not run the existing direct Nginx/Certbot scripts.

- [ ] **Step 3: Validate and apply Caddy changes in a maintenance window**

Run: `docker compose -f /docker/caddy/compose.yaml config > /dev/null && docker compose -f /docker/caddy/compose.yaml up -d && docker compose -f /docker/caddy/compose.yaml exec caddy caddy validate --config /etc/caddy/Caddyfile && docker compose -f /docker/caddy/compose.yaml exec caddy caddy reload --config /etc/caddy/Caddyfile`

Expected: Caddy has joined `fit_ingress`, validates, and reloads without syntax error.

- [ ] **Step 4: Verify HTTPS only after the Fit stack is healthy**

Run: `curl -fsS https://fit.birek.online/api/health && curl -fsSI https://fit.birek.online/`

Expected: health JSON is `{"status":"ok"}` and the web root returns 200 over HTTPS.

- [ ] **Step 5: Commit**

```bash
git add /docker/caddy/compose.yaml /docker/caddy/Caddyfile
git commit -m "ops: route FitBirek through Caddy"
```

### Task 4: Add consistent database dumps and restore drills

**Files:**
- Create: `ops/backup.sh`
- Create: `ops/restore-verify.sh`
- Create: `ops/systemd/fit-backup.{service,timer}`
- Create: `ops/systemd/fit-restore-verify.{service,timer}`
- Create: `ops/systemd/fit-operation-failure@.service`
- Test: controlled dump and isolated restore

- [ ] **Step 1: Write failing script safety checks**

```bash
if [[ "$RESTORE_DATABASE" != *_restore && "$RESTORE_DATABASE" != *_test ]]; then
  printf '%s\n' 'Refusing to restore outside a _restore or _test database.' >&2
  exit 2
fi
```

Run: `RESTORE_DATABASE=fitbirek /opt/fit/ops/restore-verify.sh`

Expected: exit code 2 before any Docker or PostgreSQL command is run.

- [ ] **Step 2: Implement dump and restore scripts**

`backup.sh` must call `docker compose -f /docker/fit/compose.yaml exec -T postgres pg_dump --format=custom --serializable-deferrable`, write to a temporary file under `/docker/fit/data/backups`, write SHA-256 plus Alembic revision and Git SHA to a manifest, then atomically rename the dump. `restore-verify.sh` must verify the manifest hash, create `fit_restore`, restore only into that database, run `alembic upgrade head`, query all `sync_records` for non-null IDs and positive versions, and drop `fit_restore` on success and failure.

- [ ] **Step 3: Add hardened timers**

Schedule `fit-backup.timer` for `01:30 Europe/Warsaw`, before Restic's 02:00 schedule. Schedule restore verification for the first Sunday at `04:30 Europe/Warsaw`. Both services use `UMask=0077`, `NoNewPrivileges=true`, `PrivateTmp=true`, `ProtectSystem=strict`, `ProtectHome=true`, `OnFailure=fit-operation-failure@%n.service`, and `flock -w 900 /run/lock/fit-backup-restore.lock`.

- [ ] **Step 4: Verify the drill**

Run: `sudo systemctl daemon-reload && sudo systemctl start fit-backup.service && sudo systemctl start fit-restore-verify.service && systemctl status fit-restore-verify.service --no-pager`

Expected: both services return success; no `fit_restore` database remains afterward.

- [ ] **Step 5: Commit**

```bash
git add ops
git commit -m "ops: back up and verify FitBirek data"
```

### Task 5: Replace obsolete deployment documentation and perform release verification

**Files:**
- Modify: `DEPLOY.md`
- Modify: `README.md`
- Modify: `ARCHITECTURE.md`
- Modify: `deploy/fitbirek-deploy-vps.sh`
- Modify: `deploy/fitbirek-nginx.conf`

- [ ] **Step 1: Rewrite documentation before releasing**

State that Caddy owns ports 80/443 and that the old Nginx/Certbot scripts are retired. Document local source at `/opt/fit`, infrastructure at `/docker/fit`, `docker compose build`, Alembic migration, the initial-account command, backup status checks, and the exact smoke-test commands below.

- [ ] **Step 2: Run the release verification**

Run: `cd /opt/fit && flutter analyze && flutter test && docker compose -f /docker/fit/compose.yaml build && docker compose -f /docker/fit/compose.yaml up -d && curl -fsS https://fit.birek.online/api/health && curl -fsSI https://fit.birek.online/sqlite3.wasm`

Expected: Flutter analysis/tests pass, all services are healthy, API health returns 200, and Wasm has `Content-Type: application/wasm`.

- [ ] **Step 3: Run the browser smoke test**

Open `https://fit.birek.online`, log in, create a mood entry while offline, reconnect, reload in a second browser profile, and verify one matching mood entry appears. Confirm logout returns to `/login` and direct access to `/today` redirects there.

- [ ] **Step 4: Commit documentation**

```bash
git add DEPLOY.md README.md ARCHITECTURE.md deploy
git commit -m "docs: document FitBirek production deployment"
```
