# opencode-config

团队共享的 OpenCode 配置，面向 Swift / iOS 项目，包含自定义 Agent、Skill、模板和工作流。

## 快速初始化

### 新项目

```bash
# 方式一：在目标项目根目录下远程一行搞定
curl -sL https://raw.githubusercontent.com/ze230123/opencode-config/main/init.sh | bash

# 方式二：本地脚本（可指定路径，默认为当前目录）
./init.sh /path/to/new-project
```

### 更新已有项目配置

```bash
git pull
./init.sh /path/to/project
```

## 配置内容

| 目录 | 说明 |
|------|------|
| `agents/` | 自定义 Agent（planner, annotater, coder, reviewer） |
| `skills/` | Skill 定义（coding-standards, naming-conventions, urouter, swift-log） |
| `plans/template/` | 计划模板（Swift Feature, Swift Refactor） |
| `reviews/template/` | Review 模板（功能收尾, 代码审查） |
| `agents-guide.md` | Agent 使用说明 |

## 初始化自动配置

`init.sh` 会自动完成以下配置：

- 复制 Agent、Skill、模板到项目 `.opencode/` 目录
- 配置 `opencode.json`：添加 Xcode MCP（`xcrun mcpbridge`）和 `PROFILE.md` 指令
- 交互式生成 `PROFILE.md`

## 更新配置

修改此仓库后，团队成员 pull 并重新运行 `init.sh` 即可同步。再次安装时会自动清理源中已不存在的旧文件（如 agent 改名后旧文件会被删除）。

项目级自定义配置：直接修改项目内对应文件，init.sh 不会覆盖已存在的文件。

## PROFILE.md

初始化时会交互式询问名字和称呼，自动生成项目根目录的 `PROFILE.md`。已有 PROFILE.md 则跳过，不会覆盖。
