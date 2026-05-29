param([Parameter(Mandatory=$true)][string]$BackupFile)
$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))
if (-not (Test-Path $BackupFile)) { throw "Backup file not found: $BackupFile" }
$backupFull = (Resolve-Path $BackupFile).Path
Write-Host "Restoring report volume from $backupFull"
docker run --rm -v report_portal_data:/data -v "${backupFull}:/backup.tar.gz:ro" alpine sh -c "rm -rf /data/* && tar xzf /backup.tar.gz -C /data"
Write-Host "Restore complete."
