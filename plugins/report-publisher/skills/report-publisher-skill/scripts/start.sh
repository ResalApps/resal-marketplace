#!/usr/bin/env sh
set -eu
. "$(dirname "$0")/common.sh"
require_docker
docker compose up -d
