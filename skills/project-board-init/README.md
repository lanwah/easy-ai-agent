# project-board-init

为任意仓库安装统一的项目看板和任务台账。当前版本：**V1.2.0**。

默认安装内容：

- `.cursor/rules/project-board.mdc`（`alwaysApply`）
- 根目录 `project.md`（六节项目总览）
- 根目录 `Task_Board.md`（所有项目默认创建，唯一权威任务台账）
- `references/task-management.md`（任务管理规范，安装时写入目标仓库）
- `plans/done.md`（完成任务归档）及配置中的目录（默认 `plans/`、`docs/`）

## 配置

配置文件由本技能自带脚本读取，无需依赖其他技能：

1. `config.defaults.json` 为可分发默认配置。
2. 复制 example 生成本机覆盖配置：

```powershell
# 进入技能实际安装目录后执行
Copy-Item config.local.json.example config.local.json
# 编辑 directories.extra，例如 ["design"]
```

3. 合并优先级：`config.local.json` 覆盖 `config.defaults.json`（对象递归合并，数组整段替换）。
4. `config.local.json` 仅供本机使用，不得提交或放入分发包。
5. 配置路径必须是仓库根目录内的相对路径；不允许绝对路径、`.`、`..` 路径穿越或非法 Windows 路径字符。
6. 是否覆盖文件只由本次命令行显式 `-Force` 决定；配置文件不能授权覆盖。

## 安装到某仓库

先预览，不写入任何文件：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\project-board-init\scripts\Install-ProjectBoard.ps1" `
  -RepoRoot "D:\path\to\your-repo" -Preview
```

确认计划后执行普通初始化（已有文件会跳过）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\project-board-init\scripts\Install-ProjectBoard.ps1" `
  -RepoRoot "D:\path\to\your-repo"
```

明确审核预览结果并授权覆盖后，才使用 `-Force`：

```powershell
# 被替换的已有文件会先备份到目标仓库 .project-board-backups/<timestamp>/
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\project-board-init\scripts\Install-ProjectBoard.ps1" `
  -RepoRoot "D:\path\to\your-repo" -Force
```

技能实际安装目录可能是 `$HOME\.agents\skills\project-board-init` 或 `$HOME\.cursor\skills\project-board-init`；请将命令中的路径替换为实际目录。也可以从技能目录调用脚本，避免硬编码路径。

或在 Cursor 对话中点名：`按 project-board-init，给当前仓库安装项目看板`。Agent 应先运行 `-Preview` 并展示计划；只有用户明确授权覆盖时才使用 `-Force`。

## 升级已有项目

使用 `scripts/Upgrade-ProjectBoard.ps1`。默认仅预览迁移计划；执行时需显式 `-Apply`。如计划会替换已有文件，还必须显式 `-Force`。替换前自动备份到 `.project-board-backups/<timestamp>/`。

```powershell
# 预览
powershell -NoProfile -ExecutionPolicy Bypass -File "<SKILL_DIR>\scripts\Upgrade-ProjectBoard.ps1" -RepoRoot "D:\path\to\your-repo"
# 执行新增文件；已有文件默认保留
powershell -NoProfile -ExecutionPolicy Bypass -File "<SKILL_DIR>\scripts\Upgrade-ProjectBoard.ps1" -RepoRoot "D:\path\to\your-repo" -Apply
# 明确授权覆盖已存在文件
powershell -NoProfile -ExecutionPolicy Bypass -File "<SKILL_DIR>\scripts\Upgrade-ProjectBoard.ps1" -RepoRoot "D:\path\to\your-repo" -Apply -Force
```

## 校验

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\project-board-init\scripts\Test-ProjectBoard.ps1" `
  -RepoRoot "D:\path\to\your-repo"

# 输出详细检查清单：在上面的命令后追加 -Detailed
```

检查器只读目标仓库：不改文件、不自动修复、不执行 Git 写操作。结果分级：ERROR（确定性错误）、WARNING（需要核实）、INFO（跳过或提示）、PASS（检查通过）。Git 仓库识别使用 Git 自身的工作树探测命令，兼容常规仓库与 Worktree。

## 任务管理

- 任务编号：`TASK-001` 起，永久唯一。
- `Task_Board.md` 是任务状态唯一权威来源；`project.md` 只展示摘要。
- `references/task-management.md` 是任务状态、转换、依赖、验收、归档和 Git 关联规则的唯一规范源；README、SKILL 与项目规则只保留操作摘要。
- DONE 任务必须验收并归档到 `plans/done.md`；代码任务记录 Commit，里程碑记录 Tag。技能不会自动创建 Commit 或 Tag。

## 安全

- 勿提交 `config.local.json`。
- 安装前先运行 `-Preview`；预览模式不会创建目录或文件。
- 安装脚本默认保留已有文件；`-Force` 仅由本次命令行显式指定生效。
- 覆盖前自动备份到目标仓库 `.project-board-backups/`，备份不会自动清理。
- 检查脚本只读，不会自动修复任何问题。
- 安装脚本不编造业务目标；项目内容由 Agent 按可验证仓库证据浅层起草，无法确认时保持「待确认」。

## 自动化测试

技能自身的测试位于 `tests/`，不依赖 Pester；在 Windows PowerShell 5.1 与 PowerShell 7 环境分别运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<SKILL_DIR>\tests\Run-Tests.ps1"
pwsh -NoProfile -File "<SKILL_DIR>\tests\Run-Tests.ps1"
```
