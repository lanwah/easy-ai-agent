# Install or upgrade the project board scaffolding. Existing files are preserved unless -Force is explicit.
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [switch]$Force,
  [string]$SkillDir,
  [string]$ConfigDefaultsPath,
  [string]$ConfigLocalPath
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $SkillDir) { $SkillDir = Split-Path -Parent $PSScriptRoot }
if (-not $ConfigDefaultsPath) { $ConfigDefaultsPath = Join-Path $SkillDir 'config.defaults.json' }
if (-not $ConfigLocalPath) { $ConfigLocalPath = Join-Path $SkillDir 'config.local.json' }
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

. (Join-Path $PSScriptRoot 'ProjectBoardConfig.ps1')

function Expand-ProjectBoardTemplate {
  param(
    [string]$Text,
    [hashtable]$Tokens
  )
  foreach ($key in $Tokens.Keys) {
    $Text = $Text.Replace("{{$key}}", [string]$Tokens[$key])
  }
  return $Text
}

function Write-ManagedFile {
  param(
    [string]$Path,
    [string]$Content
  )
  $parent = Split-Path -Parent $Path
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }
  $exists = Test-Path -LiteralPath $Path -PathType Leaf
  if ($exists -and -not $Force) { return 'skipped-existing' }
  $encoding = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($Path, $Content, $encoding)
  if ($exists) { return 'updated' }
  return 'created'
}

$config = Get-ProjectBoardConfig -DefaultsPath $ConfigDefaultsPath -LocalPath $ConfigLocalPath
$dirs = ConvertTo-ProjectBoardMap (Get-ProjectBoardValue $config 'directories' @{})
$board = ConvertTo-ProjectBoardMap (Get-ProjectBoardValue $config 'board' @{})
$init = ConvertTo-ProjectBoardMap (Get-ProjectBoardValue $config 'init' @{})

$plans = [string](Get-ProjectBoardValue $dirs 'plans' 'plans')
$docs = [string](Get-ProjectBoardValue $dirs 'docs' 'docs')
$done = [string](Get-ProjectBoardValue $dirs 'doneFile' 'plans/done.md')
$boardFile = [string](Get-ProjectBoardValue $board 'file' 'project.md')
$ruleFile = [string](Get-ProjectBoardValue $board 'ruleFile' '.cursor/rules/project-board.mdc')
$taskFile = [string](Get-ProjectBoardValue $board 'taskBoardFile' 'Task_Board.md')
$taskGuideFile = [string](Get-ProjectBoardValue $board 'taskGuideFile' 'references/task-management.md')
$extra = Get-ProjectBoardStringList (Get-ProjectBoardValue $dirs 'extra' @())

$paths = @($plans, $docs, $done, $boardFile, $ruleFile, $taskFile, $taskGuideFile) + $extra
foreach ($p in $paths) { Assert-ProjectBoardRelativePath -Path ([string]$p) -Name 'path' }

if ((Get-ProjectBoardValue $init 'force' $false) -eq $true) { $Force = $true }

$tokenDirs = @($plans, $docs) + $extra | Select-Object -Unique
$sink = ($tokenDirs | ForEach-Object { '`' + ($_ -replace '\\', '/') + '/`' }) -join ' / '
$tokens = @{
  SINK_DIRS_INLINE = $sink
  DONE_FILE        = ($done -replace '\\', '/')
  TASK_GUIDE_FILE  = ($taskGuideFile -replace '\\', '/')
  INSTALL_DATE     = (Get-Date -Format 'yyyy-MM-dd')
}

$templateDir = Join-Path $SkillDir 'templates'
$requiredTemplates = @('project-board.mdc', 'project.md', 'Task_Board.md', 'done.md')
foreach ($name in $requiredTemplates) {
  if (-not (Test-Path -LiteralPath (Join-Path $templateDir $name) -PathType Leaf)) {
    throw "Required template missing: $name"
  }
}

$taskGuideSource = Join-Path $SkillDir 'references\task-management.md'
if (-not (Test-Path -LiteralPath $taskGuideSource -PathType Leaf)) {
  throw "Required task guide missing: $taskGuideSource"
}

$results = [ordered]@{
  repoRoot    = $RepoRoot
  force       = [bool]$Force
  directories = @()
  files       = [ordered]@{}
}

foreach ($rel in (@($plans, $docs) + $extra | Select-Object -Unique)) {
  $abs = Join-Path $RepoRoot $rel
  if (-not (Test-Path -LiteralPath $abs -PathType Container)) {
    New-Item -ItemType Directory -Path $abs -Force | Out-Null
    $status = 'created'
  } else {
    $status = 'exists'
  }
  $keep = Join-Path $abs '.gitkeep'
  if (-not (Test-Path -LiteralPath $keep -PathType Leaf)) {
    [System.IO.File]::WriteAllText($keep, '', ([System.Text.UTF8Encoding]::new($false)))
  }
  $results.directories += [ordered]@{ path = $rel; status = $status }
}

$map = [ordered]@{}
$map[$ruleFile] = Expand-ProjectBoardTemplate (
  Get-Content -LiteralPath (Join-Path $templateDir 'project-board.mdc') -Raw -Encoding UTF8
) $tokens
$map[$boardFile] = Expand-ProjectBoardTemplate (
  Get-Content -LiteralPath (Join-Path $templateDir 'project.md') -Raw -Encoding UTF8
) $tokens
$map[$taskFile] = Expand-ProjectBoardTemplate (
  Get-Content -LiteralPath (Join-Path $templateDir 'Task_Board.md') -Raw -Encoding UTF8
) $tokens
$map[$done] = Expand-ProjectBoardTemplate (
  Get-Content -LiteralPath (Join-Path $templateDir 'done.md') -Raw -Encoding UTF8
) $tokens
$map[$taskGuideFile] = Expand-ProjectBoardTemplate (
  Get-Content -LiteralPath $taskGuideSource -Raw -Encoding UTF8
) $tokens

foreach ($rel in $map.Keys) {
  $results.files[$rel] = Write-ManagedFile -Path (Join-Path $RepoRoot $rel) -Content $map[$rel]
}

$results | ConvertTo-Json -Depth 8
