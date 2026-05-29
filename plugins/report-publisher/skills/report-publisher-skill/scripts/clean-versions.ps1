[CmdletBinding()]
param(
  [ValidateSet("public", "team", "pin")][string]$Visibility,
  [Alias("RelativeUrl")][string]$Url,
  [Parameter(Mandatory=$false)][int]$Keep,
  [switch]$Local
)
$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))
if (-not $Visibility) { $Visibility = Read-Host "Visibility [public/team/pin]" }
if (-not $Url) { $Url = Read-Host "Relative URL" }
if (-not $PSBoundParameters.ContainsKey("Keep")) { $Keep = [int](Read-Host "Keep how many version folders") }
$composeArgs = @("compose", "-f", "docker-compose.yml")
if ($Local) { $composeArgs += @("-f", "docker-compose.local.yml") }
& docker @composeArgs run --rm publisher clean --visibility $Visibility --url $Url --keep $Keep
