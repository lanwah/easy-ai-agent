# 02 项目目录规范

## 1. 总原则

所有项目研发文档统一归档在项目根目录 `docs/`。项目实际使用的正式研发文档模板副本放在 `docs/templates/`；技能包自身模板源文件放在技能包 `templates/`。根目录 `project.md`、`Task_Board.md` 及 `plans/done.md` 属于 V2.4 项目管理记录例外，不属于正式研发文档，不适用 `docs/` 归档路径。不得把其他项目研发文档散落在代码目录或项目根目录。

## 2. 默认结构

```text
<ProjectName>/
├── docs/
│   ├── README.md
│   ├── templates/
│   ├── 00_Project_Management/
│   ├── 01_Requirements/
│   ├── 02_Architecture/
│   ├── 03_Detailed_Design/
│   ├── 04_Reviews/
│   ├── 05_Development/
│   └── 06_Testing/
├── src/
├── tests/
├── scripts/
├── config/
├── assets/        # 按需
├── tools/         # 按需
├── README.md
└── .gitignore
```

## 3. 文档归档建议

| 目录 | 内容 |
|---|---|
| `docs/00_Project_Management/` | 项目章程、状态、文档清单、决策、变更和风险台账 |
| `docs/01_Requirements/` | 原始需求、问题台账、SRS、需求追踪 |
| `docs/02_Architecture/` | 架构方案、概要设计、ADR |
| `docs/03_Detailed_Design/` | 模块详细设计、接口和数据设计 |
| `docs/04_Reviews/` | 阶段检查、评审意见、批准与基线记录 |
| `docs/05_Development/` | 开发计划、实现记录、构建与发布说明 |
| `docs/06_Testing/` | 测试策略、用例、测试报告、缺陷记录和验收记录 |

## 4. 适配规则

- 新项目按默认结构创建；`assets/`、`tools/` 按需创建。
- 已有项目优先遵循技术栈、框架和仓库既有约定。
- 已有项目缺目录只报告建议；未经用户确认不创建迁移动作、不移动既有文件。
- 可以在 `docs/` 内按模块、版本或阶段增加子目录，但文档清单必须记录实际位置。

## 5. 命名与一致性

优先使用清晰、稳定的英文目录名；文档文件名可用中文或英文，但同一项目保持一致。模板文件名映射见 `templates/README.md`。路径调整必须更新文档清单和所有引用。

## 6. V2.4 项目管理入口文件例外

根目录 `project.md` 是管理摘要，`Task_Board.md` 是任务台账，`plans/done.md` 是完成任务追加归档。它们不是正式研发文档；正式研发文档仍统一放在 `docs/`。模板目的地必须按模板职责区分：`templates/project.md` → 根目录 `project.md`；`templates/Task_Board.md` → 根目录 `Task_Board.md`；`templates/done.md` → `plans/done.md`；其他正式研发文档模板按需复制到 `docs/templates/`。不得将前三个管理模板仅复制到 `docs/templates/` 后就视为完成初始化。新项目目录示意：

```text
<ProjectName>/
├── project.md
├── Task_Board.md
├── plans/done.md
├── docs/
├── src/
└── README.md
```

已有项目不强制迁移；缺少时只报告建议，获用户批准后才创建。已有同类管理文件优先评估复用。
