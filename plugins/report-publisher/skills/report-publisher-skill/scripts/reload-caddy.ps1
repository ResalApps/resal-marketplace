$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))
$running = docker ps --format '{{.Names}}' | Select-String '^report-portal-caddy$'
if ($running) {
  docker exec -w /etc/caddy report-portal-caddy caddy reload --config /etc/caddy/Caddyfile
} else {
  Write-Host "Caddy container is not running; skip reload."
}
