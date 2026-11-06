# project-board-init

为任意仓库安装统一的项目看板和任务台账：

- `.cursor/rules/project-board.mdc`（`alwaysApply`）
- 根目录 `project.md`（六节项目总览）
- 根目录 `Task_Board.md`（所有项目默认创建，唯一权威任务台账）
- `references/task-management.md`（任务管理规范，安装时写入目标仓库）
- `plans/done.md`（完成任务归档）及配置中的目录（默认 `plans/`、`docs/`；本机可追加 `design/` 等）

## 配置

遵循 [local-config-convention](../local-config-convention/SKILL.md)：

1. 默认可分发：`config.defaults.json`（`plans` + `docs`）
2. 复制 example 生成本机覆盖：

```powershell
cd $HOME\.agents\skills\project-board-init
Copy-Item config.local.json.example config.local.json
# 编辑 extra，例如 ["design"]
```

3. 合并优先级：`local` 覆盖 `defaults`（对象递归合并，数组整段替换）。
4. `config.local.json` 仅供本机使用，不得提交或放入分发包。

## 安装到某仓库

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\project-board-init\scripts\Install-ProjectBoard.ps1" `
  -RepoRoot "D:\path\to\your-repo"

# 覆盖已有看板文件（必须先确认备份与迁移）：
# ... -Force
```

校验：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\project-board-init\scripts\Test-ProjectBoard.ps1" `
  -RepoRoot "D:\path\to\your-repo"

# 输出详细检查清单：
# 在上面的命令后追加 -Detailed
```

或在 Cursor 对话中点名：`按 project-board-init，给当前仓库安装项目看板`。

## 任务管理

- 任务编号：`TASK-001` 起，永久唯一。
- 状态：`TODO`、`IN_PROGRESS`、`BLOCKED`、`REVIEW`、`DONE`、`DEFERRED`、`CANCELLED`。
- `Task_Board.md` 是任务状态唯一权威来源；`project.md` 只展示摘要。
- DONE 任务必须验收并归档到 `plans/done.md`。
- 代码任务记录 Commit；里程碑记录 Tag。技能不会自动创建 Commit 或 Tag。
- 详细规则见 `references/task-management.md`。

## 检查结果

检查器只读目标仓库：不改文件、不自动修复、不执行 Git 写操作。ERROR 为确定性错误，WARNING 为待核实事项，PASS 表示未发现问题。Git 不可用或目标非 Git 仓库时会明确报告跳过 Git 核验。

## 安全

- 勿提交 `config.local.json`。
- 安装脚本默认保留已有文件；`-Force` 会更新同名文件，使用前必须备份并确认。
- 检查脚本只读，不会自动修复任何问题。
- 安装脚本不 invent 业务目标；产品文案由 Agent 按 SKILL 浅层起草或保持「待确认」。
