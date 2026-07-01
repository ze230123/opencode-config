# Agents 工作流约束

> 本文件通过 `opencode.json` 的 `instructions` 注入所有 Agent 系统上下文。

---

## 一、核心原则

严禁无 plan 写代码 | 模块隔离推进 | plan 必经批注循环 | 实施后必须 review 收尾

## 二、Agent 协作流程

```
用户需求
   │
   ▼
┌─ Plan Agent ─────────┐
│  调研 → 输出 plan.md  │    状态：规划中
└────────┬─────────────┘
         │
         ▼
┌─ Annotate Agent ──────────────────┐
│  批注循环（1-6 轮）                │    状态：规划中
│  用户决策 → 原地清理 plan.md       │
│  无问题 → 状态改为实施中            │
└────────┬──────────────────────────┘
          │
          ▼
┌─ Coder Agent ──────────────────────┐
│  加载 Skill → 按 plan 实施          │    状态：实施中
│  implement it all / mark completed │
└────────┬───────────────────────────┘
          │
          ▼
┌─ Review Agent ────────────────────┐
│  三板斧 → 创建 review 文档         │    状态：review 中
│  问题分级 → 双向同步               │
│  签收 / 打回                      │
└───────────────────────────────────┘
```

## 三、Agent 职责边界

| Agent | 允许 | 禁止 |
|-------|------|------|
| **planner** | 调研、输出 plan.md | 代码实施、批注、review |
| **annotater** | 批注审查、修正 plan | 代码实施、review、编写 plan |
| **coder** | 按 plan 实施代码 | 编写 plan、批注、review |
| **reviewer** | 验收、创建 review 文档 | 代码实施、编写 plan |

**主 Agent 规则：**
- 收到批注决策时，必须传给 annotater 子代理执行修正，不得自行修改 plan
- 每个阶段只调用对应的 subagent，不跨阶段调用
- 启动 subagent 前先发通知，让用户知道哪个 agent 即将工作

## 四、Plan 状态生命周期

```
规划中 → 实施中 → review 中 → 已完成
                ↑          │
                │  review 打回
                └──────────┘
```

| 状态 | 触发者 | 含义 |
|------|-------|------|
| 规划中 | planner | plan 还在写，未开始实施 |
| 实施中 | annotater 批注完成 | 可以放手执行 |
| review 中 | reviewer | 实施完成，等待或正在 review |
| review 打回 | reviewer（发现 P0/P1） | 需回去修复 |
| 已完成 | reviewer（签收通过） | 所有 P0/P1 问题已关闭 |

## 五、工作流触发规则

| 用户意图 | 触发 Agent | 对应 dev-workflow 步骤 |
|---------|-----------|----------------------|
| 制定计划、规划功能、编写 plan | planner | Step 1-2 |
| 批注 plan、审查计划、补充约束 | annotater | Step 3 |
| 执行 plan、implement it all | coder | Step 4 |
| 修复 review 打回问题 | coder | Step 4（修复模式） |
| 审核、review 收尾、验收 | reviewer | Step 6 |

## 六、上下文管理

- **让 subagent 做重活**：代码探索、文件读取、搜索等交给 subagent，主 agent 只看摘要
- **不重复读文件**：同一文件不要在主 agent 和 subagent 中都完整读取
- **任务描述精简**：调用 subagent 时只传目标 + 关键约束 + 必要路径，不传完整对话历史或大段代码
- **Subagent 只返回摘要**：结论 + 关键决策 + 文件路径，详细内容写入对应文件

## 七、目录结构

```
plans/
├── research/                          # 调研文档
│   ├── research-v{版本号}.md          # 与版本绑定
│   └── research-{功能名}.md          # 想法/探索阶段
├── plan-v{版本号}.md                  # 计划文档
└── template/                          # 模板目录

reviews/
├── review-v{版本号}.md               # 功能收尾（必须）
├── code-review-v{版本号}.md          # 代码审查（按需）
└── template/                          # 模板目录
```
