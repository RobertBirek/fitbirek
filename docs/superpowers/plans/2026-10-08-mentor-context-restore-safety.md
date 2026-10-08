# Mentor Context Restore Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fail closed for context consent after every database restore, reserve OpenAI input-token budget before calls, and make the training projection and mentor tone safe.

**Architecture:** The API compares each persisted context-consent acknowledgement with a non-secret, operator-supplied generation held outside PostgreSQL. A context request requires the current numeric policy version, a matching SHA-256 generation digest, and enabled consent. Input tokens receive a daily reservation equal to the active profile's maximum before opening a provider connection; verified usage refunds only the difference.

**Tech Stack:** FastAPI, SQLAlchemy async/PostgreSQL, Alembic, Pydantic Settings, pytest-asyncio/Testcontainers, Python 3.12.

---

### Task 1: Add failing consent-generation tests

**Files:**
- Modify: `backend/tests/test_mentor_context.py`
- Modify: `backend/tests/test_mentor.py`

- [ ] **Step 1: Write the failing integration test for a changed operator generation.**

```python
monkeypatch.setattr(settings, "mentor_context_generation", "A" * 32)
# submit all five consents with context_policy_version=1 and verify a context call reaches the vendor
monkeypatch.setattr(settings, "mentor_context_generation", "B" * 32)
# verify the same persisted consent returns 409 before the vendor, then full online consent restores access
```

- [ ] **Step 2: Run the focused test and verify it fails.**

Run: `.venv/bin/python -m pytest -q tests/test_mentor_context.py -k generation`
Expected: FAIL because no generation is persisted or enforced.

### Task 2: Implement versioned, external consent acknowledgement

**Files:**
- Modify: `backend/app/config.py`
- Modify: `backend/app/mentor/models.py`
- Modify: `backend/app/mentor/schemas.py`
- Modify: `backend/app/mentor/service.py`
- Modify: `backend/app/mentor/router.py`
- Modify: `backend/migrations/versions/0010_mentor_customization.py`

- [ ] **Step 1: Add the non-secret marker configuration and database digest.**

```python
# config.py
mentor_context_generation: str = Field(default="", min_length=32, max_length=128,
                                        pattern=r"^[A-Za-z0-9_-]+$")

# models.py
context_policy_version: Mapped[int] = mapped_column(Integer, default=0)
context_generation_digest: Mapped[str] = mapped_column(String(64), default="")
```

- [ ] **Step 2: Require an exact full acknowledgement after invalidation.**

```python
CURRENT_CONTEXT_POLICY_VERSION = 1

def context_consents_active(setting: MentorSettings) -> bool:
    return (
        setting.context_policy_version == CURRENT_CONTEXT_POLICY_VERSION
        and hmac.compare_digest(setting.context_generation_digest, context_generation_digest())
    )
```

`PUT /settings` accepts partial consent changes only while `context_consents_active` is true. Otherwise it requires all five boolean fields plus `context_policy_version == 1`, stores their values, the version and the digest. `reply()` rejects every selected context category when acknowledgement is inactive. The migration adds the digest with an empty default and backfills version `0`, so existing rows are invalid until acknowledged online.

- [ ] **Step 3: Run the focused consent tests and verify they pass.**

Run: `.venv/bin/python -m pytest -q tests/test_mentor.py tests/test_mentor_context.py -k 'context or generation or consent'`
Expected: PASS.

### Task 3: Add and enforce conservative input-token reservations

**Files:**
- Modify: `backend/tests/test_mentor.py`
- Modify: `backend/tests/test_schema.py`
- Modify: `backend/app/mentor/service.py`
- Modify: `backend/app/mentor/vendor.py`
- Modify: `backend/app/mentor/models.py`
- Modify: `backend/migrations/versions/0010_mentor_customization.py`

- [ ] **Step 1: Write failing tests for pre-call input capacity and reserve reconciliation.**

```python
await session.execute(update(MentorUsage).values(
    input_tokens=service.LIMITS["input_tokens"] - profile.max_input_tokens + 1,
))
monkeypatch.setattr(service, "openai_reply", forbidden)
assert response.status_code == 429

# successful mocked usage.input_tokens=4 reduces a 6000-token reservation to 4
assert settings["usage"]["input_tokens"] == 4
```

- [ ] **Step 2: Run the new tests and verify they fail.**

Run: `.venv/bin/python -m pytest -q tests/test_mentor.py -k 'input_token'`
Expected: FAIL because `MentorUsage` has no input budget.

- [ ] **Step 3: Add the bounded counter and reservation logic.**

```python
LIMITS = {..., "input_tokens": 360000}

def conservative_input_tokens(messages: list[dict]) -> int:
    return len((_SYSTEM_INSTRUCTIONS + json.dumps(messages, ensure_ascii=False,
               separators=(",", ":"))).encode("utf-8"))
```

Reject a prompt when this byte upper bound exceeds `profile.max_input_tokens`; reserve `profile.max_input_tokens` in `reserve()` before `db.commit()` and provider invocation; in `complete()` replace the reserved amount with verified bounded `answer["input_tokens"]`. Failure leaves the full reservation intact.

- [ ] **Step 4: Run focused budget tests and verify they pass.**

Run: `.venv/bin/python -m pytest -q tests/test_mentor.py tests/test_mentor_vendor.py -k 'input_token or usage'`
Expected: PASS.

### Task 4: Restrict and aggregate training projection

**Files:**
- Modify: `backend/tests/test_mentor_context.py`
- Modify: `backend/tests/test_mentor_vendor.py`
- Modify: `backend/app/mentor/context.py`

- [ ] **Step 1: Write failing projection tests.**

```python
# An open workout with no valid dataKoniec is absent.
assert all(item["started_at"] != open_start for item in projected["training"]["sessions"])
# The projection carries only a bounded direction aggregate, never IDs, dates, or raw trend values.
assert projected["training"]["progress_trend"] == {
    "completed_sessions": 2,
    "by_exercise": [{"exercise": "Pompki klasyczne", "direction": "up"}],
}
```

- [ ] **Step 2: Run the projection tests and verify they fail.**

Run: `.venv/bin/python -m pytest -q tests/test_mentor_context.py tests/test_mentor_vendor.py -k 'training_context or completed or trend'`
Expected: FAIL because open sessions are currently included and no aggregate trend exists.

- [ ] **Step 3: Build the minimal bounded projection.**

Require a parseable end timestamp not earlier than start for every session. For eligible catalogue exercises, compare the first and last chronological per-session best `weight_kg * reps` values, emit only `up`, `down`, or `stable`, require at least two observations, cap at five exercises, and expose no identifiers, dates, counts per exercise, or numeric loads.

- [ ] **Step 4: Run the projection tests and verify they pass.**

Run: `.venv/bin/python -m pytest -q tests/test_mentor_context.py tests/test_mentor_vendor.py -k 'training_context or completed or trend'`
Expected: PASS.

### Task 5: Remove pressure from the system contract

**Files:**
- Modify: `backend/tests/test_mentor_vendor.py`
- Modify: `backend/app/mentor/vendor.py`

- [ ] **Step 1: Write the failing prompt assertion.**

```python
assert "bez presji" in instructions
assert "bez oceniania" in instructions
assert "wymagając" not in instructions
```

- [ ] **Step 2: Run it and verify it fails.**

Run: `.venv/bin/python -m pytest -q tests/test_mentor_vendor.py -k safety_contract`
Expected: FAIL because the existing prompt calls the mentor demanding.

- [ ] **Step 3: Replace only the conflicting clause.**

```python
"Jesteś spokojnym, konkretnym polskim partnerem treningowym: wspierasz "
"regularność i wszechstronność bez oceniania ani presji. "
```

- [ ] **Step 4: Run the prompt test and verify it passes.**

Run: `.venv/bin/python -m pytest -q tests/test_mentor_vendor.py -k safety_contract`
Expected: PASS.

### Task 6: Document the operator protocol and verify migrations

**Files:**
- Modify: `docs/mentor.md`
- Modify: `backend/tests/test_schema.py`

- [ ] **Step 1: Document the non-secret environment variable and restore order.**

State that `MENTOR_CONTEXT_GENERATION` is a random URL-safe value of at least 32 characters kept only in the deployed `/docker/fit/.env`, not in repository templates or database dumps. Before every real production restore, operator replaces it with a new random value, restores the database under the existing lock, recreates API, then users must submit the full current policy acknowledgement online. Never copy its old value from a backup.

- [ ] **Step 2: Add migration assertions.**

```python
assert row["context_policy_version"] == 0
assert row["context_generation_digest"] == ""
assert row["input_tokens"] == 0
```

- [ ] **Step 3: Run schema and focused Mentor tests.**

Run: `.venv/bin/python -m pytest -q tests/test_schema.py tests/test_mentor.py tests/test_mentor_context.py tests/test_mentor_vendor.py`
Expected: PASS.

- [ ] **Step 4: Do not commit or deploy.**

Inspect only intended changes with `git diff -- backend docs/mentor.md docs/superpowers/plans/2026-10-08-mentor-context-restore-safety.md`; do not stage, commit, build an image, or run deployment commands.
