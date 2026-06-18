[CmdletBinding()]
param(
  [string]$ServerUrl,
  [string]$ApiKey = $env:MCP_PUBLISH_API_KEY,
  [string]$Source,
  [ValidateSet("public", "team", "pin")][string]$Visibility,
  [Alias("RelativeUrl")][string]$Url,
  [string]$Title,
  [ValidateSet("versioned", "replace")][string]$Strategy = "versioned",
  [string]$Version = "auto",
  [ValidateSet("auto", "html", "markdown")][string]$Type = "auto",
  [string]$Pin,
  [int]$Keep = -1,
  [string]$Category,
  [string]$Tags,
  [string]$AccessUsers,
  [string]$AccessGroups,
  [switch]$Local
)
$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

if (-not $ServerUrl) { $ServerUrl = Read-Host "Reports base URL (https://reports.resal.dev or https://reports.abushanab.net)" }
if (-not $ApiKey) { $ApiKey = Read-Host "MCP publish API key" }
if (-not $Source) { $Source = Read-Host "Source file/folder" }
if (-not (Test-Path $Source)) { throw "Source does not exist: $Source" }
if (-not $Visibility) { $Visibility = Read-Host "Visibility [public/team/pin]" }
if (-not $Url) { $Url = Read-Host "Relative URL" }
if ($Visibility -eq "pin" -and -not $Pin) {
  $secure = Read-Host "PIN/password for this report URL" -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { $Pin = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

$allowCustomServer = $env:REPORT_PUBLISHER_ALLOW_CUSTOM_SERVER -eq "1"
if (-not $allowCustomServer) {
  $approvedHosts = @("reports.resal.dev", "reports.abushanab.net")
  $serverUri = [Uri]$ServerUrl
  if ($serverUri.Scheme -ne "https") {
    throw "ServerUrl must use https unless REPORT_PUBLISHER_ALLOW_CUSTOM_SERVER=1 is set."
  }
  if ($approvedHosts -notcontains $serverUri.Host) {
    throw "ServerUrl must be reports.resal.dev or reports.abushanab.net. Set REPORT_PUBLISHER_ALLOW_CUSTOM_SERVER=1 only for an approved diagnostic."
  }
}

$sourceFull = (Resolve-Path $Source).Path
$composeArgs = @("compose", "-f", "docker-compose.yml")
if ($Local) { $composeArgs += @("-f", "docker-compose.local.yml") }

$pinSha256 = ""
if ($Visibility -eq "pin" -and $Pin) {
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.Encoding]::UTF8.GetBytes($Pin)
    $pinSha256 = (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
  }
  finally {
    $sha.Dispose()
  }
}

$remoteArgs = @("run", "--rm", "-v", "${sourceFull}:/source:ro", "publisher", "remote-publish", "--server-url", $ServerUrl, "--api-key", $ApiKey, "--source", "/source", "--visibility", $Visibility, "--url", $Url, "--strategy", $Strategy, "--version", $Version, "--type", $Type)
if ($Title) { $remoteArgs += @("--title", $Title) }
if ($pinSha256) { $remoteArgs += @("--pin-sha256", $pinSha256) }
if ($Keep -ge 0) { $remoteArgs += @("--keep", [string]$Keep) }
if ($Category) { $remoteArgs += @("--category", $Category) }
if ($Tags) { $remoteArgs += @("--tags", $Tags) }
if ($AccessUsers) { $remoteArgs += @("--access-users", $AccessUsers) }
if ($AccessGroups) { $remoteArgs += @("--access-groups", $AccessGroups) }

& docker @composeArgs @remoteArgs
