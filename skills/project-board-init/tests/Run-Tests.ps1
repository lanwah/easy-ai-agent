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
  Assert-True (Test-Path (Join-Path $repo 'Task_Board.md')) 'Initial install creates Task_Board.md'
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
  $forceConfig = Join-Path $testRoot 'force.json'
  [System.IO.File]::WriteAllText($forceConfig,'{"init":{"force":true}}')
  [System.IO.File]::WriteAllText($board,'PRESERVE ME')
  & $installer -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath $forceConfig | Out-Null
  Assert-True ((Get-Content $board -Raw) -eq 'PRESERVE ME') 'Config cannot authorize Force overwrite'
  $validator = Join-Path $SkillDir 'scripts/Test-ProjectBoard.ps1'
  $taskPath = Join-Path $repo 'Task_Board.md'
  $badRow = '| TASK-ABC | Bad task | 需求 | core | P1 | TODO | Agent | — | file | criteria | — | — | 2026-11-07 | 普通 |'
  [System.IO.File]::WriteAllText($taskPath, "# 任务台账`r`n`r`n| Task ID | 任务名称 | 阶段 | 模块 | 优先级 | 状态 | 执行者 | 前置任务 | 交付物 | 验收标准 | Commit | Tag | 更新时间 | 任务类型 |`r`n|---|---|---|---|---|---|---|---|---|---|---|---|---|---|`r`n$badRow`r`n", ([System.Text.UTF8Encoding]::new($false)))
  $validationOutput = & $validator -RepoRoot $repo -SkillDir $SkillDir -ConfigDefaultsPath $configPath -ConfigLocalPath (Join-Path $testRoot 'missing.json') -Detailed 2>&1
  $validationExit = $LASTEXITCODE
  $validationJson = ($validationOutput -join "`n") | ConvertFrom-Json
  Assert-True ($validationExit -eq 2 -and $validationJson.status -eq 'ERROR') 'Validator rejects malformed task IDs'
} finally {
  Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "Tests passed: $passed; failed: $failed"
if ($failed -gt 0) { exit 1 }
exit 0
