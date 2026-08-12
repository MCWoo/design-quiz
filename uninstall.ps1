#requires -Version 5.1
<#
.SYNOPSIS
  Removes the codebase-quiz skill from Claude Code's global skills directory.

.DESCRIPTION
  Deletes ~/.claude/skills/codebase-quiz, whether it was installed as a symlink
  or a copy. Safe to re-run: if it's already gone, it's a no-op.

.PARAMETER Help
  Show this help. Short form: -h

.EXAMPLE
  ./uninstall.ps1
#>
[CmdletBinding()]
param(
    [Alias('h')][switch]$Help
)

if ($Help) {
    Get-Help $PSCommandPath -Detailed
    exit 0
}

$ErrorActionPreference = 'Stop'

$SkillName = 'codebase-quiz'
$Target = Join-Path $env:USERPROFILE ".claude\skills\$SkillName"

if (-not (Test-Path $Target)) {
    Write-Host "$SkillName isn't installed at $Target. Nothing to do."
    exit 0
}

Remove-Item $Target -Recurse -Force
Write-Host "Removed $SkillName from $Target."
