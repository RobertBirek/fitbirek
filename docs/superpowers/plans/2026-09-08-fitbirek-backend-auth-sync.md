# FitBirek Backend Authentication and Sync API Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide a same-origin FastAPI API that authenticates the single FitBirek account and durably accepts, orders, and returns offline synchronization changes.

**Architecture:** The API keeps a small identity model and a generic per-user sync record store in PostgreSQL. Opaque session and CSRF tokens are stored only as SHA-256 hashes; every accepted sync operation is idempotent through a unique operation ID and emits one ordered change-journal entry.

**Tech Stack:** Python 3.12, FastAPI, SQLAlchemy 2 async, Alembic, PostgreSQL 16, Argon2id, pytest, httpx.

---

## File Structure

- Create: `backend/requirements.txt` - pinned runtime and test dependencies.
- Create: `backend/Dockerfile` - non-root production API image.
- Create: `backend/app/config.py` - validated environment settings.
- Create: `backend/app/database.py` - SQLAlchemy engine and transaction dependency.
- Create: `backend/app/identity/{models,schemas,service,router}.py` - account and session boundary.
- Create: `backend/app/sync/{models,schemas,service,router}.py` - sync record, operation, and cursor boundary.
- Create: `backend/app/security/{tokens,csrf,rate_limit}.py` - token creation, CSRF validation, and login throttling.
- Create: `backend/app/cli/create_initial_account.py` - interactive one-time bootstrap command.
- Create: `backend/app/main.py` - app factory, routers, middleware, health endpoint.
- Create: `backend/alembic.ini`, `backend/migrations/*` - initial PostgreSQL schema.
- Create: `backend/tests/{conftest.py,test_identity.py,test_sync.py}` - integration tests against an isolated PostgreSQL database.

### Task 1: Create the tested application skeleton

**Files:**
- Create: `backend/requirements.txt`
- Create: `backend/app/config.py`
- Create: `backend/app/database.py`
- Create: `backend/app/main.py`
- Test: `backend/tests/test_health.py`

- [ ] **Step 1: Write the failing health test**

```python
async def test_health_requires_a_ready_database(client):
    response = await client.get("/api/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd /opt/fit/backend && pytest tests/test_health.py -q`

Expected: FAIL because the application package does not exist.

- [ ] **Step 3: Add the minimal app and database dependency**

```python
# app/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file="/run/fit/.env", extra="ignore")
    database_url: str
    session_cookie_name: str = "fit_session"
    csrf_cookie_name: str = "fit_csrf"
    trusted_origin: str = "https://fit.birek.online"

settings = Settings()

# app/main.py
from fastapi import FastAPI, Depends
from sqlalchemy import text
from .database import get_session

app = FastAPI()

@app.get("/api/health")
async def health(session=Depends(get_session)) -> dict[str, str]:
    await session.execute(text("SELECT 1"))
    return {"status": "ok"}
```

Use SQLAlchemy `create_async_engine(settings.database_url, pool_pre_ping=True)` and an `async_sessionmaker` in `database.py`. Pin `fastapi`, `uvicorn[standard]`, `sqlalchemy[asyncio]`, `asyncpg`, `alembic`, `pydantic-settings`, `argon2-cffi`, `pytest`, `pytest-asyncio`, and `httpx` in `requirements.txt`.

- [ ] **Step 4: Run the test again**

Run: `cd /opt/fit/backend && pytest tests/test_health.py -q`

Expected: PASS with the test database URL injected by `tests/conftest.py`.

- [ ] **Step 5: Commit**

```bash
git add backend
git commit -m "feat: scaffold FitBirek API"
```

### Task 2: Define and migrate the identity and sync persistence model

**Files:**
- Create: `backend/app/identity/models.py`
- Create: `backend/app/sync/models.py`
- Create: `backend/migrations/versions/0001_identity_and_sync.py`
- Test: `backend/tests/test_schema.py`

- [ ] **Step 1: Write schema tests**

```python
async def test_operation_id_is_unique_per_user(session, user):
    session.add_all([SyncOperation(user_id=user.id, operation_id="op-1"),
                     SyncOperation(user_id=user.id, operation_id="op-1")])
    with pytest.raises(IntegrityError):
        await session.commit()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /opt/fit/backend && pytest tests/test_schema.py -q`

Expected: FAIL because `SyncOperation` and the migration do not exist.

- [ ] **Step 3: Add the four model families and Alembic revision**

Use these exact persistence constraints:

```python
class User(Base):
    __tablename__ = "users"
    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))

class SyncRecord(Base):
    __tablename__ = "sync_records"
    __table_args__ = (UniqueConstraint("user_id", "entity_type", "entity_id"),)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    entity_type: Mapped[str] = mapped_column(String(64))
    entity_id: Mapped[UUID] = mapped_column(Uuid)
    version: Mapped[int] = mapped_column(Integer)
    payload: Mapped[dict] = mapped_column(JSONB)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

class SyncOperation(Base):
    __tablename__ = "sync_operations"
    __table_args__ = (UniqueConstraint("user_id", "operation_id"),)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    operation_id: Mapped[UUID] = mapped_column(Uuid)

class SyncChange(Base):
    __tablename__ = "sync_changes"
    cursor: Mapped[int] = mapped_column(BigInteger, Identity(), primary_key=True)
```

Add `sessions` with `token_hash`, `csrf_hash`, `expires_at`, and `revoked_at`. The migration must add indexes for `sessions.token_hash`, `sync_changes(user_id, cursor)`, and `sync_records(user_id, entity_type, entity_id)`.

- [ ] **Step 4: Re-run migration and schema tests**

Run: `cd /opt/fit/backend && alembic upgrade head && pytest tests/test_schema.py -q`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/app backend/migrations backend/tests/test_schema.py
git commit -m "feat: add identity and sync schema"
```

### Task 3: Implement password login, session, logout, and CSRF protection

**Files:**
- Create: `backend/app/security/tokens.py`
- Create: `backend/app/security/csrf.py`
- Create: `backend/app/security/rate_limit.py`
- Create: `backend/app/identity/{schemas,service,router}.py`
- Test: `backend/tests/test_identity.py`

- [ ] **Step 1: Write failing security tests**

```python
async def test_login_sets_secure_session_and_csrf_cookies(client, account):
    response = await client.post("/api/auth/login", json={"email": account.email, "password": "correct"})
    assert response.status_code == 204
    assert "HttpOnly" in response.headers["set-cookie"]

async def test_push_without_matching_csrf_is_forbidden(client, logged_in):
    response = await client.post("/api/sync/push", json={"operations": []})
    assert response.status_code == 403
```

- [ ] **Step 2: Run tests to verify failure**

Run: `cd /opt/fit/backend && pytest tests/test_identity.py -q`

Expected: FAIL because auth routes do not exist.

- [ ] **Step 3: Implement opaque tokens and routes**

Generate 32 random bytes using `secrets.token_urlsafe(32)`, persist only `sha256(token.encode()).hexdigest()`, and compare hashes with `hmac.compare_digest`. Hash passwords with `argon2.PasswordHasher`. Implement:

```python
@router.post("/login", status_code=204)
async def login(payload: LoginRequest, response: Response, request: Request, session=Depends(get_session)) -> None: ...

@router.get("/session", response_model=SessionResponse)
async def current_account(account=Depends(require_account)) -> SessionResponse: ...

@router.post("/logout", status_code=204)
async def logout(response: Response, account=Depends(require_account)) -> None: ...
```

Set the session cookie to `httponly=True, secure=True, samesite="strict", path="/"`. Set a separate readable CSRF cookie with the same `secure`, `samesite`, and `path` settings. Require `Origin == settings.trusted_origin` and `X-CSRF-Token` matching the stored CSRF hash on all sync mutations. Limit login attempts by `(request.client.host, normalized_email)` to five attempts per 15 minutes; return 429 thereafter.

- [ ] **Step 4: Run identity tests**

Run: `cd /opt/fit/backend && pytest tests/test_identity.py -q`

Expected: PASS, including invalid password, expired session, logout revocation, CSRF rejection, and rate-limit tests.

- [ ] **Step 5: Commit**

```bash
git add backend/app backend/tests/test_identity.py
git commit -m "feat: add FitBirek account authentication"
```

### Task 4: Implement idempotent push and ordered pull

**Files:**
- Create: `backend/app/sync/{schemas,service,router}.py`
- Test: `backend/tests/test_sync.py`

- [ ] **Step 1: Write the failing sync contract tests**

```python
async def test_repeated_operation_is_applied_once(client, csrf_headers):
    body = {"operations": [{"operationId": str(uuid4()), "entityType": "mood", "entityId": str(uuid4()), "baseVersion": 0, "payload": {"mood": "good"}, "deleted": False}]}
    assert (await client.post("/api/sync/push", json=body, headers=csrf_headers)).status_code == 200
    assert (await client.post("/api/sync/push", json=body, headers=csrf_headers)).json()["accepted"][0]["duplicate"] is True

async def test_pull_returns_changes_after_cursor_only(client, csrf_headers):
    await push_one_change(client, csrf_headers)
    first = await client.get("/api/sync/pull?cursor=0")
    second = await client.get(f"/api/sync/pull?cursor={first.json()['cursor']}")
    assert len(first.json()["changes"]) == 1
    assert second.json()["changes"] == []
```

- [ ] **Step 2: Run tests to verify failure**

Run: `cd /opt/fit/backend && pytest tests/test_sync.py -q`

Expected: FAIL because sync routes do not exist.

- [ ] **Step 3: Implement the contract transactionally**

`POST /api/sync/push` accepts at most 100 operations. For each operation, lock the existing `SyncRecord`, insert `SyncOperation`, and append `SyncChange` in one transaction. An existing `(user_id, operation_id)` returns the previously accepted outcome without another change. A stale `baseVersion` must return the current server record in `conflicts`; a non-stale operation increments `version`, assigns `updated_at = now(timezone.utc)`, and applies last-write-wins in server acceptance order. `GET /api/sync/pull?cursor=<non-negative int>` returns at most 500 ordered changes and the final cursor.

Use response shapes:

```json
{"accepted":[{"operationId":"uuid","version":1,"updatedAt":"ISO-8601","duplicate":false}],"conflicts":[]}
```

```json
{"cursor":42,"changes":[{"cursor":42,"entityType":"mood","entityId":"uuid","version":1,"payload":{"mood":"good"},"deletedAt":null,"updatedAt":"ISO-8601"}]}
```

- [ ] **Step 4: Run the sync suite**

Run: `cd /opt/fit/backend && pytest tests/test_sync.py -q`

Expected: PASS for idempotency, user isolation, stale write conflict, tombstone, cursor ordering, and partial rollback.

- [ ] **Step 5: Commit**

```bash
git add backend/app/sync backend/tests/test_sync.py
git commit -m "feat: add offline sync API"
```

### Task 5: Add bootstrap command, migration tests, and container build

**Files:**
- Create: `backend/app/cli/create_initial_account.py`
- Create: `backend/Dockerfile`
- Test: `backend/tests/test_bootstrap.py`

- [ ] **Step 1: Write the bootstrap test**

```python
def test_initial_account_rejects_a_second_user(runner, database_url):
    assert runner.invoke(create_initial_account, ["--email", "me@example.com"], input="secret\nsecret\n").exit_code == 0
    assert runner.invoke(create_initial_account, ["--email", "other@example.com"], input="secret\nsecret\n").exit_code != 0
```

- [ ] **Step 2: Run it to verify failure**

Run: `cd /opt/fit/backend && pytest tests/test_bootstrap.py -q`

Expected: FAIL because the command does not exist.

- [ ] **Step 3: Implement the one-time command and image**

The command must request the password twice using `getpass.getpass`, refuse mismatched values and refuse execution if any user exists. The Dockerfile must use `python:3.12-slim`, install requirements, copy `backend`, run as a non-root `app` user, and launch `uvicorn app.main:app --host 0.0.0.0 --port 8000`.

- [ ] **Step 4: Verify the backend**

Run: `cd /opt/fit/backend && pytest -q && docker build -t fit-api:test .`

Expected: all tests PASS and image builds successfully.

- [ ] **Step 5: Commit**

```bash
git add backend
git commit -m "feat: package FitBirek API"
```
