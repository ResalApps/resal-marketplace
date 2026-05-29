#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"
command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker is not installed or not in PATH." >&2; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "ERROR: Docker Compose v2 is required." >&2; exit 1; }
VISIBILITY=""; REL_URL=""; KEEP=""; LOCAL_MODE="0"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --visibility) VISIBILITY="$2"; shift 2 ;;
    --url|--relative-url) REL_URL="$2"; shift 2 ;;
    --keep) KEEP="$2"; shift 2 ;;
    --local) LOCAL_MODE="1"; shift ;;
    -h|--help) echo "Usage: ./scripts/clean-versions.sh --visibility public|team|pin --url relative/path --keep 5"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$VISIBILITY" ]] || read -r -p "Visibility [public/team/pin]: " VISIBILITY
[[ -n "$REL_URL" ]] || read -r -p "Relative URL: " REL_URL
[[ -n "$KEEP" ]] || read -r -p "Keep how many version folders: " KEEP
COMPOSE_ARGS=(-f docker-compose.yml)
if [[ "$LOCAL_MODE" == "1" ]]; then COMPOSE_ARGS=(-f docker-compose.yml -f docker-compose.local.yml); fi
docker compose "${COMPOSE_ARGS[@]}" run --rm publisher clean --visibility "$VISIBILITY" --url "$REL_URL" --keep "$KEEP"
