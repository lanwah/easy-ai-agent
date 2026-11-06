# Changelog

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
