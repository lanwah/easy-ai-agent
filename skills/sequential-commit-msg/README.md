# sequential-commit-msg

Cursor Agent Skill：为任意 Git 仓库启用 **`#序号 提交说明`** 自增提交规范。

当前版本：见 [`VERSION`](VERSION)。变更说明：见 [`CHANGELOG.md`](CHANGELOG.md)。

## 格式

```text
#<序号> <提交说明>
```

- `#` 与数字之间无空格（正确 `#35`，错误 `# 35`）
- 序号 = 近期 `git log` subject 中匹配到的最大 `#N` **+ 1**
- 无历史匹配时从 `1` 起

示例：

```text
#34 新增 RedMineService 启动脚本，并由 start.bat 一键调用
#35 修复 mock 接口路径拼写
```

> 这是**仓库内自增序号**，不是 Redmine / 工单系统的 `#issue` 号。

## 技能位置

本合集内：

```text
<this-repo>/skills/sequential-commit-msg/
```

推荐本机用目录联接加载到 Cursor：

```powershell
cmd /c mklink /J "$HOME\.agents\skills\sequential-commit-msg" `
  "D:\Projects\AI\easy-ai-agent\skills\sequential-commit-msg"
```

也可放到 `%USERPROFILE%\.cursor\skills\sequential-commit-msg\`。重启对话后 Agent 即可命中本技能。

## 启用到某个项目

对话：

```text
按 sequential-commit-msg，为本项目启用序号提交规范
```

或脚本（`-ProjectRoot` 指到目标仓库根）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "<path-to-this-skill>/scripts/Enable-ForProject.ps1" `
  -ProjectRoot .
```

覆盖已有规则时加 `-Force`。

效果：写入 `<repo>/.cursor/rules/sequential-commit-msg.mdc`（`alwaysApply`）。

## 取下一序号

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME\.agents\skills\sequential-commit-msg\scripts\Get-NextCommitSeq.ps1" `
  -ProjectRoot .
```

stdout 为一行整数，例如 `35`。

## 目录结构

```text
sequential-commit-msg/
├── SKILL.md                              # Agent 工作流与触发说明
├── README.md
├── VERSION / CHANGELOG.md                # Complex 版本单元
├── templates/
│   └── sequential-commit-msg.mdc         # 安装到项目的 alwaysApply 规则
└── scripts/
    ├── Enable-ForProject.ps1             # 安装规则到目标仓库
    └── Get-NextCommitSeq.ps1             # 解析下一序号
```

## 取消启用

删除项目内 `.cursor/rules/sequential-commit-msg.mdc` 即可；不必删除本技能目录。

## 相关

若使用 Gerrit，且 `commit-msg` hook 因 `#` 前缀报 `file is empty`，需去掉 hook 里 `git stripspace` 的 `--strip-comments`（可参考团队内的 `commit-msg-formater` 技能）。

## License

MIT
