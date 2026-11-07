# Changelog

## [2.4.2] - 2026-11-07

### Fixed
- 修正 `.gitignore`：不再忽略 `.cursor/`，使 `skill-rule-versioning.mdc` 可纳入版本库（与合集内其它技能一致）。

### Changed
- 移除技能包内冗余的 `sequential-commit-msg.mdc`（序号提交由合集根统一启用）。

## [2.4.1] - 2026-11-07

### Added
- 启用 skill-rule-versioning（Complex）：`.cursor/rules/skill-rule-versioning.mdc`、根目录 `VERSION` 与主文件 frontmatter 对齐。

### Changed
- `CHANGELOG.md` 改为 Keep-a-Changelog（`## [x.y.z] - YYYY-MM-DD` + Added/Changed/Fixed），并合并 git 提交 #1～#14（补 V1.0、打包脚本、忽略项等此前未入日志条目）。

## [2.4.0] - 2026-11-01

### Added
- 根目录 `project.md` 看板、`Task_Board.md` 统一任务台账与 `plans/done.md` 完成任务追加归档（#13）。
- 看板/任务管理规范、自动只读一致性检查规范及相应模板；TASK 编号、状态转换、完成证据、专业台账关联与 Git Commit/Tag 追踪规则。
- `templates/风险台账模板.md`（RISK 编号、概率/影响、应对、责任人、状态、复查、接受证据与关联规则）。
- `reports/` 作为技能包升级报告统一归档目录；按版本分目录保存升级核对/复核/验收矩阵，并新增 `reports/README.md`（#14）。
- `V2.4_验收测试矩阵.md`（TC-001～TC-036），区分文档静态核验与真实环境执行。
- 项目状态模板独立「阶段评审与用户批准记录表」「基线记录表」；评审、批准、基线三者分离并追加保留历史。

### Changed
- Project_Status 为阶段状态唯一权威源；任务完成、阶段评审、用户批准与建立基线相互独立。
- 一致性检查改为强制自动：初始化/接管后、TASK 变更/归档后、阶段状态变更后、阶段评审前及每轮实质工作结束前；保持只读、不自动修复。
- 强制一致性检查触发条件统一覆盖：TASK 新增/字段修改/状态变化/关联变化，以及 DONE 任务移入 `plans/done.md` 后。
- 阶段触发：`Project_Status` 当前阶段变化或阶段状态变化任一发生后均必须检查。
- TASK 类型枚举统一为 REQUIREMENTS、DESIGN、DEVELOPMENT、TESTING、DOCUMENTATION、REVIEW、PROJECT_MANAGEMENT、RISK_MITIGATION、RELEASE、OTHER；允许已登记 `CUSTOM:<名称>` 扩展。
- 新项目初始化必须将 `project.md`、`Task_Board.md`、`plans/done.md` 分别实例化到规定位置；区分管理模板与 `docs/templates/` 正式研发文档模板。
- 已有项目先扫描并经用户批准后补齐；README 追加 V2.4 命令，不替换原常用命令。
- 保存 V2.3 原始 `README.md` 到 `audit-baselines/README_V2.3.md`（含 SHA-256 与逐段对照）。

### Fixed
- V2.4 全量复核增量修正（P1/P2、R5/R6）与验收证据补充；静态核验与真实环境边界表述对齐。

## [2.3.0] - 2026-11-01

### Added
- P3 引入可交互网页设计 Demo，P4 完善；不新增研发阶段、不替代正式设计文档（#10）。
- Demo 目录约定 `docs/design-demo/`，当前版本位于 `current/`；Git Commit 记过程、Annotated Tag 记里程碑；正式基线 Tag 受保护。
- Demo 管理说明、变更记录与评审记录模板；Demo 修改分类、需求/设计冲突处理、CR 约束、开发阶段对齐与跨会话恢复要求。

### Changed
- P4 详细设计文档与 Demo 分别评审、分别取得用户明确批准后，才可建立正式设计基线。
- 保留 V2.2 澄清追踪规则、全部旧版规范与 README 常用命令。

## [2.2.0] - 2026-11-01

### Added
- 独立问题澄清记录台账模板：问题原文、背景、影响范围、选项版本及逐项优缺点（#9）。
- 强制助手每轮提供推荐选项、理由、置信度、依据与未知条件；推荐不构成用户决定。
- 追加式澄清历史：保留用户历次回答、讨论、否决、改选与最终确认。
- 全过程澄清扩展到 P1/P2 需求与 P3/P4 设计；阶段评审/质量检查/跨会话恢复加入澄清完整性门禁。

### Changed
- 保留 V2.1 原有文件、兼容模板与 README 常用命令，并增加问题记录查询命令。

## [2.1.0] - 2026-11-01

### Added
- 扩充 8 份 references 为可执行规范；问题/决策/变更台账与需求追踪矩阵独立模板（#6）。
- 新项目默认目录补充 `docs/05_Development/` 与 `docs/06_Testing/`。
- 阶段输入/输出、入口检查、完成条件、变更影响分析与跨会话交接要求。

### Changed
- 统一模板映射、主技能引用与文档归档约定；新项目优先独立模板，旧合并模板作兼容参考。

### Fixed
- 恢复 V2.1 README 中被冲掉的常用命令说明（#8）。

## [2.0.1] - 2026-11-01

### Added
- 按 `.gitignore` 打包技能包的 zip 脚本（#11）。

### Fixed
- 打包排除工具目录与 `.gitignore`，并正确收录中文模板（#12）。

### Changed
- 忽略 `.codegraph`（#7）。

## [2.0.0] - 2026-10-31

### Added
- 新项目与已有项目采用不同初始化策略；默认 `docs/` 文档根及标准代码目录（#2）。
- 需求质量检查、基线保护、阶段门禁与跨会话恢复要求。
- 详细规范拆分到 `references/`；阶段与必读参考映射及模板源文件复制规则。
- README 补充常用命令，便于无 SKILL 时只读操作（#5）。

### Changed
- 统一 docs 目录示例，并补充参考映射与模板说明（#3）。

### Fixed
- 忽略 `.vscode` 并移除已跟踪的空 settings（#4）。

## [1.0.0] - 2026-10-31

### Added
- 软件前期研发工作流技能包初版：SKILL 入口、基础模板与 README（#1）。
