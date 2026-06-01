#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT_DIR"

require_docker() {
  command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker is not installed or not in PATH." >&2; exit 1; }
  docker compose version >/dev/null 2>&1 || { echo "ERROR: Docker Compose v2 is required." >&2; exit 1; }
}
require_docker

SERVER_URL=""; API_KEY="${MCP_PUBLISH_API_KEY:-}"; SOURCE=""; VISIBILITY=""; REL_URL=""; TITLE=""; STRATEGY="versioned"; VERSION="auto"; TYPE="auto"; PIN=""; KEEP=""; CATEGORY=""; TAGS=""; ACCESS_USERS=""; ACCESS_GROUPS=""; LOCAL_MODE="0"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --server-url) SERVER_URL="$2"; shift 2 ;;
    --api-key) API_KEY="$2"; shift 2 ;;
    --source) SOURCE="$2"; shift 2 ;;
    --visibility) VISIBILITY="$2"; shift 2 ;;
    --url|--relative-url) REL_URL="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --strategy) STRATEGY="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --pin) PIN="$2"; shift 2 ;;
    --keep) KEEP="$2"; shift 2 ;;
    --category) CATEGORY="$2"; shift 2 ;;
    --tags) TAGS="$2"; shift 2 ;;
    --access-users) ACCESS_USERS="$2"; shift 2 ;;
    --access-groups) ACCESS_GROUPS="$2"; shift 2 ;;
    --local) LOCAL_MODE="1"; shift ;;
    -h|--help)
      cat <<HELP
Usage:
  ./scripts/remote-publish-report.sh --server-url https://reports.example.test --source ./report --visibility public|team|pin --url relative/path [options]

Options:
  --api-key "<MCP_PUBLISH_API_KEY>"  Defaults to the MCP_PUBLISH_API_KEY environment variable
  --title "Report Title"
  --strategy versioned|replace       Default: versioned
  --version v1|v2026-05-27|auto      Default: auto
  --type auto|html|markdown          Default: auto
  --pin "123456"                     Local PIN prompt/hash helper for pin visibility
  --keep N                           Keep only N old version folders
  --category "Finance"               Category shown on generated indexes
  --tags "q2,board"                  Comma-separated report tags
  --access-users "samy,fatima"       Comma-separated team users for metadata
  --access-groups "admins,team"      Comma-separated team groups for metadata
  --local                            Use docker-compose.local.yml for local testing
HELP
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$SERVER_URL" ]] || read -r -p "Reports base URL (for example https://reports.example.test): " SERVER_URL
[[ -n "$API_KEY" ]] || { read -r -s -p "MCP publish API key: " API_KEY; echo; }
[[ -n "$SOURCE" && -e "$SOURCE" ]] || { echo "Source required and must exist." >&2; exit 1; }
[[ -n "$VISIBILITY" ]] || read -r -p "Visibility [public/team/pin]: " VISIBILITY
[[ -n "$REL_URL" ]] || read -r -p "Relative URL: " REL_URL
if [[ "$VISIBILITY" == "pin" && -z "$PIN" ]]; then
  read -r -s -p "PIN/password for this report URL: " PIN
  echo
fi

SOURCE_ABS="$(cd "$(dirname "$SOURCE")" && pwd)/$(basename "$SOURCE")"
COMPOSE_ARGS=(-f docker-compose.yml)
if [[ "$LOCAL_MODE" == "1" ]]; then COMPOSE_ARGS=(-f docker-compose.yml -f docker-compose.local.yml); fi

PIN_SHA256=""
if [[ "$VISIBILITY" == "pin" && -n "$PIN" ]]; then
  if command -v sha256sum >/dev/null 2>&1; then
    PIN_SHA256="$(printf '%s' "$PIN" | sha256sum | awk '{print $1}')"
  else
    PIN_SHA256="$(printf '%s' "$PIN" | shasum -a 256 | awk '{print $1}')"
  fi
fi

REMOTE_ARGS=(remote-publish --server-url "$SERVER_URL" --api-key "$API_KEY" --source /source --visibility "$VISIBILITY" --url "$REL_URL" --strategy "$STRATEGY" --version "$VERSION" --type "$TYPE")
[[ -n "$TITLE" ]] && REMOTE_ARGS+=(--title "$TITLE")
[[ -n "$PIN_SHA256" ]] && REMOTE_ARGS+=(--pin-sha256 "$PIN_SHA256")
[[ -n "$KEEP" ]] && REMOTE_ARGS+=(--keep "$KEEP")
[[ -n "$CATEGORY" ]] && REMOTE_ARGS+=(--category "$CATEGORY")
[[ -n "$TAGS" ]] && REMOTE_ARGS+=(--tags "$TAGS")
[[ -n "$ACCESS_USERS" ]] && REMOTE_ARGS+=(--access-users "$ACCESS_USERS")
[[ -n "$ACCESS_GROUPS" ]] && REMOTE_ARGS+=(--access-groups "$ACCESS_GROUPS")

docker compose "${COMPOSE_ARGS[@]}" run --rm -v "$SOURCE_ABS:/source:ro" publisher "${REMOTE_ARGS[@]}"
