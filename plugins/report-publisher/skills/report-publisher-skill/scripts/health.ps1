$ErrorActionPreference = "Continue"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))
Write-Host "== Containers =="
docker compose ps
Write-Host "`n== Caddy config validation =="
docker exec -w /etc/caddy report-portal-caddy caddy validate --config /etc/caddy/Caddyfile
Write-Host "`n== Recent Caddy logs =="
docker compose logs --tail=80 caddy
Write-Host "`n== Recent Authelia logs =="
docker compose logs --tail=80 authelia
