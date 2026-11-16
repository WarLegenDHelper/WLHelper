# Builds the release zip for WowUp / manual installs: dist\WLHelper-<version>.zip with the
# WLHelper, WLHelper_Gear, WLHelper_Nav, WLHelper_Nav_EK and WLHelper_Nav_Kalimdor folders at its
# root (WLHelper_Gear and the WLHelper_Nav* folders are separate GPLv3 addons, shipped alongside
# with their licence and notice files, which are checked below). With -Sync, first copies the addon from the game's AddOns folder.
param(
    [switch]$Sync,
    [string]$AddOns = "G:\World of Warcraft\_forever_\Interface\AddOns"
)
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$addon = Join-Path $repo "WLHelper"
$gear = Join-Path $repo "WLHelper_Gear"
# GPL folders shipped beside WL Helper, and the files each must carry (its .toc, licence, notice).
$gpl = [ordered]@{
    "WLHelper_Gear"         = @("WLHelper_Gear.toc", "LICENSE.txt", "NOTICE.md")
    "WLHelper_Nav"          = @("WLHelper_Nav.toc", "LICENSE", "NOTICE.md", "CREDITS.md", "PACK.json")
    "WLHelper_Nav_EK"       = @("WLHelper_Nav_EK.toc", "LICENSE", "NOTICE.md")
    "WLHelper_Nav_Kalimdor" = @("WLHelper_Nav_Kalimdor.toc", "LICENSE", "NOTICE.md")
}

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
$paths = @($addon)
foreach ($name in $gpl.Keys) {
    $dir = Join-Path $repo $name
    foreach ($f in $gpl[$name]) {
        if (-not (Test-Path (Join-Path $dir $f))) { throw "Missing: $name\$f" }
    }
    $paths += $dir
}
Compress-Archive -Path $paths -DestinationPath $zip
Write-Host "Built $zip"
