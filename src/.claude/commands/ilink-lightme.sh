#!/usr/bin/env bash
# iLink ilink-lightme — Claude 平台脚本
# /ilink-lightme [-target pm|design] <story> 的预检
# 用法: bash .claude/commands/ilink-lightme.sh [-target pm|design] <story-id>
# 依赖: bash + grep + sed + awk + shasum + find + tr (macOS/Linux/Git Bash 默认全部包含)

set -euo pipefail

# ============================================================
# 1. 参数解析
# ============================================================
target="design"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -target|--target)
      if [[ $# -lt 2 ]]; then
        echo "❌ 用法：/ilink-lightme [-target pm|design] <story-id>" >&2
        exit 2
      fi
      target="$2"
      if [[ "$target" != "pm" && "$target" != "design" ]]; then
        echo "❌ 无效 target: $target (必须为 pm 或 design)" >&2
        exit 2
      fi
      shift 2
      ;;
    -*)
      echo "❌ 未知选项: $1" >&2
      echo "用法：/ilink-lightme [-target pm|design] <story-id>" >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 1 || -z "${1:-}" ]]; then
  echo "❌ 用法：/ilink-lightme [-target pm|design] <story-id>" >&2
  echo "" >&2
  echo "例如：/ilink-lightme kcia-1520" >&2
  echo "      /ilink-lightme -target pm kcia-1520" >&2
  if [[ $# -gt 1 ]]; then
    for arg in "$@"; do
      if [[ "$arg" == "-target" || "$arg" == "--target" ]]; then
        echo "" >&2
        echo "提示：flag 必须在 story-id 之前（如 /ilink-lightme -target pm kcia-1520）" >&2
        break
      fi
    done
  fi
  exit 2
fi

story="$1"

# 定位项目根：脚本位于 <project_root>/.claude/commands/ilink-lightme.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
base_dir="${PROJECT_ROOT}/iLink-doc/${story}"

# ============================================================
# 2. Story 目录与目标文档存在性校验
# ============================================================
if [[ ! -d "$base_dir" ]]; then
  echo "❌ Story 目录不存在: $base_dir" >&2
  echo "   请先执行 /ilink-init $story <usage-value> 创建 Story" >&2
  exit 1
fi

if [[ "$target" == "pm" ]]; then
  target_doc="${base_dir}/${story}-pm.master.md"
  target_label="pm"
else
  target_doc="${base_dir}/${story}-design.master.md"
  target_label="design"
fi

if [[ ! -f "$target_doc" ]]; then
  if [[ "$target" == "pm" ]]; then
    echo "❌ pm.master.md 不存在: $target_doc" >&2
    echo "   请先执行 /ilink-pm $story" >&2
  else
    echo "❌ design.master.md 不存在: $target_doc" >&2
    echo "   请先执行 /ilink-design $story" >&2
  fi
  exit 1
fi

# ============================================================
# 3. 提取 Status（仅作为预检信息展示，不阻断、不警告）
#    lightme 不限目标文档状态——任何状态下拷问对话和报告写入行为完全一致
#    参见 Root Spec §4.8.3
# ============================================================
status=$(grep -E '^Status: ' "$target_doc" 2>/dev/null | tail -1 | sed 's/^Status: //' | tr -d ' \r\n')

if [[ -z "$status" ]]; then
  status="UNKNOWN"
fi

# ============================================================
# 4. 计算 SHA1
# ============================================================
sha1=$(shasum "$target_doc" | awk '{print $1}')

# ============================================================
# 5. 报告 domain 覆盖率(仅 Design 模式,信息性)
# ============================================================
domain_dir="${PROJECT_ROOT}/iLink-doc/domain"
domain_count=0
if [[ -d "$domain_dir" ]]; then
  domain_count=$(find "$domain_dir" -maxdepth 1 -name '*-domain-knowledge.md' 2>/dev/null | wc -l | tr -d ' ')
fi

# ============================================================
# 6. 输出预检报告
# ============================================================
target_flag=""
if [[ "$target" != "design" ]]; then
  target_flag=" -target $target"
fi

echo ""
echo "=========================================="
echo "/ilink-lightme${target_flag} <$story> 预检通过"
echo "=========================================="
echo ""
echo "  目标文档      : $target_doc"
echo "  Status        : $status (信息性,不影响 lightme 行为)"
echo "  Upstream_SHA1 : $sha1"
if [[ "$target" == "design" ]]; then
echo "  Domain 文档数 : $domain_count (in $domain_dir/)"
fi
echo ""
echo "  预检完成,AI 将继续执行 lightme 拷问。"
if [[ "$target" == "pm" ]]; then
echo "  输出文件:iLink-doc/$story/${story}-lightme-pm.md"
else
echo "  输出文件:iLink-doc/$story/${story}-lightme-design.md"
fi
echo ""
echo "  友情提示:lightme 不触碰 master doc / project-context / domain-knowledge。"
echo "  所有 TO-FIX 项以 copy-ready 修订建议代码块形式写入报告,使用者自行复制粘贴。"
echo "  全新 Claude Code 会话更利于对抗 AI 自身合理性,但可能消耗更多 token;"
echo "  同会话也可继续,隔离效果会下降(见 Root Spec §4.8.3)。"
echo ""
