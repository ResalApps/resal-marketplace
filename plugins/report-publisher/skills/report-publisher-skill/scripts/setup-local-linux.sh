#!/usr/bin/env sh
set -eu
. "$(dirname "$0")/common.sh"

require_docker
cp .env.local.example .env
mkdir -p caddy/conf.d authelia incoming backups work

jwt_secret="$(random_hex)"
session_secret="$(random_hex)"
storage_key="$(random_hex)"
cp authelia/configuration.yml.template authelia/configuration.yml
sed -i "s|__REPORT_DOMAIN__|reports.resal.test|g" authelia/configuration.yml
sed -i "s|__AUTH_DOMAIN__|auth.resal.test|g" authelia/configuration.yml
sed -i "s|__ROOT_DOMAIN__|resal.test|g" authelia/configuration.yml
sed -i "s|__PUBLIC_SCHEME__|https|g" authelia/configuration.yml
sed -i "s|__JWT_SECRET__|${jwt_secret}|g" authelia/configuration.yml
sed -i "s|__SESSION_SECRET__|${session_secret}|g" authelia/configuration.yml
sed -i "s|__STORAGE_ENCRYPTION_KEY__|${storage_key}|g" authelia/configuration.yml

echo "Creating local test user: samy / ChangeMeNow123!"
hash_output="$(docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'ChangeMeNow123!' 2>/dev/null || true)"
hash="$(printf "%s" "$hash_output" | grep -Eo '\$argon2[^[:space:]]+' | tail -n 1 || true)"
cat > authelia/users_database.yml <<EOF_USERS
---
users:
  samy:
    disabled: false
    displayname: "Samy"
    password: "$hash"
    email: samy@resal.test
    groups:
      - admins
      - viewers
...
EOF_USERS

docker compose --profile tools pull
docker compose -f docker-compose.yml -f docker-compose.local.yml run --rm publisher init

echo "Local setup complete. Add hosts entries for reports.resal.test and auth.resal.test to 127.0.0.1, then run ./scripts/start-local.sh"
