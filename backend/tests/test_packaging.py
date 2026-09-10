from pathlib import Path


BACKEND_DIR = Path(__file__).parent.parent
RUNTIME_PACKAGES = {
    "argon2-cffi",
    "asyncpg",
    "fastapi",
    "pydantic-settings",
    "sqlalchemy",
    "uvicorn",
}
DEVELOPMENT_PACKAGES = {"alembic", "httpx", "pytest", "pytest-asyncio", "testcontainers"}
PYTHON_IMAGE = "python:3.12-slim@sha256:78387bc3881b8273120a12ebe6c1ab22b018ccc2c9adf565ae1ac9b536e184ea"


def requirement_names(path: Path) -> set[str]:
    return {
        line.split("==", maxsplit=1)[0].split("[", maxsplit=1)[0].casefold()
        for line in path.read_text().splitlines()
        if line and not line.startswith(("#", "-"))
    }


def test_runtime_requirements_are_separate_from_development_requirements():
    runtime_requirements = requirement_names(BACKEND_DIR / "requirements.txt")
    development_path = BACKEND_DIR / "requirements-dev.txt"

    assert development_path.exists()
    development_requirements = requirement_names(development_path)
    assert RUNTIME_PACKAGES <= runtime_requirements
    assert not DEVELOPMENT_PACKAGES & runtime_requirements
    assert DEVELOPMENT_PACKAGES <= development_requirements


def test_runtime_lock_is_hashed_and_excludes_development_packages():
    lock = (BACKEND_DIR / "requirements.lock").read_text()
    development_lock = BACKEND_DIR / "requirements-dev.lock"

    assert development_lock.exists()
    assert "--hash=sha256:" in lock
    assert not DEVELOPMENT_PACKAGES & requirement_names(BACKEND_DIR / "requirements.lock")


def test_dockerfile_uses_the_pinned_python_3_12_slim_runtime_lock():
    dockerfile = (BACKEND_DIR / "Dockerfile").read_text()

    assert f"FROM {PYTHON_IMAGE}" in dockerfile
    assert "COPY requirements.lock ./requirements.lock" in dockerfile
    assert "--require-hashes --requirement requirements.lock" in dockerfile
