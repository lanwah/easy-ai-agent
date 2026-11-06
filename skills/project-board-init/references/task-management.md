# 任务管理规范

## 1. 权威来源

- `project.md`：项目目标、当前阶段、关键决策、风险和唯一下一步。
- `Task_Board.md`：任务内容、状态、依赖、验收及 Git 关联的唯一权威来源。
- `plans/`：任务计划和执行过程，不另建平行任务状态表。
- `plans/done.md`：DONE 任务的历史归档；Task_Board.md 保留索引。

## 2. 阶段

默认阶段：需求采集、需求分析、概要设计、详细设计、开发、测试、发布。项目可按实际情况增加阶段，但阶段状态必须由项目负责人确认，不得由任务完成比例自动推断。

## 3. 状态转换

| 当前状态 | 允许的下一状态 |
|---|---|
| TODO | IN_PROGRESS、DEFERRED、CANCELLED |
| IN_PROGRESS | BLOCKED、REVIEW、DEFERRED、CANCELLED |
| BLOCKED | IN_PROGRESS、DEFERRED、CANCELLED |
| REVIEW | DONE、IN_PROGRESS、BLOCKED |
| DEFERRED | TODO、IN_PROGRESS、CANCELLED |
| DONE | 默认终态；重新打开需记录原因并获用户授权 |
| CANCELLED | 默认终态；重新打开需记录原因并获用户授权 |

## 4. 完成与归档

任务只有在交付物存在、验收标准满足、必要测试/检查有记录、台账状态同步后才能标记 DONE。DONE 必须追加到 `plans/done.md`，包含 Task ID、名称、完成日期和验收结果。代码任务应记录真实 Commit SHA；非代码任务不强制 Commit。里程碑任务应记录真实 Tag，普通任务不强制 Tag。

## 5. Git 关联

- 一个任务可关联多个 Commit；一个 Commit 可服务多个任务。
- 记录完整 SHA；检查时在目标仓库验证对象存在。
- Tag 需在目标仓库真实存在，里程碑可关联多个 DONE 任务。
- 无法验证时标记待核实，不得伪造或推断。
- Agent 不得自动执行 commit、tag、checkout、reset 等改变 Git 状态的操作。

## 6. 依赖

前置任务使用 Task ID，多个依赖逗号分隔。所有前置任务均完成后才可开始依赖任务。依赖必须指向存在的任务，不得自引用或形成循环。

## 7. 维护规则

任务类型填写普通、代码、里程碑或代码,里程碑，以区分 Commit 与 Tag 要求。任务 ID 永久唯一；DONE/CANCELLED 不删除；延期任务保留原因；变更状态时同步更新时间。项目看板只引用任务 ID，不重复维护任务状态。只读检查发现问题时仅报告，不自动修复。
