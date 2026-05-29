#!/usr/bin/env bash
set -euo pipefail

SERVER=""; USER=""; REMOTE_PATH="/opt/report-portal"; SOURCE=""; VISIBILITY=""; REL_URL=""; TITLE=""; STRATEGY="versioned"; VERSION="auto"; TYPE="auto"; PIN=""; KEEP=""; CATEGORY=""; TAGS=""; ACCESS_USERS=""; ACCESS_GROUPS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --server) SERVER="$2"; shift 2 ;;
    --user) USER="$2"; shift 2 ;;
    --remote-path) REMOTE_PATH="$2"; shift 2 ;;
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
    -h|--help)
      echo "Usage: ./scripts/remote-publish-report.sh --server VPS_IP --user root --source ./report --visibility team --url my/report [options]"
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done
[[ -n "$SERVER" ]] || read -r -p "Server hostname/IP: " SERVER
[[ -n "$USER" ]] || read -r -p "SSH user: " USER
[[ -n "$SOURCE" && -e "$SOURCE" ]] || { echo "Source required and must exist." >&2; exit 1; }
[[ -n "$VISIBILITY" ]] || read -r -p "Visibility [public/team/pin]: " VISIBILITY
[[ -n "$REL_URL" ]] || read -r -p "Relative URL: " REL_URL

STAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="/tmp/report-${STAMP}.tar.gz"
REMOTE_INCOMING="${REMOTE_PATH}/incoming/remote-${STAMP}"

tar czf "$ARCHIVE" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")"
ssh "$USER@$SERVER" "mkdir -p '$REMOTE_INCOMING'"
scp "$ARCHIVE" "$USER@$SERVER:$REMOTE_INCOMING/source.tar.gz"
rm -f "$ARCHIVE"

REMOTE_SOURCE="$REMOTE_INCOMING/$(basename "$SOURCE")"
ssh "$USER@$SERVER" "cd '$REMOTE_INCOMING' && tar xzf source.tar.gz"

cmd=("cd '$REMOTE_PATH' && ./scripts/publish-report.sh --source '$REMOTE_SOURCE' --visibility '$VISIBILITY' --url '$REL_URL' --strategy '$STRATEGY' --version '$VERSION' --type '$TYPE'")
[[ -n "$TITLE" ]] && cmd+=(" --title '$(printf "%s" "$TITLE" | sed "s/'/'\\''/g")'")
[[ -n "$PIN" ]] && cmd+=(" --pin '$(printf "%s" "$PIN" | sed "s/'/'\\''/g")'")
[[ -n "$KEEP" ]] && cmd+=(" --keep '$KEEP'")
[[ -n "$CATEGORY" ]] && cmd+=(" --category '$(printf "%s" "$CATEGORY" | sed "s/'/'\\''/g")'")
[[ -n "$TAGS" ]] && cmd+=(" --tags '$(printf "%s" "$TAGS" | sed "s/'/'\\''/g")'")
[[ -n "$ACCESS_USERS" ]] && cmd+=(" --access-users '$(printf "%s" "$ACCESS_USERS" | sed "s/'/'\\''/g")'")
[[ -n "$ACCESS_GROUPS" ]] && cmd+=(" --access-groups '$(printf "%s" "$ACCESS_GROUPS" | sed "s/'/'\\''/g")'")
ssh "$USER@$SERVER" "${cmd[*]}"
