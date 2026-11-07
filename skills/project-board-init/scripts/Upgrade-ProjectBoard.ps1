# Upgrade existing project-board files. Default mode is a non-mutating plan preview.
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
$installer = Join-Path $PSScriptRoot 'Install-ProjectBoard.ps1'
if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) { throw "Installer not found: $installer" }
if (-not $Apply) {
  if ($Force) {
    & $installer -RepoRoot $RepoRoot -Preview -Force -SkillDir $SkillDir -ConfigDefaultsPath $ConfigDefaultsPath -ConfigLocalPath $ConfigLocalPath
  } else {
    & $installer -RepoRoot $RepoRoot -Preview -SkillDir $SkillDir -ConfigDefaultsPath $ConfigDefaultsPath -ConfigLocalPath $ConfigLocalPath
  }
  exit $LASTEXITCODE
}
if ($Force) {
  & $installer -RepoRoot $RepoRoot -Force -SkillDir $SkillDir -ConfigDefaultsPath $ConfigDefaultsPath -ConfigLocalPath $ConfigLocalPath
} else {
  & $installer -RepoRoot $RepoRoot -SkillDir $SkillDir -ConfigDefaultsPath $ConfigDefaultsPath -ConfigLocalPath $ConfigLocalPath
}
exit $LASTEXITCODE
