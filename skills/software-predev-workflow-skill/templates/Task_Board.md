# Task Board

- 项目名称：
- 台账版本：1.0
- 最后更新：
- 当前阶段（引用 Project_Status）：
- 活跃任务数：
- 阻塞任务数：
- 编号规则：TASK-001 起，全局递增，永不复用

## 1. 使用规则
- 仅登记有明确执行目标和可验证完成条件的工作。
- 状态仅为 TODO / IN_PROGRESS / BLOCKED / DONE / CANCELLED / DEFERRED。
- DONE 必须有证据并追加至 plans/done.md；任务完成不等于阶段批准。
- 类型必须使用基础枚举：REQUIREMENTS / DESIGN / DEVELOPMENT / TESTING / DOCUMENTATION / REVIEW / PROJECT_MANAGEMENT / RISK_MITIGATION / RELEASE / OTHER。
- 项目扩展类型使用 CUSTOM:<名称>，须先登记在本文件第 6 节。

## 2. 活跃任务
| TASK_ID | 任务名称/目标 | 主阶段 | 类型 | 优先级 | 状态 | 完成条件 | 关联 RAW/Q/ADR/CR/RISK/AC | 负责人 | 阻塞原因 | 完成证据 | Git Commit | Git Tag | 创建日期 | 最后更新 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

## 3. 任务状态历史（追加式）
| 日期 | TASK_ID | 原状态 | 新状态 | 原因 | 证据/用户表达 |
|---|---|---|---|---|---|

## 4. 任务字段变更历史
| 日期 | TASK_ID | 字段 | 修改前 | 修改后 | 原因 |
|---|---|---|---|---|---|

## 5. 管理约束
- BLOCKED 必须有阻塞原因；DONE 必须有完成证据。
- DONE/CANCELLED 为终态；重新执行创建新 TASK 并关联旧编号。
- 每项任务只有一个主阶段；跨阶段工作拆分或明确主阶段。
- CR、需求和阶段状态由各自权威台账管理。
## 6. 项目扩展任务类型（仅登记实际需要的扩展项）

| 扩展类型代码 | 定义 | 适用范围/使用边界 | 登记日期 |
|---|---|---|---|
