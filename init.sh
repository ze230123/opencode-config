#!/bin/bash
# opencode 项目初始化脚本
# 将团队 opencode 配置复制到目标项目
# 用法:
#   本地: ./init.sh /path/to/project
#   远程: curl -sL https://raw.githubusercontent.com/ze230123/opencode-config/main/init.sh | bash -s /path/to/project

set -e

TARGET="${1:-.}"

if [ ! -d "${TARGET}" ]; then
  echo "错误: 目录 ${TARGET} 不存在"
  exit 1
fi

# 确定脚本所在目录
if [ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  REPO_URL="${OPENCODE_CONFIG_REPO:-https://github.com/ze230123/opencode-config.git}"
  SCRIPT_DIR="$(mktemp -d)"
  echo "==> 克隆配置仓库..."
  if ! git clone --depth 1 "${REPO_URL}" "${SCRIPT_DIR}"; then
    echo "错误: 无法克隆 ${REPO_URL}"
    rm -rf "${SCRIPT_DIR}"
    exit 1
  fi
  CLEANUP=1
fi

echo "==> 初始化 opencode 配置到 ${TARGET}"

# .opencode/agents
mkdir -p "${TARGET}/.opencode/agents"
for old in "${TARGET}/.opencode/agents/"*.md; do
  [ -f "$old" ] && [ ! -f "${SCRIPT_DIR}/agents/$(basename "$old")" ] && rm "$old" && echo "  删除 agents/$(basename "$old")（源中已不存在）"
done
for f in "${SCRIPT_DIR}/agents/"*.md; do
  [ -f "$f" ] && cp "$f" "${TARGET}/.opencode/agents/" && echo "  复制 agents/$(basename "$f")"
done

# .opencode/agents-guide.md
[ -f "${SCRIPT_DIR}/agents-guide.md" ] && cp "${SCRIPT_DIR}/agents-guide.md" "${TARGET}/.opencode/" && echo "  复制 agents-guide.md"

# .opencode/skills
mkdir -p "${TARGET}/.opencode/skills"
for old in "${TARGET}/.opencode/skills/"*/; do
  [ -d "$old" ] && [ ! -d "${SCRIPT_DIR}/skills/$(basename "$old")" ] && rm -rf "$old" && echo "  删除 skills/$(basename "$old")（源中已不存在）"
done
for d in "${SCRIPT_DIR}/skills/"*/; do
  [ -d "$d" ] && name=$(basename "$d") && mkdir -p "${TARGET}/.opencode/skills/${name}" && cp "${d}SKILL.md" "${TARGET}/.opencode/skills/${name}/" && echo "  复制 skills/${name}/SKILL.md"
done

# plans/template
mkdir -p "${TARGET}/plans/template"
for old in "${TARGET}/plans/template/"*.md; do
  [ -f "$old" ] && [ ! -f "${SCRIPT_DIR}/plans/template/$(basename "$old")" ] && rm "$old" && echo "  删除 plans/template/$(basename "$old")（源中已不存在）"
done
for f in "${SCRIPT_DIR}/plans/template/"*.md; do
  [ -f "$f" ] && cp "$f" "${TARGET}/plans/template/" && echo "  复制 plans/template/$(basename "$f")"
done

# reviews/template
mkdir -p "${TARGET}/reviews/template"
for old in "${TARGET}/reviews/template/"*.md; do
  [ -f "$old" ] && [ ! -f "${SCRIPT_DIR}/reviews/template/$(basename "$old")" ] && rm "$old" && echo "  删除 reviews/template/$(basename "$old")（源中已不存在）"
done
for f in "${SCRIPT_DIR}/reviews/template/"*.md; do
  [ -f "$f" ] && cp "$f" "${TARGET}/reviews/template/" && echo "  复制 reviews/template/$(basename "$f")"
done

# PROFILE.md
if [ ! -f "${TARGET}/PROFILE.md" ]; then
  echo ""
  echo "==> 配置个人信息"
  read -p "  你的名字（如：小明）: " PROFILE_NAME </dev/tty
  read -p "  你的称呼（如：明哥）: " PROFILE_NICKNAME </dev/tty
  [ -z "${PROFILE_NICKNAME}" ] && PROFILE_NICKNAME="${PROFILE_NAME}"

  cat > "${TARGET}/PROFILE.md" << PROFILEEOF
## 身份

- **名字：** ${PROFILE_NAME}
- **定位：** iOS 高级开发工程师
- **风格：** 幽默风趣，轻松有趣，做事有主见，不随便附和

## 用户资料

- **称呼：** ${PROFILE_NICKNAME}
- **代词：** 他
- **时区：** Asia/Shanghai
- **工作习惯：** 做完一个模块先跑测试，再记进度
- **偏好：** 喜欢幽默风趣的交流方式

## 交流偏好

- 中文交流，简洁直接
- 给出方案时说明利弊，由他做决策
- 不要全盘执行，有不确定时先确认
- 关注一致性和规范性，会主动审查 AI 输出的质量

## 结尾招呼

每次回复结尾处，用轻松友好的方式跟我打招呼，让我知道你还在，记忆没有丢失。

## Agent 执行偏好

启动 subagent（annotate/plan/review）前，先发一条招呼通知，让我知道哪个 agent 即将工作。
PROFILEEOF
  echo "  生成 PROFILE.md"
fi

# opencode.json
OPENCODE_JSON="${TARGET}/opencode.json"
if [ -f "${OPENCODE_JSON}" ]; then
  UPDATED=$(python3 -c "
import json
try:
  cfg = json.load(open('${OPENCODE_JSON}'))
  changed = False
  instr = cfg.get('instructions', [])
  if 'PROFILE.md' not in instr:
    instr.append('PROFILE.md')
    cfg['instructions'] = instr
    changed = True
  mcp = cfg.get('mcp', {})
  if 'xcode' not in mcp:
    mcp['xcode'] = {'type': 'local', 'command': ['xcrun', 'mcpbridge']}
    cfg['mcp'] = mcp
    changed = True
  if changed:
    json.dump(cfg, open('${OPENCODE_JSON}', 'w'), indent=2, ensure_ascii=False)
    print('updated')
  else:
    print('exists')
except Exception:
  print('error')
" 2>/dev/null || echo "error")
  if [ "${UPDATED}" = "updated" ]; then
    echo "  更新 opencode.json（已添加 PROFILE.md / xcode mcp）"
  elif [ "${UPDATED}" = "error" ]; then
    echo "  警告: opencode.json 解析失败，请手动配置"
  fi
else
  cat > "${OPENCODE_JSON}" << 'OPENCODE_EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "xcode": {
      "type": "local",
      "command": [
        "xcrun",
        "mcpbridge"
      ]
    }
  },
  "instructions": [
    "PROFILE.md"
  ]
}
OPENCODE_EOF
  echo "  生成 opencode.json"
fi

# 清理临时克隆
[ -n "${CLEANUP}" ] && rm -rf "${SCRIPT_DIR}"

echo "==> 完成"
echo ""
echo "后续步骤:"
echo "  1. 确保 .opencode/ 已加入 git"
echo "  2. 运行 opencode 开始使用"
