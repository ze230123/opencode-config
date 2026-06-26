#!/bin/bash
# opencode 项目初始化脚本
# 将团队 opencode 配置复制到目标项目
# 用法:
#   本地: ./init.sh /path/to/project
#   远程: curl -sL https://raw.githubusercontent.com/{org}/opencode-config/main/init.sh | bash -s /path/to/project

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
  REPO_URL="${OPENCODE_CONFIG_REPO:-https://github.com/youzyteam/opencode-config.git}"
  SCRIPT_DIR="$(mktemp -d)"
  echo "==> 克隆配置仓库..."
  git clone --depth 1 "${REPO_URL}" "${SCRIPT_DIR}" 2>/dev/null
  CLEANUP=1
fi

echo "==> 初始化 opencode 配置到 ${TARGET}"

# .opencode/agents
mkdir -p "${TARGET}/.opencode/agents"
for f in "${SCRIPT_DIR}/agents/"*.md; do
  [ -f "$f" ] && cp "$f" "${TARGET}/.opencode/agents/" && echo "  复制 agents/$(basename "$f")"
done

# .opencode/agents-guide.md
[ -f "${SCRIPT_DIR}/agents-guide.md" ] && cp "${SCRIPT_DIR}/agents-guide.md" "${TARGET}/.opencode/" && echo "  复制 agents-guide.md"

# .opencode/skills
mkdir -p "${TARGET}/.opencode/skills"
for d in "${SCRIPT_DIR}/skills/"*/; do
  [ -d "$d" ] && name=$(basename "$d") && mkdir -p "${TARGET}/.opencode/skills/${name}" && cp "${d}SKILL.md" "${TARGET}/.opencode/skills/${name}/" && echo "  复制 skills/${name}/SKILL.md"
done

# plans/template
mkdir -p "${TARGET}/plans/template"
for f in "${SCRIPT_DIR}/plans/template/"*.md; do
  [ -f "$f" ] && cp "$f" "${TARGET}/plans/template/" && echo "  复制 plans/template/$(basename "$f")"
done

# reviews/template
mkdir -p "${TARGET}/reviews/template"
for f in "${SCRIPT_DIR}/reviews/template/"*.md; do
  [ -f "$f" ] && cp "$f" "${TARGET}/reviews/template/" && echo "  复制 reviews/template/$(basename "$f")"
done

# PROFILE.md
if [ ! -f "${TARGET}/PROFILE.md" ] && [ -f "${SCRIPT_DIR}/PROFILE.example.md" ]; then
  cp "${SCRIPT_DIR}/PROFILE.example.md" "${TARGET}/PROFILE.md"
  echo "  复制 PROFILE.md（来自 example 模板，请修改个人信息）"
fi

# opencode.json
OPENCODE_JSON="${TARGET}/opencode.json"
if [ -f "${OPENCODE_JSON}" ]; then
  HAS_INSTRUCTIONS=$(python3 -c "
import json, sys
try:
  cfg = json.load(open('${OPENCODE_JSON}'))
  instr = cfg.get('instructions', [])
  if 'PROFILE.md' not in instr:
    instr.append('PROFILE.md')
    cfg['instructions'] = instr
    json.dump(cfg, open('${OPENCODE_JSON}', 'w'), indent=2, ensure_ascii=False)
    print('updated')
  else:
    print('exists')
except Exception:
  print('error')
" 2>/dev/null || echo "error")
  if [ "${HAS_INSTRUCTIONS}" = "updated" ]; then
    echo "  更新 opencode.json（已添加 PROFILE.md 到 instructions）"
  elif [ "${HAS_INSTRUCTIONS}" = "error" ]; then
    echo "  警告: opencode.json 解析失败，请手动添加 \"instructions\": [\"PROFILE.md\"]"
  fi
else
  cat > "${OPENCODE_JSON}" << 'OPENCODE_EOF'
{
  "$schema": "https://opencode.ai/config.json",
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
echo "  1. 修改 PROFILE.md 填写个人信息"
echo "  2. 确保 .opencode/ 已加入 git"
echo "  3. 运行 opencode 开始使用"
