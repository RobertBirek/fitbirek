"""Atomic pg_dump bundles and isolated, checksum-verified restoration drills."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone

ROOT = Path("/docker/fit/data/backups")
COMPOSE = ["docker", "compose", "-f", "/docker/fit/compose.yaml"]


def run(arguments, **kwargs):
    return subprocess.run(arguments, check=True, **kwargs)


def sql(query, database="fit"):
    return run(COMPOSE + ["exec", "-T", "postgres", "psql", "-X", "-v", "ON_ERROR_STOP=1",
                          "-U", "fit", "-d", database, "-Atc", query],
               capture_output=True, text=True).stdout.strip()


def digest(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def backup():
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    temporary = Path(tempfile.mkdtemp(prefix=".partial-", dir=ROOT))
    try:
        dump = temporary / "database.dump"
        with dump.open("xb") as output:
            run(COMPOSE + ["exec", "-T", "postgres", "pg_dump", "-U", "fit", "-d", "fit",
                           "--format=custom", "--serializable-deferrable", "--no-owner", "--no-acl"],
                stdout=output)
            output.flush()
            os.fsync(output.fileno())
        manifest = {
            "created_at": stamp, "sha256": digest(dump),
            "alembic_revision": sql("SELECT version_num FROM alembic_version"),
            "git_sha": run(["git", "-C", "/opt/fit", "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip(),
            "git_dirty": bool(run(["git", "-C", "/opt/fit", "status", "--porcelain"], capture_output=True, text=True).stdout),
            "images": run(["docker", "image", "inspect", "fit-api:production", "fit-migration:production",
                           "--format", "{{.Id}}"], capture_output=True, text=True).stdout.splitlines(),
        }
        with (temporary / "manifest.json").open("x") as output:
            json.dump(manifest, output, indent=2)
            output.flush()
            os.fsync(output.fileno())
        temporary.rename(ROOT / stamp)
        # Keep the latest 35 completed bundles; Restic retains older snapshots.
        for old in sorted(ROOT.glob("20*"))[:-35]:
            if old.is_dir() and (old / "manifest.json").is_file():
                shutil.rmtree(old)
        print(f"Backup verified and published: {ROOT / stamp}")
    finally:
        if temporary.exists():
            shutil.rmtree(temporary)


def restore():
    bundles = sorted(ROOT.glob("20*/manifest.json"))
    bundle = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else (bundles[-1].parent if bundles else None)
    if bundle is None:
        raise SystemExit("No complete backup available")
    manifest = json.loads((bundle / "manifest.json").read_text())
    dump = bundle / "database.dump"
    if digest(dump) != manifest["sha256"]:
        raise SystemExit("Backup checksum mismatch; no database touched")
    if sql("SELECT 1 FROM pg_database WHERE datname='fit_restore'", "postgres"):
        raise SystemExit("fit_restore already exists; investigate before removing it")
    sql("CREATE DATABASE fit_restore OWNER fit", "postgres")
    try:
        with dump.open("rb") as source:
            run(COMPOSE + ["exec", "-T", "postgres", "pg_restore", "-U", "fit", "-d", "fit_restore",
                           "--exit-on-error", "--single-transaction", "--no-owner", "--no-acl"], stdin=source)
        if sql("SELECT version_num FROM alembic_version", "fit_restore") != manifest["alembic_revision"]:
            raise RuntimeError("Restored revision differs from manifest")
        run(COMPOSE + ["run", "--rm", "--no-deps", "-T", "-e", "RESTORE_DATABASE=fit_restore", "migrate"])
        invalid = sql("SELECT count(*) FROM sync_records WHERE id IS NULL OR entity_id IS NULL OR user_id IS NULL OR version IS NULL OR version <= 0", "fit_restore")
        if invalid != "0":
            raise RuntimeError("Invalid restored sync records")
        users = sql("SELECT count(*) FROM users", "fit_restore")
        records = sql("SELECT count(*) FROM sync_records", "fit_restore")
        if int(users) != 1:
            raise RuntimeError("Expected one restored initial account")
        print(f"Restore verified: users={users}, sync_records={records}, invalid=0; bundle={bundle.name}")
    finally:
        sql("DROP DATABASE fit_restore WITH (FORCE)", "postgres")
        print("Isolated restore database removed")


if __name__ == "__main__":
    if os.geteuid() != 0:
        raise SystemExit("Run as root")
    os.umask(0o077)
    if sys.argv[1] == "backup":
        backup()
    elif sys.argv[1] == "restore":
        restore()
    else:
        raise SystemExit("Expected backup or restore")
