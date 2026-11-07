# Safe project-board initializer. Preview is read-only; existing files require explicit -Force.
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [switch]$Force,
  [switch]$Preview,
  [switch]$ManagedUpgrade,
  [string]$SkillDir,
  [string]$ConfigDefaultsPath,
  [string]$ConfigLocalPath
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not $SkillDir) { $SkillDir = Split-Path -Parent $PSScriptRoot }
if (-not $ConfigDefaultsPath) { $ConfigDefaultsPath = Join-Path $SkillDir 'config.defaults.json' }
if (-not $ConfigLocalPath) { $ConfigLocalPath = Join-Path $SkillDir 'config.local.json' }
if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) { throw "Repository root does not exist: $RepoRoot" }
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
. (Join-Path $PSScriptRoot 'ProjectBoardConfig.ps1')

function Expand-ProjectBoardTemplate {
  param([string]$Text, [hashtable]$Tokens)
  foreach ($key in $Tokens.Keys) { $Text = $Text.Replace("{{$key}}", [string]$Tokens[$key]) }
  return $Text
}
function Merge-ProjectBoardTaskHistory {
  param([string]$ExistingText, [string]$TemplateText)
  if ($ExistingText -match '(?m)^## 状态变更记录\s*$') { return $ExistingText }
  $start = $TemplateText.IndexOf('## 状态变更记录')
  $end = $TemplateText.IndexOf('## 使用约定', $start)
  if ($start -lt 0 -or $end -lt 0) { throw 'Task_Board template is missing the status-history section.' }
  $section = $TemplateText.Substring($start, $end - $start).TrimEnd()
  $usageIndex = $ExistingText.IndexOf('## 使用约定')
  if ($usageIndex -ge 0) {
    return $ExistingText.Substring(0,$usageIndex) + $section + "`r`n`r`n" + $ExistingText.Substring($usageIndex)
  }
  return ($ExistingText.TrimEnd() + "`r`n`r`n" + $section + "`r`n")
}
function Get-CanonicalTargetPath {
  param([string]$RelativePath)
  $candidate = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $RelativePath))
  $rootPrefix = $RepoRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
  if (-not $candidate.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
      -not $candidate.Equals($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Configured path escapes repository root: $RelativePath"
  }
  return $candidate
}

$config = Get-ProjectBoardConfig -DefaultsPath $ConfigDefaultsPath -LocalPath $ConfigLocalPath
$skillVersion = (Get-Content -LiteralPath (Join-Path $SkillDir 'VERSION') -Raw -Encoding UTF8).Trim()
$projectProfile = [string](Get-ProjectBoardValue $config 'projectProfile' 'standard')
if ($projectProfile -notin @('simple','standard','complex')) { throw "Invalid projectProfile: $projectProfile (allowed: simple, standard, complex)" }
$manifestDir = Join-Path $RepoRoot '.project-board'
$manifestPath = Join-Path $manifestDir 'manifest.json'
if (Test-Path -LiteralPath $manifestPath -PathType Container) { throw "Manifest target is an existing directory: $manifestPath" }
$manifest = @{ managedFiles = @{}; skillVersion = $skillVersion }
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
  try {
    $loadedManifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($loadedManifest.managedFiles) {
      foreach ($property in $loadedManifest.managedFiles.PSObject.Properties) { $manifest.managedFiles[$property.Name] = [string]$property.Value }
    }
  } catch { throw "Existing project-board manifest is invalid: $($_.Exception.Message)" }
}
function Get-ProjectBoardSha256 {
  param([string]$Path)
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
$dirs = ConvertTo-ProjectBoardMap (Get-ProjectBoardValue $config 'directories' @{})
$board = ConvertTo-ProjectBoardMap (Get-ProjectBoardValue $config 'board' @{})
$plans = [string](Get-ProjectBoardValue $dirs 'plans' 'plans')
$docs = [string](Get-ProjectBoardValue $dirs 'docs' 'docs')
$done = [string](Get-ProjectBoardValue $dirs 'doneFile' 'plans/done.md')
$boardFile = [string](Get-ProjectBoardValue $board 'file' 'project.md')
$ruleFile = [string](Get-ProjectBoardValue $board 'ruleFile' '.cursor/rules/project-board.mdc')
$taskFile = [string](Get-ProjectBoardValue $board 'taskBoardFile' 'Task_Board.md')
$taskGuideFile = [string](Get-ProjectBoardValue $board 'taskGuideFile' 'references/task-management.md')
$extra = Get-ProjectBoardStringList (Get-ProjectBoardValue $dirs 'extra' @())

$allPaths = @($plans, $docs, $done, $boardFile, $ruleFile, $taskFile, $taskGuideFile) + $extra
$directoryPaths = @($plans,$docs) + $extra
$filePaths = @($done,$boardFile,$ruleFile,$taskFile,$taskGuideFile)
$seenFilePaths = @{}
foreach ($fileRel in $filePaths) {
  $fileKey = ($fileRel -replace '\\','/').TrimEnd('/').ToLowerInvariant()
  if ($seenFilePaths.ContainsKey($fileKey)) { throw "Two managed files use the same configured path: $fileRel" }
  $seenFilePaths[$fileKey] = $true
}
foreach ($fileRel in $filePaths) {
  $fileNorm = ($fileRel -replace '\\','/').TrimEnd('/').ToLowerInvariant()
  foreach ($dirRel in $directoryPaths) {
    $dirNorm = ($dirRel -replace '\\','/').TrimEnd('/').ToLowerInvariant()
    if ($dirNorm -eq $fileNorm -or $dirNorm.StartsWith($fileNorm + '/')) {
      throw "Configured file path conflicts with a directory path: $fileRel <-> $dirRel"
    }
  }
  foreach ($otherFile in $filePaths) {
    if ($otherFile -eq $fileRel) { continue }
    $otherNorm = ($otherFile -replace '\\','/').TrimEnd('/').ToLowerInvariant()
    if ($otherNorm.StartsWith($fileNorm + '/')) { throw "Configured file path is a parent of another file target: $fileRel <-> $otherFile" }
  }
}
foreach ($rel in $allPaths) { Assert-ProjectBoardRelativePath -Path ([string]$rel) -Name 'path' }
$canonical = @{}
foreach ($rel in $allPaths) {
  $target = Get-CanonicalTargetPath ([string]$rel)
  $key = $target.ToLowerInvariant()
  if ($canonical.ContainsKey($key) -and $canonical[$key] -ne [string]$rel) { throw "Configured paths resolve to the same target: $rel and $($canonical[$key])" }
  $canonical[$key] = [string]$rel
  if ((Test-Path -LiteralPath $target -PathType Container) -and ($rel -in @($done,$boardFile,$ruleFile,$taskFile,$taskGuideFile))) { throw "File target conflicts with an existing directory: $rel" }
  if ((Test-Path -LiteralPath $target -PathType Leaf) -and ($rel -in @($plans,$docs) -or $rel -in $extra)) { throw "Directory target conflicts with an existing file: $rel" }
}

$templateDir = Join-Path $SkillDir 'templates'
$requiredTemplates = @('project-board.mdc','project.md','Task_Board.md','done.md')
foreach ($name in $requiredTemplates) { if (-not (Test-Path -LiteralPath (Join-Path $templateDir $name) -PathType Leaf)) { throw "Required template missing: $name" } }
$taskGuideSource = Join-Path $SkillDir 'references\task-management.md'
if (-not (Test-Path -LiteralPath $taskGuideSource -PathType Leaf)) { throw "Required task guide missing: $taskGuideSource" }

$tokenDirs = @($plans,$docs) + $extra | Select-Object -Unique
$sink = ($tokenDirs | ForEach-Object { '`' + ($_ -replace '\\','/') + '/`' }) -join ' / '
$tokens = @{
  SINK_DIRS_INLINE = $sink
  DONE_FILE = ($done -replace '\\','/')
  TASK_GUIDE_FILE = ($taskGuideFile -replace '\\','/')
  INSTALL_DATE = (Get-Date -Format 'yyyy-MM-dd')
  PROJECT_PROFILE = $projectProfile
  SKILL_DIR = ($SkillDir -replace '\\','/')
}
$map = [ordered]@{}
$map[$ruleFile] = Expand-ProjectBoardTemplate (Get-Content -LiteralPath (Join-Path $templateDir 'project-board.mdc') -Raw -Encoding UTF8) $tokens
$map[$boardFile] = Expand-ProjectBoardTemplate (Get-Content -LiteralPath (Join-Path $templateDir 'project.md') -Raw -Encoding UTF8) $tokens
$map[$taskFile] = Expand-ProjectBoardTemplate (Get-Content -LiteralPath (Join-Path $templateDir 'Task_Board.md') -Raw -Encoding UTF8) $tokens
$map[$done] = Expand-ProjectBoardTemplate (Get-Content -LiteralPath (Join-Path $templateDir 'done.md') -Raw -Encoding UTF8) $tokens
$map[$taskGuideFile] = Expand-ProjectBoardTemplate (Get-Content -LiteralPath $taskGuideSource -Raw -Encoding UTF8) $tokens

# Validate file targets and all parent components before any writes.
$plan = @()
foreach ($rel in $map.Keys) {
  $target = Get-CanonicalTargetPath $rel
  $parent = Split-Path -Parent $target
  $cursor = $parent
  while ($cursor -and $cursor.StartsWith($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    if (Test-Path -LiteralPath $cursor -PathType Leaf) { throw "Parent path is an existing file: $cursor" }
    if ($cursor -eq $RepoRoot) { break }
    $cursor = Split-Path -Parent $cursor
  }
  $exists = Test-Path -LiteralPath $target -PathType Leaf
  $action = 'create'
  if ($exists) {
    if ($Force) { $action = 'update' }
    elseif ($ManagedUpgrade -and $rel -eq $taskFile) {
      $existingTaskBoard = Get-Content -LiteralPath $target -Raw -Encoding UTF8
      if ($existingTaskBoard -notmatch '(?m)^## 状态变更记录\s*$') {
        $action = 'migrate-merge'
        $map[$rel] = Merge-ProjectBoardTaskHistory -ExistingText $existingTaskBoard -TemplateText ([string]$map[$rel])
      } elseif ($manifest.managedFiles.ContainsKey($rel) -and
        (Get-ProjectBoardSha256 $target) -eq $manifest.managedFiles[$rel]) { $action = 'update-managed' }
      else { $action = 'skip-existing' }
    }
    elseif ($ManagedUpgrade -and $manifest.managedFiles.ContainsKey($rel) -and
      (Get-ProjectBoardSha256 $target) -eq $manifest.managedFiles[$rel]) { $action = 'update-managed' }
    else { $action = 'skip-existing' }
  }
  if ($exists -and $action -in @('update','update-managed','migrate-merge')) {
    $item = Get-Item -LiteralPath $target -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReadOnly) { throw "Target file is read-only: $rel" }
  }
  $plan += [pscustomobject]@{ relativePath=$rel; fullPath=$target; action=$action; content=$map[$rel] }
}

$directoryPlan = @($plans,$docs,'.project-board') + $extra | Select-Object -Unique
$directoryPlan += (Split-Path -Parent $done), (Split-Path -Parent $ruleFile), (Split-Path -Parent $taskGuideFile)
$directoryPlan = @($directoryPlan | Where-Object { $_ -and $_ -ne '.' } | Select-Object -Unique)
foreach ($rel in $directoryPlan) {
  $target = Get-CanonicalTargetPath $rel
  if (Test-Path -LiteralPath $target -PathType Leaf) { throw "Directory path conflicts with an existing file: $rel" }
}

$report = [ordered]@{
  version = $skillVersion; projectProfile = $projectProfile; repoRoot = $RepoRoot; mode = $(if ($Preview) {'preview'} else {'apply'}); force = [bool]$Force
  directories = @($directoryPlan | ForEach-Object { [ordered]@{ path=$_; action=$(if (Test-Path -LiteralPath (Get-CanonicalTargetPath $_) -PathType Container) {'keep'} else {'create'}) } })
  files = @($plan | ForEach-Object { [ordered]@{ path=$_.relativePath; action=$_.action } })
  conflicts = @($plan | Where-Object { $_.action -eq 'skip-existing' -and $ManagedUpgrade } | ForEach-Object { $_.relativePath })
  manifestPath = '.project-board/manifest.json'
  backups = @()
}
if ($Preview) { $report | ConvertTo-Json -Depth 8; exit 0 }

# No mutation occurs before this point. Back up every file that will be replaced.
$backupRoot = Join-Path $RepoRoot ('.project-board-backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
$backupCount = 0
foreach ($item in $plan) {
  if ($item.action -notin @('update','update-managed','migrate-merge')) { continue }
  $backupPath = Join-Path $backupRoot $item.relativePath
  $backupParent = Split-Path -Parent $backupPath
  if (-not (Test-Path -LiteralPath $backupParent -PathType Container)) { New-Item -ItemType Directory -Path $backupParent -Force | Out-Null }
  Copy-Item -LiteralPath $item.fullPath -Destination $backupPath -Force
  $report.backups += $backupPath
  $backupCount++
}
foreach ($rel in $directoryPlan) {
  $abs = Get-CanonicalTargetPath $rel
  if (-not (Test-Path -LiteralPath $abs -PathType Container)) { New-Item -ItemType Directory -Path $abs -Force | Out-Null }
}
$encoding = [System.Text.UTF8Encoding]::new($false)
foreach ($item in $plan) {
  if ($item.action -eq 'skip-existing') { continue }
  $parent = Split-Path -Parent $item.fullPath
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  [System.IO.File]::WriteAllText($item.fullPath, [string]$item.content, $encoding)
}
# Update managed-file hashes only for files this run actually created or replaced.
foreach ($item in $plan) {
  if ($item.action -in @('create','update','update-managed','migrate-merge')) {
    $manifest.managedFiles[$item.relativePath] = Get-ProjectBoardSha256 $item.fullPath
  }
}
$manifestOutput = [ordered]@{
  schemaVersion = 1
  skill = 'project-board-init'
  skillVersion = $skillVersion
  projectProfile = $projectProfile
  updatedAt = (Get-Date).ToString('o')
  managedFiles = [ordered]@{}
  pendingConflicts = @($plan | Where-Object { $_.action -eq 'skip-existing' -and $ManagedUpgrade } | ForEach-Object { $_.relativePath })
}
foreach ($key in ($manifest.managedFiles.Keys | Sort-Object)) { $manifestOutput.managedFiles[$key] = $manifest.managedFiles[$key] }
$manifestJson = $manifestOutput | ConvertTo-Json -Depth 8
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
  $manifestBackup = Join-Path $backupRoot '.project-board/manifest.json'
  if (-not (Test-Path -LiteralPath (Split-Path -Parent $manifestBackup) -PathType Container)) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $manifestBackup) -Force | Out-Null
  }
  Copy-Item -LiteralPath $manifestPath -Destination $manifestBackup -Force
  $report.backups += $manifestBackup
  $backupCount++
}
[System.IO.File]::WriteAllText($manifestPath, $manifestJson, $encoding)
$report.backupCount = $backupCount
$report.manifestUpdated = $true
$report | ConvertTo-Json -Depth 8
