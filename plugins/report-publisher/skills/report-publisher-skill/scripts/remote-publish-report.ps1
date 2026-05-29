[CmdletBinding()]
param(
  [string]$Server,
  [string]$User,
  [string]$RemotePath = "/opt/report-portal",
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
  [string]$AccessGroups
)
$ErrorActionPreference = "Stop"
if (-not $Server) { $Server = Read-Host "Server hostname/IP" }
if (-not $User) { $User = Read-Host "SSH user" }
if (-not $Source) { $Source = Read-Host "Source file/folder" }
if (-not (Test-Path $Source)) { throw "Source does not exist: $Source" }
if (-not $Visibility) { $Visibility = Read-Host "Visibility [public/team/pin]" }
if (-not $Url) { $Url = Read-Host "Relative URL" }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$archive = Join-Path $env:TEMP "report-$stamp.tar.gz"
$sourceFull = (Resolve-Path $Source).Path
$parent = Split-Path $sourceFull -Parent
$name = Split-Path $sourceFull -Leaf
$remoteIncoming = "$RemotePath/incoming/remote-$stamp"

tar -czf $archive -C $parent $name
ssh "$User@$Server" "mkdir -p '$remoteIncoming'"
scp $archive "$User@$Server`:$remoteIncoming/source.tar.gz"
Remove-Item $archive -Force
ssh "$User@$Server" "cd '$remoteIncoming' && tar xzf source.tar.gz"

$remoteSource = "$remoteIncoming/$name"
$cmd = "cd '$RemotePath' && ./scripts/publish-report.sh --source '$remoteSource' --visibility '$Visibility' --url '$Url' --strategy '$Strategy' --version '$Version' --type '$Type'"
if ($Title) { $safeTitle = $Title.Replace("'", "'\''"); $cmd += " --title '$safeTitle'" }
if ($Pin) { $safePin = $Pin.Replace("'", "'\''"); $cmd += " --pin '$safePin'" }
if ($Keep -ge 0) { $cmd += " --keep '$Keep'" }
if ($Category) { $safeCategory = $Category.Replace("'", "'\''"); $cmd += " --category '$safeCategory'" }
if ($Tags) { $safeTags = $Tags.Replace("'", "'\''"); $cmd += " --tags '$safeTags'" }
if ($AccessUsers) { $safeAccessUsers = $AccessUsers.Replace("'", "'\''"); $cmd += " --access-users '$safeAccessUsers'" }
if ($AccessGroups) { $safeAccessGroups = $AccessGroups.Replace("'", "'\''"); $cmd += " --access-groups '$safeAccessGroups'" }
ssh "$User@$Server" $cmd
