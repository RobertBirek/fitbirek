"""Exercise refusal paths without altering any database."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

scripts = Path(__file__).resolve().parent
result = subprocess.run(["bash", str(scripts / "restore-verify.sh")],
                        env={**os.environ, "RESTORE_DATABASE": "fit"}, capture_output=True, text=True)
assert result.returncode == 2
print("PASS: production database name refused with exit 2")
with tempfile.TemporaryDirectory(prefix="fit-corrupt-", dir="/tmp/opencode") as directory:
    bundle = Path(directory)
    (bundle / "database.dump").write_bytes(b"corrupt dump")
    (bundle / "manifest.json").write_text(json.dumps({"sha256": "0" * 64}))
    result = subprocess.run(["bash", str(scripts / "restore-verify.sh"), directory], capture_output=True, text=True)
    assert result.returncode != 0 and "checksum mismatch" in result.stderr
print("PASS: corrupt dump refused before creating a database")
