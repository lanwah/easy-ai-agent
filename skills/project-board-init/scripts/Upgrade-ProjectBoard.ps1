# Version-aware, manifest-driven project-board upgrade.
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [switch]$Apply,
  [switch]$Force,
  [string]$SkillDir,
  [string]$ConfigDefaultsPath,
  [string]$ConfigLocalPath
)
$ErrorActionPreference = 'Stop'
if (-not $SkillDir) { $SkillDir = Split-Path -Parent $PSScriptRoot }
if (-not $ConfigDefaultsPath) { $ConfigDefaultsPath = Join-Path $SkillDir 'config.defaults.json' }
if (-not $ConfigLocalPath) { $ConfigLocalPath = Join-Path $SkillDir 'config.local.json' }
$installer = Join-Path $PSScriptRoot 'Install-ProjectBoard.ps1'
$versionFile = Join-Path $SkillDir 'VERSION'
if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) { throw "Installer not found: $installer" }
if (-not (Test-Path -LiteralPath $versionFile -PathType Leaf)) { throw "Skill VERSION not found: $versionFile" }
$targetVersion = (Get-Content -LiteralPath $versionFile -Raw -Encoding UTF8).Trim()
$manifestPath = Join-Path $RepoRoot '.project-board/manifest.json'
$fromVersion = $null
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
  try {
    $existingManifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $fromVersion = [string]$existingManifest.skillVersion
  } catch { throw "Cannot read existing project-board manifest: $($_.Exception.Message)" }
}

# Named hashtable splat is required; string-array splat binds as positionals and breaks -Config* switches.
$common = @{
  RepoRoot           = $RepoRoot
  SkillDir           = $SkillDir
  ConfigDefaultsPath = $ConfigDefaultsPath
  ConfigLocalPath    = $ConfigLocalPath
  ManagedUpgrade     = $true
}
if (-not $Apply) {
  $previewArgs = @{
    RepoRoot           = $common.RepoRoot
    SkillDir           = $common.SkillDir
    ConfigDefaultsPath = $common.ConfigDefaultsPath
    ConfigLocalPath    = $common.ConfigLocalPath
    ManagedUpgrade     = $true
    Preview            = $true
  }
  if ($Force) { $previewArgs['Force'] = $true }
  $raw = & $installer @previewArgs
  $code = $LASTEXITCODE
  if ($code -ne 0) { $raw; exit $code }
  $plan = ($raw -join "`n") | ConvertFrom-Json
  $result = [ordered]@{
    mode = 'preview'
    fromVersion = $(if ($fromVersion) {$fromVersion} else {'unknown'})
    targetVersion = $targetVersion
    force = [bool]$Force
    projectProfile = $plan.projectProfile
    files = @($plan.files)
    conflicts = @($plan.conflicts)
    directories = @($plan.directories)
    manifestPath = '.project-board/manifest.json'
    note = 'Preview is read-only. Unmodified managed files can be upgraded automatically; modified or unmanaged files are preserved unless -Force is explicitly supplied.'
  }
  $result | ConvertTo-Json -Depth 8
  exit 0
}

$applyArgs = @{
  RepoRoot           = $common.RepoRoot
  SkillDir           = $common.SkillDir
  ConfigDefaultsPath = $common.ConfigDefaultsPath
  ConfigLocalPath    = $common.ConfigLocalPath
  ManagedUpgrade     = $true
}
if ($Force) { $applyArgs['Force'] = $true }
$raw = & $installer @applyArgs
$code = $LASTEXITCODE
$raw
exit $code
