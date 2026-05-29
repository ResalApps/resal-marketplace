#!/usr/bin/env sh
set -eu
. "$(dirname "$0")/common.sh"
require_docker

echo "== Containers =="
docker compose ps

echo "\n== Caddy config validation =="
docker exec -w /etc/caddy report-portal-caddy caddy validate --config /etc/caddy/Caddyfile || true

echo "\n== Recent Caddy logs =="
docker compose logs --tail=80 caddy || true

echo "\n== Recent Authelia logs =="
docker compose logs --tail=80 authelia || true
