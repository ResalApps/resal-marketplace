#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

compose() {
  docker compose "$@"
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed or not in PATH." >&2
    exit 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo "ERROR: Docker Compose v2 is required: docker compose ..." >&2
    exit 1
  fi
}

random_hex() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  else
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'
  fi
}

read_default() {
  prompt="$1"
  default="$2"
  printf "%s [%s]: " "$prompt" "$default"
  read -r value || true
  if [ -z "${value:-}" ]; then
    printf "%s" "$default"
  else
    printf "%s" "$value"
  fi
}
