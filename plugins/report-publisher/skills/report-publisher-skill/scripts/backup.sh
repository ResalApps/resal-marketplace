#!/usr/bin/env sh
set -eu
. "$(dirname "$0")/common.sh"
require_docker
mkdir -p backups
STAMP="$(date +%Y%m%d-%H%M%S)"
echo "Backing up report volume..."
docker run --rm -v report_portal_data:/data:ro -v "$ROOT_DIR/backups:/backup" alpine tar czf "/backup/report_portal_data_${STAMP}.tar.gz" -C /data .
echo "Backing up configuration..."
tar czf "backups/report_portal_config_${STAMP}.tar.gz" docker-compose.yml docker-compose.local.yml .env caddy authelia scripts tools docs skills 2>/dev/null || true
echo "Backup files written to backups/ with stamp $STAMP"
