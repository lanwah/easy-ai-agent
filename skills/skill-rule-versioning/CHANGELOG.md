# Changelog

## [1.2.0] - 2026-11-07

### Changed
- 复杂单元 `CHANGELOG.md` 改为 Keep-a-Changelog 风格（对齐 `project-board-init`）：`## [x.y.z] - YYYY-MM-DD` + `### Added` / `### Changed` / `### Fixed`（及可选 Safety/Compatibility/Validation）分节。
- 规则模板与本单元 `.mdc` 同步复杂日志格式约定；简单单元仍用文末 `## 版本记录` 单行摘要。
- `Enable-ForProject.ps1` 新建 Complex `CHANGELOG.md` 时写入新格式种子，不再生成单行列表。

### Added
- `SKILL.md` 安装与改文件流程中明确复杂 CHANGELOG 写法；反例补充「禁止复杂日志继续用单行列表」。

## [1.1.0] - 2026-11-06

### Added
- 支持合集与子目录嵌套版本单元：就近优先、默认不联动；门禁展示单元路径；安装可对子目录重复执行。

## [1.0.0] - 2026-11-06

### Added
- 初版：可安装 Skill；项目内规则门禁；简单/复杂版本落点；安装脚本与初始版本引导。
