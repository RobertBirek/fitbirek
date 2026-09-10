"""Feed the existing interactive CLI through stdin; no secret in argv or logs."""
import os
from pathlib import Path
import subprocess

if os.geteuid() != 0:
    raise SystemExit("Run as root")
password = Path("/docker/fit/secrets/initial-account.txt").read_text().strip()
result = subprocess.run(
    ["docker", "compose", "-f", "/docker/fit/compose.yaml", "exec", "-T", "api",
     "python", "-m", "app.cli.create_initial_account", "--email", "robert@birek.online"],
    input=password + "\n" + password + "\n", text=True, capture_output=True,
)
if result.returncode:
    raise SystemExit("Account creation failed; check whether the initial account already exists")
print("Initial account created: robert@birek.online")
