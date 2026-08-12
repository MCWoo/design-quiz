#requires -Version 5.1
<#
.SYNOPSIS
  Installs the codebase-quiz skill into Claude Code's global skills directory.

.DESCRIPTION
  Links (or, as a fallback, copies) dotclaude/skills/codebase-quiz into
  ~/.claude/skills/codebase-quiz so Claude Code picks it up globally.

  Prefers a symlink so edits made in this repo take effect immediately without
  reinstalling. Symlink creation on Windows needs either Developer Mode enabled
  or an elevated shell; if it fails, this script falls back to a plain copy and
  says so, since a copy install needs to be re-run (with -Force / -f) to pick up
  future source edits.

  Safe to re-run: if the skill is already installed and up to date, it's a no-op.

.PARAMETER Force
  Overwrite an existing install (e.g. a stale copy, or a symlink pointing
  somewhere else). Short form: -f

.PARAMETER Copy
  Install as a plain copy instead of attempting a symlink. Useful if you don't
  want live-editing behavior, or symlinks are causing trouble in your environment.

.PARAMETER Help
  Show this help. Short form: -h

.EXAMPLE
  ./install.ps1

.EXAMPLE
  ./install.ps1 -Force

.EXAMPLE
  ./install.ps1 -Copy -f
#>
[CmdletBinding()]
param(
    [Alias('f')][switch]$Force,
    [switch]$Copy,
    [Alias('h')][switch]$Help
)

if ($Help) {
    Get-Help $PSCommandPath -Detailed
    exit 0
}

$ErrorActionPreference = 'Stop'

function Test-DirectoryContentMatches {
    # Compares two directory trees by relative path + file hash, so a copy
    # install can be recognized as already up to date instead of always
    # demanding -Force just to be a no-op.
    param([string]$PathA, [string]$PathB)

    $hashesA = Get-ChildItem $PathA -Recurse -File | ForEach-Object {
        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring((Resolve-Path $PathA).Path.Length)
            Hash         = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        }
    }
    $hashesB = Get-ChildItem $PathB -Recurse -File | ForEach-Object {
        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring((Resolve-Path $PathB).Path.Length)
            Hash         = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        }
    }

    $diff = Compare-Object $hashesA $hashesB -Property RelativePath, Hash
    return -not $diff
}

$SkillName = 'codebase-quiz'
$Source = Join-Path $PSScriptRoot "dotclaude\skills\$SkillName"
$SkillsRoot = Join-Path $env:USERPROFILE '.claude\skills'
$Target = Join-Path $SkillsRoot $SkillName

if (-not (Test-Path $Source)) {
    Write-Error "Source skill not found at $Source. Run this script from the project root."
    exit 1
}

if (-not (Test-Path $SkillsRoot)) {
    New-Item -ItemType Directory -Path $SkillsRoot -Force | Out-Null
}

if (Test-Path $Target) {
    $existingItem = Get-Item $Target -Force
    $isSymlinkToSource = $existingItem.LinkType -eq 'SymbolicLink' -and
        $existingItem.Target -and
        ((Resolve-Path $existingItem.Target[0]).Path -eq (Resolve-Path $Source).Path)

    if ($isSymlinkToSource -and -not $Copy) {
        Write-Host "Already installed (symlink -> $Source). Nothing to do."
        exit 0
    }

    if (-not $isSymlinkToSource -and (Test-DirectoryContentMatches $Source $Target)) {
        Write-Host "Already installed as an up-to-date copy at $Target. Nothing to do."
        exit 0
    }

    if (-not $Force) {
        Write-Error "$Target already exists and is out of date (or isn't this repo's copy). Re-run with -Force (-f) to overwrite it."
        exit 1
    }

    Remove-Item $Target -Recurse -Force
}

if ($Copy) {
    Copy-Item $Source $Target -Recurse -Force
    Write-Host "Installed $SkillName as a copy at $Target."
    Write-Host "Note: edits in this repo won't show up until you re-run 'install.ps1 -Force -Copy'."
    exit 0
}

try {
    New-Item -ItemType SymbolicLink -Path $Target -Target $Source -ErrorAction Stop | Out-Null
    Write-Host "Installed $SkillName as a symlink: $Target -> $Source"
    Write-Host "Edits to files in this repo take effect immediately."
} catch {
    Write-Warning "Couldn't create a symlink ($($_.Exception.Message)). Falling back to a copy."
    Write-Warning "To enable symlinks without this fallback, turn on Windows Developer Mode (Settings > Update & Security > For developers) or run this script as Administrator."
    Copy-Item $Source $Target -Recurse -Force
    Write-Host "Installed $SkillName as a copy at $Target."
    Write-Host "Note: edits in this repo won't show up until you re-run 'install.ps1 -Force -Copy'."
}
