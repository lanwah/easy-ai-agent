---
name: skill-rule-versioning
description: >-
  为 Skill/Rule 项目安装版本管理：改前核对版本、改后必升版并记变更；
  简单项目正文维护，复杂项目独立 VERSION/CHANGELOG；支持合集与子目录嵌套版本单元（就近优先、默认不联动）。
  当用户点名 skill-rule-versioning、说「安装版本管理」「启用 skill/rule 版本」、
  「给项目挂版本门禁」「嵌套/子项目版本」或要求跨端（Codex/ChatGPT）对齐版本时使用。
version: 1.1.0
---

# Skill / Rule 版本管理（skill-rule-versioning）

按需安装到**指定项目**；未安装的项目不生效。权威版本见根目录 `VERSION`；变更见 `CHANGELOG.md`。

## 如何使用

### 1. 技能位置

本仓库内：

```text
<this-repo>/skills/skill-rule-versioning/
```

也可复制/链接到：

- `%USERPROFILE%\.agents\skills\skill-rule-versioning\`
- `%USERPROFILE%\.cursor\skills\skill-rule-versioning\`
- 目标仓 `.cursor/skills/skill-rule-versioning\`

### 2. 对话触发（安装）

```text
按 skill-rule-versioning，为本项目启用版本管理
给当前 Skill 安装版本门禁
按 skill-rule-versioning，为 D:\path\to\skill-or-repo 启用
```

支持目标：

- **仓库根**（合集/任意工作区）→ `<根>/.cursor/rules/skill-rule-versioning.mdc` + 根 `VERSION`
- **单个 Skill / 子目录**（如 `skills/foo` 或 `~\.agents\skills\foo`）→ 该目录下规则与自身版本
- **合集 + 子项目都要独立版本**（常见）：对仓根装一次，再对每个子 Skill 目录各装一次；父子 `VERSION` 并存合法，**默认不联动**

### 3. 不必使用的情况

- 普通业务应用仓、且不含 Skill/Rule/Agent 指令包
- 用户只要口头记版本、不要文件门禁

---

## Agent 强制工作流（安装到项目）

1. 确认目标根路径（当前工作区、用户给出的路径，或单个 Skill/子目录）。合集下的子项目要把 `-ProjectRoot` 指到**子目录**，不要误装到仓根。
2. 建议形态并请用户确认：
   - **Simple**：实质文件少、无 `scripts/` / `references/` / `templates/`
   - **Complex**：多文件或含上述目录（本 Skill 自身为 Complex）
3. 若目标位于已有父版本单元之内：说明将形成**嵌套版本单元**；子版本只覆盖子树，与父版本号无需相同。
4. 确保 `<目标>/.cursor/rules/` 存在。
5. 将 [templates/skill-rule-versioning.mdc](templates/skill-rule-versioning.mdc) 写入：

   `<目标>/.cursor/rules/skill-rule-versioning.mdc`

   已存在则先说明差异，问是否覆盖；勿静默覆盖。
6. **初始化版本（默认做）**：
   - Simple：主文件（优先 `SKILL.md`，否则 `RULE.md` / `AGENTS.md` / 单份业务 `.mdc`）写入 frontmatter `version: 1.0.0`（若无）及文末 `## 版本记录` 首条。
   - Complex：创建 `VERSION`（若无）与 `CHANGELOG.md`（若无）；主文件 `version` 与 `VERSION` 对齐。
   - 已有版本元数据：保留现有号，只补缺失件，不擅自清历史。
7. 简短确认：已写入规则、当前基线版本、简单/复杂形态、是否嵌套。

推荐脚本（在目标根，或传 `-ProjectRoot`）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "<path-to-this-skill>/scripts/Enable-ForProject.ps1" `
  -ProjectRoot . `
  -Mode Auto
```

合集内给子 Skill 安装示例：

```powershell
# 合集根
... -ProjectRoot D:\Projects\AI\easy-ai-agent -Mode Complex
# 子项目
... -ProjectRoot D:\Projects\AI\easy-ai-agent\skills\skill-rule-versioning -Mode Complex
```

| 参数 | 含义 |
|------|------|
| `-Mode Simple\|Complex\|Auto` | 形态；默认 Auto |
| `-InitVersion:$false` | 只装规则、不补版本元数据 |
| `-Force` | 覆盖已有 `.mdc` |

Agent 用脚本安装后仍须向用户汇报结果；若 Auto 判定与用户意图不符，按用户确认的 Mode 重跑或手补。

---

## Agent 强制工作流（已启用项目内改文件）

当拟改路径向上能命中版本单元（见模板 §0），或用户点名按本规范修改时：

1. **解析最近版本单元**（自文件目录向上找 `VERSION` 或主文件 `version`）。
2. **改前门禁**：展示**单元路径**、当前版本、最近变更、拟改文件；多单元则分列；等待用户确认。
3. **实施修改**（仅确认后）。
4. **升版 + 记录**：只升命中单元；按模板 SemVer 与简单/复杂落点更新。
5. **收尾**：回复单元路径、旧版 → 新版与摘要。

细则以已安装的 `.mdc` 为准（与本 Skill 模板同步维护）。

---

## 取消启用

删除目标内 `.cursor/rules/skill-rule-versioning.mdc`。  
可选：保留或删除该目标的 `VERSION` / `CHANGELOG.md` / 主文件版本字段（问用户，勿擅自删历史）。  
取消子单元不影响合集根单元，反之亦然。

## 维护边界

| 改什么 | 改哪里 |
|--------|--------|
| 门禁文案 / SemVer / 嵌套约定 / 安装流程 | 本 Skill（改后对本 Skill 升版） |
| 某目录要不要启用 | 增删该目录的 `.cursor/rules/skill-rule-versioning.mdc` |
| 已装规则与模板对齐 | 用 `-Force` 重装模板，或手动同步 `.mdc` |
