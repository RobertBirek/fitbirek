# Mentor Context Consent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user attach a bounded, reviewed summary of training, profile, mass, one note, and Apple Health aggregates to one Mentor response after separate consent.

**Architecture:** The server owns consents and reads only already synchronized records belonging to the authenticated account. It renders a short-lived projection in memory for one Responses request. Flutter requests a preview, submits opaque selection IDs, and never persists the preview or selections.

**Tech Stack:** FastAPI, SQLAlchemy async, PostgreSQL JSONB sync records, Flutter, Riverpod, Drift boundary tests, Testcontainers.

---

## File map

- Modify: `backend/app/mentor/schemas.py` — context-selection request models.
- Modify: `backend/app/mentor/context.py` — allowlisted projection and preview options.
- Modify: `backend/app/mentor/router.py` — authenticated `GET /context-options`.
- Modify: `backend/app/mentor/service.py` — consent/revision checks before provider call.
- Modify: `backend/tests/test_mentor.py`, `backend/tests/test_mentor_vendor.py`; create `backend/tests/test_mentor_context.py`.
- Modify: `lib/features/mentor/data/mentor_models.dart`, `mentor_api.dart`, `mentor_operations.dart`.
- Create: `lib/features/mentor/presentation/widgets/mentor_context_composer.dart`.
- Modify: `lib/features/mentor/presentation/pages/mentor_page.dart`, `mentor_settings_page.dart`.
- Create: `test/features/mentor/mentor_context_composer_test.dart`, `mentor_privacy_boundary_test.dart`.
- Modify: `test/features/mentor/mentor_operations_test.dart`, `mentor_flow_test.dart`, `test/features/settings/backup_service_test.dart`, `docs/mentor.md`, `docs/apple-health-contract.md`.

### Task 1: Backend context contract and preview endpoint

**Files:**
- Modify: `backend/app/mentor/schemas.py`
- Modify: `backend/app/mentor/router.py`
- Test: `backend/tests/test_mentor_context.py`

- [ ] **Step 1: Write failing preview endpoint tests.**

  Assert unauthenticated access gets `401`; authenticated access gets no provider request and returns only current-account options. A response has this shape:

  ```json
  {"settings_revision": 4, "options": {"training": {"available": true, "summary": "Ostatnie 12 tygodni"}, "weight": [], "workout_notes": [], "apple_health": {"available": false}}}
  ```

  A weight/note entry must use an opaque `selection_id` and a human preview. It must not expose sync IDs, Apple import tokens, raw JSON payloads, or another account’s data.

- [ ] **Step 2: Run the focused endpoint test and confirm RED.**

  Run: `cd backend && .venv/bin/python -m pytest -q tests/test_mentor_context.py::test_context_options_are_private_and_provider_free`

  Expected: FAIL because the route and schemas do not exist.

- [ ] **Step 3: Add strict request models.**

  `MessageInput` gains optional `settings_revision: int` and `context: ContextSelection`. `ContextSelection` has booleans `training`, `profile`, `apple_health`, plus optional `WeightSelection(source, selection_id)` and `NoteSelection(selection_id)`. Forbid extra fields; do not accept text, numeric health values, UUIDs, or raw sync payloads from Flutter.

- [ ] **Step 4: Implement authenticated options.**

  Create signed, request-independent opaque IDs with `HMAC-SHA256` over user ID, record ID, category, and `settings.revision`; verify them server-side before reading a source record. The endpoint reads only records already synchronized to this user and returns previews limited to 500 visible note characters.

- [ ] **Step 5: Run focused endpoint tests and confirm GREEN.**

  Run: `cd backend && .venv/bin/python -m pytest -q tests/test_mentor_context.py -k context_options`

  Expected: PASS with no call to the mocked OpenAI transport.

- [ ] **Step 6: Commit the preview contract.**

  ```bash
  git add backend/app/mentor/schemas.py backend/app/mentor/router.py backend/tests/test_mentor_context.py
  git commit -m "feat: preview mentor context choices"
  ```

### Task 2: Deterministic projection and consent enforcement

**Files:**
- Modify: `backend/app/mentor/context.py`
- Modify: `backend/app/mentor/service.py`
- Test: `backend/tests/test_mentor_context.py`
- Test: `backend/tests/test_mentor.py`

- [ ] **Step 1: Write failing projection tests.**

  Build fixtures for two users and assert each rule: at most 24 completed sessions within 12 weeks; no UUIDs, free-text notes, profile name, raw sync payload, Apple token, or Apple source reaches the provider input; profile contains only age, goal, and optional height; selected mass has one value/date/source; selected note is at most 500 characters; Apple context contains only a 7-day step aggregate and weight trend.

- [ ] **Step 2: Add consent and revision failure tests.**

  For every category, request it without that category’s stored consent and assert `409` before `openai_reply`. Change settings revision after reservation and assert no assistant message is written. Assert removing consent invalidates a pending call and never performs a second provider call.

- [ ] **Step 3: Run the context tests and confirm RED.**

  Run: `cd backend && .venv/bin/python -m pytest -q tests/test_mentor_context.py tests/test_mentor.py -k 'context or consent'`

  Expected: FAIL because `training_context()` has no category model or consent checks.

- [ ] **Step 4: Replace raw context assembly with a bounded projector.**

  Implement:

  ```python
  async def project_context(db, user_id, selection, consents) -> dict:
      """Return a bounded provider payload; never persist it."""
  ```

  Use explicit entity-type allowlists (`workoutSession`, `workoutSet`, `profile`, `measurement`, `healthSample`). Filter all queries by `user_id` and `deleted_at is None`. Build values only from validated payload fields; omit malformed records. Keep the existing exercise-ID allowlist. Do not reuse or serialize source record IDs.

- [ ] **Step 5: Wire the projector into `reply()`.**

  Check text consent, context policy version, requested category consents, selection ownership, and credentials before reserving the request. Add the result once as a labeled user-data message. Build the reservation digest from canonical category flags and opaque selection IDs so different selections never replay each other’s request.

- [ ] **Step 6: Run backend Mentor tests and confirm GREEN.**

  Run: `cd backend && .venv/bin/python -m pytest -q tests/test_mentor_context.py tests/test_mentor.py tests/test_mentor_vendor.py`

  Expected: PASS; the tests assert that no projected text or selection ID appears in `MentorRequest`, `MentorMessage`, or provider history after completion.

- [ ] **Step 7: Commit context enforcement.**

  ```bash
  git add backend/app/mentor/context.py backend/app/mentor/service.py backend/tests/test_mentor_context.py backend/tests/test_mentor.py backend/tests/test_mentor_vendor.py
  git commit -m "feat: add consented mentor context"
  ```

### Task 3: Settings consents and Flutter context composer

**Files:**
- Modify: `lib/features/mentor/data/mentor_models.dart`
- Modify: `lib/features/mentor/data/mentor_api.dart`
- Modify: `lib/features/mentor/presentation/pages/mentor_settings_page.dart`
- Create: `lib/features/mentor/presentation/widgets/mentor_context_composer.dart`
- Modify: `lib/features/mentor/presentation/pages/mentor_page.dart`
- Test: `test/features/mentor/mentor_context_composer_test.dart`
- Test: `test/features/mentor/mentor_flow_test.dart`

- [ ] **Step 1: Write failing settings widget tests.**

  Assert five independent consent controls default to off, use partial patches with `expected_revision`, and state that a selection is sent to OpenAI only for a text conversation. Assert the Apple Health control describes a separate OpenAI consent, not the import consent.

- [ ] **Step 2: Write failing composer tests.**

  Assert the composer fetches options only while Mentor is open, shows active categories before sending, lets the user disable one category for one message, requires confirmation after choosing a weight or note, and sends only opaque selection IDs. A network failure disables Mentor sending without affecting the offline workout route.

- [ ] **Step 3: Run widget tests and confirm RED.**

  Run: `flutter test test/features/mentor/mentor_context_composer_test.dart test/features/mentor/mentor_flow_test.dart`

  Expected: FAIL because the settings model has no consents and no composer exists.

- [ ] **Step 4: Implement manual Dart models and API calls.**

  Add `MentorContextConsents`, `MentorContextOptions`, and `MentorContextSelection` with manual `fromJson`/`toJson`. Add `fetchContextOptions()` and pass `settings_revision` plus the selection to the existing message call. Do not add generated code or local persistence.

- [ ] **Step 5: Implement the controls and composer.**

  Add individual consent tiles to settings. Create an `autoDispose` composer widget that holds preview data in memory only, clears it when account/view changes, and provides a final “Wyślij z tym kontekstem” confirmation. Keep the text entry usable without any optional context.

- [ ] **Step 6: Run widget tests and confirm GREEN.**

  Run: `flutter test test/features/mentor/mentor_context_composer_test.dart test/features/mentor/mentor_flow_test.dart`

  Expected: PASS.

- [ ] **Step 7: Commit the UI.**

  ```bash
  git add lib/features/mentor test/features/mentor
  git commit -m "feat: choose mentor context per message"
  ```

### Task 4: Idempotency and local privacy boundaries

**Files:**
- Modify: `lib/features/mentor/data/mentor_operations.dart`
- Modify: `lib/features/mentor/providers/mentor_providers.dart`
- Test: `test/features/mentor/mentor_operations_test.dart`
- Create: `test/features/mentor/mentor_privacy_boundary_test.dart`
- Test: `test/features/settings/backup_service_test.dart`

- [ ] **Step 1: Write failing idempotency tests.**

  Assert that the same text plus the same canonical category/opaque-selection JSON reuses its request ID, while any changed category or selection makes a new request ID. Assert the persisted operation registry contains only request ID, kind, session/message IDs, and a one-way fingerprint, never persona, note text, mass, steps, preview values, or selection IDs.

- [ ] **Step 2: Implement canonical selection fingerprints.**

  Extend the in-memory request builder to hash a sorted JSON representation of category booleans and opaque selection IDs with the existing user/session/text digest. Do not persist the representation itself.

- [ ] **Step 3: Write and run boundary tests.**

  Assert no new `SyncOutbox` row appears while saving Mentorship settings or sending a contextual message. Assert the application export has no persona, consent, profile-key, context-option, or selection section. Keep source workout records legal in export; only Mentor-derived data is prohibited.

  Run: `flutter test test/features/mentor/mentor_operations_test.dart test/features/mentor/mentor_privacy_boundary_test.dart test/features/settings/backup_service_test.dart`

  Expected: PASS.

- [ ] **Step 4: Commit privacy boundaries.**

  ```bash
  git add lib/features/mentor/data/mentor_operations.dart lib/features/mentor/providers/mentor_providers.dart test/features/mentor test/features/settings/backup_service_test.dart
  git commit -m "test: protect mentor context privacy boundaries"
  ```

### Task 5: Documentation, release verification, and production promotion

**Files:**
- Modify: `docs/mentor.md`
- Modify: `docs/apple-health-contract.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Update documentation.**

  State the five separate consents, the 24-session/12-week/one-note/7-day boundaries, the preview requirement, source-data deletion limits, provider-retention limit, backup behavior, and that Apple Health import consent does not authorize OpenAI sharing.

- [ ] **Step 2: Run all local verification.**

  ```bash
  dart format .
  dart tools/generate_app_version.dart --check
  flutter analyze
  flutter test
  cd backend && .venv/bin/python -m pytest -q
  cd .. && docker build --target verification -f deploy/docker/web.Dockerfile -t fit-web:mentor-context .
  ```

  Expected: all commands exit `0`; mocked transports prove the suite sent no provider request.

- [ ] **Step 3: Commit documentation and verification changes.**

  ```bash
  git add docs/mentor.md docs/apple-health-contract.md CHANGELOG.md
  git commit -m "docs: define mentor context consent"
  ```

- [ ] **Step 4: Perform the approved production sequence.**

  From `/opt/fit`, retain the running images and build candidates without invoking a provider:

  ```bash
  docker tag fit-api:production fit-api:rollback-pre-1.4.0+7
  docker tag fit-web:production fit-web:rollback-pre-1.4.0+7
  docker tag fit-migration:production fit-migration:rollback-pre-1.4.0+7
  systemctl start fit-backup.service
  docker build --target runtime -t fit-api:candidate-1.4.0+7 backend
  docker build --target migration -t fit-migration:candidate-1.4.0+7 backend
  docker build --target runtime -f deploy/docker/web.Dockerfile -t fit-web:candidate-1.4.0+7 .
  ```

  Confirm the backup service reports `Result=success`, `ExecMainStatus=0`, a dump SHA-256, Alembic `0009`, and the three rollback image IDs in its manifest. Promote only `fit-migration:candidate-1.4.0+7`, run the existing isolated restore drill against that backup bundle, then run:

  ```bash
  docker tag fit-migration:candidate-1.4.0+7 fit-migration:production
  flock -w 900 /run/lock/fit-backup-restore.lock docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml run --rm --no-deps -T migrate
  docker tag fit-api:candidate-1.4.0+7 fit-api:production
  docker tag fit-web:candidate-1.4.0+7 fit-web:production
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml config --quiet
  docker compose -f /docker/fit/compose.yaml -f /docker/fit/compose.push.yaml -f /docker/fit/compose.mentor.yaml up -d --no-deps --no-build --wait --wait-timeout 180 web api push-sender
  ```

  Confirm migration `0010`, healthy services, `https://fit.birek.online/api/health`, and the shared-sites check. Keep the rollback tags. Never downgrade Alembic or restore a production database as rollback.

  Do not run a provider test or send a Mentor message during this sequence. After deployment, configure the OpenAI key only through the authenticated Mentor settings UI after the independent master-key escrow and recovery test are complete. Enable text consent and each contextual category separately; manually confirm the iPhone Shortcut import before enabling Apple Health context.
