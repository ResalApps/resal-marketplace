$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))
docker compose -f docker-compose.yml -f docker-compose.local.yml down
