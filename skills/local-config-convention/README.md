# local-config-convention

Cursor Agent Skill：统一 `config.defaults.json` / `config.local.json.example` / `config.local.json` 三件套配置规范。

适用于新建或改造 Skill、Agent 脚本、需要本机覆盖的项目配置。

当前版本：见 [`VERSION`](VERSION)。变更说明：见 [`CHANGELOG.md`](CHANGELOG.md)。

## 技能位置

本合集内：

```text
<this-repo>/skills/local-config-convention/
```

推荐本机用目录联接加载到 Cursor：

```powershell
cmd /c mklink /J "$HOME\.agents\skills\local-config-convention" `
  "D:\Projects\AI\easy-ai-agent\skills\local-config-convention"
```

也可放到 `%USERPROFILE%\.cursor\skills\local-config-convention\`。重启对话后 Agent 即可命中本技能。

## 怎么用

在 Cursor Agent 对话里**点名**或描述配置需求即可。

| 场景 | 示例说法 |
|------|----------|
| 给新技能加配置 | `按 local-config-convention，在 xxx 技能根目录加 defaults/local.example/local` |
| 给项目加本地覆盖 | `按 local-config-convention，在本仓库 scripts/foo/ 加配置三件套` |
| 本机首次配置 | 复制 `config.local.json.example` → `config.local.json` 后只填覆盖项 |
| 核对生效值 | 跑 `scripts/Merge-Config.ps1`（见下） |

完整步骤与 Agent 行为见 [SKILL.md](SKILL.md)「如何使用」。

## 快速对照

| 文件 | 提交 | 生效 |
|------|------|------|
| `config.defaults.json` | 是 | 是（默认） |
| `config.local.json.example` | 是 | **否**（仅模板） |
| `config.local.json` | 否 | 是（覆盖 defaults） |

合并：`deep merge(defaults, local)`；可选 `env` 再覆盖。详见 [SKILL.md](SKILL.md)。

## 合并脚本自测

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\local-config-convention\scripts\Merge-Config.ps1" `
  -DefaultsPath "$HOME\.agents\skills\local-config-convention\templates\config.defaults.json"
```

带 local 时再传 `-LocalPath`。

## 参考实现

`redmine-issue-reader` 已按本规范落地（defaults + example + gitignore 的 local）。
