$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))
New-Item -ItemType Directory -Force -Path "backups" | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host "Backing up report volume..."
docker run --rm -v report_portal_data:/data:ro -v "${PWD}/backups:/backup" alpine tar czf "/backup/report_portal_data_${stamp}.tar.gz" -C /data .
Write-Host "Configuration backup: create a zip of this folder excluding backups if needed."
Write-Host "Backup written to backups/report_portal_data_${stamp}.tar.gz"
