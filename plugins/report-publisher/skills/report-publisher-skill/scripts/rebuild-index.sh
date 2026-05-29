#!/usr/bin/env sh
set -eu
. "$(dirname "$0")/common.sh"
require_docker
docker compose run --rm publisher rebuild-index
