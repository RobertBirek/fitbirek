"""One-time root-only runtime and secret installation. Never prints credentials."""
import os
from pathlib import Path
import secrets
import shutil

if os.geteuid() != 0:
    raise SystemExit("Run as root")
os.umask(0o077)
runtime = Path("/docker/fit")
runtime.mkdir(mode=0o700, exist_ok=True)
(runtime / "secrets").mkdir(mode=0o700, exist_ok=True)
(runtime / "data/backups").mkdir(mode=0o700, parents=True, exist_ok=True)
# Refuse partial initialization rather than mismatching existing DB credentials.
paths = [runtime / ".env", runtime / "secrets/postgres-password.txt", runtime / "secrets/initial-account.txt"]
if any(path.exists() for path in paths):
    raise SystemExit("Secrets already exist; install updated compose separately")
db_password = secrets.token_hex(32)
contents = [
    f"DATABASE_URL=postgresql+asyncpg://fit:{db_password}@postgres:5432/fit\nTRUSTED_ORIGIN=https://fit.birek.online\n",
    db_password + "\n",
    secrets.token_urlsafe(36) + "\n",
]
for path, content in zip(paths, contents):
    with path.open("x") as output:
        output.write(content)
    path.chmod(0o600)
shutil.copyfile("/opt/fit/deploy/compose.yaml", runtime / "compose.yaml")
(runtime / "compose.yaml").chmod(0o600)
print("Runtime initialized; credentials saved to root-readable files")
