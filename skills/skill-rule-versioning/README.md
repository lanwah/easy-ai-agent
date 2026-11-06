# skill-rule-versioning

为 **Skill / Rule / Agent 指令包** 按需安装版本管理：改前核对版本，改后必升版并记变更。未安装的项目不受影响。

支持**合集 + 子目录嵌套版本单元**：就近优先、父子版本默认不联动。

当前版本：见 [`VERSION`](VERSION)。变更说明：见 [`CHANGELOG.md`](CHANGELOG.md)。

## 安装到目标项目

对话：

```text
按 skill-rule-versioning，为本项目启用版本管理
```

或脚本（`-ProjectRoot` 指到合集根或子 Skill 目录均可）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "D:\Projects\AI\easy-ai-agent\skills\skill-rule-versioning\scripts\Enable-ForProject.ps1" `
  -ProjectRoot . `
  -Mode Auto
```

写入：`<目标>/.cursor/rules/skill-rule-versioning.mdc`，并按 Simple/Complex 补齐初始版本元数据。

合集下子项目要独立版本时：对子目录再执行一次安装。

## 目录

| 路径 | 作用 |
|------|------|
| `SKILL.md` | Agent 安装与日常改文件流程 |
| `templates/skill-rule-versioning.mdc` | 安装到目标项目的规则正文 |
| `scripts/Enable-ForProject.ps1` | 一键安装 |
| `VERSION` / `CHANGELOG.md` | 本 Skill（Complex）自身版本 |

## 取消

删除目标内 `.cursor/rules/skill-rule-versioning.mdc`。
