"""Read-only health observations; persist via sender CLI, not the API process."""
import argparse
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import subprocess
import sys
from urllib.request import HTTPRedirectHandler, build_opener

COMPOSE = [
    "docker", "compose",
    "-f", "/docker/fit/compose.yaml",
    "-f", "/docker/fit/compose.push.yaml",
    "-f", "/docker/fit/compose.mentor.yaml",
]
UNITS = {"backup": "fit-backup.service", "restore": "fit-restore-verify.service"}


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def backup_is_stale(root, now):
    dates = []
    for manifest in root.glob("20*/manifest.json"):
        try:
            data = json.loads(manifest.read_text())
            stamp = datetime.strptime(data["created_at"], "%Y%m%dT%H%M%S%fZ").replace(tzinfo=timezone.utc)
            if (manifest.parent / "database.dump").stat().st_size > 0 and stamp <= now + timedelta(minutes=5):
                dates.append(stamp)
        except (OSError, ValueError, KeyError):
            continue
    return not dates or now - max(dates) > timedelta(hours=30)


def unit_failure(unit):
    result = subprocess.run(["systemctl", "show", unit, "--property=Result", "--property=ActiveState", "--property=ExecMainExitTimestampMonotonic"],
                            check=True, capture_output=True, text=True, timeout=10)
    values = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
    # An in-progress retry isn't recovery. Wait for a completed successful run.
    if values.get("ActiveState") in ("activating", "deactivating"):
        return None
    if values.get("Result") == "success" and values.get("ExecMainExitTimestampMonotonic", "0") == "0":
        return None  # A reboot/unrun unit is not proof of recovery.
    return values.get("Result") != "success" or values.get("ActiveState") == "failed"


def api_failure():
    try:
        with build_opener(NoRedirect()).open("https://fit.birek.online/api/health", timeout=8) as response:
            return response.status != 200 or json.loads(response.read(1024)) != {"status": "ok"}
    except Exception:
        return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--failure", choices=list(UNITS.values()))
    args = parser.parse_args()
    now = datetime.now(timezone.utc)
    if args.failure:
        values = {next(name for name, unit in UNITS.items() if unit == args.failure): True}
    else:
        values = {name: unit_failure(unit) for name, unit in UNITS.items()}
        values.update(stale_backup=backup_is_stale(Path("/docker/fit/data/backups"), now), api=api_failure())
    observations = [{"name": name, "failing": value, "observedAt": now.isoformat()}
                    for name, value in values.items() if value is not None]
    subprocess.run(COMPOSE + ["exec", "-T", "push-sender", "python", "-m", "app.push.ops"],
                   input=json.dumps(observations), text=True, check=True, timeout=30,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("Fit push monitor failed; observation not persisted", file=sys.stderr)
        sys.exit(1)
