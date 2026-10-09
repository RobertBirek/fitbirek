# Mentor Dead-Code Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove two unused Mentor symbols without changing the active context, TTS, or provider contracts.

**Architecture:** The active per-message context remains `project_context()` with `_training_projection()`; the legacy `training_context()` is removed. ElevenLabs voice validation remains owned by `app.mentor.vendor._VOICE_ID`; the unused duplicate in `service.py` is removed. Regression tests state that neither obsolete symbol is available.

**Tech Stack:** Python 3.12, FastAPI, pytest, PostgreSQL Testcontainers.

---

### Task 1: Remove the legacy training projection

**Files:**
- Modify: `backend/app/mentor/context.py:320-357`
- Modify: `backend/tests/test_mentor_vendor.py:258-278`

- [ ] **Step 1: Replace the legacy projection test with an absence contract.**

Replace `test_training_context_projects_only_safe_workout_fields` with:

```python
def test_legacy_training_context_is_not_exported(monkeypatch):
    monkeypatch.setenv(
        "DATABASE_URL", "postgresql+asyncpg://fit:fit@127.0.0.1:1/fit",
    )
    from app.mentor import context

    assert not hasattr(context, "training_context")
```

- [ ] **Step 2: Run the new test and verify it fails before deleting production code.**

Run:

```bash
cd backend && .venv/bin/python -m pytest -q tests/test_mentor_vendor.py::test_legacy_training_context_is_not_exported
```

Expected: failure because `context.training_context` still exists.

- [ ] **Step 3: Delete only `training_context`.**

Remove the complete `async def training_context(db, user_id) -> dict:` declaration through its final return. Keep `CATALOGUE`, `_training_projection()` and `project_context()` unchanged.

- [ ] **Step 4: Run the focused test and verify it passes.**

Run:

```bash
cd backend && .venv/bin/python -m pytest -q tests/test_mentor_vendor.py::test_legacy_training_context_is_not_exported
```

Expected: one passing test.

### Task 2: Remove the duplicate service voice validator

**Files:**
- Modify: `backend/app/mentor/service.py:31`
- Modify: `backend/tests/test_mentor_vendor.py`

- [ ] **Step 1: Add a failing absence contract for the duplicate validator.**

Add this independent test beside the legacy-context absence test:

```python
def test_service_does_not_export_duplicate_voice_validator(monkeypatch):
    monkeypatch.setenv(
        "DATABASE_URL", "postgresql+asyncpg://fit:fit@127.0.0.1:1/fit",
    )
    from app.mentor import service

    assert not hasattr(service, "VOICE_ID")
```

- [ ] **Step 2: Run the new test and verify it fails before deleting production code.**

Run:

```bash
cd backend && .venv/bin/python -m pytest -q tests/test_mentor_vendor.py::test_service_does_not_export_duplicate_voice_validator
```

Expected: failure because `service.VOICE_ID` still exists. The local valid URL is
required only because importing the module instantiates settings; no test connects
to this address.

- [ ] **Step 3: Delete only `VOICE_ID`.**

Delete this declaration from `service.py`:

```python
VOICE_ID = re.compile(r"^[A-Za-z0-9]{1,64}$")
```

Keep `import re`: it is required by `reject_credentials()` and `validated_proposal()`. Keep `vendor._VOICE_ID`: it validates provider voice data and TTS calls.

- [ ] **Step 4: Run both absence contracts and active Mentor tests.**

Run:

```bash
cd backend && .venv/bin/python -m pytest -q \
  tests/test_mentor_vendor.py::test_legacy_training_context_is_not_exported \
  tests/test_mentor_vendor.py::test_service_does_not_export_duplicate_voice_validator \
  tests/test_mentor_context.py \
  tests/test_mentor_vendor.py::test_elevenlabs_uses_fixed_paths_and_filters_voice_metadata \
  tests/test_mentor.py::test_voice_endpoints_call_mock_vendor_and_count_caps
```

Expected: all selected tests pass.

### Task 3: Verify the isolated cleanup

**Files:**
- Modify only: `backend/app/mentor/context.py`, `backend/app/mentor/service.py`, `backend/tests/test_mentor_vendor.py`

- [ ] **Step 1: Inspect references and the changed-file boundary.**

Run:

```bash
git grep -nE 'training_context|VOICE_ID' -- backend
git diff --check
git diff --name-only
```

Expected: no `training_context` or `service.VOICE_ID` consumer; only the three listed files changed.

- [ ] **Step 2: Run the full backend suite.**

Run:

```bash
cd backend && .venv/bin/python -m pytest -q
```

Expected: suite passes with PostgreSQL Testcontainers.

- [ ] **Step 3: Do not commit or deploy without a separate explicit request.**

The user authorized implementation, not a Git commit, push, or deployment. Keep the verified diff available for review.
