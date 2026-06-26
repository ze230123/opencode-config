# opencode-config

团队共享的 OpenCode 配置，包含自定义 Agent、Skill、模板和工作流。

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
| `agents/` | 自定义 Agent（plan, annotate, coder, review） |
| `skills/` | Skill 定义（coding-standards, naming-conventions, urouter, swift-log） |
| `plans/template/` | 计划模板（Swift Feature, Swift Refactor） |
| `reviews/template/` | Review 模板（功能收尾, 代码审查） |
| `agents-guide.md` | Agent 使用说明 |

## 更新配置

修改此仓库后，团队成员 pull 并重新运行 `init.sh` 即可同步。

项目级自定义配置：直接修改项目内对应文件，init.sh 不会覆盖已存在的文件。

## PROFILE.md

初始化时会交互式询问名字和称呼，自动生成项目根目录的 `PROFILE.md`。已有 PROFILE.md 则跳过，不会覆盖。
