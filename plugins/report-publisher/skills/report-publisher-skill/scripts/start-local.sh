#!/usr/bin/env sh
set -eu
. "$(dirname "$0")/common.sh"
require_docker
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d
