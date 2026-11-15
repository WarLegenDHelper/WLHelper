# Publishes a version: checks that the toc, the CHANGELOG and the tag agree, builds the zip,
# commits, tags vX.Y.Z, pushes and creates the GitHub release with the CHANGELOG section as notes.
#   .\tools\release.ps1 -Sync        copy the addon from AddOns first (usual case)
#   .\tools\release.ps1 -DryRun      check and build only, publish nothing
param(
    [switch]$Sync,
    [switch]$DryRun,
    [string]$AddOns = "G:\World of Warcraft\_forever_\Interface\AddOns"
)
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

& (Join-Path $PSScriptRoot "package.ps1") -Sync:$Sync -AddOns $AddOns

$toc = Get-Content "WLHelper\WLHelper.toc" -Encoding UTF8
$version = (($toc | Where-Object { $_ -match '^## Version:' } | Select-Object -First 1) -replace '^## Version:\s*', '').Trim()
if ($version -notmatch '^\d+\.\d+\.\d+(-(alpha|beta|rc)\.\d+)?$') { throw "Version '$version' is not SemVer (X.Y.Z or X.Y.Z-beta.N)" }
$tag = "v$version"

# The CHANGELOG must have this version's section; its text becomes the release notes.
$log = Get-Content "CHANGELOG.md" -Raw -Encoding UTF8
$m = [regex]::Match($log, "(?ms)^## \[$([regex]::Escape($version))\][^\n]*\n(.*?)(?=^## \[|\z)")
if (-not $m.Success) { throw "CHANGELOG.md has no '## [$version]' section" }
$notes = $m.Groups[1].Value.Trim()
if (git tag --list $tag) { throw "Tag $tag already exists: raise the version in the toc" }

$zip = "dist\WLHelper-$version.zip"
$pre = $version -match '-'
Write-Host "Version $version  tag $tag  zip $zip  beta: $pre"
if ($DryRun) { Write-Host "Dry run: nothing published."; return }

git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { git commit -m "Release $tag" }
git tag -a $tag -m "WL Helper $version"
git push origin HEAD
git push origin $tag
$notesFile = Join-Path $env:TEMP "wlhelper-notes.md"
Set-Content -Path $notesFile -Value $notes -Encoding UTF8
# Betas are published as normal releases on purpose: WowUp only offers non-prerelease versions by default.
gh release create $tag $zip --title "WL Helper $version" --notes-file $notesFile
Remove-Item $notesFile -Force -Confirm:$false
