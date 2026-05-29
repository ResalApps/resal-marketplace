#!/usr/bin/env sh
set -eu
. "$(dirname "$0")/common.sh"
require_docker
BACKUP_FILE="${1:-}"
if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: ./scripts/restore.sh backups/report_portal_data_YYYYMMDD-HHMMSS.tar.gz" >&2
  exit 1
fi
[ -f "$BACKUP_FILE" ] || { echo "Backup file not found: $BACKUP_FILE" >&2; exit 1; }
BACKUP_ABS="$(cd "$(dirname "$BACKUP_FILE")" && pwd)/$(basename "$BACKUP_FILE")"
echo "Restoring report volume from $BACKUP_ABS"
docker run --rm -v report_portal_data:/data -v "$BACKUP_ABS:/backup.tar.gz:ro" alpine sh -c 'rm -rf /data/* && tar xzf /backup.tar.gz -C /data'
echo "Restore complete."
