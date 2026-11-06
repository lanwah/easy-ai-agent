---
name: local-config-convention
description: >-
  统一「defaults / local.example / local」三件套配置规范：默认可提交、模板不生效、
  本机 local 部分覆盖 defaults。在新建或改造 Cursor Skill、Agent 脚本、项目本地配置，
  或出现 config.defaults.json、config.local.json、config.local.json.example、
  本地覆盖配置、密钥勿提交、从 example 生成 local 时使用本 Skill。
version: 1.0.0
---

# 本地配置三件套规范

技能与项目需要「可分发默认值 + 本机私密/个性化覆盖」时，统一使用本规范。参考实现：`redmine-issue-reader`。

权威版本见根目录 `VERSION`；变更见 `CHANGELOG.md`。

## 如何使用（给人 / Agent）

### 1. 确保技能已被 Cursor 加载

本仓库内：

```text
<this-repo>/skills/local-config-convention/
```

也可复制/链接到：

- `%USERPROFILE%\.agents\skills\local-config-convention\`
- `%USERPROFILE%\.cursor\skills\local-config-convention\`

改完后若 Agent 未命中，重开对话或确认 Settings → Rules / Skills 能看到该技能。

### 2. 对话里怎么触发

**推荐显式点名**（最稳）：

```text
按 local-config-convention，给这个技能补上配置三件套
按 local-config-convention，给本项目加本地可覆盖配置
```

**也可自然语言**（依赖 description 自动命中）：

```text
新建技能需要 apiKey / baseUrl，用 defaults + local.example + local
给项目加本地配置覆盖，密钥不要进 Git
从 example 生成 config.local.json
```

### 3. 场景 A：创建 / 改造「技能」的配置

目标目录 = 该技能根（含 `SKILL.md` 的那一层）。

对 Agent 说清配置项即可，例如：

```text
按 local-config-convention，在 ~/.agents/skills/my-skill/ 增加配置：
- defaults：baseUrl、timeoutMs
- local 可覆盖：baseUrl、apiKey
读取逻辑写在 scripts/run.ps1，合并优先级 env > local > defaults
```

Agent 应完成清单：三文件 + `.gitignore` + README/SKILL 中的配置说明 + 脚本只读 defaults/local。  
模板可从本技能 `templates/` 复制后改字段名。

### 4. 场景 B：业务「项目」需要本地配置

目标目录 = 仓库根，或约定子目录（如 `scripts/tools/`）。路径写进对话，避免 Agent 猜错：

```text
按 local-config-convention，在 nursing-plat-web/scripts/xxx/ 加配置三件套，
defaults 放可提交默认值，apiKey 只出现在 local.example 占位和本机 local
```

项目里若已有 `.ewlrc.local.js` 等历史方案，**不要强行替换**；仅在「新加一套可分发+本机覆盖」时用本规范。

### 5. 同事 / 本机首次生效

仓库或技能里只有 example、没有 local 时：

```powershell
Copy-Item config.local.json.example config.local.json
# 编辑 config.local.json，只填要覆盖的项（如 apiKey）
```

用本技能脚本核对生效结果：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\local-config-convention\scripts\Merge-Config.ps1" `
  -DefaultsPath ".\config.defaults.json" `
  -LocalPath ".\config.local.json"
```

### 6. 不必使用本技能的情况

- 无密钥、无本机差异、单一 `config.json` 即可
- 已有项目约定（如 `.ewlrc.local.js`）且不打算迁移
- 仅环境变量、不落地 JSON 文件

## 三文件职责（强制）

| 文件 | 是否提交 Git | 是否参与运行时生效 | 职责 |
|------|--------------|--------------------|------|
| `config.defaults.json` | ✅ 提交 | ✅ 生效（底座） | 随技能/项目分发的默认配置；**禁止**放密钥、密码、本机路径私货 |
| `config.local.json.example` | ✅ 提交 | ❌ **永不生效** | 支持项模板与占位说明；供人/Agent 复制生成 local |
| `config.local.json` | ❌ 忽略 | ✅ 生效（覆盖层） | 本机真实配置；可只写需覆盖的字段 |

禁止：

- 把密钥写进 `config.defaults.json` 或 `config.local.json.example`
- 把 `config.local.json` 提交进仓库或粘贴进对话
- 把 `.example` 当成运行时配置去读
- 另起第四套并行命名（如 `config.json` + `config.local`）而不说明迁移

## 合并语义（强制）

有效配置 = **deep merge**（`defaults` ← `local`）：

1. 读取 `config.defaults.json`（缺失则视为 `{}`，并应尽快补上）
2. 若存在 `config.local.json`，对其做 deep merge 覆盖
3. **忽略** `config.local.json.example`（仅文档/脚手架）
4. 可选：环境变量再覆盖最终结果（字段映射由各技能自行声明；优先级建议 `env > local > defaults`）

Deep merge 规则：

- 双方均为「纯对象」（JSON object）→ 按 key 递归合并
- 其他类型（string / number / bool / array / null）→ **整值替换**（数组不按元素合并）
- `local` 未出现的 key → 保留 `defaults`
- `local` 出现的 key → 覆盖（含显式 `null`，若业务需要「清空」须在技能内说明）

可用本目录脚本校验合并结果：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "{SKILL_DIR}/scripts/Merge-Config.ps1" `
  -DefaultsPath "path/to/config.defaults.json" `
  -LocalPath "path/to/config.local.json"
```

`{SKILL_DIR}` = 本 Skill 目录（含本 `SKILL.md` 的那一层）。

## 新建技能 / 项目时的落地清单

在目标根目录（技能根或约定的 config 目录）执行：

```
- [ ] 新增 config.defaults.json（完整默认可运行值，无密钥）
- [ ] 新增 config.local.json.example（列出可覆盖字段 + 占位符）
- [ ] 不提交 config.local.json；用 example 复制生成
- [ ] .gitignore 忽略 local（见下方片段）
- [ ] README / SKILL 写明：复制 example → local，以及合并优先级
- [ ] 读取配置的代码/脚本：只读 defaults + local，永不读 example
```

生成本机文件：

```powershell
Copy-Item config.local.json.example config.local.json
# 再编辑 config.local.json，只填需要覆盖的项
```

### .gitignore 片段（必加）

```gitignore
/config.local.json
*.local.json
!config.local.json.example
```

### 目录示意

```text
your-skill-or-project/
├── config.defaults.json
├── config.local.json.example
├── config.local.json          # gitignore，每人本地一份
├── .gitignore
└── ...
```

模板示例见 [templates/](templates/)。

## Agent 行为要求

出现以下任一情况 → 遵循本规范，勿自创命名或跳过 example：

- 为 Skill / 脚本 / 小工具增加可配置项（尤其含密钥、本机 URL、个人偏好）
- 用户提到「本地配置」「defaults / local / example」「从模板生成配置」
- 审查或改造已有 `config.*.json` 三件套

操作要点：

1. **改默认可分发行为** → 改 `config.defaults.json`
2. **增可配项** → 同步改 `config.defaults.json`（若有默认）+ `config.local.json.example`（模板字段）
3. **用户本机值** → 只动 `config.local.json`；若文件不存在，从 example 复制后再改
4. **解释配置** → 明确哪一层生效；切勿声称 example 已生效
5. **安全** → 不在回复中回显 apiKey / 密码等敏感值

## 与「仅项目规则」的边界

- 本 Skill：跨技能、跨仓库的**规范本体**与落地步骤
- 某仓库若需贴身提醒，可另加极薄 Rule，一句指向本 Skill 即可；不要在 Rule 里复制整套说明
