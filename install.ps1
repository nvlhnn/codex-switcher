[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot 'CodexSwitcher.psm1'

if (-not (Test-Path -LiteralPath $modulePath)) {
    throw "Module not found: $modulePath"
}

$profileDirectory = Split-Path -Parent $PROFILE
New-Item -ItemType Directory -Force -Path $profileDirectory | Out-Null

if (-not (Test-Path -LiteralPath $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE | Out-Null
}

$escapedModulePath = $modulePath.Replace("'", "''")
$importLine = "Import-Module '$escapedModulePath'"
$existing = Get-Content -LiteralPath $PROFILE -Raw

if ($existing -notmatch [regex]::Escape($importLine)) {
    Add-Content -LiteralPath $PROFILE -Value "`n$importLine"
    Write-Host "Added Codex Switcher to: $PROFILE"
}
else {
    Write-Host 'Codex Switcher is already installed in this PowerShell profile.'
}

Import-Module $modulePath -Force
Write-Host 'Installed. Start with: codex-account save personal' -ForegroundColor Green
