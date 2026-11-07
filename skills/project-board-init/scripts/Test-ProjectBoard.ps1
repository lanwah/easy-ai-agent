# Read-only project board consistency validator. Never writes to the target repository.
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [switch]$Detailed,
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

$config = Get-ProjectBoardConfig -DefaultsPath $ConfigDefaultsPath -LocalPath $ConfigLocalPath
$dirs = ConvertTo-ProjectBoardMap (Get-ProjectBoardValue $config 'directories' @{})
$board = ConvertTo-ProjectBoardMap (Get-ProjectBoardValue $config 'board' @{})
$taskMgmt = ConvertTo-ProjectBoardMap (Get-ProjectBoardValue $config 'taskManagement' @{})
$validation = ConvertTo-ProjectBoardMap (Get-ProjectBoardValue $config 'validation' @{})

$plans = [string](Get-ProjectBoardValue $dirs 'plans' 'plans')
$docs = [string](Get-ProjectBoardValue $dirs 'docs' 'docs')
$done = [string](Get-ProjectBoardValue $dirs 'doneFile' 'plans/done.md')
$boardFile = [string](Get-ProjectBoardValue $board 'file' 'project.md')
$ruleFile = [string](Get-ProjectBoardValue $board 'ruleFile' '.cursor/rules/project-board.mdc')
$taskFile = [string](Get-ProjectBoardValue $board 'taskBoardFile' 'Task_Board.md')
$taskGuideFile = [string](Get-ProjectBoardValue $board 'taskGuideFile' 'references/task-management.md')
$extra = Get-ProjectBoardStringList (Get-ProjectBoardValue $dirs 'extra' @())
$configuredPaths = @($plans,$docs,$done,$boardFile,$ruleFile,$taskFile,$taskGuideFile) + $extra
foreach ($rel in $configuredPaths) { Assert-ProjectBoardRelativePath -Path ([string]$rel) -Name 'path' }
foreach ($rel in $configuredPaths) {
  $full = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot ([string]$rel)))
  $prefix = $RepoRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
  if (-not $full.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Configured path escapes repository root: $rel" }
}

$taskEnabled = (Get-ProjectBoardValue $taskMgmt 'enabled' $true) -eq $true
$idPrefix = [string](Get-ProjectBoardValue $taskMgmt 'idPrefix' 'TASK')
$requireAcceptance = (Get-ProjectBoardValue $taskMgmt 'requireAcceptanceCriteria' $true) -eq $true
$requireCommit = (Get-ProjectBoardValue $taskMgmt 'requireCommitForCodeTasks' $true) -eq $true
$requireTag = (Get-ProjectBoardValue $taskMgmt 'requireTagForMilestones' $true) -eq $true
$checkGit = (Get-ProjectBoardValue $validation 'checkGit' $true) -eq $true
$checkTaskRefs = (Get-ProjectBoardValue $validation 'checkTaskReferences' $true) -eq $true
$readOnly = (Get-ProjectBoardValue $validation 'readOnly' $true) -eq $true

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$infos = New-Object System.Collections.Generic.List[string]
$checks = New-Object System.Collections.Generic.List[string]

if (-not $readOnly) {
  $warnings.Add('validation.readOnly is not true; validator still runs read-only and never writes')
}

function Add-Check {
  param([string]$Message)
  $script:checks.Add($Message)
}

function Add-Error {
  param([string]$Message)
  $script:errors.Add($Message)
}

function Add-Warning {
  param([string]$Message)
  $script:warnings.Add($Message)
}
function Add-Info {
  param([string]$Message)
  $script:infos.Add($Message)
}

function Invoke-BoardGit {
  param([Parameter(Mandatory = $true)][string[]]$GitArgs)
  # Under $ErrorActionPreference=Stop, git stderr (e.g. non-repo) becomes NativeCommandError.
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    & git @GitArgs 2>$null | Out-Null
    return $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $prev
  }
}

function Test-BoardFile {
  param([string]$Rel)
  if (Test-Path -LiteralPath (Join-Path $RepoRoot $Rel) -PathType Leaf) {
    Add-Check "file: $Rel"
  } else {
    Add-Error "missing file: $Rel"
  }
}

function Test-BoardDirectory {
  param([string]$Rel)
  if (Test-Path -LiteralPath (Join-Path $RepoRoot $Rel) -PathType Container) {
    Add-Check "directory: $Rel"
  } else {
    Add-Error "missing directory: $Rel"
  }
}

function Get-MarkdownTableCells {
  param([string]$Line)
  return @($Line.Trim('|').Split('|') | ForEach-Object { $_.Trim() })
}

Test-BoardFile $boardFile
Test-BoardFile $ruleFile
Test-BoardFile $done
Test-BoardDirectory $plans
Test-BoardDirectory $docs
foreach ($e in $extra) { Test-BoardDirectory ([string]$e) }

if ($taskEnabled) {
  Test-BoardFile $taskFile
  Test-BoardFile $taskGuideFile
}

$boardPath = Join-Path $RepoRoot $boardFile
$taskPath = Join-Path $RepoRoot $taskFile
$rulePath = Join-Path $RepoRoot $ruleFile
$donePath = Join-Path $RepoRoot $done
$taskGuidePath = Join-Path $RepoRoot $taskGuideFile

if (Test-Path -LiteralPath $boardPath -PathType Leaf) {
  $txt = Get-Content -LiteralPath $boardPath -Raw -Encoding UTF8
  if ($txt -notmatch '(?m)^# 项目看板\s*$') {
    Add-Error 'project board missing expected H1'
  }
  $expected = @('项目目标', '当前状态', '关键决策', '待办', '风险', '下一步')
  $heads = @(
    [regex]::Matches($txt, '(?m)^## (.+)$') | ForEach-Object { $_.Groups[1].Value.Trim() }
  )
  if (($heads -join '|') -ne ($expected -join '|')) {
    Add-Error 'project board H2 headings/order invalid'
  }
  if ($txt -notmatch [regex]::Escape(($done -replace '\\', '/'))) {
    Add-Error 'project board missing done archive link'
  }
  if ($taskEnabled -and ($txt -notmatch [regex]::Escape($taskFile))) {
    Add-Warning 'project board does not link Task_Board.md'
  }
}

if (Test-Path -LiteralPath $rulePath -PathType Leaf) {
  $rule = Get-Content -LiteralPath $rulePath -Raw -Encoding UTF8
  if ($rule -notmatch '(?m)^alwaysApply:\s*true\s*$') {
    Add-Error 'rule alwaysApply must be true'
  }
  if ($rule -match '\{\{[A-Z_]+\}\}') {
    Add-Error 'rule has unresolved template placeholders'
  }
}

$tasks = @{}
$deps = @{}
$doneArchiveText = $null
if (Test-Path -LiteralPath $donePath -PathType Leaf) {
  $doneArchiveText = Get-Content -LiteralPath $donePath -Raw -Encoding UTF8
}

if ($taskEnabled -and (Test-Path -LiteralPath $taskPath -PathType Leaf)) {
  $escapedPrefix = [regex]::Escape($idPrefix)
  $taskIdPattern = "^\|\s*($escapedPrefix-[0-9]+)\s*\|(.+)$"
  $validStatuses = @('TODO', 'IN_PROGRESS', 'BLOCKED', 'REVIEW', 'DONE', 'DEFERRED', 'CANCELLED')
  $lines = Get-Content -LiteralPath $taskPath -Encoding UTF8

  foreach ($line in $lines) {
    if ($line -match '^\|\s*Task ID') { continue }
    if ($line -notmatch '^\|') { continue }
    $cells = Get-MarkdownTableCells $line
    if ($cells.Count -eq 0 -or $cells[0] -match '^[-: ]+$') { continue }
    $taskMatch = [regex]::Match($line, $taskIdPattern)
    if (-not $taskMatch.Success) {
      if ($cells[0] -match ('^' + [regex]::Escape($idPrefix))) { Add-Error "malformed task ID in row: $($cells[0])" }
      elseif ($cells[0] -notmatch '^Task ID$') { Add-Warning "unrecognized task table row: $($cells[0])" }
      continue
    }

    $id = $taskMatch.Groups[1].Value
    if ($tasks.ContainsKey($id)) {
      Add-Error "duplicate task ID: $id"
      continue
    }
    $tasks[$id] = $cells

    if ($cells.Count -ne 14) {
      Add-Error "task row must have exactly 14 columns (found $($cells.Count)): $id"
      continue
    }

    $status = $cells[5]
    if ($status -notin $validStatuses) {
      Add-Error "invalid status for ${id}: $status"
    }

    if ($requireAcceptance -and ([string]::IsNullOrWhiteSpace($cells[9]) -or $cells[9] -eq '—')) {
      Add-Warning "acceptance criteria missing: $id"
    }
    $validTypes = @('普通','代码','里程碑','代码,里程碑','代码，里程碑')
    if ($cells[13] -notin $validTypes) { Add-Error "invalid task type for ${id}: $($cells[13])" }

    $deps[$id] = @()
    if ($cells[7] -and $cells[7] -ne '—') {
      $deps[$id] = @($cells[7] -split ',\s*')
    }

    if ($status -eq 'DONE') {
      $commit = $cells[10]
      $tag = $cells[11]
      $type = $cells[13]
      if ($requireCommit -and ($type -match '代码') -and ($commit -eq '—' -or [string]::IsNullOrWhiteSpace($commit))) {
        Add-Warning "DONE code task has no Commit reference: $id"
      }
      if ($requireTag -and ($type -match '里程碑') -and ($tag -eq '—' -or [string]::IsNullOrWhiteSpace($tag))) {
        Add-Warning "DONE milestone task has no Tag reference: $id"
      }
      if ($null -eq $doneArchiveText -or $doneArchiveText -notmatch [regex]::Escape($id)) {
        Add-Warning "DONE task missing from archive: $id"
      }
    }
  }

  if ($checkTaskRefs) {
    foreach ($id in $deps.Keys) {
      foreach ($dep in $deps[$id]) {
        if (-not $tasks.ContainsKey($dep)) {
          Add-Error "unknown dependency $dep referenced by $id"
        }
        if ($dep -eq $id) {
          Add-Error "self dependency: $id"
        }
      }
    }

    foreach ($id in $deps.Keys) {
      $currentStatus = $tasks[$id][5]
      if ($currentStatus -notin @('IN_PROGRESS', 'REVIEW', 'DONE')) { continue }
      foreach ($dep in $deps[$id]) {
        if ($tasks.ContainsKey($dep) -and $tasks[$dep][5] -ne 'DONE') {
          Add-Error "prerequisite $dep is not DONE while $id is $currentStatus"
        }
      }
    }

    $visiting = @{}
    $visited = @{}
    function Visit-TaskDependency {
      param([string]$Id)
      if ($visiting.ContainsKey($Id)) {
        Add-Error "dependency cycle includes $Id"
        return
      }
      if ($visited.ContainsKey($Id)) { return }
      $visiting[$Id] = $true
      foreach ($d in $deps[$Id]) {
        if ($tasks.ContainsKey($d)) {
          Visit-TaskDependency -Id $d
        }
      }
      $visiting.Remove($Id)
      $visited[$Id] = $true
    }
    foreach ($id in $tasks.Keys) {
      Visit-TaskDependency -Id $id
    }
  }

  Add-Check "tasks: $($tasks.Count) parsed"
}

if ($checkGit) {
  $git = Get-Command git -ErrorAction SilentlyContinue
  if ($null -eq $git) {
    Add-Info 'Git executable unavailable; Commit/Tag checks skipped'
  } else {
    $insideWorkTree = (Invoke-BoardGit -GitArgs @('-C', $RepoRoot, 'rev-parse', '--is-inside-work-tree')) -eq 0
    if (-not $insideWorkTree) { Add-Info 'target is not a Git working tree; Commit/Tag checks skipped' }
    if ($insideWorkTree) {
    foreach ($id in $tasks.Keys) {
      $cells = $tasks[$id]
      if ($cells.Count -lt 14) { continue }
      $commitText = $cells[10]
      $tagText = $cells[11]
      if ($commitText -and $commitText -ne '—') {
        foreach ($sha in ($commitText -split ',\s*')) {
          if ($sha -notmatch '^(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})$') {
            Add-Warning "Commit reference is not a full SHA for ${id}: $sha"
            continue
          }
          if ((Invoke-BoardGit -GitArgs @('-C', $RepoRoot, 'cat-file', '-e', "$sha^{commit}")) -ne 0) {
            Add-Warning "Commit cannot be verified for ${id}: $sha"
          }
        }
      }
      if ($tagText -and $tagText -ne '—') {
        foreach ($tag in ($tagText -split ',\s*')) {
          if ((Invoke-BoardGit -GitArgs @('-C', $RepoRoot, 'rev-parse', '-q', '--verify', "refs/tags/$tag")) -ne 0) {
            Add-Warning "Tag cannot be verified for ${id}: $tag"
          }
        }
      }
    }
    Add-Check 'Git reference checks completed'
    }
  }
}

$status = if ($errors.Count -gt 0) {
  'ERROR'
} elseif ($warnings.Count -gt 0) {
  'WARNING'
} elseif ($infos.Count -gt 0) {
  'INFO'
} else {
  'PASS'
}

$result = [ordered]@{
  ok        = ($errors.Count -eq 0)
  status    = $status
  checks    = @($checks)
  errors    = @($errors)
  warnings  = @($warnings)
  infos     = @($infos)
  readOnly  = $true
}

if ($Detailed -or $errors.Count -gt 0 -or $warnings.Count -gt 0) {
  $result | ConvertTo-Json -Depth 8
} else {
  $result | ConvertTo-Json -Depth 5
}

if ($errors.Count -gt 0) { exit 2 }
if ($warnings.Count -gt 0) { exit 1 }
if ($infos.Count -gt 0) { exit 0 }
exit 0
