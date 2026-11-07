# 设计 Demo 管理说明

## 基本信息
- 项目：
- 当前阶段：P3 / P4
- Demo 目录：`docs/design-demo/current/`
- Demo 版本：
- 关联设计文档/版本：
- 当前正式基线 Tag（如有）：

## 用途与边界
- Demo 用途：可交互网页原型，用于设计预览、评审和开发视觉/交互对齐。
- 权威依据：业务规则、数据、接口、安全和验收以获批设计文档为准。
- 不替代：SRS、概要设计、详细设计和用户批准记录。

## 运行方式
- 环境/浏览器要求：
- 依赖：
- 启动命令/步骤：
- 入口文件：`index.html`
- 已知限制：

## 目录约定
- `current/`：当前工作版本。
- `current/assets/`：静态资源。
- `current/styles/`：样式。
- `current/scripts/`：交互逻辑。
- `change-log.md`：重要修改记录。
- 历史版本由 Git Commit/Annotated Tag 管理，不建立 `milestones/` 或 `history/` 目录。

## Git 约定
- 日常修改使用 Commit；重要里程碑使用 Annotated Tag。
- Tag 格式：`demo-v主版本.次版本`。
- `demo-v0.x` 是开发/评审里程碑，不代表正式批准。
- `demo-v1.0` 仅在 P4 详细设计文档与 Demo 分别评审并获用户明确批准后建立。
- 正式基线 Tag 不得随意删除、移动、覆盖或复用；变更走 CR 并创建新版本。

## 关联记录
- 需求/RAW/Q/ADR：
- 设计评审记录：
- 用户批准记录：
- CR：
