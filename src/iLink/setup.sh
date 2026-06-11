#!/usr/bin/env bash
set -euo pipefail

# iLink - 环境初始化脚本（可选）
# 设置权限、检查依赖、更新 AGENTS.md
# Usage: bash iLink/setup.sh
#
# 前置条件: 已复制 .claude/, .qoder/, .codex/, iLink/, iLink-doc/ 到项目
#
# 注意：本脚本是可选的。/ilink-bootstrap 不依赖它。
#       仅当 .qoder / .codex 下的 bash 命令"没有执行权限"或 CRLF 行尾符
#       导致脚本无法运行时，跑一下本脚本即可。Claude / Gemini 的 slash
#       command 完全不依赖 exec 权限，可直接跳过本脚本。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "iLink — 环境初始化（可选辅助脚本）"
echo "================================================"
echo ""
echo "ℹ️  本脚本是可选的。/ilink-bootstrap 不依赖它，直接跑 bootstrap 即可使用 iLink。"
echo "   本脚本仅修复 4 件辅助事项："
echo "     ① bash 命令的可执行权限   ② Windows CRLF 行尾符"
echo "     ③ 检查基础命令依赖       ④ Codex 用户的 AGENTS.md 引导"
echo "   Claude / Gemini slash command 完全不依赖 exec 权限，可直接跳过本脚本。"
echo ""
echo "────────────────────────────────────────────────"
echo ""

# 1. Fix executable permissions
echo "[1/5] 设置脚本执行权限..."
for dir in ".claude/commands" ".qoder/commands" ".codex/commands" ".gemini/commands"; do
  if [[ -d "$PROJECT_ROOT/$dir" ]]; then
    chmod +x "$PROJECT_ROOT/$dir"/*  2>/dev/null || true
    echo "  ✓ $dir/*"
  fi
done

# 2. Fix line endings (convert CRLF to LF if needed)
echo "[2/5] 检查行尾符..."
crlf_fixed=0
sed_inplace() {
  local expr="$1"
  local file="$2"
  if sed -i '' -e "$expr" "$file" 2>/dev/null; then
    return 0
  fi
  sed -i -e "$expr" "$file"
}
for dir in ".claude/commands" ".qoder/commands" ".codex/commands" ".gemini/commands"; do
  if [[ -d "$PROJECT_ROOT/$dir" ]]; then
    for f in "$PROJECT_ROOT/$dir"/*; do
      if [[ -f "$f" ]] && grep -q $'\r' "$f" 2>/dev/null; then
        sed_inplace 's/\r$//' "$f"
        echo "  ✓ 修复 CRLF: $f"
        crlf_fixed=$((crlf_fixed + 1))
      fi
    done
  fi
done
if [[ $crlf_fixed -eq 0 ]]; then
  echo "  ✓ 无 CRLF 问题"
fi

# 3. Check dependencies
echo "[3/5] 检查依赖..."
missing=0
for cmd in bash awk sed grep tr cut sort basename od; do
  if command -v "$cmd" &>/dev/null; then
    echo "  ✓ $cmd"
  else
    echo "  ✗ $cmd 未找到"
    missing=$((missing + 1))
  fi
done
if command -v shasum &>/dev/null; then
  echo "  ✓ shasum"
else
  echo "  ✗ shasum 未找到"
  missing=$((missing + 1))
fi
# curl 仅在使用 /ilink-pull 时需要；缺失只警告不阻塞 setup
if command -v curl &>/dev/null; then
  echo "  ✓ curl"
else
  echo "  ⚠ curl 未找到（不影响 PM/Designer/Coder/QA 流水线；仅在使用 /ilink-pull 拉取 Issue System 时需要）"
fi

# 4. Verify Soul files
echo "[4/5] 检查 Soul 文件..."
souls_dir="$PROJECT_ROOT/iLink/souls"
all_ok=true
for soul in universal.soul.md pm.soul.md design.soul.md coder.soul.md qa.soul.md; do
  if [[ -f "$souls_dir/$soul" ]]; then
    echo "  ✓ $soul"
  else
    echo "  ✗ $soul 缺失"
    all_ok=false
  fi
done

if [[ -f "$PROJECT_ROOT/iLink/project-context.md" ]]; then
  echo "  ✓ project-context.md"
else
  echo "  ⚠ project-context.md 缺失（可选，但建议创建）"
fi

# 4.5 Warn sample stories
if [[ -d "$PROJECT_ROOT/iLink-doc/jzjy-0000" || -d "$PROJECT_ROOT/iLink-doc/kcia-0000" ]]; then
  echo "  ⚠ 检测到示例 Story（jzjy-0000 / kcia-0000），建议新项目中删除"
fi

# 5a. Update root CLAUDE.md for Claude CLI (optional)
if [[ -d "$PROJECT_ROOT/.claude" ]]; then
  echo "[5/5] 检测到 Claude 配置，更新根目录 CLAUDE.md..."
  claude_file="$PROJECT_ROOT/CLAUDE.md"

  if [[ -f "$claude_file" ]] && grep -q "iLink" "$claude_file" 2>/dev/null; then
    echo "  ✓ CLAUDE.md 已包含 iLink 引导，跳过"
  else
    {
      echo ""
      echo "---"
      echo ""
      echo "## iLink"
      echo ""
      echo "本项目使用 iLink 流水线开发（v1.8.0）。"
      echo ""
      echo "使用者统一在 Claude Code 对话窗口输入 \`/ilink-*\` slash 命令："
      echo "  \`/ilink-init <story> <usage-value>\` → \`/ilink-pm\` → \`/ilink-design\` → \`/ilink-approve\` → \`/ilink-coder\` → \`/ilink-qa <story> <usage-value>\`"
      echo "  可选拷问（v1.8.0+，建议全新会话，非强制）：\`/ilink-lightme <story>\`"
      echo "  辅助：\`/ilink-status [story]\`、\`/ilink-refine <story>\`、\`/ilink-pull <story>\`、\`/ilink-domain <module>\`"
      echo ""
      echo "AI 收到上述命令时，请读取 \`.claude/commands/\` 下对应的 \`.md\` 文件并按其中指令执行任务。"
      echo "\`.claude/commands/*.sh\` 是 AI 用 Bash 工具内部调用的实现细节，使用者无需打开操作系统 shell。"
    } >> "$claude_file"
    echo "  ✓ iLink 引导已追加到 CLAUDE.md"
  fi
fi

# 5b. Update root AGENTS.md for Codex CLI (optional)
if [[ -d "$PROJECT_ROOT/.codex" ]]; then
  echo "[5/5] 检测到 Codex 配置，更新根目录 AGENTS.md..."
  agents_file="$PROJECT_ROOT/AGENTS.md"

  if [[ -f "$agents_file" ]] && grep -q "iLink" "$agents_file" 2>/dev/null; then
    echo "  ✓ AGENTS.md 已包含 iLink 引导，跳过"
  else
    {
      echo ""
      echo "---"
      echo ""
      echo "## iLink"
      echo ""
      echo "本项目使用 iLink 流水线开发（v1.8.0）。"
      echo ""
      echo "使用者统一在 Codex 对话窗口输入 \`/ilink-*\` slash 命令："
      echo "  \`/ilink-init <story> <usage-value>\` → \`/ilink-pm\` → \`/ilink-design\` → \`/ilink-approve\` → \`/ilink-coder\` → \`/ilink-qa\`"
      echo "  可选拷问（v1.8.0+，建议全新会话，非强制）：\`/ilink-lightme <story>\`"
      echo "  辅助：\`/ilink-status [story]\`、\`/ilink-refine <story>\`、\`/ilink-pull <story>\`、\`/ilink-domain <module>\`"
      echo ""
      echo "AI 收到上述命令时，请读取 \`.codex/codex-commands.md\` 并按其中的指令执行对应角色任务。"
      echo "\`.codex/commands/*\` 下的 bash 脚本是 AI 内部调用的实现细节，使用者无需打开操作系统 shell。"
    } >> "$agents_file"
    echo "  ✓ iLink 引导已追加到 AGENTS.md"
  fi
else
  echo "[5/5] 跳过 AGENTS.md 更新（未检测到 Codex 配置）"
fi

echo ""
if [[ $missing -eq 0 && "$all_ok" == true ]]; then
  echo "✅ 环境就绪！"
else
  echo "⚠ 存在问题，请检查上方输出"
fi
echo ""
echo "使用方式："
echo ""
echo "【Claude CLI 用户】（复制 .claude + iLink + iLink-doc 目录）"
echo "  所有操作均在 Claude CLI 对话中执行 slash command："
echo "  /ilink-init <story-id> <usage-value> → /ilink-pm → /ilink-design → /ilink-approve → /ilink-coder → /ilink-qa"
echo "  可选拷问：/ilink-lightme <story-id>（v1.8.0+，建议全新会话，非强制）"
echo "  状态：/ilink-status [story-id]"
echo ""
echo "【Qoder CLI 用户】（复制 .qoder + iLink + iLink-doc 目录）"
echo "  所有操作均在 Qoder CLI 对话中执行 slash command："
echo "  /ilink-init <story-id> <usage-value> → /ilink-pm → /ilink-design → /ilink-approve → /ilink-coder → /ilink-qa"
echo "  可选拷问：/ilink-lightme <story-id>（v1.8.0+，建议全新会话，非强制）"
echo "  状态：/ilink-status [story-id]"
echo ""
echo "【Gemini CLI 用户】（复制 .gemini + iLink + iLink-doc 目录）"
echo "  所有操作均在 Gemini CLI 对话中执行 slash command："
echo "  /ilink-init <story-id> <usage-value> → /ilink-pm → /ilink-design → /ilink-approve → /ilink-coder → /ilink-qa"
echo "  可选拷问：/ilink-lightme <story-id>（v1.8.0+，建议全新会话，非强制）"
echo "  状态：/ilink-status [story-id]"
echo ""
if [[ -d "$PROJECT_ROOT/.codex" ]]; then
  echo "【Codex CLI 用户】（复制 .codex + iLink + iLink-doc 目录）"
  echo "  所有操作均在 Codex CLI 对话中执行 slash command："
  echo "  /ilink-init <story-id> <usage-value> → /ilink-pm → /ilink-design → /ilink-approve → /ilink-coder → /ilink-qa"
  echo "  可选拷问：/ilink-lightme <story-id>（v1.8.0+，建议全新会话，非强制）"
  echo "  状态：/ilink-status [story-id]"
fi
echo ""
