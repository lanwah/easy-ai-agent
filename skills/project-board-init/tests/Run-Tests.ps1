# Lightweight integration tests; no Pester dependency. Run under Windows PowerShell 5.1 and PowerShell 7.
[CmdletBinding()]
param([string]$SkillDir)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SkillDir)) {
  $testsDir = $PSScriptRoot
  if ([string]::IsNullOrWhiteSpace($testsDir) -and $MyInvocation.MyCommand.Path) {
    $testsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  }
  if ([string]::IsNullOrWhiteSpace($testsDir)) {
    throw 'Unable to resolve SkillDir; pass -SkillDir explicitly.'
  }
  $SkillDir = Split-Path -Parent $testsDir
}
$installer = Join-Path $SkillDir 'scripts/Install-ProjectBoard.ps1'
$configPath = Join-Path $SkillDir 'config.defaults.json'
$localPath = Join-Path $SkillDir 'config.local.json'
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('project-board-init-tests-' + [guid]::NewGuid().ToString('N'))
$passed = 0; $failed = 0
function Assert-True { param([bool]$Condition,[string]$Name) if ($Condition) { Write-Host "PASS $Name"; $script:passed++ } else { Write-Host "FAIL $Name"; $script:failed++ } }
try {
  New-Item -ItemType Directory -Path $testRoot | Out-Null
  $repo = Join-Path $testRoot 'repo'; New-Item -ItemType Directory -Path $repo | Out-Null
  $preview = & $installer -RepoRoot $repo -Preview -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') | ConvertFrom-Json
  Assert-True ($preview.mode -eq 'preview' -and -not (Test-Path (Join-Path $repo 'Task_Board.md'))) 'Preview does not write files'
  & $installer -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') | Out-Null
  Assert-True ((Test-Path (Join-Path $repo 'Task_Board.md')) -and (Test-Path (Join-Path $repo '.project-board/manifest.json'))) 'Initial install creates Task_Board.md and managed-file manifest'
  $board = Join-Path $repo 'Task_Board.md'; [System.IO.File]::WriteAllText($board,'USER DATA')
  & $installer -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') | Out-Null
  Assert-True ((Get-Content $board -Raw) -eq 'USER DATA') 'Default install preserves existing file'
  & $installer -RepoRoot $repo -Force -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') | Out-Null
  $backups = @(Get-ChildItem (Join-Path $repo '.project-board-backups') -Recurse -File -ErrorAction SilentlyContinue)
  Assert-True ($backups.Count -ge 1 -and (Get-Content $board -Raw) -ne 'USER DATA') 'Force backs up before replacing'
  $badConfig = Join-Path $testRoot 'bad.json'
  [System.IO.File]::WriteAllText($badConfig,'{"directories":{"extra":["../escape"]}}')
  $rejected = $false
  try { & $installer -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath $badConfig | Out-Null } catch { $rejected = $true }
  Assert-True $rejected 'Path traversal configuration is rejected'

  $validator = Join-Path $SkillDir 'scripts/Test-ProjectBoard.ps1'

  # Reparse points (directory symlinks/junctions) must not redirect configured paths outside the repository.
  $outsidePath = Join-Path $testRoot 'outside-target'
  $junctionPath = Join-Path $repo 'linked'
  New-Item -ItemType Directory -Path $outsidePath | Out-Null
  $junctionCreated = $false
  if ($env:OS -eq 'Windows_NT') {
    & $env:ComSpec /c "mklink /J `"$junctionPath`" `"$outsidePath`"" 2>&1 | Out-Null
    $junctionCreated = Test-Path -LiteralPath $junctionPath -PathType Container
  }
  if ($junctionCreated) {
    $rootJunctionPath = Join-Path $testRoot 'repo-root-link'
    & $env:ComSpec /c "mklink /J `"$rootJunctionPath`" `"$repo`"" 2>&1 | Out-Null
    $rootJunctionRejected = $false
    if (Test-Path -LiteralPath $rootJunctionPath -PathType Container) {
      try { & $installer -RepoRoot $rootJunctionPath -Preview -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') | Out-Null } catch { $rootJunctionRejected = $true }
    }
    Assert-True $rootJunctionRejected 'Installer rejects a repository root that is a directory junction'

    $junctionConfig = Join-Path $testRoot 'junction.json'
    [System.IO.File]::WriteAllText($junctionConfig,'{"directories":{"extra":["linked/child"]}}')
    $installerRejectedJunction = $false
    try { & $installer -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath $junctionConfig | Out-Null } catch { $installerRejectedJunction = $true }
    Assert-True $installerRejectedJunction 'Installer rejects configured paths that cross a directory junction'
    $validatorRejectedJunction = $false
    try { & $validator -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath $junctionConfig -Detailed | Out-Null } catch { $validatorRejectedJunction = $true }
    Assert-True $validatorRejectedJunction 'Validator rejects configured paths that cross a directory junction'
  } else {
    Write-Host 'SKIP Junction tests: unable to create a Windows directory junction in this environment'
  }
  $forceConfig = Join-Path $testRoot 'force.json'
  [System.IO.File]::WriteAllText($forceConfig,'{"init":{"force":true}}')
  [System.IO.File]::WriteAllText($board,'PRESERVE ME')
  & $installer -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath $forceConfig | Out-Null
  Assert-True ((Get-Content $board -Raw) -eq 'PRESERVE ME') 'Config cannot authorize Force overwrite'
  $taskPath = Join-Path $repo 'Task_Board.md'
  $badRow = '| TASK-ABC | Bad task | 需求 | core | P1 | TODO | Agent | — | file | criteria | — | — | 2026-11-07 | 普通 |'
  [System.IO.File]::WriteAllText($taskPath, "# 任务台账`r`n`r`n## 任务列表`r`n`r`n| Task ID | 任务名称 | 阶段 | 模块 | 优先级 | 状态 | 执行者 | 前置任务 | 交付物 | 验收标准 | Commit | Tag | 更新时间 | 任务类型 |`r`n|---|---|---|---|---|---|---|---|---|---|---|---|---|---|`r`n$badRow`r`n", ([System.Text.UTF8Encoding]::new($false)))
  $validationOutput = & $validator -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') -Detailed 2>&1
  $validationExit = $LASTEXITCODE
  $validationJson = ($validationOutput -join "`n") | ConvertFrom-Json
  Assert-True ($validationExit -eq 2 -and $validationJson.status -eq 'ERROR') 'Validator rejects malformed task IDs'

  # A valid append-only history must match the current task status.
  $validRow = '| TASK-001 | Sample | 需求 | core | P1 | IN_PROGRESS | Agent | — | file | criteria | — | — | 2026-11-07 | 普通 |'
  $validHistory = @'
## 状态变更记录

| Task ID | 变更类型 | 原状态 | 新状态 | 变更时间 | 原因/授权依据 |
|---|---|---|---|---|---|
| TASK-001 | 创建 | — | TODO | 2026-11-07T10:00:00 | 用户创建 |
| TASK-001 | 状态变更 | TODO | IN_PROGRESS | 2026-11-07T10:05:00 | 开始执行 |
'@
  $validBoard = "# 任务台账`r`n`r`n## 任务列表`r`n`r`n| Task ID | 任务名称 | 阶段 | 模块 | 优先级 | 状态 | 执行者 | 前置任务 | 交付物 | 验收标准 | Commit | Tag | 更新时间 | 任务类型 |`r`n|---|---|---|---|---|---|---|---|---|---|---|---|---|---|`r`n$validRow`r`n`r`n$validHistory`r`n"
  [System.IO.File]::WriteAllText($taskPath,$validBoard,([System.Text.UTF8Encoding]::new($false)))
  $validOutput = & $validator -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') -Detailed 2>&1
  $validExit = $LASTEXITCODE
  $validJson = ($validOutput -join "`n") | ConvertFrom-Json
  Assert-True ($validExit -eq 1 -and $validJson.status -eq 'WARNING' -and $validJson.errors.Count -eq 0) 'Validator accepts legal continuous status history and warns about user edits'

  $missingCreateHistory = $validHistory.Replace("| TASK-001 | 创建 | — | TODO | 2026-11-07T10:00:00 | 用户创建 |",'')
  $missingCreateBoard = $validBoard.Replace($validHistory,$missingCreateHistory)
  [System.IO.File]::WriteAllText($taskPath,$missingCreateBoard,([System.Text.UTF8Encoding]::new($false)))
  $missingCreateOutput = & $validator -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') -Detailed 2>&1
  $missingCreateExit = $LASTEXITCODE
  $missingCreateJson = ($missingCreateOutput -join "`n") | ConvertFrom-Json
  Assert-True ($missingCreateExit -eq 2 -and ($missingCreateJson.errors -join ';') -match 'begin with a creation event') 'Validator rejects history that starts with a status change'

  $duplicateCreateHistory = $validHistory.Replace("| TASK-001 | 状态变更 | TODO", "| TASK-001 | 创建 | — | TODO | 2026-11-07T10:02:00 | 重复创建 |`r`n| TASK-001 | 状态变更 | TODO")
  $duplicateCreateBoard = $validBoard.Replace($validHistory,$duplicateCreateHistory)
  [System.IO.File]::WriteAllText($taskPath,$duplicateCreateBoard,([System.Text.UTF8Encoding]::new($false)))
  $duplicateCreateOutput = & $validator -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') -Detailed 2>&1
  $duplicateCreateExit = $LASTEXITCODE
  $duplicateCreateJson = ($duplicateCreateOutput -join "`n") | ConvertFrom-Json
  Assert-True ($duplicateCreateExit -eq 2 -and ($duplicateCreateJson.errors -join ';') -match 'invalid task creation history event') 'Validator rejects duplicate creation events'

  $badTimestampHistory = $validHistory.Replace('2026-11-07T10:00:00','not-a-timestamp')
  $badTimestampBoard = $validBoard.Replace($validHistory,$badTimestampHistory)
  [System.IO.File]::WriteAllText($taskPath,$badTimestampBoard,([System.Text.UTF8Encoding]::new($false)))
  $badTimestampOutput = & $validator -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') -Detailed 2>&1
  $badTimestampExit = $LASTEXITCODE
  $badTimestampJson = ($badTimestampOutput -join "`n") | ConvertFrom-Json
  Assert-True ($badTimestampExit -eq 2 -and ($badTimestampJson.errors -join ';') -match 'invalid status history timestamp') 'Validator rejects malformed ISO 8601 timestamps'

  $outOfOrderHistory = $validHistory.Replace('2026-11-07T10:05:00','2026-11-07T09:59:00')
  $outOfOrderBoard = $validBoard.Replace($validHistory,$outOfOrderHistory)
  [System.IO.File]::WriteAllText($taskPath,$outOfOrderBoard,([System.Text.UTF8Encoding]::new($false)))
  $outOfOrderOutput = & $validator -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') -Detailed 2>&1
  $outOfOrderExit = $LASTEXITCODE
  $outOfOrderJson = ($outOfOrderOutput -join "`n") | ConvertFrom-Json
  Assert-True ($outOfOrderExit -eq 2 -and ($outOfOrderJson.errors -join ';') -match 'timestamps are out of order') 'Validator rejects timestamps that move backwards'

  $invalidHistory = $validHistory.Replace('TODO | IN_PROGRESS','TODO | DONE')
  $invalidRow = $validRow.Replace('IN_PROGRESS','DONE')
  $invalidBoard = $validBoard.Replace($validRow,$invalidRow).Replace($validHistory,$invalidHistory)
  [System.IO.File]::WriteAllText($taskPath,$invalidBoard,([System.Text.UTF8Encoding]::new($false)))
  $invalidOutput = & $validator -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') -Detailed 2>&1
  $invalidExit = $LASTEXITCODE
  $invalidJson = ($invalidOutput -join "`n") | ConvertFrom-Json
  Assert-True ($invalidExit -eq 2 -and $invalidJson.status -eq 'ERROR') 'Validator rejects illegal status transition'

  $reopenHistory = ($validHistory.TrimEnd() + "`r`n" +
    "| TASK-001 | 状态变更 | IN_PROGRESS | REVIEW | 2026-11-07T10:10:00 | 提交验收 |`r`n" +
    "| TASK-001 | 状态变更 | REVIEW | DONE | 2026-11-07T10:15:00 | 验收通过 |`r`n" +
    "| TASK-001 | 状态变更 | DONE | IN_PROGRESS | 2026-11-07T10:20:00 | 重新开始 |`r`n")
  $reopenBoard = $validBoard.Replace($validHistory.TrimEnd(), $reopenHistory.TrimEnd()) + "`r`n"
  [System.IO.File]::WriteAllText($taskPath,$reopenBoard,([System.Text.UTF8Encoding]::new($false)))
  $reopenOutput = & $validator -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') -Detailed 2>&1
  $reopenExit = $LASTEXITCODE
  $reopenJson = ($reopenOutput -join "`n") | ConvertFrom-Json
  Assert-True ($reopenExit -eq 2 -and ($reopenJson.errors -join ';') -match '用户授权') 'Validator requires explicit user authorization to reopen DONE tasks'

  $upgrade = Join-Path $SkillDir 'scripts/Upgrade-ProjectBoard.ps1'
  $upgradePreview = & $upgrade -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') | ConvertFrom-Json
  Assert-True ($upgradePreview.mode -eq 'preview' -and $upgradePreview.targetVersion -eq (Get-Content (Join-Path $SkillDir 'VERSION') -Raw).Trim()) 'Upgrade preview reports target version'
  Assert-True ($upgradePreview.conflicts -contains 'Task_Board.md' -and @($upgradePreview.files | Where-Object { $_.path -eq 'project.md' -and $_.action -eq 'update-managed' }).Count -eq 1) 'Upgrade preview separates modified files from unchanged managed files'

  $legacyRepo = Join-Path $testRoot 'legacy-repo'
  New-Item -ItemType Directory -Path $legacyRepo | Out-Null
  $legacyBoard = @'
# 任务台账

## 任务列表

| Task ID | 任务名称 | 阶段 | 模块 | 优先级 | 状态 | 执行者 | 前置任务 | 交付物 | 验收标准 | Commit | Tag | 更新时间 | 任务类型 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| TASK-007 | Legacy task | 需求 | core | P1 | TODO | Agent | — | file | criteria | — | — | 2026-11-07 | 普通 |

## 使用约定

- 保留用户自定义说明
'@
  [System.IO.File]::WriteAllText((Join-Path $legacyRepo 'Task_Board.md'),$legacyBoard,([System.Text.UTF8Encoding]::new($false)))
  $legacyPreview = & $upgrade -RepoRoot $legacyRepo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') | ConvertFrom-Json
  Assert-True (@($legacyPreview.files | Where-Object { $_.path -eq 'Task_Board.md' -and $_.action -eq 'migrate-merge' }).Count -eq 1) 'Upgrade preview identifies additive Task_Board history migration'
  & $upgrade -RepoRoot $legacyRepo -Apply -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') | Out-Null
  $migratedBoard = Get-Content (Join-Path $legacyRepo 'Task_Board.md') -Raw -Encoding UTF8
  $legacyBackup = @(Get-ChildItem (Join-Path $legacyRepo '.project-board-backups') -Recurse -File -ErrorAction SilentlyContinue)
  Assert-True ($migratedBoard.Contains('TASK-007') -and $migratedBoard.Contains('## 状态变更记录') -and $migratedBoard.Contains('保留用户自定义说明') -and $legacyBackup.Count -ge 1) 'Upgrade merges history section without losing existing tasks and backs up original'
} finally {
  Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "Tests passed: $passed; failed: $failed"
if ($failed -gt 0) { exit 1 }
exit 0
