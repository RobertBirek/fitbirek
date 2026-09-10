import os
import subprocess
import sys

import pytest


@pytest.mark.parametrize(
    ("name", "value"),
    [
        ("DATABASE_URL", "postgresql://fit:fit@localhost/fit"),
        ("SESSION_LIFETIME_HOURS", "0"),
        ("TRUSTED_ORIGIN", "http://fit.birek.online"),
    ],
)
def test_settings_reject_insecure_or_invalid_values(name, value):
    environment = os.environ | {
        "DATABASE_URL": "postgresql+asyncpg://fit:fit@localhost/fit",
        "SESSION_LIFETIME_HOURS": "24",
        "TRUSTED_ORIGIN": "https://fit.birek.online",
        name: value,
    }

    result = subprocess.run(
        [sys.executable, "-c", "from app.config import settings"],
        capture_output=True,
        env=environment,
        text=True,
        check=False,
    )

    assert result.returncode != 0
