---
version: 1.3.1
name: project-board-init
description: >-
  为仓库安装项目看板与统一任务台账：写入 .cursor/rules/project-board.mdc，创建
  project.md、Task_Board.md、plans/done.md 及配置目录。仅在用户明确要求安装、
  初始化项目看板或点名 project-board-init 时使用。
disable-model-invocation: true
compatibility: Requires Windows PowerShell 5.1+ or PowerShell 7; local config is merged by the installer.
---

# 项目看板安装（project-board-init）

本技能负责一次性初始化或经用户授权升级项目看板。安装后的仓库规则负责日常维护。默认创建根目录 `project.md`、`Task_Board.md`、`references/task-management.md`、`plans/done.md` 和 `.cursor/rules/project-board.mdc`。

## 触发方式

仅在用户明确要求时执行，例如：

```text
按 project-board-init，给当前仓库安装项目看板
按 project-board-init，在 D:\path\to\repo 初始化项目看板
```

## 文件职责

| 文件 | 唯一职责 |
|---|---|
| `project.md` | 项目级总览：目标、阶段状态、决策、风险、唯一下一步 |
| `Task_Board.md` | 所有任务及状态的唯一权威台账 |
| `references/task-management.md` | 任务状态、依赖、验收与 Git 关联规范（安装进目标仓） |
| `plans/` | 任务计划和执行过程记录，不另建平行任务台账 |
| `plans/done.md` | DONE 任务的历史归档 |
| `docs/` | 正式项目文档 |
| `.cursor/rules/project-board.mdc` | 日常看板和任务维护规则 |

所有安装本技能的项目均默认创建 `Task_Board.md`。简单项目可以只维护少量任务；复杂项目可在 `plans/` 中增加独立计划文档。

## 配置

配置合并顺序：`config.defaults.json` ← `config.local.json`。对象递归合并，数组整段替换。本机 `config.local.json` 不得进入分发包；`config.local.json.example` 仅供复制。覆盖授权不属于配置项，只能由本次命令行显式 `-Force` 提供。

默认配置：

```json
{
  "directories": {"plans":"plans","docs":"docs","doneFile":"plans/done.md","extra":[]},
  "board": {"file":"project.md","ruleFile":".cursor/rules/project-board.mdc","taskBoardFile":"Task_Board.md","taskGuideFile":"references/task-management.md"},
  "taskManagement": {"enabled":true,"idPrefix":"TASK","requireAcceptanceCriteria":true,"requireCommitForCodeTasks":true,"requireTagForMilestones":true},
  "validation": {"readOnly":true,"checkGit":true,"checkTaskReferences":true},
  "projectProfile": "standard"
}
```

所有配置路径必须是仓库根目录下的相对路径，不允许绝对路径或 `..` 路径穿越。`projectProfile` 支持 `simple`、`standard`、`complex`，默认 `standard`；所有规模始终创建 `Task_Board.md`，规模只影响任务拆分与计划文档粒度，不改变唯一权威台账原则。

## 初始化流程

1. 锁定目标仓库根目录；多根工作区无法确定时先询问。
2. 探测 `project.md`、`Task_Board.md`、归档文件和规则文件。已有文件默认保留；发现结构冲突先报告并征求迁移/覆盖/放弃选择。
3. 先执行安装脚本 `-Preview`，展示目录、创建、跳过和覆盖清单；预览不写入。确认后执行安装。默认只创建缺失文件；只有用户明确授权覆盖并在本次命令行显式使用 `-Force` 才更新已存在文件。覆盖前自动备份到目标仓库 `.project-board-backups/<timestamp>/`。
4. 根据仓库可验证证据起草 `project.md`，不得编造业务目标或已确认决策。
5. 运行只读检查脚本，报告 ERROR/WARNING/INFO/PASS。
6. 汇报新增、跳过和更新文件，以及未解决问题。不得自动 Commit 或 Tag。

安装预览与执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/Install-ProjectBoard.ps1" -RepoRoot "D:\path\to\repo" -Preview
powershell -NoProfile -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/Install-ProjectBoard.ps1" -RepoRoot "D:\path\to\repo"
```

已有项目升级使用 `scripts/Upgrade-ProjectBoard.ps1`：默认预览，需 `-Apply` 执行。安装器会在 `.project-board/manifest.json` 记录由技能创建/更新文件的 SHA-256；升级时仅自动更新与上次托管哈希一致的文件，检测到用户修改或未纳管的同名文件则保留并报告冲突。`-Force` 才会覆盖冲突文件，覆盖前自动备份。

## 任务管理规则

- Task ID 使用 `TASK-001` 等格式，永久唯一，不复用。
- 状态定义、合法转换、依赖、验收、归档和 Git 关联以 `references/task-management.md` 为唯一规范源；其他文件只保留摘要。
- 新任务创建时在 `Task_Board.md` 的“状态变更记录”追加创建事件；每次状态变化追加记录，不回写历史。检查器验证状态转换、历史连续性和最新状态一致性。历史任务没有记录时按兼容基线接受并提示 INFO。
- DONE/CANCELLED 重新打开时，必须在历史记录中填写原因和“用户授权”依据。
- DONE 必须有交付物、验收证据、必要测试记录并写入 `plans/done.md`。
- 代码任务记录真实 Commit SHA；里程碑记录真实 Tag。Agent 不得自动创建 Commit 或 Tag。
- CANCELLED 保留原因，不进入完成归档。DONE/CANCELLED 重新打开只能回到 TODO 或 IN_PROGRESS，且必须记录原因并取得用户授权。
- 项目阶段与任务状态独立，不得按任务完成比例推断阶段完成。

## 看板维护约束

`project.md` 保留六节且顺序固定：项目目标、当前状态、关键决策、待办、风险、下一步。待办仅作摘要并链接 `Task_Board.md`；下一步恰好一条、动词开头且可验收。关键决策只记录用户确认的内容。任务状态只能在 `Task_Board.md` 维护。

## 只读一致性检查

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/Test-ProjectBoard.ps1" -RepoRoot "D:\path\to\repo"
powershell -NoProfile -ExecutionPolicy Bypass -File "{SKILL_DIR}/scripts/Test-ProjectBoard.ps1" -RepoRoot "D:\path\to\repo" -Detailed
```

检查文件结构、任务 ID/表格列数/状态/类型、状态历史转换、依赖、归档和 Git 引用。Git 通过 `git rev-parse --is-inside-work-tree` 识别，兼容 Worktree。检查脚本不得写入目标仓库，不得自动修复，不得执行 Git 写操作。ERROR 表示确定性错误；WARNING 表示需要处理或核实的问题；INFO 表示兼容性提示或未执行的检查；PASS 表示未发现问题。结果 JSON 同时输出各等级计数。技能自身测试位于 `tests/`，分别在 Windows PowerShell 5.1 与 PowerShell 7 运行。

## 项目规模适配

- `simple`：少量任务，Task_Board 直接维护，不为每个任务单独建计划文档。
- `standard`（默认）：按模块或阶段拆分任务；只有复杂任务才建立独立计划。
- `complex`：按工作流/子系统建立计划文档，主台账仍统一管理任务 ID、状态和依赖。
- 三种规模均保留 `project.md`、`Task_Board.md` 和统一任务规范；不得因项目简单而省略 Task_Board。

## 安全边界

- 不覆盖已有文件，除非用户明确授权并在本次命令行显式使用 `-Force`；配置文件不得授权覆盖。
- 执行前先预览；覆盖前自动备份，备份不自动清理。
- 不修改本机配置，不分发 `config.local.json`。
- 不删除项目历史、任务、归档或自定义内容。
- 不自动 Commit、Tag、Checkout、Reset。
- 不替换其他技术栈规则，不写入用户级规则目录。
- 发现迁移可能改变历史任务编号或引用时，先生成映射报告并取得确认。
