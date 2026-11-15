# Copies the addons (WLHelper and WLHelper_Gear) from this repo into the game's AddOns folder,
# to try them in game (/reload).
# The repo is the source: work here, never in AddOns (WowUp may overwrite that folder).
#   .\tools\install.ps1
param(
    [string]$AddOns = "G:\World of Warcraft\_forever_\Interface\AddOns"
)
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
foreach ($name in @("WLHelper", "WLHelper_Gear")) {
    $src = Join-Path $repo $name
    $dst = Join-Path $AddOns $name
    if (-not (Test-Path (Join-Path $src "$name.toc"))) { throw "Not found: $src" }
    if (Test-Path $dst) { Remove-Item -Recurse -Force $dst -Confirm:$false }
    Copy-Item -Recurse $src $dst
    Write-Host "Installed $src -> $dst"
}
