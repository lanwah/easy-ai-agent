# 模板目录说明与映射

本目录是技能包模板源文件。新项目按需复制到项目的 `docs/templates/`；已有项目先扫描，不覆盖既有模板。正式文档按项目约定可用中文名或逻辑英文名，但必须在文档清单中保持一致。

| 逻辑模板名 | 中文模板源文件 | 用途 |
|---|---|---|
| `Project_Charter.md` | `项目初始化模板.md` | 项目章程与初始化记录 |
| `Project_Status.md` | `项目状态模板.md` | 阶段、基线、阻塞和待决定事项 |
| `Raw_Requirements.md` | `原始需求台账模板.md` | 原始需求原文和来源 |
| `Open_Issues.md` | `未决问题台账模板.md` | 问题、影响等级和处理状态 |
| `Decision_Log.md` | `决策台账模板.md` | 方案、依据、确认状态 |
| `Change_Log.md` | `变更台账模板.md` | CR 及审批/实施状态 |
| `Traceability_Matrix.md` | `需求追踪矩阵模板.md` | RAW 至验收追踪 |
| `SRS.md` | `需求规格说明书模板.md` | 软件需求规格说明书 |
| `High_Level_Design.md` | `概要设计模板.md` | 概要设计 |
| `Detailed_Design.md` | `详细设计模板.md` | 详细设计 |
| `Review.md` | `阶段评审检查表.md` | 阶段评审、批准和基线记录 |

`问题与决策台账模板.md`、`变更与追踪模板.md` 为 V2.0 兼容模板，仅供已有项目参考；新项目优先使用上表拆分后的独立模板。

## V2.2 新增模板

| 逻辑模板名 | 中文模板源文件 | 用途 |
|---|---|---|
| `Clarification_Log.md` | `问题澄清记录台账模板.md` | 问题原文、选项及优缺点、助手推荐、用户历次回答/改选和最终确认的完整追加式历史 |

该模板建议在项目中实例化为 `docs/00_Project_Management/问题澄清记录台账.md`。它与未决问题台账、决策台账分离，通过 CLQ/Q/RAW/ADR 编号关联。


## V2.3 新增模板

| 逻辑模板名 | 中文模板源文件 | 用途 |
|---|---|---|
| `Design_Demo_Guide.md` | `设计Demo管理说明模板.md` | 项目 Demo 用途、目录、运行方式和 Git Tag 规则 |
| `Design_Demo_Change_Log.md` | `设计Demo变更记录模板.md` | Demo 重要修改、原因、影响、关联需求/CR/评审及版本记录 |
| `Design_Demo_Review.md` | `设计Demo评审记录模板.md` | P3/P4 Demo 独立评审、用户批准和正式基线关联记录 |

项目在 P3 正式创建 Demo 时，按需复制为 `docs/design-demo/README.md`、`docs/design-demo/change-log.md`；评审记录按项目文档命名约定存放在 `docs/04_Reviews/`。

## V2.4 新增模板

| 逻辑模板名 | 模板源文件 | 用途 | 项目实例化路径 |
|---|---|---|---|
| `Project_Board.md` | `project.md` | 六节项目管理摘要 | 根目录 `project.md` |
| `Task_Board.md` | `Task_Board.md` | 统一执行任务台账 | 根目录 `Task_Board.md` |
| `Done_Tasks.md` | `done.md` | 已完成任务追加归档 | `plans/done.md` |
| `Consistency_Check_Report.md` | `项目一致性检查报告模板.md` | 只读一致性检查报告 | `docs/00_Project_Management/` 或 `docs/04_Reviews/` |
| `Risk_Register.md` | `风险台账模板.md` | 风险识别、评估、应对、接受和关闭记录 | `docs/00_Project_Management/Risk_Register.md` |

上述为项目管理记录例外；正式研发文档仍放在 `docs/`。
