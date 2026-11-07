# Changelog

## [1.2.1] - 2026-11-07

### Fixed
- `tests/Run-Tests.ps1`：不再在 `param()` 默认值里依赖可能为空的 `$PSScriptRoot`，改为脚本体内解析，必要时可显式传 `-SkillDir`。
- `Test-ProjectBoard.ps1`：在 `$ErrorActionPreference=Stop` 下安全调用 git；非 Git 目标不再因 stderr `fatal:` 变成终止错误，集成测试可跑通。

## [1.2.0] - 2026-11-07

### Added
- 安装器新增 `-Preview` 只读预览，先完成路径、模板、目标类型及路径冲突预检查，再进入写入阶段。
- 覆盖文件前自动备份至目标仓库 `.project-board-backups/<timestamp>/`，备份保留且不自动清理。
- 新增 `Upgrade-ProjectBoard.ps1`：默认预览，显式 `-Apply` 执行；覆盖已有文件还需显式 `-Force`。
- 新增无 Pester 依赖的 `tests/Run-Tests.ps1` 集成测试入口。
- 检查器新增任务表格列数、任务 ID 格式和任务类型检查，并增加 INFO 结果级别。

### Changed
- `-Force` 仅由本次命令行参数决定；配置文件中的 `init.force` 不再具有授权作用。
- 移除未被脚本执行的 `init.fillFromRepo` 配置项，项目内容填充职责由 Agent 按技能说明执行。
- 移除 README 对外部 `local-config-convention` 技能的强制依赖，改为内置配置说明。
- 明确 `references/task-management.md` 为任务管理规范唯一来源，其他文档只保留摘要。
- 检查器通过 `git rev-parse --is-inside-work-tree` 识别仓库，支持 Git Worktree。
- 规则模板的检查脚本路径改为安装时注入实际技能目录。
- 强化配置路径合法性与仓库根目录边界校验。

### Safety
- 预览模式不创建目录、文件或备份。
- 初始化默认只创建缺失文件；已有文件默认跳过。
- 升级/覆盖前自动备份；不自动清理备份，不执行 Git 写操作。

### Validation
- 已完成静态审查与压缩包结构检查。
- 当前执行环境未安装 Windows PowerShell 5.1 / PowerShell 7；需在 Windows 环境运行 `tests/Run-Tests.ps1` 完成实机验证。

## [1.1.2] - 2026-11-06

### Fixed
- 修正 `SKILL.md` Frontmatter 中 `version` 与 `name` 被错误拼接的问题，确保 YAML 元数据可被正确解析。

### Changed
- 将技能版本统一升级至 `1.1.2`，同步更新 `SKILL.md`、`VERSION` 与变更记录。

## [1.1.1] - 2026-11-01

### Fixed
- `Test-ProjectBoard.ps1` 以 UTF-8 BOM 保存并拆分可读函数，修复 Windows PowerShell 5.1 解析中文失败。
- `taskManagement` / `validation` 配置项接入检查器（enabled、idPrefix、验收/Commit/Tag 要求、checkGit、checkTaskReferences）。
- 安装时把 `references/task-management.md` 写入目标仓库；台账与规则链接仓库内副本。
- 规则中的检查命令改为技能目录路径，不再误指目标仓 `scripts/`。
- Install/Test 共用 `ProjectBoardConfig.ps1`，消除双份合并实现。
- `.gitignore` 忽略 `.codegraph/` 与 `.vscode/`。

## [1.1.0] - 2026-11-01

### Added
- 所有项目初始化时默认创建根目录 `Task_Board.md`。
- 新增统一任务状态、永久 Task ID、依赖、验收和归档规范。
- 新增 `references/task-management.md`。
- 一致性检查覆盖任务 ID、状态、依赖、归档和 Git Commit/Tag 引用。
- 增加只读检查结果分类和详细报告选项。

### Changed
- `project.md` 作为项目总览，任务状态以 `Task_Board.md` 为唯一权威来源。
- 安装器自行递归合并 defaults/local 配置，避免缺少外部合并脚本时忽略本机配置。
- 配置路径增加相对路径校验，拒绝绝对路径和 `..` 路径穿越。
- README 保留原有安装、校验及配置常用命令，并补充任务管理说明。

### Safety
- 默认不覆盖已有文件；不自动 Commit、Tag 或修复检查问题。
- `config.local.json` 不纳入分发。
