#!/bin/sh
# SPDX-FileCopyrightText: Copyright The Thingsboard Authors
# SPDX-License-Identifier: Apache-2.0
set -eu
umask 077

interval="${BACKUP_INTERVAL_SECONDS:-86400}"
retention="${BACKUP_RETENTION_DAYS:-14}"
case "$interval:$retention" in
  *[!0-9:]*|:*|*:) echo "Invalid backup interval or retention" >&2; exit 1 ;;
esac
[ "$interval" -ge 3600 ] && [ "$retention" -ge 1 ] || {
  echo "Backup interval must be >= 3600 seconds and retention >= 1 day" >&2
  exit 1
}

mkdir -p /backups
while :; do
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  final="/backups/bmamonitor-${timestamp}.dump"
  temporary="${final}.partial"
  if pg_dump --format=custom --file="$temporary"; then
    mv "$temporary" "$final"
    find /backups -type f -name 'bmamonitor-*.dump' -mtime "+$retention" -delete
    echo "Backup written: $final"
  else
    rm -f "$temporary"
    echo "Database backup failed" >&2
  fi
  sleep "$interval"
done
