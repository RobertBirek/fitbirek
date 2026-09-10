#!/usr/bin/env bash
set -euo pipefail
exec flock -w 900 /run/lock/fit-backup-restore.lock python3 /opt/fit/deploy/ops/database-backup.py backup
