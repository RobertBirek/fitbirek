# FitBirek Agent Guide

## Scope

- The repository root is the Flutter client (`lib/main.dart`); `backend/` is the FastAPI/PostgreSQL sync service. The client remains usable offline through local Drift SQLite and synchronizes authenticated data through `/api`.
- Keep Flutter 3.35.4 and Dart 3.9.2. Do not run `flutter upgrade` or change the toolchain without an explicit decision.
- Production source lives at `/opt/fit`; deployed Compose configuration and persistent data live under `/docker/fit`. Read `DEPLOY.md` before changing deployment files.

## Commands

- Bootstrap the Flutter client: `flutter pub get && dart run build_runner build --delete-conflicting-outputs`.
- After changing Drift declarations, Freezed models, or JSON-serializable models, regenerate with `dart run build_runner build --delete-conflicting-outputs`; generated `*.g.dart` and `*.freezed.dart` files are committed.
- Run focused Flutter tests with `flutter test path/to/test.dart`; run the client suite with `dart format . && flutter analyze && flutter test`.
- `backend/Makefile` provides `make test-health`, which creates a Python 3.12 virtual environment and installs the hash-locked dev dependencies. For a focused backend test use `.venv/bin/python -m pytest -q tests/test_sync.py`; the full backend suite is `.venv/bin/python -m pytest -q`.
- Backend tests start PostgreSQL 16 through Testcontainers, so Docker must be available. Build the production web verification stage with `docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:verified .`.

## Data And Web Artifacts

- Versioning: `pubspec.yaml` is the only manual source (`x.y.z+N`). Every release bumps the version (patch: fix, minor: feature, major: breaking change) and increases N. Run `dart tools/generate_app_version.dart`, commit `lib/app/app_version.g.dart`, and require `dart tools/generate_app_version.dart --check` before builds. Do not override versions with build-name/build-number or dart-define flags: UI and package metadata would diverge.

- Drift tables use `@DataClassName('XxxData')`; keep generated database rows separate from same-named Freezed domain models.
- `web/sqlite3.wasm` and `web/drift_worker.dart.js` must match the `sqlite3` and `drift` versions in `pubspec.lock`. Update those files whenever either package version changes.
- Exercise data is versioned in `assets/data/exercises.json` and imports incrementally. Never change an existing `cw...` ID or edit the SQLite database by hand. For spreadsheet-driven updates, run `python3 tools/xlsx_to_json.py`; do not run the deprecated `scripts/generate_exercises.py`.

## Production Safety

- `deploy/compose.yaml` is a template installed at `/docker/fit/compose.yaml`. Run `docker compose -f /docker/fit/compose.yaml config --quiet`, not plain `config`, because resolved output contains credentials.
- Caddy owns ports 80 and 443. Do not install host Nginx or Certbot, expose Fit service ports, recreate the external `fit_ingress` network, or weaken `FORWARDED_ALLOW_IPS` without following `DEPLOY.md`.
