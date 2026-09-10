#!/usr/bin/env bash
set -euo pipefail
# Validate before acquiring the lock or invoking Docker.
if [[ "${RESTORE_DATABASE:-fit_restore}" != fit_restore ]]; then
    printf '%s\n' 'Refusing restore: only the isolated fit_restore database is allowed.' >&2
    exit 2
fi
exec flock -w 900 /run/lock/fit-backup-restore.lock python3 /opt/fit/deploy/ops/database-backup.py restore "$@"
