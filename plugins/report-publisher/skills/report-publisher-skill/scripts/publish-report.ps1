[CmdletBinding()]
param(
  [string]$Source,
  [ValidateSet("public", "team", "pin")][string]$Visibility,
  [Alias("RelativeUrl")][string]$Url,
  [string]$Title,
  [ValidateSet("versioned", "replace")][string]$Strategy,
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

if (-not $Source) { $Source = Read-Host "Source file/folder" }
if (-not (Test-Path $Source)) { throw "Source does not exist: $Source" }
if (-not $Visibility) { $Visibility = Read-Host "Visibility [public/team/pin]" }
if ($Visibility -notin @("public", "team", "pin")) { throw "Invalid visibility: $Visibility" }
if (-not $Url) { $Url = Read-Host "Relative URL, e.g. architecture/review" }
if (-not $Title) { $Title = Read-Host "Title [optional]" }
if (-not $Strategy) {
  $Strategy = Read-Host "Publish strategy [versioned/replace] (default versioned)"
  if ([string]::IsNullOrWhiteSpace($Strategy)) { $Strategy = "versioned" }
}

$pinSha256 = ""
if ($Visibility -eq "pin") {
  if (-not $Pin) {
    $secure = Read-Host "PIN/password for this report URL" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $Pin = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
  }
  if ($Pin) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
      $bytes = [Text.Encoding]::UTF8.GetBytes($Pin)
      $pinSha256 = (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
    }
    finally {
      $sha.Dispose()
    }
  }
}

$sourceFull = (Resolve-Path $Source).Path
$composeArgs = @("compose", "-f", "docker-compose.yml")
if ($Local) { $composeArgs += @("-f", "docker-compose.local.yml") }
$publishArgs = @("run", "--rm", "-v", "${sourceFull}:/source:ro", "publisher", "publish", "--source", "/source", "--visibility", $Visibility, "--url", $Url, "--strategy", $Strategy, "--version", $Version, "--type", $Type)
if ($Title) { $publishArgs += @("--title", $Title) }
if ($pinSha256) { $publishArgs += @("--pin-sha256", $pinSha256) }
if ($Keep -ge 0) { $publishArgs += @("--keep", [string]$Keep) }
if ($Category) { $publishArgs += @("--category", $Category) }
if ($Tags) { $publishArgs += @("--tags", $Tags) }
if ($AccessUsers) { $publishArgs += @("--access-users", $AccessUsers) }
if ($AccessGroups) { $publishArgs += @("--access-groups", $AccessGroups) }

& docker @composeArgs @publishArgs

try { & "$PSScriptRoot/reload-caddy.ps1" } catch { Write-Warning $_ }
Write-Host "Published. Open the corresponding URL under your reports domain."
