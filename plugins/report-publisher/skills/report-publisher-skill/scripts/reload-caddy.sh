#!/usr/bin/env sh
set -eu
. "$(dirname "$0")/common.sh"
require_docker
if docker ps --format '{{.Names}}' | grep -qx 'report-portal-caddy'; then
  docker exec -w /etc/caddy report-portal-caddy caddy reload --config /etc/caddy/Caddyfile
else
  echo "Caddy container is not running; skip reload."
fi
