---
name: sequential-commit-msg
description: >-
  为仓库启用「#序号 提交说明」自增提交规范：从 git log 解析上次序号并 +1。
  当用户点名 sequential-commit-msg、说「启用序号提交」「#序号 提交规范」、
  「安装序号 commit message」或要求按 #N 空格说明 写提交信息时使用。
version: 1.0.1
---

# 序号提交规范（sequential-commit-msg）

首行格式：`#<序号><空格><提交说明>`。序号在仓库最近历史匹配到的最大 `#N` 上 **+1**。

示例：`#35 新增 RedMineService 启动脚本`

这是**仓库内自增序号**，不是 Redmine 工单号。若 Gerrit `commit-msg` hook 因 `#` 前缀报 `file is empty`，改用 `commit-msg-formater` 技能修 hook。

权威版本见根目录 `VERSION`；变更见 `CHANGELOG.md`。

## 如何使用

### 1. 确保技能已被 Cursor 加载

本仓库内：

```text
<this-repo>/skills/sequential-commit-msg/
```

也可复制/链接到：

- `%USERPROFILE%\.agents\skills\sequential-commit-msg\`
- `%USERPROFILE%\.cursor\skills\sequential-commit-msg\`

### 2. 对话触发（安装到项目）

```text
按 sequential-commit-msg，为本项目启用序号提交规范
给当前仓库挂上 #序号 提交规范
```

指定路径：`按 sequential-commit-msg，为 D:\Projects\Foo 启用`。

### 3. 不必使用本技能的情况

- 项目已用 Redmine `#工单号` 作提交前缀（那是工单 ID，不是自增序号）
- 项目已约定 conventional commits / 其它格式且用户未要求切换

---

## Agent 强制工作流（启用项目）

1. 确认目标仓库根（当前工作区或用户给出的路径）。
2. 确保 `<repo>/.cursor/rules/` 存在。
3. 将本 Skill 的 [templates/sequential-commit-msg.mdc](templates/sequential-commit-msg.mdc) 写入：

   `<repo>/.cursor/rules/sequential-commit-msg.mdc`

4. 若目标已存在：先说明差异，问是否覆盖；勿静默覆盖。
5. 简短确认已写入规则；之后该仓提交须遵守本规范。

推荐脚本（在目标仓库根，或传 `-ProjectRoot`）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "<path-to-this-skill>/scripts/Enable-ForProject.ps1" `
  -ProjectRoot .
```

本机 junction 场景也可用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\sequential-commit-msg\scripts\Enable-ForProject.ps1" `
  -ProjectRoot .
```

覆盖已有规则时加 `-Force`。

## Agent 强制工作流（在本仓写提交说明）

项目已启用本规范（存在上述 `.mdc`），或用户点名按本规范提交时：

1. **取下一序号**（优先脚本）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\sequential-commit-msg\scripts\Get-NextCommitSeq.ps1" `
  -ProjectRoot .
```

脚本 stdout 为一行整数（下一序号）。若无脚本，等价逻辑：

- `git log --format=%s -n 200`
- 匹配首行 `^#(\d+)\s`（`#` 与数字之间无空格；兼容历史 `# 30` 时用 `^#\s*(\d+)\s`）
- 取匹配到的**最大**数字 `M`；下一序号 = `M + 1`；无匹配则从 `1` 起

2. **写 message**：`#<下一序号> <说明>`。说明简洁、说明 why/what，中英文跟仓库既有风格。
3. **禁止**改用 `feat:` / `fix:` 等其它首行格式，除非用户当次明确要求例外。
4. 仍遵守用户/仓库其它 git 安全规则（未要求不 commit、不改 config、不 force push 等）。

### 格式细则

| 项 | 要求 |
|----|------|
| 首行 | `#` + 数字 + 一个空格 + 说明 |
| `#` 与数字 | 无空格（正确 `#35`，错误 `# 35`） |
| 说明 | 非空；单行优先；正文/脚注可选，但首行必须符合格式 |
| 序号来源 | 当前分支近期 subject 中的最大 `#N`，不是文件计数、不是日期 |

### 示例

```text
#34 新增 RedMineService 启动脚本，并由 start.bat 一键调用
#35 修复 mock 接口路径拼写
```

## 取消启用

删除项目内 `.cursor/rules/sequential-commit-msg.mdc`（勿删本 Skill 目录）。

## 维护边界

| 改什么 | 改哪里 |
|--------|--------|
| 规范文案 / 解析逻辑 | 本 Skill（`SKILL.md`、`scripts/`、`templates/`） |
| 某仓库要不要启用 | 增删该仓的 `.cursor/rules/sequential-commit-msg.mdc` |
