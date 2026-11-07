# 09 项目看板与任务管理规范（V2.4）

## 1. 文件职责与权威源

| 文件 | 职责 | 权威范围 |
|---|---|---|
| 根目录 `project.md` | 六节管理摘要 | 无独立状态权威，只读汇总 |
| 根目录 `Task_Board.md` | TASK 主表、状态历史、证据、关联 | TASK 字段与状态唯一权威源 |
| `docs/00_Project_Management/Project_Status.md` | 阶段、入口/完成条件、评审/批准/基线历史 | 阶段状态唯一权威源 |
| `plans/done.md` | DONE 任务追加归档 | 完成任务归档 |
| 专业台账 | RAW/Q/ADR/CR/RISK/AC 等 | 各专业事项权威源 |

根目录管理文件和 plans 归档是管理记录例外；正式研发文档仍统一放在 docs。

## 2. project.md 六节

必须且只包含：项目目标（最多 3 句）、当前状态（最多 5 条可核验事实）、关键决策（仍有效的用户确认决策）、待办事项（仅未完成 TASK）、风险（当前有效风险）、下一步（必须且只能一个具体可执行可验证动作）。状态从权威源汇总，不独立维护。无可执行任务时，下一步可为明确用户决策/澄清动作，不虚构工作。

## 3. Task_Board 字段

每项任务必须有唯一 TASK_ID（`TASK-001` 起，全局递增且永不复用）、名称/目标、主阶段（P0/P1/P2/P3/P4/DEV/TEST）、类型、优先级（P0-P3）、状态、可验证完成条件、创建日期、最后更新日期。

任务类型必须使用以下统一枚举：

| 类型代码 | 含义 | 典型用途 |
|---|---|---|
| `REQUIREMENTS` | 需求工作 | 需求采集、澄清、需求分析 |
| `DESIGN` | 设计工作 | 概要设计、详细设计、Demo 设计 |
| `DEVELOPMENT` | 开发工作 | 编码、集成、缺陷修复 |
| `TESTING` | 测试工作 | 测试设计、执行、回归和验收验证 |
| `DOCUMENTATION` | 文档工作 | 文档编写、整理、维护 |
| `REVIEW` | 评审工作 | 阶段评审、专项审查、复核 |
| `PROJECT_MANAGEMENT` | 项目管理 | 计划、协调、看板和进度管理 |
| `RISK_MITIGATION` | 风险应对 | 风险验证、缓解、应急措施 |
| `RELEASE` | 发布工作 | 打包、发布、部署和交付 |
| `OTHER` | 其他工作 | 不适合以上类别且需说明原因 |

项目扩展类型使用 `CUSTOM:<名称>` 格式，并必须先在 `Task_Board.md` 的“项目扩展任务类型”表中登记代码、定义和适用范围；未登记的 CUSTOM 类型视为无效。不得直接创建与基础枚举含义重复的扩展类型。

可选关联 RAW/Q/ADR/CR/RISK/AC、负责人、Commit、Tag。BLOCKED 必须写原因；DONE 必须有完成证据。

不是每条聊天都创建 TASK。仅有明确执行目标、可验证完成条件或跨会话追踪必要性的工作才登记。需求本身先进入 RAW；建议不自动变成任务。

## 4. 状态与转换

状态仅为 `TODO`、`IN_PROGRESS`、`BLOCKED`、`DONE`、`CANCELLED`、`DEFERRED`。

- TODO → IN_PROGRESS / CANCELLED / DEFERRED
- IN_PROGRESS → BLOCKED / DONE / CANCELLED / DEFERRED
- BLOCKED → IN_PROGRESS / CANCELLED / DEFERRED
- DEFERRED → TODO / IN_PROGRESS
- DONE、CANCELLED 为终态；重新执行创建新 TASK 并关联旧任务。

每次状态变化追加日期、任务编号、原/新状态、原因和证据/用户表达。标题、主阶段、验收条件等关键字段变化也记录前后值和原因。

## 5. 完成与归档

DONE 必须满足验收条件、有可定位证据、阻塞已解除、必要关联已更新、状态历史已追加。之后从活跃任务区移出并追加至 `plans/done.md`，至少记录编号、名称、阶段、完成日期、验收摘要、证据位置、关联编号、Commit/Tag（如有）。归档不得覆盖历史。CANCELLED/DEFERRED 不进入 DONE 归档。

## 6. 与阶段状态的边界

Project_Status 保持 V2.3 状态集合 `NOT_STARTED`、`IN_PROGRESS`、`REVIEW_PENDING`、`CHANGES_REQUIRED`、`APPROVED`、`BASELINED`，唯一管理阶段流转。所有任务 DONE 不自动完成阶段或批准；阶段任务未全部 DONE 也不自动判定阶段失败，须依据阶段完成条件和影响判断。每个 TASK 只有一个主阶段；跨阶段工作应拆分或说明主阶段。

## 7. 专业台账与 Git 关联

TASK 可关联 RAW/Q/ADR/CR/RISK/AC，但不替代专业台账。风险的权威记录位于项目风险台账，推荐路径为 `docs/00_Project_Management/Risk_Register.md`，使用技能包 `templates/风险台账模板.md` 实例化；TASK 只关联 RISK 编号，不替代风险评估、应对和状态记录。CR 状态与 TASK DONE 独立；TASK 完成不得自动关闭 CR。一个 Commit 可关联多个 TASK，一个 TASK 可关联多个 Commit/Tag。Git 关联仅作追踪，不构成批准或基线；V2.3 Demo Annotated Tag 和正式基线保护规则优先适用。

## 8. 每轮闭环

恢复阶段和相关任务；判断是否需新增/更新 TASK；记录状态历史和证据；同步专业台账关联。每当 TASK 新增后、TASK 任意字段修改后、TASK 状态变化后、TASK 关联关系变化后，以及 DONE 任务从活跃区移入 `plans/done.md` 归档后，必须立即按 `10-project-consistency-check.md` 执行自动只读一致性检查；`Project_Status.md` 当前阶段发生变化后，或阶段状态发生变化后，任一变化均必须立即执行一致性检查；同一轮两者同时变化时可合并一次检查，但报告必须注明覆盖两项。实质工作结束前再次确认本轮触发项均已检查（同一轮已完成且范围覆盖的检查无需重复运行）。反馈实际修改、阶段状态、任务变化、阻塞、待用户决定、检查结果和唯一下一步。不能写入时标记待保存。普通问答不机械创建任务。

## 9. 已有项目与异常

先扫描看板、任务台账、计划/归档、TASK 编号、其他任务系统和 Git。不得自动重编号、覆盖、迁移、合并或删除。冲突先报告；缺失信息不得凭聊天猜测成权威历史。