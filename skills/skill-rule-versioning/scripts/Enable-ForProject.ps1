#Requires -Version 5.1
<#
.SYNOPSIS
  Install skill-rule-versioning into a project (rule + optional initial version).

.PARAMETER ProjectRoot
  Target version-unit root: repo root OR a nested skill/subproject directory
  (default: current directory). Parent and child may each have VERSION; versions
  do not auto-link. Install on the child path for an independent nested unit.

.PARAMETER Mode
  Simple | Complex | Auto (default Auto: scripts/references/templates or >3 tracked text files => Complex).

.PARAMETER InitVersion
  Seed version metadata if missing (default: $true). Use -InitVersion:$false to skip.

.PARAMETER Force
  Overwrite existing skill-rule-versioning.mdc without failing.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $ProjectRoot = (Get-Location).Path,

    [Parameter()]
    [ValidateSet('Simple', 'Complex', 'Auto')]
    [string] $Mode = 'Auto',

    [Parameter()]
    [bool] $InitVersion = $true,

    [Parameter()]
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

function Get-Utf8Text {
    param([Parameter(Mandatory = $true)][string] $Path)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    return [System.IO.File]::ReadAllText($Path, $utf8)
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $Content
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Get-Today {
    Get-Date -Format 'yyyy-MM-dd'
}

function Test-HasFrontmatterVersion {
    param([string] $Content)
    return [bool]($Content -match '(?m)^version:\s*\S+')
}

function Ensure-FrontmatterVersion {
    param(
        [string] $Content,
        [string] $Version
    )
    if (Test-HasFrontmatterVersion $Content) {
        return @{ Content = $Content; Changed = $false }
    }
    if ($Content -match '(?s)\A(---\r?\n)(.*?)(\r?\n---\r?\n)(.*)\z') {
        $newContent = $Matches[1] + "version: $Version`r`n" + $Matches[2] + $Matches[3] + $Matches[4]
        return @{ Content = $newContent; Changed = $true }
    }
    $newContent = "---`r`nversion: $Version`r`n---`r`n`r`n" + $Content
    return @{ Content = $newContent; Changed = $true }
}

function Ensure-VersionRecordSection {
    param(
        [string] $Content,
        [string] $Version,
        [string] $Date,
        [string] $Summary
    )
    # Match Chinese heading "版本记录" without putting non-ASCII in this .ps1 source
    # (PS 5.1 may mis-decode UTF-8 scripts without BOM).
    $heading = [string]::Concat([char]0x7248, [char]0x672C, [char]0x8BB0, [char]0x5F55)
    $headingPattern = '(?m)^## ' + [regex]::Escape($heading) + '\s*$'
    if ($Content -match $headingPattern) {
        return @{ Content = $Content; Changed = $false }
    }
    $tick = [char]96
    $block = "`r`n`r`n## $heading`r`n`r`n- $tick$Version$tick $Date $Summary`r`n"
    return @{ Content = ($Content.TrimEnd() + $block); Changed = $true }
}

function Find-MainFile {
    param([string] $Root)
    $candidates = @(
        (Join-Path $Root 'SKILL.md'),
        (Join-Path $Root 'RULE.md'),
        (Join-Path $Root 'AGENTS.md'),
        (Join-Path $Root 'README.md')
    )
    foreach ($p in $candidates) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    $rulesDir = Join-Path $Root '.cursor\rules'
    if (Test-Path -LiteralPath $rulesDir) {
        $mdcs = @(Get-ChildItem -LiteralPath $rulesDir -Filter '*.mdc' -File |
            Where-Object { $_.Name -ne 'skill-rule-versioning.mdc' } |
            Sort-Object Name)
        if ($mdcs.Count -eq 1) { return $mdcs[0].FullName }
        if ($mdcs.Count -gt 1) {
            $preferred = $mdcs | Where-Object { $_.Name -match 'README|index|main' } | Select-Object -First 1
            if ($preferred) { return $preferred.FullName }
            return $mdcs[0].FullName
        }
    }
    return $null
}

function Resolve-Mode {
    param(
        [string] $Root,
        [string] $Requested
    )
    if ($Requested -ne 'Auto') { return $Requested }

    foreach ($name in @('scripts', 'references', 'templates')) {
        if (Test-Path -LiteralPath (Join-Path $Root $name)) { return 'Complex' }
    }

    $textFiles = @(Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '[\\/]\.git[\\/]' -and
            $_.FullName -notmatch '[\\/]node_modules[\\/]' -and
            $_.Extension -match '\.(md|mdc|txt|ps1|py|js|ts|json|yml|yaml)$'
        })
    if ($textFiles.Count -gt 3) { return 'Complex' }
    return 'Simple'
}

$skillDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$template = Join-Path $skillDir 'templates\skill-rule-versioning.mdc'
if (-not (Test-Path -LiteralPath $template)) {
    Write-Error "Template not found: $template"
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$rulesDir = Join-Path $root '.cursor\rules'
$dest = Join-Path $rulesDir 'skill-rule-versioning.mdc'

if (-not (Test-Path -LiteralPath $rulesDir)) {
    New-Item -ItemType Directory -Path $rulesDir -Force | Out-Null
}

if ((Test-Path -LiteralPath $dest) -and -not $Force) {
    Write-Error "Already exists: $dest`nRe-run with -Force to overwrite, or remove the file first."
}

Copy-Item -LiteralPath $template -Destination $dest -Force
Write-Output "OK wrote $dest"

$resolvedMode = Resolve-Mode -Root $root -Requested $Mode
Write-Output "Mode: $resolvedMode"

if (-not $InitVersion) {
    Write-Output 'InitVersion skipped.'
    exit 0
}

$version = '1.0.0'
$date = Get-Today
$summary = 'Enable skill-rule-versioning; establish initial version baseline'
$mainFile = Find-MainFile -Root $root

if ($resolvedMode -eq 'Complex') {
    $versionPath = Join-Path $root 'VERSION'
    $changelogPath = Join-Path $root 'CHANGELOG.md'

    if (-not (Test-Path -LiteralPath $versionPath)) {
        Write-Utf8File -Path $versionPath -Content "$version`r`n"
        Write-Output "OK wrote $versionPath"
    }
    else {
        $version = (Get-Utf8Text -Path $versionPath).Trim()
        if (-not $version) { $version = '1.0.0' }
        Write-Output "VERSION exists: $version"
    }

    if (-not (Test-Path -LiteralPath $changelogPath)) {
        $tick = [char]96
        $cl = "# Changelog`r`n`r`n- $tick$version$tick $date $summary`r`n"
        Write-Utf8File -Path $changelogPath -Content $cl
        Write-Output "OK wrote $changelogPath"
    }
    else {
        Write-Output "CHANGELOG exists: $changelogPath"
    }

    if ($mainFile) {
        $raw = Get-Utf8Text -Path $mainFile
        $r = Ensure-FrontmatterVersion -Content $raw -Version $version
        if ($r.Changed) {
            Write-Utf8File -Path $mainFile -Content $r.Content
            Write-Output "OK synced version in $mainFile"
        }
        else {
            Write-Output "Main file already has version: $mainFile"
        }
    }
    else {
        Write-Output 'WARN: no main file found to sync frontmatter version.'
    }
}
else {
    if (-not $mainFile) {
        Write-Output 'WARN: Simple mode but no main file (SKILL.md / RULE.md / AGENTS.md / single .mdc); skip seed.'
        exit 0
    }
    $raw = Get-Utf8Text -Path $mainFile
    $r1 = Ensure-FrontmatterVersion -Content $raw -Version $version
    $content = $r1.Content
    $r2 = Ensure-VersionRecordSection -Content $content -Version $version -Date $date -Summary $summary
    $content = $r2.Content
    if ($r1.Changed -or $r2.Changed) {
        Write-Utf8File -Path $mainFile -Content $content
        Write-Output "OK seeded version metadata in $mainFile"
    }
    else {
        Write-Output "Main file already versioned: $mainFile"
    }
}

Write-Output "Done. Baseline $version ($resolvedMode)"
