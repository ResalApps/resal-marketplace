param(
  [switch]$Local
)
$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

function New-RandomHex([int]$Bytes = 32) {
  $b = New-Object byte[] $Bytes
  [Security.Cryptography.RandomNumberGenerator]::Fill($b)
  ($b | ForEach-Object { $_.ToString("x2") }) -join ""
}
function Require-Docker {
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw "Docker is not installed or not in PATH." }
  docker compose version | Out-Null
}
function Read-Default($Prompt, $Default) {
  $v = Read-Host "$Prompt [$Default]"
  if ([string]::IsNullOrWhiteSpace($v)) { return $Default }
  return $v
}
function ConvertTo-PlainText([Security.SecureString]$Secure) {
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
  try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

Require-Docker
New-Item -ItemType Directory -Force -Path "caddy/conf.d", "authelia", "incoming", "backups", "work" | Out-Null

if ($Local) {
  Copy-Item ".env.local.example" ".env" -Force
  $reportDomain = "reports.resal.test"
  $authDomain = "auth.resal.test"
  $rootDomain = "resal.test"
  $scheme = "https"
  $username = "samy"
  $display = "Samy"
  $email = "samy@resal.test"
  $password = "ChangeMeNow123!"
  Write-Host "Local test mode user: samy / ChangeMeNow123!"
} else {
  if (-not (Test-Path ".env")) {
    $reportDomain = Read-Default "Report domain" "reports.resal.dev"
    $authDomain = Read-Default "Auth domain" "auth.resal.dev"
    $rootDomain = Read-Default "Root cookie domain" "resal.dev"
    $acmeEmail = Read-Default "ACME email" "admin@resal.dev"
    @"
REPORT_DOMAIN=$reportDomain
AUTH_DOMAIN=$authDomain
ROOT_DOMAIN=$rootDomain
ACME_EMAIL=$acmeEmail
TZ=Asia/Riyadh
PUBLIC_SCHEME=https
"@ | Set-Content -Encoding UTF8 ".env"
  } else {
    Write-Host ".env already exists; keeping it."
  }
  $envMap = @{}
  Get-Content ".env" | Where-Object { $_ -match "^[^#].*=" } | ForEach-Object {
    $k, $v = $_ -split "=", 2
    $envMap[$k] = $v
  }
  $reportDomain = $envMap["REPORT_DOMAIN"]
  $authDomain = $envMap["AUTH_DOMAIN"]
  $rootDomain = $envMap["ROOT_DOMAIN"]
  $scheme = if ($envMap.ContainsKey("PUBLIC_SCHEME")) { $envMap["PUBLIC_SCHEME"] } else { "https" }
}

if (-not (Test-Path "authelia/configuration.yml")) {
  $config = Get-Content "authelia/configuration.yml.template" -Raw
  $config = $config.Replace("__REPORT_DOMAIN__", $reportDomain)
  $config = $config.Replace("__AUTH_DOMAIN__", $authDomain)
  $config = $config.Replace("__ROOT_DOMAIN__", $rootDomain)
  $config = $config.Replace("__PUBLIC_SCHEME__", $scheme)
  $config = $config.Replace("__JWT_SECRET__", (New-RandomHex))
  $config = $config.Replace("__SESSION_SECRET__", (New-RandomHex))
  $config = $config.Replace("__STORAGE_ENCRYPTION_KEY__", (New-RandomHex))
  $config | Set-Content -Encoding UTF8 "authelia/configuration.yml"
} else {
  Write-Host "authelia/configuration.yml already exists; keeping it."
}

if (-not (Test-Path "authelia/users_database.yml")) {
  if (-not $Local) {
    $username = Read-Default "Username" "samy"
    $display = Read-Default "Display name" "Samy"
    $email = Read-Default "User email" "samy@resal.dev"
    $secure = Read-Host "Password for $username" -AsSecureString
    $password = ConvertTo-PlainText $secure
  }
  Write-Host "Generating Authelia Argon2 password hash using Docker..."
  $hashOutput = docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password $password 2>$null
  $hash = ($hashOutput | Select-String -Pattern '\$argon2\S+' -AllMatches).Matches.Value | Select-Object -Last 1
  if ([string]::IsNullOrWhiteSpace($hash)) { throw "Could not parse Authelia password hash. Raw output: $hashOutput" }
@"
---
users:
  $username`:
    disabled: false
    displayname: "$display"
    password: "$hash"
    email: $email
    groups:
      - admins
      - viewers
...
"@ | Set-Content -Encoding UTF8 "authelia/users_database.yml"
} else {
  Write-Host "authelia/users_database.yml already exists; keeping it."
}

Write-Host "Pulling images..."
docker compose --profile tools pull
if ($Local) {
  docker compose -f docker-compose.yml -f docker-compose.local.yml run --rm publisher init
  Write-Host "Add hosts entries: 127.0.0.1 reports.resal.test and 127.0.0.1 auth.resal.test"
  Write-Host "Then run: ./scripts/start-local.ps1"
} else {
  docker compose run --rm publisher init
  Write-Host "Setup complete. Run: ./scripts/start.ps1"
}
