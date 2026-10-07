import asyncio
from datetime import datetime, timedelta, timezone
import errno
import fcntl
from getpass import GetPassWarning
from hashlib import sha256
import inspect
import os
import pty
import select as select_module
import subprocess
import sys
import termios
import time
import warnings
from pathlib import Path
from types import SimpleNamespace

import pytest
from argon2 import PasswordHasher
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import NullPool

from app.identity.models import Session, User


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


def run_reset_password(database_url: str, input_text: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-m", "app.cli.reset_password"],
        cwd=BACKEND_DIR,
        env={**os.environ, "DATABASE_URL": database_url},
        input=input_text,
        text=True,
        capture_output=True,
        check=False,
        start_new_session=True,
        timeout=15,
    )


def interactive_reset_password_module(monkeypatch, database_url):
    monkeypatch.setenv("DATABASE_URL", database_url)
    from app.cli import reset_password

    interactive_stream = SimpleNamespace(isatty=lambda: True)
    monkeypatch.setattr(reset_password.sys, "stdin", interactive_stream)
    monkeypatch.setattr(reset_password.sys, "stderr", interactive_stream)
    return reset_password


async def run_interactive_reset_password(reset_password, database_url, monkeypatch) -> None:
    engine = create_async_engine(database_url, poolclass=NullPool)
    monkeypatch.setattr(reset_password, "session_factory", async_sessionmaker(engine, expire_on_commit=False))
    try:
        await asyncio.to_thread(reset_password.main)
    finally:
        await engine.dispose()


def read_pty_until(file_descriptor: int, output: bytearray, expected: bytes, timeout: float = 15) -> None:
    deadline = time.monotonic() + timeout
    while expected not in output:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise AssertionError(f"Did not receive PTY prompt {expected!r}")
        ready, _, _ = select_module.select([file_descriptor], [], [], remaining)
        if not ready:
            raise AssertionError(f"Did not receive PTY prompt {expected!r}")
        try:
            output.extend(os.read(file_descriptor, 1024))
        except OSError as error:
            if error.errno == errno.EIO:
                raise AssertionError(f"PTY closed before prompt {expected!r}") from error
            raise


def drain_pty(file_descriptor: int, output: bytearray) -> None:
    while select_module.select([file_descriptor], [], [], 0)[0]:
        try:
            output.extend(os.read(file_descriptor, 1024))
        except OSError as error:
            if error.errno == errno.EIO:
                return
            raise


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


@pytest.mark.asyncio
@pytest.mark.skipif(sys.platform != "linux", reason="PTY integration test requires Linux")
async def test_reset_password_cli_pty_updates_the_hash_and_revokes_all_sessions(database_url, session):
    new_password = "new secret"
    account = User(email="me@example.com", password_hash=PasswordHasher().hash("old secret"))
    session.add(account)
    await session.flush()
    first_session = Session(
        user_id=account.id,
        token_hash=sha256(b"first-session-token").hexdigest(),
        csrf_hash="a" * 64,
        expires_at=datetime.now(timezone.utc) + timedelta(days=1),
    )
    second_session = Session(
        user_id=account.id,
        token_hash=sha256(b"second-session-token").hexdigest(),
        csrf_hash="b" * 64,
        expires_at=datetime.now(timezone.utc) + timedelta(days=1),
    )
    session.add_all([first_session, second_session])
    await session.commit()

    master, slave = pty.openpty()
    process = None
    output = bytearray()

    def attach_controlling_tty():
        os.setsid()
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)

    try:
        process = subprocess.Popen(
            [sys.executable, "-m", "app.cli.reset_password"],
            cwd=BACKEND_DIR,
            env={**os.environ, "DATABASE_URL": database_url},
            stdin=slave,
            stdout=slave,
            stderr=slave,
            preexec_fn=attach_controlling_tty,
        )
        os.close(slave)
        slave = None

        read_pty_until(master, output, b"Email: ")
        os.write(master, b"me@example.com\n")
        read_pty_until(master, output, b"New password: ")
        os.write(master, new_password.encode() + b"\n")
        read_pty_until(master, output, b"Confirm new password: ")
        os.write(master, new_password.encode() + b"\n")
        assert process.wait(timeout=15) == 0
        drain_pty(master, output)
    finally:
        if process is not None and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
        if slave is not None:
            os.close(slave)
        os.close(master)

    await session.refresh(account)
    await session.refresh(first_session)
    await session.refresh(second_session)
    assert PasswordHasher().verify(account.password_hash, new_password)
    assert first_session.revoked_at is not None
    assert second_session.revoked_at is not None
    assert new_password.encode() not in output


@pytest.mark.asyncio
async def test_reset_password_cli_rejects_mismatched_passwords_without_changing_the_hash(
    database_url, session, monkeypatch
):
    bootstrap = run_bootstrap(database_url, "me@example.com", "old secret\nold secret\n")
    assert bootstrap.returncode == 0, bootstrap.stderr
    account = await session.scalar(select(User).where(User.email == "me@example.com"))
    assert account is not None
    old_hash = account.password_hash
    reset_password = interactive_reset_password_module(monkeypatch, database_url)
    monkeypatch.setattr("builtins.input", lambda _: "me@example.com")
    passwords = iter(["first", "second"])
    monkeypatch.setattr(reset_password.getpass, "getpass", lambda _: next(passwords))

    with pytest.raises(SystemExit, match="Passwords do not match"):
        reset_password.main()

    await session.refresh(account)
    assert account.password_hash == old_hash
    assert PasswordHasher().verify(account.password_hash, "old secret")


@pytest.mark.asyncio
async def test_reset_password_cli_rejects_blank_passwords_without_changing_the_hash(
    database_url, session, monkeypatch
):
    bootstrap = run_bootstrap(database_url, "me@example.com", "old secret\nold secret\n")
    assert bootstrap.returncode == 0, bootstrap.stderr
    account = await session.scalar(select(User).where(User.email == "me@example.com"))
    assert account is not None
    old_hash = account.password_hash
    reset_password = interactive_reset_password_module(monkeypatch, database_url)
    monkeypatch.setattr("builtins.input", lambda _: "me@example.com")
    passwords = iter(["", "confirmation"])
    monkeypatch.setattr(reset_password.getpass, "getpass", lambda _: next(passwords))

    with pytest.raises(SystemExit, match="Password must not be blank"):
        reset_password.main()

    await session.refresh(account)
    assert account.password_hash == old_hash
    assert PasswordHasher().verify(account.password_hash, "old secret")


@pytest.mark.asyncio
async def test_reset_password_cli_rejects_a_missing_account(database_url, session, monkeypatch):
    reset_password = interactive_reset_password_module(monkeypatch, database_url)
    monkeypatch.setattr("builtins.input", lambda _: "missing@example.com")
    passwords = iter(["new secret", "new secret"])
    monkeypatch.setattr(reset_password.getpass, "getpass", lambda _: next(passwords))

    with pytest.raises(SystemExit, match="Account does not exist"):
        await run_interactive_reset_password(reset_password, database_url, monkeypatch)

    assert await session.scalar(select(User)) is None


def test_reset_password_cli_rejects_execution_without_interactive_terminal(database_url):
    result = run_reset_password(database_url, "")

    assert result.returncode != 0
    assert "interactive terminal" in result.stderr
    assert "Traceback" not in result.stderr


def test_reset_password_cli_rejects_getpass_fallback_warning(database_url, monkeypatch):
    reset_password = interactive_reset_password_module(monkeypatch, database_url)
    monkeypatch.setattr("builtins.input", lambda _: "me@example.com")

    def fallback_getpass(_):
        warnings.warn("terminal echo cannot be controlled", GetPassWarning)
        raise AssertionError("getpass fallback continued")

    monkeypatch.setattr(reset_password.getpass, "getpass", fallback_getpass)

    with pytest.raises(SystemExit, match="Secure password input is unavailable"):
        reset_password.main()


def test_reset_password_cli_has_no_password_argument_or_environment_api(database_url, monkeypatch):
    reset_password = interactive_reset_password_module(monkeypatch, database_url)
    source = inspect.getsource(reset_password)

    assert inspect.signature(reset_password.main).parameters == {}
    assert "argparse" not in source
    assert "os.environ" not in source
    assert "os.getenv" not in source


def test_reset_password_cli_rejects_eof_while_reading_email(database_url, monkeypatch):
    reset_password = interactive_reset_password_module(monkeypatch, database_url)

    def raise_eof(_):
        raise EOFError

    monkeypatch.setattr("builtins.input", raise_eof)

    with pytest.raises(SystemExit, match="Input cancelled"):
        reset_password.main()


def test_reset_password_cli_rejects_eof_while_reading_a_password(database_url, monkeypatch):
    reset_password = interactive_reset_password_module(monkeypatch, database_url)
    monkeypatch.setattr("builtins.input", lambda _: "me@example.com")

    def raise_eof(_):
        raise EOFError

    monkeypatch.setattr(reset_password.getpass, "getpass", raise_eof)

    with pytest.raises(SystemExit, match="Input cancelled"):
        reset_password.main()


def test_reset_password_cli_rejects_eof_while_reading_password_confirmation(database_url, monkeypatch):
    reset_password = interactive_reset_password_module(monkeypatch, database_url)
    monkeypatch.setattr("builtins.input", lambda _: "me@example.com")
    passwords = iter(["new secret", EOFError()])

    def get_password(_):
        password = next(passwords)
        if isinstance(password, EOFError):
            raise password
        return password

    monkeypatch.setattr(reset_password.getpass, "getpass", get_password)

    with pytest.raises(SystemExit, match="Input cancelled"):
        reset_password.main()
