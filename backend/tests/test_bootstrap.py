import asyncio
import os
import subprocess
import sys
from pathlib import Path

import pytest
from argon2 import PasswordHasher
from sqlalchemy import select, text

from app.identity.models import User


BACKEND_DIR = Path(__file__).parent.parent


def run_bootstrap(database_url: str, email: str, password_input: str = "") -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-m", "app.cli.create_initial_account", "--email", email],
        cwd=BACKEND_DIR,
        env={**os.environ, "DATABASE_URL": database_url},
        input=password_input,
        text=True,
        capture_output=True,
        check=False,
    )


def bootstrap_command(email: str) -> list[str]:
    return [sys.executable, "-m", "app.cli.create_initial_account", "--email", email]


async def wait_for_bootstrap_lock_waiters(session) -> None:
    for _ in range(300):
        waiters = await session.scalar(
            text(
                "SELECT count(*) FROM pg_locks "
                "WHERE relation = 'users'::regclass "
                "AND mode = 'AccessExclusiveLock' AND NOT granted"
            )
        )
        if waiters == 2:
            return
        await asyncio.sleep(0.1)
    raise AssertionError("Bootstrap processes did not both reach the database lock")


@pytest.mark.asyncio
async def test_initial_account_creates_one_normalized_account(database_url, session):
    first = run_bootstrap(database_url, "  ME@Example.COM  ", "secret\nsecret\n")

    assert first.returncode == 0, first.stderr
    second = run_bootstrap(database_url, "other@example.com", "secret\nsecret\n")

    assert second.returncode != 0
    assert "already exists" in second.stderr
    accounts = (await session.scalars(select(User))).all()
    assert len(accounts) == 1
    assert accounts[0].email == "me@example.com"
    assert PasswordHasher().verify(accounts[0].password_hash, "secret")


def test_initial_account_rejects_an_invalid_email_before_requesting_password(database_url):
    result = run_bootstrap(database_url, "not-an-email")

    assert result.returncode != 0
    assert "valid email" in result.stderr


@pytest.mark.asyncio
async def test_initial_account_rejects_mismatched_passwords_without_creating_an_account(database_url, session):
    result = run_bootstrap(database_url, "me@example.com", "secret\ndifferent\n")

    assert result.returncode != 0
    assert "Passwords do not match" in result.stderr
    assert await session.scalar(select(User)) is None


@pytest.mark.asyncio
async def test_initial_account_rejects_blank_passwords_without_creating_an_account(database_url, session):
    result = run_bootstrap(database_url, "me@example.com", "\n\n")

    assert result.returncode != 0
    assert "Password must not be blank" in result.stderr
    assert await session.scalar(select(User)) is None


@pytest.mark.asyncio
async def test_concurrent_initial_account_attempts_create_exactly_one_user(database_url, session):
    environment = {**os.environ, "DATABASE_URL": database_url}
    await session.execute(text("LOCK TABLE users IN ACCESS EXCLUSIVE MODE"))
    first = subprocess.Popen(
        bootstrap_command("first@example.com"),
        cwd=BACKEND_DIR,
        env=environment,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    second = subprocess.Popen(
        bootstrap_command("second@example.com"),
        cwd=BACKEND_DIR,
        env=environment,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    for process in (first, second):
        assert process.stdin is not None
        process.stdin.write("secret\nsecret\n")
        process.stdin.flush()

    try:
        await wait_for_bootstrap_lock_waiters(session)
    finally:
        await session.commit()

    _, first_error = first.communicate(timeout=30)
    _, second_error = second.communicate(timeout=30)

    assert sorted([first.returncode, second.returncode]) == [0, 2]
    assert "already exists" in f"{first_error}{second_error}"
    assert len((await session.scalars(select(User))).all()) == 1
