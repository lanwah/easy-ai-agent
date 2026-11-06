#Requires -Version 5.1
<#
.SYNOPSIS
  Install sequential-commit-msg alwaysApply rule into a project's .cursor/rules/.

.PARAMETER ProjectRoot
  Target repository root (default: current directory).

.PARAMETER Force
  Overwrite existing sequential-commit-msg.mdc without prompting.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $ProjectRoot = (Get-Location).Path,

    [Parameter()]
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

$skillDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$template = Join-Path $skillDir 'templates\sequential-commit-msg.mdc'
if (-not (Test-Path -LiteralPath $template)) {
    Write-Error "Template not found: $template"
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$rulesDir = Join-Path $root '.cursor\rules'
$dest = Join-Path $rulesDir 'sequential-commit-msg.mdc'

if (-not (Test-Path -LiteralPath $rulesDir)) {
    New-Item -ItemType Directory -Path $rulesDir -Force | Out-Null
}

if ((Test-Path -LiteralPath $dest) -and -not $Force) {
    Write-Error "Already exists: $dest`nRe-run with -Force to overwrite, or remove the file first."
}

Copy-Item -LiteralPath $template -Destination $dest -Force
Write-Output "OK wrote $dest"
