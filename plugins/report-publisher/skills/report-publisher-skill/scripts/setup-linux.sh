#!/usr/bin/env sh
set -eu
. "$(dirname "$0")/common.sh"

require_docker

mkdir -p caddy/conf.d authelia incoming backups work

if [ ! -f .env ]; then
  echo "Creating .env"
  report_domain="$(read_default "Report domain" "reports.resal.dev")"
  auth_domain="$(read_default "Auth domain" "auth.resal.dev")"
  root_domain="$(read_default "Root cookie domain" "resal.dev")"
  acme_email="$(read_default "ACME email" "admin@resal.dev")"
  cat > .env <<EOF_ENV
REPORT_DOMAIN=$report_domain
AUTH_DOMAIN=$auth_domain
ROOT_DOMAIN=$root_domain
ACME_EMAIL=$acme_email
TZ=Asia/Riyadh
PUBLIC_SCHEME=https
EOF_ENV
else
  echo ".env already exists; keeping it."
fi

# Load .env values safely for simple KEY=VALUE lines.
set -a
. ./.env
set +a

if [ ! -f authelia/configuration.yml ]; then
  echo "Generating Authelia configuration.yml"
  jwt_secret="$(random_hex)"
  session_secret="$(random_hex)"
  storage_key="$(random_hex)"
  cp authelia/configuration.yml.template authelia/configuration.yml
  sed -i "s|__REPORT_DOMAIN__|${REPORT_DOMAIN}|g" authelia/configuration.yml
  sed -i "s|__AUTH_DOMAIN__|${AUTH_DOMAIN}|g" authelia/configuration.yml
  sed -i "s|__ROOT_DOMAIN__|${ROOT_DOMAIN}|g" authelia/configuration.yml
  sed -i "s|__PUBLIC_SCHEME__|${PUBLIC_SCHEME:-https}|g" authelia/configuration.yml
  sed -i "s|__JWT_SECRET__|${jwt_secret}|g" authelia/configuration.yml
  sed -i "s|__SESSION_SECRET__|${session_secret}|g" authelia/configuration.yml
  sed -i "s|__STORAGE_ENCRYPTION_KEY__|${storage_key}|g" authelia/configuration.yml
else
  echo "authelia/configuration.yml already exists; keeping it."
fi

if [ ! -f authelia/users_database.yml ]; then
  echo "Creating first Authelia user"
  username="$(read_default "Username" "samy")"
  displayname="$(read_default "Display name" "Samy")"
  email="$(read_default "User email" "samy@resal.dev")"
  printf "Password for %s: " "$username"
  stty -echo || true
  read -r password
  stty echo || true
  printf "\n"

  echo "Generating Authelia Argon2 password hash using Docker..."
  hash_output="$(docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password "$password" 2>/dev/null || true)"
  hash="$(printf "%s" "$hash_output" | grep -Eo '\$argon2[^[:space:]]+' | tail -n 1 || true)"
  if [ -z "$hash" ]; then
    echo "ERROR: Could not parse Authelia password hash. Raw output:" >&2
    printf "%s\n" "$hash_output" >&2
    exit 1
  fi

  cat > authelia/users_database.yml <<EOF_USERS
---
users:
  $username:
    disabled: false
    displayname: "$displayname"
    password: "$hash"
    email: $email
    groups:
      - admins
      - viewers
...
EOF_USERS
else
  echo "authelia/users_database.yml already exists; keeping it."
fi

echo "Pulling container images..."
docker compose --profile tools pull

echo "Initializing report volume and landing pages..."
docker compose run --rm publisher init

echo "Setup complete. Start with: ./scripts/start.sh"
