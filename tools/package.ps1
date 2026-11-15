# Builds the release zip for WowUp / manual installs: dist\WLHelper-<version>.zip with the
# WLHelper folder at its root. With -Sync, first copies the addon from the game's AddOns folder.
param(
    [switch]$Sync,
    [string]$AddOns = "G:\World of Warcraft\_forever_\Interface\AddOns"
)
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$addon = Join-Path $repo "WLHelper"

if ($Sync) {
    $src = Join-Path $AddOns "WLHelper"
    if (-not (Test-Path (Join-Path $src "WLHelper.toc"))) { throw "Not found: $src" }
    Remove-Item -Recurse -Force $addon -Confirm:$false
    Copy-Item -Recurse $src $addon
    Write-Host "Synced from $src"
}

$toc = Get-Content (Join-Path $addon "WLHelper.toc") -Encoding UTF8
$version = ($toc | Where-Object { $_ -match '^## Version:\s*(.+)$' } | Select-Object -First 1) -replace '^## Version:\s*', ''
if (-not $version) { throw "No version in the toc" }

$dist = Join-Path $repo "dist"
New-Item -ItemType Directory -Force $dist | Out-Null
$zip = Join-Path $dist ("WLHelper-{0}.zip" -f $version.Trim())
if (Test-Path $zip) { Remove-Item -Force $zip -Confirm:$false }
Compress-Archive -Path $addon -DestinationPath $zip
Write-Host "Built $zip"
